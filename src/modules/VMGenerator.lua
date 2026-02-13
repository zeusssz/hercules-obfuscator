local Parts = require("modules/Compiler/VMStrings")
local GetOpcodeCode = require("modules/Compiler/Opcode")
local compile = require("modules/Compiler/Compiler")
math.randomseed(os.time() + os.clock() * 1000000)

local function generate(...)
	local data = {...}
	local bytecode = data[1]
	local used_opcodes = data[2]
	local lines = {}
	local function add(line)
		lines[#lines+1] = line
	end
	
	local function generateVariable(length)
		local letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
		local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		local result = {}
		local rand = math.random(1, #letters)
		table.insert(result, letters:sub(rand, rand))
		for i = 2, length do
			rand = math.random(1, #charset)
			table.insert(result, charset:sub(rand, rand))
		end
		return table.concat(result)
	end
	
	local varMap = {
		X = generateVariable(math.random(8, 15)),
		Inst = generateVariable(math.random(8, 15)),
		z = generateVariable(math.random(8, 15)),
		n = generateVariable(math.random(8, 15)),
		Env = generateVariable(math.random(8, 15)),
		State = generateVariable(math.random(8, 15)),
		SenB = generateVariable(math.random(8, 15)),
		v = generateVariable(math.random(8, 15)),
		V = generateVariable(math.random(8, 15)),
		Top = generateVariable(math.random(8, 15)),
		x = generateVariable(math.random(8, 15)),
		S = generateVariable(math.random(8, 15)),
		A = generateVariable(math.random(8, 15)),
		B = generateVariable(math.random(8, 15)),
		C = generateVariable(math.random(8, 15)),
		D = generateVariable(math.random(8, 15)),
		F = generateVariable(math.random(8, 15)),
		Upval = generateVariable(math.random(8, 15)),
		Wrapped = generateVariable(math.random(8, 15)),
		Passed = generateVariable(math.random(8, 15)),
		LuaFunc = generateVariable(math.random(8, 15)),
		WrapState = generateVariable(math.random(8, 15)),
		BcToState = generateVariable(math.random(8, 15)),
		gChunk = generateVariable(math.random(8, 15)),
		Select = generateVariable(math.random(8, 15)),
		Unpack = generateVariable(math.random(8, 15)),
		Pack = generateVariable(math.random(8, 15)),
		Move = generateVariable(math.random(8, 15)),
		BAnd = generateVariable(math.random(8, 15)),
		LShift = generateVariable(math.random(8, 15)),
		RShift = generateVariable(math.random(8, 15)),
		BOr = generateVariable(math.random(8, 15)),
		CloseLuaUpvalues = generateVariable(math.random(8, 15)),
		SenLuaUpvalue = generateVariable(math.random(8, 15)),
		NormalizeNumber = generateVariable(math.random(8, 15)),
		CreateTbl = generateVariable(math.random(8, 15)),
		FIELDS_PER_FLUSH = generateVariable(math.random(8, 15)),
	}
	
	local function applyVarMap(code)
		for old, new in pairs(varMap) do
			code = code:gsub("%f[%w_]" .. old .. "%f[^%w_]", new)
		end
		return code
	end
	
	local function stringShuffle(str)
		local n = #str
		local codes = {}
		for i = 1, n do codes[i] = str:byte(i) end
		for i = n, 2, -1 do
			local j = math.random(1, i)
			codes[i], codes[j] = codes[j], codes[i]
		end
		for i = 1, n do codes[i] = string.char(codes[i]) end
		return table.concat(codes)
	end
	
	local function getChar(n)
		local out = {}
		for i = 1, n do
			out[#out + 1] = string.char(i)
		end
		return table.concat(out)
	end
	
	local charset = stringShuffle(getChar(94))
	local base, encode_lookup, decode_lookup = #charset, {}, {}
	for i = 1, base do
		local c = charset:sub(i, i)
		encode_lookup[i - 1], decode_lookup[c] = c, i - 1
	end
	
	local function encodeNumber(n)
		local e = {}
		repeat
			local r = n % base
			table.insert(e, 1, encode_lookup[r])
			n = math.floor(n / base)
		until n == 0
		return table.concat(e)
	end
	
	local function encodeString(str)
		local encoded = {}
		for i = 1, #str do
			local char = str:sub(i, i)
			table.insert(encoded, encodeNumber(char:byte()))
		end
		return table.concat(encoded, "_")
	end
	
	local function encode(str_param, yes)
		yes = yes or false
		if not yes then
			str_param = encodeString(str_param)
		end
		local out = {}
		for i = 1, #str_param do
			local b = string.byte(str_param, i)
			table.insert(out, "\\" .. b)
		end
		return table.concat(out)
	end
	
	local vmParts = Parts.generate(varMap)
	
	local junkVars = {}
	for i = 1, math.random(3, 7) do
		table.insert(junkVars, generateVariable(math.random(6, 12)))
	end
	
	add("heracles,__,_ = 'Protected By Heracles | github.com/zeusssz/heracles-obfuscator', 1, 0")
	
	if math.random(1, 2) == 1 then
		add("local " .. table.concat(junkVars, ",") .. " = " .. table.concat(junkVars, ","))
	end
	
	add(vmParts.Variables)
	add(vmParts.Deserializer)
	add(vmParts.Wrapper_1)
	
	local opcodeList = {}
	for i, v in pairs(used_opcodes) do
		table.insert(opcodeList, used_opcodes[v])
	end
	
	for i = #opcodeList, 2, -1 do
		local j = math.random(1, i)
		opcodeList[i], opcodeList[j] = opcodeList[j], opcodeList[i]
	end
	
	local k = "if"
	for _, op in ipairs(opcodeList) do
		add(k .. " (" .. varMap.S .. " == " .. op .. ") then\n")
		add(applyVarMap(GetOpcodeCode(op)))
		k = "elseif"
	end
	add("end")
	
	add(vmParts.Wrapper_2)
	
	local finalCall = varMap.WrapState .. "(" .. varMap.BcToState .. "('" .. encode(bytecode) .. "','" .. encode(charset,true) .. "'),(getfenv and getfenv(0)) or _ENV)()"
	add(finalCall)
	
	return table.concat(lines, "\n")
end

local VM = {}
function VM.process(source)
	_G.UsedOps = _G.UsedOps or {}
	_G.UsedOps[0] = 0
	_G.UsedOps[4] = 4
	source = generate(compile(source), _G.UsedOps)
	return source
end
return VM
