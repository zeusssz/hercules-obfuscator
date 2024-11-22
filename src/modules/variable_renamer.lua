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
    local local_var_pattern = "local%s+([%w_,%s]*)%s*"
    local local_assignment_pattern = "local%s+([%w_]+)%s*="
    local obfuscated_code = code
    local local_var_map = {}

    -- Handle variables declared without initial values
    for var in code:gmatch(local_var_pattern) do
        for single_var in var:gmatch("[%w_]+") do
            if not local_var_map[single_var] then
                local_var_map[single_var] = generate_random_name()
            end
        end
    end

    obfuscated_code = obfuscated_code:gsub(local_assignment_pattern, function(var)
        if not local_var_map[var] then
            local_var_map[var] = generate_random_name()
        end
        return "local " .. local_var_map[var] .. " ="
    end)

    for original_var, obfuscated_var in pairs(local_var_map) do
        obfuscated_code = obfuscated_code:gsub("(%W)(" .. original_var .. ")(%W)", function(pre, var, post)
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
