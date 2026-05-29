--[[
Hercules Obfuscator manifest

This file is the single source of truth for obfuscation module metadata. The
runtime pipeline, CLI flag parser, and external consumers such as Hercules-API
must derive module information from this manifest instead of duplicating it.

Top-level keys:
- version: Schema version for external consumers.
- output: Global output defaults.
- modules: Ordered module metadata. The table order is not semantically
  important; use bit_position for API bitkeys and pipeline_order for execution.
- presets: Named method sets exposed by the API and CLI consumers.
- language_detection: Weighted Lua/Luau/GLua detection patterns. `pattern` is a
  Python-compatible regex for API consumers; `lua_pattern` or `lua_patterns` are
  Lua patterns used by this CLI.

output keys:
- suffix: Default suffix for generated files when not overwriting.
- watermark_enabled: Enables the watermark module by default.
- watermark_text: Default text prepended by the watermark module. An empty
  string intentionally disables watermark output for the current run.
- final_print: Whether the CLI prints its completion summary.

module keys:
- key: Stable snake_case API identifier. Do not rename without a migration.
- config_key: Internal config.settings key used by legacy modules and presets.
- name: Human-readable display name.
- module: Lua require path for the processor module.
- enabled: Default enabled state.
- bit_position: Stable API bit position. Do not change when pipeline order
  changes, because clients may persist bitkeys.
- pipeline_order: Internal execution order. This may change to fix correctness
  without changing API bitkeys.
- cli.short / cli.long: CLI flags that enable only this module.
- incompatible_with: Target runtimes where the module must be skipped. Valid
  values are "lua", "luau", and "glua".
- settings: Optional module-specific default settings copied into config.lua.
- description: Human-readable description used by CLI help and API responses.
- process: Optional adapter for modules whose process function needs settings.

Tests may provide HERCULES_MANIFEST_EXTRA=/path/to/extra_manifest.lua. The extra
file must return a table with optional output and modules keys. It is additive
and exists only to verify that new modules are discovered consistently.
]]

local manifest = {}

manifest.version = 1

manifest.output = {
    suffix = "_obfuscated.lua",
    watermark_enabled = true,
    watermark_text = "--[Obfuscated by Hercules v2.0.0 | hercules-obfuscator.xyz/discord | hercules-obfuscator.xyz/source]\n",
    final_print = true,
}

manifest.presets = {
    {
        key = "light",
        description = "Renames symbols + compresses output - minimal overhead",
        methods = {
            "variable_renaming",
            "compressor",
        },
    },
    {
        key = "balanced",
        description = "Control-flow, string encoding, opaque predicates - everyday protection",
        methods = {
            "variable_renaming",
            "control_flow",
            "string_encoding",
            "opaque_predicates",
            "compressor",
        },
    },
    {
        key = "heavy",
        description = "Expression obfuscation, garbage code, inlining - strong protection",
        methods = {
            "variable_renaming",
            "control_flow",
            "string_encoding",
            "string_to_expressions",
            "opaque_predicates",
            "garbage_code",
            "function_inlining",
            "wrap_in_function",
            "antitamper",
            "dynamic_code",
            "compressor",
        },
    },
    {
        key = "maximum",
        description = "All methods - maximum obfuscation (incompatible per language filtered)",
        methods = {
            "virtual_machine",
            "antitamper",
            "control_flow",
            "string_to_expressions",
            "string_encoding",
            "wrap_in_function",
            "variable_renaming",
            "garbage_code",
            "opaque_predicates",
            "function_inlining",
            "dynamic_code",
            "bytecode_encoding",
            "compressor",
        },
    },
}

