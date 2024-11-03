local BytecodeEncoder = {}

-- Shift each byte in the bytecode by an offset value
local function encode_bytecode(bytecode, offset)
    local encoded = {}
    for i = 1, #bytecode do
        local byte = bytecode:byte(i)
        local shifted_byte = (byte + offset) % 256 -- Apply the offset and wrap around if necessary
        table.insert(encoded, string.char(shifted_byte))
    end
    return table.concat(encoded)
end

-- Reverse the byte shift to decode the obfuscated bytecode
local function decode_bytecode(encoded_string, offset)
    local decoded = {}
    for i = 1, #encoded_string do
        local byte = encoded_string:byte(i)
        local original_byte = (byte - offset) % 256 -- Reverse the offset
        table.insert(decoded, string.char(original_byte))
    end
    return table.concat(decoded)
end

-- Main processing function to obfuscate a given Lua script
function BytecodeEncoder.process(code)
    -- Step 1: Compile Lua code into bytecode
    local bytecode = string.dump(load(code))
    
    -- Step 2: Apply a random offset to the bytecode for obfuscation
    local offset = math.random(1, 255) -- Random byte shift offset between 1 and 255
    local encoded_bytecode = encode_bytecode(bytecode, offset)
    
    -- Step 3: Generate a Lua script that decodes and runs the encoded bytecode
    local decoder_script = [[
        local function decode(encoded_string, offset)
            local decoded = {}
            for i = 1, #encoded_string do
                local byte = encoded_string:byte(i)
                local original_byte = (byte - offset) % 256
                table.insert(decoded, string.char(original_byte))
            end
            return table.concat(decoded)
        end

        -- The encoded bytecode (with an offset)
        local encoded = "]] .. encoded_bytecode:gsub(".", function(c)
            return "\\" .. string.byte(c)
        end) .. [["
        
        -- Decode and run the bytecode
        local bytecode = decode(encoded, ]] .. offset .. [[)
        local fn = load(bytecode)
        fn()
    ]]
    
    return decoder_script
end

return BytecodeEncoder
