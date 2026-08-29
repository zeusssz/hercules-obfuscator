--!optimize 2
--!strict
--!native

-- // Parser Settings


-- [retranspile] top-level locals moved into the H namespace table (scope-aware)
local H = {}

 H.LuauIntegerType2 = false
 H.LuauExportValueSyntax = false
 H.DebugLuauNoInline = false
 H.DebugLuauUserDefinedClasses = false
 H.LuauAllowGlobalDeclarationToBeCalledClass = false
 H.LuauDisallowExternClassInTypeDefinitions = false
 H.LuauTableEntriesDontNeedToMatchIndent = true
 H.LuauStoreConstKeywordBegin = true

 H.LuauParseErrorLimit = 100

-- // Requires modules

 H.Confusables = require"Parser/LuauParser/Confusables"
 H.Syntax = require"Parser/LuauParser/Syntax"

 H.EmptyArray = table.freeze({})

 H.hotcommentHeader = true

-- // String types

 H.BraceType = {
	InterpolatedString = 0,
	Normal = 1,
}

 H.QuoteStyle = {
	QuotedSimple = 0,
	QuotedSingle = 1,
	QuotedRaw = 2,
	Unquoted = 3,
}

 H.CstQuotes = {
	QuotedSingle = 0, -- ''
	QuotedDouble = 1, -- ""
	QuotedRaw = 2, -- [[]]
	QuotedInterp = 3, -- ``
}

-- // Lookup for keywords
 H.ReversedKeywords = {
	[291] = "and",
	[292] = "break",
	[293] = "do",
	[294] = "else",
	[295] = "elseif",
	[296] = "end",
	[297] = "false",
	[298] = "for",
	[299] = "function",
	[300] = "if",
	[301] = "in",
	[302] = "local",
	[303] = "nil",
	[304] = "not",
	[305] = "or",
	[306] = "repeat",
	[307] = "return",
	[308] = "then",
	[309] = "true",
	[310] = "until",
	[311] = "while",
}

 H.IdentifierCharacters = buffer.create(256)
buffer.writeu8(H.IdentifierCharacters, 95, 1)
for Byte = 65, 90 do
	buffer.writeu8(H.IdentifierCharacters, Byte, 1)
end
for Byte = 97, 122 do
	buffer.writeu8(H.IdentifierCharacters, Byte, 1)
end
for Byte = 48, 57 do
	buffer.writeu8(H.IdentifierCharacters, Byte, 2)
end

 H.SimpleTokens = buffer.create(512)
buffer.writeu16(H.SimpleTokens, 40 * 2, 40) -- (
buffer.writeu16(H.SimpleTokens, 41 * 2, 41) -- )
buffer.writeu16(H.SimpleTokens, 93 * 2, 93) -- ]
buffer.writeu16(H.SimpleTokens, 59 * 2, 59) -- ;
buffer.writeu16(H.SimpleTokens, 44 * 2, 44) -- ,
buffer.writeu16(H.SimpleTokens, 35 * 2, 35) -- #
buffer.writeu16(H.SimpleTokens, 63 * 2, 63) -- ?
buffer.writeu16(H.SimpleTokens, 38 * 2, 38) -- &
buffer.writeu16(H.SimpleTokens, 124 * 2, 124) -- |
buffer.writeu16(H.SimpleTokens, 61 * 2, 257) -- ==
buffer.writeu16(H.SimpleTokens, 60 * 2, 258) -- <=
buffer.writeu16(H.SimpleTokens, 62 * 2, 259) -- >=
buffer.writeu16(H.SimpleTokens, 126 * 2, 260) -- ~=
buffer.writeu16(H.SimpleTokens, 43 * 2, 270) -- +=
buffer.writeu16(H.SimpleTokens, 42 * 2, 272) -- *=
buffer.writeu16(H.SimpleTokens, 37 * 2, 275) -- %=
buffer.writeu16(H.SimpleTokens, 94 * 2, 276) -- ^=

-- // Lookup for operators

 H.BinaryOp = {
	Add = 0,
	Sub = 1,
	Mul = 2,
	Div = 3,
	FloorDiv = 4,
	Mod = 5,
	Pow = 6,
	Concat = 7,
	CompareNe = 8,
	CompareEq = 9,
	CompareLt = 10,
	CompareLe = 11,
	CompareGt = 12,
	CompareGe = 13,
	And = 14,
	Or = 15,
}

 H.BinaryPriority = {
	[H.BinaryOp.Add] = { 6, 6 },
	[H.BinaryOp.Sub] = { 6, 6 },
	[H.BinaryOp.Mul] = { 7, 7 },
	[H.BinaryOp.Div] = { 7, 7 },
	[H.BinaryOp.FloorDiv] = { 7, 7 },
	[H.BinaryOp.Mod] = { 7, 7 },
	[H.BinaryOp.Pow] = { 10, 9 },
	[H.BinaryOp.Concat] = { 5, 4 },
	[H.BinaryOp.CompareNe] = { 3, 3 },
	[H.BinaryOp.CompareEq] = { 3, 3 },
	[H.BinaryOp.CompareLt] = { 3, 3 },
	[H.BinaryOp.CompareLe] = { 3, 3 },
	[H.BinaryOp.CompareGt] = { 3, 3 },
	[H.BinaryOp.CompareGe] = { 3, 3 },
	[H.BinaryOp.And] = { 2, 2 },
	[H.BinaryOp.Or] = { 1, 1 },
}

 H.CompoundLookup = {
	[274] = H.BinaryOp.FloorDiv, -- FloorDivAssign
	[277] = H.BinaryOp.Concat, -- ConcatAssign
	[275] = H.BinaryOp.Mod, -- ModAssign
	[276] = H.BinaryOp.Pow, -- PowAssign
	[270] = H.BinaryOp.Add, -- AddAssign
	[271] = H.BinaryOp.Sub, -- SubAssign
	[272] = H.BinaryOp.Mul, -- MulAssign
	[273] = H.BinaryOp.Div, -- DivAssign
}

 H.BinaryOpLookup = {
	[43] = H.BinaryOp.Add,
	[45] = H.BinaryOp.Sub,
	[42] = H.BinaryOp.Mul,
	[47] = H.BinaryOp.Div,

	[265] = H.BinaryOp.FloorDiv, -- FloorDiv

	[37] = H.BinaryOp.Mod,
	[94] = H.BinaryOp.Pow,

	[261] = H.BinaryOp.Concat, -- Dot2
	[260] = H.BinaryOp.CompareNe, -- NotEqual
	[257] = H.BinaryOp.CompareEq, -- Equal

	[60] = H.BinaryOp.CompareLt,

	[258] = H.BinaryOp.CompareLe, -- LessEqual

	[62] = H.BinaryOp.CompareGt,

	[259] = H.BinaryOp.CompareGe, -- GreaterEqual
	[291] = H.BinaryOp.And, -- ReservedAnd
	[305] = H.BinaryOp.Or, -- ReservedOr
}

 H.UnaryOpLookup = {
	[304] = 0, -- ReservedNot
	[45] = 1, -- Minus
	[35] = 2, -- Len
}

 H.BlockFollow = {
	[295] = true, -- ReservedElseif
	[310] = true, -- ReservedUntil
	[294] = true, -- ReservedElse
	[296] = true, -- ReservedEnd
	[0] = true, -- Eof
}

 H.ConstantLiteral = {
	ExprConstantNil = true,
	ExprConstantBool = true,
	ExprConstantNumber = true,
	ExprConstantInteger = true,
	ExprConstantString = true,
}

 H.ExprLValues = {
	ExprLocal = true,
	ExprGlobal = true,
	ExprIndexExpr = true,
	ExprIndexName = true,
}

 H.AllowedClassMetamethods = {
	__call = true,
	__concat = true,
	__unm = true,
	__add = true,
	__sub = true,
	__mul = true,
	__div = true,
	__mod = true,
	__pow = true,
	__tostring = true,
	__eq = true,
	__lt = true,
	__le = true,
	__iter = true,
	__len = true,
	__idiv = true,
}

 H.DisallowedClassMetamethods = {
	__index = true,
	__newindex = true,
	__mode = true,
	__metatable = true,
	__type = true,
}

-- // Lookups for Lexer

 H.HexDigits= {}
 H.HexVal= {}
 H.Digits= {}
 H.Alpha= {}

 H.Spaces = {
	[09] = true, -- \t
	[10] = true, -- \n
	[11] = true, -- \v
	[12] = true, -- \f
	[13] = true, -- \r
	[32] = true, -- space
}

 H.Escapes = {
	[97] = 7,
	[98] = 8,
	[102] = 12,
	[110] = 10,
	[114] = 13,
	[116] = 9,
	[118] = 11,
}

for i = 48, 57 do -- '0' - '9'
	H.HexDigits[i] = true
	H.Digits[i] = true
end

for i = 65, 90 do
	if i <= 70 then
		H.HexDigits[i] = true
	end -- 'a' - 'f'
	H.Alpha[i] = true
end

for i = 97, 122 do
	if i <= 102 then
		H.HexDigits[i] = true
	end -- 'A' - 'F'
	H.Alpha[i] = true
end

for i = 48, 57 do H.HexVal[i] = i - 48 end -- '0'-'9'
for i = 65, 70 do H.HexVal[i] = i - 55 end -- 'A'-'F'
for i = 97, 102 do H.HexVal[i] = i - 87 end -- 'a'-'f'

-- // Lexer helper

H.fixupQuotedString = function (data)	
if #data == 0 or not string.find(data, "\\") then
		return true, data
	end

	local size = #data
	local src = buffer.fromstring(data)
	local buf = buffer.create(size)
	local write = 0
	local i = 0

	while i < size do
local __DARKLUA_CONTINUE_10=false repeat		local ch = buffer.readu8(src, i)

		if ch ~= 92 then -- not '\'
			buffer.writeu8(buf, write, ch)
			write =write+ 1
			i =i+ 1
__DARKLUA_CONTINUE_10=true			break
		end

		if i + 1 == size then
			return false, nil -- Trailing backslash
		end

		local escape = buffer.readu8(src, i + 1)
		i =i+ 2 -- skip \ and the escape char

		if escape == 10 then -- \n
			buffer.writeu8(buf, write, 10)
			write =write+ 1
		elseif escape == 13 then -- \r
			buffer.writeu8(buf, write, 10)
			write =write+ 1
			if i < size and buffer.readu8(src, i) == 10 then
				i =i+ 1
			end
		elseif escape == 0 then
			return false, nil
		elseif escape == 120 then -- 'x'
			if i + 2 > size then
				return false, nil
			end

			local code = 0
			for j = 0, 1 do
				local c = buffer.readu8(src, i + j)
				if not H.HexDigits[c] then
					return false, nil
				end

				local hexVal = (H.Digits[c] and{(c - 48 )}or{(bit32.bor(c, 32) - 97 + 10
)})[1]				code = 16 * code + hexVal
			end

			buffer.writeu8(buf, write, code)
			write =write+ 1
			i =i+ 2
		elseif escape == 122 then -- 'z'
			while i < size and H.Spaces[buffer.readu8(src, i)] do
				i =i+ 1
			end
		elseif escape == 117 then -- 'u'
			if i + 3 > size then
				return false, nil
			end
			if buffer.readu8(src, i) ~= 123 then
				return false, nil
			end -- '{'
			i =i+ 1

			if buffer.readu8(src, i) == 125 then
				return false, nil
			end

			local code = 0
			local ended = false

			for j = 0, 15 do
				if i == size then
					return false, nil
				end
				local c = buffer.readu8(src, i)

				if c == 125 then
					ended = true
					break
				end

				if not H.HexDigits[c] then
					return false, nil
				end

				local hexVal = (H.Digits[c] and{(c - 48 )}or{(bit32.bor(c, 32) - 97 + 10
)})[1]				code = 16 * code + hexVal
				i =i+ 1
			end

			if not ended then
				if i == size or buffer.readu8(src, i) ~= 125 then
					return false, nil
				end
			end
			i =i+ 1 -- skip '}'

			if code < 0x80 then
				buffer.writeu8(buf, write, code)
				write =write+ 1
			elseif code < 0x800 then
				buffer.writeu8(buf, write, bit32.bor(0xC0, bit32.rshift(code, 6)))
				buffer.writeu8(buf, write + 1, bit32.bor(0x80, bit32.band(code, 0x3F)))
				write =write+ 2
			elseif code < 0x10000 then
				buffer.writeu8(buf, write, bit32.bor(0xE0, bit32.rshift(code, 12)))
				buffer.writeu8(buf, write + 1, bit32.bor(0x80, bit32.band(bit32.rshift(code, 6), 0x3F)))
				buffer.writeu8(buf, write + 2, bit32.bor(0x80, bit32.band(code, 0x3F)))
				write =write+ 3
			elseif code < 0x110000 then
				buffer.writeu8(buf, write, bit32.bor(0xF0, bit32.rshift(code, 18)))
				buffer.writeu8(buf, write + 1, bit32.bor(0x80, bit32.band(bit32.rshift(code, 12), 0x3F)))
				buffer.writeu8(buf, write + 2, bit32.bor(0x80, bit32.band(bit32.rshift(code, 6), 0x3F)))
				buffer.writeu8(buf, write + 3, bit32.bor(0x80, bit32.band(code, 0x3F)))
				write =write+ 4
			else
				return false, nil
			end
		else
			if H.Digits[escape] then
				local code = escape - 48

				for j = 0, 1 do
					if i == size then
						break
					end
					local c = buffer.readu8(src, i)
					if not H.Digits[c] then
						break
					end
					code = 10 * code + (c - 48)
					i =i+ 1
				end

				if code > 255 then
					return false, nil
				end

				buffer.writeu8(buf, write, code)
				write =write+ 1
			else
				buffer.writeu8(buf, write, H.Escapes[escape] or escape)
				write =write+ 1
			end
		end
__DARKLUA_CONTINUE_10=true until true if not __DARKLUA_CONTINUE_10 then break end	end

	return true, buffer.readstring(buf, 0, write)
end

H.fixupMultilineString = function (data)	
if #data == 0 then
		return data
	end

	data = string.gsub(data, "^\r?\n", "")
	data = string.gsub(data, "\r\n", "\n")

	return data
end

H.ToString = function (t, data, codepoint)	
if t == 0 then
		return "<eof>"
	elseif t == 257 then
		return "'=='"
	elseif t == 258 then
		return "'<='"
	elseif t == 259 then
		return "'>='"
	elseif t == 260 then
		return "'~='"
	elseif t == 261 then
		return "'..'"
	elseif t == 262 then
		return "'...'"
	elseif t == 263 then
		return "'->'"
	elseif t == 264 then
		return "'::'"
	elseif t == 265 then
		return "'//'"
	elseif t == 270 then
		return "'+='"
	elseif t == 271 then
		return "'-='"
	elseif t == 272 then
		return "'*='"
	elseif t == 273 then
		return "'/='"
	elseif t == 274 then
		return "'//='"
	elseif t == 275 then
		return "'%='"
	elseif t == 276 then
		return "'^='"
	elseif t == 277 then
		return "'..='"
	elseif t == 278 or t == 279 then
		if data then
			return string.format('"%s"', tostring(data))		
else
			return "string"
		end
	elseif t == 266 then
		if data then
			return string.format('`%s{', tostring(data))		
else
			return "the beginning of an interpolated string"
		end
	elseif t == 267 then
		if data then
			return string.format('}%s{', tostring(data))		
else
			return "the middle of an interpolated string"
		end
	elseif t == 268 then
		if data then
			return string.format('}%s`', tostring(data))		
else
			return "the end of an interpolated string"
		end
	elseif t == 269 then
		if data then
			return string.format('`%s`', tostring(data))		
else
			return "interpolated string"
		end
	elseif t == 280 then
		if data then
			return string.format("'%s'", tostring(data))		
else
			return "number"
		end
	elseif t == 281 then
		if data then
			return string.format("'%s'", tostring(data))		
else
			return "identifier"
		end
	elseif t == 282 then
		return "comment"
	elseif t == 284 then
		if data then
			return string.format("'%s'", tostring(data))		
else
			return "attribute"
		end
	elseif t == 285 then
		return "'@['"
	elseif t == 286 then
		return "malformed string"
	elseif t == 287 then
		return "unfinished comment"
	elseif t == 289 then
		return "'{{', which is invalid (did you mean '\\{'?)"
	elseif t == 288 then
		if codepoint then
			local confusable = H.Confusables[codepoint]
			if confusable then
				return string.format("Unicode character %s (did you mean '%s'?)", tostring(string.format("U+%x", codepoint)), tostring(confusable))			
end
			return string.format("Unicode character U+%x", codepoint)
		else
			return "invalid UTF-8 sequence"
		end
	else
		if t < 256 then
			return string.format("'%c'", t)
		elseif H.ReversedKeywords[t] then
			return string.format("'%s'", tostring(H.ReversedKeywords[t]))		
else
			return "<unknown>"
		end
	end
end

-- // Parser Helpers

H.isLiteralTable = function (expr)	
if expr.kind ~= "ExprTable" then
		return false
	end

	for _, item in ipairs(expr.items) do
		if item.kind == "General" then
			return false
		elseif item.kind == "Record" or item.kind == "List" then
			if not H.ConstantLiteral[item.value.kind] and not H.isLiteralTable(item.value) then
				return false
			end
		end
	end

	return true
end

-- // Attributes

H.deprecatedArgsValidator = function (attrLoc, args)	
local errors= {}
	if #args == 0 then
		return errors
	end
	if #args > 1 then
		table.insert(errors, {
			location = attrLoc,
			message = "@deprecated can be parametrized only by 1 argument",
		})
		return errors
	end

	local arg = args[1]
	if arg.kind ~= "ExprTable" then
		table.insert(errors, {
			location = arg.location,
			message = "Unknown argument type for @deprecated",
		})
		return errors
	end

	for _, item in ipairs(arg.items) do
		if item.key and item.kind == "Record" and item.key.kind == "ExprConstantString" then
			local keyString = item.key.value
			if keyString ~= "use" and keyString ~= "reason" then
				table.insert(errors, {
					location = item.key.location,
					message = string.format([[Unknown argument '%s' for @deprecated. Only string constants for 'use' and 'reason' are allowed]], tostring(keyString)),
				})
			elseif item.value.kind ~= "ExprConstantString" then
				table.insert(errors, {
					location = item.value.location,
					message = string.format("Only constant string allowed as value for '%s'", tostring(keyString)),
				})
			end
		else
			table.insert(errors, {
				location = item.value.location,
				message = "Only constants keys 'use' and 'reason' are allowed for @deprecated attribute",
			})
		end
	end
	return errors
end

 H.kAttributeEntries = {
	checked = {type = "Checked"},
	native = {type = "Native"},

	deprecated = {
		type = "Deprecated",
		argsValidator = H.deprecatedArgsValidator,
	},
}

 H.kDebugAttributeEntries = {
	debugnoinline = {type = "DebugNoinline"},
}

-- // Main

 H.options = {} 
-- // Settings init


 H.captureComments = H.options.captureComments
 H.storeCstData = H.options.storeCstData

-- // Lexer State & Buffer

 H.buff_data = buffer.create(0)
 H.size = 0

-- Current State
 H.offset = 0
 H.line = 0
 H.lineOffset = 0

 H.braceStack= {}
 H.braceStackSize = 0

-- // Current Token State

 H.token_type = 0 -- Eof

-- Locations
 H.token_start_line = 0
 H.token_start_col = 0
 H.token_end_line = 0
 H.token_end_col = 0

-- Previous Token Location (for errors/end mismatch)
 H.prev_start_line = 0
 H.prev_start_col = 0
 H.prev_end_line = 0
 H.prev_end_col = 0

-- Payload
 H.token_string= nil
 H.token_aux= nil
 H.token_codepoint= nil

-- // Parser init

 H.recursionCounter = 0

 H.commentLocations= {}
 H.hotcomments = {} 
 H.parseErrors= {}
 H.declaredExportBindings= {}
 H.hasModuleReturn = false
 H.classesWithinModule= {}


-- // Suspect State








 H.next_type = 0 -- Eof
 H.next_start_line = 0
 H.next_end_line = 0

 H.next_start_col = 0
 H.next_end_col = 0

 H.next_codepoint= nil
 H.next_string= nil
 H.next_aux= nil

 H.suspect_type = 0 -- Eof sentinel

 H.suspect_line = 0

 H.matchRecovery = table.create(312, 0)
H.matchRecovery[0] = 1 -- Eof

-- // Stacks

 H.functionStack= {{ vararg = true, loopDepth = 0 }}

 H.localStack= {}
 H.localMap= {}

-- // Lexer // --