manifest.language_detection = {
    threshold = 2,
    confidence_divisor = 10,
    languages = {
        luau = {
            patterns = {
                { pattern = "^#!.*\\bluau\\b", lua_pattern = "^#!.*luau", weight = 3, description = "luau shebang" },
                { pattern = "^--!", lua_pattern = "^%-%-!", weight = 3, description = "luau type comment" },
                { pattern = "\\bexport\\s+type\\s+\\w+", lua_pattern = "export%s+type%s+%w+", weight = 3, description = "export type" },
                { pattern = "\\btype\\s+\\w+\\s*=\\s*.+", lua_pattern = "type%s+%w+%s*=.+", weight = 2, description = "type alias" },
                { pattern = "\\blocal\\s+\\w+\\s*:\\s*\\w+", lua_pattern = "local%s+%w+%s*:%s*%w+", weight = 2, description = "variable type annotation" },
                { pattern = "\\bfunction\\s+\\w+\\s*\\([^)]*\\)\\s*:\\s*\\w+", lua_pattern = "function%s+%w+%s*%([^)]*%)%s*:%s*%w+", weight = 2, description = "function return type" },
                { pattern = "[+\\-*/%^..]=", lua_pattern = "[%+%-%*/%^]%=", weight = 2, description = "compound assignment" },
                { pattern = "\\bcontinue\\b", lua_pattern = "continue", weight = 1, description = "continue statement" },
                { pattern = "\\bifelse\\b", lua_pattern = "ifelse", weight = 2, description = "ifelse expression" },
                { pattern = "\\btypeset\\b", lua_pattern = "typeset", weight = 2, description = "typeset keyword" },
                { pattern = "\\)\\s*->", lua_pattern = "%)%s*%-%>", weight = 2, description = "arrow return type" },
                { pattern = "`[^`]*\\{[^}]+\\}", lua_pattern = "`[^`]*%{[^}]+%}", weight = 2, description = "string interpolation" },
                { pattern = "=\\s*if\\s+.+\\s+then\\s+", lua_pattern = "=%s*if%s+.+%s+then%s+", weight = 2, description = "if expression" },
                { pattern = "for\\s+.+\\s+in\\s+\\w+\\s+do", lua_pattern = "for%s+.+%s+in%s+%w+%s+do", weight = 1, description = "generalized iteration" },
                { pattern = "0[bB][01_]+|0[xX][0-9A-Fa-f_]+|\\d_\\d", lua_pattern = "[%d]_[%d]", weight = 1, description = "numeric separators" },
            },
        },
        glua = {
            patterns = {
                { pattern = "--@\\w+", lua_pattern = "%-%-@%w+", weight = 3, description = "glua luadoc annotation" },
                { pattern = "\\bhook\\.(Add|Remove|Run)\\s*\\(", lua_pattern = "hook%.%w+", weight = 3, description = "hook library" },
                { pattern = "\\binclude\\s*\\(", lua_pattern = "include%s*%(", weight = 3, description = "include function" },
                { pattern = "\\bAddCSLuaFile\\b", lua_pattern = "AddCSLuaFile", weight = 3, description = "AddCSLuaFile" },
                { pattern = "\\bSERVER\\b|\\bCLIENT\\b", lua_patterns = { "SERVER", "CLIENT" }, weight = 2, description = "glua constants" },
                { pattern = "\\bsurface\\.\\w+|\\bdraw\\.\\w+|\\bvgui\\.\\w+", lua_pattern = "surface%.%w+", weight = 2, description = "gmod client libraries" },
                { pattern = "\\bconcommand\\.Add\\b|\\bCreateConVar\\b", lua_pattern = "concommand%.Add", weight = 2, description = "gmod console" },
                { pattern = "\\bMsgN\\b|\\bMsg\\b", lua_pattern = "MsgN", weight = 1, description = "gmod print functions" },
                { pattern = "\\bents\\.\\w+|\\bweapon\\.\\w+", lua_pattern = "ents%.%w+", weight = 2, description = "gmod game libraries" },
                { pattern = "\\bplayer:GetByID\\b|\\bplayer:GetAll\\b|\\bplayer:GetCount\\b", lua_pattern = "player:Get", weight = 3, description = "gmod player library" },
                { pattern = "\\bVector\\s*\\(|\\bAngle\\s*\\(|\\bColor\\s*\\(", lua_patterns = { "Vector%s*%(", "Angle%s*%(", "Color%s*%(" }, weight = 2, description = "glua constructors" },
                { pattern = "\\bIsValid\\s*\\(|\\bIsValidAndEnt\\s*\\(", lua_pattern = "IsValid%s*%(", weight = 2, description = "glua validity helpers" },
                { pattern = "\\btimer\\.\\w+|\\butil\\.\\w+|\\bgame\\.\\w+|\\bnet\\.\\w+|\\bumsg\\.\\w+|\\busermessage\\.\\w+", lua_pattern = "util%.%w+", weight = 2, description = "gmod libraries" },
                { pattern = "\\bGM:\\w+|\\bGAMEMODE:\\w+", lua_pattern = "GM:%w+", weight = 2, description = "glua callbacks" },
            },
        },
    },
}

