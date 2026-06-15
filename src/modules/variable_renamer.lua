local VariableRenamer = {}

-- Lua built-in functions that should be renamed
local BUILTINS = {
    "assert", "collectgarbage", "dofile", "error", "ipairs", "next",
    "pairs", "pcall", "print", "rawequal", "rawget", "rawlen", "rawset",
    "select", "tonumber", "tostring", "type", "unpack", "xpcall",
    -- math
    "math.abs", "math.acos", "math.asin", "math.atan", "math.ceil",
    "math.cos", "math.deg", "math.exp", "math.floor", "math.fmod",
    "math.huge", "math.log", "math.max", "math.min", "math.modf",
    "math.pi", "math.pow", "math.rad", "math.random", "math.randomseed",
    "math.sin", "math.sqrt", "math.tan",
    -- string
    "string.byte", "string.char", "string.dump", "string.find",
    "string.format", "string.gmatch", "string.gsub", "string.len",
    "string.lower", "string.match", "string.rep", "string.reverse",
    "string.sub", "string.upper",
    -- table
    "table.concat", "table.insert", "table.remove", "table.sort",
    "table.pack", "table.unpack",
    -- os
    "os.clock", "os.date", "os.difftime", "os.execute", "os.exit",
    "os.getenv", "os.remove", "os.rename", "os.setlocale", "os.time",
    "os.tmpname",
}

local RESERVED = {
    ["and"]=true, ["break"]=true, ["do"]=true, ["else"]=true, ["elseif"]=true,
    ["end"]=true, ["false"]=true, ["for"]=true, ["function"]=true, ["goto"]=true,
    ["if"]=true, ["in"]=true, ["local"]=true, ["nil"]=true, ["not"]=true,
    ["or"]=true, ["repeat"]=true, ["return"]=true, ["then"]=true, ["true"]=true,
    ["until"]=true, ["while"]=true,
}

local DEFAULT_MIN_LEN, DEFAULT_MAX_LEN = 8, 12

