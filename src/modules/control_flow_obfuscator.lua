-- modules/control_flow_obfuscator.lua
local ControlFlowObfuscator = {}

function ControlFlowObfuscator.process(code)
    -- Insert fake control flow structures
    code = "while true do if false then break end " .. code .. " break end"
    return code
end

return ControlFlowObfuscator
