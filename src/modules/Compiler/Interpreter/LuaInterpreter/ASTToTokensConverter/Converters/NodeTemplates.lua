--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local ConversionRulesFactory = require("Interpreter/LuaInterpreter/ASTToTokensConverter/Converters/ConversionRulesFactory")

--* Imports *--
local createKeywordRule = ConversionRulesFactory.createKeywordRule
local createCharacterRule = ConversionRulesFactory.createCharacterRule

local createParsedExpressionRule = ConversionRulesFactory.createParsedExpressionRule
local createParsedExpressionsRule = ConversionRulesFactory.createParsedExpressionsRule
local createParsedExpressionsWithCommasRule = ConversionRulesFactory.createParsedExpressionsWithCommasRule

local createParsedBlockRule = ConversionRulesFactory.createParsedBlockRule
local createIdentifierRule = ConversionRulesFactory.createIdentifierRule
local createStringIdentifierListRule = ConversionRulesFactory.createStringIdentifierListRule
local createStringIdentifierListWithCommasRule = ConversionRulesFactory.createStringIdentifierListWithCommasRule
local createIdentifierListRule = ConversionRulesFactory.createIdentifierListRule
local createVariableListRule = ConversionRulesFactory.createVariableListRule
local createParsedElseIfsRule = ConversionRulesFactory.createParsedElseIfsRule
local createParsedElseRule = ConversionRulesFactory.createParsedElseRule

--* NodeTemplates *--
local NodeTemplates = {}

NodeTemplates = {
  ["GenericFor"] = {
    createKeywordRule("for"),
    createStringIdentifierListWithCommasRule("IteratorVariables"),
    createKeywordRule("in"),
    createParsedExpressionsWithCommasRule("Expressions"),
    createKeywordRule("do"),
    createParsedBlockRule("CodeBlock"),
    createKeywordRule("end"),
  },
  ["NumericFor"] = {
    createKeywordRule("for"),
    createStringIdentifierListWithCommasRule("IteratorVariables"),
    createCharacterRule("="),
    createParsedExpressionsWithCommasRule("Expressions"),
    createKeywordRule("do"),
    createParsedBlockRule("CodeBlock"),
    createKeywordRule("end"),
  },

  ["BreakStatement"] = {
    createKeywordRule("break"),
  },
  ["ContinueStatement"] = {
    createKeywordRule("continue"),
  },
  ["UntilLoop"] = {
    createKeywordRule("repeat"),
    createParsedBlockRule("CodeBlock"),
    createKeywordRule("until"),
    createParsedExpressionRule("Statement"),
  },

  ["DoBlock"] = {
    createKeywordRule("do"),
    createParsedBlockRule("CodeBlock"),
    createKeywordRule("end"),
  },

  ["IfStatement"] = {
    createKeywordRule("if"),
    createParsedExpressionRule("Condition"),
    createKeywordRule("then"),
    createParsedBlockRule("CodeBlock"),
    createParsedElseIfsRule(),
    createParsedElseRule(),
    createKeywordRule("end"),
  },
  ["ElseIfStatement"] = {
    createKeywordRule("elseif"),
    createParsedExpressionRule("Condition"),
    createKeywordRule("then"),
    createParsedBlockRule("CodeBlock"),
  },
  ["ElseStatement"] = {
    createKeywordRule("else"),
    createParsedBlockRule("CodeBlock"),
  },
  ["WhileLoop"] = {
    createKeywordRule("while"),
    createParsedExpressionRule("Expression"),
    createKeywordRule("do"),
    createParsedBlockRule("CodeBlock"),
    createKeywordRule("end"),
  },

  ["RepeatStatement"] = {
    createKeywordRule("repeat"),
    createParsedBlockRule("CodeBlock"),
    createKeywordRule("until"),
    createParsedExpressionRule("Condition"),
  },
  ["ReturnStatement"] = {
    createKeywordRule("return"),
    createParsedExpressionsWithCommasRule("Expressions"),
  },
  ["VariableAssignment"] = {
    createParsedExpressionsWithCommasRule("Variables"),
    createCharacterRule("="),
    createParsedExpressionsWithCommasRule("Expressions"),
  },
}

return NodeTemplates