manifest.modules = {
    {
        key = "virtual_machine",
        config_key = "VirtualMachine",
        name = "Virtual Machine",
        module = "modules/VMGenerator",
        enabled = true,
        bit_position = 0,
        pipeline_order = 70,
        cli = { short = "-vm", long = "--virtual_machine" },
        incompatible_with = { "luau", "glua" },
        description = "Enable virtual machine transformation",
    },
    {
        key = "antitamper",
        config_key = "antitamper",
        name = "Anti Tamper",
        module = "modules/antitamper",
        enabled = true,
        bit_position = 1,
        pipeline_order = 80,
        cli = { short = "-at", long = "--antitamper" },
        incompatible_with = {},
        description = "Enable antitamper",
    },
    {
        key = "control_flow",
        config_key = "control_flow",
        name = "Control Flow",
        module = "modules/control_flow_obfuscator",
        enabled = true,
        bit_position = 2,
        pipeline_order = 90,
        cli = { short = "-cf", long = "--control_flow" },
        incompatible_with = {},
        settings = { max_fake_blocks = 6 },
        description = "Enable control flow obfuscation",
        process = function(processor, code, config)
            return processor.process(code, config.get("settings.control_flow.max_fake_blocks"))
        end,
    },
    {
        key = "string_to_expressions",
        config_key = "StringToExpressions",
        name = "String To Expressions",
        module = "modules/StringToExpressions",
        enabled = true,
        bit_position = 3,
        pipeline_order = 40,
        cli = { short = "-st", long = "--string_to_expressions" },
        incompatible_with = {},
        settings = { min_number_length = 100, max_number_length = 999 },
        description = "Enable string to expression conversion",
        process = function(processor, code, config)
            return processor.process(
                code,
                config.get("settings.StringToExpressions.min_number_length"),
                config.get("settings.StringToExpressions.max_number_length")
            )
        end,
    },
    {
        key = "string_encoding",
        config_key = "string_encoding",
        name = "String Encoding",
        module = "modules/string_encoder",
        enabled = true,
        bit_position = 4,
        pipeline_order = 30,
        cli = { short = "-se", long = "--string_encoding" },
        incompatible_with = {},
        description = "Enable string encoding",
    },
    {
        key = "wrap_in_function",
        config_key = "WrapInFunction",
        name = "Function Wrapping",
        module = "modules/WrapInFunction",
        enabled = true,
        bit_position = 5,
        pipeline_order = 120,
        cli = { short = "-wif", long = "--wrap_in_function" },
        incompatible_with = {},
        description = "Enable function wrapping",
    },
    {
        key = "variable_renaming",
        config_key = "variable_renaming",
        name = "Variable Renaming",
        module = "modules/variable_renamer",
        enabled = true,
        bit_position = 6,
        pipeline_order = 60,
        cli = { short = "-vr", long = "--variable_renaming" },
        incompatible_with = {},
        settings = { min_name_length = 8, max_name_length = 12 },
        description = "Enable variable renaming",
        process = function(processor, code, config)
            return processor.process(code, {
                min_length = config.get("settings.variable_renaming.min_name_length"),
                max_length = config.get("settings.variable_renaming.max_name_length"),
                target = config.target,
            })
        end,
    },
    {
        key = "garbage_code",
        config_key = "garbage_code",
        name = "Garbage Code",
        module = "modules/garbage_code_inserter",
        enabled = true,
        bit_position = 7,
        pipeline_order = 100,
        cli = { short = "-gci", long = "--garbage_code" },
        incompatible_with = {},
        settings = { garbage_blocks = 20 },
        description = "Enable garbage code injection",
        process = function(processor, code, config)
            return processor.process(code, config.get("settings.garbage_code.garbage_blocks"))
        end,
    },
    {
        key = "opaque_predicates",
        config_key = "opaque_predicates",
        name = "Opaque Predicates",
        module = "modules/opaque_predicate_injector",
        enabled = true,
        bit_position = 8,
        pipeline_order = 20,
        cli = { short = "-opi", long = "--opaque_predicates" },
        incompatible_with = {},
        description = "Enable opaque predicates injection",
    },
    {
        key = "function_inlining",
        config_key = "function_inlining",
        name = "Function Inlining",
        module = "modules/function_inliner",
        enabled = true,
        bit_position = 9,
        pipeline_order = 50,
        cli = { short = "-fi", long = "--function_inlining" },
        incompatible_with = {},
        description = "Enable function inlining",
    },
    {
        key = "dynamic_code",
        config_key = "dynamic_code",
        name = "Dynamic Code",
        module = "modules/dynamic_code_generator",
        enabled = true,
        bit_position = 10,
        pipeline_order = 10,
        cli = { short = "-dc", long = "--dynamic_code" },
        incompatible_with = {},
        description = "Enable dynamic code generation",
    },
    {
        key = "bytecode_encoding",
        config_key = "bytecode_encoding",
        name = "Bytecode Encoding",
        module = "modules/bytecode_encoder",
        enabled = true,
        bit_position = 11,
        pipeline_order = 130,
        cli = { short = "-be", long = "--bytecode_encoding" },
        incompatible_with = { "luau", "glua" },
        description = "Enable bytecode encoding",
    },
    {
        key = "compressor",
        config_key = "compressor",
        name = "Compressor",
        module = "modules/compressor",
        enabled = true,
        bit_position = 12,
        pipeline_order = 110,
        cli = { short = "-c", long = "--compressor" },
        incompatible_with = {},
        description = "Enable compressor",
    },
}

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do
        result[k] = copy(v)
    end
    return result
