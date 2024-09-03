local BytecodeEncoder = {}

function BytecodeEncoder.process(code)
    local function encode_to_bytecode(block)
        local func, load_error = loadstring(block)
        if not func then
            error("Failed to compile block: " .. load_error)
        end
        return string.format("loadstring(%q)()", string.dump(func))
    end

    local encoded_code, gsub_error = code:gsub("(.-);", function(block)
        local success, result = pcall(encode_to_bytecode, block)
        if not success then
            error("Error encoding block: " .. result)
        end
        return result .. ";"
    end)

    if not encoded_code then
        error("Failed to encode code: " .. gsub_error)
    end

    return encoded_code
end

return BytecodeEncoder
