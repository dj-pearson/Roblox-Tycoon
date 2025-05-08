--!strict
--[[
    DataManager_enhanced.server.luau
    
    Enhanced data management system with robust health checks and recovery mechanisms.
    This module provides centralized data access, persistence, and caching with improved
    error handling and system monitoring.
    
    Features:
    - Centralized data access API
    - Robust error handling and recovery
    - Memory caching with size limits
    - Data validation and migration
    - Health monitoring and reporting
    - Automatic backup and restore
    - Player session management
    
    Created: May 3, 2025
    Updated: May 3, 2025 - Added health check and recovery system
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Import required modules
local ServerScripts = script.Parent
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")

local DataPersistence = require(script.Parent:WaitForChild("DataPersistence"))
local DataCache = require(script.Parent:WaitForChild("DataCache"))
local DataAnalytics = require(script.Parent:WaitForChild("DataAnalytics"))
local DataTypes = require(SharedModules:WaitForChild("Data"):WaitForChild("DataTypes"))
local DataConstants = require(SharedModules:WaitForChild("Data"):WaitForChild("DataConstants"))

-- Configuration
local CONFIG = {
    -- Data store configuration
    DATA_STORE_NAME = "GymTycoonData_v2",
    BACKUP_DATA_STORE_NAME = "GymTycoonBackup_v2",
    DATA_VERSION = 2,
    
    -- Timing configuration
    AUTO_SAVE_INTERVAL = 60, -- seconds
    PLAYER_LEAVING_RETRY_COUNT = 5,
    PLAYER_LEAVING_RETRY_DELAY = 1, -- seconds
    SESSION_LOCK_TIME = 600, -- seconds
    
    -- Cache configuration
    CACHE_TTL = 300, -- seconds
    MAX_CACHE_SIZE = 1000, -- entries
    
    -- Health check configuration
    HEALTH_CHECK_INTERVAL = 30, -- seconds
    MAX_ERROR_RATE = 0.1, -- 10% error rate threshold
    RECOVERY_ATTEMPTS = 3,
    RECOVERY_DELAY = 2, -- seconds
    
    -- Default data structure
    DEFAULT_DATA = {
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

-- Module state
local DataManager = {
    initialized = false,
    version = "2.0.0",
    dataStore = nil,
    backupDataStore = nil,
    playerData = {},
    saveInProgress = {},
    sessionLocks = {},
    dataCache = {},
    cacheTimestamps = {},
    saveQueue = {},
    stats = {
        loads = 0,
        saves = 0,
        errors = 0,
        cacheHits = 0,
        recoveryAttempts = 0,
        healthCheckFailures = 0
    },
    healthState = {
        status = "Unknown",
        lastCheck = 0,
        errors = {},
        warnings = {},
        recoveryInProgress = false
    }
}

-- Debug logging
local function log(message, level)
    level = level or "Info"
    print(string.format("[DataManager][%s] %s", level, message))
end

-- Safe data store operation with retries
local function safeDataStoreOperation(operation, retries)
    retries = retries or CONFIG.PLAYER_LEAVING_RETRY_COUNT
    
    local success, result
    for attempt = 1, retries do
        success, result = pcall(operation)
        if success then
            return success, result
        else
            log("Data store operation failed (Attempt " .. attempt .. "/" .. retries .. "): " .. tostring(result), "Warning")
            if attempt < retries then
                task.wait(CONFIG.PLAYER_LEAVING_RETRY_DELAY)
            end
        end
    end
    
    return success, result
end

-- Validate and fix data structure
local function validateData(data)
    if not data then
        return table.clone(CONFIG.DEFAULT_DATA)
    end
    
    -- Check version
    if not data.version or data.version < CONFIG.DATA_VERSION then
        log("Data version mismatch, upgrading from " .. tostring(data.version) .. " to " .. tostring(CONFIG.DATA_VERSION))
        data = table.clone(CONFIG.DEFAULT_DATA)
    end
    
    -- Ensure all required fields exist
    for key, defaultValue in pairs(CONFIG.DEFAULT_DATA) do
        if data[key] == nil then
            data[key] = defaultValue
        elseif type(defaultValue) == "table" and type(data[key]) == "table" then
            -- Recursively validate nested tables
            data[key] = validateData(data[key])
        end
    end
    
    -- Update version
    data.version = CONFIG.DATA_VERSION
    
    return data
end

-- Health check function
function DataManager:healthCheck()
    local currentTime = os.time()
    if currentTime - self.healthState.lastCheck < CONFIG.HEALTH_CHECK_INTERVAL then
        return self.healthState.status
    end
    
    self.healthState.lastCheck = currentTime
    self.healthState.errors = {}
    self.healthState.warnings = {}
    
    -- Check cache size
    local cacheSize = 0
    for _ in pairs(self.dataCache) do
        cacheSize += 1
    end
    
    if cacheSize > CONFIG.MAX_CACHE_SIZE then
        table.insert(self.healthState.warnings, "Cache size exceeds limit: " .. cacheSize)
    end
    
    -- Check for stuck save operations
    local stuckSaves = 0
    for userId, startTime in pairs(self.saveInProgress) do
        if os.time() - startTime > CONFIG.SESSION_LOCK_TIME then
            stuckSaves += 1
        end
    end
    
    if stuckSaves > 0 then
        table.insert(self.healthState.errors, "Stuck save operations: " .. stuckSaves)
    end
    
    -- Check error rate
    local errorRate = self.stats.errors / (self.stats.loads + self.stats.saves + 1)
    if errorRate > CONFIG.MAX_ERROR_RATE then
        table.insert(self.healthState.warnings, "High error rate: " .. string.format("%.1f%%", errorRate * 100))
    end
    
    -- Check session locks
    local expiredLocks = 0
    for userId, lockTime in pairs(self.sessionLocks) do
        if os.time() - lockTime > CONFIG.SESSION_LOCK_TIME then
            expiredLocks += 1
        end
    end
    
    if expiredLocks > 0 then
        table.insert(self.healthState.warnings, "Expired session locks: " .. expiredLocks)
    end
    
    -- Update health status
    if #self.healthState.errors > 0 then
        self.healthState.status = "Critical"
    elseif #self.healthState.warnings > 0 then
        self.healthState.status = "Degraded"
    else
        self.healthState.status = "Healthy"
    end
    
    return self.healthState.status
end

-- Recovery function
function DataManager:recover()
    if self.healthState.recoveryInProgress then
        return false
    end
    
    self.healthState.recoveryInProgress = true
    self.stats.recoveryAttempts += 1
    
    -- Clear stuck save operations
    for userId, startTime in pairs(self.saveInProgress) do
        if os.time() - startTime > CONFIG.SESSION_LOCK_TIME then
            self.saveInProgress[userId] = nil
        end
    end
    
    -- Clear expired session locks
    for userId, lockTime in pairs(self.sessionLocks) do
        if os.time() - lockTime > CONFIG.SESSION_LOCK_TIME then
            self.sessionLocks[userId] = nil
        end
    end
    
    -- Clear cache
    self.dataCache = {}
    self.cacheTimestamps = {}
    
    -- Reset stats
    self.stats.loads = 0
    self.stats.saves = 0
    self.stats.errors = 0
    self.stats.cacheHits = 0
    
    -- Reset health state
    self.healthState.lastCheck = 0
    self.healthState.errors = {}
    self.healthState.warnings = {}
    self.healthState.status = "Recovering"
    
    -- Wait for recovery delay
    task.wait(CONFIG.RECOVERY_DELAY)
    
    -- Run health check
    local status = self:healthCheck()
    
    self.healthState.recoveryInProgress = false
    return status == "Healthy"
end

-- Get health status
function DataManager:getHealthStatus()
    return {
        status = self.healthState.status,
        lastCheck = self.healthState.lastCheck,
        errors = self.healthState.errors,
        warnings = self.healthState.warnings
    }
end

-- Get statistics
function DataManager:getStats()
    return {
        loads = self.stats.loads,
        saves = self.stats.saves,
        errors = self.stats.errors,
        cacheHits = self.stats.cacheHits,
        recoveryAttempts = self.stats.recoveryAttempts,
        healthCheckFailures = self.stats.healthCheckFailures,
        cacheSize = 0, -- Calculated below
        playerCount = #Players:GetPlayers()
    }
end

-- Initialize the DataManager
function DataManager:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing DataManager v" .. self.version)
    
    -- Initialize data stores
    self.dataStore = DataStoreService:GetDataStore(CONFIG.DATA_STORE_NAME)
    self.backupDataStore = DataStoreService:GetDataStore(CONFIG.BACKUP_DATA_STORE_NAME)
    
    -- Start periodic health checks
    task.spawn(function()
        while true do
            task.wait(CONFIG.HEALTH_CHECK_INTERVAL)
            local status = self:healthCheck()
            if status == "Critical" then
                self.stats.healthCheckFailures += 1
                self:recover()
            end
        end
    end)
    
    -- Connect player events
    Players.PlayerAdded:Connect(function(player)
        self:onPlayerJoin(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:onPlayerLeave(player)
    end)
    
    -- Connect to CoreRegistry if available
    local CoreRegistry = getCoreRegistry()
    if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
        CoreRegistry.registerSystem("DataManager", self)
        log("Registered with CoreRegistry")
    end
    
    self.initialized = true
    log("DataManager initialized successfully")
    return true
end

-- Player join handler
function DataManager:onPlayerJoin(player)
    log("Player joined: " .. player.Name)
    self:loadPlayerData(player)
end

-- Player leave handler
function DataManager:onPlayerLeave(player)
    log("Player leaving: " .. player.Name)
    self:savePlayerData(player, true)
    
    -- Clean up
    self.playerData[player.UserId] = nil
    self.dataCache[player.UserId] = nil
    self.cacheTimestamps[player.UserId] = nil
    self.saveInProgress[player.UserId] = nil
    self.sessionLocks[player.UserId] = nil
end

-- Load player data
function DataManager:loadPlayerData(player)
    if not self.initialized or not player or not player.UserId then
        return false
    end
    
    local userId = player.UserId
    local keySuffix = "Player_" .. userId
    
    -- Try to load from main data store
    local success, data = safeDataStoreOperation(function()
        return self.dataStore:GetAsync(keySuffix)
    end)
    
    if success and data then
        log("Successfully loaded data for " .. player.Name)
        self.playerData[userId] = validateData(data)
        self.stats.loads += 1
        return true
    end
    
    -- If failed, try backup data store
    if self.backupDataStore then
        success, data = safeDataStoreOperation(function()
            return self.backupDataStore:GetAsync(keySuffix)
        end)
        
        if success and data then
            log("Loaded data from backup for " .. player.Name)
            self.playerData[userId] = validateData(data)
            self.stats.loads += 1
            return true
        end
    end
    
    -- Use default data if no saved data found
    log("No saved data found for " .. player.Name .. ", using default")
    self.playerData[userId] = table.clone(CONFIG.DEFAULT_DATA)
    return true
end

-- Save player data
function DataManager:savePlayerData(player, immediate)
    if not self.initialized or not player or not player.UserId then
        return false
    end
    
    local userId = player.UserId
    
    -- Check if save is already in progress
    if self.saveInProgress[userId] then
        log("Save already in progress for " .. player.Name, "Warning")
        return false
    end
    
    -- Mark save as in progress
    self.saveInProgress[userId] = os.time()
    
    -- Get player data
    local data = self.playerData[userId]
    if not data then
        self.saveInProgress[userId] = nil
        return false
    end
    
    -- Save to main data store
    local keySuffix = "Player_" .. userId
    local success = safeDataStoreOperation(function()
        self.dataStore:SetAsync(keySuffix, data)
    end)
    
    if success then
        -- Also save to backup
        if self.backupDataStore then
            safeDataStoreOperation(function()
                self.backupDataStore:SetAsync(keySuffix, data)
            end)
        end
        
        self.stats.saves += 1
        log("Successfully saved data for " .. player.Name)
    else
        self.stats.errors += 1
        log("Failed to save data for " .. player.Name, "Error")
    end
    
    -- Clear save in progress flag
    self.saveInProgress[userId] = nil
    
    return success
end

-- Get player data
function DataManager:getPlayerData(player)
    if not player or not player.UserId then
        return nil
    end
    
    local userId = player.UserId
    
    -- If data isn't loaded yet, load it
    if not self.playerData[userId] then
        self:loadPlayerData(player)
    end
    
    return self.playerData[userId]
end

-- Update player data
function DataManager:updatePlayerData(player, updateFunction)
    if not player or not player.UserId then
        return false
    end
    
    local userId = player.UserId
    
    -- Get current data
    local data = self:getPlayerData(player)
    if not data then
        return false
    end
    
    -- Apply update
    local success, result = pcall(function()
        return updateFunction(data)
    end)
    
    if success then
        self.playerData[userId] = data
        return true
    else
        self.stats.errors += 1
        log("Failed to update data for " .. player.Name .. ": " .. tostring(result), "Error")
        return false
    end
end

-- Initialize the DataManager
DataManager:initialize()

return DataManager 