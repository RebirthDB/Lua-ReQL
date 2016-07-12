--- Handler implementing latest RethinkDB handshake.
-- @module rethinkdb.internal.current_handshake
-- @author Adam Grandquist
-- @license Apache
-- @copyright Adam Grandquist 2016

local crypto = require('crypto')
local ltn12 = require('ltn12')
local pbkdf2 = require'rethinkdb.internal.pbkdf'

--- Helper for bitwise operations.
local function prequire(mod_name, ...)
  if not mod_name then return end

  local success, bits = pcall(require, mod_name)

  if success then
    return true, bits
  end

  return prequire(...)
end

local load_success, bits = prequire(
  'rethinkdb.internal.bits53', 'bit32', 'bit', 'rethinkdb.internal.bits51')

if load_success then
  if not bits.tobit then
    --- normalize integer to bitfield
    -- @int a integer
    -- @treturn int
    function bits.tobit(a)
      return bits.bor(a, 0)
    end
  end
end

local bor = bits.bor
local bxor = bits.bxor
local tobit = bits.tobit
local rand_bytes = crypto.rand.bytes
local hmac = crypto.hmac

local unpack = _G.unpack or table.unpack

local function bxor256(u, t)
  local res = {}
  for i=1, math.max(string.len(u), string.len(t)) do
    res[i] = bxor(string.byte(u, i) or 0, string.byte(t, i) or 0)
  end
  return string.char(unpack(res))
end

local function __compare_digest(a, b)
  local result

  if string.len(a) == string.len(b) then
    result = 0
  end
  if string.len(a) ~= string.len(b) then
    result = 1
  end

  for i=1, math.max(string.len(a), string.len(b)) do
    result = bor(result, bxor(string.byte(a, i) or 0, string.byte(b, i) or 0))
  end

  return tobit(result) ~= tobit(0)
end

local function current_handshake(socket_inst, auth_key, user)
  local function send(data)
    local success, err = ltn12.pump.all(ltn12.source.string(data), socket_inst.sink)
    if not success then
      socket_inst.close()
      return nil, err
    end
    return true
  end

  local buffer = ''

  local function sink(chunk, src_err)
    if src_err then
      return nil, src_err
    end
    if chunk == nil then
      return nil, 'closed'
    end
    buffer = buffer .. chunk
    return true
  end

  local r = socket_inst.r

  local function encode(object)
    return send(table.concat{r.encode(object), '\0'})
  end

  local function get_message()
    local i = string.find(buffer, '\0')
    while not i do
      local success, err = ltn12.pump.step(socket_inst.source(1), sink)
      if not success then
        return nil, err
      end
      i = string.find(buffer, '\0')
    end

    local message = string.sub(buffer, 1, i - 1)
    buffer = string.sub(buffer, i + 1)
    return message
  end

  local success, err = send'\195\189\194\52'
  if not success then
    return nil, err
  end

  -- Now we have to wait for a response from the server
  -- acknowledging the connection
  -- this will be a null terminated json document on success
  -- or a null terminated error string on failure
  local message
  message, err = get_message()
  if not message then
    return nil, err
  end

  local valid, response = pcall(r.decode, message)

  if not (valid and response) then
    return nil, message
  end

  if not response.success then
    return nil, response
  end

  local nonce = r.b64(rand_bytes(18))

  local client_first_message_bare = 'n=' .. user .. ',r=' .. nonce

  -- send the second client message
  -- {
  --   "protocol_version": <number>,
  --   "authentication_method": <method>,
  --   "authentication": "n,,n=<user>,r=<nonce>"
  -- }
  success, err = encode{
    protocol_version = response.min_protocol_version,
    authentication_method = 'SCRAM-SHA-256',
    authentication = 'n,,' .. client_first_message_bare
  }
  if not success then
    return nil, err
  end


  -- wait for the second server challenge
  -- this is always a json document
  -- {
  --   "success": <bool>,
  --   "authentication": "r=<nonce><server_nonce>,s=<salt>,i=<iteration>"
  -- }

  message, err = get_message()
  if not message then
    return nil, err
  end

  valid, response = pcall(r.decode, message)

  if not (valid and response) then
    return nil, message
  end

  if not response.success then
    return nil, response
  end

  -- the authentication property will need to be retained
  local authentication = {}
  local server_first_message = response.authentication
  local response_authentication = server_first_message .. ','
  for k, v in string.gmatch(response_authentication, '([rsi])=(.-),') do
    authentication[k] = v
  end

  if string.sub(authentication.r, 1, string.len(nonce)) ~= nonce then
    return nil, 'Invalid nonce'
  end

  authentication.i = tonumber(authentication.i)

  local client_final_message_without_proof = 'c=biws,r=' .. authentication.r

  local salt = r.unb64(authentication.s)

  -- SaltedPassword := Hi(Normalize(password), salt, i)
  local salted_password = pbkdf2(auth_key, salt, authentication.i)

  -- ClientKey := HMAC(SaltedPassword, "Client Key")
  local client_key = hmac.digest('sha256', salted_password, 'Client Key', true)

  -- StoredKey := H(ClientKey)
  local stored_key = crypto.digest('sha256', client_key, true)

  -- AuthMessage := client-first-message-bare + "," +
  --                server-first-message + "," +
  --                client-final-message-without-proof
  local auth_message = table.concat({
      client_first_message_bare,
      server_first_message,
      client_final_message_without_proof}, ',')

  -- ClientSignature := HMAC(StoredKey, AuthMessage)
  local client_signature = hmac.digest('sha256', stored_key, auth_message, true)

  local client_proof = bxor256(client_key, client_signature)

  -- ServerKey := HMAC(SaltedPassword, "Server Key")
  local server_key = hmac.digest('sha256', salted_password, 'Server Key', true)

  -- ServerSignature := HMAC(ServerKey, AuthMessage)
  local server_signature = hmac.digest('sha256', server_key, auth_message, true)

  -- send the third client message
  -- {
  --   "authentication": "c=biws,r=<nonce><server_nonce>,p=<proof>"
  -- }
  success, err = encode{
    authentication =
    table.concat{client_final_message_without_proof, ',p=', r.b64(client_proof)}
  }
  if not success then
    return nil, err
  end

  -- wait for the third server challenge
  -- this is always a json document
  -- {
  --   "success": <bool>,
  --   "authentication": "v=<server_signature>"
  -- }
  message, err = get_message()
  if not message then
    return nil, err
  end

  valid, response = pcall(r.decode, message)

  if not (valid and response) then
    return nil, message
  end

  if not response.success then
    return nil, response
  end

  if not __compare_digest(response.v, server_signature) then
    return nil, response
  end

  return true
end

return current_handshake
