-- GLua test suite for language detection

-- Hook system (very GLua-specific)
hook.Add("PlayerSpawn", "DetectionTestHook", function(ply)
    if not IsValid(ply) then return end

    local t = CurTime()
    ply:SetNWFloat("spawn_time", t)

    print("[GLuaTest] Player spawned at:", t)
end)

-- Entity definition (GLua hallmark)
ENT = ENT or {}
ENT.Type = "anim"
ENT.Base = "base_gmodentity"

function ENT:Initialize()
    self:SetModel("models/props_c17/oildrum001.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
end

function ENT:Use(activator, caller)
    if IsValid(activator) then
        activator:ChatPrint("Entity used!")
    end
end

-- Networking (GLua multiplayer system)
if SERVER then
    util.AddNetworkString("DetectionTestNet")

    net.Receive("DetectionTestNet", function(len, ply)
        print("[GLuaTest] Received net message from:", ply:Nick())
    end)
else
    net.Start("DetectionTestNet")
    net.SendToServer()
end

-- HUD drawing (clientside GLua)
if CLIENT then
    hook.Add("HUDPaint", "DetectionHUDTest", function()
        draw.SimpleText(
            "GLua Detection Test",
            "DermaDefault",
            100,
            100,
            Color(255, 255, 255, 255)
        )
    end)
end

-- Utility + runtime functions
local crc = util.CRC("glua_detection_test")
print("[GLuaTest] CRC:", crc)
print("[GLuaTest] CurTime:", CurTime())
