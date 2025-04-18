-- EnhancedDataStorageSystem.lua
-- Enhanced version of your existing DataStorageSystem with improved reliability and features
-- Place in ServerScriptService to replace or work alongside the original

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Attempt to load other systems
local BuyTileSystem
pcall(function()
	BuyTileSystem = require(ServerScriptService:FindFirstChild("BuyTile"))
end)

-- Configuration
local CONFIG = {
	-- DataStore settings
	mainDataStoreName = "GymTycoonDatav2",     -- Keep the same name as your existing system
	backupDataStoreName = "GymTycoonBackupv2", -- Separate store for backups
	saveInterval = 60,                         -- Save every 60 seconds
	backupInterval = 300,                      -- Create backup every 5 minutes

	-- Default values (used for new players)
	defaultData = {
		-- Economy
		cash = 1000,                        -- Starting cash
		totalEarned = 0,                    -- Lifetime earnings

		-- Progression
		equipmentPurchased = {},            -- Format: {tileId = true, ...}
		equipmentCount = 0, 
		gymLevel = 1,
		memberCount = 0,
		vipCount = 0,

		-- Stats
		playTime = 0,
		lastPlayed = 0,

		-- Version control
		dataVersion = 1                     -- For data migrations
	},

	-- Error handling
	maxRetries = 5,                         -- Maximum number of retry attempts
	retryDelay = 2,                         -- Base delay between retries (seconds)

	-- Debug
	debug = true
}

-- Module table
local DataStorage = {
	loadedData = {},         -- Loaded player data cache
	autoSaveActive = {}      -- For tracking active auto-save loops
}

-- Debug function
local function debugPrint(...)
	if CONFIG.debug then
		print("[DataManager]", ...)
	end
end

-- Initialize DataStores
function DataStorage.initialize()
	local success, result = pcall(function()
		DataStorage.dataStore = DataStoreService:GetDataStore(CONFIG.mainDataStoreName)
		DataStorage.backupStore = DataStoreService:GetDataStore(CONFIG.backupDataStoreName)
		return true
	end)

	if success then
		debugPrint("DataStores initialized successfully")
		return true
	else
		warn("Failed to initialize DataStores:", result)
		return false
	end
end

-- Deep copy a table
local function deepCopy(original)
	local copy
	if type(original) == "table" then
		copy = {}
		for key, value in pairs(original) do
			copy[key] = deepCopy(value)
		end
	else
		copy = original
	end
	return copy
end

-- Data version migration
local function migrateData(data)
	if not data then return deepCopy(CONFIG.defaultData) end

	local currentVersion = data.dataVersion or 0

	-- Version 0 to 1
	if currentVersion < 1 then
		data.dataVersion = 1
		data.totalEarned = data.totalEarned or 0
		debugPrint("Migrated data from version 0 to 1")
	end

	return data
end

-- Safe DataStore call with retries and exponential backoff
local function safeDataStoreCall(func)
	local retries = 0
	local success, result

	repeat
		success, result = pcall(func)

		if not success then
			retries = retries + 1
			local delay = math.min(CONFIG.retryDelay * (2 ^ retries), 30) -- Cap at 30 seconds
			warn("DataStore operation failed, retrying in", delay, "seconds. Error:", result)
			wait(delay)
		end
	until success or retries >= CONFIG.maxRetries

	return success, result
end

-- Load player data with retry mechanism
function DataStorage.loadData(player)
	if not player then return nil end
	local userId = player.UserId

	-- Check if already loaded
	if DataStorage.loadedData[userId] then
		return DataStorage.loadedData[userId]
	end

	local key = tostring(userId)
	local data

	-- Try to load data
	local success, result = safeDataStoreCall(function()
		return DataStorage.dataStore:GetAsync(key)
	end)

	if success then
		data = result
	end

	-- If data is nil, either no saved data or failed to load
	if not data then
		debugPrint("No saved data found or failed to load for " .. player.Name .. ", creating new data")
		data = deepCopy(CONFIG.defaultData)
	else
		debugPrint("Successfully loaded data for " .. player.Name)
	end

	-- Migrate data if needed
	data = migrateData(data)

	-- Add session info
	data.lastPlayed = os.time()
	data.sessionStart = os.time() -- For tracking play time

	-- Cache data
	DataStorage.loadedData[userId] = data

	-- Start auto-save for this player if not already running
	if not DataStorage.autoSaveActive[userId] then
		DataStorage.startAutoSave(player)
	end

	return data
