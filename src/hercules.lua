#!/usr/bin/env lua

local Pipeline = require("pipeline")
local config = require("config")

local function size(file)
    local f = io.open(file, "r")
    local sz = f:seek("end")
    f:close()
    return sz
end

local function print_result(input, output, time, overwrite, custom_file, sanity_failed, sanity_info)
    local colors = {
        reset = "\27[0m",
        green = "\27[32m",
        red = "\27[31m",
        white = "\27[37m",
        cyan = "\27[36m",
        blue = "\27[34m",
        yellow = "\27[33m"
    }

    local art = colors.blue .. [[
                           _                       _       ____  
  /\  /\___ _ __ ___ _   _| | ___  ___   /\   /\  / |     | ___| 
 / /_/ / _ \ '__/ __| | | | |/ _ \/ __|  \ \ / /  | |     |___ \ 
/ __  /  __/ | | (__| |_| | |  __/\__ \   \ V /   | |  _   ___) |
\/ /_/ \___|_|  \___|\__,_|_|\___||___/    \_/    |_| (_) |____/ 
                                       ]] .. colors.reset

    local line = colors.white .. string.rep("=", 50) .. colors.reset
    local og_size = size(input)
    local obfuscated_size = size(output)

    print("\n" .. line)
    print(art)
    print("     ")
    print(colors.white .. "Obfuscation Complete!" .. colors.reset)
    print(line)
    print(colors.white .. "Time Taken        : " .. string.format("%.2f", time) .. " seconds" .. colors.reset)
    print(colors.cyan .. "Original Size     : " .. og_size .. " bytes" .. colors.reset)
    print(colors.cyan .. "Obfuscated Size   : " .. obfuscated_size .. " bytes" .. colors.reset)
    print(colors.cyan .. "Size Difference   : " .. (obfuscated_size - og_size) .. " bytes (" ..
          string.format("%.2f", ((obfuscated_size - og_size) / og_size) * 100 + 100) .. "%)" .. colors.reset)

    local overwrite_str = overwrite and colors.green .. "True" .. colors.reset or colors.red .. "False" .. colors.reset
    local custom_str = custom_file and colors.green .. "True" .. colors.reset or colors.red .. "False" .. colors.reset

    print(colors.cyan .. "Overwrite         : " .. overwrite_str)
    print(colors.cyan .. "Custom Pipeline   : " .. custom_str)
    print(colors.white .. "Output File       : " .. output .. colors.reset)

    if sanity_failed then
        print(colors.red .. "Sanity Check      : Failed" .. colors.reset)
        if sanity_info then
            print(colors.yellow .. "\nExpected output:" .. colors.reset)
            print(colors.white .. sanity_info.expected .. colors.reset)
            print(colors.yellow .. "\nGot output:" .. colors.reset)
            print(colors.white .. sanity_info.got .. colors.reset)
        end
        print(colors.red .. "\nPlease file a bug report in our Discord Server --> discord.gg/Hx6RuYs8Ku" .. colors.reset)
    else
        print(colors.green .. "Sanity Check      : Passed" .. colors.reset)
    end

    print(line)

    local settings = {
        { "String To Expressions", config.get("settings.StringToExpressions.enabled") },
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
        { "Function Wrapping", config.get("settings.WrapInFunction.enabled") },
        { "Virtual Machine", config.get("settings.VirtualMachine.enabled") },
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

local function sanecheck(original_code, obfuscated_code)
    local function capture(code)
        local output = {}
        local original_print = _G.print
        
        _G.print = function(...)
            local args = {...}
            local str = ""
            for i, v in ipairs(args) do
                str = str .. tostring(v)
                if i < #args then str = str .. "\t" end
            end
            table.insert(output, str)
        end
        
        local func = load(code)
        pcall(func)
        _G.print = original_print
        
        return table.concat(output, "\n")
    end

    local original_output = capture(original_code)
    local obfuscated_output = capture(obfuscated_code)
    
    return original_output == obfuscated_output, {
        expected = original_output,
        got = obfuscated_output
    }
end

local function usage()
    print([[
Usage:
    ./hercules.lua *.lua (+ any options)

Flags:

    File:
    --overwrite          Overwrites the original file with the obfuscated code, instead of creating a new *_obfuscated.lua file.
    --pipeline <file>    Use a custom pipeline for obfuscation.
    --folder             Processes all Lua files in the given folder, instead of a single file.
    --sanity             Checks if obfuscated code output matches the original output.
    
    Obfuscation:
    --CF, --control_flow                  Enable control flow obfuscation.
    --SE, --string_encoding               Enable string encoding.
    --VR, --variable_renaming             Enable variable renaming.
    --GCI, --garbage_code                 Enable garbage code insertion.
    --OPI, --opaque_predicates            Enable opaque predicates injection.
    --BE, --bytecode_encoding             Enable bytecode encoding.
    --C, --compressor                     Enable code compression.
    --ST, --string_to_expr                Enable string to expressions.
    --VM, --virtual_machine               Enable virtual machinery.
    --WIF, --wrap_in_func                 Enable function wrapping.

    If one Obfuscation flag is enabled, all others are disabled unless manually enabled.
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
local sanity_check = false

local features = {
    control_flow = false,
    string_encoding = false,
    variable_renaming = false,
    garbage_code = false,
    opaque_predicates = false,
    bytecode_encoding = false,
    compressor = false,
    StringToExpressions = false,
    VirtualMachine = false,
    WrapInFunction = false
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
    elseif arg[i] == "--sanity" then
        sanity_check = true
    elseif arg[i] == "--CF" or arg[i] == "--control_flow" then
        features.control_flow = true
    elseif arg[i] == "--SE" or arg[i] == "--string_encoding" then
        features.string_encoding = true
    elseif arg[i] == "--VR" or arg[i] == "--variable_renaming" then
        features.variable_renaming = true
    elseif arg[i] == "--GCI" or arg[i] == "--garbage_code" then
        features.garbage_code = true
    elseif arg[i] == "--OPI" or arg[i] == "--opaque_predicates" then
        features.opaque_predicates = true
    elseif arg[i] == "--BE" or arg[i] == "--bytecode_encoding" then
        features.bytecode_encoding = true
    elseif arg[i] == "--ST" or arg[i] == "--string_to_expr" then
        features.StringToExpressions = true
    elseif arg[i] == "--VM" or arg[i] == "--virtual_machine" then
        features.VirtualMachine = true
    elseif arg[i] == "--WIF" or arg[i] == "--wrap_in_func" then
        features.WrapInFunction = true
    elseif arg[i] == "--C" or arg[i] == "--compressor" then
        features.compressor = true
    end
end

local single_enabled = false
for feature in pairs(features) do
    if features[feature] then
        single_enabled = true
        break
    end
end

if single_enabled then
    for feature in pairs(features) do
        config.settings[feature].enabled = features[feature]
    end
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

    local obfuscated_code
    local attempts = 0
    local success = false
    local sanity_failed = false
    local sanity_info = nil

    repeat
        attempts = attempts + 1
        if custom_file then
            local success, custom = pcall(require, custom_file)
            if not success then
                print("Error: Could not load custom pipeline module: " .. custom)
                os.exit(1)
            end
            obfuscated_code = custom.process(code)
        else
            obfuscated_code = Pipeline.process(code)
        end

        if sanity_check then
            success, sanity_info = sanecheck(code, obfuscated_code)
            if not success and attempts >= 3 then
                sanity_failed = true
                break
            end
        else
            success = true
        end
    until success or attempts >= 3

    local output_file = overwrite and file_path or file_path:gsub("%.lua$", "_obfuscated.lua")
    local out_file_handle = io.open(output_file, "w")
    out_file_handle:write(obfuscated_code)
    out_file_handle:close()

    local end_time = os.clock()
    print_result(file_path, output_file, end_time - start_time, overwrite, custom_file, sanity_failed, sanity_info)
end
