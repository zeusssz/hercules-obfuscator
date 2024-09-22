local BytecodeEncoder = {}

local function escape_bytecode(bytecode)
    return bytecode:gsub(".", function(char)
        local byte = string.byte(char)
        if byte < 32 or byte > 126 or char == "\\" or char == "\"" then
            return string.format("\\x%02X", byte)
        else
            return char
        end
    end)
end

function BytecodeEncoder.process(code)
    local function encode_to_bytecode(block)
        local func, load_error = load(block)
        if not func then
            error("Failed to compile block: " .. load_error)
        end

        local bytecode = string.dump(func)
        local escaped_bytecode = escape_bytecode(bytecode)
        return string.format("load(\"%s\")()", escaped_bytecode)
    end

    local encoded_code, gsub_error = code:gsub("([^;]+);", function(block)
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
