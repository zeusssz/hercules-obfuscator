-- test_worker_py.lua — Worker for Python parallel test runner
-- Usage: lua test_worker_py.lua <masks_json>
-- Outputs: P:<mask> or F:<mask>:<fixture_idx>:<reason>

if not math.ldexp then math.ldexp = function(x,n) return x*2^n end end
if not math.frexp then math.frexp = function(x)
    if x==0 then return 0,0 end
    local e=math.floor(math.log(math.abs(x))/math.log(2))+1
    return x/2^e, e
end end

local config = require("config")
local Pipeline = require("pipeline")
local fixtures = require("test_fixtures")

local ALL_MODULES = {
    "VirtualMachine","antitamper","control_flow","StringToExpressions",
    "string_encoding","WrapInFunction","variable_renaming","garbage_code",
    "opaque_predicates","function_inlining","dynamic_code","bytecode_encoding",
    "compressor","watermark"
}
local MODULE_PATHS = {
    VirtualMachine="settings.VirtualMachine.enabled",
    antitamper="settings.antitamper.enabled",
    control_flow="settings.control_flow.enabled",
    StringToExpressions="settings.StringToExpressions.enabled",
    string_encoding="settings.string_encoding.enabled",
    WrapInFunction="settings.WrapInFunction.enabled",
    variable_renaming="settings.variable_renaming.enabled",
    garbage_code="settings.garbage_code.enabled",
    opaque_predicates="settings.opaque_predicates.enabled",
    function_inlining="settings.function_inlining.enabled",
    dynamic_code="settings.dynamic_code.enabled",
    bytecode_encoding="settings.bytecode_encoding.enabled",
    compressor="settings.compressor.enabled",
    watermark="settings.watermark_enabled",
}

local ALL_FIXTURES = fixtures.get_all()

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

-- Read masks from command line (JSON array)
local masks_json = arg[1]
local masks = {}
for m in masks_json:gmatch("%d+") do
    table.insert(masks, tonumber(m))
end

for _, mask in ipairs(masks) do
    for i = 1, #ALL_MODULES do
        local bit = (mask >> (i-1)) & 1
        config.set(MODULE_PATHS[ALL_MODULES[i]], bit == 1)
    end

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
        local load_ok = load(result, "=test", "t") ~= nil
        if not load_ok then
            io.write(string.format("F:%d:%d:invalid_lua\n", mask, fidx))
            io.flush()
            combo_ok = false
            break
        end
        local out, exec_err = capture_output(result)
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
