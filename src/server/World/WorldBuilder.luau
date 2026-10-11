--!strict
--[[
	Procedural lobby + five arenas. Built once on server start.
]]

local GameConfig = require(game:GetService("ReplicatedStorage").BattleLegends.GameConfig)
local PartFactory = require(script.Parent.PartFactory)

local WorldBuilder = {}

local function folder(name: string, parent: Instance): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function ring(parent: Instance, origin: Vector3, radius: number, y: number, height: number, thickness: number, color: Color3, material: Enum.Material, segments: number)
	for i = 1, segments do
		local a = (i / segments) * math.pi * 2
		local pos = origin + Vector3.new(math.cos(a) * radius, y, math.sin(a) * radius)
		local look = CFrame.lookAt(pos, Vector3.new(origin.X, y + origin.Y, origin.Z))
		PartFactory.part({
			name = "RingSeg",
			size = Vector3.new(thickness, height, (2 * math.pi * radius) / segments + 0.4),
			cframe = look,
			color = color,
			material = material,
			parent = parent,
		})
	end
end

local function tower(parent: Instance, pos: Vector3, height: number, color: Color3, accent: Color3)
	PartFactory.part({
		name = "Tower",
		size = Vector3.new(10, height, 10),
		cframe = CFrame.new(pos + Vector3.new(0, height / 2, 0)),
		color = color,
		material = Enum.Material.Slate,
		parent = parent,
	})
	PartFactory.part({
		name = "TowerCap",
		size = Vector3.new(14, 3, 14),
		cframe = CFrame.new(pos + Vector3.new(0, height + 1.5, 0)),
		color = accent,
		material = Enum.Material.Neon,
		parent = parent,
		light = accent,
		lightRange = 40,
	})
end

local function island(parent: Instance, pos: Vector3, size: Vector3, color: Color3)
	PartFactory.part({
		name = "Island",
		size = size,
		cframe = CFrame.new(pos),
		color = color,
		material = Enum.Material.Basalt,
		parent = parent,
	})
end

