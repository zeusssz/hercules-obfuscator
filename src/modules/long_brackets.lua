-- Return the final byte of a Lua long bracket (including its delimiters),
-- or nil if there is no opener at pos. Preserve incomplete literals to EOF.
local function longBracketEnd(code, pos)
    local equals = code:match("^%[(=*)%[", pos)
    if equals == nil then return nil end
    local close = "]" .. equals .. "]"
    local _, finish = code:find(close, pos + #equals + 2, true)
    return finish or #code
end

return longBracketEnd
