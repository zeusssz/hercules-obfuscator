#!/usr/bin/env lua

local Pipeline = require("pipeline")
local config = require("config")

local function get_file_size(file)
    local f = io.open(file, "r")
    local size = f:seek("end")
    f:close()
    return size
end

local function print_final(input_file, output_file, time_taken)
    local ascii_art = [[
                           _           
  /\  /\___ _ __ ___ _   _| | ___  ___ 
 / /_/ / _ \ '__/ __| | | | |/ _ \/ __|
/ __  /  __/ | | (__| |_| | |  __/\__ \
\/ /_/ \___|_|  \___|\__,_|_|\___||___/
                                       ]]
                                       
    local line = string.rep("=", 50)

    local control_flow_enabled = config.get("settings.control_flow.enabled") and "Enabled" or "Disabled"
    local variable_renaming_enabled = config.get("settings.variable_renaming.enabled") and "Enabled" or "Disabled"
    local garbage_code_enabled = config.get("settings.garbage_code.enabled") and "Enabled" or "Disabled"
    local bytecode_encoding_enabled = config.get("settings.bytecode_encoding.enabled") and "Enabled" or "Disabled"
    local original_size = get_file_size(input_file)
    local obfuscated_size = get_file_size(output_file)
    print("\n" .. line)
    print(ascii_art)
    print(line)
    print("Obfuscation Complete!")
    print("Time Taken        : " .. string.format("%.2f", time_taken) .. " seconds")
    print("Original Size     : " .. original_size .. " bytes")
    print("Obfuscated Size   : " .. obfuscated_size .. " bytes")
    print("Size Difference   : " .. (obfuscated_size - original_size) .. " bytes (" ..
          string.format("%.2f", ((obfuscated_size - original_size) / original_size) * 100) .. "%)")
    print("Output File       : " .. output_file)
    print("Control Flow      : " .. control_flow_enabled)
    print("Variable Renaming : " .. variable_renaming_enabled)
    print("Garbage Code      : " .. garbage_code_enabled)
    print("Bytecode Encoding : " .. bytecode_encoding_enabled)
    print(line .. "\n")
end

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

local start_time = os.clock()

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

local end_time = os.clock()
local time_taken = end_time - start_time

file = io.open(output_file, "w")
file:write(obfuscated_code)
file:close()

print_final(input_file, output_file, time_taken)
