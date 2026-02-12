local ControlFlowObfuscator = {}
-- modified, its much better like that
math.randomseed(os.time())

local function generateRandomName(len)
    len = len or math.random(8, 12)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"
    local name = ""
    for _ = 1, len do
        local index = math.random(1, #charset)
        name = name .. charset:sub(index, index)
    end
    return name
end

local function generateOpaquePredicate(always_true)
    local predicates_true = {
        "(function() local x = math.abs(-5); return x * x > 20 end)()",
        "(function() local t = {1,2,3}; return #t == 3 end)()",
        "(function() return (7 * 3) == 21 end)()",
        "(function() local s = 'test'; return #s > 0 end)()",
        "(function() return math.floor(5.7) == 5 end)()",
    }
    
    local predicates_false = {
        "(function() local x = 10; return x < 5 end)()",
        "(function() return (2 + 2) == 5 end)()",
        "(function() local t = {}; return #t > 0 end)()",
        "(function() return math.floor(3.2) > 5 end)()",
    }
    
    if always_true then
        return predicates_true[math.random(1, #predicates_true)]
    else
        return predicates_false[math.random(1, #predicates_false)]
    end
end

local function generateFakeBlock()
    local fakes = {
        string.format("local %s = %d; %s = %s + %d;", 
            generateRandomName(), math.random(1, 100),
            generateRandomName(), generateRandomName(), math.random(1, 50)),
        string.format("local %s = '%s'; %s = %s .. '%s';",
            generateRandomName(), generateRandomName(5),
            generateRandomName(), generateRandomName(), generateRandomName(3)),
        string.format("local %s = {%d, %d, %d}; table.sort(%s);",
            generateRandomName(), math.random(1, 10), math.random(1, 10), math.random(1, 10),
            generateRandomName()),
        string.format("for %s = 1, %d do local %s = %d end",
            generateRandomName(), math.random(2, 5), generateRandomName(), math.random(1, 100)),
    }
    return fakes[math.random(1, #fakes)]
end

local function createStateMachine(code_blocks)
    local num_states = #code_blocks + math.random(3, 6)
    local state_var = generateRandomName()
    local result_var = generateRandomName()
    
    local states = {}
    local real_states = {}
    
    for i = 1, #code_blocks do
        local state_num
        repeat
            state_num = math.random(1, num_states * 2)
        until not states[state_num]
        states[state_num] = i
        real_states[i] = state_num
    end
    
    local machine = string.format("local %s = %d\n", state_var, real_states[1])
    machine = machine .. string.format("local %s\n", result_var)
    machine = machine .. string.format("while %s do\n", state_var)
    
    for state_num, block_idx in pairs(states) do
        machine = machine .. string.format("    if %s == %d then\n", state_var, state_num)
        
        if math.random() > 0.5 then
            machine = machine .. string.format("        if %s then\n", generateOpaquePredicate(true))
            machine = machine .. string.format("            %s = (function() %s end)()\n", 
                result_var, code_blocks[block_idx])
            
            if block_idx < #code_blocks then
                machine = machine .. string.format("            %s = %d\n", state_var, real_states[block_idx + 1])
            else
                machine = machine .. string.format("            %s = nil\n", state_var)
            end
            machine = machine .. "        end\n"
        else
            machine = machine .. string.format("        %s = (function() %s end)()\n", 
                result_var, code_blocks[block_idx])
            if block_idx < #code_blocks then
                machine = machine .. string.format("        %s = %d\n", state_var, real_states[block_idx + 1])
            else
                machine = machine .. string.format("        %s = nil\n", state_var)
            end
        end
        
        machine = machine .. "    end\n"
    end
    
    for i = 1, math.random(2, 4) do
        local fake_state
        repeat
            fake_state = math.random(1, num_states * 2)
        until not states[fake_state]
        
        machine = machine .. string.format("    if %s == %d then\n", state_var, fake_state)
        machine = machine .. "        " .. generateFakeBlock() .. "\n"
        machine = machine .. string.format("        %s = nil\n", state_var)
        machine = machine .. "    end\n"
    end
    
    machine = machine .. "end\n"
    machine = machine .. string.format("return %s\n", result_var)
    
    return machine
end

local function createSwitchCase(code_blocks)
    local switch_var = generateRandomName()
    local result_var = generateRandomName()
    local cases = {}
    
    for i = 1, #code_blocks do
        cases[i] = math.random(1, 1000)
    end
    
    local switch = string.format("local %s = %d\n", switch_var, cases[1])
    switch = switch .. string.format("local %s\n", result_var)
    switch = switch .. "repeat\n"
    
    for i = 1, #code_blocks do
        switch = switch .. string.format("    if %s == %d then\n", switch_var, cases[i])
        switch = switch .. string.format("        %s = (function() %s end)()\n", result_var, code_blocks[i])
        
        if i < #code_blocks then
            switch = switch .. string.format("        %s = %d\n", switch_var, cases[i + 1])
        else
            switch = switch .. string.format("        %s = nil\n", switch_var)
        end
        switch = switch .. "    end\n"
    end
    
    for i = 1, math.random(2, 4) do
        local fake_case = math.random(1001, 2000)
        switch = switch .. string.format("    if %s == %d then\n", switch_var, fake_case)
        switch = switch .. "        " .. generateFakeBlock() .. "\n"
        switch = switch .. string.format("        %s = nil\n", switch_var)
        switch = switch .. "    end\n"
    end
    
    switch = switch .. string.format("until not %s\n", switch_var)
    switch = switch .. string.format("return %s\n", result_var)
    
    return switch
end

local function createNestedConditionals(code_blocks)
    local result_var = generateRandomName()
    local nested = string.format("local %s\n", result_var)
    
    local function buildNested(blocks, depth)
        if #blocks == 0 then
            return ""
        end
        
        if #blocks == 1 then
            return string.format("%s = (function() %s end)()\n", result_var, blocks[1])
        end
        
        local condition = generateOpaquePredicate(true)
        local code = string.format("if %s then\n", condition)
        code = code .. "    " .. string.format("%s = (function() %s end)()\n", result_var, blocks[1])
        
        if math.random() > 0.6 then
            code = code .. "else\n"
            code = code .. "    " .. generateFakeBlock() .. "\n"
        end
        code = code .. "end\n"
        
        table.remove(blocks, 1)
        if #blocks > 0 then
            code = code .. buildNested(blocks, depth + 1)
        end
        
        return code
    end
    
    nested = nested .. buildNested(code_blocks, 0)
    nested = nested .. string.format("return %s\n", result_var)
    
    return nested
end

function ControlFlowObfuscator.process(code, max_fake_blocks)
    if type(code) ~= "string" then
        error("Input code must be a string")
    end
    
    local code_blocks = {code}
    
    local techniques = {
        createStateMachine,
        createSwitchCase,
        createNestedConditionals
    }
    
    local technique = techniques[math.random(1, #techniques)]
    return technique(code_blocks)
end

return ControlFlowObfuscator