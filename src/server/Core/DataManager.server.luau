--!strict
--[[
    DataManager.server.luau
    
    A robust data management system with built-in validation, redundancy,
    and recovery features to address the data system issues identified.
    
    Created: April 26, 2025
]]

-- Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Find CoreRegistry
local CoreRegistry
pcall(function()
    CoreRegistry = require(ServerScriptService.Core.CoreRegistry)
end)

-- Module imports
local SafeRequire = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("SafeRequire"))
local DataValidator = SafeRequire(ReplicatedStorage.shared.DataValidator)
local SafeWaitForChild = SafeRequire(ReplicatedStorage.shared.SafeWaitForChild)

-- Configuration
local CONFIG = {
    -- DataStore config
    mainDataStoreName = "GymTycoonDatav3",       -- Primary data
    backupDataStoreName = "GymTycoonBackupv3",   -- Backup copies
    sessionStoreName = "GymTycoonSessionv3",     -- Session tracking
    versionedStoreName = "GymTycoonVersionedv3", -- Historical versions
    
    -- Timing config
    saveInterval = 120,                          -- Auto-save every 2 minutes
    backupInterval = 600,                        -- Create backup every 10 minutes
    sessionTimeout = 1800,                       -- Session lock times out after 30 minutes
    shutdownTimeout = 10,                        -- Max seconds to wait during shutdown
    
    -- Retry config
    maxRetries = 5,                              -- Max retry attempts
    retryBaseDelay = 1,                          -- Base delay between retries
    
    -- Version control
    currentDataVersion = 1,                      -- Current data schema version
    maxVersionsToKeep = 5,                       -- Number of historical versions to keep
    
    -- Recovery options
    attemptDataRecovery = true,                  -- Try to recover corrupted data
    validateOnLoad = true,                       -- Validate data when loading
    validateOnSave = true,                       -- Validate data before saving
    createChecksums = true,                      -- Create checksums for data integrity
    
    -- Debug options
    debug = true,                                -- Enable debug logging
    trackOperations = true,                      -- Track data operation counts
    telemetry = true                             -- Gather performance telemetry
}

-- Debug logging
local function log(message)
    if CONFIG.debug then
        print("[DataManager] " .. message)
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

-- Default data structure
local DEFAULT_DATA = {
    -- Economy
    cash = 1000,
    totalEarned = 0,
    
    -- Progression
    equipmentPurchased = {},
    equipmentCount = 0,
    gymLevel = 1,
    memberCount = 0,
    vipCount = 0,
    
    -- Stats
    playTime = 0,
    lastPlayed = 0,
    
    -- Version control
    dataVersion = CONFIG.currentDataVersion,
    
    -- Metadata
    __lastModified = 0,
    __checksum = nil
}

-- Operation tracking
local operationStats = {
    loads = { total = 0, success = 0, failed = 0, recovered = 0 },
    saves = { total = 0, success = 0, failed = 0 },
    autoSaves = { total = 0, success = 0, failed = 0 },
    backups = { total = 0, success = 0, failed = 0 },
    sessions = { acquired = 0, released = 0, timeouts = 0 }
}

-- Module table
local DataManager = {
    initialized = false,
    loadedData = {},        -- Player data cache (userId -> data)
    activeSessions = {},    -- Track active player sessions (userId -> timestamp)
    saveQueue = {},         -- Queue of pending saves (userId -> { data = data, priority = 1-5 })
    backupQueue = {},       -- Queue of pending backups (userId -> data)
    autoSaveTimers = {},    -- Active auto-save timers (userId -> thread)
    isSaving = {},          -- Tracks active save operations (userId -> true)
    dataVersion = CONFIG.currentDataVersion
}

