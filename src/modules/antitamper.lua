local AntiTamper = {}
-- only anti beautify for the time being. wait for proper anti tamper.
function AntiTamper.process(code)
  local antiBeautifyCode = [[
local __debug = debug
local __getinfo = __debug.getinfo

if type(__getinfo) ~= "function" or tostring(__getinfo):sub(1, 8) ~= "function" then
  print("HERCULES: Tampering Detected!")
  return
end

local function __antiBeautifyCheck()
  if debug.getinfo ~= __getinfo then
    print("HERCULES: debug.getinfo override detected!")
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
