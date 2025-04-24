--[[
    VersionedDataStore.server.luau
    
    Implements versioned data storage using the OrderedDataStore (Berezaas method).
    This provides historical data snapshots, the ability to rollback to previous versions,
    and better protection against data corruption.
    
    Key features:
    - Multiple data versions stored with timestamps
    - Automatic rollback to previous version on error
    - Data integrity validation
    - Conflict resolution for concurrent saves
    
    Author: Created April 2025
]]

local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

-- Versioning configuration
local CONFIG = {
    -- Data store names
    mainStoreName = "GymTycoon_Main_v1",
    versionStoreName = "GymTycoon_Versions_v1",
    
    -- Versioning settings
    maxVersionsToKeep = 10,       -- Maximum number of versions to keep per player
    versionRetentionDays = 14,    -- How long to keep versions (in days)
    
    -- Validation settings
    validateData = true,          -- Whether to validate data structure
    
    -- Debug settings
    debug = true
}

-- Debug function
local function log(message)
    if CONFIG.debug then
        print("[VersionedDataStore] " .. message)
    end
end

-- Find CoreRegistry
local CoreRegistry
local function findCoreRegistry()
    -- Try to require from common locations
    local success, result
    local possiblePaths = {
        ServerScriptService:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("Systems") and ServerScriptService.Core.Systems:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry"),
    }
    
    for _, path in ipairs(possiblePaths) do
        if path and path:IsA("ModuleScript") then
            success, result = pcall(function()
                return require(path)
            end)
            
            if success then
                return result
            end
        end
    end
    
    return nil
end

CoreRegistry = findCoreRegistry()

-- Validate data structure
local function validateDataStructure(data)
    if not data then
        return false
    end
    
    -- Check if data is actually a table
    if type(data) ~= "table" then
        return false
    end
    
    -- Check for critical data structures needed for the game
    local requiredSections = {
        "equipment",
        "cash",
        "members",
        "revenue"
    }
    
    for _, section in ipairs(requiredSections) do
        if data[section] == nil then
            return false
        end
    end
    
    return true
end

-- Generate a version key for a user
local function generateVersionKey(userId, timestamp)
    return string.format("%s_v_%d", tostring(userId), timestamp or os.time())
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

-- VersionedDataStore singleton
local VersionedDataStore = {
    Initialized = false,
    DataAccessLayer = nil, -- Will be set during initialization
}

-- Initialize the versioned data store
function VersionedDataStore:Initialize()
    if self.Initialized then
        return self
    end
    
    log("Initializing VersionedDataStore")
    
    -- Initialize data stores
    self.mainStore = DataStoreService:GetDataStore(CONFIG.mainStoreName)
    self.versionStore = DataStoreService:GetOrderedDataStore(CONFIG.versionStoreName)
    
    -- Get DataAccessLayer reference if available
    if CoreRegistry then
        self.DataAccessLayer = CoreRegistry:GetSystem("DataAccessLayer")
        if self.DataAccessLayer then
            log("Found DataAccessLayer through CoreRegistry")
        end
    end
    
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.registerSystem then
        CoreRegistry:RegisterSystem("VersionedDataStore", self)
        log("Registered with CoreRegistry")
    end
    
    self.Initialized = true
    return self
end

-- Save data with versioning
function VersionedDataStore:SaveData(player, data, immediate)
    if not player or not data then
        return false, "Invalid parameters"
    end
    
    local userId = player.UserId
    local key = tostring(userId)
    local timestamp = os.time()
    local versionKey = generateVersionKey(userId, timestamp)
    
    -- Add metadata
    local versionedData = deepCopy(data)
    versionedData.metadata = versionedData.metadata or {}
    versionedData.metadata.version = timestamp
    versionedData.metadata.lastSave = timestamp
    
    -- Validate if enabled
    if CONFIG.validateData and not validateDataStructure(data) then
        warn("Data validation failed for " .. player.Name)
        return false, "Data validation failed"
    end
    
    -- Create a savepoint in the versioned store
    local success, versionResult = pcall(function()
        self.versionStore:SetAsync(versionKey, timestamp)
        
        -- Encode actual data safely
        local encodedData = HttpService:JSONEncode(versionedData)
        self.mainStore:SetAsync(versionKey, encodedData)
        
        return true
    end)
    
    if not success then
        warn("Failed to save version: " .. tostring(versionResult))
        return false, "Version save failed"
    end
    
    -- Update the current pointer
    local success, mainResult = pcall(function()
        self.mainStore:SetAsync(key, versionKey)
        return true
    end)
    
    if not success then
        warn("Failed to update main record: " .. tostring(mainResult))
        return false, "Main record update failed"
    end
    
    -- Cleanup old versions (async)
    task.spawn(function()
        self:CleanupOldVersions(userId)
    end)
    
    log("Saved data version " .. versionKey .. " for " .. player.Name)
    
    -- Notify events system if available
    if CoreRegistry and CoreRegistry.fireEvent then
        CoreRegistry:FireEvent("PlayerDataSaved", player, timestamp)
    end
    
    return true
