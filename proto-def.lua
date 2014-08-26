return {
  Version = {
    V0_1 = 1063369270,
    V0_2 = 1915781601,
    V0_3 = 1601562686
  },
  Protocol = {
    PROTOBUF = 656407617,
    JSON = 2120839367
  },
  QueryType = {
    START = 1,
    CONTINUE = 2,
    STOP = 3,
    NOREPLY_WAIT = 4
  },
  FrameType = {
    POS = 1,
    OPT = 2
  },
  ResponseType = {
    SUCCESS_ATOM = 1,
    SUCCESS_SEQUENCE = 2,
    SUCCESS_PARTIAL = 3,
    SUCCESS_FEED = 5,
    WAIT_COMPLETE = 4,
    CLIENT_ERROR = 16,
    COMPILE_ERROR = 17,
    RUNTIME_ERROR = 18
  },
  DatumType = {
    R_NULL = 1,
    R_BOOL = 2,
    R_NUM = 3,
    R_STR = 4,
    R_ARRAY = 5,
    R_OBJECT = 6,
    R_JSON = 7
  },
  TermType = {
    DATUM = 1,
    MAKE_ARRAY = 2,
    MAKE_OBJ = 3,
    VAR = 10,
    JAVASCRIPT = 11,
    HTTP = 153,
    ERROR = 12,
    IMPLICIT_VAR = 13,
    DB = 14,
    TABLE = 15,
    GET = 16,
    GET_ALL = 78,
    EQ = 17,
    NE = 18,
    LT = 19,
    LE = 20,
    GT = 21,
    GE = 22,
    NOT = 23,
    ADD = 24,
    SUB = 25,
    MUL = 26,
    DIV = 27,
    MOD = 28,
    APPEND = 29,
    PREPEND = 80,
    DIFFERENCE = 95,
    SET_INSERT = 88,
    SET_INTERSECTION = 89,
    SET_UNION = 90,
    SET_DIFFERENCE = 91,
    SLICE = 30,
    SKIP = 70,
    LIMIT = 71,
    INDEXES_OF = 87,
    CONTAINS = 93,
    GET_FIELD = 31,
    KEYS = 94,
    OBJECT = 143,
    HAS_FIELDS = 32,
    WITH_FIELDS = 96,
    PLUCK = 33,
    WITHOUT = 34,
    MERGE = 35,
    BETWEEN = 36,
    REDUCE = 37,
    MAP = 38,
    FILTER = 39,
    CONCATMAP = 40,
    ORDERBY = 41,
    DISTINCT = 42,
    COUNT = 43,
    IS_EMPTY = 86,
    UNION = 44,
    NTH = 45,
    INNER_JOIN = 48,
    OUTER_JOIN = 49,
    EQ_JOIN = 50,
    ZIP = 72,
    INSERT_AT = 82,
    DELETE_AT = 83,
    CHANGE_AT = 84,
    SPLICE_AT = 85,
    COERCE_TO = 51,
    TYPEOF = 52,
    UPDATE = 53,
    DELETE = 54,
    REPLACE = 55,
    INSERT = 56,
    DB_CREATE = 57,
    DB_DROP = 58,
    DB_LIST = 59,
    TABLE_CREATE = 60,
    TABLE_DROP = 61,
    TABLE_LIST = 62,
    SYNC = 138,
    INDEX_CREATE = 75,
    INDEX_DROP = 76,
    INDEX_LIST = 77,
    INDEX_STATUS = 139,
    INDEX_WAIT = 140,
    INDEX_RENAME = 156,
    FUNCALL = 64,
    BRANCH = 65,
    ANY = 66,
    ALL = 67,
    FOREACH = 68,
    FUNC = 69,
    ASC = 73,
    DESC = 74,
    INFO = 79,
    MATCH = 97,
    UPCASE = 141,
    DOWNCASE = 142,
    SAMPLE = 81,
    DEFAULT = 92,
    JSON = 98,
    ISO8601 = 99,
    TO_ISO8601 = 100,
    EPOCH_TIME = 101,
    TO_EPOCH_TIME = 102,
    NOW = 103,
    IN_TIMEZONE = 104,
    DURING = 105,
    DATE = 106,
    TIME_OF_DAY = 126,
    TIMEZONE = 127,
    YEAR = 128,
    MONTH = 129,
    DAY = 130,
    DAY_OF_WEEK = 131,
    DAY_OF_YEAR = 132,
    HOURS = 133,
    MINUTES = 134,
    SECONDS = 135,
    TIME = 136,
    MONDAY = 107,
    TUESDAY = 108,
    WEDNESDAY = 109,
    THURSDAY = 110,
    FRIDAY = 111,
    SATURDAY = 112,
    SUNDAY = 113,
    JANUARY = 114,
    FEBRUARY = 115,
    MARCH = 116,
    APRIL = 117,
    MAY = 118,
    JUNE = 119,
    JULY = 120,
    AUGUST = 121,
    SEPTEMBER = 122,
    OCTOBER = 123,
    NOVEMBER = 124,
    DECEMBER = 125,
    LITERAL = 137,
    GROUP = 144,
    SUM = 145,
    AVG = 146,
    MIN = 147,
    MAX = 148,
    SPLIT = 149,
    UNGROUP = 150,
    RANDOM = 151,
    CHANGES = 152,
    ARGS = 154,
    BINARY = 155
  }
}
