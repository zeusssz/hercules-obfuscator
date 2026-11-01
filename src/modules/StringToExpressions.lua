local StringToExpressions = {}
local longBracketEnd = require("modules/long_brackets")
local math_methods = {
    addSub = function(char, base1, base2)
        local base = math.random(base1, base2)
        local chance = math.random(0, 1)
        return chance == 1 and string.format("%d - (%d)", base, base - char) or string.format("%d + %d", char - base, base)
    end,
}

local used_ascii = {}

local function insertChar(obfuscated, ascii_code, base1, base2)
    used_ascii[ascii_code] = true
    local part = math_methods.addSub(ascii_code, base1, base2)
    table.insert(obfuscated, "chars[" .. part .. "]")
end

local function formatChar(ascii_code)
    if ascii_code < 32 or ascii_code > 126 then
        return string.format("\\%03d", ascii_code)
    else
        return string.char(ascii_code)
    end
end

local function obfuscateStringLiteral(str, base1, base2)
    if #str == 0 then
        return '""'
    end
    local obfuscated = {}
    for i = 1, #str do
        insertChar(obfuscated, str:byte(i), base1, base2)
    end
    return table.concat(obfuscated, "..")
end

function StringToExpressions.process(script_content, base1, base2)
    used_ascii = {}

    -- Scan script content and find strings properly (handling escapes)
    local parts = {}
    local pos = 1

    while pos <= #script_content do
        local ch = script_content:sub(pos, pos)

        -- Long strings are opaque, including [=[...]=] and higher levels.
        local long_end = ch == "[" and longBracketEnd(script_content, pos)
        if long_end then
            table.insert(parts, script_content:sub(pos, long_end))
            pos = long_end + 1
            goto continue
        end

        -- Handle short strings
        if ch == '"' or ch == "'" then
            local q = ch
            local str_start = pos
            pos = pos + 1
            local str_content = ""
            while pos <= #script_content do
                local c = script_content:sub(pos, pos)
                if c == "\\" then
                    -- Escape sequence: include both backslash and next char
                    str_content = str_content .. c .. script_content:sub(pos + 1, pos + 1)
                    pos = pos + 2
                elseif c == q then
                    pos = pos + 1
                    break
                else
                    str_content = str_content .. c
                    pos = pos + 1
                end
            end
            -- Obfuscate the string content
            -- Interpret escape sequences correctly
            local actual = ""
            local i = 1
            while i <= #str_content do
                local c = str_content:sub(i, i)
                if c == "\\" and i < #str_content then
                    local nxt = str_content:sub(i + 1, i + 1)
                    if nxt == "\\" then
                        actual = actual .. "\\"
                        i = i + 2
                    elseif nxt == '"' then
                        actual = actual .. '"'
                        i = i + 2
                    elseif nxt == "'" then
                        actual = actual .. "'"
                        i = i + 2
                    elseif nxt == "n" then
                        actual = actual .. "\n"
                        i = i + 2
                    elseif nxt == "r" then
                        actual = actual .. "\r"
                        i = i + 2
                    elseif nxt == "t" then
                        actual = actual .. "\t"
                        i = i + 2
                    elseif nxt == "a" then
                        actual = actual .. "\a"
                        i = i + 2
                    elseif nxt == "b" then
                        actual = actual .. "\b"
                        i = i + 2
                    elseif nxt == "f" then
                        actual = actual .. "\f"
                        i = i + 2
                    elseif nxt == "v" then
                        actual = actual .. "\v"
                        i = i + 2
                    elseif nxt:match("%d") then
                        local digits = str_content:sub(i + 1, i + 3)
                        if digits:match("^%d%d%d$") then
                            actual = actual .. string.char(tonumber(digits))
                            i = i + 4
                        else
                            actual = actual .. c
                            i = i + 1
                        end
                    else
                        actual = actual .. c .. nxt
                        i = i + 2
                    end
                else
                    actual = actual .. c
                    i = i + 1
                end
            end
            local obf = obfuscateStringLiteral(actual, base1, base2)
            table.insert(parts, "(" .. obf .. ")")
            goto continue
        end

        -- Long comments may span lines and use arbitrary = delimiters.
        if ch == "-" and script_content:sub(pos + 1, pos + 1) == "-" then
            local comment_end = longBracketEnd(script_content, pos + 2)
                or script_content:find("\n", pos) or #script_content
            table.insert(parts, script_content:sub(pos, comment_end))
            pos = comment_end + 1
            goto continue
        end

        table.insert(parts, ch)
        pos = pos + 1
        ::continue::
    end

    local obfuscated_script = table.concat(parts)

    local chars_table_parts = {}
    for ascii_code, _ in pairs(used_ascii) do
        chars_table_parts[#chars_table_parts + 1] = string.format("[%d]=%q", ascii_code, formatChar(ascii_code))
    end
    local chars_table = "local chars = {" .. table.concat(chars_table_parts, ",") .. "}\n"
    return chars_table .. obfuscated_script
end

return StringToExpressions
