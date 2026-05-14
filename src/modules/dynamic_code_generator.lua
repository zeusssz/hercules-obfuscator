local DynamicCodeGenerator = {}

-- Patterns for lines that should NOT be wrapped (control flow, declarations, etc.)
-- Note: - must be escaped as %- in Lua patterns
local SKIP_PATTERNS = {
    "^%s*$",
    "^%s*%-%-",
    "^%s*if%s",
    "^%s*then%s*",
    "^%s*else%s*",
    "^%s*elseif%s",
    "^%s*end[^%w_]",
    "^%s*end%s*",
    "^%s*for%s",
    "^%s*while%s",
    "^%s*do%s*",
    "^%s*repeat%s*",
    "^%s*until%s",
    "^%s*function%s",
    "^%s*local%s",
    "^%s*break[^%w_]",
    "^%s*break%s*$",
    "^%s*return%s",
    "^%s*module%s",
    "^%s*require%s*%(",
    "^%s*:",
}

-- Characters/patterns that indicate Lua 5.3+ syntax the VM compiler can't handle
local UNSAFE_CONTENT_PATTERNS = {
    "~",  -- Lua 5.3+ bitwise XOR (VM compiler is Lua 5.1-based)
}

local function should_skip(line)
    for _, pat in ipairs(SKIP_PATTERNS) do
        if line:match(pat) then
            return true
        end
    end
    -- Skip lines containing Lua 5.3+ syntax that the VM compiler can't parse
    for _, pat in ipairs(UNSAFE_CONTENT_PATTERNS) do
        if line:find(pat, 1, true) then
            return true
        end
    end
    return false
end

function DynamicCodeGenerator.process(code)
    local lines = {}
    for line in code:gmatch("[^\n]*") do
        table.insert(lines, line)
    end

    local output = {}
    local i = 1
    while i <= #lines do
        local line = lines[i]

        if should_skip(line) or not line:match("%S") then
            table.insert(output, line)
            i = i + 1
            local brace_depth = 0
            local bracket_depth = 0
            local paren_depth = 0
            for ch in line:gmatch(".") do
                if ch == "{" then brace_depth = brace_depth + 1
                elseif ch == "}" then brace_depth = brace_depth - 1
                elseif ch == "[" then bracket_depth = bracket_depth + 1
                elseif ch == "]" then bracket_depth = bracket_depth - 1
                elseif ch == "(" then paren_depth = paren_depth + 1
                elseif ch == ")" then paren_depth = paren_depth - 1 end
            end
            while i <= #lines and (brace_depth > 0 or bracket_depth > 0 or paren_depth > 0) do
                local next_trimmed = lines[i]:gsub("^%s*", ""):gsub("%s+$", "")
                if next_trimmed == "" then break end
                table.insert(output, lines[i])
                for ch in lines[i]:gmatch(".") do
                    if ch == "{" then brace_depth = brace_depth + 1
                    elseif ch == "}" then brace_depth = brace_depth - 1
                    elseif ch == "[" then bracket_depth = bracket_depth + 1
                    elseif ch == "]" then bracket_depth = bracket_depth - 1
                    elseif ch == "(" then paren_depth = paren_depth + 1
                    elseif ch == ")" then paren_depth = paren_depth - 1 end
                end
                i = i + 1
            end
        else
            local ws = line:match("^(%s*)")
            local stmt = line:gsub("^%s*", ""):gsub("%s+$", "")

            local block_lines = {stmt}
            local j = i + 1
            local brace_depth = 0
            local bracket_depth = 0
            local paren_depth = 0
            for ch in stmt:gmatch(".") do
                if ch == "{" then brace_depth = brace_depth + 1
                elseif ch == "}" then brace_depth = brace_depth - 1
                elseif ch == "[" then bracket_depth = bracket_depth + 1
                elseif ch == "]" then bracket_depth = bracket_depth - 1
                elseif ch == "(" then paren_depth = paren_depth + 1
                elseif ch == ")" then paren_depth = paren_depth - 1 end
            end
            while j <= #lines do
                local next_line = lines[j]
                local trimmed = next_line:gsub("^%s*", ""):gsub("%s+$", "")
                if trimmed == "" then break end
                if trimmed == "end" or trimmed == "else" or trimmed:match("^then") or trimmed:match("^elseif") then break end
                if trimmed:match("^local%s") then break end
                local last = table.concat(block_lines, " ")
                local needs_cont = last:match("=%s*$") or last:match("{%s*$") or last:match(",%s*$")
                if brace_depth <= 0 and bracket_depth <= 0 and paren_depth <= 0 and not needs_cont then break end
                table.insert(block_lines, trimmed)
                for ch in trimmed:gmatch(".") do
                    if ch == "{" then brace_depth = brace_depth + 1
                    elseif ch == "}" then brace_depth = brace_depth - 1
                    elseif ch == "[" then bracket_depth = bracket_depth + 1
                    elseif ch == "]" then bracket_depth = bracket_depth - 1
                    elseif ch == "(" then paren_depth = paren_depth + 1
                    elseif ch == ")" then paren_depth = paren_depth - 1 end
                end
                j = j + 1
            end

            local full_stmt = table.concat(block_lines, " ")

            local trailing_comment = ""
            local clean_stmt = full_stmt

            local pos = 1
            local comment_start = nil
            while pos <= #full_stmt do
                local ch = full_stmt:sub(pos, pos)
                if ch == '"' or ch == "'" then
                    local quote = ch
                    pos = pos + 1
                    while pos <= #full_stmt do
                        local c = full_stmt:sub(pos, pos)
                        if c == "\\" then
                            pos = pos + 2
                        elseif c == quote then
                            pos = pos + 1
                            break
                        else
                            pos = pos + 1
                        end
                    end
                elseif ch == "[" and full_stmt:sub(pos, pos + 1) == "[[" then
                    local end_pos = full_stmt:find("]]", pos, true)
                    if end_pos then
                        pos = end_pos + 2
                    else
                        pos = pos + 2
                    end
                elseif ch == "-" and full_stmt:sub(pos, pos + 1) == "--" then
                    comment_start = pos
                    break
                else
                    pos = pos + 1
                end
            end

            if comment_start then
                clean_stmt = full_stmt:sub(1, comment_start - 1):gsub("%s+$", "")
                trailing_comment = full_stmt:sub(comment_start)
            end

            if trailing_comment ~= "" then
                table.insert(output, ws .. "do (function() " .. clean_stmt .. " end)() end " .. trailing_comment)
            else
                table.insert(output, ws .. "do (function() " .. clean_stmt .. " end)() end")
            end

            i = j
        end
    end

    return table.concat(output, "\n")
end

return DynamicCodeGenerator
