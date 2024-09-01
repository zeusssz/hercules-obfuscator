local VariableRenamer = {}

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
    local counter = 0

    return code:gsub("([%a_][%w_]*)", function(var)
        if not variables[var] then
            counter = counter + 1
            variables[var] = generate_random_name()
        end
        return variables[var]
    end)
end

return VariableRenamer
