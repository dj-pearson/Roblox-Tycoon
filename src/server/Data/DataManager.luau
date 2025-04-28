-- DataManager.luau
-- Centralized system for managing persistent data storage and retrieval
-- Created: April 28, 2025

local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Constants and configuration
local VERSION = "1.0.0"
local DEBUG = true
local SCOPE_PREFIX = "GymTycoon_"
local SAVE_INTERVAL = 30 -- seconds
local AUTO_RETRY_COUNT = 3
local AUTO_RETRY_DELAY = 2 -- seconds
local DATA_VERSION = 2 -- Increment when data structure changes
local DEFAULT_TIMEOUT = 10 -- seconds

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" then return end
	print(string.format("[DataManager][%s] %s", level, message))
end

-- Get CoreRegistry if available
local function getCoreRegistry()
	local core = ServerScriptService:FindFirstChild("Core")
	if not core or not core:FindFirstChild("CoreRegistry") then
		return nil
	end
	
	local success, result = pcall(function()
		return require(core:FindFirstChild("CoreRegistry"))
	end)
	
	if success then
		return result
	else
		return nil
	end
end

-- Safe wait for child function with timeout
local function safeWaitForChild(parent, childName, timeout)
	timeout = timeout or DEFAULT_TIMEOUT
	local startTime = os.clock()
	
	while os.clock() - startTime < timeout do
		local child = parent:FindFirstChild(childName)
		if child then
			return child
		end
		wait(0.1)
	end
	
	return nil -- Timed out
end

-- DataManager object
local DataManager = {
	_version = VERSION,
	_stores = {}, -- DataStore instances
	_cache = {}, -- In-memory data cache
	_pendingSaves = {}, -- Data that needs to be saved
	_playerData = {}, -- Player-specific data
	_autosaveConnection = nil, -- Connection for autosave
	_sessionIds = {}, -- Track active sessions
	_stats = {
		loads = 0,
		saves = 0,
		errors = 0,
		cacheHits = 0
	},
	_initialized = false
}

-- Default data templates
DataManager._defaultData = {
	player = {
		version = DATA_VERSION,
		lastLoginTime = 0,
		coins = 0,
		gems = 0,
		experience = 0,
		level = 1,
		achievements = {},
		inventory = {},
		settings = {
			musicVolume = 0.5,
			effectsVolume = 0.5,
			cameraDistance = 20,
			colorBlindMode = false
		}
	},
	gym = {
		version = DATA_VERSION,
		name = "My Gym",
		level = 1,
		facilities = {},
		staff = {},
		customers = {},
		revenue = 0,
		reputation = 0,
		specializations = {},
		upgrades = {}
	},
	global = {
		version = DATA_VERSION,
		serverVersion = VERSION,
		eventSchedule = {},
		competitionHistory = {},
		leaderboards = {},
		announcementTimestamp = 0
	}
}

-- Generate a unique session ID
local function generateSessionId(userId)
	return tostring(userId) .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
end

-- Validate data against template
local function validateData(data, template)
	if not data then
		return table.clone(template)
	end
	
	-- Check version
	if not data.version or data.version < template.version then
		-- Data migration would go here
		log("Data version mismatch, upgrading from " .. tostring(data.version) .. " to " .. tostring(template.version))
	end
	
	-- Ensure all template fields exist in data
	for key, defaultValue in pairs(template) do
		if key ~= "version" and data[key] == nil then
			data[key] = defaultValue
		end
		
		-- Recursively validate nested tables
		if type(defaultValue) == "table" and type(data[key]) == "table" then
			data[key] = validateData(data[key], defaultValue)
		end
	end
	
	-- Update version
	data.version = template.version
	
	return data
end

-- Initialize DataManager
function DataManager:Initialize()
	if self._initialized then
		return true
	end
	
	log("Initializing DataManager v" .. VERSION)
	
	-- Connect to DataStoreService with error handling
	self:SetupDataStores()
	
	-- Start autosave timer
	self:StartAutosaveTimer()
	
	-- Connect player events
	self:ConnectPlayerEvents()
	
	-- Register with CoreRegistry if available
	local coreRegistry = getCoreRegistry()
	if coreRegistry then
		coreRegistry:Register("DataManager", self)
		log("Registered with CoreRegistry")
	else
		log("CoreRegistry not available, skipping registration", "Warning")
	end
	
	self._initialized = true
	log("DataManager initialized successfully")
	return true
