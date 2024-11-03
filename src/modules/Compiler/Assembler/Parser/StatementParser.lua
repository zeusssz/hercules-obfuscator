--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* Imports *--
local insert = table.insert
local concat = table.concat
local unpack = (unpack or table.unpack)

--* Local functions *--
local function copyTable(table1)
  local table2 = {}
  for index, value in pairs(table1) do
    table2[index] = value
  end
  return table2
end

--[[
  <Identifier> {
   |    ':' : label() {
   |     |    '{': functionLabel(),
   |     |    <String>: stringLabel(),
   |     |    <Number>: numberLabel()
   |    },
   |    default: instruction()
  }
]]

--* StatementParser *--
local StatementParser = {};
function StatementParser:identifier()
  local identifierValue = self.curToken.Value
  local nextToken = self:peek()
  if self:compareToken(nextToken, "Character", ":") then
    self:consume() -- Consume the label name
    self:consume() -- Consume the colon
    return self:label(identifierValue)
  end
  return self:instruction()
end

function StatementParser:label(labelName)
  if self:compareToken(self.curToken, "Character", "{") then
    return self:labelFunction(labelName)
  elseif self:compareToken(self.curToken, "String") then
    return self:labelString(labelName)
  elseif self:compareToken(self.curToken, "Number") then
    return self:labelNumber(labelName)
  end
  return error("Invalid token: " .. tostring(self.curToken.TYPE))
end

function StatementParser:labelFunction(labelName)
  self:consume() -- Consume "{"
  local proto = self:parseFunction()
  insert(self.proto.protos, proto)
  self.labels[labelName] = #self.proto.protos
end

function StatementParser:labelString(labelName)
  local stringValue = self.curToken.Value
  self.labels[labelName] = self:findOrCreateConstant(tostring(stringValue))
end

function StatementParser:labelNumber(labelName)
  local numberValue = self.curToken.Value
  self.labels[labelName] = self:findOrCreateConstant(tonumber(numberValue))
end

function StatementParser:instructionParams()
  local params = { }
  local function insertParam(token)
    local tokenValue = token.Value
    local tokenType = token.TYPE
    if tokenType == "Identifier" then
      tokenValue = self.labels[tokenValue]
    elseif tokenType == "String" then
      tokenValue = self:findOrCreateConstant(tokenValue)
    end
    insert(params, tonumber(tokenValue) or 0)
  end

  -- Each instruction requires at least one param
  insertParam(self.curToken)
  local nextChar = self:peek()
  if self:compareToken(nextChar, "Character", ",") then
    self:consume() -- Consume the first param
    self:consume() -- Consume the comma

    -- Get params if they're separated by a comma
    repeat
      insertParam(self.curToken)
    until not (self:compareToken(self:peek(), "Character", ",") and self:consume(2) )
  end

  return params
end

function StatementParser:instruction()
  local instructionName = self.curToken.Value
  self:consume() -- Consume instruction name
  local params = self:instructionParams()
  insert(self.proto.instructions, {instructionName, unpack(params)})
end

return StatementParser
