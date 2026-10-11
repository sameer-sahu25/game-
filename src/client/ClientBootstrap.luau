--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")

local Remotes = require(game.ReplicatedStorage:WaitForChild("BattleLegends"):WaitForChild("Remotes"))
local GameConfig = require(game.ReplicatedStorage.BattleLegends.GameConfig)
local Fighters = require(game.ReplicatedStorage.BattleLegends.Fighters)
local Abilities = require(game.ReplicatedStorage.BattleLegends.Abilities)
local ShopCatalog = require(game.ReplicatedStorage.BattleLegends.ShopCatalog)
local Achievements = require(game.ReplicatedStorage.BattleLegends.Achievements)
local Schema = require(game.ReplicatedStorage.BattleLegends.Schema)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local profile: any = Schema.default()
local hud: any = {}
local matchPayload: any = nil
local cameraShake = true
local reducedVfx = false
local musicVolume = 0.6
local sfxVolume = 0.8
local camSens = 1
local blocking = false
local menuOpen = true
local currentPage = "Play"

local NAVY = Color3.fromRGB(12, 16, 28)
local CYAN = Color3.fromRGB(80, 200, 255)
local GOLD = Color3.fromRGB(232, 190, 80)
local PURPLE = Color3.fromRGB(160, 90, 255)

local function lookVector(): Vector3
	local cam = workspace.CurrentCamera
	if cam then
		local v = cam.CFrame.LookVector
		return Vector3.new(v.X, 0, v.Z).Unit
	end
	return Vector3.new(0, 0, -1)
end

local function sendAction(kind: string)
	Remotes.get("CombatAction"):FireServer({ kind = kind, look = lookVector() })
end

local function pulse(parent: Instance, color: Color3, size: number, life: number)
	if reducedVfx then
		return
	end
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = Vector3.new(1, 1, 1)
	p.CFrame = if parent:IsA("BasePart") then parent.CFrame else CFrame.new((parent :: any).Position)
	p.Parent = workspace
	TweenService:Create(p, TweenInfo.new(life), { Size = Vector3.new(size, size, size), Transparency = 1 }):Play()
	task.delay(life, function()
		p:Destroy()
	end)
end

-- UI -----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "BattleLegendsUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function mk(className: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(className)
	for k, v in props do
		(o :: any)[k] = v
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function button(parent: Instance, text: string, pos: UDim2, size: UDim2, cb: () -> (), color: Color3?): TextButton
	local b = mk("TextButton", {
		Text = text,
		Position = pos,
		Size = size,
		BackgroundColor3 = color or Color3.fromRGB(28, 48, 90),
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		AutoButtonColor = true,
	}, parent)
	mk("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
	b.MouseButton1Click:Connect(cb)
	return b
end

-- HUD
local hudRoot = mk("Frame", {
	Name = "HUD",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Visible = false,
}, gui)

local healthBar = mk("Frame", { BackgroundColor3 = Color3.fromRGB(20, 20, 28), Position = UDim2.new(0.03, 0, 0.06, 0), Size = UDim2.new(0.28, 0, 0.035, 0) }, hudRoot)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, healthBar)
local healthFill = mk("Frame", { BackgroundColor3 = Color3.fromRGB(80, 220, 120), Size = UDim2.fromScale(1, 1) }, healthBar)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, healthFill)
local energyBar = mk("Frame", { BackgroundColor3 = Color3.fromRGB(20, 20, 28), Position = UDim2.new(0.03, 0, 0.1, 0), Size = UDim2.new(0.28, 0, 0.025, 0) }, hudRoot)
local energyFill = mk("Frame", { BackgroundColor3 = CYAN, Size = UDim2.fromScale(1, 1) }, energyBar)
local ultBar = mk("Frame", { BackgroundColor3 = Color3.fromRGB(20, 20, 28), Position = UDim2.new(0.03, 0, 0.13, 0), Size = UDim2.new(0.28, 0, 0.025, 0) }, hudRoot)
local ultFill = mk("Frame", { BackgroundColor3 = PURPLE, Size = UDim2.fromScale(0, 1) }, ultBar)
local nameLabel = mk("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.03, 0, 0.02, 0),
	Size = UDim2.new(0.4, 0, 0.035, 0),
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.new(1, 1, 1),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextScaled = true,
	Text = "Shadow Striker  Lv.1",
}, hudRoot)
local matchLabel = mk("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.35, 0, 0.02, 0),
	Size = UDim2.new(0.3, 0, 0.05, 0),
	Font = Enum.Font.GothamBlack,
	TextColor3 = CYAN,
	TextScaled = true,
	Text = "",
}, hudRoot)
local notifyLabel = mk("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.2, 0, 0.18, 0),
	Size = UDim2.new(0.6, 0, 0.05, 0),
	Font = Enum.Font.Gotham,
	TextColor3 = GOLD,
	TextScaled = true,
	Text = "",
}, hudRoot)

