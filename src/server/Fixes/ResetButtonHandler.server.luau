-- ResetButtonHandler.lua
-- Place in ServerScriptService

-- We only need ReplicatedStorage to store the remote event
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
	for attrName, _ in pairs(player:GetAttributes()) do
		if typeof(attrName) == "string" and string.find(attrName, "Milestone_") then
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
resetEvent.OnServerEvent:Connect(function(player, targetPlayerName)
	-- If admin is resetting another player's data
	if targetPlayerName and typeof(targetPlayerName) == "string" then
		-- Check if player is an admin
		local isAdmin = player.UserId == 7768610061 -- Use your admin ID list here
		
		if isAdmin then
			-- Find the target player
			local Players = game:GetService("Players")
			local targetPlayer = Players:FindFirstChild(targetPlayerName)
			
			if targetPlayer then
				print("Admin " .. player.Name .. " resetting data for " .. targetPlayer.Name)
				resetPlayerData(targetPlayer)
			else
				print("Admin tried to reset data for non-existent player: " .. targetPlayerName)
				-- Notify the admin
				local message = Instance.new("Message")
				message.Text = "Player not found: " .. targetPlayerName
				message.Parent = player
				game:GetService("Debris"):AddItem(message, 3)
			end
		else
			print("Non-admin " .. player.Name .. " attempted to reset another player's data")
			-- Notify the player of unauthorized access
			local message = Instance.new("Message")
			message.Text = "Unauthorized: You don't have permission to reset other players' data"
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 3)
		end
	else
		-- Original functionality - player resetting their own data
		resetPlayerData(player)
	end
end)

print("Reset Button Handler initialized")