-- RebirthSystem.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Rebirth settings
local rebirthCost = 100000 -- Cost to rebirth
local rebirthBonus = 0.1 -- Bonus to membership fees after rebirth

-- Function to handle rebirth
local function rebirth(player)
	local tycoon = player.Tycoon
	if tycoon.Cash.Value >= rebirthCost then
		-- Reset progress
		tycoon.Cash.Value = 0
		tycoon.GymLevel.Value = 0

		-- Apply rebirth bonuses
		tycoon.MembershipFeeMultiplier.Value = tycoon.MembershipFeeMultiplier.Value + rebirthBonus

		-- Unlock new franchise locations or improve existing ones
		-- Example: Unlock a new gym location
		local newGymLocation = Instance.new("Model")
		newGymLocation.Name = "NewGymLocation"
		newGymLocation.Parent = Workspace

		print("Rebirth successful!")
	else
		print("Insufficient funds for rebirth.")
	end
end

-- Example usage
local rebirthButton = ReplicatedStorage:FindFirstChild("RebirthButton")
if rebirthButton then
	rebirthButton.Clicked:Connect(function(player)
		rebirth(player)
	end)
end
