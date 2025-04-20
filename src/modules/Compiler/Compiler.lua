-- i seriously need help 
local Serialize = require("modules/Compiler/Serializer")
local Deserialize = require("modules/Compiler/Deserializer")
local luaZ = {}
local luaY = {}
local luaX = {}
local luaP = {}
local luaU = {}
local luaK = {}
local size_size_t = 8;
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
function compile(source, name)
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
return compile
