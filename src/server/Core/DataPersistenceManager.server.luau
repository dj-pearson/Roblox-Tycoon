--[[
    DataPersistenceManager.server.luau
    
    A robust data persistence manager to fix the data persistence failures.
    This script ensures player data is properly saved and restored.
    
    Created to fix the critical data persistence issues identified in RobloxIssues.txt
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    dataStoreName = "GymTycoonDataV2", -- Updated version number to avoid conflicts
    backupStoreName = "GymTycoonBackupV2",
    saveInterval = 60, -- Auto-save frequency in seconds
    maxRetries = 5, -- Maximum retry attempts for DataStore operations
    debug = true, -- Enable debug prints
    enforceStructure = true, -- Ensure proper data structure before saving
    eventBridgeName = "DataEvents", -- Name of the EventBridge folder
    
    -- Default player data
    defaultData = {
        cash = 1000, -- Starting cash
        equipmentPurchased = {}, -- {[tileId] = true, ...}
        equipmentCount = 0, -- Equipment counter
        gymLevel = 1, -- Gym tier/level
        memberCount = 0, -- Member count
        accruedDues = 0, -- Uncollected dues
        lastSaveTime = 0, -- Last time data was saved
        dataVersion = 2 -- Updated version number
    }
}

-- Module table
local DataPersistenceManager = {
    loaded = {}, -- Cached player data
    savers = {}, -- Auto-save coroutines
    dataStore = nil, -- Main DataStore
    backupStore = nil, -- Backup DataStore
    initialized = false,
    savedCount = 0, -- Counter for saved records
    saveFailures = 0, -- Counter for save failures
    
    -- Events
    events = {
        -- These will be created as BindableEvents
        onDataLoaded = nil,
        onDataSaved = nil,
        onDataFailed = nil
    }
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[DataPersistenceManager]", ...)
    end
end

-- Deep copy a table
local function deepCopy(original)
    if type(original) ~= "table" then return original end
    
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

-- Safe DataStore call with retries
local function safeDataStoreCall(func)
    local success, result
    local attempts = 0
    
    repeat
        attempts = attempts + 1
        success, result = pcall(func)
        
        if not success then
            -- Wait with exponential backoff
            local waitTime = math.min(2^attempts, 30)
            log("DataStore call failed:", result, "- Retrying in", waitTime, "seconds (Attempt", attempts, "of", CONFIG.maxRetries, ")")
            task.wait(waitTime)
        end
    until success or attempts >= CONFIG.maxRetries
    
    return success, result
end

-- Create and return the EventBridge
function DataPersistenceManager.ensureEventBridge()
    local eventBridge = ReplicatedStorage:FindFirstChild(CONFIG.eventBridgeName)
    
    if not eventBridge then
        eventBridge = Instance.new("Folder")
        eventBridge.Name = CONFIG.eventBridgeName
        eventBridge.Parent = ReplicatedStorage
        log("Created EventBridge in ReplicatedStorage")
    end
    
    -- Create events if they don't exist
    for name, _ in pairs(DataPersistenceManager.events) do
        if not eventBridge:FindFirstChild(name) then
            local event = Instance.new("BindableEvent")
            event.Name = name
            event.Parent = eventBridge
            DataPersistenceManager.events[name] = event
            log("Created event:", name)
        else
            DataPersistenceManager.events[name] = eventBridge:FindFirstChild(name)
        end
    end
    
    return eventBridge
end

-- Validate and fix the tycoon structure
function DataPersistenceManager.validateTycoonStructure(player)
    if not player then return false end
    
    -- Make sure Tycoon object exists and is an ObjectValue
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon:IsA("ObjectValue") then
        -- Try to find the TycoonFolderFixer script
        local fixer = ServerScriptService.Core:FindFirstChild("TycoonFolderFixer")
        
        if fixer and fixer:FindFirstChild("FixTycoonStructure") then
            log("Using TycoonFolderFixer to fix structure for", player.Name)
            fixer.FixTycoonStructure:Fire(player)
            
            -- Wait a moment for the fix to apply
            task.wait(0.5)
            
            -- Get the updated tycoon
            tycoon = player:FindFirstChild("Tycoon")
        else
            -- Manual fallback if fixer isn't available
            log("Creating basic Tycoon structure for", player.Name)
            
            -- Remove invalid tycoon if it exists
            if tycoon and not tycoon:IsA("ObjectValue") then
                tycoon:Destroy()
            end
            
            -- Create a new ObjectValue
            tycoon = Instance.new("ObjectValue")
            tycoon.Name = "Tycoon"
            tycoon.Parent = player
            
            -- Set default attributes
            tycoon:SetAttribute("EquipmentCount", 0)
            tycoon:SetAttribute("GymTier", 1)
            tycoon:SetAttribute("MemberCount", 0)
            tycoon:SetAttribute("AccruedDues", 0)
        end
    end
    
    return tycoon ~= nil
end

-- Initialize the DataStores
function DataPersistenceManager.init()
    if DataPersistenceManager.initialized then
        return true
    end
    
    if not RunService:IsServer() then
        warn("DataPersistenceManager can only run on the server")
        return false
    end
    
    -- Set up events
    DataPersistenceManager.ensureEventBridge()
    
    -- Enable Studio access in test mode
    if RunService:IsStudio() then
        log("Running in Studio - data persistence may not work unless enabled in Game Settings")
    end
    
    -- Try to get the DataStores
    local success, err = pcall(function()
        DataPersistenceManager.dataStore = DataStoreService:GetDataStore(CONFIG.dataStoreName)
        DataPersistenceManager.backupStore = DataStoreService:GetDataStore(CONFIG.backupStoreName)
    end)
    
    if not success then
        warn("Failed to initialize DataStores:", err)
        return false
    end
    
    -- Connect to player events
    DataPersistenceManager.connectEvents()
    
    DataPersistenceManager.initialized = true
    log("DataPersistenceManager initialized successfully")
    return true
end

-- Load player data
function DataPersistenceManager.loadData(player)
    if not player then return nil end
    
    -- Fix tycoon structure first if needed
    if CONFIG.enforceStructure then
        DataPersistenceManager.validateTycoonStructure(player)
    end
    
    local userId = player.UserId
    
    -- Return cached data if available
    if DataPersistenceManager.loaded[userId] then
        return DataPersistenceManager.loaded[userId]
    end
    
    -- Attempt to fetch from DataStore
    local key = "Player_" .. userId
    local data
    
    -- Try to load data
    local success, dataResult = safeDataStoreCall(function()
        return DataPersistenceManager.dataStore:GetAsync(key)
    end)
    
    if success and dataResult then
        data = dataResult
        log("Loaded data for", player.Name)
    else
        -- Create default data for new player
        data = deepCopy(CONFIG.defaultData)
        log("Created new data for", player.Name)
    end
    
    -- Migration for data version updates
    if (data.dataVersion or 0) < CONFIG.defaultData.dataVersion then
        log("Migrating data from version", data.dataVersion or 0, "to", CONFIG.defaultData.dataVersion)
        
        -- Fill in missing fields from the default data
        for dataKey, defaultValue in pairs(CONFIG.defaultData) do
            if data[dataKey] == nil then
                data[dataKey] = deepCopy(defaultValue)
            end
        end
        
        data.dataVersion = CONFIG.defaultData.dataVersion
    end
    
    -- Cache the data
    DataPersistenceManager.loaded[userId] = data
    
    -- Start auto-save
    if not DataPersistenceManager.savers[userId] then
        DataPersistenceManager.startAutoSave(player)
    end
    
    -- Fire data loaded event
    if DataPersistenceManager.events.onDataLoaded then
        DataPersistenceManager.events.onDataLoaded:Fire(player, data)
    end
    
    return data
end

-- Update data from player's current state
function DataPersistenceManager.updateDataFromPlayer(player)
    if not player then return false end
    local userId = player.UserId
    
    -- Make sure data is loaded
    if not DataPersistenceManager.loaded[userId] then
        return false
    end
    
    local data = DataPersistenceManager.loaded[userId]
    
    -- Get leaderstats (cash)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats and leaderstats:FindFirstChild("Cash") then
        data.cash = leaderstats.Cash.Value
    end
    
    -- Get tycoon attributes
    local tycoon = player:FindFirstChild("Tycoon")
    if tycoon then
        -- Update equipment count
        if tycoon:GetAttribute("EquipmentCount") ~= nil then
            data.equipmentCount = tycoon:GetAttribute("EquipmentCount")
        elseif tycoon:FindFirstChild("EquipmentCount") then
            data.equipmentCount = tycoon.EquipmentCount.Value
        end
        
        -- Update gym level/tier
        if tycoon:GetAttribute("GymTier") ~= nil then
            data.gymLevel = tycoon:GetAttribute("GymTier")
        elseif tycoon:GetAttribute("GymLevel") ~= nil then
            data.gymLevel = tycoon:GetAttribute("GymLevel")
        elseif tycoon:FindFirstChild("GymLevel") then
            data.gymLevel = tycoon.GymLevel.Value
        end
        
        -- Update membership counts
        if tycoon:GetAttribute("MemberCount") ~= nil then
            data.memberCount = tycoon:GetAttribute("MemberCount")
        elseif tycoon:GetAttribute("MembershipCount") ~= nil then
            data.memberCount = tycoon:GetAttribute("MembershipCount") 
        elseif tycoon:FindFirstChild("MemberCount") then
            data.memberCount = tycoon.MemberCount.Value
        end
        
        -- Update accrued dues
        if tycoon:GetAttribute("AccruedDues") ~= nil then
            data.accruedDues = tycoon:GetAttribute("AccruedDues")
        elseif tycoon:FindFirstChild("AccruedDues") then
            data.accruedDues = tycoon.AccruedDues.Value
        end
        
        -- Check purchased equipment
        if tycoon.Value then
            -- Look through tycoon model for equipment with ID attributes
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

-- Save player data
function DataPersistenceManager.saveData(player, immediately)
    if not player then return false end
    local userId = player.UserId
    
    -- Make sure data is loaded
    if not DataPersistenceManager.loaded[userId] then
        log("No data loaded for", player.Name, "- loading now")
        if not DataPersistenceManager.loadData(player) then
            warn("Failed to load data for", player.Name)
            
            -- Increment failure counter
            DataPersistenceManager.saveFailures = DataPersistenceManager.saveFailures + 1
            
            -- Fire data failed event
            if DataPersistenceManager.events.onDataFailed then
                DataPersistenceManager.events.onDataFailed:Fire(player, "load_failed")
            end
            
            return false
        end
    end
    
    -- Fix tycoon structure if needed
    if CONFIG.enforceStructure then
        DataPersistenceManager.validateTycoonStructure(player)
    end
    
    -- Update data from player first
    DataPersistenceManager.updateDataFromPlayer(player)
    
    local data = DataPersistenceManager.loaded[userId]
    local key = "Player_" .. userId
    
    -- Update last save time
    data.lastSaveTime = os.time()
    
    -- Try to save data
    local success = safeDataStoreCall(function()
        DataPersistenceManager.dataStore:SetAsync(key, data)
        return true
    end)
    
    if success then
        log("Saved data for", player.Name, immediately and "(immediate)" or "")
        
        -- Increment saved counter
        DataPersistenceManager.savedCount = DataPersistenceManager.savedCount + 1
        
        -- Fire data saved event
        if DataPersistenceManager.events.onDataSaved then
            DataPersistenceManager.events.onDataSaved:Fire(player, data)
        end
        
        return true
    else
        warn("Failed to save data for", player.Name)
        
        -- Increment failure counter
        DataPersistenceManager.saveFailures = DataPersistenceManager.saveFailures + 1
        
        -- Create a backup if immediate save failed
        if immediately then
            DataPersistenceManager.createBackup(player)
        end
        
        -- Fire data failed event
        if DataPersistenceManager.events.onDataFailed then
            DataPersistenceManager.events.onDataFailed:Fire(player, "save_failed")
        end
        
        return false
    end
end

-- Create a backup of player data
function DataPersistenceManager.createBackup(player)
    if not player then return false end
    local userId = player.UserId
    
    -- Make sure data is loaded
    if not DataPersistenceManager.loaded[userId] then
        return false
    end
    
    local data = DataPersistenceManager.loaded[userId]
    local key = "Backup_" .. userId .. "_" .. os.time()
    
    -- Try to save backup
    local success = pcall(function()
        DataPersistenceManager.backupStore:SetAsync(key, data)
    end)
    
    if success then
        log("Created backup for", player.Name)
        return true
    else
        warn("Failed to create backup for", player.Name)
        return false
    end
end

-- Start auto-save for player
function DataPersistenceManager.startAutoSave(player)
    if not player then return false end
    local userId = player.UserId
    
    -- Stop existing auto-save if running
    DataPersistenceManager.stopAutoSave(player)
    
    -- Start new auto-save thread
    DataPersistenceManager.savers[userId] = true
    
    task.spawn(function()
        while player and player.Parent and DataPersistenceManager.savers[userId] do
            task.wait(CONFIG.saveInterval)
            
            -- Only save if player is still in game
            if player and player.Parent then
                DataPersistenceManager.saveData(player, false)
            else
                -- Player left, stop auto-save
                DataPersistenceManager.savers[userId] = nil
                break
            end
        end
    end)
    
    log("Started auto-save for", player.Name)
    return true
end

-- Stop auto-save for player
function DataPersistenceManager.stopAutoSave(player)
    if not player then return false end
    local userId = player.UserId
    
    if DataPersistenceManager.savers[userId] then
        DataPersistenceManager.savers[userId] = nil
        log("Stopped auto-save for", player.Name)
        return true
    end
    
    return false
end

-- Apply data to player
function DataPersistenceManager.applyDataToPlayer(player)
    if not player then return false end
    local userId = player.UserId
    
    -- Make sure data is loaded
    if not DataPersistenceManager.loaded[userId] then
        log("No data loaded for", player.Name, "- loading now")
        if not DataPersistenceManager.loadData(player) then
            warn("Failed to load data for", player.Name)
            return false
        end
    end
    
    local data = DataPersistenceManager.loaded[userId]
    
    -- Create leaderstats if needed
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end
    
    -- Set cash
    local cashValue = leaderstats:FindFirstChild("Cash")
    if not cashValue then
        cashValue = Instance.new("IntValue")
        cashValue.Name = "Cash"
        cashValue.Parent = leaderstats
    end
    cashValue.Value = data.cash
    
    -- Make sure Tycoon object exists
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon:IsA("ObjectValue") then
        if CONFIG.enforceStructure then
            DataPersistenceManager.validateTycoonStructure(player)
            tycoon = player:FindFirstChild("Tycoon")
        else
            tycoon = Instance.new("ObjectValue")
            tycoon.Name = "Tycoon"
            tycoon.Parent = player
        end
    end
    
    -- Set tycoon attributes or values
    if tycoon:FindFirstChild("EquipmentCount") then
        tycoon.EquipmentCount.Value = data.equipmentCount
    else
        tycoon:SetAttribute("EquipmentCount", data.equipmentCount)
    end
    
    if tycoon:FindFirstChild("GymLevel") then
        tycoon.GymLevel.Value = data.gymLevel
    else
        tycoon:SetAttribute("GymTier", data.gymLevel)
    end
    
    if tycoon:FindFirstChild("MemberCount") then
        tycoon.MemberCount.Value = data.memberCount
    else
        tycoon:SetAttribute("MemberCount", data.memberCount)
    end
    
    if tycoon:FindFirstChild("AccruedDues") then
        tycoon.AccruedDues.Value = data.accruedDues
    else
        tycoon:SetAttribute("AccruedDues", data.accruedDues)
    end
    
    log("Applied data to", player.Name)
    return true
end

-- Set up player
function DataPersistenceManager.setupPlayer(player)
    if not player then return false end
    
    -- Load data
    local data = DataPersistenceManager.loadData(player)
    if not data then
        warn("Failed to load data for", player.Name)
        return false
    end
    
    -- Apply data to player
    DataPersistenceManager.applyDataToPlayer(player)
    
    return true
end

-- Connect events
function DataPersistenceManager.connectEvents()
    -- Connect to player joining
    Players.PlayerAdded:Connect(function(player)
        task.delay(2, function()
            DataPersistenceManager.setupPlayer(player)
        end)
    end)
    
    -- Connect to player leaving
    Players.PlayerRemoving:Connect(function(player)
        -- Save data immediately
        DataPersistenceManager.saveData(player, true)
        
        -- Create backup
        DataPersistenceManager.createBackup(player)
        
        -- Stop auto-save
        DataPersistenceManager.stopAutoSave(player)
        
        -- Clear from cache
        local userId = player.UserId
        DataPersistenceManager.loaded[userId] = nil
        
        log("Cleaned up for leaving player:", player.Name)
    end)
    
    -- Connect to game closing
    game:BindToClose(function()
        log("Game closing, saving all player data...")
        
        -- Save for all players
        for _, player in pairs(Players:GetPlayers()) do
            DataPersistenceManager.saveData(player, true)
        end
        
        -- Log stats
        log("Saved", DataPersistenceManager.savedCount, "player data records during shutdown")
        if DataPersistenceManager.saveFailures > 0 then
            warn("Failed to save", DataPersistenceManager.saveFailures, "player data records")
        end
        
        -- Allow time for saves to complete
        task.wait(5)
    end)
}

-- Initialize the system
DataPersistenceManager.init()

-- Set up for existing players
for _, player in pairs(Players:GetPlayers()) do
    task.spawn(function()
        DataPersistenceManager.setupPlayer(player)
    end)
end

return DataPersistenceManager
