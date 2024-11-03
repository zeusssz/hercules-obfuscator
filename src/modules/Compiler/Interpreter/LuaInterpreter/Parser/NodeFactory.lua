--* Imports *--
local unpack = (unpack or table.unpack)

--* NodeFactory *--
local NodeFactory = {}

-- Normal group
function NodeFactory.createGroup(nodeList)
  nodeList = nodeList or {}
  nodeList.TYPE = "Group"
  return nodeList
end

function NodeFactory.createExpressionNode(value, expectedReturnValueCount)
  return { TYPE = "Expression", Value = value, ExpectedReturnValueCount = (expectedReturnValueCount or 0)}
end

function NodeFactory.createASTNode(...)
  return { TYPE = "AST", ... }
end

-- Binary operation (e.g., a + b)
function NodeFactory.createOperatorNode(operatorValue, leftExpr, rightExpr, precedence)
  return { TYPE = "Operator",
    Value = operatorValue,
    Left = leftExpr, Right = rightExpr,
    Precedence = precedence }
end
-- Unary operation (e.g., -a)
function NodeFactory.createUnaryOperatorNode(operatorValue, operand, precedence)
  return { TYPE = "UnaryOperator",
  Value = operatorValue,
  Operand = operand,
  Precedence = precedence }
end

-- Function call (e.g., expression(arg1, arg2) )
function NodeFactory.createFunctionCallNode(expression, arguments, expectedReturnValueCount)
  return { TYPE = "FunctionCall",
  Expression = expression,
  Arguments = NodeFactory.createGroup(arguments),
  ExpectedReturnValueCount = expectedReturnValueCount or 0 }
end
-- Method call (e.g., table:fieldName(arg1, arg2) )
function NodeFactory.createMethodCallNode(expression, arguments, expectedReturnValueCount)
  return { TYPE = "MethodCall",
  Expression = expression,
  Arguments = NodeFactory.createGroup(arguments),
  ExpectedReturnValueCount = expectedReturnValueCount or 0 }
end

-- Identifier (e.g., variable name)
function NodeFactory.createIdentifierNode(value)
  return { TYPE = "Identifier", Value = value }
end
-- Number literal
function NodeFactory.createNumberNode(value)
  return { TYPE = "Number", Value = value }
end
-- String literal
function NodeFactory.createStringNode(value)
  return { TYPE = "String", Value = value }
end
-- Boolean literal
function NodeFactory.createBooleanNode(value)
  return { TYPE = "Boolean", Value = value }
end
-- Constant literal (including nil)
function NodeFactory.createConstantNode(value)
  return { TYPE = "Constant", Value = value }
end

-- Local variable
function NodeFactory.createLocalVariableNode(value)
  return { TYPE = "Variable",
  VariableType = "Local",
  Value = value }
end

-- Global variable
function NodeFactory.createGlobalVariableNode(value)
  return { TYPE = "Variable",
  VariableType = "Global",
  Value = value }
end

-- Upvalue
function NodeFactory.createUpvalueNode(value, upvalueLevel)
  return { TYPE = "Variable",
  VariableType = "Upvalue",
  Value = value,
  UpvalueLevel = upvalueLevel }
end

-- Indexing operation (e.g., a[b])
function NodeFactory.createIndexNode(index, expression)
  return { TYPE = "Index", Index = index, Expression = expression }
end
-- Method indexing (e.g., obj:m)
function NodeFactory.createMethodIndexNode(index, expression)
  return { TYPE = "MethodIndex", Index = index, Expression = expression }
end

-- Table constructor (e.g., {a, b})
function NodeFactory.createTableNode(elements)
  return { TYPE = "Table", Elements = elements }
end
-- Table element (key-value pair)
function NodeFactory.createTableElementNode(key, value, implicitKey)
  return { TYPE = "TableElement", Key = key, Value = value, ImplicitKey = implicitKey }
end

-- Function definition (e.g., function(a, b) return a + b end)
function NodeFactory.createFunctionNode(parameters, isVararg, codeBlock)
  return { TYPE = "Function", Parameters = parameters, IsVararg = isVararg, CodeBlock = NodeFactory.createGroup(codeBlock) }
