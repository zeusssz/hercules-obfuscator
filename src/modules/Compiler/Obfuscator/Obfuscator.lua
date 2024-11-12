local insert = table.insert

--* ObfuscatorMethods *--
local ObfuscatorMethods = {}

function ObfuscatorMethods:getAllStrings()
  local strings = {}
  ASTWalker.traverseAST(self.ast, function(node)
    return node.TYPE == "String"
  end, function(node)
    insert(strings, node.Value)
  end)

  return strings
end

function ObfuscatorMethods:obfuscate()
  local strings = self:getAllStrings()
  Helpers.printTable(strings)
end

--* Obfuscator *--
local Obfuscator = {}
function Obfuscator:new(ast)
  local ObfuscatorInstance = {}
  ObfuscatorInstance.ast = ast

  local function inheritModule(moduleName, moduleTable)
    for index, value in pairs(moduleTable) do
      if ObfuscatorInstance[index] then
        return error("Conflicting names in " .. moduleName .. " and ObfuscatorInstance: " .. index)
      end
      ObfuscatorInstance[index] = value
    end
  end

  -- Main
  inheritModule("ObfuscatorMethods", ObfuscatorMethods)

  return ObfuscatorInstance
end

return Obfuscator
