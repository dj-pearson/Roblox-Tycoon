--!strict
--[[
    DataPersistence.luau
    
    Core data saving and loading functionality with robust error handling.
    Provides a low-level interface to Roblox's DataStore service with additional
    reliability features.
    
    Features:
    - Robust error handling and retry logic
    - Data versioning and migration support
    - Session locking to prevent data conflicts
    - Automatic backup mechanisms
    - Rate limiting protection
    - Telemetry and monitoring
    
    Author: Updated April 27, 2025
]]

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local DataTypes = require(SharedModules:WaitForChild("Data"):WaitForChild("DataTypes"))
local DataConstants = require(SharedModules:WaitForChild("Data"):WaitForChild("DataConstants"))

-- Module and state variables
local DataPersistence = {}

local dataStores = {}
local sessionLocks = {}
local operationMetrics = {
    saveOperations = 0,
    loadOperations = 0,
    saveFailures = 0,
    loadFailures = 0,
    lastError = "",
    lastErrorTime = 0
}

local saveRateLimiter = {
    operations = {},
    lastCleanup = os.time()
}

local loadRateLimiter = {
    operations = {},
    lastCleanup = os.time()
}

--[[ Private Utility Functions ]]--

-- Clean up expired operations from rate limiters
local function cleanupRateLimiter(limiter, maxAge)
    local now = os.time()
    if now - limiter.lastCleanup < 60 then -- Only clean up once per minute
        return
    end
    
    for userId, timestamp in pairs(limiter.operations) do
        if now - timestamp > maxAge then
            limiter.operations[userId] = nil
        end
    end
    
    limiter.lastCleanup = now
end

-- Check if operation is rate limited
local function isRateLimited(limiter, userId, maxOperations, timeWindow)
    cleanupRateLimiter(limiter, timeWindow)
    
    local now = os.time()
    local operations = 0
    
    -- Count operations in time window
    for _, timestamp in pairs(limiter.operations) do
        if now - timestamp <= timeWindow then
            operations = operations + 1
        end
    end
    
    if operations >= maxOperations then
        return true
    end
    
    -- Record this operation
    limiter.operations[userId] = now
    return false
end

-- Create a session lock key for a player
local function getSessionLockKey(userId)
    return "session_lock_" .. tostring(userId)
end

-- Get the game server ID
local function getServerId()
    return tostring(game.JobId) ~= "" and game.JobId or ("Test_" .. os.time())
end

-- Get or create a DataStore
local function getDataStore(storeName)
    if dataStores[storeName] then
        return dataStores[storeName]
    end
    
    local success, result = pcall(function()
        return DataStoreService:GetDataStore(storeName)
    end)
    
    if success then
        dataStores[storeName] = result
        return result
    else
        warn("Failed to get DataStore:", storeName, result)
        return nil
    end
end

-- Safely serialize data for storage
local function safeSerialize(data)
    local success, result = pcall(function()
        return DataTypes.serialize(data)
    end)
    
    if success then
        return result
    else
        warn("Failed to serialize data:", result)
        return nil
    end
end

-- Safely deserialize data from storage
local function safeDeserialize(data)
    if not data then
        return nil
    end
    
    local success, result = pcall(function()
        return DataTypes.deserialize(data)
    end)
    
    if success then
        return result
    else
        warn("Failed to deserialize data:", result)
        return nil
    end
end

-- Create a backup key for a specific key
local function getBackupKey(key)
    return "backup_" .. key
end

--[[ Session Lock Management ]]--

