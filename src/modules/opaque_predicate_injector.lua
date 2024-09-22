local OpaquePredicateInjector = {}

local predicates = {
    "if (math.sin(math.pi) == 0) then ",
    "if ((3 & 1) == 1 or (4 | 1) == 5) then ",
    "if (5^2 - 2^5 == 9) then ",
    "if ((10 > 5 and 2 < 3) or (7 == 7)) then ",
    "if (#('abc' .. 'def') == 6) then ",
    "if (function() local x = 10; return x * 2 / 2 == 10 end)() then ",
    "if ((5 // 2 == 2) and (not (4 > 5))) then ",
    "if ((8 % 4 == 0) and (#('xyz') == 3)) then ",
}

local function inject_predicate(block)
    local predicate = predicates[math.random(#predicates)]
    return predicate .. block .. " end"
end

function OpaquePredicateInjector.process(code)
    local processed_code = code:gsub("([ \t]*)(function[^\n]*)", function(ws, func_def)
        return ws .. inject_predicate(func_def)
    end):gsub("([ \t]*)(if[^\n]*)", function(ws, if_block)
        return ws .. inject_predicate(if_block)
    end):gsub("([ \t]*)(while[^\n]*)", function(ws, while_block)
        return ws .. inject_predicate(while_block)
    end)

    return processed_code
end

return OpaquePredicateInjector
