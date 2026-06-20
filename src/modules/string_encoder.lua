local StringEncoder = {}

local function random_name(len)
    len = len or math.random(8, 14)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local out = {}
    for i = 1, len do
        local idx = math.random(1, #charset)
        out[i] = charset:sub(idx, idx)
    end
    return table.concat(out)
end

local function find_string_end(code, pos, quote)
    pos = pos + 1
    while pos <= #code do
        local c = code:sub(pos, pos)
        if c == "\\" then
            pos = pos + 2
        elseif c == quote then
            return pos + 1
        else
            pos = pos + 1
        end
    end
    return pos
end

local function literal_value(literal)
    local chunk = load("return " .. literal)
    if not chunk then return nil end
    local ok, value = pcall(chunk)
    if ok and type(value) == "string" then return value end
    return nil
end

local function encode_bytes(value, key, mode)
    local out = {}
    for i = 1, #value do
        local b = value:byte(i)
        if mode == 1 then
            out[i] = (b + key + i * 3) % 256
        elseif mode == 2 then
            out[i] = (b ~ ((key + i * 17) % 256)) % 256
        else
            out[i] = (255 - b + key + i) % 256
        end
    end
    return out
end

local function table_literal(values)
    return "{" .. table.concat(values, ",") .. "}"
end

function StringEncoder.process(code)
    local dec = random_name()
    local data = random_name()
    local key = random_name()
    local mode = random_name()
    local out = random_name()
    local byte = random_name()
    local idx = random_name()

    local decode_function = string.format([=[
local function %s(%s,%s,%s)
    local function bx(a,b)
        local r,p=0,1
        while a>0 or b>0 do
            local aa,bb=a%%2,b%%2
            if aa~=bb then r=r+p end
            a=math.floor(a/2)
            b=math.floor(b/2)
            p=p*2
        end
        return r
    end
    local %s={}
    for %s=1,#%s do
        local %s=%s[%s]
        if %s==1 then
            %s=(%s-%s-%s*3)%%256
        elseif %s==2 then
            %s=bx(%s,((%s+%s*17)%%256))%%256
        else
            %s=(255-(%s-%s-%s))%%256
        end
        %s[#%s+1]=string.char(%s)
    end
    return table.concat(%s)
end
]=], dec, data, key, mode, out, idx, data, byte, data, idx,
        mode, byte, byte, key, idx,
        mode, byte, byte, key, idx,
        byte, byte, key, idx,
        out, out, byte, out)

    local parts = {}
    local pos = 1

    while pos <= #code do
        local ch = code:sub(pos, pos)

        if ch == "[" then
            local eq = code:match("^%[(=*)%[", pos)
            if eq then
                local close = "]" .. string.rep("=", #eq) .. "]"
                local _, end_pos = code:find(close, pos + #eq + 2, true)
                if end_pos then
                    parts[#parts + 1] = code:sub(pos, end_pos)
                    pos = end_pos + 1
                    goto continue
                end
            end
        end

        if ch == "-" and code:sub(pos + 1, pos + 1) == "-" then
            local nl = code:find("\n", pos)
            if nl then
                parts[#parts + 1] = code:sub(pos, nl)
                pos = nl + 1
            else
                parts[#parts + 1] = code:sub(pos)
                pos = #code + 1
            end
            goto continue
        end

        if ch == '"' or ch == "'" then
            local end_pos = find_string_end(code, pos, ch)
            local literal = code:sub(pos, end_pos - 1)
            local value = literal_value(literal)
            if value then
                local k = math.random(1, 255)
                local m = math.random(1, 3)
                parts[#parts + 1] = string.format("%s(%s,%d,%d)", dec, table_literal(encode_bytes(value, k, m)), k, m)
            else
                parts[#parts + 1] = literal
            end
            pos = end_pos
            goto continue
        end

        parts[#parts + 1] = ch
        pos = pos + 1
        ::continue::
    end

    return decode_function .. "\n" .. table.concat(parts)
end

return StringEncoder
