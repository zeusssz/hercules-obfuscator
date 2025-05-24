local Parts = require("modules/Compiler/VMStrings")
local GetOpcodeCode = require("modules/Compiler/Opcode")
local compile = require("modules/Compiler/Compiler")
math.randomseed(os.time())
local function generate(...)
	local data = {
		...
	}
	local bytecode = data[1]
	local used_opcodes = data[2]
	local lines = {}
	local function add(line)
		lines[#lines+1] = line
	end;
	local function generateVariable(length)
		local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		local result = {}
		for i = 1, length do
			local rand = math.random(1, # charset)
			table.insert(result, charset:sub(rand, rand))
		end;
		return table.concat(result)
	end;
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
	end;
local function getChar(n)
    local out = {}
    for i = 1, n do
        out[#out + 1] = string.char(i)
    end
    return table.concat(out)
end
	local charset = stringShuffle(getChar(94))
	local base, encode_lookup, decode_lookup = # charset, {}, {}
	for i = 1, base do
		local c = charset:sub(i, i)
		encode_lookup[i - 1], decode_lookup[c] = c, i - 1
	end;
	local function encodeNumber(n)
		local e = {}
		repeat
			local r = n % base;
			table.insert(e, 1, encode_lookup[r])
			n = math.floor(n / base)
		until n == 0;
		return table.concat(e)
	end;
	local function encodeString(str)
		local encoded = {}
		for i = 1, # str do
			local char = str:sub(i, i)
			table.insert(encoded, encodeNumber(char:byte()))
		end;
		return table.concat(encoded, "_")
	end;
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
	add("hercules,v1,alpha,__,_ = 'Protected By Hercules V1.6 | github.com/zeusssz/hercules-obfuscator', function()end, true, 1, 0")
	add(Parts.Variables)
	add(Parts.Deserializer)
	add(Parts.Wrapper_1)
	local k = "if"
	for i, v in pairs(used_opcodes) do
		local op = used_opcodes[v]
		add(k .. " (S == " .. op .. ") then\n")
		add(GetOpcodeCode(op))
		k = "elseif"
	end;
	add("end")
	add(Parts.Wrapper_2)
	add("WrapState(BcToState('" .. encode(bytecode) .. "','" .. encode(charset,true) .. "'),(getfenv and getfenv(0)) or _ENV)()")
	return table.concat(lines, "\n")
end;
local VM = {}
function VM.process(source)
	_G.UsedOps = _G.UsedOps or {}
	_G.UsedOps[0] = 0;
	_G.UsedOps[4] = 4;
	source = generate(compile(source), _G.UsedOps)
	return source
end;
return VM
