-- PlayerSanctionSystem.lua
-- System for handling player abuse cases with different sanction levels
-- Place in ServerScriptService

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")

-- Try to load dependencies
local DataStorage
pcall(function()
	DataStorage = require(ServerScriptService:FindFirstChild("DataStorageSystem"))
end)

-- Configuration
local CONFIG = {
	-- Data Stores
	sanctionsDataStoreName = "GymTycoonSanctions_v1",
	bannedPlayersDataStoreName = "GymTycoonBanned_v1",

	-- Sanction levels
	sanctionLevels = {
		WARNING = 1,    -- Just log warning, no game effect
		RESET_MONEY = 2, -- Reset cash to starting amount
		RESET_PROGRESS = 3, -- Reset all progress (money, equipment, level)
		TEMP_BAN = 4,   -- Temporary ban (duration specified separately)
		PERM_BAN = 5    -- Permanent ban
	},

	-- Sanction settings
	defaultStartingCash = 1000, -- Amount to reset to
	tempBanDefaultDuration = 7, -- Default temp ban days

	-- Logging
	enableLogging = true,
	logDataStore = "GymTycoonAbuseLog_v1"
}

-- Module table
local SanctionSystem = {
	sanctionsStore = nil,
	bannedStore = nil,
	logStore = nil
}

-- Initialize data stores
function SanctionSystem.initialize()
	-- Sanctions data store (tracks player sanctions)
	SanctionSystem.sanctionsStore = DataStoreService:GetDataStore(CONFIG.sanctionsDataStoreName)

	-- Banned players data store
	SanctionSystem.bannedStore = DataStoreService:GetDataStore(CONFIG.bannedPlayersDataStoreName)

	-- Logging data store
	if CONFIG.enableLogging then
		SanctionSystem.logStore = DataStoreService:GetDataStore(CONFIG.logDataStore)
	end

	print("Player Sanction System initialized")
	return true
end

-- Log sanction event
function SanctionSystem.logSanction(player, sanctionLevel, reason, adminName)
	if not CONFIG.enableLogging or not SanctionSystem.logStore then return end

	local userId = player.UserId
	local logKey = "log_" .. userId .. "_" .. os.time()

	local logData = {
		userId = userId,
		playerName = player.Name,
		sanctionLevel = sanctionLevel,
		reason = reason or "No reason provided",
		timestamp = os.time(),
		adminName = adminName or "System"
	}

	pcall(function()
		SanctionSystem.logStore:SetAsync(logKey, logData)
	end)
end

-- Apply sanction to player
function SanctionSystem.applySanction(player, sanctionLevel, reason, adminName, customDuration)
	if not player then return false end

	local userId = player.UserId
	local sanctionLevel = sanctionLevel or CONFIG.sanctionLevels.WARNING

	-- Log the sanction
	SanctionSystem.logSanction(player, sanctionLevel, reason, adminName)

	-- Apply the sanction based on level
	if sanctionLevel == CONFIG.sanctionLevels.WARNING then
		-- Just log warning, no game effect
		print("WARNING issued to " .. player.Name .. ": " .. (reason or "No reason provided"))
		return true

	elseif sanctionLevel == CONFIG.sanctionLevels.RESET_MONEY then
		-- Reset player's cash to starting amount
		if DataStorage then
			local data = DataStorage.loadedData[userId]
			if data then
				data.cash = CONFIG.defaultStartingCash

				-- Update in-game cash
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats and leaderstats:FindFirstChild("Cash") then
					leaderstats.Cash.Value = CONFIG.defaultStartingCash
				end

				-- Force save
				DataStorage.saveData(player, true)
				print("Reset money for " .. player.Name .. " to $" .. CONFIG.defaultStartingCash)
				return true
			end
		end

	elseif sanctionLevel == CONFIG.sanctionLevels.RESET_PROGRESS then
		-- Completely reset player progress
		if DataStorage then
			-- Create new data with default values
			DataStorage.loadedData[userId] = DataStorage.deepCopy(DataStorage.defaultData)

			-- Update player in game
			DataStorage.applyDataToPlayer(player)

			-- Force save
			DataStorage.saveData(player, true)
			print("Reset all progress for " .. player.Name)

			-- Kick player to force reload
			player:Kick("Your progress has been reset by a moderator. Please rejoin.")
			return true
		end

	elseif sanctionLevel == CONFIG.sanctionLevels.TEMP_BAN then
		-- Set up temporary ban
		local duration = customDuration or CONFIG.tempBanDefaultDuration
		local banExpiration = os.time() + (duration * 86400) -- Convert days to seconds

		pcall(function()
			SanctionSystem.bannedStore:SetAsync("ban_" .. userId, {
				userId = userId,
				playerName = player.Name,
				reason = reason,
				bannedBy = adminName or "System",
				bannedAt = os.time(),
				expiresAt = banExpiration
			})
		end)

		-- Kick the player
		player:Kick("You have been temporarily banned: " .. (reason or "No reason provided"))
		print("Temporary banned " .. player.Name .. " for " .. duration .. " days")
		return true

	elseif sanctionLevel == CONFIG.sanctionLevels.PERM_BAN then
		-- Set up permanent ban
		pcall(function()
			SanctionSystem.bannedStore:SetAsync("ban_" .. userId, {
				userId = userId,
				playerName = player.Name,
				reason = reason,
				bannedBy = adminName or "System",
				bannedAt = os.time(),
				expiresAt = 0 -- 0 means permanent
			})
		end)

		-- Kick the player
		player:Kick("You have been permanently banned: " .. (reason or "No reason provided"))
		print("Permanently banned " .. player.Name)
		return true
	end

	return false
