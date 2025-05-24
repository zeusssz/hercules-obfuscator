local OpaquePredicateInjector = {}
-- TODO : make it better
local function generatePredicates()
    local predicates = {
        function() 
            local n = math.random(10, 100)
            return string.format("if (%d %% 1 == 0 and %d >= %d) then", n, n, n)
        end,
        function()
            local x = math.random(1, 10)
            return string.format("if (%d %% %d == 0) then", x, x)
        end,
        function()
            local angle = math.random(0, 360)
            return string.format("if (math.sin(%d)^2 + math.cos(%d)^2 >= 0.99999) then", 
                angle, angle)
        end,
        function()
            local str = string.format("%x", math.random(1000, 9999))
            return string.format("if (select(2, pcall(function() return tonumber('%s', 16) end)) ~= nil) then", str)
        end,
        function()
            local size = math.random(2, 5)
            return string.format("if (#{%s} == %d) then",
                string.rep("1,", size-1) .. "1", size)
        end,
        function()
            local a, b = math.random(1, 10), math.random(11, 20)
            return string.format("if ((%d < %d) == not (%d >= %d)) then", a, b, a, b)
        end
    }
    return predicates[math.random(#predicates)]()
end

local function isInjectSafe(statement)
    if statement:match("^%s*[%{%}]%s*$") or
       statement:match("^%s*$") or
       not statement:match(".+;") then
        return false
    end
    local unsafes = {
        "^%s*for%s+",
        "^%s*while%s+",
        "^%s*if%s+",
        "^%s*repeat%s+",
        "^%s*until%s+",
        "^%s*function%s+",
        "^%s*local%s+function",
        "^%s*do%s+",
    }
    for _, pattern in ipairs(unsafes) do
        if statement:match(pattern) then
            return false
        end
    end
    if statement:match("^%s*if%s+.+%s+then%s+.+%s+end%s*;?$") then
        return false
    end
    return true
end

local function injectPredicates(block)
    if block:match("%s*end%s*;?$") or block:match("^%s*return") then
        return block
    else
        local predicate = generatePredicates()
        return predicate .. block .. " end;"
    end
end

function OpaquePredicateInjector.process(code)
    if type(code) ~= "string" then
        error("Input must be a string")
    end
    local success, processed_code = pcall(function()
        local result = code:gsub("([ \t]*)([^\n;]*;)", function(ws, statement)
            if isInjectSafe(statement) then
                return ws .. injectPredicates(statement)
            else
                return ws .. statement
            end
        end)
        result = result:gsub("([ \t]*)(return%s+[^\n;]+;)", function(ws, return_stmt)
            return ws .. return_stmt
        end)
        return result
    end)
    if not success then
        error("Failed to process code: " .. tostring(processed_code))
    end
    return processed_code
end

function OpaquePredicateInjector.validateCode(code)
    local f, err = load(code)
    return f ~= nil, err
end

return OpaquePredicateInjector
