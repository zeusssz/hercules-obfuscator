--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local TokenFactory = require("Interpreter/LuaInterpreter/Lexer/TokenFactory")

--* Imports *--
local concat = table.concat
local insert = table.insert

local createEOFToken           = TokenFactory.createEOFToken
local createNewLineToken       = TokenFactory.createNewLineToken
local createVarArgToken        = TokenFactory.createVarArgToken
local createWhitespaceToken    = TokenFactory.createWhitespaceToken
local createCommentToken       = TokenFactory.createCommentToken
local createNumberToken        = TokenFactory.createNumberToken
local createConstantToken      = TokenFactory.createConstantToken
local createOperatorToken      = TokenFactory.createOperatorToken
local createKeywordToken       = TokenFactory.createKeywordToken
local createIdentifierToken    = TokenFactory.createIdentifierToken
local createCharacterToken     = TokenFactory.createCharacterToken
local createStringToken        = TokenFactory.createStringToken

local function shouldPlaceParenthesesOperator(node)
  local nodeType = node.TYPE
  if nodeType == "Variable" or nodeType == "Identifier"
      or nodeType == "Number" or nodeType == "String"
      or nodeType == "Constant" or nodeType == "Operator" then
        return false
  elseif nodeType == "Expression" then
    return shouldPlaceParenthesesOperator(node.Value)
  elseif nodeType == "Index" then
    return shouldPlaceParenthesesOperator(node.Expression)
  elseif nodeType == "FunctionCall" or nodeType == "MethodCall" then
    return shouldPlaceParenthesesOperator(node.Expression)
  end
  return true
end

local function shouldPlaceParentheses(node)
  local nodeType = node.TYPE
  if nodeType == "Variable" or nodeType == "Identifier" then
    return false
  elseif nodeType == "Expression" then
    return shouldPlaceParentheses(node.Value)
  elseif nodeType == "Index" then
    return shouldPlaceParenthesesOperator(node.Index)
  elseif nodeType == "FunctionCall" or nodeType == "MethodCall" then
    return shouldPlaceParentheses(node.Expression)
  end
  return true
end

--* NodeConverters *--
local NodeConverters = {}

--// Basic converters \\--

-- Number: { Value: "" }
function NodeConverters:Number(node)
  node.Line = nil
  insert(self.tokens, node)
end

-- String: { Value: "" }
function NodeConverters:String(node)
  node.Line = nil
  insert(self.tokens, node)
end

-- VarArg: {}
function NodeConverters:VarArg(node)
  insert(self.tokens, createVarArgToken())
end

-- Variable: { VariableType: "", Value: "" }
function NodeConverters:Variable(node)
  insert(self.tokens, createIdentifierToken(node.Value))
end

-- Identifier: { Value: "" }
function NodeConverters:Identifier(node)
  insert(self.tokens, createIdentifierToken(node.Value))
end

-- Constant: { Value: "" }
function NodeConverters:Constant(node)
  insert(self.tokens, createConstantToken(node.Value))
end

-- Operator: { Left: {}, Right: {}, Value: "" }
function NodeConverters:Operator(node)
  local addParenthesesLeft = node.Left.TYPE == "Expression"
  local addParenthesesRight = node.Right.TYPE == "Expression"
  if addParenthesesLeft then
    insert(self.tokens, createCharacterToken("("))
  end
  self:convertNode(node.Left)
  if addParenthesesLeft then
    insert(self.tokens, createCharacterToken(")"))
  end
  insert(self.tokens, createOperatorToken(node.Value))
  if addParenthesesRight then
    insert(self.tokens, createCharacterToken("("))
  end
  self:convertNode(node.Right)
  if addParenthesesRight then
    insert(self.tokens, createCharacterToken(")"))
  end
end

-- UnaryOperator: { Operand: {}, Value: "" }
function NodeConverters:UnaryOperator(node)
  local addParentheses = node.Operand.TYPE == "Expression"
  insert(self.tokens, createOperatorToken(node.Value))
  if addParentheses then
    insert(self.tokens, createCharacterToken("("))
  end
  self:convertNode(node.Operand)
  if addParentheses then
    insert(self.tokens, createCharacterToken(")"))
  end
end

-- FunctionCall: { Expression: {}, Arguments: {}, ExpectedReturnValueCount: 0 }
function NodeConverters:FunctionCall(node)
  local addParentheses = shouldPlaceParentheses(node.Expression)
  if addParentheses then
    insert(self.tokens, createCharacterToken("("))
  end
  self:convertNode(node.Expression)
  if addParentheses then
    insert(self.tokens, createCharacterToken(")"))
  end
  insert(self.tokens, createCharacterToken("("))
  self:convertNodeListWithSeparator(node.Arguments)
  insert(self.tokens, createCharacterToken(")"))
end

