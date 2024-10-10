local DynamicCodeGenerator = {}

function DynamicCodeGenerator.process(code)
    local function dynamic_wrapper(block)
        return load(block)()
    end

    local processed_code = ""
    local position = 1

    while position <= #code do
        local next_position = code:find("[%s%p]", position)
        if not next_position then
            next_position = #code + 1
        end
        local block = code:sub(position, next_position - 1):gsub("\n", "")

        if #block > 0 then
            local success, result = pcall(dynamic_wrapper, block)
            if not success then
                error("Error generating dynamic code: " .. result)
            end
            processed_code = processed_code .. result .. "\n"
        end
        position = next_position + 1
    end

    return processed_code
end

return DynamicCodeGenerator
