local TEST_DIR = "hercules_tests"

if not file.IsDir(TEST_DIR, "DATA") then
    file.CreateDir(TEST_DIR)
end

file.Write(TEST_DIR .. "/ready.txt", "1", "DATA")

hook.Add("Think", "HerculesRuntimeTestRunner", function()
    local files = file.Find(TEST_DIR .. "/*.lua", "DATA")
    if not files then return end

    for _, fname in ipairs(files) do
        local code = file.Read(TEST_DIR .. "/" .. fname, "DATA")
        if code then
            local compiled = CompileString(code, "hercules_test", false)
            local result

            if not isfunction(compiled) then
                result = "FAIL: " .. tostring(compiled)
            else
                local output = {}
                local old_print = print
                print = function(...)
                    local parts = {}
                    for i = 1, select("#", ...) do
                        parts[#parts + 1] = tostring(select(i, ...))
                    end
                    output[#output + 1] = table.concat(parts, "\t")
                end
                local ok, err = pcall(compiled)
                print = old_print

                if ok then
                    result = "PASS:" .. table.concat(output, "\n")
                else
                    result = "FAIL: " .. tostring(err)
                end
            end

            file.Write(TEST_DIR .. "/" .. fname .. ".result.txt", result, "DATA")
            file.Delete(TEST_DIR .. "/" .. fname, "DATA")
        end
    end
end)
