#!/usr/bin/env lua

local Pipeline = require("pipeline")
local config = require("config")

local function size(file)
    local f = io.open(file, "r")
    local sz = f:seek("end")
    f:close()
    return sz
end

local function print_result(input, output, time, overwrite, custom_file)
    local colors = {
        reset = "\27[0m",
        green = "\27[32m",
        red = "\27[31m",
        white = "\27[37m",
        cyan = "\27[36m",
        blue = "\27[34m",
    }

    local art = colors.blue .. [[
                           _                       _   ____  
  /\  /\___ _ __ ___ _   _| | ___  ___   /\   /\  / | | ___| 
 / /_/ / _ \ '__/ __| | | | |/ _ \/ __|  \ \ / /  | | |___ \ 
/ __  /  __/ | | (__| |_| | |  __/\__ \   \ V /   | |_ ___) |
\/ /_/ \___|_|  \___|\__,_|_|\___||___/    \_/    |_(_)____/ 
                                       ]] .. colors.reset

    local line = colors.white .. string.rep("=", 50) .. colors.reset
    local orig_size = size(input)
    local obf_size = size(output)

    print("\n" .. line)
    print(art)
    print("     ")
    print(colors.white .. "Obfuscation Complete!" .. colors.reset)
    print(line)
    print(colors.white .. "Time Taken        : " .. string.format("%.2f", time) .. " seconds" .. colors.reset)
    print(colors.cyan .. "Original Size     : " .. orig_size .. " bytes" .. colors.reset)
    print(colors.cyan .. "Obfuscated Size   : " .. obf_size .. " bytes" .. colors.reset)
    print(colors.cyan .. "Size Difference   : " .. (obf_size - orig_size) .. " bytes (" ..
          string.format("%.2f", ((obf_size - orig_size) / orig_size) * 100 + 100) .. "%)" .. colors.reset)

    local overwrite_str = overwrite and colors.green .. "True" .. colors.reset or colors.red .. "False" .. colors.reset
    local custom_str = custom_file and colors.green .. "True" .. colors.reset or colors.red .. "False" .. colors.reset

    print(colors.cyan .. "Overwrite         : " .. overwrite_str)
    print(colors.cyan .. "Custom Pipeline   : " .. custom_str)
    print(colors.white .. "Output File       : " .. output .. colors.reset)
    print(line)

    local settings = {
        { "Control Flow", config.get("settings.control_flow.enabled") },
        { "String Encoding", config.get("settings.string_encoding.enabled") },
        { "Variable Renaming", config.get("settings.variable_renaming.enabled") },
        { "Garbage Code", config.get("settings.garbage_code.enabled") },
        { "Opaque Predicates", config.get("settings.opaque_predicates.enabled") },
        { "Function Inlining", config.get("settings.function_inlining.enabled") },
        { "Dynamic Code", config.get("settings.dynamic_code.enabled") },
        { "Bytecode Encoding", config.get("settings.bytecode_encoding.enabled") },
        { "Compressor", config.get("settings.compressor.enabled") },
        { "Watermark", config.get("settings.watermark_enabled") },
    }

    local max_length = 0
    for _, setting in ipairs(settings) do
        if #setting[1] > max_length then
            max_length = #setting[1]
        end
    end

    for _, setting in ipairs(settings) do
        local name = setting[1]
        local status = (setting[2] and colors.green .. "Enabled" or colors.red .. "Disabled")
        local padding = string.rep(" ", max_length - #name + 1)
        print(colors.white .. name .. padding .. ":" .. " " .. status .. colors.reset)
    end

    print(line .. "\n")
end

local function usage()
    print([[
Usage:
    ./hercules.lua <file.lua|folder> [OPTIONS]

Description:
    This script obfuscates Lua files using various techniques. 
    You can provide a single file or a folder containing multiple Lua files.

Options:
    --overwrite          Overwrites the original file with the obfuscated code.
    --pipeline <file>    Uses a custom pipeline script for obfuscation.
    --folder             Processes all Lua files in the given folder.
    
    Available Features (Flags):
    --control_flow       Enable control flow obfuscation.
    --string_encoding    Enable string encoding obfuscation.
    --variable_renaming  Enable variable renaming obfuscation.
    --garbage_code       Enable garbage code insertion.
    --opaque_predicates  Enable opaque predicates obfuscation.
    --bytecode_encoding  Enable bytecode encoding.
    --compressor         Enable code compression.

    Note: If one feature flag is enabled, all others are disabled unless explicitly enabled.
]])
    os.exit(1)
end

if #arg < 1 then
    usage()
end

local input = arg[1]
local overwrite = false
local custom_file = nil
local folder_mode = false

-- Feature flags
local features = {
    control_flow = false,
    string_encoding = false,
    variable_renaming = false,
    garbage_code = false,
    opaque_predicates = false,
    bytecode_encoding = false,
    compressor = false,
}

for i = 2, #arg do
    if arg[i] == "--overwrite" then
        overwrite = true
    elseif arg[i] == "--pipeline" then
        if arg[i + 1] then
            custom_file = arg[i + 1]:gsub("%.lua$", "")
            i = i + 1
        else
            usage()
        end
    elseif arg[i] == "--folder" then
        folder_mode = true
    elseif arg[i] == "--control_flow" then
        features.control_flow = true
    elseif arg[i] == "--string_encoding" then
        features.string_encoding = true
    elseif arg[i] == "--variable_renaming" then
        features.variable_renaming = true
    elseif arg[i] == "--garbage_code" then
        features.garbage_code = true
    elseif arg[i] == "--opaque_predicates" then
        features.opaque_predicates = true
    elseif arg[i] == "--bytecode_encoding" then
        features.bytecode_encoding = true
    elseif arg[i] == "--compressor" then
        features.compressor = true
    end
end

-- Set features in config
for feature in pairs(features) do
    config.settings[feature].enabled = features[feature]
end

local files = {}
if folder_mode then
    local handle = io.popen('ls "' .. input .. '"')
    for file in handle:lines() do
        if file:match("%.lua$") then
            table.insert(files, input .. "/" .. file)
        end
    end
    handle:close()
else
    table.insert(files, input)
end

local start_time = os.clock()
for _, file_path in ipairs(files) do
    local file = io.open(file_path, "r")
    if not file then
        print("Error: Could not open file " .. file_path)
        os.exit(1)
    end

    local code = file:read("*all")
    file:close()

    local obf_code
    if custom_file then
        local success, custom = pcall(require, custom_file)
        if not success then
            print("Error: Could not load custom pipeline module: " .. custom)
            os.exit(1)
        end
        obf_code = custom.process(code)
    else
        obf_code = Pipeline.process(code)
    end

    local output_file
    if overwrite then
        output_file = file_path
    else
        local suffix = config.get("settings.output_suffix") or "_obfuscated.lua"
        output_file = file_path:gsub("%.lua$", suffix)
    end

    local out = io.open(output_file, "w")
    out:write(obf_code)
    out:close()

    if config.get("settings.final_print") then
        print_result(file_path, output_file, os.clock() - start_time, overwrite, custom_file ~= nil)
    end
end