function WorldBuilder.buildLobby(root: Folder)
	local lobby = folder("Lobby", root)
	local origin = Vector3.new(0, 0, 0)

	PartFactory.part({
		name = "HubFloor",
		size = Vector3.new(220, 4, 220),
		cframe = CFrame.new(origin + Vector3.new(0, 0, 0)),
		color = Color3.fromRGB(28, 34, 52),
		material = Enum.Material.SmoothPlastic,
		parent = lobby,
		shape = Enum.PartType.Cylinder,
	})
	-- Cylinder along X in Roblox; rotate for vertical disc
	local floor = lobby:FindFirstChild("HubFloor") :: Part
	floor.Size = Vector3.new(4, 220, 220)
	floor.CFrame = CFrame.new(origin) * CFrame.Angles(0, 0, math.rad(90))

	ring(lobby, origin, 108, 2.2, 8, 4, Color3.fromRGB(40, 80, 160), Enum.Material.Metal, 28)
	ring(lobby, origin, 70, 2.5, 1.2, 6, Color3.fromRGB(70, 140, 255), Enum.Material.Neon, 24)

	PartFactory.part({
		name = "Monument",
		size = Vector3.new(12, 28, 12),
		cframe = CFrame.new(0, 16, 0),
		color = Color3.fromRGB(20, 24, 40),
		material = Enum.Material.Metal,
		parent = lobby,
	})
	PartFactory.part({
		name = "MonumentCore",
		size = Vector3.new(8, 18, 8),
		cframe = CFrame.new(0, 22, 0),
		color = Color3.fromRGB(90, 60, 200),
		material = Enum.Material.Neon,
		parent = lobby,
		light = Color3.fromRGB(120, 90, 255),
		lightRange = 48,
	})

	local logo = Instance.new("BillboardGui")
	logo.Name = "TitleBillboard"
	logo.Size = UDim2.fromOffset(520, 90)
	logo.StudsOffset = Vector3.new(0, 22, 0)
	logo.AlwaysOnTop = true
	logo.Parent = lobby.Monument
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 1)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(180, 220, 255)
	title.Text = "BATTLE LEGENDS"
	title.Parent = logo

	local zones = {
		{ name = "CharacterSelect", pos = Vector3.new(40, 3, 20), color = Color3.fromRGB(80, 160, 255) },
		{ name = "Shop", pos = Vector3.new(-40, 3, 20), color = Color3.fromRGB(255, 200, 80) },
		{ name = "Leaderboard", pos = Vector3.new(40, 3, -30), color = Color3.fromRGB(180, 120, 255) },
		{ name = "DailyRewards", pos = Vector3.new(-40, 3, -30), color = Color3.fromRGB(80, 220, 140) },
		{ name = "Matchmaking", pos = Vector3.new(0, 3, 55), color = Color3.fromRGB(255, 90, 90) },
		{ name = "Training", pos = Vector3.new(0, 3, -55), color = Color3.fromRGB(90, 255, 220) },
	}
	for _, z in zones do
		local p = PartFactory.part({
			name = z.name,
			size = Vector3.new(18, 2, 18),
			cframe = CFrame.new(z.pos),
			color = z.color,
			material = Enum.Material.Neon,
			parent = lobby,
			light = z.color,
		})
		p:SetAttribute("LobbyZone", z.name)
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(200, 36)
		bb.StudsOffset = Vector3.new(0, 6, 0)
		bb.Parent = p
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Font = Enum.Font.GothamBold
		t.TextScaled = true
		t.TextColor3 = Color3.new(1, 1, 1)
		t.Text = z.name
		t.Parent = bb
	end

	local portal = PartFactory.part({
		name = "ArenaPortal",
		size = Vector3.new(16, 22, 3),
		cframe = CFrame.new(0, 13, 72),
		color = Color3.fromRGB(70, 40, 180),
		material = Enum.Material.ForceField,
		parent = lobby,
		canCollide = false,
		light = Color3.fromRGB(120, 80, 255),
		lightRange = 32,
	})
	portal:SetAttribute("LobbyZone", "Matchmaking")

	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		PartFactory.part({
			name = "Crystal",
			size = Vector3.new(3, 10, 3),
			cframe = CFrame.new(math.cos(a) * 88, 8, math.sin(a) * 88),
			color = if i % 2 == 0 then Color3.fromRGB(70, 140, 255) else Color3.fromRGB(150, 80, 255),
			material = Enum.Material.Neon,
			parent = lobby,
			light = Color3.fromRGB(120, 140, 255),
		})
	end

	island(lobby, Vector3.new(70, 18, 70), Vector3.new(22, 4, 16), Color3.fromRGB(40, 48, 70))
	island(lobby, Vector3.new(-75, 22, 60), Vector3.new(18, 4, 18), Color3.fromRGB(36, 42, 64))
	island(lobby, Vector3.new(60, 26, -80), Vector3.new(20, 3, 14), Color3.fromRGB(32, 38, 58))

	PartFactory.spawnPad(lobby, CFrame.new(0, 3.5, -12), Color3.fromRGB(90, 180, 255), "LobbySpawn")
	for i = 1, 6 do
		local a = (i / 6) * math.pi * 2
		PartFactory.spawnPad(
			lobby,
			CFrame.new(math.cos(a) * 24, 3.5, math.sin(a) * 24 - 8),
			Color3.fromRGB(80, 120, 200),
			"LobbySpawn" .. i
		)
	end

	return lobby
end

