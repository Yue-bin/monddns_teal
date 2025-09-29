#!/usr/bin/env lua

-- monddns.lua

function is_rel_path(path)
    return not string.match(path, "^/")
end

-- 提供相对require的能力
PATH = string.match(arg[0], "^(.+)/[^/]+$") .. "/"
-- 判断是否为绝对路径
if is_rel_path(PATH) then
    PATH = os.getenv("PWD") .. "/" .. PATH
end
package.path = ('%s?.lua;%s'):format(PATH .. "mods/", package.path)

local log = require("log")
local dnsrecord = require("dnsrecord")
local json = require("cjson")
local getip = require("getip")
local socket = require("socket")
local dns = socket.dns

-- Parse Configuration
local conf = require("confloader").load_conf("monddns", arg)
if conf == nil then
    print("Failed to load configuration")
    os.exit(1)
end
local log_path = conf.log.path
if is_rel_path(log_path) then
    log_path = PATH .. log_path
end
local log_file = io.open(log_path, "a")
local g_log = log.init(log_file)
g_log:setlevel(conf.log.level or "INFO")

-- 服务商实例工厂，根据给定的provider返回对应的实例
-- 要求每个provider的实例都有get_zone_id, get_dns_records, delete_dns_record, create_dns_record方法
-- 且这些方法的参数和返回值都是一致的
-- 不存在zoneid概念的服务商固定返回"none"
local processer = {
}
-- cloudflare
function processer.cloudflare(config)
    -- 初始化
    local cf = require("cloudflare")
    local cf_ins, cf_err = cf.new {
        auth = {
            api_token = config.auth.api_token,
            email = config.auth.email,
            api_key = config.auth.api_key,
        },
        log = g_log,
    }
    if cf_ins == nil then
        g_log:log(("Failed to initialize %s instance for %s: %s"):format("cloudflare", config.name, cf_err), "ERROR")
        return nil
    end
    return cf_ins
end

--namesilo
function processer.namesilo(config)
    -- 初始化
    local ns = require("namesilo")
    local ns_ins, ns_err = ns.new {
        auth = {
            apikey = config.auth.apikey,
        },
        log = g_log,
    }
    if ns_ins == nil then
        g_log:log(("Failed to initialize %s instance for %s: %s"):format("namesilo", config.name, ns_err), "ERROR")
        return nil
    end
    return ns_ins
end

--aliyun
function processer.aliyun(config)
    -- 初始化
    local ali = require("aliyun")
    local ali_ins, ali_err = ali.new {
        auth = {
            ak_id = config.auth.ak_id,
            ak_secret = config.auth.ak_secret,
        },
        log = g_log,
    }
    if ali_ins == nil then
        g_log:log(("Failed to initialize %s instance for %s: %s"):format("aliyun", config.name, ali_err), "ERROR")
        return nil
    end
    return ali_ins
end

