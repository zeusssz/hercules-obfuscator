package.path = "./src/?.lua;./src/?/init.lua;./tests/?.lua;./tests/?/init.lua;" .. package.path

if not math.ldexp then math.ldexp = function(x, n) return x * 2 ^ n end end
if not math.frexp then math.frexp = function(x)
    if x == 0 then return 0, 0 end
    local exp = math.floor(math.log(math.abs(x)) / math.log(2)) + 1
    return x / 2 ^ exp, exp
end end

local manifest = require("manifest")

local VALID_TARGETS = { lua = true, luau = true, glua = true }

local function assert_eq(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
    end
end

local function assert_type(value, expected, message)
    assert_eq(type(value), expected, message)
end

local function assert_unique(seen, value, label)
    if seen[value] then
        error(string.format("duplicate %s: %s", label, tostring(value)))
    end
    seen[value] = true
end

local function assert_snake_case(value, label)
    if not value:match("^[a-z][a-z0-9_]*$") then
        error(label .. " must be snake_case: " .. value)
    end
end

local function validate_manifest_shape()
    assert_type(manifest.version, "number", "manifest.version")
    assert_type(manifest.output, "table", "manifest.output")
    assert_type(manifest.output.suffix, "string", "manifest.output.suffix")
    assert_type(manifest.output.watermark_enabled, "boolean", "manifest.output.watermark_enabled")
    assert_type(manifest.output.watermark_text, "string", "manifest.output.watermark_text")
    assert_type(manifest.output.final_print, "boolean", "manifest.output.final_print")
    assert_type(manifest.modules, "table", "manifest.modules")
    assert(#manifest.modules > 0, "manifest.modules must not be empty")

    local seen = {
        key = {}, config_key = {}, module = {}, bit_position = {},
        pipeline_order = {}, cli_short = {}, cli_long = {},
    }

    for index, method in ipairs(manifest.modules) do
        local prefix = "manifest.modules[" .. index .. "]"
        assert_type(method.key, "string", prefix .. ".key")
        assert_type(method.config_key, "string", prefix .. ".config_key")
        assert_type(method.name, "string", prefix .. ".name")
        assert_type(method.module, "string", prefix .. ".module")
        assert_type(method.enabled, "boolean", prefix .. ".enabled")
        assert_type(method.bit_position, "number", prefix .. ".bit_position")
        assert_type(method.pipeline_order, "number", prefix .. ".pipeline_order")
        assert_type(method.cli, "table", prefix .. ".cli")
        assert_type(method.cli.short, "string", prefix .. ".cli.short")
        assert_type(method.cli.long, "string", prefix .. ".cli.long")
        assert_type(method.incompatible_with, "table", prefix .. ".incompatible_with")
        assert_type(method.description, "string", prefix .. ".description")

        assert_snake_case(method.key, prefix .. ".key")
        assert(method.cli.short:match("^%-[^%-]"), prefix .. ".cli.short must start with a single dash")
        assert(method.cli.long:match("^%-%-"), prefix .. ".cli.long must start with two dashes")

        for _, target in ipairs(method.incompatible_with) do
            assert(VALID_TARGETS[target], prefix .. ".incompatible_with contains invalid target: " .. tostring(target))
        end

        assert_unique(seen.key, method.key, "key")
        assert_unique(seen.config_key, method.config_key, "config_key")
        assert_unique(seen.module, method.module, "module")
        assert_unique(seen.bit_position, method.bit_position, "bit_position")
        assert_unique(seen.pipeline_order, method.pipeline_order, "pipeline_order")
        assert_unique(seen.cli_short, method.cli.short, "cli.short")
        assert_unique(seen.cli_long, method.cli.long, "cli.long")

        local ok, loaded = pcall(require, method.module)
        assert(ok, prefix .. ".module must be require-able: " .. tostring(loaded))
        assert_type(loaded.process, "function", prefix .. ".module.process")
    end
end

local function test_dummy_module_internal_detection()
    local extra = dofile("tests/extra_manifest.lua")
    local dummy = extra.modules[1]
    manifest.modules[#manifest.modules + 1] = dummy

    package.loaded.config = nil
    package.loaded.pipeline = nil
    local config = require("config")
    local Pipeline = require("pipeline")

    for _, method in ipairs(manifest.modules) do
        config.set("settings." .. method.config_key .. ".enabled", false)
    end
    config.set("settings.watermark_enabled", false)
    assert(config.get("settings.dummy_test_module.enabled") == false, "dummy config entry missing")
    config.set("settings.dummy_test_module.enabled", true)

    _G.__hercules_dummy_module_ran = false
    local code = Pipeline.process("")
    local fn, load_err = load(code)
    assert(fn, tostring(load_err))
    fn()
    assert(_G.__hercules_dummy_module_ran == true, "dummy module was not executed")

    manifest.modules[#manifest.modules] = nil
    package.loaded.config = nil
    package.loaded.pipeline = nil
end

local function test_dummy_module_cli_export()
    local lua = os.getenv("LUA_BIN") or "lua5.4"
    local command = 'cd src && HERCULES_MANIFEST_EXTRA="../tests/extra_manifest.lua" ' .. lua .. ' hercules.lua --manifest-json'
    local handle = io.popen(command)
    assert(handle, "failed to run manifest export command")
    local output = handle:read("*a")
    local ok = handle:close()
    assert(ok, "manifest export command failed")
    assert(output:find('"key":"dummy_test_module"', 1, true), "dummy key missing from manifest JSON")
    assert(output:find('"long":"--dummy_test_module"', 1, true), "dummy CLI flag missing from manifest JSON")
end

validate_manifest_shape()
test_dummy_module_internal_detection()
test_dummy_module_cli_export()

print("manifest tests passed")
