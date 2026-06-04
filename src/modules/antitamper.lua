local config = require("config")

local AntiTamper = {}

-- Collect critical native function names that should NOT be tampered
-- Excludes print, as it's commonly overridden for logging/testing
-- Luau doesn't have: loadfile, dofile, collectgarbage, debug.*, string.dump
local NATIVE_FUNCS_LUA = {
    -- Core
    "assert", "error", "pcall", "xpcall", "type", "tostring", "tonumber",
    "select", "next", "rawget", "rawset", "rawequal", "setmetatable", "getmetatable",
    "load", "loadfile", "dofile", "collectgarbage",
    -- String
    "string.byte", "string.char", "string.dump", "string.find", "string.format",
    "string.gmatch", "string.gsub", "string.len", "string.lower", "string.match",
    "string.rep", "string.reverse", "string.sub", "string.upper",
    -- Table
    "table.insert", "table.remove", "table.sort", "table.concat",
    -- Math
    "math.abs", "math.acos", "math.asin", "math.atan", "math.ceil", "math.cos",
    "math.deg", "math.exp", "math.floor", "math.fmod", "math.max", "math.min",
    "math.modf", "math.rad", "math.sin", "math.sqrt", "math.tan",
    -- OS
    "os.clock", "os.date", "os.difftime", "os.time", "os.exit",
    -- Debug
    "debug.getinfo", "debug.getlocal", "debug.getupvalue", "debug.traceback",
    "debug.sethook", "debug.setupvalue",
}

local NATIVE_FUNCS_LUAU = {
    -- Core (Luau lacks loadfile, dofile, collectgarbage, debug)
    "assert", "error", "pcall", "xpcall", "type", "tostring", "tonumber",
    "select", "next", "rawget", "rawset", "rawequal", "setmetatable", "getmetatable",
    "loadstring",
    -- String (Luau lacks string.dump)
    "string.byte", "string.char", "string.find", "string.format",
    "string.gmatch", "string.gsub", "string.len", "string.lower", "string.match",
    "string.rep", "string.reverse", "string.sub", "string.upper",
    -- Table
    "table.insert", "table.remove", "table.sort", "table.concat",
    -- Math
    "math.abs", "math.acos", "math.asin", "math.atan", "math.ceil", "math.cos",
    "math.deg", "math.exp", "math.floor", "math.fmod", "math.max", "math.min",
    "math.modf", "math.rad", "math.sin", "math.sqrt", "math.tan",
    -- OS (Luau lacks os.exit)
    "os.clock", "os.date", "os.difftime", "os.time",
}

local NATIVE_FUNCS_GLUA = {
    -- GMod runs a sandboxed Lua 5.1 environment and does not expose every
    -- standard Lua function available while Hercules itself is running.
    "assert", "error", "pcall", "xpcall", "type", "tostring", "tonumber",
    "select", "next", "rawget", "rawset", "rawequal", "setmetatable", "getmetatable",
    "loadstring",
    "string.byte", "string.char", "string.find", "string.format",
    "string.gmatch", "string.gsub", "string.len", "string.lower", "string.match",
    "string.rep", "string.reverse", "string.sub", "string.upper",
    "table.insert", "table.remove", "table.sort", "table.concat",
    "math.abs", "math.acos", "math.asin", "math.atan", "math.ceil", "math.cos",
    "math.deg", "math.exp", "math.floor", "math.fmod", "math.max", "math.min",
    "math.modf", "math.rad", "math.sin", "math.sqrt", "math.tan",
    "os.clock", "os.date", "os.difftime", "os.time",
    "debug.getinfo", "debug.traceback",
}

-- Check if a metamethod is set (potential tampering via __index/__newindex)
local META_METHODS = {"__index", "__newindex", "__metatable", "__call"}
local META_TABLES = {"string", "table", "math", "os"}

function AntiTamper.process(code)
    local NATIVE_FUNCS = NATIVE_FUNCS_LUA
    local debug_keys = '{"getinfo","getlocal","getupvalue","traceback","sethook","setupvalue"}'
    if config.target == "luau" then
        NATIVE_FUNCS = NATIVE_FUNCS_LUAU
        debug_keys = '{"info","traceback"}'
    elseif config.target == "glua" then
        NATIVE_FUNCS = NATIVE_FUNCS_GLUA
        debug_keys = '{"getinfo","traceback"}'
    end

    -- Capture the current state of critical functions as the baseline
    local func_refs = {}
    for _, name in ipairs(NATIVE_FUNCS) do
        -- Resolve nested names like "string.byte"
        local parts = {}
        for part in name:gmatch("[^.]+") do
            table.insert(parts, part)
        end
        local obj = _G
        for i = 1, #parts - 1 do
            obj = obj[parts[i]]
            if not obj then break end
        end
        local val = obj and obj[parts[#parts]]
        if val then
            func_refs[name] = true
        end
    end

    -- Capture metatable state for key tables
    local meta_refs = {}
    for _, tname in ipairs(META_TABLES) do
        local t = _G[tname]
        if t then
            local mt = getmetatable(t)
            if mt then
                for _, mm in ipairs(META_METHODS) do
                    local mf = rawget(mt, mm)
                    if mf then
                        meta_refs[tname .. "." .. mm] = type(mf)
                    end
                end
            end
        end
    end

    -- Serialize func_refs into the generated code
    local func_refs_str = "{"
    local count = 0
    for name in pairs(func_refs) do
        if count > 0 then func_refs_str = func_refs_str .. "," end
        func_refs_str = func_refs_str .. string.format("[%q]=%s", name, name)
        count = count + 1
    end
    func_refs_str = func_refs_str .. "}"

    -- Serialize meta_refs
    local meta_refs_str = "{"
    count = 0
    for name, ref_type in pairs(meta_refs) do
        if count > 0 then meta_refs_str = meta_refs_str .. "," end
        meta_refs_str = meta_refs_str .. string.format("[%q]=%q", name, ref_type)
        count = count + 1
    end
    meta_refs_str = meta_refs_str .. "}"

    local anti_tamper_code = string.format([=[
do
    local _BFR,_MFR,T,E,Pa,GM,RG=%s,%s,type,error,pairs,getmetatable,rawget
    local DG={table=table,string=string,math=math,os=os}
    local function check()
        for n,ref in Pa(_BFR) do
            if ref==nil then
                E("Tamper Detected! Reason: Critical function removed: "..n)
                return
            end
            if T(ref)~="function" then
                E("Tamper Detected! Reason: Critical function type changed: "..n.." (was function, now "..T(ref)..")")
                return
            end
        end
        for tname in Pa(_MFR) do
            local parts={}
            for p in tname:gmatch("[^.]+") do parts[#parts+1]=p end
            local t=DG[(parts[1])]
            if t then
                local mt=GM(t)
                if mt then
                    local mf=RG(mt,parts[2])
                    if mf then
                        local expected=_MFR[tname]
                        if T(mf)~=expected then
                            E("Tamper Detected! Reason: Metamethod tampered: "..tname)
                            return
                        end
                    end
                end
            end
        end
        local d=debug
        if T(d)=="table" then
            local _DK=%s
            for _,k in Pa(_DK) do
                if T(d[k])~="function" then
                    E("Tamper Detected! Reason: Debug library incomplete")
                    return
                end
            end
        end
    end
    check()
end
]=], func_refs_str, meta_refs_str, debug_keys)

    return anti_tamper_code .. "\n" .. code
end

return AntiTamper
