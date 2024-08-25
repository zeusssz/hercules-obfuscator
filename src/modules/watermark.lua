-- modules/watermark.lua
local Watermark = {}

function Watermark.add_watermark(code)
    return "--[Obfuscated by Shitface]\n" .. code
end

return Watermark
