-- modules/watermark.lua
local config = require("config")

local Watermark = {}

function Watermark.process(code)
    local module_file = config.get("settings.watermark_module_file")
    if module_file and module_file ~= "" then
        local chunk, err = loadfile(module_file)
        if not chunk then
            error("Failed to load custom watermark module: " .. tostring(err))
        end
        local custom = chunk()
        if type(custom) ~= "table" or type(custom.process) ~= "function" then
            error("Custom watermark module must return a table with process(code)")
        end
        return custom.process(code)
    end

    local watermark = config.get("settings.watermark_text")
    if not watermark or watermark == "" then
        return code
    end
    if watermark:sub(-1) ~= "\n" then
        watermark = watermark .. "\n"
    end
    return watermark .. code
end

return Watermark