local function make_name_generator(min_len, max_len, reserved_names)
    local used = {}
    for name in pairs(reserved_names or {}) do
        used[name] = true
    end
    return function()
        local len = math.random(min_len or DEFAULT_MIN_LEN, max_len or DEFAULT_MAX_LEN)
        local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        while true do
            local name = ""
            for _ = 1, len do
                local idx = math.random(#charset)
                name = name .. charset:sub(idx, idx)
            end
            if not used[name] and not RESERVED[name] then
                used[name] = true
                return name
            end
        end
    end
end

-- Skip over a string starting at pos (which should be a quote or open bracket)
local function skip_string(code, pos)
    if pos > #code then return pos end
    local c = code:sub(pos, pos)
    if c == '"' or c == "'" then
        local q = c
        pos = pos + 1
        while pos <= #code do
            local ch = code:sub(pos, pos)
            if ch == "\\" then pos = pos + 2
            elseif ch == q then return pos + 1
            else pos = pos + 1 end
        end
        return pos
    elseif c == "[" then
        local bracket = code:match("^%[(=*)%[", pos)
        if bracket then
            local close = "]" .. string.rep("=", #bracket) .. "]"
            local _, end_pos = code:find(close, pos + #bracket + 2, true)
            return end_pos and end_pos + 1 or pos
        end
    end
    return pos
end

-- Skip over a comment starting at pos (pos points to first '-')
local function skip_comment(code, pos)
    if pos > #code then return pos end
    if code:sub(pos, pos + 1) == "--" then
        if code:sub(pos + 2, pos + 2) == "[" then
            local bracket = code:match("^%[(=*)%[", pos + 2)
            if bracket then
                local close = "]" .. string.rep("=", #bracket) .. "]"
                local _, end_pos = code:find(close, pos + 4 + #bracket, true)
                if end_pos then
                    -- Find end of this line or end of code
                    local nl = code:find("\n", end_pos)
                    return nl and nl + 1 or #code + 1
                end
            end
        end
        local nl = code:find("\n", pos)
        return nl and nl + 1 or #code + 1
    end
    return pos
end

-- Find the next occurrence of a keyword (as a whole word) in code, skipping strings and comments
local function find_keyword(code, keyword, start_pos)
    local pos = start_pos
    local pattern = "()%f[%w_]" .. keyword .. "%f[^%w_]"
    local found = {}
    while pos <= #code do
        local ch = code:sub(pos, pos)
        -- Skip strings
        if ch == '"' or ch == "'" or (ch == "[" and code:sub(pos, pos + 1) == "[[") then
            pos = skip_string(code, pos)
            goto continue
        end
        -- Skip comments
        if code:sub(pos, pos + 1) == "--" then
            pos = skip_comment(code, pos)
            goto continue
        end
        -- Check for keyword
        local remaining = code:sub(pos)
        if remaining:match("^%f[%w_]" .. keyword .. "%f[^%w_]") then
            return pos, pos + #keyword
        end
        pos = pos + 1
        ::continue::
    end
    return nil, nil
end

-- Replace all occurrences of keyword with replacement, skipping strings and comments
local function replace_keyword(code, keyword, replacement)
    local result = ""
    local pos = 1
    while pos <= #code do
        local ch = code:sub(pos, pos)
        -- Copy strings as-is
        if ch == '"' or ch == "'" or (ch == "[" and code:sub(pos, pos + 1) == "[[") then
            local end_pos = skip_string(code, pos)
            result = result .. code:sub(pos, end_pos - 1)
            pos = end_pos
            goto continue
        end
        -- Copy comments as-is
        if code:sub(pos, pos + 1) == "--" then
            local end_pos = skip_comment(code, pos)
            result = result .. code:sub(pos, end_pos - 1)
            pos = end_pos
            goto continue
        end
        -- Check for keyword
        local remaining = code:sub(pos)
        if remaining:match("^%f[%w_]" .. keyword .. "%f[^%w_]") then
            result = result .. replacement
            pos = pos + #keyword
            goto continue
        end
        result = result .. ch
        pos = pos + 1
        ::continue::
    end
    return result
end

-- Parse local variable declarations from code
-- Returns a map of var_name -> true
-- @param target optional target language ("lua", "luau", "glua")
local function parse_local_vars(code, target)
    local vars = {}
    local pos = 1
    while pos <= #code do
        local ch = code:sub(pos, pos)
        if ch == '"' or ch == "'" or (ch == "[" and code:sub(pos, pos + 1) == "[[") then
            pos = skip_string(code, pos)
            goto continue
        end
        if code:sub(pos, pos + 1) == "--" then
            pos = skip_comment(code, pos)
            goto continue
        end
        local remaining = code:sub(pos)
        -- Match: local name [= ...] or local name1, name2 [= ...]
        local m_start, m_end = remaining:find("^local%s+")
        if m_start then
            -- Parse variable names
            local var_str = ""
            local vpos = pos + m_end  -- convert from remaining-relative to code-absolute
            local paren_depth = 0
            local bracket_depth = 0
            while vpos <= #code do
                local vc = code:sub(vpos, vpos)
                if vc == "(" then paren_depth = paren_depth + 1
                elseif vc == ")" then
                    if paren_depth == 0 then break end
                    paren_depth = paren_depth - 1
                elseif vc == "[" then bracket_depth = bracket_depth + 1
                elseif vc == "]" then bracket_depth = bracket_depth - 1
                elseif vc == "=" and paren_depth == 0 and bracket_depth == 0 then
                    break
                elseif vc == "\n" and paren_depth == 0 then
                    break
                end
                if target == "luau" and vc == ":" and paren_depth == 0 and bracket_depth == 0 then
                    -- Luau type annotation: skip type tokens (e.g. `: string`, `: PlayerData`, `: {x: number}`)
                    vpos = vpos + 1
                    local type_depth = 0
                    while vpos <= #code do
                        local tc = code:sub(vpos, vpos)
                        if tc == "{" or tc == "[" or tc == "(" then
                            type_depth = type_depth + 1
                        elseif tc == "}" or tc == "]" or tc == ")" then
                            if type_depth == 0 then break end
                            type_depth = type_depth - 1
                        elseif (tc == "=" or tc == "\n") and type_depth == 0 then
                            break
                        end
                        vpos = vpos + 1
                    end
                    -- Don't add colon or type tokens to var_str
                else
                    var_str = var_str .. vc
                    vpos = vpos + 1
                end
            end
            -- Extract individual variable names
            -- Handle `local function name(params)` — only name is a local var, not params
            if var_str:match("^function%s+") then
                local fname = var_str:match("^function%s+([%a_][%w_]*)")
                if fname and not RESERVED[fname] and not vars[fname] then
                    vars[fname] = true
                end
            else
                for var in var_str:gmatch("[%a_][%w_]*") do
                    if not RESERVED[var] and not vars[var] then
                        vars[var] = true
                    end
                end
            end
            pos = vpos
            goto continue
        end
        pos = pos + 1
        ::continue::
    end
    return vars
end

function VariableRenamer.process(code, options)
    options = options or {}
    local min_len = options.min_length or DEFAULT_MIN_LEN
    local max_len = options.max_length or DEFAULT_MAX_LEN
    local target = options.target

    -- Filter BUILTINS for target language
    local builtins = BUILTINS
    if target == "luau" then
        -- In Luau, `type` is a keyword for type aliases and must not be renamed
        local filtered = {}
        for _, b in ipairs(BUILTINS) do
            if b ~= "type" then
                table.insert(filtered, b)
            end
        end
        builtins = filtered
    end

    -- Step 1: Find all local variable names
    local local_vars = parse_local_vars(code, target)
    local reserved_names = {}
    for name in pairs(local_vars) do
        reserved_names[name] = true
    end
    for _, builtin in ipairs(builtins) do
        local simple_name = builtin:match("([^.]+)$")
        reserved_names[simple_name or builtin] = true
    end
    local gen_name = make_name_generator(min_len, max_len, reserved_names)

    -- Step 2: Create rename map for local variables
    local rename_map = {}
    for var_name in pairs(local_vars) do
        rename_map[var_name] = gen_name()
    end

    -- Step 3: Find builtins used in code and create rename map
    local builtin_map = {}
    local used_builtins = {}
    for _, builtin in ipairs(builtins) do
        if code:find(builtin, 1, true) then
            local new_name = gen_name()
            builtin_map[builtin] = new_name
            table.insert(used_builtins, {original = builtin, new_name = new_name})
        end
    end

    -- Step 4: Apply replacements
    -- Strategy: scan character by character, protect strings/comments with placeholders,
    -- replace keywords in unprotected code, restore
    local function protect_and_replace(source, renames)
        if next(renames) == nil then return source end

        -- Collect all strings and comments, replace with placeholders
        local protected = {}
        local idx = 0
        local parts = {}
        local pos = 1

        while pos <= #source do
            local ch = source:sub(pos, pos)
            -- Long strings [[...]] or [=*[...]*=]
            if ch == "[" then
                local eq = source:match("^%[(=*)%[", pos)
                if eq then
                    local close_str = "]" .. string.rep("=", #eq) .. "]"
                    local _, end_pos = source:find(close_str, pos + #eq + 2, true)
                    if end_pos then
                        idx = idx + 1
                        local ph = string.format("\001STR%d\001", idx)
                        protected[ph] = source:sub(pos, end_pos)
                        table.insert(parts, ph)
                        pos = end_pos + 1
                        goto continue
                    end
                end
            end
            -- Short strings "..." or '...'
            if ch == '"' or ch == "'" then
                local end_pos = skip_string(source, pos)
                if end_pos and end_pos > pos then
                    idx = idx + 1
                    local ph = string.format("\001STR%d\001", idx)
                    protected[ph] = source:sub(pos, end_pos - 1)
                    table.insert(parts, ph)
                    pos = end_pos
                    goto continue
                end
            end
            -- Long comments --[=[...]=]
            if ch == "-" and source:sub(pos + 1, pos + 1) == "-" then
                if source:sub(pos + 2, pos + 2) == "[" then
                    local eq = source:match("^%[(=*)%[", pos + 2)
                    if eq then
                        local close_str = "]" .. string.rep("=", #eq) .. "]"
                        local _, end_pos = source:find(close_str, pos + #eq + 4, true)
                        if end_pos then
                            -- Include trailing newline in comment
                            local nl = source:find("\n", end_pos)
                            local comment_end = nl and nl + 1 or end_pos + 1
                            idx = idx + 1
                            local ph = string.format("\001STR%d\001", idx)
                            protected[ph] = source:sub(pos, comment_end - 1)
                            table.insert(parts, ph)
                            pos = comment_end
                            goto continue
                        end
                    end
                end
                -- Line comment --...
                local nl = source:find("\n", pos)
                local comment_end = nl and nl or #source
                idx = idx + 1
                local ph = string.format("\001STR%d\001", idx)
                protected[ph] = source:sub(pos, comment_end)
                table.insert(parts, ph)
                pos = comment_end + 1
                goto continue
            end
            -- Regular character
            table.insert(parts, ch)
            pos = pos + 1
            ::continue::
        end

        local result = table.concat(parts)

        -- Protect dot-notation (.name) and colon-notation (:name) property names
        -- from renaming. These are string keys, not variable references.
        -- e.g. game.Players.LocalPlayer — Players and LocalPlayer after '.' are
        -- property accesses (equivalent to ["Players"]["LocalPlayer"]), NOT variables.
        -- IMPORTANT: use %f[%.%:] frontier to exclude '..name' (concatenation) and
        -- '::name' where the separator is preceded by another . or :
        local prop_ph = {}
        local prop_n = 0
        result = result:gsub("%f[%.%:]([%.%:])%s*([%a_][%w_]*)", function(sep, name)
            prop_n = prop_n + 1
            local ph = string.format("\001PROP%d\001", prop_n)
            prop_ph[ph] = sep .. name
            return ph
        end)

        -- Sort renames by length (longest first) to avoid partial replacements
        local sorted = {}
        for k, v in pairs(renames) do
            table.insert(sorted, {key = k, val = v})
        end
        table.sort(sorted, function(a, b) return #a.key > #b.key end)

        -- Apply replacements using gsub with word boundaries
        for _, entry in ipairs(sorted) do
            local kw = entry.key:gsub("%%", "%%%%"):gsub("%.", "%%.")
            result = result:gsub("(%f[%w_])" .. kw .. "(%f[^%w_])", function(before, after)
                return before .. entry.val .. after
            end)
        end

        -- Restore property name placeholders (must be before string/comment restore
        -- because property placeholders may precede string placeholders in the string)
        for ph, original in pairs(prop_ph) do
            result = result:gsub(ph, original, 1)
        end

        -- Restore protected content
        for ph, original in pairs(protected) do
            result = result:gsub(ph, function() return original end, 1)
        end

        return result
    end

    -- Combine all renames
    local all_renames = {}
    for k, v in pairs(builtin_map) do
        all_renames[k] = v
    end
    for k, v in pairs(rename_map) do
        all_renames[k] = v
    end

    local result = protect_and_replace(code, all_renames)

    -- Step 5: Prepend local declarations for renamed builtins
    if #used_builtins > 0 then
        local decl_parts = {}
        local assign_parts = {}
        for _, entry in ipairs(used_builtins) do
            table.insert(decl_parts, entry.new_name)
            table.insert(assign_parts, entry.new_name .. "=" .. entry.original)
        end
        -- Always add semicolon after assignments to prevent Lua from parsing
        -- "X=print\n(function..." as "X = print(function...)" across lines
        -- (line comments do NOT terminate multi-line expressions in Lua)
        result = "local " .. table.concat(decl_parts, ",") .. "\n" ..
                   table.concat(assign_parts, ";") .. ";\n" .. result
    end

    return result
end

return VariableRenamer
