-- EchoSystem.lua
-- Spawns ghost echo copies of fighters at their past positions.
-- Echoes deal damage to enemies who walk through them.

local EchoSystem = {}

-- Services
local Debris   = game:GetService("Debris")
local Players  = game:GetService("Players")

-- Internal state
local activeEchoes = {}   -- { [echoId] = { owner, part, touched } }
local echoCounter  = 0

-- ── Callbacks (set from GameManager) ─────────────────────────────────────────
EchoSystem.OnEchoHit = nil   -- fn(ownerName, victimName, damage)

-- ── Internal helpers ──────────────────────────────────────────────────────────

local function fireCallback(name, ...)
	if EchoSystem[name] then
		EchoSystem[name](...)
	end
end

local function getCharacter(playerName)
	local player = Players:FindFirstChild(playerName)
	if player then return player.Character end
	return nil
end

local function buildEchoPart(position, echoColor)
	-- Ghostly semi-transparent humanoid silhouette
	local part = Instance.new("Part")
	part.Size        = Vector3.new(2, 5, 1)
	part.Position    = position
	part.Anchored    = true
	part.CanCollide  = false
	part.CastShadow  = false
	part.Material    = Enum.Material.Neon
	part.Color       = echoColor
	part.Transparency = 0.55
	part.Parent      = workspace

	-- Fade-in effect
	local tween = game:GetService("TweenService"):Create(
		part,
		TweenInfo.new(0.2, Enum.EasingStyle.Sine),
		{ Transparency = 0.65 }
	)
	tween:Play()

	return part
end

local function fadeAndDestroy(part, duration)
	local tween = game:GetService("TweenService"):Create(
		part,
		TweenInfo.new(duration * 0.4, Enum.EasingStyle.Sine),
		{ Transparency = 1 }
	)
	tween:Play()
	Debris:AddItem(part, duration * 0.4 + 0.1)
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Spawn an echo at the fighter's current position
-- fighterData = FighterConfig entry (has EchoColor, EchoDuration, EchoDamage)
function EchoSystem.SpawnEcho(ownerName, fighterData)
	local char = getCharacter(ownerName)
	if not char or not char.PrimaryPart then return end

	local position  = char.PrimaryPart.Position
	local echoColor = fighterData.EchoColor
	local duration  = fighterData.EchoDuration
	local damage    = fighterData.EchoDamage

	echoCounter += 1
	local echoId = ownerName .. "_" .. echoCounter

	local part = buildEchoPart(position, echoColor)

	-- Track which players already took damage from this echo (no spam)
	local touched = {}

	-- Damage any enemy who walks through
	part.Touched:Connect(function(hit)
		local hitChar = hit.Parent
		local hitPlayer = Players:GetPlayerFromCharacter(hitChar)
		if not hitPlayer then return end
		if hitPlayer.Name == ownerName then return end        -- don't damage self
		if touched[hitPlayer.Name] then return end            -- one hit per echo

		touched[hitPlayer.Name] = true
		fireCallback("OnEchoHit", ownerName, hitPlayer.Name, damage)
	end)

	activeEchoes[echoId] = { owner = ownerName, part = part, touched = touched }

	-- Auto-fade and clean up after duration
	task.delay(duration * 0.6, function()
		fadeAndDestroy(part, duration * 0.4)
		activeEchoes[echoId] = nil
	end)
end

-- Call this on a timer (every N seconds) while round is active
-- to automatically leave echoes as fighters move
function EchoSystem.StartEchoLoop(ownerName, fighterData, intervalSeconds)
	local running = true

	task.spawn(function()
		while running do
			task.wait(intervalSeconds)
			if running then
				EchoSystem.SpawnEcho(ownerName, fighterData)
			end
		end
	end)

	-- Return a stop function so GameManager can kill the loop on round end
	return function()
		running = false
	end
end

-- Remove all echoes instantly (round reset)
function EchoSystem.ClearAll()
	for id, data in pairs(activeEchoes) do
		if data.part and data.part.Parent then
			data.part:Destroy()
		end
	end
	activeEchoes = {}
	echoCounter  = 0
end

-- Get count of active echoes (useful for UI/debug)
function EchoSystem.GetActiveCount()
	local count = 0
	for _ in pairs(activeEchoes) do count += 1 end
	return count
end

return EchoSystem

