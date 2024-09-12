local StringEncoder = require("modules/string_encoder")
local VariableRenamer = require("modules/variable_renamer")
local ControlFlowObfuscator = require("modules/control_flow_obfuscator")
local GarbageCodeInserter = require("modules/garbage_code_inserter")
local OpaquePredicateInjector = require("modules/opaque_predicate_injector")
local FunctionInliner = require("modules/function_inliner")
local DynamicCodeGenerator = require("modules/dynamic_code_generator")
local BytecodeEncoder = require("modules/bytecode_encoder")
local Watermarker = require("modules/watermark")

local Pipeline = {}

function Pipeline.process(code)
    code = StringEncoder.process(code)
    code = VariableRenamer.process(code)
    code = ControlFlowObfuscator.process(code)
    code = GarbageCodeInserter.process(code)
    code = OpaquePredicateInjector.process(code)
    code = FunctionInliner.process(code)
    code = DynamicCodeGenerator.process(code)
    code = BytecodeEncoder.process(code)
    code = Watermarker.process(code)
    return code
end

return Pipeline
