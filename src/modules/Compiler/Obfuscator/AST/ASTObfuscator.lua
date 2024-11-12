--* Dependencies *--

local LuaInterpreter = require("Interpreter/LuaInterpreter/LuaInterpreter")

local NodeSpecs = require("Interpreter/LuaInterpreter/Parser/NodeSpecs")
local ConstantsObfuscator = require("Obfuscator/AST/ConstantsObfuscator/ConstantsObfuscator")
local StatementObfuscator = require("Obfuscator/AST/StatementObfuscator/StatementObfuscator")

local NodeFactory = LuaInterpreter.modules.NodeFactory
local LuaExpressionEvaluator = LuaInterpreter.modules.LuaExpressionEvaluator

--* Imports *--
local insert = table.insert
local random = math.random

local numbersObfuscators = ConstantsObfuscator.Numbers
local stringsObfuscators = ConstantsObfuscator.Strings

--* Constants *--
local DEFAULT_CONFIG = {
  obfuscateConstants  = true,
  obfuscateStatements = true
}

--* Local functions *--
local function deepCopyTable(table)
  local copy = {}
  for index, value in pairs(table) do
    if type(value) == "table" then
      copy[index] = deepCopyTable(value)
    else
      copy[index] = value
    end
  end
  return copy
end

--* ASTObfuscatorMethods *--
local ASTObfuscatorMethods = {}

function ASTObfuscatorMethods:clearNode(node)
  for i in pairs(node) do
    node[i] = nil
  end
end

function ASTObfuscatorMethods:evaluateExpression(node)
  return LuaExpressionEvaluator.evaluate(node)
end

function ASTObfuscatorMethods:traverseNode(node)
  local function traverseNode(node)
    if not node then return end
    local nodeType = node.TYPE
    local nodeSpec = NodeSpecs[nodeType]

    local obfuscatorTable = StatementObfuscator[nodeType]
    if obfuscatorTable then
      local randomObfuscator = obfuscatorTable[random(1, #obfuscatorTable)]
      local templateString = randomObfuscator.String
      local interpretedString = templateString and deepCopyTable(templateString)
      return randomObfuscator.Function(self, node, interpretedString)
    elseif not nodeSpec then
      error("NodeSpec not found for node type: ".. nodeType)
    end

    for fieldName, fieldType in pairs(nodeSpec) do
      if fieldType == "Node" then
        traverseNode(node[fieldName])
      elseif fieldType == "OptionalNode" then
        if node[fieldName] then
          traverseNode(node[fieldName])
        end
      elseif fieldType == "NodeList" then
        for index, childNode in ipairs(node[fieldName]) do
          traverseNode(childNode)
        end
      end
    end
  end

  return traverseNode(node)
end

function ASTObfuscatorMethods:obfuscateCodeBlock(list)
  for index, node in ipairs(list) do
    self:traverseNode(node)
  end
  return list
end

function ASTObfuscatorMethods:obfuscateConstant(node)
  local nodeType = node.TYPE
  if nodeType == "Number" then
    while true do
      local randomObfuscator = numbersObfuscators[random(1, #numbersObfuscators)]
      local templateString = randomObfuscator.String
      local interpretedString = templateString and deepCopyTable(templateString)
      local successful = randomObfuscator.Function(self, node, interpretedString)
      if successful then
        return
      end
    end
  elseif nodeType == "String" then
    while true do
      local randomObfuscator = stringsObfuscators[random(1, #stringsObfuscators)]
      local templateString = randomObfuscator.String
      local interpretedString = templateString and deepCopyTable(templateString)
      local successful = randomObfuscator.Function(self, node, interpretedString)
      if successful then
        return
      end
    end
  end
end

function ASTObfuscatorMethods:obfuscateConstants()
  local constants = self.ast._metadata.constants
  for index, constantNode in ipairs(constants) do
    self:obfuscateConstant(constantNode)
  end
end

function ASTObfuscatorMethods:obfuscate()
  if self.config.obfuscateConstants  then self:obfuscateConstants(self.ast) end
  if self.config.obfuscateStatements then self:obfuscateCodeBlock(self.ast) end

  return self.ast
end

--* ASTObfuscator *--
local ASTObfuscator = {}
function ASTObfuscator:new(ast, config)
  local ASTObfuscatorInstance = {}
  ASTObfuscatorInstance.ast = ast
  ASTObfuscatorInstance.cachedStrings = {}
  ASTObfuscatorInstance.config = config or DEFAULT_CONFIG

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if ASTObfuscatorInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and ASTObfuscatorInstance: " .. index)
      end
      ASTObfuscatorInstance[index] = value
    end
  end

  -- Main
  inheritModule("ASTObfuscatorMethods", ASTObfuscatorMethods)

  return ASTObfuscatorInstance
end

return ASTObfuscator
