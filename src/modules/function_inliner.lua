local FunctionInliner = {}

function FunctionInliner.process(code)
    for func_name, func_body in code:gmatch("function%s+([%w_]+)%s*%((.-)%)%s*(.-)%s*end") do
        code = code:gsub(func_name .. "%((.-)%)", func_body)
    end
    return code
end

return FunctionInliner