--!strict

local Remotes = {}

Remotes.FolderName = "BattleLegendsRemotes"

Remotes.Names = {
	CombatAction = "CombatAction",
	CombatFx = "CombatFx",
	SelectFighter = "SelectFighter",
	QueueMatch = "QueueMatch",
	LeaveQueue = "LeaveQueue",
	MatchState = "MatchState",
	PlayerState = "PlayerState",
	HudPulse = "HudPulse",
	UiNotify = "UiNotify",
	ShopBuy = "ShopBuy",
	ClaimDaily = "ClaimDaily",
	SetSettings = "SetSettings",
	SkipTutorial = "SkipTutorial",
	TrainingCommand = "TrainingCommand",
}

function Remotes.getFolder(): Folder?
	local rs = game:GetService("ReplicatedStorage")
	return rs:FindFirstChild(Remotes.FolderName) :: Folder?
end

function Remotes.waitFolder(): Folder
	local rs = game:GetService("ReplicatedStorage")
	return rs:WaitForChild(Remotes.FolderName, 30) :: Folder
end

function Remotes.get(name: string): RemoteEvent
	local folder = Remotes.waitFolder()
	return folder:WaitForChild(name) :: RemoteEvent
end

function Remotes.createAll()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild(Remotes.FolderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = Remotes.FolderName
		folder.Parent = rs
	end
	for _, name in Remotes.Names do
		if not folder:FindFirstChild(name) then
			local ev = Instance.new("RemoteEvent")
			ev.Name = name
			ev.Parent = folder
		end
	end
	return folder
end

return Remotes
