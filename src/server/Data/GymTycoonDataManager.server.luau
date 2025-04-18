-- GymTycoonDataManager.lua
-- Robust data storage and retrieval system for Gym Tycoon
-- Place in ServerScriptService

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
	dataStoreName = "GymTycoonSaveV1",  -- Change version if data structure changes
	backupStoreName = "GymTycoonBackup",
	saveInterval = 60,                  -- Auto-save every 60 seconds
	maxRetries = 5,                     -- Max retry attempts for DataStore operations
	debug = true,                       -- Enable debug prints

	-- Default player data
	defaultData = {
		cash = 1000,                    -- Starting cash
		equipmentPurchased = {},        -- {[tileId] = true, ...}
		equipmentCount = 0,             -- Equipment counter
		gymLevel = 1,                   -- Gym tier/level
		memberCount = 0,                -- Member count
		accruedDues = 0,                -- Uncollected dues
		lastSaveTime = 0,               -- Last time data was saved
		dataVersion = 1                 -- For data migration
	}
}

-- Module table
local DataManager = {
	loaded = {},      -- Cached player data
	savers = {},      -- Auto-save coroutines
	dataStore = nil,  -- Main DataStore
	backupStore = nil -- Backup DataStore
}

-- Debug logger
local function log(...)
	if CONFIG.debug then
		print("[DataManager]", ...)
	end
end

-- Deep copy a table (for creating new player data)
local function deepCopy(original)
	if type(original) ~= "table" then return original end

	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = deepCopy(value)
		else
			copy[key] = value
		end
	end

	return copy
end

-- Safe DataStore call with retries
local function safeDataStoreCall(func)
	local success, result
	local attempts = 0

	repeat
		attempts = attempts + 1
		success, result = pcall(func)

		if not success then
			-- Wait with exponential backoff
			local waitTime = math.min(2^attempts, 30)
			log("DataStore call failed:", result, "- Retrying in", waitTime, "seconds (Attempt", attempts, "of", CONFIG.maxRetries, ")")
			task.wait(waitTime)
		end
	until success or attempts >= CONFIG.maxRetries

	return success, result
end

-- Initialize the DataStores
function DataManager.init()
	if not RunService:IsServer() then
		warn("DataManager can only run on the server")
		return false
	end

	-- Enable Studio access in test mode
	if RunService:IsStudio() then
		log("Running in Studio - data persistence may not work unless enabled in Game Settings")
	end

	-- Try to get the DataStores
	local success, err = pcall(function()
		DataManager.dataStore = DataStoreService:GetDataStore(CONFIG.dataStoreName)
		DataManager.backupStore = DataStoreService:GetDataStore(CONFIG.backupStoreName)
	end)

	if not success then
		warn("Failed to initialize DataStores:", err)
		return false
	end

	log("DataManager initialized successfully")
	return true
end

-- Load player data
function DataManager.loadData(player)
	if not player then return nil end
	local userId = player.UserId

	-- Return cached data if available
	if DataManager.loaded[userId] then
		return DataManager.loaded[userId]
	end

	-- Attempt to fetch from DataStore
	local key = "Player_" .. userId
	local data

	-- Try to load data
	local success, result = safeDataStoreCall(function()
		return DataManager.dataStore:GetAsync(key)
	end)

	if success and result then
		data = result
		log("Loaded data for", player.Name)
	else
		-- Create default data for new player
		data = deepCopy(CONFIG.defaultData)
		log("Created new data for", player.Name)
	end

	-- Migration for data version updates
	if (data.dataVersion or 0) < CONFIG.defaultData.dataVersion then
		log("Migrating data from version", data.dataVersion or 0, "to", CONFIG.defaultData.dataVersion)
		-- Fill in missing fields from the default data
		for key, defaultValue in pairs(CONFIG.defaultData) do
			if data[key] == nil then
				data[key] = deepCopy(defaultValue)
			end
		end
		data.dataVersion = CONFIG.defaultData.dataVersion
	end

	-- Cache the data
	DataManager.loaded[userId] = data

	-- Start auto-save
	if not DataManager.savers[userId] then
		DataManager.startAutoSave(player)
	end

	return data
