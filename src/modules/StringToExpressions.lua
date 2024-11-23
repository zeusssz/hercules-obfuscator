local stringtoexpressions = {}
local math_methods = {
    add_sub = function(char, base1, base2)
        local base = math.random(base1, base2)
        local chance = math.random(0, 1)
        local add_sub_expression = chance == 1 and string.format("%d - (%d)", base, base - char) or string.format("%d + %d", char - base, base)
        return add_sub_expression
    end,
}

local function insert_char(obfuscated, ascii_code, base1, base2)
    local part = math_methods.add_sub(ascii_code, base1, base2)
    table.insert(obfuscated, "string.char(" .. part .. ")")
end

local function obfuscate_string_literal(str, base1, base2)
    if #str == 0 then
        return '""'
    end

    local escape_chars = {
        n = 10, -- ASCII code for \n
        r = 13, -- ASCII code for \r
        t = 9   -- ASCII code for \t
    }

    local obfuscated = {}
    local i = 1

    while i <= #str do
        local char_code = str:byte(i)
        -- look for control codes starting with \
        if char_code == 92 and i < #str then
            local next_char = str:sub(i + 1, i + 1)
            if next_char == "2" and str:sub(i+2,i+2) == "7" then
                insert_char(obfuscated, 27, base1, base2)
                i = i + 2
            elseif escape_chars[next_char] then
                insert_char(obfuscated, escape_chars[next_char], base1, base2)
                i = i + 1
            else
                insert_char(obfuscated, char_code, base1, base2)
                insert_char(obfuscated, next_char:byte(), base1, base2)
                i = i + 1
            end
        else
            insert_char(obfuscated, char_code, base1, base2)
        end
        i = i + 1
    end

    return table.concat(obfuscated, "..")
end

function stringtoexpressions.process(script_content, base1, base2)
    return script_content:gsub("(['\"])(.-)%1", function(_, str)
        return obfuscate_string_literal(str, base1, base2)
    end)
end

return stringtoexpressions
