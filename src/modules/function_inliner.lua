local FunctionInliner = {}

function FunctionInliner.process(code)
    local functions = {}

    code = code:gsub("function%s+([%w_]+)%s*%((.-)%)%s*(.-)%s*end", function(func_name, params, func_body)
        functions[func_name] = func_body
        return ""
    end)

    code = code:gsub("([%w_]+)%((.-)%)", function(func_name, args)
        local func_body = functions[func_name]
        if func_body then
            func_body = func_body:gsub("%b()", function(param_block)
                return args
            end)
            return func_body
        end
        return func_name .. "(" .. args .. ")"
    end)
    
    return code
end

return FunctionInliner
