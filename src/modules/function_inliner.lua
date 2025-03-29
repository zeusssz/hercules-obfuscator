local FunctionInliner = {}

function FunctionInliner.process(code)
  if code:match("^%s*%-%-.*Obfuscated") then return code end

  local functions = {}
  local output = code
  
  output = output:gsub("%-%-[^\n]*", "")
  
  output = output:gsub("local%s+function%s+([%w_]+)%s*%(([^)]*)%)(.-)end", function(name, params, body)
    functions[name] = {params = params, body = body}
    return ""
  end)
  
  output = output:gsub("function%s+([%w_]+)%s*%(([^)]*)%)(.-)end", function(name, params, body)
    functions[name] = {params = params, body = body}
    return ""
  end)
  
  for name, func in pairs(functions) do
    output = output:gsub(name .. "%s*(%b())", function(call)
      local args = call:sub(2, -2)
      local body = func.body
      
      local params = {}
      for param in func.params:gmatch("[^,%s]+") do
        params[#params+1] = param
      end
      
      local arguments = {}
      for arg in (args..","):gmatch("([^,]*),") do
        arguments[#arguments+1] = arg:match("^%s*(.-)%s*$")
      end
      
      for i, param in ipairs(params) do
        local arg = arguments[i] or "nil"
        body = body:gsub("%f[%w_]"..param.."%f[^%w_]", arg)
      end
      
      if body:match("^%s*return%s+.+") then
        body = body:gsub("^%s*return%s+", "")
      end
      
      return "(" .. body:match("^%s*(.-)%s*$") .. ")"
    end)
  end
  
  output = output:gsub("end%s*$", "")
  output = output:gsub("end%s*\n", "\n")
  output = output:gsub("\n%s*\n", "\n")
  
  return output
end

return FunctionInliner
