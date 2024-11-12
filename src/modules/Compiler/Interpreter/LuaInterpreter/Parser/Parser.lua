--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--// Node modules //--
local NodeFactory = require("Interpreter/LuaInterpreter/Parser/NodeFactory")
local NodeSpecs = require("Interpreter/LuaInterpreter/Parser/NodeSpecs")

--// Managers //--
local ScopeManager    = require("Interpreter/LuaInterpreter/Parser/Managers/ScopeManager")
local VariableManager = require("Interpreter/LuaInterpreter/Parser/Managers/VariableManager")

--// Utility parsers //--
local LuaMathParser = require("Interpreter/LuaInterpreter/Parser/LuaMathParser/LuaMathParser")

--// Syntax parsers //--
local Keywords   = require("Interpreter/LuaInterpreter/Parser/SyntaxParsers/Keywords")
local Statements = require("Interpreter/LuaInterpreter/Parser/SyntaxParsers/Statements")

--* Imports *--
local stringifyTable = Helpers.stringifyTable
local find = table.find or Helpers.tableFind
local insert = table.insert
local unpack = (unpack or table.unpack)

local createASTNode            = NodeFactory.createASTNode            -- (...)
local createLocalVariableNode  = NodeFactory.createLocalVariableNode  -- (value)
local createGlobalVariableNode = NodeFactory.createGlobalVariableNode -- (value)
local createUpvalueNode        = NodeFactory.createUpvalueNode        -- (value, upvalueLevel)

--* Constants *--
local EOF_TOKEN = { TYPE = "EOF" }
local STOP_KEYWORDS_LOOKUP_TABLE = {
  ["end"]    = true,
  ["else"]   = true,
  ["elseif"] = true,
  ["until"]  = true
}

--* ParserMethods *--
local ParserMethods = {}

--/////// Token Traversal ///////--

function ParserMethods:peek(n)
  return self.tokens[self.currentTokenIndex + (n or 1)]
end

function ParserMethods:consume(n)
  self.currentTokenIndex = self.currentTokenIndex + (n or 1)
  self.currentToken = self.tokens[self.currentTokenIndex]
  return self.currentToken
end

--/////// Expression Helpers ///////--

function ParserMethods:compareTokenValueAndType(token, type, value)
  return token
          and (not type  or type  == token.TYPE)
          and (not value or value == token.Value)
end

--/////// Expect Helpers ///////--

function ParserMethods:expectCurrentToken(tokenType, tokenValue)
  local currentToken = self.currentToken
  if currentToken then
    if (not tokenType) or currentToken.TYPE == tokenType then
      if (not tokenValue) or currentToken.Value == tokenValue then
        return currentToken
      end
    end
  end

  error("Unexpected token at: " .. (currentToken and currentToken.Value or "EOF"))
end

function ParserMethods:expectNextToken(tokenType, tokenValue)
  self:consume()
  return self:expectCurrentToken(tokenType, tokenValue)
end

function ParserMethods:expectCurrentTokenAndConsume(tokenType, tokenValue)
  self:expectCurrentToken(tokenType, tokenValue)
  return self:consume()
end

function ParserMethods:expectNextTokenAndConsume(tokenType, tokenValue)
  self:expectNextToken(tokenType, tokenValue)
  return self:consume()
end

--/////// Utility Functions ///////--

--- Converts an identifier token to a variable node.
function ParserMethods:convertIdentifierToVariableNode(token)
  local tokenValue = token.Value

  local variableType, upvalueIndex, currentScopeVariable = self:getVariableType(tokenValue)
  local variable
  if variableType == "Local" then
    variable = createLocalVariableNode(tokenValue)
  elseif variableType == "Global" then
    variable = createGlobalVariableNode(tokenValue)
  elseif variableType == "Upvalue" then
    variable = createUpvalueNode(tokenValue, upvalueIndex)
  end

  -- Add some metadata to the variable node
  if self.includeMetadata then
    variable._Variable = currentScopeVariable
  end
  return variable, currentScopeVariable
end

--/////// General ///////--

