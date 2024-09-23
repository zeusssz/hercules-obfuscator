local VariableRenamer = {}

local lua_keywords = {
    ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
    ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
    ["function"] = true, ["goto"] = true, ["if"] = true, ["in"] = true,
    ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true,
    ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true,
    ["until"] = true, ["while"] = true, ["require"] = true,
    ["module"] = true, ["package"] = true, ["self"] = true,
    ["assert"] = true, ["collectgarbage"] = true, ["dofile"] = true,
    ["loadfile"] = true, ["loadstring"] = true, ["pairs"] = true,
    ["ipairs"] = true, ["tonumber"] = true, ["tostring"] = true,
    ["type"] = true, ["print"] = true, ["string"] = true,
    ["table"] = true, ["math"] = true, ["os"] = true, ["coroutine"] = true
}

local function generate_random_name(len)
    len = len or math.random(8, 12)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local name = ""
    for _ = 1, len do
        local index = math.random(1, #charset)
        name = name .. charset:sub(index, index)
    end
    return name
end

function VariableRenamer.process(code)
    local variables = {}
    local result = {}

    local function rename_variables(segment)
        return segment:gsub("([%a_][%w_]*)", function(var)
            if not lua_keywords[var] and not variables[var] then
                variables[var] = generate_random_name()
            end
            return variables[var] or var
        end)
    end

    local pattern = "()(['\"])(.-)%2()"
    local last_pos = 1

    for start_pos, quote_char, string_content, end_pos in code:gmatch(pattern) do
        local code_segment = code:sub(last_pos, start_pos - 1)
        result[#result + 1] = rename_variables(code_segment)
        result[#result + 1] = quote_char .. string_content .. quote_char
        last_pos = end_pos
    end
    result[#result + 1] = rename_variables(code:sub(last_pos))

    return table.concat(result)
end

return VariableRenamer
