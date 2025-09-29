-- 定义一个 record 类型，名为 Logger，用来描述 _M 的结构
local record Logger
    
    enum LogLevels
    "TRACE"
    "DEBUG"
    "INFO"
    "WARN"
    "ERROR"
    "FATAL"
end
    -- 模块的字段类型
    LOG_LEVEL: LogLevels
    record WritableStream
        write: function(self: WritableStream, ...: any)
    end
    outputstream: WritableStream
    -- 模块的方法类型
    setlevel: function(self: Logger, level: LogLevels)
    log: function(self: Logger, msg: string, level: LogLevels|nil)
end
local _M : Logger = {}

-- 日志相关
-- 搬了一点monlog

local loglevels :{Logger.LogLevels:number} = {
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
function _M:setlevel(level : Logger.LogLevels)
    if loglevels[level] ~= nil then
        _M.LOG_LEVEL = level
    else
        error("log level \"" .. level .. "\" is invalid")
    end
end

-- 输出日志
-- outputstream默认为stderr
-- level默认为INFO
function _M:log(msg : string, level : Logger.LogLevels|nil)
    level = level or ("INFO" as Logger.LogLevels|nil)
    if loglevels[level] >= loglevels[_M.LOG_LEVEL] then
        -- 使用outputstream输出日志
        self.outputstream:write(os.date("%Y.%m.%d-%H:%M:%S"), " [", level, "] ", msg, "\n")
    end
end

-- 初始化
local function init(stream : Logger.WritableStream|nil) : Logger
    _M.outputstream = stream or (io.stderr as Logger.WritableStream)
    return _M
end

return {
    init = init,
}
