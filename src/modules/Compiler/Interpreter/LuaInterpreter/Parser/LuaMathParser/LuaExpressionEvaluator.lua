--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local NodeFactory = require("Interpreter/LuaInterpreter/Parser/NodeFactory")

--* Imports *--
local createNumberNode = NodeFactory.createNumberNode
local createStringNode = NodeFactory.createStringNode
local createConstantNode = NodeFactory.createConstantNode

--* Constants *--
local OPERATIONS = {
  ["+"]  = function(a, b) return a +  b end, ["-"]   = function(a, b) return a -   b end,
  ["*"]  = function(a, b) return a *  b end, ["/"]   = function(a, b) return a /   b end,
  ["%"]  = function(a, b) return a %  b end, ["^"]   = function(a, b) return a ^   b end,
  [".."] = function(a, b) return a .. b end, ["=="]  = function(a, b) return a ==  b end,
  ["~="] = function(a, b) return a ~= b end, [">"]   = function(a, b) return a >   b end,
  ["<"]  = function(a, b) return a <  b end, [">="]  = function(a, b) return a >=  b end,
  ["<="] = function(a, b) return a <= b end, ["and"] = function(a, b) return a and b end,
  ["or"] = function(a, b) return a or b end
}

local UNARY_OPERATORS = {
  ["-"]   = function(a) return -   a end,
  ["#"]   = function(a) return #   a end,
  ["not"] = function(a) return not a end
}

local MAXIMALLY_EVALUATED_NODES = {
  ["Number"] = true,
  ["String"] = true,
  ["Boolean"] = true,
  ["Constant"] = true,
  ["Table"] = true
}

--* LuaExpressionEvaluator *--
local LuaExpressionEvaluator = {}

--- Evaluates unary operators (e.g. `-1`, `#table`, `not true`)
-- @param <Table> node The node to evaluate
-- @return <Table> result The evaluated node
-- @return <Boolean> evaluatedToConstant Whether the node evaluated to a constant
function LuaExpressionEvaluator.evaluateUnaryOperator(node)
  local nodeOperator = node.Value
  local nodeOperand = node.Operand

  -- #<Optimization_Opportunity>#
  local evaluatedValue, evaluatedToConstant = LuaExpressionEvaluator.evaluateExpression(nodeOperand)
  local operation = evaluatedToConstant and UNARY_OPERATORS[nodeOperator]
  if operation then
    return operation(evaluatedValue), true
  end

  node.Operand = LuaExpressionEvaluator.convertEvaluatedValueToNode(evaluatedValue, node.Operand)
  return node, false
end

--- Evaluates binary operators (e.g. `1 + 1`, `"Hello" .. "World"`, `true and false`)
-- @param <Table> node The node to evaluate
-- @return <Table> result The evaluated node
-- @return <Boolean> evaluatedToConstant Whether the node evaluated to a constant
function LuaExpressionEvaluator.evaluateOperator(node)
  local nodeOperator = node.Value
  local nodeLeft = node.Left
  local nodeRight = node.Right

  local evaluatedLeftValue, evaluatedLeftToConstant = LuaExpressionEvaluator.evaluateExpression(nodeLeft)
  local evaluatedRightValue, evaluatedRightToConstant = LuaExpressionEvaluator.evaluateExpression(nodeRight)
  local evaluatedConstants = evaluatedLeftToConstant and evaluatedRightToConstant

  if evaluatedConstants then
    local operation = OPERATIONS[nodeOperator]
    if operation then
      return operation(evaluatedLeftValue, evaluatedRightValue), true
    end
  end

  node.Left = LuaExpressionEvaluator.convertEvaluatedValueToNode(evaluatedLeftValue, node.Left)
  node.Right = LuaExpressionEvaluator.convertEvaluatedValueToNode(evaluatedRightValue, node.Right)
  return node, false
end

