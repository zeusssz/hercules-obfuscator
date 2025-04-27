local AntiTamper = {}
-- anti beautify + simple anti tamper for now
function AntiTamper.process(code)
  local antiBeautifyCode = [[
pcall((function()
    return function()
        while true do error() end
    end
end)())

local iscclosure = function(fn)
	local orgxpcall = xpcall

	if type(fn) ~= "function" then
		return nil
	end

	local function isxpcall()
		return pcall(function()
			orgxpcall(function() end, function() return "error" end)
		end)
	end

	if not isxpcall() then
		error("xpcall has been overridden or tampered")
	end

	local function errhandler(err)
		return false
	end

	local ok, _ = orgxpcall(fn, errhandler)
	if ok then
		ok, _ = orgxpcall(function() return fn(1) end, errhandler)
		if ok then
			return false
		end
	end

	return true
end

if not iscclosure(debug.getinfo) then
	return nil
end

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