-- MethodCall: { Expression: {}, Arguments: {}, ExpectedReturnValueCount: 0 }
function NodeConverters:MethodCall(node)
  local expression = node.Expression
  local parentTable = expression.Expression
  local methodName = expression.Index.Value
  local addParentheses = shouldPlaceParentheses(parentTable)
  if addParentheses then
    insert(self.tokens, createCharacterToken("("))
  end
  self:convertNode(parentTable)
  if addParentheses then
    insert(self.tokens, createCharacterToken(")"))
  end
  insert(self.tokens, createCharacterToken(":"))
  insert(self.tokens, createIdentifierToken(methodName))
  insert(self.tokens, createCharacterToken("("))
  self:convertNodeListWithSeparator(node.Arguments)
  insert(self.tokens, createCharacterToken(")"))
end

-- Function: { Parameters: {}, IsVararg: "", CodeBlock: {} }
function NodeConverters:Function(node)
  insert(self.tokens, createKeywordToken("function"))
  self:convertFunctionParameters(node)
  self:convertNode(node.CodeBlock)
  insert(self.tokens, createKeywordToken("end"))
end

-- LocalFunction: { Name: {}, Parameters: {}, IsVararg: "", CodeBlock: {} }
function NodeConverters:LocalFunction(node)
  insert(self.tokens, createKeywordToken("local"))
  insert(self.tokens, createKeywordToken("function"))
  insert(self.tokens, createIdentifierToken(node.Name))
  self:convertFunctionParameters(node)
  self:convertNode(node.CodeBlock)
  insert(self.tokens, createKeywordToken("end"))
end

-- LocalVariableAssignment: { Variables: {}, Expressions: {} }
function NodeConverters:LocalVariableAssignment(node)
  insert(self.tokens, createKeywordToken("local"))
  for index, variable in ipairs(node.Variables) do
    insert(self.tokens, createIdentifierToken(variable))
    if index < #node.Variables then
      insert(self.tokens, createCharacterToken(","))
    end
  end
  if #node.Expressions > 0 then
    insert(self.tokens, createOperatorToken("="))
    self:convertNodeListWithSeparator(node.Expressions)
  end
end

-- FunctionDeclaration: { Fields: {}, Parameters: {}, IsVararg: "", CodeBlock: {} }
function NodeConverters:FunctionDeclaration(node)
  insert(self.tokens, createKeywordToken("function"))
  insert(self.tokens, createIdentifierToken(node.Expression.Value))
  if #node.Fields > 0 then
    insert(self.tokens, createCharacterToken("."))
  end
  for index, field in ipairs(node.Fields) do
    insert(self.tokens, createIdentifierToken(field))
    if index < #node.Fields then
      insert(self.tokens, createCharacterToken("."))
    end
  end
  self:convertFunctionParameters(node)
  self:convertNode(node.CodeBlock)
  insert(self.tokens, createKeywordToken("end"))
end

-- MethodDeclaration: { Fields: {}, Parameters: {}, IsVararg: "", CodeBlock: {} }
function NodeConverters:MethodDeclaration(node)
  insert(self.tokens, createKeywordToken("function"))
  insert(self.tokens, createIdentifierToken(node.Expression.Value))
  if #node.Fields > 1 then
    insert(self.tokens, createCharacterToken("."))
  else
    insert(self.tokens, createCharacterToken(":"))
  end
  for index, field in ipairs(node.Fields) do
    insert(self.tokens, createIdentifierToken(field))
    if index < (#node.Fields - 1) then
      insert(self.tokens, createCharacterToken("."))
    elseif index == (#node.Fields - 1) then
      insert(self.tokens, createCharacterToken(":"))
    end
  end
  self:convertFunctionParameters(node)
  self:convertNode(node.CodeBlock)
  insert(self.tokens, createKeywordToken("end"))
end

-- Table: { Elements: {} }
function NodeConverters:Table(node)
  insert(self.tokens, createCharacterToken("{"))
  self:convertNodeListWithSeparator(node.Elements)
  insert(self.tokens, createCharacterToken("}"))
end

-- TableElement: { Key: {}, Value: {}, ImplicitKey: false }
function NodeConverters:TableElement(node)
  if not node.ImplicitKey then
    if node.Key.TYPE == "String" then
      insert(self.tokens, createIdentifierToken(node.Key.Value))
    else
      insert(self.tokens, createCharacterToken("["))
      self:convertNode(node.Key)
      insert(self.tokens, createCharacterToken("]"))
    end
    insert(self.tokens, createOperatorToken("="))
  end
  self:convertNode(node.Value)
end

-- Index: { Expression: {}, Index: {} }
function NodeConverters:Index(node)
  local index = node.Index
  local indexValue = index.Value
  local expression = node.Expression
  local addParentheses = shouldPlaceParentheses(expression)
  if addParentheses then
    insert(self.tokens, createCharacterToken("("))
  end
  self:convertNode(node.Expression)
  if addParentheses then
    insert(self.tokens, createCharacterToken(")"))
  end
  if index.TYPE == "String" and indexValue:match("^[a-zA-Z_][%w_]*$") then
    insert(self.tokens, createCharacterToken("."))
    insert(self.tokens, createIdentifierToken(indexValue))
    return
  end
  insert(self.tokens, createCharacterToken("["))
  self:convertNode(node.Index)
  insert(self.tokens, createCharacterToken("]"))
end


return NodeConverters
