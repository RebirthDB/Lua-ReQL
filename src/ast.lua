local util = require('./util')
local err = require('./errors')
local net = require('./net')
local protoTermType = require('./proto-def').TermType

-- rethinkdb is both the main export object for the module
-- and a function that shortcuts `r.expr`.
local rethinkdb = { }

local funcWrap, hasImplicit, intsp, kved, intspallargs, shouldWrap

local TermBase, RDBVal, DatumTerm, RDBOp, RDBOpWrap, MakeArray, MakeObject, Var
local JavaScript, Http, Json, Binary, Args, UserError, Random, ImplicitVar, Db
local Table, Get, GetAll, Eq, Ne, Lt, Le, Gt, Ge, Not, Add, Sub, Mul, Div, Mod
local Append, Prepend, Difference, SetInsert, SetUnion, SetIntersection
local SetDifference, Slice, Skip, Limit, GetField, Bracket, Contains, InsertAt
local SpliceAt, DeleteAt, ChangeAt, HasFields, WithFields, Keys, Changes
local Object, Pluck, IndexesOf, Without, Merge, Between, Reduce, Map, Filter
local ConcatMap, OrderBy, Distinct, Count, Union, Nth, Match, Split, Upcase
local Downcase, IsEmpty, Group, Sum, Avg, Min, Max, InnerJoin, OuterJoin
local EqJoin, Zip, CoerceTo, Ungroup, TypeOf, Info, Sample, Update, Delete
local Replace, Insert, DbCreate, DbDrop, DbList, TableCreate, TableDrop
local TableList, IndexCreate, IndexDrop, IndexRename, IndexList, IndexStatus
local IndexWait, Sync, FunCall, Default, Branch, Any, All, ForEach, Func, Asc
local Desc, Literal, ISO8601, ToISO8601, EpochTime, ToEpochTime, Now
local InTimezone, During, RQLDate, TimeOfDay, Timezone, Year, Month, Day
local DayOfWeek, DayOfYear, Hours, Minutes, Seconds, Time, GeoJson, ToGeoJson
local Point, Line, Polygon, Distance, Intersects, Includes, Circle
local GetIntersecting, GetNearest, Fill, UUID, Monday, Tuesday, Wednesday
local Thursday, Friday, Saturday, Sunday, January, February, March, April, May
local June, July, August, September, October, November, December

-- Utilities

function funcWrap(val)
  if not val then
    -- Pass through the nil value so it's caught by
    -- the appropriate nil checker
    return val
  end
  val = rethinkdb.expr(val)
  local ivarScan = function(node)
    if not isinstance(TermBase, node) then
      return false
    end
    if isinstance(ImplicitVar, node) then
      return true
    end
    for _, v in ipairs(node.args) do
      if ivarScan(v) then
        return true
      end
    end
    for k, v in ipairs(node.optargs) do
      if ivarScan(v) then
        return true
      end
    end
    return false
  end
  if ivarScan(val) then
    return Func({ }, function(x)
      return val
    end)
  end
  return val
end
function hasImplicit(args)
  -- args is an array of (strings and arrays)
  -- We recurse to look for `r.row` which is an implicit var
  if type(args) == "tree" then
    for _, arg in ipairs(args) do
      if hasImplicit(arg) == true then
        return true
      end
    end
  else
    if args == 'r.row' then
      return true
    end
  end
  return false
end

-- AST classes

