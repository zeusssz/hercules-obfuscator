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
    },
    opaque_predicates = {
        enabled = true,
    },
    function_inlining = {
        enabled = true,
    },
    dynamic_code = {
        enabled = true,
    },
    bytecode_encoding = {
        enabled = true,
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

--[[
TODO: cleanup. (@xthrx0)
TODO: fix garbage code (@xthrx0, @zeusssz)
TODO: patch issues, release GUI (@zeusssz)
TODO: clean this file (@xthrx0)
TODO: fix bytecode mutator (@xthrx0)
]]--

