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
function bit.lshift(x, n)
        return x * 2 ^ n
end
function bit.rshift(x, n)
        return math.floor(x / 2 ^ n)
end
return bit
