--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local GameConfig = require(game.ReplicatedStorage.BattleLegends.GameConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)
local Remotes = require(game.ReplicatedStorage.BattleLegends.Remotes)

local LeaderboardService = {}

local function ordered(name: string): OrderedDataStore?
	local ok, store = pcall(function()
		return DataStoreService:GetOrderedDataStore(name)
	end)
	if ok then
		return store
	end
	return nil
end

function LeaderboardService.update(player: Player)
	local profile = PlayerDataService.get(player)
	if not profile then
		return
	end
	local kills = ordered(GameConfig.OrderedStoreKills)
	local wins = ordered(GameConfig.OrderedStoreWins)
	local level = ordered(GameConfig.OrderedStoreLevel)
	if kills then
		pcall(function()
			kills:SetAsync(tostring(player.UserId), profile.kills)
		end)
	end
	if wins then
		pcall(function()
			wins:SetAsync(tostring(player.UserId), profile.wins)
		end)
	end
	if level then
		pcall(function()
			level:SetAsync(tostring(player.UserId), profile.level)
		end)
	end
end

function LeaderboardService.snapshot(): { [string]: any }
	local out = { kills = {}, wins = {}, level = {} }
	local function pull(storeName: string, bucket: { any })
		local store = ordered(storeName)
		if not store then
			return
		end
		local ok, pages = pcall(function()
			return store:GetSortedAsync(false, 10)
		end)
		if ok and pages then
			local page = pages:GetCurrentPage()
			for _, e in page do
				table.insert(bucket, { userId = tonumber(e.key) or 0, value = e.value })
			end
		end
	end
	pull(GameConfig.OrderedStoreKills, out.kills)
	pull(GameConfig.OrderedStoreWins, out.wins)
	pull(GameConfig.OrderedStoreLevel, out.level)
	return out
end

function LeaderboardService.init()
	Players.PlayerRemoving:Connect(function(player)
		pcall(LeaderboardService.update, player)
	end)
end

return LeaderboardService
