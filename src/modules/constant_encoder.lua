local ConstantEncoder = {}

local RESERVED = {
    ["true"] = true,
    ["false"] = true,
    ["nil"] = true,
}

local function skip_string(code, pos)
    local c = code:sub(pos, pos)
    if c == '"' or c == "'" then
        local q = c
        pos = pos + 1
        while pos <= #code do
            local ch = code:sub(pos, pos)
            if ch == "\\" then pos = pos + 2
            elseif ch == q then return pos + 1
            else pos = pos + 1 end
        end
        return pos
    end

    local eq = code:match("^%[(=*)%[", pos)
    if eq then
        local close = "]" .. string.rep("=", #eq) .. "]"
        local _, end_pos = code:find(close, pos + #eq + 2, true)
        return end_pos and end_pos + 1 or pos + 1
    end
    return pos + 1
end

local function skip_comment(code, pos)
    if code:sub(pos + 2, pos + 2) == "[" then
        local eq = code:match("^%[(=*)%[", pos + 2)
        if eq then
            local close = "]" .. string.rep("=", #eq) .. "]"
            local _, end_pos = code:find(close, pos + #eq + 4, true)
            return end_pos and end_pos + 1 or #code + 1
        end
    end
    local nl = code:find("\n", pos)
    return nl and nl + 1 or #code + 1
end

local function number_expr(raw)
    local n = tonumber(raw)
    if not n then return raw end
    if n % 1 ~= 0 then return raw end

    local a = math.random(97, 9999)
    local b = math.random(17, 511)
    local mode = math.random(1, 2)
    if mode == 1 then
        return string.format("((%d+%d)-%d)", n, a, a)
    end
    return string.format("(#%q+%d)", string.rep("x", b), n - b)
end

local function word_expr(word)
    if word == "true" then return "(not not 1)" end
    if word == "false" then return "(not 1)" end
    if word == "nil" then return "(function()end)()" end
    return word
end

function ConstantEncoder.process(code)
    local out = {}
    local pos = 1

    while pos <= #code do
        local ch = code:sub(pos, pos)

        if ch == '"' or ch == "'" or (ch == "[" and code:match("^%[(=*)%[", pos)) then
            local end_pos = skip_string(code, pos)
            out[#out + 1] = code:sub(pos, end_pos - 1)
            pos = end_pos
            goto continue
        end

        if ch == "-" and code:sub(pos + 1, pos + 1) == "-" then
            local end_pos = skip_comment(code, pos)
            out[#out + 1] = code:sub(pos, end_pos - 1)
            pos = end_pos
            goto continue
        end

        local prev = pos > 1 and code:sub(pos - 1, pos - 1) or ""
        local word = code:match("^([%a_][%w_]*)", pos)
        if word then
            local next_ch = code:sub(pos + #word, pos + #word)
            if RESERVED[word] and not prev:match("[%w_]") and not next_ch:match("[%w_]") then
                out[#out + 1] = word_expr(word)
                pos = pos + #word
                goto continue
            end
        end

        local num = code:match("^(%d+)", pos)
        if num and not prev:match("[%w_%.]") then
            local next_ch = code:sub(pos + #num, pos + #num)
            if not next_ch:match("[%w_%.]") then
                out[#out + 1] = number_expr(num)
                pos = pos + #num
                goto continue
            end
        end

        out[#out + 1] = ch
        pos = pos + 1
        ::continue::
    end

    return table.concat(out)
end

return ConstantEncoder
