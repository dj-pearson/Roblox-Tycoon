-- PlayerCharacterCheck.lua
-- This script fixes the issue where a player's character is mistakenly identified as their tycoon
-- Place this in ServerScriptService

local Players = game:GetService("Players")


-- Function to check and fix player tycoon values
local function checkPlayerTycoon(player)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return end

	-- Check if the tycoon value is incorrectly set to the player character
	if tycoon.Value == player.Character then
		print("?? WARNING: " .. player.Name .. "'s Tycoon is incorrectly set to their character!")

		-- Clear the incorrect value
		tycoon.Value = nil

		-- The TycoonCreator script will handle creating a proper tycoon
		print("?? Cleared incorrect Tycoon value for " .. player.Name)
	end
end

-- Check existing players
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		checkPlayerTycoon(player)

		-- Also check whenever their character changes
		player.CharacterAdded:Connect(function(character)
			task.delay(1, function() -- Small delay to let other scripts run
				checkPlayerTycoon(player)
			end)
		end)
	end)
end

-- Connect to PlayerAdded event
Players.PlayerAdded:Connect(function(player)
	-- Check when player joins
	task.delay(2, function()
		checkPlayerTycoon(player)
	end)

	-- Check when character is added
	player.CharacterAdded:Connect(function(character)
		task.delay(1, function()
			checkPlayerTycoon(player)
		end)
	end)
end)

print("?? PlayerCharacterCheck initialized - will prevent characters from being used as tycoons")