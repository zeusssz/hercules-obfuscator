--* Dependencies *--
local Helpers = require("Helpers/Helpers")
local Proto = require("Structures/Proto")

--* Imports *--
local insert = table.insert
local remove = table.remove
local unpack = (unpack or table.unpack)

--* ProtoManager *--
local ProtoManager = {}

function ProtoManager:pushProto(proto)
  local proto = proto or Proto:new()
  proto.locals = {}

  self.currentProto = proto
  insert(self.protos, proto)
  return proto
end

function ProtoManager:popProto()
  local currentProto = self.currentProto
  if currentProto then
    self.protos[#self.protos] = nil
    self.currentProto = self.protos[#self.protos]
    return
  end

  error("No proto to pop")
end

function ProtoManager:isLocalVariable(localName)
  return self.currentProto.locals[localName]
end

function ProtoManager:findOrCreateUpvalue(upvalueName)
  local foundUpvalue = self.currentProto.upvalues[upvalueName]
  if not foundUpvalue then
    foundUpvalue = self.currentProto.numUpvalues
    self.currentProto.upvalues[upvalueName] = foundUpvalue
    self.currentProto.numUpvalues = self.currentProto.numUpvalues + 1
  end

  return foundUpvalue
end

function ProtoManager:getUpvalue(name)
  for index, upvalue in ipairs(self.currentProto.upvalues) do
    local upvalueName = upvalue.Name
    if upvalueName == name then
      local upvalueRegister = upvalue.Register
      return upvalueRegister
    end
  end
  insert(self.currentProto.upvalues, {
    Name = name,
    Register = self.register
  })
end

return ProtoManager
