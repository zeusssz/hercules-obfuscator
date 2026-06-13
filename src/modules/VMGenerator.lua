local Parts = require("modules/Compiler/VMStrings")
local GetOpcodeCode = require("modules/Compiler/Opcode")
local compile = require("modules/Compiler/Compiler")
math.randomseed(os.time())
local function generate(...)
	local data = {
		...
	}
	local bytecode = data[1]
	local used_opcodes = data[2]
	local lines = {}
	local function add(line)
		lines[#lines+1] = line
	end;
	local function generateVariable(length)
		local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		local result = {}
		for i = 1, length do
			local rand = math.random(1, # charset)
			table.insert(result, charset:sub(rand, rand))
		end;
		return table.concat(result)
	end;
	local function stringShuffle(str)
		local n = #str
		local codes = {}
		for i = 1, n do codes[i] = str:byte(i) end
		for i = n, 2, -1 do
			local j = math.random(1, i)
			codes[i], codes[j] = codes[j], codes[i]
		end
		for i = 1, n do codes[i] = string.char(codes[i]) end
		return table.concat(codes)
	end;
local function getChar(n)
    local out = {}
    for i = 1, n do
        out[#out + 1] = string.char(i)
    end
    return table.concat(out)
end
	local charset = stringShuffle(getChar(94))
	local base, encode_lookup, decode_lookup = # charset, {}, {}
	for i = 1, base do
		local c = charset:sub(i, i)
		encode_lookup[i - 1], decode_lookup[c] = c, i - 1
	end;
	local function encodeNumber(n)
		local e = {}
		repeat
			local r = n % base;
			table.insert(e, 1, encode_lookup[r])
			n = math.floor(n / base)
		until n == 0;
		return table.concat(e)
	end;
	local function encodeString(str)
		local encoded = {}
		for i = 1, # str do
			local char = str:sub(i, i)
			table.insert(encoded, encodeNumber(char:byte()))
		end;
		return table.concat(encoded, "_")
	end;
local function encode(str_param, yes)
    yes = yes or false
    if not yes then
    str_param = encodeString(str_param)
    end
    local out = {}
    for i = 1, #str_param do
        local b = string.byte(str_param, i)
        table.insert(out, "\\" .. b)
    end

    return table.concat(out)
end
	add("hercules,v1,alpha,__,_ = 'Protected By Hercules V1.6 | github.com/zeusssz/hercules-obfuscator', function()end, true, 1, 0")
	add(Parts.Variables)
	add(Parts.Deserializer)
	add(Parts.Wrapper_1)
	local k = "if"
	for i, v in pairs(used_opcodes) do
		local op = used_opcodes[v]
		add(k .. " (S == " .. op .. ") then\n")
		add(GetOpcodeCode(op))
		k = "elseif"
	end;
	add("end")
	add(Parts.Wrapper_2)
	add("WrapState(BcToState('" .. encode(bytecode) .. "','" .. encode(charset,true) .. "'),(getfenv and getfenv(0)) or _ENV)()")
	return table.concat(lines, "\n")
end;
local VM = {}

-- Replace bitwise XOR (~) with __hx() calls for the Lua 5.1 VM compiler
local function preprocess_bitwise(source)
    if not source:find("~[^=]") then
        return source
    end

    local out_lines = {}
    for line in source:gmatch("[^\n]*") do
        if line:match("^%s*%-%-") then
            table.insert(out_lines, line)
            goto continue
        end

        local parts = {}
        local pos = 1
        local found_tilde = false

        while pos <= #line do
            local ch = line:sub(pos, pos)

            if ch == '"' or ch == "'" then
                local q = ch
                pos = pos + 1
                while pos <= #line do
                    local c = line:sub(pos, pos)
                    if c == "\\" then pos = pos + 2
                    elseif c == q then pos = pos + 1; break
                    else pos = pos + 1 end
                end
            elseif ch == "-" and line:sub(pos + 1, pos + 1) == "-" then
                break
            elseif ch == "~" and line:sub(pos + 1, pos + 1) ~= "=" then
                found_tilde = true

                -- Find left operand end (scan back past whitespace)
                local left_end = pos - 1
                while left_end >= 1 and (line:sub(left_end, left_end) == " " or line:sub(left_end, left_end) == "\t") do
                    left_end = left_end - 1
                end

                -- Find left operand start: scan back for expression boundary
                local left_start = left_end
                local paren_depth = 0
                while left_start > 1 do
                    local pc = line:sub(left_start - 1, left_start - 1)
                    if pc == ")" then
                        paren_depth = paren_depth + 1
                    elseif pc == "(" then
                        if paren_depth > 0 then
                            paren_depth = paren_depth - 1
                        else
                            break  -- opening paren is boundary
                        end
                    elseif paren_depth == 0 then
                        -- Check for operators or keywords
                        if pc == "," or pc == ";" then
                            break
                        elseif pc == "=" and line:sub(left_start - 2, left_start - 2) ~= "~" and line:sub(left_start - 2, left_start - 2) ~= "<" and line:sub(left_start - 2, left_start - 2) ~= ">" then
                            break
                        elseif pc == "+" or pc == "-" or pc == "*" or pc == "/" or pc == "%" or pc == "^" or pc == "<" or pc == ">" or pc == "#" or pc == "!" then
                            break
                        elseif pc == " " or pc == "\t" then
                            -- Check for keywords
                            local before = line:sub(1, left_start - 1):match("%S+%s*$")
                            if before and (before == "return" or before == "then" or before == "do" or before == "else" or before == "elseif" or before == "in" or before == "and" or before == "or" or before == "not" or before == "local") then
                                break
                            end
                        end
                    end
                    left_start = left_start - 1
                end
                if left_start < 1 then left_start = 1 end

                -- Trim leading whitespace
                while left_start <= left_end and (line:sub(left_start, left_start) == " " or line:sub(left_start, left_start) == "\t") do
                    left_start = left_start + 1
                end

                local left_op = line:sub(left_start, left_end)

                -- Find right operand
                local right_start = pos + 1
                while right_start <= #line and (line:sub(right_start, right_start) == " " or line:sub(right_start, right_start) == "\t") do
                    right_start = right_start + 1
                end
                -- Find right operand end: stop at statement separators or operators
                local right_end = right_start - 1
                local rparen_depth = 0
                for rp = right_start, #line do
                    local rc = line:sub(rp, rp)
                    if rc == "(" then
                        rparen_depth = rparen_depth + 1
                    elseif rc == ")" then
                        rparen_depth = rparen_depth - 1
                    elseif rparen_depth == 0 then
                        if rc == ";" or rc == "," then
                            break
                        end
                    end
                    right_end = rp
                end
                -- Check for comment
                local comment_pos = line:find("%-%-", right_start)
                if comment_pos and comment_pos < right_end then
                    right_end = comment_pos - 1
                end
                while right_end > right_start and (line:sub(right_end, right_end) == " " or line:sub(right_end, right_end) == "\t") do
                    right_end = right_end - 1
                end

                local right_op = line:sub(right_start, right_end)

                table.insert(parts, line:sub(1, left_start - 1))
                table.insert(parts, "__hx(" .. left_op .. ", " .. right_op .. ")")
                table.insert(parts, line:sub(right_end + 1))
                pos = #line + 1
            else
                pos = pos + 1
            end
        end

        if found_tilde then
            table.insert(out_lines, table.concat(parts))
        else
            table.insert(out_lines, line)
        end
        ::continue::
    end

    local result = table.concat(out_lines, "\n")
    local hxfn = "local function __hx(a,b) local r,p=0,1 while a>0 or b>0 do local ab,bb=a%2,b%2 if ab~=bb then r=r+p end a=math.floor(a/2) b=math.floor(b/2) p=p*2 end return r end"
    return hxfn .. "\n" .. result
end

function VM.process(source)
    source = preprocess_bitwise(source)
    _G.UsedOps = _G.UsedOps or {}
    _G.UsedOps[0] = 0;
    _G.UsedOps[4] = 4;
    local ok, compiled = pcall(compile, source)
    if ok then
        source = generate(compiled, _G.UsedOps)
    end
    return source
end;
return VM
