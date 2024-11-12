--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Imports *--
local insert = table.insert

--* ScopeManager *--
local ScopeManager = {}

function ScopeManager:pushScope(isFunctionScope)
  local newScope = {
    locals = {},
    parent = self.currentScope,
    isFunctionScope = isFunctionScope
  }

  self.currentScope = newScope
  self.scopes[#self.scopes + 1] = newScope
end

function ScopeManager:popScope()
  if self.currentScope then
    self.currentScope = self.currentScope.parent
    self.scopes[#self.scopes] = nil
    return
  end
  error("Cannot pop scope, no scope to pop.")
end

return ScopeManager
