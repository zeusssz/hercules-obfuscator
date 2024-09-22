local VariableRenamer = {}

local lua_keywords = {
    ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
    ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
    ["function"] = true, ["goto"] = true, ["if"] = true, ["in"] = true,
    ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true,
    ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true,
    ["until"] = true, ["while"] = true,
    ["require"] = true, ["module"] = true, ["package"] = true,
    ["self"] = true, ["this"] = true, ["assert"] = true,
    ["collectgarbage"] = true, ["dofile"] = true, ["loadfile"] = true,
    ["loadstring"] = true, ["pairs"] = true, ["ipairs"] = true,
    ["tonumber"] = true, ["tostring"] = true, ["type"] = true,
    ["print"] = true, ["string"] = true, ["table"] = true,
    ["math"] = true, ["os"] = true, ["coroutine"] = true,
}

local function generate_random_name(len)
    len = len or math.random(8, 12)
    local name = ""
    for i = 1, len do
        name = name .. string.char(math.random(97, 122)) -- a-z
    end
    return name
end

function VariableRenamer.process(code)
    local variables = {}
    return code:gsub("([%a_][%w_]*)", function(var)
        if not lua_keywords[var] and not variables[var] then
            variables[var] = generate_random_name()
        end
        return variables[var] or var
    end)
end

return VariableRenamer
