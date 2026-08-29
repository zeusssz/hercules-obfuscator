-- Parser/Ast.lua
-- Utility layer over the .kind AST emitted by Parser/LuauParser.
--
-- The raw parser AST is a plain tree of node tables (each carrying `kind`) and
-- anonymous binding tables (carrying `name`). ExprLocal references and
-- declarations (StatLocal.vars, StatLocalFunction.name, ExprFunction.args,
-- StatFor.var, StatForIn.vars, StatCompoundAssign...) point at the SAME binding
-- table, so mutating a binding's `name` field renames every reference and
-- declaration in one step, exactly within its scope.
--
-- This module provides:
--   * generic traversal:   Ast.each, Ast.find, Ast.count
--   * structural rewrite:  Ast.rewrite (with per-field exclusions)
--   * node constructors:   Ast.bind, Ast.global, Ast.local_ref, Ast.index_name,
--     Ast.index_expr, Ast.local_, Ast.expr_stat, Ast.block, and helpers for the
--     expression/statement kinds consumers commonly build.
--
-- Node field names follow the renderer contract in Parser/AstRenderer.

local Ast = {}

local table_concat = table.concat
local table_insert = table.insert

-- Operators (ids match Parser/LuauParser's BINARY_TEXT / UNARY_TEXT maps).
Ast.OPS = {
    add = 0, sub = 1, mul = 2, div = 3, idiv = 4, mod = 5, pow = 6,
    concat = 7, neq = 8, eq = 9, lt = 10, lte = 11, gt = 12, gte = 13,
    _and = 14, _or = 15,
}
Ast.UNARY = { not_ = 0, neg = 1, len = 2 }
Ast.INDEX_DOT, Ast.INDEX_COLON = 46, 58

local function is_node(v)
    return type(v) == "table" and rawget(v, "kind") ~= nil
end

local function is_list(v)
    return type(v) == "table" and rawget(v, 1) ~= nil
end

--------------------------------------------------------------------------------
-- Traversal
--------------------------------------------------------------------------------

-- Visits every node (table with `kind`) reachable from `root` in pre-order.
-- Anonymous binding tables are traversed but never visited. Shared nodes are
-- visited once (cycle safe).
function Ast.each(root, fn)
    local seen = {}
    local function walk(v)
        if type(v) ~= "table" or seen[v] then return end
        seen[v] = true
        if v.kind then
            fn(v)
        end
        for _, child in pairs(v) do
            walk(child)
        end
    end
    walk(root)
    return root
end

function Ast.find(root, pred)
    local hit
    Ast.each(root, function(n)
        if not hit and pred(n) then hit = n end
    end)
    return hit
end

function Ast.count(root, pred)
    local n = 0
    Ast.each(root, function(node)
        if pred(node) then n = n + 1 end
    end)
    return n
end

--------------------------------------------------------------------------------
-- Structural rewrite
--------------------------------------------------------------------------------

-- Rebuilds the tree under `root` bottom-up. `fn(node)` may return a replacement
-- node (or nil for "unchanged"); the caller's returned table replaces the node
-- wherever it is referenced by its parent. Nodes are processed in place, so any
-- returned replacement must be a fresh node rather than the node itself.
--
-- opts.exclude: map of node kind -> { fieldName = true, ... }; the children of
-- those fields are copied through untouched (neither visited nor passed to fn).
-- Useful for assignment targets, which are not expression usages.
function Ast.rewrite(root, fn, opts)
    opts = opts or {}
    local exclude = opts.exclude or {}
    local seen = {}

    local function rewrite_value(v)
        if type(v) ~= "table" or seen[v] then return v end
        seen[v] = true
        if v[1] ~= nil then
            for i, item in ipairs(v) do
                if type(item) == "table" then
                    v[i] = rewrite_value(item)
                end
            end
            return v
        end
        if not v.kind then
            return v
        end
        local ex = exclude[v.kind]
        for k, child in pairs(v) do
            if type(child) == "table" and not (ex and ex[k]) then
                v[k] = rewrite_value(child)
            end
        end
        local rep = fn(v)
        return rep or v
    end

    return rewrite_value(root)
end

--------------------------------------------------------------------------------
-- Constructors
--------------------------------------------------------------------------------

-- Anonymous binding: shares identity with the declaration and every reference.
function Ast.bind(name)
    return { name = name }
end

function Ast.constant(value)
    local kind
    if type(value) == "number" then
        kind = "ExprConstantNumber"
    elseif type(value) == "string" then
        kind = "ExprConstantString"
    elseif type(value) == "boolean" then
        kind = "ExprConstantBool"
    else
        kind = "ExprConstantNil"
    end
    return { kind = kind, value = value }
end

function Ast.nil_()
    return { kind = "ExprConstantNil" }
end

function Ast.vararg()
    return { kind = "ExprVararg" }
end

function Ast.global(name)
    return { kind = "ExprGlobal", name = name }
end

function Ast.local_ref(binding)
    return { kind = "ExprLocal", ["local"] = binding }
end

function Ast.index_name(receiver, index, colon)
    return {
        kind = "ExprIndexName",
        expr = receiver,
        index = index,
        op = colon and Ast.INDEX_COLON or Ast.INDEX_DOT,
    }
end

function Ast.index_expr(receiver, index)
    return { kind = "ExprIndexExpr", expr = receiver, index = index }
end

function Ast.binary(op, left, right)
    return { kind = "ExprBinary", op = op, left = left, right = right }
end

function Ast.unary(op, expr)
    return { kind = "ExprUnary", op = op, expr = expr }
end

function Ast.group(expr)
    return { kind = "ExprGroup", expr = expr }
end

function Ast.call(func, args)
    return { kind = "ExprCall", func = func, args = args or {} }
end

-- args: list of binding tables; body: list of statements.
function Ast.function_(args, body, vararg)
    return {
        kind = "ExprFunction",
        args = args or {},
        body = Ast.block(body),
        vararg = vararg or false,
    }
end

function Ast.block(body)
    return { kind = "StatBlock", body = body or {} }
end

function Ast.local_(vars, values)
    return { kind = "StatLocal", vars = vars or {}, values = values or {} }
end

function Ast.expr_stat(expr)
    return { kind = "StatExpr", expr = expr }
end

function Ast.return_(list)
    return { kind = "StatReturn", list = list or {} }
end

function Ast.if_(condition, thenbody, elsebody)
    return {
        kind = "StatIf",
        condition = condition,
        thenbody = Ast.block(thenbody),
        elsebody = elsebody,
    }
end

function Ast.while_(condition, body)
    return { kind = "StatWhile", condition = condition, body = Ast.block(body) }
end

function Ast.repeat_(body, condition)
    return { kind = "StatRepeat", body = Ast.block(body), condition = condition }
end

function Ast.for_(var, from, to, step, body)
    return {
        kind = "StatFor",
        var = var,
        from = from,
        to = to,
        step = step,
        body = Ast.block(body),
    }
end

function Ast.forin(vars, values, body)
    return { kind = "StatForIn", vars = vars, values = values, body = Ast.block(body) }
end

function Ast.assign(vars, values)
    return { kind = "StatAssign", vars = vars, values = values or {} }
end

--------------------------------------------------------------------------------
-- Utility
--------------------------------------------------------------------------------

-- Renders the AST back to source text (convenience around Parser.render).
function Ast.render(root, opts)
    return require("Parser/AstRenderer").render(root, opts)
end

return Ast