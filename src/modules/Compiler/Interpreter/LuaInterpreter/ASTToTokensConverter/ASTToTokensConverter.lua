--* Dependencies *--
local Helpers = require("Helpers/Helpers")

local NodeTemplates  = require("Interpreter/LuaInterpreter/ASTToTokensConverter/Converters/NodeTemplates")
local NodeConverters = require("Interpreter/LuaInterpreter/ASTToTokensConverter/Converters/NodeConverters")
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

--* ASTToTokensConverterMethods *--
local ASTToTokensConverterMethods = {}

function ASTToTokensConverterMethods:applyConversionRule(node, rule)
  local ruleType = rule.TYPE
  local ruleValue = rule.Value

  if ruleType == "Keyword" then
    return insert(self.tokens, createKeywordToken(ruleValue))
  elseif ruleType == "Character" then
    return insert(self.tokens, createCharacterToken(ruleValue))
  elseif ruleType == "ParsedExpression" then
    return self:convertNode(node[ruleValue])
  elseif ruleType == "ParsedBlock" then
    return self:convertNode(node[ruleValue])
  elseif ruleType == "Identifier" then
    return insert(self.tokens, createIdentifierToken(node[ruleValue]))
  elseif ruleType == "ParsedExpressions" then
    for _, exprNode in ipairs(node[ruleValue]) do
      self:convertNode(exprNode)
    end
  elseif ruleType == "ParsedExpressionsWithCommas" then
    for index, exprNode in ipairs(node[ruleValue]) do
      self:convertNode(exprNode)
      if index < #node[ruleValue] then
        insert(self.tokens, createCharacterToken(","))
      end
    end
  elseif ruleType == "IdentifierList" then
    for _, idNode in ipairs(node[ruleValue]) do
      self:convertNode(idNode)
    end

  elseif ruleType == "StringIdentifierList" then
    for _, idNode in ipairs(node[ruleValue]) do
      insert(self.tokens, createIdentifierToken(idNode))
    end
  elseif ruleType == "StringIdentifierListWithCommas" then
    for index, idNode in ipairs(node[ruleValue]) do
      insert(self.tokens, createIdentifierToken(idNode))
      if index < #node[ruleValue] then
        insert(self.tokens, createCharacterToken(","))
      end
    end

  elseif ruleType == "VariableList" then
    for _, varNode in ipairs(node[ruleValue]) do
      self:convertNode(varNode)
    end
  elseif ruleType == "ParsedElseIfs" then
    if node[ruleValue] then -- If there are elseifs
      for _, elseIfNode in ipairs(node[ruleValue]) do
        self:convertNode(elseIfNode)
      end
    end
  elseif ruleType == "ParsedElse" then
    if node[ruleValue] then -- If there is an else
      self:convertNode(node[ruleValue])
    end
  else error("Invalid conversion rule type: " .. tostring(ruleType)) end
end

function ASTToTokensConverterMethods:convertNode(node)
  if not node then return end
  local nodeType = node.TYPE

  if nodeType == "Group" then
    return self:convertNodeList(node)
  end
  while nodeType == "Expression" do
    node = node.Value
    nodeType = node.TYPE
  end
  if not nodeType then return end

  local nodeTemplate = NodeTemplates[nodeType]
  if not nodeTemplate then
    local nodeConverter = NodeConverters[nodeType]
    assert(nodeConverter, "No template or converter found for node type: " .. tostring(nodeType))
    return nodeConverter(self, node)
  end
  for index, conversionRule in ipairs(nodeTemplate) do
    self:applyConversionRule(node, conversionRule)
  end
end

function ASTToTokensConverterMethods:convertNodeList(nodeList)
  for _, node in ipairs(nodeList) do
    self:convertNode(node)
    -- insert(self.tokens, createCharacterToken(";"))
  end
end

function ASTToTokensConverterMethods:convertNodeListWithSeparator(nodeList)
  local tokens = self.tokens
  for index, node in ipairs(nodeList) do
    self:convertNode(node)
    if index < #nodeList then
      insert(tokens, createCharacterToken(","))
    end
  end
end

function ASTToTokensConverterMethods:convertFunctionParameters(node)
  local parameters = node.Parameters
  local tokens = self.tokens
  local vararg = node.IsVararg

  insert(tokens, createCharacterToken("("))

  for index, parameter in ipairs(parameters) do
    local token = createIdentifierToken(parameter)
    insert(tokens, token)

    if (index < #parameters) or vararg then
      insert(tokens, createCharacterToken(","))
    end
  end
  if vararg then
    insert(tokens, createVarArgToken(vararg))
  end

  insert(tokens, createCharacterToken(")"))
end

--// Main \\--
function ASTToTokensConverterMethods:convert()
  self:convertNodeList(self.ast)
  return self.tokens
end

--* ASTToTokensConverter *--
local ASTToTokensConverter = {}
function ASTToTokensConverter:new(ast)
  local ASTToTokensConverterInstance = {}
  ASTToTokensConverterInstance.ast = ast
  ASTToTokensConverterInstance.tokens = {}
  ASTToTokensConverterInstance.configRules = {
    useSemicolonsInsteadOfCommasInTable = false,
  }

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if ASTToTokensConverterInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and ASTToTokensConverterInstance: " .. index)
      end
      ASTToTokensConverterInstance[index] = value
    end
  end

  -- Main
  inheritModule("ASTToTokensConverterMethods", ASTToTokensConverterMethods)

  return ASTToTokensConverterInstance
end

return ASTToTokensConverter
