local Parts = {
	Variables = [=[
-- Generic Helpers
local LuaFunc, WrapState, BcToState, gChunk;
local FIELDS_PER_FLUSH = 50
local Select = select;
-- Array Helpers
local function CreateTbl(_) return {} end;
local Unpack = unpack or table.unpack
local function Pack(...)
    return {
        n = Select('#', ...), ...
    }
end
local function Move(src, First, Last, Offset, Dst)
    for i = _, Last - First do
        Dst[Offset + i] = src[First + i]
    end
end
-- Mini Bit Library
local function BAnd(a, b)
    local result = _
    local bitval = __
    while a > _ and b > _ do
        if (a % 2 == __) and (b % 2 == __) then
            result = result + bitval
        end
        bitval = bitval * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return result
end
local function LShift(x, n)
    return x * 2 ^ n
end
local function RShift(x, n)
    return math.floor(x / 2 ^ n)
end
local function BOr(a, b)
    local result = _
    local shift = __
    while a > _ or b > _ do
        local abit = a % 2
        local bbit = b % 2
        if abit == __ or bbit == __ then
            result = result + shift
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        shift = shift * 2
    end
    return result
end
-- Upvalue Helpers
local function CloseLuaUpvalues(B, N)
    for i, uv in pairs(B) do
        if uv.N >= N then
            uv.m = uv.M[uv.N];
            uv.M = uv;
            uv.N = 'm'
            B[i] = nil;
        end;
    end;
end;
local function SenLuaUpvalue(B, N, X)
    local Prev = B[N]
    if not Prev then
        Prev = { N = N, M = X }
        B[N] = Prev;
    end;
    return Prev
end;
local function NormalizeNumber(value)
    if value % 1 == 0 then
        return value
    end
    return value
end

-- losing sanity, please help
local _orig_tostring = tostring
function tostring(v)
    if type(v) == 'number' then
        local s = _orig_tostring(v)
        -- if no dot or exponent, assume a whole number and append .0
        if not s:find('[%.eE]') then
            return s .. '.0'
        end
        return s
    end
    return _orig_tostring(v)
end
local asciilookup = {}
for i = 0, 255 do
    asciilookup[string.char(i)] = i
end

local function chartoascii(str, pos)
    pos = pos or 1
    local ch = str:sub(pos, pos)
    return asciilookup[ch]
end
]=],
	Deserializer = [=[
function BcToState(Bytecode, charset)
    local base, decoded = #charset, {}
    local decode_lookup = {}
    for i = 1, base do decode_lookup[charset:sub(i, i)] = i - 1 end
    -- do not FUCKING change the "_"
    for encoded_char in Bytecode:gmatch("([^_]+)") do
        local n = 0
        for i = 1, #encoded_char do n = n * base + decode_lookup[encoded_char:sub(i, i)] end
        decoded[#decoded + 1] = string.char(n)
    end
    local bytes = {}
    for char in table.concat(decoded):gmatch("(.?)\\") do
        if #char > 0 then
            bytes[#bytes + 1] = chartoascii(char)
        end
    end

    local Pos = 1
    local function gBits8()
        local Val = bytes[Pos]
        Pos = Pos + 1
        return Val
    end
    local function gBits16()
        local Val1, Val2 = bytes[Pos], bytes[Pos + 1]
        Pos = Pos + 2
        return (Val2 * 256) + Val1
    end
    local function gBits32()
        local Val1, Val2, Val3, Val4 = bytes[Pos], bytes[Pos + 1], bytes[Pos + 2], bytes[Pos + 3]
        Pos = Pos + 4
        return (Val4 * 16777216) + (Val3 * 65536) + (Val2 * 256) + Val1
    end

    function gChunk()
        local Chunk = {
            n = gBits8(),
            c = gBits8(),
            d = gBits8(),
            x = {},
            D = {},
            V = {}
        }
        for i = __, gBits32() do
            local Data = gBits32()
            local Sco = gBits8()
            local Type = gBits8()
            local Inst = {
                m = Data,
                S = Sco,
                A = gBits16()
            }
            local Mode = {
                b = gBits8(),
                c = gBits8()
            }
            if (Type == __) then
                Inst.B = gBits16()
                Inst.C = gBits16()
                Inst.s = Mode.b == __ and Inst.B > 0xFF
                Inst.a = Mode.c == __ and Inst.C > 0xFF
            elseif (Type == 2) then
                Inst.F = gBits32()
                Inst.g = Mode.b == __
            elseif (Type == 3) then
                Inst.f = gBits32() - 131071
            end
            Chunk.x[i] = Inst
        end
        for i = __, gBits32() do
            local Type = gBits8()
            if (Type == __) then
                Chunk.D[i - __] = (gBits8() ~= _)
            elseif (Type == 3) then
                Chunk.D[i - __] = (function()
                    local Left = gBits32()
                    local Right = gBits32()
                    local IsNormal = __
                    local Mantissa = BOr(LShift(BAnd(Right, 0xFFFFF), 32), Left)
                    local Exponent = BAnd(RShift(Right, 20), 0x7FF)
                    local Sign = (-__) ^ RShift(Right, 31)
                    if Exponent == _ then
                        if Mantissa == _ then
                            return Sign * _
                        else
                            Exponent = __
                            IsNormal = _
                        end
                    elseif Exponent == 2047 then
                        if Mantissa == _ then
                            return Sign * (__ / _)
                        else
                            return Sign * (_ / _)
                        end
                    end
                    local raw = math.ldexp(Sign, Exponent - 1023) * (IsNormal + (Mantissa / (2 ^ 52)))
                    return NormalizeNumber(raw)
                end)()
            elseif (Type == 4) then
                Chunk.D[i - __] = (function()
                    local Str
                    local baik = gBits32()
                    if (baik == _) then return end
                    local chars = {}
                    for j = 1, baik do
                        chars[#chars + 1] = string.char(gBits8())
                    end
                    return table.concat(chars)
                end)()
            end
        end
        for i = __, gBits32() do
            Chunk.V[i - __] = gChunk()
        end

        for _, v in ipairs(Chunk.x) do
            if v.g then
                v.D = Chunk.D[v.F]
            else
                if v.s then
                    v.A = Chunk.D[v.B - 256]
                end
                if v.a then
                    v.C = Chunk.D[v.C - 256]
                end
            end
        end
        return Chunk
    end

    return gChunk()
end
]=],
	Wrapper_1 = [=[
function LuaFunc(State, Env, n)
    local x = State.x;
    local V = State.Z;
    local v = State.v;
    local Top = -__;
    local SenB = {}
    local X = State.X;
    local z = State.z;
    while alpha do
        local Inst = x[z]
        local S = Inst.S;
        local C = Inst.C;
        local A = Inst.A;
        local B = Inst.B;
        local D = Inst.D;
        local F = Inst.F;
        z = z + __;
]=],
	Wrapper_2 = [=[
        State.z = z;
    end;
end;
function WrapState(V, Env, Upval)
    local function Wrapped(...)
        local Passed = Pack(...)
        local X = CreateTbl(V.d)
        local v = { b = _, B = {} }
        Move(Passed, __, V.c, _, X)
        if (V.c < Passed.n) then
            local Start = V.c + __
            local b = Passed.n - V.c;
            v.b = b;
            Move(Passed, Start, Start + b - __, __, v.B)
        end;
        local State = {
            v = v,
            X = X,
            x = V.x,
            Z = V.V,
            z = __
        }
        return LuaFunc(State, Env, Upval)
    end;
    return Wrapped;
end;
]=]
}
return Parts
