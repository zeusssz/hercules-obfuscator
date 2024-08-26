local BytecodeEncoder = {}

function BytecodeEncoder.process(code)
    local function encode_to_bytecode(block)
        local func = loadstring(block)
        local bytecode = string.dump(func)
        return string.format("loadstring(%q)()", bytecode)
    end

    return code:gsub("(.-);", function(block)
        return encode_to_bytecode(block) .. ";"
    end)
end

return BytecodeEncoder