local AntiTamper = {}
-- only anti beautify for the time being. wait for proper anti tamper.
function AntiTamper.process(code)
  local antiBeautifyCode = [[
local __HERCULES_safe_getinfo = debug.getinfo

local function __antiBeautifyCheck()
  if debug.getinfo ~= __HERCULES_safe_getinfo then
    print("HERCULES: Tampering detected!")
    return true
  end

  local info = __HERCULES_safe_getinfo(2, "nSl")
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