-- Mobile cluster
local mobile = mk("Frame", {
	Name = "Mobile",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Visible = UserInputService.TouchEnabled,
}, hudRoot)
button(mobile, "PUNCH", UDim2.new(0.78, 0, 0.72, 0), UDim2.new(0.16, 0, 0.1, 0), function()
	sendAction("Light")
end)
button(mobile, "HEAVY", UDim2.new(0.78, 0, 0.58, 0), UDim2.new(0.16, 0, 0.1, 0), function()
	sendAction("Heavy")
end, Color3.fromRGB(140, 50, 40))
button(mobile, "SPEC", UDim2.new(0.6, 0, 0.72, 0), UDim2.new(0.14, 0, 0.09, 0), function()
	sendAction("Special")
end, Color3.fromRGB(40, 80, 160))
button(mobile, "ULT", UDim2.new(0.6, 0, 0.58, 0), UDim2.new(0.14, 0, 0.09, 0), function()
	sendAction("Ultimate")
end, Color3.fromRGB(90, 40, 140))
button(mobile, "DODGE", UDim2.new(0.05, 0, 0.72, 0), UDim2.new(0.14, 0, 0.09, 0), function()
	sendAction("Dodge")
end, Color3.fromRGB(40, 90, 70))
local blockBtn = button(mobile, "BLOCK", UDim2.new(0.05, 0, 0.58, 0), UDim2.new(0.14, 0, 0.09, 0), function() end, Color3.fromRGB(70, 70, 90))
blockBtn.MouseButton1Down:Connect(function()
	blocking = true
	sendAction("BlockStart")
end)
blockBtn.MouseButton1Up:Connect(function()
	blocking = false
	sendAction("BlockEnd")
end)

-- Main menu
local menu = mk("Frame", { Name = "Menu", BackgroundColor3 = NAVY, Size = UDim2.fromScale(1, 1) }, gui)
mk("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(8, 10, 22), Color3.fromRGB(20, 28, 60)) }, menu)
local logo = mk("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.08, 0, 0.06, 0),
	Size = UDim2.new(0.5, 0, 0.1, 0),
	Font = Enum.Font.GothamBlack,
	Text = "BATTLE LEGENDS",
	TextColor3 = CYAN,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
}, menu)
mk("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.08, 0, 0.15, 0),
	Size = UDim2.new(0.4, 0, 0.04, 0),
	Font = Enum.Font.Gotham,
	Text = GameConfig.Tagline,
	TextColor3 = Color3.fromRGB(180, 190, 220),
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
}, menu)

local content = mk("Frame", {
	Name = "Content",
	BackgroundColor3 = Color3.fromRGB(16, 22, 40),
	Position = UDim2.new(0.28, 0, 0.22, 0),
	Size = UDim2.new(0.66, 0, 0.7, 0),
}, menu)
mk("UICorner", { CornerRadius = UDim.new(0, 12) }, content)
local contentText = mk("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.04, 0, 0.04, 0),
	Size = UDim2.new(0.92, 0, 0.72, 0),
	Font = Enum.Font.Gotham,
	TextColor3 = Color3.fromRGB(220, 230, 255),
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextSize = 18,
	Text = "",
}, content)

local function setContent(text: string)
	contentText.Text = text
end

