-- config.lua

local manifest = require("manifest")

local config = {}

config.target = "lua"  -- "lua", "luau", or "glua"

config.settings = {
    output_suffix = manifest.output.suffix,
    watermark_enabled = manifest.output.watermark_enabled,
    watermark_text = manifest.output.watermark_text,
    watermark_module_file = nil,
    final_print = manifest.output.final_print,
}

for _, method in ipairs(manifest.modules) do
    local settings = manifest.copy(method.settings or {})
    settings.enabled = method.enabled
    settings.incompatible_with = manifest.copy(method.incompatible_with or {})
    config.settings[method.config_key] = settings
end

function config.get(key)
    local keys = {}
    for k in key:gmatch("[^.]+") do table.insert(keys, k) end

    local value = config
    for _, k in ipairs(keys) do
        value = value[k]
        if value == nil then
            return nil
        end
    end
    return value
end

function config.set(key, new_value)
    local keys = {}
    for k in key:gmatch("[^.]+") do table.insert(keys, k) end

    local value = config
    for i = 1, #keys - 1 do
        value = value[keys[i]]
        if value == nil then
            return false
        end
    end

    local last_key = keys[#keys]
    if value[last_key] ~= nil or last_key == "watermark_module_file" then
        value[last_key] = new_value
        return true
    else
        return false
    end
end

return config
