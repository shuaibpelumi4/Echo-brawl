-- CombatSystem.lua
-- Handles all damage, hit detection, knockback and player death

local CombatSystem = {}

-- Services
local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

-- Internal state
local healthData = {}   -- { [playerName] = { Current, Max } }
local cooldowns  = {}   -- { [playerName] = { [abilityIndex] = nextAllowedTime } }

-- ── Callbacks (set from GameManager) ─────────────────────────────────────────
CombatSystem.OnPlayerDamaged = nil   -- fn(attackerName, victimName, damage)
CombatSystem.OnPlayerDied    = nil   -- fn(victimName, killerName)
CombatSystem.OnHealthChanged = nil   -- fn(playerName, currentHP, maxHP)

-- ── Internal helpers ──────────────────────────────────────────────────────────

local function fireCallback(name, ...)
	if CombatSystem[name] then
		CombatSystem[name](...)
	end
end

local function getCharacter(playerName)
	local player = Players:FindFirstChild(playerName)
	if player then return player.Character end
	return nil
end

local function getHumanoid(playerName)
	local char = getCharacter(playerName)
	if char then return char:FindFirstChildOfClass("Humanoid") end
	return nil
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Register a player with their max HP from FighterConfig
function CombatSystem.RegisterPlayer(playerName, maxHealth)
	healthData[playerName] = {
		Current = maxHealth,
		Max     = maxHealth,
	}
	cooldowns[playerName] = {}

	local humanoid = getHumanoid(playerName)
	if humanoid then
		humanoid.MaxHealth = maxHealth
		humanoid.Health    = maxHealth
	end
end

-- Apply damage from an attacker to a victim
function CombatSystem.ApplyDamage(attackerName, victimName, damage)
	local data = healthData[victimName]
	if not data then return end

	-- Clamp damage
	data.Current = math.max(0, data.Current - damage)

	-- Sync to Roblox humanoid
	local humanoid = getHumanoid(victimName)
	if humanoid then
		humanoid.Health = data.Current
	end

	fireCallback("OnPlayerDamaged", attackerName, victimName, damage)
	fireCallback("OnHealthChanged", victimName, data.Current, data.Max)

	if data.Current <= 0 then
		fireCallback("OnPlayerDied", victimName, attackerName)
	end
end

-- Check if an ability is off cooldown, then trigger it
function CombatSystem.UseAbility(attackerName, abilityData, victimName)
	local now = tick()
	local cd   = cooldowns[attackerName]

	if not cd then return false end

	local lastUsed = cd[abilityData.Name] or 0
	if now - lastUsed < abilityData.Cooldown then
		return false   -- still on cooldown
	end

	-- Mark cooldown
	cd[abilityData.Name] = now

	-- Range check
	local attackerChar = getCharacter(attackerName)
	local victimChar   = getCharacter(victimName)

	if attackerChar and victimChar then
		local dist = (attackerChar.PrimaryPart.Position - victimChar.PrimaryPart.Position).Magnitude
		if dist <= abilityData.Range then
			CombatSystem.ApplyDamage(attackerName, victimName, abilityData.Damage)
			return true
		end
	end

	return false
end

-- Apply knockback force to a victim
function CombatSystem.ApplyKnockback(attackerName, victimName, force)
	local attackerChar = getCharacter(attackerName)
	local victimChar   = getCharacter(victimName)

	if not attackerChar or not victimChar then return end

	local direction = (victimChar.PrimaryPart.Position - attackerChar.PrimaryPart.Position).Unit
	local bodyVel   = Instance.new("BodyVelocity")
	bodyVel.Velocity       = direction * force
	bodyVel.MaxForce       = Vector3.new(1e5, 1e5, 1e5)
	bodyVel.P              = 1e4
	bodyVel.Parent         = victimChar.PrimaryPart

	Debris:AddItem(bodyVel, 0.15)   -- auto-remove after 0.15s
end

-- Reset a player's HP (called between rounds)
function CombatSystem.ResetPlayer(playerName)
	local data = healthData[playerName]
	if not data then return end

	data.Current = data.Max
	cooldowns[playerName] = {}

	local humanoid = getHumanoid(playerName)
	if humanoid then
		humanoid.Health = data.Max
	end

	fireCallback("OnHealthChanged", playerName, data.Current, data.Max)
end

-- Get current HP
function CombatSystem.GetHealth(playerName)
	return healthData[playerName]
end

-- Wipe data on match end
function CombatSystem.ClearAll()
	healthData = {}
	cooldowns  = {}
end

return CombatSystem

