local OpaquePredicateInjector = {}

-- Opaque predicates that always evaluate to true
local TRUE_PREDICATES = {
    function()
        local n = math.random(10, 100)
        return string.format("%d %% %d == 0", n, n)
    end,
    function()
        local n = math.random(1, 100)
        return string.format("%d - %d == 0", n, n)
    end,
    function()
        local n = math.random(1, 100)
        return string.format("%d * 0 + %d == %d", n, n, n)
    end,
    function()
        local a = math.random(1, 50)
        local b = math.random(51, 100)
        return string.format("(not (%d >= %d)) == (%d < %d)", a, b, a, b)
    end,
    function()
        return "true"
    end,
    function()
        local n = math.random(1, 100)
        return string.format("%d >= %d", n, n)
    end,
    function()
        local n = math.random(1, 100)
        return string.format("not (%d ~= %d)", n, n)
    end,
    function()
        local a = math.random(1, 50)
        local b = a + math.random(1, 50)
        return string.format("%d + %d == %d", a, b - a, b)
    end,
}

-- Opaque predicates that always evaluate to false
local FALSE_PREDICATES = {
    function()
        local n = math.random(10, 100)
        return string.format("%d %% %d ~= 0", n, n)
    end,
    function()
        local n = math.random(1, 100)
        return string.format("%d ~= %d", n, n)
    end,
    function()
        local n = math.random(1, 100)
        return string.format("%d > %d", n, n)
    end,
    function()
        local a = math.random(1, 50)
        local b = a + math.random(1, 50)
        return string.format("(not (%d < %d)) == (%d >= %d)", a, b, a, b)
    end,
    function()
        return "false"
    end,
    function()
        local n = math.random(1, 100)
        return string.format("not (%d == %d)", n, n)
    end,
    function()
        local a = math.random(1, 50)
        local b = a + math.random(1, 50)
        return string.format("%d + %d ~= %d", a, b - a, b)
    end,
}

