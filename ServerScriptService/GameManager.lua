-- GameManager.lua
-- The main server script. Connects all modules together.
-- Nothing is hardcoded here — all data comes from modules.

local Players      = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ── Load Modules ─────────────────────────────────────────────────────────────
local Modules       = script.Parent.Modules
local FighterConfig = require(Modules.FighterConfig)
local CombatSystem  = require(Modules.CombatSystem)
local EchoSystem    = require(Modules.EchoSystem)
local RoundManager  = require(Modules.RoundManager)

-- ── Internal State ────────────────────────────────────────────────────────────
local playerFighters = {}   -- { [playerName] = fighterName }
local echoStoppers   = {}   -- { [playerName] = stopFn }
local ECHO_INTERVAL  = 1.2  -- seconds between echo spawns

-- ── Echo Interval Setting ─────────────────────────────────────────────────────
-- How often (seconds) a fighter leaves an echo while moving
local ECHO_INTERVAL = 1.2

-- ── Helper: assign fighters to players ───────────────────────────────────────
local function assignFighters()
	local allNames   = FighterConfig.GetAllNames()
	local playerList = Players:GetPlayers()

	for i, player in ipairs(playerList) do
		-- Cycle through available fighters if more players than fighters
		local fighterName = allNames[(i - 1) % #allNames + 1]
		playerFighters[player.Name] = fighterName
		print(player.Name .. " assigned fighter: " .. fighterName)
	end
end

-- ── Helper: register all players with CombatSystem ───────────────────────────
local function registerAllPlayers()
	for playerName, fighterName in pairs(playerFighters) do
		local data = FighterConfig.Get(fighterName)
		if data then
			CombatSystem.RegisterPlayer(playerName, data.MaxHealth)
		end
	end
end

-- ── Helper: apply fighter walk speed & jump ───────────────────────────────────
local function applyFighterStats(playerName)
	local fighterName = playerFighters[playerName]
	if not fighterName then return end
	local data   = FighterConfig.Get(fighterName)
	local player = Players:FindFirstChild(playerName)
	if not player or not player.Character then return end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = data.WalkSpeed
		humanoid.JumpPower = data.JumpPower
	end
end

-- ── Helper: start echo loops for all players ─────────────────────────────────
local function startAllEchoLoops()
	for playerName, fighterName in pairs(playerFighters) do
		local data    = FighterConfig.Get(fighterName)
		local stopFn  = EchoSystem.StartEchoLoop(playerName, data, ECHO_INTERVAL)
		echoStoppers[playerName] = stopFn
	end
end

-- ── Helper: stop all echo loops ──────────────────────────────────────────────
local function stopAllEchoLoops()
	for _, stopFn in pairs(echoStoppers) do
		stopFn()
	end
	echoStoppers = {}
	EchoSystem.ClearAll()
end

-- ── Helper: reset all players for next round ─────────────────────────────────
local function resetAllPlayers()
	for playerName, _ in pairs(playerFighters) do
		CombatSystem.ResetPlayer(playerName)
		applyFighterStats(playerName)
	end
end

-- ── Wire up CombatSystem callbacks ───────────────────────────────────────────

CombatSystem.OnPlayerDamaged = function(attackerName, victimName, damage)
	print(attackerName .. " hit " .. victimName .. " for " .. damage .. " damage")
end

CombatSystem.OnHealthChanged = function(playerName, current, max)
	print(playerName .. " HP: " .. current .. "/" .. max)
	-- UI update will hook in here in Phase 6
end

CombatSystem.OnPlayerDied = function(victimName, killerName)
	print(victimName .. " was defeated by " .. killerName)
	stopAllEchoLoops()
	RoundManager.DeclareWinner(killerName)
end

-- ── Wire up EchoSystem callbacks ─────────────────────────────────────────────

EchoSystem.OnEchoHit = function(ownerName, victimName, damage)
	print(ownerName .. "'s echo hit " .. victimName .. " for " .. damage)
	CombatSystem.ApplyDamage(ownerName, victimName, damage)
end

-- ── Wire up RoundManager callbacks ───────────────────────────────────────────

RoundManager.OnPhaseChanged = function(newPhase)
	print("Phase changed: " .. newPhase)

	if newPhase == "Fighting" then
		resetAllPlayers()
		startAllEchoLoops()
	end

	if newPhase == "RoundEnd" or newPhase == "MatchEnd" then
		stopAllEchoLoops()
	end
end

RoundManager.OnCountdownTick = function(secondsLeft)
	print("Round starts in: " .. secondsLeft)
	-- UI countdown hook goes here in Phase 6
end

RoundManager.OnRoundEnd = function(winnerName)
	if winnerName == "Draw" then
		print("Round ended in a DRAW")
	else
		print("Round winner: " .. winnerName)
	end
end

RoundManager.OnMatchEnd = function(winnerName)
	print("MATCH WINNER: " .. winnerName)
	-- Reset everything for a new match
	task.wait(3)
	CombatSystem.ClearAll()
	EchoSystem.ClearAll()
	GameManager.StartGame()
end

-- ── Main entry point ──────────────────────────────────────────────────────────
local GameManager = {}

function GameManager.StartGame()
	print("=== Echo Brawl Starting ===")

	-- Wait until at least 2 players are in the game
	repeat task.wait(1) until #Players:GetPlayers() >= 2

	assignFighters()
	registerAllPlayers()

	-- Apply stats once characters load
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			applyFighterStats(player.Name)
		end
		player.CharacterAdded:Connect(function()
			applyFighterStats(player.Name)
		end)
	end

	local playerNames = {}
	for _, p in ipairs(Players:GetPlayers()) do
		table.insert(playerNames, p.Name)
	end

	RoundManager.StartMatch(playerNames)
end

-- ── Boot ──────────────────────────────────────────────────────────────────────
GameManager.StartGame()

