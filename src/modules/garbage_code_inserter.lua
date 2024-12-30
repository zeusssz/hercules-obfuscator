local GarbageCodeInserter = {}

local LOWERCASE_A, LOWERCASE_Z = 97, 122
local MIN_GARBAGE_BLOCKS, MAX_GARBAGE_BLOCKS = 2, 5
local MAX_RANDOM_NUMBER = 100
local MAX_LOOP_COUNT = 10
local VARIABLE_NAME_LENGTH = 6

local function generate_random_variable_name()
    local name = {}
    for _ = 1, VARIABLE_NAME_LENGTH do
        table.insert(name, string.char(math.random(LOWERCASE_A, LOWERCASE_Z)))
    end
    return table.concat(name)
end

local function generate_random_number(max)
    return math.random(1, max or MAX_RANDOM_NUMBER)
end

local function generate_random_code()
    local code_types = {
        variable = function()
            return string.format("local %s = %d", generate_random_variable_name(), generate_random_number())
        end,
        while_loop = function()
            return string.format("while %s do local _ = %d break end", 
                tostring(math.random() > 0.5), 
                generate_random_number(100)
            )
        end,
        for_loop = function()
            return string.format("for %s = 1, %d do local _ = %d end", 
                generate_random_variable_name(), 
                generate_random_number(MAX_LOOP_COUNT),
                generate_random_number()
            )
        end,
        if_statement = function()
            return string.format("if %s then local _ = %d end", 
                tostring(math.random() > 0.5), 
                generate_random_number()
            )
        end,
        function_def = function()
            return string.format("local function %s(%s) local _ = %d end", 
                generate_random_variable_name(), 
                generate_random_variable_name(), 
                generate_random_number()
            )
        end
    }

    local code_type_keys = {}
    for k in pairs(code_types) do
        table.insert(code_type_keys, k)
    end
    
    return code_types[code_type_keys[math.random(#code_type_keys)]]()
end

local function generate_garbage()
    local garbage_code = {}
    local block_count = math.random(MIN_GARBAGE_BLOCKS, MAX_GARBAGE_BLOCKS)
    
    for _ = 1, block_count do
        local code = generate_random_code()
        if not code:match("while true") and 
           not code:match("for %w+ = %d+, %d+ do local _ = %d+ end") then
            table.insert(garbage_code, code)
        end
    end
    
    return table.concat(garbage_code, " ")
end

function GarbageCodeInserter.process(code)
    if type(code) ~= "string" or #code == 0 then
        error("Input code must be a non-empty string", 2)
    end
    
    return string.format("%s %s %s", generate_garbage(), code, generate_garbage())
end

return GarbageCodeInserter
