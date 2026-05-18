-- InputHandler.lua
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local KEYBINDS = {
	[1] = Enum.KeyCode.Z,
	[2] = Enum.KeyCode.X,
	[3] = Enum.KeyCode.C,
}

local lastUsed = { [1]=0, [2]=0, [3]=0 }
local VISUAL_COOLDOWNS = { [1]=1.0, [2]=3.5, [3]=9.0 }

local remoteFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
local useAbilityRemote = remoteFolder and remoteFolder:WaitForChild("UseAbility", 10)

local function canUse(i)
	return tick() - lastUsed[i] >= VISUAL_COOLDOWNS[i]
end

local function fireAbility(i)
	if not canUse(i) then return end
	lastUsed[i] = tick()
	print("Ability " .. i .. " used!")
	if useAbilityRemote then
		useAbilityRemote:FireServer(i)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	for i, key in pairs(KEYBINDS) do
		if input.KeyCode == key then
			fireAbility(i)
		end
	end
end)