local navY = 0.24
local function nav(label: string, page: string, extra: (() -> ())?)
	button(menu, label, UDim2.new(0.06, 0, navY, 0), UDim2.new(0.18, 0, 0.07, 0), function()
		currentPage = page
		if extra then
			extra()
		end
	end)
	navY += 0.08
end

local function fighterListText(): string
	local lines = { "Select a fighter (starters are free). Locked fighters can be previewed." }
	for id, f in Fighters do
		local owned = table.find(profile.unlockedFighters, id) ~= nil or f.starter
		table.insert(lines, string.format("%s %s — %s | %s", if owned then "[OWNED]" else "[LOCKED]", f.name, f.role, f.description))
	end
	return table.concat(lines, "\n")
end

nav("PLAY", "Play", function()
	setContent("Free-for-All is the MVP loop. Press QUEUE FFA to enter The Eternal Arena.\n\nPC: LMB light, RMB heavy, Q special, E ultimate, F block, Left Shift dodge, Left Ctrl sprint.\nMobile: on-screen combat buttons.\n\nWalk onto lobby pads (Shop, Training, Matchmaking) or use this menu.")
end)
button(content, "QUEUE FFA", UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.28, 0, 0.12, 0), function()
	menuOpen = false
	menu.Visible = false
	hudRoot.Visible = true
	Remotes.get("QueueMatch"):FireServer("FFA", "EternalArena")
end, Color3.fromRGB(180, 40, 50))
button(content, "1v1", UDim2.new(0.36, 0, 0.8, 0), UDim2.new(0.18, 0, 0.12, 0), function()
	menuOpen = false
	menu.Visible = false
	hudRoot.Visible = true
	Remotes.get("QueueMatch"):FireServer("Duel", "EternalArena")
end)
button(content, "2v2", UDim2.new(0.56, 0, 0.8, 0), UDim2.new(0.18, 0, 0.12, 0), function()
	menuOpen = false
	menu.Visible = false
	hudRoot.Visible = true
	Remotes.get("QueueMatch"):FireServer("Team2v2", "EternalArena")
end)
button(content, "SURVIVAL", UDim2.new(0.76, 0, 0.8, 0), UDim2.new(0.2, 0, 0.12, 0), function()
	menuOpen = false
	menu.Visible = false
	hudRoot.Visible = true
	Remotes.get("QueueMatch"):FireServer("Survival", "EternalArena")
end)

nav("FIGHTERS", "Fighters", function()
	setContent(fighterListText() .. "\n\nUse the buttons below to equip starters. Unlock others in the shop.")
end)
button(content, "EQUIP STRIKER", UDim2.new(0.05, 0, 0.78, 0), UDim2.new(0.3, 0, 0.1, 0), function()
	Remotes.get("SelectFighter"):FireServer("ShadowStriker")
end)
button(content, "EQUIP FROST", UDim2.new(0.38, 0, 0.78, 0), UDim2.new(0.3, 0, 0.1, 0), function()
	Remotes.get("SelectFighter"):FireServer("FrostReaper")
end)

nav("SHOP", "Shop", function()
	local lines = { "Battle Coins: " .. tostring(profile.coins), "Cosmetic items never change combat stats." }
	for _, it in ShopCatalog do
		table.insert(lines, string.format("%s — %d coins — %s", it.name, it.cost, it.description))
	end
	setContent(table.concat(lines, "\n"))
end)
button(content, "BUY RONIN (400)", UDim2.new(0.05, 0, 0.82, 0), UDim2.new(0.4, 0, 0.1, 0), function()
	Remotes.get("ShopBuy"):FireServer("unlock_ThunderRonin")
end, GOLD)

nav("PROFILE", "Profile", function()
	setContent(string.format(
		"Level %d  XP %d/%d\nCoins %d\nKills %d  Deaths %d\nWins %d  Losses %d  Matches %d\nStreak %d\nEquipped: %s",
		profile.level,
		profile.xp,
		Schema.xpForLevel(profile.level),
		profile.coins,
		profile.kills,
		profile.deaths,
		profile.wins,
		profile.losses,
		profile.matches,
		profile.winStreak,
		profile.equippedFighter
	))
end)