end

-- Purge player data completely
function SanctionSystem.purgePlayerData(userId)
	if type(userId) ~= "number" then
		-- Check if it's a player object
		if typeof(userId) == "Instance" and userId:IsA("Player") then
			userId = userId.UserId
		else
			return false
		end
	end

	local success = true

	-- Remove from DataStorage
	pcall(function()
		-- Remove main data
		DataStorage.dataStore:RemoveAsync("player_" .. userId)

		-- Remove any loaded data
		if DataStorage.loadedData[userId] then
			DataStorage.loadedData[userId] = nil
		end
	end)

	-- Remove backups
	pcall(function()
		-- List all backups
		local backups = DataStorage.backupStore:GetSortedAsync("player_" .. userId, false, 100)
		local pages = backups:GetCurrentPage()

		-- Remove all backups
		for _, item in ipairs(pages) do
			DataStorage.backupStore:RemoveAsync(item.key)
		end
	end)

	print("Purged all data for user ID: " .. userId)
	return success
end

-- Check if player is banned
function SanctionSystem.isPlayerBanned(player)
	if not player then return false end

	local userId = player.UserId
	local banned = false
	local banReason = nil
	local banExpiration = nil

	-- Check ban status
	local success, banData = pcall(function()
		return SanctionSystem.bannedStore:GetAsync("ban_" .. userId)
	end)

	if success and banData then
		if banData.expiresAt == 0 then
			-- Permanent ban
			banned = true
			banReason = banData.reason
			banExpiration = nil
		elseif banData.expiresAt > os.time() then
			-- Temporary ban still active
			banned = true
			banReason = banData.reason
			banExpiration = banData.expiresAt
		else
			-- Ban expired, remove it
			pcall(function()
				SanctionSystem.bannedStore:RemoveAsync("ban_" .. userId)
			end)
		end
	end

	return banned, banReason, banExpiration
end

-- Format ban duration for display
function SanctionSystem.formatTimeRemaining(expiresAt)
	if not expiresAt then return "Permanent" end

	local secondsLeft = expiresAt - os.time()
	if secondsLeft <= 0 then return "Expired" end

	local days = math.floor(secondsLeft / 86400)
	local hours = math.floor((secondsLeft % 86400) / 3600)
	local minutes = math.floor((secondsLeft % 3600) / 60)

	if days > 0 then
		return days .. " days, " .. hours .. " hours"
	elseif hours > 0 then
		return hours .. " hours, " .. minutes .. " minutes"
	else
		return minutes .. " minutes"
	end
end

-- Unban a player
function SanctionSystem.unbanPlayer(userId)
	if type(userId) ~= "number" then
		-- Check if it's a player object
		if typeof(userId) == "Instance" and userId:IsA("Player") then
			userId = userId.UserId
		else
			return false
		end
	end

	-- Remove ban entry
	local success = pcall(function()
		SanctionSystem.bannedStore:RemoveAsync("ban_" .. userId)
	end)

	return success
end

-- Connect to player events
Players.PlayerAdded:Connect(function(player)
	-- Check if player is banned
	local banned, reason, expiration = SanctionSystem.isPlayerBanned(player)

	if banned then
		local formattedTime = SanctionSystem.formatTimeRemaining(expiration)
		local message = "You are banned: " .. (reason or "No reason provided")

		if expiration then
			message = message .. "\nTime remaining: " .. formattedTime
		end

		-- Kick the player
		player:Kick(message)
	end
end)

-- Initialize the system
SanctionSystem.initialize()

return SanctionSystem