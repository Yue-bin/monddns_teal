-- 定义一个 record 类型，名为 Logger，用来描述 _M 的结构
local record logger
    
    enum log_levels
    "TRACE"
    "DEBUG"
    "INFO"
    "WARN"
    "ERROR"
    "FATAL"
end
    -- 模块的字段类型
    LOG_LEVEL: log_levels
    record writable_stream
        write: function(self: writable_stream, ...: any)
    end
    outputstream: writable_stream
    -- 模块的方法类型
    setlevel: function(self: logger, level: log_levels)
    log: function(self: logger, msg: string, level: log_levels|nil)
end
local _M : logger = {}

-- 日志相关
-- 搬了一点monlog

local loglevels :{logger.log_levels:number} = {
    TRACE = 1,
    DEBUG = 2,
    INFO  = 3,
    WARN  = 4,
    ERROR = 5,
    FATAL = 6,
}

-- 默认日志级别
_M.LOG_LEVEL = "INFO"
-- LOG_LEVEL = "DEBUG"

-- 日志输出流
-- 未初始化无法使用
_M.outputstream = nil

-- 设置日志级别
function _M:setlevel(level : logger.log_levels)
    if loglevels[level] ~= nil then
        _M.LOG_LEVEL = level
    else
        error("log level \"" .. level .. "\" is invalid")
    end
end

-- 输出日志
-- outputstream默认为stderr
-- level默认为INFO
function _M:log(msg : string, level : logger.log_levels|nil)
    level = level or ("INFO" as logger.log_levels|nil)
    if loglevels[level] >= loglevels[_M.LOG_LEVEL] then
        -- 使用outputstream输出日志
        self.outputstream:write(os.date("%Y.%m.%d-%H:%M:%S"), " [", level, "] ", msg, "\n")
    end
end

-- 初始化
local function init(stream : logger.writable_stream|nil) : logger
    _M.outputstream = stream or (io.stderr as logger.writable_stream)
    return _M
end

return {
    init = init,
}
