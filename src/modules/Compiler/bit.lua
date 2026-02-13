local bit = {}
function bit.band(a, b)
        local result = 0
        local bitval = 1
        while a > 0 and b > 0 do
                if (a % 2 == 1) and (b % 2 == 1) then
                        result = result + bitval
                end
                bitval = bitval * 2
                a = math.floor(a / 2)
                b = math.floor(b / 2)
        end
        return result
end
function bit.bxor(a, b)
        local result = 0
        local bitval = 1
        while a > 0 or b > 0 do
                local aa = a % 2
                local bb = b % 2
                if aa ~= bb then
                        result = result + bitval
                end
                bitval = bitval * 2
                a = math.floor(a / 2)
                b = math.floor(b / 2)
        end
        return result
end
function bit.lshift(x, n)
        return x * 2 ^ n
end
function bit.rshift(x, n)
        return math.floor(x / 2 ^ n)
end
function bit.lrotate(x, n)
        n = n % 32
        local mask = 2^32 - 1
        x = x % (2^32)
        return ((x * (2^n)) % (2^32)) + math.floor(x / (2^(32-n)))
end
return bit
