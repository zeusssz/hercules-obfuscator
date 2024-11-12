--* Dependencies *--
local Helpers = require("Helpers/Helpers")

local OperatorConvertions = require("Interpreter/LuaInterpreter/InstructionGenerator/NodeCompilers/OperatorConvertions")

--* Imports *--
local find = table.find or Helpers.tableFind
local insert = table.insert
local unpack = (unpack or table.unpack)

local binaryOperatorConvertions = OperatorConvertions.Binary
local unaryOperatorConvertions = OperatorConvertions.Unary

--* ExpressionCompiler *--
local ExpressionCompiler = {}

-----------------// Literal and Identifier Nodes \\-----------------

-- Constant: { Value: "" }
function ExpressionCompiler:Constant(node, canReturnConstantIndex, forcedResultRegister)
  local constantValue = tostring(node.Value)
  local valueRegister = forcedResultRegister or self:allocateRegister()

  if tostring(constantValue) == "nil" then
    -- OP_LOADNIL [A, B]    R(A) := ... := R(B) := nil
    self:addInstruction("LOADNIL", valueRegister, valueRegister)
    return valueRegister
  end

  local booleanNumber = (constantValue == "true" and 1) or 0

  -- OP_LOADBOOL [A, B, C]    R(A) := (Bool)B; if (C) pc++
  self:addInstruction("LOADBOOL", valueRegister, booleanNumber, 0)
  return valueRegister
end

-- VarArg: {}
function ExpressionCompiler:VarArg(node, canReturnConstantIndex, forcedResultRegister)
  local varArgRegister = forcedResultRegister or self:allocateRegister()

  -- OP_VARARG [A, B]    R(A), R(A+1), ..., R(A+B-2) = vararg
  self:addInstruction("VARARG", varArgRegister, 2)
  return varArgRegister
end


local function getLocalVariable(self, node, canReturnConstantIndex, forcedResultRegister)
  local variableValue = node.Value
  local localRegister = self:getLocalRegister(variableValue)
  if not localRegister then
    return error("Local variable not found: " .. tostring(variableValue))
  end

  if canReturnConstantIndex then
    return localRegister
  end

  local resultRegister = forcedResultRegister or self:allocateRegister()

  -- OP_MOVE [A, B]    R(A) := R(B)
  self:addInstruction("MOVE", resultRegister, localRegister)
  return resultRegister
end

local function getGlobalVariable(self, node, canReturnConstantIndex, forcedResultRegister)
  local variableValue = node.Value
  local globalRegister = forcedResultRegister or self:allocateRegister()
  local constantIndex = self:findOrAddConstant(variableValue)

  -- OP_GETGLOBAL [A, Bx]    R(A) := Gbl[Kst(Bx)]
  self:addInstruction("GETGLOBAL", globalRegister, constantIndex)
  return globalRegister
end

local function getUpvalue(self, node, canReturnConstantIndex, forcedResultRegister)
  local upvalueRegister = forcedResultRegister or self:allocateRegister()
  local upvalueIndex = self:findOrCreateUpvalue(node.Value)

  -- OP_GETUPVAL [A, B]    R(A) := UpValue[B]
  self:addInstruction("GETUPVAL", upvalueRegister, upvalueIndex)
  return upvalueRegister
end

-- Variable: { Value: "", VariableType: "" }
function ExpressionCompiler:Variable(node, canReturnConstantIndex, forcedResultRegister)
  local variableName = node.Value
  local variableType = node.VariableType

  if variableType == "Local" then
    return getLocalVariable(self, node, canReturnConstantIndex, forcedResultRegister)
  elseif variableType == "Global" then
    return getGlobalVariable(self, node, canReturnConstantIndex, forcedResultRegister)
  elseif variableType == "Upvalue" then
    return getUpvalue(self, node, canReturnConstantIndex, forcedResultRegister)
  end

  return error("Variable type not supported: " .. tostring(variableType))
end

-- Number: { Value: "" }
function ExpressionCompiler:Number(node, canReturnConstantIndex, forcedResultRegister)
  local numberValue = node.Value
  local constantIndex = self:findOrAddConstant(numberValue)
  if canReturnConstantIndex then
    return constantIndex
  end

  local constantRegister = forcedResultRegister or self:allocateRegister()

  -- OP_LOADK [A, Bx]    R(A) := Kst(Bx)
  self:addInstruction("LOADK", constantRegister, constantIndex)
  return constantRegister
end

