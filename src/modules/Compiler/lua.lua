--[[
  Name: lua.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-21
  Description:
    This module serves as a handler for the Lua interpreter.
    It provides the command line interface for the Lua interpreter.
    As well as multiple command line options.

  Read the license file in the root of the project directory.
--]]

--* Dependencies *--
local API = require("api")

local AnsiFormatter     = API.Modules.AnsiFormatter
local Helpers           = API.Modules.Helpers
local SyntaxHighlighter = API.Modules.SyntaxHighlighter

--* Imports *--
local insert = table.insert
local concat = table.concat
local unpack = (unpack or table.unpack)

--* lua *--
local lua = {
  optionSwitches = {},
  includes = {},
  COPYRIGHT = "Lua 5.1.5 Copyright (C) 2024, Bytexenuwu & Friends",
  VERSION   = "Lua 5.1"
}

lua.params = {
  ["-e"] = {{"stat"}, "execute string 'stat'",                            lua.executeString},
  ["-l"] = {{"name"}, "require library 'name'",                           lua.includeLibrary},
  ["-i"] = {nil,     "enter interactive mode after executing 'script'",   lua.interactiveMode},
  ["-v"] = {nil,     "show version information",                          lua.printVersion},
  ["--"] = {nil,     "stop handling options"},
  ["-"] =  {nil,     "execute stdin and stop handling options"}
}

--- Prints the help message for the Lua interpreter.
function lua.printHelp()
  local lines = {}
  for index, param in pairs(lua.params) do
    local args = (param[1] and concat(param[1], ", ")) or ""
    local description = param[2] or ""

    insert(lines, {"  ", index, "  ", nil, "  ", description})
  end

  print("usage: lua [options] [script [args]].")
  print("Available options are:")
  Helpers.printAligned(lines)
end

--- Prints the version information for the Lua interpreter.
function lua.printVersion()
  print(lua.COPYRIGHT)
end

--- Enters interactive mode for the Lua interpreter.
function lua.interactiveMode()
  lua.printVersion()

  local globalLuaState = API.LuaState.NewLuaState()
  local pointingArrow = AnsiFormatter.formatString("%{BLUE}%lua> %{RESET}%")
  local cursorUpAndClearLine = AnsiFormatter.formatString("%{CURSOR_UP:1:}%%{START_LINE}%%{CLEAR_LINE}%")

  while (true) do
    io.write(pointingArrow)

    local input = io.stdin:read("*l")
    if input == "exit" then break end
    local tokensWithAdditionalInfo = API.Interpreter.ConvertToTokens(input, true)
    local syntaxHighlightedCode = SyntaxHighlighter:new(tokensWithAdditionalInfo):getFormattedTokens()

    -- Replace non-syntax-highlighted code with the syntax-highlighted code.
    print(cursorUpAndClearLine .. pointingArrow .. syntaxHighlightedCode)

    -- Execute the script and capture the output
    local pcallReturnValues = {pcall(API.ASTExecutor.ExecuteScript, input, globalLuaState)}
    local success, returnValues = pcallReturnValues[1], {select(2, unpack(pcallReturnValues))}

    -- Print the return value if the script executed successfully and returned a value
    if success and #returnValues ~= 0 then
      print(AnsiFormatter.formatString("%{RESET}%%{RGB_COLOR:0:255:0:}%returns: %{RESET}%%{RED}%{%{RESET}%"))
      for index, value in pairs(returnValues) do
        print("  " .. tostring(value))
      end
      print(AnsiFormatter.formatString("%{RED}%}%{RESET}%"))
    elseif not success then
      print(AnsiFormatter.formatString("%{RED}%error: %{RESET}%" .. returnValues[1]))
    end
  end
end

--- Parses the command line arguments for the Lua interpreter.
-- @param args The command line arguments.
function lua.parseArgs(args)
  assert(type(args) == "table", "args must be a table")

  if #args == 0 then lua.interactiveMode() end
  local fileName
  local fileVarArgs = {}
  local optionCalls = {}

  for argIndex = 1, #args do
    local currentArg = args[argIndex]

    -- Handle help request
    if currentArg == "-h" or currentArg == "--help" then
      return lua.printHelp()
    end

    -- Handle options with parameters
    if lua.params[currentArg] and not (optionCalls[currentArg]) then
      local optionProperties = lua.params[currentArg]
      local optionArgs = optionProperties[1] or {}
      local consumedArgs = {}

      for index = argIndex + 1, argIndex + #optionArgs do
        local newArg = args[index]
        if not newArg then error("Missing argument for option " .. currentArg) end
        insert(consumedArgs, newArg)
      end

      optionCalls[currentArg] = consumedArgs
      argIndex = argIndex + #optionArgs -- Skip consumed arguments
    else
      -- Handle file name and variable arguments
      if not fileName then
        fileName = currentArg
      else
        insert(fileVarArgs, currentArg)
      end
    end
  end

  -- Execute options with parameters
  for optionName, arguments in pairs(optionCalls) do
    lua.params[optionName][3](unpack(arguments))
  end

  -- Execute file if provided
  if fileName then
    lua.executeFile(fileName, unpack(fileVarArgs))
  end
end

--- Executes a Lua script from a string.
-- @param string The Lua script as a string.
-- @param varArgs The variable arguments to pass to the script.
function lua.executeString(string, varArgs)
  assert(type(string) == "string", "string must be a string")

  -- Use the AST executor for now
  -- just because the AST-instructions converter is
  -- too buggy at this moment
  return API.ASTExecutor.ExecuteScript(string)
end

--- Executes a Lua script from a file.
-- @param filename The name of the file containing the Lua script.
-- @param varArgs The variable arguments to pass to the script.
function lua.executeFile(filename, varArgs)
  assert(type(filename) == "string", "filename must be a string")

  local file = io.open(filename, "r")
  if not file then return end
  local contents = file:read("*a")
  file:close()
  return lua.executeString(contents, varArgs)
end


return lua.parseArgs({...})