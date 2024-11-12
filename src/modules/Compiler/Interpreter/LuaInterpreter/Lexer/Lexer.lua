--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local TokenFactory = require("Interpreter/LuaInterpreter/Lexer/TokenFactory")

--* Imports *--
local insert = table.insert
local concat = table.concat
local match = string.match
local stringChar = string.char
local rep = string.rep
local find = table.find or Helpers.tableFind
local stringToTable = Helpers.stringToTable

local createEOFToken           = TokenFactory.createEOFToken
local createNewLineToken       = TokenFactory.createNewLineToken
local createVarArgToken        = TokenFactory.createVarArgToken
local createWhitespaceToken    = TokenFactory.createWhitespaceToken
local createCommentToken       = TokenFactory.createCommentToken
local createNumberToken        = TokenFactory.createNumberToken
local createConstantToken      = TokenFactory.createConstantToken
local createOperatorToken      = TokenFactory.createOperatorToken
local createKeywordToken       = TokenFactory.createKeywordToken
local createIdentifierToken    = TokenFactory.createIdentifierToken
local createCharacterToken     = TokenFactory.createCharacterToken
local createStringToken        = TokenFactory.createStringToken

--* Local functions *--
local function makeTrie(table)
  local trieTable = {}
  local longestElement = 0

  for _, op in ipairs(table) do
    if #op > longestElement then
      longestElement = #op
    end

    local node = trieTable
    for index = 1, #op do
      local character = op:sub(index, index)
      node[character] = node[character] or {}
      node = node[character]
    end
    node.Value = op
  end
  return trieTable, longestElement
end
local function createPatternLookupTable(pattern)
  local lookupTable = {}
  for i = 0, 255 do
    local char = stringChar(i)
    if match(char, pattern) then
      lookupTable[char] = true
    end
  end
  return lookupTable
end

--* Constants *--
local ESCAPED_CHARACTER_CONVERSIONS = {
  ["a"]     = "\a", -- bell
  ["b"]     = "\b", -- backspace
  ["f"]     = "\f", -- form feed
  ["n"]     = "\n", -- newline
  ["r"]     = "\r", -- carriage return
  ["t"]     = "\t", -- horizontal tab
  ["v"]     = "\v", -- vertical tab

  [ "\\" ] = "\\",   -- backslash
  [ "\"" ] = "\"",  -- double quote
  [ "\'" ] = "\'",  -- single quote
}

local WHITESPACE_CHARACTERS = createPatternLookupTable("%s")
local IDENTIFIER_CHARACTERS1 = createPatternLookupTable("[%a_]")
local IDENTIFIER_CHARACTERS2 = createPatternLookupTable("[%a%d_]")
local DECIMAL_CHARACTERS = createPatternLookupTable("[%d]")
local HEXADECIMAL_CHARACTERS = createPatternLookupTable("[%da-fA-F]")
local HEXADECIMAL_PREFIX = createPatternLookupTable("[xX]")
local SCIENTIFIC_NOTATION_PREFIX = createPatternLookupTable("[eE]")
local PLUS_MINUS = createPatternLookupTable("[+-]")
local SIMPLE_STRING_DELIMITERS = createPatternLookupTable("[\"']")
local COMPLEX_STRING_DELIMITERS1 = createPatternLookupTable("[%[]")
local COMPLEX_STRING_DELIMITERS2 = createPatternLookupTable("[%[=]")


local CONSTANTS = { "false", "true", "nil" }

local RESERVED_KEYWORDS = {
  "while",    "do",     "end",   "for",
  "local",    "repeat", "until", "return",
  "in",       "if",     "else",  "elseif",
  "function", "then",   "break", "continue"
}

local OPERATORS = {
  "^", "*", "/", "%",
  "+", "-", "<", ">",
  "#",

  "<=",  ">=", "==",  "~=",
  "and", "or", "not", ".."
}

local CONSTANT_TRIE, LONGEST_CONSTANT = makeTrie(CONSTANTS)
local OPERATOR_TRIE, LONGEST_OPERATOR = makeTrie(OPERATORS)

--* LexerMethods *--
local LexerMethods = {}

function LexerMethods:peek(n)
  return ((self.charStream[self.curCharPos + (n or 1)]) or "\0")
end

function LexerMethods:consume(n)
  self.curCharPos = (self.curCharPos + (n or 1))
  self.curChar = ((self.charStream[self.curCharPos]) or "\0")
  return self.curChar
end

function LexerMethods:insertToken(token)
  token.Line = self.lineCounter
  return insert(self.tokens, token)
