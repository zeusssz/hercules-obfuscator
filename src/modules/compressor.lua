local Compressor = {}
function Compressor.process(code)
    local string_literals = {}
    if type(code) ~= "string" then
        error("Input code must be a string.")
    end
    local literal_placeholder = function(literal)
        local key = "__STR" .. tostring(#string_literals + 1) .. "__"
        table.insert(string_literals, literal)
        return key
    end
    local function escape_safe_gsub(code, pattern)
        return code:gsub(pattern, literal_placeholder)
    end
    code = escape_safe_gsub(code, '"(.-)"')
    code = escape_safe_gsub(code, "'(.-)'")
    code = escape_safe_gsub(code, "%[%[(.-)%]%]")
    code = code:gsub("%-%-%[%[.-%]%]", ""):gsub("%-%-[^\n]*", "")
    code = code:gsub("(%d)%s*%- %-(%d)", "%1 - -%2"):gsub("%- %-(%d)", "- -%1"):gsub("%- %-(%a)", "- -%1")
    code =
        code:gsub("\n+", "\n"):gsub("%s*\n%s*", "\n"):gsub("%s+", " "):gsub("%s*([%[%]{}();:,=<>~+*/%^#])%s*", "%1"):gsub(
        "(%a+)%s*%(",
        "%1("
    ):gsub("([%)%]])%s*{", "%1{"):gsub("}%s*else", "}else"):gsub("}%s*elseif", "}elseif"):gsub(";+", ";")
    code = code:match("^%s*(.-)%s*$") or ""
    code =
        code:gsub(
        "__STR(%d+)__",
        function(index)
            local str = string_literals[tonumber(index)]
            return str and ('"' .. str:gsub('[\\"]', "\\%0") .. '"') or '""'
        end
    )
    return code
end
return Compressor
