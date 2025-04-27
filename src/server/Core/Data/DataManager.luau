--!strict
--[[
    DataManager.luau
    
    Unified data management system that serves as the main entry point for all data operations.
    Coordinates between persistence, caching, validation and other data subsystems.
    
    Features:
    - Centralized data access API
    - Request routing and orchestration
    - Memory caching and optimization
    - Data validation and error handling
    - Player session management
    
    Author: Updated April 27, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Import required modules
local ServerScripts = script.Parent.Parent
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")

local DataPersistence = require(script.Parent:WaitForChild("DataPersistence"))
local DataCache = require(script.Parent:WaitForChild("DataCache"))
local DataAnalytics = require(script.Parent:WaitForChild("DataAnalytics"))
local DataTypes = require(SharedModules:WaitForChild("Data"):WaitForChild("DataTypes"))
local DataConstants = require(SharedModules:WaitForChild("Data"):WaitForChild("DataConstants"))
local DataMigration = nil -- Will be loaded later to avoid circular dependencies

-- Try to load DataMigration if it exists
pcall(function()
    DataMigration = require(script.Parent:WaitForChild("DataMigration"))
end)

-- Module and state variables
local DataManager = {}

local initialized = false
local shutdownInProgress = false
local playerData = {}
local dataSaveQueue = {}
local saveInProgress = {}
local playerJoinTimes = {}
local dataChangeListeners = {}
local saveAttempts = {}

-- Configuration options
local config = {
    autoSaveEnabled = DataConstants.AUTOSAVE.ENABLED,
    autoSaveInterval = DataConstants.AUTOSAVE.INTERVAL,
    useBackups = true,
    logSaves = false,
    logLoads = false,
    debugMode = false
}

--[[ Private Utility Functions ]]--

local function log(message, ...)
    if config.debugMode then
        print("[DataManager] " .. message, ...)
    end
end

-- Process that handles saving data in the queue
local function processSaveQueue()
    if shutdownInProgress then
        return
    end
    
    while next(dataSaveQueue) ~= nil do
        local queueItem = table.remove(dataSaveQueue, 1)
        
        if queueItem then
            local userId = queueItem.userId
            local scope = queueItem.scope
            local key = queueItem.key or tostring(userId)
            local storeName = queueItem.storeName
            local data = queueItem.data
            
            if userId and scope and storeName and data then
                -- Mark save in progress
                if not saveInProgress[userId] then
                    saveInProgress[userId] = {}
                end
                saveInProgress[userId][scope] = true
                
                -- Track save attempt
                if not saveAttempts[userId] then
                    saveAttempts[userId] = {}
                end
                if not saveAttempts[userId][scope] then
                    saveAttempts[userId][scope] = 0
                end
                saveAttempts[userId][scope] += 1
                local attempt = saveAttempts[userId][scope]
                
                -- Log if configured to do so
                if config.logSaves then
                    log("Saving data for player %d, scope '%s', attempt %d", userId, scope, attempt)
                end
                
                -- Perform the save
                local success, result = DataPersistence:saveData(storeName, key, data, {
                    createBackup = config.useBackups,
                    maxRetries = DataConstants.RATE_LIMITS.MAX_RETRY_ATTEMPTS
                })
                
                -- Cache key for this data
                local cacheKey = "player:" .. userId .. ":" .. scope
                
                -- Clear in-progress flag
                if saveInProgress[userId] then
                    saveInProgress[userId][scope] = nil
                    if not next(saveInProgress[userId]) then
                        saveInProgress[userId] = nil
                    end
                end
                
                -- Handle result
                if success then
                    -- Reset attempt counter on success
                    if saveAttempts[userId] and saveAttempts[userId][scope] then
                        saveAttempts[userId][scope] = 0
                    end
                    
                    -- Update cache with latest data
                    DataCache:set(cacheKey, DataTypes.deepCopy(data), {
                        scope = "player:" .. userId,
                        ttl = 600 -- 10 minutes
                    })
                    
                    if config.logSaves then
                        log("Successfully saved data for player %d, scope '%s'", userId, scope)
                    end
                else
                    -- Invalidate cache on save failure
                    DataCache:invalidate(cacheKey, {scope = "player:" .. userId})
                    
                    -- Put back in queue for retry if not too many attempts
                    if attempt < DataConstants.RATE_LIMITS.MAX_RETRY_ATTEMPTS then
                        task.wait(DataConstants.RATE_LIMITS.RETRY_DELAY)
                        table.insert(dataSaveQueue, queueItem)
                    else
                        warn(string.format("Failed to save data for player %d, scope '%s' after %d attempts: %s", 
                            userId, scope, attempt, tostring(result)))
                    end
                end
            end
        end
        
        -- Don't hog the thread
        task.wait()
    end
end

-- Setup auto-save timer
local function setupAutoSave()
    if config.autoSaveEnabled then
        task.spawn(function()
            while true do
                if shutdownInProgress then
                    return
                end
                
                task.wait(config.autoSaveInterval)
                DataManager:saveAllPlayerData()
            end
        end)
    end
end

-- Fire data change event
local function fireDataChange(userId, scope, data, oldData)
    if not dataChangeListeners[userId] then
        return
    end
    
    if dataChangeListeners[userId][scope] then
        for _, callback in ipairs(dataChangeListeners[userId][scope]) do
            task.spawn(function()
                pcall(callback, data, oldData)
            end)
        end
    end
    
    if dataChangeListeners[userId]["all"] then
        for _, callback in ipairs(dataChangeListeners[userId]["all"]) do
            task.spawn(function()
                pcall(callback, scope, data, oldData)
            end)
        end
    end
end

-- Get storage key for a player and scope
local function getStorageKey(userId, scope)
    return string.format("%d_%s", userId, scope)
end

-- Get appropriate store name for a scope
local function getStoreNameForScope(scope)
    if scope == DataConstants.PLAYER_SCOPES.CORE then
        return DataConstants.STORES.PLAYER_DATA
    elseif scope == DataConstants.PLAYER_SCOPES.STATS then
        return DataConstants.STORES.PLAYER_DATA
    elseif scope == DataConstants.PLAYER_SCOPES.INVENTORY then
        return DataConstants.STORES.PLAYER_DATA
    elseif scope == DataConstants.PLAYER_SCOPES.ACHIEVEMENTS then
        return DataConstants.STORES.PLAYER_DATA
    elseif scope == DataConstants.PLAYER_SCOPES.QUESTS then
        return DataConstants.STORES.PLAYER_DATA
    elseif scope == DataConstants.PLAYER_SCOPES.SOCIAL then
        return DataConstants.STORES.PLAYER_DATA
    elseif scope == DataConstants.PLAYER_SCOPES.SETTINGS then
        return DataConstants.STORES.PLAYER_DATA
    else
        -- Default for custom scopes
        return DataConstants.STORES.PLAYER_DATA
    end
end

-- Connect player events
local function connectPlayerEvents()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        local userId = player.UserId
        playerJoinTimes[userId] = os.time()
        
        -- Load player data
        DataManager:loadPlayerData(player)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        local userId = player.UserId
        
        -- Save player data
        DataManager:savePlayerData(player)
        
        -- Clean up
        task.delay(5, function() -- Small delay to ensure save completes
            playerData[userId] = nil
            saveAttempts[userId] = nil
            playerJoinTimes[userId] = nil
            dataChangeListeners[userId] = nil
            
            -- Release session lock
            DataPersistence:releaseSessionLock(userId)
        end)
    end)
    
    -- Handle game shutdown
    game:BindToClose(function()
        shutdownInProgress = true
        DataManager:saveAllPlayerData(true) -- force immediate save
        
        -- Wait a bit to ensure saves complete
        task.wait(5)
    end)
end

--[[ Public API Functions ]]--

-- Initialize the data manager
function DataManager:initialize()
    if initialized then
        return true
    end
    
    -- Initialize dependencies
    DataPersistence:initialize()
    
    -- Initialize and configure cache
    DataCache:initialize({
        memoryLimit = 50 * 1024 * 1024, -- 50MB limit
        defaultTTL = 600, -- 10 minutes default TTL
        writePolicy = "through", -- Use write-through policy for safety
        logLevel = config.debugMode and 3 or 1 -- More verbose logging in debug mode
    })
    
    -- Initialize analytics
    DataAnalytics:initialize({
        enabled = true,
        debugMode = config.debugMode,
        logLevel = config.debugMode and 3 or 1,
        sampleRate = 0.05 -- Sample 5% of operations for detailed metrics
    })
    
    -- Setup systems
    setupAutoSave()
    connectPlayerEvents()
    
    -- Start save queue processor
    task.spawn(processSaveQueue)
    
    initialized = true
    log("DataManager initialized")
    DataAnalytics:recordEvent("system_initialize", {component = "DataManager"})
    
    return true
end

-- Load data for a player
function DataManager:loadPlayerData(player, scope)
    if not player or not player.UserId then
        warn("Invalid player for loadPlayerData")
        return false
    end
    
    local userId = player.UserId
    
    -- Try to acquire a session lock
    if not DataPersistence:acquireSessionLock(userId) then
        warn("Failed to acquire session lock for player", player.Name)
        return false
    end
    
    -- Initialize player's data table if needed
    if not playerData[userId] then
        playerData[userId] = {}
    end
    
    -- If scope specified, load just that scope
    if scope then
        return self:loadPlayerDataScope(player, scope)
    end
    
    -- Otherwise load all scopes
    local allSuccess = true
    
    for _, scopeName in pairs(DataConstants.PLAYER_SCOPES) do
        local success = self:loadPlayerDataScope(player, scopeName)
        if not success then
            allSuccess = false
        end
    end
    
    return allSuccess
end

-- Load a specific data scope for a player
function DataManager:loadPlayerDataScope(player, scope)
    if not player or not player.UserId or not scope then
        warn("Invalid parameters for loadPlayerDataScope")
        DataAnalytics:recordError("invalid_params", "Invalid parameters for loadPlayerDataScope", "DataManager", {
            playerValid = player ~= nil,
            userIdValid = player and player.UserId ~= nil,
            scopeValid = scope ~= nil
        })
        return false
    end
    
    local userId = player.UserId
    local startTime = os.clock()
    
    -- Check cache first
    local cacheKey = "player:" .. userId .. ":" .. scope
    local cachedData = DataCache:get(cacheKey, {scope = "player:" .. userId})
    
    -- If found in cache, use it
    if cachedData then
        -- Track cache hit
        DataAnalytics:trackCacheUsage("hit", {
            key = cacheKey,
            scope = "player:" .. userId
        })
        
        if config.logLoads then
            log("Loaded data for player %s (%d), scope '%s' from cache", player.Name, userId, scope)
        end
        
        -- Store in memory
        if not playerData[userId] then
            playerData[userId] = {}
        end
        playerData[userId][scope] = DataTypes.deepCopy(cachedData)
        
        -- Track operation
        local duration = os.clock() - startTime
        DataAnalytics:trackOperation("read", {
            source = "cache",
            scope = scope,
            userId = userId,
            duration = duration,
            result = "success"
        })
        
        return true
    end
    
    -- Track cache miss
    DataAnalytics:trackCacheUsage("miss", {
        key = cacheKey,
        scope = "player:" .. userId
    })
    
    -- Not in cache, load from persistence
    local storeName = getStoreNameForScope(scope)
    local key = getStorageKey(userId, scope)
    
    -- Log if configured to do so
    if config.logLoads then
        log("Loading data for player %s (%d), scope '%s' from DataStore", player.Name, userId, scope)
    end
    
    -- Track DataStore request
    DataAnalytics:trackDataStoreUsage("request", {
        storeName = storeName,
        key = key
    })
    
    -- Load the data
    local success, message, data = DataPersistence:loadData(storeName, key, {
        useBackup = config.useBackups,
        maxRetries = DataConstants.RATE_LIMITS.MAX_RETRY_ATTEMPTS
    })
    
    -- Calculate operation duration
    local duration = os.clock() - startTime
    
    -- Handle load result
    if success then
        -- If no data was found, create default data
        if data == nil then
            if scope == DataConstants.PLAYER_SCOPES.CORE then
                -- For core player data, create with player info
                data = DataTypes.create("PlayerData", userId, player.Name, player.DisplayName)
            else
                -- For other scopes, use empty tables
                data = {}
            end
        end
        
        -- Migrate data if needed
        if DataMigration and type(data) == "table" then
            local migrated, newData = DataMigration:migrateData(scope, data)
            if migrated then
                data = newData
            end
        end
        
        -- Store in memory and cache
        if not playerData[userId] then
            playerData[userId] = {}
        end
        playerData[userId][scope] = data
        
        -- Cache the data
        DataCache:set(cacheKey, DataTypes.deepCopy(data), {
            scope = "player:" .. userId,
            ttl = 600 -- 10 minutes
        })
        
        if config.logLoads then
            log("Successfully loaded data for player %s, scope '%s'", player.Name, scope)
        end
        
        -- Track operation
        DataAnalytics:trackOperation("read", {
            source = "datastore",
            scope = scope,
            userId = userId,
            duration = duration,
            result = "success"
        })
        
        return true
    else
        warn("Failed to load data for player", player.Name, "scope", scope, ":", message)
        
        -- Track operation failure
        DataAnalytics:trackOperation("read", {
            source = "datastore",
            scope = scope,
            userId = userId,
            duration = duration,
            result = "failure"
        })
        
        -- Track DataStore failure
        DataAnalytics:trackDataStoreUsage("failure", {
            storeName = storeName,
            key = key,
            errorMessage = message
        })
        
        -- Record error
        DataAnalytics:recordError("data_load_error", message, "DataManager.loadPlayerDataScope", {
            player = player.Name,
            userId = userId,
            scope = scope
        })
        
        return false
    end
end

-- Save all data for a player
function DataManager:savePlayerData(player, immediate)
    if not player or not player.UserId then
        warn("Invalid player for savePlayerData")
        return false
    end
    
    local userId = player.UserId
    
    -- If player data doesn't exist, nothing to save
    if not playerData[userId] then
        return true
    end
    
    -- Save all scopes
    local allSuccess = true
    
    for scope, _ in pairs(playerData[userId]) do
        local success = self:savePlayerDataScope(player, scope, immediate)
        if not success then
            allSuccess = false
        end
    end
    
    return allSuccess
end

-- Save a specific data scope for a player
function DataManager:savePlayerDataScope(player, scope, immediate)
    if not player or not player.UserId or not scope then
        warn("Invalid parameters for savePlayerDataScope")
        DataAnalytics:recordError("invalid_params", "Invalid parameters for savePlayerDataScope", "DataManager", {
            playerValid = player ~= nil,
            userIdValid = player and player.UserId ~= nil,
            scopeValid = scope ~= nil
        })
        return false
    end
    
    local userId = player.UserId
    local startTime = os.clock()
    
    -- If no data for this scope, nothing to save
    if not playerData[userId] or not playerData[userId][scope] then
        return true
    end
    
    -- Get the data to save
    local data = playerData[userId][scope]
    
    -- Get the appropriate store name and key
    local storeName = getStoreNameForScope(scope)
    local key = getStorageKey(userId, scope)
    
    -- Update the cache with latest data
    local cacheKey = "player:" .. userId .. ":" .. scope
    DataCache:set(cacheKey, DataTypes.deepCopy(data), {
        scope = "player:" .. userId,
        ttl = 600 -- 10 minutes
    })
    
    -- If a save is already in progress for this scope, don't queue another one
    if saveInProgress[userId] and saveInProgress[userId][scope] then
        return true
    end
    
    -- If immediate, save right away
    if immediate then
        -- Mark save in progress
        if not saveInProgress[userId] then
            saveInProgress[userId] = {}
        end
        saveInProgress[userId][scope] = true
        
        -- Log if configured to do so
        if config.logSaves then
            log("Immediate save for player %s (%d), scope '%s'", player.Name, userId, scope)
        end
        
        -- Track DataStore request
        DataAnalytics:trackDataStoreUsage("request", {
            storeName = storeName,
            key = key,
            operation = "save"
        })
        
        -- Perform the save
        local success, result = DataPersistence:saveData(storeName, key, data, {
            createBackup = config.useBackups,
            maxRetries = DataConstants.RATE_LIMITS.MAX_RETRY_ATTEMPTS
        })
        
        -- Calculate operation duration
        local duration = os.clock() - startTime
        
        -- Clear in-progress flag
        if saveInProgress[userId] then
            saveInProgress[userId][scope] = nil
            if not next(saveInProgress[userId]) then
                saveInProgress[userId] = nil
            end
        end
        
        -- Handle result
        if success then
            if config.logSaves then
                log("Successfully saved data for player %s, scope '%s'", player.Name, scope)
            end
            
            -- Track operation success
            DataAnalytics:trackOperation("write", {
                source = "datastore",
                scope = scope,
                userId = userId,
                duration = duration,
                result = "success"
            })
            
            return true
        else
            warn("Failed to save data for player", player.Name, "scope", scope, ":", result)
            
            -- Invalidate cache on save failure to force a reload next time
            DataCache:invalidate(cacheKey, {scope = "player:" .. userId})
            
            -- Track operation failure
            DataAnalytics:trackOperation("write", {
                source = "datastore",
                scope = scope,
                userId = userId,
                duration = duration,
                result = "failure"
            })
            
            -- Track DataStore failure
            DataAnalytics:trackDataStoreUsage("failure", {
                storeName = storeName,
                key = key,
                errorMessage = result,
                operation = "save"
            })
            
            -- Record error
            DataAnalytics:recordError("data_save_error", tostring(result), "DataManager.savePlayerDataScope", {
                player = player.Name,
                userId = userId,
                scope = scope
            })
            
            return false
        end
    else
        -- Queue for async save
        table.insert(dataSaveQueue, {
            userId = userId,
            scope = scope,
            key = key,
            storeName = storeName,
            data = data
        })
        
        -- Track queued operation
        DataAnalytics:recordEvent("save_queued", {
            userId = userId,
            scope = scope,
            queueLength = #dataSaveQueue
        })
        
        -- Trigger save queue processing
        task.spawn(processSaveQueue)
        return true
    end
end

-- Save data for all connected players
function DataManager:saveAllPlayerData(immediate)
    local savedCount = 0
    
    for _, player in ipairs(Players:GetPlayers()) do
        if self:savePlayerData(player, immediate) then
            savedCount += 1
        end
    end
    
    return savedCount
end

-- Get player data for a specific scope
function DataManager:getPlayerData(player, scope)
    if not player or not player.UserId or not scope then
        warn("Invalid parameters for getPlayerData")
        return nil
    end
    
    local userId = player.UserId
    
    -- If data isn't loaded yet, try to load it
    if not playerData[userId] or not playerData[userId][scope] then
        local success = self:loadPlayerDataScope(player, scope)
        if not success then
            return nil
        end
    end
    
    -- Return a deep copy to prevent direct modification
    if playerData[userId] and playerData[userId][scope] then
        return DataTypes.deepCopy(playerData[userId][scope])
    end
    
    return nil
end

-- Update player data for a specific scope
function DataManager:updatePlayerData(player, scope, updateFunction)
    if not player or not player.UserId or not scope or type(updateFunction) ~= "function" then
        warn("Invalid parameters for updatePlayerData")
        return false, nil
    end
    
    local userId = player.UserId
    
    -- If data isn't loaded yet, try to load it
    if not playerData[userId] or not playerData[userId][scope] then
        local success = self:loadPlayerDataScope(player, scope)
        if not success then
            return false, nil
        end
    end
    
    -- Get current data
    local currentData = playerData[userId][scope]
    
    -- Create a deep copy for the update function
    local dataCopy = DataTypes.deepCopy(currentData)
    
    -- Apply the update function to the copy
    local success, result = pcall(function()
        return updateFunction(dataCopy)
    end)
    
    if not success then
        warn("Error in update function:", result)
        return false, nil
    end
    
    -- Use the result if provided, otherwise use the modified copy
    local newData = result or dataCopy
    
    -- Validate if this is core player data
    if scope == DataConstants.PLAYER_SCOPES.CORE then
        local valid, validationError = DataTypes.validate(newData, "PlayerData")
        if not valid then
            warn("Invalid player data after update:", validationError)
            return false, nil
        end
    end
    
    -- Store the new value
    local oldData = playerData[userId][scope]
    playerData[userId][scope] = newData
    
    -- Trigger data change event
    fireDataChange(userId, scope, newData, oldData)
    
    -- Queue for saving
    self:savePlayerDataScope(player, scope, false)
    
    return true, newData
end

-- Set a specific value in player data
function DataManager:setPlayerValue(player, scope, key, value)
    return self:updatePlayerData(player, scope, function(data)
        data[key] = value
        return data
    end)
end

-- Get a specific value from player data
function DataManager:getPlayerValue(player, scope, key)
    local data = self:getPlayerData(player, scope)
    if data then
        return data[key]
    end
    return nil
end

-- Incremental update for a numeric value
function DataManager:incrementPlayerValue(player, scope, key, amount)
    return self:updatePlayerData(player, scope, function(data)
        if type(data[key]) == "number" then
            data[key] = data[key] + (amount or 1)
        else
            data[key] = amount or 1
        end
        return data
    end)
end

-- Listen for changes to player data
function DataManager:onDataChange(player, scope, callback)
    if not player or not player.UserId or not callback or type(callback) ~= "function" then
        warn("Invalid parameters for onDataChange")
        return false
    end
    
    local userId = player.UserId
    
    -- Initialize listener tables if needed
    if not dataChangeListeners[userId] then
        dataChangeListeners[userId] = {}
    end
    if not dataChangeListeners[userId][scope] then
        dataChangeListeners[userId][scope] = {}
    end
    
    -- Add the callback
    table.insert(dataChangeListeners[userId][scope], callback)
    
    return true
end

-- Set configuration option
function DataManager:setConfig(option, value)
    if config[option] ~= nil then
        config[option] = value
        return true
    end
    return false
end

-- Get configuration value
function DataManager:getConfig(option)
    return config[option]
end

-- Get all configuration values
function DataManager:getAllConfig()
    return DataTypes.deepCopy(config)
end

-- Get player's session info
function DataManager:getPlayerSession(player)
    if not player or not player.UserId then
        return nil
    end
    
    local userId = player.UserId
    
    return {
        joinTime = playerJoinTimes[userId] or 0,
        sessionDuration = os.time() - (playerJoinTimes[userId] or os.time()),
        hasLock = DataPersistence:hasSessionLock(userId),
        saveAttempts = saveAttempts[userId] or {},
        hasSaveInProgress = saveInProgress[userId] ~= nil,
        loadedScopes = playerData[userId] and table.clone(playerData[userId]) or {}
    }
end

-- Clear player data from memory (but don't delete from DataStore)
function DataManager:clearPlayerMemory(player)
    if not player or not player.UserId then
        return false
    end
    
    local userId = player.UserId
    
    -- Save any pending changes first
    self:savePlayerData(player, true)
    
    -- Clear memory
    playerData[userId] = nil
    saveAttempts[userId] = nil
    
    -- Clear cache for this player
    DataCache:clear("player:" .. userId)
    
    return true
end

-- Utility function to handle errors with data operations
function DataManager:tryOperation(operation, context, options)
    local success, result = pcall(operation)
    
    if success then
        return true, result
    else
        warn("Error in data operation:", context, result)
        
        if options and options.retries and options.retries > 0 then
            warn("Retrying operation... (", options.retries, "attempts left)")
            task.wait(options.backoff or 1)
            options.retries -= 1
            return self:tryOperation(operation, context, options)
        end
        
        if options and options.fallback ~= nil then
            warn("Using fallback value")
            return true, options.fallback
        end
        
        return false, result
    end
end

return DataManager
