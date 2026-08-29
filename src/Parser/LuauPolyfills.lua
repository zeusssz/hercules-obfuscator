-- Parser/LuauPolyfills.lua
-- Lua 5.4 fallbacks for the Roblox Luau standard-library functions that the
-- transpiled Ast parser (Parser/LuauParser) relies on. The parser body is
-- produced by transpiling Luau source, so it calls Luau-only APIs that do not
-- exist in a stock Lua 5.4 runtime.
--
-- Every helper is installed *only if missing*, so this module is a no-op in a
-- native Luau environment and cannot shadow existing implementations in the
-- project's Lua runtime. It is loaded by Parser/init.lua before the parser.

-- buffer
-- Luau buffer offsets are 0-based. Values are written/read little-endian.
-- A buffer is represented internally as an array of bytes (indexed 1..n) with a
-- trailing length sentinel, which allows O(1) writes at arbitrary offsets and
-- unbounded growth, matching Luau's growable buffers.

local M = {}

local b = buffer
if not b then
    b = {}

    local function ensure_room(buf, offset)
        -- offset is 0-based byte index; ensure the backing array reaches it.
        while #buf < offset + 1 do
            buf[#buf + 1] = 0
        end
    end

    function b.create(size)
        local buf = {}
        local n = size or 0
        for _ = 1, n do
            buf[#buf + 1] = 0
        end
        return buf
    end

    function b.fromstring(s)
        local buf = {}
        for i = 1, #s do
            buf[i] = string.byte(s, i)
        end
        return buf
    end

    function b.readu8(buf, offset)
        return buf[offset + 1] or 0
    end

    function b.readu16(buf, offset)
        local lo = buf[offset + 1] or 0
        local hi = buf[offset + 2] or 0
        return lo + hi * 256
    end

    function b.readu32(buf, offset)
        local v = 0
        for i = 0, 3 do
            v = v + (buf[offset + 1] or 0) * (256 ^ i)
            offset = offset + 1
        end
        return v
    end

    function b.readstring(buf, offset, length)
        local parts = {}
        for i = 1, length do
            local byte = buf[offset + 1] or 0
            parts[#parts + 1] = string.char(byte)
            offset = offset + 1
        end
        return table.concat(parts)
    end

    function b.writeu8(buf, offset, value)
        ensure_room(buf, offset)
        buf[offset + 1] = value % 256
    end

    function b.writeu16(buf, offset, value)
        ensure_room(buf, offset)
        ensure_room(buf, offset + 1)
        buf[offset + 1] = value % 256
        buf[offset + 2] = math.floor(value / 256) % 256
    end

    buffer = b
end

-- vector
-- Only the 2-component position flavor is used by the parser. Expose both the
-- lowercase `.x`/`.y` accessors used by the transpiled code and the standard
-- `.X`/`.Y` for parity with native Luau vectors.

if not vector then
    vector = {}

    function vector.create(x, y)
        return { x = x, y = y, X = x, Y = y }
    end
end

-- table extensions

if not table.freeze then
    -- Freezing is a no-op in vanilla Lua; the table is still mutable.
    function table.freeze(t)
        return t
    end
end

if not table.isfrozen then
    function table.isfrozen()
        return false
    end
end

if not table.create then
    function table.create(count, value)
        local t = {}
        if count and count > 0 then
            if type(value) == "function" then
                for _ = 1, count do
                    t[#t + 1] = value()
                end
            elseif value ~= nil then
                for _ = 1, count do
                    t[#t + 1] = value
                end
            end
        end
        return t
    end
end

if not table.clone then
    function table.clone(t)
        local copy = {}
        for k, v in next, t do
            copy[k] = v
        end
        return copy
    end
end

return M