-- Acquire a session lock for a user
local function acquireSessionLock(userId)
    if sessionLocks[userId] then
        return true -- Already have a lock
    end
    
    local lockKey = getSessionLockKey(userId)
    local serverId = getServerId()
    local dataStore = getDataStore(DataConstants.STORES.PLAYER_DATA)
    
    if not dataStore then
        warn("Failed to get DataStore for session lock")
        return false
    end
    
    local success, currentLock = pcall(function()
        return dataStore:GetAsync(lockKey)
    end)
    
    if not success then
        warn("Failed to check session lock:", currentLock)
        return false
    end
    
    if currentLock then
        -- Check if lock is expired (30 minutes)
        if typeof(currentLock) == "table" and currentLock.time and 
           os.time() - currentLock.time > DataConstants.CACHE.SESSION_LOCK_DURATION * 60 then
            -- Lock is expired, we can take it
        elseif typeof(currentLock) == "table" and currentLock.server and 
               currentLock.server == serverId then
            -- This is our lock, renew it
            sessionLocks[userId] = true
            return true
        else
            -- Lock belongs to another server
            return false
        end
    end
    
    -- Try to set the lock
    local lockData = {
        server = serverId,
        time = os.time()
    }
    
    success = pcall(function()
        dataStore:SetAsync(lockKey, lockData)
    end)
    
    if success then
        sessionLocks[userId] = true
        return true
    else
        warn("Failed to set session lock")
        return false
    end
end

-- Release a session lock for a user
local function releaseSessionLock(userId)
    if not sessionLocks[userId] then
        return true -- No lock to release
    end
    
    local lockKey = getSessionLockKey(userId)
    local serverId = getServerId()
    local dataStore = getDataStore(DataConstants.STORES.PLAYER_DATA)
    
    if not dataStore then
        warn("Failed to get DataStore for releasing session lock")
        return false
    end
    
    -- Check if we still own the lock
    local success, currentLock = pcall(function()
        return dataStore:GetAsync(lockKey)
    end)
    
    if not success then
        warn("Failed to check session lock for release:", currentLock)
        sessionLocks[userId] = nil
        return false
    end
    
    if not currentLock or typeof(currentLock) ~= "table" or 
       not currentLock.server or currentLock.server ~= serverId then
        -- Lock doesn't exist or doesn't belong to us
        sessionLocks[userId] = nil
        return true
    end
    
    -- Remove the lock
    success = pcall(function()
        dataStore:RemoveAsync(lockKey)
    end)
    
    if success then
        sessionLocks[userId] = nil
        return true
    else
        warn("Failed to remove session lock")
        return false
    end
end

-- Refresh all active session locks
local function refreshSessionLocks()
    for userId, _ in pairs(sessionLocks) do
        local lockKey = getSessionLockKey(userId)
        local serverId = getServerId()
        local dataStore = getDataStore(DataConstants.STORES.PLAYER_DATA)
        
        if dataStore then
            pcall(function()
                dataStore:UpdateAsync(lockKey, function(currentLock)
                    if typeof(currentLock) == "table" and 
                       currentLock.server and currentLock.server == serverId then
                        return {
                            server = serverId,
                            time = os.time()
                        }
                    end
                    return currentLock
                end)
            end)
        end
    end
end

--[[ Data Backup Functions ]]--

-- Create a backup of data
local function backupData(storeName, key, data)
    local backupStore = getDataStore(DataConstants.STORES.BACKUP)
    
    if not backupStore then
        warn("Failed to get backup DataStore")
        return false
    end
    
    local backupKey = string.format("%s_%s", storeName, key)
    local backupData = {
        originStore = storeName,
        originKey = key,
        data = data,
        timestamp = os.time(),
        version = DataConstants.STORAGE_VERSION
    }
    
    local success, err = pcall(function()
        backupStore:SetAsync(backupKey, safeSerialize(backupData))
    end)
    
    if not success then
        warn("Failed to create backup:", err)
        return false
    end
    
    return true
end

-- Retrieve a backup of data
local function getBackupData(storeName, key)
    local backupStore = getDataStore(DataConstants.STORES.BACKUP)
    
    if not backupStore then
        warn("Failed to get backup DataStore")
        return nil
    end
    
    local backupKey = string.format("%s_%s", storeName, key)
    
    local success, result = pcall(function()
        return backupStore:GetAsync(backupKey)
    end)
    
    if not success or not result then
        return nil
    end
    
    local backupData = safeDeserialize(result)
    
    if backupData and backupData.data then
        return backupData.data
    end
    
    return nil
end

--[[ Public API Functions ]]--

