local Helpers = require("Helpers/Helpers")

--* Imports *--
local stringifyTable = Helpers.stringifyTable
local sanitizeString = Helpers.sanitizeString
local find = table.find or Helpers.tableFind
local concat = table.concat
local insert = table.insert
local rep = string.rep

--* Constants *--
local IDENTIFIER_OPERATORS = {"and", "or", "not"}

--* PrinterMethods *--
local PrinterMethods = {}

function PrinterMethods:isIdentifier(token)
  local tokenType = token and token.TYPE
  local tokenValue = token and token.Value

  return  tokenType == "Identifier" or tokenType == "Constant" or
          tokenType == "Keyword"    or
        ((tokenType == "Operator"   or tokenType == "UnaryOperator") and find(IDENTIFIER_OPERATORS, tokenValue))
end

function PrinterMethods:isIdentifierOrNumber(token)
  return self:isIdentifier(token) or (token and token.TYPE == "Number")
end

function PrinterMethods:processCurrentToken(tokens, tokenIndex)
  local token = tokens[tokenIndex]
  local tokenValue = tostring(token.Value)
  local tokenType = token.TYPE
  local metadata = token._metadata

  if self:isIdentifierOrNumber(token) then
    tokenValue = ((self:isIdentifierOrNumber(tokens[tokenIndex - 1]) and " ") or "") .. tokenValue
  elseif tokenType == "String" then
    local stringType = token.StringType or "Simple"
    if stringType == "Simple" then
      local stringDelimiter = token.Delimiter or "\""
      local value = sanitizeString(token.Value, stringDelimiter)
      tokenValue = stringDelimiter .. value .. stringDelimiter
    elseif stringType == "Complex" then
      local stringDelimiter = token.Delimiter
      local start = "[" .. stringDelimiter .. "["
      local finish = "]" .. stringDelimiter .. "]"
      tokenValue = start .. token.Value .. finish
    end
  elseif tokenType == "Operator" and tokenValue == "-" and tokens[tokenIndex - 1].Value == "-" then
    tokenValue = " " .. tokenValue
  elseif tokenType == "VarArg" then
    tokenValue = "..."
  end

  return rep("  ", (metadata and metadata.indentation) or 0) .. tokenValue
end

function PrinterMethods:processTokens(tokens)
  local strings = {}

  local tokenIndex = 1
  while tokens[tokenIndex] do
    strings[tokenIndex] = self:processCurrentToken(tokens, tokenIndex)
    tokenIndex = tokenIndex + 1
  end

  return concat(strings)
end

function PrinterMethods:run()
  return self:processTokens(self.tokens)
end

--* Printer *--
local Printer = {}
function Printer:new(tokens)
  local PrinterInstance = {}
  PrinterInstance.tokens = tokens

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if PrinterInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and PrinterInstance: " .. index)
      end
      PrinterInstance[index] = value
    end
  end

  -- Main
  inheritModule("PrinterMethods", PrinterMethods)

  return PrinterInstance
end

return Printer
