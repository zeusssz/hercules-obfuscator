local ControlFlowObfuscator = {}

function ControlFlowObfuscator.process(code)
    local function insert_fake_control_flow(original_code)
        local obfuscated_code = string.format(
            "while true do " ..
            "if math.random(0, 1) == 0 then " ..
            "local _ = %d " ..
            "else break end " ..
            "%s " ..
            "if false then break end " ..
            "end",
            math.random(1, 1000),
            original_code
        )
        return obfuscated_code
    end

    local obfuscated_code = insert_fake_control_flow(code)
    return obfuscated_code
end

return ControlFlowObfuscator
