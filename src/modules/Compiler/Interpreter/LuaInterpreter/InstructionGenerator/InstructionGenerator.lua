--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--// Compilers //--
local Instructions = require("Interpreter/LuaInterpreter/InstructionGenerator/Instructions")
local StatementCompiler = require("Interpreter/LuaInterpreter/InstructionGenerator/NodeCompilers/StatementCompiler")
local ExpressionCompiler = require("Interpreter/LuaInterpreter/InstructionGenerator/NodeCompilers/ExpressionCompiler")
-- local Compiler = require("Interpreter/LuaInterpreter/InstructionGenerator/Compiler/Compiler")

--// Managers //--
local ScopeManager = require("Interpreter/LuaInterpreter/InstructionGenerator/Managers/ScopeManager")
local ProtoManager = require("Interpreter/LuaInterpreter/InstructionGenerator/Managers/ProtoManager")
local ControlFlowManager = require("Interpreter/LuaInterpreter/InstructionGenerator/Managers/ControlFlowManager")

--* Imports *--
local stringifyTable = Helpers.stringifyTable
local find = table.find or Helpers.tableFind
local insert = table.insert

--* InstructionGeneratorMethods *--
local InstructionGeneratorMethods = {}

--////// Register stuff //////--

-- Get the lowest register that is not marked as used yet.
-- We don't use #self.registers, because it's
-- not guaranteed for registers to be consecutive (which is bad of course)
function InstructionGeneratorMethods:getNextFreeRegister()
  local registers = self.registers
  local curIndex = 0
  while registers[curIndex] do
    curIndex = curIndex + 1
  end
  return curIndex
end

-- Mark a register as taken
-- it doesn't actually hold a value, it's just an attempt of static analysis
function InstructionGeneratorMethods:allocateRegister()
  local registerIndex = self:getNextFreeRegister()
  self.registers[registerIndex] = true
  return registerIndex
end

-- Mark a register as free
-- It allows to pass constant indices as well, but they are ignored
function InstructionGeneratorMethods:deallocateRegister(registerIndex)
  if not registerIndex then return end

  -- Check if it's a local variable
  if self:getRegisterVariable(registerIndex) then
    return
  end

  -- "Registers" with the index smaller than 0 are constants
  -- We don't deallocate constants
  if registerIndex < 0 then return end

  self.registers[registerIndex] = nil
end

-- Mark a list of registers as free
-- It allows to pass constant indices as well, but they are ignored
function InstructionGeneratorMethods:deallocateRegisters(registers)
  for _, register in ipairs(registers) do
    self:deallocateRegister(register)
  end
end

-- Mark a register as temporarily taken
function InstructionGeneratorMethods:allocateTemporaryRegister()
  local registerIndex = self:allocateRegister()
  insert(self.temporaryRegisters, registerIndex)
  return registerIndex
end

-- Clear all temporary registers
function InstructionGeneratorMethods:clearTemporaryRegisters()
  self:deallocateRegisters(self.temporaryRegisters)
  self.temporaryRegisters = {}
end

-- Error if there are any temporary registers left
function InstructionGeneratorMethods:checkForLeaks()
  if #self.temporaryRegisters > 0 then
    return error("Temporary registers leaked: " .. stringifyTable(self.temporaryRegisters))
  end
end

--////// Scope stuff //////--

-- Add a constant to the constant table, if it's not already there.
-- Returns the index of the constant.
function InstructionGeneratorMethods:findOrAddConstant(constantValue)
  local constants = self.currentProto.constants
  local constantIndex = find(constants, constantValue)
  if not constantIndex then
    insert(constants, constantValue)
    constantIndex = #constants
  end
  return -constantIndex
end

-- Save the current state
function InstructionGeneratorMethods:saveState()
  return {
    currentProto = self.currentProto,
    currentControlFlow = self.currentControlFlow,
    registers = self.registers,
    temporaryRegisters = self.temporaryRegisters
  }
end

-- Restore a previously saved state
function InstructionGeneratorMethods:restoreState(savedState)
  self.currentProto = savedState.currentProto
  self.currentControlFlow = savedState.currentControlFlow
  self.registers = savedState.registers
  self.temporaryRegisters = savedState.temporaryRegisters
end

--////// Closure stuff //////--

