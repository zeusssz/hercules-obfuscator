-- modules/watermark.lua
local Watermark = {}

local function compressLuaCode(code)
    local compressedCode = code:gsub("%-%-[^\n]*", "")
    compressedCode = compressedCode:gsub("%-%-%[(.-)%]%]", "")
    compressedCode = compressedCode:gsub("%s+", " ")
    compressedCode = compressedCode:gsub("([%S])\n([%S])", "%1 %2")
    return compressedCode:match("^%s*(.-)%s*$")
end

function Watermark.add_watermark(code)
    local compressedCode = compressLuaCode(code)
    return "--[Obfuscated by Hercules]\n" .. compressedCode
end

return Watermark
