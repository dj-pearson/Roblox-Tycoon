--[[
    TycoonHelper.lua
    This module provides utilities for working with tycoons in the game.
    It handles tycoon creation, restoration, and management.
    
    Created to fix "Data Restoration Issues" reported in RobloxIssues.txt
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- Determine if we're on server or client
local isServer = RunService:IsServer()
local isClient = RunService:IsClient()

-- Create the module
local TycoonHelper = {}

-- Version information
TycoonHelper.VERSION = "1.0.0"
TycoonHelper.isLoaded = true

-- Configuration
local TYCOON_TEMPLATE_PATH = "GymTemplate"
local MAX_RETRIES = 3
local RETRY_DELAY = 1

-- Helper functions
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

local function safeRequire(modulePath, fallback)
    if typeof(modulePath) ~= "Instance" then
        return fallback
    end
    
    local success, result = pcall(function()
        return require(modulePath)
    end)
    
    if not success then
        warn("TycoonHelper: Failed to require " .. modulePath:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
    
    return result
end

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
        warn("TycoonHelper: Timeout waiting for " .. childName .. " in " .. parent:GetFullName())
    end
    
    return child
end

-- Try to load dependencies
local SafeWaitForChild = safeRequire(findModule("SafeWaitForChild")) or { waitForChild = safeWaitForChild }
local EventBridge = safeRequire(findModule("EventBridge")) or { fireEvent = function() end, registerEvent = function() end }
local DataManager = isServer and safeRequire(findModule("DataManager"))

-- Register events with EventBridge
if EventBridge.registerEvent then
    EventBridge.registerEvent("TycoonHelper_TycoonCreated")
    EventBridge.registerEvent("TycoonHelper_TileRestored")
    EventBridge.registerEvent("TycoonHelper_GymPartSpawned")
    EventBridge.registerEvent("TycoonHelper_TileCreationFailed")
end

-- Initialize the TycoonHelper
function TycoonHelper.initialize()
    print("TycoonHelper: Initializing...")
    
    -- Server-side initialization
    if isServer then
        -- Check for tycoon template
        local gymTemplate = ServerStorage:FindFirstChild(TYCOON_TEMPLATE_PATH)
        if not gymTemplate then
            warn("TycoonHelper: Could not find tycoon template at " .. TYCOON_TEMPLATE_PATH)
        else
            print("TycoonHelper: Found tycoon template")
        end
        
        -- Set up player added handler
        Players.PlayerAdded:Connect(function(player)
            -- Wait a bit for the player to fully load
            task.wait(1)
            
            -- Create tycoon for the player if needed
            if not player:FindFirstChild("Tycoon") then
                TycoonHelper.createTycoonForPlayer(player)
            end
        end)
    end
    
    print("TycoonHelper: Initialized successfully")
    return true
end

-- Create a tycoon for a player
function TycoonHelper.createTycoonForPlayer(player)
    if not isServer then
        warn("TycoonHelper: Cannot create tycoon for player on client")
        return false
    end
    
    if not player or not player:IsA("Player") then
        warn("TycoonHelper: Invalid player")
        return false
    end
    
    print("TycoonHelper: Creating tycoon for " .. player.Name)
    
    -- Check if player already has a tycoon
    if player:FindFirstChild("Tycoon") then
        print("TycoonHelper: Player " .. player.Name .. " already has a tycoon")
        return true
    end
    
    -- Find the tycoon template
    local gymTemplate = ServerStorage:FindFirstChild(TYCOON_TEMPLATE_PATH)
    if not gymTemplate then
        warn("TycoonHelper: Could not find tycoon template")
        return false
    end
    
    -- Create the tycoon
    local tycoon = gymTemplate:Clone()
    tycoon.Name = "Tycoon"
    
    -- Create required folders
    local statsFolder = Instance.new("Folder")
    statsFolder.Name = "Stats"
    statsFolder.Parent = tycoon
    
    local purchasesFolder = Instance.new("Folder")
    purchasesFolder.Name = "Purchases"
    purchasesFolder.Parent = tycoon
    
    local tycoonDataFolder = Instance.new("Folder")
    tycoonDataFolder.Name = "TycoonData"
    tycoonDataFolder.Parent = tycoon
    
    -- Create basic stats
    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = 0
    coins.Parent = statsFolder
    
    local level = Instance.new("IntValue")
    level.Name = "Level"
    level.Value = 1
    level.Parent = statsFolder
    
    -- Assign to player
    tycoon.Parent = player
    
    -- Fire event
    if EventBridge.fireEvent then
        EventBridge.fireEvent("TycoonHelper_TycoonCreated", {
            player = player,
            tycoon = tycoon
        })
    end
    
    print("TycoonHelper: Created tycoon for " .. player.Name)
    return true
end

-- Spawn a gym part on a tile
function TycoonHelper.spawnGymPart(player, tile, gymPartId)
    if not isServer then
        warn("TycoonHelper: Cannot spawn gym part on client")
        return false
    end
    
    if not player or not tile or not gymPartId then
        warn("TycoonHelper: Invalid parameters for spawnGymPart")
        return false
    end
    
    -- Look for the gym part in ServerStorage
    local gymPartsFolder = ServerStorage:FindFirstChild("GymParts")
    if not gymPartsFolder then
        warn("TycoonHelper: GymParts folder not found in ServerStorage")
        return false
    end
    
    -- Find the gym part model
    local gymPartModel
    
    -- First try direct lookup
    gymPartModel = gymPartsFolder:FindFirstChild(gymPartId)
    
    -- If not found, search recursively
    if not gymPartModel then
        for _, folder in ipairs(gymPartsFolder:GetDescendants()) do
            if folder:IsA("Folder") then
                gymPartModel = folder:FindFirstChild(gymPartId)
                if gymPartModel then
                    break
                end
            end
        end
    end
    
    -- If still not found, report failure
    if not gymPartModel then
        warn("TycoonHelper: Could not find gym part with ID: " .. gymPartId)
        return false
    end
    
    -- Clone and position the model
    local model = gymPartModel:Clone()
    model.Name = gymPartId
    
    -- Position at the tile
    if model:IsA("Model") and model.PrimaryPart then
        model:SetPrimaryPartCFrame(tile.CFrame)
    else
        -- If no primary part, position the model directly
        model.CFrame = tile.CFrame
    end
    
    model.Parent = tile
    
    -- Fire event
    if EventBridge.fireEvent then
        EventBridge.fireEvent("TycoonHelper_GymPartSpawned", {
            player = player,
            tile = tile,
            gymPartId = gymPartId,
            model = model
        })
    end
    
    return true
end

-- Get a player's tycoon
function TycoonHelper.getTycoon(player)
    if not player or not player:IsA("Player") then
        warn("TycoonHelper: Invalid player")
        return nil
    end
    
    local tycoon = player:FindFirstChild("Tycoon")
    return tycoon
end

-- Get a tile from a player's tycoon
function TycoonHelper.getTile(player, tileId)
    if not player or not tileId then
        warn("TycoonHelper: Invalid parameters for getTile")
        return nil
    end
    
    local tycoon = TycoonHelper.getTycoon(player)
    if not tycoon then
        return nil
    end
    
    return tycoon:FindFirstChild(tileId)
end

-- Check if a tile is purchased
function TycoonHelper.isTilePurchased(player, tileId)
    if not player or not tileId then
        warn("TycoonHelper: Invalid parameters for isTilePurchased")
        return false
    end
    
    local tycoon = TycoonHelper.getTycoon(player)
    if not tycoon then
        return false
    end
    
    local purchasesFolder = tycoon:FindFirstChild("Purchases")
    if not purchasesFolder then
        return false
    end
    
    local purchaseValue = purchasesFolder:FindFirstChild(tileId)
    return purchaseValue and purchaseValue.Value == true
end

-- Create a tile in the player's tycoon
function TycoonHelper.createTile(player, tileId, properties)
    if not isServer then
        warn("TycoonHelper: Cannot create tile on client")
        return false
    end
    
    if not player or not tileId then
        warn("TycoonHelper: Invalid parameters for createTile")
        return false
    end
    
    properties = properties or {}
    
    -- Get the player's tycoon
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon then
        warn("TycoonHelper: Player " .. player.Name .. " does not have a tycoon")
        return false
    end
    
    -- Check if tile already exists
    if tycoon:FindFirstChild(tileId) then
        warn("TycoonHelper: Tile " .. tileId .. " already exists for " .. player.Name)
        return false
    end
    
    -- Create the tile
    local tile = Instance.new("Part")
    tile.Name = tileId
    tile.Anchored = true
    tile.CanCollide = true
    tile.Size = properties.Size or Vector3.new(10, 1, 10)
    tile.Position = properties.Position or Vector3.new(0, 0, 0)
    tile.BrickColor = properties.BrickColor or BrickColor.new("Medium stone grey")
    tile.Material = properties.Material or Enum.Material.Concrete
    
    -- Apply additional properties
    for property, value in pairs(properties) do
        -- Skip properties we've already handled
        if property == "Size" or property == "Position" or property == "BrickColor" or property == "Material" then
            continue
        end
        
        -- Skip invalid properties
        if property == "Parent" or property == "Name" then
            continue
        end
        
        -- Try to set the property
        local success, err = pcall(function()
            tile[property] = value
        end)
        
        if not success then
            warn("TycoonHelper: Failed to set property " .. property .. " on tile " .. tileId .. " - " .. err)
        end
    end
    
    -- Parent the tile
    tile.Parent = tycoon
    
    -- Fire event
    if EventBridge.fireEvent then
        EventBridge.fireEvent("TycoonHelper_TileCreated", {
            player = player,
            tileId = tileId,
            tile = tile
        })
    end
    
    return true, tile
end

-- Restore a tile from data
function TycoonHelper.restoreTile(player, tileId, tileData)
    if not isServer then
        warn("TycoonHelper: Cannot restore tile on client")
        return false
    end
    
    if not player or not tileId or not tileData then
        warn("TycoonHelper: Invalid parameters for restoreTile")
        return false
    end
    
    -- Get the player's tycoon
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon then
        warn("TycoonHelper: Player " .. player.Name .. " does not have a tycoon")
        return false
    end
    
    -- Get or create the tile
    local tile
    
    if tycoon:FindFirstChild(tileId) then
        -- Tile exists, update it
        tile = tycoon:FindFirstChild(tileId)
        
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
                warn("TycoonHelper: Failed to set property " .. property .. " on tile " .. tileId .. " - " .. err)
            end
        end
    else
        -- Create the tile
        local success, newTile = TycoonHelper.createTile(player, tileId, tileData.properties)
        
        if not success then
            warn("TycoonHelper: Failed to create tile " .. tileId .. " for " .. player.Name)
            
            if EventBridge.fireEvent then
                EventBridge.fireEvent("TycoonHelper_TileCreationFailed", {
                    player = player,
                    tileId = tileId,
                    reason = "Creation failed"
                })
            end
            
            return false
        end
        
        tile = newTile
    end
    
    -- Restore purchase status if applicable
    if tileData.purchased then
        local purchasesFolder = tycoon:FindFirstChild("Purchases")
        if not purchasesFolder then
            purchasesFolder = Instance.new("Folder")
            purchasesFolder.Name = "Purchases"
            purchasesFolder.Parent = tycoon
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
        local success = TycoonHelper.spawnGymPart(player, tile, tileData.gymPartId)
        
        if not success then
            warn("TycoonHelper: Failed to spawn gym part for tile " .. tileId)
            
            -- Try fallback system
            if DataManager and DataManager.useFallbackGymPart then
                success = DataManager.useFallbackGymPart(player, tile, tileData.gymPartId)
                
                if not success then
                    warn("TycoonHelper: Fallback gym part spawn failed for tile " .. tileId)
                end
            end
        end
    end
    
    -- Fire event
    if EventBridge.fireEvent then
        EventBridge.fireEvent("TycoonHelper_TileRestored", {
            player = player,
            tileId = tileId,
            tile = tile
        })
    end
    
    return true
end

-- Initialize the module
TycoonHelper.initialize()

-- Register with registry system if available
if isServer then
    local CoreRegistry = safeRequire(findModule("CoreRegistry"))
    if CoreRegistry and CoreRegistry.registerSystem then
        CoreRegistry.registerSystem("TycoonHelper", TycoonHelper)
        print("TycoonHelper: Registered with CoreRegistry")
    end
end

return TycoonHelper
