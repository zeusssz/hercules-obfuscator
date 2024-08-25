-- modules/variable_renamer.lua
local VariableRenamer = {}

local function generate_random_name(len)
    local res = ""
    for i = 1, len do
        res = res .. string.char(math.random(97, 122)) -- a-z
    end
    return res
end

function VariableRenamer.process(code)
    local variables = {}
    local i = 0
    return code:gsub("([%a_][%w_]*)", function(var)
        if not variables[var] then
            i = i + 1
            variables[var] = generate_random_name(math.random(8, 12))
        end
        return variables[var]
    end)
end

return VariableRenamer
