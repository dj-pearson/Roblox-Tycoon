--!strict
--[[
    DataAccessLayer.server.luau
    
    Unified data access layer that provides a standardized interface for all data operations.
    This layer coordinates between different data systems and ensures consistent data access.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Major overhaul for improved reliability
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Import CoreRegistry
local CoreRegistry = require(script.Parent.CoreRegistry)

-- Configuration
local CONFIG = {
    debug = true,
    maxRetries = 3,
    retryDelay = 1, -- seconds
    autoSaveInterval = 60, -- seconds
    sessionLockTimeout = 600, -- seconds
    dataStoreName = "GymTycoonData_v2",
    backupStoreName = "GymTycoonBackup_v2",
    defaultData = {
        version = 2,
        cash = 100,
        experience = 0,
        level = 1,
        ownedItems = {},
        stats = {
            totalPlayTime = 0,
            totalVisitors = 0,
            tilesUnlocked = 0
        },
        settings = {
            musicVolume = 0.5,
            sfxVolume = 0.5,
            notifications = true
        },
        achievements = {},
        lastLogin = 0
    }
}

-- DataAccessLayer module
local DataAccessLayer = {
    Version = "2.0.0",
    initialized = false,
    dataStore = nil,
    backupStore = nil,
    playerData = {},
    saveInProgress = {},
    sessionLocks = {},
    saveQueue = {},
    stats = {
        loads = 0,
        saves = 0,
        errors = 0,
        cacheHits = 0
    }
}

-- Debug logging
local function log(message, level)
    if CONFIG.debug then
        local prefix = "[DataAccessLayer]"
        if level == "error" then
            warn(prefix .. " ERROR: " .. message)
        elseif level == "warn" then
            warn(prefix .. " WARNING: " .. message)
        else
            print(prefix .. " " .. message)
        end
    end
end

-- Safe DataStore operation with retries
local function safeDataStoreOperation(operation)
    local success, result
    local attempts = 0
    
    repeat
        attempts = attempts + 1
        success, result = pcall(operation)
        
        if not success then
            log("DataStore operation failed: " .. tostring(result), "error")
            task.wait(CONFIG.retryDelay)
        end
    until success or attempts >= CONFIG.maxRetries
    
    return success, result
end

-- Deep copy a table
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

-- Validate player data
local function validatePlayerData(data)
    if not data then return CONFIG.defaultData end
    
    -- Ensure all required fields exist
    for key, defaultValue in pairs(CONFIG.defaultData) do
        if data[key] == nil then
            data[key] = deepCopy(defaultValue)
        elseif type(data[key]) == "table" and type(defaultValue) == "table" then
            -- Recursively validate nested tables
            for subKey, subDefault in pairs(defaultValue) do
                if data[key][subKey] == nil then
                    data[key][subKey] = deepCopy(subDefault)
                end
            end
        end
    end
    
    return data
end

-- Initialize DataAccessLayer
function DataAccessLayer:Initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing DataAccessLayer v" .. self.Version)
    
    -- Initialize data stores
    local success, mainStore = safeDataStoreOperation(function()
        return DataStoreService:GetDataStore(CONFIG.dataStoreName)
    end)
    
    if not success then
        log("Failed to initialize main data store", "error")
        return false
    end
    
    self.dataStore = mainStore
    
    -- Initialize backup store
    local _, backupStore = safeDataStoreOperation(function()
        return DataStoreService:GetDataStore(CONFIG.backupStoreName)
    end)
    
    if backupStore then
        self.backupStore = backupStore
        log("Backup data store initialized")
    end
    
    -- Register with CoreRegistry
    if CoreRegistry then
        CoreRegistry.registerSystem("DataAccessLayer", self)
        log("Registered with CoreRegistry")
    end
    
    -- Set up auto-save
    task.spawn(function()
        while true do
            task.wait(CONFIG.autoSaveInterval)
            self:SaveAllPlayerData()
        end
    end)
    
    -- Set up player events
    Players.PlayerAdded:Connect(function(player)
        self:LoadPlayerData(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:SavePlayerData(player, true)
    end)
    
    -- Set up game shutdown handler
    game:BindToClose(function()
        self:HandleShutdown()
    end)
    
    self.initialized = true
    log("DataAccessLayer initialized successfully")
    return true
end

-- Load player data
function DataAccessLayer:LoadPlayerData(player)
    if not self.initialized then
        log("DataAccessLayer not initialized", "error")
        return nil
    end
    
    local userId = player.UserId
    
    -- Check if already loaded
    if self.playerData[userId] then
        self.stats.cacheHits += 1
        return deepCopy(self.playerData[userId])
    end
    
    -- Try to load from DataStore
    local success, data = safeDataStoreOperation(function()
        return self.dataStore:GetAsync(userId)
    end)
    
    if not success then
        log("Failed to load data for player " .. userId, "error")
        return CONFIG.defaultData
    end
    
    -- Validate and store data
    data = validatePlayerData(data)
    self.playerData[userId] = data
    self.stats.loads += 1
    
    -- Update last login
    data.lastLogin = os.time()
    
    log("Loaded data for player " .. userId)
    return deepCopy(data)
end

-- Save player data
function DataAccessLayer:SavePlayerData(player, immediate)
    if not self.initialized then
        log("DataAccessLayer not initialized", "error")
        return false
    end
    
    local userId = player.UserId
    
    -- Check if save is already in progress
    if self.saveInProgress[userId] then
        if not immediate then
            -- Queue the save
            self.saveQueue[userId] = true
            return true
        end
        return false
    end
    
    -- Get player data
    local data = self.playerData[userId]
    if not data then
        log("No data to save for player " .. userId, "warn")
        return false
    end
    
    -- Mark save as in progress
    self.saveInProgress[userId] = true
    
    -- Save to DataStore
    local success = safeDataStoreOperation(function()
        self.dataStore:SetAsync(userId, data)
    end)
    
    -- Create backup if available
    if success and self.backupStore then
        safeDataStoreOperation(function()
            self.backupStore:SetAsync(userId, data)
        end)
    end
    
    -- Clear save in progress flag
    self.saveInProgress[userId] = nil
    
    if success then
        self.stats.saves += 1
        log("Saved data for player " .. userId)
    else
        self.stats.errors += 1
        log("Failed to save data for player " .. userId, "error")
    end
    
    return success
end

-- Save all player data
function DataAccessLayer:SaveAllPlayerData()
    if not self.initialized then
        log("DataAccessLayer not initialized", "error")
        return false
    end
    
    local success = true
    local savedCount = 0
    
    for _, player in ipairs(Players:GetPlayers()) do
        if self:SavePlayerData(player) then
            savedCount += 1
        else
            success = false
        end
    end
    
    log("Saved data for " .. savedCount .. " players")
    return success
end

-- Update player data
function DataAccessLayer:UpdatePlayerData(player, key, value)
    if not self.initialized then
        log("DataAccessLayer not initialized", "error")
        return false
    end
    
    local userId = player.UserId
    local data = self.playerData[userId]
    
    if not data then
        log("No data to update for player " .. userId, "warn")
        return false
    end
    
    -- Update the data
    if type(key) == "table" then
        -- Merge tables
        for k, v in pairs(key) do
            data[k] = v
        end
    else
        data[key] = value
    end
    
    -- Queue save
    self.saveQueue[userId] = true
    return true
end

-- Handle game shutdown
function DataAccessLayer:HandleShutdown()
    if not self.initialized then
        return
    end
    
    log("Handling game shutdown")
    
    -- Save all player data
    self:SaveAllPlayerData()
    
    -- Clear all data
    self.playerData = {}
    self.saveInProgress = {}
    self.sessionLocks = {}
    self.saveQueue = {}
    
    log("Shutdown complete")
end

-- Get player data
function DataAccessLayer:GetPlayerData(player)
    if not self.initialized then
        log("DataAccessLayer not initialized", "error")
        return nil
    end
    
    local userId = player.UserId
    local data = self.playerData[userId]
    
    if not data then
        data = self:LoadPlayerData(player)
    end
    
    return data and deepCopy(data) or nil
end

-- Get all player data
function DataAccessLayer:GetAllPlayerData()
    if not self.initialized then
        log("DataAccessLayer not initialized", "error")
        return {}
    end
    
    local allData = {}
    for userId, data in pairs(self.playerData) do
        allData[userId] = deepCopy(data)
    end
    
    return allData
end

-- Get stats
function DataAccessLayer:GetStats()
    return deepCopy(self.stats)
end

-- Check if initialized
function DataAccessLayer:IsInitialized()
    return self.initialized
end

-- Check if healthy
function DataAccessLayer:IsHealthy()
    if not self.initialized then
        return false
    end
    
    -- Check if data store is available
    local success = safeDataStoreOperation(function()
        return self.dataStore:GetAsync("health_check")
    end)
    
    return success
end

-- Recover from failure
function DataAccessLayer:Recover()
    if not self.initialized then
        return self:Initialize()
    end
    
    log("Attempting recovery")
    
    -- Reinitialize data stores
    local success, mainStore = safeDataStoreOperation(function()
        return DataStoreService:GetDataStore(CONFIG.dataStoreName)
    end)
    
    if success then
        self.dataStore = mainStore
        log("Recovered main data store")
    else
        log("Failed to recover main data store", "error")
        return false
    end
    
    -- Try to recover backup store
    local _, backupStore = safeDataStoreOperation(function()
        return DataStoreService:GetDataStore(CONFIG.backupStoreName)
    end)
    
    if backupStore then
        self.backupStore = backupStore
        log("Recovered backup data store")
    end
    
    return true
end

return DataAccessLayer
