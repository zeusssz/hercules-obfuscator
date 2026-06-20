local ControlFlowObfuscator = {}

local function random_name()
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local len = math.random(8, 14)
    local out = {}
    for i = 1, len do
        local idx = math.random(1, #charset)
        out[i] = charset:sub(idx, idx)
    end
    return table.concat(out)
end

local function shuffled(values)
    local out = {}
    for i, v in ipairs(values) do out[i] = v end
    for i = #out, 2, -1 do
        local j = math.random(1, i)
        out[i], out[j] = out[j], out[i]
    end
    return out
end

local function fake_block(state_name, value, next_value)
    local a = math.random(20, 200)
    local b = math.random(5, 50)
    local tmp = random_name()
    return string.format([=[
        elseif %s==%d then
            local %s=%d
            %s=(%s*%d-#%q)%%%d
            if (%s+%d)==(%d+%s) then
                %s=%d
            else
                %s=%d
            end
]=], state_name, value, tmp, a, tmp, tmp, b, string.rep("x", b), 9973,
        tmp, b, b, tmp, state_name, next_value, state_name, next_value)
end

function ControlFlowObfuscator.process(code, max_fake_blocks)
    if type(code) ~= "string" then
        error("Input code must be a string")
    end

    local state = random_name()
    local guard = random_name()
    local real_state = math.random(10000, 90000)
    local exit_state = real_state + math.random(1000, 9000)
    local fake_count = math.max(2, tonumber(max_fake_blocks) or 6)
    local states = { real_state }
    for i = 1, fake_count do
        states[#states + 1] = exit_state + i * math.random(11, 97)
    end
    states = shuffled(states)

    local lines = {}
    lines[#lines + 1] = "do"
    lines[#lines + 1] = string.format("    local %s=%d", state, real_state)
    lines[#lines + 1] = string.format("    local %s=%d", guard, math.random(3, 11))
    lines[#lines + 1] = "    while true do"
    lines[#lines + 1] = string.format("        if %s==%d then", state, -1)
    lines[#lines + 1] = string.format("            %s=%d", state, exit_state)

    for _, value in ipairs(states) do
        if value == real_state then
            lines[#lines + 1] = string.format("        elseif %s==%d then", state, real_state)
            lines[#lines + 1] = string.format("            if ((%s*%s)-(%s*%s))==0 then", guard, guard, guard, guard)
            lines[#lines + 1] = "                do"
            lines[#lines + 1] = code
            lines[#lines + 1] = "                end"
            lines[#lines + 1] = string.format("                %s=%d", state, exit_state)
            lines[#lines + 1] = "            else"
            lines[#lines + 1] = string.format("                %s=%d", state, states[1])
            lines[#lines + 1] = "            end"
        else
            lines[#lines + 1] = fake_block(state, value, exit_state)
        end
    end

    lines[#lines + 1] = "        else"
    lines[#lines + 1] = "            break"
    lines[#lines + 1] = "        end"
    lines[#lines + 1] = string.format("        if %s==%d then break end", state, exit_state)
    lines[#lines + 1] = "    end"
    lines[#lines + 1] = "end"

    return table.concat(lines, "\n")
end

return ControlFlowObfuscator
