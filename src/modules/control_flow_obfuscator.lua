local ControlFlowObfuscator = {}
-- TODO : make it better

math.randomseed(os.time())

local function cControlFlow(code, n, a, depth, depthValues)
    n = n or math.floor(math.random() * 7000)
    a = n -- Initialize thing2 to thing for default equality
    depth = depth or 0
    depthValues = depthValues or {}
    depthValues[#depthValues + 1] = {n, a}

    local operators = {">", "<", "=="}
    local whileOperator = operators[math.floor(math.random() * 3) + 1]
    
    -- Adjust thing2 and step based on whileOperator
    local step = math.floor(math.random() * 990) + 10 -- Random step between 10 and 1000
    local maxIterations = 3 -- Fixed iterations for reliability
    if whileOperator == "<" then
        a = n + (step * maxIterations)
    elseif whileOperator == ">" then
        a = n - (step * maxIterations)
        if a < 0 then a = 0 end -- Prevent negative
        step = -step -- Decrement for >
    elseif whileOperator == "==" then
        a = n -- thing == thing2
        if math.random() > 0.5 then step = -step end -- Randomly increment or decrement
    end

    -- Set threshold to ensure else branch is reached
    local threshold = (n + step)

    -- Initialize src with adjusted thing2, counter, and threshold
    local src = depth == 0 and string.format(
        "local thing = %d;\nlocal thing2 = %d;\nlocal counter = 0;\nlocal threshold = %d;\n",
        n, a, threshold
    ) or ""

    -- While loop with counter
    src = src .. string.format(
        "while thing %s thing2 and counter < %d do\n", 
        whileOperator, maxIterations
    )
    src = src .. string.format("    thing = thing + %d;\n", step)
    src = src .. "    counter = counter + 1;\n"
    src = src .. "    if thing < threshold then\n"

    -- Spoof code generator
    local function generateSpoof()
        local spoofLines = {
            string.format("local temp = %d; temp = temp * 2;", math.floor(math.random() * 100)),
            "local str = 'dummy'; str = str .. str;",
            string.format("local x = %d; x = x - %d;", math.floor(math.random() * 50), math.floor(math.random() * 10)),
            "local tbl = {1, 2, 3}; table.sort(tbl, function(a, b) return a > b end);"
        }
        return spoofLines[math.floor(math.random() * #spoofLines) + 1]
    end

    -- Place spoof code in then, real code in else with break
    if depth == (#code - 1) then
        src = src .. string.format("        %s\n", generateSpoof())
        src = src .. string.format("    else\n        %s\n        break\n", code[1])
        table.remove(code, 1)
    else
        local subSrc, newN, newA = cControlFlow(code, n, a, depth + 1, depthValues)
        src = src .. string.format("        %s\n", generateSpoof())
        src = src .. string.format("    else\n        %s\n        break\n", subSrc)
        n = newN
        a = newA
    end

    src = src .. "    end\nend\n"

    -- Add occasional dummy operation
    if math.random() > 0.5 then
        src = src .. string.format("local dummy = 1; dummy = dummy + %d;\n", math.floor(math.random() * 10))
    end

    return depth == 0 and src or {src, n, a}
end

function ControlFlowObfuscator.process(code, max_fake_blocks)
    if type(code) ~= "string" then
        error("Input code must be a string")
    end

    local codeTable = {code}
    return cControlFlow(codeTable)
end

return ControlFlowObfuscator