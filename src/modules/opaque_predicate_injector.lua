local OpaquePredicateInjector = {}

local predicates = {
    " if (math.sin(math.pi) ~= 0) then ",
    " if (5^2 - 2^5 == -7) then ",
    " if ((10 > 5 and 2 < 3) or (7 == 7)) then ",
    " if (#('abc' .. 'def') == 6) then ",
}

local function inject_predicate(block)
    local predicate = predicates[math.random(#predicates)]
    return predicate .. block .. " end;"
end

function OpaquePredicateInjector.process(code)
    local processed_code = code:gsub("([ \t]*)([^\n;]*;)", function(ws, var_def)
        return ws .. inject_predicate(var_def)
    end)

    processed_code = processed_code:gsub("([ \t]*)(return%s+[^\n;]+;)", function(ws, return_stmt)
        return ws .. inject_predicate(return_stmt)
    end)

    return processed_code
end

return OpaquePredicateInjector
