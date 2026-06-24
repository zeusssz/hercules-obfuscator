--pipeline.lua
local config = require("config")
local manifest = require("manifest")

local Watermarker = require("modules/watermark")

local Pipeline = {}
local pipeline_methods = manifest.modules_by_pipeline()
local processor_cache = {}

local function is_enabled(method)
    local settings = config.settings[method.config_key]
    return settings and settings.enabled
end

local function apply_method(method, code)
    local processor = processor_cache[method.module]
    if not processor then
        local ok, loaded = pcall(require, method.module)
        if not ok then
            error("Failed to load module " .. method.module .. ": " .. tostring(loaded))
        end
        processor = loaded
        processor_cache[method.module] = processor
    end

    if method.process then
        return method.process(processor, code, config)
    end
    return processor.process(code)
end

function Pipeline.process(code)
    for _, method in ipairs(pipeline_methods) do
        if is_enabled(method) and not manifest.is_incompatible(method, config.target) then
            code = apply_method(method, code)
        end
    end

    -- Watermark is always last and intentionally not exposed as an API bitkey.
    if config.get("settings.watermark_enabled") then
        code = Watermarker.process(code)
    end

    return code
end

return Pipeline