--- Evaluates table index expressions (e.g. `table[1]`, `table["key"]`)
-- @param <Table> node The node to evaluate
-- @return <Table> result The evaluated node
-- @return <Boolean> evaluatedToConstant Whether the node evaluated to a constant
function LuaExpressionEvaluator.evaluateTableIndex(node)
  local expression = node.Expression
  local index = node.Index

  local evaluatedExpression, evaluatedExpressionToConstant = LuaExpressionEvaluator.evaluateExpression(expression)
  local evaluatedIndex, evaluatedIndexToConstant = LuaExpressionEvaluator.evaluateExpression(index)

  if evaluatedExpressionToConstant and evaluatedIndexToConstant then
    return evaluatedExpression[evaluatedIndex], true
  end

  return node, false
end

--- Evaluates expressions
-- @param <Table> node The node to evaluate
-- @return <Any> result The evaluated result
-- @return <Boolean> evaluatedToConstant Whether the node evaluated to a constant
function LuaExpressionEvaluator.evaluateExpression(node)
  if not node then return end
  local nodeType = node.TYPE

  if nodeType == "Expression" then
    return LuaExpressionEvaluator.evaluateExpression(node.Value)
  elseif nodeType == "Operator" then
    return LuaExpressionEvaluator.evaluateOperator(node)
  elseif nodeType == "UnaryOperator" then
    return LuaExpressionEvaluator.evaluateUnaryOperator(node)
  elseif nodeType == "Index" then
    return LuaExpressionEvaluator.evaluateTableIndex(node)
  elseif nodeType == "String" or nodeType == "Number" then
    return node.Value, true
  elseif nodeType == "Boolean" then
    -- Simple string-to-boolean conversion
    if node.Value == "nil" then return nil, false end
    return (node.Value == "true"), true
  elseif nodeType == "Table" then
    -- First, lets check if the table has any complex expressions
    local canOptimize = true
    local virtualTable = {}
    for index, tableElement in ipairs(node.Elements) do
      local key = tableElement.Key
      local value = tableElement.Value
      local evaluatedKey, evaluatedKeyToConstant = LuaExpressionEvaluator.evaluateExpression(key)
      local evaluatedValue, evaluatedValueToConstant = LuaExpressionEvaluator.evaluateExpression(value)
      if not evaluatedKeyToConstant or not evaluatedValueToConstant then
        canOptimize = false
        break
      end
      virtualTable[evaluatedKey] = evaluatedValue
    end
    if canOptimize then
      return virtualTable, true
    end
  end

  return node, false
end

function LuaExpressionEvaluator.convertEvaluatedValueToNode(evaluatedValue, node)
  local evaluatedValueType = type(evaluatedValue)
  if evaluatedValueType == "string" then
     -- It's better to keep the string as it is,
     -- cause i have no idea how to escape them
    return node, false
  elseif evaluatedValueType == "number" then
    if (evaluatedValue <= 1e13 and evaluatedValue >= -1e13) then
      return createNumberNode(evaluatedValue), true
    else
      return node, false -- Nah
    end
  elseif evaluatedValueType == "boolean" then
    return createConstantNode(tostring(evaluatedValue)), true
  elseif evaluatedValue == nil then
    return createConstantNode(nil), true
  elseif evaluatedValueType == "table" then
    return node, false
  end

  error("[???] Unknown constant type: " .. evaluatedValueType)
end

--- Evaluates an expression and returns a node
-- @param <Table> node The node to evaluate
-- @return <Table> result The evaluated node
-- @return <Boolean> evaluatedToConstant Whether the node evaluated to a constant
function LuaExpressionEvaluator.evaluate(node)
  if not node then return end
  local nodeType = node.TYPE
  if MAXIMALLY_EVALUATED_NODES[nodeType] then
    return node, false
  end

  local evaluatedValue, evaluatedToConstant = LuaExpressionEvaluator.evaluateExpression(node)
  if not evaluatedToConstant then
    return evaluatedValue, false
  end

  return LuaExpressionEvaluator.convertEvaluatedValueToNode(evaluatedValue, node)
end

return LuaExpressionEvaluator
