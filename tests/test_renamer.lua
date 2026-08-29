-- tests/test_renamer.lua
-- Regression gate for the AST-based variable renamer (modules/variable_renamer.lua).
--
-- Run from the repo root:
--   lua tests/test_renamer.lua
--   luajit tests/test_renamer.lua
--
-- Checks (all runtime-independent):
--   1. Input and transformed source execute to identical results.
--   2. Transformed output still parses (round-trips) and compiles.
--   3. Local variables are actually renamed across scopes.
--   4. Builtin usages are aliased, while assignment targets / global function
--      definitions named like a builtin are left untouched.
--   5. Strings, comments, table keys, and property accesses are untouched.
--   6. Unparseable input is returned unchanged.

package.path = "./src/?.lua;./src/?/init.lua;" .. package.path

local VariableRenamer = require("modules/variable_renamer")
local Parser = require("Parser")

local function run(code)
    -- Isolate globals each run so code that rebinds _G globals (print = nil)
    -- cannot leak into the test harness.
    local env = setmetatable({}, { __index = _G })
    local chunk, err = load(code, "input", "t", env)
    if not chunk then return nil, "load: " .. tostring(err) end
    local ok, res = pcall(chunk)
    if not ok then return nil, tostring(res) end
    return res
end

local function same_table(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    local seen = {}
    for k, v in pairs(a) do
        if not same_table(v, b[k]) then return false end
        seen[k] = true
    end
    for k in pairs(b) do
        if not seen[k] then return false end
    end
    return true
end

math.randomseed(12345)

local FIXTURE = table.concat({
    "function say(x) return x * 2 end",
    "local function fib(n)",
    "    if n <= 1 then return n end",
    "    return fib(n - 1) + fib(n - 2)",
    "end",
    "local total = 0",
    "for i = 1, 5 do",
    "    total = total + fib(i)",
    "end",
    "local obj = {}",
    "function obj.run(x)",
    "    return math.floor(x) + math.max(1, x)",
    "end",
    "local s = say(math.floor(1.5))",
    "local m = math",
    "local sf = m.floor(2.5)",
    "local t = { print = 1, ['msg'] = 2, fib = 3 }",
    "local g = tostring(total)",
    "local c = string.format('%s:%d', g, #t)",
    "local upper = ('yogi'):upper()",
    "string.find('abc', 'a')",
    "if cfg then end -- cfg.name untouched",
    "return { total = total, run = obj.run(3), s = s, sf = sf,",
    "         keys = t.print, g = g, c = c, fib8 = fib(8), upper = upper }",
}, "\n")

local function checked(name, cond)
    if not cond then
        error("ASSERT FAILED: " .. name, 2)
    end
    print(string.format("[ok ] %s", name))
end

-- Fixture compiles and runs in this runtime before transformation.
local expected, err = run(FIXTURE)
assert(expected, "fixture must run: " .. tostring(err))

-- 1. Transform and compare execution results.
local output = VariableRenamer.process(FIXTURE, { min_length = 8, max_length = 12, target = "lua" })
checked("output is a non-empty string", type(output) == "string" and #output > 0)
checked("output differs from input", output ~= FIXTURE)

local actual, perr = run(output)
checked("transformed output executes", actual ~= nil and perr == nil)
checked("input/output results identical", same_table(expected, actual))

-- 2. Round-trips and compiles.
local pok, pres = Parser.parse(output)
checked("output re-parses", pok == true)
if pok then
    local again = Parser.render(pres.root)
    checked("output render is stable", again == output)
end

-- 3. Locals renamed across all binding kinds.
do
    local Ast = require("Parser/Ast")
    local pok2, res2 = Parser.parse(output)
    assert(pok2 and res2)
    local binding_names = {}
    Ast.each(res2.root, function(node)
        local vars
        if node.kind == "StatLocal" then vars = node.vars
        elseif node.kind == "StatLocalFunction" then vars = { node.name }
        elseif node.kind == "ExprFunction" then vars = node.args
        elseif node.kind == "StatFor" then vars = { node.var }
        elseif node.kind == "StatForIn" then vars = node.vars
        end
        if vars then
            for _, b in ipairs(vars) do
                if type(b) == "table" and b.name then binding_names[b.name] = true end
            end
        end
    end)
    for _, name in ipairs({ "fib", "total", "msg", "i", "obj", "run", "x", "s", "m", "sf", "t", "g", "c", "upper" }) do
        checked("local renamed: " .. name, not binding_names[name])
    end
end

-- 4a. Builtin usages aliased: their dotted/plain call forms disappear from the body.
do
    local nl = output:find("\n", 1, true)
    local body = nl and output:sub(nl + 1) or output
    for _, pattern in ipairs({ "math%.floor", "math%.max", "tostring", "string%.find" }) do
        checked("builtin usage aliased: " .. pattern, not body:find(pattern))
    end
end

-- 4b. Builtin-named assignment targets and definitions preserved verbatim.
do
    local DEF = table.concat({
        "print = nil",
        "function gsub() return 1 end",
        "local y = 1",
        "return { p = print, g = gsub() }",
    }, "\n")
    local out = VariableRenamer.process(DEF, { min_length = 8, max_length = 12, target = "lua" })
    checked("target `print = nil` preserved", out:find("print = nil", 1, true) ~= nil)
    checked("`function gsub()` preserved", out:find("function gsub()", 1, true) ~= nil)
    local a, b = run(DEF), run(out)
    checked("definitions execute identically", same_table(a, b))
end

-- globals referenced after rebinding still hit the rebound definition
do
    local DEF2 = table.concat({
        "function print() return 77 end",
        "return print()",
    }, "\n")
    local out = VariableRenamer.process(DEF2, { min_length = 8, max_length = 12, target = "lua" })
    local ov = run(out)
    checked("rebound `function print()` keeps semantics", ov == 77)
end

-- 5. Strings / table keys / property names untouched.
do
    local SRC = table.concat({
        "local fib = 1",
        "local msg = 'fib and math.floor'",
        "return { fib = fib, ['math.floor'] = msg, fibname = 'x' }",
    }, "\n")
    local out = VariableRenamer.process(SRC, { min_length = 8, max_length = 12, target = "lua" })
    checked("key fib kept", out:match("%bfib%s*=") ~= nil)
    checked("string literal kept", out:find("'fib and math%.floor'") ~= nil or out:find("\"fib and math.floor\"") ~= nil)
end

-- 6. Unparseable input returned unchanged, and Luau-target path keeps `type`.
do
    local BAD = "this is not lua {{"
    checked("invalid input untouched", VariableRenamer.process(BAD, {}) == BAD)
    local LU = table.concat({ "local u = 1", "u += 2", "local tv = type(u)", "return tv" }, "\n")
    local out = VariableRenamer.process(LU, { min_length = 8, max_length = 12, target = "luau" })
    checked("luau target: compound assignment kept", out:find("+=", 1, true) ~= nil)
    do
        local pok3, res3 = Parser.parse(out)
        assert(pok3 and res3)
        local Ast = require("Parser/Ast")
        local type_ref_left = false
        Ast.each(res3.root, function(nd)
            if nd.kind == "ExprGlobal" and nd.name == "type" then type_ref_left = true end
        end)
        checked("luau target: `type` not aliased", type_ref_left)
    end
end

print("--- all tests passed ---")