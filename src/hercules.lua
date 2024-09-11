#!/usr/bin/env lua

local Pipeline = require("pipeline")

if #arg < 1 then
    print("Usage: ./hercules <file.lua>")
    os.exit(1)
end

local input_file = arg[1]
local file = io.open(input_file, "r")
if not file then
    print("Error: Could not open file " .. input_file)
    os.exit(1)
end

local code = file:read("*all")
file:close()

local obfuscated_code = Pipeline.process(code)

local output_file = input_file:gsub("%.lua$", "_obfuscated.lua")
file = io.open(output_file, "w")
file:write(obfuscated_code)
file:close()

print("Obfuscated code written to " .. output_file)
