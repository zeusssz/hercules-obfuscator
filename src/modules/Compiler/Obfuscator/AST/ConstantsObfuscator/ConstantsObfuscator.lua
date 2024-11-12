math.randomseed(os.time())

--* Dependencies *--

local Lexer = require("Interpreter/LuaInterpreter/Lexer/Lexer")
local Parser = require("Interpreter/LuaInterpreter/Parser/Parser")
local NodeFactory = require("Interpreter/LuaInterpreter/Parser/NodeFactory")
local MockingStrings = require("Obfuscator/AST/ConstantsObfuscator/MockingStrings")

--* Imports *--
local byte = string.byte
local insert = table.insert
local random = math.random

local createExpressionNode = NodeFactory.createExpressionNode
local createOperatorNode = NodeFactory.createOperatorNode
local createFunctionCallNode = NodeFactory.createFunctionCallNode
local createGlobalVariableNode = NodeFactory.createGlobalVariableNode
local createTableNode = NodeFactory.createTableNode
local createTableElementNode = NodeFactory.createTableElementNode
local createStringNode = NodeFactory.createStringNode
local createFunctionNode = NodeFactory.createFunctionNode
local createLocalVariableAssignmentNode = NodeFactory.createLocalVariableAssignmentNode
local createIndexNode = NodeFactory.createIndexNode
local createNumberNode = NodeFactory.createNumberNode
local createLocalVariableNode = NodeFactory.createLocalVariableNode
local createReturnStatementNode = NodeFactory.createReturnStatementNode

--* Local functions *--
local function generateSequence(number)
  local x, y, z
  local tries = 0
  repeat
    tries = tries + 1
    if tries == 1000 then return false end

    -- Choose random values for x and y
    x, y = random(1, 2^16), random(1, 2^16)

    -- Calculate z such that x*x - y*y + z = number
    z = number - x*x + y*y
    local obfuscated
    do
      local x,y, z = x, y, z
      obfuscated = x*x - y*y + z
    end
  until obfuscated == number
  -- Now, convert three numbers to bit-shifted one number
  return x, y, z
end
local function escapeString(str)
  return (str:gsub(".", function(c)
    return "\\".. c:byte()
  end))
end

--* Constants *--
local MOCKING_STRING_CHANCE = 10 -- 5.0 chance
local RANDOM_OPERATORS = {
  { "^", "__pow" },
  { "*", "__mul" },
  { "/", "__div" },
  { "+", "__add" },
  { "-", "__sub" },
  { "%", "__mod" },
  { "..", "__concat" }
}

--* Local functions *--
local function createConstantNumberNode(number)
  local isRandomMockingString = random(1, MOCKING_STRING_CHANCE) == 1
  if isRandomMockingString and number >= 100 then
    local randomString = MockingStrings[random(1, #MockingStrings)]
    return NodeFactory.createOperatorNode(
      "-",
      NodeFactory.createNumberNode(number + #randomString),
      NodeFactory.createUnaryOperatorNode("#", NodeFactory.createStringNode(randomString))
    )
  end
  return NodeFactory.createNumberNode(number)
end

--* ConstantsObfuscator *--
local ConstantsObfuscator = {}

ConstantsObfuscator.Numbers = {}
ConstantsObfuscator.Strings = {}

insert(ConstantsObfuscator.Numbers, {
  String = Parser:new(
    Lexer:new([[setmetatable({}, {
      ["__pow"] = function(_, a)
        local x, y, z = a[1], a[2], a[3]
        return x*x - y*y + z
      end
    }) ^ placeholder]]
    ):tokenize(), false
  ):getExpression(),
  Function = function(self, node, interpretedString)
    local evaluatedNumber = node.Value
    local x, y, z = generateSequence(evaluatedNumber)
    if not x then return end
    -- Change the power operator to a random operator
    local randomOperator = RANDOM_OPERATORS[random(1, #RANDOM_OPERATORS)]
    interpretedString.Value.Left.Arguments[2].Value.Elements[1].Key.Value.Value = randomOperator[2]
    self:obfuscateConstant(interpretedString.Value.Left.Arguments[2].Value.Elements[1].Key)
    -- Replace placeholder with the obfuscated number
    local xNode = createConstantNumberNode(x)
    local yNode = createConstantNumberNode(y)
    local zNode = createConstantNumberNode(z)

    interpretedString.Value.Value = randomOperator[1]
    interpretedString.Value.Right = createTableNode({
      createTableElementNode(createNumberNode(1), xNode, true),
      createTableElementNode(createNumberNode(2), yNode, true),
      createTableElementNode(createNumberNode(3), zNode, true)
    })

    for index, value in pairs(interpretedString) do
      node[index] = value
    end

    return true
  end
})

insert(ConstantsObfuscator.Numbers, {
  String = Parser:new(
    Lexer:new([[1 % 2]]
    ):tokenize(), false
  ):getExpression(),
  Function = function(self, node, interpretedString)
    if node.Value < 0 or node.Value >= 1024 then
      return false
    end

    local interpretedString = interpretedString
    local evaluatedNumber = node.Value
    local a = random(2, 2^16)
    local k = random(2, 2^16)

    local b = (a * k) + evaluatedNumber
    interpretedString.Value.Left.Value = b
    interpretedString.Value.Right.Value = a

    for index, value in pairs(interpretedString) do
      node[index] = value
    end

    return true
  end
})

insert(ConstantsObfuscator.Strings, {
  String = Parser:new(
    Lexer:new([[setmetatable({}, {
      __pow = function(_, a)
        local str = ""
        local i = 1
        while a[i] do
          local x, y, z = a[i][1], a[i][2], a[i][3]
          str = str .. str.char(x*x - y*y + z)
          i = i + 1
        end
        return str
      end
    }) ^ placeholder]]
    ):tokenize(), false
  ):getExpression(),
  Function = function(self, node, interpretedString)
    local evaluatedString = node.Value
    local obfuscatedTable = {}
    local randomOperator = RANDOM_OPERATORS[random(1, #RANDOM_OPERATORS)]
    for i = 1, #evaluatedString do
      local asciiValue = byte(evaluatedString, i)
      local x, y, z = generateSequence(asciiValue)
      local xNode = createConstantNumberNode(x)
      local yNode = createConstantNumberNode(y)
      local zNode = createConstantNumberNode(z)
      obfuscatedTable[i] = createTableNode({
        createTableElementNode(createNumberNode(1), xNode, true),
        createTableElementNode(createNumberNode(2), yNode, true),
        createTableElementNode(createNumberNode(3), zNode, true)
      })
    end
    interpretedString.Value.Value = randomOperator[1]
    interpretedString.Value.Right = createTableNode(obfuscatedTable)
    interpretedString.Value.Left.Arguments[2].Value.Elements[1].Key.Value = randomOperator[2]

    for index, value in pairs(interpretedString) do
      node[index] = value
    end

    return true
  end
})

return ConstantsObfuscator
