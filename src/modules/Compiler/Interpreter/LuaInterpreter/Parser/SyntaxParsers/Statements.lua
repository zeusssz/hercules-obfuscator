--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local NodeFactory = require("Interpreter/LuaInterpreter/Parser/NodeFactory")

--* Imports *--
local insert = table.insert
local stringifyTable = Helpers.stringifyTable

--* NodeFactory functions imports *--
local createFunctionCallNode            = NodeFactory.createFunctionCallNode -- (expression, arguments, expectedReturnValueCount)
local createMethodCallNode              = NodeFactory.createMethodCallNode -- (expression, arguments, expectedReturnValueCount)
local createStringNode                  = NodeFactory.createStringNode -- (value)
local createNumberNode                  = NodeFactory.createNumberNode -- (value)
local createIndexNode                   = NodeFactory.createIndexNode -- (index, expression)
local createMethodIndexNode             = NodeFactory.createMethodIndexNode -- (index, expression)
local createTableNode                   = NodeFactory.createTableNode -- (elements)
local createTableElementNode            = NodeFactory.createTableElementNode -- (key, value, implicitKey)
local createFunctionNode                = NodeFactory.createFunctionNode -- (parameters, isVararg, codeBlock)
local createMethodDeclarationNode       = NodeFactory.createMethodDeclarationNode -- (parameters, isVararg, codeBlock, fields)
local createVariableAssignmentNode      = NodeFactory.createVariableAssignmentNode -- (variables, expressions, metadata)
local createLocalFunctionNode           = NodeFactory.createLocalFunctionNode -- (name, parameters, isVararg, codeBlock)

--* Statements *--
local Statements = {}

-- ";?"
function Statements:consumeNextOptionalSemicolon()
  -- Consume an optional semicolon
  local nextToken = self:peek()
  if nextToken and nextToken.Value == ";" and nextToken.TYPE == "Character" then
    self:consume()
  end
end

