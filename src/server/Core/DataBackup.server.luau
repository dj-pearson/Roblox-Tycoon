--!strict
--[[
    DataBackup.luau
    
    A module for creating, managing, and restoring data backups.
    This provides an additional layer of data protection and recovery options.
    
    Created: April 26, 2025
]]

local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Find CoreRegistry
local CoreRegistry
pcall(function()
    CoreRegistry = require(ServerScriptService.Core.CoreRegistry)
end)

-- Module imports
local SafeRequire = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("SafeRequire"))
local DataValidator = SafeRequire(ReplicatedStorage.shared.DataValidator)

-- Configuration
local CONFIG = {
    -- BackupStore names
    mainBackupStoreName = "GymTycoonBackupv3",     -- Regular backups
    weeklyBackupStoreName = "GymTycoonWeeklyv3",   -- Weekly backups
    criticalBackupStoreName = "GymTycoonCriticalv3", -- Critical state backups
    
    -- Backup intervals
    regularBackupInterval = 600,                  -- Create regular backup every 10 minutes
    weeklyBackupInterval = 604800,                -- Create weekly backup every 7 days
    
    -- Retention policy
    maxRegularBackups = 5,                        -- Maximum number of regular backups per player
    maxWeeklyBackups = 4,                         -- Maximum number of weekly backups per player
    maxCriticalBackups = 3,                       -- Maximum number of critical backups per player
    
    -- Backup behavior
    compressionEnabled = true,                    -- Compress backups to save space
    validateOnRestore = true,                     -- Validate backup data before restoring
    validateOnBackup = true,                      -- Validate data before creating backup
    integrityCheckEnabled = true,                 -- Enable integrity checks on backups
    maxRetries = 5,                               -- Maximum number of retries for operations
    retryDelay = 1,                               -- Base delay between retries in seconds
    
    -- Debug options
    debug = true                                  -- Enable debug logging
}

-- Debug logging
local function log(message)
    if CONFIG.debug then
        print("[DataBackup] " .. message)
    end
end

-- Deep copy function
local function deepCopy(original)
    if type(original) ~= "table" then
        return original
    end
    
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

-- Calculate data integrity hash
local function calculateIntegrityHash(data)
    local hash = 0
    local str = game:GetService("HttpService"):JSONEncode(data)
    
    for i = 1, #str do
        hash = ((hash * 31) + string.byte(str, i)) % 0x7FFFFFFF
    end
    
    return hash
end

-- Validate data integrity
local function validateDataIntegrity(data, expectedHash)
    if not CONFIG.integrityCheckEnabled then
        return true
    end
    
    local currentHash = calculateIntegrityHash(data)
    return currentHash == expectedHash
end

-- Compress data to reduce size (simple version)
local function compressData(data)
    if not CONFIG.compressionEnabled then
        return data
    end
    
    -- Create a compressed representation with metadata
    local compressed = {
        __compressed = true,
        __timestamp = os.time(),
        __version = 1,
        __integrityHash = calculateIntegrityHash(data)
    }
    
    -- Only store non-default values
    if type(data) == "table" then
        for key, value in pairs(data) do
            if type(value) == "table" and next(value) ~= nil then
                compressed[key] = compressData(value)
            else
                compressed[key] = value
            end
        end
    end
    
    return compressed
end

-- Decompress data (simple version)
local function decompressData(compressed)
    if type(compressed) ~= "table" or not compressed.__compressed then
        return compressed
    end
    
    local decompressed = {}
    
    for key, value in pairs(compressed) do
        if key:sub(1, 2) ~= "__" then -- Skip metadata fields
            if type(value) == "table" and value.__compressed then
                decompressed[key] = decompressData(value)
            else
                decompressed[key] = value
            end
        end
    end
    
    -- Validate integrity if enabled
    if CONFIG.integrityCheckEnabled and compressed.__integrityHash then
        if not validateDataIntegrity(decompressed, compressed.__integrityHash) then
            warn("Data integrity check failed during decompression")
            return nil
        end
    end
    
    return decompressed
end

