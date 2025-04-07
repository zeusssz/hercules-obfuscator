local numbertohex = {}

function numbertohex.process(src)
  return src:gsub("(%d+)", function(num_str)
    return string.format("0x%X", tonumber(num_str))
  end)
end

return numbertohex