-- "<variable>(, <variable>)* (= <expression>(, <expression>)*)?"
function Statements:consumeVariableAssignment(lvalues)
  self:expectCurrentTokenAndConsume("Character", "=")
  local expressions = self:getExpressions(nil, #lvalues)

  local variableAssignmentNode = createVariableAssignmentNode(lvalues, expressions)
  if not self.includeMetadata then
    return variableAssignmentNode
  end

  for index, lvalue in ipairs(lvalues) do
    local lvalueType = lvalue.TYPE
    local lvalueVariableType = lvalue.VariableType
    if lvalueType == "Variable" and lvalueVariableType== "Global" then
      insert(lvalue._Variable.DeclarationNodes, variableAssignmentNode)
    elseif lvalueVariableType == "Local" then
      insert(lvalue._Variable.AssignmentNodes, variableAssignmentNode)
    end
  end

  return variableAssignmentNode
end

-- "[<functioncall> | <variableassignment>]"
function Statements:parseFunctionCallOrVariableAssignment()
  local lvalue = self:parsePrefixExpression()
  local lvalueType = lvalue.TYPE
  if lvalue then
    if lvalueType == "Index" or lvalueType == "Variable" then
      return self:parseAssignment(lvalue)
    elseif lvalueType == "FunctionCall" or lvalueType == "MethodCall" then
      lvalue.ExpectedReturnValueCount = 0
      return lvalue
    else
      error("Unexpected lvalue type: " .. lvalueType)
    end
  end

  error("Expected an lvalue, got: " .. stringifyTable(self.currentToken))
end

-- "[<identifier>, <vararg>]? [, <identifier>, <vararg>]*"
function Statements:consumeFunctionParameters()
  local parameters = {}
  local isVararg = false
  while true do
    local currentToken = self.currentToken
    local tokenType = currentToken.TYPE
    if tokenType == "Identifier" then
      insert(parameters, currentToken.Value)
    elseif tokenType == "VarArg" then
      isVararg = true
      -- There's no params after vararg.
      self:expectNextToken("Character", ")")
      break
    elseif tokenType == "Character" and currentToken.Value == ")" then
      break
    else
      error("Unexpected token: " .. stringifyTable(currentToken))
    end
    if not self:compareTokenValueAndType(self:consume(), "Character", ",") then
      break
    end
    self:consume()
  end

  local variables = {}
  for _, parameter in ipairs(parameters) do
    insert(variables, self:registerVariable(parameter))
  end
  return parameters, isVararg, variables
end

-- function(<args>) <code_block> end
function Statements:consumeFunction()
  self:consume() -- Consume the "function" keyword
  self:expectCurrentToken("Character", "(")
  self:consume() -- Consume "("
  self:pushScope(true) -- Function scope
  local parameters, isVararg, variables = self:consumeFunctionParameters()
  self:expectCurrentToken("Character", ")")
  self:consume() -- Consume ")"
  local codeBlock = self:consumeCodeBlock(nil, true)
  self:expectCurrentToken("Keyword", "end")
  self:popScope() -- Pop function scope

  -- self:consume()
  local functionNode = createFunctionNode(parameters, isVararg, codeBlock)
  for _, variable in ipairs(variables) do
    variable.DeclarationNode = functionNode
  end
  return functionNode
end

-- <table>.<index>
function Statements:consumeTableIndex(currentExpression)
  self:consume() -- Consume the "." symbol

  local indexToken = self.currentToken
  if indexToken.TYPE == "Identifier" then
    indexToken = createStringNode(indexToken.Value)
    insert(self.constants, indexToken)
  end
  return createIndexNode(indexToken, currentExpression)
end

-- <table>[<expression>]
function Statements:consumeBracketTableIndex(currentExpression)
  self:consume() -- Consume the "[" symbol
  local expression = self:getExpression()
  self:expectNextToken("Character", "]")
  return createIndexNode(expression, currentExpression)
end

-- <function_name>[<expression>]*
function Statements:consumeFunctionCall(currentExpression)
  -- Get arguments for the function
  if self.currentToken.TYPE == "Character" and self.currentToken.Value == "(" then
    self:consume() -- Consume the "(" symbol
    local arguments = {}
    if not (self.currentToken.Value == ")" and self.currentToken.TYPE == "Character") then
      arguments = self:getExpressions()
      self:consume()
    end
    self:expectCurrentToken("Character", ")")

    return createFunctionCallNode(currentExpression, arguments, self.expectedReturnValueCount)
  elseif self.currentToken.TYPE == "String" or (self.currentToken.TYPE == "Character" and self.currentToken.Value == "{") then
    local argument = self:getExpression()
    return createFunctionCallNode(currentExpression, {argument}, self.expectedReturnValueCount)
  end
end

-- <table>:<method_name>(<args>*)
function Statements:consumeMethodCall(currentExpression)
  self:consume() -- Consume the ":" symbol
  local functionName = self.currentToken
  if functionName.TYPE ~= "Identifier" then
    return error("Incorrect function name")
  end
  functionName.TYPE = "String"
  self:consume() -- Consume the name of the method

  local functionCall = self:consumeFunctionCall(createMethodIndexNode(functionName, currentExpression))
  return createMethodCallNode(functionCall.Expression, functionCall.Arguments, self.ExpectedReturnValueCount)
end

-- <identifier> [ \, <identifier> ]*
function Statements:consumeMultipleIdentifiers(self, oneOrMore)
  local identifiers = { }
  local currentToken = self.currentToken
  if currentToken.TYPE ~= "Identifier" then
    assert(not oneOrMore, "Expected an identifier, got: " .. stringifyTable(currentToken))
    return identifiers
  end
  insert(identifiers, currentToken.Value)

  while self:compareTokenValueAndType(self:peek(), "Character", ",") do
    self:consume(2) -- Consume the last identifier and ","
    local nextToken = self.currentToken
    if nextToken.TYPE ~= "Identifier" then
      return error("Expected an identifier, got: " .. stringifyTable(nextToken))
    end
    insert(identifiers, nextToken.Value)
  end

  return identifiers
end

-- <assignment> ::= <lvalue> [, <lvalue>]+ = <expression> [, <expression>]*
--                  | <lvalue> = <expression> [, <expression>]*
-- ^^^ I broke down the assignment into terms
-- (multiple lvalues vs single lvalue) so it'll be easier to parse
function Statements:parseAssignment(lvalue)
  local nextToken = self:peek()

  -- <assignment> ::= <lvalue> [, <lvalue>]+ = <expression> [, <expression>]*
  if self:compareTokenValueAndType(nextToken, "Character", ",") then
    self:consume() -- Consume the last token of the last lvalue
    self:consume() -- Consume ","
    local lvalues = { lvalue }
    while true do
      local lvalue = self:parsePrefixExpression()
      if not lvalue then break end
      local lvalueType = lvalue.TYPE
      if lvalueType == "Variable" or lvalueType == "Index" then
        insert(lvalues, lvalue)
        local nextToken = self:consume() -- Consume the last token of the lvalue
        if nextToken.TYPE ~= "Character" or nextToken.Value ~= "," then
          break
        end
        self:consume() -- Consume ","
      else
        return error("Expected an lvalue, got: " .. stringifyTable(lvalue))
      end
    end
    return self:consumeVariableAssignment(lvalues)

  -- <assignment> ::= <lvalue> = <expression>
  elseif self:compareTokenValueAndType(nextToken, "Character", "=") then
    self:consume() -- Consume the last token of the last lvalue
    return self:consumeVariableAssignment({ lvalue })
  end

  return -- This is not an assignment
end

-- <functionCall> ::= \( <args> \)
function Statements:parseFunctionCall(lvalue)
  self:consume() -- Consume the "("
  local arguments = self:getExpressions()
  self:consume() -- Consume the last token of the expression
  return createFunctionCallNode(lvalue, arguments, self.expectedReturnValueCount)
end

-- <functionCall> ::= <string> | <table>
function Statements:parseImplicitFunctionCall(lvalue)
  local currentToken = self.currentToken
  local currentTokenType = currentToken.TYPE

  if currentTokenType == "String" then
    insert(self.constants, currentToken)
    return createFunctionCallNode(lvalue, { currentToken }, self.expectedReturnValueCount)
  elseif currentTokenType == "Character" and currentToken.Value == "{" then
    return createFunctionCallNode(lvalue, { self:consumeTable() }, self.expectedReturnValueCount)
  end

  return nil
end

-- { ( \[<expression>\] = <expression> | <identifier> = <expression> | <expression> ) ( , | ; )? }*
function Statements:consumeTable()
  -- Table constructor
  -- \{ [
  --  \[ <expression> \] = <expression>
  --  || <identifier> = <expression>
  --  || <expression>
  -- ]* \}
  self:consume() -- Consume "{"

  local elements = {}
  local internalImplicitKey = 1

  -- Consume table elements
  while not self:compareTokenValueAndType(self.currentToken, "Character", "}") do
    local curToken = self.currentToken
    local key, value
    local isImplicitKey = false

    if self:compareTokenValueAndType(curToken, "Character", "[") then
      -- [<expression>] = <expression>
      self:consume() -- Consume "["
      key = self:getExpression()
      self:expectNextToken("Character", "]")
      self:expectNextToken("Character", "=")
      self:consume() -- Consume "="
      value = self:getExpression()
    elseif curToken.TYPE == "Identifier" and self:compareTokenValueAndType(self:peek(), "Character", "=") then
      -- <identifier> = <expression>
      key = createStringNode(curToken.Value)
      insert(self.constants, key)
      self:consume() -- Consume key
      self:consume() -- Consume "="
      value = self:getExpression()
    else -- <expression>
      key = createNumberNode(internalImplicitKey)
      internalImplicitKey = internalImplicitKey + 1
      isImplicitKey = true
      insert(self.constants, key)
      value = self:getExpression()
    end
    insert(elements, createTableElementNode(key, value, isImplicitKey))

    self:consume() -- Consume the last token of the expression
    local shouldContinue = (self.currentToken.TYPE == "Character") and
                            (self.currentToken.Value == "," or self.currentToken.Value == ";")
    if not shouldContinue then break end
    self:consume() -- Consume "," or ";"
  end

  return createTableNode(elements)
end

-- "local function <identifier>(<args>) <code_block> end"
function Statements:consumeLocalFunction()
  self:consume() -- Consume "local"
  self:expectCurrentTokenAndConsume("Keyword", "function") -- Consume "function"
  local functionName = self:expectCurrentToken("Identifier").Value
  local variable = self:registerVariable(functionName)
  self:consume()
  self:expectCurrentTokenAndConsume("Character", "(")
  self:pushScope(true) -- Function scope
  local parameters, isVararg, variables = self:consumeFunctionParameters()
  self:expectCurrentTokenAndConsume("Character", ")")
  local codeBlock = self:consumeCodeBlock(nil, true)
  self:popScope() -- Pop function scope
  local functionNode = createLocalFunctionNode(functionName, parameters, isVararg, codeBlock)
  variable.DeclarationNode = functionNode
  for _, variable in ipairs(variables) do
    variable.DeclarationNode = functionNode
  end

  return functionNode
end

-- ":<identifier>(<args>) <code_block> end"
function Statements:consumeMethod(expression, fields)
  self:consume() -- Consume ":"
  local methodName = self:expectCurrentToken("Identifier")
  insert(fields, methodName.Value)
  self:consume() -- Consume method name

  self:expectCurrentTokenAndConsume("Character", "(")
  self:pushScope(true) -- Function scope
  local parameters, isVararg, variables = self:consumeFunctionParameters()
  insert(parameters, "self")
  insert(variables, self:registerVariable("self"))
  self:expectCurrentTokenAndConsume("Character", ")")
  local codeBlock = self:consumeCodeBlock(nil, true)
  self:popScope() -- Function scope

  parameters[#parameters] = nil -- Remove "self"
  local methodDeclarationNode = createMethodDeclarationNode(parameters, isVararg, codeBlock, expression, fields)
  for _, variable in ipairs(variables) do
    variable.DeclarationNode = methodDeclarationNode
  end
  return methodDeclarationNode
end

return Statements