-- Initialize DataStores
function DataManager:Initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing DataManager...")
    
    local success, result = pcall(function()
        -- Initialize main datastores
        self.dataStore = DataStoreService:GetDataStore(CONFIG.mainDataStoreName)
        self.backupStore = DataStoreService:GetDataStore(CONFIG.backupDataStoreName)
        self.sessionStore = DataStoreService:GetDataStore(CONFIG.sessionStoreName)
        self.versionedStore = DataStoreService:GetOrderedDataStore(CONFIG.versionedStoreName)
        
        -- Register with CoreRegistry if available
        if CoreRegistry and CoreRegistry.registerSystem then
            CoreRegistry:registerSystem("DataManager", self)
            log("Registered with CoreRegistry")
        end
        
        -- Set up event handlers
        self:SetupEvents()
        
        -- Start save queue processor
        self:StartSaveQueueProcessor()
        
        return true
    end)
    
    if success then
        log("DataManager initialized successfully")
        self.initialized = true
        return true
    else
        warn("Failed to initialize DataManager: " .. tostring(result))
        return false
    end
end

-- Set up event handlers
function DataManager:SetupEvents()
    log("Setting up event handlers")
    
    -- Player Added
    Players.PlayerAdded:Connect(function(player)
        task.spawn(function()
            log("Player joined: " .. player.Name)
            
            -- Wait a short time for player to fully load
            task.wait(1)
            
            -- Acquire session lock
            local lockAcquired = self:AcquireSessionLock(player)
            if not lockAcquired then
                log("Warning: Session lock acquisition failed for " .. player.Name .. ". May be active in another server.")
            end
            
            -- Load player data
            local data, source = self:LoadPlayerData(player)
            
            if data then
                log("Loaded data for " .. player.Name .. " from " .. source)
                
                -- Apply data to player
                self:ApplyDataToPlayer(player, data)
                
                -- Start auto-save timer
                self:StartAutoSave(player)
                
                -- Wait a bit for the tycoon to initialize
                task.wait(3)
                
                -- Restore equipment
                self:RestorePlayerEquipment(player)
                
                -- Fire event through CoreRegistry if available
                if CoreRegistry and CoreRegistry.fireEvent then
                    CoreRegistry:fireEvent("PlayerDataLoaded", player, data)
                end
            else
                warn("Failed to load data for " .. player.Name)
                
                -- Create default data as fallback
                data = deepCopy(DEFAULT_DATA)
                self.loadedData[player.UserId] = data
                
                -- Apply default data
                self:ApplyDataToPlayer(player, data)
                
                -- Start auto-save timer
                self:StartAutoSave(player)
            end
        end)
    end)
    
    -- Player Removing
    Players.PlayerRemoving:Connect(function(player)
        task.spawn(function()
            log("Player leaving: " .. player.Name)
            
            -- Stop auto-save
            self:StopAutoSave(player)
            
            -- Save data immediately
            local success = self:SavePlayerData(player, true)
            
            if success then
                log("Successfully saved data for " .. player.Name .. " on disconnect")
            else
                warn("Failed to save data for " .. player.Name .. " on disconnect")
            end
            
            -- Create backup
            self:CreateBackup(player)
            
            -- Release session lock
            self:ReleaseSessionLock(player)
            
            -- Clear cache
            self.loadedData[player.UserId] = nil
            self.isSaving[player.UserId] = nil
            
            -- Fire event through CoreRegistry if available
            if CoreRegistry and CoreRegistry.fireEvent then
                CoreRegistry:fireEvent("PlayerDataSaved", player)
            end
        end)
    end)
    
    -- Game Close
    game:BindToClose(function()
        self:HandleShutdown()
    end)
    
    log("Event handlers set up")
end

