local StringEncoder = {}

-- Generates a random name with specified length and character set
local function generate_random_name(len)
    len = len or math.random(10, 15)  -- Random length between 10 and 15
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY0123456789"
    local name = ""
    for _ = 1, len do
        local index = math.random(1, #charset)
        name = name .. charset:sub(index, index)
    end
    return name
end

-- Checks if the character byte is valid (alphanumeric)
local function is_valid_char(byte)
    return (byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122)
end

-- Encrypts or decrypts the data using Caesar cipher with random offset (positive/negative)
local function caesar_cipher(data, offset)
    local result = {}
    for i = 1, #data do
        local byte = data:byte(i)
        if is_valid_char(byte) then
            local new_byte
            if byte >= 48 and byte <= 57 then
                new_byte = ((byte - 48 + offset) % 10) + 48
            elseif byte >= 65 and byte <= 90 then
                new_byte = ((byte - 65 + offset) % 26) + 65
            elseif byte >= 97 and byte <= 122 then
                new_byte = ((byte - 97 + offset) % 26) + 97
            end
            table.insert(result, string.char(new_byte))
        else
            table.insert(result, string.char(byte)) -- Keep non-valid chars as is
        end
    end
    return table.concat(result)
end

-- Main processing function for encoding strings
function StringEncoder.process(code)
    local random_decrypt_name = generate_random_name()
    local random_isvalidchar_name = generate_random_name()
    local random_result_name = generate_random_name()
    local random_code_name = generate_random_name()
    local random_offset_name = generate_random_name()
    local random_byte_name = generate_random_name()
    local random_new_byte_name = generate_random_name()

    -- Generate the decoding function with some added dummy logic for obfuscation
    local decode_function = [[
local function ]] .. random_isvalidchar_name .. [[(]] .. random_byte_name .. [[)
    return (]] .. random_byte_name .. [[ >= 48 and ]] .. random_byte_name .. [[ <= 57) or 
           (]] .. random_byte_name .. [[ >= 65 and ]] .. random_byte_name .. [[ <= 90) or 
           (]] .. random_byte_name .. [[ >= 97 and ]] .. random_byte_name .. [[ <= 122)
end

local function ]] .. random_decrypt_name .. [[(]] .. random_code_name .. [[, ]] .. random_offset_name .. [[)
    local ]] .. random_result_name .. [[ = {}
    for i = 1, #]] .. random_code_name .. [[ do
        local ]] .. random_byte_name .. [[ = ]] .. random_code_name .. [[:byte(i)
        if ]] .. random_isvalidchar_name .. [[(]] .. random_byte_name .. [[) then
            local ]] .. random_new_byte_name .. [[
            if ]] .. random_byte_name .. [[ >= 48 and ]] .. random_byte_name .. [[ <= 57 then
                ]] .. random_new_byte_name .. [[ = ((]] .. random_byte_name .. [[ - 48 - ]] .. random_offset_name .. [[ + 10) % 10) + 48
            elseif ]] .. random_byte_name .. [[ >= 65 and ]] .. random_byte_name .. [[ <= 90 then
                ]] .. random_new_byte_name .. [[ = ((]] .. random_byte_name .. [[ - 65 - ]] .. random_offset_name .. [[ + 26) % 26) + 65
            elseif ]] .. random_byte_name .. [[ >= 97 and ]] .. random_byte_name .. [[ <= 122 then
                ]] .. random_new_byte_name .. [[ = ((]] .. random_byte_name .. [[ - 97 - ]] .. random_offset_name .. [[ + 26) % 26) + 97
            end
            table.insert(]] .. random_result_name .. [[, string.char(]] .. random_new_byte_name .. [[))
        else
            table.insert(]] .. random_result_name .. [[, string.char(]] .. random_byte_name .. [[))
        end
    end
    return table.concat(]] .. random_result_name .. [[)
end
]]

    -- Encode the provided code with the caesar cipher, preserving the logic flow
    return decode_function .. "\n" .. code:gsub('"([^"]-)"', function(str)
        local offset = math.random(-(os.time()), os.time())
        local encoded_str = caesar_cipher(str, offset)
        return string.format('%s("%s", %d)', random_decrypt_name, encoded_str, offset)
    end)
end

return StringEncoder