end
-- Local function definition (e.g., local function func(a, b) return a + b end)
function NodeFactory.createLocalFunctionNode(name, parameters, isVararg, codeBlock)
  return { TYPE = "LocalFunction", Name = name, Parameters = parameters, IsVararg = isVararg, CodeBlock = NodeFactory.createGroup(codeBlock) }
end
-- Function declaration with fields (e.g., function obj.func(a, b) return a + b end)
function NodeFactory.createFunctionDeclarationNode(parameters, isVararg, codeBlock, expression, fields)
  return { TYPE = "FunctionDeclaration",
    Parameters = parameters,
    IsVararg = isVararg,
    CodeBlock = NodeFactory.createGroup(codeBlock),
    Expression = expression,
    Fields = fields }
end
-- Method declaration with fields (e.g., function obj:func(a, b) return a + b end)
function NodeFactory.createMethodDeclarationNode(parameters, isVararg, codeBlock, expression, fields)
  return { TYPE = "MethodDeclaration",
    Parameters = parameters,
    IsVararg = isVararg,
    CodeBlock = NodeFactory.createGroup(codeBlock),
    Expression = expression,
    Fields = fields }
end

-- Variable assignment
function NodeFactory.createVariableAssignmentNode(variables, expressions)
  return { TYPE = "VariableAssignment",
    Variables = NodeFactory.createGroup(variables),
    Expressions = NodeFactory.createGroup(expressions) }
end
-- Local variable assignment
function NodeFactory.createLocalVariableAssignmentNode(variables, expressions)
  return { TYPE = "LocalVariableAssignment",
    Variables = variables,
    Expressions = NodeFactory.createGroup(expressions) }
end

-- If statement with else-ifs and else
function NodeFactory.createIfStatementNode(condition, codeBlock, elseIfs, elseStatement)
  return { TYPE = "IfStatement", Condition = condition, CodeBlock = NodeFactory.createGroup(codeBlock), ElseIfs = NodeFactory.createGroup(elseIfs), Else = elseStatement }
end
-- Else-if clause in an if statement
function NodeFactory.createElseIfStatementNode(condition, codeBlock)
  return { TYPE = "ElseIfStatement", Condition = condition, CodeBlock = NodeFactory.createGroup(codeBlock)  }
end
-- Else clause in an if statement
function NodeFactory.createElseStatementNode(codeBlock)
  return { TYPE = "ElseStatement", CodeBlock = NodeFactory.createGroup(codeBlock) }
end

-- Do block statement
function NodeFactory.createDoBlockNode(codeBlock)
  return { TYPE = "DoBlock", CodeBlock = NodeFactory.createGroup(codeBlock) }
end

-- Until loop statement
function NodeFactory.createUntilLoopNode(codeBlock, statement)
  return { TYPE = "UntilLoop", CodeBlock = NodeFactory.createGroup(codeBlock), Statement = statement }
end
-- While loop statement
function NodeFactory.createWhileLoopNode(expression, codeBlock)
  -- TODO: Rename "Expression" to "Condition", can't do it rn, cause of the sole amount of changed we'd have to do.
  return { TYPE = "WhileLoop", Expression = expression, CodeBlock = NodeFactory.createGroup(codeBlock) }
end

-- Generic for loop statement
function NodeFactory.createGenericForNode(iteratorVariables, expressions, codeBlock)
  return {
    TYPE = "GenericFor",
    IteratorVariables = iteratorVariables,
    Expressions = expressions,
    CodeBlock = NodeFactory.createGroup(codeBlock)
  }
end
-- Numeric for loop statement
function NodeFactory.createNumericForNode(iteratorVariables, expressions, codeBlock)
  return {
    TYPE = "NumericFor",
    IteratorVariables = iteratorVariables,
    Expressions = NodeFactory.createGroup(expressions),
    CodeBlock = NodeFactory.createGroup(codeBlock)
  }
end

-- Return statement in functions
function NodeFactory.createReturnStatementNode(expressions)
  return { TYPE = "ReturnStatement", Expressions = NodeFactory.createGroup(expressions) }
end

-- Continue statement in loops
function NodeFactory.createContinueStatementNode()
  return { TYPE = "ContinueStatement" }
end
-- Break statement in loops
function NodeFactory.createBreakStatementNode()
  return { TYPE = "BreakStatement" }
end

return NodeFactory
