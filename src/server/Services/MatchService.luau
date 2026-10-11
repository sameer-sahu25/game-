--!strict

local Players = game:GetService("Players")
local GameConfig = require(game.ReplicatedStorage.BattleLegends.GameConfig)
local Remotes = require(game.ReplicatedStorage.BattleLegends.Remotes)
local WorldBuilder = require(script.Parent.Parent.World.WorldBuilder)
local CombatService = require(script.Parent.CombatService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local CharacterService = require(script.Parent.CharacterService)

export type MatchStateName = "Idle" | "Countdown" | "Active" | "Results"

export type MatchRecord = {
	id: number,
	mode: string,
	arenaId: string,
	players: { Player },
	teams: { [number]: number },
	kills: { [number]: number },
	alive: { [number]: boolean },
	state: MatchStateName,
	endsAt: number,
	startedAt: number,
}

local MatchService = {}
MatchService._queues = {
	FFA = {} :: { Player },
	Duel = {} :: { Player },
	Team2v2 = {} :: { Player },
	Training = {} :: { Player },
	Survival = {} :: { Player },
}
MatchService._byPlayer = {} :: { [number]: MatchRecord }
MatchService._matchCounter = 0
MatchService._matchStateRemote = nil :: RemoteEvent?
MatchService._npc = nil :: any

local function broadcast(match: MatchRecord, extra: { [string]: any }?)
	local payload = {
		id = match.id,
		mode = match.mode,
		arenaId = match.arenaId,
		state = match.state,
		endsAt = match.endsAt,
		kills = match.kills,
		players = {},
	}
	for _, p in match.players do
		table.insert(payload.players, { name = p.Name, userId = p.UserId, kills = match.kills[p.UserId] or 0 })
	end
	payload.remaining = math.max(0, math.floor(match.endsAt - os.clock()))
	if extra then
		for k, v in extra do
			payload[k] = v
		end
	end
	for _, p in match.players do
		if p.Parent then
			MatchService._matchStateRemote:FireClient(p, payload)
		end
	end
end

local function teleportToArena(player: Player, cf: CFrame)
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp.CFrame = cf
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Health = hum.MaxHealth
	end
	CombatService.reset(player)
end

local function returnToLobby(player: Player)
	local char = player.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			hrp.CFrame = GameConfig.LobbyCFrame
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Health = hum.MaxHealth
		end
	end
end

function MatchService.inMatch(player: Player): boolean
	local m = MatchService._byPlayer[player.UserId]
	return m ~= nil and (m.state == "Countdown" or m.state == "Active")
end

function MatchService.canFight(player: Player): boolean
	local m = MatchService._byPlayer[player.UserId]
	if m and m.state == "Active" then
		return true
	end
	-- Training zone combat always allowed for dummies / practice
	return not m
end

function MatchService.enqueue(player: Player, mode: any, arenaId: any)
	if typeof(mode) ~= "string" or MatchService._queues[mode] == nil then
		return
	end
	if MatchService._byPlayer[player.UserId] then
		return
	end
	for _, q in MatchService._queues do
		local i = table.find(q, player)
		if i then
			table.remove(q, i)
		end
	end
	table.insert(MatchService._queues[mode], player)
	Remotes.get("UiNotify"):FireClient(player, { kind = "info", text = "Queued for " .. mode })
	MatchService.tryStart(mode, if typeof(arenaId) == "string" then arenaId else GameConfig.DefaultArena)
end

function MatchService.leaveQueue(player: Player)
	for _, q in MatchService._queues do
		local i = table.find(q, player)
		if i then
			table.remove(q, i)
		end
	end
end

function MatchService.tryStart(mode: string, arenaId: string)
	local q = MatchService._queues[mode]
	local need = 2
	if mode == "Duel" then
		need = 2
	elseif mode == "Team2v2" then
		need = 4
	elseif mode == "Training" or mode == "Survival" then
		need = 1
	elseif mode == "FFA" then
		need = if GameConfig.AllowSoloMatch then 1 else GameConfig.MinPlayersFFA
	end
	if #q < need then
		return
	end
	local taken = {}
	local maxP = if mode == "FFA" then math.min(GameConfig.MaxPlayersFFA, #q) elseif mode == "Duel" then 2 elseif mode == "Team2v2" then 4 else 1
	for i = 1, maxP do
		table.insert(taken, table.remove(q, 1))
	end
	MatchService.beginMatch(mode, arenaId, taken)
end

function MatchService.beginMatch(mode: string, arenaId: string, list: { Player })
	MatchService._matchCounter += 1
	local match: MatchRecord = {
		id = MatchService._matchCounter,
		mode = mode,
		arenaId = if mode == "Training" then "Lobby" else arenaId,
		players = list,
		teams = {},
		kills = {},
		alive = {},
		state = "Countdown",
		endsAt = os.clock() + GameConfig.CountdownSeconds + GameConfig.MatchDurationSeconds,
		startedAt = os.clock(),
	}
	if mode == "Team2v2" then
		for i, p in list do
			match.teams[p.UserId] = if i <= 2 then 1 else 2
		end
	end
	for _, p in list do
		match.kills[p.UserId] = 0
		match.alive[p.UserId] = true
		MatchService._byPlayer[p.UserId] = match
	end

	local spawns = WorldBuilder.getSpawnCFrames(if mode == "Training" then "EternalArena" else arenaId)
	if mode == "Training" then
		for _, p in list do
			p:SetAttribute("InTraining", true)
		end
	else
		for i, p in list do
			local cf = spawns[((i - 1) % math.max(#spawns, 1)) + 1] or GameConfig.LobbyCFrame
			teleportToArena(p, cf)
			local char = p.Character or p.CharacterAdded:Wait()
			if match.teams[p.UserId] then
				char:SetAttribute("Team", match.teams[p.UserId])
			else
				char:SetAttribute("Team", nil)
			end
			CharacterService.applyLook(char, CharacterService.getEquipped(p))
		end
	end

	broadcast(match, { countdown = GameConfig.CountdownSeconds })
	task.delay(GameConfig.CountdownSeconds, function()
		if match.state ~= "Countdown" then
			return
		end
		match.state = "Active"
		match.endsAt = os.clock() + (if mode == "Training" then 3600 else GameConfig.MatchDurationSeconds)
		broadcast(match)
		if mode == "Survival" and MatchService._npc then
			MatchService._npc.startSurvival(match)
		end
	end)

	if mode ~= "Training" then
		task.delay(GameConfig.CountdownSeconds + GameConfig.MatchDurationSeconds, function()
			if match.state == "Active" then
				MatchService.finish(match)
			end
		end)
	end
end

function MatchService.onKill(attacker: Player, victim: Player)
	local match = MatchService._byPlayer[attacker.UserId]
	if not match or match.state ~= "Active" then
		return
	end
	if match.mode == "Team2v2" and match.teams[attacker.UserId] == match.teams[victim.UserId] then
		return
	end
	match.kills[attacker.UserId] = (match.kills[attacker.UserId] or 0) + 1
	CombatService.grantUlt(attacker, GameConfig.UltFromKill)
	PlayerDataService.mutate(attacker, function(p)
		p.kills += 1
	end)
	PlayerDataService.mutate(victim, function(p)
		p.deaths += 1
	end)
	EconomyService.addCoins(attacker, GameConfig.CoinsPerKill, "kill")
	EconomyService.addXp(attacker, GameConfig.XPPerKill)
	EconomyService.evaluate(attacker)
	broadcast(match)

	if match.mode == "Duel" then
		MatchService.finish(match)
		return
	end

	task.delay(GameConfig.RespawnDelaySeconds, function()
		if match.state ~= "Active" then
			return
		end
		if not victim.Parent then
			return
		end
		victim:LoadCharacter()
		task.wait(0.2)
		local spawns = WorldBuilder.getSpawnCFrames(match.arenaId)
		if #spawns > 0 and victim.Character then
			local hrp = victim.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				hrp.CFrame = spawns[math.random(1, #spawns)]
			end
			CharacterService.applyLook(victim.Character, CharacterService.getEquipped(victim))
			CombatService.reset(victim)
		end
	end)
end

function MatchService.finish(match: MatchRecord)
	if match.state == "Results" or match.state == "Idle" then
		return
	end
	match.state = "Results"
	local ranking = {}
	for _, p in match.players do
		table.insert(ranking, { userId = p.UserId, name = p.Name, kills = match.kills[p.UserId] or 0, team = match.teams[p.UserId] })
	end
	table.sort(ranking, function(a, b)
		return a.kills > b.kills
	end)
	local winnerId = ranking[1] and ranking[1].userId
	if match.mode == "Team2v2" then
		local t1, t2 = 0, 0
		for _, p in match.players do
			if match.teams[p.UserId] == 1 then
				t1 += match.kills[p.UserId] or 0
			else
				t2 += match.kills[p.UserId] or 0
			end
		end
		local winTeam = if t1 >= t2 then 1 else 2
		for _, p in match.players do
			if p.Parent then
				local win = match.teams[p.UserId] == winTeam
				PlayerDataService.mutate(p, function(pr)
					pr.matches += 1
					if win then
						pr.wins += 1
						pr.winStreak += 1
					else
						pr.losses += 1
						pr.winStreak = 0
					end
				end)
				EconomyService.addCoins(p, GameConfig.CoinsPerMatch + (if win then GameConfig.CoinsPerWin else 0), "match")
				EconomyService.addXp(p, GameConfig.XPPerMatch + (if win then GameConfig.XPPerWin else 0))
				EconomyService.evaluate(p)
			end
		end
	else
		for _, p in match.players do
			if p.Parent then
				local win = p.UserId == winnerId
				PlayerDataService.mutate(p, function(pr)
					pr.matches += 1
					if win then
						pr.wins += 1
						pr.winStreak += 1
					else
						pr.losses += 1
						pr.winStreak = 0
					end
				end)
				EconomyService.addCoins(p, GameConfig.CoinsPerMatch + (if win then GameConfig.CoinsPerWin else 0), "match")
				EconomyService.addXp(p, GameConfig.XPPerMatch + (if win then GameConfig.XPPerWin else 0))
				EconomyService.evaluate(p)
			end
		end
	end
	broadcast(match, { ranking = ranking, winnerId = winnerId })
	task.delay(GameConfig.ResultsDisplaySeconds, function()
		for _, p in match.players do
			MatchService._byPlayer[p.UserId] = nil
			p:SetAttribute("InTraining", nil)
			if p.Parent then
				returnToLobby(p)
				Remotes.get("PlayerState"):FireClient(p, PlayerDataService.get(p))
			end
		end
		match.state = "Idle"
	end)
end

function MatchService.init(npcService: any?)
	MatchService._npc = npcService
	MatchService._matchStateRemote = Remotes.get("MatchState")
	CombatService.setHooks({
		onKill = MatchService.onKill,
		canFight = MatchService.canFight,
	})
	Remotes.get("QueueMatch").OnServerEvent:Connect(function(player, mode, arenaId)
		MatchService.enqueue(player, mode, arenaId)
	end)
	Remotes.get("LeaveQueue").OnServerEvent:Connect(function(player)
		MatchService.leaveQueue(player)
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			local seen = {}
			for _, match in MatchService._byPlayer do
				if not seen[match.id] and (match.state == "Active" or match.state == "Countdown") then
					seen[match.id] = true
					broadcast(match)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		MatchService.leaveQueue(player)
		local match = MatchService._byPlayer[player.UserId]
		if match then
			match.alive[player.UserId] = false
			local remaining = 0
			for _, p in match.players do
				if p.Parent and p ~= player then
					remaining += 1
				end
			end
			if remaining <= 0 and match.state == "Active" then
				MatchService.finish(match)
			end
		end
		MatchService._byPlayer[player.UserId] = nil
	end)
end

return MatchService
