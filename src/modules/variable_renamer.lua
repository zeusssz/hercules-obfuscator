local VariableRenamer = {}
local varenc_names = {}
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

local reserved_words = {
    ["if"] = true, ["then"] = true, ["else"] = true, ["elseif"] = true, ["end"] = true,
    ["for"] = true, ["while"] = true, ["do"] = true, ["repeat"] = true, ["until"] = true,
    ["function"] = true, ["local"] = true, ["return"] = true, ["break"] = true, ["continue"] = true,
    ["and"] = true, ["or"] = true, ["not"] = true, ["in"] = true, ["nil"] = true,
    ["true"] = true, ["false"] = true
}

local DEFAULT_MIN_NAME_LENGTH, DEFAULT_MAX_NAME_LENGTH = 8, 12
local name_min, name_max = DEFAULT_MIN_NAME_LENGTH, DEFAULT_MAX_NAME_LENGTH

local function generateRandomName()
    local len = math.random(name_min, name_max)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local name = ""
    for _ = 1, len do
        local index = math.random(1, #charset)
        name = name .. charset:sub(index, index)
    end
    return name
end

local function replaceUnquoted(input, target, replacement)
    local placeholder = "!!!"
    local protected_input = input:gsub('(["\'])(.-)%1', function(q, content)
        content = content:gsub('\\"', '!@!'):gsub("\\'", "@!@")
        content = content:gsub(target, placeholder)
        content = content:gsub('!@!', '\\"'):gsub('@!@', "\\'")
        return q .. content .. q
    end)
    local result = protected_input:gsub('(%f[%w_])' .. target .. '(%f[^%w_])', function(before, after)
        return before .. replacement .. after
    end)
    result = result:gsub(placeholder, target)
    return result
end

local function obfuscateLocalVariables(code)
    local local_var_pattern = "local%s+([%w_,%s]+)%s*=%s*"
    local var_map = {}
    local obfuscated_code = code
    for local_vars in code:gmatch(local_var_pattern) do
        for var in local_vars:gmatch("[%w_]+") do
            if #var > 1 and not varenc_names[var] and not reserved_words[var] then
                var_map[var] = generateRandomName()
            end
        end
    end
    for original_var, obfuscated_var in pairs(var_map) do
        obfuscated_code = replaceUnquoted(obfuscated_code, original_var, obfuscated_var)
    end
    return obfuscated_code, var_map
end

local function obfuscateFunctions(code)
    local func_map = {}
    local arg_map = {}
    local obfuscated_code = code
    for func_name, args in code:gmatch("function%s+([%w_]+)%s*%(([%w_,%s]*)%)") do
        if not reserved_words[func_name] and not func_map[func_name] then
            func_map[func_name] = generateRandomName()
        end
        for arg in args:gmatch("[%w_]+") do
            if not reserved_words[arg] and not arg_map[arg] then
                arg_map[arg] = generateRandomName()
            end
        end
    end
    obfuscated_code = obfuscated_code:gsub("function%s+([%w_]+)", function(func_name)
        return "function " .. (func_map[func_name] or func_name)
    end)
    for original_func, obfuscated_func in pairs(func_map) do
        obfuscated_code = obfuscated_code:gsub(original_func .. "%(", obfuscated_func .. "(")
    end
    for original_arg, obfuscated_arg in pairs(arg_map) do
        obfuscated_code = replaceUnquoted(obfuscated_code, original_arg, obfuscated_arg)
    end
    return obfuscated_code
end

function VariableRenamer.process(code, options)
    options = options or {}
    -- apply custom name length range
    name_min = options.min_length or DEFAULT_MIN_NAME_LENGTH
    name_max = options.max_length or DEFAULT_MAX_NAME_LENGTH
    local renamed_vars = {}
    local assignment_lines = {}
    local obfuscated_code, var_map = obfuscateLocalVariables(code)
    obfuscated_code = obfuscateFunctions(obfuscated_code)
    for _, function_name in ipairs(lua_functions) do
        if string.find(code, function_name, 1, true) then
            if not varenc_names[function_name] then
                local new_name = generateRandomName()
                varenc_names[function_name] = new_name
                table.insert(renamed_vars, new_name)
                table.insert(assignment_lines, new_name .. " = " .. function_name .. ";")
            end
            obfuscated_code = obfuscated_code:gsub(function_name .. "%(", varenc_names[function_name] .. "(")
        end
    end
    local local_declaration = #renamed_vars > 0 and "local " .. table.concat(renamed_vars, ", ") or ""
    local assignments = #assignment_lines > 0 and "\n" .. table.concat(assignment_lines, " ") or ""
    local result = local_declaration .. assignments .. "\n" .. obfuscated_code
    -- reset to defaults
    name_min, name_max = DEFAULT_MIN_NAME_LENGTH, DEFAULT_MAX_NAME_LENGTH
    return result
end

return VariableRenamer
