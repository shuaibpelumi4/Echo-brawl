-- InputHandler.lua
-- Listens for player input and triggers abilities.
-- All keybinds are defined in one table — easy to remap.

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- ── Keybind Config ────────────────────────────────────────────────────────────
-- Change these to remap any ability. Ability index matches FighterConfig order.
local KEYBINDS = {
	[1] = Enum.KeyCode.Z,          -- Ability 1
	[2] = Enum.KeyCode.X,          -- Ability 2
	[3] = Enum.KeyCode.C,          -- Ability 3
}

-- Mobile buttons will be added in Phase 6 UI update

-- ── RemoteEvent (server communication) ───────────────────────────────────────
-- We'll fire this to tell the server which ability was used
local remoteFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
local useAbilityRemote = remoteFolder and remoteFolder:WaitForChild("UseAbility", 10)

-- ── Cooldown Tracking (client-side visual only) ───────────────────────────────
local lastUsed = {
	[1] = 0,
	[2] = 0,
	[3] = 0,
}

-- Cooldown times mirror FighterConfig — kept loose here since
-- server is the source of truth for actual cooldowns
local VISUAL_COOLDOWNS = {
	[1] = 1.0,
	[2] = 3.5,
	[3] = 9.0,
}

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function canUse(abilityIndex)
	local now = tick()
	return now - lastUsed[abilityIndex] >= VISUAL_COOLDOWNS[abilityIndex]
end

local function markUsed(abilityIndex)
	lastUsed[abilityIndex] = tick()
end

local function fireAbility(abilityIndex)
	if not canUse(abilityIndex) then
		print("Ability " .. abilityIndex .. " is on cooldown")
		return
	end

	markUsed(abilityIndex)
	print("Player used ability: " .. abilityIndex)

	-- Tell the server
	if useAbilityRemote then
		useAbilityRemote:FireServer(abilityIndex)
	end
end

-- ── Input Listener ────────────────────────────────────────────────────────────

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end   -- ignore if typing in chat etc.

	for abilityIndex, keyCode in pairs(KEYBINDS) do
		if input.KeyCode == keyCode then
			fireAbility(abilityIndex)
		end
	end
end)

-- ── Mobile Support (tap buttons — wired in Phase 6) ──────────────────────────
-- Placeholder function so Phase 6 UI can call this directly
local InputHandler = {}

function InputHandler.TriggerAbility(abilityIndex)
	fireAbility(abilityIndex)
end

return InputHandler

