-- modules/watermark.lua
local Watermark = {}

function Watermark.process(code)
    return "--[Obfuscated by Hercules v1.6.3 | hercules-obfuscator.xyz/discord | hercules-obfuscator.xyz/source]\n" .. code
end

return Watermark