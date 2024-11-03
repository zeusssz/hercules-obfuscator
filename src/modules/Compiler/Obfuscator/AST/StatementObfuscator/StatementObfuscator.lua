math.randomseed(os.time())

--* Dependencies *--
local Lexer = require("Interpreter/LuaInterpreter/Lexer/Lexer")
local Parser = require("Interpreter/LuaInterpreter/Parser/Parser")
local NodeFactory = require("Interpreter/LuaInterpreter/Parser/NodeFactory")

--* Imports *--
local byte = string.byte
local floor = math.floor
local insert = table.insert
local random = math.random

--* Local functions *--
local function generateOpcodeTree(opcodes, start, stop)
  -- Base case: if the start index is greater than the stop index, return nil
  if start > stop then
    return nil
  end

  -- Calculate the midpoint of the opcode range
  local mid = math.floor((start + stop) / 2)

  -- Create a new node for the current opcode
  local node = {
    opcode = opcodes[mid].OPCode,
    nextOpcode = opcodes[mid].NextOPCode,
    node = opcodes[mid].Node,
    left = generateOpcodeTree(opcodes, start, mid - 1),
    right = generateOpcodeTree(opcodes, mid + 1, stop)
  }

  return node
end

local function recursive(codeBlockNodesOpcodes, start, stop)
  if start > stop then
    return nil
  end

  local mid = math.floor((start + stop) / 2)
  local midNode = codeBlockNodesOpcodes[mid]

  local ifStatement = NodeFactory.createIfStatementNode(
    NodeFactory.createOperatorNode("==",
      NodeFactory.createLocalVariableNode("state"),
      NodeFactory.createNumberNode(midNode.OPCode)
    ),
    { NodeFactory.createVariableAssignmentNode(
      { NodeFactory.createLocalVariableNode("state") },
      { NodeFactory.createNumberNode(midNode.NextOPCode) }
    ), midNode.Node }
  )

  local elseCodeBlock = {}
  if start < mid then
    local leftElseIfStatement = recursive(codeBlockNodesOpcodes, start, mid - 1)
    if leftElseIfStatement then
      insert(elseCodeBlock, leftElseIfStatement)
    end
  end

  if mid < stop then
    local rightElseIfStatement = recursive(codeBlockNodesOpcodes, mid + 1, stop)
    if rightElseIfStatement then
      insert(elseCodeBlock, rightElseIfStatement)
    end
  end

  if #elseCodeBlock > 0 then
    local elseStatement = NodeFactory.createElseStatementNode(elseCodeBlock)
    ifStatement.Else = elseStatement
  end

  return ifStatement
end

--* StatementObfuscator *--
local StatementObfuscator = {
  IfStatement = {},
  LocalFunction = {}
}

insert(StatementObfuscator.IfStatement, {
  String = Parser:new(
    Lexer:new([[
      while(1)do

      end
    ]]):tokenize(), false
  ):parse(),
  Function = function(self, node, interpretedString)
    if #node.ElseIfs > 0 or (node.Else and node.Else.TYPE) then
      self:traverseNode(node.Condition)
      self:obfuscateCodeBlock(node.ElseIfs)
      self:obfuscateCodeBlock(node.CodeBlock)
      self:traverseNode(node.Else)
      return
    end

    local ifStatementCondition = node.Condition
    local ifStatementCodeBlock = self:obfuscateCodeBlock(node.CodeBlock)

    local interpretedString = interpretedString[1]
    local whileLoopCodeBlock = interpretedString.CodeBlock
    interpretedString.Expression = ifStatementCondition
    for index, node in ipairs(ifStatementCodeBlock) do
      whileLoopCodeBlock[index] = node
    end
    local lastNode = interpretedString.CodeBlock[#interpretedString.CodeBlock]
    local isReturnStatement = lastNode and lastNode.TYPE == "ReturnStatement"
    if not isReturnStatement then
      insert(whileLoopCodeBlock, NodeFactory.createBreakStatementNode())
    end

    for index, value in pairs(interpretedString) do
      node[index] = value
    end
  end
})

insert(StatementObfuscator.LocalFunction, {
  Function = function(self, node, interpretedString)
    local functionCodeBlock = self:obfuscateCodeBlock(node.CodeBlock)
    if #functionCodeBlock == 0 then
      return
    end
    local codeBlockNodesOpcodes = {}
    for index, value in ipairs(functionCodeBlock) do
      codeBlockNodesOpcodes[index] = {
        OPCode = random(2, 2^22),
        Node = value
      }
    end
    for index, value in ipairs(codeBlockNodesOpcodes) do
      value.NextOPCode = ((codeBlockNodesOpcodes[index + 1] or {}).OPCode) or random(2, 2^22)
    end

    local codeBlockLocalVariables = {}
    for index, value in ipairs(codeBlockNodesOpcodes) do
      local node = value.Node
      local nodeType = node.TYPE
      if nodeType == "LocalVariableAssignment" then
        if #node.Expressions == 0 then
          node.TYPE = "DoBlock"
          node.CodeBlock = {}
        else
          node.TYPE = "VariableAssignment"
          local variables = {}
          for index, variable in ipairs(node.Variables) do
            codeBlockLocalVariables[variable] = true
            variables[index] = NodeFactory.createLocalVariableNode(variable)
          end
          node.Variables = variables
        end
      elseif nodeType == "LocalFunction" then
        local nodeCodeBlock = node.CodeBlock
        local nodeParameters = node.Parameters
        local nodeIsVararg = node.IsVararg
        local nodeName = node.Name
        codeBlockLocalVariables[node.Name] = true
        self:clearNode(node)
        node.TYPE = "VariableAssignment"
        node.Variables = {
          NodeFactory.createLocalVariableNode(nodeName)
        }
        node.Expressions = {
          NodeFactory.createFunctionNode(nodeParameters, nodeIsVararg, nodeCodeBlock)
        }
      end
    end
    local codeBlockLocalVariablesList = {}
    for variable in pairs(codeBlockLocalVariables) do
      insert(codeBlockLocalVariablesList, variable)
    end

    local ifStatement = recursive(codeBlockNodesOpcodes, 1, #codeBlockNodesOpcodes)

    local stateVariableInitialization = NodeFactory.createLocalVariableAssignmentNode(
      { "state" },
      { NodeFactory.createNumberNode( codeBlockNodesOpcodes[1].OPCode ) }
    )
    local whileStateLoop = NodeFactory.createWhileLoopNode(NodeFactory.createNumberNode(random()))
    local codeBlockLocalVariablesAssignment = NodeFactory.createLocalVariableAssignmentNode(codeBlockLocalVariablesList, {})
    insert(whileStateLoop.CodeBlock, ifStatement)

    local newCodeBlock = { TYPE = "Group" }
    insert(newCodeBlock, stateVariableInitialization)
    if #codeBlockLocalVariablesList > 0 then
      insert(newCodeBlock, codeBlockLocalVariablesAssignment)
    end
    insert(newCodeBlock, whileStateLoop)
    node.CodeBlock = newCodeBlock
  end
})

return StatementObfuscator
