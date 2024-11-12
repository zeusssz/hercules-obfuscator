--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Import library functions *--
local stringifyTable = Helpers.stringifyTable
local find = table.find or Helpers.tableFind
local insert = table.insert
local unpack = (unpack or table.unpack)

--* StatementCompiler *--
local StatementCompiler = {}

-- BreakStatement: {}
function StatementCompiler:BreakStatement(node)
  local currentControlFlow = self.currentControlFlow
  if not currentControlFlow then
    error("No loop to break")
  end

  local breakJumpInstructionIndex = self:addInstruction("JMP", 0, 1)
  self:registerBreakJump(breakJumpInstructionIndex)
end

-- FunctionCall: { Expression: {}, Arguments: {} }
function StatementCompiler:FunctionCall(node)
  -- Since function calls can be used both as statements and expressions,
  -- we will use the compiler for expressions to process the function call.
  self:processExpressionNode(node)
end

-- MethodCall: { Expression: {}, Arguments: {} }
function StatementCompiler:MethodCall(node)
  -- Since method calls can be used both as statements and expressions,
  -- we will use the compiler for expressions to process the method call.
  self:processExpressionNode(node)
end

-- LocalVariableAssignment: { Expressions: {}, Variables: {} }
function StatementCompiler:LocalVariableAssignment(node)
  local expressions = node.Expressions
  local variables = node.Variables

  local expressionRegisters = {}
  for index, expression in ipairs(expressions) do
    local expressionRegister = self:processExpressionNode(expression)
    insert(expressionRegisters, expressionRegister)
  end

  for index, expressionRegister in ipairs(expressionRegisters) do
    local expressionVariable = variables[index]
    if not expressionVariable then
      -- If the register of the expression cannot be used (in this case allocated to a variable).
      -- Then we just mark it as free.
      self:deallocateRegister(expressionRegister)
      -- Still allocate a register for the variable, as it's needed for the expression.
    else
      self:registerVariable(expressionVariable, expressionRegister)
    end
  end

  -- Allocate registers for the variables that don't have an expression.
  for index = #expressionRegisters + 1, #variables do
    local variable = variables[index]
    if variable then
      local variableRegister = self:allocateRegister()
      self:registerVariable(variable, variableRegister)
      self:addInstruction("LOADNIL", variableRegister, 0) -- Just in case, set it to nil.
    end
  end
end

-- LocalFunction: { Name: "", Parameters: {}, IsVararg: "", CodeBlock: {} }
function StatementCompiler:LocalFunction(node)
  local name = node.Name
  local parameters = node.Parameters
  local isVararg = node.IsVararg
  local codeBlock = node.CodeBlock

  local functionRegister = self:allocateRegister()
  self:compileLuaFunction(node, functionRegister)
  self:registerVariable(name, functionRegister)
end

-- FunctionDeclaration: { Parameters: {}, IsVararg: "", CodeBlock: {}, Expression: {}, Fields: {} }
function StatementCompiler:FunctionDeclaration(node)
end