-- String: { Value: "" }
function ExpressionCompiler:String(node, canReturnConstantIndex, forcedResultRegister)
  local stringValue = node.Value
  local constantIndex = self:findOrAddConstant(stringValue)
  if canReturnConstantIndex then
    return constantIndex
  end
  local constantRegister = forcedResultRegister or self:allocateRegister()

  -- OP_LOADK [A, Bx]    R(A) := Kst(Bx)
  self:addInstruction("LOADK", constantRegister, constantIndex)
  return constantRegister
end

-- Table: { Elements: {} }
function ExpressionCompiler:Table(node, canReturnConstantIndex, forcedResultRegister)
  local elements = node.Elements

  local tableRegister = forcedResultRegister or self:allocateRegister()

  -- OP_NEWTABLE [A, B, C]    R(A) := {} (size = B,C)
  self:addInstruction("NEWTABLE", tableRegister, 0, 0)

  local temporaryRegisters = {}
  local numberOfImplicitKeys = 0
  for _, element in ipairs(elements) do
    if element.ImplicitKey then
      insert(temporaryRegisters, self:processExpressionNode(element.Value))
      numberOfImplicitKeys = numberOfImplicitKeys + 1
    end
  end

  -- OP_SETLIST [A, B, C]    R(A)[(C-1)*FPF+i] := R(A+i), 1 <= i <= B
  self:addInstruction("SETLIST", tableRegister, numberOfImplicitKeys, 1)
  self:deallocateRegisters(temporaryRegisters)

  -- Elements: { { Key: "", Value: "", ImplicitKey: "" } }
  for _, element in ipairs(elements) do
    local value = element.Value
    local key = element.Key
    local implicitKey = element.ImplicitKey

    if implicitKey then
    else
      local valueRegister = self:processExpressionNode(value)
      local keyRegister = self:processExpressionNode(key)
      -- Free the registers
      self:deallocateRegisters({ valueRegister, keyRegister })

      -- OP_SETTABLE [A, B, C]    R(A)[RK(B)] := RK(C)
      self:addInstruction("SETTABLE", tableRegister, keyRegister, valueRegister)
    end
  end

  return tableRegister
end

-- Function: { Parameters: {}, IsVararg: "", CodeBlock: {} }
function ExpressionCompiler:Function(node, canReturnConstantIndex, forcedResultRegister)
  local parameters = node.Parameters
  local isVararg = node.IsVararg
  local codeBlock = node.CodeBlock

  local functionRegister = forcedResultRegister or self:allocateRegister()
  local functionProto = self:compileLuaFunction(node, functionRegister)
  return functionRegister
end

-----------------// Table Indexing \\-----------------

-- Index: { Expression: {}, Index: {} }
function ExpressionCompiler:Index(node, canReturnConstantIndex, forcedResultRegister)
  local expression = node.Expression
  local index = node.Index

  local fieldRegister = forcedResultRegister or self:allocateRegister()

  local expressionRegister = self:processExpressionNode(expression)
  local indexRegister = self:processExpressionNode(index, true)

  -- Free the registers
  self:deallocateRegisters({ expressionRegister, indexRegister })

  -- OP_GETTABLE [A, B, C]    R(A) := R(B)[RK(C)]
  self:addInstruction("GETTABLE", fieldRegister, expressionRegister, indexRegister)
  return fieldRegister
end

-- MethodIndex: { Expression: {}, Index: {} }
function ExpressionCompiler:MethodIndex(node, canReturnConstantIndex, forcedResultRegister)
  local expression = node.Expression
  local index = node.Index

  local fieldRegister = forcedResultRegister or self:allocateRegister()

  local expressionRegister = self:processExpressionNode(expression)
  local indexRegister = self:processExpressionNode(index)

  -- Free the registers
  self:deallocateRegisters({ expressionRegister, indexRegister })

  -- OP_GETTABLE [A, B, C]    R(A) := R(B)[RK(C)]
  self:addInstruction("GETTABLE", fieldRegister, expressionRegister, indexRegister)
  return fieldRegister
end

-----------------// Operators \\-----------------

-- Operator: { Left: {}, Right: {}, Value: "" }
function ExpressionCompiler:Operator(node, canReturnConstantIndex, forcedResultRegister, isCondition)
  local left = node.Left
  local right = node.Right
  local value = node.Value

  if binaryOperatorConvertions[value] then
    if type(binaryOperatorConvertions[value]) == "function" then
      return binaryOperatorConvertions[value](self, left, right, forcedResultRegister, isCondition)
    end

    local leftRegister = self:processExpressionNode(left, true)
    local rightRegister = self:processExpressionNode(right, true)
    self:deallocateRegisters({ leftRegister, rightRegister })

    local resultRegister = forcedResultRegister or self:allocateRegister()

    self:addInstruction(binaryOperatorConvertions[value], resultRegister, leftRegister, rightRegister)
    return resultRegister
  end

  return error("Operator not supported: " .. tostring(value))
