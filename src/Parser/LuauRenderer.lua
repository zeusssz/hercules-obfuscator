local Renderer = {}
local math_floor, math_random = math.floor, math.random
local string_byte, string_format = string.byte, string.format
local table_concat = table.concat

local BinaryOps = { "+", "-", "*", "/", "//", "%", "^", "..", "~=", "==", "<", "<=", ">", ">=", "and", "or" }
local UnaryOps = { "not", "-", "#" }

local PREC = {
	["or"] = 1, ["and"] = 2,
	["<"] = 3, [">"] = 3, ["<="] = 3, [">="] = 3, ["~="] = 3, ["=="] = 3,
	[".."] = 5,
	["+"] = 6, ["-"] = 6,
	["*"] = 7, ["/"] = 7, ["%"] = 7,
	["^"] = 10,
}

local LUA_KEYWORDS = {
	['and'] = true, ['break'] = true, ['continue'] = true, ['do'] = true, ['else'] = true,
	['elseif'] = true, ['end'] = true, ['false'] = true, ['for'] = true, ['function'] = true,
	['if'] = true, ['in'] = true, ['local'] = true, ['nil'] = true, ['not'] = true, ['or'] = true,
	['repeat'] = true, ['return'] = true, ['then'] = true, ['true'] = true, ['typeof'] = true,
	['until'] = true, ['while'] = true
}

local EMPTY_ARR = {}

