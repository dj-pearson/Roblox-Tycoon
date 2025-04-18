-- ResetButtonHandler.lua
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create the remote event
local resetEvent = Instance.new("RemoteEvent")
resetEvent.Name = "SimpleResetEvent"
resetEvent.Parent = ReplicatedStorage

-- Function to reset player data
local function resetPlayerData(player)
	if not player then return end

	print("Resetting data for " .. player.Name)

	-- Reset tycoon attributes
	local tycoon = player:FindFirstChild("Tycoon")
	if tycoon then
		tycoon:SetAttribute("AccruedDues", 0)
		tycoon:SetAttribute("EquipmentCount", 0)
		tycoon:SetAttribute("GymTier", 1)
		tycoon:SetAttribute("GymLevel", 1)

		-- Reset other attributes
		local customAttrs = {
			"RebirthCount", "Cleanliness", "Morale", 
			"SpecMembershipBoost", "SpecDuesBoost", "TycoonStarted",
			"LevelProgress", "MembershipCount", "VIPMembershipCount",
			"HourlyRevenue", "Idle", "IdleNotified"
		}

		for _, attrName in ipairs(customAttrs) do
			tycoon:SetAttribute(attrName, nil)
		end

		-- Clear tycoon objects if value exists
		if tycoon.Value then
			-- Clear NPCs
			local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
			if npcsFolder then
				for _, npc in pairs(npcsFolder:GetChildren()) do
					npc:Destroy()
				end
			end

			-- Clear gym parts except platform
			for _, child in pairs(tycoon.Value:GetChildren()) do
				if child.Name ~= "Platform" and child.Name ~= "NPCs" then
					child:Destroy()
				end
			end

			-- Ensure NPCs folder exists
			if not npcsFolder then
				npcsFolder = Instance.new("Folder")
				npcsFolder.Name = "NPCs"
				npcsFolder.Parent = tycoon.Value
			end
		end
	end

	-- Reset leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Cash") then
		leaderstats.Cash.Value = 1000 -- Default starting cash
	end

	-- Clear milestone completions
	for _, attrName in pairs(player:GetAttributes()) do
		if string.find(attrName, "Milestone_") then
			player:SetAttribute(attrName, nil)
		end
	end

	-- Notify player
	local message = Instance.new("Message")
	message.Text = "Your data has been reset!"
	message.Parent = player
	game:GetService("Debris"):AddItem(message, 5)

	-- Kick player to force a refresh
	task.wait(3)
	player:Kick("Data has been reset. Please rejoin the game.")
end

-- Connect to event
resetEvent.OnServerEvent:Connect(function(player)
	resetPlayerData(player)
end)

print("Reset Button Handler initialized")