 -- this happens after the vm because you just can't make it before a vm, it requires string encoding adds a decoder function that must exist at runtime when the VM tries to compile code with decoder_func(data[1]) calls, it needs the decoder function to exist But the decoder is just code it gets compiled away into bytecode too
local StringEncoder = {}

math.randomseed(os.time())

local function generateRandomName(len)
    len = len or math.random(6, 12)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"
    local name = ""
    for _ = 1, len do
        local index = math.random(1, #charset)
        name = name .. charset:sub(index, index)
    end
    return name
end

local function createEncryptionService()
    local key = math.random(1, 255)
    
    local function encrypt(str)
        if #str == 0 then return {}, 0 end
        
        local seed = math.random(0, 65535)
        local encrypted = {}
        
        for i = 1, #str do
            local byte = str:byte(i)
            local offset = (seed + i + key) % 256
            local encrypted_byte = (byte + offset) % 256
            table.insert(encrypted, encrypted_byte)
        end
        
        return encrypted, seed
    end
    
    local function generateDecryptorCode()
        local v_strings = generateRandomName()
        local v_decrypt = generateRandomName()
        local v_cache = generateRandomName()
        local v_str = generateRandomName()
        local v_seed = generateRandomName()
        local v_result = generateRandomName()
        local v_i = generateRandomName()
        local v_byte = generateRandomName()
        local v_offset = generateRandomName()
        
        local code = string.format([[
local %s = {}
local %s_data = {}

local function %s(%s, %s)
    if %s[%s] then
        return %s[%s]
    end
    
    local %s = ""
    for %s = 1, #%s do
        local %s = string.byte(%s, %s)
        local %s = (%s + %s + %d) %% 256
        %s = (%s - %s) %% 256
        %s = %s .. string.char(%s)
    end
    
    %s[%s] = %s
    return %s
end

%s = setmetatable({}, {
    __index = function(_, idx)
        return %s(%s_data[idx][1], %s_data[idx][2])
    end,
    __metatable = false
})
]], 
            v_cache, v_strings,
            v_decrypt, v_str, v_seed,
            v_cache, v_seed, v_cache, v_seed,
            v_result,
            v_i, v_str,
            v_byte, v_str, v_i,
            v_offset, v_seed, v_i, key,
            v_byte, v_byte, v_offset,
            v_result, v_result, v_byte,
            v_cache, v_seed, v_result, v_result,
            v_strings,
            v_decrypt, v_strings, v_strings
        )
        
        return code, v_strings
    end
    
    return {
        encrypt = encrypt,
        generateDecryptorCode = generateDecryptorCode,
        key = key
    }
end

local protected_strings = {
    ["__index"] = true, ["__newindex"] = true, ["__call"] = true, ["__tostring"] = true,
    ["__add"] = true, ["__sub"] = true, ["__mul"] = true, ["__div"] = true, ["__mod"] = true,
    ["__pow"] = true, ["__unm"] = true, ["__concat"] = true, ["__len"] = true,
    ["__eq"] = true, ["__lt"] = true, ["__le"] = true, ["__gc"] = true, ["__mode"] = true,
    ["__metatable"] = true, ["__pairs"] = true, ["__ipairs"] = true,
}

function StringEncoder.process(code)
    if type(code) ~= "string" or #code == 0 then
        return code
    end
    
    if code:match("BcToState") or code:match("WrapState") or #code > 100000 then
        return code
    end
    
    local service = createEncryptionService()
    local string_id = 1
    local encrypted_strings = {}
    local strings_to_replace = {}
    
    local pos = 1
    while true do
        local start_pos, end_pos, content = code:find('"([^"]*)"', pos)
        if not start_pos then break end
        
        local line_start = code:sub(1, start_pos):match(".*\n(.*)$") or code:sub(1, start_pos)
        local is_comment = line_start:match("^%s*%-%-")
        local is_protected = protected_strings[content]
        local is_numeric = content:match("^%-?%d+$") or content:match("^%-?%d+%.%d+$")
        
        if not is_comment and not is_protected and not is_numeric and #content > 0 then
            table.insert(strings_to_replace, {
                start_pos = start_pos,
                end_pos = end_pos,
                content = content,
                full_match = code:sub(start_pos, end_pos)
            })
        end
        
        pos = end_pos + 1
    end
    
    pos = 1
    while true do
        local start_pos, end_pos, content = code:find("'([^']*)'", pos)
        if not start_pos then break end
        
        local line_start = code:sub(1, start_pos):match(".*\n(.*)$") or code:sub(1, start_pos)
        local is_comment = line_start:match("^%s*%-%-")
        local is_protected = protected_strings[content]
        local is_numeric = content:match("^%-?%d+$") or content:match("^%-?%d+%.%d+$")
        
        if not is_comment and not is_protected and not is_numeric and #content > 0 then
            table.insert(strings_to_replace, {
                start_pos = start_pos,
                end_pos = end_pos,
                content = content,
                full_match = code:sub(start_pos, end_pos)
            })
        end
        
        pos = end_pos + 1
    end
    
    if #strings_to_replace == 0 then
        return code
    end
    
    for _, str_info in ipairs(strings_to_replace) do
        local encrypted_bytes, seed = service.encrypt(str_info.content)
        encrypted_strings[string_id] = {
            bytes = encrypted_bytes,
            seed = seed,
            original = str_info.content
        }
        str_info.string_id = string_id
        string_id = string_id + 1
    end
    
    table.sort(strings_to_replace, function(a, b) return a.start_pos > b.start_pos end)
    
    local decryptor_code, strings_var = service.generateDecryptorCode()
    
    local strings_init = {}
    for id, data in pairs(encrypted_strings) do
        local encrypted_str = ""
        for _, byte in ipairs(data.bytes) do
            encrypted_str = encrypted_str .. string.char(byte)
        end
        
        local lua_str = '"'
        for i = 1, #encrypted_str do
            local byte = encrypted_str:byte(i)
            if byte == 92 then -- \ (must be first to avoid double escaping)
                lua_str = lua_str .. '\\\\'
            elseif byte == 34 then -- "
                lua_str = lua_str .. '\\"'
            elseif byte == 10 then -- \n
                lua_str = lua_str .. '\\n'
            elseif byte == 13 then -- \r
                lua_str = lua_str .. '\\r'
            elseif byte == 9 then -- \t
                lua_str = lua_str .. '\\t'
            elseif byte == 0 then -- null byte
                lua_str = lua_str .. '\\000'
            elseif byte >= 32 and byte <= 126 then
                lua_str = lua_str .. string.char(byte)
            else
                lua_str = lua_str .. string.format('\\%03d', byte)
            end
        end
        lua_str = lua_str .. '"'
        
        table.insert(strings_init, string.format('[%d]={%s,%d}', 
            id, 
            lua_str,
            data.seed))
    end
    
    decryptor_code = decryptor_code:gsub(strings_var .. "_data = {}", 
        strings_var .. "_data = {" .. table.concat(strings_init, ",") .. "}")
    
    local result = code
    for _, str_info in ipairs(strings_to_replace) do
        local replacement = string.format("%s[%d]", strings_var, str_info.string_id)
        result = result:sub(1, str_info.start_pos - 1) .. replacement .. result:sub(str_info.end_pos + 1)
    end
    
    for id, data in pairs(encrypted_strings) do
        local original_str = data.original
        if original_str:match("^[%a_][%w_]*$") then
            local encoded_ref = string.format("%s[%d]", strings_var, id)
            result = result:gsub("%.(" .. original_str .. ")([^%w_])", function(prop, suffix)
                return "[" .. encoded_ref .. "]" .. suffix
            end)
            result = result:gsub("%.(" .. original_str .. ")$", function(prop)
                return "[" .. encoded_ref .. "]"
            end)
        end
    end
    
    result = decryptor_code .. "\n" .. result
    
    return result
end

return StringEncoder
