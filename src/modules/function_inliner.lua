local FunctionInliner = {}

function FunctionInliner.process(code)
  if code:match("^%s*%-%-.*Obfuscated") then
    return code
  end

  local functions = {}
  
  code = code:gsub("local%s+function%s+([%w_]+)%s*%((.-)%)(.-)end", function(name, params, body)
    if body:sub(1,1) ~= "\n" then return end
    
    body = body:sub(2)
    functions[name] = {params = params, body = body}
    return ""
  end)
  
  code = code:gsub("function%s+([%w_]+)%s*%((.-)%)(.-)end", function(name, params, body)
    if body:sub(1,1) ~= "\n" then return end
    
    body = body:sub(2)
    functions[name] = {params = params, body = body}
    return ""
  end)
  
  code = code:gsub("([%w_]+)%s*%((.-)%)", function(name, args)
    if not functions[name] then
      return name .. "(" .. args .. ")"
    end
    
    local func = functions[name]
    local body = func.body
    
    if func.params == "..." then
      body = body:gsub("%.%.%.", args)
    else
      local params = {}
      for param in func.params:gmatch("[^%s,]+") do
        table.insert(params, param)
      end
      
      local arguments = {}
      for arg in args:gmatch("[^,]+") do
        table.insert(arguments, arg:match("^%s*(.-)%s*$"))
      end
      
      for i = 1, #params do
        local param = params[i]
        local arg = arguments[i] or "nil"
        body = body:gsub("%f[%w_]" .. param .. "%f[^%w_]", arg)
      end
    end
    
    body = body:gsub("return%s+", "")
    return body:match("^%s*(.-)%s*$")
  end)
  
  return code
end

return FunctionInliner
