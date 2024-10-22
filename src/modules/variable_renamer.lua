local VariableRenamer = {}

local lua_keywords = {
    ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
    ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
    ["function"] = true, ["goto"] = true, ["if"] = true, ["in"] = true,
    ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true,
    ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true,
    ["until"] = true, ["while"] = true, ["require"] = true,
    ["module"] = true, ["package"] = true, ["self"] = true,
    ["assert"] = true, ["collectgarbage"] = true, ["dofile"] = true,
    ["loadfile"] = true, ["loadstring"] = true, ["pairs"] = true,
    ["ipairs"] = true, ["tonumber"] = true, ["tostring"] = true,
    ["type"] = true, ["print"] = true, ["string"] = true,
    ["table"] = true, ["math"] = true, ["os"] = true, ["coroutine"] = true,
    ["debug"] = true, ["io"] = true, ["utf8"] = true, ["bit32"] = true,
    ["_G"] = true, ["_VERSION"] = true, ["write"] = true, ["sort"] = true,
    ["remove"] = true, ["math.abs"] = true, ["math.acos"] = true,
    ["math.asin"] = true, ["math.atan"] = true, ["math.atan2"] = true,
    ["math.ceil"] = true, ["math.cos"] = true, ["math.cosh"] = true,
    ["math.deg"] = true, ["math.exp"] = true, ["math.floor"] = true,
    ["math.fmod"] = true, ["math.frexp"] = true, ["math.ldexp"] = true,
    ["math.log"] = true, ["math.log10"] = true, ["math.max"] = true,
    ["math.min"] = true, ["math.modf"] = true, ["math.pi"] = true,
    ["math.pow"] = true, ["math.rad"] = true, ["math.random"] = true,
    ["math.randomseed"] = true, ["math.sin"] = true, ["math.sinh"] = true,
    ["math.sqrt"] = true, ["math.tan"] = true, ["math.tanh"] = true,
    ["string.byte"] = true, ["string.char"] = true, ["string.dump"] = true,
    ["string.find"] = true, ["string.format"] = true, ["string.gmatch"] = true,
    ["string.gsub"] = true, ["string.len"] = true, ["string.lower"] = true,
    ["string.match"] = true, ["string.rep"] = true, ["string.reverse"] = true,
    ["string.sub"] = true, ["string.upper"] = true,
    ["table.concat"] = true, ["table.insert"] = true, ["table.remove"] = true,
    ["table.sort"] = true, ["table.pack"] = true, ["table.unpack"] = true,
    ["coroutine.create"] = true, ["coroutine.resume"] = true,
    ["coroutine.yield"] = true, ["coroutine.running"] = true,
    ["coroutine.status"] = true, ["coroutine.wrap"] = true,
    ["debug.debug"] = true, ["debug.getinfo"] = true, ["debug.getregistry"] = true,
    ["debug.getupvalue"] = true, ["debug.getuservalue"] = true,
    ["debug.setfenv"] = true, ["debug.setmetatable"] = true,
    ["debug.setuservalue"] = true, ["io.close"] = true, ["io.flush"] = true,
    ["io.input"] = true, ["io.lines"] = true, ["io.open"] = true,
    ["io.output"] = true, ["io.popen"] = true, ["io.read"] = true,
    ["io.tmpfile"] = true, ["io.type"] = true, ["io.write"] = true,
    ["utf8.char"] = true, ["utf8.charbyte"] = true, ["utf8.codepoint"] = true,
    ["utf8.codes"] = true, ["utf8.len"] = true, ["utf8.offset"] = true, ["insert"] = true
}


local function generate_random_name(len)
    len = len or math.random(8, 12)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local name = ""
    for _ = 1, len do
        local index = math.random(1, #charset)
        name = name .. charset:sub(index, index)
    end
    return name
end

function VariableRenamer.process(code)
    local variables = {}
    local result = {}
    local in_string = false
    local current_quote
    local last_position = 1

    for i = 1, #code do
        local char = code:sub(i, i)

        if not in_string then
            if char == "'" or char == '"' then
                if last_position < i then
                    local segment = code:sub(last_position, i - 1)
                    segment = segment:gsub("([%a_][%w_]*)", function(var)
                        if not lua_keywords[var] and not variables[var] then
                            variables[var] = generate_random_name()
                        end
                        return variables[var] or var
                    end)
                    table.insert(result, segment)
                end
                in_string = true
                current_quote = char
                table.insert(result, char)
                last_position = i + 1
            end
        else
            if char == current_quote and (i == 1 or code:sub(i - 1, i - 1) ~= "\\") then
                table.insert(result, code:sub(last_position, i))
                in_string = false
                last_position = i + 1
            end
        end
    end
    if last_position <= #code then
        local segment = code:sub(last_position)
        segment = segment:gsub("([%a_][%w_]*)", function(var)
            if not lua_keywords[var] and not variables[var] then
                variables[var] = generate_random_name()
            end
            return variables[var] or var
        end)
        table.insert(result, segment)
    end

    return table.concat(result)
end

return VariableRenamer