end

-- Save player data with retry mechanism
function DataStorage.saveData(player, immediate)
	if not player then return false end
	local userId = player.UserId

	-- Check if data is loaded
	if not DataStorage.loadedData[userId] then
		warn("No data loaded for " .. player.Name .. ", cannot save")
		return false
	end

	-- Update data from player state before saving
	DataStorage.updateDataFromPlayer(player)

	-- Get the updated data
	local data = DataStorage.loadedData[userId]
	local key = tostring(userId)

	-- Update timestamps
	data.lastPlayed = os.time()

	-- Calculate playtime if we have a session start
	if data.sessionStart then
		local sessionTime = os.time() - data.sessionStart
		data.playTime = (data.playTime or 0) + sessionTime
		data.sessionStart = os.time() -- Reset for next save
	end

	-- Try to save data
	local success, result = safeDataStoreCall(function()
		DataStorage.dataStore:SetAsync(key, data)
		return true
	end)

	if success then
		debugPrint("Successfully saved data for " .. player.Name .. (immediate and " (immediate)" or ""))

		-- Create backup every 5 saves or on immediate saves
		if immediate or math.random(1, 5) == 1 then
			DataStorage.createBackup(player)
		end

		return true
	else
		warn("Failed to save data for " .. player.Name .. " after " .. CONFIG.maxRetries .. " attempts")
		return false
	end
end

-- Create a backup of player data
function DataStorage.createBackup(player)
	if not player then return false end
	local userId = player.UserId

	-- Check if data is loaded
	if not DataStorage.loadedData[userId] then
		return false
	end

	local data = DataStorage.loadedData[userId]
	local key = "Backup_" .. userId .. "_" .. os.time()

	local success, result = safeDataStoreCall(function()
		DataStorage.backupStore:SetAsync(key, data)
		return true
	end)

	if success then
		debugPrint("Created backup for " .. player.Name)
		return true
	else
		warn("Failed to create backup for " .. player.Name)
		return false
	end
end

-- Update cached data from player state
function DataStorage.updateDataFromPlayer(player)
	if not player then return false end
	local userId = player.UserId

	if not DataStorage.loadedData[userId] then return false end

	local data = DataStorage.loadedData[userId]
	local tycoon = player:FindFirstChild("Tycoon")

	if not tycoon then
		warn("No Tycoon object found for " .. player.Name)
		return false
	end

	-- Get cash from leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Cash") then
		data.cash = leaderstats.Cash.Value
	end

	-- Get equipment count and level
	data.equipmentCount = tycoon:GetAttribute("EquipmentCount") or data.equipmentCount
	data.gymLevel = tycoon:GetAttribute("GymTier") or tycoon:GetAttribute("GymLevel") or data.gymLevel

	-- Get member counts if available
	data.memberCount = tycoon:GetAttribute("MemberCount") or tycoon:GetAttribute("MembershipCount") or data.memberCount
	data.vipCount = tycoon:GetAttribute("VIPCount") or tycoon:GetAttribute("VIPMembershipCount") or data.vipCount

	-- Update purchased equipment by checking the tycoon model
	if tycoon.Value then
		for _, item in pairs(tycoon.Value:GetDescendants()) do
			local id = item:GetAttribute("ID")
			if id then
				data.equipmentPurchased[tostring(id)] = true
			end
		end
	end

	-- Check for GymParts folder in Workspace as fallback
	local gymPartsFolder = Workspace:FindFirstChild("GymParts")
	if gymPartsFolder then
		for _, item in pairs(gymPartsFolder:GetChildren()) do
			local id = item:GetAttribute("ID")
			if id then
				data.equipmentPurchased[tostring(id)] = true
			end
		end
	end

	return true
end

