--!strict
--[[
    VersionedDataStore.server.luau
    
    A robust versioned data store system that maintains a history of player data
    snapshots, allowing for point-in-time recovery and protection against data corruption.
    
    Created: April 26, 2025
]]

-- Services
local Players = game:GetService("Players")
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
    -- DataStore config
    versionDataStoreName = "GymTycoonVersionedv3", -- Historical version data
    versionIndexStoreName = "GymTycoonVersionIdxv3", -- Version indexes
    versionMetaStoreName = "GymTycoonVersionMetav3", -- Version metadata
    
    -- Version control
    currentDataVersion = 1,                    -- Current data schema version
    maxVersionsToKeep = 10,                    -- Maximum number of versions to keep per player
    versioningEnabled = true,                  -- Master toggle for versioning
    
    -- Auto-versioning triggers
    createVersionOnJoin = true,                -- Create version when player joins
    createVersionOnLeave = true,               -- Create version when player leaves
    createVersionInterval = 3600,              -- Create version every hour of playtime
    createVersionOnMilestone = true,           -- Create version on significant milestones
    
    -- Version retention policy
    keepMinutes = 60,                          -- Keep all versions from last hour
    keepHours = 24,                            -- Keep hourly versions from last day
    keepDays = 7,                              -- Keep daily versions from last week
    keepWeeks = 4,                             -- Keep weekly versions from last month
    
    -- Integrity options
    validateOnSave = true,                     -- Validate before saving a version
    validateOnLoad = true,                     -- Validate when loading a version
    automaticRepair = true,                    -- Try to repair corrupted versions
    
    -- Debug options
    debug = true,                              -- Enable debug logging
}

-- Debug logging
local function log(message)
    if CONFIG.debug then
        print("[VersionedDataStore] " .. message)
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

-- Safe DataStore Operation with retries
local function safeDataStoreOperation(storeName, operationType, storeMethod, ...)
    -- Use the globally defined DataStoreService instead of shadowing it
    local store
    local args = {...} -- Store varargs in a local table for later use
    
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
    local maxRetries = 5
    local retriesRemaining = maxRetries
    local baseDelay = 1
    
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

-- Utility function to generate a version key
local function generateVersionKey(userId, versionNumber)
    return "Player_" .. userId .. "_V" .. versionNumber
end

-- Module table
local VersionedDataStore = {
    initialized = false,
    versionCache = {},        -- Cache of loaded versions: {userId = {versionNumber = data}}
    versionMetadata = {},     -- Metadata for versions: {userId = {versionNumber = {timestamp = time, ...}}}
    versionCounts = {},       -- Number of versions per user: {userId = count}
    versionSchedule = {},     -- Next auto-version time: {userId = nextTime}
    latestVersions = {},      -- Latest version number per user: {userId = versionNumber}
    processingVersions = {},  -- Currently processing versions: {userId = true}
}

-- Initialize
function VersionedDataStore:Initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing VersionedDataStore")
    
    local success, result = pcall(function()
        -- Initialize datastores
        self.versionStore = DataStoreService:GetDataStore(CONFIG.versionDataStoreName)
        self.indexStore = DataStoreService:GetOrderedDataStore(CONFIG.versionIndexStoreName)
        self.metaStore = DataStoreService:GetDataStore(CONFIG.versionMetaStoreName)
        
        -- Register with CoreRegistry if available
        if CoreRegistry and CoreRegistry.registerSystem then
            CoreRegistry:registerSystem("VersionedDataStore", self)
            log("Registered with CoreRegistry")
        end
        
        -- Start version scheduler
        self:StartVersionScheduler()
        
        -- Connect events
        self:ConnectEvents()
        
        return true
    end)
    
    if success then
        log("VersionedDataStore initialized")
        self.initialized = true
        return true
    else
        warn("Failed to initialize VersionedDataStore: " .. tostring(result))
        return false
    end
end

-- Start the version scheduler
function VersionedDataStore:StartVersionScheduler()
    task.spawn(function()
        while true do
            task.wait(60) -- Check schedule every minute
            
            -- Process scheduled versions
            for userId, nextVersionTime in pairs(self.versionSchedule) do
                if os.time() >= nextVersionTime and not self.processingVersions[userId] then
                    task.spawn(function()
                        self.processingVersions[userId] = true
                        
                        -- Find the player
                        local player
                        for _, p in pairs(Players:GetPlayers()) do
                            if p.UserId == userId then
                                player = p
                                break
                            end
                        end
                        
                        if player then
                            -- Create a new version
                            self:CreateVersion(player, "Scheduled")
                            
                            -- Schedule next version
                            self.versionSchedule[userId] = os.time() + CONFIG.createVersionInterval
                        end
                        
                        self.processingVersions[userId] = nil
                    end)
                end
            end
            
            -- Also clean up version history
            self:CleanupVersionHistory()
        end
    end)
    
    log("Version scheduler started")