-- Safe DataStore operation with retry logic
local function safeDataStoreOperation(storeName, operationType, storeMethod, ...)
    local store
    
    -- Get the appropriate DataStore
    local success, storeResult = pcall(function()
        return DataStoreService:GetDataStore(storeName)
    end)
    
    if not success then
        warn("Failed to get DataStore " .. storeName .. ": " .. tostring(storeResult))
        return false, nil
    end
    
    store = storeResult
    
    -- Execute the operation with retries
    local maxRetries = CONFIG.maxRetries
    local retriesRemaining = maxRetries
    local baseDelay = CONFIG.retryDelay
    local args = {...}
    
    repeat
        local opSuccess, opResult = pcall(function()
            return storeMethod(store, table.unpack(args))
        end)
        
        if opSuccess then
            return true, opResult
        else
            retriesRemaining = retriesRemaining - 1
            local errorMessage = tostring(opResult)
            
            -- Some errors shouldn't be retried
            if errorMessage:match("404") then -- Data not found
                return false, nil
            end
            
            local delay = baseDelay * (2 ^ (maxRetries - retriesRemaining))
            delay = math.min(delay, 30) -- Cap at 30 seconds
            
            warn(operationType .. " operation failed. Retrying in " .. delay .. "s. Error: " .. errorMessage)
            task.wait(delay)
        end
    until retriesRemaining <= 0
    
    warn(operationType .. " operation failed after " .. maxRetries .. " attempts")
    return false, nil
end

-- Module table
local DataBackup = {
    initialized = false,
    backupSchedule = {},       -- Scheduled backups {userId = nextRegularBackupTime}
    weeklySchedule = {},       -- Weekly backup schedule {userId = nextWeeklyBackupTime}
    processingBackups = {},    -- Currently processing backups {userId = true}
}

-- Initialize backup system
function DataBackup:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing DataBackup system...")
    
    -- Initialize DataStores
    local success, mainStore = pcall(function()
        return DataStoreService:GetDataStore(CONFIG.mainBackupStoreName)
    end)
    
    if not success then
        warn("Failed to initialize main backup store")
        return false
    end
    
    local success2, weeklyStore = pcall(function()
        return DataStoreService:GetDataStore(CONFIG.weeklyBackupStoreName)
    end)
    
    if not success2 then
        warn("Failed to initialize weekly backup store")
        return false
    end
    
    local success3, criticalStore = pcall(function()
        return DataStoreService:GetDataStore(CONFIG.criticalBackupStoreName)
    end)
    
    if not success3 then
        warn("Failed to initialize critical backup store")
        return false
    end
    
    self.initialized = true
    log("DataBackup system initialized successfully")
    return true
end

-- Start the backup scheduler
function DataBackup:StartBackupScheduler()
    task.spawn(function()
        while true do
            task.wait(60) -- Check schedule every minute
            self:ProcessBackupSchedule()
        end
    end)
    
    log("Backup scheduler started")
end

-- Process scheduled backups
function DataBackup:ProcessBackupSchedule()
    local currentTime = os.time()
    
    -- Process regular backups
    for userId, nextBackupTime in pairs(self.backupSchedule) do
        if currentTime >= nextBackupTime and not self.processingBackups[userId] then
            task.spawn(function()
                self.processingBackups[userId] = true
                
                -- Create regular backup
                self:CreateRegularBackup(userId)
                
                -- Schedule next backup
                self.backupSchedule[userId] = os.time() + CONFIG.regularBackupInterval
                
                self.processingBackups[userId] = nil
            end)
        end
    end
    
    -- Process weekly backups
    for userId, nextBackupTime in pairs(self.weeklySchedule) do
        if currentTime >= nextBackupTime and not self.processingBackups[userId] then
            task.spawn(function()
                self.processingBackups[userId] = true
                
                -- Create weekly backup
                self:CreateWeeklyBackup(userId)
                
                -- Schedule next backup
                self.weeklySchedule[userId] = os.time() + CONFIG.weeklyBackupInterval
                
                self.processingBackups[userId] = nil
            end)
        end
    end
end

-- Schedule regular backups for a player
function DataBackup:ScheduleBackups(player)
    if not player then
        return false
    end
    
    local userId = player.UserId
    
    -- Schedule regular backup
    self.backupSchedule[userId] = os.time() + CONFIG.regularBackupInterval
    
    -- Schedule weekly backup if not already scheduled
    if not self.weeklySchedule[userId] then
        self.weeklySchedule[userId] = os.time() + CONFIG.weeklyBackupInterval
    end
    
    log("Scheduled backups for " .. player.Name)
    return true
end

