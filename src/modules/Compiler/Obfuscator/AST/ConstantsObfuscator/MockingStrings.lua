local MockingStrings = {
   "Kia_Ainsleyy"
}
local custom_charset = "!@#$%^&*()-=_+[]{}|;:,.<>?/~`abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local function randomString(tbl)
while 49 > #tbl do
    local length = math.random(8, 16)
    local result = {}
    
    for i = 1, length do
        local randomIndex = math.random(1, #custom_charset)
        result[i] = custom_charset:sub(randomIndex, randomIndex)
    end
    table.insert(tbl, table.concat(result))
end
end
randomString(MockingStrings)
return MockingStrings
