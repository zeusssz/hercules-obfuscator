local AntiTamper = {}
-- anti beautify + simple anti tamper for now
function AntiTamper.process(code)
  local antiBeautifyCode = [[
local __debug = debug
local __getinfo = __debug.getinfo
local __origDumpable = pcall(string.dump, __getinfo)

if type(__getinfo) ~= "function" then
  print("HERCULES: Tampering Detected!")
  return
end

local function __antiBeautifyCheck()
  if type(debug.getinfo) ~= "function" or pcall(string.dump, debug.getinfo) then
    print("HERCULES: Tampering Detected!")
    return true
  end

  local info = __getinfo(2, "nSl")
  if not info or info.currentline ~= 2 or info.linedefined ~= 2 then
    print("HERCULES: Beautification Detected!")
    return true
  end
end

if __antiBeautifyCheck() then return end
]]
  return antiBeautifyCode .. "\n" .. code
end

return AntiTamper