local function buildEternal(parent: Folder, origin: Vector3)
	local map = folder("EternalArena", parent)
	map:SetAttribute("ArenaId", "EternalArena")
	PartFactory.part({
		name = "ArenaFloor",
		size = Vector3.new(6, 160, 160),
		cframe = CFrame.new(origin) * CFrame.Angles(0, 0, math.rad(90)),
		color = Color3.fromRGB(32, 38, 55),
		material = Enum.Material.Concrete,
		parent = map,
	})
	ring(map, origin, 78, 3, 10, 5, Color3.fromRGB(40, 90, 180), Enum.Material.Neon, 32)
	ring(map, origin, 50, 2.2, 1, 8, Color3.fromRGB(90, 70, 200), Enum.Material.Neon, 20)
	for i = 1, 4 do
		local a = (i / 4) * math.pi * 2 + 0.4
		tower(map, origin + Vector3.new(math.cos(a) * 70, 0, math.sin(a) * 70), 42, Color3.fromRGB(24, 28, 40), Color3.fromRGB(70, 140, 255))
	end
	for i = 1, 4 do
		local a = (i / 4) * math.pi * 2
		island(map, origin + Vector3.new(math.cos(a) * 40, 9, math.sin(a) * 40), Vector3.new(16, 2, 16), Color3.fromRGB(40, 46, 62))
	end
	PartFactory.part({
		name = "CoverA",
		size = Vector3.new(10, 8, 3),
		cframe = CFrame.new(origin + Vector3.new(18, 5, 8)),
		color = Color3.fromRGB(50, 56, 72),
		material = Enum.Material.Metal,
		parent = map,
	})
	PartFactory.part({
		name = "CoverB",
		size = Vector3.new(3, 8, 12),
		cframe = CFrame.new(origin + Vector3.new(-16, 5, -10)),
		color = Color3.fromRGB(50, 56, 72),
		material = Enum.Material.Metal,
		parent = map,
	})
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		PartFactory.spawnPad(
			map,
			CFrame.new(origin + Vector3.new(math.cos(a) * 58, 3.2, math.sin(a) * 58)),
			Color3.fromRGB(80, 170, 255),
			"Spawn" .. i
		)
	end
	return map
end

local function buildDragonfall(parent: Folder, origin: Vector3)
	local map = folder("DragonfallTemple", parent)
	map:SetAttribute("ArenaId", "DragonfallTemple")
	PartFactory.part({
		name = "TempleFloor",
		size = Vector3.new(140, 5, 140),
		cframe = CFrame.new(origin),
		color = Color3.fromRGB(90, 80, 110),
		material = Enum.Material.Limestone,
		parent = map,
	})
	PartFactory.part({
		name = "Bridge",
		size = Vector3.new(18, 3, 70),
		cframe = CFrame.new(origin + Vector3.new(0, 8, 0)),
		color = Color3.fromRGB(120, 110, 140),
		material = Enum.Material.Slate,
		parent = map,
	})
	for i = -1, 1, 2 do
		PartFactory.part({
			name = "Crystal",
			size = Vector3.new(8, 22, 8),
			cframe = CFrame.new(origin + Vector3.new(i * 28, 14, 20)),
			color = Color3.fromRGB(90, 70, 220),
			material = Enum.Material.Neon,
			parent = map,
			light = Color3.fromRGB(140, 120, 255),
		})
	end
	island(map, origin + Vector3.new(0, 16, -40), Vector3.new(36, 4, 24), Color3.fromRGB(80, 75, 100))
	for i = 1, 6 do
		local a = (i / 6) * math.pi * 2
		PartFactory.spawnPad(map, CFrame.new(origin + Vector3.new(math.cos(a) * 50, 4, math.sin(a) * 50)), Color3.fromRGB(160, 140, 255), "Spawn" .. i)
	end
	return map
end

