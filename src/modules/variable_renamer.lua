-- modules/variable_renamer.lua
-- AST-based variable and builtin renaming.
--
-- Previously this module used fragile string scanning. It now parses the input
-- into Parser's .kind AST, mutates it (renaming binding tables in place and
-- aliasing builtin usages), and renders it back to Lua source.
--
-- Because ExprLocal references share the exact binding table object of their
-- declaration, renaming `binding.name` renames a variable everywhere it is
-- referenced, exactly within its lexical scope - no scope analysis is needed
-- and strings, comments, table keys, and property accesses are structurally
-- impossible to touch by mistake.
--
-- Public API: VariableRenamer.process(code, options)
--   options.min_length / options.max_length (8..12 unless overridden)
--   options.target ("lua" | "luau" | "glua")

local Ast = require("Parser/Ast")
local Parser = require("Parser")

local VariableRenamer = {}

-- Lua built-in functions that should be renamed
local BUILTINS = {
    "assert", "collectgarbage", "dofile", "error", "ipairs", "next",
    "pairs", "pcall", "print", "rawequal", "rawget", "rawlen", "rawset",
    "select", "tonumber", "tostring", "type", "unpack", "xpcall",
    -- math
    "math.abs", "math.acos", "math.asin", "math.atan", "math.ceil",
    "math.cos", "math.deg", "math.exp", "math.floor", "math.fmod",
    "math.huge", "math.log", "math.max", "math.min", "math.modf",
    "math.pi", "math.pow", "math.rad", "math.random", "math.randomseed",
    "math.sin", "math.sqrt", "math.tan",
    -- string
    "string.byte", "string.char", "string.dump", "string.find",
    "string.format", "string.gmatch", "string.gsub", "string.len",
    "string.lower", "string.match", "string.rep", "string.reverse",
    "string.sub", "string.upper",
    -- table
    "table.concat", "table.insert", "table.remove", "table.sort",
    "table.pack", "table.unpack",
    -- os
    "os.clock", "os.date", "os.difftime", "os.execute", "os.exit",
    "os.getenv", "os.remove", "os.rename", "os.setlocale", "os.time",
    "os.tmpname",
}

local RESERVED = {
    ["and"]=true, ["break"]=true, ["do"]=true, ["else"]=true, ["elseif"]=true,
    ["end"]=true, ["false"]=true, ["for"]=true, ["function"]=true, ["goto"]=true,
    ["if"]=true, ["in"]=true, ["local"]=true, ["nil"]=true, ["not"]=true,
    ["or"]=true, ["repeat"]=true, ["return"]=true, ["then"]=true, ["true"]=true,
    ["until"]=true, ["while"]=true,
}

local DEFAULT_MIN_LEN, DEFAULT_MAX_LEN = 8, 12

