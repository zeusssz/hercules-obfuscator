--[[
  Types of Fields:
    - Node: A node
    - NodeList: A list of nodes
    - OptionalNode: A node or nil
--]]

local NodeSpecs = {
  --/// Primitive nodes \\\--
  Identifier          = { },
  Constant            = { },
  Number              = { },
  String              = { },
  Boolean             = { },
  VarArg              = { },
  Variable            = { },

  --/// Operator nodes \\\--
  Operator            = { Left    = "Node", Right = "Node" },
  UnaryOperator       = { Operand = "Node"                 },

  --/// Expression nodes \\\--
  Expression          = { Value      = "Node"                          },
  FunctionCall        = { Expression = "Node", Arguments  = "NodeList" },
  MethodCall          = { Expression = "Node", Arguments  = "NodeList" },
  Index               = { Index      = "Node", Expression = "Node"     },
  MethodIndex         = { Index      = "Node", Expression = "Node"     },

  --/// Table nodes \\\--
  Table               = { Elements = "NodeList"             },
  TableElement        = { Key      = "Node", Value = "Node" },

  --/// Function nodes \\\--
  Function            = { CodeBlock = "NodeList"                      },
  FunctionDeclaration = { CodeBlock = "NodeList", Expression = "Node" },
  MethodDeclaration   = { CodeBlock = "NodeList", Expression = "Node" },
  LocalFunction       = { CodeBlock = "NodeList"                      },

  --/// Assignment nodes \\\--
  VariableAssignment      = { Variables   = "NodeList", Expressions = "NodeList" },
  LocalVariableAssignment = { Expressions = "NodeList"                           },

  --/// Control flow nodes \\\--
  IfStatement             = { Condition   = "Node",    CodeBlock = "NodeList", ElseIfs = "NodeList", Else = "OptionalNode" },
  ElseIfStatement         = { Condition   = "Node",    CodeBlock = "NodeList"                                              },
  ElseStatement           = { CodeBlock   = "NodeList"                                                                     },
  DoBlock                 = { CodeBlock   = "NodeList"                                                                     },
  ReturnStatement         = { Expressions = "NodeList"                                                                     },
  ContinueStatement       = { },
  BreakStatement          = { },

  --/// Loop nodes \\\--
  GenericFor          = { Expressions = "NodeList", CodeBlock = "NodeList" },
  NumericFor          = { Expressions = "NodeList", CodeBlock = "NodeList" },
  WhileLoop           = { Expression  = "Node",     CodeBlock = "NodeList" },
  UntilLoop           = { Statement   = "Node",     CodeBlock = "NodeList" }
}

return NodeSpecs
