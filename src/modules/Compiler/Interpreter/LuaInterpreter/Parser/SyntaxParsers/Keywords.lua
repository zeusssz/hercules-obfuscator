--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local NodeFactory = require("Interpreter/LuaInterpreter/Parser/NodeFactory")

--* Imports *--
local insert = table.insert

--* NodeFactory functions imports *--
local createFunctionDeclarationNode     = NodeFactory.createFunctionDeclarationNode -- (parameters, isVararg, codeBlock, fields)
local createLocalVariableAssignmentNode = NodeFactory.createLocalVariableAssignmentNode -- (variables, expressions, metadata)
local createIfStatementNode             = NodeFactory.createIfStatementNode -- (condition, codeBlock, elseIfs, elseStatement)
local createElseIfStatementNode         = NodeFactory.createElseIfStatementNode -- (condition, codeBlock)
local createElseStatementNode           = NodeFactory.createElseStatementNode -- (codeBlock)
local createUntilLoopNode               = NodeFactory.createUntilLoopNode -- (codeBlock, statement)
local createDoBlockNode                 = NodeFactory.createDoBlockNode -- (codeBlock)
local createWhileLoopNode               = NodeFactory.createWhileLoopNode -- (expression, codeBlock)
local createReturnStatementNode         = NodeFactory.createReturnStatementNode -- (expressions)
local createContinueStatementNode       = NodeFactory.createContinueStatementNode -- ()
local createBreakStatementNode          = NodeFactory.createBreakStatementNode -- ()
local createGenericForNode              = NodeFactory.createGenericForNode -- (iteratorVariables, expressions, codeBlock)
local createNumericForNode              = NodeFactory.createNumericForNode -- (iteratorVariables, expressions, codeBlock)

--* Statements *--
local Keywords = {}

-- "return( <expression>(, <expression>)*)?"
Keywords["return"] = function(self)
  self:consume() -- Consume "return"
  local expressions = self:getExpressions()

  return createReturnStatementNode(expressions)
end

-- "break"
Keywords["break"] = function(self)
  return createBreakStatementNode()
end

-- "continue"
Keywords["continue"] = function(self)
  return createContinueStatementNode()
end

-- "repeat <codeblock> until <expression>"
Keywords["repeat"] = function(self)
  self:consume() -- Consume "repeat"
  local codeBlock = self:consumeCodeBlock()
  self:expectCurrentTokenAndConsume("Keyword", "until")
  local statement = self:getExpression()

  return createUntilLoopNode(codeBlock, statement)
end

-- "do <code_block> end"
Keywords["do"] = function(self)
  self:consume() -- Consume "do"
  local codeBlock = self:consumeCodeBlock()

  return createDoBlockNode(codeBlock)
end

-- "while <expression> do <code_block> end"
Keywords["while"] = function(self)
  self:consume() -- Consume "while"
  local expression = self:getExpression()
  self:expectNextTokenAndConsume("Keyword", "do")
  local codeBlock = self:consumeCodeBlock()

  return createWhileLoopNode(expression, codeBlock)
end