end

function LexerMethods:readWhileChar(char)
  local str = {}
  while self.curChar == char do
    insert(str, self.curChar)
    self:consume()
  end
  return concat(str)
end

function LexerMethods:isNumber()
  local char = self.curChar

  return (DECIMAL_CHARACTERS[char])
          or (char == "." and DECIMAL_CHARACTERS[self:peek()] )
end

function LexerMethods:isIdentifier(char)
  local char = char or self.curChar
  return IDENTIFIER_CHARACTERS1[char]
end

function LexerMethods:isVarArg()
  local function checkChar(char) return char == "." end
  return checkChar(self.curChar) and checkChar(self:peek(1)) and checkChar(self:peek(2))
end

-- function LexerMethods:isWhitespace(char)
--  local char = char or self.curChar
--  return WHITESPACE_CHARACTERS[char]
-- end

function LexerMethods:consumeWhitespace()
  local whitespace, whitespaceIndex = { self.curChar }, 2
  local nextChar = self:peek()
  while WHITESPACE_CHARACTERS[nextChar] do
    whitespace[whitespaceIndex] = self:consume()
    whitespaceIndex = whitespaceIndex + 1
    nextChar = self:peek()
  end
  return self.includeHighlightTokens and concat(whitespace)
end

function LexerMethods:consumeIdentifier()
  local identifier = {self.curChar}
  while IDENTIFIER_CHARACTERS2[self:peek()] do
    insert(identifier, self:consume())
  end
  return concat(identifier)
end

function LexerMethods:consumeInteger(maxLength)
  local integer = {self.curChar}
  while DECIMAL_CHARACTERS[self:peek()] do
    if #integer >= maxLength then break end
    insert(integer, self:consume())
  end
  return concat(integer)
end

--- Consumes the next hexadecimal number from the character stream.
-- @param <Table> number The number character table to append the next number to.
-- @return <Table> number The parsed hexadecimal number.
function LexerMethods:consumeHexNumber(number)
  insert(number, self:consume()) -- consume 'x' or 'X'
  while HEXADECIMAL_CHARACTERS[self:peek()] do
    insert(number, self:consume())
  end
  return number
end

--- Consumes the next floating point number from the character stream.
-- @param <Table> number The number character table to append the next number to.
-- @return <Tabel> number The parsed floating point number.
function LexerMethods:consumeFloatNumber(number)
  insert(number, self:consume())
  while DECIMAL_CHARACTERS[self:peek()] do
    insert(number, self:consume())
  end
  return number
end

--- Consumes the next number in scientific notation from the character stream.
-- @param <Table> number The number character table to append the next number to.
-- @return <Table> number The parsed number in scientific notation
function LexerMethods:consumeScientificNumber(number)
  insert(number, self:consume()) -- consume 'e' or 'E'
  if PLUS_MINUS[self:peek()] then
    insert(number, self:consume()) -- consume '+' or '-'
  end
  while DECIMAL_CHARACTERS[self:peek()] do
    insert(number, self:consume())
  end
  return number
end

--- Consumes the next number from the character stream.
-- @return <String> number The next number.
function LexerMethods:consumeNumber()
  local number = { self.curChar }
  local isFloat = false
  local isScientific = false
  local isHex = false

  -- Check for hexadecimal numbers
  local nextChar = self:peek()
  if self.curChar == '0' and (HEXADECIMAL_PREFIX[nextChar]) then
    local isHex = true
    return concat(self:consumeHexNumber(number)), isFloat, isScientific, isHex
  end

  while DECIMAL_CHARACTERS[self:peek()] do
    insert(number, self:consume())
  end

  -- Check for floating point numbers
  if self:peek() == "." then
    isFloat = true
    number = self:consumeFloatNumber(number)
  end

  -- Check for scientific notation
  if SCIENTIFIC_NOTATION_PREFIX[self:peek()] then
    isScientific = true
    number = self:consumeScientificNumber(number)
  end

  return concat(number), isFloat, isScientific, isHex
end

function LexerMethods:expectChars(...)
  local expectedChars = {...}
  local curChar = self.curChar

  if find(expectedChars, curChar) then
    return self:consume()
  end
  error(("Error: Expected one of characters: {%s}, got: %s"):format(concat(expectedChars, ", "), curChar))
end