end

function manifest.copy(value)
    return copy(value)
end

function manifest.modules_by_pipeline()
    local modules = copy(manifest.modules)
    table.sort(modules, function(a, b)
        return a.pipeline_order < b.pipeline_order
    end)
    return modules
end

function manifest.modules_by_bit_position()
    local modules = copy(manifest.modules)
    table.sort(modules, function(a, b)
        return a.bit_position < b.bit_position
    end)
    return modules
end

function manifest.find_by_flag(flag)
    for _, method in ipairs(manifest.modules) do
        if method.cli and (flag == method.cli.short or flag == method.cli.long) then
            return method
        end
    end
    return nil
end

function manifest.is_incompatible(method, target)
    for _, language in ipairs(method.incompatible_with or {}) do
        if language == target then
            return true
        end
    end
    return false
end

local function load_extra_manifest()
    local path = os.getenv("HERCULES_MANIFEST_EXTRA")
    if not path or path == "" then
        return
    end

    local chunk, err = loadfile(path)
    if not chunk then
        error("Failed to load HERCULES_MANIFEST_EXTRA: " .. tostring(err))
    end

    local extra = chunk()
    if type(extra) ~= "table" then
        error("HERCULES_MANIFEST_EXTRA must return a table")
    end

    for key, value in pairs(extra.output or {}) do
        manifest.output[key] = value
    end
    for _, method in ipairs(extra.modules or {}) do
        manifest.modules[#manifest.modules + 1] = method
    end
    for _, preset in ipairs(extra.presets or {}) do
        manifest.presets[#manifest.presets + 1] = preset
    end
    if extra.language_detection then
        manifest.language_detection = extra.language_detection
    end
end

load_extra_manifest()

return manifest
