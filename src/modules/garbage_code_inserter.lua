local GarbageCodeInserter = {}

-- constants
local LOWERCASE_A = 97
local LOWERCASE_Z = 122
local MIN_GARBAGE_BLOCKS = 2
local MAX_GARBAGE_BLOCKS = 5
local MAX_RANDOM_NUMBER = 100
local MAX_LOOP_COUNT = 10
local VARIABLE_NAME_LENGTH = 6

-- helper funcs
local function generate_random_variable_name()
    local name = ""
    for _ = 1, VARIABLE_NAME_LENGTH do
        name = name .. string.char(math.random(LOWERCASE_A, LOWERCASE_Z))
    end
    return name
end

local function generate_random_number(max)
    return math.random(1, max or MAX_RANDOM_NUMBER)
end

-- code generation funcs
local function generate_random_code()
    local code_types = {
        variable = function()
            return string.format("local %s = %d", generate_random_variable_name(), generate_random_number())
        end,
        while_loop = function()
            return string.format("while %s do %s end", tostring(math.random() > 0.5), generate_random_code())
        end,
        for_loop = function()
            return string.format("for %s = 1, %d do %s end", generate_random_variable_name(), generate_random_number(MAX_LOOP_COUNT), generate_random_code())
        end,
        if_statement = function()
            return string.format("if %s then %s end", tostring(math.random() > 0.5), generate_random_code())
        end,
        function_def = function()
            return string.format("local function %s(%s) %s end", generate_random_variable_name(), generate_random_variable_name(), generate_random_code())
        end
    }

    local code_types_keys = {}
    for k in pairs(code_types) do
        table.insert(code_types_keys, k)
    end

    local random_type = code_types_keys[math.random(#code_types_keys)]
    return code_types[random_type]()
end

local function generate_garbage()
    local garbage_code = {}
    for _ = 1, math.random(MIN_GARBAGE_BLOCKS, MAX_GARBAGE_BLOCKS) do
        local code = generate_random_code()
        if not code:match("while true") and not code:match("for") then
            table.insert(garbage_code, code)
        end
    end
    return table.concat(garbage_code, " ")
end

function GarbageCodeInserter.process(code)
    assert(type(code) == "string", "Input code must be a string")
    return string.format("%s %s %s", generate_garbage(), code, generate_garbage())
end

return GarbageCodeInserter
