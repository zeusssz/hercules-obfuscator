local FunctionInliner = {}

-- Helper: skip over strings in code, returns position after the string
local function skip_string(code, pos)
    local char = code:sub(pos, pos)
    if char == '"' or char == "'" then
        local quote = char
        pos = pos + 1
        while pos <= #code do
            local c = code:sub(pos, pos)
            if c == "\\" then
                pos = pos + 2
            elseif c == quote then
                return pos + 1
            else
                pos = pos + 1
            end
        end
    elseif code:sub(pos, pos + 2) == "[[" then
        local _, end_pos = code:find("]]", pos, true)
        return end_pos and end_pos + 1 or pos
    elseif code:sub(pos, pos + 3) == "[==[" then
        local _, end_pos = code:find("]==]", pos, true)
        return end_pos and end_pos + 1 or pos
    end
    return pos
end

-- Helper: count block depth from a given position, handling strings and comments
-- Returns the position where the matching "end" keyword ends
-- Also handles: if/then/else/elseif, for, while, repeat/until, function/end, do/end
local function find_matching_end(code, start_pos)
    local depth = 1
    local pos = start_pos

    while pos <= #code and depth > 0 do
        local char = code:sub(pos, pos)

        -- Skip strings
        if char == '"' or char == "'" or code:sub(pos, pos + 1) == "[[" then
            pos = skip_string(code, pos)
            goto continue
        end

        -- Skip comments
        if code:sub(pos, pos + 1) == "--" then
            local line_end = code:find("\n", pos)
            pos = line_end and line_end + 1 or #code + 1
            goto continue
        end

        -- Check for block-opening keywords
        -- IMPORTANT: Check elseif BEFORE else and if to avoid partial matching
        local remaining = code:sub(pos)
        if remaining:match("^elseif[^%w_]") or remaining:match("^elseif$") then
            -- elseif is NOT a block opener or closer, skip over it
            pos = pos + 6
        elseif remaining:match("^do[^%w_]") or remaining:match("^do$") then
            depth = depth + 1
            pos = pos + 2
        elseif remaining:match("^function[^%w_]") or remaining:match("^function$") then
            depth = depth + 1
            pos = pos + 8
        elseif remaining:match("^if[^%w_]") or remaining:match("^if$") then
            depth = depth + 1
            pos = pos + 2
        elseif remaining:match("^for[^%w_]") or remaining:match("^for$") then
            depth = depth + 1
            pos = pos + 3
        elseif remaining:match("^while[^%w_]") or remaining:match("^while$") then
            depth = depth + 1
            pos = pos + 5
        elseif remaining:match("^repeat[^%w_]") or remaining:match("^repeat$") then
            depth = depth + 1
            pos = pos + 6
        elseif remaining:match("^end[^%w_]") or remaining:match("^end$") then
            depth = depth - 1
            if depth == 0 then
                return pos + 3
            end
            pos = pos + 3
        elseif remaining:match("^until[^%w_]") or remaining:match("^until$") then
            depth = depth - 1
            if depth == 0 then
                return pos + 5
            end
            pos = pos + 5
        else
            -- then, else, and other keywords are NOT block openers or closers
            pos = pos + 1
        end

        ::continue::
    end

    return pos
end