end

-- UnaryOperator: { Operand: {}, Value: "" }
function ExpressionCompiler:UnaryOperator(node, canReturnConstantIndex, forcedResultRegister)
  local operand = node.Operand
  local value = node.Value

  if unaryOperatorConvertions[value] then
    if type(unaryOperatorConvertions[value]) == "function" then
      return unaryOperatorConvertions[value](self, operand, forcedResultRegister)
    end

    local operandRegister = self:processExpressionNode(operand)
    self:deallocateRegister(operandRegister)

    local resultRegister = forcedResultRegister or self:allocateRegister()

    self:addInstruction(unaryOperatorConvertions[value], resultRegister, operandRegister)
    return resultRegister
  end

  return error("Unary operator not supported: " .. tostring(value))
end

-----------------// Function calls \\-----------------

-- FunctionCall: { Expression: {}, Arguments: {}, ExpectedReturnValueCount: "" }
function ExpressionCompiler:FunctionCall(node, canReturnConstantIndex, forcedResultRegister)
  local expression = node.Expression
  local arguments = node.Arguments
  local expectedReturnValueCount = node.ExpectedReturnValueCount

  local expressionRegister = self:processExpressionNode(expression)

  local argumentRegisters = {}
  for index, argument in ipairs(arguments) do
    local argumentRegister = self:processExpressionNode(argument)
    -- If the arguments are not consecutive, move them to consecutive registers
    -- This mostly happens if there's a leak from the previous expression
    -- or a local variable (the contents of which are stored only once constantly, so it has
    -- a constant register, with multiple temporary registers)
    if argumentRegister ~= (expressionRegister + index) then
      -- OP_MOVE [A, B]    R(A) := R(B)
      self:addInstruction("MOVE", expressionRegister + index, argumentRegister)
    end
    insert(argumentRegisters, argumentRegister)
  end

  local functionCallRegisters = {expressionRegister, unpack(argumentRegisters)}

  -- OP_CALL [A, B, C]    R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
  if self.canReturnMultipleValues then
    -- Return all the return values of the function call, C = 0 means all the return values
    self:addInstruction("CALL", expressionRegister, #arguments + 1, 0)
    return expressionRegister
  end

  -- OP_CALL [A, B, C]    R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
  self:addInstruction("CALL", expressionRegister, #arguments + 1, expectedReturnValueCount + 1)
  self:deallocateRegisters(functionCallRegisters)

  -- Since the function gets replaced with the return value,
  -- we return the expression (function) register
  return expressionRegister
end

-- MethodCall: { Expression: {}, Arguments: {} }
function ExpressionCompiler:MethodCall(node, canReturnConstantIndex, forcedResultRegister)
  local expression = node.Expression
  local arguments = node.Arguments

  local expressionRegister = self:processExpressionNode(expression)

  local argumentRegisters = {}
  for index, argument in ipairs(arguments) do
    local argumentRegister = self:processExpressionNode(argument)
    -- If the arguments are not consecutive, move them to consecutive registers
    -- This mostly happens if there's a leak from the previous expression
    -- or a local variable (the contents of which are stored only once constantly, so it has
    -- a constant register, with multiple temporary registers)
    if argumentRegister ~= (expressionRegister + index) then
      -- OP_MOVE [A, B]    R(A) := R(B)
      self:addInstruction("MOVE", expressionRegister + index, argumentRegister)
    end
    insert(argumentRegisters, argumentRegister)
  end

  local functionCallRegisters = {expressionRegister, unpack(argumentRegisters)}

  -- OP_CALL [A, B, C]    R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
  if self.canReturnMultipleValues then
    -- Return all the return values of the function call, C = 0 means all the return values
    self:addInstruction("CALL", expressionRegister, #arguments + 1, 0)
    return
  end

  -- Make it return only the first return value
  self:addInstruction("CALL", expressionRegister, #arguments + 1, 2)
  self:deallocateRegisters(functionCallRegisters)

  -- Since the function gets replaced with the return value,
  -- we return the expression (function) register
  return expressionRegister
end

return ExpressionCompiler
