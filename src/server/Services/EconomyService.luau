--!strict

local Players = game:GetService("Players")
local GameConfig = require(game.ReplicatedStorage.BattleLegends.GameConfig)
local Schema = require(game.ReplicatedStorage.BattleLegends.Schema)
local Achievements = require(game.ReplicatedStorage.BattleLegends.Achievements)
local ShopCatalog = require(game.ReplicatedStorage.BattleLegends.ShopCatalog)
local Fighters = require(game.ReplicatedStorage.BattleLegends.Fighters)
local Remotes = require(game.ReplicatedStorage.BattleLegends.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)

local EconomyService = {}
EconomyService._notify = nil :: RemoteEvent?

local function notify(player: Player, text: string)
	if EconomyService._notify then
		EconomyService._notify:FireClient(player, { kind = "info", text = text })
	end
end

function EconomyService.addCoins(player: Player, amount: number, reason: string)
	amount = math.floor(math.max(0, amount))
	PlayerDataService.mutate(player, function(p)
		p.coins += amount
	end)
	if amount > 0 then
		notify(player, string.format("+%d Battle Coins (%s)", amount, reason))
	end
end

function EconomyService.addXp(player: Player, amount: number)
	amount = math.floor(math.max(0, amount))
	PlayerDataService.mutate(player, function(p)
		p.xp += amount
		while p.xp >= Schema.xpForLevel(p.level) do
			p.xp -= Schema.xpForLevel(p.level)
			p.level += 1
			notify(player, "Level up! You are now level " .. p.level)
		end
	end)
end

function EconomyService.unlockAchievement(player: Player, id: string)
	local def
	for _, a in Achievements do
		if a.id == id then
			def = a
			break
		end
	end
	if not def then
		return
	end
	local already = false
	PlayerDataService.mutate(player, function(p)
		if p.achievements[id] then
			already = true
			return
		end
		p.achievements[id] = true
		p.coins += def.rewardCoins
	end)
	if not already then
		notify(player, "Achievement: " .. def.name)
	end
end

function EconomyService.evaluate(player: Player)
	local p = PlayerDataService.get(player)
	if not p then
		return
	end
	if p.wins >= 1 then
		EconomyService.unlockAchievement(player, "FirstVictory")
	end
	if p.kills >= 10 then
		EconomyService.unlockAchievement(player, "FirstTenKills")
	end
	if p.wins >= 10 then
		EconomyService.unlockAchievement(player, "ArenaChampion")
	end
	if p.matches >= 25 then
		EconomyService.unlockAchievement(player, "VeteranFighter")
	end
	if #p.unlockedFighters >= 4 then
		EconomyService.unlockAchievement(player, "Collector")
	end
end

function EconomyService.buy(player: Player, itemId: any): (boolean, string)
	if typeof(itemId) ~= "string" then
		return false, "Invalid item"
	end
	local item
	for _, it in ShopCatalog do
		if it.id == itemId then
			item = it
			break
		end
	end
	if not item then
		return false, "Unknown item"
	end
	local profile = PlayerDataService.get(player)
	if not profile then
		return false, "No profile"
	end
	if profile.coins < item.cost then
		return false, "Not enough Battle Coins"
	end
	if item.kind == "fighter" and item.fighterId then
		if table.find(profile.unlockedFighters, item.fighterId) then
			return false, "Already owned"
		end
		if not Fighters[item.fighterId] then
			return false, "Invalid fighter"
		end
		PlayerDataService.mutate(player, function(p)
			p.coins -= item.cost
			table.insert(p.unlockedFighters, item.fighterId :: string)
		end)
		EconomyService.evaluate(player)
		return true, "Unlocked " .. item.name
	end
	if table.find(profile.cosmetics, item.id) then
		return false, "Already owned"
	end
	PlayerDataService.mutate(player, function(p)
		p.coins -= item.cost
		table.insert(p.cosmetics, item.id)
	end)
	return true, "Purchased " .. item.name
end

function EconomyService.claimDaily(player: Player): (boolean, string)
	local profile = PlayerDataService.get(player)
	if not profile then
		return false, "No profile"
	end
	local elapsed = os.time() - profile.lastDailyClaim
	if elapsed < GameConfig.DailyRewardSeconds then
		return false, "Daily reward not ready"
	end
	PlayerDataService.mutate(player, function(p)
		p.lastDailyClaim = os.time()
		p.coins += GameConfig.DailyRewardCoins
	end)
	EconomyService.unlockAchievement(player, "DailyChallenger")
	return true, "Claimed " .. GameConfig.DailyRewardCoins .. " Battle Coins"
end

function EconomyService.init()
	EconomyService._notify = Remotes.get("UiNotify")
	Remotes.get("ShopBuy").OnServerEvent:Connect(function(player, itemId)
		local ok, msg = EconomyService.buy(player, itemId)
		notify(player, msg)
		if ok then
			Remotes.get("PlayerState"):FireClient(player, PlayerDataService.get(player))
		end
	end)
	Remotes.get("ClaimDaily").OnServerEvent:Connect(function(player)
		local _, msg = EconomyService.claimDaily(player)
		notify(player, msg)
		Remotes.get("PlayerState"):FireClient(player, PlayerDataService.get(player))
	end)
end

return EconomyService
