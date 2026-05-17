-- AbilityData.lua
-- Every ability in the game lives here.
-- CombatSystem reads from this — never hardcode moves anywhere else.

local AbilityData = {}

-- ── Ability Definitions ───────────────────────────────────────────────────────
-- Each ability has:
--   Name       : unique identifier (must match FighterConfig)
--   Damage     : base damage dealt
--   Cooldown   : seconds before can use again
--   Range      : stud distance required to hit
--   Knockback  : force applied to victim on hit
--   Type       : "Melee" | "Projectile" | "AoE"
--   Description: shown in UI later

AbilityData.Abilities = {

	-- ── Kael (Fire) ───────────────────────────────────────────────────────────

	["Ember Strike"] = {
		Name        = "Ember Strike",
		Damage      = 15,
		Cooldown    = 1.0,
		Range       = 5,
		Knockback   = 30,
		Type        = "Melee",
		Description = "A fast fiery punch that scorches on contact.",
	},

	["Ash Dash"] = {
		Name        = "Ash Dash",
		Damage      = 8,
		Cooldown    = 3.0,
		Range       = 10,
		Knockback   = 50,
		Type        = "Melee",
		Description = "Dash forward leaving a trail of ash. Hits everything in path.",
	},

	["Inferno Burst"] = {
		Name        = "Inferno Burst",
		Damage      = 30,
		Cooldown    = 8.0,
		Range       = 7,
		Knockback   = 80,
		Type        = "AoE",
		Description = "Explodes outward in a ring of fire. High damage, long cooldown.",
	},

	-- ── Zira (Water) ──────────────────────────────────────────────────────────

	["Tidal Slash"] = {
		Name        = "Tidal Slash",
		Damage      = 12,
		Cooldown    = 1.0,
		Range       = 5,
		Knockback   = 25,
		Type        = "Melee",
		Description = "A sweeping water blade. Quick and reliable.",
	},

	["Wave Push"] = {
		Name        = "Wave Push",
		Damage      = 6,
		Cooldown    = 3.5,
		Range       = 12,
		Knockback   = 90,
		Type        = "Projectile",
		Description = "Launches a wave that pushes enemies far back.",
	},

	["Tsunami Slam"] = {
		Name        = "Tsunami Slam",
		Damage      = 28,
		Cooldown    = 9.0,
		Range       = 6,
		Knockback   = 100,
		Type        = "AoE",
		Description = "Crashes down with a massive wave. Massive knockback.",
	},

}

-- ── Helpers ───────────────────────────────────────────────────────────────────

-- Get ability by name
function AbilityData.Get(abilityName)
	return AbilityData.Abilities[abilityName] or nil
end

-- Get all abilities belonging to a fighter (pass their FighterConfig entry)
function AbilityData.GetForFighter(fighterData)
	local result = {}
	for _, ability in ipairs(fighterData.Abilities) do
		local data = AbilityData.Get(ability.Name)
		if data then
			table.insert(result, data)
		end
	end
	return result
end

return AbilityData