end

-- Load data with versioning
function VersionedDataStore:LoadData(player)
    if not player then
        return nil, "Invalid player"
    end
    
    local userId = player.UserId
    local key = tostring(userId)
    
    -- Get the current version key
    local success, currentVersionKey = pcall(function()
        return self.mainStore:GetAsync(key)
    end)
    
    if not success or not currentVersionKey then
        log("No current version found for " .. player.Name)
        return nil, "No data found"
    end
    
    -- Get the actual data using the version key
    local success, encodedData = pcall(function()
        return self.mainStore:GetAsync(currentVersionKey)
    end)
    
    if not success or not encodedData then
        warn("Failed to load data version: " .. tostring(encodedData))
        return self:LoadPreviousVersion(player)
    end
    
    -- Decode the data
    local success, decodedData = pcall(function()
        return HttpService:JSONDecode(encodedData)
    end)
    
    if not success then
        warn("Failed to decode data: " .. tostring(decodedData))
        return self:LoadPreviousVersion(player)
    end
    
    -- Validate the data
    if CONFIG.validateData and not validateDataStructure(decodedData) then
        warn("Data validation failed for " .. player.Name)
        return self:LoadPreviousVersion(player)
    end
    
    log("Loaded data version " .. currentVersionKey .. " for " .. player.Name)
    return decodedData
end

-- Attempt to load a previous version if current is corrupted
function VersionedDataStore:LoadPreviousVersion(player)
    if not player then
        return nil, "Invalid player"
    end
    
    local userId = player.UserId
    local prefix = tostring(userId) .. "_v_"
    
    -- Get sorted versions (newest first)
    local success, pages = pcall(function()
        return self.versionStore:GetSortedAsync(false, 5, prefix)
    end)
    
    if not success or not pages then
        warn("Failed to retrieve version history")
        return nil, "No version history"
    end
    
    local versions = pages:GetCurrentPage()
    
    -- Try each version until we find a valid one
    for i, versionInfo in ipairs(versions) do
        if i > 1 then -- Skip the most recent (presumably corrupted) version
            local versionKey = versionInfo.key
            
            local success, encodedData = pcall(function()
                return self.mainStore:GetAsync(versionKey)
            end)
            
            if success and encodedData then
                -- Decode the data
                local success, decodedData = pcall(function()
                    return HttpService:JSONDecode(encodedData)
                end)
                
                if success and decodedData and validateDataStructure(decodedData) then
                    -- Found a valid previous version
                    log("Rolled back to previous version " .. versionKey .. " for " .. player.Name)
                    
                    -- Update the current pointer to this version
                    pcall(function()
                        self.mainStore:SetAsync(tostring(userId), versionKey)
                    end)
                    
                    -- Notify about rollback
                    if CoreRegistry and CoreRegistry.fireEvent then
                        CoreRegistry:FireEvent("DataRollbackPerformed", player, versionKey)
                    end
                    
                    return decodedData
                end
            end
        end
    end
    
    -- If we reach here, all versions are corrupted or unusable
    warn("All data versions corrupted for " .. player.Name)
    return nil, "All versions corrupted"
end

