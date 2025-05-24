local DynamicCodeGenerator = {}
-- TODO : make it work
function DynamicCodeGenerator.process(code)
    local function dynamicWrapper(block)
        local func, err = load("return " .. block)
        if not func then
            error("Failed to load block: " .. err)
        end
        return func()
    end

    local processed_code = {}
    local position = 1

    while position <= #code do
        local next_position = code:find("[%s%p]", position)
        if not next_position then
            next_position = #code + 1
        end
        local block = code:sub(position, next_position - 1)
        if #block > 0 then
            local success, result = pcall(dynamicWrapper, block)
            if success then
                table.insert(processed_code, tostring(result))
            else
                error("Error processing block '" .. block .. "': " .. result)
            end
        end
        if next_position <= #code then
            table.insert(processed_code, code:sub(next_position, next_position))
        end

        position = next_position + 1
    end

    return table.concat(processed_code)
end

return DynamicCodeGenerator
