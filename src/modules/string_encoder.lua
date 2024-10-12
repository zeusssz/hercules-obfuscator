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

function StringEncoder.process(code)
    local decode_function = [[
local function is_valid_char(byte)
    return (byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122)
end
	
local function decrypt_code(code, offset)
    local result = {}
    for i = 1, #code do
        local byte = code:byte(i)
        -- Transformiere nur gültige Zeichen
        if is_valid_char(byte) then
            local new_byte
            if byte >= 48 and byte <= 57 then
                -- Ziffern (48-57)
                new_byte = ((byte - 48 - offset + 10) % 10) + 48
            elseif byte >= 65 and byte <= 90 then
                -- Großbuchstaben (65-90)
                new_byte = ((byte - 65 - offset + 26) % 26) + 65
            elseif byte >= 97 and byte <= 122 then
                -- Kleinbuchstaben (97-122)
                new_byte = ((byte - 97 - offset + 26) % 26) + 97
            end
            table.insert(result, string.char(new_byte))
        else
            table.insert(result, string.char(byte)) -- Füge nicht valide Zeichen unverändert hinzu
        end
    end
    return table.concat(result)
end

local function is_valid_char(byte)
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
            return string.format('decrypt_code("%s", %d)', encoded_str, offset)
        else
            return str
        end
    end)
end

return StringEncoder