nav("SETTINGS", "Settings", function()
	setContent("M = toggle menu  |  Settings are saved on the server.\nUse the toggles below.")
end)
button(content, "SHAKE ON/OFF", UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.28, 0, 0.12, 0), function()
	cameraShake = not cameraShake
	Remotes.get("SetSettings"):FireServer({ cameraShake = cameraShake })
end)
button(content, "REDUCE VFX", UDim2.new(0.36, 0, 0.8, 0), UDim2.new(0.28, 0, 0.12, 0), function()
	reducedVfx = not reducedVfx
	Remotes.get("SetSettings"):FireServer({ reducedVfx = reducedVfx })
end)
button(content, "SKIP TUTORIAL", UDim2.new(0.66, 0, 0.8, 0), UDim2.new(0.28, 0, 0.12, 0), function()
	Remotes.get("SkipTutorial"):FireServer()
end)

nav("TRAINING", "Training", function()
	setContent("Training dummies sit on the cyan pad in the lobby. Reset dummies from here. Combat against dummies is always server-validated.")
end)
button(content, "RESET DUMMIES", UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.35, 0, 0.12, 0), function()
	Remotes.get("TrainingCommand"):FireServer("ResetDummies")
end)
button(content, "RESET CD", UDim2.new(0.44, 0, 0.8, 0), UDim2.new(0.28, 0, 0.12, 0), function()
	Remotes.get("TrainingCommand"):FireServer("ResetCooldowns")
end)

-- Tutorial overlay
local tutorial = mk("TextLabel", {
	BackgroundColor3 = Color3.fromRGB(10, 12, 24),
	BackgroundTransparency = 0.2,
	Position = UDim2.new(0.2, 0, 0.78, 0),
	Size = UDim2.new(0.6, 0, 0.16, 0),
	Font = Enum.Font.Gotham,
	TextColor3 = Color3.new(1, 1, 1),
	TextWrapped = true,
	TextSize = 16,
	Text = "Move with WASD / thumbstick. Open PLAY to queue FFA. Light attack to hit dummies in Training. Press M to toggle this menu.",
	Visible = true,
}, gui)
mk("UICorner", { CornerRadius = UDim.new(0, 10) }, tutorial)

setContent("Welcome, fighter. Queue Free-for-All to start the MVP match loop. Two starter characters are unlocked.")

-- Input
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.M then
		menuOpen = not menuOpen
		menu.Visible = menuOpen
		hudRoot.Visible = not menuOpen
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		sendAction("Light")
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		sendAction("Heavy")
	elseif input.KeyCode == Enum.KeyCode.Q then
		sendAction("Special")
	elseif input.KeyCode == Enum.KeyCode.E then
		sendAction("Ultimate")
	elseif input.KeyCode == Enum.KeyCode.F then
		blocking = true
		sendAction("BlockStart")
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		sendAction("Dodge")
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		sendAction("SprintStart")
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F then
		blocking = false
		sendAction("BlockEnd")
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		sendAction("SprintEnd")
	end
end)

-- Camera
local cam = workspace.CurrentCamera
local yaw = 0
local pitch = 0.2
UserInputService.MouseIconEnabled = true
RunService.RenderStepped:Connect(function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp or menuOpen then
		return
	end
	cam.CameraType = Enum.CameraType.Scriptable
	local delta = UserInputService:GetMouseDelta()
	yaw -= delta.X * 0.004 * camSens
	pitch = math.clamp(pitch - delta.Y * 0.004 * camSens, -0.8, 0.8)
	local offset = CFrame.new(hrp.Position)
		* CFrame.Angles(0, yaw, 0)
		* CFrame.Angles(pitch, 0, 0)
		* CFrame.new(0, 2.4, 10)
	cam.CFrame = CFrame.new(offset.Position, hrp.Position + Vector3.new(0, 1.6, 0))
end)

