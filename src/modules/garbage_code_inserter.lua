local GarbageCodeInserter = {}

local function generate_random_variable_name()
    return string.char(math.random(97, 122)) -- random lowercase letter
end

local function generate_random_code()
    local code_types = {
        "local %s = %d",
        "while true do %s end",
        "for %s = 1, %d do %s end",
        "if %s then %s end",
        "function %s(%s) %s end"
    }
    
    local random_type = code_types[math.random(#code_types)]
    
    if random_type == code_types[1] then
        return string.format(random_type, generate_random_variable_name(), math.random(1, 100))
    elseif random_type == code_types[2] then
        return string.format(random_type, generate_random_code())
    elseif random_type == code_types[3] then
        return string.format(random_type, generate_random_variable_name(), math.random(1, 10), generate_random_code())
    elseif random_type == code_types[4] then
        return string.format(random_type, "true", generate_random_code())
    elseif random_type == code_types[5] then
        return string.format(random_type, generate_random_variable_name(), generate_random_variable_name(), generate_random_code())
    end
end

local function generate_garbage()
    local garbage_code = ""
    for _ = 1, math.random(2, 5) do
        garbage_code = garbage_code .. generate_random_code() .. " "
    end
    return garbage_code
end

function GarbageCodeInserter.process(code)
    return generate_garbage() .. code .. generate_garbage()
end

return GarbageCodeInserter
