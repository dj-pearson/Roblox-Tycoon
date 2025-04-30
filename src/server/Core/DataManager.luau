--[[
    DataManager.luau
    
    Core system for managing data persistence and access.
    This module handles data storage, retrieval, and caching.
    
    Created: April 30, 2025
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

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
        },
        -- Add more default data as needed
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
                -- Wait before retrying
                wait(1)
            end
        end
    end
    
    return success, result
end

-- Initialize the data manager
function DataManager.initialize()
    if DataManager.initialized then
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
    
    DataManager.dataStore = mainDataStore
    log("Main data store initialized")
    
    -- Set up backup data store
    local _, backupDataStore = safeDataStoreOperation(function()
        return DataStoreService:GetDataStore(CONFIG.BACKUP_DATA_STORE_NAME)
    end)
    
    if backupDataStore then
        DataManager.backupDataStore = backupDataStore
        log("Backup data store initialized")
    else
        log("No backup data store available")
    end
    
    -- Set up auto-saving
    spawn(function()
        while true do
            wait(CONFIG.AUTO_SAVE_INTERVAL)
            
            log("Running auto-save...")
            local savedCount = 0
            
            for _, player in ipairs(Players:GetPlayers()) do
                if playerData[player.UserId] and not saveInProgress[player.UserId] then
                    local success = DataManager.savePlayerData(player)
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
        log("Player leaving, saving data: " .. player.Name)
        
        for attempt = 1, CONFIG.PLAYER_LEAVING_RETRY_COUNT do
            local success = DataManager.savePlayerData(player)
            if success then
                log("Successfully saved data for " .. player.Name .. " on exit")
                break
            else
                if attempt < CONFIG.PLAYER_LEAVING_RETRY_COUNT then
                    log("Retrying data save for " .. player.Name .. " (Attempt " .. attempt .. "/" .. CONFIG.PLAYER_LEAVING_RETRY_COUNT .. ")")
                    wait(CONFIG.PLAYER_LEAVING_RETRY_DELAY)
                else
                    warn("[DataManager] Failed to save data for " .. player.Name .. " after " .. CONFIG.PLAYER_LEAVING_RETRY_COUNT .. " attempts")
                end
            end
        end
        
        -- Clean up player data cache
        playerData[player.UserId] = nil
        saveInProgress[player.UserId] = nil
    end)
    
    -- Set up player joining handler
    Players.PlayerAdded:Connect(function(player)
        log("Player joined, loading data: " .. player.Name)
        local data = DataManager.loadPlayerData(player)
        
        if data then
            log("Successfully loaded data for " .. player.Name)
        else
            log("Using default data for " .. player.Name)
        end
    end)
    
    -- Handle game closure
    game:BindToClose(function()
        log("Game closing, saving all player data...")
        
        for _, player in ipairs(Players:GetPlayers()) do
            if playerData[player.UserId] and not saveInProgress[player.UserId] then
                local success = DataManager.savePlayerData(player)
                if success then
                    log("Successfully saved data for " .. player.Name .. " on game close")
                else
                    warn("[DataManager] Failed to save data for " .. player.Name .. " on game close")
                end
            end
        end
        
        log("All player data saved, game can close")
    end)
    
    DataManager.initialized = true
    log("DataManager initialized successfully")
    return true
end

-- Save a player's data
function DataManager.savePlayerData(player)
    if not DataManager.initialized or not player or not player.UserId then
        return false
    end
    
    local userId = player.UserId
    if not playerData[userId] then
        warn("[DataManager] No data to save for " .. player.Name)
        return false
    end
    
    if saveInProgress[userId] then
        log("Save already in progress for " .. player.Name .. ", skipping")
        return false
    end
    
    saveInProgress[userId] = true
    
    -- Prepare data for storage
    local dataToSave = table.clone(playerData[userId])
    dataToSave.lastSaveTime = os.time()
    
    -- Save to main data store
    local success, errorMessage = safeDataStoreOperation(function()
        DataManager.dataStore:SetAsync("Player_" .. userId, dataToSave)
        return true
    end)
    
    -- Also save to backup if we have one
    if success and DataManager.backupDataStore then
        safeDataStoreOperation(function()
            DataManager.backupDataStore:SetAsync("Player_" .. userId .. "_" .. os.time(), dataToSave)
            return true
        end)
    end
    
    saveInProgress[userId] = false
    
    if success then
        log("Regular save successful for: " .. player.Name)
    else
        warn("[DataManager] Failed to save data for " .. player.Name .. ": " .. tostring(errorMessage))
    end
    
    return success
end

-- Load a player's data
function DataManager.loadPlayerData(player)
    if not DataManager.initialized or not player or not player.UserId then
        return CONFIG.DEFAULT_DATA
    end
    
    local userId = player.UserId
    local keySuffix = "Player_" .. userId
    
    -- Try to load from main data store
    local success, data = safeDataStoreOperation(function()
        return DataManager.dataStore:GetAsync(keySuffix)
    end)
    
    if success and data then
        log("Successfully loaded data for " .. player.Name)
        playerData[userId] = data
        return data
    end
    
    -- If failed, check if we have any backup data
    if DataManager.backupDataStore then
        -- This would be complex in practice and need to find the most recent backup
        -- For now, we'll just use default data
    end
    
    -- Use default data if no saved data found
    log("No saved data found for " .. player.Name .. ", using default")
    playerData[userId] = table.clone(CONFIG.DEFAULT_DATA)
    return playerData[userId]
end

-- Get a player's data from cache
function DataManager.getPlayerData(player)
    if not player or not player.UserId then
        return nil
    end
    
    local userId = player.UserId
    
    -- If data isn't loaded yet, load it
    if not playerData[userId] then
        return DataManager.loadPlayerData(player)
    end
    
    return playerData[userId]
end

-- Update a specific value in the player's data
function DataManager.updateValue(player, key, value)
    if not player or not player.UserId then
        return false
    end
    
    local data = DataManager.getPlayerData(player)
    if not data then
        return false
    end
    
    data[key] = value
    return true
end

-- Update a nested value in the player's data
function DataManager.updateNestedValue(player, path, value)
    if not player or not player.UserId or not path or type(path) ~= "table" or #path == 0 then
        return false
    end
    
    local data = DataManager.getPlayerData(player)
    if not data then
        return false
    end
    
    local current = data
    for i = 1, #path - 1 do
        local key = path[i]
        if not current[key] then
            current[key] = {}
        elseif type(current[key]) ~= "table" then
            current[key] = {}
        end
        current = current[key]
    end
    
    current[path[#path]] = value
    return true
end

-- Initialize the DataManager
DataManager.initialize()

return DataManager