-- Execute DataStore operation with retry logic
function DataManager:SafeDataStoreOperation(operationType, storeMethod, ...)
    local retriesRemaining = CONFIG.maxRetries
    local args = {...}
    local success, result
    local operationName = operationType .. " operation"
    
    -- Track operation
    if operationStats[operationType] then
        operationStats[operationType].total = operationStats[operationType].total + 1
    end
    
    repeat
        -- Execute the operation
        local startTime = os.clock()
        success, result = pcall(storeMethod, unpack(args))
        local elapsed = os.clock() - startTime
        
        if success then
            -- Operation succeeded
            if CONFIG.telemetry and elapsed > 0.1 then
                log(operationName .. " took " .. string.format("%.2f", elapsed) .. "s")
            end
            
            -- Track success
            if operationStats[operationType] then
                operationStats[operationType].success = operationStats[operationType].success + 1
            end
            
            return true, result
        else
            -- Operation failed
            retriesRemaining = retriesRemaining - 1
            local errorMessage = tostring(result)
            
            -- Check error type
            if errorMessage:match("404") then
                -- Data not found, don't retry
                log(operationName .. " failed: Data not found")
                return false, nil
            end
            
            local delay = CONFIG.retryBaseDelay * (2 ^ (CONFIG.maxRetries - retriesRemaining))
            delay = math.min(delay, 30) -- Cap at 30 seconds
            
            warn(operationName .. " failed. Retrying in " .. delay .. "s. Error: " .. errorMessage)
            task.wait(delay)
        end
    until retriesRemaining <= 0
    
    -- Track failure
    if operationStats[operationType] then
        operationStats[operationType].failed = operationStats[operationType].failed + 1
    end
    
    warn(operationName .. " failed after " .. CONFIG.maxRetries .. " attempts")
    return false, nil
end

-- Migrate data between versions if needed
function DataManager:MigrateData(data)
    if not data then
        return deepCopy(DEFAULT_DATA)
    end
    
    local currentVersion = data.dataVersion or 0
    
    -- Add missing fields from default data
    for key, defaultValue in pairs(DEFAULT_DATA) do
        if data[key] == nil then
            data[key] = deepCopy(defaultValue)
        end
    end
    
    -- Version 0 to 1
    if currentVersion < 1 then
        data.dataVersion = 1
        data.totalEarned = data.totalEarned or 0
        data.playTime = data.playTime or 0
        log("Migrated data from version 0 to 1")
    end
    
    -- Add timestamp
    data.__lastModified = os.time()
    
    return data
end

-- Load player data with cascading fallbacks
function DataManager:LoadPlayerData(player)
    if not player then
        return nil, "Invalid player"
    end
    
    local userId = player.UserId
    local key = "Player_" .. userId
    
    -- Check if already cached
    if self.loadedData[userId] then
        return self.loadedData[userId], "cache"
    end
    
    local data, source
    
    -- Try primary datastore
    local success, result = self:SafeDataStoreOperation("loads", function()
        return self.dataStore:GetAsync(key)
    end)
    
    if success and result then
        data = result
        source = "primary"
        log("Loaded data from primary store for " .. player.Name)
    end
    
    -- Try versioned store if primary fails
    if not data then
        log("Primary data not found for " .. player.Name .. ", trying versioned store")
        
        local vSuccess, versionData = self:SafeDataStoreOperation("loads", function()
            -- Get the latest version number
            local latestVersionKey = "LatestVersion_" .. userId
            local version = self.versionedStore:GetAsync(latestVersionKey)
            
            if version then
                local versionedKey = "Player_" .. userId .. "_V" .. version
                return self.dataStore:GetAsync(versionedKey)
            end
            return nil
        end)
        
        if vSuccess and versionData then
            data = versionData
            source = "versioned"
            log("Loaded data from versioned store for " .. player.Name)
        end
    end
    
    -- Try backup store if all else fails
    if not data and CONFIG.attemptDataRecovery then
        log("No data found for " .. player.Name .. ", trying backup store")
        
        local bSuccess, backupData = self:SafeDataStoreOperation("loads", function()
            return self.backupStore:GetAsync(key)
        end)
        
        if bSuccess and backupData then
            data = backupData
            source = "backup"
            log("Loaded data from backup store for " .. player.Name)
            operationStats.loads.recovered = operationStats.loads.recovered + 1
        end
    end
    
    -- If still no data, create default
    if not data then
        log("No saved data found for " .. player.Name .. ", creating new data")
        data = deepCopy(DEFAULT_DATA)
        source = "default"
    end
    
    -- Validate and repair if needed
    if CONFIG.validateOnLoad and DataValidator then
        local isValid, validatedData = DataValidator.validatePlayerData(data)
        
        if not isValid then
            warn("Data validation failed for " .. player.Name .. ", using repaired data")
            data = validatedData
            source = source .. " (repaired)"
        end
    end
    
    -- Migrate data if needed
    data = self:MigrateData(data)
    
    -- Add timestamp
    data.__lastModified = os.time()
    
    -- Add session start time
    data.sessionStart = os.time()
    
    -- Cache the data
    self.loadedData[userId] = data
    
    return data, source
