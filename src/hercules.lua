#!/usr/bin/env lua

-- ─── Polyfills for Lua 5.3+ (math.ldexp/frexp removed in 5.3+) ────────────────
if not math.ldexp then
    math.ldexp = function(x, n) return x * 2 ^ n end
end
if not math.frexp then
    math.frexp = function(x)
        if x == 0 then return 0, 0 end
        local exp = math.floor(math.log(math.abs(x)) / math.log(2)) + 1
        local mantissa = x / 2 ^ exp
        return mantissa, exp
    end
end

local Pipeline = require("pipeline")
local config = require("config")
local manifest = require("manifest")
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
    return sz or 0
end

local function map(func, tbl)
    local mapped = {}
    for k, v in pairs(tbl) do
        mapped[k] = func(v, k)
    end
    return mapped
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

local obfuscated_list = {}

local function json_escape(value)
    return tostring(value)
        :gsub('\\', '\\\\')
        :gsub('"', '\\"')
        :gsub('\n', '\\n')
        :gsub('\r', '\\r')
        :gsub('\t', '\\t')
end

local function json_value(value)
    local value_type = type(value)
    if value_type == "string" then
        return '"' .. json_escape(value) .. '"'
    elseif value_type == "number" or value_type == "boolean" then
        return tostring(value)
    elseif value_type == "table" then
        local parts = {}
        local is_array = #value > 0
        local count = 0
        for k in pairs(value) do
            if type(k) ~= "number" then
                is_array = false
                break
            end
            count = math.max(count, k)
        end
        if is_array then
            for i = 1, count do
                parts[#parts + 1] = json_value(value[i])
            end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        for k, v in pairs(value) do
            if type(v) ~= "function" then
                parts[#parts + 1] = '"' .. json_escape(k) .. '":' .. json_value(v)
            end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "null"
end

local function json_array(values)
    local parts = {}
    for _, value in ipairs(values or {}) do
        parts[#parts + 1] = json_value(value)
    end
    return "[" .. table.concat(parts, ",") .. "]"
end

local function printManifestJson()
    local methods = {}
    for _, method in ipairs(manifest.modules_by_bit_position()) do
        methods[#methods + 1] = "{" .. table.concat({
            '"key":' .. json_value(method.key),
            '"config_key":' .. json_value(method.config_key),
            '"name":' .. json_value(method.name),
            '"module":' .. json_value(method.module),
            '"enabled":' .. json_value(method.enabled),
            '"bit_position":' .. json_value(method.bit_position),
            '"pipeline_order":' .. json_value(method.pipeline_order),
            '"cli":' .. json_value(method.cli or {}),
            '"incompatible_with":' .. json_array(method.incompatible_with),
            '"settings":' .. json_value(method.settings or {}),
            '"description":' .. json_value(method.description or ""),
        }, ",") .. "}"
    end

    print("{" .. table.concat({
        '"version":' .. json_value(manifest.version),
        '"output":' .. json_value(manifest.output),
        '"presets":' .. json_value(manifest.presets),
        '"language_detection":' .. json_value(manifest.language_detection),
        '"modules":[' .. table.concat(methods, ",") .. "]",
    }, ",") .. "}")
end

local BANNER = colors.blue .. [[                                                                                     
                                _                       ____         ___     
  /\  /\ ___  _ __  ___  _   _ | |  ___  ___   /\   /\ |___  \      / _ \  
 / /_/ // _ \| '__|/ __|| | | || | / _ \/ __|  \ \ / /   __) |     | | | |
/ __  /|  __/| |  | (__ | |_| || ||  __/\__ \   \ V /   / __/   _  | |_| |
\/ /_/  \___||_|   \___| \__,_||_| \___||___/    \_/   |_____| (_)  \___/
 
       
                                       ]] .. colors.reset

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

    local line = colors.white .. string.rep("═", 65) .. colors.reset
    print("\n" .. line)
    print(BANNER)
    print(colors.white .. "Obfuscation Complete!" .. colors.reset)
    print(colors.white .. "Details:" .. colors.reset)
    print(line)
    print(colors.white .. "Time Taken        : " .. string.format("%.2f", time) .. " seconds" .. colors.reset)
    print(colors.cyan .. "Original Size     : " .. original_size .. " bytes" .. colors.reset)
    print(colors.cyan .. "Obfuscated Size   : " .. obfuscated_size .. " bytes" .. colors.reset)
    print(colors.cyan .. "Size Difference   : " .. (obfuscated_size - original_size) .. " bytes (" .. size_diff_percent .. "%)" .. colors.reset)

    local function formatBool(val) 
        return val and colors.green .. "True" .. colors.reset or colors.red .. "False" .. colors.reset 
    end

    print(colors.cyan .. "Overwrite         : " .. formatBool(options.overwrite))
    print(colors.cyan .. "Folder Mode       : " .. formatBool(options.folder_mode))
    local target_label = string.upper(options.target)
    if not options.target_override then
        target_label = target_label .. " (auto)"
    end
    print(colors.cyan .. "Target            : " .. target_label .. colors.reset)
    if options.folder_mode then
        if not output then
            print(colors.white .. "Output File       : " .. colors.reset
                .. colors.cyan .. table.concat(obfuscated_list, ", ") .. colors.reset)
        end
    else
        print(colors.white .. "Output File       : " .. output .. colors.reset)
    end

    if options.sanity_check then
        if options.sanity_failed then
            print(colors.red .. "Sanity Check      : Failed" .. colors.reset)
            print(colors.yellow .. "\nExpected output:" .. colors.reset)
            print(colors.white .. options.sanity_info.expected .. colors.reset)
            print(colors.yellow .. "\nGot output:" .. colors.reset)
            print(colors.white .. options.sanity_info.got .. colors.reset)
            print(colors.red .. "Please dm 'zeusssz_' on Discord with with the file, or make an issue on the GitHub" .. colors.reset)
            print(colors.red .. "You may also join the Discord Server using the invite link" .. colors.reset)
        else
            print(colors.green .. "Sanity Check      : Passed" .. colors.reset)
        end
    end

    print(line)

    local settings = {
        { "Watermark", config.get("settings.watermark_enabled") },
    }
    for _, method in ipairs(manifest.modules_by_bit_position()) do
        settings[#settings + 1] = {
            method.name,
            config.get("settings." .. method.config_key .. ".enabled"),
        }
    end

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

local function find_preset(name)
    for _, preset in ipairs(manifest.presets or {}) do
        if preset.key == name then
            return preset
        end
    end
    return nil
end

local function apply_method_selection(selected_methods)
    for _, method in ipairs(manifest.modules) do
        config.settings[method.config_key].enabled = selected_methods[method.key] == true
    end
end

local function printUsage()
    print(colors.white .. "Usage: " .. colors.reset .. colors.cyan .. "./hercules.lua *.lua (+ any options)" .. colors.reset)
    print(colors.white .. "\nOptional Presets:" .. colors.reset)
    for _, preset in ipairs(manifest.presets or {}) do
        local flag = "--" .. preset.key
        print(colors.cyan .. flag .. string.rep(" ", math.max(1, 22 - #flag)) .. colors.green .. preset.description .. colors.reset)
    end
    
    print(colors.white .. "\nGeneral Flags:" .. colors.reset)
    local general_flags = {
        { flags = {"--overwrite", ""}, description = "Overwrites the original file with obfuscated code" },
        { flags = {"--folder", ""}, description = "Process all Lua files in the given folder" },
        { flags = {"--sanity", ""}, description = "Check if obfuscated code output matches original" },
        { flags = {"--target <t>", ""}, description = "Target runtime: 'lua', 'luau' (Roblox), or 'glua' (Garry's Mod)" },
        { flags = {"--watermark <text>", ""}, description = "Use custom watermark text for this run" },
        { flags = {"--watermark-file <path>", ""}, description = "Use a custom watermark module file for this run" },
        { flags = {"--no-watermark", ""}, description = "Disable watermark output for this run" },
        { flags = {"--manifest-json", ""}, description = "Print API manifest JSON and exit" }
    }
    for _, flag in ipairs(general_flags) do
        print(colors.cyan .. flag.flags[1] .. flag.flags[2] .. colors.green .. string.rep(" ", 20 - #flag.flags[1] - #flag.flags[2]) .. flag.description .. colors.reset)
    end

    print(colors.white .. "\nObfuscation Flags:" .. colors.reset)

local obfuscation_flags = {}
for _, method in ipairs(manifest.modules_by_bit_position()) do
    obfuscation_flags[#obfuscation_flags + 1] = {
        flags = { method.cli.short, method.cli.long },
        description = method.description,
    }
end

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
    print(colors.cyan .. short_flag .. ", " .. long_flag .. padding .. colors.white .. ": " .. colors.green .. flag.description .. colors.reset)
end
os.exit(1)
end

-- ─── Target Auto-Detection ─────────────────────────────────────────────────────
-- The manifest owns target detection metadata so API and CLI stay in sync.
local function score_language(code, language)
    local detection = manifest.language_detection or {}
    local language_config = ((detection.languages or {})[language] or {})
    local score = 0
    for _, item in ipairs(language_config.patterns or {}) do
        local matched = item.lua_pattern and code:match(item.lua_pattern)
        for _, pattern in ipairs(item.lua_patterns or {}) do
            matched = matched or code:match(pattern)
        end
        if matched then
            score = score + (item.weight or 1)
        end
    end
    return score
end

local function detect_target(code, file_path)
    local threshold = (manifest.language_detection or {}).threshold or 2
    local luau_score = score_language(code, "luau")
    local glua_score = score_language(code, "glua")

    if glua_score > luau_score and glua_score >= threshold then
        return "glua"
    elseif luau_score > glua_score and luau_score >= threshold then
        return "luau"
    elseif file_path and file_path:match("%.luau$") then
        return "luau"
    end

    return "lua"
end

local function main()
    if #arg == 1 and arg[1] == "--manifest-json" then
        printManifestJson()
        return
    end

    if #arg < 1 then
        print(colors.red .. "Error: No input file specified" .. colors.reset)
        printUsage()
        os.exit(1)
    end

    local input = arg[1]
    if input:sub(1,1) == "-" then
        print(colors.red .. "Error: Unexpected flag '" .. input .. "'" .. colors.reset)
        printUsage()
        os.exit(1)
    end

    local options = {
        overwrite = false,
        custom_file = nil,
        folder_mode = false,
        sanity_check = false,
        target = nil,
        target_override = false,
        watermark = nil,
        watermark_file = nil,
        no_watermark = false,
    }

    local features = {}
    for _, method in ipairs(manifest.modules) do
        features[method.config_key] = false
    end

    local i = 2
    while i <= #arg do
        if arg[i] == "--overwrite" then
            options.overwrite = true
        elseif arg[i] == "--folder" then
            options.folder_mode = true
        elseif arg[i] == "--sanity" then
            options.sanity_check = true
        elseif arg[i] == "--no-watermark" then
            options.no_watermark = true
        elseif arg[i] == "--watermark" then
            local next_arg = arg[i + 1]
            if next_arg and next_arg ~= "" then
                options.watermark = next_arg
                i = i + 1
            else
                print(colors.red .. "Error: --watermark requires text" .. colors.reset)
                printUsage()
                os.exit(1)
            end
        elseif arg[i] == "--watermark-file" then
            local next_arg = arg[i + 1]
            if next_arg and next_arg ~= "" then
                options.watermark_file = next_arg
                i = i + 1
            else
                print(colors.red .. "Error: --watermark-file requires a path" .. colors.reset)
                printUsage()
                os.exit(1)
            end
        elseif manifest.find_by_flag(arg[i]) then
            local method = manifest.find_by_flag(arg[i])
            features[method.config_key] = true
        elseif arg[i]:match("^%-%-") and find_preset(arg[i]:sub(3)) then
            options.preset_key = arg[i]:sub(3)
        elseif arg[i] == "--target" then
            local next_arg = arg[i + 1]
            if next_arg == "lua" or next_arg == "luau" or next_arg == "glua" then
                options.target = next_arg
                options.target_override = true
                i = i + 1
            else
                print(colors.red .. "Error: --target requires 'lua', 'luau', or 'glua'" .. colors.reset)
                printUsage()
                os.exit(1)
            end
        else
            print(colors.red .. "Error: Unknown option '" .. arg[i] .. "'" .. colors.reset)
            printUsage()
            os.exit(1)
        end
        i = i + 1
    end
    if not options.folder_mode and not input:match("%.lua$") and not input:match("%.luau$") then
        print(colors.red .. "Error: Invalid file extension for '" .. input .. "'" .. colors.reset)
        printUsage()
        os.exit(1)
    end
    if options.folder_mode then
        if not os.rename(input, input) then
            print(colors.red .. "Error: Folder '" .. input .. "' does not exist or could not be found" .. colors.reset)
            printUsage()
            os.exit(1)
        end
    else
        local fh = io.open(input, "r")
        if not fh then
            print(colors.red .. "Error: File '" .. input .. "' does not exist or could not be found" .. colors.reset)
            printUsage()
            os.exit(1)
        end
        fh:close()
    end

    local selected_methods = {}
    local preset = options.preset_key and find_preset(options.preset_key)
    if preset then
        for _, method_key in ipairs(preset.methods or {}) do
            selected_methods[method_key] = true
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
        for _, method in ipairs(manifest.modules) do
            if features[method.config_key] then
                selected_methods[method.key] = true
            end
        end
    end

    if preset or single_enabled then
        apply_method_selection(selected_methods)
    end

    local base_module_enabled = {}
    for _, method in ipairs(manifest.modules) do
        base_module_enabled[method.config_key] = config.get("settings." .. method.config_key .. ".enabled")
    end

    if options.no_watermark then
        config.set("settings.watermark_text", "")
        config.set("settings.watermark_module_file", nil)
    elseif options.watermark_file ~= nil then
        config.set("settings.watermark_module_file", options.watermark_file)
    elseif options.watermark ~= nil then
        config.set("settings.watermark_text", options.watermark)
        config.set("settings.watermark_module_file", nil)
    end

    local files = {}
    if options.folder_mode then
        local ext_patterns = { lua = "*.lua", luau = "*.luau", glua = "*.lua" }
        local ext = ext_patterns[options.target] or "*.lua"
        local find_command
        if package.config:sub(1,1) == "\\" then
            -- windows
            local pattern = input .. "\\" .. ext
            find_command = string.format('dir %q /b /s 2>nul', pattern)
        else
            -- mac/linux
            find_command = string.format('find %q -type f -name "%s"', input, ext)
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

        -- Auto-detect target from source code (can be overridden with --target)
        if not options.target_override then
            options.target = detect_target(code, file_path)
        end
        if not options.target then
            options.target = "lua"
        end

        config.target = options.target
        for _, method in ipairs(manifest.modules) do
            config.settings[method.config_key].enabled =
                base_module_enabled[method.config_key] and not manifest.is_incompatible(method, options.target)
        end

        -- Luau/GLua compatibility: replace load() with loadstring()
        -- Luau's load() only accepts functions, not strings
        -- Only replace load( when preceded by whitespace, operators, or at line start
        -- to avoid matching load( inside string literals
        if options.target == "luau" then
            code = code:gsub("([^%w_])load%(", "%1loadstring(")
            code = code:gsub("^load(", "loadstring(")
        end

        local start_time = os.clock()
        local obfuscated_code, sanity_failed, sanity_info
        local attempts, success = 0, false

        -- Polyfills for Lua 5.3+ / Luau compatibility
        local polyfills = [[-- Lua 5.3+ / Luau compatibility polyfills
if not math.ldexp then math.ldexp = function(x, n) return x * 2 ^ n end end
if not math.frexp then math.frexp = function(x)
    if x == 0 then return 0, 0 end
    local exp = math.floor(math.log(math.abs(x)) / math.log(2)) + 1
    local mantissa = x / 2 ^ exp
    return mantissa, exp
end end
if not loadstring and load then loadstring = load end
if not loadstring then loadstring = function(s) return load(s) end end

]]

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

        local output_ext = options.target == "luau" and ".luau" or ".lua"
        local output_file
        if options.overwrite then
            output_file = file_path
        elseif file_path:match("%.luau$") then
            output_file = file_path:gsub("%.luau$", "_obfuscated" .. output_ext)
        else
            output_file = file_path:gsub("%.lua$", "_obfuscated" .. output_ext)
        end
        local out_file_handle = assert(io.open(output_file, "w"))
        out_file_handle:write(polyfills .. obfuscated_code)
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
