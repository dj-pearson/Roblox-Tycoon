--[[
    BuyTileSystem.luau
    
    Core system for managing buyable tiles in the tycoon.
    This module handles tile purchasing, unlocking, and progression.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BuyTileSystem = {}
BuyTileSystem.initialized = false

-- Configuration
local CONFIG = {
    SAVE_KEY = "ownedTiles",
    DEFAULT_COST_MULTIPLIER = 1.0,
    PROGRESSION_MULTIPLIER = 1.2,
    COST_ROUND_TO = 10, -- Round costs to nearest multiple of this value
    MAX_TILES_PER_TYCOON = 100
}

-- Debug settings
BuyTileSystem.DEBUG = true

-- Internal state
local tiles = {}
local playerTiles = {}

-- Log a message to the output
local function log(message)
    if BuyTileSystem.DEBUG then
        print("[BuyTileSystem] " .. message)
    end
end

-- Get the CoreRegistry if available
local function getCoreRegistry()
    -- Try to use SafeRequire first
    local safeRequirePaths = {
        ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("SafeRequire"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared") and ReplicatedStorage.src.shared:FindFirstChild("SafeRequire"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("shared") and ServerScriptService.src.shared:FindFirstChild("SafeRequire")
    }
    
    for _, path in ipairs(safeRequirePaths) do
        if path then
            local success, safeRequire = pcall(function()
                return require(path)
            end)
            
            if success and safeRequire and typeof(safeRequire.requireFromPath) == "function" then
                local CoreRegistry = safeRequire.requireFromPath("CoreRegistry")
                if CoreRegistry then
                    log("Found CoreRegistry via SafeRequire")
                    return CoreRegistry
                end
            end
        end
    end
    
    -- Try standard paths
    local standardPaths = {
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("server") and ServerScriptService.server:FindFirstChild("Core") and ServerScriptService.server.Core:FindFirstChild("CoreRegistry")
    }
    
    -- Try to find via ModuleLoader if available
    local success, ModuleLoader = pcall(function()
        return require(ReplicatedStorage:FindFirstChild("shared", true) and ReplicatedStorage:FindFirstChild("shared", true):FindFirstChild("ModuleLoader"))
    end)
    
    if success and ModuleLoader then
        local CoreRegistry = ModuleLoader.require("CoreRegistry")
        if CoreRegistry then
            log("Found CoreRegistry via ModuleLoader")
            return CoreRegistry
        end
    end
    
    for _, path in ipairs(standardPaths) do
        if path and path:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(path)
            end)
            
            if success and result then
                return result
            end
        end
    end
    
    return nil
end

-- Get the DataManager if available
local function getDataManager()
    local CoreRegistry = getCoreRegistry()
    if CoreRegistry and typeof(CoreRegistry.getSystem) == "function" then
        return CoreRegistry.getSystem("DataManager")
    end
    
    -- Try direct paths
    local standardPaths = {
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("DataManager"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("DataManager")
    }
    
    for _, path in ipairs(standardPaths) do
        if path and path:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(path)
            end)
            
            if success and result then
                return result
            end
        end
    end
    
    return nil
end

-- Initialize the BuyTileSystem
function BuyTileSystem.initialize()
    if BuyTileSystem.initialized then
        return true
    end
    
    log("Initializing BuyTileSystem...")
      -- Register with CoreRegistry if available
    local CoreRegistry = getCoreRegistry()
    if CoreRegistry then
        if typeof(CoreRegistry.Register) == "function" then
            CoreRegistry:Register("BuyTileSystem", BuyTileSystem)
            log("Registered with CoreRegistry using Register function")
        elseif typeof(CoreRegistry.registerSystem) == "function" then
            CoreRegistry.registerSystem("BuyTileSystem", BuyTileSystem)
            log("Registered with CoreRegistry using registerSystem function")
        else
            log("CoreRegistry found but no registration function available")
        end
    else
        log("CoreRegistry not found, but BuyTileSystem will still function")
    end
    
    -- Initialize player tracking
    for _, player in ipairs(Players:GetPlayers()) do
        BuyTileSystem.initializePlayer(player)
    end
    
    -- Set up player added/removed events
    Players.PlayerAdded:Connect(function(player)
        BuyTileSystem.initializePlayer(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        BuyTileSystem.cleanupPlayer(player)
    end)
    
    -- Set up remotes for client communication
    local remotes = ReplicatedStorage:FindFirstChild("BuyTileRemotes")
    if not remotes then
        remotes = Instance.new("Folder")
        remotes.Name = "BuyTileRemotes"
        remotes.Parent = ReplicatedStorage
        
        -- Create remote for buying tiles
        local buyTileRemote = Instance.new("RemoteFunction")
        buyTileRemote.Name = "BuyTile"
        buyTileRemote.Parent = remotes
        
        -- Create remote for checking if a tile is owned
        local isTileOwnedRemote = Instance.new("RemoteFunction")
        isTileOwnedRemote.Name = "IsTileOwned"
        isTileOwnedRemote.Parent = remotes
        
        -- Create remote for getting owned tiles
        local getOwnedTilesRemote = Instance.new("RemoteFunction")
        getOwnedTilesRemote.Name = "GetOwnedTiles"
        getOwnedTilesRemote.Parent = remotes
        
        -- Handle remote calls
        buyTileRemote.OnServerInvoke = function(player, tileId)
            return BuyTileSystem.buyTile(player, tileId)
        end
        
        isTileOwnedRemote.OnServerInvoke = function(player, tileId)
            return BuyTileSystem.isTileOwned(player, tileId)
        end
        
        getOwnedTilesRemote.OnServerInvoke = function(player)
            return BuyTileSystem.getOwnedTiles(player)
        end
    end
    
    BuyTileSystem.initialized = true
    log("BuyTileSystem initialized")
    
    return true
end

-- Initialize a player in the system
function BuyTileSystem.initializePlayer(player)
    if not player or not player.UserId then
        return
    end
    
    local userId = player.UserId
    
    if playerTiles[userId] then
        return -- Already initialized
    end
    
    log("Initializing player: " .. player.Name)
    
    -- Try to load owned tiles from data store
    local DataManager = getDataManager()
    if DataManager then
        local playerData = DataManager.getPlayerData(player)
        
        if playerData and playerData[CONFIG.SAVE_KEY] then
            playerTiles[userId] = playerData[CONFIG.SAVE_KEY]
            log("Loaded " .. #playerTiles[userId] .. " owned tiles for " .. player.Name)
        else
            playerTiles[userId] = {}
            log("No saved tiles found for " .. player.Name .. ", starting fresh")
        end
    else
        -- Fallback if DataManager not available
        playerTiles[userId] = {}
    end
    
    -- Apply any tile effects for already owned tiles
    for _, tileId in ipairs(playerTiles[userId]) do
        local tile = BuyTileSystem.getTile(tileId)
        if tile and tile.onOwned then
            tile.onOwned(player)
        end
    end
end

-- Clean up player data
function BuyTileSystem.cleanupPlayer(player)
    if not player or not player.UserId then
        return
    end
    
    local userId = player.UserId
    
    -- Save owned tiles
    local DataManager = getDataManager()
    if DataManager and playerTiles[userId] then
        local success = DataManager.updateValue(player, CONFIG.SAVE_KEY, playerTiles[userId])
        if success then
            log("Saved " .. #playerTiles[userId] .. " owned tiles for " .. player.Name)
        else
            warn("[BuyTileSystem] Failed to save owned tiles for " .. player.Name)
        end
    end
    
    -- Clean up
    playerTiles[userId] = nil
end

-- Register a new buyable tile
function BuyTileSystem.registerTile(tileInfo)
    if not tileInfo or type(tileInfo) ~= "table" then
        warn("[BuyTileSystem] Invalid tile info provided")
        return false
    end
    
    -- Required properties
    if not tileInfo.id then
        warn("[BuyTileSystem] Tile missing required id property")
        return false
    end
    
    -- Set default values
    tileInfo.cost = tileInfo.cost or 100
    tileInfo.requiredLevel = tileInfo.requiredLevel or 1
    tileInfo.name = tileInfo.name or "Unnamed Tile"
    
    -- Store tile
    tiles[tileInfo.id] = tileInfo
    log("Registered tile: " .. tileInfo.name .. " (ID: " .. tileInfo.id .. ")")
    
    return true
end

-- Register multiple tiles at once
function BuyTileSystem.registerTiles(tilesInfo)
    if not tilesInfo or type(tilesInfo) ~= "table" then
        warn("[BuyTileSystem] Invalid tiles table provided")
        return 0
    end
    
    local count = 0
    for _, tileInfo in ipairs(tilesInfo) do
        if BuyTileSystem.registerTile(tileInfo) then
            count = count + 1
        end
    end
    
    log("Registered " .. count .. " tiles")
    return count
end

-- Get a tile's info
function BuyTileSystem.getTile(tileId)
    return tiles[tileId]
end

-- Buy a tile for a player
function BuyTileSystem.buyTile(player, tileId)
    if not player or not player.UserId or not tileId then
        return false, "Invalid parameters"
    end
    
    local userId = player.UserId
    
    -- Initialize player if needed
    if not playerTiles[userId] then
        BuyTileSystem.initializePlayer(player)
    end
    
    -- Check if tile exists
    local tile = tiles[tileId]
    if not tile then
        return false, "Tile does not exist"
    end
    
    -- Check if already owned
    if BuyTileSystem.isTileOwned(player, tileId) then
        return false, "Tile already owned"
    end
    
    -- Check prerequisites
    if tile.requiredTiles then
        for _, requiredTileId in ipairs(tile.requiredTiles) do
            if not BuyTileSystem.isTileOwned(player, requiredTileId) then
                return false, "Missing required tile: " .. (tiles[requiredTileId] and tiles[requiredTileId].name or requiredTileId)
            end
        end
    end
    
    -- Check level requirement
    if tile.requiredLevel and tile.requiredLevel > 1 then
        local DataManager = getDataManager()
        local playerData = DataManager and DataManager.getPlayerData(player)
        local playerLevel = playerData and playerData.level or 1
        
        if playerLevel < tile.requiredLevel then
            return false, "Required level: " .. tile.requiredLevel
        end
    end
    
    -- Perform transaction
    local tileCost = tile.cost
    
    -- Get player money
    local DataManager = getDataManager()
    if not DataManager then
        return false, "Data system unavailable"
    end
    
    local playerData = DataManager.getPlayerData(player)
    if not playerData then
        return false, "Player data unavailable"
    end
    
    local playerCash = playerData.cash or 0
    
    -- Check if player has enough money
    if playerCash < tileCost then
        return false, "Not enough money"
    end
    
    -- Deduct cost
    DataManager.updateValue(player, "cash", playerCash - tileCost)
    
    -- Add to owned tiles
    table.insert(playerTiles[userId], tileId)
    
    -- Save
    DataManager.updateValue(player, CONFIG.SAVE_KEY, playerTiles[userId])
    
    -- Fire tile owned callback
    if tile.onOwned then
        tile.onOwned(player)
    end
    
    log(player.Name .. " purchased tile: " .. tile.name)
    
    return true, "Purchase successful"
end

-- Check if a player owns a tile
function BuyTileSystem.isTileOwned(player, tileId)
    if not player or not player.UserId or not tileId then
        return false
    end
    
    local userId = player.UserId
    
    -- Initialize player if needed
    if not playerTiles[userId] then
        BuyTileSystem.initializePlayer(player)
    end
    
    -- Check if tile is in owned list
    return table.find(playerTiles[userId], tileId) ~= nil
end

-- Get all tiles owned by a player
function BuyTileSystem.getOwnedTiles(player)
    if not player or not player.UserId then
        return {}
    end
    
    local userId = player.UserId
    
    -- Initialize player if needed
    if not playerTiles[userId] then
        BuyTileSystem.initializePlayer(player)
    end
    
    return playerTiles[userId]
end

-- Get all available tiles for a player
function BuyTileSystem.getAvailableTiles(player)
    if not player or not player.UserId then
        return {}
    end
    
    local availableTiles = {}
    
    -- Check each registered tile
    for tileId, tile in pairs(tiles) do
        if not BuyTileSystem.isTileOwned(player, tileId) then
            -- Check prerequisites
            local meetsPrerequisites = true
            
            if tile.requiredTiles then
                for _, requiredTileId in ipairs(tile.requiredTiles) do
                    if not BuyTileSystem.isTileOwned(player, requiredTileId) then
                        meetsPrerequisites = false
                        break
                    end
                end
            end
            
            -- Check level requirement
            if meetsPrerequisites and tile.requiredLevel and tile.requiredLevel > 1 then
                local DataManager = getDataManager()
                local playerData = DataManager and DataManager.getPlayerData(player)
                local playerLevel = playerData and playerData.level or 1
                
                if playerLevel < tile.requiredLevel then
                    meetsPrerequisites = false
                end
            end
            
            if meetsPrerequisites then
                table.insert(availableTiles, tileId)
            end
        end
    end
    
    return availableTiles
end

-- Client interface that's safe to expose to clients
function BuyTileSystem:getClientInterface()
    local clientInterface = {
        getTile = self.getTile,
        getOwnedTiles = function(player)
            -- Player parameter is ignored on client, using LocalPlayer
            return self.getOwnedTiles(player)
        end,
        getAvailableTiles = function(player)
            -- Player parameter is ignored on client, using LocalPlayer
            return self.getAvailableTiles(player)
        end,
        isTileOwned = function(player, tileId)
            -- Player parameter is ignored on client, using LocalPlayer
            return self.isTileOwned(player, tileId)
        end
    }
    
    return clientInterface
end

-- Initialize the BuyTileSystem
BuyTileSystem.initialize()

-- Try to register with CoreRegistry
task.spawn(function()
    local CoreRegistry = getCoreRegistry()
    if CoreRegistry then
        if typeof(CoreRegistry.registerSystem) == "function" then
            CoreRegistry.registerSystem("BuyTileSystem", BuyTileSystem)
            log("Successfully registered with CoreRegistry via registerSystem")
        elseif typeof(CoreRegistry.Register) == "function" then
            CoreRegistry:Register("BuyTileSystem", BuyTileSystem)
            log("Successfully registered with CoreRegistry via Register")
        else
            warn("[BuyTileSystem] CoreRegistry found but no registration method available")
        end
    else
        warn("[BuyTileSystem] Could not find CoreRegistry for registration")
    end
end)

return BuyTileSystem
