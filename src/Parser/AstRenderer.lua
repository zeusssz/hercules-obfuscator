-- Parser/AstRenderer.lua
-- Emits Lua source text from the AST produced by Parser/LuauParser.
--
-- The transpiled Luau parser produces Luau's official AST shaped with `kind`
-- keys (StatBlock, StatLocal, ExprBinary, ...). The bundled Parser/LuauRenderer
-- was written against a different schema and cannot render this AST, so this
-- module is the canonical renderer for Parser output.
--
-- Design goals:
--   * Faithful: re-emitted source must compile and behave identically.
--   * Deterministic: identical output for a given resolved AST (no dependence
--     on the input's original whitespace, quote style, or number spelling).
--   * Configurable: opts selects formatting and language features.
--
-- opts:
--   opts.indent   (string, default "  ") the unit added per nesting level.
--   opts.allow_luau (boolean) reserved for future Luau-only feature emission;
--                    always renders Lua-compatible output today.

local AstRenderer = {}

local table_concat = table.concat
local string_format = string.format

--------------------------------------------------------------------------------
-- Precedence (Lua 5.x standard, matches the parser's expression grammar)
--------------------------------------------------------------------------------
local BINARY_PREC = {
    [15] = 1, -- Or
    [14] = 2, -- And
    [9] = 3, [8] = 3, [10] = 3, [11] = 3, [12] = 3, [13] = 3, -- == ~= < <= > >=
    [7] = 5,  -- ..
    [0] = 6, [1] = 6, -- + -
    [2] = 7, [3] = 7, [4] = 7, [5] = 7, -- * / // %
    [6] = 10, -- ^
}
local UNARY_PREC = 8
local POW_PREC = 10

local RIGHT_ASSOC = { [7] = true, [6] = true } -- .. and ^

local BINARY_TEXT = {
    [15] = "or", [14] = "and",
    [9] = "==", [8] = "~=", [10] = "<", [11] = "<=", [12] = ">", [13] = ">=",
    [7] = "..", [0] = "+", [1] = "-", [2] = "*", [3] = "/", [4] = "//", [5] = "%",
    [6] = "^",
}
local UNARY_TEXT = { [0] = "not", [1] = "-", [2] = "#" }
local COMPOUND_TEXT = {
    [0] = "+=", [1] = "-=", [2] = "*=", [3] = "/=", [4] = "//=", [5] = "%=",
    [6] = "^=", [7] = "..=",
}

local function num_to_literal(value)
    if type(value) ~= "number" then return tostring(value) end
    -- %g avoids trailing .0 noise; %.17g round-trips doubles safely.
    return string_format("%.17g", value):gsub("e%+", "e")
end

local function str_to_literal(value)
    return string_format("%q", value)
end

local render_expr

-- Parenthesize a sub-expression when the surrounding context needs stronger
-- binding than the child provides (respecting right-associativity).
local function render_expr_at(e, context_prec, is_right)
    if type(e) ~= "table" then return "" end
    if e.kind ~= "ExprBinary" then
        local body = render_expr(e)
        if e.kind == "ExprUnary" and context_prec > UNARY_PREC then
            return "(" .. body .. ")"
        end
        return body
    end
    local child_prec = BINARY_PREC[e.op] or 0
    local need
    if child_prec < context_prec then
        need = true
    elseif child_prec == context_prec then
        -- left-assoc: right child of same precedence needs parens unless the op
        -- is right-associative (then the right child is fine, left child isn't).
        need = is_right and (not RIGHT_ASSOC[child_prec])
    else
        need = false
    end
    if need then
        return "(" .. render_expr(e) .. ")"
    end
    return render_expr(e)
end

local function render_arguments(args)
    local parts = {}
    for _, a in ipairs(args) do
        parts[#parts + 1] = render_expr(a)
    end
    return table_concat(parts, ", ")
end

local function render_params(args, vararg)
    local parts = {}
    for _, a in ipairs(args) do
        parts[#parts + 1] = a.name or ""
    end
    if vararg then
        parts[#parts + 1] = "..."
    end
    return table_concat(parts, ", ")
end

local function render_local_bindings(names)
    local parts = {}
    for _, n in ipairs(names) do
        parts[#parts + 1] = n.name or ""
    end
    return table_concat(parts, ", ")
end

local function render_block_lines(block, indent_line)
    -- Accepts a StatBlock node (common) or a plain statement list.
    local stmts = (type(block) == "table" and block.body) or block or {}
    local lines = {}
    for _, st in ipairs(stmts) do
        local s = AstRenderer.render_stat(st, indent_line)
        if s ~= "" then
            lines[#lines + 1] = s
        end
    end
    return lines
end

local render_function

render_function = function(fn, ind)
    local head = "function(" .. render_params(fn.args, fn.vararg) .. ")"
    local child = AstRenderer.indent .. ind
    local inner = table_concat(render_block_lines(fn.body, child), "\n")
    if #inner == 0 then
        return head .. " end"
    end
    return head .. "\n" .. inner .. "\n" .. ind .. "end"
end

local function render_table_item(item)
    local kind = item.kind
    if kind == "List" then
        return render_expr(item.value)
    elseif kind == "Record" then
        local key_name
        if type(item.key) == "table" and item.key.kind == "ExprConstantString" then
            key_name = item.key.value
        else
            key_name = render_expr(item.key)
        end
        if key_name and key_name:match("^[%a_][%w_]*$") then
            return key_name .. " = " .. render_expr(item.value)
        end
        return "[" .. str_to_literal(key_name) .. "] = " .. render_expr(item.value)
    elseif kind == "General" then
        return "[" .. render_expr(item.key) .. "] = " .. render_expr(item.value)
    elseif kind == "Map" then
        return "[" .. render_expr(item.key) .. "] = " .. render_expr(item.value)
    else
        return render_expr(item.value)
    end
end

local function render_table(tbl)
    local parts = {}
    for _, it in ipairs(tbl.items) do
        parts[#parts + 1] = render_table_item(it)
    end
    if #parts == 0 then
        return "{}"
    end
    return "{ " .. table_concat(parts, ", ") .. " }"
end

render_expr = function(e)
    local kind = e.kind
    if kind == "ExprGlobal" then
        return e.name
    elseif kind == "ExprLocal" then
        return e["local"] and e["local"].name or ""
    elseif kind == "ExprConstantNumber" then
        return num_to_literal(e.value)
    elseif kind == "ExprConstantString" then
        return str_to_literal(e.value)
    elseif kind == "ExprConstantBool" then
        return e.value and "true" or "false"
    elseif kind == "ExprConstantNil" then
        return "nil"
    elseif kind == "ExprVarargs" or kind == "ExprVararg" then
        return "..."
    elseif kind == "ExprFunction" then
        return render_function(e, "")
    elseif kind == "ExprBinary" then
        local prec = BINARY_PREC[e.op] or 0
        local left = render_expr_at(e.left, prec, false)
        local right = render_expr_at(e.right, prec + (RIGHT_ASSOC[prec] and 0 or 1), true)
        return left .. " " .. BINARY_TEXT[e.op] .. " " .. right
    elseif kind == "ExprUnary" then
        local op = UNARY_TEXT[e.op]
        local arg = render_expr_at(e.expr, UNARY_PREC, true)
        if op == "not" then
            return "not " .. arg
        end
        return op .. arg
    elseif kind == "ExprGroup" then
        return "(" .. render_expr(e.expr) .. ")"
    elseif kind == "ExprCall" then
        return render_expr(e.func) .. "(" .. render_arguments(e.args) .. ")"
    elseif kind == "ExprIndexName" then
        if e.op == 58 then
            return render_expr(e.expr) .. ":" .. (e.index or "")
        end
        return render_expr(e.expr) .. "." .. (e.index or "")
    elseif kind == "ExprIndexExpr" then
        return render_expr(e.expr) .. "[" .. render_expr(e.index) .. "]"
    elseif kind == "ExprTable" then
        return render_table(e)
    elseif kind == "ExprIfElse" then
        return "(if " .. render_expr(e.condition) .. " then "
            .. render_expr(e.trueExpr) .. " else " .. render_expr(e.falseExpr) .. ")"
    elseif kind == "ExprTypeof" then
        return "typeof(" .. render_expr(e.expr) .. ")"
    end
    return ""
end

function AstRenderer.render_stat(st, ind)
    ind = ind or ""
    local I = AstRenderer.indent
    local head = ind
    local kind = st.kind

    if kind == "StatLocal" then
        local vars = render_local_bindings(st.vars)
        local init = ""
        if st.values and #st.values > 0 then
            init = " = " .. render_arguments(st.values)
        end
        return head .. "local " .. vars .. init
    elseif kind == "StatLocalFunction" then
        local name = st.name and st.name.name or ""
        local fn = st.func
        local child = ind .. I
        local inner = table_concat(render_block_lines(fn.body, child), "\n")
        local s = head .. "local function " .. name .. "(" .. render_params(fn.args, fn.vararg) .. ")"
        if #inner == 0 then
            return s .. " end"
        end
        return s .. "\n" .. inner .. "\n" .. ind .. "end"
    elseif kind == "StatFunction" then
        local fname = render_expr(st.name)
        local fn = st.func
        local child = ind .. I
        local inner = table_concat(render_block_lines(fn.body, child), "\n")
        local s = head .. "function " .. fname .. "(" .. render_params(fn.args, fn.vararg) .. ")"
        if #inner == 0 then
            return s .. " end"
        end
        return s .. "\n" .. inner .. "\n" .. ind .. "end"
    elseif kind == "StatAssign" then
        return head .. render_arguments(st.vars) .. " = " .. render_arguments(st.values)
    elseif kind == "StatCompoundAssign" then
        local var = render_expr(st.var)
        if AstRenderer.lower_compound then
            -- Lua targets cannot use `x op= v`; lower to `x = x op v`.
            return head .. var .. " = " .. var .. " " .. (BINARY_TEXT[st.op] or "") .. " " .. render_expr(st.value)
        end
        return head .. var .. " " .. (COMPOUND_TEXT[st.op] or "") .. " " .. render_expr(st.value)
    elseif kind == "StatExpr" then
        return head .. render_expr(st.expr)
    elseif kind == "StatBreak" then
        return head .. "break"
    elseif kind == "StatContinue" then
        return head .. "continue"
    elseif kind == "StatReturn" then
        if st.list and #st.list > 0 then
            return head .. "return " .. render_arguments(st.list)
        end
        return head .. "return"
    elseif kind == "StatIf" then
        return render_if_stat(st, ind)
    elseif kind == "StatWhile" then
        local child = ind .. I
        local inner = table_concat(render_block_lines(st.body, child), "\n")
        return head .. "while " .. render_expr(st.condition) .. " do\n"
            .. inner .. "\n" .. ind .. "end"
    elseif kind == "StatRepeat" then
        local child = ind .. I
        local inner = table_concat(render_block_lines(st.body, child), "\n")
        return head .. "repeat\n" .. inner .. "\n" .. ind .. "until " .. render_expr(st.condition)
    elseif kind == "StatFor" then
        local child = ind .. I
        local inner = table_concat(render_block_lines(st.body, child), "\n")
        local step = st.step and (", " .. render_expr(st.step)) or ""
        return head .. "for " .. (st.var and st.var.name or "") .. " = "
            .. render_expr(st.from) .. ", " .. render_expr(st.to) .. step .. " do\n"
            .. inner .. "\n" .. ind .. "end"
    elseif kind == "StatForIn" then
        local child = ind .. I
        local inner = table_concat(render_block_lines(st.body, child), "\n")
        return head .. "for " .. render_local_bindings(st.vars) .. " in "
            .. render_arguments(st.values) .. " do\n" .. inner .. "\n" .. ind .. "end"
    elseif kind == "StatBlock" then
        local child = ind .. I
        local inner = table_concat(render_block_lines(st.body, child), "\n")
        return head .. "do\n" .. inner .. "\n" .. ind .. "end"
    elseif kind == "StatGoto" then
        return head .. "goto " .. (st.label and st.label.name or "")
    elseif kind == "StatLabel" then
        return head .. "::" .. (st.label and st.label.name or "") .. "::"
    end
    return ""
end

function render_if_stat(st, ind)
    local I = AstRenderer.indent
    local out = {}
    local function emit_if(s)
        local child = ind .. I
        out[#out + 1] = ind .. "if " .. render_expr(s.condition) .. " then"
        out[#out + 1] = table_concat(render_block_lines(s.thenbody, child), "\n")
        return s.elsebody
    end
    local elsebody = emit_if(st)
    while type(elsebody) == "table" and elsebody.kind == "StatIf" do
        local child = ind .. I
        out[#out + 1] = ind .. "elseif " .. render_expr(elsebody.condition) .. " then"
        out[#out + 1] = table_concat(render_block_lines(elsebody.thenbody, child), "\n")
        elsebody = elsebody.elsebody
    end
    if type(elsebody) == "table" then
        local child = ind .. I
        out[#out + 1] = ind .. "else"
        out[#out + 1] = table_concat(render_block_lines(elsebody, child), "\n")
    end
    out[#out + 1] = ind .. "end"
    local parts = {}
    for _, l in ipairs(out) do
        if l ~= "" then parts[#parts + 1] = l end
    end
    return table_concat(parts, "\n")
end

function AstRenderer.render(ast, opts)
    opts = opts or {}
    AstRenderer.indent = opts.indent or "    "
    -- Language feature control. Lua (default) has no compound assignment, so
    -- lower Luau `x op= v` to `x = x op v`. Pass lower_compound=false to keep
    -- the Luau form for Luau targets.
    if opts.lower_compound ~= nil then
        AstRenderer.lower_compound = opts.lower_compound
    else
        AstRenderer.lower_compound = true
    end
    local lines = render_block_lines(ast, "")
    return table_concat(lines, "\n")
end

return AstRenderer
