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

    local obfuscated = {}
    local i = 1

    while i <= #str do
        local char = str:sub(i, i)

        -- look for char starting with \
        if char == "\\" and i < #str then
            local next_char = str:sub(i + 1, i + 1)

            if next_char == "n" then
               insert_char(obfuscated, 10, base1, base2) -- ASCII code for \n
            elseif next_char == "r" then
                insert_char(obfuscated, 13, base1, base2) -- ASCII code for \r
            elseif next_char == "t" then
                insert_char(obfuscated, 9, base1, base2) -- ASCII code for \t
            else
                -- remove the escaping and just insert the next_char
                insert_char(obfuscated, next_char:byte(), base1, base2)
            end
            
            -- skip ahead
            i = i + 1
        else
            -- Handle regular characters
            insert_char(obfuscated, char:byte(), base1, base2)
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
