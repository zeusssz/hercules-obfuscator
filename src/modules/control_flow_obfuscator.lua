local ControlFlowObfuscator = {}

function ControlFlowObfuscator.process(code)
    local function insert_fake_control_flow(original_code)
        -- Encapsulate the original code in a fake loop and condition
        local obfuscated_code = string.format(
            "while true do if false then break end %s break end",
            original_code
        )
        return obfuscated_code
    end

    -- Process the input code with fake control flow
    local obfuscated_code = insert_fake_control_flow(code)

    return obfuscated_code
end

return ControlFlowObfuscator
