#!/usr/bin/env lua
-- test.lua — End-to-end test suite for Hercules Obfuscator
-- Runs real obfuscation against real Lua fixtures and verifies output.
-- Tests ALL 2^14 = 16384 module combinations against all fixtures.
-- Run from src/:  lua test.lua

-- ─── Polyfills for Lua 5.4 (math.ldexp/frexp removed in 5.3+) ─────────────────
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

-- ─── Test Runner ───────────────────────────────────────────────────────────────
local ALL_FIXTURES = fixtures.get_all()
local total_start = os.clock()

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

-- Phase 0: Quick mode — baseline + working single modules + working module combos
register("quick_combo", function()
    -- Baseline
    disable_all()
    for _, f in ipairs(ALL_FIXTURES) do
        local result = Pipeline.process(f.code)
        local out, err = capture_output(result)
        assert(err == nil, string.format("baseline %s: %s", f.name, err))
        assert(out == f.expected, string.format("baseline %s mismatch: got %q, expected %q", f.name, out, f.expected))
    end

    -- Single modules (6 working only)
    local working_singles = {"string_encoding", "garbage_code", "control_flow", "compressor", "WrapInFunction", "watermark"}
    for _, mod in ipairs(working_singles) do
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

    -- Working module combinations (6 working modules = 2^6 = 64 combos, minus empty = 63)
    for mask = 1, 2 ^ #working_singles - 1 do
        disable_all()
        for j = 1, #working_singles do
            if (mask >> (j - 1)) & 1 == 1 then
                config.set(MODULE_PATHS[working_singles[j]], true)
            end
        end
        for _, f in ipairs(ALL_FIXTURES) do
            local ok, result = pcall(function() return Pipeline.process(f.code) end)
            assert(ok, string.format("combo %s %s: pipeline error", modules_to_label(mask_to_modules(mask)), f.name))
            local load_ok, load_err = load(result, "=test", "t")
            assert(load_ok, string.format("combo %s %s: invalid Lua: %s", modules_to_label(mask_to_modules(mask)), f.name, load_err))
            local out, err = capture_output(result)
            assert(err == nil, string.format("combo %s %s: exec error: %s", modules_to_label(mask_to_modules(mask)), f.name, err))
            assert(out == f.expected, string.format("combo %s %s: mismatch got %q expected %q", modules_to_label(mask_to_modules(mask)), f.name, out, f.expected))
        end
    end
end)

