--!strict
--[[
	Central tunables for Battle Legends.
	Balance numbers are MVP defaults (combat rules left many values configurable).
]]

export type MatchMode = "FFA" | "Duel" | "Team2v2" | "Training" | "Survival"

local GameConfig = {
	Title = "BATTLE LEGENDS",
	Tagline = "Fight. Win. Become a Legend.",
	SchemaVersion = 1,
	DataStoreName = "BattleLegends_Player_v1",
	OrderedStoreKills = "BattleLegends_Kills_v1",
	OrderedStoreWins = "BattleLegends_Wins_v1",
	OrderedStoreLevel = "BattleLegends_Level_v1",

	AllowSoloMatch = true, -- Studio / low-pop testing
	MinPlayersFFA = 2,
	MaxPlayersFFA = 8,
	MatchDurationSeconds = 180,
	CountdownSeconds = 5,
	RespawnDelaySeconds = 3,
	ResultsDisplaySeconds = 8,

	WalkSpeed = 16,
	SprintSpeed = 24,
	JumpPower = 50,
	DodgeSpeed = 48,
	DodgeDuration = 0.28,
	DodgeCooldown = 1.15,
	DodgeIFrames = 0.22,
	BlockDamageMultiplier = 0.4,
	PerfectBlockWindow = 0.12,
	MaxHealth = 100,
	BaseEnergy = 100,
	EnergyRegenPerSecond = 8,
	UltimateMax = 100,
	UltFromDamageDealt = 0.35,
	UltFromDamageTaken = 0.15,
	UltFromKill = 25,

	LightDamage = 8,
	HeavyDamage = 16,
	LightRange = 7,
	HeavyRange = 8.5,
	LightCooldown = 0.32,
	HeavyCooldown = 0.95,
	HeavyStartup = 0.28,
	ComboWindow = 0.55,
	ComboMaxHits = 5,
	ComboScaleAfter = 3,
	ComboScaleFactor = 0.85,
	MaxDamagePerHit = 80,
	KnockbackLight = 18,
	KnockbackHeavy = 38,
	HitStunLight = 0.18,
	HitStunHeavy = 0.38,

	RateLimitCombat = 18, -- requests / second
	MaxHorizontalSpeed = 56,
	SaveIntervalSeconds = 60,
	DailyRewardCoins = 150,
	DailyRewardSeconds = 20 * 60 * 60,

	XPPerMatch = 40,
	XPPerWin = 80,
	XPPerKill = 18,
	CoinsPerMatch = 25,
	CoinsPerWin = 50,
	CoinsPerKill = 8,

	StarterFighters = { "ShadowStriker", "FrostReaper" },
	DefaultFighter = "ShadowStriker",
	DefaultArena = "EternalArena",

	LobbyCFrame = CFrame.new(0, 12, 0),
	ArenaOrigins = {
		EternalArena = Vector3.new(0, 0, 900),
		DragonfallTemple = Vector3.new(900, 0, 0),
		InfernoFortress = Vector3.new(-900, 0, 0),
		SkybladeDojo = Vector3.new(0, 0, -900),
		CyberneticCity = Vector3.new(1800, 0, 0),
	},
}

return GameConfig
