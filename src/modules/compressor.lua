-- modules/compressor.lua
local Compressor = {}

local function compressLuaCode(code)
    local compressedCode = code:gsub("%-%-[^\n]*", ""):gsub("%-%-%[(=*)%[.-%]%1%]", "")
    compressedCode = compressedCode:gsub("%s+", " ")
    compressedCode = compressedCode:gsub("([%w_])%s*([=+%-*/%%<>~])%s*([%w_])", "%1%2%3")
    compressedCode = compressedCode:gsub("([=+%-*/%%<>~])%s*([%w_])", "%1%2")
    compressedCode = compressedCode:gsub("([%w_])%s*([=+%-*/%%<>~])", "%1%2")
    compressedCode = compressedCode:gsub("(%s*%f[%w]end%f[%W])", "end")
    compressedCode = compressedCode:gsub("(%f[%w]do%f[%W]%s+)", "do")
    compressedCode = compressedCode:gsub("(%f[%w]then%f[%W]%s+)", "then")
    compressedCode = compressedCode:gsub("(%f[%w]else%f[%W]%s+)", "else")
    compressedCode = compressedCode:gsub("(%f[%w]elseif%f[%W]%s+)", "elseif")
    compressedCode = compressedCode:gsub("%s*(%b())", "%1"):gsub("([%w_])%s*%(", "%1(")
    return compressedCode:match("^%s*(.-)%s*$")
end

function Compressor.process(code)
    return compressLuaCode(code)
end

return Compressor
