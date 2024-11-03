--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local Proto = require("Structures/Proto")

local StatementParser = require("Assembler/Parser/StatementParser")
local Preprocessor = require("Assembler/Parser/Preprocessor/Preprocessor")

--* Constants *--
local STOP_CHARACTER_TOKENS_LOOKUP = {
  ["}"] = true
}

--* Imports *--
local find = Helpers.tableFind
local insert = table.insert
local concat = table.concat

--* ParserMethods *--
local ParserMethods = {}

function ParserMethods:peek(n)
  return self.tokens[self.tokenPos + (n or 1)]
end

function ParserMethods:consume(n)
  self.tokenPos = self.tokenPos + (n or 1)
  self.curToken = self.tokens[self.tokenPos]
  return self.curToken
end

function ParserMethods:findOrCreateConstant(value)
  local constants = self.proto.constants
  local constantIndex = find(constants, value)
  if not constantIndex then
    insert(constants, value)
    constantIndex = #constants
  end
  return -constantIndex
end

function ParserMethods:compareToken(token, type, value)
  if (token and token.TYPE == type and (not value or token.Value == value)) then
    return true
  end
  return false
end

function ParserMethods:expectCurToken(type, value, dontConsume)
  local curToken = self.curToken
  if not curToken or not (curToken.TYPE == type and curToken.Value == value) then
    return error("Expected token type: " .. type .. " (" .. value .. ")")
  end
  if not dontConsume then self:consume() end
  return curToken
end

function ParserMethods:parseToken()
  local currentToken = self.curToken
  local currentTokenType = currentToken.TYPE
  if currentTokenType == "Identifier" then
    return self:identifier()
  elseif currentTokenType == "String" then
    return self:findOrCreateConstant(currentToken.Value)
  elseif currentTokenType == "Number" then
    return self:findOrCreateConstant(tonumber(currentToken.Value))

  -- Pre-processor stuff
  elseif currentTokenType == "Attribute" then
    return self:attribute(currentToken)
  elseif currentTokenType == "Directive" then
    return self:directive(currentToken)
  end

  return error("Unexpected token type: " .. tostring(currentToken.TYPE) .. " (" .. currentToken.Value .. ")")
end

function ParserMethods:parseTokens(stopAtStopTokens)
  local currentToken = self.curToken
  while currentToken do
    if stopAtStopTokens and STOP_CHARACTER_TOKENS_LOOKUP[currentToken.Value] then
      break
    end

    self:parseToken()
    currentToken = self:consume()
  end
end

function ParserMethods:parseFunction()
  local oldProto = self.proto
  local newProto = Proto:new()
  newProto.constants = oldProto.constants

  self.proto = newProto
  self:parseTokens(true)
  self.proto = oldProto
  return newProto
end

-- Main (public)
function ParserMethods:parse()
  self:parseTokens()
  return self.proto
end

--* Parser *--
local Parser = {};
function Parser:new(tokens, proto)
  local ParserInstance = {}
  ParserInstance.tokens = tokens
  ParserInstance.tokenPos = 1
  ParserInstance.curToken = tokens[1]
  ParserInstance.proto = (proto or Proto:new())
  ParserInstance.labels = {}

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if ParserInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and ParserInstance: " .. index)
      end
      ParserInstance[index] = value
    end
  end

  -- Main
  inheritModule("ParserMethods", ParserMethods)

  inheritModule("StatementParser", StatementParser)
  inheritModule("Preprocessor", Preprocessor)

  return ParserInstance
end

return Parser