-- Apply loaded data to player
function DataStorage.applyDataToPlayer(player)
	if not player then return false end
	local userId = player.UserId

	if not DataStorage.loadedData[userId] then
		warn("No loaded data for " .. player.Name)
		return false
	end

	local data = DataStorage.loadedData[userId]

	-- Create leaderstats if it doesn't exist
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	-- Set Cash value
	local cashValue = leaderstats:FindFirstChild("Cash")
	if not cashValue then
		cashValue = Instance.new("IntValue")
		cashValue.Name = "Cash"
		cashValue.Parent = leaderstats
	end
	cashValue.Value = data.cash

	-- Ensure Tycoon value exists
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then
		tycoon = Instance.new("ObjectValue")
		tycoon.Name = "Tycoon"
		tycoon.Parent = player
	end

	-- Set attributes from saved data
	tycoon:SetAttribute("EquipmentCount", data.equipmentCount)
	tycoon:SetAttribute("GymTier", data.gymLevel)
	tycoon:SetAttribute("MemberCount", data.memberCount)
	tycoon:SetAttribute("VIPCount", data.vipCount)

	-- Start session time tracking
	data.sessionStart = os.time()

	debugPrint("Applied data to " .. player.Name)
	return true
end

-- Record purchased equipment
function DataStorage.recordEquipmentPurchase(player, tileId)
	if not player then return false end
	local userId = player.UserId

	if not DataStorage.loadedData[userId] then
		warn("No loaded data for " .. player.Name)
		return false
	end

	local data = DataStorage.loadedData[userId]

	-- Initialize if needed
	if not data.equipmentPurchased then
		data.equipmentPurchased = {}
	end

	-- Record purchase
	data.equipmentPurchased[tostring(tileId)] = true

	debugPrint(player.Name .. " purchased tile " .. tileId)
	return true
end

-- Restore purchased equipment
function DataStorage.restorePurchasedEquipment(player)
	if not player then return false end
	local userId = player.UserId

	if not DataStorage.loadedData[userId] then
		warn("No loaded data for " .. player.Name)
		return false
	end

	local data = DataStorage.loadedData[userId]

	-- Check if player has any purchased equipment
	if not data.equipmentPurchased or next(data.equipmentPurchased) == nil then
		debugPrint("No purchased equipment to restore for " .. player.Name)
		return true
	end

	-- Get tycoon reference
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then
		warn("No valid tycoon for " .. player.Name)
		return false
	end

	-- Check if BuyTile system is available
	if not BuyTileSystem or not BuyTileSystem.spawnGymPart then
		warn("BuyTile system not available or missing spawnGymPart function")
		return false
	end

	-- Get purchased tile IDs
	local purchasedTiles = {}
	for tileId, _ in pairs(data.equipmentPurchased) do
		table.insert(purchasedTiles, tonumber(tileId) or tonumber(string.match(tileId, "%d+")))
	end

	-- Sort IDs to purchase in order
	table.sort(purchasedTiles)

	-- Allow time for tycoon to fully initialize
	task.wait(2)

	debugPrint("Restoring " .. #purchasedTiles .. " equipment pieces for " .. player.Name)

	-- Track successful spawns
	local spawnCount = 0

	-- Spawn each tile with a small delay between them
	for i, tileId in ipairs(purchasedTiles) do
		task.wait(0.2) -- Slight delay to prevent issues

		local success = false

		if i == 1 then
			-- Spawn initial tile
			local tile = BuyTileSystem.spawnBuyTile(1)
			if tile then
				spawnCount = spawnCount + 1
				debugPrint("Restored initial tile for " .. player.Name)
				success = true
			end
		else
			-- Try to spawn gym part
			local part = BuyTileSystem.spawnGymPart(tileId)
			if part then
				spawnCount = spawnCount + 1
				debugPrint("Restored gym part " .. tileId .. " for " .. player.Name)
				success = true
			else
				warn("Failed to restore gym part " .. tileId .. " for " .. player.Name)
			end
		end
	end

	debugPrint("Successfully restored " .. spawnCount .. "/" .. #purchasedTiles .. " equipment pieces for " .. player.Name)

	-- Update equipment count on tycoon
	tycoon:SetAttribute("EquipmentCount", spawnCount)
	data.equipmentCount = spawnCount

	return true
end

-- Set up auto-save for a player
function DataStorage.startAutoSave(player)
	if not player then return false end
	local userId = player.UserId

	-- Clean up existing timer if it exists
	if DataStorage.autoSaveActive[userId] then
		DataStorage.autoSaveActive[userId] = nil
	end

	-- Create new auto-save loop
	DataStorage.autoSaveActive[userId] = true

	-- Start the auto-save loop in a separate thread
	task.spawn(function()
		while DataStorage.autoSaveActive[userId] do
			wait(CONFIG.saveInterval)
			if player and player.Parent then
				DataStorage.saveData(player, false)
			else
				-- Player left, stop auto-save
				DataStorage.autoSaveActive[userId] = nil
				break
			end
		end
	end)

	debugPrint("Started auto-save for " .. player.Name)
	return true
end

-- Stop auto-save for a player
function DataStorage.stopAutoSave(player)
	if not player then return false end
	local userId = player.UserId

	if DataStorage.autoSaveActive[userId] then
		DataStorage.autoSaveActive[userId] = nil
		debugPrint("Stopped auto-save for " .. player.Name)
		return true
	end

	return false
end

-- Event connections
function DataStorage.connectEvents()
	-- Player joining
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			-- Wait a moment for the player to load
			task.wait(2)

			-- Load player data
			local data = DataStorage.loadData(player)
			if data then
				-- Apply loaded data to player
				DataStorage.applyDataToPlayer(player)

				-- Wait a moment for the tycoon to be created
				task.wait(3)

				-- Restore purchased equipment
				task.spawn(function()
					DataStorage.restorePurchasedEquipment(player)
				end)
			end
		end)
	end)

	-- Player leaving
	Players.PlayerRemoving:Connect(function(player)
		task.spawn(function()
			-- Stop auto-save
			DataStorage.stopAutoSave(player)

			-- Save player data immediately
			DataStorage.saveData(player, true)

			-- Create backup
			DataStorage.createBackup(player)

			-- Clear cache
			local userId = player.UserId
			DataStorage.loadedData[userId] = nil

			debugPrint("Cleaned up data for leaving player: " .. player.Name)
		end)
	end)

	-- Connect to tile purchase events
	local EventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
	if EventBridge then
		local tilePurchasedEvent = EventBridge:FindFirstChild("TilePurchased")
		if tilePurchasedEvent then
			tilePurchasedEvent.Event:Connect(function(player, tileId)
				DataStorage.recordEquipmentPurchase(player, tileId)
			end)
			debugPrint("Connected to TilePurchased event")
		else
			warn("TilePurchased event not found in EventBridge")
		end
	else
		warn("EventBridge not found in ReplicatedStorage")
	end

	-- Connect to game close event
	game:BindToClose(function()
		debugPrint("Game closing, saving all player data...")

		-- Save data for all players
		for _, player in pairs(Players:GetPlayers()) do
			task.spawn(function()
				DataStorage.saveData(player, true)
			end)
		end

		-- Wait a moment to allow saves to complete
		wait(5)
		debugPrint("All player data saved")
	end)

	debugPrint("Events connected")
