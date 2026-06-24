-- test_worker_py.lua — Long-lived worker for Python parallel test runner
-- Reads masks from stdin (one per line), outputs P:<mask> or F:<mask>:<fidx>:<reason>

-- Polyfills for Lua 5.4 (math.ldexp/frexp removed in 5.3+)
package.path = "./src/?.lua;./src/?/init.lua;./tests/?.lua;./tests/?/init.lua;" .. package.path

if not math.ldexp then math.ldexp = function(x,n) return x*2^n end end
if not math.frexp then math.frexp = function(x)
    if x==0 then return 0,0 end
    local e=math.floor(math.log(math.abs(x))/math.log(2))+1
    return x/2^e, e
end end

local config = require("config")
local Pipeline = require("pipeline")
local fixtures = require("test_fixtures")
local test_support = require("test_support")

local TEST_MODULES = test_support.get_modules()
local ALL_FIXTURES = fixtures.get_all()

if arg and arg[1] then
    local selected = {}
    for _, fixture in ipairs(ALL_FIXTURES) do
        if fixture.name == arg[1] then
            selected[#selected + 1] = fixture
            break
        end
    end
    if #selected == 0 then
        io.stderr:write("unknown fixture: " .. tostring(arg[1]) .. "\n")
        os.exit(2)
    end
    ALL_FIXTURES = selected
end

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

-- Read masks from stdin, one per line
for line in io.lines() do
    local mask = tonumber(line)
    if not mask then break end

    test_support.set_all_modules(config, TEST_MODULES, mask)

    math.randomseed(mask * 1000 + 1)

    local combo_ok = true
    for fidx, f in ipairs(ALL_FIXTURES) do
        local ok, result = pcall(function() return Pipeline.process(f.code) end)
        if not ok then
            io.write(string.format("F:%d:%d:pipeline_error\n", mask, fidx))
            io.flush()
            combo_ok = false
            break
        end
        if type(result) ~= "string" then
            io.write(string.format("F:%d:%d:not_string\n", mask, fidx))
            io.flush()
            combo_ok = false
            break
        end
        local loaded = load(result, "=test", "t")
        if not loaded then
            io.write(string.format("F:%d:%d:invalid_lua\n", mask, fidx))
            io.flush()
            combo_ok = false
            break
        end
        local out, exec_err = capture_loaded(loaded)
        if exec_err then
            io.write(string.format("F:%d:%d:exec_error\n", mask, fidx))
            io.flush()
            combo_ok = false
            break
        end
        if out ~= f.expected then
            io.write(string.format("F:%d:%d:mismatch\n", mask, fidx))
            io.flush()
            combo_ok = false
            break
        end
    end

    if combo_ok then
        io.write(string.format("P:%d\n", mask))
        io.flush()
    end
end
