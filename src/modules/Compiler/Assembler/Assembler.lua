--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local Lexer = require("Assembler/Lexer/Lexer")
local Parser = require("Assembler/Parser/Parser")

--* Imports *--
local readFile = Helpers.readFile

--* Assembler *--
local Assembler = {}

--- Tokenizes a string of Lua source code.
-- @param str The string of Lua source code to tokenize.
-- @return A table of tokens.
function Assembler:tokenize(str)
  local tokens = Lexer:new(str):tokenize()
  return tokens
end

--- Parses a table of tokens into a table representing the parsed proto of the source code.
-- @param tokens A table of tokens.
-- @return A table representing the parsed proto of the source code.
function Assembler:parse(tokens)
  local proto = Parser:new(tokens):parse()
  return proto
end

--- Assembles a string of Lua source code into bytecode.
-- @param str The string of Lua source code to assemble.
-- @return A table representing the parsed proto of the source code.
function Assembler:assemble(str)
  local tokens = self:tokenize(str)
  local proto = self:parse(tokens)
  return proto
end

--- Loads a file containing Lua source code, assembles its contents, and returns the resulting proto.
-- @param filePath The path to the file to load.
-- @return A table representing the parsed proto of the source code.
function Assembler:loadFile(filePath)
  return self:assemble(readFile(filePath))
end

return Assembler