end

-- Set up data stores
function DataManager:SetupDataStores()
	log("Setting up data stores")
	
	-- Define store names with proper scoping
	local storeNames = {
		player = SCOPE_PREFIX .. "PlayerData",
		gym = SCOPE_PREFIX .. "GymData",
		global = SCOPE_PREFIX .. "GlobalData"
	}
	
	-- Attempt to get each data store
	for key, name in pairs(storeNames) do
		local success, result = pcall(function()
			return DataStoreService:GetDataStore(name)
		end)
		
		if success then
			self._stores[key] = result
			log("Successfully created data store: " .. name)
		else
			self._stores[key] = nil
			log("Failed to create data store: " .. name .. " - " .. tostring(result), "Error")
			self._stats.errors += 1
		end
	end
	
	return true
end

-- Start autosave timer
function DataManager:StartAutosaveTimer()
	log("Starting autosave timer")
	
	-- Clear existing connection if any
	if self._autosaveConnection then
		self._autosaveConnection:Disconnect()
		self._autosaveConnection = nil
	end
	
	-- Create new timer
	spawn(function()
		while true do
			wait(SAVE_INTERVAL)
			self:AutosaveAllData()
		end
	end)
	
	log("Autosave timer started with interval: " .. SAVE_INTERVAL .. " seconds")
	return true
end

-- Connect player events
function DataManager:ConnectPlayerEvents()
	log("Connecting player events")
	
	-- Handle player joining
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerJoined(player)
	end)
	
	-- Handle player leaving
	Players.PlayerRemoving:Connect(function(player)
		self:OnPlayerLeaving(player)
	end)
	
	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do
		spawn(function()
			self:OnPlayerJoined(player)
		end)
	end
	
	log("Player events connected")
	return true
end

-- Handle player joining
function DataManager:OnPlayerJoined(player)
	log("Player joined: " .. player.Name .. " (" .. player.UserId .. ")")
	
	-- Generate a new session ID
	local sessionId = generateSessionId(player.UserId)
	self._sessionIds[player.UserId] = sessionId
	
	-- Load player data
	spawn(function()
		local success, playerData = self:LoadPlayerData(player.UserId)
		
		-- If the player's session changed while loading data, abort
		if self._sessionIds[player.UserId] ~= sessionId then
			log("Session changed for player " .. player.Name .. ", aborting data load")
			return
		end
		
		if success then
			self._playerData[player.UserId] = playerData
			log("Successfully loaded data for player: " .. player.Name)
			
			-- Update last login time
			playerData.lastLoginTime = os.time()
			self:MarkForSave("player", player.UserId)
			
			-- Fire player data loaded event
			self:FireEvent("PlayerDataLoaded", player, playerData)
		else
			log("Failed to load data for player: " .. player.Name, "Error")
			
			-- Create new data for the player
			local newData = table.clone(self._defaultData.player)
			newData.lastLoginTime = os.time()
			self._playerData[player.UserId] = newData
			self:MarkForSave("player", player.UserId)
			
			-- Fire player data created event
			self:FireEvent("PlayerDataCreated", player, newData)
		end
	end)
end

-- Handle player leaving
function DataManager:OnPlayerLeaving(player)
	log("Player leaving: " .. player.Name .. " (" .. player.UserId .. ")")
	
	-- Save player data one last time
	local success, _ = self:SavePlayerData(player.UserId)
	if success then
		log("Successfully saved data for leaving player: " .. player.Name)
	else
		log("Failed to save data for leaving player: " .. player.Name, "Error")
	end
	
	-- Clean up player data from memory
	self._playerData[player.UserId] = nil
	self._pendingSaves.player = self._pendingSaves.player or {}
	self._pendingSaves.player[player.UserId] = nil
	self._sessionIds[player.UserId] = nil
