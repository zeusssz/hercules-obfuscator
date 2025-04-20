local AntiTamper = {}
-- anti beautify + simple anti tamper for now
function AntiTamper.process(code)
  local antiBeautifyCode = [[
local dbg, gmatch = debug, string.gmatch

local function antitamper()
    if type(dbg.getinfo) ~= "function" or pcall(string.dump, dbg.getinfo) then return true end
    for _, f in ipairs({pcall, string.dump, gmatch, dbg.getinfo, dbg.getlocal, dbg.getupvalue}) do
        local i = dbg.getinfo(f)
        if not i or i.what ~= "C" or pcall(string.dump, f) or dbg.getlocal(f, 1) or dbg.getupvalue(f, 1) then
            return true
        end
    end
end

local function getLine(msg)
    return tonumber(gmatch(tostring(msg), ":(%d+):")())
end

local function antibeautify()
    local ref = getLine(select(2, pcall(function() error("X") end)))
    if not ref then return false end
    for _ = 1, 10 do
        if getLine(select(2, pcall(function() error("Y") end))) ~= ref then return false end
    end
    return true
end

if not antibeautify() or antitamper() then print("HERCULES: Tamper Detected!") end
]]
  return antiBeautifyCode .. "\n"..code
end

return AntiTamper