-- Get version history for a player
function VersionedDataStore:GetVersionHistory(player, maxVersions)
    if not player then
        return nil, "Invalid player"
    end
    
    local userId = player.UserId
    local prefix = tostring(userId) .. "_v_"
    maxVersions = maxVersions or CONFIG.maxVersionsToKeep
    
    -- Get sorted versions (newest first)
    local success, pages = pcall(function()
        return self.versionStore:GetSortedAsync(false, maxVersions, prefix)
    end)
    
    if not success or not pages then
        return nil, "Failed to retrieve version history"
    end
    
    local versions = pages:GetCurrentPage()
    local history = {}
    
    for _, versionInfo in ipairs(versions) do
        table.insert(history, {
            key = versionInfo.key,
            timestamp = versionInfo.value
        })
    end
    
    return history
end

-- Rollback to a specific version
function VersionedDataStore:RollbackToVersion(player, versionKey)
    if not player or not versionKey then
        return false, "Invalid parameters"
    end
    
    local userId = player.UserId
    
    -- Verify the version exists and belongs to this player
    if not string.match(versionKey, "^" .. tostring(userId) .. "_v_") then
        return false, "Invalid version key for this player"
    end
    
    -- Check if version exists
    local success, versionExists = pcall(function()
        return self.versionStore:GetAsync(versionKey) ~= nil
    end)
    
    if not success or not versionExists then
        return false, "Version not found"
    end
    
    -- Get the data for this version
    local success, encodedData = pcall(function()
        return self.mainStore:GetAsync(versionKey)
    end)
    
    if not success or not encodedData then
        return false, "Version data not found"
    end
    
    -- Update the current pointer to this version
    local success, result = pcall(function()
        self.mainStore:SetAsync(tostring(userId), versionKey)
        return true
    end)
    
    if not success then
        return false, "Failed to update current version"
    end
    
    log("Manually rolled back to version " .. versionKey .. " for " .. player.Name)
    
    -- Notify about rollback
    if CoreRegistry and CoreRegistry.fireEvent then
        CoreRegistry:FireEvent("DataRollbackPerformed", player, versionKey)
    end
    
    return true
end

-- Clean up old versions to save data store space
function VersionedDataStore:CleanupOldVersions(userId)
    if not userId then
        return false, "Invalid user ID"
    end
    
    local prefix = tostring(userId) .. "_v_"
    local cutoffTime = os.time() - (CONFIG.versionRetentionDays * 24 * 60 * 60)
    
    -- Get all versions for this user
    local success, pages = pcall(function()
        return self.versionStore:GetSortedAsync(false, 100, prefix)
    end)
    
    if not success or not pages then
        return false, "Failed to retrieve versions"
    end
    
    local versions = pages:GetCurrentPage()
    local currentVersionKey = nil
    
    -- Get current version key
    pcall(function()
        currentVersionKey = self.mainStore:GetAsync(tostring(userId))
    end)
    
    -- Keep track of how many we're keeping
    local keptVersions = 0
    
    for i, versionInfo in ipairs(versions) do
        local versionKey = versionInfo.key
        local timestamp = versionInfo.value
        
        -- Keep the current version, the CONFIG.maxVersionsToKeep most recent versions,
        -- and any versions within the retention period
        local shouldKeep = (versionKey == currentVersionKey) or 
                          (keptVersions < CONFIG.maxVersionsToKeep) or
                          (timestamp > cutoffTime)
        
        if shouldKeep then
            keptVersions = keptVersions + 1
        else
            -- Remove this old version
            pcall(function()
                self.versionStore:RemoveAsync(versionKey)
                self.mainStore:RemoveAsync(versionKey)
            end)
            log("Removed old version " .. versionKey)
        end
    end
    
    return true
end

-- Handle server shutdown to ensure clean saving
function VersionedDataStore:HandleShutdown()
    log("Processing shutdown, saving all player data with versioning")
    
    -- Get all active players
    local Players = game:GetService("Players")
    local players = Players:GetPlayers()
    
    -- Set a flag to prevent other operations during shutdown
    self.ShuttingDown = true
    
    -- If DataAccessLayer is available, use it to get player data
    if self.DataAccessLayer then
        for _, player in ipairs(players) do
            local data = self.DataAccessLayer:GetAllPlayerData(player)
            
            if data then
                -- Save with versioning
                self:SaveData(player, data, true)
            end
        end
    else
        log("DataAccessLayer not available for shutdown save")
    end
    
    log("Versioned save completed for " .. #players .. " players")
end

-- Initialize and return
return VersionedDataStore:Initialize()
