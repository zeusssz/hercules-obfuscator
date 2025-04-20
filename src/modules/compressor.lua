local Compressor = {}

function Compressor.process(code)
    if type(code) ~= "string" then
        error("Input code must be a string.")
    end
    if code:match("^[\\d\\%\\]+$") then
        return code
    end

    local strings = {}
    local string_count = 0

    local function preservestrs(code)
        code = code:gsub("%[(=*)%[(.-)%]%1%]", function(equals, str)
            string_count = string_count + 1
            strings[string_count] = "[" .. equals .. "[" .. str .. "]" .. equals .. "]"
            return "<S" .. string_count .. ">"
        end)
        code = code:gsub('(".-")', function(str)
            string_count = string_count + 1
            strings[string_count] = str
            return "<S" .. string_count .. ">"
        end)
        
        code = code:gsub("('.-')", function(str)
            string_count = string_count + 1
            strings[string_count] = str
            return "<S" .. string_count .. ">"
        end)
        
        return code
    end

    local function restorestrs(code)
        for i = string_count, 1, -1 do
            code = string.gsub(code, "<S" .. i .. ">", function() return (strings[i]) end)
        end
        return code
    end

    local lua_keywords = {
        "and", "or", "function", "if", "else", "elseif", "for", "while", "do", 
        "end", "repeat", "until", "return", "local", "then"
    }

    local function preservekeyws(code)
        for _, keyword in ipairs(lua_keywords) do
            code = code:gsub("%f[%a]" .. keyword .. "%f[%A]", "___" .. keyword .. "___")
        end
        return code
    end

    local function restorekeyws(code)
        for _, keyword in ipairs(lua_keywords) do
            code = code:gsub("___" .. keyword .. "___", keyword)
        end
        return code
    end

    code = preservestrs(code)
    code = preservekeyws(code)

    code = code
        :gsub("--%[%[.-%]%]", "")
        :gsub("%-%-[^\n]*", "")
        :gsub("\n+", "\n")
        :gsub("%s*\n%s*", "\n")
        :gsub("%s+", " ")
        :gsub("%s*([%[%]{}();:,=<>~+*/%^#])%s*", "%1")
        :gsub("([%w_]+)%s*%(", "%1(")
        :gsub("([%)%]])%s*{", "%1{")
        :gsub("}%s*else", "}else")
        :gsub("}%s*elseif", "}elseif")
        :gsub(";+", ";")
        :gsub("([%w_]+)%s*([%+%-%*/%^#])%s*(%d+)", "%1%2%3")
        :gsub("([%d]+)%s*([%+%-%*/%^#])%s*([%w_]+)", "%1%2%3")
        :gsub("%s*([%[%]{}();:,=<>~+*/%^#])%s*", "%1")
    
    code = restorekeyws(code)
    code = restorestrs(code)
    
    return code:match("^%s*(.-)%s*$") or ""
end

return Compressor