end

-- Save player data
function DataManager.saveData(player, immediately)
	if not player then return false end
	local userId = player.UserId

	-- Make sure data is loaded
	if not DataManager.loaded[userId] then
		log("No data loaded for", player.Name)
		return false
	end

	-- Update data from player first
	DataManager.updateDataFromPlayer(player)

	local data = DataManager.loaded[userId]
	local key = "Player_" .. userId

	-- Update last save time
	data.lastSaveTime = os.time()

	-- Try to save data
	local success, result = safeDataStoreCall(function()
		DataManager.dataStore:SetAsync(key, data)
		return true
	end)

	if success then
		log("Saved data for", player.Name, immediately and "(immediate)" or "")
		return true
	else
		warn("Failed to save data for", player.Name)
		return false
	end
end

-- Create a backup of player data
function DataManager.createBackup(player)
	if not player then return false end
	local userId = player.UserId

	-- Make sure data is loaded
	if not DataManager.loaded[userId] then
		return false
	end

	local data = DataManager.loaded[userId]
	local key = "Backup_" .. userId .. "_" .. os.time()

	-- Try to save backup
	local success = pcall(function()
		DataManager.backupStore:SetAsync(key, data)
	end)

	if success then
		log("Created backup for", player.Name)
		return true
	else
		warn("Failed to create backup for", player.Name)
		return false
	end
end

-- Update cached data from player state
function DataManager.updateDataFromPlayer(player)
	if not player then return false end
	local userId = player.UserId

	-- Make sure data is loaded
	if not DataManager.loaded[userId] then
		return false
	end

	local data = DataManager.loaded[userId]

	-- Get leaderstats (cash)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Cash") then
		data.cash = leaderstats.Cash.Value
	end

	-- Get tycoon attributes
	local tycoon = player:FindFirstChild("Tycoon")
	if tycoon then
		-- Update equipment count
		data.equipmentCount = tycoon:GetAttribute("EquipmentCount") or data.equipmentCount

		-- Update gym level/tier
		data.gymLevel = tycoon:GetAttribute("GymTier") or tycoon:GetAttribute("GymLevel") or data.gymLevel

		-- Update membership counts
		data.memberCount = tycoon:GetAttribute("MemberCount") or tycoon:GetAttribute("MembershipCount") or data.memberCount

		-- Update accrued dues
		data.accruedDues = tycoon:GetAttribute("AccruedDues") or data.accruedDues

		-- Check purchased equipment
		if tycoon.Value then
			-- Look through tycoon model for equipment with ID attributes
			for _, item in pairs(tycoon.Value:GetDescendants()) do
				local id = item:GetAttribute("ID")
				if id then
					data.equipmentPurchased[tostring(id)] = true
				end
			end
		end
	end

	return true
end

-- Apply data to player
function DataManager.applyDataToPlayer(player)
	if not player then return false end
	local userId = player.UserId

	-- Make sure data is loaded
	if not DataManager.loaded[userId] then
		log("No data loaded for", player.Name)
		return false
	end

	local data = DataManager.loaded[userId]

	-- Create leaderstats if needed
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	-- Set cash
	local cashValue = leaderstats:FindFirstChild("Cash")
	if not cashValue then
		cashValue = Instance.new("IntValue")
		cashValue.Name = "Cash"
		cashValue.Parent = leaderstats
	end
	cashValue.Value = data.cash

	-- Make sure Tycoon object exists
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then
		tycoon = Instance.new("ObjectValue")
		tycoon.Name = "Tycoon"
		tycoon.Parent = player
	end

	-- Set tycoon attributes
	tycoon:SetAttribute("EquipmentCount", data.equipmentCount)
	tycoon:SetAttribute("GymTier", data.gymLevel)
	tycoon:SetAttribute("MemberCount", data.memberCount)
	tycoon:SetAttribute("AccruedDues", data.accruedDues)

	log("Applied data to", player.Name)
	return true
end

