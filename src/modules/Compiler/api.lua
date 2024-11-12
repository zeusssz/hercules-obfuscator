--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local Assembler = require("Assembler/Assembler")
local Lexer = require("Interpreter/LuaInterpreter/Lexer/Lexer")
local Parser = require("Interpreter/LuaInterpreter/Parser/Parser")
local InstructionGenerator = require("Interpreter/LuaInterpreter/InstructionGenerator/InstructionGenerator")
local ASTToTokensConverter = require("Interpreter/LuaInterpreter/ASTToTokensConverter/ASTToTokensConverter")
local Printer = require("Printer/Printer")
local ASTObfuscator = require("Obfuscator/AST/ASTObfuscator")
--* Imports *--
local unpack = (unpack or table.unpack)

--* API *--
local API = {
  Interpreter = {},
  InstructionGenerator = {},
  Assembler = {},
  ASTToTokensConverter = {},
  Printer = {
    TokenPrinter = {},
  },
  Obfuscator = {
    ASTObfuscator = {},
  },

  -- Expose modules for easier access in the future
  Modules = {
    Helpers              = Helpers,
    Assembler            = Assembler,
    Lexer                = Lexer,
    Parser               = Parser,
    InstructionGenerator = InstructionGenerator,
    ASTToTokensConverter = ASTToTokensConverter,
    SyntaxHighlighter    = SyntaxHighlighter,
    ASTObfuscator        = ASTObfuscator,
    Printer              = Printer,
  }
}
--* API.Interpreter *--

--- Tokenizes a Lua script and returns its tokens.
-- @param <string> script A Lua script.
-- @param <boolean> includeHighlightTokens Whether to include additional highlight tokens or not.
-- @return <table> tokens The tokens of the Lua script.
function API.Interpreter.ConvertToTokens(script, includeHighlightTokens)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local tokens = Lexer:new(script, includeHighlightTokens):tokenize()
  return tokens
end

--- Tokenizes and parses Lua script and returns its Abstract Syntax Tree.
-- @param <string> script A Lua script.
-- @return <table> AST The Abstract Syntax Tree of the Lua script.
function API.Interpreter.ConvertToAST(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local tokens = API.Interpreter.ConvertToTokens(script)
  local AST = Parser:new(tokens):parse()
  return AST
end

--- Tokenizes, parses, and converts Lua script to instructions and returns its proto.
-- @param <string> script A Lua script.
-- @return <table> proto The proto of a Lua script.
function API.Interpreter.ConvertToInstructions(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local AST = API.Interpreter.ConvertToAST(script)
  local proto = InstructionGenerator:new(AST):run()
  return proto
end

--* API.InstructionGenerator *--

--- Converts AST to instructions and returns its proto.
-- @param <table> AST The Abstract Syntax Tree of a Lua script.
-- @return <table> proto The proto of a Lua script.
function API.InstructionGenerator.ConvertASTToInstructions(AST)
  assert(type(AST) == "table", "Expected table for argument 'AST', but got " .. type(AST))

  local proto = InstructionGenerator:new(AST):run()
  return proto
end

--- Converts Lua script to instructions and returns its proto.
-- @param <string> script A Lua script.
-- @return <table> proto The proto of a Lua script.
function API.InstructionGenerator.ConvertScriptToInstructions(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local AST = API.Interpreter.ConvertToAST(script)
  local proto = API.InstructionGenerator.ConvertASTToInstructions(AST)
  return proto
end

--* API.Assembler *--

--- Tokenizes code and returns its tokens.
-- @param <string> code Assembly code.
-- @return <table> tokens The tokens of an assembly code.
function API.Assembler.Tokenize(code)
  assert(type(code) == "string", "Expected string for argument 'code', but got " .. type(code))

  local tokens = Assembler:tokenize(code)
  return tokens
end

--- Tokenizes and Parses code and returns its proto.
-- @param <string> code Assembly code.
-- @return <table> proto The proto of the code.
function API.Assembler.Parse(code)
  assert(type(code) == "string", "Expected string for argument 'code', but got " .. type(code))

  local tokens = Assembler:tokenize(code)
  local proto = Assembler:parse(tokens)
  return proto
end

--* API.ASTToTokensConverter *--

--- Convert the given Abstract Syntax Tree to tokens and return it
-- @param <table> AST The Abstract Syntax Tree of a Lua script.
-- @return <table> tokens The tokens of the given Abstract Syntax Tree.
function API.ASTToTokensConverter.ConvertToTokens(AST)
  assert(type(AST) == "table", "Expected table for argument 'AST', but got " .. type(AST))

  local tokens = ASTToTokensConverter:new(AST):convert()
  return tokens
end

--* API.Obfuscator *--

--* API.Obfuscator.ASTObfuscator *--

--- Obfuscate an Abstract Syntax Tree.
-- @param <table> ast The Abstract Syntax Tree of a Lua script.
-- @return <table> obfuscatedAST The obfuscated Abstract Syntax Tree.
function API.Obfuscator.ASTObfuscator.ObfuscateAST(ast)
  assert(type(ast) == "table", "Expected table for argument 'ast', but got " .. type(ast))

  local obfuscatedAST = ASTObfuscator:new(ast):obfuscate()
  -- Convert that ast to tokens -> code -> ast
  -- because we need to update the ast with new metadata
  -- and it's currently the only way to do that
  local obfuscatedASTTokens = ASTToTokensConverter:new(obfuscatedAST):convert()
  local obfuscatedCode = Printer:new(obfuscatedASTTokens):run()
  local obfuscatedAST = API.Interpreter.ConvertToAST(obfuscatedCode)

  return obfuscatedAST
end

--- Obfuscate a Lua script.
-- @param <string> script A Lua script.
-- @return <string> obfuscatedScript The obfuscated version of the given Lua script.
function API.Obfuscator.ASTObfuscator.ObfuscateScript(script)
  assert(type(script) == "string", "Expected string for argument 'script', but got " .. type(script))

  local AST = API.Interpreter.ConvertToAST(script)
  local obfuscatedAST = API.Obfuscator.ASTObfuscator.ObfuscateAST(AST)
  local obfuscatedASTTokens = ASTToTokensConverter:new(obfuscatedAST):convert()
  local obfuscatedScript = Printer:new(obfuscatedASTTokens):run()
  return obfuscatedScript
end

return API