-- 从主循环拆出来的子函数，用于避免goto
-- 获取新记录列表
local function get_new_rl(config, sub, ip_setting, new_recordlist)
    local ip_list, code, err = getip(ip_setting.method, ip_setting.content)
    if ip_list == nil then
        g_log:log(
            "Failed to get IP for " .. config.name .. " " .. sub.sub_domain .. " with code " .. code ..
            " error " .. err, "ERROR")
        return
    end

    -- 使用socket.dns严格验证IP地址
    local valid_ips = {}
    for _, ip in ipairs(ip_list) do
        local result, resolve_err = dns.getaddrinfo(ip)
        if result then
            local is_valid = false
            for _, addr in ipairs(result) do
                if addr.family == "inet" or addr.family == "inet6" then
                    is_valid = true
                    break
                end
            end
            if is_valid then
                table.insert(valid_ips, ip)
            else
                g_log:log(("Invalid IP format: %s"):format(ip), "WARN")
            end
        else
            g_log:log(("DNS resolution failed for %s: %s"):format(ip, resolve_err), "WARN")
        end
    end
    ip_list = valid_ips
    if #ip_list == 0 then
        g_log:log("No valid IP addresses found after verification", "ERROR")
        return
    end
    g_log:log(("Acquired %d IPs via %s method"):format(#ip_list, ip_setting.method), "DEBUG")
    if #ip_list ~= 0 then
        g_log:log("those IPs are " .. table.concat(ip_list, ", "), "DEBUG")
    end
    for _, ip in ipairs(ip_list) do
        new_recordlist = new_recordlist .. dnsrecord.new_dnsrecord {
            rr = sub.sub_domain,
            domain = config.domain,
            type = ip_setting.type,
            value = ip,
            ttl = sub.ttl or conf.default_ttl or 600
        }
    end
end

-- 用于处理每一个子域名
local function processe_sub(config, ps_ins, zone_id, sub)
    g_log:log("Processing sub domain " .. sub.sub_domain, "INFO")
    -- 获取现有的dns记录
    -- 带指数退避的重试机制（使用socket.sleep）
    local max_retries = 3
    local base_delay = 1.0
    local recordlist, code, err

    for attempt = 1, max_retries do
        recordlist, code, err = ps_ins.get_dns_records(sub.sub_domain, config.domain, zone_id)
        if recordlist then break end
        local delay = base_delay * (2 ^ (attempt - 1))
        g_log:log(
            ("try to get dns records %d/%d failed, retrying in %.1f secs : %s"):format(attempt, max_retries, delay, err),
            "WARN")
        socket.sleep(delay) -- 使用socket.sleep替代os.execute
    end

    if not recordlist then
        g_log:log(
            "Failed to get dns records for " ..
            config.name .. " " .. sub.sub_domain .. ": " .. code .. " " .. err,
            "ERROR")
        return
    end
    g_log:log("Got dns record with lenth " .. #recordlist, "INFO")
    if #recordlist ~= 0 then
        g_log:log("those dns records are " .. json.encode(recordlist), "DEBUG")
    end

    -- 获取新的dns记录
    local new_recordlist = dnsrecord.new_recordlist()
    for _, ip_setting in ipairs(sub.ip_list) do
        get_new_rl(config, sub, ip_setting, new_recordlist)
    end

    -- 比较现有的dns记录和新的dns记录
    local to_delete = recordlist - new_recordlist
    local to_add = new_recordlist - recordlist
    g_log:log(#to_delete .. " records to delete", "INFO")
    g_log:log("To delete: " .. json.encode(to_delete), "DEBUG")
    g_log:log(#to_add .. " records to add", "INFO")
    g_log:log("To add: " .. json.encode(to_add), "DEBUG")

    -- 删除多余的dns记录
    ps_ins.delete_dns_record(to_delete, zone_id)

    -- 添加新的dns记录
    ps_ins.create_dns_record(to_add, zone_id)
end

-- 处理配置文件中的每一个配置
local function processe_conf(config)
    g_log:log("Processing conf " .. config.name, "INFO")
    if processer[config.provider] then
        local ps_ins = processer[config.provider](config)
        if ps_ins == nil then
            g_log:log("Failed to initialize instance for " .. config.name, "ERROR")
            return
        end

        -- 获取zone_id
        local zone_id, code, err = ps_ins.get_zone_id(config.domain)
        if zone_id == nil then
            g_log:log("Failed to get zone_id for " .. config.name .. ": " .. code .. " " .. err, "ERROR")
            return
        end

        -- 处理配置中每一个子域名
        for _, sub in ipairs(config.subs) do
            processe_sub(config, ps_ins, zone_id, sub)
        end
    else
        g_log:log("Unknown provider " .. config.provider, "ERROR")
    end
end


-- Main Loop
-- 遍历配置文件中每一个配置
g_log:log("Start processing", "INFO")
for _, config in ipairs(conf.confs) do
    processe_conf(config)
end
g_log:log("End processing", "INFO")
-- 确保关闭日志文件
if log_file then
    log_file:close()
end
