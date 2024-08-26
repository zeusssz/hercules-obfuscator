local DynamicCodeGenerator = {}

function DynamicCodeGenerator.process(code)
    local function dynamic_wrapper(block)
        local encoded = string.reverse(block)
        return string.format("loadstring(string.reverse('%s'))()", encoded)
    end

    return code:gsub("(.-);", function(block)
        return dynamic_wrapper(block) .. ";"
    end)
end

return DynamicCodeGenerator