-- Record equipment purchase
function DataManager.recordEquipmentPurchase(player, tileId)
	if not player then return false end
	local userId = player.UserId

	-- Make sure data is loaded
	if not DataManager.loaded[userId] then
		log("No data loaded for", player.Name, "- loading now")
		DataManager.loadData(player)
	end

	-- Make sure we have data now
	if not DataManager.loaded[userId] then
		warn("Failed to load data for", player.Name)
		return false
	end

	local data = DataManager.loaded[userId]

	-- Record the purchase
	data.equipmentPurchased[tostring(tileId)] = true

	-- Update equipment count
	local tycoon = player:FindFirstChild("Tycoon")
	if tycoon then
		local count = tycoon:GetAttribute("EquipmentCount") or 0
		tycoon:SetAttribute("EquipmentCount", count + 1)
		data.equipmentCount = count + 1
	end

	log(player.Name, "purchased tile", tileId)

	-- Trigger a save soon after purchase
	task.delay(5, function()
		if player and player.Parent then
			DataManager.saveData(player, false)
		end
	end)

	return true
end

-- Helper function to get BuyTile System
function DataManager.getBuyTileSystem()
	-- Try direct require
	local buyTileSystem = nil
	pcall(function()
		buyTileSystem = require(ServerScriptService:FindFirstChild("BuyTile"))
	end)

	-- Check if we got valid functions
	if buyTileSystem and buyTileSystem.spawnGymPart and buyTileSystem.spawnBuyTile then
		return buyTileSystem
	end

	-- Create minimal compatibility layer if not found
	local fallbackSystem = {
		spawnGymPart = function(id)
			log("Using fallback spawnGymPart for ID:", id)
			-- Attempt to find GymParts in workspace or ServerStorage
			local ServerStorage = game:GetService("ServerStorage")
			local gymPartsFolder = ServerStorage:FindFirstChild("GymParts") or workspace:FindFirstChild("GymParts")

			if not gymPartsFolder then
				warn("No GymParts folder found")
				return nil
			end

			-- Find the part by ID
			local part = nil
			for _, item in pairs(gymPartsFolder:GetDescendants()) do
				if item:IsA("Model") and item:GetAttribute("ID") == id then
					part = item:Clone()
					part.Parent = workspace
					log("Found and cloned gym part with ID:", id)
					return part
				end
			end

			warn("Could not find gym part with ID:", id)
			return nil
		end,

		spawnBuyTile = function(id)
			log("Using fallback spawnBuyTile for ID:", id)
			-- Similar implementation to spawnGymPart but for BuyTiles
			local ServerStorage = game:GetService("ServerStorage")
			local buyTilesFolder = ServerStorage:FindFirstChild("BuyTiles") or workspace:FindFirstChild("BuyTiles")

			if not buyTilesFolder then
				warn("No BuyTiles folder found")
				return nil
			end

			-- Find the tile by ID
			local tile = nil
			for _, item in pairs(buyTilesFolder:GetDescendants()) do
				if item:IsA("Model") and item:GetAttribute("ID") == id then
					tile = item:Clone()
					tile.Parent = workspace
					log("Found and cloned buy tile with ID:", id)
					return tile
				end
			end

			warn("Could not find buy tile with ID:", id)
			return nil
		end
	}

	return fallbackSystem
end

