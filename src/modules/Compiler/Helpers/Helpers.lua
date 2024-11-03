--* Import library functions *--
local rep    = string.rep
local gmatch = string.gmatch
local char   = string.char
local byte   = string.byte
local gsub   = string.gsub
local len    = string.len
local format = string.format
local floor  = math.floor
local max    = math.max
local insert = table.insert
local concat = table.concat
local unpack = (unpack or table.unpack)

--* Constants *--
local ESCAPED_CHARACTER_CONVERSIONS = {
  ["\a"] = "a", -- bell
  ["\b"] = "b", -- backspace
  ["\f"] = "f", -- form feed
  ["\n"] = "n", -- newline
  ["\r"] = "r", -- carriage return
  ["\t"] = "t", -- horizontal tab
  ["\v"] = "v", -- vertical tab
  ["\\"] = "\\"
}

--* Library object *--
local Helpers = {}

--- Finds a value in a table, and returns its key if found.
-- @param <table> table The table to search for a value.
-- @param <any> value The value to search for in the table.
-- @return <any> The key of the value in the table.
function Helpers.tableFind(table, value)
  for key, tableValue in pairs(table) do
    if value == tableValue then
      return key
    end
  end
  return nil
end

--- Returns the total number of elements in a table.
-- @param <table> table The table to count the elements of.
-- @return <number> The total number of elements in the table.
function Helpers.tableLen(table)
  local number = 0
  for _ in pairs(table) do
    number = number + 1
  end
  return number
end

--- Creates a shallow copy of a table.
-- @param <table> table The table to copy.
-- @return <table> The shallow copy of the table.
function Helpers.shallowCopyTable(table)
  local clonedTable = {}
  for index, value in pairs(table) do
    clonedTable[index] = value
  end
  return clonedTable
end

--- Creates a deep copy of a table.
-- @param <table> table The table to copy.
-- @return <table> The deep copy of the table.
function Helpers.deepCopyTable(table)
  local clonedTable = {}
  for index, value in pairs(table) do
    if type(value) ~= "table" then
      clonedTable[index] = index
    else
      clonedTable[index] = Helpers.deepCopyTable(value)
    end
  end
  return clonedTable
end

--- Serializes a value into a string.
-- @param <any> value The value to serialize.
-- @return <string> The serialized value.
function Helpers.serializeValue(value)
  local valueType = type(value)

  if valueType == "string" then
    return "'" .. value .. "'"
  else
    return tostring(value)
  end
end

--- Gets the contents of a file.
-- @param <string> filePath The path to the file.
-- @return <string> The contents of the file.
function Helpers.readFile(filePath)
  local file = io.open(filePath, "r")
  if not file then return nil end
  local contents = file:read("*a")
  return contents
end

--- Writes contents to a file.
-- @param <string> filePath The path to the file.
-- @param <string> contents The contents to write to the file.
-- @return <nil>
function Helpers.writeFile(filePath, contents)
  return io.open(filePath, "w"):write(contents)
end

--- Prints a table in a formatted way.
-- @param <table> table The table to print.
-- @return <nil>
function Helpers.printAligned(Table)
  assert(type(Table) == "table", "Table must be a table")

  print(Helpers.alignLines(Table))
end

--- Prints a string representation of a table.
-- @param <table> table The table to print.
-- @param <number> spacing The spacing between each element.
-- @return <nil>
function Helpers.printTable(Table, Spacing)
  assert(type(Table) == "table", "Table must be a table")

  return print(Helpers.stringifyTable(Table, Spacing))
end

--- Converts a string to a table of characters.
-- @param <string> string The string to convert.
-- @return <table> The table of characters.
function Helpers.stringToTable(string)
  local table = {}
  local index = 1
  for char in gmatch(string, ".") do
    table[index] = char
    index = index + 1
  end
  return table
end

--- Sanitizes a string by escaping special characters.
-- @param <string> string The string to sanitize.
-- @return <string> The sanitized string.
function Helpers.sanitizeString(stringValue, stringDelimiter)
  local stringDelimiter = stringDelimiter or "\""
  local formattingValue = "[\\" .. stringDelimiter .. "\a\b\f\n\r\t\v\\]"
  stringValue = stringValue:gsub(formattingValue, function(character)
    return "\\" .. (ESCAPED_CHARACTER_CONVERSIONS[character] or character)
  end)
  stringValue = stringValue:gsub("(%c)%d", function(c)
    return format("\\%03d", byte(c))
  end)
  stringValue = stringValue:gsub("(%c)", function(c)
    return format("\\%d", byte(c))
  end)

  return stringValue
end

--- Converts a table to aligned lines
-- @param <table> table The table to convert.
-- @return <string> The aligned lines.
function Helpers.alignLines(table)
  -- Find the longest string in each column
  local maxLengths = {}
  for _, row in pairs(table) do
    for column, value in pairs(row) do
      local length = len(tostring(value))
      if not maxLengths[column] or length > maxLengths[column] then
        maxLengths[column] = length
      end
    end
  end

  -- Concat each line with the same spacing
  local lines = {}
  for _, row in pairs(table) do
    local line = {}
    for column, value in pairs(row) do
      local spacing = rep(" ", maxLengths[column] - len(value))
      insert(line, value .. spacing)
    end
    insert(lines, concat(line, ""))
  end

  return concat(lines, "\n")
end

--- Converts a table to its string representation.
-- @param <table> inputTable The table to convert.
-- @param <number> spacing The spacing between each element.
-- @return <string> The string representation of the table.
function Helpers.stringifyTable(inputTable, spacing)
  local indentSpacing = spacing or 2
  local indentString = string.rep(" ", indentSpacing)

  local visitTable, visitTableElement;
  local function visitTableElement(lines, indentation, key, value)
    local formatString = (type(value) == "table" and "%s[%s] = %s {") or "%s[%s] = %s";

    local currentIndentation = string.rep(indentString, indentation)
    table.insert(lines, formatString:format(currentIndentation, tostring(key), tostring(value)))
    if type(value) == "table" then
      table.insert(lines, visitTable(value, indentation + 1))
      table.insert(lines, currentIndentation .. "}")
    end
  end

  local visitedTables = {}
  local function visitTable(table, indentation)
    if visitedTables[table] and visitedTables[table] >= 3 then
      -- Terminate any possibility of an infinite recursion
      return string.rep(indentString, indentation) .. "<Repeated table>"
    end

    visitedTables[table] = visitedTables[table] and visitedTables[table] + 1 or 0

    local lines = {}
    for key, value in pairs(table) do
      if tostring(key):sub(1, 1) ~= "_" then
        visitTableElement(lines, indentation, key, value)
      end
    end

    return concat(lines, "\n")
  end

  return "{\n" .. visitTable(inputTable, 1) .. "\n}"
end

return Helpers
