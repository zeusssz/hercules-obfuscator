--pipeline.lua
local config = require("config")

local StringEncoder = require("modules/string_encoder")
local VariableRenamer = require("modules/variable_renamer")
local ControlFlowObfuscator = require("modules/control_flow_obfuscator")
local GarbageCodeInserter = require("modules/garbage_code_inserter")
local OpaquePredicateInjector = require("modules/opaque_predicate_injector")
local FunctionInliner = require("modules/function_inliner")
local DynamicCodeGenerator = require("modules/dynamic_code_generator")
local BytecodeEncoder = require("modules/bytecode_encoder")
local Watermarker = require("modules/watermark")
local Compressor = require("modules/compressor")

local Pipeline = {}

function Pipeline.process(code)
    if config.get("settings.string_encoding.enabled") then
        code = StringEncoder.process(code)
    end
    if config.get("settings.control_flow.enabled") then
        local max_fake_blocks = config.get("settings.control_flow.max_fake_blocks")
        code = ControlFlowObfuscator.process(code, max_fake_blocks)
    end
    if config.get("settings.garbage_code.enabled") then
        local garbage_blocks = config.get("settings.garbage_code.garbage_blocks")
        code = GarbageCodeInserter.process(code, garbage_blocks)
    end
    if config.get("settings.dynamic_code.enabled") then
        code = DynamicCodeGenerator.process(code)
    end

    if config.get("settings.opaque_predicates.enabled") then
        code = OpaquePredicateInjector.process(code)
    end

    if config.get("settings.variable_renaming.enabled") then
        local min_length = config.get("settings.variable_renaming.min_name_length")
        local max_length = config.get("settings.variable_renaming.max_name_length")
        code = VariableRenamer.process(code, { min_length = min_length, max_length = max_length })
    end

    if config.get("settings.bytecode_encoding.enabled") then
        code = BytecodeEncoder.process(code)
    end
    if config.get("settings.function_inlining.enabled") then
        code = FunctionInliner.process(code)
    end
    if config.get("settings.compressor.enabled") then
        code = Compressor.process(code)
    end
    if config.get("settings.watermark_enabled") then
        code = Watermarker.process(code)
    end

    return code
end

return Pipeline
