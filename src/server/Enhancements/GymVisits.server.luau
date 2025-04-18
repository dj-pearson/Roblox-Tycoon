-- GymVisits.lua
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")


-- Function to teleport a player to another gym
local function visitGym(player, targetGym)
	local character = player.Character
	if character then
		if targetGym and targetGym:FindFirstChild("FrontDesk") then
			character.HumanoidRootPart.CFrame = targetGym.FrontDesk.CFrame
		else
			-- Fall back to the tycoon's main position
			if targetGym then
				if targetGym.PrimaryPart then
					character.HumanoidRootPart.CFrame = targetGym.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
				else
					-- Find any part to use as reference
					for _, part in pairs(targetGym:GetDescendants()) do
						if part:IsA("BasePart") then
							character.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 5, 0)
							break
						end
					end
				end
			end
		end
	end
end

-- Example usage
local visitButton = Instance.new("Part")
visitButton.Name = "VisitButton"
visitButton.Parent = Workspace

visitButton.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if player then
		-- Logic to determine the target gym
		local targetGym = Workspace:FindFirstChild("OtherPlayerGym")
		visitGym(player, targetGym)
	end
end)
