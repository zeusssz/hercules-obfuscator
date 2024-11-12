local OpaquePredicateInjector = {}

local predicates = {
    " if (math.sin(0) == 0) then ", 
    " if (5^2 == 25) then ", 
    " if ((10 > 5 and 2 < 3) or (7 ~= 8)) then ", 
    " if (#('abcdef') == 6) then ", 
    " if (not false) then ", 
    " if (select(2, pcall(function() return 1 end)) == 1) then ", 
    " if (type(tonumber('123')) == 'number') then ", 
}

local function is_safe_for_injection(statement)
    if statement:match("^%s*for%s+") or statement:match("^%s*while%s+") or statement:match("^%s*if%s+") then
        return false
    end
    if statement:match("^%s*$") or not statement:match(".+;") then
        return false
    end
    return true
end
local function inject_predicate(block)
    local predicate = predicates[math.random(#predicates)] 
    if block:match("%s*end%s*;?$") then
        return predicate .. block
    elseif block:match("^%s*return") then
        return block
    else
        return predicate .. block .. " end;"
    end
end
function OpaquePredicateInjector.process(code)
    local success, processed_code = pcall(function()
        return code:gsub("([ \t]*)([^\n;]*;)", function(ws, statement)
            if is_safe_for_injection(statement) then
                return ws .. inject_predicate(statement)
            else
                return ws .. statement
            end
        end)
    end)
    if success then
        processed_code = processed_code:gsub("([ \t]*)(return%s+[^\n;]+;)", function(ws, return_stmt)
            return ws .. return_stmt
        end)
        return processed_code
    else
        return code
    end
end

return OpaquePredicateInjector
