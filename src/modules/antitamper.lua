local AntiTamper = {}
-- anti beautify + simple anti tamper for now
function AntiTamper.process(code)
  local antiBeautifyCode = [[
pcall((function()
    return function()
        while true do error() end
    end
end)())  

local dbg = debug
local function antitamper()
  if type(dbg.getinfo) ~= "function" or pcall(string.dump, dbg.getinfo) then return true end
  for _, f in ipairs({pcall, string.dump, dbg.getinfo, dbg.getlocal, dbg.getupvalue}) do
    local i = dbg.getinfo(f)
    if not i or i.what ~= "C" or pcall(string.dump, f) or dbg.getlocal(f, 1) or dbg.getupvalue(f, 1) then
      return true
    end
  end
end

local function antibeautify()
  local i = dbg.getinfo(2, "Sl")
  return not i or i.linedefined ~= 2 or i.currentline ~= 2
end

if antibeautify() or antitamper() then
  print("HERCULES: Tamper Detected!")
  return
end
]]
  return antiBeautifyCode .. "\n" .. code
end

return AntiTamper