H.lex = function (skip_comments)
	local ptr = H.offset
	local cur_line = H.line
	local cur_line_offset = H.lineOffset

	local buff = H.buff_data
	local sourceSize = H.size
	local IdentifierCharactersLookup = H.IdentifierCharacters
	local SimpleTokensLookup = H.SimpleTokens

	while true do
		if ptr >= sourceSize then
			-- EOF Logic
			H.offset = ptr
			H.line = cur_line
			H.lineOffset = cur_line_offset

			H.next_type = 0 -- Eof
			H.next_end_line = cur_line
			H.next_end_col = ptr - cur_line_offset

			H.next_start_line = cur_line
			H.next_start_col = ptr - cur_line_offset
			return
		end

		local c = buffer.readu8(buff, ptr)

		if c == 32 or c == 9 then -- space or tab
			ptr =ptr+ 1
		elseif c == 10 then -- \n
			cur_line =cur_line+ 1
			ptr =ptr+ 1
			cur_line_offset = ptr
		elseif c == 13 then -- \r
			if ptr + 1 < sourceSize and buffer.readu8(buff, ptr + 1) == 10 then
				ptr =ptr+ 2
				cur_line =cur_line+ 1
				cur_line_offset = ptr
			else
				ptr =ptr+ 1
			end
		elseif c == 11 or c == 12 then -- \v, \f
			ptr =ptr+ 1
		else
			break -- not whitespace
		end
	end

	H.next_start_line = cur_line
	H.next_start_col = ptr - cur_line_offset
	H.next_string = nil
	H.next_aux = nil
	H.next_codepoint = nil

	local ch = buffer.readu8(buff, ptr)
	local characterType = buffer.readu8(IdentifierCharactersLookup, ch)
	local start_ptr = ptr
	ptr =ptr+ 1 -- Consume current char

	-- Identifiers / Keywords
	if characterType == 1 then
		while ptr < sourceSize do
			local c = buffer.readu8(buff, ptr)
			if buffer.readu8(IdentifierCharactersLookup, c) ~= 0 then
				ptr =ptr+ 1
			else
				break
			end
		end

		local identifierLength = ptr - start_ptr
		local identifierType = 281

		if identifierLength == 2 then
			local bytes = buffer.readu16(buff, start_ptr)
			if bytes == 0x6f64 then -- do
				identifierType = 293
			elseif bytes == 0x6669 then -- if
				identifierType = 300
			elseif bytes == 0x6e69 then -- in
				identifierType = 301
			elseif bytes == 0x726f then -- or
				identifierType = 305
			end
		elseif identifierLength == 3 then
			local firstBytes = buffer.readu16(buff, start_ptr)
			local thirdByte = buffer.readu8(buff, start_ptr + 2)
			if firstBytes == 0x6e61 and thirdByte == 100 then -- and
				identifierType = 291
			elseif firstBytes == 0x6e65 and thirdByte == 100 then -- end
				identifierType = 296
			elseif firstBytes == 0x6f66 and thirdByte == 114 then -- for
				identifierType = 298
			elseif firstBytes == 0x696e and thirdByte == 108 then -- nil
				identifierType = 303
			elseif firstBytes == 0x6f6e and thirdByte == 116 then -- not
				identifierType = 304
			end
		elseif identifierLength == 4 then
			local bytes = buffer.readu32(buff, start_ptr)
			if bytes == 0x65736c65 then -- else
				identifierType = 294
			elseif bytes == 0x6e656874 then -- then
				identifierType = 308
			elseif bytes == 0x65757274 then -- true
				identifierType = 309
			end
		elseif identifierLength == 5 then
			local firstBytes = buffer.readu32(buff, start_ptr)
			local fifthByte = buffer.readu8(buff, start_ptr + 4)
			if firstBytes == 0x61657262 and fifthByte == 107 then -- break
				identifierType = 292
			elseif firstBytes == 0x736c6166 and fifthByte == 101 then -- false
				identifierType = 297
			elseif firstBytes == 0x61636f6c and fifthByte == 108 then -- local
				identifierType = 302
			elseif firstBytes == 0x69746e75 and fifthByte == 108 then -- until
				identifierType = 310
			elseif firstBytes == 0x6c696877 and fifthByte == 101 then -- while
				identifierType = 311
			end
		elseif identifierLength == 6 then
			local firstBytes = buffer.readu32(buff, start_ptr)
			local lastBytes = buffer.readu16(buff, start_ptr + 4)
			if firstBytes == 0x65736c65 and lastBytes == 0x6669 then -- elseif
				identifierType = 295
			elseif firstBytes == 0x65706572 and lastBytes == 0x7461 then -- repeat
				identifierType = 306
			elseif firstBytes == 0x75746572 and lastBytes == 0x6e72 then -- return
				identifierType = 307
			end
		elseif
			identifierLength == 8
			and buffer.readu32(buff, start_ptr) == 0x636e7566
			and buffer.readu32(buff, start_ptr + 4) == 0x6e6f6974
		then -- function
			identifierType = 299
		end

		H.next_type = identifierType
		if identifierType == 281 then
			H.next_string = buffer.readstring(buff, start_ptr, ptr - start_ptr)
		end
		-- Numbers (0-9)
	elseif characterType == 2 then
		while ptr < sourceSize do
			local numberChar = buffer.readu8(buff, ptr)
			local numberCharacterType = buffer.readu8(IdentifierCharactersLookup, numberChar)

			if numberCharacterType == 2 or numberChar == 46 or numberChar == 95 then
				ptr =ptr+ 1
			elseif numberChar == 101 or numberChar == 69 then -- e / E
				ptr =ptr+ 1

				if ptr < sourceSize then
					local exp_ch = buffer.readu8(buff, ptr)
					if exp_ch == 43 or exp_ch == 45 then -- + / -
						ptr =ptr+ 1
					end
				end
			else
				break
			end
		end

		while ptr < sourceSize do
			local suffixChar = buffer.readu8(buff, ptr)

			if buffer.readu8(IdentifierCharactersLookup, suffixChar) ~= 0 then
				ptr =ptr+ 1
			else
				break
			end
		end
		
		H.next_type = 280 -- Number
		H.next_string = buffer.readstring(buff, start_ptr, ptr - start_ptr)

		-- Strings (" or ')
	elseif ch == 34 or ch == 39 then -- " or '
		local delim = ch
		local content_start = ptr

		while ptr < sourceSize do
			local c = buffer.readu8(buff, ptr)
			if c == delim then
				break
			elseif c == 92 then -- \
				ptr =ptr+ 1
				if ptr < sourceSize then
					local esc = buffer.readu8(buff, ptr)
					if esc == 10 then -- \n
						cur_line =cur_line+ 1
						cur_line_offset = ptr + 1
					elseif esc == 13 then -- \r
						if ptr + 1 < sourceSize and buffer.readu8(buff, ptr + 1) == 10 then
							cur_line =cur_line+ 1
							ptr =ptr+ 1
							cur_line_offset = ptr + 1
						end
					elseif esc == 122 then -- z
						ptr =ptr+ 1
						while ptr < sourceSize do
							local wc = buffer.readu8(buff, ptr)
							if wc == 32 or wc == 9 or wc == 10 or wc == 13 or wc == 11 or wc == 12 then
								if wc == 10 then
									cur_line =cur_line+ 1
									cur_line_offset = ptr + 1
								elseif wc == 13 then
									if ptr + 1 < sourceSize and buffer.readu8(buff, ptr + 1) == 10 then
										ptr =ptr+ 1
										cur_line =cur_line+ 1
										cur_line_offset = ptr + 1
									end
								end
								ptr =ptr+ 1
							else
								ptr =ptr- 1
								break
							end
						end
					end
				end
			elseif c == 10 or c == 13 then -- \n / \r
				H.next_type = 286 -- BrokenString
				break
			end
			ptr =ptr+ 1
		end

		if H.next_type == 286 then -- BrokenString
			-- handled
		elseif ptr >= sourceSize then
			H.next_type = 286 -- BrokenString
		else
			H.next_type = 279 -- QuotedString
			H.next_string = buffer.readstring(buff, content_start, ptr - content_start)
			H.next_aux = delim == 39 and 0 or 1
			ptr =ptr+ 1 -- consume closing delim
		end

		-- Operators & Punctuation
	elseif buffer.readu16(SimpleTokensLookup, ch * 2) ~= 0 then
		local directToken = buffer.readu16(SimpleTokensLookup, ch * 2)
		if directToken > 255 and ptr < sourceSize and buffer.readu8(buff, ptr) == 61 then
			ptr =ptr+ 1
			H.next_type = directToken
		else
			H.next_type = ch
		end
	elseif ch == 45 then -- '-'
		local next_ch = (ptr < sourceSize and{(buffer.readu8(buff, ptr) )}or{0
})[1]		if next_ch == 62 then -- ->
			ptr =ptr+ 1
			H.next_type = 263 -- SkinnyArrow
		elseif next_ch == 61 then -- -=
			ptr =ptr+ 1
			H.next_type = 271 -- SubAssign
		elseif next_ch == 45 then -- -- Comment
			ptr =ptr+ 1
			local comment_start = ptr

			-- Block Comment --[
			local is_block = false
			if ptr < sourceSize and buffer.readu8(buff, ptr) == 91 then
				local sep_start = ptr
				ptr =ptr+ 1
				local count = 0
				while ptr < sourceSize and buffer.readu8(buff, ptr) == 61 do
					ptr =ptr+ 1
					count =count+ 1
				end

				if ptr < sourceSize and buffer.readu8(buff, ptr) == 91 then
					-- Found long comment
					is_block = true
					ptr =ptr+ 1
					local found_end = false

					while ptr < sourceSize do
						local c = buffer.readu8(buff, ptr)
						if c == 93 then -- ]
							local c2_idx = ptr + 1
							local close_count = 0
							while c2_idx < sourceSize and buffer.readu8(buff, c2_idx) == 61 do
								c2_idx =c2_idx+ 1
								close_count =close_count+ 1
							end
							if close_count == count and c2_idx < sourceSize and buffer.readu8(buff, c2_idx) == 93 then
								ptr = c2_idx + 1
								found_end = true
								break
							end
						elseif c == 10 then -- \n
							cur_line =cur_line+ 1
							cur_line_offset = ptr + 1
						end
						ptr =ptr+ 1
					end

					if not found_end then
						H.next_type = 287 -- BrokenComment
					else
						H.next_type = 283 -- BlockComment
					end
				else
					-- Not a block comment
					ptr = sep_start -- Backtrack
				end
			end

			if not is_block then
				-- Line Comment
				while ptr < sourceSize do
					local c = buffer.readu8(buff, ptr)
					if c == 10 or c == 13 then
						break
					end -- \n or \r
					ptr =ptr+ 1
				end
				H.next_type = 282 -- Comment
			end

			if
				not skip_comments
				or (
					H.next_type == 282
					and comment_start < ptr
					and buffer.readu8(buff, comment_start) == 33
				)
			then
				H.next_string = buffer.readstring(buff, comment_start, ptr - comment_start)
			end
		else
			H.next_type = 45 -- '-'
		end
	elseif ch == 46 then -- '.'
		local next_ch = (ptr < sourceSize and{(buffer.readu8(buff, ptr) )}or{0
})[1]		if next_ch == 46 then -- ..
			ptr =ptr+ 1
			local third_ch = (ptr < sourceSize and{(buffer.readu8(buff, ptr) )}or{0
})[1]			if third_ch == 46 then -- ...
				ptr =ptr+ 1
				H.next_type = 262 -- Dot3
			elseif third_ch == 61 then -- ..=
				ptr =ptr+ 1
				H.next_type = 277 -- ConcatAssign
			else
				H.next_type = 261 -- Dot2
			end
		else
			if buffer.readu8(IdentifierCharactersLookup, next_ch) == 2 then
				ptr =ptr- 1 -- Backtrack
				local n_start = ptr
				while ptr < sourceSize do
					local numberChar = buffer.readu8(buff, ptr)
					local numberCharacterType = buffer.readu8(IdentifierCharactersLookup, numberChar)

					if numberCharacterType == 2 or numberChar == 46 or numberChar == 95 then
						ptr =ptr+ 1
					elseif numberChar == 101 or numberChar == 69 then -- e / E
						ptr =ptr+ 1

						if ptr < sourceSize then
							local exp_ch = buffer.readu8(buff, ptr)
							if exp_ch == 43 or exp_ch == 45 then -- + / -
								ptr =ptr+ 1
							end
						end
					else
						break
					end
				end

				while ptr < sourceSize do
					local suffixChar = buffer.readu8(buff, ptr)

					if buffer.readu8(IdentifierCharactersLookup, suffixChar) ~= 0 then
						ptr =ptr+ 1
					else
						break
					end
				end
				
				H.next_type = 280 -- Number
				H.next_string = buffer.readstring(buff, n_start, ptr - n_start)
			else
				H.next_type = 46 -- '.'
			end
		end
	elseif ch == 47 then -- '/'
		local next_ch = (ptr < sourceSize and{(buffer.readu8(buff, ptr) )}or{0
})[1]		if next_ch == 61 then
			ptr =ptr+ 1
			H.next_type = 273 -- DivAssign
		elseif next_ch == 47 then
			ptr =ptr+ 1
			if ptr < sourceSize and buffer.readu8(buff, ptr) == 61 then
				ptr =ptr+ 1
				H.next_type = 274 -- FloorDivAssign
			else
				H.next_type = 265 -- FloorDiv
			end
		else
			H.next_type = 47
		end
	elseif ch == 58 then -- ':'
		if ptr < sourceSize and buffer.readu8(buff, ptr) == 58 then
			ptr =ptr+ 1
			H.next_type = 264 -- DoubleColon
		else
			H.next_type = 58
		end

		-- Single Char / Interp
	elseif
		ch == 123
		or ch == 125
	then
		if ch == 123 then
			if H.braceStackSize > 0 then
				H.braceStackSize =H.braceStackSize+ 1
				H.braceStack[H.braceStackSize] = H.BraceType.Normal
			end
			H.next_type = ch
		elseif ch == 125 then
			if H.braceStackSize == 0 then
				H.next_type = ch
			else
				local top = H.braceStack[H.braceStackSize]
				H.braceStack[H.braceStackSize] = nil
				H.braceStackSize =H.braceStackSize- 1
				if top ~= H.BraceType.InterpolatedString then
					H.next_type = ch
				else
					local sectionStart = ptr
					local sectionDone = false

					while ptr < sourceSize do
						local c = buffer.readu8(buff, ptr)

						if c == 96 then -- `
							H.next_type = 268 -- InterpStringEnd
							H.next_string = buffer.readstring(buff, sectionStart, ptr - sectionStart)
							ptr =ptr+ 1
							sectionDone = true
							break
						elseif c == 13 or c == 10 then -- \r / \n
							H.next_type = 286 -- BrokenString
							sectionDone = true
							break
						elseif c == 92 then -- \
							-- Allow \u{...} without treating '{' as interpolation start.
							if
								ptr + 2 < sourceSize
								and buffer.readu8(buff, ptr + 1) == 117
								and buffer.readu8(buff, ptr + 2) == 123
							then
								ptr =ptr+ 3
							else
								ptr =ptr+ 1 -- consume '\'

								if ptr < sourceSize then
									local esc = buffer.readu8(buff, ptr)

									if esc == 13 then -- \r
										if ptr + 1 < sourceSize and buffer.readu8(buff, ptr + 1) == 10 then
											cur_line =cur_line+ 1
											ptr =ptr+ 1
											cur_line_offset = ptr + 1
										end
									elseif esc == 122 then -- z
										ptr =ptr+ 1
										while ptr < sourceSize do
											local wc = buffer.readu8(buff, ptr)
											if
												wc ~= 32
												and wc ~= 9
												and wc ~= 13
												and wc ~= 10
												and wc ~= 11
												and wc ~= 12
											then
												break
											end

											if wc == 10 then
												cur_line =cur_line+ 1
												cur_line_offset = ptr + 1
											elseif
												wc == 13
												and ptr + 1 < sourceSize
												and buffer.readu8(buff, ptr + 1) == 10
											then
												ptr =ptr+ 1
												cur_line =cur_line+ 1
												cur_line_offset = ptr + 1
											end

											ptr =ptr+ 1
										end
									elseif esc == 10 then -- \n
										cur_line =cur_line+ 1
										cur_line_offset = ptr + 1
										ptr =ptr+ 1
									else
										ptr =ptr+ 1
									end
								end
							end
						elseif c == 123 then -- {
							H.braceStackSize =H.braceStackSize+ 1
							H.braceStack[H.braceStackSize] = H.BraceType.InterpolatedString

							if ptr + 1 < sourceSize and buffer.readu8(buff, ptr + 1) == 123 then
								H.next_type = 289 -- BrokenInterpDoubleBrace
								H.next_string = buffer.readstring(buff, sectionStart, ptr - sectionStart)
								ptr =ptr+ 2
								sectionDone = true
								break
							end

							H.next_type = 267 -- InterpStringMid
							H.next_string = buffer.readstring(buff, sectionStart, ptr - sectionStart)
							ptr =ptr+ 1
							sectionDone = true
							break
						else
							ptr =ptr+ 1
						end
					end

					if not sectionDone then
						H.next_type = 286 -- BrokenString
					end
				end
			end
		else
			H.next_type = ch
		end
	elseif ch == 96 then -- `
		local sectionStart = ptr
		local sectionDone = false

		while ptr < sourceSize do
			local c = buffer.readu8(buff, ptr)

			if c == 96 then -- `
				H.next_type = 269 -- InterpStringSimple
				H.next_string = buffer.readstring(buff, sectionStart, ptr - sectionStart)
				ptr =ptr+ 1
				sectionDone = true
				break
			elseif c == 13 or c == 10 then -- \r / \n
				H.next_type = 286 -- BrokenString
				sectionDone = true
				break
			elseif c == 92 then -- \
				-- Allow \u{...} without treating '{' as interpolation start.
				if ptr + 2 < sourceSize and buffer.readu8(buff, ptr + 1) == 117 and buffer.readu8(buff, ptr + 2) == 123 then
					ptr =ptr+ 3
				else
					ptr =ptr+ 1 -- consume '\'
					if ptr < sourceSize then
						local esc = buffer.readu8(buff, ptr)

						if esc == 13 then -- \r
							if ptr + 1 < sourceSize and buffer.readu8(buff, ptr + 1) == 10 then
								cur_line =cur_line+ 1
								ptr =ptr+ 1
								cur_line_offset = ptr + 1
							end
						elseif esc == 122 then -- z
							ptr =ptr+ 1
							while ptr < sourceSize do
								local wc = buffer.readu8(buff, ptr)
								if wc ~= 32 and wc ~= 9 and wc ~= 13 and wc ~= 10 and wc ~= 11 and wc ~= 12 then
									break
								end

								if wc == 10 then
									cur_line =cur_line+ 1
									cur_line_offset = ptr + 1
								elseif wc == 13 and ptr + 1 < sourceSize and buffer.readu8(buff, ptr + 1) == 10 then
									ptr =ptr+ 1
									cur_line =cur_line+ 1
									cur_line_offset = ptr + 1
								end

								ptr =ptr+ 1
							end
						elseif esc == 10 then -- \n
							cur_line =cur_line+ 1
							cur_line_offset = ptr + 1
							ptr =ptr+ 1
						else
							ptr =ptr+ 1
						end
					end
				end
			elseif c == 123 then -- {
				H.braceStackSize =H.braceStackSize+ 1
				H.braceStack[H.braceStackSize] = H.BraceType.InterpolatedString

				if ptr + 1 < sourceSize and buffer.readu8(buff, ptr + 1) == 123 then
					H.next_type = 289 -- BrokenInterpDoubleBrace
					H.next_string = buffer.readstring(buff, sectionStart, ptr - sectionStart)
					ptr =ptr+ 2
					sectionDone = true
					break
				end

				H.next_type = 266 -- InterpStringBegin
				H.next_string = buffer.readstring(buff, sectionStart, ptr - sectionStart)
				ptr =ptr+ 1
				sectionDone = true
				break
			else
				ptr =ptr+ 1
			end
		end

		if not sectionDone then
			H.next_type = 286 -- BrokenString
		end
	elseif ch == 91 then -- [
		local count = 0
		while ptr < sourceSize and buffer.readu8(buff, ptr) == 61 do
			ptr =ptr+ 1
			count =count+ 1
		end

		if ptr < sourceSize and buffer.readu8(buff, ptr) == 91 then
			ptr =ptr+ 1
			-- Long String
			local ls_start = ptr
			local found = false

			while ptr < sourceSize do
				if buffer.readu8(buff, ptr) == 93 then
					local c2 = ptr + 1
					local cc = 0

					while c2 < sourceSize and buffer.readu8(buff, c2) == 61 do
						c2 =c2+ 1
						cc =cc+ 1
					end

					if cc == count and c2 < sourceSize and buffer.readu8(buff, c2) == 93 then
						H.next_type = 278 -- RawString
						H.next_string = buffer.readstring(buff, ls_start, ptr - ls_start)
						ptr = c2 + 1
						H.next_aux = count
						found = true
						break
					end
				elseif buffer.readu8(buff, ptr) == 10 then
					cur_line =cur_line+ 1
					cur_line_offset = ptr + 1
				end
				ptr =ptr+ 1
			end
			if not found then
				H.next_type = 286 -- BrokenString
			end
		elseif count == 0 then
			H.next_type = 91 -- [
		else
			H.next_type = 286 -- BrokenString
		end
	elseif ch == 64 then -- @
		if ptr < sourceSize and buffer.readu8(buff, ptr) == 91 then
			ptr =ptr+ 1
			H.next_type = 285 -- AttributeOpen
		else
			H.next_type = 284 -- Attribute
			if ptr < sourceSize then
				local first = buffer.readu8(buff, ptr)
				if buffer.readu8(IdentifierCharactersLookup, first) == 1 then
					local name_start = ptr
					ptr =ptr+ 1
					while ptr < sourceSize do
						local c = buffer.readu8(buff, ptr)
						if buffer.readu8(IdentifierCharactersLookup, c) ~= 0 then
							ptr =ptr+ 1
						else
							break
						end
					end
					H.next_string = buffer.readstring(buff, name_start, ptr - name_start)
				else
					H.next_string = ""
				end
			else
				H.next_string = ""
			end
		end
	else
		if bit32.btest(ch, 0x80) then
			local cp = 0
			local seq_len = 0
			if bit32.band(ch, 0xE0) == 0xC0 then
				seq_len = 1
				cp = bit32.band(ch, 0x1F)
			elseif bit32.band(ch, 0xF0) == 0xE0 then
				seq_len = 2
				cp = bit32.band(ch, 0x0F)
			elseif bit32.band(ch, 0xF8) == 0xF0 then
				seq_len = 3
				cp = bit32.band(ch, 0x07)
			else
				H.next_type = 288 -- BrokenUnicode
				seq_len = -1 -- signal fail
			end

			if seq_len ~= -1 then
				local ok = true
				for i = 1, seq_len do
					if ptr >= sourceSize then
						ok = false
						break
					end

					local c = buffer.readu8(buff, ptr)
					if bit32.band(c, 0xC0) ~= 0x80 then
						ok = false
						break
					end

					cp = bit32.lshift(cp, 6) + bit32.band(c, 0x3F)
					ptr =ptr+ 1
				end

				if ok then
					H.next_type = 288 -- BrokenUnicode
					H.next_codepoint = cp
				else
					H.next_type = 288 -- BrokenUnicode
				end
			end
		else
			H.next_type = ch
		end
	end

	-- Sync State
	H.offset = ptr
	H.line = cur_line
	H.lineOffset = cur_line_offset
	H.next_end_line = cur_line
	H.next_end_col = ptr - cur_line_offset
end

-- // Parser Interface
H.fillNext = function ()
	while true do
local __DARKLUA_CONTINUE_38=false repeat		H.lex(not H.captureComments) -- writes to next_*

		if H.next_type == 282 or H.next_type == 283 or H.next_type == 287 then -- Comment / BlockComment / BrokenComment
			if H.captureComments then
				if H.commentLocations == H.EmptyArray then
					H.commentLocations = {}
				end
				table.insert(H.commentLocations, {
					type = H.next_type,
					location = {
						begin = vector.create(H.next_start_line, H.next_start_col),
						end_ = vector.create(H.next_end_line, H.next_end_col),
					},
				})
			end

			if H.next_type == 282 and H.next_string and string.byte(H.next_string , 1) == 33 then -- Comment and '!'
				if H.hotcomments == H.EmptyArray then
					H.hotcomments = {}
				end
				local text = H.next_string 				
local ending = #text

				while ending > 0 do
					local byte = string.byte(text, ending)
					if byte and H.Spaces[byte] then
						ending =ending- 1
					else
						break
					end
				end

				table.insert(
					H.hotcomments,
					{
						header = H.hotcommentHeader,
						location = {
							begin = vector.create(H.next_start_line, H.next_start_col),
							end_ = vector.create(H.next_end_line, H.next_end_col),
						},
						content = string.sub(text, 2, ending),
					} 				
)
			end

			if H.next_type == 287 then return end -- BrokenComment
__DARKLUA_CONTINUE_38=true			break
		end

		break
until true if not __DARKLUA_CONTINUE_38 then break end	end
end

H.nextLexeme = function ()
	-- Save previous current to prev
	H.prev_start_line = H.token_start_line
	H.prev_start_col = H.token_start_col
	H.prev_end_line = H.token_end_line
	H.prev_end_col = H.token_end_col

	-- Move NEXT to CURRENT
	H.token_type = H.next_type
	H.token_start_line = H.next_start_line
	H.token_start_col = H.next_start_col
	H.token_end_line = H.next_end_line
	H.token_end_col = H.next_end_col
	H.token_string = H.next_string
	H.token_aux = H.next_aux
	H.token_codepoint = H.next_codepoint

	-- Refill NEXT
	H.fillNext()
end

-- // Parser Commons

H.snapshot = function ()	
return {
		begin = vector.create(H.token_start_line, H.token_start_col),
		end_ = vector.create(H.token_end_line, H.token_end_col),
	}
end

H.getprev = function ()	
return {
		begin = vector.create(H.prev_start_line, H.prev_start_col),
		end_ = vector.create(H.prev_end_line, H.prev_end_col),
	}
end

-- // Error reports

H.positionsEqual = function (a, b)	
return a.x == b.x and a.y == b.y
end

H.locationsEqual = function (a, b)	
return H.positionsEqual(a.begin, b.begin) and H.positionsEqual(a.end_, b.end_)
end

H.report = function (loc, fmt, ...)
	if #H.parseErrors > 0 and H.locationsEqual(H.parseErrors[#H.parseErrors].location, loc) then
		return
	end

	local msg = string.format(fmt, ...)
	if H.parseErrors == H.EmptyArray then
		H.parseErrors = {}
	end
	table.insert(H.parseErrors, { location = loc, message = msg })

	if H.LuauParseErrorLimit == 1 then
		error(msg, 0)
	end

	if #H.parseErrors >= H.LuauParseErrorLimit and not H.options.noErrorLimit then
		error(string.format('Reached error limit (%s)', tostring(H.LuauParseErrorLimit)), 0)
	end
end

H.expectAndConsumeFail = function (type_, context)
	local typeString = H.ToString(type_)
	local lexString = H.ToString(H.token_type, H.token_string, H.token_codepoint)

	if context then
		H.report(H.snapshot(), "Expected %s when parsing %s, got %s", typeString, context, lexString)
	else
		H.report(H.snapshot(), "Expected %s, got %s", typeString, lexString)
	end
end

H.expectMatchAndConsumeFail = function (
	type_,
	begin_type,
	line,
	column,
	extra
)
	local typeString = H.ToString(type_)
	local matchString = H.ToString(begin_type)
	local currString = H.ToString(H.token_type, H.token_string, H.token_codepoint)

	if H.token_start_line == line then
		H.report(
			H.snapshot(),
			"Expected %s (to close %s at column %d), got %s%s",
			typeString,
			matchString,
			column + 1,
			currString,
			extra or ""
		)
	else
		H.report(
			H.snapshot(),
			"Expected %s (to close %s at line %d), got %s%s",
			typeString,
			matchString,
			line + 1,
			currString,
			extra or ""
		)
	end
end

H.expectAndConsume = function (type_, context)	
if H.token_type ~= type_ then
		H.expectAndConsumeFail(type_, context)

		if H.next_type == type_ then
			H.nextLexeme()
			H.nextLexeme()
		end

		return false
	end

	H.nextLexeme()
	return true
end

H.expectMatchAndConsume = function (
	value,
	begin_type,
	line,
	column,
	searchForMissing
)	
if H.token_type ~= value then
		H.expectMatchAndConsumeFail(value, begin_type, line, column)

		if searchForMissing then
			local currentLine = H.prev_end_line
			local type_ = H.token_type

			while currentLine == H.token_start_line and type_ ~= value and H.matchRecovery[type_] == 0 do
				H.nextLexeme()
				type_ = H.token_type
			end

			if type_ == value then
				H.nextLexeme()
				return true
			end
		else
			if H.next_type == value then
				H.nextLexeme()
				H.nextLexeme()
				return true
			end
		end

		return false
	end

	H.nextLexeme()
	return true
end

H.expectMatchEndAndConsume = function (type_, begin_type, line, column)	
if H.token_type ~= type_ then
		if H.suspect_type ~= 0 and H.suspect_line > line then
			H.expectMatchAndConsumeFail(type_, begin_type, line, column,
				string.format(
				"; did you forget to close %s at line %d?",
				H.ToString(H.suspect_type, H.token_string, H.token_codepoint),
				H.suspect_line + 1
				)
			)
		else
			H.expectMatchAndConsumeFail(type_, begin_type, line, column)
		end

		if H.next_type == type_ then
			H.nextLexeme()
			H.nextLexeme()
			return true
		end

		return false
	end

	if H.token_start_line ~= line and H.token_start_col ~= column and H.suspect_line < line then
		H.suspect_line = line
		H.suspect_type = begin_type
	end

	H.nextLexeme()
	return true
end

-- // Ast reports

H.reportStatError = function (
	location,
	exprs,
	stats,
	fmt,
	...
)	
H.report(location, fmt, ...)

	return {
		kind = "StatError",
		location = location,
		expressions = exprs,
		statements = stats,
		messageIndex = #H.parseErrors,
	}
end

H.reportExprError = function (
	location,
	exprs,
	fmt,
	...
)	
H.report(location, fmt, ...)

	return {
		kind = "ExprError",
		location = location,
		expressions = exprs,
		messageIndex = #H.parseErrors,
	}
end

H.reportTypeError = function (
	location,
	types,
	fmt,
	...
)	
H.report(location, fmt, ...)

	return {
		kind = "TypeError",
		location = location,
		types = types,
		isMissing = false,
		messageIndex = #H.parseErrors,
	}
end

H.reportMissingTypeError = function (
	parseErrorLocation,
	astErrorLocation,
	fmt,
	...
)	
H.report(parseErrorLocation, fmt, ...)

	return {
		kind = "TypeError",
		location = astErrorLocation,
		types = H.EmptyArray ,
		isMissing = true,
		messageIndex = #H.parseErrors,
	}
end

H.reportNameError = function (context)
	local currString = H.ToString(H.token_type, H.token_string, H.token_codepoint)
	if context then
		H.report(H.snapshot(), "Expected identifier when parsing %s, got %s", context, currString)
	else
		H.report(H.snapshot(), "Expected identifier, got %s", currString)
	end
end

-- // Locals Helpers

H.restoreLocals = function (offset)
	for i = #H.localStack, offset + 1, -1 do
		local l = H.localStack[i] 		
H.localMap[l.name] = l.shadow
	end

	for i = #H.localStack, offset + 1, -1 do
		H.localStack[i] = nil
	end
end

H.pushLocal = function (binding)	
local name = binding.name.value
	local shadow = H.localMap[name]

	local local_ = {
		name = name,
		location = binding.location,
		shadow = shadow,
		functionDepth = #H.functionStack - 1,
		loopDepth = H.functionStack[#H.functionStack].loopDepth,
		annotation = binding.annotation,
		isConst = binding.isConst == true,
		isExported = false,
	} 
	
H.localMap[name] = local_
	table.insert(H.localStack, local_)

	return local_
end

H.incrementRecursionCounter = function (context)
	H.recursionCounter =H.recursionCounter+ 1

	if H.recursionCounter > 1000 then
		local msg = string.format([[Exceeded allowed recursion depth; simplify your %s to make the code compile]], tostring(context))		
H.report(H.snapshot(), "%s", msg)
		error(msg, 0)
	end
end

H.isExprLValue = function (expr)	
if expr.kind == "ExprLocal" then
		local local_ = expr["local"]
		return local_.isConst ~= true
	end

	return H.ExprLValues[expr.kind] == true
end

H.reportLValueError = function (expr)	
if expr.kind == "ExprLocal" and expr["local"].isConst == true then
		return H.reportExprError(
			expr.location,
			{ expr },
			"Variable '%s' is constant and may not be reassigned",
			expr["local"].name
		)
	end

	return H.reportExprError(expr.location, { expr }, "Assigned expression must be a variable or a field")
end

-- // The core of the code

 H.typeFunctionDepth = 0








 H.ParserFunctions = {} 

H.parseNameScalars = function (context)	
if H.token_type ~= 281 then
		H.reportNameError(context)
		return nil, H.token_start_line, H.token_start_col, H.token_end_line, H.token_end_col
	end

	local name = H.token_string 	
local startLine, startColumn = H.token_start_line, H.token_start_col
	local endLine, endColumn = H.token_end_line, H.token_end_col

	H.nextLexeme()
	return name, startLine, startColumn, endLine, endColumn
end

H.parseNameOptImpl = function (context)	
local name, startLine, startColumn, endLine, endColumn = H.parseNameScalars(context)
	if not name then
		return nil
	end

	local result = {
		name = { value = name },
		location = {
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(endLine, endColumn),
		},
	} 
	
return result
end

-- Type ::=
--      nil |
--      Name[`.' Name] [`<' namelist `>'] |
--      `{' [PropList] `}' |
--      `(' [TypeList] `)' `->` ReturnType
--      `typeof` Type
H.parseTypeSuffixImpl = function (type_, beginLine, beginColumn)	
local parts = {} 	
if type_ then
		table.insert(parts, type_)
	end

	H.incrementRecursionCounter("type annotation")

	local isUnion = false
	local isIntersection = false
	local optionalCount = 0

	local separatorPositions= H.storeCstData and{} or nil
	local leadingPosition= nil

	while true do
		local t = H.token_type
		local separatorLine, separatorColumn = H.token_start_line, H.token_start_col

		if t == 124 then
			H.nextLexeme()

			local oldRecursion = H.recursionCounter

			local typePart, _ = H.ParserFunctions.parseSimpleType(false, false)
			if typePart then
				table.insert(parts, typePart)
			end

			H.recursionCounter = oldRecursion

			isUnion = true

			if separatorPositions then
				local separatorPosition = vector.create(separatorLine, separatorColumn)
				if type_ == nil and not leadingPosition then
					leadingPosition = separatorPosition
				else
					table.insert(separatorPositions, separatorPosition)
				end
			end
		elseif t == 63 then
			local loc = H.snapshot()
			H.nextLexeme()

			table.insert(parts, { kind = "TypeOptional", location = loc } )

			optionalCount =optionalCount+ 1
			isUnion = true
		elseif t == 38 then
			H.nextLexeme()

			local oldRecursion = H.recursionCounter

			local typePart, _ = H.ParserFunctions.parseSimpleType(false, false)
			if typePart then
				table.insert(parts, typePart)
			end

			H.recursionCounter = oldRecursion

			isIntersection = true

			if separatorPositions then
				local separatorPosition = vector.create(separatorLine, separatorColumn)
				if type_ == nil and not leadingPosition then
					leadingPosition = separatorPosition
				else
					table.insert(separatorPositions, separatorPosition)
				end
			end
		elseif t == 262 then
			H.report(H.snapshot(), "Unexpected '...' after type annotation")
			H.nextLexeme()
		else
			break
		end

		if #parts > 1000 + optionalCount then
			local msg = "Exceeded allowed type length; simplify your type annotation to make the code compile"
			H.report(parts[#parts].location, "%s", msg)
			error(msg, 0)
		end
	end

	if #parts == 1 and not isUnion and not isIntersection then
		return parts[1]
	end

	if isUnion and isIntersection then
		return H.reportTypeError(
			{
				begin = vector.create(beginLine, beginColumn),
				end_ = parts[#parts].location.end_,
			},
			parts,
			"Mixing union and intersection types is not allowed; consider wrapping in parentheses."
		)
	end

	local loc = {
		begin = vector.create(beginLine, beginColumn),
		end_ = parts[#parts].location.end_,
	}

	if isUnion then
		local node = { kind = "TypeUnion", location = loc, types = parts } 		
if separatorPositions then
			node.cstNode = {
				kind = "CstTypeUnion",
				leadingPosition = leadingPosition,
				separatorPositions = separatorPositions,
			}
		end
		return node
	end

	if isIntersection then
		local node = { kind = "TypeIntersection", location = loc, types = parts } 		
if separatorPositions then
			node.cstNode = {
				kind = "CstTypeIntersection",
				leadingPosition = leadingPosition,
				separatorPositions = separatorPositions,
			}
		end
		return node
	end

	return parts[1]
end

H.parseTypeImpl = function (inDeclarationContext)	
local oldRec = H.recursionCounter
	-- recursion counter is incremented in parseSimpleType and/or parseTypeSuffix

	local beginLine, beginColumn = H.token_start_line, H.token_start_col

	local type_= nil

	if H.token_type ~= 124 and H.token_type ~= 38 then
		type_ = H.ParserFunctions.parseSimpleType(false, inDeclarationContext or false)
		H.recursionCounter = oldRec
	end

	local typeWithSuffix = H.parseTypeSuffixImpl(type_, beginLine, beginColumn)
	H.recursionCounter = oldRec

	return typeWithSuffix
end

H.parseOptionalTypeImpl = function ()	
if H.token_type == 58 then
		H.nextLexeme()
		return H.parseTypeImpl(false)
	else
		return nil
	end
end
H.parseBinding = function (isConst)	
local name, startLine, startColumn, endLine, endColumn = H.parseNameScalars("variable name")
	name = name or "%error-id%"

	local colonPos = (H.storeCstData and H.token_type == 58 and{(vector.create(H.token_start_line, H.token_start_col) )}or{nil
})[1]	local annotation = H.parseOptionalTypeImpl()

	return {
		name = { value = name },
		location = {
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(endLine, endColumn),
		},
		annotation = annotation,
		colonPosition = colonPos,
		isConst = isConst == true,
	} 
end

H.parseVariadicArgumentTypePackImpl = function ()	-- Generic: a...
	
if H.token_type == 281 and H.next_type == 262 then
		local name, startLine, startColumn = H.parseNameScalars("generic name")
		local endStartLine, endStartColumn = H.token_start_line, H.token_start_col
		local endLine, endColumn = H.token_end_line, H.token_end_col

		-- This will not fail because of the lookahead guard.
		H.expectAndConsume(262, "generic type pack annotation")

		local node = {
			kind = "TypePackGeneric",
			location = {
				begin = vector.create(startLine, startColumn),
				end_ = vector.create(endLine, endColumn),
			},
			genericName = name ,
		} 
		
if H.storeCstData then
			node.cstNode = {
				kind = "CstTypePackGeneric",
				ellipsisPosition = vector.create(endStartLine, endStartColumn),
			}
		end

		return node
	else -- Variadic: T
		local varTy = H.parseTypeImpl(false)

		return {
			kind = "TypePackVariadic",
			location = varTy.location,
			variadicType = varTy,
		}
	end
end

-- bindinglist ::= (binding | `...') [`,' bindinglist]
H.parseBindingList = function (
	result,
	allowDot3,
	commaPositions,
	initialComma,
	varargAnnotColonPos,
	isConst
)	
local localCommaPositions= commaPositions and{} or nil

	if localCommaPositions and initialComma then
		table.insert(localCommaPositions, initialComma)
	end

	while true do
		if H.token_type == 262 and allowDot3 then
			local varargLocation = H.snapshot()
			H.nextLexeme()

			local tailAnnotation= nil
			if H.token_type == 58 then
				if varargAnnotColonPos then
					varargAnnotColonPos[1] = vector.create(H.token_start_line, H.token_start_col)
				end

				H.nextLexeme()
				tailAnnotation = H.parseVariadicArgumentTypePackImpl()
			end

			if commaPositions and localCommaPositions then
				for _, v in ipairs(localCommaPositions) do
					table.insert(commaPositions, v)
				end
			end

			return true, varargLocation, tailAnnotation
		end

		table.insert(result, H.parseBinding(isConst))

		if H.token_type ~= 44 then
			break
		end

		if localCommaPositions then
			table.insert(localCommaPositions, vector.create(H.token_start_line, H.token_start_col))
		end

		H.nextLexeme()
	end

	if commaPositions and localCommaPositions then
		for _, v in ipairs(localCommaPositions) do
			table.insert(commaPositions, v)
		end
	end

	return false, nil, nil
end

H.parseBlockNoScope = function ()	
local body= {}

	local prevPos = vector.create(H.prev_end_line, H.prev_end_col)

	while not H.BlockFollow[H.token_type] do
		local oldRecursion = H.recursionCounter
		H.incrementRecursionCounter("block")

		local stat = H.ParserFunctions.parseStat()

		H.recursionCounter = oldRecursion

		if H.token_type == 59 then
			H.nextLexeme()
			stat.hasSemicolon = true

			stat.location.end_ = vector.create(H.prev_end_line, H.prev_end_col)
		end

		table.insert(body, stat)

		if stat.kind == "StatBreak" or stat.kind == "StatContinue" or stat.kind == "StatReturn" then
			break
		end
	end

	return {
		kind = "StatBlock",
		location = {
			begin = prevPos,
			end_ = vector.create(H.token_start_line, H.token_start_col),
		},
		body = body,
		hasEnd = false,
	} 
end

-- chunk ::= {stat [`;']} [laststat [`;']]
-- block ::= chunk
H.parseBlock = function ()	
local localsBegin = #H.localStack
	local result = H.parseBlockNoScope()
	H.restoreLocals(localsBegin)
	return result
end

-- if exp then block {elseif exp then block} [else block] end
H.parseIfImpl = function ()	
local startLine, startColumn = H.token_start_line, H.token_start_col

	H.nextLexeme()

	local cond = H.ParserFunctions.parseExpr()

	local Then_start_line, Then_start_col = H.token_start_line, H.token_start_col
	local Then_end_line, Then_end_col = H.token_end_line, H.token_end_col

	local thenLocation= nil
	if H.expectAndConsume(308, "if statement") then
		thenLocation = {
			begin = vector.create(Then_start_line, Then_start_col),
			end_ = vector.create(Then_end_line, Then_end_col),
		}
	end

	local thenbody = H.parseBlock()

	local elsebody= nil
	local endLine, endColumn = H.token_end_line, H.token_end_col
	local elseLocation= nil

	if H.token_type == 295 then
		thenbody.hasEnd = true
		local oldRecursionCount = H.recursionCounter
		H.incrementRecursionCounter("elseif")

		elseLocation = H.snapshot()
		elsebody = H.parseIfImpl()
		endLine, endColumn = elsebody.location.end_.x, elsebody.location.end_.y

		H.recursionCounter = oldRecursionCount
	else
		local ThenElse_type = H.token_type

		local ThenElse_start_line, ThenElse_start_col = H.token_start_line, H.token_start_col
		local ThenElse_end_line, ThenElse_end_col = H.token_end_line, H.token_end_col

		if H.token_type == 294 then
			thenbody.hasEnd = true
			elseLocation = H.snapshot()

			ThenElse_type = H.token_type

			ThenElse_start_line, ThenElse_start_col = H.token_start_line, H.token_start_col
			ThenElse_end_line, ThenElse_end_col = H.token_end_line, H.token_end_col

			H.nextLexeme()

			local body = H.parseBlock()
			body.location.begin = vector.create(ThenElse_end_line, ThenElse_end_col)
			elsebody = body
		end

		endLine, endColumn = H.token_end_line, H.token_end_col

		local hasEnd = H.expectMatchEndAndConsume(296, ThenElse_type, ThenElse_start_line, ThenElse_start_col)

		if elsebody then
			if elsebody.kind == "StatBlock" then
				elsebody.hasEnd = hasEnd
			end
		else
			thenbody.hasEnd = hasEnd
		end
	end

	return {
		kind = "StatIf",
		location = {
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(endLine, endColumn),
		},
		condition = cond,
		thenbody = thenbody,
		elsebody = elsebody,
		thenLocation = thenLocation,
		elseLocation = elseLocation,
	} 
end

-- while exp do block end
H.parseWhileImpl = function ()	
local startLine, startColumn = H.token_start_line, H.token_start_col
	H.nextLexeme()

	local cond = H.ParserFunctions.parseExpr()

	local Do_type = H.token_type

	local Do_start_line, Do_start_col = H.token_start_line, H.token_start_col
	local Do_end_line, Do_end_col = H.token_end_line, H.token_end_col

	local hasDo = H.expectAndConsume(293, "while loop")
do local __DARKLUA_VAR=
	H.functionStack[#H.functionStack]__DARKLUA_VAR.loopDepth =__DARKLUA_VAR.loopDepth+ 1
end
	local body = H.parseBlock()
do local __DARKLUA_VAR0=
	H.functionStack[#H.functionStack]__DARKLUA_VAR0.loopDepth =__DARKLUA_VAR0.loopDepth- 1
end
	local endLine, endColumn = H.token_end_line, H.token_end_col
	local hasEnd = H.expectMatchEndAndConsume(296, Do_type, Do_start_line, Do_start_col)

	body.hasEnd = hasEnd

	return {
		kind = "StatWhile",
		location = {
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(endLine, endColumn),
		},
		condition = cond,
		body = body,
		hasDo = hasDo,
		doLocation = {
			begin = vector.create(Do_start_line, Do_start_col),
			end_ = vector.create(Do_end_line, Do_end_col),
		},
	} 
end

-- repeat block until exp
H.parseRepeatImpl = function ()	
local startLine, startColumn = H.token_start_line, H.token_start_col

	local Repeat_type = H.token_type
	local Repeat_start_line, Repeat_start_col = H.token_start_line, H.token_start_col

	H.nextLexeme() -- repeat

	local localsBegin = #H.localStack
do local __DARKLUA_VAR=
	H.functionStack[#H.functionStack]__DARKLUA_VAR.loopDepth =__DARKLUA_VAR.loopDepth+ 1
end
	local body = H.parseBlockNoScope()
do local __DARKLUA_VAR0=
	H.functionStack[#H.functionStack]__DARKLUA_VAR0.loopDepth =__DARKLUA_VAR0.loopDepth- 1
end
	local untilLine, untilColumn = 0, 0
	local hasUntil = H.expectMatchEndAndConsume(310, Repeat_type, Repeat_start_line, Repeat_start_col)
	body.hasEnd = hasUntil
	if hasUntil then
		untilLine, untilColumn = H.prev_start_line, H.prev_start_col
	end

	local cond = H.ParserFunctions.parseExpr()

	H.restoreLocals(localsBegin)

	local node = {
		kind = "StatRepeat",
		location = {
			begin = vector.create(startLine, startColumn),
			end_ = cond.location.end_,
		},
		condition = cond,
		body = body,
		hasUntil = hasUntil,
	} 
	
if H.storeCstData then
		node.cstNode = {
			kind = "CstStatRepeat",
			untilPosition = vector.create(untilLine, untilColumn),
		}
	end

	return node
end

-- do block end
H.parseDoImpl = function ()	
local startLine, startColumn = H.token_start_line, H.token_start_col

	local Do_type = H.token_type
	local Do_start_line, Do_start_col = H.token_start_line, H.token_start_col

	H.nextLexeme() -- do

	local statsStartLine, statsStartColumn = H.token_start_line, H.token_start_col

	local body = H.parseBlock()
	body.location.begin = vector.create(startLine, startColumn)

	local endStartLine, endStartColumn = H.token_start_line, H.token_start_col
	local endLine, endColumn = H.token_end_line, H.token_end_col
	body.hasEnd = H.expectMatchEndAndConsume(296, Do_type, Do_start_line, Do_start_col)

	if body.hasEnd then
		body.location.end_ = vector.create(endLine, endColumn)
	end

	if H.storeCstData then
		body.cstNode = {
			kind = "CstStatDo",
			statsStart = vector.create(statsStartLine, statsStartColumn),
			endPosition = (body.hasEnd
and{(vector.create(endStartLine, endStartColumn)
)}or{(vector.create(0, 0))})[1],
		} 	
end

	return body
end

-- break
H.parseBreakImpl = function ()	
local start = H.snapshot()
	H.nextLexeme() -- break

	if H.functionStack[#H.functionStack].loopDepth == 0 then
		return H.reportStatError(
			start,
			{},
			{ { kind = "StatBreak", location = start } },
			"break statement must be inside a loop"
		)
	end

	return {
		kind = "StatBreak",
		location = start,
	}
end

-- continue
H.parseContinueImpl = function (start)	
if H.functionStack[#H.functionStack].loopDepth == 0 then
		return H.reportStatError(
			start,
			{},
			{ { kind = "StatContinue", location = start } },
			"continue statement must be inside a loop"
		)
	end

	-- note: the token is already parsed for us!

	return {
		kind = "StatContinue",
		location = start,
	}
end

H.extractAnnotationColonPositions = function (bindings)	
local positions= {}
	for i, binding in ipairs(bindings) do
		positions[i] = binding.colonPosition
	end
	return positions
end

-- explist ::= {exp `,'} exp
H.parseExprListImpl = function (result, commaPositions)
	table.insert(result, H.ParserFunctions.parseExpr())

	while H.token_type == 44 do
		if commaPositions then
			table.insert(commaPositions, vector.create(H.token_start_line, H.token_start_col))
		end

		H.nextLexeme()
		if H.token_type == 41 then
			H.report(H.snapshot(), "Expected expression after ',' but got ')' instead")

			break
		end

		table.insert(result, H.ParserFunctions.parseExpr())
	end
end

-- for binding `=' exp `,' exp [`,' exp] do block end |
-- for bindinglist in explist do block end |
H.parseForImpl = function ()	
local startLine, startColumn = H.token_start_line, H.token_start_col
	H.nextLexeme() -- for

	local varname = H.parseBinding()

	if H.token_type == 61 then
		local equalsPosition = (H.storeCstData and{(vector.create(H.token_start_line, H.token_start_col) )}or{nil
})[1]		H.nextLexeme()

		local from = H.ParserFunctions.parseExpr()

		local endCommaPosition= (H.storeCstData and{(vector.create(0, 0) )}or{nil
})[1]		if H.expectAndConsume(44, "index range") then
			if endCommaPosition then
				endCommaPosition = vector.create(H.prev_start_line, H.prev_start_col)
			end
		end

		local to = H.ParserFunctions.parseExpr()

		local stepCommaPosition= nil
		local step= nil

		if H.token_type == 44 then
			if H.storeCstData then
				stepCommaPosition = vector.create(H.token_start_line, H.token_start_col)
			end
			H.nextLexeme()
			step = H.ParserFunctions.parseExpr()
		end

		local Do_type = H.token_type

		local Do_start_line, Do_start_col = H.token_start_line, H.token_start_col
		local Do_end_line, Do_end_col = H.token_end_line, H.token_end_col

		local hasDo = H.expectAndConsume(293, "for loop")

		local localsBegin = #H.localStack
do local __DARKLUA_VAR=		H.functionStack[#H.functionStack]__DARKLUA_VAR.loopDepth =__DARKLUA_VAR.loopDepth+ 1
end
		local var = H.pushLocal(varname)

		local body = H.parseBlock()
do local __DARKLUA_VAR0=
		H.functionStack[#H.functionStack]__DARKLUA_VAR0.loopDepth =__DARKLUA_VAR0.loopDepth- 1
end		H.restoreLocals(localsBegin)

		local end_ = vector.create(H.token_end_line, H.token_end_col)
		local hasEnd = H.expectMatchEndAndConsume(296, Do_type, Do_start_line, Do_start_col)
		body.hasEnd = hasEnd

		local node = {
			kind = "StatFor",
			location = {
				begin = vector.create(startLine, startColumn),
				end_ = end_,
			},
			var = var,
			from = from,
			to = to,
			step = step,
			body = body,
			hasDo = hasDo,
			doLocation = {
				begin = vector.create(Do_start_line, Do_start_col),
				end_ = vector.create(Do_end_line, Do_end_col),
			},
		} 
		
if equalsPosition and endCommaPosition then
			node.cstNode = {
				kind = "CstStatFor",
				annotationColonPosition = varname.colonPosition,
				equalsPosition = equalsPosition,
				endCommaPosition = endCommaPosition,
				stepCommaPosition = stepCommaPosition,
			}
		end

		return node
	else
		local names = { varname }
		local varsCommaPosition= H.storeCstData and{} or nil

		if H.token_type == 44 then
			local initialCommaPos = (H.storeCstData and{(vector.create(H.token_start_line, H.token_start_col) )}or{nil
})[1]			H.nextLexeme()
			H.parseBindingList(names, false, varsCommaPosition, initialCommaPos)
		end

		local inLocation = H.snapshot()
		local hasIn = H.expectAndConsume(301, "for loop")

		local values= {}

		local valuesCommaPositions= H.storeCstData and{} or nil
		H.parseExprListImpl(values, valuesCommaPositions)

		local Do_type = H.token_type

		local Do_start_line, Do_start_col = H.token_start_line, H.token_start_col
		local Do_end_line, Do_end_col = H.token_end_line, H.token_end_col

		local hasDo = H.expectAndConsume(293, "for loop")

		local localsBegin = #H.localStack
do local __DARKLUA_VAR=		H.functionStack[#H.functionStack]__DARKLUA_VAR.loopDepth =__DARKLUA_VAR.loopDepth+ 1
end
		local vars = {} 		
for _, binding in ipairs(names) do
			table.insert(vars, H.pushLocal(binding))
		end

		local body = H.parseBlock()
do local __DARKLUA_VAR0=
		H.functionStack[#H.functionStack]__DARKLUA_VAR0.loopDepth =__DARKLUA_VAR0.loopDepth- 1
end		H.restoreLocals(localsBegin)

		local end_ = vector.create(H.token_end_line, H.token_end_col)

		local hasEnd = H.expectMatchEndAndConsume(296, Do_type, Do_start_line, Do_start_col)
		body.hasEnd = hasEnd

		local node = {
			kind = "StatForIn",
			location = {
				begin = vector.create(startLine, startColumn),
				end_ = end_,
			},
			vars = vars,
			values = values,
			body = body,
			hasIn = hasIn,
			inLocation = inLocation,
			hasDo = hasDo,
			doLocation = {
				begin = vector.create(Do_start_line, Do_start_col),
				end_ = vector.create(Do_end_line, Do_end_col),
			},
		} 
		
if varsCommaPosition and valuesCommaPositions then
			node.cstNode = {
				kind = "CstStatForIn",
				varsAnnotationColonPositions = H.extractAnnotationColonPositions(names),
				varsCommaPositions = varsCommaPosition,
				valuesCommaPositions = valuesCommaPositions,
			}
		end

		return node
	end
end

-- NAME
H.parseNameExprImpl = function (context)	
local name, startLine, startColumn, endLine, endColumn = H.parseNameScalars(context)

	if not name then
		return {
			kind = "ExprError",
			location = H.snapshot(),
			expressions = {},
			messageIndex = #H.parseErrors,
		}
	end

	local nameLocation = {
		begin = vector.create(startLine, startColumn),
		end_ = vector.create(endLine, endColumn),
	}
	local local_ = H.localMap[name]

	if local_ then
		if local_.functionDepth < (H.typeFunctionDepth or 0) then
			return H.reportExprError(H.snapshot(), {}, "Type function cannot reference outer local '%s'", local_.name)
		end

		return {
			kind = "ExprLocal",
			location = nameLocation,
			["local"] = local_,
			upvalue = local_.functionDepth ~= (#H.functionStack - 1),
		}
	end

	return {
		kind = "ExprGlobal",
		location = nameLocation,
		name = name,
	}
end

-- funcname ::= Name {`.' Name} [`:' Name]
H.parseFunctionName = function ()	
local hasSelf = false
	local debugname = (H.token_type == 281 and{H.token_string }or{nil
})[1]
	-- parse funcname into a chain of indexing operators
	local expr = H.parseNameExprImpl("function name")

	local oldRecursionCount = H.recursionCounter

	while H.token_type == 46 do
		local opPosition = vector.create(H.token_start_line, H.token_start_col)
		H.nextLexeme()

		local name, startLine, startColumn, endLine, endColumn = H.parseNameScalars("field name")
		name = name or "%error-id%"
		local nameLocation = {
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(endLine, endColumn),
		}

		-- while we could concatenate the name chain, for now let's just write the short name
		debugname = name

		expr = {
			kind = "ExprIndexName",
			location = {
				begin = expr.location.begin,
				end_ = nameLocation.end_,
			},
			expr = expr,
			index = name,
			indexLocation = nameLocation,
			opPosition = opPosition,
			op = 46,
		}

		-- note: while the parser isn't recursive here, we're generating recursive structures of unbounded depth
		H.incrementRecursionCounter("function name")
	end

	H.recursionCounter = oldRecursionCount

	-- finish with :
	if H.token_type == 58 then
		local opPosition = vector.create(H.token_start_line, H.token_start_col)
		H.nextLexeme()

		local name, startLine, startColumn, endLine, endColumn = H.parseNameScalars("method name")
		name = name or "%error-id%"
		local nameLocation = {
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(endLine, endColumn),
		}

		-- while we could concatenate the name chain, for now let's just write the short name
		debugname = name

		expr = {
			kind = "ExprIndexName",
			location = {
				begin = expr.location.begin,
				end_ = nameLocation.end_,
			},
			expr = expr,
			index = name,
			indexLocation = nameLocation,
			opPosition = opPosition,
			op = 58,
		}

		hasSelf = true
	end

	return expr , hasSelf, debugname
end

H.shouldParseTypePack = function ()
	local t = H.token_type

	if t == 262 then
		return true
	end

	if t == 281 and H.next_type == 262 then
		return true
	end

	return false
end

H.parseTypePackImpl = function ()	-- Variadic: ...T
	
if H.token_type == 262 then
		local startLine, startColumn = H.token_start_line, H.token_start_col
		H.nextLexeme()
		local varTy = H.parseTypeImpl(false)
		return {
			kind = "TypePackVariadic",
			location = {
				begin = vector.create(startLine, startColumn),
				end_ = varTy.location.end_,
			},
			variadicType = varTy,
		}

		-- Generic: a...
	elseif H.token_type == 281 and H.next_type == 262 then
		local name, startLine, startColumn = H.parseNameScalars("generic name")
		local endStartLine, endStartColumn = H.token_start_line, H.token_start_col
		local endLine, endColumn = H.token_end_line, H.token_end_col

		-- This will not fail because of the lookahead guard.
		H.expectAndConsume(262, "generic type pack annotation")

		local node = {
			kind = "TypePackGeneric",
			location = {
				begin = vector.create(startLine, startColumn),
				end_ = vector.create(endLine, endColumn),
			},
			genericName = name ,
		}

		if H.storeCstData then
			node.cstNode = {
				kind = "CstTypePackGeneric",
				ellipsisPosition = vector.create(endStartLine, endStartColumn),
			}
		end

		return node 	
end

	-- TODO: shouldParseTypePack can be removed and parseTypePack can be called unconditionally instead
	error("parseTypePack can't be called if shouldParseTypePack() returned false")
end

H.parseSimpleTypeOrPackImpl = function ()	
local oldRec = H.recursionCounter
	-- recursion counter is incremented in parseSimpleType

	local beginLine, beginColumn = H.token_start_line, H.token_start_col

	local type_, typePack = H.ParserFunctions.parseSimpleType(true, false)

	if typePack then
		return nil, typePack
	end

	H.recursionCounter = oldRec

	return H.parseTypeSuffixImpl(type_, beginLine, beginColumn), nil
end

H.parseGenericTypeListImpl = function (
	withDefaultValues,
	openPosRef,
	commaPosRef,
	closePosRef
)	
if H.token_type ~= 60 then
		return H.EmptyArray , H.EmptyArray 	
end

	local names= {}
	local namePacks= {}
	local localCommaPositions= commaPosRef and{} or nil

	if H.token_type == 60 then
		local begin_type = H.token_type
		local begin_start_line, begin_start_col = H.token_start_line, H.token_start_col

		if openPosRef then
			openPosRef[1] = vector.create(begin_start_line, begin_start_col)
		end

		H.nextLexeme()

		local seenPack = false
		local seenDefault = false

		while true do
			local nameLoc = H.snapshot()
			local name = H.parseNameScalars()
			name = name or "%error-id%"

			if H.token_type == 262 or seenPack then
				seenPack = true
				local ellipsisLine, ellipsisColumn = 0, 0

				if H.token_type ~= 262 then
					H.report(H.snapshot(), "Generic types come before generic type packs")
				else
					ellipsisLine, ellipsisColumn = H.token_start_line, H.token_start_col
					H.nextLexeme()
				end

				if withDefaultValues and H.token_type == 61 then
					seenDefault = true
					local equalsLine, equalsColumn = H.token_start_line, H.token_start_col
					H.nextLexeme()

					local typePack= nil
					if H.shouldParseTypePack() then
						typePack = H.parseTypePackImpl()
					else
						local type_, pack_ = H.parseSimpleTypeOrPackImpl()
						if type_ then
							H.report(type_.location, "Expected type pack after '=', got type")
						end
						typePack = pack_
					end

					local node = {
						kind = "GenericTypePack",
						location = nameLoc,
						name = name,
						defaultValue = typePack,
					} 
					
if H.storeCstData then
						node.cstNode = {
							kind = "CstGenericTypePack",
							ellipsisPosition = vector.create(ellipsisLine, ellipsisColumn),
							defaultEqualsPosition = vector.create(equalsLine, equalsColumn),
						} 					
end

					table.insert(namePacks, node)
				else
					if seenDefault then
						H.report(H.snapshot(), "Expected default type pack after type pack name")
					end

					local node = {
						kind = "GenericTypePack",
						location = nameLoc,
						name = name,
						defaultValue = nil,
					} 
					
if H.storeCstData then
						node.cstNode = {
							kind = "CstGenericTypePack",
							ellipsisPosition = vector.create(ellipsisLine, ellipsisColumn),
							defaultEqualsPosition = nil,
						} 					
end

					table.insert(namePacks, node)
				end
			else
				if withDefaultValues and H.token_type == 61 then
					seenDefault = true
					local equalsLine, equalsColumn = H.token_start_line, H.token_start_col
					H.nextLexeme()

					local defaultType = H.parseTypeImpl()

					local node = {
						kind = "GenericType",
						location = nameLoc,
						name = name,
						defaultValue = defaultType,
					} 
					
if H.storeCstData then
						node.cstNode = {
							kind = "CstGenericType",
							defaultEqualsPosition = vector.create(equalsLine, equalsColumn),
						} 					
end
					table.insert(names, node)
				else
					if seenDefault then
						H.report(H.snapshot(), "Expected default type after type name")
					end

					local node = {
						kind = "GenericType",
						location = nameLoc,
						name = name,
						defaultValue = nil,
					} 
					
if H.storeCstData then
						node.cstNode = {
							kind = "CstGenericType",
							defaultEqualsPosition = nil,
						} 					
end
					table.insert(names, node)
				end
			end

			if H.token_type == 44 then
					if localCommaPositions then
						table.insert(localCommaPositions, vector.create(H.token_start_line, H.token_start_col))
				end
				H.nextLexeme()

				if H.token_type == 62 then
					H.report(H.snapshot(), "Expected type after ',' but got '>' instead")
					break
				end
			else
				break
			end
		end

		if H.expectMatchAndConsume(62, begin_type, begin_start_line, begin_start_col) and closePosRef then
			closePosRef[1] = vector.create(H.prev_start_line, H.prev_start_col)
		end
	end

	if commaPosRef and localCommaPositions then
		for _, v in ipairs(localCommaPositions) do
			table.insert(commaPosRef, v)
		end
	end

	return names, namePacks
end

H.parseOptionalReturnTypeImpl = function (returnSpecifierPosRef)	
if H.token_type == 58 or H.token_type == 263 then
		if H.token_type == 263 then
			H.report(H.snapshot(), "Function return type annotations are written after ':' instead of '->'")
		end

		if returnSpecifierPosRef then
			returnSpecifierPosRef[1] = vector.create(H.token_start_line, H.token_start_col)
		end

		H.nextLexeme()

		local oldRecursion = H.recursionCounter
		local res = H.ParserFunctions.parseReturnType()
		H.recursionCounter = oldRecursion

		-- At this point, if we find a , character, it indicates that there are multiple return types
		-- in this type annotation, but the list wasn't wrapped in parentheses.
		if H.token_type == 44 then
			H.report(
				H.snapshot(),
				"Expected a statement, got ','; did you forget to wrap the list of return types in parentheses?"
			)
			H.nextLexeme()
		end

		return res
	end

	return nil
end

H.prepareFunctionArgumentsImpl = function (start, hasself, args)	
local selfLocal= nil
	if hasself then
		selfLocal = H.pushLocal({
			name = { value = "self" },
			location = start,
			annotation = nil,
			colonPosition = nil,
		})
	end

	if #args == 0 then
		return selfLocal, H.EmptyArray 	
end

	local vars= {}
	for _, arg in ipairs(args) do
		table.insert(vars, H.pushLocal(arg))
	end

	return selfLocal, vars
end

-- funcbody ::= `(' [parlist] `)' [`:' ReturnType] block end
-- parlist ::= bindinglist [`,' `...'] | `...'
H.parseFunctionBodyImpl = function (
	hasself,
	matchFunctionType,
	matchFunctionLine,
	matchFunctionColumn,
	matchFunctionEndLine,
	matchFunctionEndColumn,
	debugname,
	localName,
	localNameLocation,
	attributes,
	cstAttrLists,
	isConst
)	
local matchFunctionLocation = {
		begin = vector.create(matchFunctionLine, matchFunctionColumn),
		end_ = vector.create(matchFunctionEndLine, matchFunctionEndColumn),
	}
	local start = matchFunctionLocation
	if #attributes > 0 then
		start = attributes[1].location
	end

	local cstNode= nil
	if H.storeCstData then
		cstNode = {
			kind = "CstExprFunction",
			attrLists = cstAttrLists or {},
			functionKeywordPosition = matchFunctionLocation.begin,
			openGenericsPosition = vector.create(0, 0),
			genericsCommaPositions = {},
			closeGenericsPosition = vector.create(0, 0),
			argsAnnotationColonPositions = {},
			argsCommaPositions = {},
			varargAnnotationColonPosition = vector.create(0, 0),
			returnSpecifierPosition = vector.create(0, 0),
		} 	
end

	local openGenPosRef = cstNode and { cstNode.openGenericsPosition } or nil
	local genCommaPosRef = cstNode and cstNode.genericsCommaPositions or nil
	local closeGenPosRef = cstNode and { cstNode.closeGenericsPosition } or nil

	local generics, genericPacks = H.parseGenericTypeListImpl(false, openGenPosRef, genCommaPosRef, closeGenPosRef)

	if cstNode and openGenPosRef then
		cstNode.openGenericsPosition = openGenPosRef[1]
	end
	if cstNode and closeGenPosRef then
		cstNode.closeGenericsPosition = closeGenPosRef[1]
	end

	local Paren_type = H.token_type
	local Paren_line = H.token_start_line
	local Paren_col = H.token_start_col

	H.expectAndConsume(40, "function")

	-- NOTE: This was added in conjunction with passing `searchForMissing` to
	-- `expectMatchAndConsume` inside `parseTableType` so that the behavior of
	-- parsing code like below (note the missing `}`):

	-- function (t: { a: number  ) end

	-- ... will still parse as (roughly):

	-- function (t: { a: number }) end

	H.matchRecovery[41]=H.matchRecovery[41]+ 1

	local args = H.EmptyArray 	
local vararg = false
	local varargLocation= nil
	local varargAnnotation= nil

	if H.token_type ~= 41 then
		args = {}
		local vaAnnotPosRef = cstNode and { cstNode.varargAnnotationColonPosition } or nil

		vararg, varargLocation, varargAnnotation =
			H.parseBindingList(args, true, (cstNode and{cstNode.argsCommaPositions }or{nil})[1], nil, vaAnnotPosRef, false)

		if cstNode and vaAnnotPosRef then
			cstNode.varargAnnotationColonPosition = vaAnnotPosRef[1]
		end
	end

	local argLocation= nil
	if Paren_type == 40 and H.token_type == 41 then
		argLocation = {
			begin = vector.create(Paren_line, Paren_col),
			end_ = vector.create(H.token_end_line, H.token_end_col),
		}
	end

	H.expectMatchAndConsume(41, Paren_type, Paren_line, Paren_col, true)
	H.matchRecovery[41]=H.matchRecovery[41]- 1

	local retSpecPosRef = cstNode and { cstNode.returnSpecifierPosition } or nil
	local typelist = H.parseOptionalReturnTypeImpl(retSpecPosRef)
	if cstNode and retSpecPosRef then
		cstNode.returnSpecifierPosition = retSpecPosRef[1]
	end

	local funLocal= nil
	if localName then
		local bindingLocation = localNameLocation or start
		funLocal = H.pushLocal({
			name = { value = localName },
			location = bindingLocation,
			annotation = nil,
			colonPosition = nil,
			isConst = isConst == true,
		} )
	end

	local localsBegin = #H.localStack

	local fun = { vararg = vararg, loopDepth = 0 } 	
table.insert(H.functionStack, fun)

	local selfLocal, vars = H.prepareFunctionArgumentsImpl(start, hasself, args)

	local body = H.parseBlock()

	table.remove(H.functionStack)

	H.restoreLocals(localsBegin)

	local endPosition = vector.create(H.token_end_line, H.token_end_col)
	local hasEnd = H.expectMatchEndAndConsume(
		296,
		matchFunctionType,
		matchFunctionLine,
		matchFunctionColumn
	)
	body.hasEnd = hasEnd

	local node = {
		kind = "ExprFunction",
		location = { begin = start.begin, end_ = endPosition },
		attributes = attributes,
		generics = generics,
		genericPacks = genericPacks,
		self = selfLocal,
		args = vars,
		vararg = vararg,
		varargLocation = varargLocation,
		body = body,
		functionDepth = #H.functionStack,
		debugname = debugname,
		returnAnnotation = typelist,
		varargAnnotation = varargAnnotation,
		argLocation = argLocation,
	} 
	
if H.storeCstData and cstNode then
		cstNode.argsAnnotationColonPositions = H.extractAnnotationColonPositions(args)
		node.cstNode = cstNode
	end

	return node, funLocal
end

-- function funcname funcbody
H.parseFunctionStatImpl = function (
	attributes,
	attributeStartLocation,
	cstAttrLists
)	
local startPosition = vector.create(H.token_start_line, H.token_start_col)
	if attributeStartLocation ~= nil then
		startPosition = attributeStartLocation.begin
	elseif #attributes > 0 then
		startPosition = attributes[1].location.begin
	end

	local matchFunctionType = H.token_type
	local matchFunctionLine, matchFunctionColumn = H.token_start_line, H.token_start_col
	local matchFunctionEndLine, matchFunctionEndColumn = H.token_end_line, H.token_end_col
	H.nextLexeme()

	local expr, hasSelf, debugname = H.parseFunctionName()

	if not H.isExprLValue(expr) then
		expr = (H.LuauExportValueSyntax
and{(H.reportLValueError(expr)
)}or{(H.reportExprError(expr.location, { expr }, "Assigned expression must be a variable or a field")
)})[1]	end

	H.matchRecovery[296]=H.matchRecovery[296]+ 1

	local body = H.parseFunctionBodyImpl(
		hasSelf,
		matchFunctionType,
		matchFunctionLine,
		matchFunctionColumn,
		matchFunctionEndLine,
		matchFunctionEndColumn,
		debugname,
		nil,
		nil,
		attributes,
		nil,
		false
	)

	H.matchRecovery[296]=H.matchRecovery[296]- 1

	local node = {
		kind = "StatFunction",
		location = {
			begin = startPosition,
			end_ = body.location.end_,
		},
		name = expr,
		func = body,
	} 
	
if H.storeCstData then
		node.cstNode = {
			kind = "CstStatFunction",
			attrLists = cstAttrLists or {},
			functionKeywordPosition = vector.create(matchFunctionLine, matchFunctionColumn),
		}
	end

	return node
end

H.validateAttribute = function (
	loc,
	attributeName,
	attributes,
	args
)
	-- check if the attribute name is valid
	local entry = H.kAttributeEntries[attributeName]
	local type_= nil
	local argsValidator= nil

	if entry then
		type_ = entry.type
		argsValidator = entry.argsValidator
	elseif H.DebugLuauNoInline and H.kDebugAttributeEntries[attributeName] then
		type_ = H.kDebugAttributeEntries[attributeName].type
	else
		if #attributeName == 0 then
			H.report(loc, "Attribute name is missing")
		else
			H.report(loc, "Invalid attribute '@%s'", attributeName)
		end
	end

	if type_ then
		-- check that attribute is not duplicated
		for _, attr in ipairs(attributes) do
			if attr.type == type_ then
				H.report(loc, "Cannot duplicate attribute '@%s'", attributeName)
			end
		end

		if argsValidator then
			local validator = argsValidator 			
local errors = validator(loc, args)
			for _, err in ipairs(errors) do
				H.report(err.location, "%s", err.message)
			end
		end
	end

	return type_
end

H.tableSeparator = function ()	
if H.token_type == 44 then
		return 0
	elseif H.token_type == 59 then
		return 1
	else
		return nil
	end
end

H.cstSeparatorPosition = function (separator)	
return (separator == nil and{(vector.create(0, 0) )}or{(vector.create(H.token_start_line, H.token_start_col)
)})[1]end

-- tableconstructor ::= `{' [fieldlist] `}'
-- fieldlist ::= field {fieldsep field} [fieldsep]
-- field ::= `[' exp `]' `=' exp | Name `=' exp | exp
-- fieldsep ::= `,' | `;'
H.parseTableConstructorImpl = function ()	
local items = {} 	
local cstItems= H.storeCstData and{} or nil

	local startLine, startColumn = H.token_start_line, H.token_start_col

	local brace_type, brace_line, brace_col = H.token_type, H.token_start_line, H.token_start_col
	H.expectAndConsume(123, "table literal")

	local lastElementIndent = 0

	while H.token_type ~= 125 do
		if not H.LuauTableEntriesDontNeedToMatchIndent then
			lastElementIndent = H.token_start_col
		end

		local indexerOpenPos= nil
		local indexerClosePos= nil
		local equalsPos= nil

		if H.token_type == 91 then
			if cstItems then
				indexerOpenPos = vector.create(H.token_start_line, H.token_start_col)
			end
			local bracket_type, bracket_line, bracket_col = H.token_type, H.token_start_line, H.token_start_col
			H.nextLexeme()

			local key = H.ParserFunctions.parseExpr()

			if H.expectMatchAndConsume(93, bracket_type, bracket_line, bracket_col) then
				if cstItems then
					indexerClosePos = vector.create(H.prev_start_line, H.prev_start_col)
				end
			end

			if H.expectAndConsume(61, "table field") then
				if cstItems then
					equalsPos = vector.create(H.prev_start_line, H.prev_start_col)
				end
			end

			local value = H.ParserFunctions.parseExpr()

			table.insert(
				items,
				{
					kind = "General",
					key = key,
					value = value,
				} 			
)

			if cstItems then
				local separator = H.tableSeparator()
				table.insert(
					cstItems,
					{
						kind = "General",
						indexerOpenPosition = indexerOpenPos,
						indexerClosePosition = indexerClosePos,
						equalsPosition = equalsPos,
						separator = separator,
						separatorPosition = H.cstSeparatorPosition(separator),
					} 				
)
			end
		elseif H.token_type == 281 and H.next_type == 61 then
			local name, nameStartLine, nameStartColumn, nameEndLine, nameEndColumn =
				H.parseNameScalars("table field")
			local fieldName = name 
			
if H.expectAndConsume(61, "table field") then
				if cstItems then
					equalsPos = vector.create(H.prev_start_line, H.prev_start_col)
				end
			end

			local key = {
				kind = "ExprConstantString",
				location = {
					begin = vector.create(nameStartLine, nameStartColumn),
					end_ = vector.create(nameEndLine, nameEndColumn),
				},
				value = fieldName,
				quoteStyle = H.QuoteStyle.Unquoted,
			}

			local value = H.ParserFunctions.parseExpr()

			if value.kind == "ExprFunction" then
				value.debugname = fieldName
			end

			table.insert(
				items,
				{
					kind = "Record",
					key = key,
					value = value,
				} 			
)

			if cstItems then
				local separator = H.tableSeparator()
				table.insert(
					cstItems,
					{
						kind = "Record",
						equalsPosition = equalsPos,
						separator = separator,
						separatorPosition = H.cstSeparatorPosition(separator),
					} 				
)
			end
		else
			local expr = H.ParserFunctions.parseExpr()
			table.insert(
				items,
				{
					kind = "List",
					value = expr,
				} 			
)

			if cstItems then
				local separator = H.tableSeparator()
				table.insert(
					cstItems,
					{
						kind = "List",
						separator = separator,
						separatorPosition = H.cstSeparatorPosition(separator),
					} 				
)
			end
		end

		if H.token_type == 44 or H.token_type == 59 then
			H.nextLexeme()
		elseif
			(H.token_type == 91 or H.token_type == 281)
			and (H.LuauTableEntriesDontNeedToMatchIndent or H.token_start_col == lastElementIndent)
		then
			H.report(H.snapshot(), "Expected ',' after table constructor element")
		elseif H.token_type ~= 125 then
			break
		end
	end

	local endLine, endColumn = H.token_end_line, H.token_end_col
	if not H.expectMatchAndConsume(125, brace_type, brace_line, brace_col) then
		endLine, endColumn = H.prev_end_line, H.prev_end_col
	end

	local node = {
		kind = "ExprTable",
		location = {
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(endLine, endColumn),
		},
		items = items,
	} 
	
if cstItems then
		node.cstNode = {
			kind = "CstExprTable",
			items = cstItems,
		} 	
end

	return node
end

H.extractStringDetails = function ()
	local style = 0
	local depth = 0

	if H.token_type == 279 then
		style = H.token_aux == 0 and H.CstQuotes.QuotedSingle or H.CstQuotes.QuotedDouble
	elseif H.token_type == 269 then
		style = H.CstQuotes.QuotedInterp
	elseif H.token_type == 278 then
		style = H.CstQuotes.QuotedRaw
		depth = H.token_aux or 0
	end

	return style, depth
end

H.parseCharArrayImpl = function ()	
local t = H.token_type
	local data = H.token_string or ""

	if t == 279 or t == 269 then
		local ok, fixed = H.fixupQuotedString(data)
		if not ok then
			H.nextLexeme()
			return nil
		end
		data = fixed 	
else
		data = H.fixupMultilineString(data)
	end

	H.nextLexeme()
	return data
end

H.parseStringImpl = function ()	
local location = H.snapshot()
	local quoteStyle = H.QuoteStyle.QuotedSimple

	if H.token_type == 279 then
		if H.token_aux == 0 then
			quoteStyle = H.QuoteStyle.QuotedSingle
		else
			quoteStyle = H.QuoteStyle.QuotedSimple
		end
	elseif H.token_type == 269 then
		quoteStyle = H.QuoteStyle.QuotedSimple
	elseif H.token_type == 278 then
		quoteStyle = H.QuoteStyle.QuotedRaw
	end

	local fullStyle = 0
	local blockDepth = 0
	if H.storeCstData then
		fullStyle, blockDepth = H.extractStringDetails()
	end

	local originalString= nil
	if H.storeCstData then
		originalString = H.token_string
	end

	local value = H.parseCharArrayImpl()

	if value then
		local node = {
			kind = "ExprConstantString",
			location = location,
			value = value,
			quoteStyle = quoteStyle,
		} 
		
if H.storeCstData then
			node.cstNode = {
				kind = "CstExprConstantString",
				sourceString = originalString,
				quoteStyle = fullStyle,
				blockDepth = blockDepth,
			}
		end

		return node 	
else
		return H.reportExprError(location, {}, "String literal contains malformed escape sequence")
	end
end

H.parseCallListImpl = function (commaPositions)	





if H.token_type == 40 then
		local argStart = vector.create(H.token_end_line, H.token_end_col)
		local paren_type, paren_line, paren_col = H.token_type, H.token_start_line, H.token_start_col

		H.nextLexeme()

		local args= {}

		if H.token_type ~= 41 then
			H.parseExprListImpl(args, commaPositions)
		end

		local endStartLine, endStartColumn = H.token_start_line, H.token_start_col
		local endLine, endColumn = H.token_end_line, H.token_end_col
		local closeParenPosition= nil
		if H.expectMatchAndConsume(41, paren_type, paren_line, paren_col) then
			if commaPositions then
				closeParenPosition = vector.create(endStartLine, endStartColumn)
			end
		end

		return args,
			{
				begin = argStart,
				end_ = vector.create(endLine, endColumn),
			},
			{
				begin = vector.create(paren_line, paren_col),
				end_ = vector.create(H.prev_start_line, H.prev_start_col),
			},
			closeParenPosition
	elseif H.token_type == 123 then
		local argStart = vector.create(H.token_end_line, H.token_end_col)
		local expr = H.parseTableConstructorImpl()

		return { expr } ,
			{
				begin = argStart,
				end_ = vector.create(H.prev_end_line, H.prev_end_col),
			},
			expr.location,
			nil
	else
		local argLoc = H.snapshot()
		local expr = H.parseStringImpl()
		return { expr } , argLoc, expr.location, nil
	end
end

-- attribute ::= '@' NAME
H.parseAttribute = function (attributes)	
if H.token_type == 284 then
		local loc = H.snapshot()
		local name = H.token_string or ""
		local type_ = H.validateAttribute(loc, name, attributes, H.EmptyArray )
		H.nextLexeme()
		local attr = {
			kind = "Attr",
			location = loc,
			type = type_ or "Unknown",
			args = H.EmptyArray ,
			name = name,
		} 
		
if H.storeCstData then
			attr.cstNode = {
				kind = "CstAttr",
				hasAt = true,
			}
		end

		table.insert(attributes, attr)

		return loc, nil
	else
		local open_type = H.token_type
		local open_start_line, open_start_col = H.token_start_line, H.token_start_col
		local openLocation = {
			begin = vector.create(open_start_line, open_start_col),
			end_ = vector.create(open_start_line, open_start_col),
		}
		local commaPositions= H.storeCstData and{} or nil

		H.nextLexeme()
		if H.token_type ~= 93 then
			while true do
				local attrName, nameStartLine, nameStartColumn, nameEndLine, nameEndColumn =
					H.parseNameScalars("attribute name")
				attrName = attrName or "%error-id%"
				local nameLoc = {
					begin = vector.create(nameStartLine, nameStartColumn),
					end_ = vector.create(nameEndLine, nameEndColumn),
				}
				local args= {}
				local argsLocation = nameLoc
				local hasArgs = false
				local openParenLine, openParenColumn = 0, 0
				local closeParenLine, closeParenColumn = 0, 0
				local argsCommaPositions= H.storeCstData and{} or nil

				if H.token_type == 278 or H.token_type == 279 or H.token_type == 123 or H.token_type == 40 then
					local argOpenType = H.token_type
					if argOpenType == 40 then
						openParenLine, openParenColumn = H.token_start_line, H.token_start_col
					end

					local args_, argsLoc_, _, parsedCloseParenPosition =
						H.parseCallListImpl(argsCommaPositions)
					args = args_
					argsLocation = argsLoc_
					hasArgs = true
					if argOpenType == 40 and parsedCloseParenPosition then
						closeParenLine = parsedCloseParenPosition.x
						closeParenColumn = parsedCloseParenPosition.y
					end

					for _, arg in ipairs(args) do
						if not H.ConstantLiteral[arg.kind] and not H.isLiteralTable(arg) then
							H.report(argsLocation, "Only literals can be passed as arguments for attributes")
						end
					end
				end

				local type_ = H.validateAttribute(nameLoc, attrName, attributes, args)
				local attrLocation = nameLoc
				if hasArgs then
					attrLocation = {
						begin = nameLoc.begin,
						end_ = argsLocation.end_,
					}
				end

				local attr = {
					kind = "Attr",
					location = attrLocation,
					type = type_ or "Unknown",
					args = args,
					name = attrName,
				} 
				
if H.storeCstData then
					attr.cstNode = hasArgs
and{
							kind = "CstParametrizedAttr",
							openParenPosition = vector.create(openParenLine, openParenColumn),
							closeParenPosition = vector.create(closeParenLine, closeParenColumn),
							argsCommaPositions = argsCommaPositions ,
						}
or{
							kind = "CstAttr",
							hasAt = false,
						}
				end

				table.insert(attributes, attr)

				if H.token_type == 44 then
					if commaPositions then
						table.insert(commaPositions, vector.create(H.token_start_line, H.token_start_col))
					end
					H.nextLexeme()
				else
					break
				end
			end
		else
			local errorLocation = {
				begin = vector.create(open_start_line, open_start_col),
				end_ = vector.create(H.token_end_line, H.token_end_col),
			}

			H.report(errorLocation, "Attribute list cannot be empty")

			local attr = {
				kind = "Attr",
				location = errorLocation,
				type = "Unknown",
				args = H.EmptyArray ,
				name = "%error-id%",
			} 
			
if H.storeCstData then
				attr.cstNode = {
					kind = "CstAttr",
					hasAt = false,
				}
			end

			table.insert(attributes, attr)
		end

		local closeBracketLine = (H.token_type == 93 and{H.token_start_line }or{0
})[1]		local closeBracketColumn = (H.token_type == 93 and{H.token_start_col }or{0
})[1]		H.expectMatchAndConsume(93, open_type, open_start_line, open_start_col)

		local cstList= H.storeCstData
and{
				kind = "CstAttrList",
				atBracketPosition = openLocation.begin,
				closeBracketPosition = vector.create(closeBracketLine, closeBracketColumn),
				commaPositions = commaPositions ,
			}
or nil

		return openLocation, cstList
	end
end

-- attributes ::= {attribute}
H.parseAttributes = function ()	
local attributes= {}
	local startLocation= nil
	local cstAttrLists= H.storeCstData and{} or nil

	while H.token_type == 284 or H.token_type == 285 do
		local attributeStart, cstAttrList = H.parseAttribute(attributes)
		if startLocation == nil then
			startLocation = attributeStart
		end
		if cstAttrLists and cstAttrList then
			table.insert(cstAttrLists, cstAttrList)
		end
	end

	return attributes, startLocation, cstAttrLists
end

H.isEnoughValues = function (values, expected)	
if #values > 0 then
		local last = values[#values]
		if last.kind == "ExprCall" or last.kind == "ExprVarargs" then
			return true
		end
	end

	return #values == expected
end

H.parseLocalImpl = function (
	start,
	keywordPosition,
	attributes,
	cstAttrLists,
	isConst
)	
if not isConst then
		H.nextLexeme() -- local
	end

	if H.token_type == 299 then
		local matchFunctionType = H.token_type
		local matchFunctionLine = H.token_start_line
		local matchFunctionColumn = H.token_start_col
		local matchFunctionEndLine, matchFunctionEndColumn = H.token_end_line, H.token_end_col
		H.nextLexeme()

		-- matchFunction is only used for diagnostics; to make it suitable for detecting missed indentation between
		-- `local function` and `end`, we patch the token to begin at the column where `local` starts
		if matchFunctionLine == start.begin.x then
			matchFunctionColumn = start.begin.y
		end

		local name, nameStartLine, nameStartColumn, nameEndLine, nameEndColumn =
			H.parseNameScalars("variable name")
		name = name or "%error-id%"
		local nameLocation = {
			begin = vector.create(nameStartLine, nameStartColumn),
			end_ = vector.create(nameEndLine, nameEndColumn),
		}

		H.matchRecovery[296]=H.matchRecovery[296]+ 1

		local body, var = H.parseFunctionBodyImpl(
			false,
			matchFunctionType,
			matchFunctionLine,
			matchFunctionColumn,
			matchFunctionEndLine,
			matchFunctionEndColumn,
			name,
			name,
			nameLocation,
			attributes or (H.EmptyArray ),
			nil,
			isConst
		)

		H.matchRecovery[296]=H.matchRecovery[296]- 1

		local node = {
			kind = "StatLocalFunction",
			location = { begin = start.begin, end_ = body.location.end_ },
			name = var,
			func = body,
			isConst = isConst,
			constKeywordBegin = (isConst and H.LuauStoreConstKeywordBegin and{keywordPosition }or{nil})[1],
		} 
		
if H.storeCstData then
			node.cstNode = {
				kind = "CstStatLocalFunction",
				attrLists = cstAttrLists or {},
				localKeywordPosition = keywordPosition,
				functionKeywordPosition = vector.create(matchFunctionLine, matchFunctionColumn),
			}
		end

		return node
	else
		if attributes and #attributes ~= 0 then
			return H.reportStatError(
				H.snapshot(),
				{},
				{},
				"Expected 'function' after local declaration with attribute, but got %s instead",
				H.ToString(H.token_type, H.token_string, H.token_codepoint)
			)
		end

		H.matchRecovery[61]=H.matchRecovery[61]+ 1

		local names= {}
		local varsCommaPositions= H.storeCstData and{} or nil
		H.parseBindingList(names, false, varsCommaPositions, nil, nil, isConst)

		H.matchRecovery[61]=H.matchRecovery[61]- 1

		local vars= {}
		local values= {}
		local valuesCommaPositions= H.storeCstData and{} or nil
		local equalsSignLocation= nil

		if H.token_type == 61 then
			equalsSignLocation = H.snapshot()
			H.nextLexeme()
			H.parseExprListImpl(values, valuesCommaPositions)
		end

		for _, binding in ipairs(names) do
			table.insert(vars, H.pushLocal(binding))
		end

		local end_
		if #values == 0 then
			end_ = vector.create(H.prev_end_line, H.prev_end_col)
		else
			end_ = values[#values].location.end_
		end

		if isConst and not H.isEnoughValues(values, #vars) then
			H.report({ begin = start.begin, end_ = end_ }, "Missing initializer in local declaration")
		end

		local node = {
			kind = "StatLocal",
			location = { begin = start.begin, end_ = end_ },
			vars = vars,
			values = values,
			equalsSignLocation = equalsSignLocation,
			isConst = isConst,
			isExported = false,
		} 
		
if varsCommaPositions and valuesCommaPositions then
			node.cstNode = {
				kind = "CstStatLocal",
				varsAnnotationColonPositions = H.extractAnnotationColonPositions(names),
				varsCommaPositions = varsCommaPositions,
				valuesCommaPositions = valuesCommaPositions,
			}
		end

		return node
	end
end

H.checkDuplicateExport = function (name, location)	
if H.declaredExportBindings[name] then
		return false
	end

	if H.declaredExportBindings == H.EmptyArray then
		H.declaredExportBindings = {}
	end
	H.declaredExportBindings[name] = location
	return true
end

H.exportLocalStat = function (stat, keywordLocation)	
if stat.kind == "StatLocal" then
		stat.isExported = true

		for _, local_ in ipairs(stat.vars) do
			if not H.checkDuplicateExport(local_.name, local_.location) then
				H.report(local_.location, "Duplicate exported identifier '%s'", local_.name)
			else
				local_.isExported = true
			end
		end

		stat.keywordLocation = keywordLocation
	end

	return stat
end

H.parseClassStatImpl = function (start, exported)	
local name = H.parseNameOptImpl("type name")

	if not name then
		name = {
			name = { value = "%error-id%" },
			location = H.snapshot(),
		} 	
end
	local className = name 
	
local savedLocals = #H.localStack
	local nameLocal = H.pushLocal({
		name = className.name,
		location = className.location,
		annotation = nil,
		colonPosition = nil,
		isConst = true,
	} )

	local members = {} 	
local memberNames= {}

	while H.token_type ~= 296 and H.token_type ~= 0 do
local __DARKLUA_CONTINUE_63=false repeat		local qualifierLocation = nil 		
if H.token_type == 281 and H.token_string == "public" then
			qualifierLocation = H.snapshot()
			H.nextLexeme()
		end

		if qualifierLocation and H.token_type ~= 299 then
			local propName = H.parseNameOptImpl("class property name")
			if not propName then
__DARKLUA_CONTINUE_63=true				break
			end

			local propType = nil 			
local typeColonLocation = nil 
			
if H.token_type == 58 then
				typeColonLocation = H.snapshot()
				H.nextLexeme()
				propType = H.parseTypeImpl()
			end

			if string.sub(propName.name.value, 1, 2) == "__" then
				H.report(propName.location, "Class properties cannot start with '__'")
			end

			if memberNames[propName.name.value] then
				H.report(propName.location, "Duplicate class member '%s'", propName.name.value)
			else
				memberNames[propName.name.value] = true
				table.insert(
					members,
					{
						kind = "ClassProperty",
						qualifierLocation = qualifierLocation,
						name = propName.name,
						nameLocation = propName.location,
						typeColonLocation = typeColonLocation,
						type = propType,
					} 				
)
			end
		elseif H.token_type == 299 then
			local matchFunctionType = H.token_type
			local matchFunctionLine, matchFunctionColumn = H.token_start_line, H.token_start_col
			local matchFunctionEndLine, matchFunctionEndColumn = H.token_end_line, H.token_end_col
			H.nextLexeme()

			local methodName, nameStartLine, nameStartColumn, nameEndLine, nameEndColumn =
				H.parseNameScalars("method name")
			methodName = methodName or "%error-id%"
			local methodNameLocation = {
				begin = vector.create(nameStartLine, nameStartColumn),
				end_ = vector.create(nameEndLine, nameEndColumn),
			}

			H.matchRecovery[296]=H.matchRecovery[296]+ 1
			local body = H.parseFunctionBodyImpl(
				false,
				matchFunctionType,
				matchFunctionLine,
				matchFunctionColumn,
				matchFunctionEndLine,
				matchFunctionEndColumn,
				methodName,
				nil,
				nil,
				H.EmptyArray ,
				nil,
				false
			)
			H.matchRecovery[296]=H.matchRecovery[296]- 1

			local selfAnnotation = (#body.args > 0 and body.args[1].name == "self" and{body.args[1].annotation }or{nil
})[1]			if selfAnnotation then
				H.report(selfAnnotation.location, "The 'self' parameter cannot have a type annotation")
			end

			if string.sub(methodName, 1, 2) == "__" then
				if H.DisallowedClassMetamethods[methodName] then
					H.report(methodNameLocation, "Classes cannot define '%s' as a metamethod", methodName)
				elseif not H.AllowedClassMetamethods[methodName] then
					H.report(
						methodNameLocation,
						"Cannot use '%s' as a method name: names starting with '__' are reserved",
						methodName
					)
				end
			end

			if memberNames[methodName] then
				H.report(methodNameLocation, "Duplicate class member '%s'", methodName)
			else
				memberNames[methodName] = true
				table.insert(
					members,
					{
						kind = "ClassMethod",
						qualifierLocation = qualifierLocation,
						keywordLocation = {
							begin = vector.create(matchFunctionLine, matchFunctionColumn),
							end_ = vector.create(matchFunctionEndLine, matchFunctionEndColumn),
						},
						functionName = { value = methodName },
						nameLocation = methodNameLocation,
						func = body,
					} 				
)
			end
		else
			H.report(H.snapshot(), "Only class properties and functions can be declared within a class")
			H.nextLexeme()
		end
__DARKLUA_CONTINUE_63=true until true if not __DARKLUA_CONTINUE_63 then break end	end

	local endLine, endColumn = H.token_end_line, H.token_end_col
	H.expectAndConsume(296, "class")

	local node = {
		kind = "StatClass",
		location = {
			begin = start.begin,
			end_ = vector.create(endLine, endColumn),
		},
		name = nameLocal,
		members = members,
		exported = exported,
	} 
	
if H.recursionCounter > 1 then
		H.report(nameLocal.location, "Cannot declare class '%s' inside another statement or expression", nameLocal.name)
	end

	if H.classesWithinModule[nameLocal.name] then
		H.restoreLocals(savedLocals)
		return H.reportStatError(
			nameLocal.location,
			{},
			{ node },
			"A class named '%s' has already been declared in this module",
			nameLocal.name
		)
	end

	if H.classesWithinModule == H.EmptyArray then
		H.classesWithinModule = {}
	end
	H.classesWithinModule[nameLocal.name] = true
	return node
end

H.parseExportValueImpl = function (
	start,
	keywordPosition,
	attributes,
	cstAttrLists
)	
if #H.functionStack ~= 1 or H.recursionCounter ~= 1 then
		H.report(start, "'export' may only be applied to top-level statements")
	end

	if H.hasModuleReturn then
		H.report(start, "Exporting values is not compatible with top-level return (export/return conflict)")
	end

	if #attributes ~= 0 and H.token_type ~= 299 then
		H.report(
			H.snapshot(),
			"Expected 'function' after export declaration with attribute, but got %s instead",
			H.ToString(H.token_type, H.token_string, H.token_codepoint)
		)
	end

	if H.token_type == 302 then
		local localKeywordLocation = H.snapshot()

		if H.next_type == 299 then
			H.report(start, "'export' must be followed by an identifier or 'function'; try removing 'local'")
			return H.parseLocalImpl(start, localKeywordLocation.begin, nil, nil, true)
		end

		return H.exportLocalStat(H.parseLocalImpl(start, keywordPosition, nil, nil, false), localKeywordLocation)
	elseif H.token_type == 299 then
		local stat = H.parseLocalImpl(start, keywordPosition, attributes, cstAttrLists, true)

		if stat.kind == "StatLocalFunction" and stat.name then
			if not H.checkDuplicateExport(stat.name.name, stat.name.location) then
				H.report(stat.name.location, "Duplicate exported identifier '%s'", stat.name.name)
			end

			stat.name.isExported = true
			stat.name.isConst = true
		end

		return stat
	elseif H.token_type == 281 and H.token_string == "const" then
		local constKeywordLocation = H.snapshot()
		H.nextLexeme()

		if H.token_type == 299 then
			H.report(start, "'export' must be followed by an identifier or 'function'")
			return H.parseLocalImpl(start, constKeywordLocation.begin, nil, nil, true)
		end

		return H.exportLocalStat(H.parseLocalImpl(start, constKeywordLocation.begin, nil, nil, true), constKeywordLocation)
	elseif H.DebugLuauUserDefinedClasses and H.token_type == 281 and H.token_string == "class" then
		H.nextLexeme()
		local stat = H.parseClassStatImpl(start, true)

		if stat.kind == "StatClass" then
			if not H.checkDuplicateExport(stat.name.name, stat.name.location) then
				H.report(stat.name.location, "Duplicate exported class '%s'", stat.name.name)
			end

			stat.name.isExported = true
		end

		return stat
	end

	return H.reportStatError(start, {}, {}, "'export' must be followed by an identifier or 'function'")
end

-- prefixexp -> NAME | '(' expr ')'
H.parsePrefixExprImpl = function ()	
if H.token_type == 40 then
		local start = vector.create(H.token_start_line, H.token_start_col)
		local Paren_type = H.token_type
		local Paren_line = H.token_start_line
		local Paren_col = H.token_start_col
		H.nextLexeme()

		local expr = H.ParserFunctions.parseExpr()

		local end_ = vector.create(H.token_end_line, H.token_end_col)
		local closeLine, closeColumn = 0, 0
		if H.token_type ~= 41 then
			H.expectMatchAndConsumeFail(

				41,
				Paren_type,
				Paren_line,
				Paren_col,
				H.token_type == 61 and "; did you mean to use '{' when defining a table?" or nil
			)

			end_ = vector.create(H.prev_end_line, H.prev_end_col)
		else
			closeLine, closeColumn = H.token_start_line, H.token_start_col
			H.nextLexeme()
		end

		local node = {
			kind = "ExprGroup",
			location = {
				begin = start,
				end_ = end_,
			},
			expr = expr,
		} 
		
if H.storeCstData then
			node.cstNode = {
				kind = "CstExprGroup",
				closePosition = vector.create(closeLine, closeColumn),
			}
		end

		return node
	else
		return H.parseNameExprImpl("expression")
	end
end

H.parseIndexNameScalars = function (context, prev)	
if H.token_type == 281 then
		return H.parseNameScalars(context)
	end

	H.reportNameError(context)

	if H.token_type >= 291 and H.token_type < 312 and H.token_start_line == prev.x then
		local name = H.token_string
		local startLine, startColumn = H.token_start_line, H.token_start_col
		local endLine, endColumn = H.token_end_line, H.token_end_col
		H.nextLexeme()
		return name, startLine, startColumn, endLine, endColumn
	end

	return "%error-id%", H.token_start_line, H.token_start_col, H.token_end_line, H.token_end_col
end

H.parseTypeParamsImpl = function (
	openingPosRef,
	commaPosRef,
	closingPosRef
)	
local params = {} 
	
if H.token_type == 60 then
		local beginType = H.token_type
		local beginLine, beginColumn = H.token_start_line, H.token_start_col
		if openingPosRef then
			openingPosRef[1] = vector.create(beginLine, beginColumn)
		end

		H.nextLexeme()

		while true do
			if H.shouldParseTypePack() then
				local pack = H.parseTypePackImpl()
				table.insert(params, { typePack = pack, type = nil })
			elseif H.token_type == 40 then
				local beginParenLine, beginParenColumn = H.token_start_line, H.token_start_col
				local type_= nil
				local typePack= nil
				local t = H.token_type

				if t ~= 124 and t ~= 38 then
					type_, typePack = H.ParserFunctions.parseSimpleType(true, false)
				end

				--/ Consider the following type:

				--  X<(T)>

				-- Is this a type pack or a parenthesized type? The
				-- assumption will be a type pack, as that's what allows one
				-- to express either a singular type pack or a potential
				-- complex type.

				if typePack then
					if
						typePack.kind == "TypePackExplicit"
						and #typePack.types == 1
						and not typePack.tailType
						and (H.token_type == 124 or H.token_type == 63 or H.token_type == 38)
					then
						-- If we parsed an explicit type pack with a single
						-- type in it (something of the form `(T)`), and
						-- the next lexeme is one that follows a type
						-- (&, |, ?), then assume that this was actually a
						-- parenthesized type.

						local parenTy = typePack.types[1]

						local node = {
							kind = "TypeGroup",
							location = parenTy.location,
							type = parenTy,
						} 
						
if H.storeCstData then
							local closePosition = parenTy.location.end_
							if typePack.cstNode and typePack.cstNode.closeParenthesesPosition then
								closePosition = typePack.cstNode.closeParenthesesPosition
							end

							node.cstNode = {
								kind = "CstTypeGroup",
								closePosition = closePosition,
							}
						end

						table.insert(
							params,
							{ type = H.parseTypeSuffixImpl(node, beginParenLine, beginParenColumn), typePack = nil }
						)
					else
						-- Otherwise, it's a type pack.
						table.insert(params, { type = nil, typePack = typePack })
					end
				else
					table.insert(
						params,
						{ type = H.parseTypeSuffixImpl(type_, beginParenLine, beginParenColumn), typePack = nil }
					)
				end
			elseif H.token_type == 62 and #params == 0 then
				break
			else
				table.insert(params, { type = H.parseTypeImpl(false), typePack = nil })
			end

			if H.token_type == 44 then
				if commaPosRef then
					table.insert(commaPosRef, vector.create(H.token_start_line, H.token_start_col))
				end
				H.nextLexeme()
			else
				break
			end
		end

		if H.expectMatchAndConsume(62, beginType, beginLine, beginColumn, false) and closingPosRef then
			closingPosRef[1] = vector.create(H.prev_start_line, H.prev_start_col)
		end
	end
	return params
end

-- // Explicit Type Instantiation

H.parseTypeInstantiationExpr = function ()	
local begin_type, begin_line, begin_col = H.token_type, H.token_start_line, H.token_start_col
	local leftArrow1 = (H.storeCstData and{(vector.create(H.token_start_line, H.token_start_col) )}or{nil
})[1]	H.nextLexeme()

	local leftArrow2Ref= H.storeCstData and{} or nil
	local commaPositions= H.storeCstData and{} or nil
	local rightArrow1Ref= H.storeCstData and{} or nil

	local typesOrPacks = H.parseTypeParamsImpl(leftArrow2Ref, commaPositions, rightArrow1Ref)

	local endStartLine, endStartColumn = H.token_start_line, H.token_start_col
	local endPosition = vector.create(H.token_end_line, H.token_end_col)
	local rightArrow2 = (H.storeCstData
and{(H.token_type == 62
and{(vector.create(endStartLine, endStartColumn)
)}or{(vector.create(0, 0)
)})[1]}or{nil
})[1]	H.expectMatchAndConsume(62, begin_type, begin_line, begin_col)

	local cstData= nil
	if leftArrow1 and leftArrow2Ref and commaPositions and rightArrow1Ref and rightArrow2 then
		cstData = {
			kind = "CstTypeInstantiation",
			leftArrow1Position = leftArrow1,
			leftArrow2Position = leftArrow2Ref[1],
			commaPositions = commaPositions,
			rightArrow1Position = rightArrow1Ref[1],
			rightArrow2Position = rightArrow2,
		}
	end

	if cstData then
		return typesOrPacks, cstData , endPosition
	end

	return typesOrPacks, nil, endPosition
end

H.reportAmbiguousCallError = function ()
	H.report(
		H.snapshot(),
		"Ambiguous syntax: this looks like an argument list for a function call, but could also be a start of new statement; use ';' to separate statements"
	)
end

H.reportFunctionArgsErrorImpl = function (func, selfCall)	
if selfCall and H.token_start_line ~= func.location.end_.x then
		return H.reportExprError(func.location , { func }, "Expected function call arguments after '('")
	else
		return H.reportExprError(
			{
				begin = func.location.begin,
				end_ = vector.create(H.token_start_line, H.token_start_col),
			},
			{ func },
			"Expected '(', '{' or <string> when parsing function call, got %s",
			H.ToString(H.token_type, H.token_string, H.token_codepoint)
		)
	end
end

-- args ::=  `(' [explist] `)' | tableconstructor | String
H.parseFunctionArgsImpl = function (func, selfCall)	
if H.token_type == 40 then
		local argStart = vector.create(H.token_end_line, H.token_end_col)
		if func.location.end_.x ~= H.token_start_line then
			H.reportAmbiguousCallError()
		end

		local paren_type, paren_line, paren_col = H.token_type, H.token_start_line, H.token_start_col
		H.nextLexeme()

		local args = H.EmptyArray 		
local commaPositions= H.storeCstData and{} or nil
		if H.token_type ~= 41 then
			args = {}
			H.parseExprListImpl(args, commaPositions)
		end

		local endLine, endColumn = H.token_end_line, H.token_end_col
		local closeParen= (H.storeCstData and{(vector.create(0, 0) )}or{nil
})[1]		if H.expectMatchAndConsume(41, paren_type, paren_line, paren_col) then
			if closeParen then
				closeParen = vector.create(H.prev_start_line, H.prev_start_col)
			end
		end

		local endPosition = vector.create(endLine, endColumn)
		local result = {
			kind = "ExprCall",
			location = { begin = func.location.begin, end_ = endPosition },
			func = func,
			args = args,
			self = selfCall,
			typeArguments = H.EmptyArray ,
			argLocation = { begin = argStart, end_ = endPosition },
		} 
		
if commaPositions and closeParen then
			result.cstNode = {
				kind = "CstExprCall",
				openParens = vector.create(paren_line, paren_col),
				closeParens = closeParen,
				commaPositions = commaPositions,
				explicitTypes = nil,
			}
		end

		return result
	elseif H.token_type == 123 then
		local argStart = vector.create(H.token_end_line, H.token_end_col)
		local expr = H.parseTableConstructorImpl()
		local argEnd = vector.create(H.prev_end_line, H.prev_end_col)

		local result = {
			kind = "ExprCall",
			location = {
				begin = func.location.begin,
				end_ = expr.location.end_,
			},
			func = func,
			args = { expr },
			self = selfCall,
			typeArguments = H.EmptyArray ,
			argLocation = {
				begin = argStart,
				end_ = argEnd,
			},
		} 
		
if H.storeCstData then
			result.cstNode = {
				kind = "CstExprCall",
				commaPositions = {},
				explicitTypes = nil,
			}
		end

		return result
	elseif H.token_type == 278 or H.token_type == 279 then
		local argLocation = H.snapshot()
		local expr = H.parseStringImpl()

		local result = {
			kind = "ExprCall",
			location = {
				begin = func.location.begin,
				end_ = expr.location.end_,
			},
			func = func,
			args = { expr },
			self = selfCall,
			typeArguments = H.EmptyArray ,
			argLocation = argLocation,
		} 
		
if H.storeCstData then
			result.cstNode = {
				kind = "CstExprCall",
				commaPositions = {},
				explicitTypes = nil,
			}
		end

		return result
	else
		return H.reportFunctionArgsErrorImpl(func, selfCall)
	end
end

H.parseExplicitTypeInstantiationExpr = function (
	start,
	basedOnExpr
)	
local typesOrPacks, cstInstantiation, endPosition = H.parseTypeInstantiationExpr()

	local expr = {
		kind = "ExprInstantiate",
		location = { begin = start, end_ = endPosition },
		expr = basedOnExpr,
		typeArguments = typesOrPacks,
	} 
	
if cstInstantiation then
		expr.cstNode = {
			kind = "CstExprExplicitTypeInstantiation",
			instantiation = cstInstantiation,
		}
	end

	return expr
end

-- primaryexp -> prefixexp { `.' NAME | `[' exp `]' | `:' NAME funcargs | funcargs }
H.parsePrimaryExprImpl = function (asStatement)	
local expr= H.parsePrefixExprImpl()

	local oldRecursion = H.recursionCounter

	while true do
		if H.token_type == 46 then
			local opPosition = vector.create(H.token_start_line, H.token_start_col)
			H.nextLexeme()

			local index, indexStartLine, indexStartColumn, indexEndLine, indexEndColumn =
				H.parseIndexNameScalars(nil, opPosition)
			local indexLocation = {
				begin = vector.create(indexStartLine, indexStartColumn),
				end_ = vector.create(indexEndLine, indexEndColumn),
			}

			expr = {
				kind = "ExprIndexName",
				location = { begin = expr.location.begin, end_ = indexLocation.end_ },
				expr = expr,
				index = index,
				indexLocation = indexLocation,
				opPosition = opPosition,
				op = 46,
			} 		
elseif H.token_type == 91 then
			local bracket_type, bracket_line, bracket_col = H.token_type, H.token_start_line, H.token_start_col
			H.nextLexeme()

			local index = H.ParserFunctions.parseExpr()
			local end_ = vector.create(H.token_end_line, H.token_end_col)
			local closeBracketLine, closeBracketColumn = 0, 0

			if H.expectMatchAndConsume(93, bracket_type, bracket_line, bracket_col) then
				closeBracketLine, closeBracketColumn = H.prev_start_line, H.prev_start_col
			end

			expr = {
				kind = "ExprIndexExpr",
				location = { begin = expr.location.begin, end_ = end_ },
				expr = expr,
				index = index,
			} 
			
if H.storeCstData then
				expr.cstNode = {
					kind = "CstExprIndexExpr",
					openBracketPosition = vector.create(bracket_line, bracket_col),
					closeBracketPosition = vector.create(closeBracketLine, closeBracketColumn),
				}
			end
		elseif H.token_type == 58 then
			local opPosition = vector.create(H.token_start_line, H.token_start_col)
			H.nextLexeme()

			local index, indexStartLine, indexStartColumn, indexEndLine, indexEndColumn =
				H.parseIndexNameScalars("method name", opPosition)
			local indexLocation = {
				begin = vector.create(indexStartLine, indexStartColumn),
				end_ = vector.create(indexEndLine, indexEndColumn),
			}

			local func = {
				kind = "ExprIndexName",
				location = { begin = expr.location.begin, end_ = indexLocation.end_ },
				expr = expr,
				index = index,
				indexLocation = indexLocation,
				opPosition = opPosition,
				op = 58,
			} 
			
local typeArgs= {}
			local cstInstantiation= nil

			if H.token_type == 60 and H.next_type == 60 then
				typeArgs, cstInstantiation = H.parseTypeInstantiationExpr()
			end

			local callExpr = H.parseFunctionArgsImpl(func, true)
			expr = callExpr

			if #typeArgs > 0 and callExpr.kind == "ExprCall" then
				callExpr.typeArguments = typeArgs
			end

			if H.storeCstData and cstInstantiation and (callExpr ).cstNode then
				(callExpr.cstNode ).explicitTypes = cstInstantiation
			end
		elseif H.token_type == 40 then
			-- This error is handled inside 'parseFunctionArgs' as well, but for better error recovery we need to break out the current loop here
			if not asStatement and expr.location.end_.x ~= H.token_start_line then
				H.reportAmbiguousCallError()
				break
			end
			expr = H.parseFunctionArgsImpl(expr, false)
		elseif H.token_type == 123 or H.token_type == 278 or H.token_type == 279 then
			expr = H.parseFunctionArgsImpl(expr, false)
		elseif H.token_type == 60 and H.next_type == 60 then
			expr = H.parseExplicitTypeInstantiationExpr(expr.location.begin, expr)
		else
			break
		end

		-- note: while the parser isn't recursive here, we're generating recursive structures of unbounded depth
		H.incrementRecursionCounter("expression")
	end

	H.recursionCounter = oldRecursion
	return expr
end

H.emptyReturnTypePack = function (location)	
return {
		kind = "TypePackExplicit",
		location = location,
		types = H.EmptyArray ,
		tailType = nil,
	} 
end

H.parseDeclaredExternTypeMethodImpl = function (attributes)	
local startLine, startColumn = H.token_start_line, H.token_start_col
	local startEndLine, startEndColumn = H.token_end_line, H.token_end_col
	H.nextLexeme()

	local fnName, nameStartLine, nameStartColumn, nameEndLine, nameEndColumn =
		H.parseNameScalars("function name")
	fnName = fnName or "%error-id%"
	local fnNameLocation = {
		begin = vector.create(nameStartLine, nameStartColumn),
		end_ = vector.create(nameEndLine, nameEndColumn),
	}

	local matchParenType = H.token_type
	local matchParenLine, matchParenColumn = H.token_start_line, H.token_start_col
	H.expectAndConsume(40, "function parameter list start")

	local args = {} 	
local vararg = false
	local varargAnnotation = nil 
	
if H.token_type ~= 41 then
		vararg, _, varargAnnotation = H.parseBindingList(args, true)
	end

	H.expectMatchAndConsume(41, matchParenType, matchParenLine, matchParenColumn)

	local retTypes = H.parseOptionalReturnTypeImpl(nil)
	if not retTypes then
		retTypes = H.emptyReturnTypePack(H.snapshot())
	end

	local methodLocation = {
		begin = vector.create(startLine, startColumn),
		end_ = vector.create(H.prev_end_line, H.prev_end_col),
	}

	if #args == 0 or args[1].name.value ~= "self" or args[1].annotation ~= nil then
		return {
			kind = "DeclaredExternTypeProperty",
			name = { value = fnName },
			nameLocation = fnNameLocation,
			type = H.reportTypeError(methodLocation, {}, "'self' must be present as the unannotated first parameter"),
			isMethod = true,
			location = methodLocation,
			access = "ReadWrite",
		} 	
end

	local params = {} 	
local paramNames = {} 
	
for i = 2, #args do
		local arg = args[i]
		table.insert(paramNames, { name = arg.name.value, location = arg.location })

		if arg.annotation then
			table.insert(params, arg.annotation)
		else
			table.insert(
				params,
				H.reportTypeError(methodLocation, {}, "All declaration parameters aside from 'self' must be annotated")
			)
		end
	end

	if vararg and not varargAnnotation then
		H.report(
			{
				begin = vector.create(startLine, startColumn),
				end_ = vector.create(startEndLine, startEndColumn),
			},
			"All declaration parameters aside from 'self' must be annotated"
		)
	end

	local fnType = {
		kind = "TypeFunction",
		location = methodLocation,
		attributes = attributes,
		generics = H.EmptyArray ,
		genericPacks = H.EmptyArray ,
		argTypes = {
			types = params,
			tailType = varargAnnotation,
		},
		argNames = paramNames,
		returnTypes = retTypes,
	} 
	
return {
		kind = "DeclaredExternTypeProperty",
		name = { value = fnName },
		nameLocation = fnNameLocation,
		type = fnType,
		isMethod = true,
		location = methodLocation,
		access = "ReadWrite",
	} 
end

-- TableIndexer ::= `[' Type `]' `:' Type
H.parseTableIndexerImpl = function (
	access,
	accessLoc,
	beginType,
	beginLine,
	beginColumn
)	
local index = H.parseTypeImpl(false)

	local indexerCloseLine, indexerCloseColumn = 0, 0
	if H.expectMatchAndConsume(93, beginType, beginLine, beginColumn) then
		indexerCloseLine, indexerCloseColumn = H.prev_start_line, H.prev_start_col
	end

	local colonLine, colonColumn = 0, 0
	if H.expectAndConsume(58, "table field") then
		colonLine, colonColumn = H.prev_start_line, H.prev_start_col
	end

	local result = H.parseTypeImpl(false)
	local beginPosition = vector.create(beginLine, beginColumn)

	local node = {
		kind = "TableIndexer",
		location = {
			begin = beginPosition,
			end_ = result.location.end_,
		},
		indexType = index,
		resultType = result,
		access = access,
		accessLocation = accessLoc,
	} 
	
return node, indexerCloseLine, indexerCloseColumn, colonLine, colonColumn
end

H.parseDeclarationImpl = function (start, attributes)	
if #attributes ~= 0 and H.token_type ~= 299 then
		return H.reportStatError(
			H.snapshot(),
			{},
			{},
			"Expected a function type declaration after attribute, but got %s instead",
			H.ToString(H.token_type, H.token_string, H.token_codepoint)
		)
	end

	if H.token_type == 299 then
		H.nextLexeme()

		local globalName, nameStartLine, nameStartColumn, nameEndLine, nameEndColumn =
			H.parseNameScalars("global function name")
		globalName = globalName or "%error-id%"
		local globalNameLocation = {
			begin = vector.create(nameStartLine, nameStartColumn),
			end_ = vector.create(nameEndLine, nameEndColumn),
		}
		local generics, genericPacks = H.parseGenericTypeListImpl(false)

		local matchParenType = H.token_type
		local matchParenLine, matchParenColumn = H.token_start_line, H.token_start_col
		H.expectAndConsume(40, "global function declaration")

		local args = {} 		
local vararg = false
		local varargLocation = nil 		
local varargAnnotation = nil 
		
if H.token_type ~= 41 then
			vararg, varargLocation, varargAnnotation = H.parseBindingList(args, true)
		end

		H.expectMatchAndConsume(41, matchParenType, matchParenLine, matchParenColumn)

		local retTypes = H.parseOptionalReturnTypeImpl(nil)
		local endStartLine, endStartColumn = H.token_start_line, H.token_start_col
		local endLine, endColumn = H.token_end_line, H.token_end_col
		if not retTypes then
			retTypes = H.emptyReturnTypePack({
				begin = vector.create(endStartLine, endStartColumn),
				end_ = vector.create(endLine, endColumn),
			})
		end

		local params = {} 		
local paramNames = {} 		
local declLocation = {
			begin = start.begin,
			end_ = vector.create(endLine, endColumn),
		}

		for _, arg in ipairs(args) do
			if not arg.annotation then
				return H.reportStatError(declLocation, {}, {}, "All declaration parameters must be annotated")
			end

			table.insert(params, arg.annotation)
			table.insert(paramNames, { name = arg.name.value, location = arg.location })
		end

		if vararg and not varargAnnotation then
			return H.reportStatError(declLocation, {}, {}, "All declaration parameters must be annotated")
		end

		return {
			kind = "StatDeclareFunction",
			location = declLocation,
			attributes = attributes,
			name = globalName,
			nameLocation = globalNameLocation,
			generics = generics,
			genericPacks = genericPacks,
			params = {
				types = params,
				tailType = varargAnnotation,
			},
			paramNames = paramNames,
			vararg = vararg,
			varargLocation = varargLocation,
			retTypes = retTypes,
		} 	
elseif
		H.token_type == 281
		and (
(H.LuauDisallowExternClassInTypeDefinitions
and{(H.token_string == "extern"
)}or{(
					H.token_string == "extern"
					or (
						H.token_string == "class"
						and ((H.LuauAllowGlobalDeclarationToBeCalledClass and{(H.next_type ~= 58 )}or{true})[1])
					)
				)
})[1]		)
	then
		local foundExtern = false

		if H.token_string == "extern" then
			if not H.LuauDisallowExternClassInTypeDefinitions then
				foundExtern = true
			end

			H.nextLexeme()

			if H.token_type ~= 281 or H.token_string ~= "type" then
				return H.reportStatError(
					H.snapshot(),
					{},
					{},
					"Expected `type` keyword after `extern`, but got %s instead",
					H.ToString(H.token_type, H.token_string, H.token_codepoint)
				)
			end
		end

		H.nextLexeme()

		local typeStartLine, typeStartColumn = H.token_start_line, H.token_start_col
		local typeName = H.parseNameScalars("type name")
		typeName = typeName or "%error-id%"
		local superName = nil 
		
if H.token_type == 281 and H.token_string == "extends" then
			H.nextLexeme()
			superName = H.parseNameScalars("supertype name")
			superName = superName or "%error-id%"
		end

		if H.LuauDisallowExternClassInTypeDefinitions or foundExtern then
			if H.token_type == 281 and H.token_string == "with" then
				H.nextLexeme()
			else
				H.report(
					H.snapshot(),
					"Expected `with` keyword before listing properties of the external type, but got %s instead",
					H.ToString(H.token_type, H.token_string, H.token_codepoint)
				)
			end
		end

		local props = {} 		
local indexer = nil 
		
while H.token_type ~= 296 and H.token_type ~= 0 do
			local methodAttributes = {} 
			
if H.token_type == 284 or H.token_type == 285 then
				methodAttributes = H.parseAttributes()

				if H.token_type ~= 299 then
					return H.reportStatError(
						H.snapshot(),
						{},
						{},
						"Expected a method type declaration after attribute, but got %s instead",
						H.ToString(H.token_type, H.token_string, H.token_codepoint)
					)
				end
			end

			if H.token_type == 299 then
				table.insert(props, H.parseDeclaredExternTypeMethodImpl(methodAttributes))
			elseif H.token_type == 91 then
				local beginType = H.token_type
				local beginLine, beginColumn = H.token_start_line, H.token_start_col
				local beginEndLine, beginEndColumn = H.token_end_line, H.token_end_col
				H.nextLexeme()

				if (H.token_type == 278 or H.token_type == 279) and H.next_type == 93 then
					local beginLocation = {
						begin = vector.create(beginLine, beginColumn),
						end_ = vector.create(beginEndLine, beginEndColumn),
					}
					local nameLocation = H.snapshot()
					local chars = H.parseCharArrayImpl()
					local nameEnd = H.getprev()

					H.expectMatchAndConsume(93, beginType, beginLine, beginColumn)
					H.expectAndConsume(58, "property type annotation")
					local propType = H.parseTypeImpl(true)

					if chars and string.find(chars, "\0", 1, true) == nil then
						table.insert(
							props,
							{
								kind = "DeclaredExternTypeProperty",
								name = { value = chars },
								nameLocation = { begin = nameLocation.begin, end_ = nameEnd.end_ },
								type = propType,
								isMethod = false,
								location = { begin = beginLocation.begin, end_ = propType.location.end_ },
								access = "ReadWrite",
							} 						
)
					else
						H.report(beginLocation, "String literal contains malformed escape sequence or \\0")
					end
				elseif indexer then
					local badIndexer = H.parseTableIndexerImpl("ReadWrite", nil, beginType, beginLine, beginColumn)
					H.report(badIndexer.location, "Cannot have more than one indexer on an extern type")
				else
					indexer = H.parseTableIndexerImpl("ReadWrite", nil, beginType, beginLine, beginColumn)
				end
			else
				local access= "ReadWrite"
				local accessLocation = nil 
				
if H.token_type == 281 and H.next_type ~= 58 then
					if H.token_string == "read" then
						access = "Read"
						accessLocation = H.snapshot()
						H.nextLexeme()
					elseif H.token_string == "write" then
						access = "Write"
						accessLocation = H.snapshot()
						H.nextLexeme()
					else
						H.report(H.snapshot(), "Expected blank or 'read' or 'write' attribute, got '%s'", H.token_string or "")
						H.nextLexeme()
					end
				end

				local propStart = H.snapshot()
				local propName = H.parseNameOptImpl("property name")
				if not propName then
					break
				end

				H.expectAndConsume(58, "property type annotation")
				local propType = H.parseTypeImpl(true)

				table.insert(
					props,
					{
						kind = "DeclaredExternTypeProperty",
						name = propName.name,
						nameLocation = propName.location,
						type = propType,
						isMethod = false,
						location = { begin = propStart.begin, end_ = propType.location.end_ },
						access = access,
					} 				
)

				if accessLocation then
					props[#props].location.begin = accessLocation.begin
				end
			end

			if H.token_type == 44 or H.token_type == 59 then
				H.nextLexeme()
			end
		end

		local typeEndLine, typeEndColumn = H.token_end_line, H.token_end_col
		H.expectAndConsume(296, "extern type")

		return {
			kind = "StatDeclareExternType",
			location = {
				begin = vector.create(typeStartLine, typeStartColumn),
				end_ = vector.create(typeEndLine, typeEndColumn),
			},
			name = typeName,
			superName = superName,
			props = props,
			indexer = indexer,
		} 	
end

	local globalName = H.parseNameOptImpl("global variable name")
	if globalName then
		H.expectAndConsume(58, "global variable declaration")
		local type_ = H.parseTypeImpl(true)

		return {
			kind = "StatDeclareGlobal",
			location = { begin = start.begin, end_ = type_.location.end_ },
			name = globalName.name.value,
			nameLocation = globalName.location,
			type = type_,
		} 	
end

	return H.reportStatError(start, {}, {}, "declare must be followed by an identifier, 'function', or 'extern type'")
end

-- attributes local function Name funcbody
-- attributes function funcname funcbody
-- attributes `declare function' Name`(' [parlist] `)' [`:` Type]
-- declare Name '{' Name ':' attributes `(' [parlist] `)' [`:` Type] '}'
H.parseAttributeStatImpl = function ()	
local attributes, attributeStartLocation, cstAttrLists = H.parseAttributes()
	local type_ = H.token_type

	if type_ == 299 then
		return H.parseFunctionStatImpl(attributes, attributeStartLocation, cstAttrLists)
	elseif type_ == 302 then
		local keywordLocation = H.snapshot()
		return H.parseLocalImpl(
			attributeStartLocation or keywordLocation,
			keywordLocation.begin,
			attributes,
			cstAttrLists,
			false
		)
	elseif type_ == 281 and H.token_string == "const" then
		local keywordLocation = H.snapshot()
		H.nextLexeme()
		return H.parseLocalImpl(
			attributeStartLocation or keywordLocation,
			keywordLocation.begin,
			attributes,
			cstAttrLists,
			true
		)
	elseif H.LuauExportValueSyntax and type_ == 281 and H.token_string == "export" then
		local keywordLocation = H.snapshot()
		H.nextLexeme()
		return H.parseExportValueImpl(
			attributeStartLocation or keywordLocation,
			keywordLocation.begin,
			attributes,
			cstAttrLists
		)
	elseif H.options.allowDeclarationSyntax and type_ == 281 and H.token_string == "declare" then
		local expr = H.parsePrimaryExprImpl(true)
		return H.parseDeclarationImpl(expr.location, attributes)
	end

	return H.reportStatError(
		H.snapshot(),
		{},
		{},
		"Expected 'function', 'local function', 'local function', 'declare function' or a function type declaration after attribute, but got %s instead",
		H.ToString(H.token_type, H.token_string, H.token_codepoint)
	)
end

-- return [explist]
H.parseReturnImpl = function ()	
local startLine, startColumn = H.token_start_line, H.token_start_col
	local startEndLine, startEndColumn = H.token_end_line, H.token_end_col
	H.nextLexeme()

	if H.LuauExportValueSyntax and #H.functionStack == 1 then
		for _, exportLocation in ipairs(H.declaredExportBindings) do
			H.report(
				exportLocation,
				"Exporting values is not compatible with top-level return (export/return conflict)"
			)
			break
		end

		H.hasModuleReturn = true
	end

	local list= {}
	local commaPositions= H.storeCstData and{} or nil

	if not H.BlockFollow[H.token_type] and H.token_type ~= 59 then
		H.parseExprListImpl(list, commaPositions)
	end

	local end_= vector.create(startEndLine, startEndColumn)
	if #list > 0 then
		end_ = list[#list].location.end_
	end

	local node = {
		kind = "StatReturn",
		location = {
			begin = vector.create(startLine, startColumn),
			end_ = end_,
		},
		list = list,
	} 
	
if commaPositions then
		node.cstNode = {
			kind = "CstStatReturn",
			commaPositions = commaPositions,
		}
	end

	return node
end

-- type function Name `(' arglist `)' `=' funcbody `end'
H.parseTypeFunctionImpl = function (
	start,
	exported,
	typeKeywordLine,
	typeKeywordColumn
)	
local matchFunctionType = H.token_type
	local matchFunctionLine, matchFunctionColumn = H.token_start_line, H.token_start_col
	local matchFunctionEndLine, matchFunctionEndColumn = H.token_end_line, H.token_end_col
	H.nextLexeme()

	local errorsAtStart = #H.parseErrors

	-- parse the name of the type function
	local fnNameOpt = H.parseNameOptImpl("type function name")
	local fnName = fnNameOpt 
	
if fnName == nil then
		fnName = {
			name = { value = "%error-id%" },
			location = H.snapshot(),
		} 	
end

	H.matchRecovery[296]=H.matchRecovery[296]+ 1

	local oldTypeFunctionDepth = H.typeFunctionDepth
	H.typeFunctionDepth = #H.functionStack

	local body = H.parseFunctionBodyImpl(
		false,
		matchFunctionType,
		matchFunctionLine,
		matchFunctionColumn,
		matchFunctionEndLine,
		matchFunctionEndColumn,
		fnName.name.value,
		nil,
		nil,
		{},
		nil,
		false
	)

	H.typeFunctionDepth = oldTypeFunctionDepth
	H.matchRecovery[296]=H.matchRecovery[296]- 1

	local hasErrors = #H.parseErrors > errorsAtStart

	local node = {
		kind = "StatTypeFunction",
		location = {
			begin = start.begin,
			end_ = body.location.end_,
		},
		name = fnName.name.value,
		nameLocation = fnName.location,
		body = body,
		exported = exported,
		hasErrors = hasErrors,
	} 
	
if H.storeCstData then
		node.cstNode = {
			kind = "CstStatTypeFunction",
			typeKeywordPosition = vector.create(typeKeywordLine, typeKeywordColumn),
			functionKeywordPosition = vector.create(matchFunctionLine, matchFunctionColumn),
		}
	end

	return node
end

-- type Name [`<' varlist `>'] `=' Type
H.parseTypeAliasImpl = function (
	start,
	exported,
	typeKeywordLine,
	typeKeywordColumn
)	-- parsing a type function
	
if H.token_type == 299 then
		return H.parseTypeFunctionImpl(start, exported, typeKeywordLine, typeKeywordColumn)
	end

	-- parsing a type alias

	-- note: `type` token is already parsed for us, so we just need to parse the rest

	local nameOpt = H.parseNameOptImpl("type name")
	local name = nameOpt 
	-- Use error name if the name is missing
	
if not name then
		name = {
			name = { value = "%error-id%" },
			location = H.snapshot(),
		} 	
end

	local genericsCommaPos= H.storeCstData and{} or nil
	local genericsClosePos= H.storeCstData and{ vector.create(0, 0) } or nil
	local genericsOpenPos= H.storeCstData and{ vector.create(0, 0) } or nil

	local generics, genericPacks =
		H.parseGenericTypeListImpl(true, genericsOpenPos, genericsCommaPos, genericsClosePos)

	local equalsPosition= (H.storeCstData and{(vector.create(0, 0) )}or{nil
})[1]	if H.expectAndConsume(61, "type alias") then
		if equalsPosition then
			equalsPosition = vector.create(H.prev_start_line, H.prev_start_col)
		end
	end

	local type_ = H.parseTypeImpl()

	local node = {
		kind = "StatTypeAlias",
		location = { begin = start.begin, end_ = type_.location.end_ },
		name = name.name.value,
		nameLocation = name.location,
		generics = generics,
		genericPacks = genericPacks,
		type = type_,
		exported = exported,
	} 
	
if genericsOpenPos and genericsCommaPos and genericsClosePos and equalsPosition then
		node.cstNode = {
			kind = "CstStatTypeAlias",
			typeKeywordPosition = vector.create(typeKeywordLine, typeKeywordColumn),
			genericsOpenPosition = genericsOpenPos[1],
			genericsCommaPositions = genericsCommaPos,
			genericsClosePosition = genericsClosePos[1],
			equalsPosition = equalsPosition,
		}
	end

	return node
end

-- varlist `=' explist
H.parseAssignmentImpl = function (initial)	
if not H.isExprLValue(initial) then
		initial = (H.LuauExportValueSyntax
and{(H.reportLValueError(initial)
)}or{(H.reportExprError(initial.location, { initial }, "Assigned expression must be a variable or a field")
)})[1]	end

	local vars= { initial }
	local varsCommaPositions= H.storeCstData and{} or nil

	while H.token_type == 44 do
		if varsCommaPositions then
			table.insert(varsCommaPositions, vector.create(H.token_start_line, H.token_start_col))
		end
		H.nextLexeme()

		local expr = H.parsePrimaryExprImpl(true)
		if not H.isExprLValue(expr) then
			expr = (H.LuauExportValueSyntax
and{(H.reportLValueError(expr)
)}or{(H.reportExprError(expr.location, { expr }, "Assigned expression must be a variable or a field")
)})[1]		end
		table.insert(vars, expr)
	end

	local equalsLine, equalsColumn = 0, 0
	if H.expectAndConsume(61, "assignment") then
		equalsLine, equalsColumn = H.prev_start_line, H.prev_start_col
	end

	local values= {}
	local valuesCommaPositions= H.storeCstData and{} or nil
	H.parseExprListImpl(values, valuesCommaPositions)

	local end_ = values[#values].location

	local node = {
		kind = "StatAssign",
		location = { begin = initial.location.begin, end_ = end_.end_ },
		vars = vars,
		values = values,
	} 
	
if varsCommaPositions and valuesCommaPositions then
		node.cstNode = {
			kind = "CstStatAssign",
			varsCommaPositions = varsCommaPositions,
			equalsPosition = vector.create(equalsLine, equalsColumn),
			valuesCommaPositions = valuesCommaPositions,
		}
	end

	return node
end

-- var [`+=' | `-=' | `*=' | `/=' | `%=' | `^=' | `..='] exp
H.parseCompoundAssignmentImpl = function (initial, op)	
if not H.isExprLValue(initial) then
		initial = (H.LuauExportValueSyntax
and{(H.reportLValueError(initial)
)}or{(H.reportExprError(initial.location, { initial }, "Assigned expression must be a variable or a field")
)})[1]	end

	local opLine, opColumn = H.token_start_line, H.token_start_col
	H.nextLexeme()

	local value = H.ParserFunctions.parseExpr()

	local node = {
		kind = "StatCompoundAssign",
		location = { begin = initial.location.begin, end_ = value.location.end_ },
		op = op,
		var = initial,
		value = value,
	} 
	
if H.storeCstData then
		node.cstNode = {
			kind = "CstStatCompoundAssign",
			opPosition = vector.create(opLine, opColumn),
		}
	end

	return node
end

-- TypeList ::= Type [`,' TypeList] | ...Type
H.parseTypeListImpl = function (
	result,
	resultNames,
	commaPositions,
	nameColonPositions
)	
while true do
		if H.shouldParseTypePack() then
			return H.parseTypePackImpl()
		end

		if H.token_type == 281 and H.next_type == 58 then
			-- Fill in previous argument names with empty slots
			while #resultNames < #result do
				table.insert(resultNames, false)
				if nameColonPositions then
					table.insert(nameColonPositions, false)
				end
			end

			local name = {
				name = H.token_string ,
				location = H.snapshot(),
			}

			table.insert(resultNames, name)
			H.nextLexeme()

			if nameColonPositions then
				table.insert(nameColonPositions, vector.create(H.token_start_line, H.token_start_col))
			end

			H.expectAndConsume(58)
		elseif #resultNames > 0 then
			-- If we have a type with named arguments, provide elements for all types
			table.insert(resultNames, false)
			if nameColonPositions then
				table.insert(nameColonPositions, false)
			end
		end

		table.insert(result, H.parseTypeImpl(false))

		if H.token_type ~= 44 then
			break
		end

		if commaPositions then
			table.insert(commaPositions, vector.create(H.token_start_line, H.token_start_col))
		end
		H.nextLexeme()

		if H.token_type == 41 then
			H.report(H.snapshot(), "Expected type after ',' but got ')' instead")

			break
		end
	end
	return nil
end

-- TableProp ::= Name `:' Type
-- TablePropOrIndexer ::= TableProp | TableIndexer
-- PropList ::= TablePropOrIndexer {fieldsep TablePropOrIndexer} [fieldsep]
-- TableType ::= `{' PropList `}'
H.parseTableTypeImpl = function (inDeclarationContext)	
H.incrementRecursionCounter("type annotation")

	local props= {}
	local cstItems= H.storeCstData and{} or nil
	local indexer= nil

	local startLine, startColumn = H.token_start_line, H.token_start_col
	local matchBraceType = H.token_type
	local matchBraceLine, matchBraceColumn = H.token_start_line, H.token_start_col
	H.expectAndConsume(123, "table type")

	local isArray = false

	while H.token_type ~= 125 do
		local access= "ReadWrite"
		local accessLoc= nil

		if H.token_type == 281 and H.next_type ~= 58 then
			if H.token_string == "read" then
				accessLoc = H.snapshot()
				access = "Read"
				H.nextLexeme()
			elseif H.token_string == "write" then
				accessLoc = H.snapshot()
				access = "Write"
				H.nextLexeme()
			end
		end

		if H.token_type == 91 then
			local beginType = H.token_type
			local beginLine, beginColumn = H.token_start_line, H.token_start_col
			local beginEndLine, beginEndColumn = H.token_end_line, H.token_end_col
			H.nextLexeme()

			if (H.token_type == 278 or H.token_type == 279) and H.next_type == 93 then
				local beginLocation = {
					begin = vector.create(beginLine, beginColumn),
					end_ = vector.create(beginEndLine, beginEndColumn),
				}
				local style = 0
				local depth = 0
				if H.storeCstData then
					style, depth = H.extractStringDetails()
				end

				local stringLine, stringColumn = H.token_start_line, H.token_start_col
				local sourceString= nil
				if H.storeCstData then
					sourceString = H.token_string
				end

				local chars = H.parseCharArrayImpl()

				local indexerCloseLine, indexerCloseColumn = 0, 0
				if H.expectMatchAndConsume(93, beginType, beginLine, beginColumn) then
					indexerCloseLine, indexerCloseColumn = H.prev_start_line, H.prev_start_col
				end

				local colonLine, colonColumn = 0, 0
				if H.expectAndConsume(58, "table field") then
					colonLine, colonColumn = H.prev_start_line, H.prev_start_col
				end

				local type_ = H.parseTypeImpl()

				if chars and string.find(chars, "\0", 1, true) == nil then
					table.insert(
						props,
						{
							kind = "TableProp",
							name = { value = chars },
							location = beginLocation,
							type = type_,
							access = access,
							accessLocation = accessLoc,
						} 					
)

					if cstItems then
						local separator = H.tableSeparator()
						local cstString = {
							kind = "CstExprConstantString",
							sourceString = sourceString,
							quoteStyle = style,
							blockDepth = depth,
						}

						table.insert(
							cstItems,
							{
								kind = "StringProperty",
								indexerOpenPosition = beginLocation.begin,
								indexerClosePosition = vector.create(indexerCloseLine, indexerCloseColumn),
								colonPosition = vector.create(colonLine, colonColumn),
								separator = separator,
								separatorPosition = H.cstSeparatorPosition(separator),
								stringInfo = cstString,
								stringPosition = vector.create(stringLine, stringColumn),
							} 						
)
					end
				else
					H.report(beginLocation, "String literal contains malformed escape sequence or \\0")
				end
			else
				if indexer then
					local badIndexerRes = H.parseTableIndexerImpl(access, accessLoc, beginType, beginLine, beginColumn)
					H.report(badIndexerRes.location, "Cannot have more than one table indexer")
				else
					local idxNode, indexerCloseLine, indexerCloseColumn, colonLine, colonColumn =
						H.parseTableIndexerImpl(access, accessLoc, beginType, beginLine, beginColumn)
					indexer = idxNode

					if cstItems then
						local separator = H.tableSeparator()
						table.insert(
							cstItems,
							{
								kind = "Indexer",

								indexerOpenPosition = vector.create(beginLine, beginColumn),
								indexerClosePosition = vector.create(indexerCloseLine, indexerCloseColumn),
								colonPosition = vector.create(colonLine, colonColumn),
								separator = separator,
								separatorPosition = H.cstSeparatorPosition(separator),
							} 						
)
					end
				end
			end
		elseif #props == 0 and not indexer and not (H.token_type == 281 and H.next_type == 58) then
			local type_ = H.parseTypeImpl()
			isArray = true

			-- array-like table type: {T} desugars into {[number]: T}
			local index = {
				kind = "TypeReference",
				location = type_.location,
				name = "number",
				nameLocation = type_.location,
				hasParameterList = false,
				parameters = H.EmptyArray ,
			} 
			
indexer = {
				kind = "TableIndexer",
				location = type_.location,
				indexType = index,
				resultType = type_,
				access = access,
				accessLocation = accessLoc,
			} 			
break
		else
			local nameOpt = H.parseNameOptImpl("table field")
			if not nameOpt then
				break
			end

			local colonLine, colonColumn = 0, 0
			if H.expectAndConsume(58, "table field") then
				colonLine, colonColumn = H.prev_start_line, H.prev_start_col
			end

			local type_ = H.parseTypeImpl(inDeclarationContext)

			table.insert(
				props,
				{
					kind = "TableProp",
					name = nameOpt.name,
					location = nameOpt.location,
					type = type_,
					access = access,
					accessLocation = accessLoc,
				} 			
)

			if cstItems then
				local separator = H.tableSeparator()
				table.insert(
					cstItems,
					{
						kind = "Property",
						colonPosition = vector.create(colonLine, colonColumn),
						separator = separator,
						separatorPosition = H.cstSeparatorPosition(separator),
					} 				
)
			end
		end

		if H.token_type == 44 or H.token_type == 59 then
			H.nextLexeme()
		elseif H.token_type ~= 125 then
			break
		end
	end

	local endLine, endColumn = H.token_end_line, H.token_end_col
	if
		not H.expectMatchAndConsume(
			125,
			matchBraceType,
			matchBraceLine,
			matchBraceColumn,
			true
		)
	then
		endLine, endColumn = H.prev_end_line, H.prev_end_col
	end

	local node = {
		kind = "TypeTable",
		location = {
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(endLine, endColumn),
		},
		props = props,
		indexer = indexer,
	} 
	
if cstItems then
		node.cstNode = {
			kind = "CstTypeTable",
			items = cstItems,
			isArray = isArray,
		}
	end

	return node
end

H.parseFunctionTypeTailImpl = function (
	beginType,
	beginLocation,
	attributes,
	generics,
	genericPacks,
	params,
	paramNames,
	varargAnnotation
)	
H.incrementRecursionCounter("type annotation")

	if H.token_type == 58 then
		H.report(H.snapshot(), "Return types in function type annotations are written after '->' instead of ':'")

		H.nextLexeme()

		-- Users occasionally write '()' as the 'unit' type when they actually want to use 'nil', here we'll try to give a more specific error
	elseif H.token_type ~= 263 and #generics == 0 and #genericPacks == 0 and #params == 0 then
		H.report({
			begin = beginLocation.begin,
			end_ = vector.create(H.prev_end_line, H.prev_end_col),
		}, "Expected '->' after '()' when parsing function type; did you mean 'nil'?")

		return {
			kind = "TypeReference",
			location = beginLocation,
			name = "nil",
			nameLocation = beginLocation,
			hasParameterList = false,
			parameters = H.EmptyArray ,
		} 	
else
		H.expectAndConsume(263, "function type")
	end

	local returnType = H.ParserFunctions.parseReturnType()

	return {
		kind = "TypeFunction",
		location = {
			begin = beginLocation.begin,
			end_ = returnType.location.end_,
		},
		attributes = attributes,
		generics = generics,
		genericPacks = genericPacks,
		argTypes = {
			types = params,
			tailType = varargAnnotation,
		},
		argNames = paramNames,
		returnTypes = returnType,
	}
end

-- ReturnType ::= Type | `(' TypeList `)'
-- FunctionType ::= [`<' varlist `>'] `(' [TypeList] `)' `->` ReturnType
H.parseFunctionTypeImpl = function (
allowPack, attributes
)	
H.incrementRecursionCounter("type annotation")

	local forceFunctionType = (H.token_type == 60)
	local beginType = H.token_type
	local beginLocation = {
		begin = vector.create(H.token_start_line, H.token_start_col),
		end_ = vector.create(H.token_end_line, H.token_end_col),
	}

	local openGenPos= H.storeCstData and{ vector.create(0, 0) } or nil
	local genCommaPos= H.storeCstData and{} or nil
	local closeGenPos= H.storeCstData and{ vector.create(0, 0) } or nil

	local generics, genericPacks = H.parseGenericTypeListImpl(false, openGenPos, genCommaPos, closeGenPos)

	local paramStartType = H.token_type
	local paramStartLine, paramStartColumn = H.token_start_line, H.token_start_col
	local openArgsFound = H.expectAndConsume(40, "function parameters")
	local openArgsPosition = (H.storeCstData
and{(openArgsFound
and{(vector.create(paramStartLine, paramStartColumn)
)}or{(vector.create(0, 0)
)})[1]}or{nil
})[1]
	H.matchRecovery[263]=H.matchRecovery[263]+ 1

	local params = H.EmptyArray 	
local names = H.EmptyArray 	
local argCommaPos= H.storeCstData and{} or nil
	local nameColonPos= H.storeCstData and{} or nil

	local varargAnnotation= nil

	if H.token_type ~= 41 then
		params = {}
		names = {}
		varargAnnotation = H.parseTypeListImpl(params, names, argCommaPos, nameColonPos)
	end

	local closeArgsStartLine, closeArgsStartColumn = H.token_start_line, H.token_start_col
	local closeArgsEndLine, closeArgsEndColumn = H.token_end_line, H.token_end_col
	local closeArgsPosition= (H.storeCstData and{(vector.create(0, 0) )}or{nil
})[1]	if H.expectMatchAndConsume(41, paramStartType, paramStartLine, paramStartColumn, true) then
		if closeArgsPosition then
			closeArgsPosition = vector.create(closeArgsStartLine, closeArgsStartColumn)
		end
	end

	H.matchRecovery[263]=H.matchRecovery[263]- 1

	local paramTypes = params
	if #names > 0 then
		forceFunctionType = true
	end

	local returnTypeIntroducer = (H.token_type == 263 or H.token_type == 58)

	-- ot a function at all. Just a parenthesized type. Or maybe a type pack with a single element
	if #params == 1 and not varargAnnotation and not forceFunctionType and not returnTypeIntroducer then
		if allowPack then
			local node = {
				kind = "TypePackExplicit",
				location = beginLocation,
				types = paramTypes,
			} 
			
if argCommaPos and openArgsPosition and closeArgsPosition then
				node.cstNode = {
					kind = "CstTypePackExplicit",
					openParenthesesPosition = openArgsPosition,
					closeParenthesesPosition = closeArgsPosition,
					commaPositions = argCommaPos,
				}
			end

			return nil, node
		else
			local node = {
				kind = "TypeGroup",
				location = {
					begin = vector.create(paramStartLine, paramStartColumn),
					end_ = vector.create(closeArgsEndLine, closeArgsEndColumn),
				},
				type = params[1],
			} 
			
if closeArgsPosition then
				node.cstNode = {
					kind = "CstTypeGroup",
					closePosition = closeArgsPosition,
				}
			end

			return node, nil
		end
	end

	if not forceFunctionType and not returnTypeIntroducer and allowPack then
		local node = {
			kind = "TypePackExplicit",
			location = beginLocation,
			types = paramTypes,
			tailType = varargAnnotation,
		} 
		
if argCommaPos and openArgsPosition and closeArgsPosition then
			node.cstNode = {
				kind = "CstTypePackExplicit",
				openParenthesesPosition = openArgsPosition,
				closeParenthesesPosition = closeArgsPosition,
				commaPositions = argCommaPos,
			}
		end

		return nil, node
	end

	local returnArrowPosition =
(H.storeCstData and{(vector.create(H.token_start_line, H.token_start_col) )}or{nil
})[1]	local node = H.parseFunctionTypeTailImpl(
		beginType,
		beginLocation,
		attributes,
		generics,
		genericPacks,
		paramTypes,
		names,
		varargAnnotation
	)

	if
		openGenPos
		and genCommaPos
		and closeGenPos
		and nameColonPos
		and argCommaPos
		and openArgsPosition
		and closeArgsPosition
		and returnArrowPosition
		and node.kind == "TypeFunction"
	then
		node.cstNode = {
			kind = "CstTypeFunction",
			openGenericsPosition = openGenPos[1],
			genericsCommaPositions = genCommaPos,
			closeGenericsPosition = closeGenPos[1],
			openArgsPosition = openArgsPosition,
			argumentNameColonPositions = nameColonPos,
			argumentsCommaPositions = argCommaPos,
			closeArgsPosition = closeArgsPosition,
			returnArrowPosition = returnArrowPosition,
		}
	end

	return node, nil
end

H.checkUnaryConfusables = function ()	-- early-out: need to check if this is a possible confusable quickly
	
if H.token_type ~= 33 then
		return nil
	end

	H.report(H.snapshot(), "Unexpected '!'; did you mean 'not'?")

	return 0 -- UnaryOp.Not
end

H.checkBinaryConfusables = function (limit)	
local currentType = H.token_type

	-- arly-out: need to check if this is a possible confusable quickly
	if currentType ~= 38 and currentType ~= 124 and currentType ~= 33 then
		return nil
	end

	-- slow path: possible confusable
	local startLine, startColumn = H.token_start_line, H.token_start_col
	local endLine, endColumn = H.token_end_line, H.token_end_col

	if
		currentType == 38
		and H.next_type == 38
		and endLine == H.next_start_line
		and endColumn == H.next_start_col
		and H.BinaryPriority[H.BinaryOp.And][1] > limit
	then
		H.nextLexeme()

		H.report({
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(H.token_end_line, H.token_end_col),
		}, "Unexpected '&&'; did you mean 'and'?")

		return H.BinaryOp.And
	elseif
		currentType == 124
		and H.next_type == 124
		and endLine == H.next_start_line
		and endColumn == H.next_start_col
		and H.BinaryPriority[H.BinaryOp.Or][1] > limit
	then
		H.nextLexeme()

		H.report({
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(H.token_end_line, H.token_end_col),
		}, "Unexpected '||'; did you mean 'or'?")

		return H.BinaryOp.Or
	elseif
		currentType == 33
		and H.next_type == 61
		and endLine == H.next_start_line
		and endColumn == H.next_start_col
		and H.BinaryPriority[H.BinaryOp.CompareNe][1] > limit
	then
		H.nextLexeme()

		H.report({
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(H.token_end_line, H.token_end_col),
		}, "Unexpected '!='; did you mean '~='?")

		return H.BinaryOp.CompareNe
	end

	return nil
end

H.digitValue = function (ch)	
if ch >= 48 and ch <= 57 then
		return ch - 48
	elseif ch >= 65 and ch <= 70 then
		return ch - 55
	elseif ch >= 97 and ch <= 102 then
		return ch - 87
	end

	return nil
end



 H.ParseResultOk= "Ok"
 H.ParseResultImprecise= "Imprecise"
 H.ParseResultHexOverflow= "HexOverflow"
 H.ParseResultBinOverflow= "BinOverflow"
 H.ParseResultIntOverflow= "IntOverflow"
 H.ParseResultMalformed= "Malformed"

H.parseInteger64Words = function (data, base, allowFullUint64)	
local low = 0
	local high = 0

	if #data == 0 then
		return 0, 0, H.ParseResultMalformed
	end

	for i = 1, #data do
		local ch = string.byte(data, i)
		local digit = H.digitValue(ch)
		if digit == nil or digit >= base then
			return 0, 0, H.ParseResultMalformed
		end

		if base == 2 then
			local lowCarry = bit32.rshift(low, 31)
			low = bit32.band(low * 2 + digit, 0xFFFFFFFF)

			if bit32.rshift(high, 31) ~= 0 then
				return 0, 0, H.ParseResultBinOverflow
			end

			high = bit32.band(high * 2 + lowCarry, 0xFFFFFFFF)
		else
			local lowCarry = bit32.rshift(low, 28)
			low = bit32.band(low * 16 + digit, 0xFFFFFFFF)

			if bit32.rshift(high, 28) ~= 0 then
				return 0, 0, H.ParseResultHexOverflow
			end

			high = bit32.band(high * 16 + lowCarry, 0xFFFFFFFF)
		end
	end

	if not allowFullUint64 and (high > 2147483647 or (high == 2147483647 and low > 4294967295)) then
		return 0, 0, H.ParseResultIntOverflow
	end

	return low, high, H.ParseResultOk
end

H.makeNumberNode = function (
	location,
	value,
	parseResult,
	sourceData
)	
local node= {
		kind = "ExprConstantNumber",
		location = location,
		value = value,
		parseResult = parseResult,
	}

	if H.storeCstData then
		node.cstNode = { kind = "CstExprConstantNumber", value = sourceData }
	end

	return node
end

H.parseNumberImpl = function ()	
local start = H.snapshot()
	local data = H.token_string or ""

	local sourceData= nil
	if H.storeCstData then
		sourceData = data
	end

	-- Remove internal '_'
	local cleanData = string.gsub(data, "_", "")

	if H.LuauIntegerType2 and string.sub(cleanData, -1) == "i" then
		local integerData = string.sub(cleanData, 1, -2)
		local low = 0
		local high = 0
		local parseResult= H.ParseResultOk

		if string.find(integerData, "^0[xX]") then
			low, high, parseResult = H.parseInteger64Words(string.sub(integerData, 3), 16, true)
		elseif string.find(integerData, "^0[bB]") then
			low, high, parseResult = H.parseInteger64Words(string.sub(integerData, 3), 2, true)
		else
			low, high, parseResult = H.parseInteger64Words(integerData, 10, false)
		end

		H.nextLexeme()

		if parseResult == H.ParseResultMalformed then
			return H.reportExprError(start, {}, "Malformed integer")
		end

		if parseResult ~= H.ParseResultOk then
			return H.reportExprError(start, {}, "Integer overflow")
		end

		local node = {
			kind = "ExprConstantInteger",
			location = start,
			low = low,
			high = high,
			parseResult = parseResult,
		} 
		
if H.storeCstData then
			node.cstNode = { kind = "CstExprConstantInteger", value = sourceData }
		end

		return node
	end

	local value = 0
	local parseResult= H.ParseResultOk

	-- Hexadecimal check (0x...)
	if string.find(cleanData, "^0[xX]") then
		local content = string.sub(cleanData, 3)
		local significant = string.match(content, "^0*(.+)") or "0"

		-- 16 Hex digits * 4 bits = 64 bits. Anything more is overflow for uint64.
		if #significant > 16 then
			parseResult = H.ParseResultHexOverflow
			value = 0
		else
			local v = tonumber(cleanData)
			if v then
				value = v
				if significant ~= "0" then
					local firstNibble = H.HexVal[string.byte(significant, 1)]
					if firstNibble then
						local headBits = firstNibble >= 8
and 4
or(
firstNibble >= 2 and 2
or(firstNibble >= 4 and 3
or 1
))						local bitLength = (#significant - 1) * 4 + headBits

						if bitLength > 53 then
							local requiredTrailingZeros = bitLength - 53
							local trailingZeros = 0

							for i = #significant, 1, -1 do
								local nibble = H.HexVal[string.byte(significant, i)]
								if nibble == nil then
									trailingZeros = -1
									break
								end

								if nibble == 0 then
									trailingZeros =trailingZeros+ 4
								else
									trailingZeros =trailingZeros+ (nibble == 0 and 32 or 31 - bit32.countlz(
										bit32.band(nibble, -nibble)
									)
)									break
								end
							end

							if trailingZeros < requiredTrailingZeros then
								parseResult = H.ParseResultImprecise
							end
						end
					else
						parseResult = H.ParseResultImprecise
					end
				end
			else
				parseResult = H.ParseResultMalformed
				value = 0
			end
		end
	elseif string.find(cleanData, "^0[bB][01]+") then
		local content = string.sub(cleanData, 3)
		local significant = string.match(content, "^0*(.+)") or "0"

		-- 64 bits max for uint64
		if #significant > 64 then
			parseResult = H.ParseResultBinOverflow
			value = 0
		else
			local v = tonumber(content, 2)
			if v then
				value = v
				local bitLength = #significant

				if bitLength > 53 then
					local requiredTrailingZeros = bitLength - 53
					local precise = true

					for i = bitLength, bitLength - requiredTrailingZeros + 1, -1 do
						if string.byte(significant, i) ~= 48 then -- '0'
							precise = false
							break
						end
					end

					if not precise then
						parseResult = H.ParseResultImprecise
					end
				end
			else
				parseResult = H.ParseResultMalformed
				value = 0
			end
		end
	else
		local v = tonumber(cleanData)
		value = v or 0

		if v then
			if value >= 9007199254740992 and string.find(cleanData, "^%d+$") then
				local repr = string.format("%.0f", value)
				if repr ~= cleanData then
					parseResult = H.ParseResultImprecise
				end
			end
		else
			parseResult = H.ParseResultMalformed
			value = 0
		end
	end

	H.nextLexeme()

	if parseResult == H.ParseResultMalformed then
		return H.reportExprError(start, {}, "Malformed number")
	end

	return H.makeNumberNode(start, value, parseResult, sourceData)
end

H.parseInterpStringImpl = function ()	local strings= {}
	local sourceStrings= H.storeCstData and{} or nil
	local stringPositions= H.storeCstData and{} or nil
	local expressions= {}

	local startLine, startColumn = H.token_start_line, H.token_start_col
	local endLine, endColumn = H.token_end_line, H.token_end_col

	while true do
		local currentType = H.token_type
		local currentStartLine, currentStartColumn = H.token_start_line, H.token_start_col
		endLine, endColumn = H.token_end_line, H.token_end_col

		local data = H.token_string or ""

		if sourceStrings and stringPositions then
			table.insert(sourceStrings, data)
			table.insert(stringPositions, vector.create(currentStartLine, currentStartColumn))
		end

		local ok, fixedData = H.fixupQuotedString(data)
		if not ok then
			H.nextLexeme()
			return H.reportExprError(
				{
					begin = vector.create(startLine, startColumn),
					end_ = vector.create(endLine, endColumn),
				},
				{},
				"Interpolated string literal contains malformed escape sequence"
			)
		end

		H.nextLexeme()
		table.insert(strings, fixedData )

		if currentType == 268 or currentType == 269 then
			break
		end

		local errorWhileChecking = false
		local t = H.token_type

		if t == 267 or t == 268 then
			errorWhileChecking = true
			H.nextLexeme()
			table.insert(
				expressions,
				H.reportExprError(
					{
						begin = vector.create(currentStartLine, currentStartColumn),
						end_ = vector.create(endLine, endColumn),
					},
					{},
					"Malformed interpolated string, expected expression inside '{}'"
				)
			)
		elseif t == 286 then
			errorWhileChecking = true
			H.nextLexeme()
			table.insert(
				expressions,
				H.reportExprError(
					{
						begin = vector.create(currentStartLine, currentStartColumn),
						end_ = vector.create(endLine, endColumn),
					},
					{},
					"Malformed interpolated string; did you forget to add a '`'?"
				)
			)
		else
			table.insert(expressions, H.ParserFunctions.parseExpr())
		end

		if errorWhileChecking then
			break
		end

		t = H.token_type

		if t == 266 or t == 267 or t == 268 then
		elseif H.token_type == 289 then
			H.nextLexeme()
			return H.reportExprError(
				{
					begin = vector.create(currentStartLine, currentStartColumn),
					end_ = vector.create(endLine, endColumn),
				},
				{},
				"Double braces are not permitted within interpolated strings; did you mean '\\{'?"
			)
		elseif H.token_type == 286 or H.token_type == 0 then
			if H.token_type == 286 then
				H.nextLexeme()
			end

			local node = {
				kind = "ExprInterpString",
				location = {
					begin = vector.create(startLine, startColumn),
					end_ = vector.create(H.prev_end_line, H.prev_end_col),
				},
				strings = strings,
				expressions = expressions,
			} 
			
if sourceStrings and stringPositions then
				node.cstNode =
					{ kind = "CstExprInterpString", sourceStrings = sourceStrings, stringPositions = stringPositions }
			end

			local top = (H.braceStackSize > 0 and{H.braceStack[H.braceStackSize] }or{nil
})[1]
			if top then
				if top == H.BraceType.InterpolatedString then
					H.report(H.getprev(), "Malformed interpolated string; did you forget to add a '}'?")
				end
			else
				H.report(H.getprev(), "Malformed interpolated string; did you forget to add a '`'?")
			end

			return node 		
else
			return H.reportExprError(
				{
					begin = vector.create(currentStartLine, currentStartColumn),
					end_ = vector.create(endLine, endColumn),
				},
				{},
				"Malformed interpolated string, got %s",
				H.ToString(H.token_type, H.token_string, H.token_codepoint)
			)
		end
	end

	local node = {
		kind = "ExprInterpString",
		location = {
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(endLine, endColumn),
		},
		strings = strings,
		expressions = expressions,
	} 
	
if sourceStrings and stringPositions then
		node.cstNode =
			{ kind = "CstExprInterpString", sourceStrings = sourceStrings, stringPositions = stringPositions }
	end

	return node 
end

H.parseIfElseExprImpl = function ()	
local hasElse = false
	local startLine, startColumn = H.token_start_line, H.token_start_col

	H.nextLexeme() -- skip if / elseif

	local condition = H.ParserFunctions.parseExpr()

	local thenLine, thenColumn = 0, 0
	local hasThen = H.expectAndConsume(308, "if then else expression")
	if hasThen then
		thenLine, thenColumn = H.prev_start_line, H.prev_start_col
	end

	local trueExpr = H.ParserFunctions.parseExpr()
	local falseExpr= nil

	local elseLine, elseColumn = H.token_start_line, H.token_start_col
	local isElseIf = false

	if H.token_type == 295 then
		local oldRecursion = H.recursionCounter
		H.incrementRecursionCounter("expression")
		hasElse = true
		falseExpr = H.parseIfElseExprImpl()
		H.recursionCounter = oldRecursion
		isElseIf = true
	else
		hasElse = H.expectAndConsume(294, "if then else expression")
		falseExpr = H.ParserFunctions.parseExpr()
	end

	local resolvedFalseExpr = falseExpr 
	
local node = {
		kind = "ExprIfElse",
		location = {
			begin = vector.create(startLine, startColumn),
			end_ = resolvedFalseExpr.location.end_,
		},
		condition = condition,
		hasThen = hasThen,
		trueExpr = trueExpr,
		hasElse = hasElse,
		falseExpr = resolvedFalseExpr,
	} 
	
if H.storeCstData then
		node.cstNode = {
			kind = "CstExprIfElse",
			thenPosition = vector.create(thenLine, thenColumn),
			elsePosition = vector.create(elseLine, elseColumn),
			isElseIf = isElseIf,
		}
	end

	return node
end

-- simpleexp -> NUMBER | STRING | NIL | true | boolean | ... | constructor | [attributes] FUNCTION body | primaryexp
H.parseSimpleExprImpl = function ()	
local attributes= nil
	local attributeStartLocation= nil
	local cstAttrLists= nil

	if H.token_type == 284 or H.token_type == 285 then
		attributes, attributeStartLocation, cstAttrLists = H.parseAttributes()

		if H.token_type ~= 299 then
			return H.reportExprError(
				attributeStartLocation ,
				{},
				"Expected 'function' declaration after attribute, but got %s instead",
				H.ToString(H.token_type, H.token_string, H.token_codepoint)
			)
		end
	end

	if H.token_type == 303 then
		local location = H.snapshot()
		H.nextLexeme()
		return {
			kind = "ExprConstantNil",
			location = location,
		}
	elseif H.token_type == 309 then
		local location = H.snapshot()
		H.nextLexeme()
		return {
			kind = "ExprConstantBool",
			location = location,
			value = true,
		}
	elseif H.token_type == 297 then
		local location = H.snapshot()
		H.nextLexeme()
		return {
			kind = "ExprConstantBool",
			location = location,
			value = false,
		}
	elseif H.token_type == 299 then
		local matchFunctionType = H.token_type
		local matchFunctionLine, matchFunctionColumn = H.token_start_line, H.token_start_col
		local matchFunctionEndLine, matchFunctionEndColumn = H.token_end_line, H.token_end_col
		H.nextLexeme()
		local node = H.parseFunctionBodyImpl(
			false,
			matchFunctionType,
			matchFunctionLine,
			matchFunctionColumn,
			matchFunctionEndLine,
			matchFunctionEndColumn,
			nil,
			nil,
			nil,
			attributes or (H.EmptyArray ),
			cstAttrLists,
			false
		)
		return node
	elseif H.token_type == 280 then
		return H.parseNumberImpl()
	elseif H.token_type == 278 or H.token_type == 279 or H.token_type == 269 then
		return H.parseStringImpl()
	elseif H.token_type == 266 then
		return H.parseInterpStringImpl()
	elseif H.token_type == 286 then
		local location = H.snapshot()
		H.nextLexeme()
		return H.reportExprError(location, {}, "Malformed string; did you forget to finish it?")
	elseif H.token_type == 289 then
		local location = H.snapshot()
		H.nextLexeme()
		return H.reportExprError(
			location,
			{},
			"Double braces are not permitted within interpolated strings; did you mean '\\{'?"
		)
	elseif H.token_type == 262 then
		local location = H.snapshot()
		if H.functionStack[#H.functionStack].vararg then
			H.nextLexeme()
			return {
				kind = "ExprVarargs",
				location = location,
			}
		else
			H.nextLexeme()
			return H.reportExprError(location, {}, "Cannot use '...' outside of a vararg function")
		end
	elseif H.token_type == 123 then
		return H.parseTableConstructorImpl()
	elseif H.token_type == 300 then
		return H.parseIfElseExprImpl()
	else
		return H.parsePrimaryExprImpl(false)
	end
end

-- asexp -> simpleexp [`::' Type]
H.parseAssertionExprImpl = function ()	
local startLine, startColumn = H.token_start_line, H.token_start_col
	local expr = H.parseSimpleExprImpl()

	if H.token_type == 264 then
		local opLine, opColumn = H.token_start_line, H.token_start_col
		H.nextLexeme()
		local annotation = H.parseTypeImpl()
		local node = {
			kind = "ExprTypeAssertion",
			location = {
				begin = vector.create(startLine, startColumn),
				end_ = annotation.location.end_,
			},
			expr = expr,
			annotation = annotation,
		} 
		
if H.storeCstData then
			node.cstNode = {
				kind = "CstExprTypeAssertion",
				opPosition = vector.create(opLine, opColumn),
			}
		end

		return node
	else
		return expr
	end
end

-- stat ::=
-- varlist `=' explist |
-- functioncall |
-- do block end |
-- while exp do block end |
-- repeat block until exp |
-- if exp then block {elseif exp then block} [else block] end |
-- for binding `=' exp `,' exp [`,' exp] do block end |
-- for namelist in explist do block end |
-- function funcname funcbody |
-- attributes function funcname funcbody |
-- local function Name funcbody |
-- local attributes function Name funcbody |
-- local namelist [`=' explist]
-- laststat ::= return [explist] | break
H.parseStat = function ()	
local type_ = H.token_type

	if type_ == 300 then
		return H.parseIfImpl()
	elseif type_ == 311 then
		return H.parseWhileImpl()
	elseif type_ == 293 then
		return H.parseDoImpl()
	elseif type_ == 298 then
		return H.parseForImpl()
	elseif type_ == 306 then
		return H.parseRepeatImpl()
	elseif type_ == 299 then
		return H.parseFunctionStatImpl(H.EmptyArray , nil, nil)
	elseif type_ == 302 then
		local start = H.snapshot()
		return H.parseLocalImpl(start, start.begin, nil, nil, false)
	elseif type_ == 307 then
		return H.parseReturnImpl()
	elseif type_ == 292 then
		return H.parseBreakImpl()
	elseif type_ == 284 or type_ == 285 then
		return H.parseAttributeStatImpl()
	end

	local start_line, start_column = H.token_start_line, H.token_start_col
	local start_end_line, start_end_column = H.token_end_line, H.token_end_col
	local expr = H.parsePrimaryExprImpl(true)

	if expr.kind == "ExprCall" then
		return {
			kind = "StatExpr",
			location = expr.location,
			expr = expr,
		}
	end

	if H.token_type == 44 or H.token_type == 61 then
		return H.parseAssignmentImpl(expr)
	end

	local operator = H.CompoundLookup[H.token_type]
	if operator then
		return H.parseCompoundAssignmentImpl(expr, operator)
	end

	local ident = nil 	
if expr.kind == "ExprGlobal" then
		ident = expr.name
	elseif expr.kind == "ExprLocal" then
		ident = expr["local"] and expr["local"].name
	end

	if ident == "type" then
		return H.parseTypeAliasImpl(expr.location, false, expr.location.begin.x, expr.location.begin.y)
	end

	if H.DebugLuauUserDefinedClasses and ident == "class" then
		return H.parseClassStatImpl(expr.location, false)
	end

	if ident == "export" then
		if
			H.LuauExportValueSyntax
			and (
				H.token_type == 302
				or H.token_type == 299
				or (
					H.token_type == 281
					and (H.token_string == "const" or (H.DebugLuauUserDefinedClasses and H.token_string == "class"))
				)
			)
		then
			return H.parseExportValueImpl(expr.location, expr.location.begin, H.EmptyArray , nil)
		elseif H.token_type == 281 and H.token_string == "type" then
			local typeKeywordLine, typeKeywordColumn = H.token_start_line, H.token_start_col
			H.nextLexeme()
			return H.parseTypeAliasImpl(expr.location, true, typeKeywordLine, typeKeywordColumn)
		elseif not H.LuauExportValueSyntax and H.DebugLuauUserDefinedClasses and H.token_type == 281 and H.token_string == "class" then
			H.nextLexeme()
			return H.parseClassStatImpl(expr.location, true)
		end
	end

	if ident == "continue" then
		return H.parseContinueImpl(expr.location)
	end

	if ident == "const" then
		return H.parseLocalImpl(expr.location, expr.location.begin, nil, nil, true)
	end

	if H.options.allowDeclarationSyntax and ident == "declare" then
		return H.parseDeclarationImpl(expr.location, H.EmptyArray )
	end

	if
		start_line == H.token_start_line
		and start_column == H.token_start_col
		and start_end_line == H.token_end_line
		and start_end_column == H.token_end_col
	then
		H.nextLexeme()
	end

	return H.reportStatError(expr.location, { expr }, {}, "Incomplete statement: expected assignment or a function call")
end

-- ReturnType ::= Type | `(' TypeList `)'
H.parseReturnTypeImpl = function ()	
H.incrementRecursionCounter("type annotation")

	local begin_type, begin_line, begin_col = H.token_type, H.token_start_line, H.token_start_col
	local beginLocation = {
		begin = vector.create(begin_line, begin_col),
		end_ = vector.create(H.token_end_line, H.token_end_col),
	}

	if H.token_type ~= 40 then
		if H.shouldParseTypePack() then
			return H.parseTypePackImpl()
		else
			local type_ = H.parseTypeImpl(false)

			local node = {
				kind = "TypePackExplicit",
				location = type_.location,
				types = { type_ },
			} 
			
if H.storeCstData then
				node.cstNode = {
					kind = "CstTypePackExplicit",
				}
			end
			return node
		end
	end

	H.nextLexeme()

	H.matchRecovery[263]=H.matchRecovery[263]+ 1

	local result= {}
	local resultNames= {}
	local commaPositions= H.storeCstData and{} or nil
	local nameColonPositions= H.storeCstData and{} or nil

	local varargAnnotation= nil

	-- possibly () -> ReturnType
	if H.token_type ~= 41 then
		varargAnnotation = H.parseTypeListImpl(result, resultNames, commaPositions, nameColonPositions)
	end

	local endStartLine, endStartColumn = H.token_start_line, H.token_start_col
	local endLine, endColumn = H.token_end_line, H.token_end_col
	local closeParenPos= (H.storeCstData and{(vector.create(0, 0) )}or{nil
})[1]
	if H.expectMatchAndConsume(41, begin_type, begin_line, begin_col, true) then
		if closeParenPos then
			closeParenPos = vector.create(endStartLine, endStartColumn)
		end
	end

	H.matchRecovery[263]=H.matchRecovery[263]- 1

	if H.token_type ~= 263 and #resultNames == 0 then
		-- If it turns out that it's just '(A)', it's possible that there are unions/intersections to follow, so fold over it.
		if #result == 1 then
			-- TODO(CLI-140667): stop parsing type suffix when varargAnnotation != nullptr - this should be a parse error
			local inner			
if varargAnnotation == nil then
				local typeGroup = {
					kind = "TypeGroup",
					location = {
						begin = beginLocation.begin,
						end_ = vector.create(endLine, endColumn),
					},
					type = result[1],
				} 
				
if H.storeCstData then
					typeGroup.cstNode = {
						kind = "CstTypeGroup",
						closePosition = closeParenPos ,
					}
				end

				inner = typeGroup
			else
				inner = result[1]
			end

			local returnType = H.parseTypeSuffixImpl(inner, begin_line, begin_col)

			-- If parseType parses nothing, then returnType->location.end only points at the last non-type-pack
			-- type to successfully parse.  We need the span of the whole annotation.
			local endPos = (#result == 1
and{(vector.create(endLine, endColumn)
)}or{returnType.location.end_
})[1]
			local node = {
				kind = "TypePackExplicit",
				location = {
					begin = beginLocation.begin,
					end_ = endPos,
				},
				types = { returnType },
				tailType = varargAnnotation,
			} 
			
if H.storeCstData then
				node.cstNode = {
					kind = "CstTypePackExplicit",
				}
			end
			return node
		end

		local node = {
			kind = "TypePackExplicit",
			location = {
				begin = beginLocation.begin,
				end_ = vector.create(endLine, endColumn),
			},
			types = result,
			tailType = varargAnnotation,
		} 
		
if commaPositions then
			node.cstNode = {
				kind = "CstTypePackExplicit",
				openParenthesesPosition = beginLocation.begin,
				closeParenthesesPosition = closeParenPos ,
				commaPositions = commaPositions,
			}
		end
		return node
	end

	local returnArrowLine, returnArrowColumn = H.token_start_line, H.token_start_col
	local tail = H.parseFunctionTypeTailImpl(
		begin_type,
		beginLocation,
		H.EmptyArray ,
		H.EmptyArray ,
		H.EmptyArray ,
		result,
		resultNames,
		varargAnnotation
	)

	if commaPositions and nameColonPositions and tail.kind == "TypeFunction" then
		tail.cstNode = {
			kind = "CstTypeFunction",
			openGenericsPosition = vector.create(0, 0),
			genericsCommaPositions = {},
			closeGenericsPosition = vector.create(0, 0),
			openArgsPosition = beginLocation.begin,
			argumentNameColonPositions = nameColonPositions,
			argumentsCommaPositions = commaPositions,
			closeArgsPosition = closeParenPos ,
			returnArrowPosition = vector.create(returnArrowLine, returnArrowColumn),
		}
	end

	local node = {
		kind = "TypePackExplicit",
		location = {
			begin = beginLocation.begin,
			end_ = tail.location.end_,
		},
		types = { tail },
	} 
	
if H.storeCstData then
		node.cstNode = {
			kind = "CstTypePackExplicit",
		}
	end

	return node
end

-- Type ::= nil | Name[`.' Name] [ `<' Type [`,' ...] `>' ] | `typeof' `(' expr `)' | `{' [PropList] `}'
--   | [`<' varlist `>'] `(' [TypeList] `)' `->` ReturnType
H.parseSimpleTypeImpl = function (allowPack, inDeclarationContext)	
H.incrementRecursionCounter("type annotation")

	local startLine, startColumn = H.token_start_line, H.token_start_col
	local startEndLine, startEndColumn = H.token_end_line, H.token_end_col

	if H.token_type == 284 or H.token_type == 285 then
		if not inDeclarationContext then
			return H.reportTypeError(
				{
					begin = vector.create(startLine, startColumn),
					end_ = vector.create(startEndLine, startEndColumn),
				},
				{},
				"attributes are not allowed in declaration context"
			),
				nil
		else
			local attributes = H.parseAttributes()

			return H.parseFunctionTypeImpl(allowPack, attributes), nil
		end
	elseif H.token_type == 303 then
		local location = {
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(startEndLine, startEndColumn),
		}
		H.nextLexeme()

		return {
			kind = "TypeReference",
			location = location,
			name = "nil",
			nameLocation = location,
			hasParameterList = false,
			parameters = H.EmptyArray ,
		} ,
			nil
	elseif H.token_type == 309 then
		local location = {
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(startEndLine, startEndColumn),
		}
		H.nextLexeme()

		return {
			kind = "TypeSingletonBool",
			location = location,
			value = true,
		} ,
			nil
	elseif H.token_type == 297 then
		local location = {
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(startEndLine, startEndColumn),
		}
		H.nextLexeme()

		return {
			kind = "TypeSingletonBool",
			location = location,
			value = false,
		} ,
			nil
	elseif H.token_type == 278 or H.token_type == 279 then
		local style = 0
		local depth = 0
		local sourceString = nil 		
if H.storeCstData then
			style, depth = H.extractStringDetails()
			sourceString = H.token_string
		end

		local location = {
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(startEndLine, startEndColumn),
		}
		local chars = H.parseCharArrayImpl()
		if chars then
			local node = {
				kind = "TypeSingletonString",
				location = location,
				value = chars,
			} 
			
if H.storeCstData then
				node.cstNode = {
					kind = "CstTypeSingletonString",
					sourceString = sourceString,
					quoteStyle = style,
					blockDepth = depth,
				}
			end

			return node, nil
		else
			return H.reportTypeError(location, {}, "String literal contains malformed escape sequence"), nil
		end
	elseif H.token_type == 266 or H.token_type == 269 then
		local location = {
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(startEndLine, startEndColumn),
		}
		H.parseInterpStringImpl()

		return H.reportTypeError(location, {}, "Interpolated string literals cannot be used as types"), nil
	elseif H.token_type == 286 then
		local location = {
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(startEndLine, startEndColumn),
		}
		H.nextLexeme()
		return H.reportTypeError(location, {}, "Malformed string; did you forget to finish it?"), nil
	elseif H.token_type == 281 then
		local name, nameStartLine, nameStartColumn, nameEndLine, nameEndColumn = H.parseNameScalars("type name")
		name = name or "%error-id%"
		local nameLocation = {
			begin = vector.create(nameStartLine, nameStartColumn),
			end_ = vector.create(nameEndLine, nameEndColumn),
		}
		local prefix= nil
		local prefixLoc= nil
		local prefixPointPos= nil

		if H.token_type == 46 then
			if H.storeCstData then
				prefixPointPos = vector.create(H.token_start_line, H.token_start_col)
			end
			H.nextLexeme()
			prefix = name
			prefixLoc = nameLocation
			name, nameStartLine, nameStartColumn, nameEndLine, nameEndColumn =
				H.parseIndexNameScalars("field name", nameLocation.end_)
			name = name or "%error-id%"
			nameLocation = {
				begin = vector.create(nameStartLine, nameStartColumn),
				end_ = vector.create(nameEndLine, nameEndColumn),
			}
		elseif H.token_type == 262 then
			H.report(H.snapshot(), "Unexpected '...' after type name; type pack is not allowed in this context")

			H.nextLexeme()
		elseif name == "typeof" then
			local typeofBeginType = H.token_type
			local typeofBeginLine, typeofBeginColumn = H.token_start_line, H.token_start_col
			local openParenFound = H.expectAndConsume(40, "typeof type")
			local expr = H.ParserFunctions.parseExpr()
			local endStartLine, endStartColumn = H.token_start_line, H.token_start_col
			local endLine, endColumn = H.token_end_line, H.token_end_col
			local closeLine, closeColumn = 0, 0
			if H.expectMatchAndConsume(
				41,
				typeofBeginType,
				typeofBeginLine,
				typeofBeginColumn,
				false
			) then
				closeLine, closeColumn = endStartLine, endStartColumn
			end

			local node = {
				kind = "TypeTypeof",
				location = {
					begin = vector.create(startLine, startColumn),
					end_ = vector.create(endLine, endColumn),
				},
				expr = expr,
			} 
			
if H.storeCstData then
				node.cstNode = {
					kind = "CstTypeTypeof",
					openPosition = (openParenFound
and{(vector.create(typeofBeginLine, typeofBeginColumn)
)}or{(vector.create(0, 0))})[1],
					closePosition = vector.create(closeLine, closeColumn),
				}
			end
			return node, nil
		end

		local hasParams = false
		local params = H.EmptyArray 
		
local openPosRef = H.storeCstData and{ vector.create(0, 0) } or nil
		local commaPosRef = H.storeCstData and{} or nil
		local closePosRef = H.storeCstData and{ vector.create(0, 0) } or nil

		if H.token_type == 60 then
			hasParams = true
			params = H.parseTypeParamsImpl(openPosRef, commaPosRef, closePosRef)
		end

		local node = {
			kind = "TypeReference",
			location = {
				begin = vector.create(startLine, startColumn),
				end_ = vector.create(H.prev_end_line, H.prev_end_col),
			},
			prefix = prefix,
			name = name,
			prefixLocation = prefixLoc,
			nameLocation = nameLocation,
			hasParameterList = hasParams,
			parameters = params,
		} 
		
if H.storeCstData then
			node.cstNode = {
				kind = "CstTypeReference",
				prefixPointPosition = prefixPointPos,
				openParametersPosition = openPosRef and openPosRef[1] or nil,
				parametersCommaPositions = commaPosRef or {},
				closeParametersPosition = closePosRef and closePosRef[1] or nil,
			}
		end

		return node, nil
	elseif H.token_type == 123 then
		return H.parseTableTypeImpl(inDeclarationContext), nil
	elseif H.token_type == 40 or H.token_type == 60 then
		return H.parseFunctionTypeImpl(allowPack, H.EmptyArray )
	elseif H.token_type == 299 then
		local location = {
			begin = vector.create(startLine, startColumn),
			end_ = vector.create(startEndLine, startEndColumn),
		}
		H.nextLexeme()

		return H.reportTypeError(location, {}, "Using 'function' as a type annotation is not supported..."), nil
	else
		local astErrorLocation = {
			begin = vector.create(H.prev_end_line, H.prev_end_col),
			end_ = vector.create(startLine, startColumn),
		}
		local parseErrorLocation = {
			begin = vector.create(H.prev_end_line, H.prev_end_col),
			end_ = vector.create(startEndLine, startEndColumn),
		}

		return H.reportMissingTypeError(
			parseErrorLocation,
			astErrorLocation,
			"Expected type, got %s",
			H.ToString(H.token_type, H.token_string, H.token_codepoint)
		),
			nil
	end
end

-- subexpr -> (asexp | unop subexpr) { binop subexpr }
-- where `binop' is any binary operator with a priority higher than `limit'
H.parseExprImpl = function (limit_val)	
local limit= limit_val or 0
	local oldRecursion = H.recursionCounter

	-- this handles recursive calls to parseSubExpr/parseExpr
	H.incrementRecursionCounter("expression")

	local startLine, startColumn = H.token_start_line, H.token_start_col
	local startPosition= nil
	local expr= nil

	local uop= H.UnaryOpLookup[H.token_type] -- Fix: Lookup based on token type
	if not uop then
		uop = H.checkUnaryConfusables()
	end

	if uop then
		local opLine, opColumn = H.token_start_line, H.token_start_col
		startPosition = vector.create(startLine, startColumn)
		H.nextLexeme()

		local subexpr = H.ParserFunctions.parseExpr(8)

		expr = {
			kind = "ExprUnary",
			location = {
				begin = startPosition,
				end_ = subexpr.location.end_,
			},
			op = uop ,
			expr = subexpr,
		} 
		
if H.storeCstData then
			expr.cstNode = {
				kind = "CstExprOp",
				opPosition = vector.create(opLine, opColumn),
			}
		end
	else
		expr = H.parseAssertionExprImpl()
	end

	-- expand while operators have priorities higher than `limit'
	local op= H.BinaryOpLookup[H.token_type] or H.checkBinaryConfusables(limit)

	-- expand while operators have priorities higher than `limit'
	while op and H.BinaryPriority[op][1] > limit do
		local opLine, opColumn = H.token_start_line, H.token_start_col
		if not startPosition then
			startPosition = vector.create(startLine, startColumn)
		end
		H.nextLexeme()

		-- read sub-expression with higher priority
		local nextExpr = H.ParserFunctions.parseExpr(H.BinaryPriority[op][2])

		expr = {
			kind = "ExprBinary",
			location = {
				begin = startPosition,
				end_ = nextExpr.location.end_,
			},
			op = op ,
			left = expr ,
			right = nextExpr,
		} 
		
if H.storeCstData then
			expr.cstNode = {
				kind = "CstExprOp",
				opPosition = vector.create(opLine, opColumn),
			}
		end

		op = H.BinaryOpLookup[H.token_type] or H.checkBinaryConfusables(limit) -- Fix: Lookup based on token type

		-- note: while the parser isn't recursive here, we're generating recursive structures of unbounded depth
		H.incrementRecursionCounter("expression")
	end

	H.recursionCounter = oldRecursion
	return expr
end

H.ParserFunctions.parseStat = H.parseStat
H.ParserFunctions.parseReturnType = H.parseReturnTypeImpl
H.ParserFunctions.parseSimpleType = H.parseSimpleTypeImpl
H.ParserFunctions.parseExpr = H.parseExprImpl

H.parseChunk = function (sourceText, parseOptions)	
H.options = parseOptions
	H.captureComments = parseOptions.captureComments == true
	H.storeCstData = parseOptions.storeCstData == true

	H.buff_data = buffer.fromstring(sourceText)
	H.size = #sourceText

	H.offset = 0

	if parseOptions.parseFragment and parseOptions.parseFragment.resumePosition then
		H.line = parseOptions.parseFragment.resumePosition.x
		H.lineOffset = 0 - parseOptions.parseFragment.resumePosition.y
	else
		H.line = 0
		H.lineOffset = 0
	end

	local startColumn = 0 - H.lineOffset

	H.braceStack = {}
	H.braceStackSize = 0

	H.token_type = 0

	H.token_start_line = H.line
	H.token_start_col = startColumn
	H.token_end_line = H.line
	H.token_end_col = startColumn

	H.prev_start_line = H.line
	H.prev_start_col = startColumn
	H.prev_end_line = H.line
	H.prev_end_col = startColumn

	H.token_string = nil
	H.token_aux = nil
	H.token_codepoint = nil

	H.recursionCounter = 0

	H.commentLocations = H.EmptyArray 	
H.hotcomments = H.EmptyArray 	
H.parseErrors = H.EmptyArray 	
H.declaredExportBindings = H.EmptyArray 	
H.hasModuleReturn = false
	H.classesWithinModule = H.EmptyArray 
	
H.hotcommentHeader = true

	H.suspect_type = 0
	H.suspect_line = 0

	H.matchRecovery = table.create(312, 0)
	H.matchRecovery[0] = 1

	H.functionStack = {
		{ vararg = true, loopDepth = 0 },
	}

	if parseOptions.parseFragment then
		H.localStack = table.clone(parseOptions.parseFragment.localStack)
		H.localMap = table.clone(parseOptions.parseFragment.localMap)
	else
		H.localStack = {}
		H.localMap = {}
	end

	H.fillNext()
	H.nextLexeme()
	H.hotcommentHeader = false

	local localsBegin = #H.localStack
	local result = H.parseBlockNoScope()
	H.restoreLocals(localsBegin)

	if H.token_type ~= 0 then
		H.expectAndConsumeFail(0)
	end

	return result
end

-- Standalone lexer: tokenizes `sourceText` by driving the parser's own lex(),
-- returning every token (including comments) with its decoded value, raw text
-- and 0-indexed line/column positions. This is the shared token layer that
-- obfuscation modules consume instead of hand-rolling string/comment scanners.
H.LTokenName = function (t, data)
	if t == 0 then
		return "eof"
	elseif t < 256 then
		return string.format("'%s'", string.char(t))
	elseif H.ReversedKeywords[t] then
		return H.ReversedKeywords[t]
	else
		local s = H.ToString(t, data)
		if s and s:sub(1, 1) == "'" then
			return s:match("^'(.*)'$") or s
		end
		return t
	end
end

H.tokenize = function (sourceText)
	local tokens = {}
	H.buff_data = buffer.fromstring(sourceText)
	H.size = #sourceText
	H.offset = 0
	H.line = 0
	H.lineOffset = 0
	while true do
		H.lex(false)
		if H.next_type == 0 then
			break
		end
		tokens[#tokens + 1] = {
			type = H.next_type,
			name = H.LTokenName(H.next_type, H.next_string),
			value = H.next_string,
			codepoint = H.next_codepoint,
			begin = vector.create(H.next_start_line, H.next_start_col),
			end_ = vector.create(H.next_end_line, H.next_end_col),
		}
	end
	return tokens
end

return {
	parse = function(source, options)		
local parseOptions = options or {} 		
local success, result = pcall(H.parseChunk, source, parseOptions)
		local root = (success and{result }or{nil
})[1]		local lines = (success and{(H.token_end_line + (H.size > 0 and buffer.readu8(H.buff_data, H.size - 1) ~= 10 and 1 or 0 ))}or{0
})[1]
		return success and #H.parseErrors == 0,
			{
				root = (success and{root }or{nil})[1],
				lines = lines,
				commentLocations = H.commentLocations,
				hotcomments = H.hotcomments,
				errors = H.parseErrors,
			}
	end,

	BraceType = H.BraceType,
	QuoteStyle = H.QuoteStyle,
	
	UnaryOp = {
		Not = 0,
		Minus = 1,
		Len = 2,
	},
	
	BinaryOp = H.BinaryOp,
	CstQuotes = H.CstQuotes,
	tokenize = H.tokenize,
}
