--* Dependencies *--
local Helpers = require("Helpers/Helpers")

local Lexer = require("Interpreter/LuaInterpreter/Lexer/Lexer")
local Parser = require("Interpreter/LuaInterpreter/Parser/Parser")
local MathParser = require("Interpreter/LuaInterpreter/Parser/LuaMathParser/LuaMathParser")
local LuaExpressionEvaluator = require("Interpreter/LuaInterpreter/Parser/LuaMathParser/LuaExpressionEvaluator")
local ASTToTokensConverter = require("Interpreter/LuaInterpreter/ASTToTokensConverter/ASTToTokensConverter")
local InstructionGenerator = require("Interpreter/LuaInterpreter/InstructionGenerator/InstructionGenerator")

-- Useful second-level imports
local NodeSpecs = require("Interpreter/LuaInterpreter/Parser/NodeSpecs")
local NodeFactory = require("Interpreter/LuaInterpreter/Parser/NodeFactory")

--* LuaInterpreter *--
local LuaInterpreter = {}
LuaInterpreter.modules = {
  Lexer = Lexer,
  Parser = Parser,
  MathParser = MathParser,
  LuaExpressionEvaluator = LuaExpressionEvaluator,

  ASTToTokensConverter = ASTToTokensConverter,
  InstructionGenerator = InstructionGenerator,

  NodeSpecs = NodeSpecs,
  NodeFactory = NodeFactory
}

--- Converts a Lua script to tokens.
-- @param <String> script The Lua script to convert to tokens.
-- @return <Table> tokens The tokens of the Lua script.
-- @raise Error if script is not a string
function LuaInterpreter.ConvertScriptToTokens(script)
  assert(type(script) == "string", "Expected script to be a string")
  local tokens = Lexer:new(script):tokenize()
  return tokens
end

--- Converts a Lua script to an AST.
-- @param <String> script The Lua script to convert to an AST.
-- @return <Table> ast The AST of the Lua script.
-- @raise Error if script is not a string
function LuaInterpreter.ConvertScriptToAST(script)
  assert(type(script) == "string", "Expected script to be a string")
  local tokens = LuaInterpreter.ConvertScriptToTokens(script)
  local ast = Parser:new(tokens):parse()
  return ast
end

--- Converts tokens to an AST.
-- @param <Table> tokens The tokens to convert to an AST.
-- @return <Table> ast The AST of the tokens.
-- @raise Error if tokens is not a table
function LuaInterpreter.ConvertTokensToAST(tokens)
  assert(type(tokens) == "table", "Expected tokens to be a table")
  local ast = Parser:new(tokens):parse()
  return ast
end

--- Converts an AST to tokens.
-- @param <Table> ast The AST to convert to tokens.
-- @return <Table> tokens The tokens of the AST.
-- @raise Error if AST is not a table
function LuaInterpreter.ConvertASTToTokens(ast)
  assert(type(ast) == "table", "Expected AST to be a table")
  local tokens = ASTToTokensConverter:new(ast):convert()
  return tokens
end

--- Converts a Lua script to a proto.
-- @param <String> script The Lua script to convert to instructions.
-- @return <Table> proto The generated proto with instructions/constants/etc.
-- @raise Error if script is not a string
function LuaInterpreter.ConvertScriptToProto(script)
  assert(type(script) == "string", "Expected script to be a string")
  local ast = LuaInterpreter.ConvertScriptToAST(script)
  local proto = LuaInterpreter.ConvertASTToInstructions(ast)
  return proto
end

--- Converts an AST to a proto.
-- @param <Table> ast The AST to convert to instructions.
-- @return <Table> proto The generated proto with instructions/constants/etc.
-- @raise Error if AST is not a table
function LuaInterpreter.ConvertASTToProto(ast)
  assert(type(ast) == "table", "Expected AST to be a table")
  local instructionGenerator = InstructionGenerator:new(ast)
  local proto = instructionGenerator:run()
  return proto
end

return LuaInterpreter
