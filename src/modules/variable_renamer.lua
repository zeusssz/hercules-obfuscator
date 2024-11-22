local VariableRenamer = {}
local varencNames = {}

local lua_functions = {
    "assert", "collectgarbage", "dofile", "loadfile", "loadstring",
    "pairs", "ipairs", "tonumber", "tostring", "type", "print",
    "_G", "_VERSION", "write", "sort",
    "math.abs", "math.acos", "math.asin", "math.atan", "math.atan2",
    "math.ceil", "math.cos", "math.cosh", "math.deg", "math.exp",
    "math.floor", "math.fmod", "math.frexp", "math.ldexp", "math.log",
    "math.log10", "math.max", "math.min", "math.modf", "math.pi",
    "math.pow", "math.rad", "math.random", "math.randomseed", "math.sin",
    "math.sinh", "math.sqrt", "math.tan", "math.tanh",
    "string.byte", "string.char", "string.dump", "string.find",
    "string.format", "string.gmatch", "string.gsub", "string.len",
    "string.lower", "string.match", "string.rep", "string.reverse",
    "string.sub", "string.upper",
    "table.concat", "table.insert", "table.remove", "table.sort",
    "table.pack", "table.unpack", "game:GetService",
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

local function obfuscate_local_variables(code)
    local local_var_pattern = "local%s+([%w_,%s]+)%s*=?"
    local local_func_pattern = "local%s+function%s+([%w_]+)%s*%(([%w_,%s]*)%)"
    local var_map = {}
    local obfuscated_code = code
    for local_vars in code:gmatch(local_var_pattern) do
        for var in local_vars:gmatch("[%w_]+") do
            if not var_map[var] then
                var_map[var] = generate_random_name()
            end
        end
    end
    for func_name, args in code:gmatch(local_func_pattern) do
        if not var_map[func_name] then
            var_map[func_name] = generate_random_name()
        end
        for arg in args:gmatch("[%w_]+") do
            if not var_map[arg] then
                var_map[arg] = generate_random_name()
            end
        end
    end

    obfuscated_code = obfuscated_code:gsub("local%s+([%w_,%s]+)%s*=?", function(local_vars)
        return "local " .. local_vars:gsub("[%w_]+", function(var)
            return var_map[var] or var
        end)
    end)

    obfuscated_code = obfuscated_code:gsub("local%s+function%s+([%w_]+)", function(func_name)
        return "local function " .. (var_map[func_name] or func_name)
    end)

    for original_var, obfuscated_var in pairs(var_map) do
        obfuscated_code = obfuscated_code:gsub("([^%w_])(" .. original_var .. ")([^%w_])", function(pre, var, post)
            return pre .. obfuscated_var .. post
        end)
    end

    return obfuscated_code
end

function VariableRenamer.process(code)
    code = obfuscate_local_variables(code)

    local renamed_vars = {}
    local assignment_lines = {}
    local replacements = code

    for _, function_name in ipairs(lua_functions) do
        if string.find(code, function_name, 1, true) then
            if not varencNames[function_name] then
                local new_name = generate_random_name()
                varencNames[function_name] = new_name
                table.insert(renamed_vars, new_name)
                table.insert(assignment_lines, new_name .. " = " .. function_name .. ";")
            end
            replacements = string.gsub(replacements, function_name, varencNames[function_name])
        end
    end

    local local_declaration = #renamed_vars > 0 and "local " .. table.concat(renamed_vars, ", ") or ""
    return local_declaration .. (#assignment_lines > 0 and "\n" .. table.concat(assignment_lines, " ") or "") .. "\n" .. replacements
end

return VariableRenamer
