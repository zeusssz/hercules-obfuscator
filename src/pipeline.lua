local StringEncoder = require("string_encoder")
local VariableRenamer = require("variable_renamer")
local ControlFlowObfuscator = require("control_flow_obfuscator")
local GarbageCodeInserter = require("garbage_code_inserter")
local OpaquePredicateInjector = require("opaque_predicate_injector")
local FunctionInliner = require("function_inliner")
local DynamicCodeGenerator = require("dynamic_code_generator")
local BytecodeEncoder = require("bytecode_encoder")

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
    return code
end

return Pipeline
