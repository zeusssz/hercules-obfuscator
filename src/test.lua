--------------------------------------------------
-- Utility: Deep Copy
--------------------------------------------------
local function deep_copy(orig, seen)
    if type(orig) ~= "table" then
        return orig
    end
    if seen and seen[orig] then
        return seen[orig]
    end

    local copy = {}
    seen = seen or {}
    seen[orig] = copy

    for k, v in pairs(orig) do
        copy[deep_copy(k, seen)] = deep_copy(v, seen)
    end

    return setmetatable(copy, getmetatable(orig))
end

--------------------------------------------------
-- Fibonacci (Memoized + Recursive)
--------------------------------------------------
local fib_cache = {}

local function fib(n)
    if n < 2 then
        return n
    end
    if fib_cache[n] then
        return fib_cache[n]
    end
    fib_cache[n] = fib(n - 1) + fib(n - 2)
    return fib_cache[n]
end

print("Fib(20):", fib(20))

--------------------------------------------------
-- OOP-Style Class System
--------------------------------------------------
local Entity = {}
Entity.__index = Entity

function Entity:new(name)
    local obj = {
        name = name or "Unknown",
        id = math.random(1000, 9999),
        components = {}
    }
    return setmetatable(obj, self)
end

function Entity:add_component(name, data)
    self.components[name] = data
end

function Entity:__tostring()
    return "Entity<" .. self.name .. ":" .. self.id .. ">"
end

--------------------------------------------------
-- Component with Metatable Operator Overloading
--------------------------------------------------
local Vector = {}
Vector.__index = Vector

function Vector:new(x, y)
    return setmetatable({ x = x or 0, y = y or 0 }, self)
end

function Vector:__add(other)
    return Vector:new(self.x + other.x, self.y + other.y)
end

function Vector:__mul(scalar)
    return Vector:new(self.x * scalar, self.y * scalar)
end

function Vector:__tostring()
    return "(" .. self.x .. ", " .. self.y .. ")"
end

--------------------------------------------------
-- Closure-based Counter Factory
--------------------------------------------------
local function make_counter()
    local count = 0
    return function()
        count = count + 1
        return count
    end
end

local counterA = make_counter()
print("Counter A:", counterA(), counterA(), counterA())

--------------------------------------------------
-- Coroutine Task Scheduler
--------------------------------------------------
local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler:new()
    return setmetatable({ tasks = {} }, self)
end

function Scheduler:add_task(func)
    table.insert(self.tasks, coroutine.create(func))
end

function Scheduler:run()
    while #self.tasks > 0 do
        for i = #self.tasks, 1, -1 do
            local co = self.tasks[i]
            if coroutine.status(co) == "dead" then
                table.remove(self.tasks, i)
            else
                coroutine.resume(co)
            end
        end
    end
end

--------------------------------------------------
-- Event System
--------------------------------------------------
local EventBus = {}
EventBus.__index = EventBus

function EventBus:new()
    return setmetatable({ listeners = {} }, self)
end

function EventBus:on(event, callback)
    self.listeners[event] = self.listeners[event] or {}
    table.insert(self.listeners[event], callback)
end

function EventBus:emit(event, ...)
    if self.listeners[event] then
        for _, cb in ipairs(self.listeners[event]) do
            cb(...)
        end
    end
end

--------------------------------------------------
-- Weird Metatable: Auto-create missing keys
--------------------------------------------------
local autoTable = setmetatable({}, {
    __index = function(t, key)
        local val = "auto_" .. tostring(key)
        rawset(t, key, val)
        return val
    end
})

print("Weird auto value:", autoTable.hello)
print("Stored now:", autoTable.hello)

--------------------------------------------------
-- Demonstration
--------------------------------------------------

-- Create entity
local player = Entity:new("Player")
player:add_component("position", Vector:new(5, 10))
player:add_component("velocity", Vector:new(1, 1))

print(player)
print("Position:", player.components.position)

-- Vector math
local newPos = player.components.position + (player.components.velocity * 5)
print("New Position after 5 ticks:", newPos)

-- Scheduler usage
local scheduler = Scheduler:new()

scheduler:add_task(function()
    for i = 1, 3 do
        print("Task 1 tick", i)
        coroutine.yield()
    end
end)

scheduler:add_task(function()
    for i = 1, 2 do
        print("Task 2 tick", i)
        coroutine.yield()
    end
end)

scheduler:run()

-- Event system usage
local bus = EventBus:new()

bus:on("damage", function(amount)
    print("Entity took damage:", amount)
end)

bus:emit("damage", 25)

--------------------------------------------------
-- Custom Iterator
--------------------------------------------------
local function fibonacci_iterator(limit)
    local a, b = 0, 1
    return function()
        if a > limit then
            return nil
        end
        a, b = b, a + b
        return a
    end
end

print("Fibonacci sequence up to 50:")
for value in fibonacci_iterator(50) do
    print(value)
end

--------------------------------------------------
-- Deep copy demo
--------------------------------------------------
local original = { x = 10, nested = { y = 20 } }
local clone = deep_copy(original)

clone.nested.y = 999

print("Original nested y:", original.nested.y)
print("Cloned nested y:", clone.nested.y)

print("Script finished.")
