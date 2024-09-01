local DynamicCodeGenerator = {}

function DynamicCodeGenerator.process(code)
    local function dynamic_wrapper(block)
        local reversed_block = string.reverse(block)
        return string.format("loadstring(string.reverse(%q))()", reversed_block)
    end

    local processed_code, gsub_error = code:gsub("(.-);", function(block)
        local success, result = pcall(dynamic_wrapper, block)
        if not success then
            error("Error generating dynamic code: " .. result)
        end
        return result .. ";"
    end)

    if not processed_code then
        error("Failed to process code: " .. gsub_error)
    end

    return processed_code
end

return DynamicCodeGenerator
