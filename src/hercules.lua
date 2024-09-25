#!/usr/bin/env lua

local Pipeline = require("pipeline")
local config = require("config")

local function get_file_size(file)
    local f = io.open(file, "r")
    local size = f:seek("end")
    f:close()
    return size
end

local function print_final(input_file, output_file, time_taken, overwrite, custom_pipeline_file)
    local colors = {
        reset = "\27[0m",
        green = "\27[32m",
        red = "\27[31m",
        white = "\27[37m",
        cyan = "\27[36m",
        deep_blue = "\27[34m",
    }

    local ascii_art = colors.deep_blue .. [[
                           _           
  /\  /\___ _ __ ___ _   _| | ___  ___ 0000
 / /_/ / _ \ '__/ __| | | | |/ _ \/ __|000000
/ __  /  __/ | | (__| |_| | |  __/\__ \00000000
\/ /_/ \___|_|  \___|\__,_|_|\___||___/000000000
                                       ]] .. colors.reset

    local line = colors.white .. string.rep("=", 50) .. colors.reset

    local original_size = get_file_size(input_file)
    local obfuscated_size = get_file_size(output_file)

    print("\n" .. line)
    print(ascii_art)
    print("     ")
    print(colors.white .. "Obfuscation Complete!" .. colors.reset)
    print(line)
    print(colors.white .. "Time Taken        : " .. string.format("%.2f", time_taken) .. " seconds" .. colors.reset)
    print(colors.cyan .. "Original Size     : " .. original_size .. " bytes" .. colors.reset)
    print(colors.cyan .. "Obfuscated Size   : " .. obfuscated_size .. " bytes" .. colors.reset)
    print(colors.cyan .. "Size Difference   : " .. (obfuscated_size - original_size) .. " bytes (" ..
          string.format("%.2f", ((obfuscated_size - original_size) / original_size) * 100) .. "%)" .. colors.reset)

    -- Use a local variable to determine if overwrite and custom pipeline are set
    local overwrite_str = overwrite and colors.green .. "True" .. colors.reset or colors.red .. "False" .. colors.reset
    local custom_pipeline_str = custom_pipeline_file and colors.green .. "True" .. colors.reset or colors.red .. "False" .. colors.reset

    print(colors.cyan .. "Overwrite         : " .. overwrite_str)
    print(colors.cyan .. "Custom Pipeline   : " .. custom_pipeline_str)
    print(colors.white .. "Output File       : " .. output_file .. colors.reset)
    print(line)

    local control_flow_enabled = config.get("settings.control_flow.enabled")
    local string_encoding_enabled = config.get("settings.string_encoding.enabled")
    local variable_renaming_enabled = config.get("settings.variable_renaming.enabled")
    local garbage_code_enabled = config.get("settings.garbage_code.enabled")
    local opaque_predicates_enabled = config.get("settings.opaque_predicates.enabled")
    local function_inlining_enabled = config.get("settings.function_inlining.enabled")
    local dynamic_code_enabled = config.get("settings.dynamic_code.enabled")
    local bytecode_encoding_enabled = config.get("settings.bytecode_encoding.enabled")

    print(colors.white .. "Control Flow      : " .. (control_flow_enabled and colors.green .. "Enabled" .. colors.reset or colors.red .. "Disabled" .. colors.reset))
    print(colors.white .. "String Encoding   : " .. (string_encoding_enabled and colors.green .. "Enabled" .. colors.reset or colors.red .. "Disabled" .. colors.reset))
    print(colors.white .. "Variable Renaming : " .. (variable_renaming_enabled and colors.green .. "Enabled" .. colors.reset or colors.red .. "Disabled" .. colors.reset))
    print(colors.white .. "Garbage Code      : " .. (garbage_code_enabled and colors.green .. "Enabled" .. colors.reset or colors.red .. "Disabled" .. colors.reset))
    print(colors.white .. "Opaque Predicates : " .. (opaque_predicates_enabled and colors.green .. "Enabled" .. colors.reset or colors.red .. "Disabled" .. colors.reset))
    print(colors.white .. "Function Inlining : " .. (function_inlining_enabled and colors.green .. "Enabled" .. colors.reset or colors.red .. "Disabled" .. colors.reset))
    print(colors.white .. "Dynamic Code      : " .. (dynamic_code_enabled and colors.green .. "Enabled" .. colors.reset or colors.red .. "Disabled" .. colors.reset))
    print(colors.white .. "Bytecode Encoding : " .. (bytecode_encoding_enabled and colors.green .. "Enabled" .. colors.reset or colors.red .. "Disabled" .. colors.reset))

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

local end_time = os.clock()
local time_taken = end_time - start_time

local output_file
if overwrite then
    output_file = input_file
else
    local output_suffix = config.get("settings.output_suffix") or "_obfuscated.lua" -- jos asked me to remove this code comment
    output_file = input_file:gsub("%.lua$", output_suffix)
end

file = io.open(output_file, "w")
file:write(obfuscated_code)
file:close()

print_final(input_file, output_file, time_taken, overwrite, custom_pipeline_file)