local function random_true_predicate()
    return TRUE_PREDICATES[math.random(#TRUE_PREDICATES)]()
end

local function countChar(s, ch)
    local count = 0
    for _ in s:gmatch(ch) do count = count + 1 end
    return count
end

local function isBalanced(stmt)
    local stripped = stmt:gsub('"[^"]*"', ""):gsub("'[^']*'", ""):gsub("%-%-[^\n]*", "")
    local open_paren = countChar(stripped, "%(")
    local close_paren = countChar(stripped, "%)")
    local open_brace = countChar(stripped, "%{")
    local close_brace = countChar(stripped, "%}")
    local open_bracket = countChar(stripped, "%[")
    local close_bracket = countChar(stripped, "%]")
    return open_paren == close_paren and open_brace == close_brace and open_bracket == close_bracket
end

local function random_false_predicate()
    return FALSE_PREDICATES[math.random(#FALSE_PREDICATES)]()
end

-- Keywords that should NOT be wrapped (they start blocks or are part of control flow)
local SKIP_PATTERNS = {
    "^%s*$",
    "^%s*%-%-",
    "^%s*if%s",
    "^%s*then%s*$",
    "^%s*else[^%w_]",
    "^%s*else%s*$",
    "^%s*elseif%s",
    "^%s*end[^%w_]",
    "^%s*end%s*$",
    "^%s*for%s",
    "^%s*while%s",
    "^%s*do%s*$",
    "^%s*repeat%s*$",
    "^%s*until%s",
    "^%s*function%s",
    "^%s*local%s+function%s",
    "^%s*local%s+.-%s*=%s*function%s",
    "^%s*module%s",
    "^%s*break[^%w_]",
    "^%s*break%s*$",
    "^%s*return%s",
}

local function should_skip(line)
    for _, pat in ipairs(SKIP_PATTERNS) do
        if line:match(pat) then
            return true
        end
    end
    return false
end

-- Skip strings in code, returns position after the string
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
    elseif code:sub(pos, pos + 4) == "[===[[" then
        local _, end_pos = code:find("]===]", pos, true)
        return end_pos and end_pos + 1 or pos
    elseif code:sub(pos, pos + 5) == "[====[[" then
        local _, end_pos = code:find("]====]", pos, true)
        return end_pos and end_pos + 1 or pos
    end
    return pos
end

-- Check if a line contains the keyword "local" (for variable declarations)
-- This is needed because local vars must stay at the same scope level
local function is_local_declaration(line)
    return line:match("^%s*local%s+%w") ~= nil
end

local function block_delta(line)
    local stripped = line:gsub('"[^"\\]*(\\.[^"\\]*)*"', "")
                         :gsub("'[^'\\]*(\\.[^'\\]*)*'", "")
                         :gsub("%-%-[^\n]*", "")
    local delta = 0
    if stripped:match("^%s*if%s") and stripped:match("%sthen%s*$") then delta = delta + 1 end
    if stripped:match("^%s*for%s") and stripped:match("%sdo%s*$") then delta = delta + 1 end
    if stripped:match("^%s*while%s") and stripped:match("%sdo%s*$") then delta = delta + 1 end
    if stripped:match("^%s*function%s") or stripped:match("^%s*local%s+function%s") or
        stripped:match("^%s*local%s+.-%s*=%s*function%s") then delta = delta + 1 end
    if stripped:match("^%s*do%s*$") then delta = delta + 1 end
    if stripped:match("^%s*repeat%s*$") then delta = delta + 1 end
    if stripped:match("^%s*end[^%w_]") or stripped:match("^%s*end%s*$") then delta = delta - 1 end
    if stripped:match("^%s*until%s") then delta = delta - 1 end
    return delta
end

local function starts_control_block(line)
    return block_delta(line) > 0
end

local function copy_control_block(lines, start_index, output)
    local depth = 0
    local i = start_index
    while i <= #lines do
        table.insert(output, lines[i])
        depth = depth + block_delta(lines[i])
        i = i + 1
        if depth <= 0 then break end
    end
    return i
end

function OpaquePredicateInjector.process(code)
    local lines = {}
    for line in code:gmatch("[^\n]*") do
        table.insert(lines, line)
    end

    local output = {}
    local inject_count = 0

    local i = 1
    while i <= #lines do
        local line = lines[i]
        local trimmed = line:gsub("^%s*", ""):gsub("%s+$", "")

        if starts_control_block(line) then
            i = copy_control_block(lines, i, output)
        elseif should_skip(line) or not line:match("%S") then
            table.insert(output, line)
            i = i + 1
            while i <= #lines do
                local next_trimmed = lines[i]:gsub("^%s*", ""):gsub("%s+$", "")
                if next_trimmed == "" then break end
                local last = output[#output]:gsub("^%s*", ""):gsub("%s+$", "")
                if next_trimmed:match("^:") or last:match("=%s*$") or last:match("{%s*$") or last:match(",%s*$") then
                    table.insert(output, lines[i])
                    i = i + 1
                else
                    break
                end
            end
        else
            local ws = line:match("^(%s*)") or ""
            local stmt = trimmed

            if is_local_declaration(line) then
                local skip_block = {line}
                i = i + 1
                local brace_depth = 0
                local bracket_depth = 0
                local paren_depth = 0
                -- Calculate initial depth from first line
                for ch in line:gmatch(".") do
                    if ch == "{" then brace_depth = brace_depth + 1
                    elseif ch == "}" then brace_depth = brace_depth - 1
                    elseif ch == "[" then bracket_depth = bracket_depth + 1
                    elseif ch == "]" then bracket_depth = bracket_depth - 1
                    elseif ch == "(" then paren_depth = paren_depth + 1
                    elseif ch == ")" then paren_depth = paren_depth - 1 end
                end
                while i <= #lines and (brace_depth > 0 or bracket_depth > 0 or paren_depth > 0) do
                    local next_trimmed = lines[i]:gsub("^%s*", ""):gsub("%s+$", "")
                    if next_trimmed == "" and brace_depth <= 0 and bracket_depth <= 0 and paren_depth <= 0 then break end
                    table.insert(skip_block, lines[i])
                    for ch in lines[i]:gmatch(".") do
                        if ch == "{" then brace_depth = brace_depth + 1
                        elseif ch == "}" then brace_depth = brace_depth - 1
                        elseif ch == "[" then bracket_depth = bracket_depth + 1
                        elseif ch == "]" then bracket_depth = bracket_depth - 1
                        elseif ch == "(" then paren_depth = paren_depth + 1
                        elseif ch == ")" then paren_depth = paren_depth - 1 end
                    end
                    i = i + 1
                end
                for _, sl in ipairs(skip_block) do
                    table.insert(output, sl)
                end
            else
                local block_lines = {line}
                local j = i + 1
                local brace_depth = 0
                local bracket_depth = 0
                local paren_depth = 0
                for ch in line:gmatch(".") do
                    if ch == "{" then brace_depth = brace_depth + 1
                    elseif ch == "}" then brace_depth = brace_depth - 1
                    elseif ch == "[" then bracket_depth = bracket_depth + 1
                    elseif ch == "]" then bracket_depth = bracket_depth - 1
                    elseif ch == "(" then paren_depth = paren_depth + 1
                    elseif ch == ")" then paren_depth = paren_depth - 1 end
                end
                while j <= #lines do
                    local next_line = lines[j]
                    local next_trimmed = next_line:gsub("^%s*", ""):gsub("%s+$", "")
                    if next_trimmed == "" and brace_depth <= 0 and bracket_depth <= 0 and paren_depth <= 0 then break end
                    if (next_trimmed == "end" or next_trimmed == "else" or next_trimmed:match("^then") or next_trimmed:match("^elseif")) and brace_depth <= 0 and bracket_depth <= 0 and paren_depth <= 0 then break end
                    if next_trimmed:match("^local%s") and brace_depth <= 0 and bracket_depth <= 0 and paren_depth <= 0 then break end
                    local last = block_lines[#block_lines]:gsub("^%s*", ""):gsub("%s+$", "")
                    local needs_continuation = next_trimmed:match("^:") or last:match("=%s*$") or last:match("{%s*$") or last:match(",%s*$")
                    local combined = table.concat(block_lines, " ") .. " " .. next_trimmed
                    table.insert(block_lines, next_line)
                    for ch in next_line:gmatch(".") do
                        if ch == "{" then brace_depth = brace_depth + 1
                        elseif ch == "}" then brace_depth = brace_depth - 1
                        elseif ch == "[" then bracket_depth = bracket_depth + 1
                        elseif ch == "]" then bracket_depth = bracket_depth - 1
                        elseif ch == "(" then paren_depth = paren_depth + 1
                        elseif ch == ")" then paren_depth = paren_depth - 1 end
                    end
                    j = j + 1
                    if isBalanced(combined) and not needs_continuation and brace_depth <= 0 and bracket_depth <= 0 and paren_depth <= 0 then break end
                end

                inject_count = inject_count + 1
                local predicate = random_true_predicate()

                if inject_count % 3 == 0 then
                    table.insert(output, ws .. "if " .. predicate .. " then")
                    for _, bl in ipairs(block_lines) do
                        table.insert(output, ws .. "    " .. bl:gsub("^%s*", ""))
                    end
                    table.insert(output, ws .. "elseif " .. random_false_predicate() .. " then")
                    table.insert(output, ws .. "    -- dead")
                    table.insert(output, ws .. "end")
                else
                    table.insert(output, ws .. "if " .. predicate .. " then")
                    for _, bl in ipairs(block_lines) do
                        table.insert(output, ws .. "    " .. bl:gsub("^%s*", ""))
                    end
                    table.insert(output, ws .. "end")
                end

                i = j
            end
        end
    end

    return table.concat(output, "\n")
end

return OpaquePredicateInjector