-- Restore purchased equipment
function DataManager.restorePurchasedEquipment(player)
	if not player then return false end
	local userId = player.UserId

	-- Make sure data is loaded
	if not DataManager.loaded[userId] then
		log("No data loaded for", player.Name, "- loading now")
		DataManager.loadData(player)
	end

	-- Make sure we have data now
	if not DataManager.loaded[userId] then
		warn("Failed to load data for", player.Name)
		return false
	end

	local data = DataManager.loaded[userId]

	-- Check if we have any purchases to restore
	if not data.equipmentPurchased or not next(data.equipmentPurchased) then
		log("No equipment to restore for", player.Name)
		return true
	end

	-- Make sure player has a tycoon model
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then
		log("Player", player.Name, "has no tycoon model assigned")
		return false
	end

	-- Get the BuyTile system
	local buyTileSystem = DataManager.getBuyTileSystem()
	if not buyTileSystem then
		warn("Could not get BuyTile system")
		return false
	end

	-- Create a list of purchased tile IDs
	local tileIds = {}
	for idStr in pairs(data.equipmentPurchased) do
		local id = tonumber(idStr)
		if id then
			table.insert(tileIds, id)
		end
	end

	-- Sort IDs for sequential placement
	table.sort(tileIds)

	log("Restoring", #tileIds, "tiles for", player.Name)

	-- Track successful restores
	local restoredCount = 0

	-- Restore each tile with a small delay
	for i, id in ipairs(tileIds) do
		task.wait(0.2) -- Small delay to avoid overwhelming the server

		-- Check if item with this ID already exists
		local exists = false
		for _, item in pairs(tycoon.Value:GetDescendants()) do
			if item:GetAttribute("ID") == id then
				exists = true
				restoredCount = restoredCount + 1
				break
			end
		end

		if not exists then
			-- For first tile, use spawnBuyTile
			local part = nil
			if id == 1 then
				part = buyTileSystem.spawnBuyTile(id)
			else
				part = buyTileSystem.spawnGymPart(id)
			end

			if part then
				-- Make sure the part is parented to the tycoon model
				if part.Parent ~= tycoon.Value then
					part.Parent = tycoon.Value
				end

				-- Set owner attribute
				part:SetAttribute("Owner", player.UserId)

				restoredCount = restoredCount + 1
				log("Restored tile", id, "for", player.Name)
			else
				warn("Failed to restore tile", id, "for", player.Name)
			end
		end
	end

	-- Update equipment count attribute
	tycoon:SetAttribute("EquipmentCount", restoredCount)
	data.equipmentCount = restoredCount

	log("Restored", restoredCount, "of", #tileIds, "tiles for", player.Name)

	-- Update front desk if possible
	task.spawn(function()
		task.wait(1)
		pcall(function()
			-- Try to set up front desk GUI
			local frontDesk = tycoon.Value:FindFirstChild("Front Desk")
			if frontDesk then
				-- Create basic GUI manually if needed
				if not frontDesk:FindFirstChild("BillboardGui") then
					local billboardGui = Instance.new("BillboardGui")
					billboardGui.Name = "BillboardGui"
					billboardGui.Size = UDim2.new(3, 0, 2, 0)
					billboardGui.StudsOffset = Vector3.new(0, 3, 0)
					billboardGui.Adornee = frontDesk
					billboardGui.Parent = frontDesk

					local frame = Instance.new("Frame")
					frame.Size = UDim2.new(1, 0, 1, 0)
					frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
					frame.BackgroundTransparency = 0.5
					frame.Parent = billboardGui

					local textLabel = Instance.new("TextLabel")
					textLabel.Name = "DuesLabel"
					textLabel.Size = UDim2.new(1, 0, 0.5, 0)
					textLabel.Position = UDim2.new(0, 0, 0.25, 0)
					textLabel.BackgroundTransparency = 1
					textLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
					textLabel.TextScaled = true
					textLabel.Font = Enum.Font.GothamBold
					textLabel.Text = "Membership Dues: $" .. (data.accruedDues or 0)
					textLabel.Parent = frame

					log("Created front desk GUI for", player.Name)
				end
			end
		end)
	end)

	return true
end

-- Start auto-save for player
function DataManager.startAutoSave(player)
	if not player then return false end
	local userId = player.UserId

	-- Stop existing auto-save if running
	DataManager.stopAutoSave(player)

	-- Start new auto-save thread
	DataManager.savers[userId] = true

	task.spawn(function()
		while player and player.Parent and DataManager.savers[userId] do
			task.wait(CONFIG.saveInterval)

			-- Only save if player is still in game
			if player and player.Parent then
				DataManager.saveData(player, false)
			else
				-- Player left, stop auto-save
				DataManager.savers[userId] = nil
				break
			end
		end
	end)

	log("Started auto-save for", player.Name)
	return true
end

-- Stop auto-save for player
function DataManager.stopAutoSave(player)
	if not player then return false end
	local userId = player.UserId

	if DataManager.savers[userId] then
		DataManager.savers[userId] = nil
		log("Stopped auto-save for", player.Name)
		return true
	end

	return false
end

-- Create EventBridge for system communication
function DataManager.ensureEventBridge()
	if not ReplicatedStorage:FindFirstChild("EventBridge") then
		local eventBridge = Instance.new("Folder")
		eventBridge.Name = "EventBridge"
		eventBridge.Parent = ReplicatedStorage
		log("Created EventBridge in ReplicatedStorage")
	end

	local eventBridge = ReplicatedStorage.EventBridge

	-- Create common events
	local events = {
		"TilePurchased",
		"DuesCollected",
		"NPCSpawned",
		"GymLevelUp"
	}

	for _, eventName in ipairs(events) do
		if not eventBridge:FindFirstChild(eventName) then
			local event = Instance.new("BindableEvent")
			event.Name = eventName
			event.Parent = eventBridge
			log("Created event:", eventName)
		end
	end

	return eventBridge
end

-- Set up player
function DataManager.setupPlayer(player)
	if not player then return false end

	-- Load data
	local data = DataManager.loadData(player)
	if not data then
		warn("Failed to load data for", player.Name)
		return false
	end

	-- Apply data to player
	DataManager.applyDataToPlayer(player)

	-- Wait for tycoon to be fully set up
	task.delay(3, function()
		if player and player.Parent then
			DataManager.restorePurchasedEquipment(player)
		end
	end)

	return true
end

-- Connect events
function DataManager.connectEvents()
	-- Create EventBridge
	DataManager.ensureEventBridge()

	-- Connect to TilePurchased event
	local eventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
	if eventBridge then
		local tilePurchasedEvent = eventBridge:FindFirstChild("TilePurchased")
		if tilePurchasedEvent then
			tilePurchasedEvent.Event:Connect(function(player, tileId)
				DataManager.recordEquipmentPurchase(player, tileId)
			end)
			log("Connected to TilePurchased event")
		end
	end

	-- Connect to player joining
	Players.PlayerAdded:Connect(function(player)
		task.delay(2, function()
			DataManager.setupPlayer(player)
		end)
	end)

	-- Connect to player leaving
	Players.PlayerRemoving:Connect(function(player)
		-- Save data immediately
		DataManager.saveData(player, true)

		-- Create backup
		DataManager.createBackup(player)

		-- Stop auto-save
		DataManager.stopAutoSave(player)

		-- Clear from cache
		local userId = player.UserId
		DataManager.loaded[userId] = nil

		log("Cleaned up for leaving player:", player.Name)
	end)

	-- Connect to game closing
	game:BindToClose(function()
		log("Game closing, saving all player data...")

		-- Save for all players
		for _, player in pairs(Players:GetPlayers()) do
			DataManager.saveData(player, true)
		end

		-- Allow time for saves to complete
		task.wait(5)
	end)

	log("Events connected")
	return true
end

-- Check for and fix common issues
function DataManager.fixCommonIssues()
	-- Create AccruedDues folder if missing
	if not ReplicatedStorage:FindFirstChild("AccruedDues") then
		local accruedDues = Instance.new("Folder")
		accruedDues.Name = "AccruedDues"
		accruedDues.Parent = ReplicatedStorage
		log("Created 'AccruedDues' folder in ReplicatedStorage")
	end

	-- Create GymParts folder if missing
	local ServerStorage = game:GetService("ServerStorage")
	if not ServerStorage:FindFirstChild("GymParts") and not workspace:FindFirstChild("GymParts") then
		local gymParts = Instance.new("Folder")
		gymParts.Name = "GymParts"
		gymParts.Parent = ServerStorage
		log("Created 'GymParts' folder in ServerStorage")
	end

	-- Create BuyTiles folder if missing
	if not ServerStorage:FindFirstChild("BuyTiles") and not workspace:FindFirstChild("BuyTiles") then
		local buyTiles = Instance.new("Folder")
		buyTiles.Name = "BuyTiles"
		buyTiles.Parent = ServerStorage
		log("Created 'BuyTiles' folder in ServerStorage")
	end

	log("Fixed common issues")
	return true
end

-- Initialize the system
DataManager.init()
DataManager.connectEvents()
DataManager.fixCommonIssues()

-- Set up for existing players
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		DataManager.setupPlayer(player)
	end)
end

return DataManager