-- Save data to DataStore with retry logic
function DataPersistence:saveData(storeName, key, data, options)
    options = options or {}
    
    -- Check parameters
    if not storeName or not key or data == nil then
        warn("Invalid parameters for saveData")
        return false, "Invalid parameters"
    end
    
    -- Check rate limit
    local canProceed, rateLimitError = checkRateLimit("save", key)
    if not canProceed then
        warn("Save rate limit exceeded for key:", key)
        return false, rateLimitError
    end
    
    -- Get the appropriate DataStore
    local dataStore = getDataStore(storeName)
    if not dataStore then
        return false, "Failed to get DataStore"
    end
    
    -- Serialize the data
    local serializedData = safeSerialize(data)
    if not serializedData then
        return false, "Failed to serialize data"
    end
    
    -- Add metadata
    local dataWithMetadata = {
        data = serializedData,
        version = DataConstants.STORAGE_VERSION,
        timestamp = os.time(),
        server = getServerId()
    }
    
    -- Track metrics
    operationMetrics.saveOperations += 1
    
    -- Attempt to save with retries
    local success, result
    local attempts = 0
    local maxAttempts = options.maxRetries or DataConstants.RATE_LIMITS.MAX_RETRY_ATTEMPTS
    
    repeat
        attempts += 1
        
        success, result = pcall(function()
            return dataStore:SetAsync(key, dataWithMetadata)
        end)
        
        if not success then
            -- Track failure and wait before retry
            operationMetrics.saveFailures += 1
            operationMetrics.lastError = tostring(result)
            operationMetrics.lastErrorTime = os.time()
            
            if attempts < maxAttempts then
                task.wait(DataConstants.RATE_LIMITS.RETRY_DELAY * attempts)
            end
        end
    until success or attempts >= maxAttempts
    
    -- If successful, create backup if enabled
    if success and (options.createBackup == nil or options.createBackup) then
        task.spawn(function()
            backupData(storeName, key, data)
        end)
    end
    
    if not success then
        warn(string.format("Failed to save data after %d attempts: %s", attempts, tostring(result)))
    end
    
    return success, success and "Success" or ("Failed after " .. attempts .. " attempts: " .. tostring(result))
end

-- Update data in DataStore with retry logic
function DataPersistence:updateData(storeName, key, updateFunction, options)
    options = options or {}
    
    -- Check parameters
    if not storeName or not key or not updateFunction or type(updateFunction) ~= "function" then
        warn("Invalid parameters for updateData")
        return false, "Invalid parameters", nil
    end
    
    -- Check rate limit
    local canProceed, rateLimitError = checkRateLimit("save", key)
    if not canProceed then
        warn("Update rate limit exceeded for key:", key)
        return false, rateLimitError, nil
    end
    
    -- Get the appropriate DataStore
    local dataStore = getDataStore(storeName)
    if not dataStore then
        return false, "Failed to get DataStore", nil
    end
    
    -- Track metrics
    operationMetrics.saveOperations += 1
    
    -- Attempt to update with retries
    local success, result, updatedData
    local attempts = 0
    local maxAttempts = options.maxRetries or DataConstants.RATE_LIMITS.MAX_RETRY_ATTEMPTS
    
    repeat
        attempts += 1
        
        success, result = pcall(function()
            return dataStore:UpdateAsync(key, function(currentData)
                local currentRawData = nil
                
                -- Extract the raw data if it exists
                if currentData and typeof(currentData) == "table" and currentData.data then
                    currentRawData = safeDeserialize(currentData.data)
                end
                
                -- Call the update function
                local newRawData
                success, newRawData = pcall(function()
                    return updateFunction(currentRawData)
                end)
                
                -- If the update function fails or returns nil, keep the current data
                if not success or newRawData == nil then
                    warn("Update function failed or returned nil:", newRawData)
                    return currentData
                end
                
                -- Store the updated data for return
                updatedData = newRawData
                
                -- Serialize and add metadata
                local serializedData = safeSerialize(newRawData)
                if not serializedData then
                    warn("Failed to serialize updated data")
                    return currentData
                end
                
                return {
                    data = serializedData,
                    version = DataConstants.STORAGE_VERSION,
                    timestamp = os.time(),
                    server = getServerId()
                }
            end)
        end)
        
        if not success then
            -- Track failure and wait before retry
            operationMetrics.saveFailures += 1
            operationMetrics.lastError = tostring(result)
            operationMetrics.lastErrorTime = os.time()
            
            if attempts < maxAttempts then
                task.wait(DataConstants.RATE_LIMITS.RETRY_DELAY * attempts)
            end
        end
    until success or attempts >= maxAttempts
    
    -- If successful, create backup if enabled
    if success and updatedData and (options.createBackup == nil or options.createBackup) then
        task.spawn(function()
            backupData(storeName, key, updatedData)
        end)
    end
    
    if not success then
        warn(string.format("Failed to update data after %d attempts: %s", attempts, tostring(result)))
    end
    
    return success, success and "Success" or ("Failed after " .. attempts .. " attempts: " .. tostring(result)), updatedData