end

-- Save player data
function DataManager:SavePlayerData(player, immediate)
    if not player then
        return false, "Invalid player"
    end
    
    local userId = player.UserId
    
    -- Check if data is loaded
    if not self.loadedData[userId] then
        return false, "No loaded data"
    end
    
    -- Get the current data
    local data = self.loadedData[userId]
    
    -- Update from player state
    self:UpdateDataFromPlayer(player)
    
    -- Validate data if enabled
    if CONFIG.validateOnSave and DataValidator then
        local isValid, validatedData = DataValidator.validatePlayerData(data)
        
        if not isValid then
            warn("Data validation failed before save for " .. player.Name)
            
            if validatedData then
                data = validatedData
                self.loadedData[userId] = data
            else
                return false, "Data validation failed"
            end
        end
    end
    
    -- Calculate play time
    if data.sessionStart then
        local sessionDuration = os.time() - data.sessionStart
        data.playTime = (data.playTime or 0) + sessionDuration
        data.sessionStart = os.time() -- Reset for next calculation
    end
    
    -- Update last modified timestamp
    data.__lastModified = os.time()
    
    -- Add checksum if enabled
    if CONFIG.createChecksums and DataValidator and DataValidator.generateChecksum then
        data.__checksum = DataValidator.generateChecksum(data)
    end
    
    -- If immediate, save directly
    if immediate then
        local key = "Player_" .. userId
        
        -- Mark as saving
        self.isSaving[userId] = true
        
        -- Execute save
        local success, _ = self:SafeDataStoreOperation("saves", function()
            self.dataStore:SetAsync(key, data)
            return true
        end)
        
        -- Clear saving flag
        self.isSaving[userId] = nil
        
        -- Save to versioned store
        if success then
            self:SaveToVersionedStore(userId, data)
        end
        
        return success
    else
        -- Add to save queue with normal priority (3)
        self:QueueSave(userId, data, 3)
        return true
    end
end

-- Queue a save operation
function DataManager:QueueSave(userId, data, priority)
    priority = priority or 3 -- Default: 3=normal, 1=highest, 5=lowest
    
    -- Remove any existing save requests for this user
    self.saveQueue[userId] = {
        data = data,
        priority = priority,
        timestamp = os.time()
    }
    
    return true
end

-- Process save queue
function DataManager:StartSaveQueueProcessor()
    task.spawn(function()
        while true do
            task.wait(1) -- Process queue every second
            
            -- Process save queue
            self:ProcessSaveQueue()
            
            -- Process backup queue
            self:ProcessBackupQueue()
        end
    end)
    
    log("Save queue processor started")
end