end

-- Connect events
function VersionedDataStore:ConnectEvents()
    -- Listen for player data changes if CoreRegistry is available
    if CoreRegistry and CoreRegistry.onEvent then
        -- Player data loaded
        CoreRegistry:onEvent("PlayerDataLoaded", function(player)
            if CONFIG.createVersionOnJoin then
                task.spawn(function()
                    task.wait(5) -- Wait a bit for data to fully load
                    self:CreateVersion(player, "PlayerJoined")
                end)
            end
            
            -- Schedule regular versions
            local userId = player.UserId
            self.versionSchedule[userId] = os.time() + CONFIG.createVersionInterval
        end)
          -- Player data saved
        CoreRegistry:onEvent("PlayerDataSaved", function(_player)
            -- Nothing to do here by default
            -- Could add additional triggers based on game events
            -- Using _player (with underscore) to denote intentionally unused parameter
        end)
        
        -- Player milestone reached
        CoreRegistry:onEvent("PlayerMilestoneReached", function(player, milestone)
            if CONFIG.createVersionOnMilestone then
                self:CreateVersion(player, "Milestone_" .. milestone)
            end
        end)
    end
    
    -- Connect to player leave event
    Players.PlayerRemoving:Connect(function(player)
        if CONFIG.createVersionOnLeave then
            self:CreateVersion(player, "PlayerLeft")
        end
        
        -- Clear schedule
        local userId = player.UserId
        self.versionSchedule[userId] = nil
    end)
    
    log("Events connected")
end

-- Get the latest version number for a player
function VersionedDataStore:GetLatestVersionNumber(userId)
    -- Check cache first
    if self.latestVersions[userId] then
        return self.latestVersions[userId]
    end
    
    -- Try to get from DataStore
    local success, versionNumber = safeDataStoreOperation(
        CONFIG.versionIndexStoreName,
        "GetLatestVersion",
        function(store, key)
            return store:GetAsync(key)
        end,
        "Latest_" .. userId
    )
    
    if success and versionNumber then
        self.latestVersions[userId] = versionNumber
        return versionNumber
    end
    
    return 0 -- No versions yet
end

-- Get version metadata
function VersionedDataStore:GetVersionMetadata(userId, versionNumber)
    -- Check cache first
    if self.versionMetadata[userId] and self.versionMetadata[userId][versionNumber] then
        return deepCopy(self.versionMetadata[userId][versionNumber])
    end
    
    -- Try to get from DataStore
    local metaKey = "Meta_" .. userId .. "_V" .. versionNumber
    local success, metadata = safeDataStoreOperation(
        CONFIG.versionMetaStoreName,
        "GetVersionMetadata",
        function(store, key)
            return store:GetAsync(key)
        end,
        metaKey
    )
    
    if success and metadata then
        -- Cache it
        if not self.versionMetadata[userId] then
            self.versionMetadata[userId] = {}
        end
        
        self.versionMetadata[userId][versionNumber] = metadata
        return deepCopy(metadata)
    end
    
    return nil
end

