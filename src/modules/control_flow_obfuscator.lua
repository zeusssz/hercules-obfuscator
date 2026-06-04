local ControlFlowObfuscator = {}
-- TODO : make it better

math.randomseed(os.time())

local function controlFlow(code, depth, depth_values)
    depth = depth or 0
    depth_values = depth_values or {}
    local n = math.floor(math.random() * 7000)
    depth_values[#depth_values + 1] = n

    local src = depth == 0 and string.format(
        "local thing = %d;\nlocal thing2 = %d;\nlocal counter = 0;\n",
        n, n
    ) or ""

    src = src .. "while thing == thing2 and counter < 1 do\n"
    src = src .. "    thing = thing + 1;\n"
    src = src .. "    counter = counter + 1;\n"
    src = src .. "    if thing == thing2 then\n"

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
        src = src .. string.format("    else\n        do\n            %s\n        end\n        break\n", code[1])
        table.remove(code, 1)
    else
        local sub_src = controlFlow(code, depth + 1, depth_values)
        src = src .. string.format("        %s\n", generateSpoof())
        src = src .. string.format("    else\n        do\n            %s\n        end\n        break\n", sub_src)
    end

    src = src .. "    end\nend\n"

    if math.random() > 0.5 then
        src = src .. string.format("local dummy = 1; dummy = dummy + %d;\n", math.floor(math.random() * 10))
    end

    return src
end

function ControlFlowObfuscator.process(code, max_fake_blocks)
    if type(code) ~= "string" then
        error("Input code must be a string")
    end

    local code_table = {code}
    return controlFlow(code_table)
end

return ControlFlowObfuscator