Remotes.get("PlayerState").OnClientEvent:Connect(function(data)
	if typeof(data) == "table" then
		profile = data
		if data.settings then
			cameraShake = data.settings.cameraShake ~= false
			reducedVfx = data.settings.reducedVfx == true
			musicVolume = data.settings.musicVolume or 0.6
			sfxVolume = data.settings.sfxVolume or 0.8
			camSens = data.settings.cameraSensitivity or 1
			tutorial.Visible = data.settings.tutorialComplete ~= true
		end
		local f = Fighters[profile.equippedFighter]
		nameLabel.Text = string.format("%s  Lv.%d   Coins %d", if f then f.name else "Fighter", profile.level, profile.coins)
	end
end)

Remotes.get("HudPulse").OnClientEvent:Connect(function(snap)
	if typeof(snap) ~= "table" then
		return
	end
	hud = snap
	local maxh = snap.maxHealth or 100
	healthFill.Size = UDim2.fromScale(math.clamp((snap.health or 0) / maxh, 0, 1), 1)
	energyFill.Size = UDim2.fromScale(math.clamp((snap.energy or 0) / GameConfig.BaseEnergy, 0, 1), 1)
	ultFill.Size = UDim2.fromScale(math.clamp((snap.ultimate or 0) / GameConfig.UltimateMax, 0, 1), 1)
end)

Remotes.get("MatchState").OnClientEvent:Connect(function(payload)
	matchPayload = payload
	menuOpen = false
	menu.Visible = false
	hudRoot.Visible = true
	if typeof(payload) == "table" then
		local remain = payload.remaining or 0
		matchLabel.Text = string.format("%s | %s | %ds", payload.mode or "", payload.state or "", remain)
		if payload.state == "Results" then
			notifyLabel.Text = "Match complete — returning to lobby"
			menuOpen = true
			menu.Visible = true
		end
	end
end)

Remotes.get("UiNotify").OnClientEvent:Connect(function(msg)
	if typeof(msg) == "table" and typeof(msg.text) == "string" then
		notifyLabel.Text = msg.text
		task.delay(3, function()
			if notifyLabel.Text == msg.text then
				notifyLabel.Text = ""
			end
		end)
	end
end)

Remotes.get("CombatFx").OnClientEvent:Connect(function(kind, payload)
	if reducedVfx then
		return
	end
	if typeof(payload) ~= "table" or typeof(payload.pos) ~= "Vector3" then
		if kind == "Hit" and payload and payload.pos then
			-- continue
		else
			if typeof(payload) == "table" and payload.pos then
				-- ok
			else
				return
			end
		end
	end
	local pos = payload.pos
	if typeof(pos) ~= "Vector3" then
		return
	end
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = CFrame.new(pos)
	part.Transparency = 1
	part.Parent = workspace
	local color = CYAN
	if kind == "Heavy" then
		color = Color3.fromRGB(255, 140, 60)
	elseif kind == "Ability" then
		color = PURPLE
	elseif kind == "Hit" then
		color = Color3.fromRGB(255, 230, 120)
		if payload.damage then
			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.fromOffset(80, 40)
			bb.StudsOffset = Vector3.new(0, 3, 0)
			bb.Parent = part
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Size = UDim2.fromScale(1, 1)
			t.Font = Enum.Font.GothamBlack
			t.TextScaled = true
			t.TextColor3 = GOLD
			t.Text = tostring(payload.damage)
			t.Parent = bb
		end
	end
	pulse(part, color, if kind == "Ability" then 18 else 8, 0.35)
	if cameraShake and (kind == "Heavy" or kind == "Ability") and workspace.CurrentCamera then
		local c = workspace.CurrentCamera
		local orig = c.CFrame
		c.CFrame = orig * CFrame.new(0.15, 0.1, 0)
		task.delay(0.05, function()
			-- restored next frame by camera loop
		end)
	end
	task.delay(0.6, function()
		part:Destroy()
	end)
end)

-- Ambient music placeholder (no fake asset ids)
local music = Instance.new("Sound")
music.Name = "LobbyTone"
music.Looped = true
music.Volume = 0
music.Parent = SoundService
-- Intentionally no SoundId until a licensed asset is uploaded.

print("[BattleLegends] Client ready")