-- Create a new version
function VersionedDataStore:CreateVersion(player, reason)
    if not player or not CONFIG.versioningEnabled then
        return false, "Versioning disabled or invalid player"
    end
    
    local userId = player.UserId
    reason = reason or "Manual"
    
    -- Get the current data from DataManager
    local dataManager
    if CoreRegistry then
        dataManager = CoreRegistry.getSystem("DataManager")
    end
    
    if not dataManager then
        pcall(function()
            dataManager = require(ServerScriptService.Core.DataManager)
        end)
    end
    
    -- Check if we have data
    if not dataManager or not dataManager.loadedData or not dataManager.loadedData[userId] then
        return false, "Could not access player data"
    end
    
    -- Get a deep copy of the data
    local playerData = deepCopy(dataManager.loadedData[userId])
    
    -- Validate data if required
    if CONFIG.validateOnSave and DataValidator then
        local isValid, validatedData = DataValidator.validatePlayerData(playerData)
        
        if not isValid then
            warn("Data validation failed during version creation for " .. player.Name)
            
            if CONFIG.automaticRepair and validatedData then
                playerData = validatedData
                log("Using repaired data for version creation: " .. player.Name)
            else
                return false, "Data validation failed"
            end
        end
    end
    
    -- Get the next version number
    local currentVersion = self:GetLatestVersionNumber(userId)
    local newVersion = currentVersion + 1
    
    -- Create version key
    local versionKey = generateVersionKey(userId, newVersion)
    
    -- Add version metadata to the data
    playerData.__version = {
        versionNumber = newVersion,
        timestamp = os.time(),
        reason = reason,
        previousVersion = currentVersion > 0 and currentVersion or nil
    }
    
    -- Save the version
    local success, _ = safeDataStoreOperation(
        CONFIG.versionDataStoreName,
        "SaveVersion",
        function(store, key, data)
            store:SetAsync(key, data)
            return true
        end,
        versionKey,
        playerData
    )
    
    if not success then
        return false, "Failed to save version data"
    end
    
    -- Save metadata separately (useful for browsing versions without loading entire data)
    local metadata = {
        versionNumber = newVersion,
        timestamp = os.time(),
        reason = reason,
        previousVersion = currentVersion > 0 and currentVersion or nil,
        playerName = player.Name,
        stats = {
            cash = playerData.cash,
            equipmentCount = playerData.equipmentCount,
            gymLevel = playerData.gymLevel,
            memberCount = playerData.memberCount,
            vipCount = playerData.vipCount,
            playTime = playerData.playTime
        }
    }
    
    local metaKey = "Meta_" .. userId .. "_V" .. newVersion
    safeDataStoreOperation(
        CONFIG.versionMetaStoreName,
        "SaveVersionMetadata",
        function(store, key, data)
            store:SetAsync(key, data)
            return true
        end,
        metaKey,
        metadata
    )
    
    -- Update latest version pointer
    safeDataStoreOperation(
        CONFIG.versionIndexStoreName,
        "UpdateLatestVersion",
        function(store, key, version)
            store:SetAsync(key, version)
            return true
        end,
        "Latest_" .. userId,
        newVersion
    )
    
    -- Update cache
    self.latestVersions[userId] = newVersion
    
    if not self.versionMetadata[userId] then
        self.versionMetadata[userId] = {}
    end
    
    self.versionMetadata[userId][newVersion] = metadata
    
    -- Update version count
    self.versionCounts[userId] = (self.versionCounts[userId] or 0) + 1
    
    log("Created version " .. newVersion .. " for " .. player.Name .. " (Reason: " .. reason .. ")")
    
    return true, newVersion
end

-- Load a specific version
function VersionedDataStore:LoadVersion(player, versionNumber)
    if not player then
        return nil, "Invalid player"
    end
    
    local userId = player.UserId
    
    -- If no version specified, get the latest
    if not versionNumber then
        versionNumber = self:GetLatestVersionNumber(userId)
        
        if versionNumber <= 0 then
            return nil, "No versions available"
        end
    end
    
    -- Check cache first
    if self.versionCache[userId] and self.versionCache[userId][versionNumber] then
        return deepCopy(self.versionCache[userId][versionNumber])
    end
    
    -- Generate key
    local versionKey = generateVersionKey(userId, versionNumber)
    
    -- Load the version
    local success, versionData = safeDataStoreOperation(
        CONFIG.versionDataStoreName,
        "LoadVersion",
        function(store, key)
            return store:GetAsync(key)
        end,
        versionKey
    )
    
    if not success or not versionData then
        return nil, "Version not found"
    end
    
    -- Validate if required
    if CONFIG.validateOnLoad and DataValidator then
        local isValid, validatedData = DataValidator.validatePlayerData(versionData)
        
        if not isValid then
            warn("Version validation failed for " .. player.Name .. " (Version " .. versionNumber .. ")")
            
            if CONFIG.automaticRepair and validatedData then
                versionData = validatedData
                log("Using repaired data for version " .. versionNumber)
            end
        end
    end
    
    -- Cache the version
    if not self.versionCache[userId] then
        self.versionCache[userId] = {}
    end
    
    self.versionCache[userId][versionNumber] = deepCopy(versionData)
    
    log("Loaded version " .. versionNumber .. " for " .. player.Name)
    
    return deepCopy(versionData)
end

