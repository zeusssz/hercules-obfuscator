local OpaquePredicateInjector = {}

function OpaquePredicateInjector.process(code)
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
        local end_predicate = " end"
        return predicate .. block .. end_predicate
    end

    local processed_code, gsub_error = code:gsub("(.-);", function(block)
        local success, result = pcall(inject_predicate, block)
        if not success then
            error("Error injecting predicate: " .. result)
        end
        return result .. ";"
    end)

    if not processed_code then
        error("Failed to process code: " .. gsub_error)
    end

    return processed_code
end

return OpaquePredicateInjector
