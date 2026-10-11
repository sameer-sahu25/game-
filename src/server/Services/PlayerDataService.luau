--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local GameConfig = require(game.ReplicatedStorage.BattleLegends.GameConfig)
local Schema = require(game.ReplicatedStorage.BattleLegends.Schema)

local PlayerDataService = {}
PlayerDataService._store = nil :: DataStore?
PlayerDataService._cache = {} :: { [number]: Schema.PlayerProfile }
PlayerDataService._loaded = {} :: { [number]: boolean }
PlayerDataService._saving = {} :: { [number]: boolean }

local function getStore(): DataStore?
	if PlayerDataService._store then
		return PlayerDataService._store
	end
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(GameConfig.DataStoreName)
	end)
	if ok then
		PlayerDataService._store = store
		return store
	end
	warn("[BattleLegends] DataStore unavailable (enable API in Game Settings for live saves):", store)
	return nil
end

local function key(userId: number): string
	return "u_" .. tostring(userId)
end

function PlayerDataService.load(player: Player): Schema.PlayerProfile
	if PlayerDataService._cache[player.UserId] then
		return PlayerDataService._cache[player.UserId]
	end
	local store = getStore()
	local profile: Schema.PlayerProfile? = nil
	if store then
		for attempt = 1, 4 do
			local ok, data = pcall(function()
				return store:GetAsync(key(player.UserId))
			end)
			if ok then
				profile = Schema.migrate(data)
				PlayerDataService._loaded[player.UserId] = true
				break
			end
			warn("[BattleLegends] Load failed attempt", attempt, data)
			task.wait(0.4 * attempt)
		end
		if not profile then
			-- Failed load: do not overwrite with defaults on save
			PlayerDataService._loaded[player.UserId] = false
			profile = Schema.default()
			warn("[BattleLegends] Using session-only defaults; save skipped until a successful load.")
		end
	else
		profile = Schema.default()
		PlayerDataService._loaded[player.UserId] = true -- Studio without store still session-saves in memory
	end
	PlayerDataService._cache[player.UserId] = profile
	return profile
end

function PlayerDataService.get(player: Player): Schema.PlayerProfile?
	return PlayerDataService._cache[player.UserId]
end

function PlayerDataService.save(player: Player): boolean
	local profile = PlayerDataService._cache[player.UserId]
	if not profile then
		return false
	end
	if PlayerDataService._loaded[player.UserId] == false then
		warn("[BattleLegends] Refusing save after failed load for", player.Name)
		return false
	end
	local store = getStore()
	if not store then
		return true
	end
	if PlayerDataService._saving[player.UserId] then
		return false
	end
	PlayerDataService._saving[player.UserId] = true
	local ok = false
	for attempt = 1, 4 do
		local success, err = pcall(function()
			store:UpdateAsync(key(player.UserId), function(old)
				local migrated = Schema.migrate(old)
				-- Keep schema; write current session profile
				return profile
			end)
		end)
		if success then
			ok = true
			break
		end
		warn("[BattleLegends] Save failed attempt", attempt, err)
		task.wait(0.5 * attempt)
	end
	PlayerDataService._saving[player.UserId] = nil
	return ok
end

function PlayerDataService.mutate(player: Player, fn: (Schema.PlayerProfile) -> ())
	local profile = PlayerDataService.get(player)
	if not profile then
		return
	end
	fn(profile)
end

function PlayerDataService.release(player: Player)
	PlayerDataService.save(player)
	PlayerDataService._cache[player.UserId] = nil
	PlayerDataService._loaded[player.UserId] = nil
end

function PlayerDataService.startAutosave()
	task.spawn(function()
		while true do
			task.wait(GameConfig.SaveIntervalSeconds)
			for _, player in Players:GetPlayers() do
				pcall(PlayerDataService.save, player)
			end
		end
	end)
	game:BindToClose(function()
		local jobs = {}
		for _, player in Players:GetPlayers() do
			table.insert(jobs, task.spawn(function()
				PlayerDataService.save(player)
			end))
		end
		if not RunService:IsStudio() then
			task.wait(3)
		end
	end)
end

return PlayerDataService
