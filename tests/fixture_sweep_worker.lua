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
local test_support = require("test_support")

local TEST_MODULES = test_support.get_modules()

local function normalize_output(s)
    if not s then return s end
    return s:gsub("(%d+)%.(0+) ", "%1 ")
            :gsub("(%d+)%.(0+)$", "%1")
            :gsub("(%d+)%.(0+)", "%1")
end

local function capture_loaded(fn)
    local output = {}
    local orig_print = _G.print
    _G.print = function(...)
        local args = { ... }
        for i, v in ipairs(args) do args[i] = tostring(v) end
        table.insert(output, table.concat(args, "\t"))
    end
    local ok, err = pcall(fn)
    _G.print = orig_print
    if not ok then return nil, tostring(err) end
    return normalize_output(table.concat(output, "\n")), nil
end

local function set_all_modules(mask)
    test_support.set_all_modules(config, TEST_MODULES, mask)
end

local function find_fixture(name)
    for _, fixture in ipairs(fixtures.get_all()) do
        if fixture.name == name then return fixture end
    end
    return nil
end

local function clean_field(value)
    return tostring(value):gsub("[\r\n\t]", " ")
end

local function write_results(path, pass, failures)
    local handle, err = io.open(path, "w")
    if not handle then error(err) end
    handle:write(string.format("pass\t%d\n", pass))
    handle:write(string.format("fail\t%d\n", #failures))
    for _, failure in ipairs(failures) do
        local fields = {}
        for i, field in ipairs(failure) do
            fields[i] = clean_field(field)
        end
        handle:write(table.concat(fields, "\t") .. "\n")
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
        local loaded, load_err = load(result, "=test", "t")
        if not loaded then
            failures[#failures + 1] = { tostring(mask), "invalid Lua", tostring(load_err):sub(1, 250) }
        else
            local out, exec_err = capture_loaded(loaded)
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
