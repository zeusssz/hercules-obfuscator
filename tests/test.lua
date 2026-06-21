#!/usr/bin/env lua
-- test.lua — End-to-end test suite for Hercules Obfuscator
-- Tests ONLY output equivalence: obfuscated code must produce the same output as the original.
-- Tests ALL module combinations against all fixtures.
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
local manifest  = require("manifest")
local Pipeline  = require("pipeline")
local fixtures  = require("test_fixtures")
local test_support = require("test_support")

-- ─── Normalize Output ──────────────────────────────────────────────────────────
-- Lua 5.4 prints floats as "4.0" while Lua 5.1 would print "4".
local function normalize_output(s)
    if not s then return s end
    return s:gsub("(%d+)%.(0+) ", "%1 ")
              :gsub("(%d+)%.(0+)$", "%1")
              :gsub("(%d+)%.(0+)", "%1")
end

-- ─── Capture Output ────────────────────────────────────────────────────────────
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

local function capture_output(code)
    local f, load_err = load(code, "=test", "t")
    if not f then return nil, "compile error: " .. tostring(load_err) end
    return capture_loaded(f)
end

-- ─── All Modules (manifest bit order + synthetic watermark bit) ────────────────
local TEST_MODULES = test_support.get_modules()
local ALL_MODULES = {}
for _, module in ipairs(TEST_MODULES) do
    ALL_MODULES[#ALL_MODULES + 1] = module.name
end
local NUM_MODULES = #ALL_MODULES
local NUM_COMBOS  = 2 ^ NUM_MODULES

local MODULE_PATHS = test_support.get_module_paths(TEST_MODULES)

local function set_all_modules(mask)
    test_support.set_all_modules(config, TEST_MODULES, mask)
end

local function mask_to_modules(mask)
    return test_support.mask_to_modules(TEST_MODULES, mask)
end

local function modules_to_label(mods)
    return test_support.modules_to_label(mods)
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
    test_support.disable_all(config, TEST_MODULES)
end

local function enable_preset_methods(preset_key)
    disable_all()
    local selected = {}
    for _, preset in ipairs(manifest.presets) do
        if preset.key == preset_key then
            for _, method_key in ipairs(preset.methods or {}) do
                selected[method_key] = true
            end
            break
        end
    end
    for _, method in ipairs(manifest.modules) do
        config.set(
            "settings." .. method.config_key .. ".enabled",
            selected[method.key] and not manifest.is_incompatible(method, config.target)
        )
    end
end

local function make_object()
    return setmetatable({}, {
        __index = function(t, key)
            local value = function() return make_object() end
            rawset(t, key, value)
            return value
        end,
        __call = function() return make_object() end,
    })
end

local function capture_with_env(code, env)
    local output = {}
    env.print = function(...)
        local args = { ... }
        for i, v in ipairs(args) do args[i] = tostring(v) end
        output[#output + 1] = table.concat(args, "\t")
    end
    env._G = env
    setmetatable(env, { __index = _G })
    local fn, load_err = load(code, "=maximum_smoke", "t", env)
    if not fn then return nil, "compile error: " .. tostring(load_err) end
    local ok, err = pcall(fn)
    if not ok then return nil, tostring(err) end
    return normalize_output(table.concat(output, "\n")), nil
end

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function run_shell_command(command)
    local handle = io.popen(command .. " 2>&1")
    if not handle then
        return false, "popen failed", nil
    end

    for line in handle:lines() do
        print(line)
    end

    local ok, exit_type, code = handle:close()
    return ok == true, exit_type, code
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

    -- Single modules
    for _, mod in ipairs(ALL_MODULES) do
        disable_all()
        config.set(MODULE_PATHS[mod], true)
        for _, f in ipairs(ALL_FIXTURES) do
            local ok, result = pcall(function() return Pipeline.process(f.code) end)
            assert(ok, string.format("single %s %s: pipeline error: %s", mod, f.name, tostring(result)))
            local load_ok, load_err = load(result, "=test", "t")
            assert(load_ok, string.format("single %s %s: invalid Lua: %s", mod, f.name, load_err))
            local out, err = capture_loaded(load_ok)
            assert(err == nil, string.format("single %s %s: exec error: %s", mod, f.name, err))
            assert(out == f.expected, string.format("single %s %s: mismatch got %q expected %q", mod, f.name, out, f.expected))
        end
    end
end)

-- Phase 1: FULL — All module combinations against all fixtures (output-only verification)
register("full_combinations", function()
    local python = os.getenv("PYTHON_BIN") or "python3"
    for _, f in ipairs(ALL_FIXTURES) do
        local command = string.format(
            "%s tests/fixture_sweep_parallel.py %s",
            shell_quote(python),
            shell_quote(f.name)
        )
        local ok, exit_type, code = run_shell_command(command)
        if ok ~= true then
            error(string.format(
                "full combination sweep failed for %s (%s %s)",
                f.name,
                tostring(exit_type),
                tostring(code)
            ))
        end
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

register("maximum_smoke_lua_fixture", function()
    local orig_target = config.target
    config.target = "lua"
    enable_preset_methods("maximum")
    math.randomseed(12345)
    local result = Pipeline.process(fixtures.main_script.code)
    local out, err = capture_output(result)
    config.target = orig_target
    assert(err == nil, string.format("maximum lua exec error: %s", tostring(err)))
    assert(out == fixtures.main_script.expected, string.format("maximum lua mismatch got %q expected %q", out, fixtures.main_script.expected))
end)

register("maximum_smoke_glua_stub", function()
    local orig_target = config.target
    config.target = "glua"
    enable_preset_methods("maximum")
    math.randomseed(12345)

    local source = [[
hook.Add("PlayerSpawn", "SmokeHook", function(ply)
    if not IsValid(ply) then return end
    ply:SetNWFloat("spawn_time", CurTime())
end)
ENT = ENT or {}
ENT.Type = "anim"
function ENT:Initialize()
    self:SetModel("models/props_c17/oildrum001.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
end
if SERVER then
    util.AddNetworkString("SmokeNet")
    net.Receive("SmokeNet", function(len, ply) print("recv", ply:Nick()) end)
end
local crc = util.CRC("glua_smoke")
print("glua-ok", crc, CurTime())
]]
    local result = Pipeline.process(source)
    local env = {
        hook = { Add = function() end },
        util = { AddNetworkString = function() end, CRC = function() return "crc" end },
        net = { Receive = function() end, Start = function() end, SendToServer = function() end },
        IsValid = function(v) return v ~= nil end,
        CurTime = function() return 123 end,
        Color = function() return make_object() end,
        Vector = function() return make_object() end,
        Angle = function() return make_object() end,
        SERVER = true,
        CLIENT = false,
        ENT = {},
        SOLID_VPHYSICS = 1,
    }
    local out, err = capture_with_env(result, env)
    config.target = orig_target
    assert(err == nil, string.format("maximum glua stub error: %s", tostring(err)))
    assert(out == "glua-ok\tcrc\t123", string.format("maximum glua stub mismatch: %q", tostring(out)))
end)

register("maximum_smoke_luau_stub", function()
    local orig_target = config.target
    config.target = "luau"
    enable_preset_methods("maximum")
    math.randomseed(12345)

    local source = [[
local game = { GetService = function(_, name) return { Name = name } end }
local Instance = { new = function(class) return { ClassName = class } end }
local workspace = {}
local Players = game:GetService("Players")
local part = Instance.new("Part")
part.Name = "Smoke"
part.Parent = workspace
print("luau-ok", Players.Name, part.Name)
]]
    local result = Pipeline.process(source)
    local env = {
        game = { GetService = function(_, name) return { Name = name } end },
        Instance = { new = function(class) return { ClassName = class } end },
        workspace = {},
        task = { spawn = function(fn) return fn() end, wait = function() end },
        Vector3 = { new = function() return make_object() end },
        CFrame = { new = function() return make_object() end, Angles = function() return make_object() end },
    }
    local out, err = capture_with_env(result, env)
    config.target = orig_target
    assert(err == nil, string.format("maximum luau stub error: %s", tostring(err)))
    assert(out == "luau-ok\tPlayers\tSmoke", string.format("maximum luau stub mismatch: %q", tostring(out)))

    local probe = io.popen("command -v luau 2>/dev/null")
    local luau = probe and probe:read("*l") or nil
    if probe then probe:close() end
    if luau and luau ~= "" then
        local tmp = os.tmpname() .. ".luau"
        local handle = assert(io.open(tmp, "w"))
        handle:write(result)
        handle:close()
        local runner = io.popen(string.format("%q %q 2>&1", luau, tmp))
        local luau_output = runner and runner:read("*a") or ""
        local ok = runner and runner:close()
        os.remove(tmp)
        assert(ok, string.format("maximum luau interpreter failed:\n%s", luau_output))
        assert(normalize_output(luau_output):match("luau%-ok%s+Players%s+Smoke"),
            string.format("maximum luau interpreter mismatch:\n%s", luau_output))
    end
end)

-- Phase 3: Single module semantics
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
            local out, exec_err = capture_loaded(load_ok)
            assert(exec_err == nil, string.format("%s %s: exec error: %s", mod, f.name, exec_err))
            assert(out == f.expected, string.format("%s %s: mismatch got %q expected %q", mod, f.name, out, f.expected))
        end
    end)
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
        local ok, exit_type, code = run_shell_command(command)
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

register("dynamic_code_table_field_boundary", function()
    local DynamicCodeGenerator = require("modules/dynamic_code_generator")
    local source = [[
local CONFIG = {
    Title = "ALTER",
    Instructions = "Get a key below",
    JunkieService = "Alter",
    JunkieIdentifier = "1127751",
    JunkieProvider = "Linkvertise 12H",
}

print(CONFIG.Title)
]]
    local output = DynamicCodeGenerator.process(source)

    -- Table field lines MUST NOT be wrapped (they are inside {})
    for line in output:gmatch("[^\n]+") do
        if line:match("Title%s*=") or line:match("Instructions%s*=") or
           line:match("JunkieService%s*=") or line:match("JunkieIdentifier%s*=") or
           line:match("JunkieProvider%s*=") then
            assert(not line:match("do %(function%("),
                "do-block in expression context (table field): " .. line)
        end
    end

    -- Normal statement outside table should still be wrapped
    assert(output:match("do %(function%(%) print%(CONFIG%.Title%) end%)%(%) end"),
        "expected print(CONFIG.Title) to be wrapped, got:\n" .. output)

    local fn, load_err = load(output, "=dynamic_code_table_field_boundary", "t")
    assert(fn, tostring(load_err) .. "\n" .. output)
    local out, exec_err = capture_output(output)
    assert(exec_err == nil, tostring(exec_err))
    assert(out == "ALTER", string.format("expected ALTER, got %q", tostring(out)))
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

-- ─── Regression: function() IIFE boundary ────────────────────────────────────
-- After inlining, function() (empty param list) must NOT get ; inserted before
-- (function(...) on the next line. This was a Luau SyntaxError: Expected
-- identifier when parsing expression, got ';' at function();(function( sites.

register("regression_function_iife_boundary", function()
    local FunctionInliner = require("modules/function_inliner")
    local Compressor = require("modules/compressor")

    local function assert_loadable(label, code)
        local fn, err = load(code, "=t_" .. label, "t")
        assert(fn, string.format("%s: invalid Lua: %s\n%s", label, err, code))
        return fn, code
    end

    -- Test A: function_inliner must NOT produce function()(function or function();(function
    -- Source: a recursive no-param function (won't be inlined) whose definition
    -- remains, creating a line ending with function() followed by an IIFE.
    local source_a = [[
local function counter()
    local c = 0
    return function()
        c = c + 1
        return c
    end
end

local function show()
    local c = counter()
    (function()
        print(c())
    end)()
end

show()
]]
    local result_a = FunctionInliner.process(source_a)
    assert_loadable("fi_a", result_a)
    assert(not result_a:match("function%(%)%(function"),
        string.format("FIX 1 FAIL: function_inliner produced 'function()(function' pattern:\n%s", result_a))
    assert(not result_a:match("function%(%)%s*;"),
        string.format("FIX 2 FAIL: function_inliner produced 'function();' pattern:\n%s", result_a))

    -- Test B: function_inliner must handle )()(function adjacency correctly
    -- Source: two no-param functions inlined, producing adjacent IIFEs with () calls
    local source_b = [[
local function get_a()
    return "a"
end

local function get_b()
    return "b"
end

local function show()
    print(get_a() .. get_b())
end

show()
]]
    local result_b = FunctionInliner.process(source_b)
    assert_loadable("fi_b", result_b)
    -- The IIFE output should have end)()(function properly separated with ;
    -- But NOT function()(function
    assert(not result_b:match("function%(%)%(function"),
        string.format("FIX 3 FAIL: function_inliner produced 'function()(function' in source_b:\n%s", result_b))

    -- Test C: compressor must not insert ; after function keyword at end of line
    -- Construct input where function keyword ends a line and ( starts the next
    local source_c = [[
local x = (function()
    return 42
end
)(
    2
)
print(x)
]]
    local result_c = Compressor.process(source_c)
    assert_loadable("comp_c", result_c)
    assert(not result_c:match("function;"),
        string.format("FIX 4 FAIL: compressor produced 'function;' pattern:\n%s", result_c))

    -- Test D: compressor on function_inliner output must not produce function;(function
    local result_d = Compressor.process(result_a)
    assert_loadable("comp_d", result_d)
    assert(not result_d:match("function;"),
        string.format("FIX 5 FAIL: compressor on FI output produced 'function;':\n%s", result_d))

    -- Test E: Full pipeline with function_inlining + compressor + variable_renaming
    local orig_target = config.target
    config.target = "lua"
    disable_all()
    for _, key in ipairs({"function_inlining", "compressor", "variable_renaming"}) do
        config.set(MODULE_PATHS[key], true)
    end

    local source_e = [[
local function get_val()
    return 42
end

local function show()
    print(get_val())
end

show()
]]
    local ok_e, result_e = pcall(function() return Pipeline.process(source_e) end)
    assert(ok_e, string.format("FIX 6 FAIL: pipeline error: %s", tostring(result_e):sub(1, 150)))
    assert_loadable("pipeline_e", result_e)
    assert(not result_e:match("function%(%)%(function") and not result_e:match("function;"),
        string.format("FIX 7 FAIL: pipeline produced function()(function or function;:\n%s", result_e))

    -- Test F: Pipeline with the pattern from the original bug report
    -- (function_inlining + compressor + other common modules)
    disable_all()
    for _, key in ipairs({"function_inlining", "compressor", "variable_renaming",
        "string_encoding", "StringToExpressions", "garbage_code", "opaque_predicates"}) do
        config.set(MODULE_PATHS[key], true)
    end

    local source_f = [[
local function process(x)
    return x * 2
end

local function show()
    local result = process(21)
    (function()
        print(result)
    end)()
end

show()
]]
    local ok_f, result_f = pcall(function() return Pipeline.process(source_f) end)
    assert(ok_f, string.format("FIX 8 FAIL: pipeline advanced error: %s", tostring(result_f):sub(1, 150)))
    assert_loadable("pipeline_f", result_f)
    assert(not result_f:match("function%(%)%(function") and not result_f:match("function;"),
        string.format("FIX 9 FAIL: advanced pipeline produced function()(function or function;:\n%s", result_f))

    config.target = orig_target
end)

-- ─── Regression: dot-notation property names ────────────────────────────────
-- Property names in dot-notation (.name) and colon-notation (:name) must NOT
-- be renamed by variable_renamer — they are string keys, not variable refs.
-- e.g. game:GetService("Players").LocalPlayer — LocalPlayer after '.' is a
-- property access, not a variable reference.

register("regression_dot_notation_property_names", function()
    local Renamer = require("modules/variable_renamer")

    local function assert_loadable(label, code)
        local fn, err = load(code, "=t_" .. label, "t")
        assert(fn, string.format("%s: invalid Lua: %s\n%s", label, err, code))
    end

    -- Test A: game.Players.LocalPlayer — property after dot must NOT be renamed
    local source_a = [[
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
print(Player)
]]
    local result_a = Renamer.process(source_a)
    -- Players (standalone var ref) should be renamed
    -- But .LocalPlayer (property after dot) must NOT be renamed
    assert(result_a:match("%.LocalPlayer"),
        string.format("FAIL A1: .LocalPlayer property was renamed:\n%s", result_a))
    assert(not result_a:match("local%s+Players%s*="),
        string.format("FAIL A2: 'Players' local var should be renamed:\n%s", result_a))
    assert_loadable("dot_a", result_a)

    -- Test B: obj:Method() — colon method call must NOT rename the method name
    local source_b = [[
local obj = {}
function obj:getValue()
    return 42
end
print(obj:getValue())
]]
    local result_b = Renamer.process(source_b)
    assert(result_b:match(":getValue%(%)"),
        string.format("FAIL B1: :getValue method name was renamed:\n%s", result_b))
    assert_loadable("dot_b", result_b)

    -- Test C: .. operator must NOT trigger property protection
    -- e.g. a .. b — the '..' concatenation operator should not protect 'b'
    local source_c = [[
local a = "hello"
local b = " world"
print(a .. b)
]]
    local result_c = Renamer.process(source_c)
    -- Both 'a' and 'b' should be renamed (they are local variables)
    -- The .. operator should be preserved
    assert(not result_c:match("local%s+a%s*="),
        string.format("FAIL C1: 'a' should be renamed:\n%s", result_c))
    assert(not result_c:match("local%s+b%s*="),
        string.format("FAIL C2: 'b' should be renamed:\n%s", result_c))
    assert_loadable("dot_c", result_c)

    -- Test D: table constructor keys must NOT be renamed (they are property names)
    local source_d = [[
local obj = {
    value = 10,
    name = "test",
}
local x = obj.value
print(x)
]]
    local result_d = Renamer.process(source_d)
    -- 'obj' (standalone) should be renamed
    -- But 'value' in obj.value (property) must NOT be renamed
    -- And 'value' in {value = 10} (table key) must NOT be renamed
    assert(result_d:match("%.value"),
        string.format("FAIL D1: .value property was renamed:\n%s", result_d))
    assert(result_d:match("value%s*="),
        string.format("FAIL D2: table key 'value' was renamed:\n%s", result_d))
    -- 'x' (standalone var) should be renamed
    assert(not result_d:match("local%s+x%s*="),
        string.format("FAIL D3: 'x' should be renamed:\n%s", result_d))
    assert_loadable("dot_d", result_d)

    -- Test E: Full pipeline with variable_renaming must preserve dot-notation
    local orig_target = config.target
    config.target = "lua"
    disable_all()
    for _, key in ipairs({"variable_renaming"}) do
        config.set(MODULE_PATHS[key], true)
    end

    local source_e = [[
local Players = game:GetService("Players")
print(Players.LocalPlayer)
]]
    local ok_e, result_e = pcall(function() return Pipeline.process(source_e) end)
    assert(ok_e, string.format("FAIL E1: pipeline error: %s", tostring(result_e):sub(1, 150)))
    assert(result_e:match("%.LocalPlayer"),
        string.format("FAIL E2: .LocalPlayer was renamed by pipeline:\n%s", result_e))
    assert_loadable("dot_e", result_e)

    config.target = orig_target
end)

-- ─── Regression: table constructor keys ────────────────────────────────────
-- Keys in {Key = value} form are literal identifiers (string keys), NOT
-- variable references. They must not be renamed even if a local variable
-- with the same name exists. e.g. TweenService:Create(obj, info, {Scale = 0.5})
-- must keep 'Scale' as the key.

register("regression_table_key_renaming", function()
    local Renamer = require("modules/variable_renamer")

    local function assert_loadable(label, code)
        local fn, err = load(code, "=t_" .. label, "t")
        assert(fn, string.format("%s: invalid Lua: %s\n%s", label, err, code))
    end

    -- Test A: {Scale = 0.5} — explicit key-value, key must NOT be renamed
    local source_a = [[
local UIScale = {}
local target = 0.5
TweenService:Create(UIScale, nil, {Scale = target})
]]
    local result_a = Renamer.process(source_a)
    assert(result_a:match("{[%s]*Scale%s*=") or result_a:match(",%s*Scale%s*="),
        string.format("FAIL A1: 'Scale' table key was renamed:\n%s", result_a))
    -- 'target' (standalone var) should be renamed
    assert(not result_a:match("local%s+target%s*="),
        string.format("FAIL A2: 'target' variable should be renamed:\n%s", result_a))
    assert_loadable("tblk_a", result_a)

    -- Test B: {Scale} — shorthand, no =, must still be renamed (IS a variable ref)
    local source_b = [[
local Scale = 0.5
local info = {Scale}
]]
    local result_b = Renamer.process(source_b)
    -- 'Scale' in {Scale} should be renamed because it's shorthand for {Scale = Scale}
    assert(not result_b:match("{[%s]*Scale[%s]*}"),
        string.format("FAIL B1: 'Scale' in shorthand should be renamed:\n%s", result_b))
    assert_loadable("tblk_b", result_b)

    -- Test C: {[Scale] = value} — computed key with brackets, Scale IS a var ref
    local source_c = [[
local prop = "Size"
local ui = {}
local val = 100
ui[prop] = val
]]
    local result_c = Renamer.process(source_c)
    -- 'prop' and 'val' should be renamed
    assert(not result_c:match("local%s+prop%s*="),
        string.format("FAIL C1: 'prop' should be renamed:\n%s", result_c))
    assert(not result_c:match("local%s+val%s*="),
        string.format("FAIL C2: 'val' should be renamed:\n%s", result_c))
    assert_loadable("tblk_c", result_c)

    -- Test D: Nested tables — keys at all levels must be preserved
    local source_d = [[
local config = {
    Display = {
        Scale = 1.0,
        Theme = "dark",
    },
    Audio = {
        Volume = 0.8,
    },
}
local x = config.Display.Scale
print(x)
]]
    local result_d = Renamer.process(source_d)
    assert(result_d:match("Display%s*="),
        string.format("FAIL D1: 'Display' table key was renamed:\n%s", result_d))
    assert(result_d:match("Scale%s*="),
        string.format("FAIL D2: 'Scale' table key was renamed:\n%s", result_d))
    assert(result_d:match("Theme%s*="),
        string.format("FAIL D3: 'Theme' table key was renamed:\n%s", result_d))
    assert(result_d:match("Volume%s*="),
        string.format("FAIL D4: 'Volume' table key was renamed:\n%s", result_d))
    -- Dot-notation property access should also be preserved
    assert(result_d:match("%.Display%.Scale"),
        string.format("FAIL D5: .Display.Scale property access was broken:\n%s", result_d))
    assert_loadable("tblk_d", result_d)

    -- Test E: Full pipeline with variable_renaming preserves table keys
    local orig_target = config.target
    config.target = "lua"
    disable_all()
    for _, key in ipairs({"variable_renaming"}) do
        config.set(MODULE_PATHS[key], true)
    end

    local source_e = [[
local TweenService = game:GetService("TweenService")
local UIScale = script.Parent.UIScale
TweenService:Create(UIScale, nil, {Scale = 0.5})
]]
    local ok_e, result_e = pcall(function() return Pipeline.process(source_e) end)
    assert(ok_e, string.format("FAIL E1: pipeline error: %s", tostring(result_e):sub(1, 150)))
    -- The table key 'Scale' must be preserved in the pipeline output
    assert(result_e:match("Scale%s*="),
        string.format("FAIL E2: 'Scale' table key was renamed by pipeline:\n%s", result_e))
    assert_loadable("tblk_e", result_e)

    config.target = orig_target
end)

register("regression_comma_separated_locals", function()
    local Renamer = require("modules/variable_renamer")

    local function assert_loadable(label, code)
        local fn, err = load(code, "=t_" .. label, "t")
        assert(fn, string.format("%s: invalid Lua: %s\n%s", label, err, code))
    end

    -- Test A: Basic comma-separated local — both vars must be renamed
    local source_a = [[
local CheckStroke, Junkie = 1, 2
print(CheckStroke + Junkie)
]]
    local result_a = Renamer.process(source_a)
    assert(not result_a:match("local%s+[%a_][%w_]*%s*,%s*Junkie"),
        string.format("FAIL A1: 'Junkie' (2nd in comma pair) not renamed:\n%s", result_a))
    assert(not result_a:match("CheckStroke"),
        string.format("FAIL A2: 'CheckStroke' should be renamed:\n%s", result_a))
    assert_loadable("comma_a", result_a)

    -- Test B: Comma-separated with table-key lookalike in same line
    local source_b = [[
local TweenService = game:GetService("TweenService")
local UIScale = script.Parent
local upTween, downTween = TweenService:Create(UIScale, nil, {Scale = 1.1}), nil
]]
    local result_b = Renamer.process(source_b)
    -- downTween (2nd in comma pair) must be renamed
    assert(not result_b:match("downTween"),
        string.format("FAIL B1: 'downTween' should be renamed:\n%s", result_b))
    -- Scale as table key {Scale = 1.1} must survive
    assert(result_b:match("Scale%s*="),
        string.format("FAIL B2: 'Scale' table key was renamed:\n%s", result_b))
    assert_loadable("comma_b", result_b)

    -- Test C: pcall() comma pattern
    local source_c = [[
local ok, err = pcall(function() return 1 end)
print(ok, err)
]]
    local result_c = Renamer.process(source_c)
    assert(not result_c:match("local%s+[%a_][%w_]*%s*,%s*err"),
        string.format("FAIL C1: 'err' (2nd in comma pair) not renamed:\n%s", result_c))
    assert_loadable("comma_c", result_c)

    -- Test D: Three-variable comma chain
    local source_d = [[
local a, b, c = 1, 2, 3
print(a, b, c)
]]
    local result_d = Renamer.process(source_d)
    assert(not result_d:match("local%s+[%a_][%w_]*%s*,%s*b%s*,"),
        string.format("FAIL D1: 'b' (2nd in triple comma) not renamed:\n%s", result_d))
    assert(not result_d:match("local%s+[%a_][%w_]*%s*,%s*[%a_][%w_]*%s*,%s*c[^%w_]"),
        string.format("FAIL D2: 'c' (3rd in triple comma) not renamed:\n%s", result_d))
    assert_loadable("comma_d", result_d)

    -- Test E: Full pipeline with all modules enabled
    local orig_target = config.target
    config.target = "lua"
    disable_all()
    for _, key in ipairs({"variable_renaming"}) do
        config.set(MODULE_PATHS[key], true)
    end
    local source_e = [[
local ok, err = pcall(function() return 1 end)
print(ok, err)
]]
    local ok_e, result_e = pcall(function() return Pipeline.process(source_e) end)
    assert(ok_e, string.format("FAIL E1: pipeline error: %s", tostring(result_e):sub(1, 150)))
    assert(not result_e:match("%f[%w_]err%f[^%w_]"),
        string.format("FAIL E2: 'err' survived full pipeline:\n%s", result_e))
    assert_loadable("comma_e", result_e)

    config.target = orig_target
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
                if t.name == "quick_combo" or t.name == "config_get_set" then
                    table.insert(filtered, t)
                end
            else
                if not t.name:match("^fixture_sweep_") then
                    table.insert(filtered, t)
                end
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
