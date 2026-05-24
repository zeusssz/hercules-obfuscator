#!/usr/bin/env lua

package.path = "./src/?.lua;./src/?/init.lua;./tests/?.lua;./tests/?/init.lua;" .. package.path

if not math.ldexp then
    math.ldexp = function(x, n) return x * 2 ^ n end
end
if not math.frexp then
    math.frexp = function(x)
        if x == 0 then return 0, 0 end
        local exp = math.floor(math.log(math.abs(x)) / math.log(2)) + 1
        local mantissa = x / 2 ^ exp
        return mantissa, exp
    end
end

local config = require("config")
local Pipeline = require("pipeline")
local fixtures = require("test_fixtures")

local ALL_MODULES = {
    "VirtualMachine",
    "antitamper",
    "control_flow",
    "StringToExpressions",
    "string_encoding",
    "WrapInFunction",
    "variable_renaming",
    "garbage_code",
    "opaque_predicates",
    "function_inlining",
    "dynamic_code",
    "bytecode_encoding",
    "compressor",
    "watermark",
}

local MODULE_PATHS = {
    VirtualMachine      = "settings.VirtualMachine.enabled",
    antitamper          = "settings.antitamper.enabled",
    control_flow        = "settings.control_flow.enabled",
    StringToExpressions = "settings.StringToExpressions.enabled",
    string_encoding     = "settings.string_encoding.enabled",
    WrapInFunction      = "settings.WrapInFunction.enabled",
    variable_renaming   = "settings.variable_renaming.enabled",
    garbage_code        = "settings.garbage_code.enabled",
    opaque_predicates   = "settings.opaque_predicates.enabled",
    function_inlining   = "settings.function_inlining.enabled",
    dynamic_code        = "settings.dynamic_code.enabled",
    bytecode_encoding   = "settings.bytecode_encoding.enabled",
    compressor          = "settings.compressor.enabled",
    watermark           = "settings.watermark_enabled",
}

local function normalize_output(s)
    if not s then return s end
    return s:gsub("(%d+)%.(0+) ", "%1 ")
            :gsub("(%d+)%.(0+)$", "%1")
            :gsub("(%d+)%.(0+)", "%1")
end

local function capture_output(code)
    local output = {}
    local orig_print = _G.print
    _G.print = function(...)
        local args = { ... }
        for i, v in ipairs(args) do args[i] = tostring(v) end
        table.insert(output, table.concat(args, "\t"))
    end
    local ok, err = pcall(function()
        local f, load_err = load(code, "=test", "t")
        if not f then error("compile error: " .. load_err) end
        f()
    end)
    _G.print = orig_print
    if not ok then return nil, tostring(err) end
    return normalize_output(table.concat(output, "\n")), nil
end

local function set_all_modules(mask)
    for i = 1, #ALL_MODULES do
        local bit = (mask >> (i - 1)) & 1
        config.set(MODULE_PATHS[ALL_MODULES[i]], bit == 1)
    end
end

local function find_fixture(name)
    for _, fixture in ipairs(fixtures.get_all()) do
        if fixture.name == name then return fixture end
    end
    return nil
end

local function write_results(path, pass, failures)
    local handle, err = io.open(path, "w")
    if not handle then error(err) end
    handle:write(string.format("pass\t%d\n", pass))
    handle:write(string.format("fail\t%d\n", #failures))
    for _, failure in ipairs(failures) do
        handle:write(table.concat(failure, "\t") .. "\n")
    end
    handle:close()
end

local fixture_name = arg[1]
local start_mask = tonumber(arg[2])
local end_mask = tonumber(arg[3])
local result_path = arg[4]

if not fixture_name or not start_mask or not end_mask or not result_path then
    error("usage: fixture_sweep_worker.lua <fixture> <start_mask> <end_mask> <result_path>")
end

local fixture = find_fixture(fixture_name)
if not fixture then error("unknown fixture: " .. fixture_name) end

local pass = 0
local failures = {}

for mask = start_mask, end_mask do
    math.randomseed(mask * 1000 + 1)
    set_all_modules(mask)

    local ok, result = pcall(function() return Pipeline.process(fixture.code) end)
    if not ok then
        failures[#failures + 1] = { tostring(mask), "pipeline error", tostring(result):sub(1, 250) }
    elseif type(result) ~= "string" then
        failures[#failures + 1] = { tostring(mask), "result not string", type(result) }
    else
        local load_ok, load_err = load(result, "=test", "t")
        if not load_ok then
            failures[#failures + 1] = { tostring(mask), "invalid Lua", tostring(load_err):sub(1, 250) }
        else
            local out, exec_err = capture_output(result)
            if exec_err then
                failures[#failures + 1] = { tostring(mask), "exec error", tostring(exec_err):sub(1, 250) }
            elseif out ~= fixture.expected then
                failures[#failures + 1] = { tostring(mask), "output mismatch", tostring(out):sub(1, 250) }
            else
                pass = pass + 1
            end
        end
    end
end

write_results(result_path, pass, failures)