local function make_name_generator(min_len, max_len, reserved_names)
    local used = {}
    for name in pairs(reserved_names or {}) do
        used[name] = true
    end
    return function()
        local len = math.random(min_len or DEFAULT_MIN_LEN, max_len or DEFAULT_MAX_LEN)
        local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        while true do
            local name = ""
            for _ = 1, len do
                local idx = math.random(#charset)
                name = name .. charset:sub(idx, idx)
            end
            if not used[name] and not RESERVED[name] then
                used[name] = true
                return name
            end
        end
    end
end

-- Node kinds whose fields hold local binding tables.
local function is_binding_carrier(kind)
    return kind == "StatLocal"
        or kind == "StatLocalFunction"
        or kind == "ExprFunction"
        or kind == "StatFor"
        or kind == "StatForIn"
end

-- Extract the binding tables introduced by a carrier node. Returns a list.
local function carrier_bindings(node)
    if node.kind == "StatLocal" then
        return node.vars
    elseif node.kind == "StatLocalFunction" then
        return { node.name }
    elseif node.kind == "ExprFunction" then
        return node.args
    elseif node.kind == "StatFor" then
        if node.var then return { node.var } end
        return {}
    elseif node.kind == "StatForIn" then
        return node.vars
    end
    return {}
end

-- Flatten an assignment/definition target expression into a dotted name such as
-- "print" or "math.floor"; returns nil for non-identifier targets (t[k] = v).
local function flatten_target(node)
    if node.kind == "ExprGlobal" then
        return node.name
    elseif node.kind == "ExprIndexName" then
        local base = flatten_target(node.expr)
        if base then return base .. "." .. node.index end
    elseif node.kind == "ExprIndexExpr" then
        local base = flatten_target(node.expr)
        if base and node.index.kind == "ExprConstantString" then
            return base .. "." .. node.index.value
        end
    end
    return nil
end

-- A builtin called as `base.name`, looked up in `seen` (map of builtin -> true).
local function bind_builtin_expr(builtins_by_full, node)
    if node.kind == "ExprGlobal" then
        if not node.name:match("%.") and builtins_by_full[node.name] then
            return node.name
        end
        return nil
    elseif node.kind == "ExprIndexName" then
        local base = node.expr
        if node.op ~= Ast.INDEX_COLON
            and type(base) == "table" and base.kind == "ExprGlobal" then
            local key = base.name .. "." .. node.index
            if builtins_by_full[key] then return key end
        end
        return nil
    elseif node.kind == "ExprIndexExpr" then
        local base, idx = node.expr, node.index
        if type(base) == "table" and base.kind == "ExprGlobal"
            and type(idx) == "table" and idx.kind == "ExprConstantString" then
            local key = base.name .. "." .. idx.value
            if builtins_by_full[key] then return key end
        end
        return nil
    end
    return nil
end

function VariableRenamer.process(code, options)
    options = options or {}
    local min_len = options.min_length or DEFAULT_MIN_LEN
    local max_len = options.max_length or DEFAULT_MAX_LEN
    local target = options.target

    -- Filter BUILTINS for target language
    local builtins = BUILTINS
    if target == "luau" then
        -- In Luau, `type` is a keyword for type aliases and must not be renamed
        local filtered = {}
        for _, b in ipairs(BUILTINS) do
            if b ~= "type" then
                table.insert(filtered, b)
            end
        end
        builtins = filtered
    end

    local ok, parsed = Parser.parse(code)
    if not ok then
        -- Not valid (or parseable) Lua: leave the input untouched rather than
        -- risking a destructive partial transformation.
        return code
    end
    local root = parsed.root

    -- Step 1: Collect every local binding and its declaration name.
    local bindings = {}
    local seen_bindings = {}
    local local_names = {}
    Ast.each(root, function(node)
        if is_binding_carrier(node.kind) then
            for _, b in ipairs(carrier_bindings(node)) do
                if type(b) == "table" and b.name and not seen_bindings[b] then
                    seen_bindings[b] = true
                    table.insert(bindings, b)
                    local_names[b.name] = true
                end
            end
        end
    end)

    -- Step 2: Reserve all original local names and builtin simple names so the
    -- generator never emits a name that collides with an untouched identifier.
    local reserved_names = {}
    for name in pairs(local_names) do
        reserved_names[name] = true
    end
    for _, builtin in ipairs(builtins) do
        local simple_name = builtin:match("([^.]+)$")
        reserved_names[simple_name or builtin] = true
    end
    local gen_name = make_name_generator(min_len, max_len, reserved_names)

    -- Step 3: Create rename map for local variables and apply it in place.
    -- Distinct names are collected in discovery order so aliases below draw
    -- from an equally-shuffled stream as the legacy implementation.
    local rename_map = {}
    local seen_names = {}
    for _, b in ipairs(bindings) do
        local name = b.name
        if not seen_names[name] then
            seen_names[name] = true
            rename_map[name] = gen_name()
        end
        b.name = rename_map[name]
    end

    -- Step 4: Find builtins used in code and create alias map.
    -- A builtin whose name is defined or reassigned by the code (a global
    -- function definition, or an assignment target such as `print = nil` or
    -- `string.format = f`) must NOT be aliased: the alias would capture the
    -- value from before the reassignment and silently change behavior.
    local blocked = {}
    Ast.each(root, function(node)
        if node.kind == "StatAssign" then
            for _, v in ipairs(node.vars) do
                local full = flatten_target(v)
                if full then blocked[full] = true end
            end
        elseif node.kind == "StatCompoundAssign" then
            local full = flatten_target(node.var)
            if full then blocked[full] = true end
        elseif node.kind == "StatFunction" then
            local full = flatten_target(node.name)
            if full then blocked[full] = true end
        end
    end)
    local function is_blocked(builtin)
        if blocked[builtin] then return true end
        local base = builtin:match("^([^.]+)%.")
        if base then
            if blocked[base] then return true end
            local prefix = base:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1") .. "%."
            for name in pairs(blocked) do
                if name:match("^" .. prefix) then
                    return true
                end
            end
        end
        return false
    end

    local builtins_by_full = {}
    for _, builtin in ipairs(builtins) do
        builtins_by_full[builtin] = true
    end
    local builtin_map = {} -- full builtin name -> alias name
    local used_builtins = {}
    local seen = {}
    Ast.each(root, function(node)
        local key = bind_builtin_expr(builtins_by_full, node)
        if key and not seen[key] then
            seen[key] = true
            if not is_blocked(key) then
                local new_name = gen_name()
                builtin_map[key] = new_name
                table.insert(used_builtins, { original = key, new_name = new_name })
            end
        end
    end)

    -- Step 5: Replace expression-position builtin usages with alias references.
    -- Assignment targets (StatAssign.vars, StatCompoundAssign.var) and global
    -- function definitions (StatFunction.name) are NOT expression usages and
    -- must never be aliased - doing so would change what the code assigns to.
    local alias_bindings = {}
    for _, entry in ipairs(used_builtins) do
        alias_bindings[entry.original] = Ast.bind(entry.new_name)
    end
    Ast.rewrite(root, function(node)
        local key = bind_builtin_expr(builtins_by_full, node)
        if key and alias_bindings[key] then
            return Ast.local_ref(alias_bindings[key])
        end
        return nil
    end, {
        exclude = {
            StatAssign = { vars = true },
            StatCompoundAssign = { var = true },
            StatFunction = { name = true },
        },
    })

    -- Step 6: Prepend alias declarations, e.g.
    --   local a, b = print, math.floor
    if #used_builtins > 0 then
        local vars, values = {}, {}
        for _, entry in ipairs(used_builtins) do
            table.insert(vars, alias_bindings[entry.original])
            local base, index = entry.original:match("^([^.]+)%.(.+)$")
            if base then
                table.insert(values, Ast.index_name(Ast.global(base), index, false))
            else
                table.insert(values, Ast.global(entry.original))
            end
        end
        table.insert(root.body, 1, Ast.local_(vars, values))
    end

    -- Render back to source. Lua-family targets cannot use `x op= v`, so lower
    -- compound assignments; Luau keeps the `x op= v` spelling the parser saw.
    return Ast.render(root, { lower_compound = target ~= "luau" })
end

return VariableRenamer