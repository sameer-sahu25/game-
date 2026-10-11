--!strict

local Players = game:GetService("Players")
local Fighters = require(game.ReplicatedStorage.BattleLegends.Fighters)
local GameConfig = require(game.ReplicatedStorage.BattleLegends.GameConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)

local CharacterService = {}
CharacterService._appearance = {} :: { [number]: string }

local function weld(part: BasePart, to: BasePart)
	part.CFrame = to.CFrame
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = part
	w.Parent = part
	part.Anchored = false
	part.CanCollide = false
	part.Massless = true
end

function CharacterService.applyLook(character: Model, fighterId: string)
	local def = Fighters[fighterId]
	if not def then
		return
	end
	local body = character:FindFirstChildOfClass("BodyColors")
	if not body then
		body = Instance.new("BodyColors")
		body.Parent = character
	end
	body.HeadColor3 = def.colors.hair
	body.TorsoColor3 = def.colors.primary
	body.LeftArmColor3 = def.colors.secondary
	body.RightArmColor3 = def.colors.secondary
	body.LeftLegColor3 = def.colors.primary
	body.RightLegColor3 = def.colors.primary

	local old = character:FindFirstChild("BL_Accessories")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "BL_Accessories"
	folder.Parent = character

	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local head = character:FindFirstChild("Head")
	if torso and torso:IsA("BasePart") then
		local core = Instance.new("Part")
		core.Name = "AuraCore"
		core.Size = Vector3.new(2.2, 2.2, 1.1)
		core.Material = Enum.Material.Neon
		core.Color = def.colors.accent
		core.Parent = folder
		weld(core, torso)
		local light = Instance.new("PointLight")
		light.Color = def.colors.accent
		light.Brightness = 1
		light.Range = 10
		light.Parent = core
	end
	if head and head:IsA("BasePart") then
		local spike = Instance.new("Part")
		spike.Name = "HairAccent"
		spike.Size = Vector3.new(1.1, 1.4, 1.1)
		spike.Material = Enum.Material.SmoothPlastic
		spike.Color = def.colors.hair
		spike.CFrame = head.CFrame * CFrame.new(0, 0.9, 0)
		spike.Parent = folder
		weld(spike, head)
	end

	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.MaxHealth = def.stats.health
		hum.Health = def.stats.health
		hum.WalkSpeed = def.stats.speed
		character:SetAttribute("SpeedBase", def.stats.speed)
		character:SetAttribute("FighterId", fighterId)
		character:SetAttribute("Power", def.stats.power)
		character:SetAttribute("Defense", def.stats.defense)
	end
end

function CharacterService.getEquipped(player: Player): string
	local profile = PlayerDataService.get(player)
	if profile then
		return profile.equippedFighter
	end
	return GameConfig.DefaultFighter
end

function CharacterService.canUse(player: Player, fighterId: string): boolean
	if not Fighters[fighterId] then
		return false
	end
	local profile = PlayerDataService.get(player)
	if not profile then
		return false
	end
	if Fighters[fighterId].starter then
		return true
	end
	return table.find(profile.unlockedFighters, fighterId) ~= nil
end

function CharacterService.equip(player: Player, fighterId: string): (boolean, string)
	if not CharacterService.canUse(player, fighterId) then
		return false, "Fighter locked"
	end
	PlayerDataService.mutate(player, function(p)
		p.equippedFighter = fighterId
	end)
	if player.Character then
		CharacterService.applyLook(player.Character, fighterId)
	end
	return true, "Equipped " .. Fighters[fighterId].name
end

function CharacterService.hookCharacter(player: Player)
	local function onChar(char: Model)
		local id = CharacterService.getEquipped(player)
		task.defer(function()
			if char.Parent then
				CharacterService.applyLook(char, id)
			end
		end)
	end
	player.CharacterAdded:Connect(onChar)
	if player.Character then
		onChar(player.Character)
	end
end

function CharacterService.init()
	Players.PlayerAdded:Connect(function(player)
		CharacterService.hookCharacter(player)
	end)
	for _, player in Players:GetPlayers() do
		CharacterService.hookCharacter(player)
	end
end

return CharacterService
