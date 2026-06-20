local BytecodeEncoder = {}

local function random_name()
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local len = math.random(8, 14)
    local out = {}
    for i = 1, len do
        local idx = math.random(1, #charset)
        out[i] = charset:sub(idx, idx)
    end
    return table.concat(out)
end

local function next_state(state, mul, inc, mod)
    return (state * mul + inc) % mod
end

local function key_byte(state)
    return math.floor(state / 65536) % 256
end

local function encode_bytecode(bytecode, seed, salt, mul, inc, mod)
    local state = seed
    local encoded = {}
    for i = 1, #bytecode do
        state = next_state(state, mul, inc, mod)
        encoded[i] = (bytecode:byte(i) + key_byte(state) + i + salt) % 256
    end
    return encoded
end

local function split_chunks(bytes)
    local chunks = {}
    local pos = 1
    while pos <= #bytes do
        local size = math.random(37, 113)
        local chunk = {}
        for _ = 1, size do
            if pos > #bytes then break end
            chunk[#chunk + 1] = bytes[pos]
            pos = pos + 1
        end
        chunks[#chunks + 1] = chunk
    end
    return chunks
end

local function shuffled_layout(chunks)
    local slots, order = {}, {}
    local indices = {}
    for i = 1, #chunks do indices[i] = i end
    for i = #indices, 2, -1 do
        local j = math.random(1, i)
        indices[i], indices[j] = indices[j], indices[i]
    end
    for slot, original in ipairs(indices) do
        slots[slot] = chunks[original]
        order[original] = slot
    end
    return slots, order
end

local function table_literal(values)
    return "{" .. table.concat(values, ",") .. "}"
end

local function chunks_literal(chunks)
    local out = {}
    for i, chunk in ipairs(chunks) do
        out[i] = table_literal(chunk)
    end
    return "{" .. table.concat(out, ",") .. "}"
end

function BytecodeEncoder.process(code)
    local ok, fn = pcall(load, code, "=hercules", "t")
    if not ok or type(fn) ~= "function" then return code end

    local dumped_ok, bytecode = pcall(string.dump, fn, true)
    if not dumped_ok then return code end

    local seed = math.random(1, 2147483646)
    local salt = math.random(1, 255)
    local mul = ({1103515245, 1664525, 22695477})[math.random(1, 3)]
    local inc = math.random(101, 65535)
    if inc % 2 == 0 then inc = inc + 1 end
    local mod = 2147483647

    local encoded = encode_bytecode(bytecode, seed, salt, mul, inc, mod)
    local chunks = split_chunks(encoded)
    local slots, order = shuffled_layout(chunks)

    local n_chunks = random_name()
    local n_order = random_name()
    local n_state = random_name()
    local n_seed = random_name()
    local n_out = random_name()
    local n_idx = random_name()
    local n_ci = random_name()
    local n_chunk = random_name()
    local n_value = random_name()
    local n_key = random_name()
    local n_loader = random_name()
    local n_char = random_name()
    local n_concat = random_name()
    local n_fn = random_name()

    return string.format([=[
do
    local %s=%s
    local %s=%s
    local %s,%s,%s,%s=%d,%d,{},0
    local %s,%s=string.char,table.concat
    for _=1,#%s do
        local %s=%s[%s[_]]
        for __=1,#%s do
            %s=(%s*%d+%d)%%%d
            local %s=math.floor(%s/65536)%%256
            local %s=%s[__]
            %s=%s+1
            %s[#%s+1]=%s((%s-%s-%s-%d)%%256)
        end
    end
    local %s=assert((loadstring or load)(%s(%s)))
    return %s()
end
]=],
        n_chunks, chunks_literal(slots),
        n_order, table_literal(order),
        n_seed, n_state, n_out, n_idx, seed, seed,
        n_char, n_concat,
        n_order,
        n_chunk, n_chunks, n_order,
        n_chunk,
        n_state, n_state, mul, inc, mod,
        n_key, n_state,
        n_value, n_chunk,
        n_idx, n_idx,
        n_out, n_out, n_char, n_value, n_key, n_idx, salt,
        n_fn, n_concat, n_out,
        n_fn
    )
end

return BytecodeEncoder
