--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local Crypt = require("Crypt/Crypt")

--* Import library functions *--
local insert = table.insert
local unpack = (unpack or table.unpack)

local readOneByte   = Crypt.readOneByte
local readTwoBytes  = Crypt.readTwoBytes
local readFourBytes = Crypt.readFourBytes
local readDouble    = Crypt.readDouble

local makeOneByte   = Crypt.makeOneByteLittleEndian
local makeTwoBytes  = Crypt.makeTwoBytesLittleEndian
local makeFourBytes = Crypt.makeFourBytesLittleEndian
local makeEightBytes = Crypt.makeEightBytesLittleEndian
local makeDouble    = Crypt.makeDoubleLittleEndian

--* Constants *--
local MAGIC = "\27Lua"
local VERSION = 0x51

local MODE_iABC = 0
local MODE_iABx = 1
local MODE_iAsBx = 2
local MODE_iAB = 3

local OPCODE_TO_NUMBER = {
  ["MOVE"]     = 0,  ["LOADK"]     = 1,  ["LOADBOOL"] = 2,  ["LOADNIL"]   = 3,
  ["GETUPVAL"] = 4,  ["GETGLOBAL"] = 5,  ["GETTABLE"] = 6,  ["SETGLOBAL"] = 7,
  ["SETUPVAL"] = 8,  ["SETTABLE"]  = 9,  ["NEWTABLE"] = 10, ["SELF"]      = 11,
  ["ADD"]      = 12, ["SUB"]       = 13, ["MUL"]      = 14, ["DIV"]       = 15,
  ["MOD"]      = 16, ["POW"]       = 17, ["UNM"]      = 18, ["NOT"]       = 19,
  ["LEN"]      = 20, ["CONCAT"]    = 21, ["JMP"]      = 22, ["EQ"]        = 23,
  ["LT"]       = 24, ["LE"]        = 25, ["TEST"]     = 26, ["TESTSET"]   = 27,
  ["CALL"]     = 28, ["TAILCALL"]  = 29, ["RETURN"]   = 30, ["FORLOOP"]   = 31,
  ["FORPREP"]  = 32, ["TFORLOOP"]  = 33, ["SETLIST"]  = 34, ["CLOSE"]     = 35,
  ["CLOSURE"]  = 36, ["VARARG"]    = 37
}

local OPMODES = {
  [0] = MODE_iABC,  [1]  = MODE_iABx,  [2]  = MODE_iABC,
  [3] = MODE_iABC,  [4]  = MODE_iABC,  [5]  = MODE_iABx,
  [6] = MODE_iABC,  [7]  = MODE_iABx,  [8]  = MODE_iABC,
  [9] = MODE_iABC,  [10] = MODE_iABC,  [11] = MODE_iABC,
  [12] = MODE_iABC, [13] = MODE_iABC,  [14] = MODE_iABC,
  [15] = MODE_iABC, [16] = MODE_iABC,  [17] = MODE_iABC,
  [18] = MODE_iABC, [19] = MODE_iABC,  [20] = MODE_iABC,
  [21] = MODE_iABC, [22] = MODE_iAsBx, [23] = MODE_iABC,
  [24] = MODE_iABC, [25] = MODE_iABC,  [26] = MODE_iABC,
  [27] = MODE_iABC, [28] = MODE_iABC,  [29] = MODE_iABC,
  [30] = MODE_iABC, [31] = MODE_iAsBx, [32] = MODE_iAsBx,
  [33] = MODE_iABC, [34] = MODE_iABC,  [35] = MODE_iABC,
  [36] = MODE_iABx, [37] = MODE_iABC
}


--* Compiler *--
local Compiler = {}

function Compiler.compile(proto)
  local header = Compiler.compileHeader(proto)
  local functionProto = Compiler.compileFunction(proto)
  return header .. functionProto
end

function Compiler.compileHeader(proto)
  local header = MAGIC
  header = header .. makeOneByte(VERSION)
  header = header .. makeOneByte(0) -- format version

  header = header .. makeOneByte(1) -- endianness
  header = header .. makeOneByte(4) -- size of int
  header = header .. makeOneByte(8) -- size of size_t
  header = header .. makeOneByte(4) -- size of Instruction
  header = header .. makeOneByte(8) -- size of lua_Number
  header = header .. makeOneByte(0) -- integral flag
  return header