end

-- Load data from DataStore with retry logic
function DataPersistence:loadData(storeName, key, options)
    options = options or {}
    
    -- Check parameters
    if not storeName or not key then
        warn("Invalid parameters for loadData")
        return false, "Invalid parameters", nil
    end
    
    -- Check rate limit
    local canProceed, rateLimitError = checkRateLimit("load", key)
    if not canProceed then
        warn("Load rate limit exceeded for key:", key)
        return false, rateLimitError, nil
    end
    
    -- Get the appropriate DataStore
    local dataStore = getDataStore(storeName)
    if not dataStore then
        return false, "Failed to get DataStore", nil
    end
    
    -- Track metrics
    operationMetrics.loadOperations += 1
    
    -- Attempt to load with retries
    local success, result
    local attempts = 0
    local maxAttempts = options.maxRetries or DataConstants.RATE_LIMITS.MAX_RETRY_ATTEMPTS
    
    repeat
        attempts += 1
        
        success, result = pcall(function()
            return dataStore:GetAsync(key)
        end)
        
        if not success then
            -- Track failure and wait before retry
            operationMetrics.loadFailures += 1
            operationMetrics.lastError = tostring(result)
            operationMetrics.lastErrorTime = os.time()
            
            if attempts < maxAttempts then
                task.wait(DataConstants.RATE_LIMITS.RETRY_DELAY * attempts)
            end
        end
    until success or attempts >= maxAttempts
    
    if not success then
        warn(string.format("Failed to load data after %d attempts: %s", attempts, tostring(result)))
        
        -- Try to load from backup if enabled
        if options.useBackup then
            warn("Attempting to load from backup")
            local backupData = getBackupData(storeName, key)
            
            if backupData then
                return true, "Loaded from backup", backupData
            end
        end
        
        return false, "Failed to load data", nil
    end
    
    -- If no data was found
    if not result then
        return true, "No data found", nil
    end
    
    -- Extract and deserialize the actual data
    if typeof(result) == "table" and result.data then
        local deserializedData = safeDeserialize(result.data)
        
        if deserializedData then
            return true, "Success", deserializedData
        else
            warn("Failed to deserialize loaded data")
            
            -- Try to load from backup if enabled
            if options.useBackup then
                warn("Attempting to load from backup due to deserialization failure")
                local backupData = getBackupData(storeName, key)
                
                if backupData then
                    return true, "Loaded from backup", backupData
                end
            end
            
            return false, "Failed to deserialize data", nil
        end
    else
        -- Legacy data format (no metadata)
        return true, "Legacy format", result
    end
end

