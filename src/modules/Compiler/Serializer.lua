local bit = require("modules/Compiler/bit")
function Serialize(Chunk)
	local Buffer = {}
	local function AddByte(Value)
		table.insert(Buffer, string.char(Value).."\\")
	end;
	local function WriteBits8(Value)
		AddByte(Value)
	end;
	local function WriteBits16(Value)
		for i = 0, 1 do
			AddByte(bit.band(bit.rshift(Value, i * 8), 255))
		end
	end;
	local function WriteBits32(Value)
		for i = 0, 3 do
			AddByte(bit.band(bit.rshift(Value, i * 8), 255))
		end
	end;
	local function WriteFloat64(value)
		local sign = 0;
		if value < 0 or (value == 0 and 1 / value == - math.huge) then
			sign = 1
		end;
		local mantissa, exponent = math.frexp(math.abs(value))
		if value == 0 then
			exponent, mantissa = 0, 0
		elseif value == math.huge then
			exponent, mantissa = 2047, 0
		elseif value ~= value then
			exponent, mantissa = 2047, 1
		else
			mantissa = (mantissa * 2 - 1) * 2 ^ 52;
			exponent = exponent + 1022
		end;
		local high = sign * 2 ^ 31 + exponent * 2 ^ 20 + math.floor(mantissa / 2 ^ 32)
		local low = mantissa % 2 ^ 32;
		WriteBits32(low)
		WriteBits32(high)
	end;
	local function WriteString(Str)
		WriteBits32(# Str)
		for i = 1, # Str do
			WriteBits8(string.byte(Str, i))
		end
	end;
	local function WriteChunk(SubChunk)
		WriteBits8(SubChunk.Upvals)
		WriteBits8(SubChunk.Parameters)
		WriteBits8(SubChunk.MaxStack)
		WriteBits32(# SubChunk.Instructions)
		for i = 1, # SubChunk.Instructions do
			local Inst = SubChunk.Instructions[i]
			local Data = Inst.Value;
			local Enum = Inst.Enum;
			local Type = Inst.Type;
			local Mode = Inst.Mode;
			WriteBits32(Data)
			WriteBits8(Enum)
			WriteBits8((Type == "ABC" and 1) or (Type == "ABx" and 2) or (Type == "AsBx" and 3))
			WriteBits16(Inst.A)
			if (Mode.b == "OpArgK") then
				WriteBits8(1)
			elseif (Mode.b == "OpArgN") then
				WriteBits8(0)
			elseif (Mode.b == "OpArgU") then
				WriteBits8(0)
			elseif (Mode.b == "OpArgR") then
				WriteBits8(0)
			end;
			if (Mode.c == "OpArgK") then
				WriteBits8(1)
			elseif (Mode.c == "OpArgN") then
				WriteBits8(0)
			elseif (Mode.c == "OpArgU") then
				WriteBits8(0)
			elseif (Mode.c == "OpArgR") then
				WriteBits8(0)
			end;
			if (Type == "ABC") then
				WriteBits16(Inst.B)
				WriteBits16(Inst.C)
			elseif (Type == "ABx") then
				WriteBits32(Inst.Bx)
			elseif (Type == "AsBx") then
				WriteBits32(Inst.sBx + 131071)
			end
		end;
		WriteBits32(# SubChunk.Constants)
		for i = 1, # SubChunk.Constants do
			local Const = SubChunk.Constants[i]
			local Type = type(Const)
			if (Type == "boolean") then
				WriteBits8(1)
				WriteBits8(Const and 1 or 0)
			elseif (Type == "number") then
				WriteBits8(3)
				WriteFloat64(Const)
			elseif (Type == "string") then
				WriteBits8(4)
				WriteString(Const)
			end
		end;
		WriteBits32(# SubChunk.Protos)
		for i = 1, # SubChunk.Protos do
			WriteChunk(SubChunk.Protos[i])
		end
	end;
	WriteChunk(Chunk)
	return table.concat(Buffer)
end;
return Serialize
