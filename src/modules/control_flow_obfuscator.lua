local ControlFlowObfuscator = {}

local function gen_random_identifier(length)
    length = length or math.random(5, 10)
    local chars = {}
    for i = 1, length do
        local char_type = math.random(3)
        if char_type == 1 then
            chars[i] = string.char(math.random(97, 122))
        elseif char_type == 2 then
            chars[i] = string.char(math.random(65, 90))
        else
            chars[i] = string.char(math.random(48, 57))
        end
    end
    return table.concat(chars)
end
local function insert_control_flow(original_code)
    local layers = {
        function(code)
            return string.format(
                "local _gate_%s = false " ..
                "while not _gate_%s do " ..
                "    if math.random(1, 10) > %d then " ..
                "        _gate_%s = true " ..
                "    end " ..
                "end " ..
                "%s",
                gen_random_identifier(), 
                gen_random_identifier(), 
                math.random(3, 8),
                gen_random_identifier(),
                code
            )
        end,

        function(code)
            return string.format(
                "local _flag_%s = %s " ..
                "local _counter_%s = 0 " ..
                "repeat " ..
                "    _counter_%s = _counter_%s + 1 " ..
                "    if _flag_%s or _counter_%s > %d then " ..
                "        %s " ..
                "        break " ..
                "    end " ..
                "until false",
                gen_random_identifier(), 
                tostring(math.random(0, 1) == 1),
                gen_random_identifier(),
                gen_random_identifier(), 
                gen_random_identifier(),
                gen_random_identifier(), 
                gen_random_identifier(), 
                math.random(3, 7),
                code
            )
        end,

        function(code)
            local noise_func_name = gen_random_identifier()
            return string.format(
                "local function %s() " ..
                "    local _temp = {%s} " ..
                "    return _temp[math.random(1, #_temp)] " ..
                "end " ..
                "%s " ..
                "%s()",
                noise_func_name,
                table.concat({math.random(1, 1000), math.random(1, 1000), math.random(1, 1000)}, ", "),
                code,
                noise_func_name
            )
        end
    }

    local obfuscated = original_code
    for _ = 1, math.random(1, #layers) do
        local layer = layers[math.random(1, #layers)]
        obfuscated = layer(obfuscated)
    end
    
    return obfuscated
end

function ControlFlowObfuscator.process(code)
    if type(code) ~= "string" then
        error("Input code must be a string")
    end
    local obfuscated_code = insert_control_flow(code)
    
    return obfuscated_code
end

return ControlFlowObfuscator
