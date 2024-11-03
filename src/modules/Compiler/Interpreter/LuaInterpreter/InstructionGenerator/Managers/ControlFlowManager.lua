--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Imports *--
local insert = table.insert
local remove = table.remove

--* ControlFlowManager *--
local ControlFlowManager = {}

function ControlFlowManager:pushControlFlow()
  local newControlFlow = {
    breakJumps = {},
    continueJumps = {},
    parent = self.currentControlFlow,
  }

  self.currentControlFlow = newControlFlow
  self.controlFlows[#self.controlFlows + 1] = newControlFlow
  return newControlFlow
end

function ControlFlowManager:popControlFlow()
  local currentControlFlow = self.currentControlFlow
  if currentControlFlow then
    self.currentControlFlow = currentControlFlow.parent
    self.controlFlows[#self.controlFlows] = nil
    return
  end

  error("No control flow to pop")
end

function ControlFlowManager:registerBreakJump(jump)
  local currentControlFlow = self.currentControlFlow
  insert(currentControlFlow.breakJumps, jump)
end

function ControlFlowManager:registerContinueJump(jump)
  local currentControlFlow = self.currentControlFlow
  insert(currentControlFlow.continueJumps, jump)
end

return ControlFlowManager
