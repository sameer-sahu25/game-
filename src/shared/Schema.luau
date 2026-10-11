--!strict

local GameConfig = require(script.Parent.GameConfig)
local Fighters = require(script.Parent.Fighters)

export type Settings = {
	musicVolume: number,
	sfxVolume: number,
	cameraSensitivity: number,
	cameraShake: boolean,
	reducedVfx: boolean,
	uiScale: number,
	tutorialComplete: boolean,
}

export type PlayerProfile = {
	schemaVersion: number,
	level: number,
	xp: number,
	coins: number,
	kills: number,
	deaths: number,
	wins: number,
	losses: number,
	matches: number,
	winStreak: number,
	equippedFighter: string,
	unlockedFighters: { string },
	cosmetics: { string },
	equippedCosmetics: { [string]: string },
	achievements: { [string]: boolean },
	settings: Settings,
	lastDailyClaim: number,
	createdAt: number,
}

local Schema = {}

function Schema.defaultSettings(): Settings
	return {
		musicVolume = 0.6,
		sfxVolume = 0.8,
		cameraSensitivity = 1,
		cameraShake = true,
		reducedVfx = false,
		uiScale = 1,
		tutorialComplete = false,
	}
end

function Schema.default(): PlayerProfile
	return {
		schemaVersion = GameConfig.SchemaVersion,
		level = 1,
		xp = 0,
		coins = 0,
		kills = 0,
		deaths = 0,
		wins = 0,
		losses = 0,
		matches = 0,
		winStreak = 0,
		equippedFighter = GameConfig.DefaultFighter,
		unlockedFighters = table.clone(GameConfig.StarterFighters),
		cosmetics = {},
		equippedCosmetics = {},
		achievements = {},
		settings = Schema.defaultSettings(),
		lastDailyClaim = 0,
		createdAt = os.time(),
	}
end

function Schema.xpForLevel(level: number): number
	return math.floor(100 + (level - 1) * 55)
end

function Schema.migrate(raw: any): PlayerProfile
	local base = Schema.default()
	if typeof(raw) ~= "table" then
		return base
	end
	for key, value in base :: any do
		if raw[key] ~= nil then
			(base :: any)[key] = raw[key]
		end
	end
	if typeof(base.unlockedFighters) ~= "table" then
		base.unlockedFighters = table.clone(GameConfig.StarterFighters)
	end
	if typeof(base.settings) ~= "table" then
		base.settings = Schema.defaultSettings()
	end
	if not Fighters[base.equippedFighter] then
		base.equippedFighter = GameConfig.DefaultFighter
	end
	base.schemaVersion = GameConfig.SchemaVersion
	base.coins = math.max(0, math.floor(base.coins))
	base.level = math.max(1, math.floor(base.level))
	return base
end

function Schema.clientSafe(profile: PlayerProfile): PlayerProfile
	-- Profile is already non-sensitive; clone for replication.
	return table.clone(profile)
end

return Schema
