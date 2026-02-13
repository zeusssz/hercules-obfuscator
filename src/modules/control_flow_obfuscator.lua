local ControlFlowObfuscator = {}
-- TODO : make it better

math.randomseed(os.time())

local function controlFlow(code, n, a, depth, depth_values)
    n = n or math.floor(math.random() * 7000)
    a = n
    depth = depth or 0
    depth_values = depth_values or {}
    depth_values[#depth_values + 1] = {n, a}

    local operators = {">", "<", "=="}
    local while_operator = operators[math.random(1, 3)]
    
    local step = math.floor(math.random() * 990) + 10
    local max_iterations = 3
    if while_operator == "<" then
        a = n + (step * max_iterations)
    elseif while_operator == ">" then
        a = n - (step * max_iterations)
        if a < 0 then a = 0 end
        step = -step
    elseif while_operator == "==" then
        a = n
        if math.random() > 0.5 then step = -step end
    end

    local threshold = (n + step)

    local src = depth == 0 and string.format(
        "local thing = %d;\nlocal thing2 = %d;\nlocal counter = 0;\nlocal threshold = %d;\n",
        n, a, threshold
    ) or ""

    src = src .. string.format(
        "while thing %s thing2 and counter < %d do\n", 
        while_operator, max_iterations
    )
    src = src .. string.format("    thing = thing + %d;\n", step)
    src = src .. "    counter = counter + 1;\n"
    src = src .. "    if thing < threshold then\n"

    local function generateSpoof()
        local spoof_lines = {
            string.format("local temp = %d; temp = temp * 2;", math.floor(math.random() * 100)),
            "local str = 'dummy'; str = str .. str;",
            string.format("local x = %d; x = x - %d;", math.floor(math.random() * 50), math.floor(math.random() * 10)),
            "local tbl = {1, 2, 3}; table.sort(tbl, function(a, b) return a > b end);"
        }
        return spoof_lines[math.random(1, #spoof_lines)]
    end

    if depth == (#code - 1) then
        src = src .. string.format("        %s\n", generateSpoof())
        src = src .. string.format("    else\n        %s\n        break\n", code[1])
        table.remove(code, 1)
    else
        local sub_src, new_n, new_a = controlFlow(code, n, a, depth + 1, depth_values)
        src = src .. string.format("        %s\n", generateSpoof())
        src = src .. string.format("    else\n        %s\n        break\n", sub_src)
        n = new_n
        a = new_a
    end

    src = src .. "    end\nend\n"

    if math.random() > 0.5 then
        src = src .. string.format("local dummy = 1; dummy = dummy + %d;\n", math.floor(math.random() * 10))
    end

    return depth == 0 and src or {src, n, a}
end

function ControlFlowObfuscator.process(code, max_fake_blocks)
    if type(code) ~= "string" then
        error("Input code must be a string")
    end

    local code_table = {code}
    return controlFlow(code_table)
end

return ControlFlowObfuscator