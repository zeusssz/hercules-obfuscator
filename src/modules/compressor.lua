local Compressor = {}

function Compressor.process(code, preserveComments)
    local string_literals = {}
    
    if type(code) ~= "string" then
        error("Input code must be a string.")
    end
    local literal_placeholder = function(literal)
        local key = "__STR" .. #string_literals + 1 .. "__"
        table.insert(string_literals, literal)
        return key
    end
    code = code:gsub('"(.-)"', literal_placeholder)
              :gsub("'(.-)'", literal_placeholder)
    if not preserveComments then
        code = code:gsub("%-%-%[%[.-%]%]", "")
                   :gsub("%-%-[^\n]*", "")
    end
    code = code:gsub("\n+", "\n")
               :gsub("%s*\n%s*", "\n")
               :gsub("%s+", " ")
               :gsub("%s*([%[%]{}();:,=<>~+%-*/%^#])%s*", "%1")
               :gsub("(%a+)%s*%(", "%1(")
               :gsub("([%)%]])%s*{", "%1{")
               :gsub("}%s*else", "}else")
               :gsub("}%s*elseif", "}elseif")
               :gsub(";+", ";")
    code = code:match("^%s*(.-)%s*$") or ""
    code = code:gsub("__STR(%d+)__", function(index)
        return '"' .. (string_literals[tonumber(index)] or "") .. '"'
    end)
    return code
end
return Compressor