-- Remove data from DataStore with retry logic
function DataPersistence:removeData(storeName, key, options)
    options = options or {}
    
    -- Check parameters
    if not storeName or not key then
        warn("Invalid parameters for removeData")
        return false, "Invalid parameters"
    end
    
    -- Check rate limit
    local canProceed, rateLimitError = checkRateLimit("save", key)
    if not canProceed then
        warn("Remove rate limit exceeded for key:", key)
        return false, rateLimitError
    end
    
    -- Get the appropriate DataStore
    local dataStore = getDataStore(storeName)
    if not dataStore then
        return false, "Failed to get DataStore"
    end
    
    -- If backup is requested, get the current data before removal
    if options.createBackup then
        local success, _, currentData = self:loadData(storeName, key)
        
        if success and currentData then
            task.spawn(function()
                backupData(storeName, key, currentData)
            end)
        end
    end
    
    -- Track metrics
    operationMetrics.saveOperations += 1
    
    -- Attempt to remove with retries
    local success, result
    local attempts = 0
    local maxAttempts = options.maxRetries or DataConstants.RATE_LIMITS.MAX_RETRY_ATTEMPTS
    
    repeat
        attempts += 1
        
        success, result = pcall(function()
            return dataStore:RemoveAsync(key)
        end)
        
        if not success then
            -- Track failure and wait before retry
            operationMetrics.saveFailures += 1
            operationMetrics.lastError = tostring(result)
            operationMetrics.lastErrorTime = os.time()
            
            if attempts < maxAttempts then
                task.wait(DataConstants.RATE_LIMITS.RETRY_DELAY * attempts)
            end
        end
    until success or attempts >= maxAttempts
    
    if not success then
        warn(string.format("Failed to remove data after %d attempts: %s", attempts, tostring(result)))
    end
    
    return success, success and "Success" or ("Failed after " .. attempts .. " attempts: " .. tostring(result))
end

-- List all keys matching a prefix
function DataPersistence:listKeys(storeName, prefix, pageSize, cursor)
    -- Check parameters
    if not storeName then
        warn("Invalid parameters for listKeys")
        return false, "Invalid parameters", nil, nil
    end
    
    pageSize = pageSize or 50
    prefix = prefix or ""
    
    -- Get the appropriate DataStore
    local dataStore = getDataStore(storeName)
    if not dataStore then
        return false, "Failed to get DataStore", nil, nil
    end
    
    -- Attempt to list keys
    local success, pages, nextCursor
    
    success, pages = pcall(function()
        return dataStore:ListKeysAsync(prefix, pageSize, cursor)
    end)
    
    if not success then
        warn("Failed to list keys:", pages)
        return false, "Failed to list keys: " .. tostring(pages), nil, nil
    end
    
    -- Extract keys from pages
    local keys = {}
    
    success, nextCursor = pcall(function()
        return pages:GetCurrentPage()
    end)
    
    if not success then
        warn("Failed to get current page:", nextCursor)
        return false, "Failed to get page: " .. tostring(nextCursor), nil, nil
    end
    
    for _, keyInfo in ipairs(nextCursor) do
        table.insert(keys, keyInfo.key)
    end
    
    -- Check if there are more pages
    local hasMorePages = pcall(function()
        return pages:AdvanceToNextPageAsync()
    end)
    
    if hasMorePages then
        nextCursor = pages
    else
        nextCursor = nil
    end
    
    return true, "Success", keys, nextCursor
end

-- Get metrics about data operations
function DataPersistence:getMetrics()
    return DataTypes.deepCopy(operationMetrics)
end

-- Attempt to acquire a session lock for a user
function DataPersistence:acquireSessionLock(userId)
    return acquireSessionLock(userId)
end

-- Release a session lock for a user
function DataPersistence:releaseSessionLock(userId)
    return releaseSessionLock(userId)
end

-- Check if a user has an active session lock on this server
function DataPersistence:hasSessionLock(userId)
    return sessionLocks[userId] ~= nil
end

-- Initialize the module
function DataPersistence:initialize()
    if self.initialized then
        return true
    end
    
    print("DataPersistence: Initializing...")
    
    -- Create main data store
    local success, result = pcall(function()
        return DataStoreService:GetDataStore("PlayerData_v2")
    end)
    
    if not success then
        warn("DataPersistence: Failed to create main data store - " .. tostring(result))
        return false
    end
    
    self.dataStore = result
    print("DataPersistence: Main data store created")
    
    -- Create backup data store
    success, result = pcall(function()
        return DataStoreService:GetDataStore("PlayerData_Backup_v2")
    end)
    
    if success then
        self.backupStore = result
        print("DataPersistence: Backup data store created")
    else
        warn("DataPersistence: Failed to create backup data store - " .. tostring(result))
    end
    
    -- Set up auto-save
    task.spawn(function()
        while true do
            task.wait(300) -- Auto-save every 5 minutes
            self:AutoSave()
        end
    end)
    
    self.initialized = true
    print("DataPersistence: Initialization complete")
    return true
