#!/usr/bin/env lua
-- test.lua — End-to-end test suite for Hercules Obfuscator
-- Tests ONLY output equivalence: obfuscated code must produce the same output as the original.
-- Tests ALL 2^14 = 16384 module combinations against all fixtures.
-- Run from src/:  lua test.lua

-- ─── Polyfills for Lua 5.4 (math.ldexp/frexp removed in 5.3+) ─────────────────
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

-- ─── Dependencies ──────────────────────────────────────────────────────────────
local config    = require("config")
local Pipeline  = require("pipeline")
local fixtures  = require("test_fixtures")

-- ─── Normalize Output ──────────────────────────────────────────────────────────
-- Lua 5.4 prints floats as "4.0" while Lua 5.1 would print "4".
local function normalize_output(s)
    if not s then return s end
    return s:gsub("(%d+)%.(0+) ", "%1 ")
              :gsub("(%d+)%.(0+)$", "%1")
              :gsub("(%d+)%.(0+)", "%1")
end

-- ─── Capture Output ────────────────────────────────────────────────────────────
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

-- ─── All 14 Modules (must match config settings) ───────────────────────────────
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
local NUM_MODULES = #ALL_MODULES  -- 14
local NUM_COMBOS  = 2 ^ NUM_MODULES  -- 16384

-- Config path map
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

local function set_all_modules(mask)
    for i = 1, NUM_MODULES do
        local bit = (mask >> (i - 1)) & 1
        config.set(MODULE_PATHS[ALL_MODULES[i]], bit == 1)
    end
end

