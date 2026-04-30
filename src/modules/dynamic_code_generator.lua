local DynamicCodeGenerator = {}

-- Patterns for lines that should NOT be wrapped (control flow, declarations, etc.)
-- Note: - must be escaped as %- in Lua patterns
local SKIP_PATTERNS = {
    "^%s*$",              -- empty lines
    "^%s*%-%-",           -- comments (-- comment)
    "^%s*if%s",           -- if statements
    "^%s*then%s*",        -- then
    "^%s*else%s*",        -- else
    "^%s*elseif%s",       -- elseif
    "^%s*end%s*",         -- end
    "^%s*for%s",          -- for loops
    "^%s*while%s",        -- while loops
    "^%s*do%s*",          -- do
    "^%s*repeat%s*",      -- repeat
    "^%s*until%s",        -- until
    "^%s*function%s",     -- function declarations
    "^%s*local%s",        -- local declarations
    "^%s*return%s",       -- return statements
    "^%s*module%s",       -- module declarations
    "^%s*require%s*%(",  -- require calls
}

local function should_skip(line)
    for _, pat in ipairs(SKIP_PATTERNS) do
        if line:match(pat) then
            return true
        end
    end
    return false
end

function DynamicCodeGenerator.process(code)
    -- Split code into lines (without trailing newline)
    local lines = {}
    for line in code:gmatch("[^\n]*") do
        table.insert(lines, line)
    end

    -- Wrap each wrappable statement in an IIFE
    -- This obfuscates code by adding function call indirection
    local output = {}
    for _, line in ipairs(lines) do
        if should_skip(line) or not line:match("%S") then
            table.insert(output, line)
        else
            local ws = line:match("^(%s*)")
            local stmt = line:gsub("^%s*", ""):gsub("%s+$", "")
            -- Prefix with ; to prevent Lua from parsing adjacent IIFEs as one expression
            -- e.g. (f())(g()) would call result of f() with g() as argument
            table.insert(output, ws .. ";(function() " .. stmt .. " end)()")
        end
    end

    return table.concat(output, "\n")
end

return DynamicCodeGenerator
