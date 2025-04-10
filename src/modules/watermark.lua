-- modules/watermark.lua
local Watermark = {}

function Watermark.process(code)
    return "--[Obfuscated by Hercules v1.6.2 | zeusssz.github.io/hercules-discord/ | zeusssz/hercules-obfuscator]\n" .. code
end

return Watermark
