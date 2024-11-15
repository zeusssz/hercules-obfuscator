local stringtoexpressions = {}
local math_methods = {
    add_sub = function(char, base1, base2)
        local base = math.random(base1, base2)
        local chance = math.random(0, 1)
        local add_sub_expression = chance == 1 and string.format("%d - %d", base, base - char) or string.format("%d + %d", char - base, base)
        return add_sub_expression
    end,
}

local function obfuscate_string_literal(str, base1, base2)
    if #str == 0 then
        return '""' 
    end

    local obfuscated = {}
    for i = 1, #str do
        local char = str:byte(i)
        local part = math_methods.add_sub(char, base1, base2)
        table.insert(obfuscated, "string.char(" .. part .. ")")
    end
    return table.concat(obfuscated, "..")
end

function stringtoexpressions.process(script_content, base1, base2)
    return script_content:gsub("(['\"])(.-)%1", function(_, str)
        return obfuscate_string_literal(str, base1, base2)
    end)
end

return stringtoexpressions