do
  local _base_0 = {
    showRunWarning = true,
    run = function(connection, options, callback)
      -- Valid syntaxes are
      -- connection, callback
      -- connection, options, callback
      -- connection, nil, callback

      if net.isConnection(connection) == true then
        -- Handle run(connection, callback)
        if type(options) == "function" then
          if not (callback) then
            callback = options
            options = { }
          else
            options(err.RqlDriverError("Second argument to `run` cannot be a function if a third argument is provided."))
            return
          end
        end
      end
      -- else we suppose that we have run(connection[, options][, callback])
      if not (options) then
        options = { }
      end

      -- Check if the arguments are valid types
      for key, _ in ipairs(options) do
        local _exp_0 = key
        if 'useOutdated' == _exp_0 or 'noreply' == _exp_0 or 'timeFormat' == _exp_0 or 'profile' == _exp_0 or 'durability' == _exp_0 or 'groupFormat' == _exp_0 or 'binaryFormat' == _exp_0 or 'batchConf' == _exp_0 or 'arrayLimit' == _exp_0 then
        else
          callback(err.RqlDriverError("Found " + key + " which is not a valid option. valid options are {useOutdated: <bool>, noreply: <bool>, timeFormat: <string>, groupFormat: <string>, binaryFormat: <string>, profile: <bool>, durability: <string>, arrayLimit: <number>}."))
        end
      end
      if not net.isConnection(connection) then
        callback(err.RqlDriverError("First argument to `run` must be an open connection."))
      end
      if options.noreply == true or type(callback) == 'function' then
        local status
        status, err = pcall(connection._start(self, callback, options))
        if not (status) then
          -- It was decided that, if we can, we prefer to invoke the callback
          -- with any errors rather than throw them as normal exceptions.
          -- Thus we catch errors here and invoke the callback instead of
          -- letting the error bubble up.
          if type(callback) == 'function' then
            return callback(err)
          end
        end
      end
    end,
    toString = function()
      return err.printQuery(self)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self = function(field)
        return self.bracket(field)
      end
      return self
    end,
    __base = _base_0,
    __name = "TermBase"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  TermBase = _class_0
end
do
  local _parent_0 = TermBase
  local _base_0 = {
    eq = function(...)
      return Eq({ }, self, unpack(arg))
    end,
    ne = function(...)
      return Ne({ }, self, unpack(arg))
    end,
    lt = function(...)
      return Lt({ }, self, unpack(arg))
    end,
    le = function(...)
      return Le({ }, self, unpack(arg))
    end,
    gt = function(...)
      return Gt({ }, self, unpack(arg))
    end,
    ge = function(...)
      return Ge({ }, self, unpack(arg))
    end,
    not_ = function(...)
      return Not({ }, self, unpack(arg))
    end,
    add = function(...)
      return Add({ }, self, unpack(arg))
    end,
    sub = function(...)
      return Sub({ }, self, unpack(arg))
    end,
    mul = function(...)
      return Mul({ }, self, unpack(arg))
    end,
    div = function(...)
      return Div({ }, self, unpack(arg))
    end,
    mod = function(...)
      return Mod({ }, self, unpack(arg))
    end,
    append = function(...)
      return Append({ }, self, unpack(arg))
    end,
    prepend = function(...)
      return Prepend({ }, self, unpack(arg))
    end,
    difference = function(...)
      return Difference({ }, self, unpack(arg))
    end,
    set_insert = function(...)
      return SetInsert({ }, self, unpack(arg))
    end,
    set_union = function(...)
      return SetUnion({ }, self, unpack(arg))
    end,
    set_intersection = function(...)
      return SetIntersection({ }, self, unpack(arg))
    end,
    set_difference = function(...)
      return SetDifference({ }, self, unpack(arg))
    end,
    slice = function(left, right_or_opts, opts)
      if opts then
        return Slice(opts, self, left, right_or_opts)
      else
        if right_or_opts then
          if (type(right_or_opts) == 'tree') and (not isinstance(TermBase, right_or_opts)) then
            return Slice(right_or_opts, self, left)
          else
            return Slice({ }, self, left, right_or_opts)
          end
        else
          return Slice({ }, self, left)
        end
      end
    end,
    skip = function(...)
      return Skip({ }, self, unpack(arg))
    end,
    limit = function(...)
      return Limit({ }, self, unpack(arg))
    end,
    get_field = function(...)
      return GetField({ }, self, unpack(arg))
    end,
    contains = function(...)
      return Contains({ }, self, unpack(arg))
    end,
    insert_at = function(...)
      return InsertAt({ }, self, unpack(arg))
    end,
    splice_at = function(...)
      return SpliceAt({ }, self, unpack(arg))
    end,
    delete_at = function(...)
      return DeleteAt({ }, self, unpack(arg))
    end,
    change_at = function(...)
      return ChangeAt({ }, self, unpack(arg))
    end,
    indexes_of = function(...)
      return IndexesOf({ }, self, unpack(arg))
    end,
    has_fields = function(...)
      return HasFields({ }, self, unpack(arg))
    end,
    with_fields = function(...)
      return WithFields({ }, self, unpack(arg))
    end,
    keys = function(...)
      return Keys({ }, self, unpack(arg))
    end,
    changes = function(...)
      return Changes({ }, self, unpack(arg))
    end,

    -- pluck and without on zero fields are allowed
    pluck = function(...)
      return Pluck({ }, self, unpack(arg))
    end,
    without = function(...)
      return Without({ }, self, unpack(arg))
    end,
    merge = function(...)
      return Merge({ }, self, unpack(arg))
    end,
    between = function(left, right, opts)
      return Between(opts, self, left, right)
    end,
    reduce = function(...)
      return Reduce({ }, self, unpack(arg))
    end,
    map = function(...)
      return Map({ }, self, unpack(arg))
    end,
    filter = function(predicate, opts)
      return Filter(opts, self, funcWrap(predicate))
    end,
    concat_map = function(...)
      return ConcatMap({ }, self, unpack(arg))
    end,
    distinct = function(opts)
      return Distinct(opts, self)
    end,
    count = function(...)
      return Count({ }, self, unpack(arg))
    end,
    union = function(...)
      return Union({ }, self, unpack(arg))
    end,
    nth = function(...)
      return Nth({ }, self, unpack(arg))
    end,
    bracket = function(...)
      return Bracket({ }, self, unpack(arg))
    end,
    match = function(...)
      return Match({ }, self, unpack(arg))
    end,
    split = function(...)
      return Split({ }, self, unpack(arg))
    end,
    upcase = function(...)
      return Upcase({ }, self, unpack(arg))
    end,
    downcase = function(...)
      return Downcase({ }, self, unpack(arg))
    end,
    is_empty = function(...)
      return IsEmpty({ }, self, unpack(arg))
    end,
    inner_join = function(...)
      return InnerJoin({ }, self, unpack(arg))
    end,
    outer_join = function(...)
      return OuterJoin({ }, self, unpack(arg))
    end,
    eq_join = function(left_attr, right, opts)
      return EqJoin(opts, self, funcWrap(left_attr), right)
    end,
    zip = function(...)
      return Zip({ }, self, unpack(arg))
    end,
    coerce_to = function(...)
      return CoerceTo({ }, self, unpack(arg))
    end,
    ungroup = function(...)
      return Ungroup({ }, self, unpack(arg))
    end,
    type_of = function(...)
      return TypeOf({ }, self, unpack(arg))
    end,
    update = function(func, opts)
      return Update(opts, self, funcWrap(func))
    end,
    delete = function(opts)
      return Delete(opts, self)
    end,
    replace = function(func, opts)
      return Replace(opts, self, funcWrap(func))
    end,
    do_ = function(...)
      local args
      do
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = arg
        local _max_0 = (arg.n - 1)
        for _index_0 = 1, _max_0 < 0 and #_list_0 + _max_0 or _max_0 do
          local a = _list_0[_index_0]
          _accum_0[_len_0] = a
          _len_0 = _len_0 + 1
        end
        args = _accum_0
      end
      return FunCall({ }, funcWrap(arg[arg.n]), self, unpack(args))
    end,
    default = function(...)
      return Default({ }, self, unpack(arg))
    end,
    or_ = function(...)
      return Any({ }, self, unpack(arg))
    end,
    any = function(...)
      return Any({ }, self, unpack(arg))
    end,
    and_ = function(...)
      return All({ }, self, unpack(arg))
    end,
    all = function(...)
      return All({ }, self, unpack(arg))
    end,
    for_each = function(...)
      return ForEach({ }, self, unpack(arg))
    end,
    sum = function(...)
      return Sum({ }, self, unpack(arg))
    end,
    avg = function(...)
      return Avg({ }, self, unpack(arg))
    end,
    min = function(...)
      return Min({ }, self, unpack(arg))
    end,
    max = function(...)
      return Max({ }, self, unpack(arg))
    end,
    info = function(...)
      return Info({ }, self, unpack(arg))
    end,
    sample = function(...)
      return Sample({ }, self, unpack(arg))
    end,
    group = function(...)
      -- Default if no opts dict provided
      local opts = { }
      local fields = arg

      -- Look for opts dict
      if arg.n > 0 then
        local perhapsOptDict = arg[arg.n]
        if perhapsOptDict and (type(perhapsOptDict) == 'tree') and not (isinstance(TermBase, perhapsOptDict)) then
          opts = perhapsOptDict
          do
            local _accum_0 = { }
            local _len_0 = 1
            local _list_0 = arg
            local _max_0 = (arg.n - 1)
            for _index_0 = 1, _max_0 < 0 and #_list_0 + _max_0 or _max_0 do
              local a = _list_0[_index_0]
              _accum_0[_len_0] = a
              _len_0 = _len_0 + 1
            end
            fields = _accum_0
          end
        end
      end
      do
        local _accum_0 = { }
        local _len_0 = 1
        for i, field in ipairs(fields) do
          _accum_0[_len_0] = funcWrap(field)
          _len_0 = _len_0 + 1
        end
        fields = _accum_0
      end
      return Group(opts, self, unpack(fields))
    end,
    order_by = function(...)
      -- Default if no opts dict provided
      local opts = { }
      local attrs = arg

      -- Look for opts dict
      local perhapsOptDict = arg[arg.n]
      if perhapsOptDict and (type(perhapsOptDict) == 'tree') and not isinstance(TermBase, perhapsOptDict) then
        opts = perhapsOptDict
        do
          local _accum_0 = { }
          local _len_0 = 1
          local _list_0 = arg
          local _max_0 = (arg.n - 1)
          for _index_0 = 1, _max_0 < 0 and #_list_0 + _max_0 or _max_0 do
            local a = _list_0[_index_0]
            _accum_0[_len_0] = a
            _len_0 = _len_0 + 1
          end
          attrs = _accum_0
        end
      end
      do
        local _accum_0 = { }
        local _len_0 = 1
        for i, attr in ipairs(attrs) do
          if isinstance(Asc, attr) or isinstance(Desc, attr) then
            _accum_0[_len_0] = attr
          else
            _accum_0[_len_0] = funcWrap(attr)
          end
          _len_0 = _len_0 + 1
        end
        attrs = _accum_0
      end
      return OrderBy(opts, self, unpack(attrs))
    end,

    -- Geo operations
    to_geojson = function(...)
      return ToGeoJson({ }, self, unpack(arg))
    end,
    distance = function(g, opts)
      return Distance(opts, self, g)
    end,
    intersects = function(...)
      return Intersects({ }, self, unpack(arg))
    end,
    includes = function(...)
      return Includes({ }, self, unpack(arg))
    end,
    fill = function(...)
      return Fill({ }, self, unpack(arg))
    end,

    -- Database operations

    table_create = function(tblName, opts)
      return TableCreate(opts, self, tblName)
    end,
    table_drop = function(...)
      return TableDrop({ }, self, unpack(arg))
    end,
    table_list = function(...)
      return TableList({ }, self, unpack(arg))
    end,
    table = function(tblName, opts)
      return Table(opts, self, tblName)
    end,

    -- Table operations

    get = function(...)
      return Get({ }, self, unpack(arg))
    end,
    get_all = function(...)
      -- Default if no opts dict provided
      local opts = { }
      local keys = arg

      -- Look for opts dict
      if arg.n > 1 then
        local perhapsOptDict = arg[arg.n - 1]
        if perhapsOptDict and ((type(perhapsOptDict) == 'tree') and not (isinstance(TermBase, perhapsOptDict))) then
          opts = perhapsOptDict
          do
            local _accum_0 = { }
            local _len_0 = 1
            local _list_0 = arg
            local _max_0 = (arg.n - 1)
            for _index_0 = 1, _max_0 < 0 and #_list_0 + _max_0 or _max_0 do
              local a = _list_0[_index_0]
              _accum_0[_len_0] = a
              _len_0 = _len_0 + 1
            end
            keys = _accum_0
          end
        end
      end
      return GetAll(opts, self, unpack(keys))
    end,
    insert = function(doc, opts)
      return Insert(opts, self, rethinkdb.expr(doc))
    end,
    index_create = function(name, defun_or_opts, opts)
      if opts then
        return IndexCreate(opts, self, name, funcWrap(defun_or_opts))
      else
        if defun_or_opts then
          -- FIXME?
          if (type(defun_or_opts) == 'tree') and not isinstance(Function, defun_or_opts) and not isinstance(TermBase, defun_or_opts) then
            return IndexCreate(defun_or_opts, self, name)
          else
            return IndexCreate({ }, self, name, funcWrap(defun_or_opts))
          end
        else
          return IndexCreate({ }, self, name)
        end
      end
    end,
    index_drop = function(...)
      return IndexDrop({ }, self, unpack(arg))
    end,
    index_list = function(...)
      return IndexList({ }, self, unpack(arg))
    end,
    index_status = function(...)
      return IndexStatus({ }, self, unpack(arg))
    end,
    index_wait = function(...)
      return IndexWait({ }, self, unpack(arg))
    end,
    index_rename = function(old_name, new_name, opts)
      return IndexRename(opts, self, old_name, new_name)
    end,
    sync = function(...)
      return Sync({ }, self, unpack(arg))
    end,
    to_iso8601 = function(...)
      return ToISO8601({ }, self, unpack(arg))
    end,
    to_epoch_time = function(...)
      return ToEpochTime({ }, self, unpack(arg))
    end,
    in_timezone = function(...)
      return InTimezone({ }, self, unpack(arg))
    end,
    during = function(t2, t3, opts)
      return During(opts, self, t2, t3)
    end,
    date = function(...)
      return RQLDate({ }, self, unpack(arg))
    end,
    time_of_day = function(...)
      return TimeOfDay({ }, self, unpack(arg))
    end,
    timezone = function(...)
      return Timezone({ }, self, unpack(arg))
    end,
    year = function(...)
      return Year({ }, self, unpack(arg))
    end,
    month = function(...)
      return Month({ }, self, unpack(arg))
    end,
    day = function(...)
      return Day({ }, self, unpack(arg))
    end,
    day_of_week = function(...)
      return DayOfWeek({ }, self, unpack(arg))
    end,
    day_of_year = function(...)
      return DayOfYear({ }, self, unpack(arg))
    end,
    hours = function(...)
      return Hours({ }, self, unpack(arg))
    end,
    minutes = function(...)
      return Minutes({ }, self, unpack(arg))
    end,
    seconds = function(...)
      return Seconds({ }, self, unpack(arg))
    end,
    uuid = function(...)
      return UUID({ }, self, unpack(arg))
    end,
    get_intersecting = function(g, opts)
      return GetIntersecting(opts, self, g)
    end,
    get_nearest = function(g, opts)
      return GetNearest(opts, self, g)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "RDBVal",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  RDBVal = _class_0
end
do
  local _parent_0 = RDBVal
  local _base_0 = {
    args = { },
    optargs = { },
    compose = function()
      local _exp_0 = type(self.data)
      if 'string' == _exp_0 then
        return '"' + self.data + '"'
      else
        return '' + self.data
      end
    end,
    build = function()
      if type(self.data) == 'number' then
        if not (isFinite(self.data)) then
          error(TypeError("Illegal non-finite number `" + self.data.toString() + "`."))
        end
      end
      return self.data
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(val)
      local self = { }
      self.data = val
      return self
    end,
    __base = _base_0,
    __name = "DatumTerm",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  DatumTerm = _class_0
end
do
  local _parent_0 = RDBVal
  local _base_0 = {
    build = function()
      local res = {
        self.tt,
        { }
      }
      for i, arg in ipairs(self.args) do
        res[1].push(arg.build())
      end
      local opts = { }
      local add_opts = false
      for key, val in ipairs(self.optargs) do
        add_opts = true
        opts[key] = val.build()
      end
      if add_opts then
        res.push(opts)
      end
      return res
    end,
    compose = function(args, optargs)
      if self.st then
        return {
          'r.',
          self.st,
          '(',
          intspallargs(args, optargs),
          ')'
        }
      else
        if shouldWrap(self.args[0]) then
          args[0] = {
            'r(',
            args[0],
            ')'
          }
        end
        return {
          args[0],
          '.',
          self.mt,
          '(',
          intspallargs((function()
            local _accum_0 = { }
            local _len_0 = 1
            for _index_0 = 2, #args do
              local a = args[_index_0]
              _accum_0[_len_0] = a
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)(), optargs),
          ')'
        }
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(optargs, ...)
      local self = { }
      do
        local _accum_0 = { }
        for i, a in ipairs(arg) do
          _accum_0[i] = rethinkdb.expr(a)
        end
        self.args = _accum_0
      end
      self.optargs = optargs
      return self
    end,
    __base = _base_0,
    __name = "RDBOp",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  RDBOp = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(optargs, ...)
      local self = _parent_0.__init(self)
      do
        local _accum_0 = { }
        local _len_0 = 1
        for i, a in ipairs(arg) do
          _accum_0[_len_0] = rethinkdb.expr(funcWrap(a))
          _len_0 = _len_0 + 1
        end
        self.args = _accum_0
      end
      self.optargs = optargs
      return self
    end,
    __base = _base_0,
    __name = "RDBOpWrap",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  RDBOpWrap = _class_0
end
function intsp(seq)
  if not (seq[0]) then
    return { }
  end
  local res = {
    seq[1]
  }
  for _index_0 = 2, #seq do
    local e = seq[_index_0]
    res.push(', ', e)
  end
  return res
end
function kved(optargs)
  return {
    '{',
    intsp((function()
      local _accum_0 = { }
      local _len_0 = 1
      for k, v in ipairs(optargs) do
        _accum_0[_len_0] = {
          k,
          ': ',
          v
        }
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)()),
    '}'
  }
end
function intspallargs(args, optargs)
  local argrepr = { }
  if args.length > 0 then
    argrepr.push(intsp(args))
  end
  if Object.keys(optargs).length > 0 then
    if argrepr.length > 0 then
      argrepr.push(', ')
    end
    argrepr.push(kved(optargs))
  end
  return argrepr
end
function shouldWrap(arg)
  return isinstance(DatumTerm, arg) or isinstance(MakeArray, arg) or isinstance(MakeObject, arg)
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.MAKE_ARRAY,
    st = '[...]', -- This is only used by the `nil` argument checker
    compose = function(args)
      return {
        '[',
        intsp(args),
        ']'
      }
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "MakeArray",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  MakeArray = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.MAKE_OBJECT,
    st = '{...}', -- This is only used by the `nil` argument checker
    compose = function(args, optargs)
      return kved(optargs)
    end,
    build = function()
      local res = { }
      for key, val in ipairs(self.optargs) do
        res[key] = val.build()
      end
      return res
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(obj, nestingDepth)
      if nestingDepth == nil then
        nestingDepth = 20
      end
      local self = _parent_0.__init(self, { })
      self.optargs = { }
      for key, val in ipairs(obj) do
        if not (val) then
          error(err.RqlDriverError("Object field '" .. tostring(key) .. "' may not be nil"))
        end
        self.optargs[key] = rethinkdb.expr(val, nestingDepth - 1)
      end
      return self
    end,
    __base = _base_0,
    __name = "MakeObject",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  MakeObject = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.VAR,
    compose = function(args)
      return {
        'var_' .. args
      }
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Var",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Var = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.JAVASCRIPT,
    st = 'js'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "JavaScript",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  JavaScript = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.HTTP,
    st = 'http'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Http",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Http = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.JSON,
    st = 'json'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Json",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Json = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.BINARY,
    st = 'binary',
    compose = function()
      if self.args.length == 0 then
        return 'r.binary(<data>)'
      else
        return _parent_0
      end
    end,
    build = function()
      if self.args.length == 0 then
        local data = self.base64_data
        return {
          ['$reql_type$'] = 'BINARY',
          data = data
        }
      else
        return _parent_0
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(data)
      if isinstance(TermBase, data) then
        local self = _parent_0.__init(self, { }, data)
      else
        if isinstance(Buffer, data) then
          local self = _parent_0.__init(self)
          self.base64_data = data.toString("base64")
        else
          error(TypeError("Parameter to `r.binary` must be a Buffer object or RQL query."))
        end
      end
      return self
    end,
    __base = _base_0,
    __name = "Binary",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Binary = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.ARGS,
    st = 'args'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Args",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Args = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.ERROR,
    st = 'error'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "UserError",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  UserError = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.RANDOM,
    st = 'random'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Random",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Random = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.IMPLICIT_VAR,
    compose = function()
      return {
        'r.row'
      }
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "ImplicitVar",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ImplicitVar = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DB,
    st = 'db'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Db",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Db = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.TABLE,
    st = 'table',
    compose = function(args, optargs)
      if isinstance(Db, self.args[0]) then
        return {
          args[0],
          '.table(',
          intspallargs((function()
            local _accum_0 = { }
            local _len_0 = 1
            for _index_0 = 2, #args do
              local a = args[_index_0]
              _accum_0[_len_0] = a
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)(), optargs),
          ')'
        }
      else
        return {
          'r.table(',
          intspallargs(args, optargs),
          ')'
        }
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Table",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Table = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.GET,
    mt = 'get'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Get",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Get = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.GET_ALL,
    mt = 'get_all'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "GetAll",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  GetAll = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.EQ,
    mt = 'eq'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Eq",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Eq = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.NE,
    mt = 'ne'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Ne",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Ne = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.LT,
    mt = 'lt'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Lt",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Lt = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.LE,
    mt = 'le'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Le",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Le = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.GT,
    mt = 'gt'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Gt",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Gt = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.GE,
    mt = 'ge'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Ge",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Ge = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.NOT,
    mt = 'not_'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Not",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Not = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.ADD,
    mt = 'add'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Add",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Add = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.SUB,
    mt = 'sub'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Sub",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Sub = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.MUL,
    mt = 'mul'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Mul",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Mul = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DIV,
    mt = 'div'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Div",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Div = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.MOD,
    mt = 'mod'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Mod",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Mod = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.APPEND,
    mt = 'append'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Append",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Append = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.PREPEND,
    mt = 'prepend'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Prepend",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Prepend = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DIFFERENCE,
    mt = 'difference'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Difference",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Difference = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.SET_INSERT,
    mt = 'set_insert'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "SetInsert",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  SetInsert = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.SET_UNION,
    mt = 'set_union'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "SetUnion",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  SetUnion = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.SET_INTERSECTION,
    mt = 'set_intersection'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "SetIntersection",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  SetIntersection = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.SET_DIFFERENCE,
    mt = 'set_difference'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "SetDifference",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  SetDifference = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.SLICE,
    mt = 'slice'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Slice",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Slice = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.SKIP,
    mt = 'skip'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Skip",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Skip = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.LIMIT,
    mt = 'limit'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Limit",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Limit = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.GET_FIELD,
    mt = 'get_field'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "GetField",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  GetField = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.BRACKET,
    st = '(...)', -- This is only used by the `nil` argument checker
    compose = function(args)
      return {
        args[0],
        '(',
        args[1],
        ')'
      }
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Bracket",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Bracket = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.CONTAINS,
    mt = 'contains'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Contains",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Contains = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.INSERT_AT,
    mt = 'insert_at'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "InsertAt",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  InsertAt = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.SPLICE_AT,
    mt = 'splice_at'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "SpliceAt",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  SpliceAt = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DELETE_AT,
    mt = 'delete_at'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "DeleteAt",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  DeleteAt = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.CHANGE_AT,
    mt = 'change_at'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "ChangeAt",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ChangeAt = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.CONTAINS,
    mt = 'contains'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Contains",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Contains = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.HAS_FIELDS,
    mt = 'has_fields'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "HasFields",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  HasFields = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.WITH_FIELDS,
    mt = 'with_fields'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "WithFields",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  WithFields = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.KEYS,
    mt = 'keys'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Keys",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Keys = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.CHANGES,
    mt = 'changes'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Changes",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Changes = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.OBJECT,
    mt = 'object'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Object",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Object = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.PLUCK,
    mt = 'pluck'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Pluck",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Pluck = _class_0
end
do
  local _parent_0 = RDBOpWrap
  local _base_0 = {
    tt = protoTermType.INDEXES_OF,
    mt = 'indexes_of'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "IndexesOf",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  IndexesOf = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.WITHOUT,
    mt = 'without'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Without",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Without = _class_0
end
do
  local _parent_0 = RDBOpWrap
  local _base_0 = {
    tt = protoTermType.MERGE,
    mt = 'merge'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Merge",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Merge = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.BETWEEN,
    mt = 'between'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Between",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Between = _class_0
end
do
  local _parent_0 = RDBOpWrap
  local _base_0 = {
    tt = protoTermType.REDUCE,
    mt = 'reduce'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Reduce",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Reduce = _class_0
end
do
  local _parent_0 = RDBOpWrap
  local _base_0 = {
    tt = protoTermType.MAP,
    mt = 'map'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Map",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Map = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.FILTER,
    mt = 'filter'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Filter",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Filter = _class_0
end
do
  local _parent_0 = RDBOpWrap
  local _base_0 = {
    tt = protoTermType.CONCATMAP,
    mt = 'concat_map'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "ConcatMap",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ConcatMap = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.ORDERBY,
    mt = 'order_by'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "OrderBy",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  OrderBy = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DISTINCT,
    mt = 'distinct'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Distinct",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Distinct = _class_0
end
do
  local _parent_0 = RDBOpWrap
  local _base_0 = {
    tt = protoTermType.COUNT,
    mt = 'count'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Count",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Count = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.UNION,
    mt = 'union'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Union",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Union = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.NTH,
    mt = 'nth'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Nth",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Nth = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.MATCH,
    mt = 'match'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Match",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Match = _class_0
end
do
  local _parent_0 = RDBOpWrap
  local _base_0 = {
    tt = protoTermType.SPLIT,
    mt = 'split'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Split",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Split = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.UPCASE,
    mt = 'upcase'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Upcase",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Upcase = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DOWNCASE,
    mt = 'downcase'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Downcase",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Downcase = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.IS_EMPTY,
    mt = 'is_empty'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "IsEmpty",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  IsEmpty = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.GROUP,
    mt = 'group'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Group",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Group = _class_0
end
do
  local _parent_0 = RDBOpWrap
  local _base_0 = {
    tt = protoTermType.SUM,
    mt = 'sum'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Sum",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Sum = _class_0
end
do
  local _parent_0 = RDBOpWrap
  local _base_0 = {
    tt = protoTermType.AVG,
    mt = 'avg'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Avg",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Avg = _class_0
end
do
  local _parent_0 = RDBOpWrap
  local _base_0 = {
    tt = protoTermType.MIN,
    mt = 'min'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Min",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Min = _class_0
end
do
  local _parent_0 = RDBOpWrap
  local _base_0 = {
    tt = protoTermType.MAX,
    mt = 'max'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Max",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Max = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.INNER_JOIN,
    mt = 'inner_join'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "InnerJoin",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  InnerJoin = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.OUTER_JOIN,
    mt = 'outer_join'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "OuterJoin",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  OuterJoin = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.EQ_JOIN,
    mt = 'eq_join'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "EqJoin",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  EqJoin = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.ZIP,
    mt = 'zip'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Zip",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Zip = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.COERCE_TO,
    mt = 'coerce_to'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "CoerceTo",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  CoerceTo = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.UNGROUP,
    mt = 'ungroup'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Ungroup",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Ungroup = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.TYPEOF,
    mt = 'type_of'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "TypeOf",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  TypeOf = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.INFO,
    mt = 'info'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Info",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Info = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.SAMPLE,
    mt = 'sample'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Sample",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Sample = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.UPDATE,
    mt = 'update'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Update",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Update = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DELETE,
    mt = 'delete'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Delete",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Delete = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.REPLACE,
    mt = 'replace'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Replace",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Replace = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.INSERT,
    mt = 'insert'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Insert",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Insert = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DB_CREATE,
    st = 'db_create'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "DbCreate",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  DbCreate = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DB_DROP,
    st = 'db_drop'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "DbDrop",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  DbDrop = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DB_LIST,
    st = 'db_list'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "DbList",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  DbList = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.TABLE_CREATE,
    mt = 'table_create'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "TableCreate",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  TableCreate = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.TABLE_DROP,
    mt = 'table_drop'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "TableDrop",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  TableDrop = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.TABLE_LIST,
    mt = 'table_list'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "TableList",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  TableList = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.INDEX_CREATE,
    mt = 'index_create'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "IndexCreate",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  IndexCreate = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.INDEX_DROP,
    mt = 'index_drop'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "IndexDrop",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  IndexDrop = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.INDEX_RENAME,
    mt = 'index_rename'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "IndexRename",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  IndexRename = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.INDEX_LIST,
    mt = 'index_list'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "IndexList",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  IndexList = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.INDEX_STATUS,
    mt = 'index_status'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "IndexStatus",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  IndexStatus = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.INDEX_WAIT,
    mt = 'index_wait'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "IndexWait",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  IndexWait = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.SYNC,
    mt = 'sync'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Sync",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Sync = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.FUNCALL,
    st = 'do_', -- This is only used by the `nil` argument checker
    compose = function(args)
      if args.length > 2 then
        return {
          'r.do_(',
          intsp((function()
            local _accum_0 = { }
            local _len_0 = 1
            for _index_0 = 2, #args do
              local a = args[_index_0]
              _accum_0[_len_0] = a
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)()),
          ', ',
          args[0],
          ')'
        }
      else
        if shouldWrap(self.args[1]) then
          args[1] = {
            'r(',
            args[1],
            ')'
          }
        end
        return {
          args[1],
          '.do_(',
          args[0],
          ')'
        }
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "FunCall",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  FunCall = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DEFAULT,
    mt = 'default'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Default",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Default = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.BRANCH,
    st = 'branch'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Branch",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Branch = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.ANY,
    mt = 'or_'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Any",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Any = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.ALL,
    mt = 'and_'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "All",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  All = _class_0
end
do
  local _parent_0 = RDBOpWrap
  local _base_0 = {
    tt = protoTermType.FOREACH,
    mt = 'for_each'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "ForEach",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ForEach = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.FUNC,
    compose = function(args)
      if hasImplicit(args[1]) == true then
        return {
          args[1]
        }
      else
        local varStr = ""
        for arg, i in ipairs(args[0][1]) do -- ['0', ', ', '1']
          if i % 2 == 0 then
            varStr = varStr + Var.compose(arg)
          else
            varStr = varStr + arg
          end
        end
        return {
          'function(',
          varStr,
          ') { return ',
          args[1],
          '; }'
        }
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(optargs, func)
      local args = { }
      local argNums = { }
      local i = 0
      while i < func.length do
        argNums.push(Func.nextVarId)
        args.push(Var({ }, Func.nextVarId))
        Func.nextVarId = Func.nextVarId + 1
        i = i + 1
      end
      local body = func(unpack(args))
      if not body then
        error(err.RqlDriverError("Anonymous function returned `nil`. Did you forget a `return`?"))
      end
      local argsArr = MakeArray({ }, unpack(argNums))
      return _parent_0.__init(self, optargs, argsArr, body)
    end,
    __base = _base_0,
    __name = "Func",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.nextVarId = 0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Func = _class_0
end
do
  local _parent_0 = RDBOpWrap
  local _base_0 = {
    tt = protoTermType.ASC,
    st = 'asc'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Asc",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Asc = _class_0
end
do
  local _parent_0 = RDBOpWrap
  local _base_0 = {
    tt = protoTermType.DESC,
    st = 'desc'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Desc",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Desc = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.LITERAL,
    st = 'literal'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Literal",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Literal = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.ISO8601,
    st = 'iso8601'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "ISO8601",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ISO8601 = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.TO_ISO8601,
    mt = 'to_iso8601'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "ToISO8601",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ToISO8601 = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.EPOCH_TIME,
    st = 'epoch_time'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "EpochTime",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  EpochTime = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.TO_EPOCH_TIME,
    mt = 'to_epoch_time'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "ToEpochTime",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ToEpochTime = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.NOW,
    st = 'now'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Now",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Now = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.IN_TIMEZONE,
    mt = 'in_timezone'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "InTimezone",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  InTimezone = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DURING,
    mt = 'during'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "During",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  During = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DATE,
    mt = 'date'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "RQLDate",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  RQLDate = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.TIME_OF_DAY,
    mt = 'time_of_day'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "TimeOfDay",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  TimeOfDay = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.TIMEZONE,
    mt = 'timezone'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Timezone",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Timezone = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.YEAR,
    mt = 'year'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Year",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Year = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.MONTH,
    mt = 'month'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Month",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Month = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DAY,
    mt = 'day'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Day",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Day = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DAY_OF_WEEK,
    mt = 'day_of_week'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "DayOfWeek",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  DayOfWeek = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DAY_OF_YEAR,
    mt = 'day_of_year'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "DayOfYear",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  DayOfYear = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.HOURS,
    mt = 'hours'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Hours",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Hours = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.MINUTES,
    mt = 'minutes'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Minutes",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Minutes = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.SECONDS,
    mt = 'seconds'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Seconds",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Seconds = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.TIME,
    st = 'time'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Time",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Time = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.GEOJSON,
    mt = 'geojson'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "GeoJson",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  GeoJson = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.TO_GEOJSON,
    mt = 'to_geojson'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "ToGeoJson",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ToGeoJson = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.POINT,
    mt = 'point'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Point",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Point = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.LINE,
    mt = 'line'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Line",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Line = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.POLYGON,
    mt = 'polygon'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Polygon",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Polygon = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DISTANCE,
    mt = 'distance'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Distance",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Distance = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.INTERSECTS,
    mt = 'intersects'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Intersects",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Intersects = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.INCLUDES,
    mt = 'includes'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Includes",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Includes = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.CIRCLE,
    mt = 'circle'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Circle",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Circle = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.GET_INTERSECTING,
    mt = 'get_intersecting'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "GetIntersecting",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  GetIntersecting = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.GET_NEAREST,
    mt = 'get_nearest'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "GetNearest",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  GetNearest = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.FILL,
    mt = 'fill'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Fill",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Fill = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.UUID,
    st = 'uuid'
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "UUID",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  UUID = _class_0
end


-- All top level exported functions

-- Wrap a native Lua value in an ReQL datum
function rethinkdb.expr(val, nestingDepth)
  if nestingDepth == nil then
    nestingDepth = 20
  end
  if not (val) then
    error(err.RqlDriverError("Cannot wrap nil with r.expr()."))
  end
  if nestingDepth <= 0 then
    error(err.RqlDriverError("Nesting depth limit exceeded"))
  end
  if type(nestingDepth) ~= "number" or nestingDepth == (1/0) * 0 or nestingDepth == 1/0 or nestingDepth == -1/0 then
    error(err.RqlDriverError("Second argument to `r.expr` must be a number or nil."))
  end
  if TermBase.__class == val then
    return val
  end
  if type(val) == "function" then
    return Func({ }, val)
  end
  if nil then
    return ISO8601({ }, val.toISOString())
  end
  if nil then
    return Binary(val)
  end
  if type(val) == "tree" then
    local t = nil
    for i, v in ipairs(val) do
      if t == "dict" and type(i) == "number" then
        error("")
      end
      if t == "array" and type(i) == "string" then
        error("")
      end
      if not t then
        if type(i) == "number" then
          t = "array"
        else
          if type(i) == "string" then
            t = "dict"
          else
            error("")
          end
        end
      end
    end
    if t == "dict" then
      return MakeObject(val, nestingDepth)
    end
    for i, v in ipairs(val) do
      val[i] = rethinkdb.expr(v, nestingDepth - 1)
    end
    return MakeArray({ }, unpack(val))
  end
  return DatumTerm(val)
end
function rethinkdb.js(jssrc, opts)
  return JavaScript(opts, jssrc)
end
function rethinkdb.http(url, opts)
  return Http(opts, url)
end
function rethinkdb.json(...)
  return Json({ }, unpack(arg))
end
function rethinkdb.error(...)
  return UserError({ }, unpack(arg))
end
function rethinkdb.random(...)
  -- Default if no opts dict provided
  local opts = { }
  local limits = arg

  -- Look for opts dict
  local perhapsOptDict = arg[arg.n - 1]
  if perhapsOptDict and ((type(perhapsOptDict) == 'tree') and not (isinstance(TermBase, perhapsOptDict))) then
    opts = perhapsOptDict
    do
      local _accum_0 = { }
      local _len_0 = 1
      local _list_0 = arg
      local _max_0 = (arg.n - 1)
      for _index_0 = 1, _max_0 < 0 and #_list_0 + _max_0 or _max_0 do
        local a = _list_0[_index_0]
        _accum_0[_len_0] = a
        _len_0 = _len_0 + 1
      end
      limits = _accum_0
    end
  end
  return Random(opts, unpack(limits))
end
function rethinkdb.binary(data)
  return Binary(data)
end
rethinkdb.row = ImplicitVar({ })
function rethinkdb.table(tblName, opts)
  return Table(opts, tblName)
end
function rethinkdb.db(...)
  return Db({ }, unpack(arg))
end
function rethinkdb.db_create(...)
  return DbCreate({ }, unpack(arg))
end
function rethinkdb.db_drop(...)
  return DbDrop({ }, unpack(arg))
end
function rethinkdb.db_list(...)
  return DbList({ }, unpack(arg))
end
function rethinkdb.table_create(tblName, opts)
  return TableCreate(opts, tblName)
end
function rethinkdb.table_drop(...)
  return TableDrop({ }, unpack(arg))
end
function rethinkdb.table_list(...)
  return TableList({ }, unpack(arg))
end
function rethinkdb.do_(...)
  return FunCall({ }, funcWrap(arg[arg.n]), unpack((function()
    local _accum_0 = { }
    local _len_0 = 1
    local _list_0 = arg
    local _max_0 = (arg.n - 1)
    for _index_0 = 1, _max_0 < 0 and #_list_0 + _max_0 or _max_0 do
      local a = _list_0[_index_0]
      _accum_0[_len_0] = a
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)()))
end
function rethinkdb.branch(...)
  return Branch({ }, unpack(arg))
end
function rethinkdb.asc(...)
  return Asc({ }, unpack(arg))
end
function rethinkdb.desc(...)
  return Desc({ }, unpack(arg))
end
function rethinkdb.eq(...)
  return Eq({ }, unpack(arg))
end
function rethinkdb.ne(...)
  return Ne({ }, unpack(arg))
end
function rethinkdb.lt(...)
  return Lt({ }, unpack(arg))
end
function rethinkdb.le(...)
  return Le({ }, unpack(arg))
end
function rethinkdb.gt(...)
  return Gt({ }, unpack(arg))
end
function rethinkdb.ge(...)
  return Ge({ }, unpack(arg))
end
function rethinkdb.or_(...)
  return Any({ }, unpack(arg))
end
function rethinkdb.any(...)
  return Any({ }, unpack(arg))
end
function rethinkdb.and_(...)
  return All({ }, unpack(arg))
end
function rethinkdb.all(...)
  return All({ }, unpack(arg))
end
function rethinkdb.not_(...)
  return Not({ }, unpack(arg))
end
function rethinkdb.add(...)
  return Add({ }, unpack(arg))
end
function rethinkdb.sub(...)
  return Sub({ }, unpack(arg))
end
function rethinkdb.div(...)
  return Div({ }, unpack(arg))
end
function rethinkdb.mul(...)
  return Mul({ }, unpack(arg))
end
function rethinkdb.mod(...)
  return Mod({ }, unpack(arg))
end
function rethinkdb.type_of(...)
  return TypeOf({ }, unpack(arg))
end
function rethinkdb.info(...)
  return Info({ }, unpack(arg))
end
function rethinkdb.literal(...)
  return Literal({ }, unpack(arg))
end
function rethinkdb.iso8601(str, opts)
  return ISO8601(opts, str)
end
function rethinkdb.epoch_time(...)
  return EpochTime({ }, unpack(arg))
end
function rethinkdb.now(...)
  return Now({ }, unpack(arg))
end
function rethinkdb.time(...)
  return Time({ }, unpack(arg))
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.MONDAY
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Monday",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Monday = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.TUESDAY
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Tuesday",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Tuesday = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.WEDNESDAY
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Wednesday",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Wednesday = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.THURSDAY
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Thursday",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Thursday = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.FRIDAY
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Friday",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Friday = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.SATURDAY
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Saturday",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Saturday = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.SUNDAY
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Sunday",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Sunday = _class_0
end
rethinkdb.monday = Monday()
rethinkdb.tuesday = Tuesday()
rethinkdb.wednesday = Wednesday()
rethinkdb.thursday = Thursday()
rethinkdb.friday = Friday()
rethinkdb.saturday = Saturday()
rethinkdb.sunday = Sunday()
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.JANUARY
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "January",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  January = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.FEBRUARY
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "February",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  February = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.MARCH
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "March",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  March = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.APRIL
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "April",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  April = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.MAY
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "May",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  May = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.JUNE
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "June",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  June = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.JULY
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "July",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  July = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.AUGUST
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "August",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  August = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.SEPTEMBER
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "September",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  September = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.OCTOBER
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "October",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  October = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.NOVEMBER
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "November",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  November = _class_0
end
do
  local _parent_0 = RDBOp
  local _base_0 = {
    tt = protoTermType.DECEMBER
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "December",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  December = _class_0
end
rethinkdb.january = January()
rethinkdb.february = February()
rethinkdb.march = March()
rethinkdb.april = April()
rethinkdb.may = May()
rethinkdb.june = June()
rethinkdb.july = July()
rethinkdb.august = August()
rethinkdb.september = September()
rethinkdb.october = October()
rethinkdb.november = November()
rethinkdb.december = December()
function rethinkdb.object(...)
  return Object({ }, unpack(arg))
end
function rethinkdb.args(...)
  return Args({ }, unpack(arg))
end
function rethinkdb.geojson(...)
  return GeoJson({ }, unpack(arg))
end
function rethinkdb.point(...)
  return Point({ }, unpack(arg))
end
function rethinkdb.line(...)
  return Line({ }, unpack(arg))
end
function rethinkdb.polygon(...)
  return Polygon({ }, unpack(arg))
end
function rethinkdb.intersects(...)
  return Intersects({ }, unpack(arg))
end
function rethinkdb.distance(g1, g2, opts)
  return Distance(opts, g1, g2)
end
function rethinkdb.circle(cen, rad, opts)
  return Circle(opts, cen, rad)
end
function rethinkdb.uuid(...)
  return UUID({ }, unpack(arg))
end

-- Export all names defined on rethinkdb
return rethinkdb