-- Phase 1: FULL — All 2^14 combinations against all fixtures
register("full_combinations", function()
    local total = 0
    local pass_combos = 0
    local fail_combos = 0

    -- Track failure categories by module
    local fail_by_module = {}
    for _, m in ipairs(ALL_MODULES) do fail_by_module[m] = 0 end
    local fail_by_pair = {}
    local fail_first_fixture = {}  -- first fixture that caused failure per combo

    local max_fail_details = 50  -- cap detail output
    local fail_details = {}

    -- Skip mask 0 (no modules) — that's the baseline
    for mask = 1, NUM_COMBOS - 1 do
        local mods = mask_to_modules(mask)
        local label = modules_to_label(mods)
        set_all_modules(mask)

        local combo_ok = true
        local first_fail_fixture = nil
        local first_fail_reason = nil

        for _, f in ipairs(ALL_FIXTURES) do
            total = total + 1

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

            -- Track which modules are involved in failures
            for _, m in ipairs(mods) do
                fail_by_module[m] = fail_by_module[m] + 1
            end
            -- Track pairs
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

    -- Report summary
    io.write(string.format("\n  Passed: %d / %d  |  Failed: %d / %d\n",
        pass_combos, NUM_COMBOS - 1, fail_combos, NUM_COMBOS - 1))

    io.write(string.format("  Total fixture executions: %d\n\n", total))

    -- Show failure breakdown by single module
    io.write("  Failures by module:\n")
    for _, m in ipairs(ALL_MODULES) do
        if fail_by_module[m] > 0 then
            io.write(string.format("    %-22s %d combos\n", m, fail_by_module[m]))
        end
    end

    -- Show top failure pairs
    io.write("\n  Top failing pairs:\n")
    local sorted_pairs = {}
    for pair, count in pairs(fail_by_pair) do
        sorted_pairs[#sorted_pairs + 1] = { pair = pair, count = count }
    end
    table.sort(sorted_pairs, function(a, b) return a.count > b.count end)
    for i = 1, math.min(20, #sorted_pairs) do
        io.write(string.format("    %-45s %d combos\n", sorted_pairs[i].pair, sorted_pairs[i].count))
    end

    -- Show sample failed combos
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

-- Phase 4: Fixture-specific full combination sweep (--fixture <name>)
local function register_fixture_sweep(fixture_name, fixture)
    register("fixture_sweep_" .. fixture_name, function()
        local pass, fail = 0, 0
        for mask = 1, NUM_COMBOS - 1 do
            local mods = mask_to_modules(mask)
            local label = modules_to_label(mods)
            set_all_modules(mask)

            local ok, result = pcall(function() return Pipeline.process(fixture.code) end)
            if not ok or type(result) ~= "string" then
                fail = fail + 1
            else
                local load_ok = load(result, "=test", "t") ~= nil
                if not load_ok then
                    fail = fail + 1
                else
                    local out, err = capture_output(result)
                    if err or out ~= fixture.expected then
                        fail = fail + 1
                    else
                        pass = pass + 1
                    end
                end
            end
        end
        io.write(string.format("  %s: %d/%d combos pass\n", fixture_name, pass, NUM_COMBOS - 1))
        if fail > 0 then
            error(string.format("%d combinations failed for fixture %s", fail, fixture_name))
        end
    end)
end

for _, f in ipairs(ALL_FIXTURES) do
    register_fixture_sweep(f.name, f)
end

-- Phase 5: Compressor-specific
register("compressor_removes_comments", function()
    disable_all()
    config.set(MODULE_PATHS["compressor"], true)
    local result = Pipeline.process("-- comment\nprint('hi')\n-- footer\n")
    assert(not result:find("%-%-"), "compressor should remove comments")
end)

register("compressor_collapses_whitespace", function()
    disable_all()
    config.set(MODULE_PATHS["compressor"], true)
    local result = Pipeline.process("print(  'hello'  )")
    assert(not result:find("  "), "compressor should collapse multiple spaces")
end)

-- Phase 6: Garbage Code scale
register("garbage_code_scales", function()
    disable_all()
    config.set(MODULE_PATHS["garbage_code"], true)
    local r1 = Pipeline.process("print('hi')")
    config.settings.garbage_code.garbage_blocks = 50
    local r2 = Pipeline.process("print('hi')")
    assert(#r2 > #r1, "more garbage blocks should produce longer output")
end)

-- Phase 7: Watermark presence
register("watermark_present_when_enabled", function()
    disable_all()
    config.set(MODULE_PATHS["watermark"], true)
    local result = Pipeline.process("print('hi')")
    assert(result:find("Obfuscated by Hercules"), "watermark should be present when enabled")
end)

-- Phase 8: Config API
register("config_get_set", function()
    local orig = config.get("settings.compressor.enabled")
    config.set("settings.compressor.enabled", not orig)
    assert(config.get("settings.compressor.enabled") == not orig)
    config.set("settings.compressor.enabled", orig)
    assert(config.get("settings.compressor.enabled") == orig)
    assert(config.get("settings.nonexistent.key") == nil)
    assert(config.set("settings.nonexistent.key", true) == false)
end)

-- ─── Main ──────────────────────────────────────────────────────────────────────
local function main()
    local filters, group, list_only, verbose, quick, fixture_filter = parse_args()

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
                   t.name:match("^compressor_") or t.name:match("^garbage_") or
                   t.name:match("^watermark_") or t.name == "config_get_set" then
                    table.insert(filtered, t)
                elseif t.name:match("^single_") then
                    local mod = t.name:match("^single_(.+)$")
                    local known_broken = {dynamic_code=true, function_inlining=true,
                        opaque_predicates=true, bytecode_encoding=true, VirtualMachine=true,
                        antitamper=true, variable_renaming=true, StringToExpressions=true}
                    if not known_broken[mod] then
                        table.insert(filtered, t)
                    end
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
