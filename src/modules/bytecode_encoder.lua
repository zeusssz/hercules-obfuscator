local BytecodeEncoder = {}
-- will be replaced with a better module
local function encodeBytecode(bytecode, offset)
    local encoded = {}
    for i = 1, #bytecode do
        local byte = bytecode:byte(i)
        local shifted_byte = (byte + offset) % 256
        table.insert(encoded, string.format("%02X", shifted_byte))
    end
    return table.concat(encoded)
end

function BytecodeEncoder.process(code)
    local bytecode = string.dump(assert(load(code)))
    local offset = math.random(1, 255)
    local encoded_bytecode = encodeBytecode(bytecode, offset)
    local alpha = [[
        local e, o, d = "%s", %d, {}
        for i = 1, #e, 2 do
            local b = tonumber(e:sub(i, i + 1), 16)
            b = (b - o + 256) % 256
            d[#d + 1] = string.char(b)
        end
        local f = assert(load(table.concat(d)))
        f()
    ]]
    return string.format(alpha, encoded_bytecode, offset)
end

return BytecodeEncoder
