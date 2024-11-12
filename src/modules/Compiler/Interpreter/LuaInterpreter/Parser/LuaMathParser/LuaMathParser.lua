--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local NodeFactory = require("Interpreter/LuaInterpreter/Parser/NodeFactory")

local LuaExpressionEvaluator = require("Interpreter/LuaInterpreter/Parser/LuaMathParser/LuaExpressionEvaluator")

--* Constants *--
local UNARY_OPERATOR_PRECEDENCE = 8
local OPERATOR_PRECEDENCE = {
  ["+"]   = {6, 6},  ["-"]  = {6, 6},
  ["*"]   = {7, 7},  ["/"]  = {7, 7}, ["%"] = {7, 7},
  ["^"]   = {10, 9}, [".."] = {5, 4},
  ["=="]  = {3, 3},  ["~="] = {3, 3},
  ["<"]   = {3, 3},  [">"]  = {3, 3}, ["<="] = {3, 3}, [">="] = {3, 3},
  ["and"] = {2, 2},  ["or"] = {1, 1}
}

local LUA_UNARY_OPERATORS =  { "-", "#", "not" }
local LUA_BINARY_OPERATORS = {
  "+",  "-",   "*",  "/",
  "%",  "^",   "..", "==",
  "~=", "<",   ">",  "<=",
  ">=", "and", "or"
}

--* Local functions *--
local function makeLookupTable(array)
  local lookupTable = {}
  for _, value in ipairs(array) do
    lookupTable[value] = true
  end
  return lookupTable
end

--* Imports *--
local insert = table.insert

local unaryOperatorsLookupTable = makeLookupTable(LUA_UNARY_OPERATORS)
local binaryOperatorsLookupTable = makeLookupTable(LUA_BINARY_OPERATORS)

--* NodeFactory function assignments *--
local createExpressionNode     = NodeFactory.createExpressionNode
local createOperatorNode       = NodeFactory.createOperatorNode
local createUnaryOperatorNode  = NodeFactory.createUnaryOperatorNode

--* LuaMathParserMethods *--
local LuaMathParserMethods = {}

-- Normal math parsers have these constructors:
--  <Primary>, <Unary>, <Binary>, <Expression>
-- But Lua has more than that:
--  <Primary> = <Literal> | <Identifier> | <FunctionCall> | <ParenthesizedExpression> | etc.
--  <Suffix> = <FunctionCall> | <TableAccess>
--  <Prefix> = <Primary> <Suffix>*
--  <Unary> = <Prefix> | <UnaryOperator> <Unary>
--  <Binary> = <Unary> <BinaryOperator> <Binary>
--  <Expression> = <Binary>

--- (MAIN) Parses a Lua expression from the token stream.
-- @return <Table> expressionNode The parsed expression node.
function LuaMathParserMethods:getExpression()
  local expression = self:parseBinaryExpression(0)
  if not expression then
    self:consume(-1)
    return
  end

  -- local evaluated = LuaExpressionEvaluator.evaluate(expression)
  return createExpressionNode(expression)
end

--- Gets multiple expressions from the token stream.
-- @param <Number?> maxAmount The maximum amount of expressions to parse.
-- @param <Number?> maxReturnValueCount The maximum amount of return values for each expression.
-- @return <Table> expressions The parsed expressions.
function LuaMathParserMethods:getExpressions(maxAmount, maxReturnValueCount)
  local expressions = { self:getExpression() }

  -- If no expression was consumed, return the empty expressions table.
  if #expressions == 0 then return expressions end

  local oldExpectedReturnValueCount = self.expectedReturnValueCount
  self.expectedReturnValueCount = maxReturnValueCount or 0

  while self:compareTokenValueAndType(self:peek(), "Character", ",") do
    if maxAmount and #expressions >= maxAmount then break end
    self:consume(2) -- Consume the last token of the last expression and ","
    -- Consume the next expression
    local expression = self:getExpression()
    insert(expressions, expression)
  end

  return expressions
end

--// Input checkers //--

--- Checks if the given token is an unary operator.
-- @param <Table?> token=self.currentToken The token to check.
-- @return <Boolean> isUnaryOperator Whether the token is an unary operator.
function LuaMathParserMethods:isUnaryOperator(token)
  local token = token or self.currentToken
  return token and token.TYPE == "Operator" and unaryOperatorsLookupTable[token.Value]
end

--- Checks if the given token is a binary operator.
-- @param <Table?> token=self.currentToken The token to check.
-- @return <Boolean> isBinaryOperator Whether the token is a binary operator.
function LuaMathParserMethods:isBinaryOperator(token)
  local token = token or self.currentToken
  return token and token.TYPE == "Operator" and binaryOperatorsLookupTable[token.Value]
end

--// Parsers //--