-- Process saves in the queue
function DataManager:ProcessSaveQueue()
    -- Find the highest priority save
    local nextSaveUserId = nil
    local highestPriority = 6 -- Higher than any valid priority
    local oldestTimestamp = os.time()
    
    for userId, saveInfo in pairs(self.saveQueue) do
        -- Skip if already saving
        if self.isSaving[userId] then
            continue
        end
        
        -- Find highest priority or oldest request at same priority
        if saveInfo.priority < highestPriority or 
           (saveInfo.priority == highestPriority and saveInfo.timestamp < oldestTimestamp) then
            highestPriority = saveInfo.priority
            oldestTimestamp = saveInfo.timestamp
            nextSaveUserId = userId
        end
    end
    
    -- If we found a save to process
    if nextSaveUserId then
        local saveInfo = self.saveQueue[nextSaveUserId]
        self.saveQueue[nextSaveUserId] = nil
        
        -- Mark as saving
        self.isSaving[nextSaveUserId] = true
        
        -- Execute the save
        task.spawn(function()
            local key = "Player_" .. nextSaveUserId
            
            -- Track operation
            operationStats.autoSaves.total = operationStats.autoSaves.total + 1
            
            local success, _ = self:SafeDataStoreOperation("autoSaves", function()
                self.dataStore:SetAsync(key, saveInfo.data)
                return true
            end)
            
            -- Update session last active time
            pcall(function()
                if success then
                    self.sessionStore:SetAsync("Session_" .. nextSaveUserId, os.time())
                    operationStats.autoSaves.success = operationStats.autoSaves.success + 1
                    
                    -- Save to versioned store
                    self:SaveToVersionedStore(nextSaveUserId, saveInfo.data)
                    
                    -- Queue backup every 5 saves (random)
                    if math.random(1, 5) == 1 then
                        self:QueueBackup(nextSaveUserId, saveInfo.data)
                    end
                else
                    operationStats.autoSaves.failed = operationStats.autoSaves.failed + 1
                    
                    -- Requeue with higher priority if failed
                    local newPriority = math.max(1, saveInfo.priority - 1)
                    self:QueueSave(nextSaveUserId, saveInfo.data, newPriority)
                end
            end)
            
            -- Clear saving flag
            self.isSaving[nextSaveUserId] = nil
        end)
    end
end

-- Queue a backup creation
function DataManager:QueueBackup(userId, data)
    self.backupQueue[userId] = {
        data = data,
        timestamp = os.time()
    }
    
    return true
end

-- Process backup queue
function DataManager:ProcessBackupQueue()
    -- Process one backup at a time
    for userId, backupInfo in pairs(self.backupQueue) do
        -- Execute the backup
        task.spawn(function()
            local key = "Backup_" .. userId .. "_" .. os.time()
            local data = backupInfo.data
            
            -- Remove from queue immediately
            self.backupQueue[userId] = nil
            
            -- Track operation
            operationStats.backups.total = operationStats.backups.total + 1
            
            local success, _ = self:SafeDataStoreOperation("backups", function()
                self.backupStore:SetAsync(key, data)
                
                -- Also update the latest backup key
                self.backupStore:SetAsync("Latest_" .. userId, key)
                
                return true
            end)
            
            if success then
                operationStats.backups.success = operationStats.backups.success + 1
            else
                operationStats.backups.failed = operationStats.backups.failed + 1
            end
        end)
        
        -- Only process one backup per cycle
        break
    end
end

-- Create a backup of player data
function DataManager:CreateBackup(player)
    if not player then
        return false, "Invalid player"
    end
    
    local userId = player.UserId
    
    -- Check if data is loaded
    if not self.loadedData[userId] then
        return false, "No loaded data"
    end
    
    -- Queue backup
    return self:QueueBackup(userId, deepCopy(self.loadedData[userId]))
end

-- Save data to versioned store
function DataManager:SaveToVersionedStore(userId, data)
    -- First get the latest version
    local latestVersionKey = "LatestVersion_" .. userId
    
    local success, currentVersion = self:SafeDataStoreOperation("loads", function()
        return self.versionedStore:GetAsync(latestVersionKey) or 0
    end)
    
    if not success then
        currentVersion = 0
    end
    
    -- Increment version number
    local newVersion = currentVersion + 1
    
    -- Save with version number
    local versionedKey = "Player_" .. userId .. "_V" .. newVersion
    
    local saveSuccess, _ = self:SafeDataStoreOperation("saves", function()
        -- Save the new version
        self.dataStore:SetAsync(versionedKey, data)
        
        -- Update latest version pointer
        self.versionedStore:SetAsync(latestVersionKey, newVersion)
        
        -- Clean up old versions if we have too many
        if newVersion > CONFIG.maxVersionsToKeep then
            local oldVersionKey = "Player_" .. userId .. "_V" .. (newVersion - CONFIG.maxVersionsToKeep)
            -- Remove old version (not critical if this fails)
            pcall(function()
                self.dataStore:RemoveAsync(oldVersionKey)
            end)
        end
        
        return true
    end)
    
    return saveSuccess