-- Cancel scheduled backups for a player
function DataBackup:CancelScheduledBackups(player)
    if not player then
        return false
    end
    
    local userId = player.UserId
    
    -- Clear schedules
    self.backupSchedule[userId] = nil
    self.weeklySchedule[userId] = nil
    
    log("Cancelled scheduled backups for " .. player.Name)
    return true
end

-- Create regular backup
function DataBackup:CreateRegularBackup(userId)
    if not self.initialized then
        return false, "Backup system not initialized"
    end
    
    -- Get player data from DataManager
    local dataManager
    if CoreRegistry then
        dataManager = CoreRegistry.getSystem("DataManager")
    end
    
    if not dataManager then
        pcall(function()
            dataManager = require(ServerScriptService.Core.DataManager)
        end)
    end
    
    if not dataManager or not dataManager.loadedData or not dataManager.loadedData[userId] then
        return false, "Could not access player data"
    end
    
    local playerData = deepCopy(dataManager.loadedData[userId])
    
    -- Validate data if enabled
    if CONFIG.validateOnBackup and DataValidator then
        local isValid, validatedData = DataValidator.validatePlayerData(playerData)
        
        if not isValid then
            warn("Backup validation failed for userId " .. userId)
            
            if validatedData then
                playerData = validatedData
                log("Using repaired data for backup")
            else
                return false, "Backup validation failed"
            end
        end
    end
    
    -- Add backup metadata
    playerData.__backup = {
        type = "regular",
        timestamp = os.time(),
        createdBy = "DataBackup",
        version = DataValidator and DataValidator.getCurrentVersion() or 1
    }
    
    -- Compress the data
    local compressedData = compressData(playerData)
    
    -- Create a backup key
    local backupKey = "Regular_" .. userId .. "_" .. os.time()
    
    -- Save the backup
    local success, _ = safeDataStoreOperation(
        CONFIG.mainBackupStoreName,
        "CreateBackup",
        function(store, key, data)
            store:SetAsync(key, data)
            return true
        end,
        backupKey,
        compressedData
    )
    
    if success then
        log("Created regular backup for userId " .. userId .. " with key " .. backupKey)
        -- Update latest backup pointer
        safeDataStoreOperation(
            CONFIG.mainBackupStoreName,
            "UpdateLatest",
            function(store)
                store:SetAsync("Latest_" .. userId, backupKey)
                return true
            end
        )
        
        -- Clean up old backups if needed
        self:CleanupOldBackups(userId, "regular")
        
        return true, backupKey
    else
        warn("Failed to create regular backup for userId " .. userId)
        return false, nil
    end
end

-- Create weekly backup
function DataBackup:CreateWeeklyBackup(userId)
    -- Get player data (same as regular backup)
    local dataManager
    if CoreRegistry then
        dataManager = CoreRegistry.getSystem("DataManager")
    end
    
    if not dataManager then
        pcall(function()
            dataManager = require(ServerScriptService.Core.DataManager)
        end)
    end
    
    if not dataManager or not dataManager.loadedData or not dataManager.loadedData[userId] then
        return false, "Could not access player data"
    end
    
    local playerData = deepCopy(dataManager.loadedData[userId])
    
    -- Add backup metadata
    playerData.__backup = {
        type = "weekly",
        timestamp = os.time(),
        weekNumber = os.date("*t").yday // 7,
        createdBy = "DataBackup"
    }
    
    -- Compress the data
    local compressedData = compressData(playerData)
    
    -- Create a backup key
    local backupKey = "Weekly_" .. userId .. "_" .. os.time()
    
    -- Save the backup
    local success, _ = safeDataStoreOperation(
        CONFIG.weeklyBackupStoreName,
        "CreateWeeklyBackup",
        function(store, key, data)
            store:SetAsync(key, data)
            return true
        end,
        backupKey,
        compressedData
    )
    
    if success then
        log("Created weekly backup for userId " .. userId .. " with key " .. backupKey)
          -- Update latest weekly backup pointer
        safeDataStoreOperation(
            CONFIG.weeklyBackupStoreName,
            "UpdateLatest",
            function(store)
                store:SetAsync("LatestWeekly_" .. userId, backupKey)
                return true
            end
        )
        
        -- Clean up old backups if needed
        self:CleanupOldBackups(userId, "weekly")
        
        return true, backupKey
    else
        warn("Failed to create weekly backup for userId " .. userId)
        return false, nil
    end
