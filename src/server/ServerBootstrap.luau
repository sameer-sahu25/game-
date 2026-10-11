--!strict
--[[
	Phase 1 bootstrap: remotes, world, data, combat, matches.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("BattleLegends")
local Remotes = require(Shared.Remotes)
local GameConfig = require(Shared.GameConfig)
local Fighters = require(Shared.Fighters)

local WorldBuilder = require(script.Parent.World.WorldBuilder)
local PlayerDataService = require(script.Parent.Services.PlayerDataService)
local CharacterService = require(script.Parent.Services.CharacterService)
local CombatService = require(script.Parent.Services.CombatService)
local EconomyService = require(script.Parent.Services.EconomyService)
local MatchService = require(script.Parent.Services.MatchService)
local NPCService = require(script.Parent.Services.NPCService)
local LeaderboardService = require(script.Parent.Services.LeaderboardService)
local SecurityService = require(script.Parent.Services.SecurityService)

Remotes.createAll()
WorldBuilder.build()
PlayerDataService.startAutosave()
CharacterService.init()
CombatService.init()
EconomyService.init()
NPCService.init()
MatchService.init(NPCService)
LeaderboardService.init()

local function replicate(player: Player)
	local profile = PlayerDataService.get(player)
	if profile then
		Remotes.get("PlayerState"):FireClient(player, profile)
		Remotes.get("HudPulse"):FireClient(player, CombatService.snapshot(player))
	end
end

Players.PlayerAdded:Connect(function(player)
	PlayerDataService.load(player)
	SecurityService.watch(player)
	task.wait(0.4)
	replicate(player)
	Remotes.get("UiNotify"):FireClient(player, {
		kind = "info",
		text = "Welcome to BATTLE LEGENDS. Queue at the red Matchmaking pad or press Play.",
	})
end)

for _, player in Players:GetPlayers() do
	task.spawn(function()
		PlayerDataService.load(player)
		SecurityService.watch(player)
		replicate(player)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	LeaderboardService.update(player)
	PlayerDataService.release(player)
end)

Remotes.get("SelectFighter").OnServerEvent:Connect(function(player, fighterId)
	local ok, msg = CharacterService.equip(player, fighterId)
	Remotes.get("UiNotify"):FireClient(player, { kind = if ok then "info" else "error", text = msg })
	replicate(player)
end)

Remotes.get("SetSettings").OnServerEvent:Connect(function(player, settings)
	if typeof(settings) ~= "table" then
		return
	end
	PlayerDataService.mutate(player, function(p)
		if typeof(settings.musicVolume) == "number" then
			p.settings.musicVolume = math.clamp(settings.musicVolume, 0, 1)
		end
		if typeof(settings.sfxVolume) == "number" then
			p.settings.sfxVolume = math.clamp(settings.sfxVolume, 0, 1)
		end
		if typeof(settings.cameraSensitivity) == "number" then
			p.settings.cameraSensitivity = math.clamp(settings.cameraSensitivity, 0.2, 3)
		end
		if typeof(settings.cameraShake) == "boolean" then
			p.settings.cameraShake = settings.cameraShake
		end
		if typeof(settings.reducedVfx) == "boolean" then
			p.settings.reducedVfx = settings.reducedVfx
		end
		if typeof(settings.uiScale) == "number" then
			p.settings.uiScale = math.clamp(settings.uiScale, 0.75, 1.4)
		end
	end)
	replicate(player)
end)

Remotes.get("SkipTutorial").OnServerEvent:Connect(function(player)
	PlayerDataService.mutate(player, function(p)
		p.settings.tutorialComplete = true
	end)
	replicate(player)
end)

Remotes.get("TrainingCommand").OnServerEvent:Connect(function(player, cmd)
	if typeof(cmd) ~= "string" then
		return
	end
	if cmd == "ResetDummies" then
		local world = workspace:FindFirstChild("BattleWorld")
		local grounds = world and world:FindFirstChild("TrainingGrounds")
		if grounds then
			for _, d in grounds:GetChildren() do
				local hum = d:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.Health = hum.MaxHealth
				end
			end
		end
	elseif cmd == "ResetCooldowns" then
		CombatService.reset(player)
	end
end)

task.spawn(function()
	while true do
		task.wait(0.2)
		for _, player in Players:GetPlayers() do
			if PlayerDataService.get(player) then
				Remotes.get("HudPulse"):FireClient(player, CombatService.snapshot(player))
			end
		end
	end
end)

print(string.format("[BattleLegends] Server ready | fighters=%d | title=%s", #({
	"ShadowStriker",
}), GameConfig.Title))
-- count fighters
local n = 0
for _ in Fighters do
	n += 1
end
print("[BattleLegends] Roster size:", n)
