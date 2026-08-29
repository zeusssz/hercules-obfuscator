-- tools/retranspile_parser_locals.lua
-- One-shot, rerunnable transform for src/Parser/LuauParser/init.lua.
--
-- The file is a Luau->Lua transpile whose top-level scope declares >200 live
-- locals (113 `local function` + 156 `local X = ...`). Stock Lua 5.4 and LuaJIT
-- refuse to compile any function with more than 200 simultaneously-active
-- locals, so `require("Parser")` crashes before a single token is parsed.
--
-- This tool rewrites every module-scope `local X = v` / `local function X(...)`
-- into fields of one namespace table (default name `H`):
--
--     local H = {}
--     H.lex       = function(...) ... end
--     H.buff_data = buffer.create(...)
--
-- and rewrites references to those names as H.<name>, skipping table-field keys,
-- `.name`/`:name` indices, and any identifier shadowed by a narrower scope. The
-- chunk then stays well under 200 active locals and loads everywhere.
--
-- Usage:  lua tools/retranspile_parser_locals.lua [in.lua] [out.lua]
-- (defaults: src/Parser/LuauParser/init.lua, same file; reruns are idempotent)

local NAMESPACE = "H"

local function read_file(path)
    local f = assert(io.open(path, "rb"))
    local data = f:read("*all")
    f:close()
    return data
end

local function write_file(path, data)
    local f = assert(io.open(path, "wb"))
    f:write(data)
    f:close()
end

-- ─── Tokenizer ────────────────────────────────────────────────────────────────
-- Reconstructs the source byte-for-byte when token texts are concatenated, so the
-- transform only ever replaces the *text* of individual tokens.

local TOKEN_IDENT, TOKEN_KEYWORD, TOKEN_NUMBER, TOKEN_STRING = 1, 2, 3, 4
local TOKEN_OPERATOR, TOKEN_WHITESPACE, TOKEN_COMMENT = 5, 6, 7

local KEYWORDS = {}
for _, w in ipairs {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
    "goto", "if", "in", "local", "nil", "not", "or", "repeat", "return",
    "then", "true", "until", "while",
} do
    KEYWORDS[w] = true
end

-- Multi-character operators must stay a SINGLE token so a lone `=` check is
-- unambiguous, `..` is never read as a `.` index, and `...` survives whole.
local MULTI_OPS = {
    [".."] = true, ["..."] = true,
    ["=="] = true, ["~="] = true, ["<="] = true, [">="] = true,
    ["//"] = true, ["<<"] = true, [">>"] = true,
    ["+="] = true, ["-="] = true, ["*="] = true, ["/="] = true,
    ["%="] = true, ["^="] = true, ["..="] = true,
}

