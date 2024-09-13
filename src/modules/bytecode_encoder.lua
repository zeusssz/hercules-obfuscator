local BytecodeEncoder = {}

function BytecodeEncoder.process(code)
    local function encode_to_bytecode(block)
        local func, load_error = loadstring(block)
        if not func then
            error("Failed to compile block: " .. load_error)
        end
        return string.format("loadstring(%q)()", string.dump(func))
    end

    local encoded_code, position = "", 1

    while position <= #code do
        local next_position = code:find(";", position)
        if not next_position then
            next_position = #code + 1
        end
        
        local block = code:sub(position, next_position - 1)
        local success, result = pcall(encode_to_bytecode, block)
        
        if not success then
            error("Error encoding block: " .. result)
        end
        
        encoded_code = encoded_code .. result .. ";"
        position = next_position + 1
    end

    return encoded_code
end

return BytecodeEncoder
