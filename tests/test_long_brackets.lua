-- Run from repository root: lua tests/test_long_brackets.lua
package.path = "./src/?.lua;./src/?/init.lua;" .. package.path
local encoder = require("modules/string_encoder")
local expressions = require("modules/StringToExpressions")
local longEnd = require("modules/long_brackets")

local cases = {
    {name="nested load", source=[====[local script = [=[return "hello", 'world']=]
local f = loadstring or load
local a,b = assert(f(script))()
return a .. ":" .. b]====], expected="hello:world"},
    {name="higher delimiter", source=[====[local s = [==[value "quoted" and ]=] brackets]==]
return s]====], expected='value "quoted" and ]=] brackets'},
    {name="zero delimiter", source=[====[local s = [[value "quoted"]]
return s]====], expected='value "quoted"'},
    {name="multiline comment", source=[====[--[==[ comment with "quote"
"second line" and ]=] other delimiter
]==]
return "after-comment"]====], expected='after-comment'},
    {name="line comment", source='-- "quoted"\nreturn "after-line"', expected='after-line'},
    {name="bracket indexing", source='local t={"first"}; return t[1]', expected='first'},
}
local processors = {
    {name="string encoder", run=function(s) return encoder.process(s) end},
    {name="string expressions", run=function(s) return expressions.process(s,10,50) end},
    {name="both in pipeline order", run=function(s) return encoder.process(expressions.process(s,10,50)) end},
}
for _, processor in ipairs(processors) do
    for _, case in ipairs(cases) do
        math.randomseed(1234)
        local transformed = processor.run(case.source)
        local compile = loadstring or load
        local chunk, err = compile(transformed)
        assert(chunk, processor.name .. " / " .. case.name .. ": " .. tostring(err))
        local ok, value = pcall(chunk)
        assert(ok and value == case.expected, processor.name .. " / " .. case.name .. ": " .. tostring(value))
    end
end
assert(longEnd('[========[unclosed', 1) == #('[========[unclosed'))
assert(longEnd('[1]', 1) == nil)
print("PASS long bracket literals, comments, nested load and string transforms")
