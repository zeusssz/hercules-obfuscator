--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Imports *--
local insert = table.insert
local concat = table.concat

--* Constants *--
local ALLOWED_ATTRIBUTES_LOOKUP = {
  ["source"]       = true, ["lineDefined"]  = true, ["lastLineDefined"] = true,
  ["numParams"]    = true, ["numUpvalues"]  = true, ["isVararg"]        = true,
  ["maxStackSize"] = true, ["instructions"] = true, ["constants"]       = true,
  ["register"]     = true, ["upvalues"]     = true, ["protos"]          = true,
  ["lineInfo"]     = true
}


--* Preprocessor *--
local Preprocessor = {}

function Preprocessor:luaValue()
  local currentToken = self.curToken
  local currentTokenType = currentToken.TYPE
  if currentTokenType == "String" then
    return currentToken.Value
  elseif currentTokenType == "Number" then
    return tonumber(currentToken.Value)
  elseif currentTokenType == "Character" then
    local currentTokenValue = currentToken.Value
    if currentTokenValue == "[" then
      return self:list()
    elseif currentTokenValue == "{" then
      return self:table()
    end
  elseif currentTokenType == "Identifier" then
    local currentTokenValue = currentToken.Value
    if currentTokenValue == "true" or currentTokenValue == "false" then
      return currentTokenValue == "true"
    end
  end

  error("Invalid token: " .. tostring(currentTokenType) .. " (" .. tostring(currentToken.Value) .. ")")
end

-- List ::= '[' [ <value> (',' <value>)* ] ']'
function Preprocessor:list()
  self:consume() -- Consume '['
  if self:compareToken(self.curToken, "Character", "]") then
    return {}
  end

  local list = {}
  repeat
    local value = self:luaValue()
    insert(list, value)
  until not (self:compareToken(self:peek(), "Character", ",") and self:consume(2))
  self:compareToken(self:peek(), "Character", "]")
  self:consume() -- Consume ']'
  return list
end

-- Table ::= '{' [ ( <value> ':' <value> )* ] '}'
function Preprocessor:table()
  self:consume() -- Consume '{'
  if self:compareToken(self.curToken, "Character", "}") then
    return {}
  end

  local table = {}
  repeat
    local field = self:luaValue()
    local nextToken = self:consume()
    assert(self:compareToken(nextToken, "Character", ":"), "Expected table colon")
    self:consume() -- Consume the colon
    local value = self:luaValue()
    table[field] = value
  until not (self:compareToken(self:peek(), "Character", ",") and self:consume(2))
  self:compareToken(self:peek(), "Character", "}")
  self:consume() -- Consume '}'

  return table
end

-- Directive ::= <directive> \: [ <block> | <value> ]
function Preprocessor:directive()
  local directiveName = self.curToken.Value
  self:consume() -- Consume directive name
  local nextToken = self:peek()
  assert(self:compareToken(nextToken, "Character", ":"), "Expected directive colon")
  self:consume() -- Consume the colon
  if self:compareToken(self:peek(), "Character", "{") then
    return self:blockDirective(directiveName)
  elseif self:compareToken(self:peek(), "Identifier") then
    return self:valueDirective(directiveName)
  end
end

-- attribute ::= '.' <Identifier> ':' <value>
function Preprocessor:attribute(currentToken)
  local attributeName = currentToken.Value
  if not ALLOWED_ATTRIBUTES_LOOKUP[attributeName] then
    return error("Invalid attribute: " .. attributeName)
  end

  local nextToken = self:consume() -- Consume attribute name
  assert(self:compareToken(nextToken, "Character", ":"), "Expected attribute colon")
  local valueToken = self:consume() -- Consume the colon
  local valueTokenType = valueToken.TYPE
  local luaValue = self:luaValue()

  self.proto[attributeName] = luaValue
end

return Preprocessor
