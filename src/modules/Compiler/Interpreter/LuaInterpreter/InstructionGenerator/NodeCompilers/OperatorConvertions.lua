--* Local functions *--
local function generateLoadBoolPair(self, forcedResultRegister)
  local resultRegister = forcedResultRegister or self:allocateRegister()

  -- OP_LOADBOOL [A, B, C] R(A) := (Bool)B; if (C) pc++
  -- The second LOADBOOL will not be executed if the first one was executed.
  self:addInstruction("LOADBOOL", resultRegister, 0, 1)
  self:addInstruction("LOADBOOL", resultRegister, 1, 0)
  return resultRegister
end

--* OperatorConvertions *--
local OperatorConvertions = {}
OperatorConvertions.Unary = {
  ["-"]   = "UNM",  -- OP_UNM    [A, B]        R(A) := -R(B)
  ["#"]   = "LEN",  -- OP_LEN    [A, B]        R(A) := length of R(B)
  ["not"] = "NOT",  -- OP_NOT    [A, B]        R(A) := not R(B)
}

OperatorConvertions.Binary = {
  ["+"]   = "ADD",    -- OP_ADD    [A, B, C]    R(A) := RK(B) + RK(C)
  ["-"]   = "SUB",    -- OP_SUB    [A, B, C]    R(A) := RK(B) - RK(C)
  ["*"]   = "MUL",    -- OP_MUL    [A, B, C]    R(A) := RK(B) * RK(C)
  ["/"]   = "DIV",    -- OP_DIV    [A, B, C]    R(A) := RK(B) / RK(C)
  ["%"]   = "MOD",    -- OP_MOD    [A, B, C]    R(A) := RK(B) % RK(C)
  ["^"]   = "POW",    -- OP_POW    [A, B, C]    R(A) := RK(B) ^ RK(C)

  --[[
    <Left>
    <Right>
    CONCAT R(Result), R(Left), R(Right)
  --]]
  [".."]  = function(self, left, right, forcedResultRegister)
    local leftRegister = self:processExpressionNode(left)
    local rightRegister = self:processExpressionNode(right)
    self:deallocateRegisters({ leftRegister, rightRegister })

    local resultRegister = forcedResultRegister or self:allocateRegister()
    self:addInstruction("CONCAT", resultRegister, leftRegister, rightRegister)
    return resultRegister
  end,

  --// Comparison operators \\--
  -- Note: All comparison operators have "isCondition" argument, if it's present,
  --       The comparison operator will be flipped to the opposite, so it can be used in conditions.

  --[[
    <Left>
    <Right>
    LT 1, RK(Left), RK(Right)
    JMP 0, 1
    LOADBOOL R(Result), 0, 1
    LOADBOOL R(Result), 1, 0
  --]]
  ["<"]   = function(self, left, right, forcedResultRegister, isCondition)
    local leftRegister = self:processExpressionNode(left, true)
    local rightRegister = self:processExpressionNode(right, true)
    self:deallocateRegisters({ leftRegister, rightRegister })

    if isCondition then
      self:addInstruction("LT", 0, leftRegister, rightRegister)
      self:addInstruction("JMP", 0, 1)
      -- Return nothing, because we dont work with registers in conditions
      -- Instead, we work with JMP instructions
      return
    end
    self:addInstruction("LT", 1, leftRegister, rightRegister)
    self:addInstruction("JMP", 0, 1)

    return generateLoadBoolPair(self, forcedResultRegister)
  end,

  --[[
    <Left>
    <Right>
    LT 1, RK(Right), RK(Left)
    JMP 0, 1
    LOADBOOL R(Result), 0, 1
    LOADBOOL R(Result), 1, 0
  --]]
  [">"]   = function(self, left, right, forcedResultRegister, isCondition)
    local leftRegister = self:processExpressionNode(left, true)
    local rightRegister = self:processExpressionNode(right, true)
    self:deallocateRegisters({ leftRegister, rightRegister })

    if isCondition then
      self:addInstruction("LT", 0, rightRegister, leftRegister)
      self:addInstruction("JMP", 0, 1)
      -- Return nothing, because we dont work with registers in conditions
      -- Instead, we work with JMP instructions
      return
    end
    self:addInstruction("LT", 1, rightRegister, leftRegister)
    self:addInstruction("JMP", 0, 1)

    return generateLoadBoolPair(self, forcedResultRegister)
  end,

  --[[
    <Left>
    <Right>
    LE 0, RK(Left), RK(Right)
    JMP 0, 1
    LOADBOOL R(Result), 0, 1
    LOADBOOL R(Result), 1, 0
  --]]
  ["<="]  = function(self, left, right, forcedResultRegister, isCondition)
    local leftRegister = self:processExpressionNode(left, true)
    local rightRegister = self:processExpressionNode(right, true)
    self:deallocateRegisters({ leftRegister, rightRegister })

    if isCondition then
      self:addInstruction("LE", 0, leftRegister, rightRegister)
      self:addInstruction("JMP", 0, 1)
      -- Return nothing, because we dont work with registers in conditions
      -- Instead, we work with JMP instructions
      return
    end
    self:addInstruction("LE", 1, leftRegister, rightRegister)
    self:addInstruction("JMP", 0, 1)

    return generateLoadBoolPair(self, forcedResultRegister)
  end,

  --[[
    <Left>
    <Right>
    LE 1, RK(Right), RK(Left)
    JMP 0, 1
    LOADBOOL R(Result), 0, 1
    LOADBOOL R(Result), 1, 0
  --]]
  [">="]  = function(self, left, right, forcedResultRegister, isCondition)
    local leftRegister = self:processExpressionNode(left, true)
    local rightRegister = self:processExpressionNode(right, true)
    self:deallocateRegisters({ leftRegister, rightRegister })

    if isCondition then
      self:addInstruction("LE", 0, rightRegister, leftRegister)
      self:addInstruction("JMP", 0, 1)
      -- Return nothing, because we dont work with registers in conditions
      -- Instead, we work with JMP instructions
      return
    end
    self:addInstruction("LE", 1, rightRegister, leftRegister)
    self:addInstruction("JMP", 0, 1)

    return generateLoadBoolPair(self, forcedResultRegister)
  end,

  --[[
    <Left>
    <Right>
    EQ 1, RK(Left), RK(Right)
    JMP 0, 1
    LOADBOOL R(Result), 0, 1
    LOADBOOL R(Result), 1, 0
  --]]
  ["=="]  = function(self, left, right, forcedResultRegister, isCondition)
    local leftRegister = self:processExpressionNode(left, true)
    local rightRegister = self:processExpressionNode(right, true)
    self:deallocateRegisters({ leftRegister, rightRegister })

    if isCondition then
      self:addInstruction("EQ", 0, leftRegister, rightRegister)
      self:addInstruction("JMP", 0, 1)
      -- Return nothing, because we dont work with registers in conditions
      -- Instead, we work with JMP instructions
      return
    end
    self:addInstruction("EQ", 1, leftRegister, rightRegister)
    self:addInstruction("JMP", 0, 1)

    return generateLoadBoolPair(self, forcedResultRegister)
  end,

  --[[
    <Left>
    <Right>
    EQ 0, RK(Left), RK(Right)
    JMP 0, 1
    LOADBOOL R(Result), 0, 1
    LOADBOOL R(Result), 1, 0
  --]]
  ["~="]  = function(self, left, right, forcedResultRegister, isCondition)
    local leftRegister = self:processExpressionNode(left, true)
    local rightRegister = self:processExpressionNode(right, true)
    self:deallocateRegisters({ leftRegister, rightRegister })

    if isCondition then
      self:addInstruction("EQ", 1, leftRegister, rightRegister)
      self:addInstruction("JMP", 0, 1)
      -- Return nothing, because we dont work with registers in conditions
      -- Instead, we work with JMP instructions
      return
    end
    self:addInstruction("EQ", 0, leftRegister, rightRegister)
    self:addInstruction("JMP", 0, 1)

    return generateLoadBoolPair(self, forcedResultRegister)
  end,

  --[[
    <Left>
    TEST R(Left), 0
    JMP 0, #Instructions(Right)
    <Right>

    NOTE: If the left expression is false, it's result register will be returned.
          If the left expression is true, the right expression will be executed,
           and the right expression register will be returned.
          In all cases, the left expression is executed.
  --]]
  ["and"] = function(self, left, right)
    local leftRegister = self:processExpressionNode(left)
    self:addInstruction("TEST", leftRegister, 0)
    local jumpInstruction = self:addInstruction("JMP", 0, 1)
    local rightRegister, rightInstructions = self:processExpressionNode(right, nil, true, leftRegister)
    self:changeInstruction(jumpInstruction, "JMP", 0, #rightInstructions)
    return leftRegister
  end,

  --[[
    <Left>
    TEST R(Left), 1
    JMP 0, #Instructions(Right)
    <Right>

    NOTE: If the left expression is true, the right expression will not be executed,
           and the left expression register will be returned.
          If the left expression is false, the right expression will be executed and returned.
          In all cases, the left expression is executed.
  --]]
  ["or"]  = function(self, left, right)
    local leftRegister = self:processExpressionNode(left)
    self:addInstruction("TEST", leftRegister, 1)
    local jumpInstruction = self:addInstruction("JMP", 0, 1)
    local rightRegister, rightInstructions = self:processExpressionNode(right, nil, true, leftRegister)
    self:changeInstruction(jumpInstruction, "JMP", 0, #rightInstructions)
    return leftRegister
  end
}

return OperatorConvertions
