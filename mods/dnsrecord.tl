--[[
    此处定义dnsrecord类型和recordlist类型
--]]

-- dnsrecord类型
global record DnsRecord
    id: string
    rr: string
    domain: string
    type: string
    value: string
    ttl: integer
    metamethod __index: function(self: DnsRecord, key: string): any
    metamethod __eq: function(dr1: DnsRecord, dr2: DnsRecord): boolean
end
-- 默认值
local dnsrecord: DnsRecord = {
    id = "",     -- 1234567890qwertyuiop
    rr = "",     -- web
    domain = "", -- example.com
    type = "",   -- A
    value = "",  -- 1.2.3.4
    ttl = 1,     -- 1
}

-- dnsrecord判断相等,使用==
local function dnsrecord_equal(dr1: DnsRecord, dr2: DnsRecord): boolean
    return dr1.rr == dr2.rr 
        and dr1.domain == dr2.domain 
        and dr1.type == dr2.type 
        and dr1.value == dr2.value
end

local dnsrecord_mt = {
    __index = dnsrecord,
    __eq = dnsrecord_equal,
}
setmetatable(dnsrecord, dnsrecord_mt)

local function new_dr(dr: DnsRecord): DnsRecord
    local new_dr_obj: DnsRecord = {
        id = dr.id or "",
        rr = dr.rr or "",
        domain = dr.domain or "",
        type = dr.type or "",
        value = dr.value or "",
        ttl = dr.ttl or 1
    }
    setmetatable(new_dr_obj, dnsrecord_mt)
    return new_dr_obj
end


-- recordlist类型
--global type RecordList = {DnsRecord}
global record RecordList
    {DnsRecord}
    metamethod __index: function(self: RecordList, key: string|integer): any
    metamethod __eq: function(rl1: RecordList, rl2: RecordList): boolean
    metamethod __lt: function(rl: RecordList, dr: DnsRecord): boolean
    metamethod __concat: function(rl: RecordList, dr: DnsRecord): RecordList
    metamethod __sub: function(rl1: RecordList, rl2: RecordList): RecordList
    metamethod __add: function(rl1: RecordList, rl2: RecordList): RecordList
end
-- 默认值
local recordlist: RecordList = {}

-- recordlist判断相等,使用==
local function recordlist_equal(rl1: RecordList, rl2: RecordList): boolean
    if #rl1 ~= #rl2 then
        return false
    end
    for i = 1, #rl1 do
        if not (rl1[i] == rl2[i]) then
            return false
        end
    end
    return true
end

-- recordlist判断是否包含某个dnsrecord, 使用<
local function recordlist_contains(rl: RecordList, dr: DnsRecord): boolean
    for i = 1, #rl do
        if dnsrecord_equal(rl[i], dr) then
            return true
        end
    end
    return false
end

-- 考虑到我在实际使用中, 需要的最多的操作是
--  1.从空列表开始往recordlist中添加元素(获取dns记录等)
--  2.合并两个recordlist(多个不同来源的dns记录)
--  3.比较两个recordlist的差异(更新dns记录)
-- 实际上, 我并不需要对recordlist进行删除单个元素的操作

-- recordlist添加一个dnsrecord, 使用..
local function recordlist_add_element(rl: RecordList, dr: DnsRecord): RecordList
    local result = rl
    if not recordlist_contains(rl, dr) then
        result[#result + 1] = dr
    end
    return result
end

-- recordlist相减, 从rl1中删去所有出现在rl2中的项, 使用-
local function recordlist_sub(rl1: RecordList, rl2: RecordList): RecordList
    local result = {}
    for i = 1, #rl1 do
        if not recordlist_contains(rl2, rl1[i]) then
            result[#result + 1] = rl1[i]
        end
    end
    return result
end

-- recordlist合并, 重复项仅保留一个, 使用+
local function recordlist_merge(rl1: RecordList, rl2: RecordList): RecordList
    local result = {}
    for i = 1, #rl1 do
        result[#result + 1] = rl1[i]
    end
    for i = 1, #rl2 do
        if not recordlist_contains(result, rl2[i]) then
            result[#result + 1] = rl2[i]
        end
    end
    return result
end


-- 限定recordlist为dnsrecord类型的列表
local recordlist_mt = {
    __index = recordlist,
    __eq = recordlist_equal,
    __lt = recordlist_contains,
    __concat = recordlist_add_element,
    __sub = recordlist_sub,
    __add = recordlist_merge,
}
setmetatable(recordlist, recordlist_mt)

local function new_rl(): RecordList
    local new_rl_obj = {}
    setmetatable(new_rl_obj, recordlist_mt)
    return new_rl_obj
end



-- 暴露dnsrecord和recordlist
return {
    new_dnsrecord = new_dr,
    new_recordlist = new_rl,
}
