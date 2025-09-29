-- 定义一个 record 类型，名为 Logger，用来描述 _M 的结构
local record logger
    -- 定义日志级别常量
    -- 这里我们使用 string 类型，也可以使用枚举（enum）如果可能的值是固定的
    record loglevels
        TRACE: number
        DEBUG: number
        INFO: number
        WARN: number
        ERROR: number
        FATAL: number
    end
    -- 模块的字段类型
    LOG_LEVEL: string
    record writable_stream
        write: function(self: writable_stream, ...: any)
    end
    outputstream: writable_stream
    -- 模块的方法类型
    setlevel: function(self: logger, level: string)
    log: function(self: logger, msg: string, level: string)
end
local _M = {}

-- 日志相关
-- 搬了一点monlog
local loglevels = {
    TRACE = -1,
    DEBUG = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3,
    FATAL = 4
}

-- 默认日志级别
_M.LOG_LEVEL = "INFO"
-- LOG_LEVEL = "DEBUG"

-- 日志输出流
-- 未初始化无法使用
_M.outputstream = nil

-- 设置日志级别
function _M:setlevel(level)
    level = string.upper(level)
    if loglevels[level] ~= nil then
        _M.LOG_LEVEL = level
    else
        error("log level \"" .. level .. "\" is invalid")
    end
end

-- 输出日志
-- outputstream默认为stderr
-- level默认为INFO
function _M:log(msg, level)
    level = level or "INFO"
    if loglevels[level] >= loglevels[_M.LOG_LEVEL] then
        -- 使用outputstream输出日志
        self.outputstream:write(os.date("%Y.%m.%d-%H:%M:%S"), " [", level, "] ", msg, "\n")
    end
end

-- 初始化
local function init(stream)
    _M.outputstream = stream or io.stderr
    return _M
end

return {
    init = init,
}