function LexerMethods:readWhileNotString(targetString, allowUnexpectedEnd)
  local stringTb = stringToTable(targetString)
  local stringLen = #targetString
  local matchedIndex = 1

  local returnString = {}
  while matchedIndex <= stringLen do
    local curChar = self.curChar
    if curChar == "\0" then
      if allowUnexpectedEnd then
        return concat(returnString):sub(0, -matchedIndex)
      end
      return error("Unexpected end")
    elseif stringTb[matchedIndex] == curChar then
      matchedIndex = matchedIndex + 1
      if matchedIndex > stringLen then
        break
      end
    else
      matchedIndex = 1
    end
    insert(returnString, curChar)
    self:consume()
  end

  return concat(returnString):sub(0, -matchedIndex)
end

function LexerMethods:isString()
  local curChar = self.curChar
  local nextChar = self:peek()

  return SIMPLE_STRING_DELIMITERS[curChar]
        or (COMPLEX_STRING_DELIMITERS1[curChar] and COMPLEX_STRING_DELIMITERS2[nextChar])
end

function LexerMethods:isComment()
  return self.curChar == "-" and self:peek() == "-"
end

function LexerMethods:consumeOperator()
  local node = OPERATOR_TRIE
  local operator

  for index = 0, LONGEST_OPERATOR - 1 do
    -- Use peek() instead of consume(), so we'll avoid backtracking
    local character = self:peek(index)
    node = node[character]
    if not node then break end
    if node.Value then operator = node.Value end
  end
  if operator then self:consume(#operator - 1) end
  return operator
end

function LexerMethods:consumeConstant()
  local node = CONSTANT_TRIE
  local constant
  for index = 0, LONGEST_CONSTANT - 1 do
    local character = self:peek(index)
    node = node[character]
    if not node then break end
    if node.Value then constant = node.Value end
  end
  if constant then self:consume(#constant - 1) end
  return constant
end

function LexerMethods:consumeSimpleString()
  local newString = {}
  local startQuote = self.curChar
  if self.includeHighlightTokens then
    insert(newString, self.curChar)
  end
  self:consume()

  local startPos = self.curCharPos
  local curChar = self.curChar
  while curChar ~= startQuote do
    if curChar == "\\" then
      local nextChar = self:consume()
      if DECIMAL_CHARACTERS[nextChar] then
        local number = self:consumeInteger(3)
        insert(newString, stringChar(tonumber(number)))
      elseif ESCAPED_CHARACTER_CONVERSIONS[nextChar] then
        insert(newString, ESCAPED_CHARACTER_CONVERSIONS[nextChar])
      else
        -- insert(newString, nextChar)
        error("invalid escape sequence near '\\" .. nextChar .. "'")
      end
    else
      insert(newString, curChar)
    end
    curChar = self:consume()
  end

  if self.includeHighlightTokens then
    insert(newString, self.curChar)
  end
  return concat(newString)
end

function LexerMethods:consumeComplexString()
  self:expectChars("[")
  local depth = #self:readWhileChar("=")
  local delimiter = rep("=", depth)
  self:expectChars("[")

  local targetString = "]" .. delimiter .. "]"
  local stringTb = stringToTable(targetString)
  local stringLen = #targetString
  local matchedIndex = 1

  local returnString = {}
  while matchedIndex <= stringLen do
    local curChar = self.curChar
    if curChar == "\0" then
      return error("Unexpected end")
    elseif stringTb[matchedIndex] == curChar then
      matchedIndex = matchedIndex + 1
      if matchedIndex > stringLen then
        break
      end
    else
      matchedIndex = 1
    end
    insert(returnString, curChar)
    self:consume()
  end

  return concat(returnString):sub(0, (-matchedIndex) + 1), delimiter
end

function LexerMethods:consumeComplexComment()
  self:expectChars("[")
  local depth = #self:readWhileChar("=")
  self:expectChars("[")

  local comment = {}
  if self.includeHighlightTokens then
    insert(comment, "--")
    insert(comment, "[")
    insert(comment, rep("=", depth))
    insert(comment, "[")
  end

  while self.curChar ~= "\0" do
    local curChar = self.curChar
    if curChar == "\0" then
      return error("Unexpected end")
    elseif curChar == "\n" then
      self.lineCounter = self.lineCounter + 1
    elseif curChar == "]" then
      local depthCounter = 0
      while self:peek(depthCounter + 1) == "=" do
        depthCounter = depthCounter + 1
      end
      if self:peek(depthCounter + 1) == "]" and depthCounter == depth then
        self:consume(depthCounter + 1)
        if self.includeHighlightTokens then
          insert(comment, "]")
          insert(comment, rep("=", depth))
          insert(comment, "]")
        end
        break
      end

    end
    insert(comment, curChar)
    self:consume()
  end

  return concat(comment)
end

function LexerMethods:consumeComment()
  self:expectChars("-")
  self:expectChars("-")

  local curChar = self.curChar
  local nextChar = self:peek()
  if curChar == '[' and (nextChar == '[' or nextChar == "=") then
    return self:consumeComplexComment()
  else
    local comment = self:readWhileNotString("\n", true)
    if self.includeHighlightTokens then
      comment = "--" .. comment
    end
    self:consume(-1)
    return comment
  end
end

function LexerMethods:tokenizeNextToken()
  local curChar = self.curChar
  if curChar == "\n" then
    self.lineCounter = self.lineCounter + 1
    if self.includeHighlightTokens then
      return self:insertToken(createNewLineToken())
    end
    return
  elseif WHITESPACE_CHARACTERS[curChar] then
    local whitespace = self:consumeWhitespace()
    if self.includeHighlightTokens then
      return self:insertToken(createWhitespaceToken(whitespace))
    end
    return
  elseif self:isComment() then
    local comment = self:consumeComment()
    insert(self.comments, {
      Position = #self.tokens,
      Value = comment
    })
    if self.includeHighlightTokens then
      return self:insertToken(createCommentToken(comment))
    end
    return
  elseif self:isNumber() then
    local newNumber, isFloat, isScientific, isHex = self:consumeNumber()
    local isLua53OrHigher = utf8 ~= nil
    local realNumber = tonumber(newNumber)
    -- Prevent some obfuscatated code from breaking due to detections like these:
    -- if (9007199254740992 % 15) ~= 2 then error("Code transformation detected") end
    -- Lua5.3+ fixes this issue by using 64-bit integers n_n
    if isLua53OrHigher or (realNumber <= 1e13 and realNumber >= -1e13) then
      return self:insertToken(createNumberToken(realNumber))
    end
    return self:insertToken(createNumberToken(newNumber))
  elseif self:isIdentifier() then
    local newIdentifier = self:consumeIdentifier()
    if find(CONSTANTS, newIdentifier) then
      local constantValue = newIdentifier
      return self:insertToken(createConstantToken(constantValue))
    elseif find(OPERATORS, newIdentifier) then
      return self:insertToken(createOperatorToken(newIdentifier))
    elseif find(RESERVED_KEYWORDS, newIdentifier) then
      return self:insertToken(createKeywordToken(newIdentifier))
    else
      return self:insertToken(createIdentifierToken(newIdentifier))
    end
  elseif self:isString() then
    local delimiter = self.curChar
    if delimiter == "'" or delimiter == '"' then -- Simple string
      local newString = self:consumeSimpleString()
      return self:insertToken(createStringToken(newString, "Simple", delimiter))
    else -- Complex string
      local newString, newDelimiter = self:consumeComplexString()
      return self:insertToken(createStringToken(newString, "Complex", newDelimiter))
    end
  elseif self:isVarArg() then
    self:consume(2) -- Consume two "." characters
    return self:insertToken(createVarArgToken())
  end

  local operator = self:consumeOperator()
  if operator then
    return self:insertToken(createOperatorToken(operator))
  end

  return self:insertToken(createCharacterToken(curChar))
end

-- Main (public)
function LexerMethods:tokenize()
  while self.curChar ~= "\0" do
    self:tokenizeNextToken()
    self:consume()
  end

  return self.tokens
end

--- Resets the lexer to its initial state so it can be reused.
-- @param string The string to reset the lexer to.
-- @param includeHighlightTokens Whether to include highlight tokens in the tokenization.
function LexerMethods:resetToInitialState(string, includeHighlightTokens)
  self.includeHighlightTokens = includeHighlightTokens
  self.charStream = stringToTable(string)
  self.curCharPos = 1
  self.lineCounter = 1
  self.curChar = self.charStream[1] or "\0"
  self.tokens = {}
  self.comments = {}
end

--* Lexer *--
local Lexer = {}
function Lexer:new(string, includeHighlightTokens)
  local LexerInstance = {}

  LexerInstance.includeHighlightTokens = includeHighlightTokens
  LexerInstance.charStream = string and stringToTable(string)
  LexerInstance.curCharPos = 1
  LexerInstance.lineCounter = 1
  LexerInstance.curChar = string and LexerInstance.charStream[1] or "\0"
  LexerInstance.tokens = {}
  LexerInstance.comments = {}

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
