local StringEncoder = {}

local function is_valid_char(byte)
    return (byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122)
end

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
            table.insert(result, string.char(byte))
        end
    end
    return table.concat(result)
end

local function generate_random_name(len)
    len = len or math.random(8, 12)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local name = ""
    for _ = 1, len do
        local index = math.random(1, #charset)
        name = name .. charset:sub(index, index)
    end
    return name
end

function StringEncoder.process(code)
    local random_decrypt_name = generate_random_name()
    local random_isvalidchar_name = generate_random_name()

    local decode_function = [[
local function ]] .. random_isvalidchar_name .. [[(byte)
    return (byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122)
end
	
local function ]] .. random_decrypt_name .. [[(code, offset)
    local result = {}
    for i = 1, #code do
        local byte = code:byte(i)
        if ]] .. random_isvalidchar_name .. [[(byte) then
            local new_byte
            if byte >= 48 and byte <= 57 then
                new_byte = ((byte - 48 - offset + 10) % 10) + 48
            elseif byte >= 65 and byte <= 90 then
                new_byte = ((byte - 65 - offset + 26) % 26) + 65
            elseif byte >= 97 and byte <= 122 then
                new_byte = ((byte - 97 - offset + 26) % 26) + 97
            end
            table.insert(result, string.char(new_byte))
        else
            table.insert(result, string.char(byte))
        end
    end
    return table.concat(result)
end

local function ]] .. random_isvalidchar_name .. [[(byte)
    return (byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122)
end
]]

    return decode_function .. "\n" .. code:gsub('"([^"]-)"', function(str)
        if type(str) == "string" then
            local offset = math.random(1, 9)
            if str:match("%a") then
                offset = math.random(1, 25)
            end
            local encoded_str = caesar_cipher(str, offset)
            return string.format('%s("%s", %d)', random_decrypt_name, encoded_str, offset)
        else
            return str
        end
    end)
end

return StringEncoder
