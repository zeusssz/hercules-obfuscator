--* Dependencies *--
local Helpers = require("Helpers/Helpers")

--* ConversionRulesFactory *--
local ConversionRulesFactory = {}

function ConversionRulesFactory.createKeywordRule(keyword)
  return {TYPE="Keyword", Value=keyword}
end

function ConversionRulesFactory.createCharacterRule(character)
  return {TYPE="Character", Value=character}
end

function ConversionRulesFactory.createVariableListRule(variables)
  return {TYPE="VariableList", Value=variables}
end

function ConversionRulesFactory.createIdentifierRule(identifier)
  return {TYPE="Identifier", Value=identifier}
end
function ConversionRulesFactory.createIdentifierListRule(identifiers)
  return {TYPE="IdentifierList", Value=identifiers}
end

function ConversionRulesFactory.createStringIdentifierListRule(identifiers)
  return {TYPE="StringIdentifierList", Value=identifiers}
end

function ConversionRulesFactory.createStringIdentifierListWithCommasRule(identifiers)
  return {TYPE="StringIdentifierListWithCommas", Value=identifiers}
end

function ConversionRulesFactory.createParsedExpressionRule(expression)
  return {TYPE="ParsedExpression", Value=expression}
end
function ConversionRulesFactory.createParsedExpressionsRule(expressions)
  return {TYPE="ParsedExpressions", Value=expressions}
end
function ConversionRulesFactory.createParsedExpressionsWithCommasRule(expressions)
  return {TYPE="ParsedExpressionsWithCommas", Value=expressions}
end

function ConversionRulesFactory.createParsedBlockRule(block)
  return {TYPE="ParsedBlock", Value=block}
end

function ConversionRulesFactory.createParsedElseIfsRule()
  return {TYPE="ParsedElseIfs", Value="ElseIfs"}
end
function ConversionRulesFactory.createParsedElseRule()
  return {TYPE="ParsedElse", Value="Else"}
end

return ConversionRulesFactory
