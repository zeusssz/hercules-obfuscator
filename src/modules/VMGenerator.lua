
local luaZ = {}
local luaY = {}
local luaX = {}
local luaP = {}
local luaU = {}
local luaK = {}
local size_size_t = 8;
local bit = {}
function bit.band(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
        if (a % 2 == 1) and (b % 2 == 1) then
            result = result + bitval
        end
        bitval = bitval * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return result
end
function bit.lshift(x, n)
    return x * 2 ^ n
end
function bit.rshift(x, n)
    return math.floor(x / 2 ^ n)
end
local function Serialize(Chunk)
	local Buffer = {}
	local function AddByte(Value)
		table.insert(Buffer, string.char(Value))
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
_G.UsedOps = {}
if not table.create then
	function table.create(_)
		return {}
	end
end;
local lua_bc_to_state;
local stm_lua_func;
local OPCODE_T = {
	[0] = 'ABC',
	'ABx',
	'ABC',
	'ABC',
	'ABC',
	'ABx',
	'ABC',
	'ABx',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'AsBx',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'AsBx',
	'AsBx',
	'ABC',
	'ABC',
	'ABC',
	'ABx',
	'ABC'
}
local OPCODE_M = {
	[0] = {
		b = 'OpArgR',
		c = 'OpArgN'
	},
	{
		b = 'OpArgK',
		c = 'OpArgN'
	},
	{
		b = 'OpArgU',
		c = 'OpArgU'
	},
	{
		b = 'OpArgR',
		c = 'OpArgN'
	},
	{
		b = 'OpArgU',
		c = 'OpArgN'
	},
	{
		b = 'OpArgK',
		c = 'OpArgN'
	},
	{
		b = 'OpArgR',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgN'
	},
	{
		b = 'OpArgU',
		c = 'OpArgN'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgU',
		c = 'OpArgU'
	},
	{
		b = 'OpArgR',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgR',
		c = 'OpArgN'
	},
	{
		b = 'OpArgR',
		c = 'OpArgN'
	},
	{
		b = 'OpArgR',
		c = 'OpArgN'
	},
	{
		b = 'OpArgR',
		c = 'OpArgR'
	},
	{
		b = 'OpArgR',
		c = 'OpArgN'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgR',
		c = 'OpArgU'
	},
	{
		b = 'OpArgR',
		c = 'OpArgU'
	},
	{
		b = 'OpArgU',
		c = 'OpArgU'
	},
	{
		b = 'OpArgU',
		c = 'OpArgU'
	},
	{
		b = 'OpArgU',
		c = 'OpArgN'
	},
	{
		b = 'OpArgR',
		c = 'OpArgN'
	},
	{
		b = 'OpArgR',
		c = 'OpArgN'
	},
	{
		b = 'OpArgN',
		c = 'OpArgU'
	},
	{
		b = 'OpArgU',
		c = 'OpArgU'
	},
	{
		b = 'OpArgN',
		c = 'OpArgN'
	},
	{
		b = 'OpArgU',
		c = 'OpArgN'
	},
	{
		b = 'OpArgU',
		c = 'OpArgN'
	}
}
local function rd_int_basic(src, s, e, d)
	local num = 0;
	for i = s, e, d do
		local mul = 256 ^ math.abs(i - s)
		num = num + mul * string.byte(src, i, i)
	end;
	return num
end;
local function rd_flt_basic(f1, f2, f3, f4)
	local sign = (- 1) ^ bit.rshift(f4, 7)
	local exp = bit.rshift(f3, 7) + bit.lshift(bit.band(f4, 127), 1)
	local frac = f1 + bit.lshift(f2, 8) + bit.lshift(bit.band(f3, 127), 16)
	local normal = 1;
	if exp == 0 then
		if frac == 0 then
			return sign * 0
		else
			normal = 0;
			exp = 1
		end
	elseif exp == 127 then
		if frac == 0 then
			return sign * (1 / 0)
		else
			return sign * (0 / 0)
		end
	end;
	return sign * 2 ^ (exp - 127) * (1 + normal / 2 ^ 23)
end;
local function rd_dbl_basic(f1, f2, f3, f4, f5, f6, f7, f8)
	local sign = (- 1) ^ bit.rshift(f8, 7)
	local exp = bit.lshift(bit.band(f8, 127), 4) + bit.rshift(f7, 4)
	local frac = bit.band(f7, 15) * 2 ^ 48;
	local normal = 1;
	frac = frac + (f6 * 2 ^ 40) + (f5 * 2 ^ 32) + (f4 * 2 ^ 24) + (f3 * 2 ^ 16) + (f2 * 2 ^ 8) + f1;
	if exp == 0 then
		if frac == 0 then
			return sign * 0
		else
			normal = 0;
			exp = 1
		end
	elseif exp == 2047 then
		if frac == 0 then
			return sign * (1 / 0)
		else
			return sign * (0 / 0)
		end
	end;
	return sign * 2 ^ (exp - 1023) * (normal + frac / 2 ^ 52)
end;
local function rd_int_le(src, s, e)
	return rd_int_basic(src, s, e - 1, 1)
end;
local function rd_int_be(src, s, e)
	return rd_int_basic(src, e - 1, s, - 1)
end;
local function rd_flt_le(src, s)
	return rd_flt_basic(string.byte(src, s, s + 3))
end;
local function rd_flt_be(src, s)
	local f1, f2, f3, f4 = string.byte(src, s, s + 3)
	return rd_flt_basic(f4, f3, f2, f1)
end;
local function rd_dbl_le(src, s)
	return rd_dbl_basic(string.byte(src, s, s + 7))
end;
local function rd_dbl_be(src, s)
	local f1, f2, f3, f4, f5, f6, f7, f8 = string.byte(src, s, s + 7)
	return rd_dbl_basic(f8, f7, f6, f5, f4, f3, f2, f1)
end;
local float_types = {
	[4] = {
		little = rd_flt_le,
		big = rd_flt_be
	},
	[8] = {
		little = rd_dbl_le,
		big = rd_dbl_be
	}
}
local function stm_byte(S)
	local idx = S.index;
	local bt = string.byte(S.source, idx, idx)
	S.index = idx + 1;
	return bt
end;
local function stm_string(S, len)
	local pos = S.index + len;
	local str = string.sub(S.source, S.index, pos - 1)
	S.index = pos;
	return str
end;
local function stm_lstring(S)
	local len = S:s_szt()
	local str;
	if len ~= 0 then
		str = string.sub(stm_string(S, len), 1, - 2)
	end;
	return str
end;
local function cst_int_rdr(len, func)
	return function(S)
		local pos = S.index + len;
		local int = func(S.source, S.index, pos)
		S.index = pos;
		return int
	end
end;
local function cst_flt_rdr(len, func)
	return function(S)
		local flt = func(S.source, S.index)
		S.index = S.index + len;
		return flt
	end
end;
local function stm_inst_list(S)
	local len = S:s_int()
	local list = table.create(len)
	for i = 1, len do
		local ins = S:s_ins()
		local op = bit.band(ins, 63)
		local args = OPCODE_T[op]
		local mode = OPCODE_M[op]
		local data = {
			Value = ins,
			Enum = op,
			Type = args,
			Mode = mode,
			A = bit.band(bit.rshift(ins, 6), 255)
		}
		if args == 'ABC' then
			data.B = bit.band(bit.rshift(ins, 23), 511)
			data.C = bit.band(bit.rshift(ins, 14), 511)
		elseif args == 'ABx' then
			data.Bx = bit.band(bit.rshift(ins, 14), 262143)
		elseif args == 'AsBx' then
			data.sBx = bit.band(bit.rshift(ins, 14), 262143) - 131071
		end;
		if not _G.UsedOps[op] then
			_G.UsedOps[op] = op
		end;
		list[i] = data
	end;
	return list
end;
local function stm_const_list(S)
	local len = S:s_int()
	local list = table.create(len)
	for i = 1, len do
		local tt = stm_byte(S)
		local k;
		if tt == 1 then
			k = stm_byte(S) ~= 0
		elseif tt == 3 then
			k = S:s_num()
		elseif tt == 4 then
			k = stm_lstring(S)
		end;
		list[i] = k
	end;
	return list
end;
local function stm_sub_list(S, src)
	local len = S:s_int()
	local list = table.create(len)
	for i = 1, len do
		list[i] = stm_lua_func(S, src)
	end;
	return list
end;
local function stm_line_list(S)
	local len = S:s_int()
	local list = table.create(len)
	for i = 1, len do
		list[i] = S:s_int()
	end;
	return list
end;
local function stm_loc_list(S)
	local len = S:s_int()
	local list = table.create(len)
	for i = 1, len do
		list[i] = {
			varname = stm_lstring(S),
			startpc = S:s_int(),
			endpc = S:s_int()
		}
	end;
	return list
end;
local function stm_upval_list(S)
	local len = S:s_int()
	local list = table.create(len)
	for i = 1, len do
		list[i] = stm_lstring(S)
	end;
	return list
end;
function stm_lua_func(S, psrc)
	local proto = {}
	local src = stm_lstring(S) or psrc;
	proto.SourceName = src;
	S:s_int()
	S:s_int()
	proto.Upvals = stm_byte(S)
	proto.Parameters = stm_byte(S)
	stm_byte(S)
	proto.MaxStack = stm_byte(S)
	proto.Instructions = stm_inst_list(S)
	proto.Constants = stm_const_list(S)
	proto.Protos = stm_sub_list(S, src)
	stm_line_list(S)
	stm_loc_list(S)
	stm_upval_list(S)
	return proto
end;
function Deserialize(src)
	local rdr_func;
	local little;
	local size_int;
	local size_szt;
	local size_ins;
	local size_num;
	local flag_int;
	local stream = {
		index = 1,
		source = src
	}
	assert(stm_string(stream, 4) == '\27Lua', 'invalid Lua signature')
	assert(stm_byte(stream) == 81, 'invalid Lua version')
	assert(stm_byte(stream) == 0, 'invalid Lua format')
	little = stm_byte(stream) ~= 0;
	size_int = stm_byte(stream)
	size_szt = stm_byte(stream)
	size_ins = stm_byte(stream)
	size_num = stm_byte(stream)
	flag_int = stm_byte(stream) ~= 0;
	rdr_func = little and rd_int_le or rd_int_be;
	stream.s_int = cst_int_rdr(size_int, rdr_func)
	stream.s_szt = cst_int_rdr(size_szt, rdr_func)
	stream.s_ins = cst_int_rdr(size_ins, rdr_func)
	if flag_int then
		stream.s_num = cst_int_rdr(size_num, rdr_func)
	elseif float_types[size_num] then
		stream.s_num = cst_flt_rdr(size_num, float_types[size_num][little and 'little' or 'big'])
	else
		error('unsupported float size')
	end;
	return stm_lua_func(stream, '@virtual')
end;
local function lua_assert(test)
	if not test then
		error("assertion failed!")
	end
end;
function luaZ:make_getS(buff)
	local b = buff;
	return function()
		if not b then
			return nil
		end;
		local data = b;
		b = nil;
		return data
	end
end;
function luaZ:make_getF(source)
	local LUAL_BUFFERSIZE = 512;
	local pos = 1;
	return function()
		local buff = source:sub(pos, pos + LUAL_BUFFERSIZE - 1)
		pos = math.min(# source + 1, pos + LUAL_BUFFERSIZE)
		return buff
	end
end;
function luaZ:init(reader, data)
	if not reader then
		return
	end;
	local z = {}
	z.reader = reader;
	z.data = data or ""
	z.name = ""
	if not data or data == "" then
		z.n = 0
	else
		z.n = # data
	end;
	z.p = 0;
	return z
end;
function luaZ:fill(z)
	local buff = z.reader()
	z.data = buff;
	if not buff or buff == "" then
		return "EOZ"
	end;
	z.n, z.p = # buff - 1, 1;
	return string.sub(buff, 1, 1)
end;
function luaZ:zgetc(z)
	local n, p = z.n, z.p + 1;
	if n > 0 then
		z.n, z.p = n - 1, p;
		return string.sub(z.data, p, p)
	else
		return self:fill(z)
	end
end;
luaX.RESERVED = [[
	TK_AND and
	TK_BREAK break
	TK_DO do
	TK_ELSE else
	TK_ELSEIF elseif
	TK_END end
	TK_FALSE false
	TK_FOR for
	TK_FUNCTION function
	TK_IF if
	TK_IN in
	TK_LOCAL local
	TK_NIL nil
	TK_NOT not
	TK_OR or
	TK_REPEAT repeat
	TK_RETURN return
	TK_THEN then
	TK_TRUE true
	TK_UNTIL until
	TK_WHILE while
	TK_CONCAT ..
	TK_DOTS ...
	TK_EQ ==
	TK_GE >=
	TK_LE <=
	TK_NE ~=
	TK_NAME <name>
	TK_NUMBER <number>
	TK_STRING <string>
	TK_EOS <eof>]]
luaX.MAXSRC = 80;
luaX.MAX_INT = 2147483645;
luaX.LUA_QS = "'%s'"
luaX.LUA_COMPAT_LSTR = 1;
function luaX:init()
	local tokens, enums = {}, {}
	for v in string.gmatch(self.RESERVED, "[^\n]+") do
		local _, _, tok, str = string.find(v, "(%S+)%s+(%S+)")
		tokens[tok] = str;
		enums[str] = tok
	end;
	self.tokens = tokens;
	self.enums = enums
end;
function luaX:chunkid(source, bufflen)
	local out;
	local first = string.sub(source, 1, 1)
	if first == "=" then
		out = string.sub(source, 2, bufflen)
	else
		if first == "@" then
			source = string.sub(source, 2)
			bufflen = bufflen - # " '...' "
			local l = # source;
			out = ""
			if l > bufflen then
				source = string.sub(source, 1 + l - bufflen)
				out = out .. "..."
			end;
			out = out .. source
		else
			local len = string.find(source, "[\n\r]")
			len = len and (len - 1) or # source;
			bufflen = bufflen - # (" [string \"...\"] ")
			if len > bufflen then
				len = bufflen
			end;
			out = "[string \""
			if len < # source then
				out = out .. string.sub(source, 1, len) .. "..."
			else
				out = out .. source
			end;
			out = out .. "\"]"
		end
	end;
	return out
end;
function luaX:token2str(ls, token)
	if string.sub(token, 1, 3) ~= "TK_" then
		if string.find(token, "%c") then
			return string.format("char(%d)", string.byte(token))
		end;
		return token
	else
		return self.tokens[token]
	end
end;
function luaX:lexerror(ls, msg, token)
	local function txtToken(ls, token)
		if token == "TK_NAME" or token == "TK_STRING" or token == "TK_NUMBER" then
			return ls.buff
		else
			return self:token2str(ls, token)
		end
	end;
	local buff = self:chunkid(ls.source, self.MAXSRC)
	local msg = string.format("%s:%d: %s", buff, ls.linenumber, msg)
	if token then
		msg = string.format("%s near " .. self.LUA_QS, msg, txtToken(ls, token))
	end;
	error(msg)
end;
function luaX:syntaxerror(ls, msg)
	self:lexerror(ls, msg, ls.t.token)
end;
function luaX:currIsNewline(ls)
	return ls.current == "\n" or ls.current == "\r"
end;
function luaX:inclinenumber(ls)
	local old = ls.current;
	self:nextc(ls)
	if self:currIsNewline(ls) and ls.current ~= old then
		self:nextc(ls)
	end;
	ls.linenumber = ls.linenumber + 1;
	if ls.linenumber >= self.MAX_INT then
		self:syntaxerror(ls, "chunk has too many lines")
	end
end;
function luaX:setinput(L, ls, z, source)
	if not ls then
		ls = {}
	end;
	if not ls.lookahead then
		ls.lookahead = {}
	end;
	if not ls.t then
		ls.t = {}
	end;
	ls.decpoint = "."
	ls.L = L;
	ls.lookahead.token = "TK_EOS"
	ls.z = z;
	ls.fs = nil;
	ls.linenumber = 1;
	ls.lastline = 1;
	ls.source = source;
	self:nextc(ls)
end;
function luaX:check_next(ls, set)
	if not string.find(set, ls.current, 1, 1) then
		return false
	end;
	self:save_and_next(ls)
	return true
end;
function luaX:next(ls)
	ls.lastline = ls.linenumber;
	if ls.lookahead.token ~= "TK_EOS" then
		ls.t.seminfo = ls.lookahead.seminfo;
		ls.t.token = ls.lookahead.token;
		ls.lookahead.token = "TK_EOS"
	else
		ls.t.token = self:llex(ls, ls.t)
	end
end;
function luaX:lookahead(ls)
	ls.lookahead.token = self:llex(ls, ls.lookahead)
end;
function luaX:nextc(ls)
	local c = luaZ:zgetc(ls.z)
	ls.current = c;
	return c
end;
function luaX:save(ls, c)
	local buff = ls.buff;
	ls.buff = buff .. c
end;
function luaX:save_and_next(ls)
	self:save(ls, ls.current)
	return self:nextc(ls)
end;
function luaX:str2d(s)
	local result = tonumber(s)
	if result then
		return result
	end;
	if string.lower(string.sub(s, 1, 2)) == "0x" then
		result = tonumber(s, 16)
		if result then
			return result
		end
	end;
	return nil
end;
function luaX:buffreplace(ls, from, to)
	local result, buff = "", ls.buff;
	for p = 1, # buff do
		local c = string.sub(buff, p, p)
		if c == from then
			c = to
		end;
		result = result .. c
	end;
	ls.buff = result
end;
function luaX:trydecpoint(ls, Token)
	local old = ls.decpoint;
	self:buffreplace(ls, old, ls.decpoint)
	local seminfo = self:str2d(ls.buff)
	Token.seminfo = seminfo;
	if not seminfo then
		self:buffreplace(ls, ls.decpoint, ".")
		self:lexerror(ls, "malformed number", "TK_NUMBER")
	end
end;
function luaX:read_numeral(ls, Token)
	repeat
		self:save_and_next(ls)
	until string.find(ls.current, "%D") and ls.current ~= "."
	if self:check_next(ls, "Ee") then
		self:check_next(ls, "+-")
	end;
	while string.find(ls.current, "^%w$") or ls.current == "_" do
		self:save_and_next(ls)
	end;
	self:buffreplace(ls, ".", ls.decpoint)
	local seminfo = self:str2d(ls.buff)
	Token.seminfo = seminfo;
	if not seminfo then
		self:trydecpoint(ls, Token)
	end
end;
function luaX:skip_sep(ls)
	local count = 0;
	local s = ls.current;
	self:save_and_next(ls)
	while ls.current == "=" do
		self:save_and_next(ls)
		count = count + 1
	end;
	return (ls.current == s) and count or (- count) - 1
end;
function luaX:read_long_string(ls, Token, sep)
	local cont = 0;
	self:save_and_next(ls)
	if self:currIsNewline(ls) then
		self:inclinenumber(ls)
	end;
	while true do
		local c = ls.current;
		if c == "EOZ" then
			self:lexerror(ls, Token and "unfinished long string" or "unfinished long comment", "TK_EOS")
		elseif c == "[" then
			if self.LUA_COMPAT_LSTR then
				if self:skip_sep(ls) == sep then
					self:save_and_next(ls)
					cont = cont + 1;
					if self.LUA_COMPAT_LSTR == 1 then
						if sep == 0 then
							self:lexerror(ls, "nesting of [[...]] is deprecated", "[")
						end
					end
				end
			end
		elseif c == "]" then
			if self:skip_sep(ls) == sep then
				self:save_and_next(ls)
				if self.LUA_COMPAT_LSTR and self.LUA_COMPAT_LSTR == 2 then
					cont = cont - 1;
					if sep == 0 and cont >= 0 then
						break
					end
				end;
				break
			end
		elseif self:currIsNewline(ls) then
			self:save(ls, "\n")
			self:inclinenumber(ls)
			if not Token then
				ls.buff = ""
			end
		else
			if Token then
				self:save_and_next(ls)
			else
				self:nextc(ls)
			end
		end
	end;
	if Token then
		local p = 3 + sep;
		Token.seminfo = string.sub(ls.buff, p, - p)
	end
end;
function luaX:read_string(ls, del, Token)
	self:save_and_next(ls)
	while ls.current ~= del do
		local c = ls.current;
		if c == "EOZ" then
			self:lexerror(ls, "unfinished string", "TK_EOS")
		elseif self:currIsNewline(ls) then
			self:lexerror(ls, "unfinished string", "TK_STRING")
		elseif c == "\\" then
			c = self:nextc(ls)
			if self:currIsNewline(ls) then
				self:save(ls, "\n")
				self:inclinenumber(ls)
			elseif c ~= "EOZ" then
				local i = string.find("abfnrtv", c, 1, 1)
				if i then
					self:save(ls, string.sub("\a\b\f\n\r\t\v", i, i))
					self:nextc(ls)
				elseif not string.find(c, "%d") then
					self:save_and_next(ls)
				else
					c, i = 0, 0;
					repeat
						c = 10 * c + ls.current;
						self:nextc(ls)
						i = i + 1
					until i >= 3 or not string.find(ls.current, "%d")
					if c > 255 then
						self:lexerror(ls, "escape sequence too large", "TK_STRING")
					end;
					self:save(ls, string.char(c))
				end
			end
		else
			self:save_and_next(ls)
		end
	end;
	self:save_and_next(ls)
	Token.seminfo = string.sub(ls.buff, 2, - 2)
end;
function luaX:llex(ls, Token)
	ls.buff = ""
	while true do
		local c = ls.current;
		if self:currIsNewline(ls) then
			self:inclinenumber(ls)
		elseif c == "-" then
			c = self:nextc(ls)
			if c ~= "-" then
				return "-"
			end;
			local sep = - 1;
			if self:nextc(ls) == '[' then
				sep = self:skip_sep(ls)
				ls.buff = ""
			end;
			if sep >= 0 then
				self:read_long_string(ls, nil, sep)
				ls.buff = ""
			else
				while not self:currIsNewline(ls) and ls.current ~= "EOZ" do
					self:nextc(ls)
				end
			end
		elseif c == "[" then
			local sep = self:skip_sep(ls)
			if sep >= 0 then
				self:read_long_string(ls, Token, sep)
				return "TK_STRING"
			elseif sep == - 1 then
				return "["
			else
				self:lexerror(ls, "invalid long string delimiter", "TK_STRING")
			end
		elseif c == "=" then
			c = self:nextc(ls)
			if c ~= "=" then
				return "="
			else
				self:nextc(ls)
				return "TK_EQ"
			end
		elseif c == "<" then
			c = self:nextc(ls)
			if c ~= "=" then
				return "<"
			else
				self:nextc(ls)
				return "TK_LE"
			end
		elseif c == ">" then
			c = self:nextc(ls)
			if c ~= "=" then
				return ">"
			else
				self:nextc(ls)
				return "TK_GE"
			end
		elseif c == "~" then
			c = self:nextc(ls)
			if c ~= "=" then
				return "~"
			else
				self:nextc(ls)
				return "TK_NE"
			end
		elseif c == "\"" or c == "'" then
			self:read_string(ls, c, Token)
			return "TK_STRING"
		elseif c == "." then
			c = self:save_and_next(ls)
			if self:check_next(ls, ".") then
				if self:check_next(ls, ".") then
					return "TK_DOTS"
				else
					return "TK_CONCAT"
				end
			elseif not string.find(c, "%d") then
				return "."
			else
				self:read_numeral(ls, Token)
				return "TK_NUMBER"
			end
		elseif c == "EOZ" then
			return "TK_EOS"
		else
			if string.find(c, "%s") then
				self:nextc(ls)
			elseif string.find(c, "%d") then
				self:read_numeral(ls, Token)
				return "TK_NUMBER"
			elseif string.find(c, "[_%a]") then
				repeat
					c = self:save_and_next(ls)
				until c == "EOZ" or not string.find(c, "[_%w]")
				local ts = ls.buff;
				local tok = self.enums[ts]
				if tok then
					return tok
				end;
				Token.seminfo = ts;
				return "TK_NAME"
			else
				self:nextc(ls)
				return c
			end
		end
	end
end;
luaP.OpMode = {
	iABC = 0,
	iABx = 1,
	iAsBx = 2
}
luaP.SIZE_C = 9;
luaP.SIZE_B = 9;
luaP.SIZE_Bx = luaP.SIZE_C + luaP.SIZE_B;
luaP.SIZE_A = 8;
luaP.SIZE_OP = 6;
luaP.POS_OP = 0;
luaP.POS_A = luaP.POS_OP + luaP.SIZE_OP;
luaP.POS_C = luaP.POS_A + luaP.SIZE_A;
luaP.POS_B = luaP.POS_C + luaP.SIZE_C;
luaP.POS_Bx = luaP.POS_C;
luaP.MAXARG_Bx = math.ldexp(1, luaP.SIZE_Bx) - 1;
luaP.MAXARG_sBx = math.floor(luaP.MAXARG_Bx / 2)
luaP.MAXARG_A = math.ldexp(1, luaP.SIZE_A) - 1;
luaP.MAXARG_B = math.ldexp(1, luaP.SIZE_B) - 1;
luaP.MAXARG_C = math.ldexp(1, luaP.SIZE_C) - 1;
function luaP:GET_OPCODE(i)
	return self.ROpCode[i.OP]
end;
function luaP:SET_OPCODE(i, o)
	i.OP = self.OpCode[o]
end;
function luaP:GETARG_A(i)
	return i.A
end;
function luaP:SETARG_A(i, u)
	i.A = u
end;
function luaP:GETARG_B(i)
	return i.B
end;
function luaP:SETARG_B(i, b)
	i.B = b
end;
function luaP:GETARG_C(i)
	return i.C
end;
function luaP:SETARG_C(i, b)
	i.C = b
end;
function luaP:GETARG_Bx(i)
	return i.Bx
end;
function luaP:SETARG_Bx(i, b)
	i.Bx = b
end;
function luaP:GETARG_sBx(i)
	return i.Bx - self.MAXARG_sBx
end;
function luaP:SETARG_sBx(i, b)
	i.Bx = b + self.MAXARG_sBx
end;
function luaP:CREATE_ABC(o, a, b, c)
	return {
		OP = self.OpCode[o],
		A = a,
		B = b,
		C = c
	}
end;
function luaP:CREATE_ABx(o, a, bc)
	return {
		OP = self.OpCode[o],
		A = a,
		Bx = bc
	}
end;
function luaP:CREATE_Inst(c)
	local o = c % 64;
	c = (c - o) / 64;
	local a = c % 256;
	c = (c - a) / 256;
	return self:CREATE_ABx(o, a, c)
end;
function luaP:Instruction(i)
	if i.Bx then
		i.C = i.Bx % 512;
		i.B = (i.Bx - i.C) / 512
	end;
	local I = i.A * 64 + i.OP;
	local c0 = I % 256;
	I = i.C * 64 + (I - c0) / 256;
	local c1 = I % 256;
	I = i.B * 128 + (I - c1) / 256;
	local c2 = I % 256;
	local c3 = (I - c2) / 256;
	return string.char(c0, c1, c2, c3)
end;
function luaP:DecodeInst(x)
	local byte = string.byte;
	local i = {}
	local I = byte(x, 1)
	local op = I % 64;
	i.OP = op;
	I = byte(x, 2) * 4 + (I - op) / 64;
	local a = I % 256;
	i.A = a;
	I = byte(x, 3) * 4 + (I - a) / 256;
	local c = I % 512;
	i.C = c;
	i.B = byte(x, 4) * 2 + (I - c) / 512;
	local opmode = self.OpMode[tonumber(string.sub(self.opmodes[op + 1], 7, 7))]
	if opmode ~= "iABC" then
		i.Bx = i.B * 512 + i.C
	end;
	return i
end;
luaP.BITRK = math.ldexp(1, luaP.SIZE_B - 1)
function luaP:ISK(x)
	return x >= self.BITRK
end;
function luaP:INDEXK(r)
	return r - self.BITRK
end;
luaP.MAXINDEXRK = luaP.BITRK - 1;
function luaP:RKASK(x)
	return x + self.BITRK
end;
luaP.NO_REG = luaP.MAXARG_A;
luaP.opnames = {}
luaP.OpCode = {}
luaP.ROpCode = {}
local i = 0;
for v in string.gmatch([[
	MOVE LOADK LOADBOOL LOADNIL GETUPVAL
	GETGLOBAL GETTABLE SETGLOBAL SETUPVAL SETTABLE
	NEWTABLE SELF ADD SUB MUL
	DIV MOD POW UNM NOT
	LEN CONCAT JMP EQ LT
	LE TEST TESTSET CALL TAILCALL
	RETURN FORLOOP FORPREP TFORLOOP SETLIST
	CLOSE CLOSURE VARARG
	]], "%S+") do
	local n = "OP_" .. v;
	luaP.opnames[i] = v;
	luaP.OpCode[n] = i;
	luaP.ROpCode[i] = n;
	i = i + 1
end;
luaP.NUM_OPCODES = i;
luaP.OpArgMask = {
	OpArgN = 0,
	OpArgU = 1,
	OpArgR = 2,
	OpArgK = 3
}
function luaP:getOpMode(m)
	return self.opmodes[self.OpCode[m]] % 4
end;
function luaP:getBMode(m)
	return math.floor(self.opmodes[self.OpCode[m]] / 16) % 4
end;
function luaP:getCMode(m)
	return math.floor(self.opmodes[self.OpCode[m]] / 4) % 4
end;
function luaP:testAMode(m)
	return math.floor(self.opmodes[self.OpCode[m]] / 64) % 2
end;
function luaP:testTMode(m)
	return math.floor(self.opmodes[self.OpCode[m]] / 128)
end;
luaP.LFIELDS_PER_FLUSH = 50;
local function opmode(t, a, b, c, m)
	local luaP = luaP;
	return t * 128 + a * 64 + luaP.OpArgMask[b] * 16 + luaP.OpArgMask[c] * 4 + luaP.OpMode[m]
end;
luaP.opmodes = {
	opmode(0, 1, "OpArgK", "OpArgN", "iABx"),
	opmode(0, 1, "OpArgU", "OpArgU", "iABC"),
	opmode(0, 1, "OpArgR", "OpArgN", "iABC"),
	opmode(0, 1, "OpArgU", "OpArgN", "iABC"),
	opmode(0, 1, "OpArgK", "OpArgN", "iABx"),
	opmode(0, 1, "OpArgR", "OpArgK", "iABC"),
	opmode(0, 0, "OpArgK", "OpArgN", "iABx"),
	opmode(0, 0, "OpArgU", "OpArgN", "iABC"),
	opmode(0, 0, "OpArgK", "OpArgK", "iABC"),
	opmode(0, 1, "OpArgU", "OpArgU", "iABC"),
	opmode(0, 1, "OpArgR", "OpArgK", "iABC"),
	opmode(0, 1, "OpArgK", "OpArgK", "iABC"),
	opmode(0, 1, "OpArgK", "OpArgK", "iABC"),
	opmode(0, 1, "OpArgK", "OpArgK", "iABC"),
	opmode(0, 1, "OpArgK", "OpArgK", "iABC"),
	opmode(0, 1, "OpArgK", "OpArgK", "iABC"),
	opmode(0, 1, "OpArgK", "OpArgK", "iABC"),
	opmode(0, 1, "OpArgR", "OpArgN", "iABC"),
	opmode(0, 1, "OpArgR", "OpArgN", "iABC"),
	opmode(0, 1, "OpArgR", "OpArgN", "iABC"),
	opmode(0, 1, "OpArgR", "OpArgR", "iABC"),
	opmode(0, 0, "OpArgR", "OpArgN", "iAsBx"),
	opmode(1, 0, "OpArgK", "OpArgK", "iABC"),
	opmode(1, 0, "OpArgK", "OpArgK", "iABC"),
	opmode(1, 0, "OpArgK", "OpArgK", "iABC"),
	opmode(1, 1, "OpArgR", "OpArgU", "iABC"),
	opmode(1, 1, "OpArgR", "OpArgU", "iABC"),
	opmode(0, 1, "OpArgU", "OpArgU", "iABC"),
	opmode(0, 1, "OpArgU", "OpArgU", "iABC"),
	opmode(0, 0, "OpArgU", "OpArgN", "iABC"),
	opmode(0, 1, "OpArgR", "OpArgN", "iAsBx"),
	opmode(0, 1, "OpArgR", "OpArgN", "iAsBx"),
	opmode(1, 0, "OpArgN", "OpArgU", "iABC"),
	opmode(0, 0, "OpArgU", "OpArgU", "iABC"),
	opmode(0, 0, "OpArgN", "OpArgN", "iABC"),
	opmode(0, 1, "OpArgU", "OpArgN", "iABx"),
	opmode(0, 1, "OpArgU", "OpArgN", "iABC")
}
luaP.opmodes[0] = opmode(0, 1, "OpArgR", "OpArgN", "iABC")
luaU.LUA_SIGNATURE = "\27Lua"
luaU.LUA_TNUMBER = 3;
luaU.LUA_TSTRING = 4;
luaU.LUA_TNIL = 0;
luaU.LUA_TBOOLEAN = 1;
luaU.LUA_TNONE = - 1;
luaU.LUAC_VERSION = 81;
luaU.LUAC_FORMAT = 0;
luaU.LUAC_HEADERSIZE = 12;
function luaU:make_setS()
	local buff = {}
	buff.data = ""
	local writer = function(s, buff)
		if not s then
			return 0
		end;
		buff.data = buff.data .. s;
		return 0
	end;
	return writer, buff
end;
function luaU:make_setF(filename)
	local buff = {}
	buff.h = io.open(filename, "wb")
	if not buff.h then
		return nil
	end;
	local writer = function(s, buff)
		if not buff.h then
			return 0
		end;
		if not s then
			if buff.h:close() then
				return 0
			end
		else
			if buff.h:write(s) then
				return 0
			end
		end;
		return 1
	end;
	return writer, buff
end;
function luaU:ttype(o)
	local tt = type(o.value)
	if tt == "number" then
		return self.LUA_TNUMBER
	elseif tt == "string" then
		return self.LUA_TSTRING
	elseif tt == "nil" then
		return self.LUA_TNIL
	elseif tt == "boolean" then
		return self.LUA_TBOOLEAN
	else
		return self.LUA_TNONE
	end
end;
function luaU:from_double(x)
	local function grab_byte(v)
		local c = v % 256;
		return (v - c) / 256, string.char(c)
	end;
	local sign = 0;
	if x < 0 then
		sign = 1;
		x = - x
	end;
	local mantissa, exponent = math.frexp(x)
	if x == 0 then
		mantissa, exponent = 0, 0
	elseif x == 1 / 0 then
		mantissa, exponent = 0, 2047
	else
		mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 53)
		exponent = exponent + 1022
	end;
	local v = ""
	local byte;
	x = math.floor(mantissa)
	for i = 1, 6 do
		x, byte = grab_byte(x)
		v = v .. byte
	end;
	x, byte = grab_byte(exponent * 16 + x)
	v = v .. byte;
	x, byte = grab_byte(sign * 128 + x)
	v = v .. byte;
	return v
end;
function luaU:from_int(x)
	local v = ""
	x = math.floor(x)
	if x < 0 then
		x = 4294967296 + x
	end;
	for i = 1, 4 do
		local c = x % 256;
		v = v .. string.char(c)
		x = math.floor(x / 256)
	end;
	return v
end;
function luaU:DumpBlock(b, D)
	if D.status == 0 then
		D.status = D.write(b, D.data)
	end
end;
function luaU:DumpChar(y, D)
	self:DumpBlock(string.char(y), D)
end;
function luaU:DumpInt(x, D)
	self:DumpBlock(self:from_int(x), D)
end;
function luaU:DumpSizeT(x, D)
	self:DumpBlock(self:from_int(x), D)
	if size_size_t == 8 then
		self:DumpBlock(self:from_int(0), D)
	end
end;
function luaU:DumpNumber(x, D)
	self:DumpBlock(self:from_double(x), D)
end;
function luaU:DumpString(s, D)
	if s == nil then
		self:DumpSizeT(0, D)
	else
		s = s .. "\0"
		self:DumpSizeT(# s, D)
		self:DumpBlock(s, D)
	end
end;
function luaU:DumpCode(f, D)
	local n = f.sizecode;
	self:DumpInt(n, D)
	for i = 0, n - 1 do
		self:DumpBlock(luaP:Instruction(f.code[i]), D)
	end
end;
function luaU:DumpConstants(f, D)
	local n = f.sizek;
	self:DumpInt(n, D)
	for i = 0, n - 1 do
		local o = f.k[i]
		local tt = self:ttype(o)
		self:DumpChar(tt, D)
		if tt == self.LUA_TNIL then
		elseif tt == self.LUA_TBOOLEAN then
			self:DumpChar(o.value and 1 or 0, D)
		elseif tt == self.LUA_TNUMBER then
			self:DumpNumber(o.value, D)
		elseif tt == self.LUA_TSTRING then
			self:DumpString(o.value, D)
		else
		end
	end;
	n = f.sizep;
	self:DumpInt(n, D)
	for i = 0, n - 1 do
		self:DumpFunction(f.p[i], f.source, D)
	end
end;
function luaU:DumpDebug(f, D)
	local n;
	n = D.strip and 0 or f.sizelineinfo;
	self:DumpInt(n, D)
	for i = 0, n - 1 do
		self:DumpInt(f.lineinfo[i], D)
	end;
	n = D.strip and 0 or f.sizelocvars;
	self:DumpInt(n, D)
	for i = 0, n - 1 do
		self:DumpString(f.locvars[i].varname, D)
		self:DumpInt(f.locvars[i].startpc, D)
		self:DumpInt(f.locvars[i].endpc, D)
	end;
	n = D.strip and 0 or f.sizeupvalues;
	self:DumpInt(n, D)
	for i = 0, n - 1 do
		self:DumpString(f.upvalues[i], D)
	end
end;
function luaU:DumpFunction(f, p, D)
	local source = f.source;
	if source == p or D.strip then
		source = nil
	end;
	self:DumpString(source, D)
	self:DumpInt(f.lineDefined, D)
	self:DumpInt(f.lastlinedefined, D)
	self:DumpChar(f.nups, D)
	self:DumpChar(f.numparams, D)
	self:DumpChar(f.is_vararg, D)
	self:DumpChar(f.maxstacksize, D)
	self:DumpCode(f, D)
	self:DumpConstants(f, D)
	self:DumpDebug(f, D)
end;
function luaU:DumpHeader(D)
	local h = self:header()
	assert(# h == self.LUAC_HEADERSIZE)
	self:DumpBlock(h, D)
end;
function luaU:header()
	local x = 1;
	return self.LUA_SIGNATURE .. string.char(self.LUAC_VERSION, self.LUAC_FORMAT, x, 4, size_size_t, 4, 8, 0)
end;
function luaU:dump(L, f, w, data, strip)
	local D = {}
	D.L = L;
	D.write = w;
	D.data = data;
	D.strip = strip;
	D.status = 0;
	self:DumpHeader(D)
	self:DumpFunction(f, nil, D)
	D.write(nil, D.data)
	return D.status
end;
luaK.MAXSTACK = 250;
function luaK:ttisnumber(o)
	if o then
		return type(o.value) == "number"
	else
		return false
	end
end;
function luaK:nvalue(o)
	return o.value
end;
function luaK:setnilvalue(o)
	o.value = nil
end;
function luaK:setsvalue(o, x)
	o.value = x
end;
luaK.setnvalue = luaK.setsvalue;
luaK.sethvalue = luaK.setsvalue;
luaK.setbvalue = luaK.setsvalue;
function luaK:numadd(a, b)
	return a + b
end;
function luaK:numsub(a, b)
	return a - b
end;
function luaK:nummul(a, b)
	return a * b
end;
function luaK:numdiv(a, b)
	return a / b
end;
function luaK:nummod(a, b)
	return a % b
end;
function luaK:numpow(a, b)
	return a ^ b
end;
function luaK:numunm(a)
	return - a
end;
function luaK:numisnan(a)
	return not a == a
end;
luaK.NO_JUMP = - 1;
luaK.BinOpr = {
	OPR_ADD = 0,
	OPR_SUB = 1,
	OPR_MUL = 2,
	OPR_DIV = 3,
	OPR_MOD = 4,
	OPR_POW = 5,
	OPR_CONCAT = 6,
	OPR_NE = 7,
	OPR_EQ = 8,
	OPR_LT = 9,
	OPR_LE = 10,
	OPR_GT = 11,
	OPR_GE = 12,
	OPR_AND = 13,
	OPR_OR = 14,
	OPR_NOBINOPR = 15
}
luaK.UnOpr = {
	OPR_MINUS = 0,
	OPR_NOT = 1,
	OPR_LEN = 2,
	OPR_NOUNOPR = 3
}
function luaK:getcode(fs, e)
	return fs.f.code[e.info]
end;
function luaK:codeAsBx(fs, o, A, sBx)
	return self:codeABx(fs, o, A, sBx + luaP.MAXARG_sBx)
end;
function luaK:setmultret(fs, e)
	self:setreturns(fs, e, luaY.LUA_MULTRET)
end;
function luaK:hasjumps(e)
	return e.t ~= e.f
end;
function luaK:isnumeral(e)
	return e.k == "VKNUM" and e.t == self.NO_JUMP and e.f == self.NO_JUMP
end;
function luaK:_nil(fs, from, n)
	if fs.pc > fs.lasttarget then
		if fs.pc == 0 then
			if from >= fs.nactvar then
				return
			end
		else
			local previous = fs.f.code[fs.pc - 1]
			if luaP:GET_OPCODE(previous) == "OP_LOADNIL" then
				local pfrom = luaP:GETARG_A(previous)
				local pto = luaP:GETARG_B(previous)
				if pfrom <= from and from <= pto + 1 then
					if from + n - 1 > pto then
						luaP:SETARG_B(previous, from + n - 1)
					end;
					return
				end
			end
		end
	end;
	self:codeABC(fs, "OP_LOADNIL", from, from + n - 1, 0)
end;
function luaK:jump(fs)
	local jpc = fs.jpc;
	fs.jpc = self.NO_JUMP;
	local j = self:codeAsBx(fs, "OP_JMP", 0, self.NO_JUMP)
	j = self:concat(fs, j, jpc)
	return j
end;
function luaK:ret(fs, first, nret)
	self:codeABC(fs, "OP_RETURN", first, nret + 1, 0)
end;
function luaK:condjump(fs, op, A, B, C)
	self:codeABC(fs, op, A, B, C)
	return self:jump(fs)
end;
function luaK:fixjump(fs, pc, dest)
	local jmp = fs.f.code[pc]
	local offset = dest - (pc + 1)
	lua_assert(dest ~= self.NO_JUMP)
	if math.abs(offset) > luaP.MAXARG_sBx then
		luaX:syntaxerror(fs.ls, "control structure too long")
	end;
	luaP:SETARG_sBx(jmp, offset)
end;
function luaK:getlabel(fs)
	fs.lasttarget = fs.pc;
	return fs.pc
end;
function luaK:getjump(fs, pc)
	local offset = luaP:GETARG_sBx(fs.f.code[pc])
	if offset == self.NO_JUMP then
		return self.NO_JUMP
	else
		return (pc + 1) + offset
	end
end;
function luaK:getjumpcontrol(fs, pc)
	local pi = fs.f.code[pc]
	local ppi = fs.f.code[pc - 1]
	if pc >= 1 and luaP:testTMode(luaP:GET_OPCODE(ppi)) ~= 0 then
		return ppi
	else
		return pi
	end
end;
function luaK:need_value(fs, list)
	while list ~= self.NO_JUMP do
		local i = self:getjumpcontrol(fs, list)
		if luaP:GET_OPCODE(i) ~= "OP_TESTSET" then
			return true
		end;
		list = self:getjump(fs, list)
	end;
	return false
end;
function luaK:patchtestreg(fs, node, reg)
	local i = self:getjumpcontrol(fs, node)
	if luaP:GET_OPCODE(i) ~= "OP_TESTSET" then
		return false
	end;
	if reg ~= luaP.NO_REG and reg ~= luaP:GETARG_B(i) then
		luaP:SETARG_A(i, reg)
	else
		luaP:SET_OPCODE(i, "OP_TEST")
		local b = luaP:GETARG_B(i)
		luaP:SETARG_A(i, b)
		luaP:SETARG_B(i, 0)
	end;
	return true
end;
function luaK:removevalues(fs, list)
	while list ~= self.NO_JUMP do
		self:patchtestreg(fs, list, luaP.NO_REG)
		list = self:getjump(fs, list)
	end
end;
function luaK:patchlistaux(fs, list, vtarget, reg, dtarget)
	while list ~= self.NO_JUMP do
		local _next = self:getjump(fs, list)
		if self:patchtestreg(fs, list, reg) then
			self:fixjump(fs, list, vtarget)
		else
			self:fixjump(fs, list, dtarget)
		end;
		list = _next
	end
end;
function luaK:dischargejpc(fs)
	self:patchlistaux(fs, fs.jpc, fs.pc, luaP.NO_REG, fs.pc)
	fs.jpc = self.NO_JUMP
end;
function luaK:patchlist(fs, list, target)
	if target == fs.pc then
		self:patchtohere(fs, list)
	else
		lua_assert(target < fs.pc)
		self:patchlistaux(fs, list, target, luaP.NO_REG, target)
	end
end;
function luaK:patchtohere(fs, list)
	self:getlabel(fs)
	fs.jpc = self:concat(fs, fs.jpc, list)
end;
function luaK:concat(fs, l1, l2)
	if l2 == self.NO_JUMP then
		return l1
	elseif l1 == self.NO_JUMP then
		return l2
	else
		local list = l1;
		local _next = self:getjump(fs, list)
		while _next ~= self.NO_JUMP do
			list = _next;
			_next = self:getjump(fs, list)
		end;
		self:fixjump(fs, list, l2)
	end;
	return l1
end;
function luaK:checkstack(fs, n)
	local newstack = fs.freereg + n;
	if newstack > fs.f.maxstacksize then
		if newstack >= self.MAXSTACK then
			luaX:syntaxerror(fs.ls, "function or expression too complex")
		end;
		fs.f.maxstacksize = newstack
	end
end;
function luaK:reserveregs(fs, n)
	self:checkstack(fs, n)
	fs.freereg = fs.freereg + n
end;
function luaK:freereg(fs, reg)
	if not luaP:ISK(reg) and reg >= fs.nactvar then
		fs.freereg = fs.freereg - 1;
		lua_assert(reg == fs.freereg)
	end
end;
function luaK:freeexp(fs, e)
	if e.k == "VNONRELOC" then
		self:freereg(fs, e.info)
	end
end;
function luaK:addk(fs, k, v)
	local L = fs.L;
	local idx = fs.h[k.value]
	local f = fs.f;
	if self:ttisnumber(idx) then
		return self:nvalue(idx)
	else
		idx = {}
		self:setnvalue(idx, fs.nk)
		fs.h[k.value] = idx;
		luaY:growvector(L, f.k, fs.nk, f.sizek, nil, luaP.MAXARG_Bx, "constant table overflow")
		f.k[fs.nk] = v;
		local nk = fs.nk;
		fs.nk = fs.nk + 1;
		return nk
	end
end;
function luaK:stringK(fs, s)
	local o = {}
	self:setsvalue(o, s)
	return self:addk(fs, o, o)
end;
function luaK:numberK(fs, r)
	local o = {}
	self:setnvalue(o, r)
	return self:addk(fs, o, o)
end;
function luaK:boolK(fs, b)
	local o = {}
	self:setbvalue(o, b)
	return self:addk(fs, o, o)
end;
function luaK:nilK(fs)
	local k, v = {}, {}
	self:setnilvalue(v)
	self:sethvalue(k, fs.h)
	return self:addk(fs, k, v)
end;
function luaK:setreturns(fs, e, nresults)
	if e.k == "VCALL" then
		luaP:SETARG_C(self:getcode(fs, e), nresults + 1)
	elseif e.k == "VVARARG" then
		luaP:SETARG_B(self:getcode(fs, e), nresults + 1)
		luaP:SETARG_A(self:getcode(fs, e), fs.freereg)
		luaK:reserveregs(fs, 1)
	end
end;
function luaK:setoneret(fs, e)
	if e.k == "VCALL" then
		e.k = "VNONRELOC"
		e.info = luaP:GETARG_A(self:getcode(fs, e))
	elseif e.k == "VVARARG" then
		luaP:SETARG_B(self:getcode(fs, e), 2)
		e.k = "VRELOCABLE"
	end
end;
function luaK:dischargevars(fs, e)
	local k = e.k;
	if k == "VLOCAL" then
		e.k = "VNONRELOC"
	elseif k == "VUPVAL" then
		e.info = self:codeABC(fs, "OP_GETUPVAL", 0, e.info, 0)
		e.k = "VRELOCABLE"
	elseif k == "VGLOBAL" then
		e.info = self:codeABx(fs, "OP_GETGLOBAL", 0, e.info)
		e.k = "VRELOCABLE"
	elseif k == "VINDEXED" then
		self:freereg(fs, e.aux)
		self:freereg(fs, e.info)
		e.info = self:codeABC(fs, "OP_GETTABLE", 0, e.info, e.aux)
		e.k = "VRELOCABLE"
	elseif k == "VVARARG" or k == "VCALL" then
		self:setoneret(fs, e)
	else
	end
end;
function luaK:code_label(fs, A, b, jump)
	self:getlabel(fs)
	return self:codeABC(fs, "OP_LOADBOOL", A, b, jump)
end;
function luaK:discharge2reg(fs, e, reg)
	self:dischargevars(fs, e)
	local k = e.k;
	if k == "VNIL" then
		self:_nil(fs, reg, 1)
	elseif k == "VFALSE" or k == "VTRUE" then
		self:codeABC(fs, "OP_LOADBOOL", reg, (e.k == "VTRUE") and 1 or 0, 0)
	elseif k == "VK" then
		self:codeABx(fs, "OP_LOADK", reg, e.info)
	elseif k == "VKNUM" then
		self:codeABx(fs, "OP_LOADK", reg, self:numberK(fs, e.nval))
	elseif k == "VRELOCABLE" then
		local pc = self:getcode(fs, e)
		luaP:SETARG_A(pc, reg)
	elseif k == "VNONRELOC" then
		if reg ~= e.info then
			self:codeABC(fs, "OP_MOVE", reg, e.info, 0)
		end
	else
		lua_assert(e.k == "VVOID" or e.k == "VJMP")
		return
	end;
	e.info = reg;
	e.k = "VNONRELOC"
end;
function luaK:discharge2anyreg(fs, e)
	if e.k ~= "VNONRELOC" then
		self:reserveregs(fs, 1)
		self:discharge2reg(fs, e, fs.freereg - 1)
	end
end;
function luaK:exp2reg(fs, e, reg)
	self:discharge2reg(fs, e, reg)
	if e.k == "VJMP" then
		e.t = self:concat(fs, e.t, e.info)
	end;
	if self:hasjumps(e) then
		local final;
		local p_f = self.NO_JUMP;
		local p_t = self.NO_JUMP;
		if self:need_value(fs, e.t) or self:need_value(fs, e.f) then
			local fj = (e.k == "VJMP") and self.NO_JUMP or self:jump(fs)
			p_f = self:code_label(fs, reg, 0, 1)
			p_t = self:code_label(fs, reg, 1, 0)
			self:patchtohere(fs, fj)
		end;
		final = self:getlabel(fs)
		self:patchlistaux(fs, e.f, final, reg, p_f)
		self:patchlistaux(fs, e.t, final, reg, p_t)
	end;
	e.f, e.t = self.NO_JUMP, self.NO_JUMP;
	e.info = reg;
	e.k = "VNONRELOC"
end;
function luaK:exp2nextreg(fs, e)
	self:dischargevars(fs, e)
	self:freeexp(fs, e)
	self:reserveregs(fs, 1)
	self:exp2reg(fs, e, fs.freereg - 1)
end;
function luaK:exp2anyreg(fs, e)
	self:dischargevars(fs, e)
	if e.k == "VNONRELOC" then
		if not self:hasjumps(e) then
			return e.info
		end;
		if e.info >= fs.nactvar then
			self:exp2reg(fs, e, e.info)
			return e.info
		end
	end;
	self:exp2nextreg(fs, e)
	return e.info
end;
function luaK:exp2val(fs, e)
	if self:hasjumps(e) then
		self:exp2anyreg(fs, e)
	else
		self:dischargevars(fs, e)
	end
end;
function luaK:exp2RK(fs, e)
	self:exp2val(fs, e)
	local k = e.k;
	if k == "VKNUM" or k == "VTRUE" or k == "VFALSE" or k == "VNIL" then
		if fs.nk <= luaP.MAXINDEXRK then
			if e.k == "VNIL" then
				e.info = self:nilK(fs)
			else
				e.info = (e.k == "VKNUM") and self:numberK(fs, e.nval) or self:boolK(fs, e.k == "VTRUE")
			end;
			e.k = "VK"
			return luaP:RKASK(e.info)
		end
	elseif k == "VK" then
		if e.info <= luaP.MAXINDEXRK then
			return luaP:RKASK(e.info)
		end
	else
	end;
	return self:exp2anyreg(fs, e)
end;
function luaK:storevar(fs, var, ex)
	local k = var.k;
	if k == "VLOCAL" then
		self:freeexp(fs, ex)
		self:exp2reg(fs, ex, var.info)
		return
	elseif k == "VUPVAL" then
		local e = self:exp2anyreg(fs, ex)
		self:codeABC(fs, "OP_SETUPVAL", e, var.info, 0)
	elseif k == "VGLOBAL" then
		local e = self:exp2anyreg(fs, ex)
		self:codeABx(fs, "OP_SETGLOBAL", e, var.info)
	elseif k == "VINDEXED" then
		local e = self:exp2RK(fs, ex)
		self:codeABC(fs, "OP_SETTABLE", var.info, var.aux, e)
	else
		lua_assert(0)
	end;
	self:freeexp(fs, ex)
end;
function luaK:_self(fs, e, key)
	self:exp2anyreg(fs, e)
	self:freeexp(fs, e)
	local func = fs.freereg;
	self:reserveregs(fs, 2)
	self:codeABC(fs, "OP_SELF", func, e.info, self:exp2RK(fs, key))
	self:freeexp(fs, key)
	e.info = func;
	e.k = "VNONRELOC"
end;
function luaK:invertjump(fs, e)
	local pc = self:getjumpcontrol(fs, e.info)
	lua_assert(luaP:testTMode(luaP:GET_OPCODE(pc)) ~= 0 and luaP:GET_OPCODE(pc) ~= "OP_TESTSET" and luaP:GET_OPCODE(pc) ~= "OP_TEST")
	luaP:SETARG_A(pc, (luaP:GETARG_A(pc) == 0) and 1 or 0)
end;
function luaK:jumponcond(fs, e, cond)
	if e.k == "VRELOCABLE" then
		local ie = self:getcode(fs, e)
		if luaP:GET_OPCODE(ie) == "OP_NOT" then
			fs.pc = fs.pc - 1;
			return self:condjump(fs, "OP_TEST", luaP:GETARG_B(ie), 0, cond and 0 or 1)
		end
	end;
	self:discharge2anyreg(fs, e)
	self:freeexp(fs, e)
	return self:condjump(fs, "OP_TESTSET", luaP.NO_REG, e.info, cond and 1 or 0)
end;
function luaK:goiftrue(fs, e)
	local pc;
	self:dischargevars(fs, e)
	local k = e.k;
	if k == "VK" or k == "VKNUM" or k == "VTRUE" then
		pc = self.NO_JUMP
	elseif k == "VFALSE" then
		pc = self:jump(fs)
	elseif k == "VJMP" then
		self:invertjump(fs, e)
		pc = e.info
	else
		pc = self:jumponcond(fs, e, false)
	end;
	e.f = self:concat(fs, e.f, pc)
	self:patchtohere(fs, e.t)
	e.t = self.NO_JUMP
end;
function luaK:goiffalse(fs, e)
	local pc;
	self:dischargevars(fs, e)
	local k = e.k;
	if k == "VNIL" or k == "VFALSE" then
		pc = self.NO_JUMP
	elseif k == "VTRUE" then
		pc = self:jump(fs)
	elseif k == "VJMP" then
		pc = e.info
	else
		pc = self:jumponcond(fs, e, true)
	end;
	e.t = self:concat(fs, e.t, pc)
	self:patchtohere(fs, e.f)
	e.f = self.NO_JUMP
end;
function luaK:codenot(fs, e)
	self:dischargevars(fs, e)
	local k = e.k;
	if k == "VNIL" or k == "VFALSE" then
		e.k = "VTRUE"
	elseif k == "VK" or k == "VKNUM" or k == "VTRUE" then
		e.k = "VFALSE"
	elseif k == "VJMP" then
		self:invertjump(fs, e)
	elseif k == "VRELOCABLE" or k == "VNONRELOC" then
		self:discharge2anyreg(fs, e)
		self:freeexp(fs, e)
		e.info = self:codeABC(fs, "OP_NOT", 0, e.info, 0)
		e.k = "VRELOCABLE"
	else
		lua_assert(0)
	end;
	e.f, e.t = e.t, e.f;
	self:removevalues(fs, e.f)
	self:removevalues(fs, e.t)
end;
function luaK:indexed(fs, t, k)
	t.aux = self:exp2RK(fs, k)
	t.k = "VINDEXED"
end;
function luaK:constfolding(op, e1, e2)
	local r;
	if not self:isnumeral(e1) or not self:isnumeral(e2) then
		return false
	end;
	local v1 = e1.nval;
	local v2 = e2.nval;
	if op == "OP_ADD" then
		r = self:numadd(v1, v2)
	elseif op == "OP_SUB" then
		r = self:numsub(v1, v2)
	elseif op == "OP_MUL" then
		r = self:nummul(v1, v2)
	elseif op == "OP_DIV" then
		if v2 == 0 then
			return false
		end;
		r = self:numdiv(v1, v2)
	elseif op == "OP_MOD" then
		if v2 == 0 then
			return false
		end;
		r = self:nummod(v1, v2)
	elseif op == "OP_POW" then
		r = self:numpow(v1, v2)
	elseif op == "OP_UNM" then
		r = self:numunm(v1)
	elseif op == "OP_LEN" then
		return false
	else
		lua_assert(0)
		r = 0
	end;
	if self:numisnan(r) then
		return false
	end;
	e1.nval = r;
	return true
end;
function luaK:codearith(fs, op, e1, e2)
	if self:constfolding(op, e1, e2) then
		return
	else
		local o2 = (op ~= "OP_UNM" and op ~= "OP_LEN") and self:exp2RK(fs, e2) or 0;
		local o1 = self:exp2RK(fs, e1)
		if o1 > o2 then
			self:freeexp(fs, e1)
			self:freeexp(fs, e2)
		else
			self:freeexp(fs, e2)
			self:freeexp(fs, e1)
		end;
		e1.info = self:codeABC(fs, op, 0, o1, o2)
		e1.k = "VRELOCABLE"
	end
end;
function luaK:codecomp(fs, op, cond, e1, e2)
	local o1 = self:exp2RK(fs, e1)
	local o2 = self:exp2RK(fs, e2)
	self:freeexp(fs, e2)
	self:freeexp(fs, e1)
	if cond == 0 and op ~= "OP_EQ" then
		o1, o2 = o2, o1;
		cond = 1
	end;
	e1.info = self:condjump(fs, op, cond, o1, o2)
	e1.k = "VJMP"
end;
function luaK:prefix(fs, op, e)
	local e2 = {}
	e2.t, e2.f = self.NO_JUMP, self.NO_JUMP;
	e2.k = "VKNUM"
	e2.nval = 0;
	if op == "OPR_MINUS" then
		if not self:isnumeral(e) then
			self:exp2anyreg(fs, e)
		end;
		self:codearith(fs, "OP_UNM", e, e2)
	elseif op == "OPR_NOT" then
		self:codenot(fs, e)
	elseif op == "OPR_LEN" then
		self:exp2anyreg(fs, e)
		self:codearith(fs, "OP_LEN", e, e2)
	else
		lua_assert(0)
	end
end;
function luaK:infix(fs, op, v)
	if op == "OPR_AND" then
		self:goiftrue(fs, v)
	elseif op == "OPR_OR" then
		self:goiffalse(fs, v)
	elseif op == "OPR_CONCAT" then
		self:exp2nextreg(fs, v)
	elseif op == "OPR_ADD" or op == "OPR_SUB" or op == "OPR_MUL" or op == "OPR_DIV" or op == "OPR_MOD" or op == "OPR_POW" then
		if not self:isnumeral(v) then
			self:exp2RK(fs, v)
		end
	else
		self:exp2RK(fs, v)
	end
end;
luaK.arith_op = {
	OPR_ADD = "OP_ADD",
	OPR_SUB = "OP_SUB",
	OPR_MUL = "OP_MUL",
	OPR_DIV = "OP_DIV",
	OPR_MOD = "OP_MOD",
	OPR_POW = "OP_POW"
}
luaK.comp_op = {
	OPR_EQ = "OP_EQ",
	OPR_NE = "OP_EQ",
	OPR_LT = "OP_LT",
	OPR_LE = "OP_LE",
	OPR_GT = "OP_LT",
	OPR_GE = "OP_LE"
}
luaK.comp_cond = {
	OPR_EQ = 1,
	OPR_NE = 0,
	OPR_LT = 1,
	OPR_LE = 1,
	OPR_GT = 0,
	OPR_GE = 0
}
function luaK:posfix(fs, op, e1, e2)
	local function copyexp(e1, e2)
		e1.k = e2.k;
		e1.info = e2.info;
		e1.aux = e2.aux;
		e1.nval = e2.nval;
		e1.t = e2.t;
		e1.f = e2.f
	end;
	if op == "OPR_AND" then
		lua_assert(e1.t == self.NO_JUMP)
		self:dischargevars(fs, e2)
		e2.f = self:concat(fs, e2.f, e1.f)
		copyexp(e1, e2)
	elseif op == "OPR_OR" then
		lua_assert(e1.f == self.NO_JUMP)
		self:dischargevars(fs, e2)
		e2.t = self:concat(fs, e2.t, e1.t)
		copyexp(e1, e2)
	elseif op == "OPR_CONCAT" then
		self:exp2val(fs, e2)
		if e2.k == "VRELOCABLE" and luaP:GET_OPCODE(self:getcode(fs, e2)) == "OP_CONCAT" then
			lua_assert(e1.info == luaP:GETARG_B(self:getcode(fs, e2)) - 1)
			self:freeexp(fs, e1)
			luaP:SETARG_B(self:getcode(fs, e2), e1.info)
			e1.k = "VRELOCABLE"
			e1.info = e2.info
		else
			self:exp2nextreg(fs, e2)
			self:codearith(fs, "OP_CONCAT", e1, e2)
		end
	else
		local arith = self.arith_op[op]
		if arith then
			self:codearith(fs, arith, e1, e2)
		else
			local comp = self.comp_op[op]
			if comp then
				self:codecomp(fs, comp, self.comp_cond[op], e1, e2)
			else
				lua_assert(0)
			end
		end
	end
end;
function luaK:fixline(fs, line)
	fs.f.lineinfo[fs.pc - 1] = line
end;
function luaK:code(fs, i, line)
	local f = fs.f;
	self:dischargejpc(fs)
	luaY:growvector(fs.L, f.code, fs.pc, f.sizecode, nil, luaY.MAX_INT, "code size overflow")
	f.code[fs.pc] = i;
	luaY:growvector(fs.L, f.lineinfo, fs.pc, f.sizelineinfo, nil, luaY.MAX_INT, "code size overflow")
	f.lineinfo[fs.pc] = line;
	local pc = fs.pc;
	fs.pc = fs.pc + 1;
	return pc
end;
function luaK:codeABC(fs, o, a, b, c)
	lua_assert(luaP:getOpMode(o) == luaP.OpMode.iABC)
	lua_assert(luaP:getBMode(o) ~= luaP.OpArgMask.OpArgN or b == 0)
	lua_assert(luaP:getCMode(o) ~= luaP.OpArgMask.OpArgN or c == 0)
	return self:code(fs, luaP:CREATE_ABC(o, a, b, c), fs.ls.lastline)
end;
function luaK:codeABx(fs, o, a, bc)
	lua_assert(luaP:getOpMode(o) == luaP.OpMode.iABx or luaP:getOpMode(o) == luaP.OpMode.iAsBx)
	lua_assert(luaP:getCMode(o) == luaP.OpArgMask.OpArgN)
	return self:code(fs, luaP:CREATE_ABx(o, a, bc), fs.ls.lastline)
end;
function luaK:setlist(fs, base, nelems, tostore)
	local c = math.floor((nelems - 1) / luaP.LFIELDS_PER_FLUSH) + 1;
	local b = (tostore == luaY.LUA_MULTRET) and 0 or tostore;
	lua_assert(tostore ~= 0)
	if c <= luaP.MAXARG_C then
		self:codeABC(fs, "OP_SETLIST", base, b, c)
	else
		self:codeABC(fs, "OP_SETLIST", base, b, 0)
		self:code(fs, luaP:CREATE_Inst(c), fs.ls.lastline)
	end;
	fs.freereg = base + 1
end;
luaY.LUA_QS = luaX.LUA_QS or "'%s'"
luaY.SHRT_MAX = 32767;
luaY.LUAI_MAXVARS = 200;
luaY.LUAI_MAXUPVALUES = 60;
luaY.MAX_INT = luaX.MAX_INT or 2147483645;
luaY.LUAI_MAXCCALLS = 200;
luaY.VARARG_HASARG = 1;
luaY.HASARG_MASK = 2;
luaY.VARARG_ISVARARG = 2;
luaY.VARARG_NEEDSARG = 4;
luaY.LUA_MULTRET = - 1;
function luaY:LUA_QL(x)
	return "'" .. x .. "'"
end;
function luaY:growvector(L, v, nelems, size, t, limit, e)
	if nelems >= limit then
		error(e)
	end
end;
function luaY:newproto(L)
	local f = {}
	f.k = {}
	f.sizek = 0;
	f.p = {}
	f.sizep = 0;
	f.code = {}
	f.sizecode = 0;
	f.sizelineinfo = 0;
	f.sizeupvalues = 0;
	f.nups = 0;
	f.upvalues = {}
	f.numparams = 0;
	f.is_vararg = 0;
	f.maxstacksize = 0;
	f.lineinfo = {}
	f.sizelocvars = 0;
	f.locvars = {}
	f.lineDefined = 0;
	f.lastlinedefined = 0;
	f.source = nil;
	return f
end;
function luaY:int2fb(x)
	local e = 0;
	while x >= 16 do
		x = math.floor((x + 1) / 2)
		e = e + 1
	end;
	if x < 8 then
		return x
	else
		return ((e + 1) * 8) + (x - 8)
	end
end;
function luaY:hasmultret(k)
	return k == "VCALL" or k == "VVARARG"
end;
function luaY:getlocvar(fs, i)
	return fs.f.locvars[fs.actvar[i]]
end;
function luaY:checklimit(fs, v, l, m)
	if v > l then
		self:errorlimit(fs, l, m)
	end
end;
function luaY:anchor_token(ls)
	if ls.t.token == "TK_NAME" or ls.t.token == "TK_STRING" then
	end
end;
function luaY:error_expected(ls, token)
	luaX:syntaxerror(ls, string.format(self.LUA_QS .. " expected", luaX:token2str(ls, token)))
end;
function luaY:errorlimit(fs, limit, what)
	local msg = (fs.f.linedefined == 0) and string.format("main function has more than %d %s", limit, what) or string.format("function at line %d has more than %d %s", fs.f.linedefined, limit, what)
	luaX:lexerror(fs.ls, msg, 0)
end;
function luaY:testnext(ls, c)
	if ls.t.token == c then
		luaX:next(ls)
		return true
	else
		return false
	end
end;
function luaY:check(ls, c)
	if ls.t.token ~= c then
		self:error_expected(ls, c)
	end
end;
function luaY:checknext(ls, c)
	self:check(ls, c)
	luaX:next(ls)
end;
function luaY:check_condition(ls, c, msg)
	if not c then
		luaX:syntaxerror(ls, msg)
	end
end;
function luaY:check_match(ls, what, who, where)
	if not self:testnext(ls, what) then
		if where == ls.linenumber then
			self:error_expected(ls, what)
		else
			luaX:syntaxerror(ls, string.format(self.LUA_QS .. " expected (to close " .. self.LUA_QS .. " at line %d)", luaX:token2str(ls, what), luaX:token2str(ls, who), where))
		end
	end
end;
function luaY:str_checkname(ls)
	self:check(ls, "TK_NAME")
	local ts = ls.t.seminfo;
	luaX:next(ls)
	return ts
end;
function luaY:init_exp(e, k, i)
	e.f, e.t = luaK.NO_JUMP, luaK.NO_JUMP;
	e.k = k;
	e.info = i
end;
function luaY:codestring(ls, e, s)
	self:init_exp(e, "VK", luaK:stringK(ls.fs, s))
end;
function luaY:checkname(ls, e)
	self:codestring(ls, e, self:str_checkname(ls))
end;
function luaY:registerlocalvar(ls, varname)
	local fs = ls.fs;
	local f = fs.f;
	self:growvector(ls.L, f.locvars, fs.nlocvars, f.sizelocvars, nil, self.SHRT_MAX, "too many local variables")
	f.locvars[fs.nlocvars] = {}
	f.locvars[fs.nlocvars].varname = varname;
	local nlocvars = fs.nlocvars;
	fs.nlocvars = fs.nlocvars + 1;
	return nlocvars
end;
function luaY:new_localvarliteral(ls, v, n)
	self:new_localvar(ls, v, n)
end;
function luaY:new_localvar(ls, name, n)
	local fs = ls.fs;
	self:checklimit(fs, fs.nactvar + n + 1, self.LUAI_MAXVARS, "local variables")
	fs.actvar[fs.nactvar + n] = self:registerlocalvar(ls, name)
end;
function luaY:adjustlocalvars(ls, nvars)
	local fs = ls.fs;
	fs.nactvar = fs.nactvar + nvars;
	for i = nvars, 1, - 1 do
		self:getlocvar(fs, fs.nactvar - i).startpc = fs.pc
	end
end;
function luaY:removevars(ls, tolevel)
	local fs = ls.fs;
	while fs.nactvar > tolevel do
		fs.nactvar = fs.nactvar - 1;
		self:getlocvar(fs, fs.nactvar).endpc = fs.pc
	end
end;
function luaY:indexupvalue(fs, name, v)
	local f = fs.f;
	for i = 0, f.nups - 1 do
		if fs.upvalues[i].k == v.k and fs.upvalues[i].info == v.info then
			lua_assert(f.upvalues[i] == name)
			return i
		end
	end;
	self:checklimit(fs, f.nups + 1, self.LUAI_MAXUPVALUES, "upvalues")
	self:growvector(fs.L, f.upvalues, f.nups, f.sizeupvalues, nil, self.MAX_INT, "")
	f.upvalues[f.nups] = name;
	lua_assert(v.k == "VLOCAL" or v.k == "VUPVAL")
	fs.upvalues[f.nups] = {
		k = v.k,
		info = v.info
	}
	local nups = f.nups;
	f.nups = f.nups + 1;
	return nups
end;
function luaY:searchvar(fs, n)
	for i = fs.nactvar - 1, 0, - 1 do
		if n == self:getlocvar(fs, i).varname then
			return i
		end
	end;
	return - 1
end;
function luaY:markupval(fs, level)
	local bl = fs.bl;
	while bl and bl.nactvar > level do
		bl = bl.previous
	end;
	if bl then
		bl.upval = true
	end
end;
function luaY:singlevaraux(fs, n, var, base)
	if fs == nil then
		self:init_exp(var, "VGLOBAL", luaP.NO_REG)
		return "VGLOBAL"
	else
		local v = self:searchvar(fs, n)
		if v >= 0 then
			self:init_exp(var, "VLOCAL", v)
			if base == 0 then
				self:markupval(fs, v)
			end;
			return "VLOCAL"
		else
			if self:singlevaraux(fs.prev, n, var, 0) == "VGLOBAL" then
				return "VGLOBAL"
			end;
			var.info = self:indexupvalue(fs, n, var)
			var.k = "VUPVAL"
			return "VUPVAL"
		end
	end
end;
function luaY:singlevar(ls, var)
	local varname = self:str_checkname(ls)
	local fs = ls.fs;
	if self:singlevaraux(fs, varname, var, 1) == "VGLOBAL" then
		var.info = luaK:stringK(fs, varname)
	end
end;
function luaY:adjust_assign(ls, nvars, nexps, e)
	local fs = ls.fs;
	local extra = nvars - nexps;
	if self:hasmultret(e.k) then
		extra = extra + 1;
		if extra <= 0 then
			extra = 0
		end;
		luaK:setreturns(fs, e, extra)
		if extra > 1 then
			luaK:reserveregs(fs, extra - 1)
		end
	else
		if e.k ~= "VVOID" then
			luaK:exp2nextreg(fs, e)
		end;
		if extra > 0 then
			local reg = fs.freereg;
			luaK:reserveregs(fs, extra)
			luaK:_nil(fs, reg, extra)
		end
	end
end;
function luaY:enterlevel(ls)
	ls.L.nCcalls = ls.L.nCcalls + 1;
	if ls.L.nCcalls > self.LUAI_MAXCCALLS then
		luaX:lexerror(ls, "chunk has too many syntax levels", 0)
	end
end;
function luaY:leavelevel(ls)
	ls.L.nCcalls = ls.L.nCcalls - 1
end;
function luaY:enterblock(fs, bl, isbreakable)
	bl.breaklist = luaK.NO_JUMP;
	bl.isbreakable = isbreakable;
	bl.nactvar = fs.nactvar;
	bl.upval = false;
	bl.previous = fs.bl;
	fs.bl = bl;
	lua_assert(fs.freereg == fs.nactvar)
end;
function luaY:leaveblock(fs)
	local bl = fs.bl;
	fs.bl = bl.previous;
	self:removevars(fs.ls, bl.nactvar)
	if bl.upval then
		luaK:codeABC(fs, "OP_CLOSE", bl.nactvar, 0, 0)
	end;
	lua_assert(not bl.isbreakable or not bl.upval)
	lua_assert(bl.nactvar == fs.nactvar)
	fs.freereg = fs.nactvar;
	luaK:patchtohere(fs, bl.breaklist)
end;
function luaY:pushclosure(ls, func, v)
	local fs = ls.fs;
	local f = fs.f;
	self:growvector(ls.L, f.p, fs.np, f.sizep, nil, luaP.MAXARG_Bx, "constant table overflow")
	f.p[fs.np] = func.f;
	fs.np = fs.np + 1;
	self:init_exp(v, "VRELOCABLE", luaK:codeABx(fs, "OP_CLOSURE", 0, fs.np - 1))
	for i = 0, func.f.nups - 1 do
		local o = (func.upvalues[i].k == "VLOCAL") and "OP_MOVE" or "OP_GETUPVAL"
		luaK:codeABC(fs, o, 0, func.upvalues[i].info, 0)
	end
end;
function luaY:open_func(ls, fs)
	local L = ls.L;
	local f = self:newproto(ls.L)
	fs.f = f;
	fs.prev = ls.fs;
	fs.ls = ls;
	fs.L = L;
	ls.fs = fs;
	fs.pc = 0;
	fs.lasttarget = - 1;
	fs.jpc = luaK.NO_JUMP;
	fs.freereg = 0;
	fs.nk = 0;
	fs.np = 0;
	fs.nlocvars = 0;
	fs.nactvar = 0;
	fs.bl = nil;
	f.source = ls.source;
	f.maxstacksize = 2;
	fs.h = {}
end;
function luaY:close_func(ls)
	local L = ls.L;
	local fs = ls.fs;
	local f = fs.f;
	self:removevars(ls, 0)
	luaK:ret(fs, 0, 0)
	f.sizecode = fs.pc;
	f.sizelineinfo = fs.pc;
	f.sizek = fs.nk;
	f.sizep = fs.np;
	f.sizelocvars = fs.nlocvars;
	f.sizeupvalues = f.nups;
	lua_assert(fs.bl == nil)
	ls.fs = fs.prev;
	if fs then
		self:anchor_token(ls)
	end
end;
function luaY:parser(L, z, buff, name)
	local lexstate = {}
	lexstate.t = {}
	lexstate.lookahead = {}
	local funcstate = {}
	funcstate.upvalues = {}
	funcstate.actvar = {}
	L.nCcalls = 0;
	lexstate.buff = buff;
	luaX:setinput(L, lexstate, z, name)
	self:open_func(lexstate, funcstate)
	funcstate.f.is_vararg = self.VARARG_ISVARARG;
	luaX:next(lexstate)
	self:chunk(lexstate)
	self:check(lexstate, "TK_EOS")
	self:close_func(lexstate)
	lua_assert(funcstate.prev == nil)
	lua_assert(funcstate.f.nups == 0)
	lua_assert(lexstate.fs == nil)
	return funcstate.f
end;
function luaY:field(ls, v)
	local fs = ls.fs;
	local key = {}
	luaK:exp2anyreg(fs, v)
	luaX:next(ls)
	self:checkname(ls, key)
	luaK:indexed(fs, v, key)
end;
function luaY:yindex(ls, v)
	luaX:next(ls)
	self:expr(ls, v)
	luaK:exp2val(ls.fs, v)
	self:checknext(ls, "]")
end;
function luaY:recfield(ls, cc)
	local fs = ls.fs;
	local reg = ls.fs.freereg;
	local key, val = {}, {}
	if ls.t.token == "TK_NAME" then
		self:checklimit(fs, cc.nh, self.MAX_INT, "items in a constructor")
		self:checkname(ls, key)
	else
		self:yindex(ls, key)
	end;
	cc.nh = cc.nh + 1;
	self:checknext(ls, "=")
	local rkkey = luaK:exp2RK(fs, key)
	self:expr(ls, val)
	luaK:codeABC(fs, "OP_SETTABLE", cc.t.info, rkkey, luaK:exp2RK(fs, val))
	fs.freereg = reg
end;
function luaY:closelistfield(fs, cc)
	if cc.v.k == "VVOID" then
		return
	end;
	luaK:exp2nextreg(fs, cc.v)
	cc.v.k = "VVOID"
	if cc.tostore == luaP.LFIELDS_PER_FLUSH then
		luaK:setlist(fs, cc.t.info, cc.na, cc.tostore)
		cc.tostore = 0
	end
end;
function luaY:lastlistfield(fs, cc)
	if cc.tostore == 0 then
		return
	end;
	if self:hasmultret(cc.v.k) then
		luaK:setmultret(fs, cc.v)
		luaK:setlist(fs, cc.t.info, cc.na, self.LUA_MULTRET)
		cc.na = cc.na - 1
	else
		if cc.v.k ~= "VVOID" then
			luaK:exp2nextreg(fs, cc.v)
		end;
		luaK:setlist(fs, cc.t.info, cc.na, cc.tostore)
	end
end;
function luaY:listfield(ls, cc)
	self:expr(ls, cc.v)
	self:checklimit(ls.fs, cc.na, self.MAX_INT, "items in a constructor")
	cc.na = cc.na + 1;
	cc.tostore = cc.tostore + 1
end;
function luaY:constructor(ls, t)
	local fs = ls.fs;
	local line = ls.linenumber;
	local pc = luaK:codeABC(fs, "OP_NEWTABLE", 0, 0, 0)
	local cc = {}
	cc.v = {}
	cc.na, cc.nh, cc.tostore = 0, 0, 0;
	cc.t = t;
	self:init_exp(t, "VRELOCABLE", pc)
	self:init_exp(cc.v, "VVOID", 0)
	luaK:exp2nextreg(ls.fs, t)
	self:checknext(ls, "{")
	repeat
		lua_assert(cc.v.k == "VVOID" or cc.tostore > 0)
		if ls.t.token == "}" then
			break
		end;
		self:closelistfield(fs, cc)
		local c = ls.t.token;
		if c == "TK_NAME" then
			luaX:lookahead(ls)
			if ls.lookahead.token ~= "=" then
				self:listfield(ls, cc)
			else
				self:recfield(ls, cc)
			end
		elseif c == "[" then
			self:recfield(ls, cc)
		else
			self:listfield(ls, cc)
		end
	until not self:testnext(ls, ",") and not self:testnext(ls, ";")
	self:check_match(ls, "}", "{", line)
	self:lastlistfield(fs, cc)
	luaP:SETARG_B(fs.f.code[pc], self:int2fb(cc.na))
	luaP:SETARG_C(fs.f.code[pc], self:int2fb(cc.nh))
end;
function luaY:parlist(ls)
	local fs = ls.fs;
	local f = fs.f;
	local nparams = 0;
	f.is_vararg = 0;
	if ls.t.token ~= ")" then
		repeat
			local c = ls.t.token;
			if c == "TK_NAME" then
				self:new_localvar(ls, self:str_checkname(ls), nparams)
				nparams = nparams + 1
			elseif c == "TK_DOTS" then
				luaX:next(ls)
				self:new_localvarliteral(ls, "arg", nparams)
				nparams = nparams + 1;
				f.is_vararg = self.VARARG_HASARG + self.VARARG_NEEDSARG;
				f.is_vararg = f.is_vararg + self.VARARG_ISVARARG
			else
				luaX:syntaxerror(ls, "<name> or " .. self:LUA_QL("...") .. " expected")
			end
		until f.is_vararg ~= 0 or not self:testnext(ls, ",")
	end;
	self:adjustlocalvars(ls, nparams)
	f.numparams = fs.nactvar - (f.is_vararg % self.HASARG_MASK)
	luaK:reserveregs(fs, fs.nactvar)
end;
function luaY:body(ls, e, needself, line)
	local new_fs = {}
	new_fs.upvalues = {}
	new_fs.actvar = {}
	self:open_func(ls, new_fs)
	new_fs.f.lineDefined = line;
	self:checknext(ls, "(")
	if needself then
		self:new_localvarliteral(ls, "self", 0)
		self:adjustlocalvars(ls, 1)
	end;
	self:parlist(ls)
	self:checknext(ls, ")")
	self:chunk(ls)
	new_fs.f.lastlinedefined = ls.linenumber;
	self:check_match(ls, "TK_END", "TK_FUNCTION", line)
	self:close_func(ls)
	self:pushclosure(ls, new_fs, e)
end;
function luaY:explist1(ls, v)
	local n = 1;
	self:expr(ls, v)
	while self:testnext(ls, ",") do
		luaK:exp2nextreg(ls.fs, v)
		self:expr(ls, v)
		n = n + 1
	end;
	return n
end;
function luaY:funcargs(ls, f)
	local fs = ls.fs;
	local args = {}
	local nparams;
	local line = ls.linenumber;
	local c = ls.t.token;
	if c == "(" then
		if line ~= ls.lastline then
			luaX:syntaxerror(ls, "ambiguous syntax (function call x new statement)")
		end;
		luaX:next(ls)
		if ls.t.token == ")" then
			args.k = "VVOID"
		else
			self:explist1(ls, args)
			luaK:setmultret(fs, args)
		end;
		self:check_match(ls, ")", "(", line)
	elseif c == "{" then
		self:constructor(ls, args)
	elseif c == "TK_STRING" then
		self:codestring(ls, args, ls.t.seminfo)
		luaX:next(ls)
	else
		luaX:syntaxerror(ls, "function arguments expected")
		return
	end;
	lua_assert(f.k == "VNONRELOC")
	local base = f.info;
	if self:hasmultret(args.k) then
		nparams = self.LUA_MULTRET
	else
		if args.k ~= "VVOID" then
			luaK:exp2nextreg(fs, args)
		end;
		nparams = fs.freereg - (base + 1)
	end;
	self:init_exp(f, "VCALL", luaK:codeABC(fs, "OP_CALL", base, nparams + 1, 2))
	luaK:fixline(fs, line)
	fs.freereg = base + 1
end;
function luaY:prefixexp(ls, v)
	local c = ls.t.token;
	if c == "(" then
		local line = ls.linenumber;
		luaX:next(ls)
		self:expr(ls, v)
		self:check_match(ls, ")", "(", line)
		luaK:dischargevars(ls.fs, v)
	elseif c == "TK_NAME" then
		self:singlevar(ls, v)
	else
		luaX:syntaxerror(ls, "unexpected symbol")
	end;
	return
end;
function luaY:primaryexp(ls, v)
	local fs = ls.fs;
	self:prefixexp(ls, v)
	while true do
		local c = ls.t.token;
		if c == "." then
			self:field(ls, v)
		elseif c == "[" then
			local key = {}
			luaK:exp2anyreg(fs, v)
			self:yindex(ls, key)
			luaK:indexed(fs, v, key)
		elseif c == ":" then
			local key = {}
			luaX:next(ls)
			self:checkname(ls, key)
			luaK:_self(fs, v, key)
			self:funcargs(ls, v)
		elseif c == "(" or c == "TK_STRING" or c == "{" then
			luaK:exp2nextreg(fs, v)
			self:funcargs(ls, v)
		else
			return
		end
	end
end;
function luaY:simpleexp(ls, v)
	local c = ls.t.token;
	if c == "TK_NUMBER" then
		self:init_exp(v, "VKNUM", 0)
		v.nval = ls.t.seminfo
	elseif c == "TK_STRING" then
		self:codestring(ls, v, ls.t.seminfo)
	elseif c == "TK_NIL" then
		self:init_exp(v, "VNIL", 0)
	elseif c == "TK_TRUE" then
		self:init_exp(v, "VTRUE", 0)
	elseif c == "TK_FALSE" then
		self:init_exp(v, "VFALSE", 0)
	elseif c == "TK_DOTS" then
		local fs = ls.fs;
		self:check_condition(ls, fs.f.is_vararg ~= 0, "cannot use " .. self:LUA_QL("...") .. " outside a vararg function")
		local is_vararg = fs.f.is_vararg;
		if is_vararg >= self.VARARG_NEEDSARG then
			fs.f.is_vararg = is_vararg - self.VARARG_NEEDSARG
		end;
		self:init_exp(v, "VVARARG", luaK:codeABC(fs, "OP_VARARG", 0, 1, 0))
	elseif c == "{" then
		self:constructor(ls, v)
		return
	elseif c == "TK_FUNCTION" then
		luaX:next(ls)
		self:body(ls, v, false, ls.linenumber)
		return
	else
		self:primaryexp(ls, v)
		return
	end;
	luaX:next(ls)
end;
function luaY:getunopr(op)
	if op == "TK_NOT" then
		return "OPR_NOT"
	elseif op == "-" then
		return "OPR_MINUS"
	elseif op == "#" then
		return "OPR_LEN"
	else
		return "OPR_NOUNOPR"
	end
end;
luaY.getbinopr_table = {
	["+"] = "OPR_ADD",
	["-"] = "OPR_SUB",
	["*"] = "OPR_MUL",
	["/"] = "OPR_DIV",
	["%"] = "OPR_MOD",
	["^"] = "OPR_POW",
	["TK_CONCAT"] = "OPR_CONCAT",
	["TK_NE"] = "OPR_NE",
	["TK_EQ"] = "OPR_EQ",
	["<"] = "OPR_LT",
	["TK_LE"] = "OPR_LE",
	[">"] = "OPR_GT",
	["TK_GE"] = "OPR_GE",
	["TK_AND"] = "OPR_AND",
	["TK_OR"] = "OPR_OR"
}
function luaY:getbinopr(op)
	local opr = self.getbinopr_table[op]
	if opr then
		return opr
	else
		return "OPR_NOBINOPR"
	end
end;
luaY.priority = {
	{
		6,
		6
	},
	{
		6,
		6
	},
	{
		7,
		7
	},
	{
		7,
		7
	},
	{
		7,
		7
	},
	{
		10,
		9
	},
	{
		5,
		4
	},
	{
		3,
		3
	},
	{
		3,
		3
	},
	{
		3,
		3
	},
	{
		3,
		3
	},
	{
		3,
		3
	},
	{
		3,
		3
	},
	{
		2,
		2
	},
	{
		1,
		1
	}
}
luaY.UNARY_PRIORITY = 8;
function luaY:subexpr(ls, v, limit)
	self:enterlevel(ls)
	local uop = self:getunopr(ls.t.token)
	if uop ~= "OPR_NOUNOPR" then
		luaX:next(ls)
		self:subexpr(ls, v, self.UNARY_PRIORITY)
		luaK:prefix(ls.fs, uop, v)
	else
		self:simpleexp(ls, v)
	end;
	local op = self:getbinopr(ls.t.token)
	while op ~= "OPR_NOBINOPR" and self.priority[luaK.BinOpr[op] + 1][1] > limit do
		local v2 = {}
		luaX:next(ls)
		luaK:infix(ls.fs, op, v)
		local nextop = self:subexpr(ls, v2, self.priority[luaK.BinOpr[op] + 1][2])
		luaK:posfix(ls.fs, op, v, v2)
		op = nextop
	end;
	self:leavelevel(ls)
	return op
end;
function luaY:expr(ls, v)
	self:subexpr(ls, v, 0)
end;
function luaY:block_follow(token)
	if token == "TK_ELSE" or token == "TK_ELSEIF" or token == "TK_END" or token == "TK_UNTIL" or token == "TK_EOS" then
		return true
	else
		return false
	end
end;
function luaY:block(ls)
	local fs = ls.fs;
	local bl = {}
	self:enterblock(fs, bl, false)
	self:chunk(ls)
	lua_assert(bl.breaklist == luaK.NO_JUMP)
	self:leaveblock(fs)
end;
function luaY:check_conflict(ls, lh, v)
	local fs = ls.fs;
	local extra = fs.freereg;
	local conflict = false;
	while lh do
		if lh.v.k == "VINDEXED" then
			if lh.v.info == v.info then
				conflict = true;
				lh.v.info = extra
			end;
			if lh.v.aux == v.info then
				conflict = true;
				lh.v.aux = extra
			end
		end;
		lh = lh.prev
	end;
	if conflict then
		luaK:codeABC(fs, "OP_MOVE", fs.freereg, v.info, 0)
		luaK:reserveregs(fs, 1)
	end
end;
function luaY:assignment(ls, lh, nvars)
	local e = {}
	local c = lh.v.k;
	self:check_condition(ls, c == "VLOCAL" or c == "VUPVAL" or c == "VGLOBAL" or c == "VINDEXED", "syntax error")
	if self:testnext(ls, ",") then
		local nv = {}
		nv.v = {}
		nv.prev = lh;
		self:primaryexp(ls, nv.v)
		if nv.v.k == "VLOCAL" then
			self:check_conflict(ls, lh, nv.v)
		end;
		self:checklimit(ls.fs, nvars, self.LUAI_MAXCCALLS - ls.L.nCcalls, "variables in assignment")
		self:assignment(ls, nv, nvars + 1)
	else
		self:checknext(ls, "=")
		local nexps = self:explist1(ls, e)
		if nexps ~= nvars then
			self:adjust_assign(ls, nvars, nexps, e)
			if nexps > nvars then
				ls.fs.freereg = ls.fs.freereg - (nexps - nvars)
			end
		else
			luaK:setoneret(ls.fs, e)
			luaK:storevar(ls.fs, lh.v, e)
			return
		end
	end;
	self:init_exp(e, "VNONRELOC", ls.fs.freereg - 1)
	luaK:storevar(ls.fs, lh.v, e)
end;
function luaY:cond(ls)
	local v = {}
	self:expr(ls, v)
	if v.k == "VNIL" then
		v.k = "VFALSE"
	end;
	luaK:goiftrue(ls.fs, v)
	return v.f
end;
function luaY:breakstat(ls)
	local fs = ls.fs;
	local bl = fs.bl;
	local upval = false;
	while bl and not bl.isbreakable do
		if bl.upval then
			upval = true
		end;
		bl = bl.previous
	end;
	if not bl then
		luaX:syntaxerror(ls, "no loop to break")
	end;
	if upval then
		luaK:codeABC(fs, "OP_CLOSE", bl.nactvar, 0, 0)
	end;
	bl.breaklist = luaK:concat(fs, bl.breaklist, luaK:jump(fs))
end;
function luaY:whilestat(ls, line)
	local fs = ls.fs;
	local bl = {}
	luaX:next(ls)
	local whileinit = luaK:getlabel(fs)
	local condexit = self:cond(ls)
	self:enterblock(fs, bl, true)
	self:checknext(ls, "TK_DO")
	self:block(ls)
	luaK:patchlist(fs, luaK:jump(fs), whileinit)
	self:check_match(ls, "TK_END", "TK_WHILE", line)
	self:leaveblock(fs)
	luaK:patchtohere(fs, condexit)
end;
function luaY:repeatstat(ls, line)
	local fs = ls.fs;
	local repeat_init = luaK:getlabel(fs)
	local bl1, bl2 = {}, {}
	self:enterblock(fs, bl1, true)
	self:enterblock(fs, bl2, false)
	luaX:next(ls)
	self:chunk(ls)
	self:check_match(ls, "TK_UNTIL", "TK_REPEAT", line)
	local condexit = self:cond(ls)
	if not bl2.upval then
		self:leaveblock(fs)
		luaK:patchlist(ls.fs, condexit, repeat_init)
	else
		self:breakstat(ls)
		luaK:patchtohere(ls.fs, condexit)
		self:leaveblock(fs)
		luaK:patchlist(ls.fs, luaK:jump(fs), repeat_init)
	end;
	self:leaveblock(fs)
end;
function luaY:exp1(ls)
	local e = {}
	self:expr(ls, e)
	local k = e.k;
	luaK:exp2nextreg(ls.fs, e)
	return k
end;
function luaY:forbody(ls, base, line, nvars, isnum)
	local bl = {}
	local fs = ls.fs;
	self:adjustlocalvars(ls, 3)
	self:checknext(ls, "TK_DO")
	local prep = isnum and luaK:codeAsBx(fs, "OP_FORPREP", base, luaK.NO_JUMP) or luaK:jump(fs)
	self:enterblock(fs, bl, false)
	self:adjustlocalvars(ls, nvars)
	luaK:reserveregs(fs, nvars)
	self:block(ls)
	self:leaveblock(fs)
	luaK:patchtohere(fs, prep)
	local endfor = isnum and luaK:codeAsBx(fs, "OP_FORLOOP", base, luaK.NO_JUMP) or luaK:codeABC(fs, "OP_TFORLOOP", base, 0, nvars)
	luaK:fixline(fs, line)
	luaK:patchlist(fs, isnum and endfor or luaK:jump(fs), prep + 1)
end;
function luaY:fornum(ls, varname, line)
	local fs = ls.fs;
	local base = fs.freereg;
	self:new_localvarliteral(ls, "(for index)", 0)
	self:new_localvarliteral(ls, "(for limit)", 1)
	self:new_localvarliteral(ls, "(for step)", 2)
	self:new_localvar(ls, varname, 3)
	self:checknext(ls, '=')
	self:exp1(ls)
	self:checknext(ls, ",")
	self:exp1(ls)
	if self:testnext(ls, ",") then
		self:exp1(ls)
	else
		luaK:codeABx(fs, "OP_LOADK", fs.freereg, luaK:numberK(fs, 1))
		luaK:reserveregs(fs, 1)
	end;
	self:forbody(ls, base, line, 1, true)
end;
function luaY:forlist(ls, indexname)
	local fs = ls.fs;
	local e = {}
	local nvars = 0;
	local base = fs.freereg;
	self:new_localvarliteral(ls, "(for generator)", nvars)
	nvars = nvars + 1;
	self:new_localvarliteral(ls, "(for state)", nvars)
	nvars = nvars + 1;
	self:new_localvarliteral(ls, "(for control)", nvars)
	nvars = nvars + 1;
	self:new_localvar(ls, indexname, nvars)
	nvars = nvars + 1;
	while self:testnext(ls, ",") do
		self:new_localvar(ls, self:str_checkname(ls), nvars)
		nvars = nvars + 1
	end;
	self:checknext(ls, "TK_IN")
	local line = ls.linenumber;
	self:adjust_assign(ls, 3, self:explist1(ls, e), e)
	luaK:checkstack(fs, 3)
	self:forbody(ls, base, line, nvars - 3, false)
end;
function luaY:forstat(ls, line)
	local fs = ls.fs;
	local bl = {}
	self:enterblock(fs, bl, true)
	luaX:next(ls)
	local varname = self:str_checkname(ls)
	local c = ls.t.token;
	if c == "=" then
		self:fornum(ls, varname, line)
	elseif c == "," or c == "TK_IN" then
		self:forlist(ls, varname)
	else
		luaX:syntaxerror(ls, self:LUA_QL("=") .. " or " .. self:LUA_QL("in") .. " expected")
	end;
	self:check_match(ls, "TK_END", "TK_FOR", line)
	self:leaveblock(fs)
end;
function luaY:test_then_block(ls)
	luaX:next(ls)
	local condexit = self:cond(ls)
	self:checknext(ls, "TK_THEN")
	self:block(ls)
	return condexit
end;
function luaY:ifstat(ls, line)
	local fs = ls.fs;
	local escapelist = luaK.NO_JUMP;
	local flist = self:test_then_block(ls)
	while ls.t.token == "TK_ELSEIF" do
		escapelist = luaK:concat(fs, escapelist, luaK:jump(fs))
		luaK:patchtohere(fs, flist)
		flist = self:test_then_block(ls)
	end;
	if ls.t.token == "TK_ELSE" then
		escapelist = luaK:concat(fs, escapelist, luaK:jump(fs))
		luaK:patchtohere(fs, flist)
		luaX:next(ls)
		self:block(ls)
	else
		escapelist = luaK:concat(fs, escapelist, flist)
	end;
	luaK:patchtohere(fs, escapelist)
	self:check_match(ls, "TK_END", "TK_IF", line)
end;
function luaY:localfunc(ls)
	local v, b = {}, {}
	local fs = ls.fs;
	self:new_localvar(ls, self:str_checkname(ls), 0)
	self:init_exp(v, "VLOCAL", fs.freereg)
	luaK:reserveregs(fs, 1)
	self:adjustlocalvars(ls, 1)
	self:body(ls, b, false, ls.linenumber)
	luaK:storevar(fs, v, b)
	self:getlocvar(fs, fs.nactvar - 1).startpc = fs.pc
end;
function luaY:localstat(ls)
	local nvars = 0;
	local nexps;
	local e = {}
	repeat
		self:new_localvar(ls, self:str_checkname(ls), nvars)
		nvars = nvars + 1
	until not self:testnext(ls, ",")
	if self:testnext(ls, "=") then
		nexps = self:explist1(ls, e)
	else
		e.k = "VVOID"
		nexps = 0
	end;
	self:adjust_assign(ls, nvars, nexps, e)
	self:adjustlocalvars(ls, nvars)
end;
function luaY:funcname(ls, v)
	local needself = false;
	self:singlevar(ls, v)
	while ls.t.token == "." do
		self:field(ls, v)
	end;
	if ls.t.token == ":" then
		needself = true;
		self:field(ls, v)
	end;
	return needself
end;
function luaY:funcstat(ls, line)
	local v, b = {}, {}
	luaX:next(ls)
	local needself = self:funcname(ls, v)
	self:body(ls, b, needself, line)
	luaK:storevar(ls.fs, v, b)
	luaK:fixline(ls.fs, line)
end;
function luaY:exprstat(ls)
	local fs = ls.fs;
	local v = {}
	v.v = {}
	self:primaryexp(ls, v.v)
	if v.v.k == "VCALL" then
		luaP:SETARG_C(luaK:getcode(fs, v.v), 1)
	else
		v.prev = nil;
		self:assignment(ls, v, 1)
	end
end;
function luaY:retstat(ls)
	local fs = ls.fs;
	local e = {}
	local first, nret;
	luaX:next(ls)
	if self:block_follow(ls.t.token) or ls.t.token == ";" then
		first, nret = 0, 0
	else
		nret = self:explist1(ls, e)
		if self:hasmultret(e.k) then
			luaK:setmultret(fs, e)
			if e.k == "VCALL" and nret == 1 then
				luaP:SET_OPCODE(luaK:getcode(fs, e), "OP_TAILCALL")
				lua_assert(luaP:GETARG_A(luaK:getcode(fs, e)) == fs.nactvar)
			end;
			first = fs.nactvar;
			nret = self.LUA_MULTRET
		else
			if nret == 1 then
				first = luaK:exp2anyreg(fs, e)
			else
				luaK:exp2nextreg(fs, e)
				first = fs.nactvar;
				lua_assert(nret == fs.freereg - first)
			end
		end
	end;
	luaK:ret(fs, first, nret)
end;
function luaY:statement(ls)
	local line = ls.linenumber;
	local c = ls.t.token;
	if c == "TK_IF" then
		self:ifstat(ls, line)
		return false
	elseif c == "TK_WHILE" then
		self:whilestat(ls, line)
		return false
	elseif c == "TK_DO" then
		luaX:next(ls)
		self:block(ls)
		self:check_match(ls, "TK_END", "TK_DO", line)
		return false
	elseif c == "TK_FOR" then
		self:forstat(ls, line)
		return false
	elseif c == "TK_REPEAT" then
		self:repeatstat(ls, line)
		return false
	elseif c == "TK_FUNCTION" then
		self:funcstat(ls, line)
		return false
	elseif c == "TK_LOCAL" then
		luaX:next(ls)
		if self:testnext(ls, "TK_FUNCTION") then
			self:localfunc(ls)
		else
			self:localstat(ls)
		end;
		return false
	elseif c == "TK_RETURN" then
		self:retstat(ls)
		return true
	elseif c == "TK_BREAK" then
		luaX:next(ls)
		self:breakstat(ls)
		return true
	else
		self:exprstat(ls)
		return false
	end
end;
function luaY:chunk(ls)
	local islast = false;
	self:enterlevel(ls)
	while not islast and not self:block_follow(ls.t.token) do
		islast = self:statement(ls)
		self:testnext(ls, ";")
		lua_assert(ls.fs.f.maxstacksize >= ls.fs.freereg and ls.fs.freereg >= ls.fs.nactvar)
		ls.fs.freereg = ls.fs.nactvar
	end;
	self:leavelevel(ls)
end;
luaX:init()
local LuaState = {}
local function compile(source, name)
	name = name or 'compiled-lua'
	local zio = luaZ:init(luaZ:make_getF(source), nil)
	if not zio then
		return
	end;
	local func = luaY:parser(LuaState, zio, nil, "@" .. name)
	local writer, buff = luaU:make_setS()
	luaU:dump(LuaState, func, writer, buff)
	return Serialize(Deserialize(buff.data))
end;
local Parts = {
	Variables = [=[
-- Generic Helpers
local Args = {}
Args[__] = getfenv and getfenv(0) or _ENV
local b = string.char
local function Not(enum,thing)
if enum > _ then
return not thing
else
return #thing
end
end
local function concat(...)
local d = {...}
local w = ''
for i=__,Not(_,d)do
w = w..d[i]
end
return w
end
        local function ba(...)
          local d = (...)
          local duh = ""
          for i = __, Not(_,d) do
             duh = concat(duh,b(d[i]/99))
          end
          return duh
        end
-- Array Helper
local function CreateTbl(_) return {} end;
Args[2] = Args[__][ba(IGNORE:TABLE)]
Args[3] = Args[__][ba(IGNORE:STRING)]
Args[4] = Args[__][ba(IGNORE:MATH)]
Args[5] = Args[__][ba(IGNORE:UNPACK)] or Args[2][ba(IGNORE:UNPACK)]
Args[6] = Args[4][ba(IGNORE:FLOOR)]
Args[7] = Args[2][ba(IGNORE:CONCAT)]
Args[8] = Args[3][ba(IGNORE:BYTE)]
Args[13] = Args[3][ba(IGNORE:SUB)]
Args[9] = Args[__][ba(IGNORE:SELECT)]
Args[10] = Args[3][ba(IGNORE:CHAR)]
Args[11] = Args[__][ba(IGNORE:PAIRS)]
Args[12] = Args[__][ba(IGNORE:IPAIRS)]
Args[14] = Args[4][ba(IGNORE:LDEXP)]
Args[15] = Args[4][ba(IGNORE:ABS)]
local function Pack(...)
    return {
        n = Args[9]('#', ...), ...
    }
end
local function Op(a, b, c)
        if a < 2 then
                return b + c
        elseif a > 2 then
                if a < 5 and a > 3 then
                        return b / c
                elseif a > 5 then
                        if a > 6 then
                            return -b
                        end
                        return b^c
                end
                if a > 4 and a < 6 then
                        return b % c
                end
                return b * c
        else
                return b - c
        end
end
local function Move(src, First, Last, Offset, Dst)
    for i = _, Op(2,Last,First) do
        Dst[Op(__,Offset,i)] = src[Op(__,First,i)]
    end
end
-- Mini Bit Library
local function BAnd(a, b)
    Args[16] = _
    local bitval = __
    while a > _ and b > _ do
        if (Op(5,a,2) == __) and (Op(5,b,2) == __) then
            Args[16] = Op(__,Args[16],bitval)
        end
        bitval = Op(3,bitval,2)
        a = Args[6](Op(4,a,2))
        b = Args[6](Op(4,b,2))
    end
    return Args[16]
end
local function LShift(x, n)
    return Op(6,Op(3,x,2),n)
end
local function RShift(x, n)
    return Args[6](Op(4,x,Op(6,2,n)))
end
local function BOr(a, b)
    Args[16] = _
    local shift = __
    while a > _ or b > _ do
        local abit = Op(5,a,2)
        local bbit = Op(5,b,2)
        if abit == __ or bbit == __ then
            Args[16] = Op(__,Args[16],shift)
        end
        a = Args[6](Op(4,a,2))
        b = Args[6](Op(4,b,2))
        shift = Op(3,shift,2)
    end
    return Args[16]
end
-- Upvalue Helpers
local function CloseLuaUpvalues(B, N)
    for i, uv in Args[11](B) do
        if uv.N >= N then
            uv.m = uv.M[uv.N];
            uv.M = uv;
            uv.N = 'm'
            B[i] = nil;
        end;
    end;
end;
local function SenLuaUpvalue(B, N, X)
    local Prev = B[N]
    if Not(__,1,Prev)then
        Prev = { N = N, M = X }
        B[N] = Prev;
    end;
    return Prev;
end;
]=],
	Deserializer = [=[
-- Args[8] decompression
local basedictdecompress = {}
for i = _, 255 do
    local ic, iic = b(i), b(i, _)
    basedictdecompress[iic] = ic
end
local function dictAddB(str, dict, a, b)
    if a >= 256 then
        a, b = _, Op(__,b,__)
        if b >= 256 then
            dict = {}
            b = __
        end
    end
    dict[Args[10](a, b)] = str
    a = Op(__,a,__)
    return dict, a, b
end
Args[17] = ba(Args[17])
local control = Args[13](Args[17], __, __)
Args[17] = Args[13](Args[17], 2)
local len = Not(_,Args[17])
local dict = {}
local a, b = _, __
Args[16] = {}
local n = __
local last = Args[13](Args[17], __, 2)
Args[16][n] = basedictdecompress[last] or dict[last]
n = Op(__,n,__)
for i = 3, len, 2 do
    local code = Args[13](Args[17], i, Op(__,i,__))
    local lastStr = basedictdecompress[last] or dict[last]
    local toAdd = basedictdecompress[code] or dict[code]
    if toAdd then
        Args[16][n] = toAdd
        n = Op(__,n,__)
        dict, a, b = dictAddB(concat(lastStr,Args[13](toAdd, __, __)), dict, a, b)
    else
        local tmp = concat(lastStr,Args[13](lastStr, __, __))
        Args[16][n] = tmp
        n = Op(__,n,__)
        dict, a, b = dictAddB(tmp, dict, a, b)
    end
    last = code
end
Args[17] = Args[7](Args[16])
-- Args[8] Decoder
local charset = ba(IGNORE:1)
local base, decoded = Not(_,charset), {}
local decode_lookup = {}
    for i = __, base do decode_lookup[Args[13](charset,i, i)] = Op(2,i,__) end
    for encoded_char in Args[17]:gmatch("[^x]+") do
        local n = _
        for i = __, Not(_,encoded_char) do n = Op(__,Op(3,n,base),decode_lookup[Args[13](encoded_char,i, i)]) end
        decoded[Op(__,Not(_,decoded),__)] = Args[10](n)
    end
    Args[17] = Args[7](decoded)
    local Pos = __
    local function gBits8()
        local Val = Args[8](Args[17], Pos, Pos)
        Pos = Op(__,Pos,__)
        return Val;
    end;
    local function gBits16()
        local Val1, Val2 = Args[8](Args[17], Pos, Op(__,Pos,2))
        Pos = Op(__,Pos,2);
        return Op(__,(Op(3,Val2,256)),Val1);
    end;
    local function gBits32()
        local Val1, Val2, Val3, Val4 = Args[8](Args[17], Pos, Op(__,Pos,3))
        Pos = Op(__,Pos,4);
        return Op(__,Op(__,Op(__,(Op(3,Val4,16777216)),(Op(3,Val3,65536))),(Op(3,Val2,256))),Val1);
    end;
    function gChunk()
        local Chunk = {
            n = gBits8(),
            c = gBits8(),
            d = gBits8(),
            x = {},
            D = {},
            V = {}
        }
        for i = __, gBits32() do
            local Data = gBits32()
            local Sco = gBits8()
            local Type = gBits8()
            local Inst = {
                m = Data,
                S = Sco,
                A = gBits16()
            }
            local Mode = {
                b = gBits8(),
                c = gBits8()
            }
            if (Type == __) then
                Inst.B = gBits16()
                Inst.C = gBits16()
                Inst.s = Mode.b == __ and Inst.B > 0xFF
                Inst.a = Mode.c == __ and Inst.C > 0xFF
            elseif (Type == 2) then
                Inst.F = gBits32()
                Inst.g = Mode.b == __
            elseif (Type == 3) then
                Inst.f = Op(2,gBits32(),131071)
            end;
            Chunk.x[i] = Inst;
        end;
        for i = __, gBits32() do
            local Type = gBits8()
            if (Type == __) then
                Chunk.D[Op(2,i,__)] = (gBits8() ~= _)
            elseif (Type == 3) then
                Chunk.D[Op(2,i,__)] =     (function()
        local Left = gBits32()
        local Right = gBits32()
        local IsNormal = __
        local Mantissa = BOr(LShift(BAnd(Right, 0xFFFFF), 32), Left);
        local Exponent  = BAnd(RShift(Right, 20), 0x7FF)
        local Sign = Op(6,(Op(7,__)),RShift(Right, 31))
        if Exponent == _ then
            if Mantissa == _ then
                return Op(3,Sign,_)
            else
                Exponent = __
                IsNormal = _
            end;
        elseif Exponent == 2047 then
            if Mantissa == _ then
                return Op(3,Sign,(Op(4,__,_)))
            else
                return Op(3,Sign,(Op(4,_,_)))
            end;
        end;
        return Op(3,Args[14](Sign, Op(2,Exponent,1023)),(Op(__,IsNormal,(Op(4,Mantissa,(Op(6,2,52)))))))
    end)()
            elseif (Type == 4) then
                Chunk.D[Op(2,i,__)] =     (function()
		local Str;
			local baik = gBits32();
			if (baik == _) then return; end;
			Str	= Args[13](Args[17], Pos, Op(2,Op(__,Pos,baik),__));
			Pos = Op(__,Pos,baik)
		return Str;
	end)()
            end
        end;
        for i = __, gBits32() do
            Chunk.V[Op(2,i,__)] = gChunk()
        end
        -- post process optimization
        for _, v in Args[12](Chunk.x) do
            if v.g then
                v.D = Chunk.D[v.F]
            else
                if v.s then
                    v.A = Chunk.D[Op(2,v.B,256)]
                end;
                if v.a then
                    v.C = Chunk.D[Op(2,v.C,256)]
                end;
            end;
        end
        return Chunk
    end;
]=],
	Wrapper_1 = [=[
function WrapState(V, Upval)
    return (function(...)
        local Passed = Pack(...)
        Args[18] = CreateTbl(V.d)
        local v = { b = _, B = {} }
        Move(Passed, __, V.c, _, Args[18])
        if (V.c < Passed.n) then
            local Start = Op(__,V.c,__)
            local b = Op(2,Passed.n,V.c);
            v.b = b;
            Move(Passed, Start, Op(2,Op(__,Start,b),__), __, v.B)
        end;
        local State = {
            v = v,
            X = Args[18],
            x = V.x,
            Z = V.V,
            z = __
        }
        return (function(State,n)
    local x = State.x;
    local V = State.Z;
    local v = State.v;
    local Top = Op(7,__);
    local SenB = {}
    Args[18] = State.X;
    local z = State.z;
    while alpha do
        local Inst = x[z]
        local S = Inst.S;
        z = Op(__,z,__);
]=],
Wrapper_2 = [=[
        State.z = z;
     end
     end)(State,Upval)
    end)(V,Upval)
end;
]=]
}
local function GetOpcodeCode(S)
	if (S == 0) then
		return [=[
			Args[18][Inst.A] = Args[18][Inst.B];
		]=]
	elseif (S == 1) then
		return [=[
			Args[18][Inst.A] = Inst.D;
		]=]
	elseif (S == 2) then
		return [=[
			Args[18][Inst.A] = Inst.B ~= _;
			if Inst.C ~= _ then z = Op(__,z,__) end;
		]=]
	elseif (S == 3) then
		return [=[
			for i = Inst.A, Inst.B do Args[18][i] = nil end;
		]=]
	elseif (S == 4) then
		return [=[
			local Uv = n[Inst.B];
			Args[18][Inst.A] = Uv.M[Uv.N];
		]=]
	elseif (S == 5) then
		return [=[
			Args[18][Inst.A] = Args[__][Inst.D];
		]=]
	elseif (S == 6) then
		return [=[
			local N = Inst.a and Inst.C or Args[18][Inst.C];
			Args[18][Inst.A] = Args[18][Inst.B][N];
		]=]
	elseif (S == 7) then
		return [=[
			Args[__][Inst.D] = Args[18][Inst.A];
		]=]
	elseif (S == 8) then
		return [=[
			local Uv = n[Inst.B];
			Uv.M[Uv.N] = Args[18][Inst.A];
		]=]
	elseif (S == 9) then
		return [=[
			local N = Inst.s and Inst.A or Args[18][Inst.B];
			local m = Inst.a and Inst.C or Args[18][Inst.C];
			Args[18][Inst.A][N] = m;
		]=]
	elseif (S == 10) then
		return [=[
			Args[18][Inst.A] = {};
		]=]
	elseif (S == 11) then
		return [=[
			local A, B = Inst.A, Inst.B;
			local N = Inst.a and Inst.C or Args[18][Inst.C];
			Args[18][Op(__,A,__)] = Args[18][B];
			Args[18][A] = Args[18][B][N];
		]=]
	elseif (S == 12) then
		return [=[
			local Lhs = Inst.s and Inst.A or Args[18][Inst.B];
			local Rhs = Inst.a and Inst.C or Args[18][Inst.C];
			Args[18][Inst.A] = Op(__,Lhs,Rhs);
		]=]
	elseif (S == 13) then
		return [=[
			local Lhs = Inst.s and Inst.A or Args[18][Inst.B];
			local Rhs = Inst.a and Inst.C or Args[18][Inst.C];
			Args[18][Inst.A] = Op(2,Lhs,Rhs);
		]=]
	elseif (S == 14) then
		return [=[
			local Lhs = Inst.s and Inst.A or Args[18][Inst.B];
			local Rhs = Inst.a and Inst.C or Args[18][Inst.C];
			Args[18][Inst.A] = Op(3,Lhs,Rhs);
		]=]
	elseif (S == 15) then
		return [=[
			local Lhs = Inst.s and Inst.A or Args[18][Inst.B];
			local Rhs = Inst.a and Inst.C or Args[18][Inst.C];
			Args[18][Inst.A] = Op(4,Lhs,Rhs);
		]=]
	elseif (S == 16) then
		return [=[
			local Lhs = Inst.s and Inst.A or Args[18][Inst.B];
			local Rhs = Inst.a and Inst.C or Args[18][Inst.C];
			Args[18][Inst.A] = Op(5,Lhs,Rhs);
		]=]
	elseif (S == 17) then
		return [=[
			local Lhs = Inst.s and Inst.A or Args[18][Inst.B];
			local Rhs = Inst.a and Inst.C or Args[18][Inst.C];
			Args[18][Inst.A] = Op(6,Lhs,Rhs);
		]=]
	elseif (S == 18) then
		return [=[
			Args[18][Inst.A] = Op(7,Args[18][Inst.B]);
		]=]
	elseif (S == 19) then
		return [=[
			Args[18][Inst.A] = Not(__,Args[18][Inst.B]);
		]=]
	elseif (S == 20) then
		return [=[
			Args[18][Inst.A] = Not(_,Args[18][Inst.B]);
		]=]
	elseif (S == 21) then
		return [=[
			local B, C = Inst.B, Inst.C;
			local Success, Str = pcall(Args[7], Args[18], "", B, C);
			if Not(__,Success)then
				Str = Args[18][B] or "";
				for i = Op(__,B,__), C do
					Str = concat(Str,(Args[18][i] or Args[18][Op(2,i,__)]));
				end
			end;
			Args[18][Inst.A] = Str;
		]=]
	elseif (S == 22) then
		return [=[
			z = Op(__,z,Inst.f);
		]=]
	elseif (S == 23) then
		return [=[
			local Lhs = Inst.s and Inst.A or Args[18][Inst.B];
			local Rhs = Inst.a and Inst.C or Args[18][Inst.C];
			if (Lhs == Rhs) == (Inst.A ~= _) then z = Op(__,z,x[z].f) end;
			z = Op(__,z,__);
		]=]
	elseif (S == 24) then
		return [=[
			local Lhs = Inst.s and Inst.A or Args[18][Inst.B];
			local Rhs = Inst.a and Inst.C or Args[18][Inst.C];
			if (Lhs < Rhs) == (Inst.A ~= _) then z = Op(__,z,x[z].f) end;
			z = Op(__,z,__);
		]=]
	elseif (S == 25) then
		return [=[
			local Lhs = Inst.s and Inst.A or Args[18][Inst.B];
			local Rhs = Inst.a and Inst.C or Args[18][Inst.C];
			if (Lhs <= Rhs) == (Inst.A ~= _) then z = Op(__,z,x[z].f) end;
			z = Op(__,z,__);
		]=]
	elseif (S == 26) then
		return [=[
			if (Not(__,Args[18][Inst.A])) ~= (Inst.C ~= _) then z = Op(__,z,x[z].f) end;
			z = Op(__,z,__);
		]=]
	elseif (S == 27) then
		return [=[
			local A, B = Inst.A, Inst.B;
			if (Not(__,Args[18][B])) ~= (Inst.C ~= _) then
				Args[18][A] = Args[18][B];
				z = Op(__,z,x[z].f);
			end;
			z = Op(__,z,__);
		]=]
	elseif (S == 28) then
		return [=[
			local A, B, C = Inst.A, Inst.B, Inst.C;
			local Params = (B == _) and (Op(2,Top,A)) or (Op(2,B,__));
			local RetB = Pack(Args[18][A](Args[5](Args[18], Op(__,A,__), Op(__,A,Params))));
			local RetNum = RetB.n;
			if C == _ then
				Top = Op(2,Op(__,A,RetNum),__);
			else
				RetNum = Op(2,C,__);
			end;
			Move(RetB, __, RetNum, A, Args[18]);
		]=]
	elseif (S == 29) then
		return [=[
			local A, B = Inst.A, Inst.B;
			local Params = (B == _) and (Op(2,Top,A)) or (Op(2,B,__));
			CloseLuaUpvalues(SenB, _);
			return Args[18][A](Args[5](Args[18], Op(__,A,__), Op(__,A,Params)));
		]=]
	elseif (S == 30) then
		return [=[
			local A, B = Inst.A, Inst.B;
			local b = (B == _) and (Op(__,Op(2,Top,A),__)) or (Op(2,B,__));
			CloseLuaUpvalues(SenB, _);
			return Args[5](Args[18], A, Op(2,Op(__,A,b),__));
		]=]
	elseif (S == 31) then
		return [=[
			local A = Inst.A
            local Step = Args[18][Op(__,A,2)];
			local N = Op(__,Args[18][A],Step);
			local Limit = Args[18][Op(__,A,__)];
			local Loops = (Step == Args[15](Step)) and (N <= Limit) or (N >= Limit);
			if Loops then
				Args[18][A] = N;
				Args[18][Op(__,A,3)] = N;
				z = Op(__,z,Inst.f);
			end;
		]=]
	elseif (S == 32) then
		return [=[
			local A = Inst.A;
			local Init, Limit, Step = tonumber(Args[18][A]), tonumber(Args[18][Op(__,A,__)]), tonumber(Args[18][Op(__,A,2)]);
			Args[18][A] = Op(2,Init,Step);
			Args[18][Op(__,A,__)] = Limit;
			Args[18][Op(__,A,2)] = Step;
			z = Op(__,z,Inst.f);
		]=]
	elseif (S == 33) then
		return [=[
			local A = Inst.A;
			local Base = Op(__,A,3);
			local Vals = {Args[18][A](Args[18][Op(__,A,__)], Args[18][Op(__,A,2)])};
			Move(Vals, __, Inst.C, Base, Args[18]);
			if Args[18][Base] ~= nil then
				Args[18][Op(__,A,2)] = Args[18][Base];
				z = Op(__,z,x[z].f);
			end;
			z = Op(__,z,__);
		]=]
	elseif (S == 34) then
		return [=[
			local A, C = Inst.A, Inst.C;
			local b = Inst.B;
			local Tab = Args[18][A];
			if b == _ then b = Op(2,Top,A) end;
			if C == _ then
				C = x[z].m;
				z = Op(__,z,__);
			end;
			local Offset = Op(3,(Op(2,C,__)),50);
			Move(Args[18], Op(__,A,__), Op(__,A,b), Op(__,Offset,__), Tab);
		]=]
	elseif (S == 35) then
		return [=[CloseLuaUpvalues(SenB, Inst.A)]=]
	elseif (S == 36) then
		return [=[
			Args[13] = V[Inst.F];
			local Nups = Args[13].n;
			local UvB;
			if Nups ~= _ then
				UvB = CreateTbl(Op(2,Nups,__));
				for i = __, Nups do
					local Pseudo = x[Op(2,Op(__,z,i),__)];
					if (Pseudo.S == _) then
						UvB[Op(2,i,__)] = SenLuaUpvalue(SenB, Pseudo.B, Args[18]);
					elseif (Pseudo.S == 4) then
						UvB[Op(2,i,__)] = n[Pseudo.B];
					end;
				end;
				z = Op(__,z,Nups);
			end;
			Args[18][Inst.A] = WrapState(Args[13], Args[__], UvB);
		]=]
	elseif (S == 37) then
		return [=[
			local A, b = Inst.A, Inst.B;
			if (b == _) then
				b = v.b;
				Top = Op(2,Op(__,A,b),__);
			end;
			Move(v.B, __, b, A, Args[18]);
		]=]
	end
end;
local function Generate(...)
	local Data = {
		...
	}
	local Bytecode = Data[1]
	local UsedOpcodes = Data[2]
	local Out = ""
	local function Add(Code)
		Out = Out .. "\n" .. Code
	end;
	local function GenerateVariable(length)
		local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		local result = {}
		math.randomseed(os.clock() ^ math.random(2, 5))
		for i = 1, length do
			local rand = math.random(1, # charset)
			table.insert(result, charset:sub(rand, rand))
		end;
		return table.concat(result)
	end;
	local function string_shuffle(str)
		local chars = {}
		for i = 1, # str do
			chars[i] = str:sub(i, i)
		end;
		for i = # chars, 2, - 1 do
			local j = math.random(1, i)
			chars[i], chars[j] = chars[j], chars[i]
		end;
		return table.concat(chars)
	end;
	math.randomseed(os.time())
	local charset = string_shuffle('\0\2')
	local base, encode_lookup, decode_lookup = # charset, {}, {}
	for i = 1, base do
		local c = charset:sub(i, i)
		encode_lookup[i - 1], decode_lookup[c] = c, i - 1
	end;
        local basedictcompress = {}
        for i = 0, 255 do
           local ic, iic = string.char(i), string.char(i, 0)
           basedictcompress[ic] = iic
        end
        local function dictAddA(str, dict, a, b)
            if a >= 256 then
               a, b = 0, b+1
                if b >= 256 then
                   dict = {}
                   b = 1
                end
           end
           dict[str] = string.char(a,b)
           a = a+1
           return dict, a, b
       end

local function compress(input)
    if type(input) ~= "string" then
        return nil, "string expected, got "..type(input)
    end
    local len = #input
    if len <= 1 then
        return "u"..input
    end

    local dict = {}
    local a, b = 0, 1

    local result = {"c"}
    local resultlen = 1
    local n = 2
    local word = ""
    for i = 1, len do
        local c = string.sub(input, i, i)
        local wc = word..c
               if not (basedictcompress[wc] or dict[wc]) then
                   local write = basedictcompress[word] or dict[word]
                   if not write then
                       return nil, "algorithm error, could not fetch word"
                   end
                   result[n] = write
                   resultlen = resultlen + #write
                   n = n+1
                   if  len <= resultlen then
                       return "u"..input
                   end
                   dict, a, b = dictAddA(wc, dict, a, b)
                   word = c
               else
                   word = wc
               end
           end
           result[n] = basedictcompress[word] or dict[word]
           resultlen = resultlen+#result[n]
           n = n+1
           if  len <= resultlen then
              return "u"..input
           end
           return table.concat(result)
        end
	local function encode_number(n)
		local e = {}
		repeat
			local r = n % base;
			table.insert(e, 1, encode_lookup[r])
			n = math.floor(n / base)
		until n == 0;
		return table.concat(e)
	end;
	local function encode_string(str)
		local encoded = {}
		for i = 1, # str do
			local char = str:sub(i, i)
			table.insert(encoded, encode_number(char:byte()))
		end;
		return table.concat(encoded, "x")
	end;
	local function Encode(Str,yes,normal)
                normal = normal or true
                if yes then
		Str = compress(encode_string(Str))
                end
		local out = "{"
		for i = 1, # Str do
                        local hi = string.byte(Str, i)
                        if normal then hi = hi*99 end
			out = out .. hi .. ','
		end;
                out = out .. '}'
		return out
	end;
        local function EncodeBin(Str)
                local out = ''
                for i = 1, # Str do
                        out = out .. '\\' .. string.byte(Str, i)
                end;
                return out
        end;
	Add("hercules,v1,alpha,__,_ = 'Protected By Hercules V1.6 | VM', function()end, true, 1, 0")
	Add(Parts.Variables:gsub("IGNORE:SELECT",Encode("select",false)):gsub("IGNORE:UNPACK",Encode("unpack",false)):gsub("IGNORE:TABLE",Encode("table",false)):gsub("IGNORE:STRING",Encode("string",false)):gsub("IGNORE:MATH",Encode("math",false)):gsub("IGNORE:SUB",Encode("sub",false)):gsub("IGNORE:BYTE",Encode("byte",false)):gsub("IGNORE:FLOOR",Encode("floor")):gsub("IGNORE:CONCAT",Encode("concat",false)):gsub("IGNORE:CHAR",Encode("char",false)):gsub("IGNORE:PAIRS",Encode("pairs",false)):gsub("IGNORE:IPAIRS",Encode("ipairs",false)):gsub("IGNORE:LDEXP",Encode("ldexp",false)):gsub("IGNORE:ABS",Encode("abs",false)))
        Add("Args[17] = "..Encode(Bytecode,true))
	Add(Parts.Deserializer:gsub("IGNORE:1",Encode(charset,false)))
	Add(Parts.Wrapper_1)
	local k = "if"
	for i, v in pairs(UsedOpcodes) do
		local Op = UsedOpcodes[v]
		Add(k .. " (S == " .. Op .. ") then\n")
		Add(GetOpcodeCode(Op))
		k = "elseif"
	end;
	Add("end")
	Add(Parts.Wrapper_2)
	Add("WrapState(gChunk())")
	return Out
end;
local VM = {}
function VM.process(source)
	_G.UsedOps[0] = 0;
	_G.UsedOps[4] = 4;
        --[[for i=1,37 do
           if not _G.UsedOps[i] then
               _G.UsedOps[i] = i
          end
        end]] -- might bloat, dont uncomment unless you want yottabytes B)
	source = Generate(compile(source), _G.UsedOps)
	return source
end;
return VM
