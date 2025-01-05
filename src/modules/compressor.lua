local Compressor = {}

local function preservestrs(code)
    local storedstrs = {}
    local index = 0
    code = code:gsub("(['\"])(.-)%1", function(quote, content)
        index = index + 1
        local placeholder = "___STRING_" .. index .. "___"
        storedstrs[placeholder] = quote .. content .. quote
        return placeholder
    end)
    return code, storedstrs
end

local function restorestrs(code, storedstrs)
    for placeholder, original in pairs(storedstrs) do
        code = code:gsub(placeholder, original)
    end
    return code
end

function Compressor.process(code)
    if type(code) ~= "string" then
        error("Input code must be a string.")
    end
    if code:match("^[\\d\\%\\]+$") then
        return code
    end
    local lua_keywords = {
        "and", "or", "function", "if", "else", "elseif",
        "for", "while", "do", "end", "repeat", "until", "return"
    }

    local function preserve_keywords(code)
        for _, keyword in ipairs(lua_keywords) do
            code = code:gsub("%f[%a]" .. keyword .. "%f[%A]", "___" .. keyword .. "___")
        end
        return code
    end

    local function restore_keywords(code)
        for _, keyword in ipairs(lua_keywords) do
            code = code:gsub("___" .. keyword .. "___", keyword)
        end
        return code
    end
    code = preserve_keywords(code)
    local storedstrs
    code, storedstrs = preservestrs(code)
    code = code
        :gsub("--%[%[.-%]%]", "")
        :gsub("%-%-[^\n]*", "")
        :gsub("\n+", "\n")
        :gsub("%s*\n%s*", "\n")
        :gsub("%s+", " ")
        :gsub("%s*([%[%]{}();:,=<>~+*/%^#])%s*", "%1")
        :gsub("([%w_]+)%s*%(", "%1(")
        :gsub("([%)%]])%s*{", "%1{")
    code = restorestrs(code, storedstrs)
    code = restore_keywords(code)

    return code
end

return Compressor
