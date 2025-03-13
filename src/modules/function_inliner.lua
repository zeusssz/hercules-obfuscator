local FunctionInliner = {}

function FunctionInliner.process(code)
    local functions = {}
    code = code:gsub("function%s+([%w_]+)%s*%((.-)%)%s*(.-)%s*end", function(func_name, params, func_body)
        functions[func_name] = { body = func_body, params = params }
        return ""
    end)

    code = code:gsub("local%s+function%s+([%w_]+)%s*%((.-)%)%s*(.-)%s*end", function(func_name, params, func_body)
        return "local function " .. func_name .. "(" .. params .. ")" .. func_body .. " end"
    end)
    code = code:gsub("([%w_]+)%s*%((.-)%)", function(func_name, args)
        local func = functions[func_name]
        if func then
            local inlined_body = func.body
            local param_names = {}
            for param in func.params:gmatch("[^,%s]+") do
                table.insert(param_names, param)
            end

            local arg_values = {}
            for arg in args:gmatch("[^,]+") do
                table.insert(arg_values, arg:match("^%s*(.-)%s*$"))
            end
            for i = 1, #param_names do
                local param = param_names[i]
                local arg = arg_values[i] or "nil"
                inlined_body = inlined_body:gsub("%f[%w_]" .. param .. "%f[^%w_]", "(" .. arg .. ")")
            end
            inlined_body = inlined_body:gsub("return%s+(.+)", "%1")
            
            return "(" .. inlined_body .. ")"
        end
        return func_name .. "(" .. args .. ")"
    end)

    return code
end

return FunctionInliner
