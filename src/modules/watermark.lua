-- modules/watermark.lua
local Watermark = {}

function Watermark.process(code)
    return "--[Obfuscated by Hercules v1.5 | discord.gg/Hx6RuYs8Ku]\n" .. code
end

return Watermark
