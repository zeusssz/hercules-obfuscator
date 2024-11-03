--* TokenFactory *--
local TokenFactory = {}

function TokenFactory.createIdentifierToken(value)
  return { TYPE = "Identifier", Value = value }
end
function TokenFactory.createStringToken(value)
  return { TYPE = "String", Value = value }
end
function TokenFactory.createNumberToken(value)
  return { TYPE = "Number", Value = value }
end
function TokenFactory.createCharacterToken(value)
  return { TYPE = "Character", Value = value }
end
function TokenFactory.createAttributeToken(value)
  return { TYPE = "Attribute", Value = value }
end
function TokenFactory.createDirectiveToken(value)
  return { TYPE = "Directive", Value = value }
end

return TokenFactory
