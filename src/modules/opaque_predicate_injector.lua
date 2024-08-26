local OpaquePredicateInjector = {}

function OpaquePredicateInjector.process(code)
    local function inject_predicate(block)
        local predicate = "if (math.random(1, 1) == 1) then "
        local end_predicate = " end"
        return predicate .. block .. end_predicate
    end

    return code:gsub("(.-);", function(block)
        return inject_predicate(block) .. ";"
    end)
end

return OpaquePredicateInjector