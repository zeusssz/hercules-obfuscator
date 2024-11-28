local VariableRenamer = {}
local varencNames = {}

local lua_functions = {
    "assert", "collectgarbage", "dofile", "loadfile", "loadstring",
    "ipairs", "pairs", "tonumber", "tostring", "type", "print",
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

local function replace_unquoted(input, target, replacement)
    local placeholder = "!!!"

    -- Replace target in quoted strings with a placeholder to skip them
    local protected_input = input:gsub('(["\'])(.-)%1', function(_, content)
        content = content:gsub('\\"', '!@!'):gsub("\\'", "@!@")
        content = content:gsub(target, placeholder)
        content = content:gsub('!@!', '\\"'):gsub('@!@', "\\'")
    end)

    -- Replace standalone occurrences of the target outside of quotes
    local result = protected_input:gsub('(%f[%w_])' .. target .. '(%f[^%w_])', function(before, after)
        return before .. replacement .. after
    end)

    -- Restore placeholders in quoted strings
    result = result:gsub(placeholder, target)
    return result
end

local function obfuscate_local_variables(code)
    local local_var_pattern = "local%s+([%w_,%s]+)%s*=%s*"
    local var_map = {}
    local obfuscated_code = code

    -- update variable name
    for local_vars in code:gmatch(local_var_pattern) do
        for var in local_vars:gmatch("[%w_]+") do
            if #var > 1 then
                if not var_map[var] then
                    var_map[var] = generate_random_name()
                end
            end
        end
    end

    -- Update the variables args
    for original_var, obfuscated_var in pairs(var_map) do
        print(original_var, obfuscated_var)
        obfuscated_code = replace_unquoted(obfuscated_code, original_var, obfuscated_var)
    end

    return obfuscated_code
end

local function obfuscate_functions(code)
    local local_func_pattern = "function%s+([%w_]+)%s*%(([%w_,%s]*)%)"
    local func_map = {}
    local arg_map = {}
    local obfuscated_code = code

    for func_name, args in code:gmatch(local_func_pattern) do
        if not func_map[func_name] then
            func_map[func_name] = generate_random_name()
        end
        for arg in args:gmatch("[%w_]+") do
            if not arg_map[arg] then
                arg_map[arg] = generate_random_name()
            end
        end
    end

    -- Update the function name
    obfuscated_code = obfuscated_code:gsub("function%s+([%w_]+)", function(func_name)
        return "function " .. (func_map[func_name] or func_name)
    end)

    -- update the function name
    for original_func, obfuscated_func in pairs(func_map) do
        obfuscated_code = obfuscated_code:gsub(original_func .. "%(", obfuscated_func .. "(")
    end

    -- Update the function args
    for original_arg, obfuscated_arg in pairs(arg_map) do
        obfuscated_code = replace_unquoted(obfuscated_code, original_arg, obfuscated_arg)
    end

    return obfuscated_code
end

function VariableRenamer.process(code)
    code = obfuscate_local_variables(code)
    code = obfuscate_functions(code)

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
