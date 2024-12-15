#!/usr/bin/env lua

local Pipeline = require("pipeline")
local config = require("config")

local function filesize(file)
    local f = io.open(file, "r")
    if not f then return 0 end
    local sz = f:seek("end")
    f:close()
    return sz
end

local colors = {
    reset = "\27[0m",
    green = "\27[32m",
    red = "\27[31m",
    white = "\27[37m",
    cyan = "\27[36m", 
    blue = "\27[34m",
    yellow = "\27[33m"
}

local BANNER = colors.blue .. [[
                                _                      _        __   
  /\  /\ ___  _ __  ___  _   _ | |  ___  ___   __   __/ |      / /_  
 / /_/ // _ \| '__|/ __|| | | || | / _ \/ __|  \ \ / /| |     | '_ \ 
/ __  /|  __/| |  | (__ | |_| || ||  __/\__ \   \ V / | |  _  | (_) |
\/ /_/  \___||_|   \___| \__,_||_| \___||___/    \_/  |_| (_)  \___/ 
                                       ]] .. colors.reset

local function runsanecheck(original_code, obfuscated_code)
    local function captureoutput(code)
        local output = {}
        local ogprint = _G.print
        _G.print = function(...)
            local args = {...}
            local str = table.concat(map(tostring, args), "\t")
            table.insert(output, str)
        end
        local func, err = load(code)
        if not func then
            return "", "Compilation error: " .. tostring(err)
        end
        local status, result = pcall(func)
        _G.print = ogprint
        if not status then
            return "", "Runtime error: " .. tostring(result)
        end
        return table.concat(output, "\n"), nil
    end

    local original_output, original_err = captureoutput(original_code)
    local obfuscated_output, obfuscated_err = captureoutput(obfuscated_code)

    if original_err or obfuscated_err then
        return false, { expected = original_err or original_output, got = obfuscated_err or obfuscated_output }
    end

    return original_output == obfuscated_output, { expected = original_output, got = obfuscated_output }
end

local function printcliresult(input, output, time, options)
    local og_size = filesize(input)
    local obfuscated_size = filesize(output)
    local size_diff_percent = string.format("%.2f", ((obfuscated_size - og_size) / og_size) * 100 + 100)

    local line = colors.white .. string.rep("=", 65) .. colors.reset
    print("\n" .. line)
    print(BANNER)
    print(colors.white .. "Obfuscation Complete!" .. colors.reset)
    print(line)
    print(colors.white .. "Time Taken        : " .. string.format("%.2f", time) .. " seconds" .. colors.reset)
    print(colors.cyan .. "Original Size     : " .. og_size .. " bytes" .. colors.reset)
    print(colors.cyan .. "Obfuscated Size   : " .. obfuscated_size .. " bytes" .. colors.reset)
    print(colors.cyan .. "Size Difference   : " .. (obfuscated_size - og_size) .. " bytes (" .. size_diff_percent .. "%)" .. colors.reset)

    local function formatbool(val) 
        return val and colors.green .. "True" .. colors.reset or colors.red .. "False" .. colors.reset 
    end

    print(colors.cyan .. "Overwrite         : " .. formatbool(options.overwrite))
    print(colors.cyan .. "Custom Pipeline   : " .. formatbool(options.custom_file))
    print(colors.white .. "Output File       : " .. output .. colors.reset)

    if options.sanity_check then
        if options.sanity_failed then
            print(colors.red .. "Sanity Check      : Failed" .. colors.reset)
            print(colors.yellow .. "\nExpected output:" .. colors.reset)
            print(colors.white .. options.sanity_info.expected .. colors.reset)
            print(colors.yellow .. "\nGot output:" .. colors.reset)
            print(colors.white .. options.sanity_info.got .. colors.reset)
        else
            print(colors.green .. "Sanity Check      : Passed" .. colors.reset)
        end
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

local function print_usage()
    print(colors.white .. "Usage: " .. colors.reset .. colors.cyan .. "./hercules.lua *.lua (+ any options)" .. colors.reset)
    print(colors.white .. "\nFlags:" .. colors.reset)
    local flags = {
        { flags = {"--overwrite", ""}, description = "Overwrites the original file with obfuscated code" },
        { flags = {"--pipeline", " <file>"}, description = "Use a custom pipeline for obfuscation" },
        { flags = {"--folder", ""}, description = "Process all Lua files in the given folder" },
        { flags = {"--sanity", ""}, description = "Check if obfuscated code output matches original" }
    }
    for _, flag in ipairs(flags) do
        print(colors.cyan .. flag.flags[1] .. flag.flags[2] .. colors.green .. string.rep(" ", 20 - #flag.flags[1] - #flag.flags[2]) .. flag.description .. colors.reset)
    end
    os.exit(1)
end

local function main()
    if #arg < 1 then
        print_usage()
    end

    local input = arg[1]
    local options = {
        overwrite = false,
        custom_file = nil,
        folder_mode = false,
        sanity_check = false
    }

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
        WrapInFunction = false,
        function_inlining = false,
        dynamic_code = false,
    }

    for i = 2, #arg do
        if arg[i] == "--overwrite" then
            options.overwrite = true
        elseif arg[i] == "--pipeline" then
            if arg[i + 1] then
                options.custom_file = arg[i + 1]:gsub("%.lua$", "")
                i = i + 1
            else
                print_usage()
            end
        elseif arg[i] == "--folder" then
            options.folder_mode = true
        elseif arg[i] == "--sanity" then
            options.sanity_check = true
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
        elseif arg[i] == "--FI" or arg[i] == "--func_inlining" then
            features.function_inlining = true
        elseif arg[i] == "--DC" or arg[i] == "--dynamic_code" then
            features.dynamic_code = true
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
        for feature, enabled in pairs(features) do
            config.settings[feature].enabled = enabled
        end
    end

    local files = {}
    if options.folder_mode then
        for file in io.popen('ls "' .. input .. '"'):lines() do
            if file:match("%.lua$") then
                table.insert(files, input .. "/" .. file)
            end
        end
    else
        table.insert(files, input)
    end

    for _, file_path in ipairs(files) do
        local file = io.open(file_path, "r")
        if not file then
            print("Error: Could not open file " .. file_path)
            os.exit(1)
        end

        local code = file:read("*all")
        file:close()

        local start_time = os.clock()
        local obfuscated_code, sanity_failed, sanity_info
        local attempts, success = 0, false

        repeat
            attempts = attempts + 1
            if options.custom_file then
                local ok, custom = pcall(require, options.custom_file)
                if not ok then
                    print("Error: Could not load custom pipeline module: " .. tostring(custom))
                    os.exit(1)
                end
                obfuscated_code = custom.process(code)
            else
                obfuscated_code = Pipeline.process(code)
            end

            if options.sanity_check then
                success, sanity_info = runsanecheck(code, obfuscated_code)
                if not success and attempts >= 3 then
                    sanity_failed = true
                    break
                end
            else
                success = true
            end
        until success or attempts >= 3

        local output_file = options.overwrite and file_path or file_path:gsub("%.lua$", "_obfuscated.lua")
        local out_file_handle = assert(io.open(output_file, "w"))
        out_file_handle:write(obfuscated_code)
        out_file_handle:close()

        local end_time = os.clock()
        options.sanity_failed = sanity_failed
        options.sanity_info = sanity_info

        printcliresult(file_path, output_file, end_time - start_time, options)
    end
end

function map(func, tbl)
    local mapped = {}
    for k, v in pairs(tbl) do
        mapped[k] = func(v, k)
    end
    return mapped
end

main()
