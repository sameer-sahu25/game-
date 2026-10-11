--!strict

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local GameConfig = require(game.ReplicatedStorage.BattleLegends.GameConfig)
local Fighters = require(game.ReplicatedStorage.BattleLegends.Fighters)
local Abilities = require(game.ReplicatedStorage.BattleLegends.Abilities)
local Remotes = require(game.ReplicatedStorage.BattleLegends.Remotes)
local RateLimiter = require(game.ReplicatedStorage.BattleLegends.RateLimiter)

export type CombatState = {
	blocking: boolean,
	blockStarted: number,
	comboCount: number,
	lastLight: number,
	lastHeavy: number,
	lastDodge: number,
	lastSpecial: number,
	lastUltimate: number,
	energy: number,
	ultimate: number,
	stunUntil: number,
	iframesUntil: number,
	shield: number,
	slowUntil: number,
	slowFactor: number,
	specialHits: number,
}

local CombatService = {}
CombatService._states = {} :: { [number]: CombatState }
CombatService._limiter = RateLimiter.new(GameConfig.RateLimitCombat)
CombatService._onKill = nil :: ((Player, Player) -> ())?
CombatService._canFight = nil :: ((Player) -> boolean)?
CombatService._fx = nil :: RemoteEvent?

local function now(): number
	return os.clock()
end

function CombatService.setHooks(hooks: {
	onKill: (Player, Player) -> (),
	canFight: (Player) -> boolean,
})
	CombatService._onKill = hooks.onKill
	CombatService._canFight = hooks.canFight
end

function CombatService.state(player: Player): CombatState
	local s = CombatService._states[player.UserId]
	if not s then
		s = {
			blocking = false,
			blockStarted = 0,
			comboCount = 0,
			lastLight = 0,
			lastHeavy = 0,
			lastDodge = 0,
			lastSpecial = 0,
			lastUltimate = 0,
			energy = GameConfig.BaseEnergy,
			ultimate = 0,
			stunUntil = 0,
			iframesUntil = 0,
			shield = 0,
			slowUntil = 0,
			slowFactor = 1,
			specialHits = 0,
		}
		CombatService._states[player.UserId] = s
	end
	return s
end

function CombatService.reset(player: Player)
	CombatService._states[player.UserId] = nil
	CombatService.state(player)
end

local function root(model: Model): BasePart?
	return model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function los(fromPos: Vector3, toPos: Vector3, ignore: Instance): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { ignore }
	local dir = toPos - fromPos
	local result = workspace:Raycast(fromPos, dir, params)
	if not result then
		return true
	end
	local model = result.Instance:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		return true
	end
	if result.Instance:GetAttribute("TrainingDummy") then
		return true
	end
	return false
end

local function fx(kind: string, payload: { [string]: any })
	if CombatService._fx then
		CombatService._fx:FireAllClients(kind, payload)
	end
end

local function applyKnock(targetRoot: BasePart, fromPos: Vector3, force: number)
	local dir = (targetRoot.Position - fromPos)
	if dir.Magnitude < 0.1 then
		dir = targetRoot.CFrame.LookVector
	end
	dir = dir.Unit + Vector3.new(0, 0.25, 0)
	targetRoot.AssemblyLinearVelocity = dir.Unit * force
end

function CombatService.grantUlt(player: Player, amount: number)
	local s = CombatService.state(player)
	s.ultimate = math.clamp(s.ultimate + amount, 0, GameConfig.UltimateMax)
end

