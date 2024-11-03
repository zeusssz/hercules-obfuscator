--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Imports *--
local insert = table.insert

--* VariableManager *--
local VariableManager = {}

function VariableManager:registerVariable(variableName)
  local currentScope = self.currentScope
  local variable = {
    Name = variableName,
    Scope = currentScope,
    DeclarationNode = nil,
    AssignmentNodes = {},
    References = {},
    TYPE = "Local"
  }

  currentScope.locals[variableName] = variable
  insert(self.variables, variable)
  return variable
end

function VariableManager:registerGlobalVariable(variableName)
  local globalScope = self.scopes[1]
  local variable = self.registeredGlobals[variableName] or {
    Name = variableName,
    Scope = globalScope,
    DeclarationNodes = {},
    References = {},
    TYPE = "Global"
  }

  if not self.registeredGlobals[variableName] then
    self.registeredGlobals[variableName] = variable
    insert(self.globals, variable)
  end
  return variable
end

function VariableManager:registerVariables(variableNames)
  for _, variableName in ipairs(variableNames) do
    self:registerVariable(variableName)
  end
end

function VariableManager:getVariableType(variableName)
  local currentScope = self.currentScope
  local upvalueLevel = 0

  while currentScope do
    local currentScopeLocals = currentScope.locals
    local currentScopeParent = currentScope.parent
    local isFunctionScope    = currentScope.isFunctionScope

    local currentScopeVariable = currentScopeLocals[variableName]
    if currentScopeVariable then
      return (upvalueLevel == 0 and "Local") or "Upvalue", upvalueLevel, currentScopeVariable
    elseif isFunctionScope then
      upvalueLevel = upvalueLevel + 1
    end

    currentScope = currentScope.parent
  end

  return "Global", 0, self:registerGlobalVariable(variableName)
end

return VariableManager
