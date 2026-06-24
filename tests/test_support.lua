local manifest = require("manifest")

local M = {}

local function mask_has_bit(mask, index)
    return math.floor(mask / (2 ^ (index - 1))) % 2 == 1
end

function M.get_modules()
    local modules = {}
    for _, method in ipairs(manifest.modules_by_bit_position()) do
        modules[#modules + 1] = {
            name = method.config_key,
            label = method.config_key,
            path = "settings." .. method.config_key .. ".enabled",
        }
    end

    -- Watermark is not a manifest module, but the historical combination tests
    -- exercise it as the final synthetic bit.
    modules[#modules + 1] = {
        name = "watermark",
        label = "watermark",
        path = "settings.watermark_enabled",
    }

    return modules
end

function M.get_module_paths(modules)
    local paths = {}
    for _, module in ipairs(modules) do
        paths[module.name] = module.path
    end
    return paths
end

function M.set_all_modules(config, modules, mask)
    for i = 1, #modules do
        config.set(modules[i].path, mask_has_bit(mask, i))
    end
end

function M.disable_all(config, modules)
    for _, module in ipairs(modules) do
        config.set(module.path, false)
    end
end

function M.mask_to_modules(modules, mask)
    local selected = {}
    for i = 1, #modules do
        if mask_has_bit(mask, i) then
            selected[#selected + 1] = modules[i].label
        end
    end
    return selected
end

function M.modules_to_label(modules)
    return table.concat(modules, "+")
end

return M