function CombatService.snapshot(player: Player): { [string]: any }
	local s = CombatService.state(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return {
		health = if hum then hum.Health else 0,
		maxHealth = if hum then hum.MaxHealth else GameConfig.MaxHealth,
		energy = s.energy,
		ultimate = s.ultimate,
		combo = s.comboCount,
		blocking = s.blocking,
		fighter = if char then char:GetAttribute("FighterId") else GameConfig.DefaultFighter,
	}
end

local function hitPlayerOrDummy(attacker: Player, origin: Vector3, look: Vector3, range: number, radius: number, damage: number, knock: number, stun: number, abilityId: string?)
	local hits = {}
	look = if look.Magnitude > 0.05 then look.Unit else Vector3.new(0, 0, -1)
	local center = origin + look * math.min(range, range * 0.55)

	for _, other in Players:GetPlayers() do
		if other ~= attacker and other.Character then
			local r = root(other.Character)
			local hum = other.Character:FindFirstChildOfClass("Humanoid")
			if r and hum and hum.Health > 0 then
				local atkTeam = attacker.Character and attacker.Character:GetAttribute("Team")
				local defTeam = other.Character:GetAttribute("Team")
				if typeof(atkTeam) == "number" and atkTeam == defTeam then
					continue
				end
				local dist = (r.Position - origin).Magnitude
				local lateral = (r.Position - center).Magnitude
				if dist <= range + 2 and lateral <= radius + 3 then
					if los(origin, r.Position, attacker.Character) then
						table.insert(hits, { player = other, root = r, humanoid = hum, model = other.Character })
					end
				end
			end
		end
	end

	local world = workspace:FindFirstChild("BattleWorld")
	if world then
		local grounds = world:FindFirstChild("TrainingGrounds")
		if grounds then
			for _, inst in grounds:GetChildren() do
				if inst:IsA("BasePart") and inst:GetAttribute("TrainingDummy") then
					if (inst.Position - origin).Magnitude <= range + 4 then
						local hum = inst:FindFirstChildOfClass("Humanoid")
						if hum then
							table.insert(hits, { player = nil, root = inst, humanoid = hum, model = inst, dummy = true })
						end
					end
				end
			end
		end
	end

	local dealt = 0
	for _, h in hits do
		local victimState: CombatState? = nil
		if h.player then
			victimState = CombatService.state(h.player)
			if now() < victimState.iframesUntil then
				continue
			end
		end
		local dmg = math.clamp(damage, 0, GameConfig.MaxDamagePerHit)
		if victimState and victimState.blocking then
			local perfect = (now() - victimState.blockStarted) <= GameConfig.PerfectBlockWindow
			if perfect then
				dmg = 0
				fx("PerfectBlock", { pos = h.root.Position })
			else
				dmg *= GameConfig.BlockDamageMultiplier
			end
		end
		if victimState and victimState.shield > 0 then
			local absorb = math.min(victimState.shield, dmg)
			victimState.shield -= absorb
			dmg -= absorb
		end
		if dmg > 0 then
			h.humanoid:TakeDamage(dmg)
			dealt += dmg
			applyKnock(h.root, origin, knock)
			if victimState then
				victimState.stunUntil = now() + stun
				CombatService.grantUlt(h.player, dmg * GameConfig.UltFromDamageTaken)
			end
			fx("Hit", { pos = h.root.Position, dummy = h.dummy == true, damage = math.floor(dmg) })
			if h.player and h.humanoid.Health <= 0 and CombatService._onKill then
				CombatService._onKill(attacker, h.player)
			end
		end
	end
	if abilityId and dealt > 0 then
		CombatService.state(attacker).specialHits += 1
	end
	return dealt
end

function CombatService._regenLoop()
	task.spawn(function()
		while true do
			task.wait(0.25)
			for _, player in Players:GetPlayers() do
				local s = CombatService._states[player.UserId]
				if s then
					s.energy = math.min(GameConfig.BaseEnergy, s.energy + GameConfig.EnergyRegenPerSecond * 0.25)
					local char = player.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if hum and now() < s.slowUntil then
						hum.WalkSpeed = math.max(8, (char:GetAttribute("SpeedBase") or 16) * s.slowFactor)
					elseif hum then
						local sprint = player:GetAttribute("Sprinting") == true
						hum.WalkSpeed = if sprint then GameConfig.SprintSpeed else (char:GetAttribute("SpeedBase") or GameConfig.WalkSpeed)
					end
				end
			end
		end
	end)
end

function CombatService.handle(player: Player, action: any)
	if typeof(action) ~= "table" then
		return
	end
	if not CombatService._limiter:allow(player.UserId) then
		return
	end
	if CombatService._canFight and not CombatService._canFight(player) then
		if action.kind ~= "BlockEnd" then
			return
		end
	end
	local char = player.Character
	if not char then
		return
	end
	local r = root(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not r or not hum or hum.Health <= 0 then
		return
	end
	local s = CombatService.state(player)
	if now() < s.stunUntil and action.kind ~= "BlockEnd" then
		return
	end
	local look = action.look
	if typeof(look) ~= "Vector3" then
		look = r.CFrame.LookVector
	else
		if look.Magnitude > 0.05 then
			look = look.Unit
		else
			look = r.CFrame.LookVector
		end
	end

	local kind = action.kind
	if kind == "BlockStart" then
		s.blocking = true
		s.blockStarted = now()
		return
	elseif kind == "BlockEnd" then
		s.blocking = false
		return
	elseif kind == "SprintStart" then
		player:SetAttribute("Sprinting", true)
		return
	elseif kind == "SprintEnd" then
		player:SetAttribute("Sprinting", false)
		return
	elseif kind == "Dodge" then
		if now() - s.lastDodge < GameConfig.DodgeCooldown then
			return
		end
		s.lastDodge = now()
		s.iframesUntil = now() + GameConfig.DodgeIFrames
		r.AssemblyLinearVelocity = look * GameConfig.DodgeSpeed + Vector3.new(0, 8, 0)
		fx("Dodge", { pos = r.Position, userId = player.UserId })
		return
	elseif kind == "Light" then
		if now() - s.lastLight < GameConfig.LightCooldown then
			return
		end
		if now() - s.lastLight > GameConfig.ComboWindow then
			s.comboCount = 0
		end
		s.lastLight = now()
		s.comboCount = math.min(GameConfig.ComboMaxHits, s.comboCount + 1)
		local scale = 1
		if s.comboCount > GameConfig.ComboScaleAfter then
			scale = GameConfig.ComboScaleFactor
		end
		local dmg = GameConfig.LightDamage * scale
		local dealt = hitPlayerOrDummy(player, r.Position, look, GameConfig.LightRange, 4.5, dmg, GameConfig.KnockbackLight, GameConfig.HitStunLight)
		CombatService.grantUlt(player, dealt * GameConfig.UltFromDamageDealt)
		fx("Light", { pos = r.Position + look * 4, userId = player.UserId })
		return
	elseif kind == "Heavy" then
		if now() - s.lastHeavy < GameConfig.HeavyCooldown then
			return
		end
		s.lastHeavy = now()
		s.comboCount = 0
		task.delay(GameConfig.HeavyStartup, function()
			if not player.Parent or not player.Character then
				return
			end
			local nr = root(player.Character)
			if not nr then
				return
			end
			local dealt = hitPlayerOrDummy(player, nr.Position, look, GameConfig.HeavyRange, 5.5, GameConfig.HeavyDamage, GameConfig.KnockbackHeavy, GameConfig.HitStunHeavy)
			CombatService.grantUlt(player, dealt * GameConfig.UltFromDamageDealt)
			fx("Heavy", { pos = nr.Position + look * 5, userId = player.UserId })
		end)
		return
	elseif kind == "Special" or kind == "Ultimate" then
		local fighterId = char:GetAttribute("FighterId") or GameConfig.DefaultFighter
		local def = Fighters[fighterId]
		if not def then
			return
		end
		local abilityId = if kind == "Ultimate" then def.ultimateId else def.specialId
		local ab = Abilities[abilityId]
		if not ab then
			return
		end
		if kind == "Ultimate" then
			if s.ultimate < ab.ultimateCost then
				return
			end
			if now() - s.lastUltimate < ab.cooldown then
				return
			end
		else
			if s.energy < ab.energyCost then
				return
			end
			if now() - s.lastSpecial < ab.cooldown then
				return
			end
		end
		if kind == "Ultimate" then
			s.ultimate -= ab.ultimateCost
			s.lastUltimate = now()
		else
			s.energy -= ab.energyCost
			s.lastSpecial = now()
		end
		fx("Telegraph", { pos = r.Position, radius = ab.radius, color = { ab.color.R, ab.color.G, ab.color.B }, wait = ab.startup })
		task.delay(ab.startup, function()
			if not player.Parent or not player.Character then
				return
			end
			local nr = root(player.Character)
			if not nr then
				return
			end
			if ab.kind == "dash" or ab.kind == "teleport" then
				local dest = nr.Position + look * ab.range
				local params = RaycastParams.new()
				params.FilterDescendantsInstances = { player.Character }
				local ray = workspace:Raycast(nr.Position, look * ab.range, params)
				if ray then
					dest = ray.Position - look * 3
				end
				nr.CFrame = CFrame.new(dest, dest + look)
			end
			if ab.kind == "shield" then
				s.shield = ab.shieldAmount
				fx("Shield", { userId = player.UserId })
				return
			end
			local dealt = hitPlayerOrDummy(player, nr.Position, look, math.max(ab.range, ab.radius), math.max(ab.radius, 6), ab.damage, ab.knockback, 0.35, abilityId)
			CombatService.grantUlt(player, dealt * GameConfig.UltFromDamageDealt * 0.4)
			if ab.slowDuration > 0 then
				for _, other in Players:GetPlayers() do
					if other ~= player and other.Character then
						local oroot = root(other.Character)
						if oroot and (oroot.Position - nr.Position).Magnitude <= ab.radius + ab.range * 0.3 then
							local vs = CombatService.state(other)
							vs.slowUntil = now() + ab.slowDuration
							vs.slowFactor = ab.slowFactor
						end
					end
				end
			end
			fx("Ability", { id = abilityId, pos = nr.Position, look = look, userId = player.UserId })
		end)
	end
end

function CombatService.init()
	CombatService._fx = Remotes.get("CombatFx")
	Remotes.get("CombatAction").OnServerEvent:Connect(function(player, action)
		CombatService.handle(player, action)
	end)
	Players.PlayerRemoving:Connect(function(player)
		CombatService._states[player.UserId] = nil
		CombatService._limiter:clear(player.UserId)
	end)
	CombatService._regenLoop()
end

return CombatService