-- Check if a function body contains recursive calls to itself
local function is_recursive(name, body)
    -- Simple check: look for name( pattern outside of strings
    local pos = 1
    while pos <= #body do
        local char = body:sub(pos, pos)
        -- Skip strings
        if char == '"' or char == "'" then
            pos = skip_string(body, pos)
            goto continue
        end
        -- Check for name(
        if body:sub(pos):match("^" .. name .. "%s*%(") then
            return true
        end
        pos = pos + 1
        ::continue::
    end
    return false
end

-- Find all function definitions and their bodies
local function find_functions(code)
    local functions = {}
    local pos = 1

    while pos <= #code do
        local char = code:sub(pos, pos)

        -- Skip strings
        if char == '"' or char == "'" or code:sub(pos, pos + 1) == "[[" then
            pos = skip_string(code, pos)
            goto continue
        end

        -- Skip comments
        if code:sub(pos, pos + 1) == "--" then
            local line_end = code:find("\n", pos)
            pos = line_end and line_end + 1 or #code + 1
            goto continue
        end

        local remaining = code:sub(pos)

        -- Match: local function name(params)
        local match_start, match_end, name, params = remaining:find("^local%s+function%s+([%a_][%w_]*)%s*%(([^)]*)%)")
        if match_start then
            local body_start = match_end + 1
            local body_end_pos = find_matching_end(code, body_start)
            if body_end_pos then
                local body = code:sub(body_start, body_end_pos - 4) -- -4 to exclude "end"
                table.insert(functions, {
                    name = name,
                    params = params,
                    body = body,
                    start = pos + match_start - 1,
                    end_pos = pos + body_end_pos - 1,
                    is_local = true,
                    is_recursive = is_recursive(name, body),
                })
                pos = body_end_pos
                goto continue
            end
        end

        -- Match: function name(params)  (global function)
        match_start, match_end, name, params = remaining:find("^function%s+([%a_][%w_]*)%s*%(([^)]*)%)")
        if match_start then
            local body_start = match_end + 1
            local body_end_pos = find_matching_end(code, body_start)
            if body_end_pos then
                local body = code:sub(body_start, body_end_pos - 4)
                table.insert(functions, {
                    name = name,
                    params = params,
                    body = body,
                    start = pos + match_start - 1,
                    end_pos = pos + body_end_pos - 1,
                    is_local = false,
                    is_recursive = is_recursive(name, body),
                })
                pos = body_end_pos
                goto continue
            end
        end

        -- Match: local name = function(params)
        match_start, match_end, name, params = remaining:find("^local%s+([%a_][%w_]*)%s*=%s*function%s*%(([^)]*)%)")
        if match_start then
            local body_start = match_end + 1
            local body_end_pos = find_matching_end(code, body_start)
            if body_end_pos then
                local body = code:sub(body_start, body_end_pos - 4)
                table.insert(functions, {
                    name = name,
                    params = params,
                    body = body,
                    start = pos + match_start - 1,
                    end_pos = pos + body_end_pos - 1,
                    is_local = true,
                    is_recursive = is_recursive(name, body),
                })
                pos = body_end_pos
                goto continue
            end
        end

        pos = pos + 1
        ::continue::
    end

    return functions
end

-- Replace function calls with inlined IIFEs
local function inline_calls(code, functions)
    local result = code

    -- For each non-recursive function, replace calls with IIFEs
    for _, func in ipairs(functions) do
        if func.is_recursive then
            goto continue
        end

        -- Find and replace function calls: funcName(args)
        local pattern = func.name .. "%s*(%b())"

        result = result:gsub(pattern, function(call_args)
            local args_inside = call_args:sub(2, -2)
            return "(function(" .. func.params .. ")\n" .. func.body .. "\nend)(" .. args_inside .. ")"
        end)

        ::continue::
    end

    -- Fix adjacent IIFEs: add semicolon between IIFE call and next IIFE
    -- Pattern: )(args)\n(function → )(args);\n(function
    result = result:gsub("(%b())\n(%(function)", function(args, func_start)
        return args .. ";\n" .. func_start
    end)

    return result
end

-- Remove function definitions from code (replace with empty lines to preserve line numbers)
local function remove_functions(code, functions)
    local result = code
    -- Process in reverse order to maintain offsets
    for i = #functions, 1, -1 do
        local func = functions[i]
        if func.is_recursive then
            goto continue
        end
        local before = result:sub(1, func.start - 1)
        local after = result:sub(func.end_pos)
        -- Preserve newlines to keep line numbers
        local original = result:sub(func.start, func.end_pos - 1)
        local newlines = original:gsub("[^\n]", "")
        result = before .. newlines .. after
        ::continue::
    end
    return result
end

function FunctionInliner.process(code)
    if code:match("^%s*%-%-.*Obfuscated") then return code end

    -- Find all function definitions
    local functions = find_functions(code)

    if #functions == 0 then
        return code
    end

    -- Remove original function definitions first (to avoid matching them as calls)
    local result = remove_functions(code, functions)

    -- Then inline function calls (replace with IIFEs)
    result = inline_calls(result, functions)

    return result
end

return FunctionInliner
