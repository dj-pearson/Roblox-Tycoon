--!strict
--[[
    BuyTileSystem.server.luau
    
    Core system for managing buyable tiles in the tycoon.
    This module handles tile purchasing, unlocking, and progression.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Unified implementation with DataAccessLayer integration
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Import CoreRegistry and DataAccessLayer
local CoreRegistry = require(script.Parent.CoreRegistry)
local DataAccessLayer = require(script.Parent.DataAccessLayer)

-- Configuration
local CONFIG = {
    debug = true,
    maxRetries = 3,
    retryDelay = 1, -- seconds
    dataKey = "ownedTiles",
    defaultCostMultiplier = 1.0,
    progressionMultiplier = 1.2,
    costRoundTo = 10,
    maxTilesPerTycoon = 100,
    equipmentFolder = "GymEquipment",
    specialEquipmentMultiplier = 2,
    purchaseEffectEnabled = true,
    staggeredPlacement = true,
    placementDelay = 0.1
}

-- BuyTileSystem module
local BuyTileSystem = {
    Version = "2.0.0",
    initialized = false,
    tiles = {},
    playerTiles = {},
    equipmentTemplates = {},
    equipmentPrices = {},
    specialEquipment = {},
    stats = {
        purchases = 0,
        errors = 0,
        cacheHits = 0
    }
}

-- Debug logging
local function log(message, level)
    if CONFIG.debug then
        local prefix = "[BuyTileSystem]"
        if level == "error" then
            warn(prefix .. " ERROR: " .. message)
        elseif level == "warn" then
            warn(prefix .. " WARNING: " .. message)
        else
            print(prefix .. " " .. message)
        end
    end
end

-- Initialize the BuyTileSystem
function BuyTileSystem:Initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing BuyTileSystem v" .. self.Version)
    
    -- Register with CoreRegistry
    if CoreRegistry then
        CoreRegistry.registerSystem("BuyTileSystem", self)
        log("Registered with CoreRegistry")
    end
    
    -- Set up player events
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayer(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayer(player)
    end)
    
    -- Set up game shutdown handler
    game:BindToClose(function()
        self:HandleShutdown()
    end)
    
    self.initialized = true
    log("BuyTileSystem initialized successfully")
    return true
end

-- Initialize a player
function BuyTileSystem:InitializePlayer(player)
    if not player then return false end
    
    local userId = player.UserId
    
    -- Load owned tiles from DataAccessLayer
    local ownedTiles = DataAccessLayer:GetPlayerData(player, CONFIG.dataKey)
    if ownedTiles then
        self.playerTiles[userId] = ownedTiles
        log("Loaded " .. #ownedTiles .. " owned tiles for " .. player.Name)
    else
        self.playerTiles[userId] = {}
        log("No saved tiles found for " .. player.Name .. ", starting fresh")
    end
    
    -- Apply any tile effects for already owned tiles
    for _, tileId in ipairs(self.playerTiles[userId]) do
        local tile = self:GetTile(tileId)
        if tile and tile.onOwned then
            tile.onOwned(player)
        end
    end
    
    return true
end

-- Clean up player data
function BuyTileSystem:CleanupPlayer(player)
    if not player then return false end
    
    local userId = player.UserId
    
    -- Save owned tiles
    if self.playerTiles[userId] then
        local success = DataAccessLayer:UpdatePlayerData(player, CONFIG.dataKey, self.playerTiles[userId])
        if success then
            log("Saved " .. #self.playerTiles[userId] .. " owned tiles for " .. player.Name)
        else
            log("Failed to save owned tiles for " .. player.Name, "error")
        end
    end
    
    -- Clean up
    self.playerTiles[userId] = nil
    return true
end

-- Register a new tile
function BuyTileSystem:RegisterTile(tileInfo)
    if not tileInfo or type(tileInfo) ~= "table" then
        log("Invalid tile info provided", "error")
        return false
    end
    
    -- Required properties
    if not tileInfo.id then
        log("Tile missing required id property", "error")
        return false
    end
    
    -- Set default values
    tileInfo.cost = tileInfo.cost or 100
    tileInfo.requiredLevel = tileInfo.requiredLevel or 1
    tileInfo.name = tileInfo.name or "Unnamed Tile"
    
    -- Store tile
    self.tiles[tileInfo.id] = tileInfo
    log("Registered tile: " .. tileInfo.name .. " (ID: " .. tileInfo.id .. ")")
    
    return true
end

-- Get tile info
function BuyTileSystem:GetTile(tileId)
    return self.tiles[tileId]
end

-- Check if a player owns a tile
function BuyTileSystem:IsTileOwned(player, tileId)
    if not player or not tileId then return false end
    
    local userId = player.UserId
    if not self.playerTiles[userId] then
        self:InitializePlayer(player)
    end
    
    return table.find(self.playerTiles[userId], tileId) ~= nil
end

-- Get all tiles owned by a player
function BuyTileSystem:GetOwnedTiles(player)
    if not player then return {} end
    
    local userId = player.UserId
    if not self.playerTiles[userId] then
        self:InitializePlayer(player)
    end
    
    return table.clone(self.playerTiles[userId])
end

-- Buy a tile for a player
function BuyTileSystem:BuyTile(player, tileId)
    if not player or not tileId then
        return false, "Invalid parameters"
    end
    
    local userId = player.UserId
    
    -- Initialize player if needed
    if not self.playerTiles[userId] then
        self:InitializePlayer(player)
    end
    
    -- Check if tile exists
    local tile = self:GetTile(tileId)
    if not tile then
        return false, "Tile does not exist"
    end
    
    -- Check if already owned
    if self:IsTileOwned(player, tileId) then
        return false, "Tile already owned"
    end
    
    -- Check prerequisites
    if tile.requiredTiles then
        for _, requiredTileId in ipairs(tile.requiredTiles) do
            if not self:IsTileOwned(player, requiredTileId) then
                return false, "Missing required tile: " .. (self.tiles[requiredTileId] and self.tiles[requiredTileId].name or requiredTileId)
            end
        end
    end
    
    -- Check level requirement
    if tile.requiredLevel and tile.requiredLevel > 1 then
        local playerData = DataAccessLayer:GetPlayerData(player)
        local playerLevel = playerData and playerData.level or 1
        
        if playerLevel < tile.requiredLevel then
            return false, "Required level: " .. tile.requiredLevel
        end
    end
    
    -- Get player's cash
    local playerData = DataAccessLayer:GetPlayerData(player)
    local playerCash = playerData and playerData.cash or 0
    
    -- Check if player has enough money
    if playerCash < tile.cost then
        return false, "Not enough money"
    end
    
    -- Deduct cost
    local success = DataAccessLayer:UpdatePlayerData(player, "cash", playerCash - tile.cost)
    if not success then
        return false, "Failed to update player cash"
    end
    
    -- Add to owned tiles
    table.insert(self.playerTiles[userId], tileId)
    
    -- Save owned tiles
    success = DataAccessLayer:UpdatePlayerData(player, CONFIG.dataKey, self.playerTiles[userId])
    if not success then
        -- Refund the cost if saving fails
        DataAccessLayer:UpdatePlayerData(player, "cash", playerCash)
        return false, "Failed to save owned tiles"
    end
    
    -- Fire tile owned callback
    if tile.onOwned then
        tile.onOwned(player)
    end
    
    self.stats.purchases += 1
    log(player.Name .. " purchased tile: " .. tile.name)
    
    return true, "Purchase successful"
end

-- Get all available tiles for a player
function BuyTileSystem:GetAvailableTiles(player)
    if not player then return {} end
    
    local availableTiles = {}
    
    -- Check each registered tile
    for tileId, tile in pairs(self.tiles) do
        if not self:IsTileOwned(player, tileId) then
            -- Check prerequisites
            local meetsPrerequisites = true
            
            if tile.requiredTiles then
                for _, requiredTileId in ipairs(tile.requiredTiles) do
                    if not self:IsTileOwned(player, requiredTileId) then
                        meetsPrerequisites = false
                        break
                    end
                end
            end
            
            -- Check level requirement
            if meetsPrerequisites and tile.requiredLevel and tile.requiredLevel > 1 then
                local playerData = DataAccessLayer:GetPlayerData(player)
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

-- Handle game shutdown
function BuyTileSystem:HandleShutdown()
    log("Handling game shutdown")
    
    -- Save all player data
    for _, player in ipairs(Players:GetPlayers()) do
        self:CleanupPlayer(player)
    end
end

-- Get system health
function BuyTileSystem:IsHealthy()
    return self.initialized
end

-- Recover from failure
function BuyTileSystem:Recover()
    if not self.initialized then
        return self:Initialize()
    end
    return true
end

-- Initialize the BuyTileSystem
BuyTileSystem:Initialize()

return BuyTileSystem