end

-- Fire an event through CoreRegistry if available
function DataManager:FireEvent(eventName, ...)
	local coreRegistry = getCoreRegistry()
	if coreRegistry and coreRegistry.FireEvent then
		coreRegistry:FireEvent(eventName, ...)
	end
end

-- Load player data
function DataManager:LoadPlayerData(userId)
	if not userId then
		return false, "User ID is nil"
	end
	
	-- Check if we already have this data in memory
	if self._playerData[userId] then
		self._stats.cacheHits += 1
		return true, self._playerData[userId]
	end
	
	-- Get the player data store
	local playerStore = self._stores.player
	if not playerStore then
		return false, "Player data store not available"
	end
	
	-- Attempt to load from data store
	local success, result = pcall(function()
		return playerStore:GetAsync("User_" .. userId)
	end)
	
	self._stats.loads += 1
	
	if success then
		-- Validate and update data structure
		local validatedData = validateData(result, self._defaultData.player)
		log("Loaded data for user: " .. userId)
		return true, validatedData
	else
		self._stats.errors += 1
		log("Failed to load data for user: " .. userId .. " - " .. tostring(result), "Error")
		return false, result
	end
end

-- Save player data
function DataManager:SavePlayerData(userId)
	if not userId then
		return false, "User ID is nil"
	end
	
	-- Check if we have data to save
	if not self._playerData[userId] then
		return false, "No data found for user"
	end
	
	-- Get the player data store
	local playerStore = self._stores.player
	if not playerStore then
		return false, "Player data store not available"
	end
	
	-- Get the data to save
	local dataToSave = self._playerData[userId]
	
	-- Attempt to save to data store
	local success, result
	
	-- Try multiple times if needed
	for attempt = 1, AUTO_RETRY_COUNT do
		success, result = pcall(function()
			return playerStore:SetAsync("User_" .. userId, dataToSave)
		end)
		
		if success then
			break
		else
			if attempt < AUTO_RETRY_COUNT then
				log("Save attempt " .. attempt .. " failed, retrying in " .. AUTO_RETRY_DELAY .. " seconds", "Warning")
				wait(AUTO_RETRY_DELAY)
			end
		end
	end
	
	self._stats.saves += 1
	
	if success then
		log("Saved data for user: " .. userId)
		
		-- Clean up pending save
		self._pendingSaves.player = self._pendingSaves.player or {}
		self._pendingSaves.player[userId] = nil
		
		return true, nil
	else
		self._stats.errors += 1
		log("Failed to save data for user: " .. userId .. " - " .. tostring(result), "Error")
		return false, result
	end
end

-- Mark data for saving
function DataManager:MarkForSave(storeType, key)
	if not storeType or not key then
		return false
	end
	
	-- Initialize pending saves table if needed
	self._pendingSaves[storeType] = self._pendingSaves[storeType] or {}
	
	-- Mark for save
	self._pendingSaves[storeType][key] = true
	
	return true
end

-- Autosave all pending data
function DataManager:AutosaveAllData()
	log("Running autosave...")
	
	-- Save player data
	if self._pendingSaves.player then
		for userId, _ in pairs(self._pendingSaves.player) do
			-- Check if player is still on the server
			local playerStillConnected = false
			for _, player in ipairs(Players:GetPlayers()) do
				if player.UserId == userId then
					playerStillConnected = true
					break
				end
			end
			
			if playerStillConnected then
				self:SavePlayerData(userId)
			else
				-- Player gone, remove from pending saves
				self._pendingSaves.player[userId] = nil
			end
		end
	end
	
	-- TODO: Add other data types as needed
	
	log("Autosave complete")
end

-- Get player data
function DataManager:GetPlayerData(userId)
	if not userId then
		return nil
	end
	
	return self._playerData[userId]
end