end

-- Update data from player state
function DataManager:UpdateDataFromPlayer(player)
    if not player then
        return false
    end
    
    local userId = player.UserId
    
    if not self.loadedData[userId] then
        return false
    end
    
    local data = self.loadedData[userId]
    
    -- Get leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats and leaderstats:FindFirstChild("Cash") then
        data.cash = leaderstats.Cash.Value
    end
    
    -- Get tycoon data
    local tycoon = player:FindFirstChild("Tycoon")
    if tycoon then
        -- Get core attributes
        data.equipmentCount = tycoon:GetAttribute("EquipmentCount") or data.equipmentCount
        data.gymLevel = tycoon:GetAttribute("GymTier") or tycoon:GetAttribute("GymLevel") or data.gymLevel
        data.memberCount = tycoon:GetAttribute("MemberCount") or tycoon:GetAttribute("MembershipCount") or data.memberCount
        data.vipCount = tycoon:GetAttribute("VIPCount") or tycoon:GetAttribute("VIPMembershipCount") or data.vipCount
        
        -- Record purchased equipment by equipment ID
        if tycoon.Value then
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
function DataManager:ApplyDataToPlayer(player, data)
    if not player or not data then
        return false
    end
    
    -- Create leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end
    
    -- Set Cash value
    local cashValue = leaderstats:FindFirstChild("Cash")
    if not cashValue then
        cashValue = Instance.new("IntValue")
        cashValue.Name = "Cash"
        cashValue.Parent = leaderstats
    end
    cashValue.Value = data.cash or DEFAULT_DATA.cash
    
    -- Ensure Tycoon value exists
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon then
        tycoon = Instance.new("ObjectValue")
        tycoon.Name = "Tycoon"
        tycoon.Parent = player
    end
    
    -- Set attributes from saved data
    tycoon:SetAttribute("EquipmentCount", data.equipmentCount or DEFAULT_DATA.equipmentCount)
    tycoon:SetAttribute("GymTier", data.gymLevel or DEFAULT_DATA.gymLevel)
    tycoon:SetAttribute("MemberCount", data.memberCount or DEFAULT_DATA.memberCount)
    tycoon:SetAttribute("VIPCount", data.vipCount or DEFAULT_DATA.vipCount)
    
    -- Start session time tracking
    data.sessionStart = os.time()
    
    return true
end

