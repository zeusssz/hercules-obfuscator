-- Luau test suite for language detection (Roblox environment)

-- Services (core Luau pattern)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Instance creation (strong Luau signature)
local part = Instance.new("Part")
part.Size = Vector3.new(4, 1, 2)
part.Position = Vector3.new(0, 10, 0)
part.Anchored = true
part.Parent = workspace

-- Player handling
Players.PlayerAdded:Connect(function(player)
    print("[LuauTest] Player joined:", player.Name)

    player.CharacterAdded:Connect(function(char)
        local humanoid = char:WaitForChild("Humanoid")
        print("[LuauTest] Character ready for:", player.Name)

        humanoid.Died:Connect(function()
            print("[LuauTest] Player died:", player.Name)
        end)
    end)
end)

-- RunService loop (very Luau-specific runtime pattern)
RunService.Heartbeat:Connect(function(deltaTime)
    local t = os.clock()
    if t % 5 < 0.1 then
        print("[LuauTest] Heartbeat tick:", t)
    end
end)

-- Task scheduler (Luau modern API)
task.spawn(function()
    while true do
        task.wait(2)
        print("[LuauTest] Background task running...")
    end
end)

-- Table typing style (Luau hinting pattern)
type PlayerData = {
    name: string,
    score: number
}

local data: PlayerData = {
    name = "TestUser",
    score = 0
}

data.score += 10
print("[LuauTest] Score:", data.score)

-- Vector / CFrame usage (Roblox math types)
local cf = CFrame.new(0, 5, 0) * CFrame.Angles(0, math.rad(90), 0)
print("[LuauTest] CFrame:", cf)