local function mask_to_modules(mask)
    local mods = {}
    for i = 1, NUM_MODULES do
        if (mask >> (i - 1)) & 1 == 1 then
            mods[#mods + 1] = ALL_MODULES[i]
        end
    end
    return mods
end

local function modules_to_label(mods)
    return table.concat(mods, "+")
end

-- ─── Colors ────────────────────────────────────────────────────────────────────
local C = {
    g = "\27[32m", r = "\27[31m", y = "\27[33m",
    c = "\27[36m", b = "\27[34m", reset = "\27[0m",
}
local function col(c, s) return c .. s .. C.reset end

local function format_eta(seconds)
    if seconds < 60 then
        return string.format("%ds", math.ceil(seconds))
    elseif seconds < 3600 then
        return string.format("%dm %ds", math.floor(seconds / 60), math.ceil(seconds % 60))
    else
        return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

local function format_eta(seconds)
    if seconds < 60 then
        return string.format("%ds", math.ceil(seconds))
    elseif seconds < 3600 then
        return string.format("%dm %ds", math.floor(seconds / 60), math.ceil(seconds % 60))
    else
        return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

local function format_eta(seconds)
    if seconds < 60 then
        return string.format("%ds", math.ceil(seconds))
    elseif seconds < 3600 then
        return string.format("%dm %ds", math.floor(seconds / 60), math.ceil(seconds % 60))
    else
        return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

-- ─── Test Runner ───────────────────────────────────────────────────────────────
local ALL_FIXTURES = fixtures.get_all()
local total_start = os.clock()
local VERBOSE = false

local function parse_args()
    local filters = {}
    local group, list_only, verbose, quick, fixture_filter = nil, false, false, false, nil
    local i = 1
    while i <= #arg do
        if arg[i] == "--test" and arg[i + 1] then
            filters[#filters + 1] = arg[i + 1]; i = i + 2
        elseif arg[i] == "--group" and arg[i + 1] then group = arg[i + 1]; i = i + 2
        elseif arg[i] == "--fixture" and arg[i + 1] then fixture_filter = arg[i + 1]; i = i + 2
        elseif arg[i] == "--list" then list_only = true; i = i + 1
        elseif arg[i] == "--verbose" or arg[i] == "-v" then verbose = true; i = i + 1
        elseif arg[i] == "--quick" then quick = true; i = i + 1
        elseif arg[i] == "--help" or arg[i] == "-h" then
            print("Usage: lua test.lua [options]")
            print("  --test <name>          Run specific test(s), repeatable")
            print("  --group <name>         Run tests matching group prefix")
            print("  --fixture <name>       Test only this fixture (all combinations)")
            print("  --quick                Run subset: baseline + singles + working combos")
            print("  --list                 List all tests")
            print("  --verbose, -v          Show detailed output")
            print("  --help, -h             Show this help")
            os.exit(0)
        else i = i + 1
        end
    end
    return filters, group, list_only, verbose, quick, fixture_filter
end

-- ─── Test Definitions ──────────────────────────────────────────────────────────
local tests = {}
local function register(name, fn) tests[#tests + 1] = { name = name, fn = fn } end

local function extract_group(name)
    return name:match("^([%w]+)_")
end

local function disable_all()
    for _, key in ipairs(ALL_MODULES) do
        config.set(MODULE_PATHS[key], false)
    end
end

-- Phase 0: Quick mode — baseline + single modules + combos (output-only verification)
register("quick_combo", function()
    -- Baseline (no modules)
    disable_all()
    for _, f in ipairs(ALL_FIXTURES) do
        local result = Pipeline.process(f.code)
        local out, err = capture_output(result)
        assert(err == nil, string.format("baseline %s: %s", f.name, err))
        assert(out == f.expected, string.format("baseline %s mismatch: got %q, expected %q", f.name, out, f.expected))
    end

    -- Single modules (14)
    for _, mod in ipairs(ALL_MODULES) do
        disable_all()
        config.set(MODULE_PATHS[mod], true)
        for _, f in ipairs(ALL_FIXTURES) do
            local ok, result = pcall(function() return Pipeline.process(f.code) end)
            assert(ok, string.format("single %s %s: pipeline error: %s", mod, f.name, tostring(result)))
            local load_ok, load_err = load(result, "=test", "t")
            assert(load_ok, string.format("single %s %s: invalid Lua: %s", mod, f.name, load_err))
            local out, err = capture_output(result)
            assert(err == nil, string.format("single %s %s: exec error: %s", mod, f.name, err))
            assert(out == f.expected, string.format("single %s %s: mismatch got %q expected %q", mod, f.name, out, f.expected))
        end
    end
end)

-- Phase 1: FULL — All 2^14 combinations against all fixtures (output-only verification)
register("full_combinations", function()
    local total = 0
    local pass_combos = 0
    local fail_combos = 0
    local total_tests = (NUM_COMBOS - 1) * #ALL_FIXTURES
    -- Adaptive progress: verbose = every combo, otherwise every ~500 fixtures
    local progress_interval = VERBOSE and 1 or math.max(1, math.floor(500 / #ALL_FIXTURES))
    local next_progress = progress_interval
    local start_time = os.clock()

    local fail_by_module = {}
    for _, m in ipairs(ALL_MODULES) do fail_by_module[m] = 0 end
    local fail_by_pair = {}
    local fail_first_fixture = {}

    local max_fail_details = 50
    local fail_details = {}

    for mask = 1, NUM_COMBOS - 1 do
        local mods = mask_to_modules(mask)
        local label = modules_to_label(mods)
        set_all_modules(mask)

        -- Seed random deterministically so obfuscation output is reproducible
        math.randomseed(mask * 1000 + 1)

        local combo_ok = true
        local first_fail_fixture = nil
        local first_fail_reason = nil

        for _, f in ipairs(ALL_FIXTURES) do
            total = total + 1

            if total >= next_progress then
                local pct = (total / total_tests) * 100
                local elapsed = os.clock() - start_time
                local rate = total / elapsed
                local eta = (total_tests - total) / rate
                io.write(string.format("\r  [%5.1f%%] %d/%d  (%.0f tests/s, ETA: %s) ",
                    pct, total, total_tests, rate, format_eta(eta)))
                io.flush()
                next_progress = next_progress + progress_interval
            end

            local ok, result = pcall(function() return Pipeline.process(f.code) end)
            if not ok then
                combo_ok = false
                first_fail_fixture = f.name
                first_fail_reason = "pipeline error"
                break
            end

            if type(result) ~= "string" then
                combo_ok = false
                first_fail_fixture = f.name
                first_fail_reason = "result not string"
                break
            end

            local load_ok, load_err = load(result, "=test", "t")
            if not load_ok then
                combo_ok = false
                first_fail_fixture = f.name
                first_fail_reason = "invalid Lua"
                break
            end

            local out, exec_err = capture_output(result)
            if exec_err then
                combo_ok = false
                first_fail_fixture = f.name
                first_fail_reason = "exec error"
                break
            end

            if out ~= f.expected then
                combo_ok = false
                first_fail_fixture = f.name
                first_fail_reason = "output mismatch"
                break
            end
        end

        if combo_ok then
            pass_combos = pass_combos + 1
        else
            fail_combos = fail_combos + 1
            for _, m in ipairs(mods) do
                fail_by_module[m] = fail_by_module[m] + 1
            end
            if #mods >= 2 then
                for i = 1, #mods - 1 do
                    for j = i + 1, #mods do
                        local pair = mods[i] .. "+" .. mods[j]
                        fail_by_pair[pair] = (fail_by_pair[pair] or 0) + 1
                    end
                end
            end
            fail_first_fixture[label] = first_fail_fixture .. " (" .. first_fail_reason .. ")"
            if #fail_details < max_fail_details then
                fail_details[#fail_details + 1] = string.format("  [%s] first fail: %s — %s", label, first_fail_fixture, first_fail_reason)
            end
        end
    end

    local elapsed = os.clock() - start_time
    io.write(string.format("\r  [100.0%%] %d/%d  (%.0f tests/s, %.1fs)  \n\n",
        total, total_tests, total / elapsed, elapsed))

    io.write(string.format("\n  Passed: %d / %d  |  Failed: %d / %d\n",
        pass_combos, NUM_COMBOS - 1, fail_combos, NUM_COMBOS - 1))
    io.write(string.format("  Total fixture executions: %d\n\n", total))

    io.write("  Failures by module:\n")
    for _, m in ipairs(ALL_MODULES) do
        if fail_by_module[m] > 0 then
            io.write(string.format("    %-22s %d combos\n", m, fail_by_module[m]))
        end
    end

    io.write("\n  Top failing pairs:\n")
    local sorted_pairs = {}
    for pair, count in pairs(fail_by_pair) do
        sorted_pairs[#sorted_pairs + 1] = { pair = pair, count = count }
    end
    table.sort(sorted_pairs, function(a, b) return a.count > b.count end)
    for i = 1, math.min(20, #sorted_pairs) do
        io.write(string.format("    %-45s %d combos\n", sorted_pairs[i].pair, sorted_pairs[i].count))
    end

    io.write(string.format("\n  Sample failed combos (first %d):\n", #fail_details))
    for _, detail in ipairs(fail_details) do
        io.write(detail .. "\n")
    end
    if fail_combos > max_fail_details then
        io.write(string.format("  ... and %d more\n", fail_combos - max_fail_details))
    end

    if fail_combos > 0 then
        error(string.format("%d combinations failed out of %d", fail_combos, NUM_COMBOS - 1))
    end
end)

-- Phase 2: Baseline (no modules)
register("baseline_no_modules", function()
    disable_all()
    for _, f in ipairs(ALL_FIXTURES) do
        local result = Pipeline.process(f.code)
        local out, err = capture_output(result)
        assert(err == nil, string.format("baseline %s: %s", f.name, err))
        assert(out == f.expected, string.format("baseline %s mismatch: got %q, expected %q", f.name, out, f.expected))
    end
end)

-- Phase 3: Single module semantics (each of 14 modules individually)
for m = 1, NUM_MODULES do
    local mod = ALL_MODULES[m]
    register("single_" .. mod, function()
        disable_all()
        config.set(MODULE_PATHS[mod], true)
        for _, f in ipairs(ALL_FIXTURES) do
            local ok, result = pcall(function() return Pipeline.process(f.code) end)
            assert(ok, string.format("%s %s: pipeline error: %s", mod, f.name, tostring(result):sub(1, 150)))
            assert(type(result) == "string", string.format("%s %s: result not string", mod, f.name))
            local load_ok, load_err = load(result, "=test", "t")
            assert(load_ok, string.format("%s %s: invalid Lua: %s", mod, f.name, load_err))
            local out, exec_err = capture_output(result)
            assert(exec_err == nil, string.format("%s %s: exec error: %s", mod, f.name, exec_err))
            assert(out == f.expected, string.format("%s %s: mismatch got %q expected %q", mod, f.name, out, f.expected))
        end
    end)
end

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

-- Phase 4: Fixture-specific full combination sweep (--fixture <name>)
local function register_fixture_sweep(fixture_name, _fixture)
    register("fixture_sweep_" .. fixture_name, function()
        local python = os.getenv("PYTHON_BIN") or "python3"
        local command = string.format(
            "%s tests/fixture_sweep_parallel.py %s",
            shell_quote(python),
            shell_quote(fixture_name)
        )
        local ok, exit_type, code = os.execute(command)
        if ok ~= true then
            error(string.format(
                "fixture sweep failed for %s (%s %s)",
                fixture_name,
                tostring(exit_type),
                tostring(code)
            ))
        end
    end)
end

for _, f in ipairs(ALL_FIXTURES) do
    register_fixture_sweep(f.name, f)
end

-- Phase 5: Config API
register("config_get_set", function()
    local orig = config.get("settings.compressor.enabled")
    config.set("settings.compressor.enabled", not orig)
    assert(config.get("settings.compressor.enabled") == not orig)
    config.set("settings.compressor.enabled", orig)
    assert(config.get("settings.compressor.enabled") == orig)
    assert(config.get("settings.nonexistent.key") == nil)
    assert(config.set("settings.nonexistent.key", true) == false)
end)

register("compressor_statement_boundaries", function()
    local Compressor = require("modules/compressor")
    local source = [[
local a = 1
local b = 2
print(a + b)
]]
    local compressed = Compressor.process(source)
    local fn, load_err = load(compressed, "=compressor_statement_boundaries", "t")
    assert(fn, tostring(load_err) .. "\n" .. compressed)
    assert(compressed:find("local a=1;local b=2;print", 1, true), compressed)
    local out, exec_err = capture_output(compressed)
    assert(exec_err == nil, tostring(exec_err))
    assert(out == "3", string.format("expected 3, got %q", tostring(out)))
end)

register("compressor_return_boundary", function()
    local Compressor = require("modules/compressor")
    local source = [[
local function value()
    return
    (function()
        return "ok"
    end)()
end

print(value())
]]
    local compressed = Compressor.process(source)
    assert(not compressed:find("return;", 1, true), compressed)
    local fn, load_err = load(compressed, "=compressor_return_boundary", "t")
    assert(fn, tostring(load_err) .. "\n" .. compressed)
    local out, exec_err = capture_output(compressed)
    assert(exec_err == nil, tostring(exec_err))
    assert(out == "ok", string.format("expected ok, got %q", tostring(out)))
end)

register("compressor_multiline_call_boundary", function()
    local Compressor = require("modules/compressor")
    local source = [[
local function call(...)
    print(select("#", ...))
end

call(
    "a",
    "b",
    "c"
)
]]
    local compressed = Compressor.process(source)
    assert(not compressed:find("call%(;", 1, false), compressed)
    local fn, load_err = load(compressed, "=compressor_multiline_call_boundary", "t")
    assert(fn, tostring(load_err) .. "\n" .. compressed)
    local out, exec_err = capture_output(compressed)
    assert(exec_err == nil, tostring(exec_err))
    assert(out == "3", string.format("expected 3, got %q", tostring(out)))
end)

register("compressor_multiline_table_boundary", function()
    local Compressor = require("modules/compressor")
    local source = [[
local t = {
    a = 1,
    b = 2,
    c = 3,
}

print(t.a + t.b + t.c)
]]
    local compressed = Compressor.process(source)
    assert(not compressed:find("{%s*;", 1, false), compressed)
    local fn, load_err = load(compressed, "=compressor_multiline_table_boundary", "t")
    assert(fn, tostring(load_err) .. "\n" .. compressed)
    local out, exec_err = capture_output(compressed)
    assert(exec_err == nil, tostring(exec_err))
    assert(out == "6", string.format("expected 6, got %q", tostring(out)))
end)

register("compressor_multiline_logical_operator", function()
    local Compressor = require("modules/compressor")
    local source = [[
local a = nil
local b = "ok"
local value = a
    or b
print(value)
]]
    local compressed = Compressor.process(source)
    assert(not compressed:find(";or", 1, true), compressed)
    assert(not compressed:find(";and", 1, true), compressed)
    local fn, load_err = load(compressed, "=compressor_multiline_logical_operator", "t")
    assert(fn, tostring(load_err) .. "\n" .. compressed)
    local out, exec_err = capture_output(compressed)
    assert(exec_err == nil, tostring(exec_err))
    assert(out == "ok", string.format("expected ok, got %q", tostring(out)))
end)

register("dynamic_code_closing_table_call_boundary", function()
    local DynamicCodeGenerator = require("modules/dynamic_code_generator")
    local source = [[
local function Button(options)
    options.Callback()
end

Button({
    Title = "Run",
    Callback = function()
        print("ok")
    end
})
]]
    local output = DynamicCodeGenerator.process(source)
    assert(not output:find("do %(function%(%) %}%)", 1, false), output)
    local fn, load_err = load(output, "=dynamic_code_closing_table_call_boundary", "t")
    assert(fn, tostring(load_err) .. "\n" .. output)
    local out, exec_err = capture_output(output)
    assert(exec_err == nil, tostring(exec_err))
    assert(out == "ok", string.format("expected ok, got %q", tostring(out)))
end)

register("luau_api_method_combo_syntax", function()
    local orig_target = config.target
    config.target = "luau"

    local source = [[
local Section = {}
function Section:Button(options) end

Section:Button({
    Title = "Purchase",
    Callback = function()
        local remote = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents")
            and game:GetService("ReplicatedStorage").RemoteEvents:FindFirstChild("BuyItemCash")
        if remote then remote:FireServer("Green Dino") end
    end
})
]]

    for _, key in ipairs(ALL_MODULES) do
        config.set(MODULE_PATHS[key], false)
    end
    for _, key in ipairs({
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
        "compressor",
    }) do
        config.set(MODULE_PATHS[key], true)
    end

    local ok, result = pcall(function() return Pipeline.process(source) end)
    assert(ok, string.format("pipeline error: %s", tostring(result):sub(1, 150)))
    local fn, load_err = load(result, "=luau_api_method_combo_syntax", "t")
    assert(fn, tostring(load_err) .. "\n" .. result)

    config.target = orig_target
end)

register("lua_comprehensive_combo_5894_syntax", function()
    local orig_target = config.target
    config.target = "lua"

    local source = [[print("lua-ok")]]

    for _, key in ipairs(ALL_MODULES) do
        config.set(MODULE_PATHS[key], false)
    end
    for _, key in ipairs({
        "antitamper",
        "control_flow",
        "StringToExpressions",
        "string_encoding",
        "variable_renaming",
        "function_inlining",
        "dynamic_code",
        "VirtualMachine",
    }) do
        config.set(MODULE_PATHS[key], true)
    end

    local ok, result = pcall(function() return Pipeline.process(source) end)
    assert(ok, string.format("pipeline error: %s", tostring(result):sub(1, 150)))
    local fn, load_err = load(result, "=lua_comprehensive_combo_5894_syntax", "t")
    assert(fn, tostring(load_err) .. "\n" .. result)

    config.target = orig_target
end)

register("compressor_realistic_glua_syntax", function()
    local Compressor = require("modules/compressor")
    local source = [[
hook.Add("PlayerSpawn", "DetectionTestHook", function(ply)
    if not IsValid(ply) then return end
    local t = CurTime()
    ply:SetNWFloat("spawn_time", t)
    print("[GLuaTest] Player spawned at:", t)
end)

ENT = ENT or {}
ENT.Type = "anim"
ENT.Base = "base_gmodentity"

function ENT:Initialize()
    self:SetModel("models/props_c17/oildrum001.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
end

function ENT:Use(activator, caller)
    if IsValid(activator) then
        activator:ChatPrint("Entity used!")
    end
end

if SERVER then
    util.AddNetworkString("DetectionTestNet")
    net.Receive("DetectionTestNet", function(len, ply)
        print("[GLuaTest] Received net message from:", ply:Nick())
    end)
else
    net.Start("DetectionTestNet")
    net.SendToServer()
end

if CLIENT then
    hook.Add("HUDPaint", "DetectionHUDTest", function()
        draw.SimpleText(
            "GLua Detection Test",
            "DermaDefault",
            100,
            100,
            Color(255, 255, 255, 255)
        )
    end)
end

local crc = util.CRC("glua_detection_test")
print("[GLuaTest] CRC:", crc)
print("[GLuaTest] CurTime:", CurTime())
]]
    local compressed = Compressor.process(source)
    local fn, load_err = load(compressed, "=compressor_realistic_glua_syntax", "t")
    assert(fn, tostring(load_err) .. "\n" .. compressed)
    assert(compressed:find("local t=CurTime();", 1, true), compressed)
    assert(not compressed:find("\n%s*local t = CurTime", 1, false), compressed)
end)

register("opaque_predicates_realistic_glua_syntax", function()
    local OpaquePredicateInjector = require("modules/opaque_predicate_injector")
    local source = [[
hook.Add("PlayerSpawn", "DetectionTestHook", function(ply)
    if not IsValid(ply) then return end

    local t = CurTime()
    ply:SetNWFloat("spawn_time", t)

    print("[GLuaTest] Player spawned at:", t)
end)
]]
    local output = OpaquePredicateInjector.process(source)
    local fn, load_err = load(output, "=opaque_predicates_realistic_glua_syntax", "t")
    assert(fn, tostring(load_err) .. "\n" .. output)
end)

register("opaque_predicates_if_else_boundary", function()
    local OpaquePredicateInjector = require("modules/opaque_predicate_injector")
    local source = [[
local value = 2
if value > 1 then
    print("then")
else
    print("else")
end
print("done")
]]
    local output = OpaquePredicateInjector.process(source)
    local fn, load_err = load(output, "=opaque_predicates_if_else_boundary", "t")
    assert(fn, tostring(load_err) .. "\n" .. output)
    local out, exec_err = capture_output(output)
    assert(exec_err == nil, tostring(exec_err))
    assert(out == "then\ndone", string.format("expected then/done, got %q", tostring(out)))
end)

register("variable_renaming_luau_types", function()
    local VariableRenamer = require("modules/variable_renamer")
    local source = [[
-- Type alias (Luau)
type PlayerData = {
    name: string,
    score: number
}

-- Local with type annotation
local data: PlayerData = {
    name = "TestUser",
    score = 0
}

-- Using type() function should be a valid expression
local t = type(data)
print(t)
]]
    local result = VariableRenamer.process(source, {target = "luau", min_length = 8, max_length = 12})

    -- 'type' keyword in type alias must be preserved (not renamed)
    assert(result:match("type%s+%w+%s*="),
        string.format("type alias should preserve 'type' keyword, got:\n%s", result:sub(1, 200)))

    -- Type annotation with colon and custom type name must be preserved
    assert(result:match("local%s+%w+%s*:%s*%w+%s*="),
        string.format("type annotation should be preserved, got:\n%s", result:sub(1, 200)))

    -- type() function call should still exist (not renamed)
    assert(result:match("type%("),
        string.format("type() function call should exist, got:\n%s", result:sub(1, 300)))
end)

register("variable_renaming_luau_type_annotation_names", function()
    local VariableRenamer = require("modules/variable_renamer")
    -- When variable has a type annotation like `: string`, the type name
    -- must NOT be extracted as a local variable and renamed
    local source = [[
local x: string = "hello"
local y: number = 42
print(x, y)
]]
    local result = VariableRenamer.process(source, {target = "luau", min_length = 8, max_length = 12})

    -- Type names string/number must NOT be renamed
    -- They should appear as-is after the colon
    assert(result:match(":%s*string%s*="),
        string.format("'string' type should be preserved after colon, got:\n%s", result))
    assert(result:match(":%s*number%s*="),
        string.format("'number' type should be preserved after colon, got:\n%s", result))
end)

register("variable_renaming_luau_pipeline", function()
    -- End-to-end: run Pipeline.process() with target=luau on Luau source
    -- The pipeline disables VM + bytecode_encoding for luau
    local orig_target = config.target
    config.target = "luau"

    local source = [[
-- Type alias (Luau)
type PlayerData = {
    name: string,
    score: number
}

local data: PlayerData = {
    name = "TestUser",
    score = 0
}

-- Simulate print-based equivalence
data.score = data.score + 10
print("[LuauTest] Score:", data.score)
]]
    local expected = normalize_output("[LuauTest] Score:\t10")

    -- Enable all modules except VM + bytecode_encoding (auto-disabled for luau)
    -- But enable variable_renaming explicitly
    for _, key in ipairs(ALL_MODULES) do
        config.set(MODULE_PATHS[key], false)
    end
    config.set(MODULE_PATHS.variable_renaming, true)

    local ok, result = pcall(function() return Pipeline.process(source) end)
    assert(ok, string.format("pipeline error: %s", tostring(result):sub(1, 150)))

    -- The result must retain 'type' keyword in the type alias
    assert(result:match("type%s+%w+%s*="),
        string.format("type alias must be preserved in pipeline output, got:\n%s", result:sub(1, 200)))

    -- Restore config
    config.target = orig_target
end)

register("wrap_in_function_no_top_level_vararg", function()
    local Wrapper = require("modules/WrapInFunction")
    local source = [[print("hello")]]
    local result = Wrapper.process(source)

    -- Must use () call, not (...) call, to avoid "Cannot use '...' outside of vararg function" in Luau
    assert(result:match("end%)%(%)$") or result:match("end%)%(%)%s*$"),
        string.format("must end with 'end)()' not 'end)(...)', got:\n%s", result))

    -- Must still be loadable and runnable in Lua 5.4
    local fn, err = load(result, "=test_wrap", "t")
    assert(fn, string.format("wrap result should be loadable: %s\n%s", tostring(err), result))

    local out, exec_err = capture_output(result)
    assert(exec_err == nil, string.format("exec error: %s", tostring(exec_err)))
    assert(out == "hello", string.format("expected hello, got %q", tostring(out)))
end)

-- ─── Main ──────────────────────────────────────────────────────────────────────
local function main()
    local filters, group, list_only, verbose, quick, fixture_filter = parse_args()
    VERBOSE = verbose

    local filtered = {}
    for _, t in ipairs(tests) do
        if #filters > 0 then
            for _, f in ipairs(filters) do
                if t.name == f then
                    table.insert(filtered, t)
                    break
                end
            end
        elseif group then
            local g = extract_group(t.name)
            if g == group then table.insert(filtered, t) end
        elseif fixture_filter and t.name == "fixture_sweep_" .. fixture_filter then
            table.insert(filtered, t)
        else
            if quick then
                if t.name == "quick_combo" or t.name == "baseline_no_modules" or
                   t.name == "config_get_set" then
                    table.insert(filtered, t)
                elseif t.name:match("^single_") then
                    table.insert(filtered, t)
                end
            else
                table.insert(filtered, t)
            end
        end
    end

    if list_only then
        print("Available tests:")
        for _, t in ipairs(tests) do
            local g = extract_group(t.name) or "other"
            print(string.format("  %-50s [%s]", t.name, g))
        end
        print(string.format("\nTotal: %d tests  |  Fixtures: %d  |  Combinations: %d (2^%d)",
            #tests, #ALL_FIXTURES, NUM_COMBOS, NUM_MODULES))
        return
    end

    if #filtered == 0 then
        print(col(C.r, "No tests matched."))
        os.exit(1)
    end

    print(col(C.c, "Hercules Obfuscator — Test Suite"))
    print(col(C.c, string.rep("─", 60)))
    print(string.format("Fixtures: %d  |  Modules: %d  |  Combinations: %d (2^%d)\n",
        #ALL_FIXTURES, NUM_MODULES, NUM_COMBOS, NUM_MODULES))
    print(string.format("Running %d tests...\n", #filtered))

    local passed, failed, skipped = 0, 0, 0
    for _, t in ipairs(filtered) do
        local start = os.clock()
        local ok, err = pcall(t.fn)
        local elapsed = os.clock() - start
        local grp = extract_group(t.name) or "other"
        local label = string.format("[%s] %s", grp, t.name)

        if ok then
            passed = passed + 1
            if verbose then
                print(string.format("  %s  %s  (%.3fs)", col(C.g, "PASS"), label, elapsed))
            else
                io.write(col(C.g, "."))
            end
        else
            local errstr = tostring(err)
            if errstr:find("SKIP") then
                skipped = skipped + 1
                if verbose then
                    print(string.format("  %s  %s", col(C.y, "SKIP"), label))
                else
                    io.write(col(C.y, "s"))
                end
            else
                failed = failed + 1
                if verbose then
                    print(string.format("  %s  %s  (%.3fs)", col(C.r, "FAIL"), label, elapsed))
                    if #errstr > 300 then errstr = errstr:sub(1, 300) .. "..." end
                    for line in errstr:gmatch("[^\n]+") do
                        print("         " .. col(C.r, line))
                    end
                else
                    io.write(col(C.r, "F"))
                end
            end
        end
    end

    if not verbose then io.write("\n") end

    local total_time = os.clock() - total_start
    print(col(C.c, string.rep("─", 60)))
    print(string.format("Results: %d passed, %d failed, %d skipped (%.3fs)",
        passed, failed, skipped, total_time))

    if failed > 0 then
        print(col(C.r, "\nSome tests failed."))
        os.exit(1)
    else
        print(col(C.g, "\nAll tests passed."))
        os.exit(0)
    end
end

main()
