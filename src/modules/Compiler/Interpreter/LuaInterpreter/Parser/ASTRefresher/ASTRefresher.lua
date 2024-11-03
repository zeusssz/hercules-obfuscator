--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--// Node modules //--
local NodeSpecs = require("Interpreter/LuaInterpreter/Parser/NodeSpecs")
local NodeFactory = require("Interpreter/LuaInterpreter/Parser/NodeFactory")

--// Managers //--
local ScopeManager    = require("Interpreter/LuaInterpreter/Parser/Managers/ScopeManager")
local VariableManager = require("Interpreter/LuaInterpreter/Parser/Managers/VariableManager")

--* Imports *--
local insert = table.insert

--* Constants *--
local FUNCTION_NODES_LOOKUP = {
  Function            = true,
  FunctionDeclaration = true,
  MethodDeclaration   = true,
  LocalFunction       = true
}

--* ASTRefresherMethods *--
local ASTRefresherMethods = {}

function ASTRefresherMethods:refreshNode(node)
  local function refreshNode(node)
    local nodeType = node.TYPE
    local isFunctionNode = (FUNCTION_NODES_LOOKUP[nodeType] == true)
  
    if nodeType == "String" or nodeType == "Number" then
      insert(self.constants, node)
    elseif nodeType == "Variable" then
      local nodeVariableType = node.VariableType

      local variableType, upvalueIndex, currentScopeVariable = self:getVariableType(node.Value)
      if nodeVariableType and (variableType ~= nodeVariableType) then
        print(nodeVariableType, variableType, node.Value)
        error("huh?")
      end

      insert(currentScopeVariable.References, node)

    elseif nodeType == "LocalVariableAssignment" then
      for index, variableName in ipairs(node.Variables) do
        local variable = self:registerVariable(variableName)
        variable.DeclarationNode = node
      end
    elseif node.IteratorVariables then
      for index, value in ipairs(node.IteratorVariables) do
        local variable = self:registerVariable(value)
        variable.DeclarationNode = node
      end
    elseif nodeType == "MethodDeclaration" then
      local variable = self:registerVariable("self")
      variable.DeclarationNode = node
    elseif nodeType == "LocalFunction" then
      local variable = self:registerVariable(node.Name)
      variable.DeclarationNode = node
    end

    if node.Parameters then
      for index, parameter in ipairs(node.Parameters) do
        local variable = self:registerVariable(parameter)
        variable.DeclarationNode = node
      end
    end

    local nodeSpec = NodeSpecs[nodeType]

    for nodeField, fieldType in pairs(nodeSpec) do
      local isCodeBlock = nodeField == "CodeBlock"
      local fieldValue = node[nodeField]

      if isCodeBlock then
        self:pushScope(isFunctionNode)
      end

      if fieldType == "Node" then
        refreshNode(fieldValue)
      elseif fieldType == "OptionalNode" and fieldValue then
        refreshNode(fieldValue)
      elseif fieldType == "NodeList" then
        for index, childNode in ipairs(fieldValue) do
          refreshNode(childNode)
        end
      end

      if isCodeBlock then
        self:popScope(isFunctionNode)
      end
    end
  end

  return refreshNode(node)
end

--- Updates the AST to make it use correct variable scopes, etc.
-- @param ast The AST to update.
-- @return The updated AST.
function ASTRefresherMethods:refresh()
  local ast = self.ast
  ast.metadata = {}

  local globalScope = self:pushScope()
  for index, node in ipairs(ast) do
    self:refreshNode(node)
  end
  self:popScope()

  ast.metadata = {
    constants = self.constants,
    variables = self.variables,
    globals = self.globals,
    globalScope = globalScope
  }

  return ast
end

--* ASTRefresher *--
local ASTRefresher = {}
function ASTRefresher:new(ast, excludeMetadata)
  local ASTRefresherInstance = {}
  ASTRefresherInstance.ast = ast
  ASTRefresherInstance.constants = {}

  -- ScopeManager/VariableManager fields
  ASTRefresherInstance.scopes = {}
  ASTRefresherInstance.currentScope = nil
  -- VariableManager-only fields
  ASTRefresherInstance.variables = {}
  ASTRefresherInstance.registeredGlobals = {}
  ASTRefresherInstance.globals = {}
  ASTRefresherInstance.constants = {}

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if ASTRefresherInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and ASTRefresherInstance: " .. index)
      end
      ASTRefresherInstance[index] = value
    end
  end

  -- Main methods
  inheritModule("ASTRefresherMethods", ASTRefresherMethods)

  -- Managers
  inheritModule("ScopeManager", ScopeManager)
  inheritModule("VariableManager", VariableManager)

  return ASTRefresherInstance
end

return ASTRefresher
