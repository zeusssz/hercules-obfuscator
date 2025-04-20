local ControlFlowObfuscator = {}

function ControlFlowObfuscator.process(code, max_fake_blocks)
    local function insert_fake_control_flow(original_code)
        local obfuscated_code = string.format(
            "local executed = false " ..
            "while not executed do " ..
            "if math.random(0, 1) == 0 then " ..
            "local _ = %d " ..
            "else executed = true end " ..
            "end " ..
            "%s", 
            math.random(1, 1000),
            original_code
        )
        return obfuscated_code
    end

    if type(code) ~= "string" then
        error("Input code must be a string")
    end

    local blocks = (type(max_fake_blocks) == "number" and max_fake_blocks) or 1
    local result = code
    for i = 1, blocks do
        result = insert_fake_control_flow(result)
    end
    return result
end

return ControlFlowObfuscator


