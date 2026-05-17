-- RoundManager.lua
-- Controls match flow: lobby > countdown > fight > winner > reset

local RoundManager = {}

-- Config (change these numbers to tweak the game feel)
local SETTINGS = {
	CountdownTime  = 5,    -- seconds before fight starts
	RoundTimeLimit = 120,  -- seconds before round ends (draws go to higher HP)
	WinScreenTime  = 4,    -- seconds to show winner screen before reset
	MaxRounds      = 3,    -- first to win this many rounds wins the match
}

-- Internal state
local state = {
	Phase        = "Waiting",  -- Waiting | Countdown | Fighting | RoundEnd | MatchEnd
	RoundNumber  = 1,
	Scores       = {},         -- { [playerName] = wins }
	TimeLeft     = 0,
	ActiveTimer  = nil,
}

-- ── Callbacks (set these from GameManager) ──────────────────────────────────
RoundManager.OnPhaseChanged  = nil   -- fn(newPhase)
RoundManager.OnCountdownTick = nil   -- fn(secondsLeft)
RoundManager.OnRoundEnd      = nil   -- fn(winnerName or "Draw")
RoundManager.OnMatchEnd      = nil   -- fn(winnerName)

-- ── Internal helpers ─────────────────────────────────────────────────────────

local function fireCallback(name, ...)
	if RoundManager[name] then
		RoundManager[name](...)
	end
end

local function setPhase(newPhase)
	state.Phase = newPhase
	fireCallback("OnPhaseChanged", newPhase)
end

local function stopTimer()
	if state.ActiveTimer then
		task.cancel(state.ActiveTimer)
		state.ActiveTimer = nil
	end
end

-- ── Public API ───────────────────────────────────────────────────────────────

-- Call this when players are loaded and ready
function RoundManager.StartMatch(playerNames)
	state.Scores = {}
	state.RoundNumber = 1
	for _, name in ipairs(playerNames) do
		state.Scores[name] = 0
	end
	RoundManager.StartRound()
end

function RoundManager.StartRound()
	setPhase("Countdown")
	state.TimeLeft = SETTINGS.CountdownTime

	state.ActiveTimer = task.spawn(function()
		while state.TimeLeft > 0 do
			fireCallback("OnCountdownTick", state.TimeLeft)
			task.wait(1)
			state.TimeLeft -= 1
		end
		RoundManager.BeginFighting()
	end)
end

function RoundManager.BeginFighting()
	setPhase("Fighting")
	state.TimeLeft = SETTINGS.RoundTimeLimit

	state.ActiveTimer = task.spawn(function()
		while state.TimeLeft > 0 do
			task.wait(1)
			state.TimeLeft -= 1
		end
		-- Time ran out — GameManager should call DeclareWinner with HP check
		RoundManager.DeclareWinner("Draw")
	end)
end

-- Call this from CombatSystem when a player reaches 0 HP
function RoundManager.DeclareWinner(winnerName)
	stopTimer()
	setPhase("RoundEnd")
	fireCallback("OnRoundEnd", winnerName)

	if winnerName ~= "Draw" then
		state.Scores[winnerName] = (state.Scores[winnerName] or 0) + 1
	end

	-- Check if someone won the match
	for name, wins in pairs(state.Scores) do
		if wins >= SETTINGS.MaxRounds then
			task.wait(SETTINGS.WinScreenTime)
			setPhase("MatchEnd")
			fireCallback("OnMatchEnd", name)
			return
		end
	end

	-- Nobody won the match yet — next round
	state.RoundNumber += 1
	task.wait(SETTINGS.WinScreenTime)
	RoundManager.StartRound()
end

function RoundManager.GetState()
	return state
end

function RoundManager.GetSettings()
	return SETTINGS
end

return RoundManager