--- Consumes primary expressions (e.g., literals, identifiers, etc.)
-- @return <Table> expressionNode The parsed expression node.
function LuaMathParserMethods:parsePrimaryExpression()
  local currentToken = self.currentToken
  local tokenType = currentToken.TYPE
  local tokenValue = currentToken.Value

  if tokenType == "Number" or tokenType == "String" then
    insert(self.constants, currentToken)
    return currentToken
  elseif tokenType == "Constant" or tokenType == "VarArg" then
    return currentToken
  elseif tokenType == "Identifier" then
    local variableNode, variable = self:convertIdentifierToVariableNode(currentToken)
    if variable then
      insert(variable.References, variableNode)
    end
    return variableNode
  elseif tokenType == "Character" then
    if tokenValue == "(" then -- Parenthesized expression
      self:consume() -- Consume the parenthesis
      local oldExpectedReturnValueCount = self.expectedReturnValueCount
      self.expectedReturnValueCount = 1 -- Parenthesized expressions always return 1 value
      local expression = self:getExpression()
      self.expectedReturnValueCount = oldExpectedReturnValueCount

      self:consume() -- Consume the last char of the expression
      return expression
    elseif tokenValue == "{" then -- Table
      return self:consumeTable()
    end
  elseif tokenType == "Keyword" then
    if tokenValue == "function" then
      local oldExpectedReturnValueCount = self.expectedReturnValueCount
      self.expectedReturnValueCount = 0
      local functionNode = self:consumeFunction()
      self.expectedReturnValueCount = oldExpectedReturnValueCount
      return functionNode
    end
  end

  return nil
end

--- Consumes suffix expressions (e.g., function calls, table accesses, etc.)
-- @return <Table> expressionNode The parsed expression node.
function LuaMathParserMethods:parseSuffixExpression(primaryExpression)
  -- suffixExpressions ::= [
  --  <expression> \( <args> \)
  --  || <expression> \. <identifier>
  --  || <expression> \: <identifier> \( <args> \)
  --  || <expression> \[ <expression> \]
  -- ]
  local nextToken = self:peek()
  local nextTokenValue = nextToken and nextToken.Value
  if nextTokenValue == "(" then -- Function call
    local lastLine = self.currentToken.Line
    local isCallable = self.currentToken.TYPE ~= "Number"
    if lastLine ~= nextToken.Line and isCallable then
      error("ambiguous syntax (function call x new statement)")
    end
    self:consume()
    -- <expression> \( <args> \)
    return self:parseFunctionCall(primaryExpression)
  elseif nextTokenValue == "." then -- Table access
    self:consume()
    -- <expression> \. <identifier>
    return self:consumeTableIndex(primaryExpression)
  elseif nextTokenValue == ":" then -- Method call
    self:consume()
    -- <expression> \: <identifier> \( <args> \)
    return self:consumeMethodCall(primaryExpression)
  elseif nextTokenValue == "[" then -- Bracket indexing
    self:consume()
    -- <expression> \[ <expression> \]
    return self:consumeBracketTableIndex(primaryExpression)
  elseif nextToken then
    -- In some edge cases, a user may call a function using only string,
    -- example: `print "Hello, World!"`. This is a valid Lua syntax.
    -- Let's handle both strings and tables here for that case.
    local nextTokenType = nextToken.TYPE
    if nextTokenType == "String" or (nextTokenValue == "{" and nextTokenType == "Character") then
      self:consume()
      return self:parseImplicitFunctionCall(primaryExpression)
    end
  end

  return nil
end

--- Consumes prefix expressions (e.g., primary expressions followed by suffix expressions)
-- @return <Table> expressionNode The parsed expression node.
function LuaMathParserMethods:parsePrefixExpression(precedence)
  local primaryExpression = self:parsePrimaryExpression(precedence) -- <primary>
  if not primaryExpression then return end

  -- <suffix>*
  while (true) do
    local newExpression = self:parseSuffixExpression(primaryExpression)
    if not newExpression then break end
    primaryExpression = newExpression
  end

  return primaryExpression
end

--- Consumes unary expressions (e.g., unary operators followed by prefix expressions)
-- @return <Table> expressionNode The parsed expression node.
function LuaMathParserMethods:parseUnaryOperator()
  -- <unary> ::= <unary operator> <unary> | <primary>
  local unaryOperator = self.currentToken
  if not self:isUnaryOperator(unaryOperator) then
    return self:parsePrefixExpression(UNARY_OPERATOR_PRECEDENCE)
  end

  -- <unary operator> <unary>
  self:consume() -- Consume the operator
  local expression = self:parseBinaryExpression(UNARY_OPERATOR_PRECEDENCE)
  return createUnaryOperatorNode(unaryOperator.Value, expression)
end

--- Consumes binary expressions (e.g., binary operators followed by unary expressions)
-- @return <Table> expressionNode The parsed expression node.
function LuaMathParserMethods:parseBinaryExpression(minPrecedence)
  -- <binary> ::= <unary> <binary operator> <binary> | <unary>
  local minPrecedence = minPrecedence or 0
  local expression = self:parseUnaryOperator() -- <unary>
  if not expression then return end

  -- [<binary operator> <binary>]
  while true do
    local operatorToken = self:peek()
    local precedence = operatorToken and OPERATOR_PRECEDENCE[operatorToken.Value]
    if not self:isBinaryOperator(operatorToken) or precedence[1] <= minPrecedence then
      break
    end

    -- The <binary operator> <binary> part itself
    local nextToken = self:consume(2) -- Advance to and consume the operator
    if not nextToken then error("Unexpected end") end

    local right = self:parseBinaryExpression(precedence[2])
    if not right then error("Unexpected end") end

    expression = createOperatorNode(operatorToken.Value, expression, right)
  end
  return expression
end

return LuaMathParserMethods
