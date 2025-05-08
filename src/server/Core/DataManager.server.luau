--!strict
--[[
    DataManager.server.luau
    
    Core system for managing data persistence and access.
    This module handles data storage, retrieval, and caching.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Unified implementation with CoreRegistry integration
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Import CoreRegistry
local CoreRegistry = require(script.Parent.CoreRegistry)

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

-- DataManager module
local DataManager = {
    initialized = false,
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
        cacheHits = 0
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

-- Initialize the DataManager
function DataManager:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing DataManager...")
    
    -- Create data stores
    local success, mainDataStore = safeDataStoreOperation(function()
        return DataStoreService:GetDataStore(CONFIG.DATA_STORE_NAME)
    end)
    
    if not success then
        log("Failed to initialize main data store", "Error")
        return false
    end
    
    self.dataStore = mainDataStore
    log("Main data store initialized")
    
    -- Set up backup data store
    local _, backupDataStore = safeDataStoreOperation(function()
        return DataStoreService:GetDataStore(CONFIG.BACKUP_DATA_STORE_NAME)
    end)
    
    if backupDataStore then
        self.backupDataStore = backupDataStore
        log("Backup data store initialized")
    end
    
    -- Set up auto-saving
    task.spawn(function()
        while true do
            task.wait(CONFIG.AUTO_SAVE_INTERVAL)
            self:saveAllPlayerData(false)
        end
    end)
    
    -- Set up player events
    Players.PlayerAdded:Connect(function(player)
        self:onPlayerJoin(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:onPlayerLeave(player)
    end)
    
    -- Handle server shutdown
    game:BindToClose(function()
        self:onServerShutdown()
    end)
    
    self.initialized = true
    log("DataManager initialized successfully")
    return true
end

-- Load player data
function DataManager:loadPlayerData(player)
    if not self.dataStore then
        log("Data store not initialized", "Error")
        return false
    end
    
    -- Check cache first
    if self.dataCache[player.UserId] then
        local cacheTime = self.cacheTimestamps[player.UserId]
        if cacheTime and os.time() - cacheTime < CONFIG.CACHE_TTL then
            self.stats.cacheHits += 1
            return true
        end
    end
    
    -- Load from data store
    local success, result = safeDataStoreOperation(function()
        return self.dataStore:GetAsync(tostring(player.UserId))
    end)
    
    if success then
        -- Validate and store data
        self.playerData[player.UserId] = validateData(result)
        self.dataCache[player.UserId] = true
        self.cacheTimestamps[player.UserId] = os.time()
        self.stats.loads += 1
        log("Successfully loaded data for " .. player.Name)
        return true
    else
        log("Failed to load data for " .. player.Name .. ": " .. tostring(result), "Error")
        self.stats.errors += 1
        return false
    end
end

-- Save player data
function DataManager:savePlayerData(player, immediate)
    if not self.dataStore then
        log("Data store not initialized", "Error")
        return false
    end
    
    if not self.playerData[player.UserId] then
        log("No data to save for " .. player.Name, "Warning")
        return false
    end
    
    if self.saveInProgress[player.UserId] then
        log("Save already in progress for " .. player.Name, "Warning")
        return false
    end
    
    self.saveInProgress[player.UserId] = true
    
    local success, result = safeDataStoreOperation(function()
        return self.dataStore:SetAsync(tostring(player.UserId), self.playerData[player.UserId])
    end)
    
    self.saveInProgress[player.UserId] = nil
    
    if success then
        self.stats.saves += 1
        log("Successfully saved data for " .. player.Name)
        return true
    else
        log("Failed to save data for " .. player.Name .. ": " .. tostring(result), "Error")
        self.stats.errors += 1
        return false
    end
end

-- Save all player data
function DataManager:saveAllPlayerData(immediate)
    log("Saving all player data...")
    local savedCount = 0
    
    for _, player in ipairs(Players:GetPlayers()) do
        if self.playerData[player.UserId] and not self.saveInProgress[player.UserId] then
            if self:savePlayerData(player, immediate) then
                savedCount += 1
            end
        end
    end
    
    log("Saved data for " .. savedCount .. " players")
    return savedCount
end

-- Get player data
function DataManager:getPlayerData(player)
    return self.playerData[player.UserId]
end

-- Update player data
function DataManager:updatePlayerData(player, updateFunction)
    if not self.playerData[player.UserId] then
        return false
    end
    
    local success, result = pcall(function()
        return updateFunction(self.playerData[player.UserId])
    end)
    
    if success then
        return true
    else
        log("Failed to update data for " .. player.Name .. ": " .. tostring(result), "Error")
        self.stats.errors += 1
        return false
    end
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
end

-- Server shutdown handler
function DataManager:onServerShutdown()
    log("Server shutting down, saving all player data...")
    self:saveAllPlayerData(true)
end

-- Get statistics
function DataManager:getStats()
    return {
        loads = self.stats.loads,
        saves = self.stats.saves,
        errors = self.stats.errors,
        cacheHits = self.stats.cacheHits,
        playerCount = #Players:GetPlayers(),
        cacheSize = #self.dataCache
    }
end

-- Initialize the DataManager
DataManager:initialize()

-- Register with CoreRegistry
if CoreRegistry then
    CoreRegistry.registerSystem("DataManager", DataManager)
    log("Registered with CoreRegistry")
end

return DataManager
