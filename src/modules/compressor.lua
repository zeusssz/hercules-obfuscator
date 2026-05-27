local Compressor = {}

local LUA_KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
    "goto", "if", "in", "local", "nil", "not", "or", "repeat", "return",
    "then", "true", "until", "while"
}

local KW_PLACEHOLDER_PRE = "@@KW_"
local KW_PLACEHOLDER_POST = "_KW@@"
local STR_PLACEHOLDER_PRE = "@@S_"
local STR_PLACEHOLDER_POST = "_S@@"

function Compressor.process(code)
    if type(code) ~= "string" then
        error("Input code must be a string.", 2)
    end
    if #code < 10 or code:match("^[%s%d%p]*$") then
        return code:match("^%s*(.-)%s*$") or ""
    end

    local strings = {}
    local string_count = 0
    local keywords_map = {}

    local function preserveStrings(c)
        local out = {}
        local i = 1

        local function preserve(value)
            string_count = string_count + 1
            local key = STR_PLACEHOLDER_PRE .. string_count .. STR_PLACEHOLDER_POST
            strings[key] = value
            out[#out + 1] = key
        end

        while i <= #c do
            local ch = c:sub(i, i)
            if ch == '"' or ch == "'" then
                local quote = ch
                local j = i + 1
                while j <= #c do
                    local current = c:sub(j, j)
                    if current == "\\" then
                        j = j + 2
                    elseif current == quote then
                        break
                    else
                        j = j + 1
                    end
                end
                preserve(c:sub(i, math.min(j, #c)))
                i = math.min(j + 1, #c + 1)
            elseif ch == "[" then
                local j = i + 1
                while c:sub(j, j) == "=" do j = j + 1 end
                if c:sub(j, j) == "[" then
                    local equals = c:sub(i + 1, j - 1)
                    local close_pattern = "]" .. equals .. "]"
                    local _, close_end = c:find(close_pattern, j + 1, true)
                    if close_end then
                        preserve(c:sub(i, close_end))
                        i = close_end + 1
                    else
                        out[#out + 1] = ch
                        i = i + 1
                    end
                else
                    out[#out + 1] = ch
                    i = i + 1
                end
            else
                out[#out + 1] = ch
                i = i + 1
            end
        end

        return table.concat(out)
    end

    local function preserveKeywords(c)
        for _, keyword in ipairs(LUA_KEYWORDS) do
            local placeholder = KW_PLACEHOLDER_PRE .. keyword .. KW_PLACEHOLDER_POST
            keywords_map[placeholder] = keyword
            c = c:gsub("([^%w_])(" .. keyword .. ")([^%w_])", "%1"..placeholder.."%3")
            c = c:gsub("^(" .. keyword .. ")([^%w_])", placeholder.."%2")
            c = c:gsub("([^%w_])(" .. keyword .. ")$", "%1"..placeholder)
            c = c:gsub("^(" .. keyword .. ")$", placeholder)
        end
        return c
    end

    local function restoreKeywords(c)
        for placeholder, keyword in pairs(keywords_map) do
             c = string.gsub(c, placeholder, function() return keyword end)
        end
        return c
    end

    local function restoreStrings(c)
        for i = string_count, 1, -1 do
            local key = STR_PLACEHOLDER_PRE .. i .. STR_PLACEHOLDER_POST
            c = string.gsub(c, key, function() return strings[key] end)
        end
        return c
    end

    local function keywordToken(keyword)
        return KW_PLACEHOLDER_PRE .. keyword .. KW_PLACEHOLDER_POST
    end

    local function startsWithKeyword(line, keyword)
        local token = keywordToken(keyword)
        return line:sub(1, #token) == token
    end

    local function endsWithKeyword(line, keyword)
        local token = keywordToken(keyword)
        return line:sub(-#token) == token
    end

    local function startsWithLastStatement(line)
        return startsWithKeyword(line, "return") or startsWithKeyword(line, "break") or
            line:match("^continue[^%w_]") or line == "continue"
    end

    local function lineDepthDelta(line)
        local delta = 0
        for i = 1, #line do
            local ch = line:sub(i, i)
            if ch == "(" or ch == "{" or ch == "[" then
                delta = delta + 1
            elseif ch == ")" or ch == "}" or ch == "]" then
                delta = delta - 1
            end
        end
        return delta
    end

    local function joinSeparator(prev, next_line, depth_after_prev)
        if prev:match("[%(%{%[,]$") or prev:match(",$") then return "" end
        if prev:match("[%+%-%*/%%%^#<>=~%.:]$") then return "" end
        if next_line:match("^[%)%}%]%],%.:]") then return "" end
        if next_line:match("^[%+%-%*/%%%^#<>=~]") then return "" end
        if startsWithLastStatement(prev) then return " " end
        if endsWithKeyword(prev, "end") or endsWithKeyword(prev, "until") then return " " end
        if startsWithKeyword(next_line, "end") or startsWithKeyword(next_line, "else") or
            startsWithKeyword(next_line, "elseif") or startsWithKeyword(next_line, "until") then
            return " "
        end
        if endsWithKeyword(prev, "then") or endsWithKeyword(prev, "do") or
            endsWithKeyword(prev, "else") or endsWithKeyword(prev, "repeat") then
            return " "
        end
        if prev:find(keywordToken("function"), 1, true) and prev:match("%)$") then
            return " "
        end
        return ";"
    end

    local function joinLines(c)
        local lines = {}
        for line in c:gmatch("[^\n]+") do
            line = line:match("^%s*(.-)%s*$") or ""
            if line ~= "" then lines[#lines + 1] = line end
        end

        local out = lines[1] or ""
        local depth = math.max(0, lineDepthDelta(out))
        for i = 2, #lines do
            out = out .. joinSeparator(lines[i - 1], lines[i], depth) .. lines[i]
            depth = math.max(0, depth + lineDepthDelta(lines[i]))
        end
        return out
    end

    code = preserveStrings(code)
    code = preserveKeywords(code)

    code = code:gsub("--%[%[.-%]%]", "")
    code = code:gsub("%-%-[^\n]*", "")

    code = code:gsub("[ \t]+", " ")
    code = code:gsub("[ \t]*[\n\r]+[ \t]*", "\n")

    code = code:gsub("[ \t]*%.%.[ \t]*", "..")
    code = code:gsub("[ \t]*([%+%-%*/%%\\^#%<%>%~%=%,%;:%(%){}%[%]])[ \t]*", "%1")
    code = code:gsub("[ \t]*%.[ \t]*", ".")
    code = code:gsub("%.%.", "..")
    code = joinLines(code)
    code = code:gsub(keywordToken("end") .. ";", keywordToken("end") .. " ")
    code = code:gsub(keywordToken("until") .. ";", keywordToken("until") .. " ")
    code = code:gsub("end;", "end ")
    code = code:gsub("until;", "until ")
    code = code:gsub(";+", ";")

    code = code:match("^%s*(.-)%s*$") or ""

    code = restoreKeywords(code)
    code = restoreStrings(code)

    return code
end

return Compressor
