--!strict
--[[
    DataManager.server.luau
    
    Core system for managing data persistence and access.
    This module handles data storage, retrieval, and caching.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Fixed initialization and CoreRegistry integration
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Get CoreRegistry
local CoreRegistry
local success, result = pcall(function()
    return require(script.Parent.CoreRegistry)
end)
if success then
    CoreRegistry = result
end

local DataManager = {}
DataManager.initialized = false

-- Configuration
local CONFIG = {
    DATA_STORE_NAME = "GymTycoonData_v2",
    BACKUP_DATA_STORE_NAME = "GymTycoonBackup_v2",
    AUTO_SAVE_INTERVAL = 60, -- seconds
    PLAYER_LEAVING_RETRY_COUNT = 5,
    PLAYER_LEAVING_RETRY_DELAY = 1, -- seconds
    DEFAULT_DATA = {
        cash = 100,
        experience = 0,
        level = 1,
        ownedItems = {},
        stats = {
            totalPlayTime = 0,
            totalVisitors = 0,
            tilesUnlocked = 0
        }
    }
}

-- Debug settings
DataManager.DEBUG = true

-- Player data cache
local playerData = {}
local saveInProgress = {}

-- Log a message to the output
local function log(message)
    if DataManager.DEBUG then
        print("[DataManager] " .. message)
    end
end

-- Safe data store access with retries
local function safeDataStoreOperation(operation, retries)
    retries = retries or 3
    
    local success, result
    for attempt = 1, retries do
        success, result = pcall(operation)
        if success then
            return success, result
        else
            log("Data store operation failed (Attempt " .. attempt .. "/" .. retries .. "): " .. tostring(result))
            if attempt < retries then
                wait(1)
            end
        end
    end
    
    return success, result
end

-- Initialize the data manager
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
        warn("[DataManager] Failed to initialize main data store, data persistence disabled")
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
    else
        log("No backup data store available")
    end
    
    -- Set up auto-saving
    task.spawn(function()
        while true do
            wait(CONFIG.AUTO_SAVE_INTERVAL)
            
            log("Running auto-save...")
            local savedCount = 0
            
            for _, player in ipairs(Players:GetPlayers()) do
                if playerData[player.UserId] and not saveInProgress[player.UserId] then
                    local success = self:savePlayerData(player)
                    if success then
                        savedCount = savedCount + 1
                    end
                end
            end
            
            log("Auto-save complete: Saved " .. savedCount .. " players' data")
        end
    end)
    
    -- Set up player leaving handler
    Players.PlayerRemoving:Connect(function(player)
        self:handlePlayerLeaving(player)
    end)
    
    -- Register with CoreRegistry
    if CoreRegistry and CoreRegistry.registerSystem then
        CoreRegistry:registerSystem("DataManager", self)
        log("Registered with CoreRegistry")
        
        -- Mark as initialized in CoreRegistry
        if CoreRegistry.markInitialized then
            CoreRegistry:markInitialized("DataManager")
            log("Marked as initialized in CoreRegistry")
        end
    end
    
    self.initialized = true
    log("DataManager initialized successfully")
    return true
end

-- Handle player leaving
function DataManager:handlePlayerLeaving(player)
    if not playerData[player.UserId] then
        return
    end
    
    log("Player leaving: " .. player.Name)
    
    -- Try to save data with retries
    for attempt = 1, CONFIG.PLAYER_LEAVING_RETRY_COUNT do
        local success = self:savePlayerData(player)
        if success then
            log("Successfully saved data for " .. player.Name)
            break
        else
            log("Failed to save data for " .. player.Name .. " (Attempt " .. attempt .. "/" .. CONFIG.PLAYER_LEAVING_RETRY_COUNT .. ")")
            if attempt < CONFIG.PLAYER_LEAVING_RETRY_COUNT then
                wait(CONFIG.PLAYER_LEAVING_RETRY_DELAY)
            end
        end
    end
    
    -- Clean up
    playerData[player.UserId] = nil
    saveInProgress[player.UserId] = nil
end

-- Save player data
function DataManager:savePlayerData(player)
    if not playerData[player.UserId] then
        return false
    end
    
    if saveInProgress[player.UserId] then
        return false
    end
    
    saveInProgress[player.UserId] = true
    
    local success, result = safeDataStoreOperation(function()
        return self.dataStore:SetAsync(tostring(player.UserId), playerData[player.UserId])
    end)
    
    saveInProgress[player.UserId] = nil
    
    if success then
        log("Successfully saved data for " .. player.Name)
        return true
    else
        warn("[DataManager] Failed to save data for " .. player.Name .. ": " .. tostring(result))
        return false
    end
end

-- Load player data
function DataManager:loadPlayerData(player)
    if not self.dataStore then
        warn("[DataManager] Data store not initialized")
        return false
    end
    
    local success, result = safeDataStoreOperation(function()
        return self.dataStore:GetAsync(tostring(player.UserId))
    end)
    
    if success then
        if result then
            playerData[player.UserId] = result
            log("Successfully loaded data for " .. player.Name)
        else
            playerData[player.UserId] = table.clone(CONFIG.DEFAULT_DATA)
            log("Created new data for " .. player.Name)
        end
        return true
    else
        warn("[DataManager] Failed to load data for " .. player.Name .. ": " .. tostring(result))
        return false
    end
end

-- Get player data
function DataManager:getPlayerData(player)
    return playerData[player.UserId]
end

-- Update player data
function DataManager:updatePlayerData(player, updateFunction)
    if not playerData[player.UserId] then
        return false
    end
    
    local success, result = pcall(function()
        return updateFunction(playerData[player.UserId])
    end)
    
    if success then
        return true
    else
        warn("[DataManager] Failed to update data for " .. player.Name .. ": " .. tostring(result))
        return false
    end
end

-- Get configuration
function DataManager:getConfig()
    return CONFIG
end

-- Get data store
function DataManager:getDataStore()
    return self.dataStore
end

-- Get backup data store
function DataManager:getBackupDataStore()
    return self.backupDataStore
end

-- Check if initialized
function DataManager:isInitialized()
    return self.initialized
end

return DataManager
