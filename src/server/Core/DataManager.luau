--[[
    DataManager.luau
    This module provides a centralized data management system for the game.
    It handles loading, saving, and validation of player data.
    
    Created to fix critical "Data Saving Failures on Player Leave" reported in RobloxIssues.txt
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

-- Find safe require module
local function findModule(moduleName)
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService,
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    return nil
end

-- Safe require function to handle missing modules
local function safeRequire(modulePath, fallback)
    if typeof(modulePath) ~= "Instance" then
        return fallback
    end
    
    local success, result = pcall(function()
        return require(modulePath)
    end)
    
    if success then
        return result
    else
        warn("DataManager: Failed to require " .. modulePath:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
end

-- Safe wait for child with timeout
local function safeWaitForChild(parent, childName, timeout)
    timeout = timeout or 5
    
    -- Quick check first
    local child = parent:FindFirstChild(childName)
    if child then return child end
    
    -- Use timeout to prevent infinite yield
    local startTime = os.clock()
    
    while not child and (os.clock() - startTime) < timeout do
        task.wait(0.1)
        child = parent:FindFirstChild(childName)
    end
    
    if not child then
        warn("DataManager: Timeout waiting for " .. childName .. " in " .. parent:GetFullName())
    end
    
    return child
end

-- Configuration
local DATA_STORE_NAME = "GymTycoonDataV2"
local AUTOSAVE_INTERVAL = 60 -- seconds
local MAX_RETRIES = 3
local RETRY_DELAY = 3 -- seconds

-- Try to load dependencies
local SafeWaitForChild = safeRequire(findModule("SafeWaitForChild")) or { waitForChild = safeWaitForChild }
local EventBridge = safeRequire(findModule("EventBridge")) or { fireEvent = function() end, registerEvent = function() end }

-- Create the module
local DataManager = {}

-- Data cache
local playerData = {}
local dataStore
local isInitialized = false
local savingInProgress = {}
local coreRegistry

-- Version information
DataManager.VERSION = "1.0.0"
DataManager.isLoaded = true

-- Register events with EventBridge
if EventBridge.registerEvent then
    EventBridge.registerEvent("DataManager_PlayerDataLoaded")
    EventBridge.registerEvent("DataManager_PlayerDataSaved")
    EventBridge.registerEvent("DataManager_PlayerDataError")
    EventBridge.registerEvent("DataManager_TileRestored")
    EventBridge.registerEvent("DataManager_DataMigrated")
end

-- Default data structure for new players
local DEFAULT_PLAYER_DATA = {
    coins = 0,
    level = 1,
    experience = 0,
    statistics = {
        totalVisitors = 0,
        totalRevenue = 0,
        playtime = 0,
        tilesUnlocked = 0
    },
    tiles = {},
    purchases = {},
    settings = {
        musicVolume = 0.5,
        sfxVolume = 0.5,
        notifications = true
    },
    achievements = {},
    lastLogin = 0,
    version = 2
}

-- Initialize the DataManager
function DataManager.initialize()
    if isInitialized then
        return true
    end
    
    print("DataManager: Initializing...")
    
    -- Attempt to get the DataStore
    local success, result = pcall(function()
        return DataStoreService:GetDataStore(DATA_STORE_NAME)
    end)
    
    if not success then
        warn("DataManager: Failed to get DataStore - " .. tostring(result))
        warn("DataManager: Data saving will not work!")
        return false
    end
    
    dataStore = result
    isInitialized = true
    
    -- Set up player events
    Players.PlayerAdded:Connect(function(player)
        DataManager.loadPlayerData(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        DataManager.savePlayerData(player)
    end)
    
    -- Set up autosave
    task.spawn(function()
        while true do
            task.wait(AUTOSAVE_INTERVAL)
            DataManager.saveAllPlayers()
        end
    end)
    
    print("DataManager: Initialized successfully")
    return true
end

-- Validate player data structure
function DataManager.validateData(data)
    if not data then
        return false
    end
    
    -- Check if it's a table
    if typeof(data) ~= "table" then
        return false
    end
    
    -- Check for essential fields
    local essentialFields = {
        "coins", "level", "statistics", "tiles", "purchases", "version"
    }
    
    for _, field in ipairs(essentialFields) do
        if data[field] == nil then
            warn("DataManager: Missing essential field in player data - " .. field)
            return false
        end
    end
    
    return true
end

-- Fix player data structure
function DataManager.fixPlayerData(data)
    if not data then
        return table.clone(DEFAULT_PLAYER_DATA)
    end
    
    -- Make sure it's a table
    if typeof(data) ~= "table" then
        warn("DataManager: Player data is not a table, creating default data")
        return table.clone(DEFAULT_PLAYER_DATA)
    end
    
    -- Create a fixed copy
    local fixedData = table.clone(data)
    
    -- Check and fix essential fields
    if not fixedData.coins then fixedData.coins = DEFAULT_PLAYER_DATA.coins end
    if not fixedData.level then fixedData.level = DEFAULT_PLAYER_DATA.level end
    if not fixedData.experience then fixedData.experience = DEFAULT_PLAYER_DATA.experience end
    
    if not fixedData.statistics or typeof(fixedData.statistics) ~= "table" then
        fixedData.statistics = table.clone(DEFAULT_PLAYER_DATA.statistics)
    else
        -- Ensure all statistics fields exist
        for k, v in pairs(DEFAULT_PLAYER_DATA.statistics) do
            if fixedData.statistics[k] == nil then
                fixedData.statistics[k] = v
            end
        end
    end
    
    if not fixedData.tiles or typeof(fixedData.tiles) ~= "table" then
        fixedData.tiles = {}
    end
    
    if not fixedData.purchases or typeof(fixedData.purchases) ~= "table" then
        fixedData.purchases = {}
    end
    
    if not fixedData.settings or typeof(fixedData.settings) ~= "table" then
        fixedData.settings = table.clone(DEFAULT_PLAYER_DATA.settings)
    else
        -- Ensure all settings fields exist
        for k, v in pairs(DEFAULT_PLAYER_DATA.settings) do
            if fixedData.settings[k] == nil then
                fixedData.settings[k] = v
            end
        end
    end
    
    if not fixedData.achievements or typeof(fixedData.achievements) ~= "table" then
        fixedData.achievements = {}
    end
    
    -- Update version to current
    fixedData.version = DEFAULT_PLAYER_DATA.version
    
    -- Update last login
    fixedData.lastLogin = os.time()
    
    return fixedData
end

-- Load player data
function DataManager.loadPlayerData(player)
    if savingInProgress[player.UserId] then
        warn("DataManager: Cannot load data for " .. player.Name .. " while saving is in progress")
        return false
    end
    
    if not isInitialized then
        warn("DataManager: Cannot load data for " .. player.Name .. " - DataManager not initialized")
        return false
    end
    
    print("DataManager: Loading data for " .. player.Name)
    
    -- Try to load from DataStore
    local success, result
    
    for retry = 1, MAX_RETRIES do
        success, result = pcall(function()
            return dataStore:GetAsync("Player_" .. player.UserId)
        end)
        
        if success then
            break
        else
            warn("DataManager: Failed to load data for " .. player.Name .. " - " .. tostring(result) .. " (Attempt " .. retry .. "/" .. MAX_RETRIES .. ")")
            task.wait(RETRY_DELAY)
        end
    end
    
    local data
    
    if success and result then
        -- We got some data, validate and fix it if needed
        if DataManager.validateData(result) then
            data = result
        else
            warn("DataManager: Invalid data structure for " .. player.Name .. ", fixing...")
            data = DataManager.fixPlayerData(result)
        end
    else
        -- No data or failed to load, use default
        warn("DataManager: No data found for " .. player.Name .. ", creating default data")
        data = table.clone(DEFAULT_PLAYER_DATA)
    end
    
    -- Update last login
    data.lastLogin = os.time()
    
    -- Cache the data
    playerData[player.UserId] = data
    
    -- Notify that data was loaded
    if EventBridge.fireEvent then
        EventBridge.fireEvent("DataManager_PlayerDataLoaded", {
            player = player,
            data = data
        })
    end
    
    -- Restore player's tycoon
    DataManager.restorePlayerTycoon(player)
    
    return true
end

-- Save player data
function DataManager.savePlayerData(player)
    if not isInitialized then
        warn("DataManager: Cannot save data for " .. player.Name .. " - DataManager not initialized")
        return false
    end
    
    if savingInProgress[player.UserId] then
        warn("DataManager: Already saving data for " .. player.Name)
        return false
    end
    
    local data = playerData[player.UserId]
    if not data then
        warn("DataManager: No data found for " .. player.Name)
        return false
    end
    
    print("DataManager: Saving data for " .. player.Name)
    savingInProgress[player.UserId] = true
    
    -- Update last played time
    data.statistics.playtime = data.statistics.playtime + (os.time() - data.lastLogin)
    data.lastLogin = os.time()
    
    -- Check for the DataAccessLayer for enhanced saving
    local dataAccessLayerModule = findModule("DataAccessLayer")
    local DataAccessLayer = dataAccessLayerModule and safeRequire(dataAccessLayerModule)
    
    if DataAccessLayer and typeof(DataAccessLayer.saveData) == "function" then
        -- Use the enhanced DataAccessLayer
        local saveSuccess = DataAccessLayer.saveData(
            DATA_STORE_NAME, 
            "Player_" .. player.UserId, 
            data, 
            {
                retryCount = MAX_RETRIES,
                retryDelay = RETRY_DELAY,
                metadata = {
                    playerName = player.Name,
                    saveTime = os.time()
                }
            }
        )
        
        savingInProgress[player.UserId] = nil
        
        -- Notify that data was scheduled for saving
        if EventBridge.fireEvent then
            EventBridge.fireEvent("DataManager_PlayerDataSaved", {
                player = player,
                success = saveSuccess,
                usingAdvancedLayer = true
            })
        end
        
        return saveSuccess
    else
        -- Fall back to direct DataStore usage
        local success, result
        
        for retry = 1, MAX_RETRIES do
            success, result = pcall(function()
                return dataStore:SetAsync("Player_" .. player.UserId, data)
            end)
            
            if success then
                break
            else
                warn("DataManager: Failed to save data for " .. player.Name .. " - " .. tostring(result) .. " (Attempt " .. retry .. "/" .. MAX_RETRIES .. ")")
                task.wait(RETRY_DELAY)
            end
        end
        
        savingInProgress[player.UserId] = nil
        
        -- Notify that data was saved or failed to save
        if EventBridge.fireEvent then
            if success then
                EventBridge.fireEvent("DataManager_PlayerDataSaved", {
                    player = player,
                    success = true,
                    usingAdvancedLayer = false
                })
            else
                EventBridge.fireEvent("DataManager_PlayerDataError", {
                    player = player,
                    error = "Failed to save data after " .. MAX_RETRIES .. " attempts"
                })
            end
        end
        
        return success
    end
end

-- Save all player data
function DataManager.saveAllPlayers()
    if not isInitialized then
        warn("DataManager: Cannot save all players - DataManager not initialized")
        return false
    end
    
    print("DataManager: Saving data for all players")
    
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            DataManager.savePlayerData(player)
        end)
    end
    
    return true
end

-- Get player data
function DataManager.getPlayerData(player)
    if not player then
        warn("DataManager: Cannot get data for nil player")
        return nil
    end
    
    local userId = typeof(player) == "number" and player or player.UserId
    
    if not playerData[userId] then
        warn("DataManager: No data found for player " .. tostring(userId))
        return nil
    end
    
    return table.clone(playerData[userId])
end

-- Update player data
function DataManager.updatePlayerData(player, newData)
    if not player then
        warn("DataManager: Cannot update data for nil player")
        return false
    end
    
    local userId = typeof(player) == "number" and player or player.UserId
    
    if not playerData[userId] then
        warn("DataManager: No data found for player " .. tostring(userId))
        return false
    end
    
    if typeof(newData) ~= "table" then
        warn("DataManager: Invalid data type for player " .. tostring(userId))
        return false
    end
    
    -- Update the data
    for key, value in pairs(newData) do
        if key ~= "version" then -- Don't override version
            playerData[userId][key] = value
        end
    end
    
    return true
end

-- Restore player's tycoon
function DataManager.restorePlayerTycoon(player)
    if not player then
        warn("DataManager: Cannot restore tycoon for nil player")
        return false
    end
    
    local data = playerData[player.UserId]
    if not data then
        warn("DataManager: No data found for " .. player.Name)
        return false
    end
    
    print("DataManager: Restoring tycoon for " .. player.Name)
    
    -- Wait for player Tycoon folder to be created
    local tycoonFolder = SafeWaitForChild.waitForChild(player, "Tycoon", 10)
    if not tycoonFolder then
        warn("DataManager: Tycoon folder not found for " .. player.Name)
        return false
    end
    
    -- Create TycoonData folder if it doesn't exist
    local tycoonData = tycoonFolder:FindFirstChild("TycoonData")
    if not tycoonData then
        tycoonData = Instance.new("Folder")
        tycoonData.Name = "TycoonData"
        tycoonData.Parent = tycoonFolder
    end
    
    -- Create Stats folder if it doesn't exist
    local statsFolder = tycoonFolder:FindFirstChild("Stats")
    if not statsFolder then
        statsFolder = Instance.new("Folder")
        statsFolder.Name = "Stats"
        statsFolder.Parent = tycoonFolder
    end
    
    -- Create Purchases folder if it doesn't exist
    local purchasesFolder = tycoonFolder:FindFirstChild("Purchases")
    if not purchasesFolder then
        purchasesFolder = Instance.new("Folder")
        purchasesFolder.Name = "Purchases"
        purchasesFolder.Parent = tycoonFolder
    end
    
    -- Set up basic values
    local function createOrUpdateValue(parent, name, value, valueType)
        local valueObj = parent:FindFirstChild(name)
        
        if not valueObj then
            valueObj = Instance.new(valueType)
            valueObj.Name = name
            valueObj.Parent = parent
        end
        
        valueObj.Value = value
    end
    
    -- Create or update basic stats
    createOrUpdateValue(statsFolder, "Coins", data.coins, "IntValue")
    createOrUpdateValue(statsFolder, "Level", data.level, "IntValue")
    createOrUpdateValue(statsFolder, "Experience", data.experience, "IntValue")
    createOrUpdateValue(statsFolder, "TotalVisitors", data.statistics.totalVisitors, "IntValue")
    createOrUpdateValue(statsFolder, "TotalRevenue", data.statistics.totalRevenue, "IntValue")
    createOrUpdateValue(statsFolder, "Playtime", data.statistics.playtime, "IntValue")
    createOrUpdateValue(statsFolder, "TilesUnlocked", data.statistics.tilesUnlocked, "IntValue")
    
    -- Restore tiles
    local restoredTiles = 0
    local totalTiles = 0
    
    for tileId, tileData in pairs(data.tiles) do
        totalTiles = totalTiles + 1
        
        -- Try to restore the tile
        local success = DataManager.restoreTile(player, tileId, tileData)
        
        if success then
            restoredTiles = restoredTiles + 1
            
            if EventBridge.fireEvent then
                EventBridge.fireEvent("DataManager_TileRestored", {
                    player = player,
                    tileId = tileId,
                    success = true
                })
            end
        else
            warn("DataManager: Failed to restore tile " .. tileId .. " for " .. player.Name)
            
            if EventBridge.fireEvent then
                EventBridge.fireEvent("DataManager_TileRestored", {
                    player = player,
                    tileId = tileId,
                    success = false
                })
            end
        end
    end
    
    print("DataManager: Restored " .. restoredTiles .. " of " .. totalTiles .. " tiles for " .. player.Name)
    return true
end

-- Restore a specific tile
function DataManager.restoreTile(player, tileId, tileData)
    if not player or not tileId or not tileData then
        warn("DataManager: Invalid parameters for restoreTile")
        return false
    end
    
    local tycoonFolder = player:FindFirstChild("Tycoon")
    if not tycoonFolder then
        warn("DataManager: Tycoon folder not found for " .. player.Name)
        return false
    end
    
    -- Find the tile in the tycoon
    local tile = tycoonFolder:FindFirstChild(tileId)
    if not tile then
        warn("DataManager: Tile " .. tileId .. " not found for " .. player.Name)
        return false
    end
    
    -- Update tile properties
    for property, value in pairs(tileData.properties or {}) do
        -- Skip invalid properties
        if property == "Parent" or property == "Name" then
            continue
        end
        
        -- Try to set the property
        local success, err = pcall(function()
            tile[property] = value
        end)
        
        if not success then
            warn("DataManager: Failed to set property " .. property .. " on tile " .. tileId .. " - " .. err)
        end
    end
    
    -- Restore purchase status if applicable
    if tileData.purchased then
        local purchasesFolder = tycoonFolder:FindFirstChild("Purchases")
        if not purchasesFolder then
            purchasesFolder = Instance.new("Folder")
            purchasesFolder.Name = "Purchases"
            purchasesFolder.Parent = tycoonFolder
        end
        
        local purchaseValue = purchasesFolder:FindFirstChild(tileId)
        if not purchaseValue then
            purchaseValue = Instance.new("BoolValue")
            purchaseValue.Name = tileId
            purchaseValue.Value = true
            purchaseValue.Parent = purchasesFolder
        else
            purchaseValue.Value = true
        end
    end
    
    -- Spawn gym part if needed
    if tileData.gymPartId then
        local success = DataManager.spawnGymPart(player, tile, tileData.gymPartId)
        if not success then
            warn("DataManager: Failed to spawn gym part for tile " .. tileId)
        end
    end
    
    return true
end

-- Spawn a gym part on a tile
function DataManager.spawnGymPart(player, tile, gymPartId)
    if not player or not tile or not gymPartId then
        warn("DataManager: Invalid parameters for spawnGymPart")
        return false
    end
    
    -- Create GymParts folder if it doesn't exist
    local gymPartsFolder = ServerStorage:FindFirstChild("GymParts")
    if not gymPartsFolder then
        gymPartsFolder = Instance.new("Folder")
        gymPartsFolder.Name = "GymParts"
        gymPartsFolder.Parent = ServerStorage
        warn("DataManager: GymParts folder not found in ServerStorage, created a new one")
    end
    
    -- Find the gym part model
    local gymPartModel
    
    -- First try direct lookup
    gymPartModel = gymPartsFolder:FindFirstChild(gymPartId)
    
    -- Try numeric ID conversion if the ID looks like a string number
    if not gymPartModel and tonumber(gymPartId) then
        gymPartModel = gymPartsFolder:FindFirstChild(tostring(tonumber(gymPartId)))
    end
    
    -- If not found, search recursively by name
    if not gymPartModel then
        for _, item in ipairs(gymPartsFolder:GetDescendants()) do
            if item:IsA("Model") or item:IsA("Part") then
                if item.Name == gymPartId or item.Name == tostring(tonumber(gymPartId)) then
                    gymPartModel = item
                    break
                end
            end
        end
    end
    
    -- Search by tag if tags are being used
    if not gymPartModel then
        local CollectionService = game:GetService("CollectionService")
        local taggedParts = CollectionService:GetTagged("GymPart_"..gymPartId)
        if #taggedParts > 0 then
            gymPartModel = taggedParts[1]
        end
    end
    
    -- If still not found, check for standard parts by ID
    if not gymPartModel then
        -- Look in predefined categories
        local categories = {"Weights", "Cardio", "Machines", "Amenities", "Furniture", "Standard"}
        for _, category in ipairs(categories) do
            local folder = gymPartsFolder:FindFirstChild(category)
            if folder then
                gymPartModel = folder:FindFirstChild(gymPartId)
                if gymPartModel then 
                    break
                end
            end
        end
    end
    
    -- If still not found, use fallback system
    if not gymPartModel then
        warn("DataManager: Could not find gym part with ID: " .. gymPartId)
        
        -- Create a default part as ultimate fallback
        local defaultPart = Instance.new("Part")
        defaultPart.Name = "DefaultGymPart_" .. gymPartId
        defaultPart.Anchored = true
        defaultPart.Size = Vector3.new(4, 1, 4)
        defaultPart.BrickColor = BrickColor.new("Bright blue")
        defaultPart.Material = Enum.Material.Plastic
        
        -- Add a SurfaceGui with a label
        local surfaceGui = Instance.new("SurfaceGui")
        surfaceGui.Parent = defaultPart
        surfaceGui.Face = Enum.NormalId.Top
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Parent = surfaceGui
        textLabel.BackgroundTransparency = 1
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.Text = "Gym Part " .. gymPartId
        textLabel.TextScaled = true
        
        -- Use this as the model
        gymPartModel = defaultPart
        
        -- Also try custom fallback if available
        if DataManager.useFallbackGymPart then
            print("DataManager: Using fallback spawnGymPart for ID: " .. gymPartId)
            local success = DataManager.useFallbackGymPart(player, tile, gymPartId)
            if success then
                return true
            end
        end
    end
    
    -- Clone and position the model
    local model = gymPartModel:Clone()
    model.Name = gymPartId
    
    -- Position at the tile (handle different model types)
    if model:IsA("Model") and model.PrimaryPart then
        model:SetPrimaryPartCFrame(tile.CFrame)
    else
        -- For parts or models without PrimaryPart
        model.CFrame = tile.CFrame + Vector3.new(0, model:IsA("Part") and model.Size.Y/2 or 0, 0)
    end
    
    model.Parent = tile
    
    print("DataManager: Successfully spawned gym part with ID: " .. gymPartId)
    return true
end

-- Add a custom fallback for gym part spawning
function DataManager.setFallbackGymPartHandler(handler)
    if typeof(handler) ~= "function" then
        warn("DataManager: Invalid fallback handler, must be a function")
        return false
    end
    
    DataManager.useFallbackGymPart = handler
    return true
end

-- Initialize the module
DataManager.initialize()

-- Register with CoreRegistry if available
coreRegistry = safeRequire(findModule("CoreRegistry"))
if coreRegistry and coreRegistry.registerSystem then
    coreRegistry.registerSystem("DataManager", DataManager)
    print("DataManager: Registered with CoreRegistry")
end

return DataManager