end

-- Print player data for debugging
function DataStorage.printPlayerData(player)
	if not player then return end
	local userId = player.UserId

	if not DataStorage.loadedData[userId] then
		print("No loaded data for " .. player.Name)
		return
	end

	local data = DataStorage.loadedData[userId]
	print("=== Saved Data for " .. player.Name .. " ===")
	print("Cash: $" .. data.cash)
	print("Gym Level: " .. data.gymLevel)
	print("Equipment Count: " .. data.equipmentCount)
	print("Member Count: " .. (data.memberCount or "N/A"))
	print("VIP Count: " .. (data.vipCount or "N/A"))
	print("Play Time: " .. (data.playTime or 0) .. " seconds")
	print("Last Played: " .. os.date("%Y-%m-%d %H:%M:%S", data.lastPlayed))
	print("Data Version: " .. data.dataVersion)

	-- Print purchased equipment
	if data.equipmentPurchased and next(data.equipmentPurchased) then
		print("Purchased Equipment:")
		local count = 0
		for tileId, _ in pairs(data.equipmentPurchased) do
			count = count + 1
			print("- Tile ID: " .. tileId)
		end
		print("Total: " .. count .. " pieces of equipment")
	else
		print("No purchased equipment")
	end
end

-- Initialize the system
if DataStorage.initialize() then
	DataStorage.connectEvents()
end

-- Start auto-save for existing players
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		-- Load data for existing player
		local data = DataStorage.loadData(player)
		if data then
			DataStorage.applyDataToPlayer(player)
			task.wait(3)
			DataStorage.restorePurchasedEquipment(player)
		end
	end)
end

-- Handle existing auto-save function in the old system
-- Detect if we need to override the global autoSave function
if _G.autoSave then
	debugPrint("Detected existing autoSave function, will use enhanced version")
	-- We'll keep the existing global to avoid errors but make it a no-op
	_G.autoSave = function() end
end

-- Ensure this module can be used as a drop-in replacement
return DataStorage