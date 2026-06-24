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
    assert_type(manifest.presets, "table", "manifest.presets")
    assert(#manifest.presets > 0, "manifest.presets must not be empty")
    assert_type(manifest.language_detection, "table", "manifest.language_detection")
    assert_type(manifest.language_detection.threshold, "number", "manifest.language_detection.threshold")
    assert_type(manifest.language_detection.languages, "table", "manifest.language_detection.languages")

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

    local method_keys = seen.key
    local preset_keys = {}
    for index, preset in ipairs(manifest.presets) do
        local prefix = "manifest.presets[" .. index .. "]"
        assert_type(preset.key, "string", prefix .. ".key")
        assert_type(preset.description, "string", prefix .. ".description")
        assert_type(preset.methods, "table", prefix .. ".methods")
        assert_snake_case(preset.key, prefix .. ".key")
        assert_unique(preset_keys, preset.key, "preset key")
        assert(#preset.methods > 0, prefix .. ".methods must not be empty")
        for _, method_key in ipairs(preset.methods) do
            assert(method_keys[method_key], prefix .. " references unknown method: " .. tostring(method_key))
        end
    end

    for _, language in ipairs({ "luau", "glua" }) do
        local language_config = manifest.language_detection.languages[language]
        assert_type(language_config, "table", "manifest.language_detection.languages." .. language)
        assert_type(language_config.patterns, "table", "manifest.language_detection.languages." .. language .. ".patterns")
        assert(#language_config.patterns > 0, language .. " detection patterns must not be empty")
        for index, item in ipairs(language_config.patterns) do
            local prefix = "manifest.language_detection.languages." .. language .. ".patterns[" .. index .. "]"
            assert_type(item.pattern, "string", prefix .. ".pattern")
            assert(item.lua_pattern or item.lua_patterns, prefix .. " must define lua_pattern or lua_patterns")
            assert_type(item.weight, "number", prefix .. ".weight")
            assert_type(item.description, "string", prefix .. ".description")
            assert(item.weight > 0, prefix .. ".weight must be positive")
            local patterns = item.lua_patterns or { item.lua_pattern }
            for _, pattern in ipairs(patterns) do
                local ok, err = pcall(function() return (""):find(pattern) end)
                assert(ok, prefix .. ".lua_pattern is invalid: " .. tostring(err))
            end
        end
    end
end

local function score_language(code, language)
    local language_config = manifest.language_detection.languages[language]
    local score = 0
    for _, item in ipairs(language_config.patterns or {}) do
        local matched = item.lua_pattern and code:match(item.lua_pattern)
        for _, pattern in ipairs(item.lua_patterns or {}) do
            matched = matched or code:match(pattern)
        end
        if matched then
            score = score + item.weight
        end
    end
    return score
end

local function detect_target(code, file_path)
    local threshold = manifest.language_detection.threshold
    local luau_score = score_language(code, "luau")
    local glua_score = score_language(code, "glua")

    if glua_score > luau_score and glua_score >= threshold then
        return "glua"
    elseif luau_score > glua_score and luau_score >= threshold then
        return "luau"
    elseif file_path and file_path:match("%.luau$") then
        return "luau"
    end

    return "lua"
end

local function test_language_detection()
    local roblox_code = [[
local WindUI = loadstring(game:HttpGet("https://example.com/main.lua"))()
local Window = WindUI:CreateWindow({
    Size = UDim2.fromOffset(480, 360),
    Theme = "Red",
})
task.spawn(function()
    local remote = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("BuyItemCash")
    remote:FireServer("Green Dino")
end)
local localPlayer = game:GetService("Players").LocalPlayer
local frame = Instance.new("Frame")
frame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
frame.Position = UDim2.new(0.55, 0, 0.25, 0)
]]

    local glua_code = [[
hook.Add("PlayerSpawn", "DetectionTestHook", function(ply)
    if not IsValid(ply) then return end
    util.AddNetworkString("DetectionTestNet")
    net.Receive("DetectionTestNet", function(len, sender) print(sender:Nick()) end)
end)
]]

    local lua_code = [[
local items = {"a", "b", "c"}
for i, item in ipairs(items) do
    print(i, item:upper())
end
]]

    assert_eq(detect_target(roblox_code, "script.lua"), "luau", "Roblox API code should detect as luau")
    assert_eq(detect_target(glua_code, "script.lua"), "glua", "Garry's Mod code should detect as glua")
    assert_eq(detect_target(lua_code, "script.lua"), "lua", "plain Lua code should stay lua")
    assert_eq(detect_target(lua_code, "script.luau"), "luau", ".luau files should default to luau")
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
    local lua = os.getenv("LUA_BIN") or "lua"
    local command = 'cd src && HERCULES_MANIFEST_EXTRA="../tests/extra_manifest.lua" ' .. lua .. ' hercules.lua --manifest-json'
    local handle = io.popen(command)
    assert(handle, "failed to run manifest export command")
    local output = handle:read("*a")
    local ok = handle:close()
    assert(ok, "manifest export command failed")
    assert(output:find('"key":"dummy_test_module"', 1, true), "dummy key missing from manifest JSON")
    assert(output:find('"long":"--dummy_test_module"', 1, true), "dummy CLI flag missing from manifest JSON")
    assert(output:find('"presets"', 1, true), "presets missing from manifest JSON")
    assert(output:find('"language_detection"', 1, true), "language detection missing from manifest JSON")
end

validate_manifest_shape()
test_language_detection()
test_dummy_module_internal_detection()
test_dummy_module_cli_export()

print("manifest tests passed")
