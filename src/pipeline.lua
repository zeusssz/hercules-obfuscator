--pipeline.lua
local config = require("config")
local manifest = require("manifest")

local Watermarker = require("modules/watermark")

local Pipeline = {}

local function is_enabled(method)
    return config.get("settings." .. method.config_key .. ".enabled")
end

local function apply_method(method, code)
    local ok, processor = pcall(require, method.module)
    if not ok then
        error("Failed to load module " .. method.module .. ": " .. tostring(processor))
    end

    if method.process then
        return method.process(processor, code, config)
    end
    return processor.process(code)
end

function Pipeline.process(code)
    for _, method in ipairs(manifest.modules_by_pipeline()) do
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
