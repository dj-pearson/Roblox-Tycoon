--[[
    DataManager.server.luau
    
    Enhanced data management system for Gym Tycoon.
    Provides robust data persistence, tile restoration, and error recovery.
    
    Features:
    - Reliable data persistence with backup system
    - Improved tile restoration with multiple fallback mechanisms
    - Better error handling and recovery
    - Integration with CoreRegistry
    - Health monitoring and status reporting
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Configuration
local CONFIG = {
    debug = true,
    dataStoreName = "GymTycoonDataV2",
    backupStoreName = "GymTycoonBackupV2",
    saveInterval = 60, -- seconds
    maxRetries = 3,
    retryDelay = 2, -- seconds
    defaultData = {
        cash = 1000,
        equipmentPurchased = {},
        equipmentCount = 0,
        gymLevel = 1,
        memberCount = 0,
        accruedDues = 0,
        lastSaveTime = 0,
        dataVersion = 2
    }
}

-- Module state
local DataManager = {
    loaded = {},      -- Cached player data
    savers = {},      -- Auto-save coroutines
    dataStore = nil,  -- Main DataStore
    backupStore = nil -- Backup DataStore
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[DataManager]", ...)
    end
end

-- Deep copy a table
local function deepCopy(original)
    if type(original) ~= "table" then return original end
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = type(value) == "table" and deepCopy(value) or value
    end
    return copy
end

-- Safe DataStore call with retries
local function safeDataStoreCall(operation, ...)
    local retries = 0
    local success, result
    
    while retries < CONFIG.maxRetries do
        success, result = pcall(operation, ...)
        if success then
            return true, result
        end
        
        retries += 1
        if retries < CONFIG.maxRetries then
            log("DataStore operation failed, retrying... (" .. retries .. "/" .. CONFIG.maxRetries .. ")")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    return false, result
end

-- Initialize DataManager
function DataManager.initialize()
    if DataManager.initialized then return true end
    
    log("Initializing DataManager...")
    
    -- Set up DataStores
    DataManager.dataStore = DataStoreService:GetDataStore(CONFIG.dataStoreName)
    DataManager.backupStore = DataStoreService:GetDataStore(CONFIG.backupStoreName)
    
    -- Connect to player events
    Players.PlayerAdded:Connect(function(player)
        task.delay(2, function()
            DataManager.loadData(player)
        end)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        DataManager.saveData(player, true)
    end)
    
    -- Start auto-save loop
    task.spawn(function()
        while true do
            task.wait(CONFIG.saveInterval)
            for _, player in ipairs(Players:GetPlayers()) do
                DataManager.saveData(player, false)
            end
        end
    end)
    
    DataManager.initialized = true
    log("DataManager initialized")
    return true
end

-- Load player data
function DataManager.loadData(player)
    if not player then return nil end
    local userId = player.UserId
    
    -- Check cache first
    if DataManager.loaded[userId] then
        return DataManager.loaded[userId]
    end
    
    log("Loading data for " .. player.Name)
    
    -- Try main DataStore
    local success, data = safeDataStoreCall(function()
        return DataManager.dataStore:GetAsync(tostring(userId))
    end)
    
    -- If failed, try backup
    if not success or not data then
        log("Main DataStore failed, trying backup...")
        success, data = safeDataStoreCall(function()
            return DataManager.backupStore:GetAsync(tostring(userId))
        end)
    end
    
    -- If still no data, use defaults
    if not success or not data then
        log("No saved data found, using defaults")
        data = deepCopy(CONFIG.defaultData)
    end
    
    -- Validate and repair data
    data = DataManager.validateAndRepairData(data)
    
    -- Cache the data
    DataManager.loaded[userId] = data
    
    -- Apply data to player
    DataManager.applyDataToPlayer(player)
    
    -- Restore purchased equipment
    task.delay(3, function()
        if player and player.Parent then
            DataManager.restorePurchasedEquipment(player)
        end
    end)
    
    return data
end

-- Save player data
function DataManager.saveData(player, force)
    if not player then return false end
    local userId = player.UserId
    local data = DataManager.loaded[userId]
    
    if not data then
        log("No data to save for " .. player.Name)
        return false
    end
    
    -- Update last save time
    data.lastSaveTime = os.time()
    
    -- Save to main DataStore
    local success, err = safeDataStoreCall(function()
        DataManager.dataStore:SetAsync(tostring(userId), data)
    end)
    
    if not success then
        log("Failed to save to main DataStore: " .. tostring(err))
        return false
    end
    
    -- Also save to backup
    success, err = safeDataStoreCall(function()
        DataManager.backupStore:SetAsync(tostring(userId), data)
    end)
    
    if not success then
        log("Failed to save to backup DataStore: " .. tostring(err))
    end
    
    log("Saved data for " .. player.Name)
    return true
end

-- Validate and repair data
function DataManager.validateAndRepairData(data)
    if not data then return deepCopy(CONFIG.defaultData) end
    
    -- Ensure all required fields exist
    for key, defaultValue in pairs(CONFIG.defaultData) do
        if data[key] == nil then
            data[key] = deepCopy(defaultValue)
        end
    end
    
    -- Validate equipmentPurchased
    if type(data.equipmentPurchased) ~= "table" then
        data.equipmentPurchased = {}
    end
    
    -- Validate equipmentCount
    if type(data.equipmentCount) ~= "number" then
        data.equipmentCount = 0
    end
    
    -- Validate gymLevel
    if type(data.gymLevel) ~= "number" or data.gymLevel < 1 then
        data.gymLevel = 1
    end
    
    -- Validate memberCount
    if type(data.memberCount) ~= "number" or data.memberCount < 0 then
        data.memberCount = 0
    end
    
    -- Validate accruedDues
    if type(data.accruedDues) ~= "number" or data.accruedDues < 0 then
        data.accruedDues = 0
    end
    
    return data
end

-- Apply data to player
function DataManager.applyDataToPlayer(player)
    if not player then return false end
    local userId = player.UserId
    local data = DataManager.loaded[userId]
    
    if not data then
        log("No data to apply for " .. player.Name)
        return false
    end
    
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
    if not tycoon then
        tycoon = Instance.new("ObjectValue")
        tycoon.Name = "Tycoon"
        tycoon.Parent = player
    end
    
    -- Set tycoon attributes
    tycoon:SetAttribute("EquipmentCount", data.equipmentCount)
    tycoon:SetAttribute("GymTier", data.gymLevel)
    tycoon:SetAttribute("MemberCount", data.memberCount)
    tycoon:SetAttribute("AccruedDues", data.accruedDues)
    
    log("Applied data to " .. player.Name)
    return true
end

-- Record equipment purchase
function DataManager.recordEquipmentPurchase(player, tileId)
    if not player then return false end
    local userId = player.UserId
    
    -- Make sure data is loaded
    if not DataManager.loaded[userId] then
        log("No data loaded for " .. player.Name .. " - loading now")
        DataManager.loadData(player)
    end
    
    -- Make sure we have data now
    if not DataManager.loaded[userId] then
        warn("Failed to load data for " .. player.Name)
        return false
    end
    
    local data = DataManager.loaded[userId]
    
    -- Record the purchase
    data.equipmentPurchased[tostring(tileId)] = true
    
    -- Update equipment count
    local tycoon = player:FindFirstChild("Tycoon")
    if tycoon then
        local count = tycoon:GetAttribute("EquipmentCount") or 0
        tycoon:SetAttribute("EquipmentCount", count + 1)
        data.equipmentCount = count + 1
    end
    
    log(player.Name .. " purchased tile " .. tileId)
    
    -- Trigger a save soon after purchase
    task.delay(5, function()
        if player and player.Parent then
            DataManager.saveData(player, false)
        end
    end)
    
    return true
end

-- Restore purchased equipment
function DataManager.restorePurchasedEquipment(player)
    if not player then return false end
    local userId = player.UserId
    
    -- Make sure data is loaded
    if not DataManager.loaded[userId] then
        log("No data loaded for " .. player.Name .. " - loading now")
        DataManager.loadData(player)
    end
    
    -- Make sure we have data now
    if not DataManager.loaded[userId] then
        warn("Failed to load data for " .. player.Name)
        return false
    end
    
    local data = DataManager.loaded[userId]
    
    -- Check if we have any purchases to restore
    if not data.equipmentPurchased or not next(data.equipmentPurchased) then
        log("No equipment to restore for " .. player.Name)
        return true
    end
    
    -- Make sure player has a tycoon model
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then
        log("Player " .. player.Name .. " has no tycoon model assigned")
        return false
    end
    
    -- Get the BuyTile system
    local buyTileSystem = CoreRegistry.getSystem("BuyTileSystem")
    if not buyTileSystem then
        warn("Could not get BuyTile system")
        return false
    end
    
    -- Create a list of purchased tile IDs
    local tileIds = {}
    for idStr in pairs(data.equipmentPurchased) do
        local id = tonumber(idStr)
        if id and id > 0 then
            table.insert(tileIds, id)
        end
    end
    
    -- Sort IDs for sequential placement
    table.sort(tileIds)
    
    log("Restoring " .. #tileIds .. " tiles for " .. player.Name)
    
    -- Track successful restores
    local restoredCount = 0
    
    -- Restore each tile with a small delay
    for _, id in ipairs(tileIds) do
        task.wait(0.2) -- Small delay to avoid overwhelming the server
        
        -- Check if item with this ID already exists
        local exists = false
        for _, item in pairs(tycoon.Value:GetDescendants()) do
            if item:GetAttribute("ID") == id then
                exists = true
                restoredCount = restoredCount + 1
                break
            end
        end
        
        if not exists then
            -- Try different spawn methods
            local part = nil
            
            -- Try BuyTileSystem first
            if buyTileSystem.spawnGymPart then
                part = buyTileSystem.spawnGymPart(id)
            end
            
            -- If that failed, try fallback methods
            if not part then
                -- Try to find the part in ServerStorage
                local serverStorage = game:GetService("ServerStorage")
                local buyTilesFolder = serverStorage:FindFirstChild("BuyTiles")
                
                if buyTilesFolder then
                    for _, item in pairs(buyTilesFolder:GetDescendants()) do
                        if item:IsA("Model") and item:GetAttribute("ID") == id then
                            part = item:Clone()
                            part.Parent = tycoon.Value
                            break
                        end
                    end
                end
            end
            
            if part then
                -- Make sure the part is parented to the tycoon model
                if part.Parent ~= tycoon.Value then
                    part.Parent = tycoon.Value
                end
                
                -- Set owner attribute
                part:SetAttribute("Owner", player.UserId)
                
                restoredCount = restoredCount + 1
                log("Restored tile " .. id .. " for " .. player.Name)
            else
                warn("Failed to restore tile " .. id .. " for " .. player.Name)
            end
        end
    end
    
    -- Update equipment count attribute
    tycoon:SetAttribute("EquipmentCount", restoredCount)
    data.equipmentCount = restoredCount
    
    log("Restored " .. restoredCount .. " of " .. #tileIds .. " tiles for " .. player.Name)
    
    return restoredCount > 0
end

-- Get player data
function DataManager.getPlayerData(player)
    if not player then return nil end
    local userId = player.UserId
    return DataManager.loaded[userId]
end

-- Get all player data
function DataManager.getAllPlayerData()
    return DataManager.loaded
end

-- Clear player data (for testing)
function DataManager.clearPlayerData(player)
    if not player then return false end
    local userId = player.UserId
    
    -- Clear from cache
    DataManager.loaded[userId] = nil
    
    -- Clear from DataStores
    local success = true
    
    success = success and safeDataStoreCall(function()
        DataManager.dataStore:RemoveAsync(tostring(userId))
    end)
    
    success = success and safeDataStoreCall(function()
        DataManager.backupStore:RemoveAsync(tostring(userId))
    end)
    
    return success
end

return DataManager 