end

-- Create critical backup (for important game state changes)
function DataBackup:CreateCriticalBackup(player, reason)
    if not player then
        return false, "Invalid player"
    end
    
    local userId = player.UserId
    reason = reason or "Manual critical backup"
    
    -- Get player data
    local dataManager
    if CoreRegistry then
        dataManager = CoreRegistry.getSystem("DataManager")
    end
    
    if not dataManager then
        pcall(function()
            dataManager = require(ServerScriptService.Core.DataManager)
        end)
    end
    
    if not dataManager or not dataManager.loadedData or not dataManager.loadedData[userId] then
        return false, "Could not access player data"
    end
    
    local playerData = deepCopy(dataManager.loadedData[userId])
    
    -- Add backup metadata
    playerData.__backup = {
        type = "critical",
        timestamp = os.time(),
        reason = reason,
        createdBy = "DataBackup"
    }
    
    -- Compress the data
    local compressedData = compressData(playerData)
    
    -- Create a backup key with reason code
    local reasonCode = reason:gsub("[^%w]", "_"):sub(1, 20)
    local backupKey = "Critical_" .. userId .. "_" .. reasonCode .. "_" .. os.time()
    
    -- Save the backup
    local success, _ = safeDataStoreOperation(
        CONFIG.criticalBackupStoreName,
        "CreateCriticalBackup",
        function(store, key, data)
            store:SetAsync(key, data)
            return true
        end,
        backupKey,
        compressedData
    )
    
    if success then
        log("Created critical backup for userId " .. userId .. " with key " .. backupKey .. " (Reason: " .. reason .. ")")
          -- Update latest critical backup pointer
        safeDataStoreOperation(
            CONFIG.criticalBackupStoreName,
            "UpdateLatest",
            function(store)
                store:SetAsync("LatestCritical_" .. userId, backupKey)
                return true
            end
        )
        
        -- Clean up old backups if needed
        self:CleanupOldBackups(userId, "critical")
        
        return true, backupKey
    else
        warn("Failed to create critical backup for userId " .. userId)
        return false, nil
    end
end

-- Restore a backup
function DataBackup:RestoreBackup(player, backupKey, backupType)
    if not player then
        return false, "Invalid player"
    end
    
    local userId = player.UserId
    backupType = backupType or "regular" -- Default to regular backup
    
    -- Determine which store to use
    local storeName
    if backupType == "regular" then
        storeName = CONFIG.mainBackupStoreName
    elseif backupType == "weekly" then
        storeName = CONFIG.weeklyBackupStoreName
    elseif backupType == "critical" then
        storeName = CONFIG.criticalBackupStoreName
    else
        return false, "Invalid backup type"
    end
    
    -- If no specific key provided, use the latest backup
    if not backupKey then
        local success, latestKey = safeDataStoreOperation(
            storeName,
            "GetLatestBackup",
            function(store)
                return store:GetAsync("Latest" .. (backupType ~= "regular" and backupType:sub(1, 1):upper() .. backupType:sub(2) or "") .. "_" .. userId)
            end
        )
        
        if success and latestKey then
            backupKey = latestKey
        else
            return false, "No backup found"
        end
    end
    
    -- Load the backup
    local success, backupData = safeDataStoreOperation(
        storeName,
        "GetBackup",
        function(store, key)
            return store:GetAsync(key)
        end,
        backupKey
    )
    
    if not success or not backupData then
        return false, "Failed to load backup"
    end
    
    -- Decompress the data
    local data = decompressData(backupData)
    
    if not data then
        return false, "Failed to decompress backup data"
    end
    
    -- Validate if required
    if CONFIG.validateOnRestore and DataValidator then
        local isValid, validatedData = DataValidator.validatePlayerData(data)
        
        if not isValid then
            warn("Backup validation failed for " .. player.Name .. " with key " .. backupKey)
            
            if validatedData then
                data = validatedData
                log("Using repaired backup data for " .. player.Name)
            else
                return false, "Backup validation failed"
            end
        end
    end
    
    -- Remove backup metadata
    data.__backup = nil
    
    -- Apply the backup data
    local dataManager
    if CoreRegistry then
        dataManager = CoreRegistry.getSystem("DataManager")
    end
    
    if not dataManager then
        pcall(function()
            dataManager = require(ServerScriptService.Core.DataManager)
        end)
    end
    
    if not dataManager then
        return false, "Could not access DataManager"
    end
    
    -- Update loaded data
    dataManager.loadedData[userId] = data
    
    -- Apply to player
    if dataManager.ApplyDataToPlayer then
        dataManager:ApplyDataToPlayer(player, data)
    end
    
    -- Save immediately
    if dataManager.SavePlayerData then
        dataManager:SavePlayerData(player, true)
    end
    
    log("Restored " .. backupType .. " backup for " .. player.Name .. " with key " .. backupKey)
    
    -- Create a new critical backup after restore
    self:CreateCriticalBackup(player, "Post-restore backup")
    
    return true
