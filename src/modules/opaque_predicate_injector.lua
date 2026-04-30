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

local function random_false_predicate()
    return FALSE_PREDICATES[math.random(#FALSE_PREDICATES)]()
end

-- Keywords that should NOT be wrapped (they start blocks or are part of control flow)
local SKIP_PATTERNS = {
    "^%s*$",
    "^%s*%-%-",
    "^%s*if%s",
    "^%s*then%s*$",
    "^%s*else%s*$",
    "^%s*elseif%s",
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

function OpaquePredicateInjector.process(code)
    -- Split code into lines
    local lines = {}
    for line in code:gmatch("[^\n]*") do
        table.insert(lines, line)
    end

    -- Track block depth and determine injectable lines
    -- We only inject at depth 0 (top-level) or inside simple blocks (not nested control flow)
    local output = {}
    local inject_count = 0

    for _, line in ipairs(lines) do
        if should_skip(line) or not line:match("%S") then
            table.insert(output, line)
        else
            local ws = line:match("^(%s*)") or ""
            local stmt = line:gsub("^%s*", ""):gsub("%s+$", "")

            -- Local variable declarations must NOT be wrapped in if blocks
            -- because that would limit their scope to the if block
            if is_local_declaration(line) then
                table.insert(output, line)
            else
                inject_count = inject_count + 1
                local predicate = random_true_predicate()

                if inject_count % 3 == 0 then
                    table.insert(output, ws .. "if " .. predicate .. " then")
                    table.insert(output, ws .. "    " .. stmt)
                    table.insert(output, ws .. "elseif " .. random_false_predicate() .. " then")
                    table.insert(output, ws .. "    -- dead")
                    table.insert(output, ws .. "end")
                else
                    table.insert(output, ws .. "if " .. predicate .. " then")
                    table.insert(output, ws .. "    " .. stmt)
                    table.insert(output, ws .. "end")
                end
            end
        end
    end

    return table.concat(output, "\n")
end

return OpaquePredicateInjector
