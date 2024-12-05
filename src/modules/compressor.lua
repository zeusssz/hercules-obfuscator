local Compressor = {}

function Compressor.process(code)
    -- Check if the input is a string
    if type(code) ~= "string" then
        error("Input code must be a string.")
    end

    -- If the code matches a specific pattern, skip processing
    if code:match("^[\\d\\%\\]+$") then
        return code
    end

    -- List of Lua keywords we need to preserve during processing
    local lua_keywords = {
        "and", "or", "function", "if", "else", "elseif", "for", "while", "do", "end", "repeat", "until", "return"
    }

    -- Function to temporarily replace Lua keywords with unique placeholders
    local function preserve_keywords(code)
        for _, keyword in ipairs(lua_keywords) do
            -- Replace the keyword with a unique placeholder to avoid it being changed
            code = code:gsub("%f[%a]" .. keyword .. "%f[%A]", "___" .. keyword .. "___")
        end
        return code
    end

    -- Function to restore Lua keywords after transformations
    local function restore_keywords(code)
        for _, keyword in ipairs(lua_keywords) do
            -- Replace the placeholder back with the original keyword
            code = code:gsub("___" .. keyword .. "___", keyword)
        end
        return code
    end

    -- Preserve keywords before making changes to the code
    code = preserve_keywords(code)

    -- Perform the main compression by cleaning up whitespace, removing comments, etc.
    code = code
        :gsub("--%[%[.-%]%]", "")    -- Remove block comments (multi-line comments)
        :gsub("%-%-[^\n]*", "")       -- Remove single-line comments
        :gsub("\n+", "\n")            -- Replace multiple newlines with a single newline
        :gsub("%s*\n%s*", "\n")       -- Remove extra spaces around newlines
        :gsub("%s+", " ")             -- Replace consecutive spaces with a single space
        :gsub("%s*([%[%]{}();:,=<>~+*/%^#])%s*", "%1")  -- Remove spaces around operators and punctuation
        :gsub("([%w_]+)%s*%(", "%1(")  -- Remove spaces before function calls
        :gsub("([%)%]])%s*{", "%1{")   -- Remove spaces before opening curly braces
        :gsub("}%s*else", "}else")    -- Remove space between closing brace and else
        :gsub("}%s*elseif", "}elseif") -- Remove space between closing brace and elseif
        :gsub(";+", ";")              -- Replace multiple semicolons with a single semicolon

    -- Restore the original Lua keywords after all transformations
    return restore_keywords(code:match("^%s*(.-)%s*$") or "")
end

return Compressor
