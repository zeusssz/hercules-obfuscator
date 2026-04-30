-- test_fixtures.lua — Real Lua source code fixtures for end-to-end testing
-- Each fixture has: name, code, expected_output
-- The test harness runs the code via load() and captures print output.

local M = {}

function M.fixture(name, code, expected_output)
    return { name = name, code = code, expected = expected_output }
end

-- ─── Basic Print Tests ────────────────────────────────────────────────────────

M.hello_world = M.fixture(
    "hello_world",
    [[print("hello world")]],
    "hello world"
)

M.multi_print = M.fixture(
    "multi_print",
    [[
print("line one")
print("line two")
print("line three")
]],
    "line one\nline two\nline three"
)

M.concat = M.fixture(
    "concat",
    [[print("a" .. "b" .. "c")]],
    "abc"
)

-- ─── Variables & Arithmetic ───────────────────────────────────────────────────

M.simple_math = M.fixture(
    "simple_math",
    [[
local x = 10
local y = 20
print(x + y)
print(x * y)
print(y - x)
]],
    "30\n200\n10"
)

M.variable_reassign = M.fixture(
    "variable_reassign",
    [[
local a = 5
a = a + 10
print(a)
]],
    "15"
)

M.multiple_types = M.fixture(
    "multiple_types",
    [[
local n = 42
local s = "test"
local b = true
print(n)
print(s)
print(b)
print(type(n))
print(type(s))
print(type(b))
]],
    "42\ntest\ntrue\nnumber\nstring\nboolean"
)

-- ─── Functions ─────────────────────────────────────────────────────────────────

M.function_call = M.fixture(
    "function_call",
    [[
local function greet(name)
    return "Hello, " .. name
end
print(greet("World"))
]],
    "Hello, World"
)

M.function_with_math = M.fixture(
    "function_with_math",
    [[
local function add(a, b)
    return a + b
end
print(add(3, 7))
print(add(100, 200))
]],
    "10\n300"
)

M.function_no_return = M.fixture(
    "function_no_return",
    [[
local function print_sum(a, b)
    print(a + b)
end
print_sum(1, 2)
print_sum(10, 20)
]],
    "3\n30"
)

-- ─── Loops ─────────────────────────────────────────────────────────────────────

M.for_loop = M.fixture(
    "for_loop",
    [[
for i = 1, 3 do
    print(i)
end
]],
    "1\n2\n3"
)

M.for_loop_accumulate = M.fixture(
    "for_loop_accumulate",
    [[
local sum = 0
for i = 1, 5 do
    sum = sum + i
end
print(sum)
]],
    "15"
)

M.while_loop = M.fixture(
    "while_loop",
    [[
local i = 1
while i <= 3 do
    print(i)
    i = i + 1
end
]],
    "1\n2\n3"
)

-- ─── Conditionals ──────────────────────────────────────────────────────────────

M.if_true = M.fixture(
    "if_true",
    [[
if true then
    print("yes")
end
]],
    "yes"
)

M.if_else_true = M.fixture(
    "if_else_true",
    [[
if 10 > 5 then
    print("greater")
else
    print("not greater")
end
]],
    "greater"
)

M.if_else_false = M.fixture(
    "if_else_false",
    [[
if 10 < 5 then
    print("less")
else
    print("not less")
end
]],
    "not less"
)

M.if_elseif_else = M.fixture(
    "if_elseif_else",
    [[
local x = 0
if x > 0 then
    print("positive")
elseif x < 0 then
    print("negative")
else
    print("zero")
end
]],
    "zero"
)

-- ─── Tables ────────────────────────────────────────────────────────────────────

M.table_index = M.fixture(
    "table_index",
    [[
local t = {10, 20, 30}
print(t[1])
print(t[2])
print(t[3])
]],
    "10\n20\n30"
)

M.table_string_keys = M.fixture(
    "table_string_keys",
    [[
local t = {x = 1, y = 2}
print(t.x)
print(t.y)
]],
    "1\n2"
)

M.table_length = M.fixture(
    "table_length",
    [[
local t = {"a", "b", "c"}
print(#t)
]],
    "3"
)

M.table_iteration = M.fixture(
    "table_iteration",
    [[
local t = {10, 20, 30}
for i = 1, #t do
    print(t[i])
end
]],
    "10\n20\n30"
)

M.table_pairs = M.fixture(
    "table_pairs",
    [[
local t = {a = 1, b = 2}
local sum = 0
for k, v in pairs(t) do
    sum = sum + v
end
print(sum)
]],
    "3"
)

-- ─── String Operations ────────────────────────────────────────────────────────

M.string_sub = M.fixture(
    "string_sub",
    [[
local s = "hello world"
print(s:sub(1, 5))
print(s:sub(7))
]],
    "hello\nworld"
)

M.string_len = M.fixture(
    "string_len",
    [[
print(#"abcde")
print(string.len("abcde"))
]],
    "5\n5"
)

M.string_upper = M.fixture(
    "string_upper",
    [[
print(string.upper("hello"))
]],
    "HELLO"
)

M.string_lower = M.fixture(
    "string_lower",
    [[
print(string.lower("HELLO"))
]],
    "hello"
)

-- ─── Math Operations ───────────────────────────────────────────────────────────

M.math_basics = M.fixture(
    "math_basics",
    [[
print(math.abs(-42))
print(math.floor(3.7))
print(math.ceil(3.2))
print(math.max(1, 5, 3))
print(math.min(1, 5, 3))
]],
    "42\n3\n4\n5\n1"
)

M.math_sqrt = M.fixture(
    "math_sqrt",
    [[
print(math.sqrt(16))
print(math.sqrt(81))
]],
    "4\n9"
)

-- ─── Combined / Realistic Scripts ──────────────────────────────────────────────

M.fibonacci = M.fixture(
    "fibonacci",
    [[
local function fib(n)
    if n <= 1 then return n end
    return fib(n - 1) + fib(n - 2)
end
print(fib(0))
print(fib(1))
print(fib(2))
print(fib(3))
print(fib(4))
print(fib(5))
print(fib(6))
]],
    "0\n1\n1\n2\n3\n5\n8"
)

M.factorial = M.fixture(
    "factorial",
    [[
local function fact(n)
    if n <= 1 then return 1 end
    return n * fact(n - 1)
end
print(fact(1))
print(fact(2))
print(fact(3))
print(fact(4))
print(fact(5))
]],
    "1\n2\n6\n24\n120"
)

M.complex_script = M.fixture(
    "complex_script",
    [[
local function calculate(a, b, op)
    if op == "add" then
        return a + b
    elseif op == "mul" then
        return a * b
    else
        return 0
    end
end

local results = {}
results[1] = calculate(2, 3, "add")
results[2] = calculate(4, 5, "mul")
results[3] = calculate(10, 0, "add")

for i = 1, #results do
    print(results[i])
end

local total = 0
for i = 1, #results do
    total = total + results[i]
end
print(total)
]],
    "5\n20\n10\n35"
)

-- ─── Get all fixtures ──────────────────────────────────────────────────────────

function M.get_all()
    local fixtures = {}
    for k, v in pairs(M) do
        if type(v) == "table" and v.name and v.code and v.expected then
            table.insert(fixtures, v)
        end
    end
    -- Sort by name for deterministic order
    table.sort(fixtures, function(a, b) return a.name < b.name end)
    return fixtures
end

return M
