local AntiTamper = {}
-- only anti beautify for the time being. wait for proper anti tamper.
function AntiTamper.process(code)
  local antiBeautifyCode = [[
local function __antiBeautifyCheck()
  local info = debug.getinfo(2, "nSl")
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