-- Update player data
function DataManager:UpdatePlayerData(userId, dataPath, newValue)
	if not userId or not dataPath then
		return false, "Missing parameters"
	end
	
	-- Get current data
	local playerData = self._playerData[userId]
	if not playerData then
		return false, "No data found for user"
	end
	
	-- Parse data path
	local pathParts = string.split(dataPath, ".")
	
	-- Navigate to the correct location
	local current = playerData
	for i = 1, #pathParts - 1 do
		local part = pathParts[i]
		if not current[part] then
			current[part] = {}
		end
		current = current[part]
	end
	
	-- Update value
	local lastPart = pathParts[#pathParts]
	current[lastPart] = newValue
	
	-- Mark for save
	self:MarkForSave("player", userId)
	
	return true
end

-- Increment a player data value
function DataManager:IncrementPlayerData(userId, dataPath, amount)
	if not userId or not dataPath then
		return false, "Missing parameters"
	end
	
	-- Default amount to 1 if not specified
	amount = amount or 1
	
	-- Get current data
	local playerData = self._playerData[userId]
	if not playerData then
		return false, "No data found for user"
	end
	
	-- Parse data path
	local pathParts = string.split(dataPath, ".")
	
	-- Navigate to the correct location
	local current = playerData
	for i = 1, #pathParts - 1 do
		local part = pathParts[i]
		if not current[part] then
			current[part] = {}
		end
		current = current[part]
	end
	
	-- Get last part
	local lastPart = pathParts[#pathParts]
	
	-- Ensure current value is a number
	if type(current[lastPart]) ~= "number" then
		current[lastPart] = 0
	end
	
	-- Increment value
	current[lastPart] += amount
	
	-- Mark for save
	self:MarkForSave("player", userId)
	
	return true, current[lastPart]
end

-- Load global data
function DataManager:LoadGlobalData(key)
	if not key then
		return false, "Key is nil"
	end
	
	-- Check if we already have this data in cache
	if self._cache.global and self._cache.global[key] then
		self._stats.cacheHits += 1
		return true, self._cache.global[key]
	end
	
	-- Get the global data store
	local globalStore = self._stores.global
	if not globalStore then
		return false, "Global data store not available"
	end
	
	-- Attempt to load from data store
	local success, result = pcall(function()
		return globalStore:GetAsync(key)
	end)
	
	self._stats.loads += 1
	
	if success then
		-- Initialize cache if needed
		self._cache.global = self._cache.global or {}
		
		-- Cache the result
		self._cache.global[key] = result
		
		log("Loaded global data for key: " .. key)
		return true, result
	else
		self._stats.errors += 1
		log("Failed to load global data for key: " .. key .. " - " .. tostring(result), "Error")
		return false, result
	end
end

-- Save global data
function DataManager:SaveGlobalData(key, data)
	if not key then
		return false, "Key is nil"
	end
	
	-- Get the global data store
	local globalStore = self._stores.global
	if not globalStore then
		return false, "Global data store not available"
	end
	
	-- Update cache
	self._cache.global = self._cache.global or {}
	self._cache.global[key] = data
	
	-- Attempt to save to data store
	local success, result
	
	-- Try multiple times if needed
	for attempt = 1, AUTO_RETRY_COUNT do
		success, result = pcall(function()
			return globalStore:SetAsync(key, data)
		end)
		
		if success then
			break
		else
			if attempt < AUTO_RETRY_COUNT then
				log("Save attempt " .. attempt .. " failed, retrying in " .. AUTO_RETRY_DELAY .. " seconds", "Warning")
				wait(AUTO_RETRY_DELAY)
			end
		end
	end
	
	self._stats.saves += 1
	
	if success then
		log("Saved global data for key: " .. key)
		return true, nil
	else
		self._stats.errors += 1
		log("Failed to save global data for key: " .. key .. " - " .. tostring(result), "Error")
		return false, result
	end
end

-- Get DataManager statistics
function DataManager:GetStats()
	return {
		version = self._version,
		initialized = self._initialized,
		loads = self._stats.loads,
		saves = self._stats.saves,
		errors = self._stats.errors,
		cacheHits = self._stats.cacheHits,
		playerDataCount = 0, -- Calculated below
		pendingSaves = 0 -- Calculated below
	}
end

-- Get the data manager version
function DataManager:GetVersion()
	return self._version
end

-- Initialize the DataManager
DataManager:Initialize()

return DataManager
