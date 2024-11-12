--* Dependencies *--
local TokenFactory = require("Assembler/Lexer/TokenFactory")

--* Imports *--
local Helpers = require("Helpers/Helpers")
local stringToTable = Helpers.stringToTable
local insert = table.insert
local concat = table.concat

local createIdentifierToken = TokenFactory.createIdentifierToken
local createStringToken = TokenFactory.createStringToken
local createNumberToken = TokenFactory.createNumberToken
local createAttributeToken = TokenFactory.createAttributeToken
local createDirectiveToken = TokenFactory.createDirectiveToken
local createCharacterToken = TokenFactory.createCharacterToken

--* LexerMethods *--
local LexerMethods = {}

function LexerMethods:peek(n)
  return self.charStream[self.charPos + (n or 1)] or "\0"
end

function LexerMethods:consume(n)
  self.charPos = self.charPos + (n or 1)
  self.curChar = self.charStream[self.charPos] or "\0"
  return self.curChar
end

function LexerMethods:isIdentifier()
  return self.curChar:match("[%a_]")
end

function LexerMethods:consumeIdentifier()
  local identifier = {}
  repeat
    insert(identifier, self.curChar)
  until not (self:peek() and self:peek():match("[%a_]") and self:consume())
  return concat(identifier)
end

function LexerMethods:isString()
  return self.curChar == "'" or self.curChar == "\""
end

function LexerMethods:consumeString()
  local openingQuote = self.curChar
  self:consume()
  local newString = {}
  while (self.curChar ~= "\0" and self.curChar ~= openingQuote) do
    insert(newString, self.curChar)
    self:consume()
  end
  if self.curChar == "\0" then
    return error("Error: Unfinished string")
  end

  return concat(newString)
end

function LexerMethods:isNumber()
  if self.curChar == "-" then
    return self:peek():match("[%d]")
  end
  return self.curChar:match("[%d]")
end

function LexerMethods:consumeNumber()
  local number = {}
  repeat
    insert(number, self.curChar)
  until not (self:peek():match("%d") and self:consume())
  return concat(number)
end

function LexerMethods:isComment()
  return self.curChar == ";"
end

function LexerMethods:consumeComment()
  local comment = {}
  while self:peek() ~= "\n" do
    insert(comment, self:consume())
  end
  return concat(comment)
end

function LexerMethods:isWhitespace()
  return self.curChar:match("%s")
end

function LexerMethods:consumeWhitespace()
  while self:peek():match("%s") do
    self:consume()
  end
end

-- Directive ::= #<Identifier>
function LexerMethods:isDirective()
  return self.curChar == "#" and self:peek():match("[%a_]")
end

-- Attribute ::= \.<Identifier>
function LexerMethods:isAttribute()
  return self.curChar == "." and self:peek():match("[%a_]")
end

function LexerMethods:consumeDirective()
  self:consume() -- Consume "#"
  return self:consumeIdentifier()
end

function LexerMethods:consumeAttribute()
  self:consume() -- Consume "."
  return self:consumeIdentifier()
end

function LexerMethods:getCurrentToken()
  if self:isWhitespace() then
    self:consumeWhitespace()
    return
  elseif self:isIdentifier() then
    local newIdentifier = self:consumeIdentifier()
    return createIdentifierToken(newIdentifier)
  elseif self:isString() then
    local newString = self:consumeString()
    return createStringToken(newString)
  elseif self:isNumber() then
    local newNumber = self:consumeNumber()
    return createNumberToken(newNumber)
  elseif self:isComment() then
    self:consumeComment()
    return
  elseif self:isDirective() then
    local newDirective = self:consumeDirective()
    return createDirectiveToken(newDirective)
  elseif self:isAttribute() then
    local newAttribute = self:consumeAttribute()
    return createAttributeToken(newAttribute)
  else
    return createCharacterToken(self.curChar)
  end
end

function LexerMethods:tokenize()
  local tokens, tokenIndex = {}, 1
  local curChar = self.curChar
  while curChar ~= "\0" do
    local currentToken = self:getCurrentToken()
    if currentToken then
      tokens[tokenIndex] = currentToken
      tokenIndex = tokenIndex + 1
    end

    curChar = self:consume()
  end

  return tokens
end

--* Lexer *--
local Lexer = {};
function Lexer:new(assemblyCode)
  local LexerInstance = {}
  LexerInstance.charStream = stringToTable(assemblyCode)
  LexerInstance.charPos = 1
  LexerInstance.curChar = LexerInstance.charStream[1]

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if LexerInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and LexerInstance: " .. index)
      end
      LexerInstance[index] = value
    end
  end

  -- Main
  inheritModule("LexerMethods", LexerMethods)

  return LexerInstance
end

return Lexer
