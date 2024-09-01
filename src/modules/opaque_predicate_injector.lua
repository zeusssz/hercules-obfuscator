local OpaquePredicateInjector = {}

function OpaquePredicateInjector.process(code)
    local function inject_predicate(block)
        local predicate = "if (math.random() > 0) then "
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
