#!/usr/bin/env lua

local Pipeline = require("pipeline")
local config = require("config")
-- utils

local function filesize(file)
    local f = io.open(file, "r")
    if not f then return 0 end
    local sz
    local success, err = pcall(function()
        sz = f:seek("end")
    end)
    f:close()
    if not success then return 0 end
    return sz
end

local function map(func, tbl)
    local mapped = {}
    for k, v in pairs(tbl) do
        mapped[k] = func(v, k)
    end
    return mapped
end

local colors = {
    reset = "",
    green = "",
    red = "",
    white = "",
    cyan = "", 
    blue = "",
    yellow = ""
}

local obfuscated_list = {}

local BANNER = [[
                                _                      _        __   
  /\  /\ ___  _ __  ___  _   _ | |  ___  ___   __   __/ |      / /_  
 / /_/ // _ \| '__|/ __|| | | || | / _ \/ __|  \ \ / /| |     | '_ \ 
/ __  /|  __/| |  | (__ | |_| || ||  __/\__ \   \ V / | |  _  | (_) |
\/ /_/  \___||_|   \___| \__,_||_| \___||___/    \_/  |_| (_)  \___/ 
                                       ]]

local function runSanityCheck(original_code, obfuscated_code)
    local function captureOutput(code)
        local output = {}
        local ogprint = _G.print
        local success, result = pcall(function()
            _G.print = function(...)
                local args = {...}
                local str = table.concat(map(tostring, args), "\t")
                table.insert(output, str)
            end
            local func, err = load(code)
            if not func then
                error("Compilation error: " .. tostring(err))
            end
            local status, run_result = pcall(func)
            if not status then
                error("Runtime error: " .. tostring(run_result))
            end
        end)
        _G.print = ogprint
        if not success then
            return "", result
        end
        return table.concat(output, "\n"), nil
    end

    local original_output, original_err = captureOutput(original_code)
    local obfuscated_output, obfuscated_err = captureOutput(obfuscated_code)

    if original_err or obfuscated_err then
        return false, { expected = original_err or original_output, got = obfuscated_err or obfuscated_output }
    end

    return original_output == obfuscated_output, { expected = original_output, got = obfuscated_output }
end

local function printCliResult(input, output, time, options)
    local original_size = filesize(input)
    local obfuscated_size = output and filesize(output) or 0
    local size_diff_percent
    if original_size > 0 then
        size_diff_percent = string.format("%.2f", ((obfuscated_size - original_size) / original_size) * 100 + 100)
    else
        size_diff_percent = "N/A"
    end

    local line = string.rep("=", 65)
    print("\n" .. line)
    print(BANNER)
    print("Obfuscation Complete!")
    print("Details:")
    print(line)
    print("Time Taken        : " .. string.format("%.2f", time) .. " seconds")
    print("Original Size     : " .. original_size .. " bytes")
    print("Obfuscated Size   : " .. obfuscated_size .. " bytes")
    print("Size Difference   : " .. (obfuscated_size - original_size) .. " bytes (" .. size_diff_percent .. "%)")

    local function formatBool(val) 
        return val and "True" or "False"
    end

    print(colors.cyan .. "Overwrite         : " .. formatBool(options.overwrite))
    print(colors.cyan .. "Folder Mode       : " .. formatBool(options.folder_mode))
    if options.folder_mode then
        if not output then
            print("Output File       : " .. table.concat(obfuscated_list, ", "))
        end
    else
        print("Output File       : " .. output)
    end

    if options.sanity_check then
        if options.sanity_failed then
            print("Sanity Check      : Failed")
            print("\nExpected output:")
            print(options.sanity_info.expected)
            print("\nGot output:")
            print(options.sanity_info.got)
            print("Please dm 'zeusssz_' on Discord with with the file, or make an issue on the GitHub")
            print("You may also join the Discord Server using the invite link")
        else
            print("Sanity Check      : Passed")
        end
    end

    print(line)

    local settings = {
        { "Watermark", config.get("settings.watermark_enabled") },
        { "Control Flow", config.get("settings.control_flow.enabled") },
        { "String Encoding", config.get("settings.string_encoding.enabled") },
        { "Variable Renaming", config.get("settings.variable_renaming.enabled") },
        { "Garbage Code", config.get("settings.garbage_code.enabled") },
        { "Opaque Predicates", config.get("settings.opaque_predicates.enabled") },
        { "Compressor", config.get("settings.compressor.enabled") },
        { "Function Wrapping", config.get("settings.WrapInFunction.enabled") },
        { "Virtual Machine", config.get("settings.VirtualMachine.enabled") },
        { "Anti Tamper", config.get("settings.antitamper.enabled") },
    }

    local max_length = 0
    for _, setting in ipairs(settings) do
        if #setting[1] > max_length then
            max_length = #setting[1]
        end
    end

    for _, setting in ipairs(settings) do
        local name = setting[1]
        local status = (setting[2] and "Enabled" or "Disabled")
        local padding = string.rep(" ", max_length - #name + 1)
        print(name .. padding .. ":" .. " " .. status)
    end

    print(line .. "\n")
end

local function applyPreset(level)
    if level == "min" then
        config.set("settings.variable_renaming.min_name_length", 10)
        config.set("settings.variable_renaming.max_name_length", 20)
        config.set("settings.garbage_code.garbage_blocks", 5)
        config.set("settings.control_flow.max_fake_blocks", 2)

    elseif level == "mid" then
        config.set("settings.variable_renaming.min_name_length", 40)
        config.set("settings.variable_renaming.max_name_length", 60)
        config.set("settings.garbage_code.garbage_blocks", 25)
        config.set("settings.control_flow.max_fake_blocks", 8)

    elseif level == "max" then
        config.set("settings.variable_renaming.min_name_length", 90)
        config.set("settings.variable_renaming.max_name_length", 120)
        config.set("settings.garbage_code.garbage_blocks", 50)
        config.set("settings.control_flow.max_fake_blocks", 12)
    end
end

local function printUsage()
    print("Usage: ./hercules.lua *.lua (+ any options)")
    print("\nOptional Presets:")
    print("--min" .. string.rep(" ", 17) .. "Minimal parameters for lighter obfuscation")
    print("--mid" .. string.rep(" ", 17) .. "Moderate parameters for balanced obfuscation")
    print("--max" .. string.rep(" ", 17) .. "Maximum parameters for heavy obfuscation")
    
    print("\nGeneral Flags:")
    local general_flags = {
        { flags = {"--overwrite", ""}, description = "Overwrites the original file with obfuscated code" },
        { flags = {"--folder", ""}, description = "Process all Lua files in the given folder" },
        { flags = {"--sanity", ""}, description = "Check if obfuscated code output matches original" }
    }
    for _, flag in ipairs(general_flags) do
        print(flag.flags[1] .. flag.flags[2] .. string.rep(" ", 20 - #flag.flags[1] - #flag.flags[2]) .. flag.description)
    end

    print("\nObfuscation Flags:")

local obfuscation_flags = {
    { flags = {"-cf", "--control_flow"}, description = "Enable control flow obfuscation" },
    { flags = {"-se", "--string_encoding"}, description = "Enable string encoding" },
    { flags = {"-vr", "--variable_renaming"}, description = "Enable variable renaming" },
    { flags = {"-gci", "--garbage_code"}, description = "Enable garbage code injection" },
    { flags = {"-opi", "--opaque_preds"}, description = "Enable opaque predicates injection" },
    { flags = {"-vm", "--virtual_machine"}, description = "Enable virtual machine transformation" },
    { flags = {"-wif", "--wrap_in_func"}, description = "Enable function wrapping" },
    { flags = {"-fi", "--func_inlining"}, description = "Enable function inlining" },
    { flags = {"-dc", "--dynamic_code"}, description = "Enable dynamic code generation" },
    { flags = {"-c", "--compressor"}, description = "Enable compressor" },
    { flags = {"-at", "--antitamper"}, description = "Enable antitamper" }
}

local max_flag_length = 0
for _, flag in ipairs(obfuscation_flags) do
    local short_flag = flag.flags[1]
    local long_flag = flag.flags[2]
    max_flag_length = math.max(max_flag_length, #short_flag + #long_flag + 2)
end
for _, flag in ipairs(obfuscation_flags) do
    local short_flag = flag.flags[1]
    local long_flag = flag.flags[2]
    local padding = string.rep(" ", max_flag_length - (#short_flag + #long_flag + 2))
    print(short_flag .. ", " .. long_flag .. padding .. ": " .. flag.description)
end
os.exit(1)
end

local function main()
    if #arg < 1 then
        print("Error: No input file specified")
        printUsage()
        os.exit(1)
    end

    local input = arg[1]
    if input:sub(1,1) == "-" then
        print("Error: Unexpected flag '" .. input .. "'")
        printUsage()
        os.exit(1)
    end

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
        compressor = false,
        VirtualMachine = false,
        WrapInFunction = false,
        function_inlining = false,
        dynamic_code = false,
        antitamper = false,
    }

    for i = 2, #arg do
        if arg[i] == "--overwrite" then
            options.overwrite = true
        elseif arg[i] == "--folder" then
            options.folder_mode = true
        elseif arg[i] == "--sanity" then
            options.sanity_check = true
        elseif arg[i] == "-cf" or arg[i] == "--control_flow" then
            features.control_flow = true
        elseif arg[i] == "-c" or arg[i] == "--compressor" then
            features.compressor = true
        elseif arg[i] == "-se" or arg[i] == "--string_encoding" then
            features.string_encoding = true
        elseif arg[i] == "-vr" or arg[i] == "--variable_renaming" then
            features.variable_renaming = true
        elseif arg[i] == "-gci" or arg[i] == "--garbage_code" then
            features.garbage_code = true
        elseif arg[i] == "-opi" or arg[i] == "--opaque_preds" then
            features.opaque_predicates = true
        elseif arg[i] == "-vm" or arg[i] == "--virtual_machine" then
            features.VirtualMachine = true
        elseif arg[i] == "-wif" or arg[i] == "--wrap_in_func" then
            features.WrapInFunction = true
        elseif arg[i] == "-fi" or arg[i] == "--func_inlining" then
            features.function_inlining = true
        elseif arg[i] == "-dc" or arg[i] == "--dynamic_code" then
            features.dynamic_code = true
        elseif arg[i] == "-at" or arg[i] == "--antitamper" then
            features.antitamper = true
        elseif arg[i] == "--min" then
            options.preset_level = "min"
        elseif arg[i] == "--mid" then
            options.preset_level = "mid"
        elseif arg[i] == "--max" then
            options.preset_level = "max"
        else
            print("Error: Unknown option '" .. arg[i] .. "'")
            printUsage()
            os.exit(1)
        end
    end
    if not options.folder_mode and not input:match("%.lua$") then
        print("Error: Invalid file extension for '" .. input .. "'")
        printUsage()
        os.exit(1)
    end
    if options.folder_mode then
        if not os.rename(input, input) then
            print("Error: Folder '" .. input .. "' does not exist or could not be found")
            printUsage()
            os.exit(1)
        end
    else
        local fh = io.open(input, "r")
        if not fh then
            print("Error: File '" .. input .. "' does not exist or could not be found")
            printUsage()
            os.exit(1)
        end
        fh:close()
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
        local find_command
        if package.config:sub(1,1) == "\\" then
            -- windows
            local pattern = input .. "\\*.lua"
            find_command = string.format('dir %q /b /s 2>nul', pattern)
        else
            -- mac/linux
            find_command = string.format('find %q -type f -name "*.lua"', input)
        end
        local p = io.popen(find_command)
        if not p then
            error("Error: Failed to execute find command: " .. find_command)
        end
        for file in p:lines() do
            table.insert(files, file)
        end
        p:close()
  else
        table.insert(files, input)
    end

    obfuscated_list = {}
    local batch_start = os.clock()
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
                success, sanity_info = runSanityCheck(code, obfuscated_code)
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

        table.insert(obfuscated_list, output_file)
        local file_time = os.clock() - start_time
        options.sanity_failed = sanity_failed
        options.sanity_info = sanity_info
        if not options.folder_mode then
            printCliResult(file_path, output_file, file_time, options)
        end
    end
    if options.folder_mode then
        local total_time = os.clock() - batch_start
        printCliResult(input, nil, total_time, options)
    end
end
main()
