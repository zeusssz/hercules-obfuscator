local AntiTamper = {}
-- only anti beautify for the time being. wait for proper anti tamper.
function AntiTamper.process(code)
  local antiBeautifyCode = [[
local function __antiBeautifyCheck()
  local info = debug.getinfo(2, "nSl")
  if not info then error("HERCULES: Failed due to insufficient resources") end
  if info.currentline ~= 2 or info.linedefined ~= 2 then
    error("HERCULES: Beautification Detected!")
  end
end
__antiBeautifyCheck()
]]
  return antiBeautifyCode .. "\n" .. code
end

return AntiTamper