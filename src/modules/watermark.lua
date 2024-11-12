-- modules/watermark.lua
local Watermark = {}

function Watermark.process(code)
    return "--[Obfuscated by Hercules v1.6 | discord.gg/Hx6RuYs8Ku (server deleted)]\n" .. code
end

return Watermark