-- Restore purchased equipment
function DataManager:RestorePlayerEquipment(player)
    if not player then
        return false
    end
    
    local userId = player.UserId
    
    -- Check if data is loaded
    if not self.loadedData[userId] then
        return false
    end
    
    local data = self.loadedData[userId]
    
    -- Check if player has any purchased equipment
    if not data.equipmentPurchased or next(data.equipmentPurchased) == nil then
        log("No purchased equipment to restore for " .. player.Name)
        return true
    end
    
    -- Get tycoon reference
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then
        warn("No valid tycoon for " .. player.Name)
        return false
    end
    
    -- Try to find BuyTile system
    local BuyTileSystem
    pcall(function()
        -- Try different possible paths
        local paths = {
            ServerScriptService.BuyTile,
            ServerScriptService.Systems and ServerScriptService.Systems.BuyTile,
            ServerScriptService.Core and ServerScriptService.Core.BuyTile,
            ReplicatedStorage.Systems and ReplicatedStorage.Systems.BuyTile
        }
        
        for _, path in ipairs(paths) do
            local success, result = pcall(function()
                if path then
                    return require(path)
                end
                return nil
            end)
            
            if success and result then
                BuyTileSystem = result
                break
            end
        end
        
        -- If still not found, try CoreRegistry
        if not BuyTileSystem and CoreRegistry then
            BuyTileSystem = CoreRegistry.getSystem("BuyTileSystem")
        end
    end)
    
    if not BuyTileSystem or not BuyTileSystem.spawnGymPart then
        warn("BuyTile system not available")
        return false
    end
    
    -- Get purchased tile IDs
    local purchasedTiles = {}
    for tileId, _ in pairs(data.equipmentPurchased) do
        table.insert(purchasedTiles, tonumber(tileId) or tonumber(string.match(tileId, "%d+")))
    end
    
    -- Sort IDs to purchase in order
    table.sort(purchasedTiles)
    
    -- Allow time for tycoon to fully initialize
    task.wait(2)
    
    log("Restoring " .. #purchasedTiles .. " equipment pieces for " .. player.Name)
    
    -- Track successful spawns
    local spawnCount = 0
    
    -- Spawn each tile with a small delay between them
    for i, tileId in ipairs(purchasedTiles) do
        task.wait(0.2) -- Slight delay to prevent issues
        
        local success = false
        
        if i == 1 then
            -- Spawn initial tile
            local tile = BuyTileSystem.spawnBuyTile and BuyTileSystem.spawnBuyTile(1)
            if tile then
                spawnCount = spawnCount + 1
                log("Restored initial tile for " .. player.Name)
                success = true
            end
        else
            -- Try to spawn gym part
            local part = BuyTileSystem.spawnGymPart(tileId)
            if part then
                spawnCount = spawnCount + 1
                log("Restored gym part " .. tileId .. " for " .. player.Name)
                success = true
            else
                warn("Failed to restore gym part " .. tileId .. " for " .. player.Name)
            end
        end
    end
    
    log("Successfully restored " .. spawnCount .. "/" .. #purchasedTiles .. " equipment pieces for " .. player.Name)
    
    -- Update equipment count on tycoon
    tycoon:SetAttribute("EquipmentCount", spawnCount)
    data.equipmentCount = spawnCount
    
    return true
end

-- Start auto-save for a player
function DataManager:StartAutoSave(player)
    if not player then
        return false
    end
    
    local userId = player.UserId
    
    -- Clear existing timer if it exists
    if self.autoSaveTimers[userId] then
        task.cancel(self.autoSaveTimers[userId])
        self.autoSaveTimers[userId] = nil
    end
    
    -- Create new auto-save loop
    self.autoSaveTimers[userId] = task.spawn(function()
        while true do
            task.wait(CONFIG.saveInterval)
            
            -- Check if player is still connected
            if not player or not player.Parent then
                break
            end
            
            pcall(function()
                -- Save data (non-immediate)
                self:SavePlayerData(player, false)
                
                -- Create backup occasionally
                if CONFIG.backupInterval > 0 and (os.time() % CONFIG.backupInterval) < CONFIG.saveInterval then
                    self:CreateBackup(player)
                end
            end)
        end
        
        self.autoSaveTimers[userId] = nil
    end)
    
    log("Started auto-save for " .. player.Name)
    return true
end

-- Stop auto-save for a player
function DataManager:StopAutoSave(player)
    if not player then
        return false
    end
    
    local userId = player.UserId
    
    if self.autoSaveTimers[userId] then
        task.cancel(self.autoSaveTimers[userId])
        self.autoSaveTimers[userId] = nil
        
        log("Stopped auto-save for " .. player.Name)
        return true
    end
    
    return false
end

-- Session management
function DataManager:AcquireSessionLock(player)
    if not player then
        return false
    end
    
    local userId = player.UserId
    local sessionKey = "Session_" .. userId
    
    -- Track operation
    operationStats.sessions.acquired = operationStats.sessions.acquired + 1
    
    -- Try to acquire session lock
    local success, currentSession = self:SafeDataStoreOperation("sessions", function()
        return self.sessionStore:GetAsync(sessionKey)
    end)
    
    if success and currentSession then
        -- Check if session is expired
        local sessionAge = os.time() - currentSession
        if sessionAge < CONFIG.sessionTimeout then
            log("Session exists for " .. player.Name .. " and is " .. sessionAge .. "s old")
            return false
        else
            log("Session exists for " .. player.Name .. " but expired " .. (sessionAge - CONFIG.sessionTimeout) .. "s ago")
            operationStats.sessions.timeouts = operationStats.sessions.timeouts + 1
        end
    end
    
    -- Set our session
    local setSuccess, _ = self:SafeDataStoreOperation("sessions", function()
        self.sessionStore:SetAsync(sessionKey, os.time())
        return true
    end)
    
    if setSuccess then
        -- Mark session as active
        self.activeSessions[userId] = os.time()
        log("Acquired session lock for " .. player.Name)
        return true
    else
        warn("Failed to acquire session lock for " .. player.Name)
        return false
    end
end

-- Release session lock
function DataManager:ReleaseSessionLock(player)
    if not player then
        return false
    end
    
    local userId = player.UserId
    local sessionKey = "Session_" .. userId
    
    -- Track operation
    operationStats.sessions.released = operationStats.sessions.released + 1
    
    -- Release the session
    local success, _ = self:SafeDataStoreOperation("sessions", function()
        self.sessionStore:RemoveAsync(sessionKey)
        return true
    end)
    
    if success then
        -- Clear local tracking
        self.activeSessions[userId] = nil
        log("Released session lock for " .. player.Name)
        return true
    else
        warn("Failed to release session lock for " .. player.Name)
        return false
    end
end

-- Handle game shutdown
function DataManager:HandleShutdown()
    log("Game shutdown initiated, saving all player data...")
    
    -- Save data for all players
    local players = Players:GetPlayers()
    local saveCount = 0
    local saveTasks = {}
    
    for _, player in pairs(players) do
        table.insert(saveTasks, task.spawn(function()
            -- Stop auto-save
            self:StopAutoSave(player)
            
            -- Save data immediately
            local success = self:SavePlayerData(player, true)
            if success then
                saveCount = saveCount + 1
            end
            
            -- Create backup
            self:CreateBackup(player)
            
            -- Release session lock
            self:ReleaseSessionLock(player)
        end))
    end
    
    -- Wait for saves to complete, up to shutdown timeout
    local start = os.time()
    while (os.time() - start) < CONFIG.shutdownTimeout do
        local remaining = 0
        for _, task in pairs(saveTasks) do
            if coroutine.status(task) ~= "dead" then
                remaining = remaining + 1
            end
        end
        
        if remaining == 0 then
            break
        end
        
        task.wait(0.1)
    end
    
    log("Shutdown complete. Saved " .. saveCount .. "/" .. #players .. " players.")
end

-- Get operation statistics
function DataManager:GetStats()
    return {
        operations = operationStats,
        activeData = {
            loadedPlayers = #table.keys(self.loadedData),
            activeSessions = #table.keys(self.activeSessions),
            queuedSaves = #table.keys(self.saveQueue),
            activeSaves = #table.keys(self.isSaving),
            queuedBackups = #table.keys(self.backupQueue),
            autoSaveTimers = #table.keys(self.autoSaveTimers)
        }
    }
end

-- Compatibility layer for older systems
function DataManager:CreateCompatibilityLayer()
    -- Create enhanced methods with fallback to legacy-style calls
    
    -- Legacy method: getPlayerData
    self.getPlayerData = function(player)
        return self.loadedData[player.UserId]
    end
    
    -- Legacy method: updatePlayerData
    self.updatePlayerData = function(player, path, value)
        local userId = player.UserId
        if not self.loadedData[userId] then
            return false
        end
        
        local data = self.loadedData[userId]
        
        -- Handle dot notation paths
        if type(path) == "string" and path:find("%.") then
            local currentTable = data
            local parts = string.split(path, ".")
            
            -- Navigate to the correct location
            for i = 1, #parts - 1 do
                local part = parts[i]
                if currentTable[part] == nil then
                    currentTable[part] = {}
                elseif type(currentTable[part]) ~= "table" then
                    currentTable[part] = {}
                end
                currentTable = currentTable[part]
            end
            
            -- Set the value
            currentTable[parts[#parts]] = value
        else
            -- Direct property
            data[path] = value
        end
        
        -- Queue a save
        self:QueueSave(userId, data, 3)
        
        return true
    end
    
    log("Compatibility layer created")
end

-- Initialize on module load
DataManager:Initialize()
DataManager:CreateCompatibilityLayer()

return DataManager