local function buildInferno(parent: Folder, origin: Vector3)
	local map = folder("InfernoFortress", parent)
	map:SetAttribute("ArenaId", "InfernoFortress")
	PartFactory.part({
		name = "FortFloor",
		size = Vector3.new(150, 6, 150),
		cframe = CFrame.new(origin),
		color = Color3.fromRGB(50, 28, 22),
		material = Enum.Material.Basalt,
		parent = map,
	})
	PartFactory.part({
		name = "LavaRing",
		size = Vector3.new(4, 170, 170),
		cframe = CFrame.new(origin + Vector3.new(0, -2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		color = Color3.fromRGB(255, 90, 20),
		material = Enum.Material.Neon,
		parent = map,
		canCollide = false,
		light = Color3.fromRGB(255, 80, 20),
		lightRange = 60,
	})
	tower(map, origin + Vector3.new(40, 0, 40), 36, Color3.fromRGB(30, 18, 14), Color3.fromRGB(255, 110, 30))
	tower(map, origin + Vector3.new(-40, 0, 40), 36, Color3.fromRGB(30, 18, 14), Color3.fromRGB(255, 110, 30))
	for i = 1, 6 do
		local a = (i / 6) * math.pi * 2
		PartFactory.spawnPad(map, CFrame.new(origin + Vector3.new(math.cos(a) * 48, 4.5, math.sin(a) * 48)), Color3.fromRGB(255, 120, 40), "Spawn" .. i)
	end
	return map
end

local function buildDojo(parent: Folder, origin: Vector3)
	local map = folder("SkybladeDojo", parent)
	map:SetAttribute("ArenaId", "SkybladeDojo")
	PartFactory.part({
		name = "DojoFloor",
		size = Vector3.new(130, 3, 130),
		cframe = CFrame.new(origin),
		color = Color3.fromRGB(150, 110, 70),
		material = Enum.Material.WoodPlanks,
		parent = map,
	})
	PartFactory.part({
		name = "Ring",
		size = Vector3.new(3, 90, 90),
		cframe = CFrame.new(origin + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		color = Color3.fromRGB(90, 40, 30),
		material = Enum.Material.Wood,
		parent = map,
	})
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		PartFactory.part({
			name = "Blossom",
			size = Vector3.new(10, 1, 10),
			cframe = CFrame.new(origin + Vector3.new(math.cos(a) * 55, 8, math.sin(a) * 55)),
			color = Color3.fromRGB(255, 160, 190),
			material = Enum.Material.SmoothPlastic,
			parent = map,
			canCollide = false,
		})
	end
	for i = 1, 6 do
		local a = (i / 6) * math.pi * 2
		PartFactory.spawnPad(map, CFrame.new(origin + Vector3.new(math.cos(a) * 40, 3, math.sin(a) * 40)), Color3.fromRGB(220, 180, 120), "Spawn" .. i)
	end
	return map
end

local function buildCyber(parent: Folder, origin: Vector3)
	local map = folder("CyberneticCity", parent)
	map:SetAttribute("ArenaId", "CyberneticCity")
	PartFactory.part({
		name = "Roof",
		size = Vector3.new(160, 4, 160),
		cframe = CFrame.new(origin),
		color = Color3.fromRGB(20, 24, 32),
		material = Enum.Material.Metal,
		parent = map,
	})
	for i = 1, 6 do
		local a = (i / 6) * math.pi * 2
		PartFactory.part({
			name = "Tower",
			size = Vector3.new(12, 50, 12),
			cframe = CFrame.new(origin + Vector3.new(math.cos(a) * 70, 27, math.sin(a) * 70)),
			color = Color3.fromRGB(18, 22, 40),
			material = Enum.Material.Metal,
			parent = map,
		})
		PartFactory.part({
			name = "Sign",
			size = Vector3.new(10, 6, 1),
			cframe = CFrame.new(origin + Vector3.new(math.cos(a) * 64, 18, math.sin(a) * 64)),
			color = Color3.fromRGB(0, 220, 255),
			material = Enum.Material.Neon,
			parent = map,
			light = Color3.fromRGB(0, 220, 255),
		})
	end
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		PartFactory.spawnPad(map, CFrame.new(origin + Vector3.new(math.cos(a) * 52, 3.2, math.sin(a) * 52)), Color3.fromRGB(0, 200, 255), "Spawn" .. i)
	end
	return map
end

function WorldBuilder.buildTraining(root: Folder)
	local grounds = folder("TrainingGrounds", root)
	local origin = Vector3.new(0, 0, -55)
	for i = 1, 6 do
		local dummy = PartFactory.part({
			name = "Dummy" .. i,
			size = Vector3.new(4, 8, 3),
			cframe = CFrame.new(origin + Vector3.new((i - 3.5) * 8, 7, -18)),
			color = Color3.fromRGB(200, 200, 210),
			material = Enum.Material.SmoothPlastic,
			parent = grounds,
			canCollide = true,
		})
		dummy.Anchored = true
		dummy:SetAttribute("TrainingDummy", true)
		dummy:SetAttribute("DummyType", ({ "Stationary", "Moving", "Blocking", "Dodging", "Combo", "Damage" })[i])
		local hum = Instance.new("Humanoid")
		hum.MaxHealth = 10000
		hum.Health = 10000
		hum.Parent = dummy
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(140, 28)
		bb.StudsOffset = Vector3.new(0, 6, 0)
		bb.Parent = dummy
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Font = Enum.Font.Gotham
		t.TextScaled = true
		t.TextColor3 = Color3.new(1, 1, 1)
		t.Text = dummy:GetAttribute("DummyType") :: string
		t.Parent = bb
	end
	return grounds
end

function WorldBuilder.build()
	local ws = game:GetService("Workspace")
	if ws:GetAttribute("BattleLegendsWorld") then
		return
	end
	local base = ws:FindFirstChild("Baseplate")
	if base then
		base:Destroy()
	end
	local spawn = ws:FindFirstChildOfClass("SpawnLocation")
	if spawn then
		spawn:Destroy()
	end

	local root = folder("BattleWorld", ws)
	folder("ActiveCharacters", root)
	folder("NPCs", root)
	folder("Effects", root)
	folder("Environment", root)
	local arenas = folder("Arenas", root)

	WorldBuilder.buildLobby(root)
	WorldBuilder.buildTraining(root)
	buildEternal(arenas, GameConfig.ArenaOrigins.EternalArena)
	buildDragonfall(arenas, GameConfig.ArenaOrigins.DragonfallTemple)
	buildInferno(arenas, GameConfig.ArenaOrigins.InfernoFortress)
	buildDojo(arenas, GameConfig.ArenaOrigins.SkybladeDojo)
	buildCyber(arenas, GameConfig.ArenaOrigins.CyberneticCity)

	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "LobbySpawnLocation"
	spawnLoc.Size = Vector3.new(12, 1, 12)
	spawnLoc.CFrame = CFrame.new(0, 4, -12)
	spawnLoc.Anchored = true
	spawnLoc.Neutral = true
	spawnLoc.Duration = 0
	spawnLoc.Transparency = 1
	spawnLoc.CanCollide = false
	spawnLoc.Parent = root

	local lighting = game:GetService("Lighting")
	if not lighting:FindFirstChild("BL_Atmosphere") then
		local at = Instance.new("Atmosphere")
		at.Name = "BL_Atmosphere"
		at.Density = 0.28
		at.Offset = 0.1
		at.Color = Color3.fromRGB(90, 100, 140)
		at.Decay = Color3.fromRGB(40, 50, 80)
		at.Glare = 0.2
		at.Haze = 1.4
		at.Parent = lighting
	end
	if not lighting:FindFirstChild("BL_Bloom") then
		local bloom = Instance.new("BloomEffect")
		bloom.Name = "BL_Bloom"
		bloom.Intensity = 0.35
		bloom.Size = 22
		bloom.Threshold = 0.9
		bloom.Parent = lighting
	end
	if not lighting:FindFirstChild("BL_Color") then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "BL_Color"
		cc.Saturation = 0.12
		cc.Contrast = 0.08
		cc.TintColor = Color3.fromRGB(230, 235, 255)
		cc.Parent = lighting
	end

	ws:SetAttribute("BattleLegendsWorld", true)
end

function WorldBuilder.getArenaFolder(arenaId: string): Folder?
	local arenas = game.Workspace:FindFirstChild("BattleWorld")
		and (game.Workspace.BattleWorld :: Folder):FindFirstChild("Arenas")
	if not arenas then
		return nil
	end
	return arenas:FindFirstChild(arenaId) :: Folder?
end

function WorldBuilder.getSpawnCFrames(arenaId: string): { CFrame }
	local map = WorldBuilder.getArenaFolder(arenaId)
	local result = {}
	if not map then
		return result
	end
	for _, inst in map:GetDescendants() do
		if inst:IsA("BasePart") and inst:GetAttribute("SpawnPad") then
			table.insert(result, inst.CFrame + Vector3.new(0, 4, 0))
		end
	end
	return result
end

return WorldBuilder