local function ensureSeparator(buf)
	if #buf == 0 then return end
	local last = buf[#buf]
	if #last == 0 then return end
	local lastChar = string_byte(last, #last)
	if (lastChar >= 48 and lastChar <= 57)
		or (lastChar >= 65 and lastChar <= 90)
		or (lastChar >= 97 and lastChar <= 122)
		or lastChar == 95
		or lastChar == 34 then
		buf[#buf + 1] = ";"
	end
end

local function arr(x)
	if x == nil then return EMPTY_ARR end
	return type(x) == "table" and x or {}
end

local function escStr(s)
	s = tostring(s == nil and "" or s)
	local out = {}
	for Index = 1, #s do
		local Char = s:sub(Index, Index)
		local ByteValue = string_byte(Char)
		if ByteValue == 92 then
			out[#out + 1] = "\\\\"
		elseif ByteValue == 34 then
			out[#out + 1] = '\\"'
		elseif ByteValue == 10 then
			out[#out + 1] = "\\n"
		elseif ByteValue == 13 then
			out[#out + 1] = "\\r"
		elseif ByteValue == 9 then
			out[#out + 1] = "\\t"
		elseif ByteValue < 32 or ByteValue > 126 then
			out[#out + 1] = string_format("\\x%02X", ByteValue)
		else
			out[#out + 1] = Char
		end
	end
	return table_concat(out)
end

local function isAlphaNum(c)
	return (c >= 97 and c <= 122) or (c >= 65 and c <= 90) or (c >= 48 and c <= 57) or c == 95
end

local function isAlphaNumChar(s)
	if #s == 0 then return false end
	return isAlphaNum(string_byte(s, 1))
end

local function fmtExprList(nodes, depth)
	nodes = arr(nodes)
	if #nodes == 0 then return "" end
	local out = fmtExpr(nodes[1], depth)
	for i = 2, #nodes do
		out =out.. ", " .. fmtExpr(nodes[i], depth)
	end
	return out
end

local function fmtNameList(nodes)
	nodes = arr(nodes)
	if #nodes == 0 then return "" end
	local out = nodes[1].name or ""
	for i = 2, #nodes do
		out =out.. ", " .. (nodes[i].name or "")
	end
	return out
end

local function fmtFieldList(fields, depth)
	fields = arr(fields)
	if #fields == 0 then return "" end
	local out = fmtField(fields[1], depth)
	for i = 2, #fields do
		out =out.. ", " .. fmtField(fields[i], depth)
	end
	return out
end

local indentCache = { "" }
local function indent(depth)
	if indentCache[depth] then return indentCache[depth] end
	local s = ""
	for _ = 1, depth do s =s.. "    " end
	indentCache[depth] = s
	return s
end

local function fmtBody(body, depth)
	body = arr(body)
	if #body == 0 then return "" end
	local lines = {}
	local prefix = indent(depth + 1)
	for _, stmt in next, body do
		local s = fmtStmt(stmt, depth + 1)
		if s ~= "" then
			for _, part in next, s:split("\n") do
				lines[#lines + 1] = prefix .. part
			end
		end
	end
	return table_concat(lines, "\n")
end

function fmtExpr(e, depth)
	if type(e) ~= "table" then return "nil" end
	local s = fmtExprInner(e, depth)
	if e.inParens then s = "(" .. s .. ")" end
	return s
end

function fmtExprInner(e, depth)
	if type(e) ~= "table" then return "nil" end
	local t = e.type
	if t == "Identifier" then
		return e.name or ""
	elseif t == "NumericLiteral" then
		return tostring(e.value ~= nil and e.value or e.raw)
	elseif t == "StringLiteral" then
		return '"' .. escStr(e.value) .. '"'
	elseif t == "BooleanLiteral" then
		return e.value and "true" or "false"
	elseif t == "NilLiteral" then
		return "nil"
	elseif t == "VarargLiteral" then
		return "..."
	elseif t == "BinaryExpression" or t == "LogicalExpression" then
		return fmtExpr(e.left, depth) .. " " .. (e.operator or "") .. " " .. fmtExpr(e.right, depth)
	elseif t == "UnaryExpression" then
		return (e.operator == "not" and (e.operator .. " ") or (e.operator or "")) .. fmtExpr(e.argument, depth)
	elseif t == "MemberExpression" then
		return fmtExprBase(e.base, depth) .. (e.indexer or ".") .. fmtIdentifier(e.identifier)
	elseif t == "IndexExpression" then
		return fmtExprBase(e.base, depth) .. "[" .. fmtExpr(e.index, depth) .. "]"
	elseif t == "CallExpression" then
		return fmtExpr(e.base, depth) .. "(" .. fmtExprList(e.arguments, depth) .. ")"
	elseif t == "MemberCallExpression" then
		return fmtExprBase(e.base, depth) .. ":" .. fmtIdentifier(e.method) .. "(" .. fmtExprList(e.arguments, depth) .. ")"
	elseif t == "StringCallExpression" then
		return fmtExpr(e.base, depth) .. " " .. fmtExpr(e.argument, depth)
	elseif t == "TableConstructorExpression" then
		return "{" .. fmtFieldList(e.fields, depth) .. "}"
	elseif t == "FunctionDeclaration" then
		return fmtFuncExpr(e, depth)
	elseif t == "IfExpression" then
		return "(if " .. fmtExpr(e.condition, depth) .. " then "
			.. fmtExpr(e.trueExpr, depth) .. " else "
			.. fmtExpr(e.falseExpr, depth) .. ")"
	end
	return "nil"
end

function fmtIdentifier(node)
	if type(node) ~= "table" then return "" end
	if node.type == "Identifier" then return node.name or "" end
	return fmtExpr(node, 0)
end

function fmtExprBase(e, depth)
	if type(e) ~= "table" then return "nil" end
	local needsParens = e.inParens and (
		e.type == "BinaryExpression"
		or e.type == "FunctionDeclaration"
		or e.type == "TableConstructorExpression"
		or e.type == "LogicalExpression"
		or e.type == "StringLiteral"
		or e.type == "NilLiteral"
	)
	if needsParens then return "(" .. fmtExpr(e, depth) .. ")" end
	return fmtExpr(e, depth)
end

function fmtField(f, depth)
	if type(f) ~= "table" then return "" end
	if f.type == "TableValue" then
		return fmtExpr(f.value, depth)
	elseif f.type == "TableKeyString" or f.type == "MapValue" then
		return fmtExpr(f.key, depth) .. "=" .. fmtExpr(f.value, depth)
	elseif f.type == "TableKey" then
		return "[" .. fmtExpr(f.key, depth) .. "]=" .. fmtExpr(f.value, depth)
	end
	return fmtExpr(f.value, depth)
end

function fmtFuncExpr(e, depth)
	local head = (e.inParens and "(" or "")
		.. (e.isLocal and "local " or "")
		.. "function"
	if e.identifier then
		head =head.. " " .. fmtExpr(e.identifier, depth + 1)
	end
	head =head.. "(" .. fmtExprList(e.parameters, depth + 1) .. ")"
	local tail = "\n" .. fmtBody(e.body, depth + 1) .. "\n" .. indent(depth) .. "end"
		.. (e.inParens and ")" or "")
	return head .. tail
end

function fmtStmt(s, depth)
	if type(s) ~= "table" then return "" end
	local t = s.type
	if t == "LocalStatement" then
		local init = arr(s.init)
		return "local " .. fmtNameList(s.variables)
			.. (#init > 0 and (" = " .. fmtExprList(init, depth)) or "")
	elseif t == "AssignmentStatement" then
		return fmtExprList(s.variables, depth) .. " = " .. fmtExprList(s.init, depth)
	elseif t == "CallStatement" then
		return fmtExpr(s.expression, depth)
	elseif t == "ReturnStatement" then
		return "return " .. fmtExprList(s.arguments, depth)
	elseif t == "IfStatement" then
		return fmtIf(s, depth)
	elseif t == "WhileStatement" then
		return "while " .. fmtExpr(s.condition, depth) .. " do\n"
			.. fmtBody(s.body, depth) .. "\n" .. indent(depth) .. "end"
	elseif t == "RepeatStatement" then
		return "repeat\n" .. fmtBody(s.body, depth) .. "\n" .. indent(depth)
			.. "until " .. fmtExpr(s.condition, depth)
	elseif t == "NumericForStatement" or t == "ForNumericStatement" then
		return "for " .. (s.variable and s.variable.name or "") .. "="
			.. fmtExpr(s.start, depth) .. "," .. fmtExpr(s["end"], depth)
			.. (s.step and (", " .. fmtExpr(s.step, depth)) or "")
			.. " do\n" .. fmtBody(s.body, depth) .. "\n" .. indent(depth) .. "end"
	elseif t == "GenericForStatement" or t == "ForGenericStatement" then
		return "for " .. fmtNameList(s.variables) .. " in "
			.. fmtExprList(s.iterators, depth) .. " do\n"
			.. fmtBody(s.body, depth) .. "\n" .. indent(depth) .. "end"
	elseif t == "DoStatement" then
		return "do\n" .. fmtBody(s.body, depth) .. "\n" .. indent(depth) .. "end"
	elseif t == "FunctionDeclaration" then
		return fmtFuncExpr(s, depth)
	elseif t == "BreakStatement" then
		return "break"
	elseif t == "ContinueStatement" then
		return "continue"
	elseif t == "LabelStatement" then
		return "::" .. (s.label and s.label.name or "") .. "::"
	elseif t == "GotoStatement" then
		return "goto " .. (s.label and s.label.name or "")
	end
	return ""
end

function fmtIf(s, depth)
	local clauses = arr(s.clauses)
	if #clauses == 0 then return "" end
	local out = ""
	for ci, cl in next, clauses do
		if ci > 1 then
			if cl.condition then
				out =out.. "\n" .. indent(depth) .. "elseif " .. fmtExpr(cl.condition, depth) .. " then\n"
			else
				out =out.. "\n" .. indent(depth) .. "else\n"
			end
		else
			out =out.. "if " .. fmtExpr(cl.condition, depth) .. " then\n"
		end
		out =out.. fmtBody(cl.body, depth)
	end
	return out .. "\n" .. indent(depth) .. "end"
end

-- Minified renderer
local pushExpr, pushExprWithParens, pushIdentifier, pushExprBase, pushExprList
local pushNameList, pushFieldList, pushField, pushTableConstructor, pushFuncExpr
local pushBody, pushStmt, pushIf

pushExpr = function(buf, state, e)
	if type(e) ~= "table" then
		buf[#buf + 1] = "nil"
		return
	end
	if e.inParens then
		buf[#buf + 1] = "("
	end
	local t = e.type
	if t == "Identifier" then
		buf[#buf + 1] = e.name or ""
	elseif t == "NumericLiteral" then
		buf[#buf + 1] = tostring(e.value ~= nil and e.value or e.raw)
	elseif t == "StringLiteral" then
		buf[#buf + 1] = '"'
		buf[#buf + 1] = escStr(e.value)
		buf[#buf + 1] = '"'
	elseif t == "BooleanLiteral" then
		buf[#buf + 1] = e.value and "true" or "false"
	elseif t == "NilLiteral" then
		buf[#buf + 1] = "nil"
	elseif t == "VarargLiteral" then
		buf[#buf + 1] = "..."
	elseif t == "BinaryExpression" or t == "LogicalExpression" then
		local op = e.operator or ""
		local needSpace = op == "and" or op == "or"
		pushExprWithParens(buf, state, e.left, PREC[e.operator] or 0, "left", e.operator)
		if needSpace then buf[#buf + 1] = " " end
		buf[#buf + 1] = op
		if needSpace then buf[#buf + 1] = " " end
		pushExprWithParens(buf, state, e.right, PREC[e.operator] or 0, "right", e.operator)
	elseif t == "UnaryExpression" then
		if e.operator == "not" then
			buf[#buf + 1] = "not "
		else
			buf[#buf + 1] = e.operator or ""
		end
		pushExprWithParens(buf, state, e.argument, 8, "right", "unary")
	elseif t == "CallExpression" then
		pushExprBase(buf, state, e.base)
		buf[#buf + 1] = "("
		pushExprList(buf, state, e.arguments)
		buf[#buf + 1] = ")"
	elseif t == "TableCallExpression" then
		pushExpr(buf, state, e.base)
		pushTableConstructor(buf, state, e.arguments)
	elseif t == "StringCallExpression" then
		pushExpr(buf, state, e.base)
		buf[#buf + 1] = " "
		pushExpr(buf, state, e.argument)
	elseif t == "MemberCallExpression" then
		pushExprBase(buf, state, e.base)
		buf[#buf + 1] = ":"
		buf[#buf + 1] = e.method and e.method.name or ""
		buf[#buf + 1] = "("
		pushExprList(buf, state, e.arguments)
		buf[#buf + 1] = ")"
	elseif t == "IndexExpression" then
		pushExprBase(buf, state, e.base)
		buf[#buf + 1] = "["
		pushExpr(buf, state, e.index)
		buf[#buf + 1] = "]"
	elseif t == "MemberExpression" then
		pushExprBase(buf, state, e.base)
		buf[#buf + 1] = e.indexer == ":" and ":" or "."
		buf[#buf + 1] = e.identifier and e.identifier.name or ""
	elseif t == "TableConstructorExpression" then
		pushTableConstructor(buf, state, e)
	elseif t == "FunctionDeclaration" then
		pushFuncExpr(buf, state, e)
	elseif t == "IfExpression" then
		buf[#buf + 1] = "(if "
		pushExpr(buf, state, e.condition)
		buf[#buf + 1] = " then "
		pushExpr(buf, state, e.trueExpr)
		buf[#buf + 1] = " else "
		pushExpr(buf, state, e.falseExpr)
		buf[#buf + 1] = ")"
	else
		buf[#buf + 1] = "nil"
	end
	if e.inParens then
		buf[#buf + 1] = ")"
	end
end

pushExprWithParens = function(buf, state, e, parentPrec, dir, parentOp)
	if type(e) ~= "table" then
		buf[#buf + 1] = "nil"
		return
	end
	local t = e.type
	local prec = 0
	if t == "BinaryExpression" or t == "LogicalExpression" then
		prec = PREC[e.operator] or 0
	elseif t == "UnaryExpression" then
		prec = 8
	end
	local needParens = false
	if prec > 0 and prec < parentPrec then
		needParens = true
	elseif prec == parentPrec and dir == "right" and parentOp ~= "+" and not (parentOp == "*" and (e.operator == "/" or e.operator == "*")) then
		needParens = true
	end
	if needParens then
		buf[#buf + 1] = "("
		pushExpr(buf, state, e)
		buf[#buf + 1] = ")"
	else
		pushExpr(buf, state, e)
	end
end

pushIdentifier = function(buf, node)
	if type(node) == "table" and node.type == "Identifier" then
		buf[#buf + 1] = node.name or ""
	else
		pushExpr(buf, {}, node)
	end
end

function pushExprBase(buf, state, e)
	if type(e) ~= "table" then
		buf[#buf + 1] = "nil"
		return
	end
	local needsParens = e.inParens and (
		e.type == "BinaryExpression"
		or e.type == "FunctionDeclaration"
		or e.type == "TableConstructorExpression"
		or e.type == "LogicalExpression"
		or e.type == "StringLiteral"
		or e.type == "NilLiteral"
	)
	if needsParens then buf[#buf + 1] = "(" end
	pushExpr(buf, state, e)
	if needsParens then buf[#buf + 1] = ")" end
end

function pushExprList(buf, state, nodes)
	nodes = arr(nodes)
	for i, n in next, nodes do
		if i > 1 then buf[#buf + 1] = "," end
		pushExpr(buf, state, n)
	end
end

pushNameList = function(buf, nodes)
	nodes = arr(nodes)
	for i, n in next, nodes do
		if i > 1 then buf[#buf + 1] = "," end
		buf[#buf + 1] = n.name or ""
	end
end

pushFieldList = function(buf, state, fields)
	fields = arr(fields)
	for i, f in next, fields do
		if i > 1 then buf[#buf + 1] = "," end
		pushField(buf, state, f)
	end
end

pushField = function(buf, state, f)
	if f.type == "TableValue" then
		pushExpr(buf, state, f.value)
	elseif f.type == "TableKeyString" or f.type == "MapValue" then
		pushExpr(buf, state, f.key)
		buf[#buf + 1] = "="
		pushExpr(buf, state, f.value)
	elseif f.type == "TableKey" then
		buf[#buf + 1] = "["
		pushExpr(buf, state, f.key)
		buf[#buf + 1] = "]"
		buf[#buf + 1] = "="
		pushExpr(buf, state, f.value)
	else
		pushExpr(buf, state, f.value)
	end
end

function pushTableConstructor(buf, state, e)
	buf[#buf + 1] = "{"
	pushFieldList(buf, state, arr(e.fields))
	buf[#buf + 1] = "}"
end

function pushFuncExpr(buf, state, e)
	if e.inParens then buf[#buf + 1] = "(" end
	if e.isLocal then buf[#buf + 1] = "local " end
	buf[#buf + 1] = "function"
	if e.identifier then
		buf[#buf + 1] = " "
		pushExpr(buf, state, e.identifier)
	end
	buf[#buf + 1] = "("
	local params = arr(e.parameters)
	for i, p in next, params do
		if i > 1 then buf[#buf + 1] = "," end
		if p.name then
			buf[#buf + 1] = p.name
		else
			buf[#buf + 1] = "..."
		end
	end
	buf[#buf + 1] = ")"
	pushBody(buf, state, e.body)
	ensureSeparator(buf)
	buf[#buf + 1] = "end"
	if e.inParens then buf[#buf + 1] = ")" end
end

function pushBody(buf, state, body)
	body = arr(body)
	for i, s in next, body do
		if i > 1 then buf[#buf + 1] = ";" end
		pushStmt(buf, state, s)
	end
end

function pushStmt(buf, state, s)
	if type(s) ~= "table" then return end
	local t = s.type
	if t == "LocalStatement" then
		local init = arr(s.init)
		buf[#buf + 1] = "local "
		pushNameList(buf, s.variables)
		if #init > 0 then
			buf[#buf + 1] = "="
			pushExprList(buf, state, init)
		end
	elseif t == "AssignmentStatement" then
		pushExprList(buf, state, s.variables)
		buf[#buf + 1] = "="
		pushExprList(buf, state, s.init)
	elseif t == "CallStatement" then
		pushExpr(buf, state, s.expression)
	elseif t == "ReturnStatement" then
		buf[#buf + 1] = "return"
		local args = arr(s.arguments)
		if #args > 0 then
			buf[#buf + 1] = " "
			pushExprList(buf, state, args)
		end
	elseif t == "IfStatement" then
		pushIf(buf, state, s)
	elseif t == "WhileStatement" then
		buf[#buf + 1] = "while"
		buf[#buf + 1] = " "
		pushExpr(buf, state, s.condition)
			buf[#buf + 1] = " do "
		pushBody(buf, state, s.body)
		ensureSeparator(buf)
		buf[#buf + 1] = "end"
	elseif t == "RepeatStatement" then
		buf[#buf + 1] = "repeat "
		pushBody(buf, state, s.body)
		ensureSeparator(buf)
		buf[#buf + 1] = "until "
		pushExpr(buf, state, s.condition)
	elseif t == "NumericForStatement" or t == "ForNumericStatement" then
		buf[#buf + 1] = "for "
		buf[#buf + 1] = s.variable and s.variable.name or ""
		buf[#buf + 1] = "="
		pushExpr(buf, state, s.start)
		buf[#buf + 1] = ","
		pushExpr(buf, state, s["end"])
		if s.step then
			buf[#buf + 1] = ","
			pushExpr(buf, state, s.step)
		end
		buf[#buf + 1] = " do "
		pushBody(buf, state, s.body)
		ensureSeparator(buf)
		buf[#buf + 1] = "end"
	elseif t == "GenericForStatement" or t == "ForGenericStatement" then
		buf[#buf + 1] = "for "
		pushNameList(buf, s.variables)
		buf[#buf + 1] = " in "
		pushExprList(buf, state, s.iterators)
		buf[#buf + 1] = " do "
		pushBody(buf, state, s.body)
		ensureSeparator(buf)
		buf[#buf + 1] = "end"
	elseif t == "DoStatement" then
		buf[#buf + 1] = "do "
		pushBody(buf, state, s.body)
		ensureSeparator(buf)
		buf[#buf + 1] = "end"
	elseif t == "FunctionDeclaration" then
		pushFuncExpr(buf, state, s)
	elseif t == "BreakStatement" then
		buf[#buf + 1] = "break"
	elseif t == "ContinueStatement" then
		buf[#buf + 1] = "continue"
	elseif t == "LabelStatement" then
		buf[#buf + 1] = "::"
		buf[#buf + 1] = s.label and s.label.name or ""
		buf[#buf + 1] = "::"
	elseif t == "GotoStatement" then
		buf[#buf + 1] = "goto "
		buf[#buf + 1] = s.label and s.label.name or ""
	end
end

function pushIf(buf, state, s)
	local clauses = arr(s.clauses)
	for ci, cl in next, clauses do
		if ci > 1 then
			if cl.condition then
				buf[#buf + 1] = "elseif "
				pushExpr(buf, state, cl.condition)
				buf[#buf + 1] = " then "
			else
				buf[#buf + 1] = "else "
			end
		else
			buf[#buf + 1] = "if "
			pushExpr(buf, state, cl.condition)
			buf[#buf + 1] = " then "
		end
		pushBody(buf, state, cl.body)
		ensureSeparator(buf)
	end
	buf[#buf + 1] = "end"
end

-- Minification passes
local function combinedMinifyPass(ast)
	local function walkAndMark(node)
		if type(node) ~= "table" then return end
		for k, v in next, node do
			if k ~= "globals" and k ~= "comments" then
				if type(v) == "table" then walkAndMark(v) end
			end
		end
	end

	walkAndMark(ast)
end

local function randomRenameLocals(ast)
	local localNameSet = {}
	local allLocalNodes = {}

	local function collect(node)
		if type(node) ~= "table" then return end
		if node.type == "Identifier" and node.isLocal then
			localNameSet[node.name] = true
			allLocalNodes[#allLocalNodes + 1] = node
		end
		for k, v in next, node do
			if k ~= "globals" and k ~= "comments" then
				collect(v)
			end
		end
	end

	collect(ast)

	local keepName = {}
	for _, g in next, arr(ast.globals) do
		keepName[g.name] = true
	end

	local reserved = {}
	for _, g in next, arr(ast.globals) do
		reserved[g.name] = true
	end
	for n in next, localNameSet do
		reserved[n] = true
	end

	local FIRST_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local NEXT_CHARS = FIRST_CHARS .. "0123456789_"

	local shuffledFirst = {}
	for i = 1, #FIRST_CHARS do shuffledFirst[i] = FIRST_CHARS:sub(i, i) end
	local shuffledNext = {}
	for i = 1, #NEXT_CHARS do shuffledNext[i] = NEXT_CHARS:sub(i, i) end

	local namePool = {}
	local poolIdx = 0
	local curLen = 1

	local function shuffleArray(arr)
		for i = #arr, 2, -1 do
			local j = math_random(1, i)
			arr[i], arr[j] = arr[j], arr[i]
		end
	end

	local function nextName()
		local function isUsed(name)
			return LUA_KEYWORDS[name] or reserved[name]
		end
		while poolIdx >= #namePool do
			local NextCharacterCount = #NEXT_CHARS
			local total = NextCharacterCount ^ (curLen - 1)
			local allNames = {}
			for fi = 1, #shuffledFirst do
				for ri = 0, total - 1 do
					local rest = ""
					local n = ri
					for _ = 1, curLen - 1 do
						rest = shuffledNext[(n % NextCharacterCount) + 1] .. rest
						n = math_floor(n / NextCharacterCount)
					end
					local name = shuffledFirst[fi] .. rest
					if not isUsed(name) then
						allNames[#allNames + 1] = name
					end
				end
			end
			shuffleArray(allNames)
			namePool = allNames
			poolIdx = 1
			curLen =curLen+ 1
		end
		local name = namePool[poolIdx]
		poolIdx =poolIdx+ 1
		return name
	end

	shuffleArray(shuffledFirst)
	shuffleArray(shuffledNext)

	local nameMap = {}
	for originalName in next, localNameSet do
		if keepName[originalName] then
			nameMap[originalName] = originalName
		else
			local randomName = nextName()
			nameMap[originalName] = randomName
			reserved[randomName] = true
		end
	end

	for _, node in next, allLocalNodes do
		if nameMap[node.name] then
			node.name = nameMap[node.name]
		end
	end

	for orig, randomName in next, nameMap do
		if orig ~= randomName then
			local found = false
			for _, g in next, arr(ast.globals) do
				if g.name == randomName then
					found = true
					break
				end
			end
			if not found then
				ast.globals[#ast.globals + 1] = { name = randomName }
			end
		end
	end
end

local function getWatermarkLines(ast)
	local lines = {}
	for _, c in next, arr(ast.comments) do
		if c.isWatermark then
			lines[#lines + 1] = c.raw or ("--" .. (c.value or ""))
		end
	end
	return lines
end

local function buildHeader(ast)
	local header = {}
	for _, line in next, getWatermarkLines(ast) do
		header[#header + 1] = line
	end
	for _, c in next, arr(ast.comments) do
		if not c.isWatermark then
			header[#header + 1] = c.raw or ("--" .. (c.value or ""))
		end
	end
	return header
end

function Renderer.renderMinified(ast)
	combinedMinifyPass(ast)
	randomRenameLocals(ast)

	local buf = {}
	local header = buildHeader(ast)
	if #header > 0 then
		buf[#buf + 1] = table_concat(header, "\n") .. "\n"
	end
	pushBody(buf, {}, arr(ast.body))
	return table_concat(buf)
end

function Renderer.renderPretty(ast)
	local body = fmtBody(arr(ast.body), 0)
	local header = buildHeader(ast)
	if #header > 0 then
		body = table_concat(header, "\n") .. "\n" .. body
	end
	return body
end

return Renderer