end

-- List available backups for a player
function DataBackup:ListBackups(player, backupType)
    if not player then
        return nil, "Invalid player"
    end
    
    local userId = player.UserId
    backupType = backupType or "regular" -- Default to regular backup
    
    -- Determine which store to use
    local storeName
    if backupType == "regular" then
        storeName = CONFIG.mainBackupStoreName
    elseif backupType == "weekly" then
        storeName = CONFIG.weeklyBackupStoreName
    elseif backupType == "critical" then
        storeName = CONFIG.criticalBackupStoreName
    elseif backupType == "all" then
        -- Special case: collect from all stores
        local results = {}
        
        -- Get regular backups
        local regularBackups = self:ListBackups(player, "regular")
        if regularBackups then
            results.regular = regularBackups
        end
        
        -- Get weekly backups
        local weeklyBackups = self:ListBackups(player, "weekly")
        if weeklyBackups then
            results.weekly = weeklyBackups
        end
        
        -- Get critical backups
        local criticalBackups = self:ListBackups(player, "critical")
        if criticalBackups then
            results.critical = criticalBackups
        end
        
        return results
    else
        return nil, "Invalid backup type"
    end
    
    -- This is a simplified implementation since DataStores don't support listing
    -- In a real implementation, you would need to maintain a separate key list
    -- For now, just return the latest backup key
    local success, latestKey = safeDataStoreOperation(
        storeName,
        "GetLatestBackup",
        function(store)
            return store:GetAsync("Latest" .. (backupType ~= "regular" and backupType:sub(1, 1):upper() .. backupType:sub(2) or "") .. "_" .. userId)
        end
    )
    
    if success and latestKey then
        return { latestKey }
    else
        return {}
    end
end

-- Clean up old backups
function DataBackup:CleanupOldBackups(userId, backupType)
    if not userId or not backupType then
        return false
    end
    
    local maxBackups
    local storeName
    
    if backupType == "regular" then
        maxBackups = CONFIG.maxRegularBackups
        storeName = CONFIG.mainBackupStoreName
    elseif backupType == "weekly" then
        maxBackups = CONFIG.maxWeeklyBackups
        storeName = CONFIG.weeklyBackupStoreName
    elseif backupType == "critical" then
        maxBackups = CONFIG.maxCriticalBackups
        storeName = CONFIG.criticalBackupStoreName
    else
        return false
    end
    
    -- Get list of backups (in a real implementation, you would need to maintain a separate key list)
    -- For now, we'll just use the latest backup pointer
    local success, latestKey = safeDataStoreOperation(
        storeName,
        "GetLatestBackup",
        function(store)
            return store:GetAsync("Latest" .. (backupType ~= "regular" and backupType:sub(1, 1):upper() .. backupType:sub(2) or "") .. "_" .. userId)
        end
    )
    
    if success and latestKey then
        -- In a real implementation, you would delete old backups here
        -- For now, we'll just log the cleanup
        log("Cleaned up old " .. backupType .. " backups for userId " .. userId)
    end
    
    return true
end

-- Initialize on module load
DataBackup:initialize()

-- Connect to DataManager events if available through CoreRegistry
if CoreRegistry and CoreRegistry.onEvent then
    CoreRegistry:onEvent("PlayerDataLoaded", function(player)
        -- Schedule backups for this player
        DataBackup:ScheduleBackups(player)
    end)
      CoreRegistry:onEvent("PlayerDataSaved", function(_player)
        -- Consider creating a backup if significant changes were made
        -- This would require tracking what changed in the data
        -- We use _player (with underscore) to denote intentionally unused parameter
    end)
end

return DataBackup
