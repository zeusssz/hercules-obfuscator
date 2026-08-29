#!/usr/bin/env lua
-- tests/test_parser.lua — Phase 0 gate: the Parser subsystem must load and
-- parse+render+execute under plain Lua (5.4 and LuaJIT).
--
-- Run from src/:  lua test_parser.lua
--
-- Covers:
--   * Parser factory + AstRenderer resolve.
--   * parse -> render -> execute equivalence on a battery of programs
--     (fixtures are LuaJIT-safe: no `//` or compound-assign output relies on 5.3).
--   * Multi-statement chunks separated by `;` (the parser's accepted form).

package.path = "./?.lua;./?/init.lua;./src/?.lua;./src/?/init.lua;./tests/?.lua;./tests/?/init.lua;" .. package.path

local Parser = require("Parser")
local AstRenderer = require("Parser/AstRenderer")

local pass, fail = 0, 0

local function report(ok, msg)
    if ok then
        pass = pass + 1
    else
        fail = fail + 1
        print("[FAIL] " .. msg)
    end
end

-- ─── Execute code capturing print, normalizing 5.1-vs-5.4 float printing ──────
local function run(code)
    local fn, ler = load(code, "=roundtrip", "t")
    if not fn then return nil, "compile: " .. tostring(ler) end
    local buf = {}
    local old = _G.print
    _G.print = function(...)
        local t = {}
        local n = select("#", ...)
        for i = 1, n do t[#t + 1] = tostring(select(i, ...)) end
        buf[#buf + 1] = table.concat(t, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old
    if not ok then return nil, "run: " .. tostring(err) end
    local out = table.concat(buf, "\n")
    out = out:gsub("(%d+)%.(0+)", "%1")
    return out
end

-- ─────────────────────────────────────────────────────────────────────────────

report(type(Parser.parse) == "function", "Parser.parse is a function")
report(type(Parser.render) == "function", "Parser.render is a function")
report(type(AstRenderer.render) == "function", "AstRenderer.render is a function")

local programs = {
    ["hello"] = [[
local function greet(name)
    return "Hello, " .. name .. "!"
end
print(greet("World"))
]],
    ["arithmetic"] = [[
local a, b, c = 5, 2, 7
print(a + b * c)
print((a + b) * c)
print(a - b)
print(-a)
print(a % b)
print(2 ^ 10)
print(a * -b)
]],
    ["tables"] = [[
local key = "computed"
local t = { 1, 2, 3, key = "val", [1] = 99, nested = { deep = true }, [key] = "computed" }
print(t[1], t.key, t.nested.deep)
]],
    ["control"] = [[
local sum = 0
for i = 1, 5 do
    if i % 2 == 0 then
        sum = sum + i
    else
        sum = sum - i
    end
end
print(sum)
while sum > 0 do
    sum = sum - 1
end
print(sum)
repeat
    sum = sum + 1
until sum == 10
print(sum)
]],
    ["fns"] = [[
local function fib(n)
    if n < 2 then return n end
    return fib(n - 1) + fib(n - 2)
end
print(fib(10))
local obj = { x = 10 }
function obj:double()
    return self.x * 2
end
function obj.double2(o)
    return o.x * 2
end
print(obj:double(), obj.double2(obj))
]],
    ["genfor"] = [[
local t = { 1, 2, 3 }
for i, v in ipairs(t) do
    print(i, v)
end
]],
    ["strings"] = [[
local s1 = 'single'
local s2 = "double with \"quote\""
local s3 = "newline\nhere"
print(s1, s2)
print(s3)
]],
    ["nested_fns"] = [[
local function outer(a)
    return function(b)
        return a + b
    end
end
print(outer(1)(2))
]],
    ["method_chain"] = [[
local s = "abc"
print(s:upper())
print(("  hi  "):gsub("%s", "-"))
]],
    ["cnst"] = [[
print(nil == nil)
print(true and not false)
print(0x10, 1e2, .5, 3.)
]],
    ["assign_multi"] = [[
local a, b
a, b = 1, 2
print(a, b)
]],
    ["do_block"] = [[
local out = 0
do
    local x = 5
    out = out + x
end
print(out)
]],
    -- The parser accepts multi-statement chunks separated by `;`.
    ["semicolon_chunk"] = [[
local q = 1; q = q + 2; local w = 9
print(q); print(w)
]],
}

for name, code in pairs(programs) do
    local okp, ast = Parser.parse(code)
    if not okp then
        report(false, name .. ": parse error: " .. tostring(ast))
    else
        local rendered = AstRenderer.render(ast.root, { indent = "    " })
        local origOut = run(code)
        local rndOut = run(rendered)
        if origOut == nil then
            report(false, name .. ": original fails to run: " .. tostring(rndOut))
        elseif rndOut == nil then
            report(false, name .. ": rendered fails to run: " .. tostring(origOut))
        elseif origOut ~= rndOut then
            report(false, string.format("%s: output mismatch\n  orig: %s\n  rnd : %s", name, origOut, rndOut))
        else
            report(true, string.format("%-15s parse+render+run equiv (%d bytes)", name, #code))
        end
    end
end

print(string.format("=== test_parser: %d pass, %d fail ===", pass, fail))
if fail > 0 then os.exit(1) end