-- modules/compressor.lua
local Compressor = {}

local function compressLuaCode(code)
    local compressedCode = code:gsub("%-%-[^\n]*", "")
    compressedCode = compressedCode:gsub("%-%-%[(.-)%]%]", "")
    compressedCode = compressedCode:gsub("%s+", " ")
    compressedCode = compressedCode:gsub("([%S])\n([%S])", "%1 %2")
    return compressedCode:match("^%s*(.-)%s*$")
end

function Compressor.process(code)
    return compressLuaCode(code)
end

return Compressor