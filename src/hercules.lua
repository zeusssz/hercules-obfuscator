#!/usr/bin/env lua

local Pipeline = require("pipeline")

local function print_usage()
    print("Usage: ./hercules <file.lua> [--overwrite]")
    os.exit(1)
end

if #arg < 1 then
    print_usage()
end

local input_file = arg[1]
local overwrite = false

if #arg > 1 and arg[2] == "--overwrite" then
    overwrite = true
elseif #arg > 1 then
    print_usage()
end

local file = io.open(input_file, "r")
if not file then
    print("Error: Could not open file " .. input_file)
    os.exit(1)
end

local code = file:read("*all")
file:close()

local obfuscated_code = Pipeline.process(code)

local output_file
if overwrite then
    output_file = input_file
else
    output_file = input_file:gsub("%.lua$", "_obfuscated.lua")
end

file = io.open(output_file, "w")
file:write(obfuscated_code)
file:close()

print("Obfuscated code written to " .. output_file)
