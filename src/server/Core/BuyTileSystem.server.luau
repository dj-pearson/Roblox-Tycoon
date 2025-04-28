--[[
    BuyTileSystem.server.luau
    
    This module manages the purchasing and placement of gym tiles in the tycoon.
    It handles tile cost, prerequisites, and spawning the associated gym parts.
    
    Created to fix the "BuyTile System Errors" reported in RobloxIssues.txt
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Find a module
local function findModule(moduleName)
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Server"),
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

-- Safely require a module
local function safeRequire(moduleInstance, fallback)
    if not moduleInstance then
        return fallback
    end
    
    local success, result = pcall(function()
        return require(moduleInstance)
    end)
    
    if success then
        return result
    else
        warn("BuyTileSystem: Failed to require " .. moduleInstance:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
end

-- Try to load dependencies
local CoreRegistryModule = findModule("CoreRegistry")
local CoreRegistry = safeRequire(CoreRegistryModule)

local EventBridgeModule = findModule("EventBridge")
local EventBridge = safeRequire(EventBridgeModule, { fireEvent = function() end, registerEvent = function() end })

local DataManagerModule = findModule("DataManager")
local DataManager = safeRequire(DataManagerModule)

local ModuleLoaderModule = findModule("ModuleLoader")
local ModuleLoader = safeRequire(ModuleLoaderModule)

-- Notify of dependency status
if not CoreRegistry then
    print("[BuyTileSystem] NOTICE: CoreRegistry not found, using standalone mode")
end

if not EventBridge then
    print("[BuyTileSystem] NOTICE: EventBridge not found, events will not be fired")
else
    -- Register events
    EventBridge.registerEvent("BuyTile_TilePurchased")
    EventBridge.registerEvent("BuyTile_GymPartSpawned")
    EventBridge.registerEvent("BuyTile_PurchaseError")
end

-- Create the module
local BuyTileSystem = {}

-- Version information
BuyTileSystem.VERSION = "1.0.0"
BuyTileSystem.isLoaded = true

-- Internal data
local tileData = {}
local playerPurchases = {}
local gymPartCache = {}

-- Default tile configuration
local DEFAULT_TILE_CONFIG = {
    cost = 1000,
    requiredLevel = 1,
    gymPartId = "DefaultGymPart",
    category = "Basic",
    description = "A basic gym tile",
    unlockMessage = "You've unlocked a new tile!",
    order = 1,
    isRequired = false,
    floor = 1,
    prerequisites = {} -- Array of tile IDs that must be purchased first
}

-- Set the gym part data
function BuyTileSystem.setTileData(data)
    if type(data) ~= "table" then
        warn("BuyTileSystem: Invalid tile data provided")
        return false
    end
    
    tileData = data
    return true
end

-- Get tile data for a specific ID
function BuyTileSystem.getTileData(tileId)
    if not tileId then
        return nil
    end
    
    return tileData[tileId]
end

-- Get all tile data
function BuyTileSystem.getAllTileData()
    return table.clone(tileData)
end

-- Check if a player has purchased a tile
function BuyTileSystem.hasPlayerPurchasedTile(player, tileId)
    if not player or not tileId then
        return false
    end
    
    local userId = typeof(player) == "number" and player or player.UserId
    
    if not playerPurchases[userId] then
        -- Try to load from player's Tycoon folder
        if typeof(player) == "Instance" then
            local tycoonFolder = player:FindFirstChild("Tycoon")
            if tycoonFolder then
                local purchasesFolder = tycoonFolder:FindFirstChild("Purchases")
                if purchasesFolder then
                    local purchaseValue = purchasesFolder:FindFirstChild(tileId)
                    return purchaseValue and purchaseValue.Value
                end
            end
        end
        
        return false
    end
    
    return playerPurchases[userId][tileId] == true
end

-- Check if a player can purchase a tile
function BuyTileSystem.canPlayerPurchaseTile(player, tileId)
    if not player or not tileId then
        return false, "Invalid player or tile ID"
    end
    
    -- Check if tile exists
    local tile = tileData[tileId]
    if not tile then
        warn("[BuyTile] Tile ID " .. tileId .. " not found in tile data")
        return false, "Tile not found"
    end
    
    -- Check if already purchased
    if BuyTileSystem.hasPlayerPurchasedTile(player, tileId) then
        return false, "Already purchased"
    end
    
    -- Check prerequisites
    if tile.prerequisites then
        for _, prereq in ipairs(tile.prerequisites) do
            if not BuyTileSystem.hasPlayerPurchasedTile(player, prereq) then
                return false, "Missing prerequisite: " .. prereq
            end
        end
    end
    
    -- Check player level if using level system
    if tile.requiredLevel and tile.requiredLevel > 1 then
        -- Try to get player level from stats or data manager
        local playerLevel = 1
        
        -- First check tycoon folder
        local tycoonFolder = player:FindFirstChild("Tycoon")
        if tycoonFolder then
            local statsFolder = tycoonFolder:FindFirstChild("Stats")
            if statsFolder then
                local levelValue = statsFolder:FindFirstChild("Level")
                if levelValue then
                    playerLevel = levelValue.Value
                end
            end
        end
        
        -- Try data manager if available
        if DataManager and typeof(DataManager.getPlayerData) == "function" then
            local playerData = DataManager.getPlayerData(player)
            if playerData and playerData.level then
                playerLevel = playerData.level
            end
        end
        
        if playerLevel < tile.requiredLevel then
            return false, "Required level: " .. tile.requiredLevel
        end
    end
    
    -- Check if player has enough money
    local playerMoney = 0
    
    -- First check tycoon folder
    local tycoonFolder = player:FindFirstChild("Tycoon")
    if tycoonFolder then
        local statsFolder = tycoonFolder:FindFirstChild("Stats")
        if statsFolder then
            local coinsValue = statsFolder:FindFirstChild("Coins")
            if coinsValue then
                playerMoney = coinsValue.Value
            end
        end
    end
    
    -- Try data manager if available
    if DataManager and typeof(DataManager.getPlayerData) == "function" then
        local playerData = DataManager.getPlayerData(player)
        if playerData and playerData.coins then
            playerMoney = playerData.coins
        end
    end
    
    if playerMoney < tile.cost then
        return false, "Not enough money. Cost: " .. tile.cost
    end
    
    return true, "Can purchase"
end

-- Purchase a tile for a player
function BuyTileSystem.purchaseTile(player, tileId)
    if not player or not tileId then
        warn("[BuyTile] Invalid player or tile ID")
        return false, "Invalid player or tile ID"
    end
    
    local userId = player.UserId
    
    -- Check if player can purchase
    local canPurchase, reason = BuyTileSystem.canPlayerPurchaseTile(player, tileId)
    if not canPurchase then
        if EventBridge.fireEvent then
            EventBridge.fireEvent("BuyTile_PurchaseError", {
                player = player,
                tileId = tileId,
                reason = reason
            })
        end
        
        return false, reason
    end
    
    -- Get tile data
    local tile = tileData[tileId]
    if not tile then
        warn("[BuyTile] Could not find tile data for ID: " .. tileId)
        return false, "Tile not found"
    end
    
    -- Deduct money
    local success = false
    local playerData = nil
    
    -- Try data manager first
    if DataManager and typeof(DataManager.getPlayerData) == "function" and typeof(DataManager.updatePlayerData) == "function" then
        playerData = DataManager.getPlayerData(player)
        if playerData then
            playerData.coins = playerData.coins - tile.cost
            success = DataManager.updatePlayerData(player, playerData)
        end
    end
    
    -- Fallback to direct manipulation
    if not success then
        local tycoonFolder = player:FindFirstChild("Tycoon")
        if tycoonFolder then
            local statsFolder = tycoonFolder:FindFirstChild("Stats")
            if statsFolder then
                local coinsValue = statsFolder:FindFirstChild("Coins")
                if coinsValue then
                    coinsValue.Value = coinsValue.Value - tile.cost
                    success = true
                end
            end
        end
    end
    
    if not success then
        warn("[BuyTile] Failed to deduct money for " .. player.Name)
        return false, "Failed to deduct money"
    end
    
    -- Mark as purchased
    if not playerPurchases[userId] then
        playerPurchases[userId] = {}
    end
    
    playerPurchases[userId][tileId] = true
    
    -- Create purchase value in player's tycoon
    local tycoonFolder = player:FindFirstChild("Tycoon")
    if tycoonFolder then
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
            purchaseValue.Parent = purchasesFolder
        end
        
        purchaseValue.Value = true
    end
    
    -- Track purchase in player data if available
    if playerData and typeof(DataManager.updatePlayerData) == "function" then
        if not playerData.tiles then
            playerData.tiles = {}
        end
        
        playerData.tiles[tileId] = {
            purchased = true,
            purchaseDate = os.time(),
            gymPartId = tile.gymPartId
        }
        
        DataManager.updatePlayerData(player, playerData)
    end
    
    -- Fire purchase event
    if EventBridge.fireEvent then
        EventBridge.fireEvent("BuyTile_TilePurchased", {
            player = player,
            tileId = tileId,
            cost = tile.cost,
            gymPartId = tile.gymPartId
        })
    end
    
    -- Spawn the gym part if specified
    if tile.gymPartId then
        local success, result = pcall(function()
            return BuyTileSystem.spawnGymPart(player, tileId, tile.gymPartId)
        end)
        
        if not success then
            warn("[BuyTile] Failed to spawn gym part for " .. tileId .. ": " .. tostring(result))
        end
    else
        warn("[BuyTile] No gym part ID specified for tile " .. tileId)
    end
    
    return true, "Purchase successful"
end

-- Spawn a gym part for a tile
function BuyTileSystem.spawnGymPart(player, tileId, gymPartId)
    if not player or not tileId then
        warn("[BuyTile] Invalid parameters for spawnGymPart")
        return false
    end
    
    gymPartId = gymPartId or (tileData[tileId] and tileData[tileId].gymPartId)
    
    if not gymPartId then
        warn("[BuyTile] No gym part ID specified for tile " .. tileId)
        return false
    end
    
    -- Find the tile in the player's tycoon
    local tycoonFolder = player:FindFirstChild("Tycoon")
    if not tycoonFolder then
        warn("[BuyTile] Tycoon folder not found for " .. player.Name)
        return false
    end
    
    -- Find or create the tile object
    local tileObj = tycoonFolder:FindFirstChild(tileId)
    if not tileObj then
        -- Try to create a default tile at a fallback position
        tileObj = Instance.new("Part")
        tileObj.Name = tileId
        tileObj.Anchored = true
        tileObj.Size = Vector3.new(4, 1, 4)
        tileObj.Position = tycoonFolder:GetPivot().Position + Vector3.new(0, 2, 0)
        tileObj.Parent = tycoonFolder
        
        warn("[BuyTile] Created default tile for " .. tileId .. " as it didn't exist")
    end
    
    -- Look for the gym part in the cache first
    if gymPartCache[gymPartId] then
        local model = gymPartCache[gymPartId]:Clone()
        model.Name = gymPartId
        
        -- Position the model at the tile
        if model:IsA("Model") and model.PrimaryPart then
            model:SetPrimaryPartCFrame(tileObj.CFrame)
        else
            model.CFrame = tileObj.CFrame + Vector3.new(0, model:IsA("Part") and model.Size.Y/2 or 2, 0)
        end
        
        model.Parent = tileObj
        
        -- Fire event
        if EventBridge.fireEvent then
            EventBridge.fireEvent("BuyTile_GymPartSpawned", {
                player = player,
                tileId = tileId,
                gymPartId = gymPartId,
                fromCache = true
            })
        end
        
        return true
    end
    
    -- Look for gym part in ServerStorage
    local gymPartsFolder = ServerStorage:FindFirstChild("GymParts")
    if not gymPartsFolder then
        gymPartsFolder = Instance.new("Folder")
        gymPartsFolder.Name = "GymParts"
        gymPartsFolder.Parent = ServerStorage
        
        warn("[BuyTile] Created GymParts folder as it didn't exist")
    end
    
    -- Find gym part model
    local gymPartModel
    
    -- Direct lookup
    gymPartModel = gymPartsFolder:FindFirstChild(gymPartId)
    
    -- Try numeric conversion
    if not gymPartModel and tonumber(gymPartId) then
        gymPartModel = gymPartsFolder:FindFirstChild(tostring(tonumber(gymPartId)))
    end
    
    -- Search by category
    if not gymPartModel then
        local categories = {"Weights", "Cardio", "Machines", "Furniture", "Basic", "Amenities"}
        for _, category in ipairs(categories) do
            local folder = gymPartsFolder:FindFirstChild(category)
            if folder then
                gymPartModel = folder:FindFirstChild(gymPartId)
                if gymPartModel then break end
                
                -- Try numeric conversion
                if tonumber(gymPartId) then
                    gymPartModel = folder:FindFirstChild(tostring(tonumber(gymPartId)))
                    if gymPartModel then break end
                end
            end
        end
    end
    
    -- Recursive search if needed
    if not gymPartModel then
        for _, obj in ipairs(gymPartsFolder:GetDescendants()) do
            if obj.Name == gymPartId or (tonumber(gymPartId) and obj.Name == tostring(tonumber(gymPartId))) then
                gymPartModel = obj
                break
            end
        end
    end
    
    -- If still not found, create a default part
    if not gymPartModel then
        warn("[BuyTile] Could not find gym part with ID: " .. gymPartId)
        
        -- Create default part
        gymPartModel = Instance.new("Part")
        gymPartModel.Name = "Default_" .. gymPartId
        gymPartModel.Size = Vector3.new(2, 1, 2)
        gymPartModel.BrickColor = BrickColor.new("Bright blue")
        gymPartModel.Anchored = true
        
        -- Add a SurfaceGui with a label
        local surfaceGui = Instance.new("SurfaceGui")
        surfaceGui.Parent = gymPartModel
        surfaceGui.Face = Enum.NormalId.Top
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Parent = surfaceGui
        textLabel.BackgroundTransparency = 0.5
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.Text = "Gym Part " .. gymPartId
        textLabel.TextScaled = true
    end
    
    -- Cache the gym part for future use
    gymPartCache[gymPartId] = gymPartModel
    
    -- Clone and position the model
    local model = gymPartModel:Clone()
    model.Name = gymPartId
    
    -- Position the model at the tile
    if model:IsA("Model") and model.PrimaryPart then
        model:SetPrimaryPartCFrame(tileObj.CFrame)
    else
        model.CFrame = tileObj.CFrame + Vector3.new(0, model:IsA("Part") and model.Size.Y/2 or 2, 0)
    end
    
    model.Parent = tileObj
    
    -- Fire event
    if EventBridge.fireEvent then
        EventBridge.fireEvent("BuyTile_GymPartSpawned", {
            player = player,
            tileId = tileId,
            gymPartId = gymPartId,
            fromCache = false
        })
    end
    
    return true
end

-- Initialize a new player
function BuyTileSystem.initializePlayer(player)
    local userId = player.UserId
    playerPurchases[userId] = {}
    
    -- Load existing purchases from player's tycoon
    local tycoonFolder = player:FindFirstChild("Tycoon")
    if tycoonFolder then
        local purchasesFolder = tycoonFolder:FindFirstChild("Purchases")
        if purchasesFolder then
            for _, value in ipairs(purchasesFolder:GetChildren()) do
                if value:IsA("BoolValue") and value.Value then
                    playerPurchases[userId][value.Name] = true
                end
            end
        end
    end
    
    -- Try data manager if available
    if DataManager and typeof(DataManager.getPlayerData) == "function" then
        local playerData = DataManager.getPlayerData(player)
        if playerData and playerData.tiles then
            for tileId, tileInfo in pairs(playerData.tiles) do
                if tileInfo.purchased then
                    playerPurchases[userId][tileId] = true
                    
                    -- Spawn the gym part if needed
                    if tileInfo.gymPartId then
                        task.spawn(function()
                            BuyTileSystem.spawnGymPart(player, tileId, tileInfo.gymPartId)
                        end)
                    end
                end
            end
        end
    end
    
    return true
end

-- Clean up when player leaves
function BuyTileSystem.cleanupPlayer(player)
    local userId = player.UserId
    playerPurchases[userId] = nil
    return true
end

-- Get floor name based on floor number
function BuyTileSystem.getFloorName(floorNumber)
    local suffixes = {"st", "nd", "rd"}
    local suffix = (floorNumber >= 1 and floorNumber <= 3) and suffixes[floorNumber] or "th"
    return tostring(floorNumber) .. suffix
end

-- Check if a player has unlocked a floor by name
function BuyTileSystem.hasUnlockedFloorByName(player, floorName)
    -- Implementation depends on how floors are tracked
    -- This is a placeholder implementation
    return true
end

-- Get all available floors
function BuyTileSystem.getAllFloors()
    -- Collect unique floors from tile data
    local floors = {}
    local floorSet = {}
    
    for _, tile in pairs(tileData) do
        if tile.floor and not floorSet[tile.floor] then
            floorSet[tile.floor] = true
            table.insert(floors, {
                number = tile.floor,
                name = BuyTileSystem.getFloorName(tile.floor)
            })
        end
    end
    
    -- Sort by floor number
    table.sort(floors, function(a, b)
        return a.number < b.number
    end)
    
    return floors
end

-- Set up player connections
Players.PlayerAdded:Connect(function(player)
    BuyTileSystem.initializePlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    BuyTileSystem.cleanupPlayer(player)
end)

-- Initialize existing players
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        BuyTileSystem.initializePlayer(player)
    end)
end

-- Set up sample tile data if none provided
if not next(tileData) then
    tileData = {
        ["BuyTile1"] = {
            cost = 500,
            requiredLevel = 1,
            gymPartId = "1",
            category = "Basic",
            description = "Your first gym equipment",
            unlockMessage = "You've started your gym journey!",
            order = 1,
            isRequired = true,
            floor = 1,
            prerequisites = {}
        },
        ["BuyTile2"] = {
            cost = 1000,
            requiredLevel = 1,
            gymPartId = "2",
            category = "Basic",
            description = "Expand your gym",
            unlockMessage = "Your gym is growing!",
            order = 2,
            isRequired = false,
            floor = 1,
            prerequisites = {"BuyTile1"}
        }
    }
    
    print("[BuyTile] Set up default tile data with 2 tiles")
end

-- Register with CoreRegistry if available
if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
    CoreRegistry.registerSystem("BuyTileSystem", BuyTileSystem)
    print("[BuyTile] Registered with CoreRegistry")
end

print("✅ BuyTileSystem initialized successfully")
return BuyTileSystem
