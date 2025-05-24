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
        c = c:gsub("%[(=*)%[(.-)%]%1%]", function(equals, str)
            string_count = string_count + 1
            local key = STR_PLACEHOLDER_PRE .. string_count .. STR_PLACEHOLDER_POST
            strings[key] = "[" .. equals .. "[" .. str .. "]" .. equals .. "]"
            return key
        end)
        c = c:gsub('"(.-)"', function(str)
            if not str:find("\\", 1, true) and str:find(STR_PLACEHOLDER_PRE, 1, true) then
                 return '"'..str..'"'
            end
            string_count = string_count + 1
            local key = STR_PLACEHOLDER_PRE .. string_count .. STR_PLACEHOLDER_POST
            strings[key] = '"' .. str .. '"'
            return key
        end)
        c = c:gsub("('.-')", function(str)
             if not str:find("\\", 1, true) and str:find(STR_PLACEHOLDER_PRE, 1, true) then
                 return "'"..str.."'"
            end
            string_count = string_count + 1
            local key = STR_PLACEHOLDER_PRE .. string_count .. STR_PLACEHOLDER_POST
            strings[key] = str
            return key
        end)
        return c
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

    code = preserveStrings(code)
    code = preserveKeywords(code)

    code = code:gsub("--%[%[.-%]%]", "")
    code = code:gsub("%-%-[^\n]*", "")

    code = code:gsub("[\n\r]+", " ")
    code = code:gsub("%s+", " ")

    code = code:gsub("%s*%.%.%s*", "..")
    code = code:gsub("%s*([%+%-%*/%%\\^#%<%>%~%=%,%;:%(%){}%[%]])%s*", "%1")
    code = code:gsub("%s*%.%s*", ".")
    code = code:gsub("%.%.", "..")

    code = code:match("^%s*(.-)%s*$") or ""

    code = restoreKeywords(code)
    code = restoreStrings(code)

    return code
end

return Compressor