-- MethodDeclaration: { Parameters: {}, IsVararg: "", CodeBlock: {}, Fields: {} }
function StatementCompiler:MethodDeclaration(node)
  local parameters = node.Parameters
  local isVararg = node.IsVararg
  local codeBlock = node.CodeBlock
  local fields = node.Fields

  --[[
  local functionRegister = self:allocateRegister()
  local functionProto = self:compileLuaFunction(node, functionRegister)
  insert(self.currentProto.protos, functionProto)

  local field = fields[1]
  local fieldRegister = self:processExpressionNode(field)
  self:addInstruction("CLOSURE", functionRegister, #self.currentProto.protos)
  self:addInstruction("SETTABLE", fieldRegister, fieldRegister, functionRegister)
  --]]
end

-- VariableAssignment: { Expressions: {}, Variables: {} }
function StatementCompiler:VariableAssignment(node)
  local expressions = node.Expressions
  local variables = node.Variables

  local expressionRegisters = {}
  for index, expression in ipairs(expressions) do
    local expression = expression.Value -- > <Expression>{ Value {} }
    local variable = variables[index]
    local expressionType = expression.TYPE
    if not variable then
      -- If the variable is nil, then we don't need to allocate a register for it.
      -- We can just process the expression and deallocate the register.
      local expressionRegister = self:processExpressionNode(expression)
      self:deallocateRegister(expressionRegister)
    else
      local variableType = variable.TYPE
      local variableValue = variable.Value
      if variableType == "Variable" then
        local variableName = variableValue
        local variableRegister = self:getLocalRegister(variableName)
        local expressionEvaluatedRegister = self:allocateRegister()
        local expressionRegister = self:processExpressionNode(expression, false, nil, expressionEvaluatedRegister)
        insert(expressionRegisters, { expressionEvaluatedRegister, variableRegister })
      elseif variableType == "Index" then
        local shouldProcessVariable = not (variable.Expression.TYPE == "String")
        --if shouldProcessExpression then -- It's a variable assignment like this: `a.b.c.d = 1`
        --else -- It's just one-level deep, like this: `a.b = 1`
        local variableNode = variable.Expression
        local indexNode = variable.Index
        local expressionRegister = self:processExpressionNode(expression, false, nil, expressionEvaluatedRegister)

        local variableRegister = self:processExpressionNode(variableNode)
        local indexRegister = self:processExpressionNode(indexNode, true)

        -- Free the registers
        self:deallocateRegisters({ variableRegister, indexRegister })

        -- OP_SETTABLE [A, B, C]    R(A)[RK(B)] := RK(C)
        self:addInstruction("SETTABLE", variableRegister, indexRegister, expressionRegister)
        --end
      end
    end
  end

  for index, value in ipairs(expressionRegisters) do
    local expressionRegister, variableRegister = unpack(value)
    self:addInstruction("MOVE", variableRegister, expressionRegister)
    self:deallocateRegister(expressionRegister)
  end
end

--[[ DoBlock: { CodeBlock: {} }
  | do                      | do:
  | .  <CodeBlock>          |  Instructions(CodeBlock(<CodeBlock>))
  | end                     |
--]]
function StatementCompiler:DoBlock(node)
  local codeBlock = node.CodeBlock
  self:processCodeBlock(codeBlock)
end

--[[ IfStatement: { Condition: {}, CodeBlock: {}, ElseIfs: {}, Else: {} }
  | if <Condition> then     | condition:
  | .                       |  Instructions(Expression(<Condition>))
  | .                       |  [TEST R(<Condition>), 0] // Jumps to the codeblock, in some cases is not used.
  | .                       |  [JMP 0, #Instructions(code-block)] // Jump to the end or to the next condition.
  | .  <CodeBlock>          | code-block:
  | .                       |  Instructions(CodeBlock(<CodeBlock>))
  | .                       |  JMP 0, end // Jump to the very end of the entire if-statement.
  | elseif <Condition> then | elseif-condition: // Optional, can be repeated.
  | .                       |  Instructions(Expression(<ElseIf.Condition>))
  | .                       |  [TEST R(<ElseIf.Condition>), 0]
  | .                       |  [JMP 0, #Instructions(elseif-block)] // Jump to the next elseif-condition, to the else-block, or to the end.
  | .  <CodeBlock>          | elseif-block:
  | .                       |  Instructions(CodeBlock(<ElseIf.CodeBlock>))
  | .                       |  JMP 0, end
  | ...                     | ... // Optionally more elseif-conditions and elseif-blocks.
  | else                    | else-block: // Optional.
  | .  <CodeBlock>          |  Instructions(CodeBlock(<Else.CodeBlock>))
  | end                     | end: // Nothing.
--]]
function StatementCompiler:IfStatement(node)
  local condition = node.Condition
  local codeBlock = node.CodeBlock
  local elseIfs = node.ElseIfs
  local elseStatement = node.Else

  local ifConditionCodeBlockStatements = { { Condition = condition, CodeBlock = codeBlock } }
  for _, elseIfStatement in ipairs(elseIfs) do
    insert(ifConditionCodeBlockStatements, elseIfStatement)
  end

  local jumpsToTheEndInstructionIndices = {}
  for index, ifConditionCodeBlockStatement in ipairs(ifConditionCodeBlockStatements) do
    local condition = ifConditionCodeBlockStatement.Condition
    local codeBlock = ifConditionCodeBlockStatement.CodeBlock

    local conditionInstructions = self:processConditionNode(condition)
    local codeBlockInstructions = self:processCodeBlock(codeBlock, true)

    local conditionJumpInstruction = conditionInstructions[#conditionInstructions]
    if index ~= #ifConditionCodeBlockStatements or elseStatement then
      conditionJumpInstruction[3] = #codeBlockInstructions + 1
      insert(jumpsToTheEndInstructionIndices, self:addInstruction("JMP", 0, 1))
    else
      conditionJumpInstruction[3] = #codeBlockInstructions
    end
  end

  if elseStatement then
    local elseBlockInstructions = self:processCodeBlock(elseStatement.CodeBlock, true)
  end

  -- Make all the code block jump instructions jump to the end of the entire if-statement
  for _, jumpToTheEndInstructionIndex in ipairs(jumpsToTheEndInstructionIndices) do
    self:changeInstruction(jumpToTheEndInstructionIndex, "JMP", 0, #self.currentProto.instructions - jumpToTheEndInstructionIndex)
  end
end

--[[ NumericFor: { IteratorVariables: {}, Expressions: {}, CodeBlock: {} }
  | for <IteratorVariables> = <Expressions> do | for_header:
  | .                                          |  Instructions(Expression(<Expressions[1]>))
  | .                                          |  Instructions(Expression(<Expressions[2]>))
  | .                                          |  Instructions(Expression(<Expressions[3]>))
  | .                                          |  FORPREP R(<Expressions[1]>), #Instructions(code-block)
  | .  <CodeBlock>                             | loop:
  | .                                          |  Instructions(CodeBlock(<CodeBlock>))
  | .                                          |  FORLOOP R(<Expressions[1]>), -#Instructions(code-block) - 1
  | end                                        | end: // Nothing.
--]]
function StatementCompiler:NumericFor(node)
  local iteratorVariables = node.IteratorVariables
  local expressions = node.Expressions
  local codeBlock = node.CodeBlock

  local iteratorVariable = iteratorVariables[1]

  local iteratorStart = self:processExpressionNode(expressions[1])
  local iteratorEnd = self:processExpressionNode(expressions[2])
  local iteratorStep
  if expressions[3] then
    iteratorStep = self:processExpressionNode(expressions[3])
  else
    iteratorStep = self:allocateRegister()
    self:addInstruction("LOADK", iteratorStep, self:findOrAddConstant(1))
  end

  -- OP_FORPREP [A, Bx]    R(A)-=R(A+2); pc+=Bx
  local forLoopInstruction = self:addInstruction("FORPREP", iteratorStart, 0)

  self:pushScope()
  self:registerVariable(iteratorVariable, iteratorStart)
  local codeBlockgeneratedInstructions = self:processCodeBlock(codeBlock, true)
  self:popScope()

  self:changeInstruction(forLoopInstruction, "FORPREP", iteratorStart, #codeBlockgeneratedInstructions)

  -- OP_FORLOOP [A, Bx]    R(A)+=R(A+2);
  --                       if R(A) <?= R(A+1) then { pc+=Bx; R(A+3)=R(A) }
  self:addInstruction("FORLOOP", iteratorStart, -(#codeBlockgeneratedInstructions + 1))
end

--[[ GenericFor: { IteratorVariables: {}, Expressions: {}, CodeBlock: {} }
  | for <IteratorVariables> in <Expressions> do | for_header:
  | .                                           |  Instructions(Expression(<Expressions[1]>)) # Iterator function
  | .                                           |  Instructions(Expression(<Expressions[2]>)) # State, optional
  | .                                           |  Instructions(Expression(<Expressions[3]>)) # Initial value, optional
  | .                                           |  JMP 0, loop_end # Jump to the TFORLOOP instruction
  | .  <CodeBlock>                              | loop:
  | .                                           |  Instructions(CodeBlock(<CodeBlock>))
  | .                                           | loop_end:
  | .                                           |  TFORLOOP R(<Expressions[1]>), #IteratorVariables - 1
  | .                                           |  JMP 0, loop
  | end                                         | end: // Nothing.
--]]
function StatementCompiler:GenericFor(node)
  local iteratorVariables = node.IteratorVariables
  local expressions = node.Expressions
  local codeBlock = node.CodeBlock

  local iteratorFunctionRegister, iteratorStateRegister, iteratorInitialValueRegister

  self:processExpressionNode(expressions[1])
  -- TODO: in Lua generic for nodes accept multiple expressions,
  -- for example: `for _ in func1(), 1, 2 do ...` is valid.
  -- We need to handle this case.

  local iteratorFunctionRegister = self:allocateRegister()
  local iteratorStateRegister = self:allocateRegister()
  local iteratorInitialValueRegister = self:allocateRegister()

  if expressions[2] then -- State (Table for the generated function)
    self:processExpressionNode(expressions[2], nil, nil, iteratorFunctionRegister)
  end
  if expressions[3] then -- Initial value
    self:processExpressionNode(expressions[3], nil, nil, iteratorInitialValueRegister)
  end

  -- Set iterator variables
  local variableRegisters = {}
  for index, iteratorVariable in ipairs(iteratorVariables) do
    local variableRegister = self:allocateRegister()
    variableRegisters[index] = variableRegister
    self:registerVariable(iteratorVariable, variableRegister)
  end

  local jumpToTheEndInstructionIndex = self:addInstruction("JMP", 0, 1)

  local controlFlow = self:pushControlFlow()
  local codeBlockgeneratedInstructions = self:processCodeBlock(codeBlock, true)
  self:popControlFlow()

  self:changeInstruction(jumpToTheEndInstructionIndex, "JMP", 0, #codeBlockgeneratedInstructions)
  -- OP_TFORLOOP [A, C]    R(A+3), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2));
  --                       if R(A+3) ~= nil then R(A+2)=R(A+3) else pc++
  self:addInstruction("TFORLOOP", iteratorFunctionRegister, #iteratorVariables)
  self:addInstruction("JMP", 0, -(#codeBlockgeneratedInstructions + 1 + 1))

  -- Dellocate them, registers
  self:deallocateRegisters({ iteratorFunctionRegister, iteratorStateRegister, iteratorInitialValueRegister })
  self:deallocateRegisters(variableRegisters)
end

--[[ WhileLoop: { Expression: {}, CodeBlock: {} }
  | while <Condition> do | condition:
  | .                    |  Instructions(Condition(<Condition>))
  | .                    |  [TEST R(<Condition>), 0] // Optional.
  | .                    |  [JMP 0, loop_end] // Optional.
  | .  <CodeBlock>       | loop:
  | .                    |  Instructions(CodeBlock(<CodeBlock>))
  | .                    |  JMP 0, condition
  | end                  | loop_end: // Nothing.
--]]
function StatementCompiler:WhileLoop(node)
  local expression = node.Expression
  local codeBlock = node.CodeBlock

  local conditionInstructions = self:processConditionNode(expression)
  local oldInstructionCount = #self.currentProto.instructions
  local controlFlow = self:pushControlFlow()
  local codeBlockGeneratedInstructions = self:processCodeBlock(codeBlock, true)
  self:popControlFlow()
  local newInstructionCount = #self.currentProto.instructions

  local conditionJumpInstruction = conditionInstructions[#conditionInstructions]
  conditionJumpInstruction[3] = #codeBlockGeneratedInstructions + 1
  self:addInstruction("JMP", 0, -(#codeBlockGeneratedInstructions + #conditionInstructions + 1))
  local newInstructionCount = #self.currentProto.instructions
  for index, jumpInstructionIndex in ipairs(controlFlow.breakJumps) do
    self:changeInstruction(jumpInstructionIndex, "JMP", 0, newInstructionCount - jumpInstructionIndex)
  end
end

--[[ ReturnStatement: { Expressions: {} }
  | return <Expressions> | return:
  | .                    |  Instructions(Expression(<Expressions[1]>))
  | .                    |  ...
  | .                    |  Instructions(Expression(<Expressions[#Expressions]>))
  | .                    |  RETURN R(<Expressions[1]>), R(#Expressions - 1)
--]]
function StatementCompiler:ReturnStatement(node)
  local expressions = node.Expressions
  if #expressions == 0 then
    -- OP_RETURN [A, B]    return R(A), ... ,R(A+B-2)
    self:addInstruction("RETURN", 0, 0)
    return
  end

  local expressionRegisters = {}

  for index, expression in ipairs(expressions) do
    local expressionRegister = self:processExpressionNode(expression)
    -- If the expressions are not consecutive, move them to consecutive registers
    if expressionRegister ~= index then
      -- OP_MOVE [A, B]    R(A) := R(B)
      self:addInstruction("MOVE", index, expressionRegister)
    end
    insert(expressionRegisters, expressionRegister)
  end

  -- OP_RETURN [A, B]    return R(A), ... ,R(A+B-2)
  self:addInstruction("RETURN", expressionRegisters[1], (expressionRegisters[1] + #expressionRegisters) + 1)
  self:deallocateRegisters(expressionRegisters)
end

--[[ UntilLoop: { Expression: {}, CodeBlock: {} }
  | repeat             |
  | .  <CodeBlock>     | loop-body:
  | .                  |  Instructions(CodeBlock(<CodeBlock>))
  | until <Expression> | condition:
  | .                  |  Instructions(Condition(not <Expression>))
  | .                  |  [TEST R(<Expression>), 0] ; Not always "TEST", it can be "EQ"/etc.
  | .                  |  [JMP 0, loop-body]
--]]
function StatementCompiler:UntilLoop(node)
  local statement = node.Statement
  local codeBlock = node.CodeBlock

  local codeBlockInstructions = self:processCodeBlock(codeBlock, true)
  local conditionInstructions = self:processConditionNode(statement)

  --[[ We're at:
    [TEST/EQ/LE/LT/etc] R(<Expression>), 0
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    [JMP 0, loop-body]
  --]]

  -- [JMP 0, loop-body] {
  local conditionJumpInstruction = conditionInstructions[#conditionInstructions]
  conditionJumpInstruction[3] = -(#codeBlockInstructions + #conditionInstructions)
  -- }
end

return StatementCompiler
