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
    local in_string = false
    local current_quote
    local last_position = 1

    for i = 1, #code do
        local char = code:sub(i, i)

        if not in_string then
            if char == "'" or char == '"' then
                if last_position < i then
                    local segment = code:sub(last_position, i - 1)
                    segment = segment:gsub("([%a_][%w_]*)", function(var)
                        if not lua_keywords[var] and not variables[var] then
                            variables[var] = generate_random_name()
                        end
                        return variables[var] or var
                    end)
                    table.insert(result, segment)
                end
                in_string = true
                current_quote = char
                table.insert(result, char)
                last_position = i + 1
            end
        else
            if char == current_quote and (i == 1 or code:sub(i - 1, i - 1) ~= "\\") then
                table.insert(result, code:sub(last_position, i))
                in_string = false
                last_position = i + 1
            end
        end
    end
    if last_position <= #code then
        local segment = code:sub(last_position)
        segment = segment:gsub("([%a_][%w_]*)", function(var)
            if not lua_keywords[var] and not variables[var] then
                variables[var] = generate_random_name()
            end
            return variables[var] or var
        end)
        table.insert(result, segment)
    end

    return table.concat(result)
end

return VariableRenamer
