#!/usr/bin/env lua

local Pipeline = require("pipeline")
local config = require("config")

local function print_usage()
    print("Usage: ./hercules <file.lua> [--overwrite] [--pipeline <pipeline.lua>]")
    os.exit(1)
end

if #arg < 1 then
    print_usage()
end

local input_file = arg[1]
local overwrite = false
local custom_pipeline_file = nil

for i = 2, #arg do
    if arg[i] == "--overwrite" then
        overwrite = true
    elseif arg[i] == "--pipeline" then
        if arg[i + 1] then
            custom_pipeline_file = arg[i + 1]:gsub("%.lua$", "")
            i = i + 1
        else
            print_usage()
        end
    end
end

local file = io.open(input_file, "r")
if not file then
    print("Error: Could not open file " .. input_file)
    os.exit(1)
end

local code = file:read("*all")
file:close()

local obfuscated_code
if custom_pipeline_file then
    local success, custom_pipeline = pcall(require, custom_pipeline_file)
    if not success then
        print("Error: Could not load custom pipeline module: " .. custom_pipeline)
        os.exit(1)
    end
    obfuscated_code = custom_pipeline.process(code)
else
    obfuscated_code = Pipeline.process(code)
end

local output_file
if overwrite then
    output_file = input_file
else
    local output_suffix = config.get("settings.output_suffix") or "_obfuscated.lua" --fallback because im not going to trust the user
    output_file = input_file:gsub("%.lua$", output_suffix)
end

file = io.open(output_file, "w")
file:write(obfuscated_code)
file:close()

print("Obfuscated code written to " .. output_file)