local function tokenize(code)
    local tokens = {}
    local i, n = 1, #code

    local function wordc(c) return c ~= "" and c:match("^[%w_]$") ~= nil end
    local function numc(c) return c ~= "" and c:match("^[%d%x%.%a_]$") ~= nil end

    while i <= n do
        local c = code:sub(i, i)

        if c == "-" and code:sub(i + 1, i + 1) == "-" then
            if code:match("^%-%-%[(=*)%[", i) then
                local eq = code:match("^%-%-%[(=*)%[", i)
                local close = "]" .. string.rep("=", #eq) .. "]"
                local _, e = code:find(close, i + #eq + 4, true)
                e = e or n
                tokens[#tokens + 1] = { t = TOKEN_COMMENT, s = code:sub(i, e + #close - 1) }
                i = e + #close
            else
                local nl = code:find("\n", i)
                local e = (nl and (nl - 1)) or n
                tokens[#tokens + 1] = { t = TOKEN_COMMENT, s = code:sub(i, e) }
                i = e + 1
            end
        elseif c == '"' or c == "'" then
            local q = c
            local buf, j = { c }, i + 1
            while j <= n do
                local ch = code:sub(j, j)
                if ch == "\\" then
                    buf[#buf + 1] = ch .. (code:sub(j + 1, j + 1) or "")
                    j = j + 2
                elseif ch == q then
                    buf[#buf + 1] = ch
                    break
                else
                    buf[#buf + 1] = ch
                    j = j + 1
                end
            end
            tokens[#tokens + 1] = { t = TOKEN_STRING, s = table.concat(buf) }
            i = j + 1
        elseif c == "[" then
            local eq = code:match("^%[(=*)%[", i)
            if eq then
                local close = "]" .. string.rep("=", #eq) .. "]"
                local _, e = code:find(close, i + #eq + 2, true)
                e = e or n
                tokens[#tokens + 1] = { t = TOKEN_STRING, s = code:sub(i, e + #close - 1) }
                i = e + #close
            else
                tokens[#tokens + 1] = { t = TOKEN_OPERATOR, s = c }
                i = i + 1
            end
        elseif wordc(c) then
            local j = i
            while j <= n and wordc(code:sub(j, j)) do j = j + 1 end
            local word = code:sub(i, j - 1)
            tokens[#tokens + 1] = { t = KEYWORDS[word] and TOKEN_KEYWORD or TOKEN_IDENT, s = word }
            i = j
        elseif c:match("^%d") or (c == "." and code:sub(i + 1, i + 1):match("^%d")) then
            local j = i
            while j <= n do
                local ch = code:sub(j, j)
                if ch == "." and code:sub(j + 1, j + 1) == "." then
                    break
                elseif numc(ch) then
                    j = j + 1
                elseif (ch == "+" or ch == "-")
                    and code:sub(j - 1, j - 1):match("^[eEpP]$") then
                    j = j + 1
                else
                    break
                end
            end
            tokens[#tokens + 1] = { t = TOKEN_NUMBER, s = code:sub(i, j - 1) }
            i = j
        elseif c == " " or c == "\t" or c == "\r" or c == "\n" then
            local j = i
            while j <= n and code:sub(j, j):match("^[%s]$") do j = j + 1 end
            tokens[#tokens + 1] = { t = TOKEN_WHITESPACE, s = code:sub(i, j - 1) }
            i = j
        else
            local two = code:sub(i, i + 1)
            if two == ".." and code:sub(i + 2, i + 2) == "." then
                tokens[#tokens + 1] = { t = TOKEN_OPERATOR, s = "..." }
                i = i + 3
            elseif MULTI_OPS[two] then
                tokens[#tokens + 1] = { t = TOKEN_OPERATOR, s = two }
                i = i + 2
            else
                tokens[#tokens + 1] = { t = TOKEN_OPERATOR, s = c }
                i = i + 1
            end
        end
    end

    return tokens
end

-- ─── Scope-aware walker ───────────────────────────────────────────────────────
-- Mirrors Lua's lexical scoping far enough to classify every identifier as one of
--   * binding   (local n, local function n)  -> on_binding(idx, name, kind, top_level)
--   * key       (table-field key after { , ; ; index after . :) -> on_key(idx, name)
--   * reference (everything else, H.<name> candidates) -> on_reference(idx, name, top_level, shadowed)
-- `blocks` mirrors the lexical scope stack; only module-scope (= depth 1) matters
-- to the transform, but inner scopes are still tracked to detect shadowing.

local KIND_LOCALVAR = "localvar"
local KIND_LOCALFUNCTION = "localfunction"

local function walk(tokens, hooks)
    local nt = #tokens
    local prev_sig, next_sig = {}, {}
    do
        local p = 0
        for idx = 1, nt do
            local t = tokens[idx]
            if t.t ~= TOKEN_WHITESPACE and t.t ~= TOKEN_COMMENT then
                prev_sig[idx] = p
                next_sig[p] = idx
                p = idx
            end
        end
        next_sig[p] = 0
    end

    local blocks = { { bindings = {}, tag = "chunk" } }
    local skip = {}

    local function module_scope() return #blocks == 1 end

    local function add(name)
        if name and name ~= "..." then blocks[#blocks].bindings[name] = true end
    end

    local function inner_bound(name)
        for depth = 2, #blocks do
            if blocks[depth].bindings[name] then return true end
        end
        return false
    end

    local function push_block(tag, names)
        local b = { bindings = {}, tag = tag }
        if names then
            for _, name in ipairs(names) do
                if name ~= "..." then b.bindings[name] = true end
            end
        end
        blocks[#blocks + 1] = b
    end

    local function pop_block()
        if #blocks > 1 then blocks[#blocks] = nil end
    end

    local pending_function = false
    local function_parens = 0
    local ctors = {}
    local for_vars = {}

    for idx = 1, nt do
        local tok = tokens[idx]
        local tt = tok.t
        local word = tok.s

        if tt == TOKEN_IDENT or tt == TOKEN_KEYWORD then
            -- Parameter list: every identifier is a parameter (binds in the body).
            if function_parens > 0 then
                if tt == TOKEN_IDENT then add(word) end
                goto continue
            end

            if word == "function" then
                pending_function = true
                goto continue
            elseif word == "local" then
                local ni = next_sig[idx]
                local nxt = ni ~= 0 and tokens[ni] or nil
                if nxt and nxt.t == TOKEN_KEYWORD and nxt.s == "function" then
                    local ni2 = next_sig[ni]
                    local name = ni2 ~= 0 and tokens[ni2] or nil
                    if name and name.t == TOKEN_IDENT then
                        if hooks.on_binding then hooks.on_binding(ni2, name.s, KIND_LOCALFUNCTION, module_scope()) end
                        add(name.s)
                        skip[ni2] = true
                        pending_function = true
                    end
                else
                    while true do
                        if ni == 0 or tokens[ni].t ~= TOKEN_IDENT then break end
                        if hooks.on_binding then hooks.on_binding(ni, tokens[ni].s, KIND_LOCALVAR, module_scope()) end
                        add(tokens[ni].s)
                        ni = next_sig[ni]
                        if ni == 0 or tokens[ni].s ~= "," then break end
                        ni = next_sig[ni]
                    end
                end
                goto continue
            elseif word == "for" then
                for_vars = {}
                local ni = idx
                while true do
                    ni = next_sig[ni]
                    if ni == 0 then break end
                    local t = tokens[ni]
                    if t.t == TOKEN_IDENT then
                        for_vars[#for_vars + 1] = t.s
                        skip[ni] = true
                    elseif t.s == "=" or t.s == "in" then
                        break
                    else
                        break
                    end
                end
                goto continue
            elseif word == "then" or word == "do" then
                push_block(word, for_vars)
                for_vars = {}
                goto continue
            elseif word == "repeat" then
                push_block("repeat")
                goto continue
            elseif word == "else" then
                pop_block()
                push_block("else")
                goto continue
            elseif word == "elseif" then
                pop_block()
                goto continue
            elseif word == "end" or word == "until" then
                pop_block()
                goto continue
            end

            if tt ~= TOKEN_IDENT then goto continue end
            if skip[idx] then
                goto continue
            end

            -- table-field key / . : index detection
            local is_key = false
            local prev = prev_sig[idx]
            if prev ~= 0 and tokens[prev].t == TOKEN_OPERATOR
                and (tokens[prev].s == "." or tokens[prev].s == ":") then
                is_key = true
            elseif #ctors > 0 then
                local ni = next_sig[idx]
                if ni ~= 0 and tokens[ni].s == "=" then
                    local last = ctors[#ctors]
                    is_key = (last == "{" or last == "," or last == ";")
                end
            end

            if is_key then
                if hooks.on_key then hooks.on_key(idx, word) end
            elseif hooks.on_reference then
                hooks.on_reference(idx, word, module_scope(), inner_bound(word))
            end
        elseif tt == TOKEN_OPERATOR then
            local op = tok.s
            if op == "{" then
                ctors[#ctors + 1] = "{"
            elseif op == "}" then
                if #ctors > 0 then ctors[#ctors] = nil end
            elseif #ctors > 0 and (op == "," or op == ";") then
                ctors[#ctors] = op
            elseif op == "[" then
                if #ctors > 0 then ctors[#ctors] = "[" end
            elseif op == "(" then
                if pending_function then
                    pending_function = false
                    function_parens = 1
                    -- parameters bind in the function-body scope; open it now so
                    -- a param that shadows a module local is seen by inner_bound
                    push_block("function")
                else
                    function_parens = 0
                end
            elseif op == ")" then
                if function_parens > 0 then
                    function_parens = function_parens - 1
                end
            end
        end
        ::continue::
    end
end

-- ─── Binding post-processing ──────────────────────────────────────────────────
-- Localvar groups:  `local a, b = v`  ->  `H.a, H.b = v`   (drop the keyword)
--                   `local a`         ->  `H.a = nil`
-- Localfunction:   `local function f(` -> `H.f = function(`

local function sig_neighbors(tokens)
    local prev, next_ = {}, {}
    local nt = #tokens
    local p = 0
    for idx = 1, nt do
        local t = tokens[idx]
        if t.t ~= TOKEN_WHITESPACE and t.t ~= TOKEN_COMMENT then
            prev[idx] = p
            next_[p] = idx
            p = idx
        end
    end
    next_[p] = 0
    return prev, next_
end

local function transform_bindings(tokens, bindings, ns)
    local prev_sig, next_sig = sig_neighbors(tokens)
    local i = 1
    local nt_b = #bindings

    while i <= nt_b do
        local b = bindings[i]

        if b.kind == KIND_LOCALFUNCTION then
            local fi = prev_sig[b.idx]
            assert(tokens[fi] and tokens[fi].s == "function", "bad localfunction anchor")
            local li = prev_sig[fi]
            assert(tokens[li] and tokens[li].s == "local", "bad localfunction anchor")
            tokens[li].emit = ns .. "." .. tokens[b.idx].s .. " ="
            tokens[b.idx].emit = ""
            i = i + 1
        else
            local names = { b.idx }
            while i < nt_b do
                local nb = bindings[i + 1]
                if nb.kind ~= KIND_LOCALVAR then break end
                local after_prev = next_sig[names[#names]]
                if after_prev == 0 or tokens[after_prev].s ~= "," then break end
                if next_sig[after_prev] ~= nb.idx then break end
                names[#names + 1] = nb.idx
                i = i + 1
            end

            local li = prev_sig[names[1]]
            assert(tokens[li] and tokens[li].s == "local", "bad local anchor")
            tokens[li].emit = ""
            for _, idx in ipairs(names) do
                tokens[idx].emit = ns .. "." .. tokens[idx].s
            end

            local after_last = next_sig[names[#names]]
            if after_last == 0 or tokens[after_last].s ~= "=" then
                tokens[names[#names]].emit = tokens[names[#names]].emit .. " = nil"
            end
            i = i + 1
        end
    end
end

-- ─── Transform ────────────────────────────────────────────────────────────────

local function transform(code)
    local tokens = tokenize(code)

    -- Already transformed? Bail out (keeps re-runs a no-op).
    for _, tok in ipairs(tokens) do
        if tok.t == TOKEN_COMMENT and tok.s:find("%[retranspile%]") then
            return code, { "already transformed (marker found); leaving unchanged" }
        end
    end

    -- Namespace name must collide with nothing in the file.
    local used = {}
    for _, tok in ipairs(tokens) do
        if tok.t == TOKEN_IDENT then used[tok.s] = true end
    end
    local ns = NAMESPACE
    while used[ns] do ns = ns .. "_" end

    -- Pass 1: discover module-scope locals (and which names inner scopes shadow).
    local modules, shadowed = {}, {}
    walk(tokens, {
        on_binding = function(idx, name, kind, top_level)
            if top_level then
                modules[name] = true
            elseif modules[name] then
                shadowed[name] = true
            end
        end,
    })

    local stderr_info = {}
    if next(shadowed) then
        local names = {}
        for name in pairs(shadowed) do names[#names + 1] = name end
        table.sort(names)
        table.insert(stderr_info, "inner scopes shadow these module locals (references there are left alone):")
        for _, name in ipairs(names) do table.insert(stderr_info, "  " .. name) end
    end

    for _, tok in ipairs(tokens) do tok.emit = tok.s end

    -- Pass 2: rewrite references.
    walk(tokens, {
        on_reference = function(idx, name, top_level, shadowed_ref)
            if modules[name] and not shadowed_ref then
                tokens[idx].emit = ns .. "." .. name
            end
        end,
    })

    -- Pass 3: collect module-scope bindings in token order (both kinds).
    local bindings = {}
    walk(tokens, {
        on_binding = function(idx, name, kind, top_level)
            if top_level then
                bindings[#bindings + 1] = { idx = idx, kind = kind, name = name }
            end
        end,
    })

    -- Pass 4: rewrite binding sites.
    transform_bindings(tokens, bindings, ns)

    -- Assembly: splice a module-scope header before the first significant token.
    local parts = {}
    local header_placed = false
    local hdr = "\n-- [retranspile] top-level locals moved into the " .. ns .. " namespace table (scope-aware)\nlocal " .. ns .. " = {}\n\n"
    for _, tok in ipairs(tokens) do
        if not header_placed and tok.t ~= TOKEN_WHITESPACE and tok.t ~= TOKEN_COMMENT then
            if next(modules) then parts[#parts + 1] = hdr end
            header_placed = true
        end
        parts[#parts + 1] = tok.emit
    end

    local mn = 0
    for _ in pairs(modules) do mn = mn + 1 end
    local summary = { string.format("%d module-scope locals moved into the %s namespace table", mn, ns) }
    for _, line in ipairs(stderr_info) do table.insert(summary, line) end
    return table.concat(parts), summary
end

local function main()
    local input = arg[1] or "src/Parser/LuauParser/init.lua"
    local output = arg[2] or input

    local code = read_file(input)
    local result, summary = transform(code)
    for _, line in ipairs(summary) do io.stderr:write(line .. "\n") end
    write_file(output, result)
    print(string.format("wrote %s (%d -> %d bytes)", output, #code, #result))
end

main()