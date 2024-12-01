local scriptPath = (debug.getinfo(1).source:match("@?(.*/)") or "")
local requirePath = scriptPath .. "../Compiler/?.lua"
local localPath = scriptPath .. "../Compiler/"
package.path = requirePath
local Vmify = {}
local luaAPI = require("api")
local NewVm = require("NewVMGeneratpr")
function Vmify.process(code)
    return luaAPI.Obfuscator.ASTObfuscator.ObfuscateScript(NewVm(code))
end

return Vmify
