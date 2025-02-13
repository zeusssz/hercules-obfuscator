-- modules/watermark.lua
local Watermark = {}

function Watermark.process(code)
    return "--[Obfuscated by Hercules v1.6.2 | github.com/zeusssz/hercules-obfuscator | .gg/placeholder]\n" .. code
end

return Watermark