-- Generate a proto for a function
function InstructionGeneratorMethods:compileLuaFunction(node, closureRegister)
  local codeBlock = node.CodeBlock
  local parameters = node.Parameters
  local isVararg = node.IsVararg
  local closureRegister = closureRegister or self:allocateRegister()
  local savedState = self:saveState()

  local functionProto = self:pushProto()
  functionProto.numParmas = #parameters
  functionProto.isVararg = isVararg
  functionProto.parameters = parameters

  self.currentProto = functionProto
  self.currentControlFlow = nil
  self.registers = {}
  self.temporaryRegisters = {}

  -- Put parameters into the local scope
  for index, parameter in ipairs(parameters) do
    self:registerVariable(parameter, index - 1)
  end

  self:processCodeBlock(codeBlock)
  self:restoreState(savedState)

  insert(self.currentProto.protos, functionProto)

  -- OP_CLOSURE A Bx    R(A) := closure(KPROTO[Bx])
  self:addInstruction("CLOSURE", closureRegister, #self.currentProto.protos)

  -- Instructions generated here are being mostly* skipped in the VM
  -- * only the OP_CLOSURE reads them, and they are not executed.
  for upvalueName, _ in pairs(functionProto.upvalues) do
    if self:isLocalVariable(upvalueName) then
      local upvalueRegister = self:getLocalRegister(upvalueName)
      self:addInstruction("MOVE", 0, upvalueRegister)
    else
      local upvalueRegister = self:findOrCreateUpvalue(upvalueName)
      self:addInstruction("GETUPVAL", 0, upvalueRegister)
    end
  end

  return functionProto, closureRegister
end

--////// Expression stuff //////--

-- Process an expression node (e.g. Identifier, Number, Operator)
function InstructionGeneratorMethods:processExpressionNode(node, canReturnConstantIndex, returnGeneratedInstructions, forcedResultRegister)
  local nodeType = node.TYPE
  local oldInstructionCount = #self.currentProto.instructions

  -- Since "Expression" is just a placeholder node for expressions
  -- we can skip it, so we take the child (Value) node instead.
  while (nodeType == "Expression") do
    node = node.Value
    nodeType = node.TYPE
  end

  local expressionMethod = self.expressions[nodeType]

  if not expressionMethod then
    return error("Unsupported expression node type: " .. nodeType)
  end

  local returnRegister = expressionMethod(self, node, canReturnConstantIndex, forcedResultRegister)

  -- Check for leaks, all node methods must clear
  -- their temporary registers before returning
  self:checkForLeaks()

  if forcedResultRegister and forcedResultRegister ~= returnRegister then
    -- This shouldn't really happen, instead of using this,
    -- the mapped node compiling functions should be used.
    self:addInstruction("MOVE", forcedResultRegister, returnRegister)
    returnRegister = forcedResultRegister

    -- print("Warning: Forced result register was used, this shouldn't happen!")
  end

  if returnGeneratedInstructions then
    local newInstructionCount = #self.currentProto.instructions
    local generatedInstructions = self:getInstructionsFromRange(oldInstructionCount + 1, newInstructionCount)
    return returnRegister, generatedInstructions
  end

  return returnRegister
end

--////// Condition stuff //////--

-- Process a condition node (e.g. >=, <=, == in if statements/etc)
-- It always returns instructions
function InstructionGeneratorMethods:processConditionNode(node, forcedResultRegister)
  local nodeType = node.TYPE
  local oldInstructionCount = #self.currentProto.instructions

  -- Since "Expression" is just a placeholder node for expressions
  -- we can skip it, so we take the child (Value) node instead.
  while nodeType == "Expression" do
    node = node.Value
    nodeType = node.TYPE
  end

  local expressionMethod = self.expressions[nodeType]
  if not expressionMethod then
    return error("Unsupported expression node type: " .. nodeType)
  end

  local returnRegister = expressionMethod(self, node, false, forcedResultRegister, true)
  self:deallocateRegister(returnRegister)

  local lastGeneratedInstruction = self.currentProto.instructions[#self.currentProto.instructions]
  if lastGeneratedInstruction[1] ~= "JMP" then
    -- Add a mini if statement, if there's none
    self:addInstruction("TEST", returnRegister, 0)
    self:addInstruction("JMP", 0, 1)
  end

  local newInstructionCount = #self.currentProto.instructions
  local generatedInstructions = self:getInstructionsFromRange(oldInstructionCount + 1, newInstructionCount)
  return generatedInstructions
end

--////// Node stuff //////--

-- Process a statement node (e.g. FunctionCall, ReturnStatement, - everything in code blocks)
function InstructionGeneratorMethods:processStatementNode(node, returnGeneratedInstructions)
  local nodeType = node.TYPE

  -- Since "Expression" is just a placeholder node for expressions
  -- we can skip it, so we take the child (Value) node instead.
  while nodeType == "Expression" do
    node = node.Value
    nodeType = node.TYPE
  end

  local oldInstructionCount = #self.currentProto.instructions
  local statementMethod = self.statements[nodeType]

  if not statementMethod then
    return error("Unsupported statement node type: " .. nodeType)
  end

  statementMethod(self, node)
  -- Check for leaks, all node methods must clear
  -- their temporary registers before returning
  self:checkForLeaks()

  if returnGeneratedInstructions then
    local newInstructionCount = #self.currentProto.instructions
    local generatedInstructions = self:getInstructionsFromRange(oldInstructionCount + 1, newInstructionCount)
    return generatedInstructions
  end
end

-- Process a list of statement nodes from a code block
function InstructionGeneratorMethods:processCodeBlock(nodeList, returnGeneratedInstructions)
  local oldInstructionCount = #self.currentProto.instructions

  self:pushScope()
  for _, node in ipairs(nodeList) do
    self:processStatementNode(node)
  end
  self:popScope()

  if returnGeneratedInstructions then
    local newInstructionCount = #self.currentProto.instructions
    local generatedInstructions = self:getInstructionsFromRange(oldInstructionCount + 1, newInstructionCount)
    return generatedInstructions
  end
end

--////// Main (Public) //////--

-- This is the only method that is intended to be called from outside.
function InstructionGeneratorMethods:run(proto)
  local globalProto = self:pushProto(proto)

  -- Process the AST, and generate instructions/constants/etc.
  self:processCodeBlock(self.ast)

  -- Add a default return instruction,
  -- by Lua design it's always needed, even if there's already one.
  -- OP_RETURN [A, B]    return R(A), ... ,R(A+B-2)
  self:addInstruction("RETURN", 0, 1)

  -- Helpers.writeFile("test2.out", Compiler.compile(globalProto))
  return globalProto
end

--* InstructionGenerator *--
local InstructionGenerator = {}
function InstructionGenerator:new(AST, proto)
  if proto then error("Proto support is discontinued") end

  local InstructionGeneratorInstance = {}
  InstructionGeneratorInstance.ast = AST

  InstructionGeneratorInstance.registers = {}
  InstructionGeneratorInstance.locals = {}

  -- These are the registers that are allocated only for one statement/expression function.
  -- We store them here, so we can check the code for leaks.
  InstructionGeneratorInstance.temporaryRegisters = {}
  -- This is used to keep track of which registers are taken by variables.
  InstructionGeneratorInstance.takenRegisters = {}

  InstructionGeneratorInstance.breakJumpStack = {}

  -- Tables for node compilers
  InstructionGeneratorInstance.statements = {}
  InstructionGeneratorInstance.expressions = {}

  -- ScopeManager stuff
  InstructionGeneratorInstance.scopes = {}
  InstructionGeneratorInstance.currentScope = { locals = {} }

  -- ProtoManager stuff
  InstructionGeneratorInstance.protos = {}
  InstructionGeneratorInstance.currentProto = nil
  InstructionGeneratorInstance.currentProtoLocals = {}

  -- ControlFlowManager stuff
  InstructionGeneratorInstance.controlFlows = {}

  local function inheritModule(moduleName, moduleTable, field)
    for index, value in pairs(moduleTable) do
      if InstructionGeneratorInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and InstructionGeneratorInstance: " .. index)
      end
      if field then
        InstructionGeneratorInstance[field][index] = value
      else
        InstructionGeneratorInstance[index] = value
      end
    end
  end

  -- Main methods
  inheritModule("InstructionGeneratorMethods", InstructionGeneratorMethods)

  -- Helper instruction methods
  inheritModule("Instructions", Instructions)

  -- Node compilers
  inheritModule("StatementCompiler", StatementCompiler, "statements")
  inheritModule("ExpressionCompiler", ExpressionCompiler, "expressions")

  -- Managers
  inheritModule("ScopeManager", ScopeManager)
  inheritModule("ProtoManager", ProtoManager)
  inheritModule("ControlFlowManager", ControlFlowManager)

  return InstructionGeneratorInstance
end

return InstructionGenerator
