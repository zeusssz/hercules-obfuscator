-- config.lua

local config = {}

config.settings = {
    output_suffix = "_obfuscated.lua",
    watermark_enabled = true,
    control_flow = {
        enabled = true,
        max_fake_blocks = 5,
    },
    string_encoding = {
        enabled = true,
        encoding_type = 'base64',
    },
    variable_renaming = {
        enabled = true,
        min_name_length = 8,
        max_name_length = 12,
    },
    garbage_code = {
        enabled = true,
        garbage_blocks = 3,
    }
}

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

return config