-- "local <identifier>(, <identifier>)* (= <expression>(, <expression>)*)?" |
-- "local function <identifier>(<args>) <code_block> end"
Keywords["local"] = function(self)
  if self:compareTokenValueAndType(self:peek(), "Keyword", "function") then
    return self:consumeLocalFunction()
  end
  self:consume() -- Consume "local"

  local identifiers = self:consumeMultipleIdentifiers(self, true)
  local nextToken = self:peek()
  if not self:compareTokenValueAndType(nextToken, "Character", "=") then
    local localVariableAssignmentNode = createLocalVariableAssignmentNode(identifiers)
    for _, identifier in ipairs(identifiers) do
      local variable = self:registerVariable(identifier)
      variable.DeclarationNode = localVariableAssignmentNode
    end
    return localVariableAssignmentNode
  end

  self:consume() -- Consume the last identifier
  self:expectCurrentTokenAndConsume("Character", "=")
  local expressions = self:getExpressions(nil, #identifiers)
  local localVariableAssignmentNode = createLocalVariableAssignmentNode(identifiers, expressions)
  for _, identifier in ipairs(identifiers) do
    local variable = self:registerVariable(identifier)
    variable.DeclarationNode = localVariableAssignmentNode
  end
  return localVariableAssignmentNode
end

-- "if <expression> then <codeblock>( elseif <expression> then <codeblock>)*( else <codeblock>)? end"
Keywords["if"] = function(self)
  self:consume() -- Consume "if"

  local expression = self:getExpression()
  self:expectNextTokenAndConsume("Keyword", "then")
  local ifStatementCodeBlock = self:consumeCodeBlock()
  local newIfStatement = createIfStatementNode(expression, ifStatementCodeBlock, {})

  -- Consume multiple "elseif" statements if there's any
  while self:compareTokenValueAndType(self.currentToken, "Keyword", "elseif") do
    self:consume() -- Consume "elseif"
    local elseIfCondition = self:getExpression()
    self:expectNextTokenAndConsume("Keyword", "then")
    local elseIfCodeBlock = self:consumeCodeBlock()
    insert(newIfStatement.ElseIfs, createElseIfStatementNode(elseIfCondition, elseIfCodeBlock))
  end
  -- Consume an optional "else" statement
  if self:compareTokenValueAndType(self.currentToken, "Keyword", "else") then
    self:consume() -- Consume "else"
    local elseCodeBlock = self:consumeCodeBlock()
    newIfStatement.Else = createElseStatementNode(elseCodeBlock)
  end

  return newIfStatement
end

-- "function <identifier>[. <identifier>]*[: <identifier>]?(<args>) <code_block> end"
Keywords["function"] = function(self, isLocal)
  self:consume() -- Consume "function"
  local variableNode, variable = self:convertIdentifierToVariableNode(self:expectCurrentToken("Identifier"))
  if variable then
    insert(variable.References, variableNode)
  end
  local expression = variableNode
  self:consume() -- Consume the first identifier field

  local currentToken = self.currentToken
  local fields = {}
  -- [. <identifier>]*
  while self:compareTokenValueAndType(currentToken, "Character", ".") do
    local previousToken = currentToken
    self:consume() -- Consume "."
    local identifier = self:expectCurrentToken("Identifier")
    insert(fields, identifier.Value)
    currentToken = self:consume() -- Consume field
  end
  -- [[: <identifier>](<args>) <code_block> end ]?
  if (not isLocal and self:compareTokenValueAndType(currentToken, "Character", ":")) then
    -- Consume it as a method declaration instead.
    return self:consumeMethod(expression, fields)
  end

  self:expectCurrentTokenAndConsume("Character", "(")
  self:pushScope(true) -- Function scope
  local parameters, isVararg, variables = self:consumeFunctionParameters()
  self:expectCurrentTokenAndConsume("Character", ")")
  local codeBlock = self:consumeCodeBlock(nil, true)
  self:popScope() -- Function scope
  local functionDeclarationNode = createFunctionDeclarationNode(parameters, isVararg, codeBlock, expression, fields)
  for _, variable in ipairs(variables) do
    variable.DeclarationNode = functionDeclarationNode
  end
  return functionDeclarationNode
end

-- "for <identifier>(, <identifier>)* in <expression> do <codeblock> end" |
-- "for <identifier> = <expression>, <expression>(, <expression>)? do <codeblock> end"
Keywords["for"] = function(self)
  self:consume() -- Consume "for"
  local iteratorVariables = {self:expectCurrentToken("Identifier").Value}
  -- <identifier>(, <identifier>)*
  while self:compareTokenValueAndType(self:consume(), "Character", ",")  do
    insert(iteratorVariables, self:expectNextToken("Identifier").Value)
  end
  if #iteratorVariables > 1 or self:compareTokenValueAndType(self.currentToken, "Keyword", "in") then
    -- Generic loop
    self:expectCurrentTokenAndConsume("Keyword", "in")
    local expressions = self:getExpressions()
    self:expectNextTokenAndConsume("Keyword", "do")
    local variables = {}
    for index, identifierValue in ipairs(iteratorVariables) do
      local variable = self:registerVariable(identifierValue)
      insert(variables, variable)
    end
    local codeBlock = self:consumeCodeBlock()
    local genericForNode = createGenericForNode(iteratorVariables, expressions, codeBlock)
    for _, variable in ipairs(variables) do
      variable.DeclarationNode = genericForNode
    end
    return genericForNode
  elseif self:expectCurrentToken("Character", "=") then
    -- Numeric loop
    self:expectCurrentTokenAndConsume("Character", "=")
    local expressions = self:getExpressions(3)
    self:expectNextTokenAndConsume("Keyword", "do")
    local variables = {}
    for index, identifierValue in ipairs(iteratorVariables) do
      local variable = self:registerVariable(identifierValue)
      insert(variables, variable)
    end
    local codeBlock = self:consumeCodeBlock()
    local numericForNode = createNumericForNode(iteratorVariables, expressions, codeBlock)
    for _, variable in ipairs(variables) do
      variable.DeclarationNode = numericForNode
    end
    return numericForNode
  end
end

return Keywords
