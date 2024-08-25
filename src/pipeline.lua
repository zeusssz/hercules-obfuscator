-- pipeline.lua
local StringEncoder = require("modules.string_encoder")
local VariableRenamer = require("modules.variable_renamer")
local ControlFlowObfuscator = require("modules.control_flow_obfuscator")
local GarbageCodeInserter = require("modules.garbage_code_inserter")
local Watermark = require("modules.watermark")

local Pipeline = {}

function Pipeline.process(code)
    code = StringEncoder.process(code)
    code = VariableRenamer.process(code)
    code = ControlFlowObfuscator.process(code)
    code = GarbageCodeInserter.process(code)
    code = Watermark.add_watermark(code)
    return code
end

return Pipeline