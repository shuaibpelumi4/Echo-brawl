-- FighterConfig.lua
-- ALL fighter data lives here. Add new fighters by adding a new block.

local FighterConfig = {}

FighterConfig.Fighters = {

	["Kael"] = {
		DisplayName = "Kael the Ashen",
		Element = "Fire",
		MaxHealth = 100,
		WalkSpeed = 16,
		JumpPower = 50,
		EchoColor = Color3.fromRGB(255, 80, 20),   -- orange echo trail
		EchoDuration = 3,                            -- seconds echo lasts
		EchoDamage = 5,                              -- damage echo deals on touch

		Abilities = {
			[1] = { Name = "Ember Strike",  Damage = 15, Cooldown = 1.0, Range = 5  },
			[2] = { Name = "Ash Dash",      Damage = 8,  Cooldown = 3.0, Range = 10 },
			[3] = { Name = "Inferno Burst", Damage = 30, Cooldown = 8.0, Range = 7  },
		},
	},

	["Zira"] = {
		DisplayName = "Zira the Tide",
		Element = "Water",
		MaxHealth = 120,
		WalkSpeed = 14,
		JumpPower = 45,
		EchoColor = Color3.fromRGB(20, 180, 255),  -- blue echo trail
		EchoDuration = 4,
		EchoDamage = 4,

		Abilities = {
			[1] = { Name = "Tidal Slash",  Damage = 12, Cooldown = 1.0, Range = 5  },
			[2] = { Name = "Wave Push",    Damage = 6,  Cooldown = 3.5, Range = 12 },
			[3] = { Name = "Tsunami Slam", Damage = 28, Cooldown = 9.0, Range = 6  },
		},
	},

}

-- Helper: get a fighter's data by name
function FighterConfig.Get(fighterName)
	return FighterConfig.Fighters[fighterName] or nil
end

-- Helper: get all fighter names as a list
function FighterConfig.GetAllNames()
	local names = {}
	for name, _ in pairs(FighterConfig.Fighters) do
		table.insert(names, name)
	end
	return names
end

return FighterConfig

