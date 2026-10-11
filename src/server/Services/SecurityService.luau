--!strict

local GameConfig = require(game.ReplicatedStorage.BattleLegends.GameConfig)

local SecurityService = {}
SecurityService._lastPos = {} :: { [number]: Vector3 }
SecurityService._strikes = {} :: { [number]: number }

function SecurityService.watch(player: Player)
	task.spawn(function()
		while player.Parent do
			task.wait(0.5)
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				local last = SecurityService._lastPos[player.UserId]
				if last then
					local delta = (hrp.Position - last).Magnitude
					if delta > GameConfig.MaxHorizontalSpeed then
						SecurityService._strikes[player.UserId] = (SecurityService._strikes[player.UserId] or 0) + 1
						hrp.CFrame = CFrame.new(last)
						if SecurityService._strikes[player.UserId] > 12 then
							player:Kick("Abnormal movement detected")
							return
						end
					end
				end
				SecurityService._lastPos[player.UserId] = hrp.Position
			end
		end
		SecurityService._lastPos[player.UserId] = nil
		SecurityService._strikes[player.UserId] = nil
	end)
end

return SecurityService
