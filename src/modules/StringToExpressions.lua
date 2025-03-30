local stringtoexpressions = {}
local math_methods = {
    add_sub = function(char, base1, base2)
        local base = math.random(base1, base2)
        local chance = math.random(0, 1)
        return chance == 1 and string.format("%d - (%d)", base, base - char) or string.format("%d + %d", char - base, base)
    end,
}

local used_ascii = {}

local function insert_char(obfuscated, ascii_code, base1, base2)
    used_ascii[ascii_code] = true
    local part = math_methods.add_sub(ascii_code, base1, base2)
    table.insert(obfuscated, "chars[" .. part .. "]")
end

local function format_char(ascii_code)
    if ascii_code < 32 or ascii_code > 126 then
        return string.format("\\%03d", ascii_code)
    else
        return string.char(ascii_code)
    end
end

local function obfuscate_string_literal(str, base1, base2)
    if #str == 0 then
        return '""'
    end
    local escape_chars = { n = 10, r = 13, t = 9, ["'"] = 39, ['"'] = 34 }
    local obfuscated = {}
    local i = 1
    while i <= #str do
        local char_code = str:byte(i)
        if char_code == 92 and i < #str then
            local next_char = str:sub(i + 1, i + 1)
            if next_char == "2" and str:sub(i + 2, i + 2) == "7" then
                insert_char(obfuscated, 27, base1, base2)
                i = i + 2
            elseif escape_chars[next_char] then
                insert_char(obfuscated, escape_chars[next_char], base1, base2)
                i = i + 1
            else
                insert_char(obfuscated, char_code, base1, base2)
                insert_char(obfuscated, str:sub(i + 1, i + 1):byte(), base1, base2)
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
    script_content = script_content:gsub('\\"', '!@!'):gsub("\\'", "@!@")
    local obfuscated_script = script_content:gsub("(['\"])(.-)%1", function(quote, str)
        str = str:gsub('!@!', '\\"'):gsub('@!@', "\\'")
        local obf = obfuscate_string_literal(str, base1, base2)
        return obf
    end)

    local chars_table_parts = {}
    for ascii_code, _ in pairs(used_ascii) do
        chars_table_parts[#chars_table_parts + 1] = string.format("[%d]=%q", ascii_code, format_char(ascii_code))
    end
    local chars_table = "local chars = {" .. table.concat(chars_table_parts, ",") .. "}\n"
    return chars_table .. obfuscated_script
end

return stringtoexpressions