end

function Compiler.compileFunction(proto)
  local functionProto = ""
  functionProto = functionProto .. Compiler.compileString(proto.sourceName or "@test.lua")
  functionProto = functionProto .. Compiler.compileInt(0)
  functionProto = functionProto .. Compiler.compileInt(0)
  functionProto = functionProto .. makeOneByte(proto.numParams or 0)
  functionProto = functionProto .. makeOneByte(0)
  functionProto = functionProto .. makeOneByte(2)
  functionProto = functionProto .. makeOneByte(2)
  functionProto = functionProto .. Compiler.compileCode(proto)
  functionProto = functionProto .. Compiler.compileConstants(proto.constants)
  -- functionProto = functionProto .. Compiler.compileFunctions(proto.functions)
  -- functionProto = functionProto .. Compiler.compileDebug(proto.debug)
  functionProto = functionProto .. Compiler.compileInt(0) -- n_functions
  functionProto = functionProto .. Compiler.compileInt(0) -- n_linepositions
  functionProto = functionProto .. Compiler.compileInt(0) -- n_locals
  functionProto = functionProto .. Compiler.compileInt(0) -- n_upvalues
  return functionProto
end

function Compiler.compileString(str)
  local stringSize = #str
  local size = stringSize + 1 -- including null terminator
  local compiledString = makeEightBytes(size) -- compile size into eight bytes
  compiledString = compiledString .. str -- append the string itself
  compiledString = compiledString .. makeOneByte(0) -- append null terminator
  return compiledString
end

function Compiler.compileInt(int)
  return makeFourBytes(int)
end

function twos_complement(n, bits)
  if n < 0 then
      n = n + 1
      if n < 0 then
        n = bit_xor(bit_not(math.abs(n)), (1 << bits) - 1) + 1
      end
  end
  return n
end

function bit_not(n)
  local p,c=1,0
  while n > 0 do
      local r=n%2
      if r<1 then c=c+p end
      n,p=(n-r)/2,p*2
  end
  return c
end

function bit_xor(m, n)
  local xr = 0
  for p=0,31 do
      local a = m / 2 + xr
      local b = n / 2
      if (a ~= math.floor(a)) and (b ~= math.floor(b)) then
          xr = math.pow(2, p)
      else
          xr = 0
      end
      m, n = math.floor(a), math.floor(b)
  end
  return xr
end

function Compiler.compileCode(proto)
  local code = Compiler.compileInt(#proto.instructions)
  local instructions = proto.instructions
  for _, instruction in ipairs(instructions) do
      local opName, a, b, c = unpack(instruction)
      a = twos_complement(a or 0, 9)
      b = twos_complement(b or 0, 9)
      c = twos_complement(c or 0, 9)
      local opcode = OPCODE_TO_NUMBER[opName]
      local opMode = OPMODES[opcode]
      local inst = 0
      if opMode == MODE_iABC then
        inst = inst + opcode
        inst = inst + (a * 64)      -- a << 6
        inst = inst + (b * 8388608) -- b << 23
        inst = inst + (c * 16384)   -- c << 14
      elseif opMode == MODE_iABx then
        inst = inst + opcode
        inst = inst + (a * 64)        -- a << 6
        inst = inst + (b * 16384)     -- b << 14
      elseif opMode == MODE_iAsBx then
        inst = inst + opcode
        inst = inst + (a * 64)               -- a << 6
        inst = inst + ((b + 131071) * 16384) -- (b + 131071) << 14
      elseif opMode == MODE_iAB then
        inst = inst + opcode
        inst = inst + (a * 64)    -- a << 6
        inst = inst + (b * 16384) -- b << 14
      end
      code = code .. makeFourBytes(inst)
  end
  return code
end

function Compiler.compileConstants(constants)
  local constantString = Compiler.compileInt(#constants)
  for _, constant in ipairs(constants) do
    local constantType = type(constant)
    if constantType == "string" then
      constantString = constantString .. string.char(4)
      constantString = constantString .. Compiler.compileString(constant)
    elseif constantType == "number" then
      constantString = constantString .. string.char(3)
      constantString = constantString .. makeDouble(constant)
    else
      error(constantType)
    end
  end
  return constantString
end

function Compiler.compileFunctions(functions)
end

function Compiler.compileDebug(debug)
end

return Compiler
