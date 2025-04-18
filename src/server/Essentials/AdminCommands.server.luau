-- AdminCommands.lua
-- System for admin commands to manage player sanctions
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Load the sanction system
local SanctionSystem = require(ServerScriptService:FindFirstChild("PlayerSanctionSystem"))

-- List of admin user IDs (replace with your actual admin IDs)
local ADMIN_IDS = {
	7768610061, -- Replace with actual admin user IDs
	-- Add more admin IDs here
}

-- Check if player is an admin
local function isAdmin(player)
	if not player then return false end

	-- Check if player's ID is in the admin list
	for _, adminId in ipairs(ADMIN_IDS) do
		if player.UserId == adminId then
			return true
		end
	end

	return false
end

-- Parse command arguments
local function parseArgs(message)
	local args = {}

	-- Split by space
	for arg in string.gmatch(message, "%S+") do
		table.insert(args, arg)
	end

	return args
end

-- Find player by name or partial name
local function findPlayer(nameOrPartial)
	nameOrPartial = string.lower(nameOrPartial)

	for _, player in pairs(Players:GetPlayers()) do
		if string.lower(player.Name) == nameOrPartial then
			-- Exact match
			return player
		end
	end

	-- Try partial match
	for _, player in pairs(Players:GetPlayers()) do
		if string.find(string.lower(player.Name), nameOrPartial) then
			return player
		end
	end

	return nil
end

-- Process admin commands
local function processAdminCommand(player, message)
	if not isAdmin(player) then return end

	-- Check if message starts with the command prefix
	if not string.sub(message, 1, 1) == "/" then return end

	-- Parse command
	local args = parseArgs(message)
	local command = string.lower(table.remove(args, 1)) -- Remove and get first element (the command)

	-- Skip prefix
	command = string.sub(command, 2)

	-- Process commands
	if command == "warn" then
		-- Format: /warn PlayerName Reason
		local targetName = args[1]
		table.remove(args, 1) -- Remove player name
		local reason = table.concat(args, " ")

		local targetPlayer = findPlayer(targetName)
		if targetPlayer then
			SanctionSystem.applySanction(
				targetPlayer, 
				SanctionSystem.CONFIG.sanctionLevels.WARNING, 
				reason, 
				player.Name
			)

			-- Notify admin
			local message = Instance.new("Message")
			message.Text = "Warning issued to " .. targetPlayer.Name
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 3)
		else
			-- Player not found
			local message = Instance.new("Message")
			message.Text = "Player not found: " .. targetName
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 3)
		end

	elseif command == "resetmoney" then
		-- Format: /resetmoney PlayerName Reason
		local targetName = args[1]
		table.remove(args, 1) -- Remove player name
		local reason = table.concat(args, " ")

		local targetPlayer = findPlayer(targetName)
		if targetPlayer then
			SanctionSystem.applySanction(
				targetPlayer, 
				SanctionSystem.CONFIG.sanctionLevels.RESET_MONEY, 
				reason, 
				player.Name
			)

			-- Notify admin
			local message = Instance.new("Message")
			message.Text = "Reset money for " .. targetPlayer.Name
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 3)
		else
			-- Player not found
			local message = Instance.new("Message")
			message.Text = "Player not found: " .. targetName
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 3)
		end

	elseif command == "resetprogress" then
		-- Format: /resetprogress PlayerName Reason
		local targetName = args[1]
		table.remove(args, 1) -- Remove player name
		local reason = table.concat(args, " ")

		local targetPlayer = findPlayer(targetName)
		if targetPlayer then
			SanctionSystem.applySanction(
				targetPlayer, 
				SanctionSystem.CONFIG.sanctionLevels.RESET_PROGRESS, 
				reason, 
				player.Name
			)

			-- Notify admin
			local message = Instance.new("Message")
			message.Text = "Reset progress for " .. targetPlayer.Name
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 3)
		else
			-- Player not found
			local message = Instance.new("Message")
			message.Text = "Player not found: " .. targetName
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 3)
		end

	elseif command == "tempban" then
		-- Format: /tempban PlayerName Duration Reason
		local targetName = args[1]
		local duration = tonumber(args[2]) or SanctionSystem.CONFIG.tempBanDefaultDuration

		table.remove(args, 1) -- Remove player name
		table.remove(args, 1) -- Remove duration
		local reason = table.concat(args, " ")

		local targetPlayer = findPlayer(targetName)
		if targetPlayer then
			SanctionSystem.applySanction(
				targetPlayer, 
				SanctionSystem.CONFIG.sanctionLevels.TEMP_BAN, 
				reason, 
				player.Name,
				duration
			)

			-- Notify admin
			local message = Instance.new("Message")
			message.Text = "Temp banned " .. targetPlayer.Name .. " for " .. duration .. " days"
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 3)
		else
			-- Player not found
			local message = Instance.new("Message")
			message.Text = "Player not found: " .. targetName
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 3)
		end

	elseif command == "permban" then
		-- Format: /permban PlayerName Reason
		local targetName = args[1]
		table.remove(args, 1) -- Remove player name
		local reason = table.concat(args, " ")

		local targetPlayer = findPlayer(targetName)
		if targetPlayer then
			SanctionSystem.applySanction(
				targetPlayer, 
				SanctionSystem.CONFIG.sanctionLevels.PERM_BAN, 
				reason, 
				player.Name
			)

			-- Notify admin
			local message = Instance.new("Message")
			message.Text = "Permanently banned " .. targetPlayer.Name
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 3)
		else
			-- Player not found
			local message = Instance.new("Message")
			message.Text = "Player not found: " .. targetName
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 3)
		end

	elseif command == "purge" then
		-- Format: /purge PlayerName
		local targetName = args[1]

		local targetPlayer = findPlayer(targetName)
		if targetPlayer then
			SanctionSystem.purgePlayerData(targetPlayer)

			-- Notify admin
			local message = Instance.new("Message")
			message.Text = "Purged all data for " .. targetPlayer.Name
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 3)
		else
			-- Player not found
			local message = Instance.new("Message")
			message.Text = "Player not found: " .. targetName
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 3)
		end

	elseif command == "unban" then
		-- Format: /unban UserId
		local userIdString = args[1]
		local userId = tonumber(userIdString)

		if userId then
			local success = SanctionSystem.unbanPlayer(userId)

			-- Notify admin
			local message = Instance.new("Message")
			message.Text = success and "Unbanned user ID: " .. userId or "Failed to unban user ID: " .. userId
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 3)
		else
			-- Invalid user ID
			local message = Instance.new("Message")
			message.Text = "Invalid user ID: " .. (userIdString or "nil")
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 3)
		end
	end
end

-- Connect to player chat event
local function onPlayerChatted(player, message)
	processAdminCommand(player, message)
end

-- Connect to chat events
for _, player in pairs(Players:GetPlayers()) do
	player.Chatted:Connect(function(message)
		onPlayerChatted(player, message)
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		onPlayerChatted(player, message)
	end)
end)

print("Admin Commands System initialized")