-- Apply a version to a player
function VersionedDataStore:ApplyVersion(player, versionNumber, keepCurrentEquipment)
    if not player then
        return false, "Invalid player"
    end
    
    -- Load the version
    local versionData, errorMsg = self:LoadVersion(player, versionNumber)
    if not versionData then
        return false, errorMsg or "Failed to load version"
    end
    
    local userId = player.UserId
    
    -- Get the current data for equipment preservation if needed
    local currentEquipment = nil
    if keepCurrentEquipment then
        local dataManager
        if CoreRegistry then
            dataManager = CoreRegistry.getSystem("DataManager")
        end
        
        if not dataManager then
            pcall(function()
                dataManager = require(ServerScriptService.Core.DataManager)
            end)
        end
        
        if dataManager and dataManager.loadedData and dataManager.loadedData[userId] then
            currentEquipment = deepCopy(dataManager.loadedData[userId].equipmentPurchased)
        end
    end
    
    -- Strip version metadata
    versionData.__version = nil
    
    -- Preserve current equipment if requested
    if keepCurrentEquipment and currentEquipment then
        versionData.equipmentPurchased = currentEquipment
        
        -- Update equipment count
        local count = 0
        for _ in pairs(currentEquipment) do
            count = count + 1
        end
        versionData.equipmentCount = count
    end
    
    -- Apply to DataManager
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
    
    -- Update the data
    dataManager.loadedData[userId] = versionData
    
    -- Apply to player
    if dataManager.ApplyDataToPlayer then
        dataManager:ApplyDataToPlayer(player, versionData)
    end
    
    -- Save immediately
    if dataManager.SavePlayerData then
        dataManager:SavePlayerData(player, true)
    end
    
    -- Restore equipment if needed
    if dataManager.RestorePlayerEquipment then
        task.delay(1, function()
            dataManager:RestorePlayerEquipment(player)
        end)
    end
    
    log("Applied version " .. versionNumber .. " to " .. player.Name)
    
    -- Create a new version to record this restoration
    self:CreateVersion(player, "RestoredFromV" .. versionNumber)
    
    return true
end

-- List available versions for a player
function VersionedDataStore:ListVersions(player, limit)
    if not player then
        return nil, "Invalid player"
    end
    
    limit = limit or 10 -- Default to 10 versions
    local userId = player.UserId
    
    -- Get the latest version number
    local latestVersion = self:GetLatestVersionNumber(userId)
    if latestVersion <= 0 then
        return {}, "No versions available"
    end
    
    -- Collect available versions
    local versions = {}
    local count = 0
    
    for i = latestVersion, 1, -1 do
        -- Check if we've reached the limit
        if count >= limit then
            break
        end
        
        -- Get metadata for this version
        local metadata = self:GetVersionMetadata(userId, i)
        
        if metadata then
            table.insert(versions, metadata)
            count = count + 1
        end
    end
    
    return versions
end

-- Compare two versions
function VersionedDataStore:CompareVersions(player, version1, version2)
    if not player then
        return nil, "Invalid player"
    end
    
    -- Load both versions
    local data1, error1 = self:LoadVersion(player, version1)
    local data2, error2 = self:LoadVersion(player, version2)
    
    if not data1 then
        return nil, "Version " .. tostring(version1) .. " not found: " .. tostring(error1)
    end
    
    if not data2 then
        return nil, "Version " .. tostring(version2) .. " not found: " .. tostring(error2)
    end
    
    -- Compare the data
    local comparison = {
        version1 = version1,
        version2 = version2,
        differences = {}
    }
    
    -- Compare simple fields
    local simpleFields = {"cash", "totalEarned", "equipmentCount", "gymLevel", 
                         "memberCount", "vipCount", "playTime", "dataVersion"}
    
    for _, field in ipairs(simpleFields) do
        if data1[field] ~= data2[field] then
            comparison.differences[field] = {
                v1 = data1[field],
                v2 = data2[field],
                diff = (type(data1[field]) == "number" and type(data2[field]) == "number") 
                    and (data2[field] - data1[field]) or nil
            }
        end
    end
    
    -- Compare equipment
    comparison.differences.equipment = {
        added = {},
        removed = {}
    }
    
    -- Equipment in v1 but not v2
    for id, _ in pairs(data1.equipmentPurchased or {}) do
        if not data2.equipmentPurchased or not data2.equipmentPurchased[id] then
            comparison.differences.equipment.removed[id] = true
        end
    end
    
    -- Equipment in v2 but not v1
    for id, _ in pairs(data2.equipmentPurchased or {}) do
        if not data1.equipmentPurchased or not data1.equipmentPurchased[id] then
            comparison.differences.equipment.added[id] = true
        end
    end
    
    -- Metadata for reference
    comparison.metadata = {
        v1 = data1.__version,
        v2 = data2.__version
    }
    
    return comparison
end

-- Clean up version history
function VersionedDataStore:CleanupVersionHistory()
    log("Version history cleanup not fully implemented")
    -- This would normally clean up old versions based on retention policy
    -- Since we can't enumerate DataStore keys, we need to maintain version lists separately
    
    -- The simplified version would use the counts in self.versionCounts and
    -- the latest version in self.latestVersions to determine which ones to keep
    
    return true
end

-- Handle game shutdown
function VersionedDataStore:HandleShutdown()
    log("Handling shutdown, creating final versions for all players")
    
    local players = Players:GetPlayers()
    
    for _, player in pairs(players) do
        -- Create a final version for each player
        task.spawn(function()
            self:CreateVersion(player, "GameShutdown")
        end)
    end
    
    -- Wait a moment to allow versions to save
    task.wait(5)
    
    log("Version creation complete for shutdown")
end

-- Initialize on module load
VersionedDataStore:Initialize()

return VersionedDataStore
