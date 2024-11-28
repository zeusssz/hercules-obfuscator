local GarbageCodeInserter = {}

local Config = {
    CHAR_RANGES = {
        lowercase = {min = 97, max = 122},
        uppercase = {min = 65, max = 90},
        numbers = {min = 48, max = 57}
    },

    RANDOMIZATION = {
        min_garbage_blocks = 2,
        max_garbage_blocks = 5,
        max_random_number = 100,
        max_loop_count = 10,
        variable_name_length = {min = 4, max = 8}
    },
    COMPLEXITY = {
        max_nesting_depth = 3,
        code_type_weights = {
            variable = 0.3,
            while_loop = 0.2,
            for_loop = 0.2,
            if_statement = 0.2,
            function_def = 0.1
        }
    }
}
local RandomUtil = {
    generate_char = function(range)
        return string.char(math.random(range.min, range.max))
    end,
    weighted_choice = function(choices)
        local total_weight = 0
        for _, weight in pairs(choices) do
            total_weight = total_weight + weight
        end
        
        local random_point = math.random() * total_weight
        local current_weight = 0
        
        for choice, weight in pairs(choices) do
            current_weight = current_weight + weight
            if random_point <= current_weight then
                return choice
            end
        end
    end
}
local function generate_variable_name()
    local length = math.random(
        Config.RANDOMIZATION.variable_name_length.min, 
        Config.RANDOMIZATION.variable_name_length.max
    )
    local name = ""
    local possible_ranges = {
        Config.CHAR_RANGES.lowercase,
        Config.CHAR_RANGES.uppercase,
        Config.CHAR_RANGES.numbers
    }
    
    for _ = 1, length do
        local range = possible_ranges[math.random(#possible_ranges)]
        name = name .. RandomUtil.generate_char(range)
    end
    
    return name
end
local function generate_random_code(current_depth)
    current_depth = current_depth or 0
    if current_depth >= Config.COMPLEXITY.max_nesting_depth then
        return ""
    end
    
    local code_generators = {
        variable = function()
            return string.format("local %s = %d", 
                generate_variable_name(), 
                math.random(1, Config.RANDOMIZATION.max_random_number)
            )
        end,
        
        while_loop = function()
            return string.format("while %s do %s end", 
                tostring(math.random() > 0.5),
                generate_random_code(current_depth + 1)
            )
        end,
        
        for_loop = function()
            return string.format("for %s = 1, %d do %s end", 
                generate_variable_name(), 
                math.random(1, Config.RANDOMIZATION.max_loop_count),
                generate_random_code(current_depth + 1)
            )
        end,
        
        if_statement = function()
            return string.format("if %s then %s else %s end", 
                tostring(math.random() > 0.5),
                generate_random_code(current_depth + 1),
                generate_random_code(current_depth + 1)
            )
        end,
        
        function_def = function()
            return string.format("local function %s(%s) %s end", 
                generate_variable_name(), 
                generate_variable_name(),
                generate_random_code(current_depth + 1)
            )
        end
    }
    local code_type = RandomUtil.weighted_choice(
        Config.COMPLEXITY.code_type_weights
    )
    
    return code_generators[code_type]()
end
local function generate_garbage()
    local garbage_code = {}
    local block_count = math.random(
        Config.RANDOMIZATION.min_garbage_blocks, 
        Config.RANDOMIZATION.max_garbage_blocks
    )
    
    for _ = 1, block_count do
        local code = generate_random_code()
        if not code:match("while true") and 
           not code:match("for %w+ = %d+, %d+") then
            table.insert(garbage_code, code)
        end
    end
    
    return table.concat(garbage_code, " ")
end
function GarbageCodeInserter.process(code)
    if type(code) ~= "string" then
        error("Input must be a string. Received: " .. type(code), 2)
    end
    local obfuscated_code = string.format(
        "%s %s %s", 
        generate_garbage(), 
        code, 
        generate_garbage()
    )
    
    return obfuscated_code
end

function GarbageCodeInserter.configure(custom_config)
    for k, v in pairs(custom_config) do
        if Config[k] then
            for subk, subv in pairs(v) do
                Config[k][subk] = subv
            end
        end
    end
end

return GarbageCodeInserter
