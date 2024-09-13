local DynamicCodeGenerator = {}

function DynamicCodeGenerator.process(code)
    local function dynamic_wrapper(block)
        local reversed_block = string.reverse(block)
        return string.format("loadstring(string.reverse(%q))()", reversed_block)
    end

    local processed_code, position = "", 1

    while position <= #code do
        local next_position = code:find(";", position)
        if not next_position then
            next_position = #code + 1
        end
        
        local block = code:sub(position, next_position - 1)
        local success, result = pcall(dynamic_wrapper, block)
        
        if not success then
            error("Error generating dynamic code: " .. result)
        end
        
        processed_code = processed_code .. result .. ";"
        position = next_position + 1
    end

    return processed_code
end

return DynamicCodeGenerator