end

-- Get player data
function DataPersistence:GetPlayerData(userId)
    if not self.initialized then
        warn("DataPersistence: Not initialized")
        return nil
    end
    
    if not userId then
        warn("DataPersistence: Invalid userId")
        return nil
    end
    
    -- Check rate limiting
    if isRateLimited(loadRateLimiter, userId, 10, 60) then -- Max 10 loads per minute
        warn("DataPersistence: Rate limit exceeded for userId " .. userId)
        return nil
    end
    
    -- Try to get from cache first
    if self.cache and self.cache[userId] then
        return deepCopy(self.cache[userId])
    end
    
    -- Try main data store
    local success, data = pcall(function()
        return self.dataStore:GetAsync(userId)
    end)
    
    if success and data then
        -- Cache the data
        if not self.cache then self.cache = {} end
        self.cache[userId] = deepCopy(data)
        
        -- Update metrics
        operationMetrics.loadOperations = operationMetrics.loadOperations + 1
        return data
    end
    
    -- Try backup store if main store failed
    if self.backupStore then
        success, data = pcall(function()
            return self.backupStore:GetAsync(userId)
        end)
        
        if success and data then
            -- Cache the data
            if not self.cache then self.cache = {} end
            self.cache[userId] = deepCopy(data)
            
            -- Update metrics
            operationMetrics.loadOperations = operationMetrics.loadOperations + 1
            return data
        end
    end
    
    -- Update metrics
    operationMetrics.loadFailures = operationMetrics.loadFailures + 1
    operationMetrics.lastError = "Failed to load data"
    operationMetrics.lastErrorTime = os.time()
    
    return nil
end

-- Save player data
function DataPersistence:SavePlayerData(userId, data, immediate)
    if not self.initialized then
        warn("DataPersistence: Not initialized")
        return false
    end
    
    if not userId or not data then
        warn("DataPersistence: Invalid parameters")
        return false
    end
    
    -- Check rate limiting
    if isRateLimited(saveRateLimiter, userId, 5, 60) then -- Max 5 saves per minute
        warn("DataPersistence: Rate limit exceeded for userId " .. userId)
        return false
    end
    
    -- Update cache
    if not self.cache then self.cache = {} end
    self.cache[userId] = deepCopy(data)
    
    -- Save to main store
    local success, result = pcall(function()
        return self.dataStore:SetAsync(userId, data)
    end)
    
    if success then
        -- Update metrics
        operationMetrics.saveOperations = operationMetrics.saveOperations + 1
        return true
    end
    
    -- Try backup store if main store failed
    if self.backupStore then
        success, result = pcall(function()
            return self.backupStore:SetAsync(userId, data)
        end)
        
        if success then
            -- Update metrics
            operationMetrics.saveOperations = operationMetrics.saveOperations + 1
            return true
        end
    end
    
    -- Update metrics
    operationMetrics.saveFailures = operationMetrics.saveFailures + 1
    operationMetrics.lastError = "Failed to save data"
    operationMetrics.lastErrorTime = os.time()
    
    return false
end

-- Auto-save all cached data
function DataPersistence:AutoSave()
    if not self.initialized or not self.cache then
        return
    end
    
    print("DataPersistence: Starting auto-save...")
    local saved = 0
    local failed = 0
    
    for userId, data in pairs(self.cache) do
        if self:SavePlayerData(userId, data, false) then
            saved = saved + 1
        else
            failed = failed + 1
        end
    end
    
    print("DataPersistence: Auto-save complete - " .. saved .. " saved, " .. failed .. " failed")
end

-- Get operation metrics
function DataPersistence:GetMetrics()
    return deepCopy(operationMetrics)
end

-- Clear cache for a player
function DataPersistence:ClearCache(userId)
    if self.cache then
        self.cache[userId] = nil
    end
end

-- Clear all cache
function DataPersistence:ClearAllCache()
    self.cache = {}
end

return DataPersistence