function ParserMethods:getNextNode()
  --[[
    codeBlock:
      // Note: After each non-terminal, there may be an optional semicolon.
      <codeBlock> ::= ( <functionCall> | <statement> | <variableAssignment> ) ;?
  --]]

  local currentToken = self.currentToken
  local tokenValue, tokenType = currentToken.Value, currentToken.TYPE

  -- <statement>
  if tokenType == "Keyword" then
    if STOP_KEYWORDS_LOOKUP_TABLE[tokenValue] then
      return nil
    end

    local keywordFunction = self[tokenValue]
    local returnValue = keywordFunction(self)
    self:consumeNextOptionalSemicolon()
    return returnValue
  end

  -- <functionCall> | <variableAssignment>
  local returnValue = self:parseFunctionCallOrVariableAssignment()
  self:consumeNextOptionalSemicolon()
  return returnValue
end

function ParserMethods:consumeCodeBlock(isFunction, dontPushScope)
  if not dontPushScope then self:pushScope(isFunction) end

  local codeblock, codeblockIndex = {}, 1
  local currentToken = self.currentToken
  while currentToken do
    local astNode = self:getNextNode()
    if not astNode then break end

    codeblock[codeblockIndex] = astNode
    codeblockIndex = codeblockIndex + 1
    currentToken = self:consume()
  end

  if not dontPushScope then self:popScope() end
  return codeblock
end

function ParserMethods:setParents(node, parent)
  local function setParents(node, parent)
    node.Parent = parent
    local nodeSpec = NodeSpecs[node.TYPE]
    for fieldName, fieldType in pairs(nodeSpec) do
      if fieldType == "Node" or fieldType == "OptionalNode" then
        local child = node[fieldName]
        if child then
          setParents(child, node)
        end
      elseif fieldType == "NodeList" then
        for index, child in ipairs(node[fieldName]) do
          setParents(child, node)
        end
      end
    end
  end

  return setParents(node, parent)
end

--/////// Main ///////--

function ParserMethods:parse()
  local globalScope = self:pushScope()
  local ast = self:consumeCodeBlock(false, true)
  self:popScope()
  assert((#self.scopes == 0 and not self.currentScope), "ScopeManager did not pop all scopes")

  local ast = createASTNode(unpack(ast))
  if self.includeMetadata then
    ast._metadata = {
      variables = self.variables,
      globals = self.globals,
      constants = self.constants,
      globalScope = globalScope
    } --[[
    for index, value in ipairs(ast) do
      self:setParents(value, ast)
    end --]]
  end

  return ast
end

--- Resets the parser to its initial state so it can be reused.
-- @param tokens The tokens to reset the parser to.
function ParserMethods:resetToInitialState(tokens, includeMetadata)
  self.tokens = tokens
  self.currentToken = tokens and tokens[1]
  self.currentTokenIndex = 1
  self.expectedReturnValueCount = 0
  self.includeMetadata = (includeMetadata == nil and true) or includeMetadata
  -- ScopeManager/VariableManager fields
  self.scopes = {}
  self.currentScope = nil
  -- VariableManager-only fields
  self.variables = {}
  self.registeredGlobals = {}
  self.globals = {}
  self.constants = {}
end

--* Parser *--
local Parser = {}
function Parser:new(tokens, includeMetadata)
  local ParserInstance = {}
  ParserInstance.tokens = tokens
  ParserInstance.currentToken = tokens and tokens[1]
  ParserInstance.currentTokenIndex = 1
  ParserInstance.expectedReturnValueCount = 0
  ParserInstance.includeMetadata = (includeMetadata == nil and true) or includeMetadata
  -- ScopeManager/VariableManager fields
  ParserInstance.scopes = {}
  ParserInstance.currentScope = nil
  -- VariableManager-only fields
  ParserInstance.variables = {}
  ParserInstance.registeredGlobals = {}
  ParserInstance.globals = {}
  ParserInstance.constants = {}

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if ParserInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and ParserInstance: " .. index)
      end
      ParserInstance[index] = value
    end
  end

  -- Main
  inheritModule("ParserMethods", ParserMethods)

  -- Parsers
  inheritModule("LuaMathParser", LuaMathParser)
  inheritModule("Statements", Statements)
  inheritModule("Keywords", Keywords)

  -- Managers
  inheritModule("ScopeManager", ScopeManager)
  inheritModule("VariableManager", VariableManager)

  return ParserInstance
end

return Parser
