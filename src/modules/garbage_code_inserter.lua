-- modules/garbage_code_inserter.lua
local GarbageCodeInserter = {}

local function generate_garbage()
    local garbage = "if math.random() > 1 then local _ = '" .. string.rep("x", math.random(10, 30)) .. "' end "
    return garbage
end

function GarbageCodeInserter.process(code)
    return generate_garbage() .. code .. generate_garbage()
end

return GarbageCodeInserter