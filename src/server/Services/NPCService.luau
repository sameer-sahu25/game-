--!strict

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local GameConfig = require(game.ReplicatedStorage.BattleLegends.GameConfig)
local WorldBuilder = require(script.Parent.Parent.World.WorldBuilder)
local PartFactory = require(script.Parent.Parent.World.PartFactory)

local NPCService = {}
NPCService._alive = {} :: { Model }

local DIFFICULTY = {
	Easy = { speed = 12, damage = 6, think = 1.2 },
	Normal = { speed = 14, damage = 8, think = 0.8 },
	Hard = { speed = 16, damage = 11, think = 0.55 },
	Expert = { speed = 18, damage = 14, think = 0.4 },
}

local function makeNpc(parent: Instance, cf: CFrame, name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.CFrame = cf
	root.Anchored = false
	root.Parent = model
	local torso = Instance.new("Part")
	torso.Name = "UpperTorso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Color = Color3.fromRGB(80, 30, 30)
	torso.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = torso
	weld.Parent = torso
	torso.CFrame = cf
	local hum = Instance.new("Humanoid")
	hum.MaxHealth = 80
	hum.Health = 80
	hum.WalkSpeed = 14
	hum.Parent = model
	model.PrimaryPart = root
	model.Parent = parent
	return model
end

function NPCService.clear()
	for _, m in NPCService._alive do
		if m.Parent then
			m:Destroy()
		end
	end
	table.clear(NPCService._alive)
end

function NPCService.startSurvival(match: any)
	NPCService.clear()
	local spawns = WorldBuilder.getSpawnCFrames(match.arenaId)
	local npcsFolder = workspace:FindFirstChild("BattleWorld") and workspace.BattleWorld:FindFirstChild("NPCs")
	if not npcsFolder then
		return
	end
	task.spawn(function()
		for wave = 1, 8 do
			if match.state ~= "Active" then
				break
			end
			local count = 2 + wave
			local diff = if wave < 3 then "Easy" elseif wave < 5 then "Normal" elseif wave < 7 then "Hard" else "Expert"
			local cfg = DIFFICULTY[diff]
			for i = 1, count do
				local cf = spawns[((i - 1) % math.max(#spawns, 1)) + 1] or CFrame.new(GameConfig.ArenaOrigins.EternalArena)
				local npc = makeNpc(npcsFolder, cf + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8)), "WaveNPC")
				npc:SetAttribute("Wave", wave)
				table.insert(NPCService._alive, npc)
				task.spawn(function()
					local hum = npc:FindFirstChildOfClass("Humanoid")
					local root = npc:FindFirstChild("HumanoidRootPart") :: BasePart
					hum.WalkSpeed = cfg.speed
					while npc.Parent and hum.Health > 0 and match.state == "Active" do
						local nearest: Player? = nil
						local best = 1e9
						for _, plr in match.players do
							if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
								local d = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
								if d < best then
									best = d
									nearest = plr
								end
							end
						end
						if nearest and nearest.Character then
							hum:MoveTo(nearest.Character.HumanoidRootPart.Position)
							if best < 7 then
								local vh = nearest.Character:FindFirstChildOfClass("Humanoid")
								if vh and vh.Health > 0 then
									vh:TakeDamage(cfg.damage)
								end
							end
						end
						task.wait(cfg.think)
					end
				end)
			end
			-- wait until wave cleared or timeout
			local t0 = os.clock()
			while os.clock() - t0 < 40 do
				local live = 0
				for _, n in NPCService._alive do
					local h = n:FindFirstChildOfClass("Humanoid")
					if n.Parent and h and h.Health > 0 then
						live += 1
					end
				end
				if live == 0 then
					break
				end
				task.wait(0.5)
			end
			if wave >= 5 then
				for _, p in match.players do
					if p.Parent then
						p:SetAttribute("SurvivalWave", wave)
					end
				end
			end
		end
	end)
end

function NPCService.init()
	-- training dummy motion
	task.spawn(function()
		while true do
			task.wait(1)
			local world = workspace:FindFirstChild("BattleWorld")
			if not world then
				continue
			end
			local grounds = world:FindFirstChild("TrainingGrounds")
			if not grounds then
				continue
			end
			for _, d in grounds:GetChildren() do
				if d:IsA("BasePart") and d:GetAttribute("DummyType") == "Moving" then
					d.CFrame = d.CFrame * CFrame.new(math.sin(os.clock()) * 0.4, 0, 0)
				end
			end
		end
	end)
end

return NPCService
