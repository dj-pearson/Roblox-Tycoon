--!strict
--[[
    BuyTileProgressionManager.server.luau
    
    Manages the progression and unlocking of buyable tiles in the tycoon.
    Integrates with BuyTileSystem to handle tile prerequisites and progression.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Added client notification system and enhanced progression features
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Import dependencies
local CoreRegistry = require(script.Parent.CoreRegistry)
local BuyTileSystem = require(script.Parent.BuyTileSystem)
local DataAccessLayer = require(script.Parent.DataAccessLayer)

-- Configuration
local CONFIG = {
    debug = true,
    maxTilesPerFloor = 20,
    floorProgressionMultiplier = 1.5,
    requiredTilePercentage = 0.3, -- 30% of tiles must be required
    buildOrderIncrement = 10,
    maxFloors = 5,
    notificationDuration = 5, -- seconds
    notificationSound = "rbxassetid://1234567890", -- Replace with actual sound ID
    progressionMilestones = {
        { tiles = 5, reward = 1000 },
        { tiles = 10, reward = 2500 },
        { tiles = 25, reward = 5000 },
        { tiles = 50, reward = 10000 }
    }
}

-- BuyTileProgressionManager module
local BuyTileProgressionManager = {
    Version = "2.0.0",
    initialized = false,
    buildOrder = {},
    floorPrerequisites = {},
    requiredTiles = {},
    stats = {
        tilesProcessed = 0,
        errors = 0,
        warnings = 0
    }
}

-- Debug logging
local function log(message, level)
    if CONFIG.debug then
        local prefix = "[BuyTileProgressionManager]"
        if level == "error" then
            warn(prefix .. " ERROR: " .. message)
        elseif level == "warn" then
            warn(prefix .. " WARNING: " .. message)
        else
            print(prefix .. " " .. message)
        end
    end
end

-- Generate build order for tiles
function BuyTileProgressionManager:GenerateBuildOrder()
    log("Generating build order")
    
    -- Get all registered tiles
    local tiles = {}
    for tileId, tile in pairs(BuyTileSystem.tiles) do
        table.insert(tiles, {
            id = tileId,
            data = tile
        })
    end
    
    -- Sort tiles by floor and build order
    table.sort(tiles, function(a, b)
        if a.data.floor ~= b.data.floor then
            return a.data.floor < b.data.floor
        end
        return a.data.buildOrder < b.data.buildOrder
    end)
    
    -- Create build order
    self.buildOrder = {}
    for i, tile in ipairs(tiles) do
        self.buildOrder[i] = tile.id
    end
    
    log("Generated build order with " .. #self.buildOrder .. " tiles")
end

-- Set up floor prerequisites
function BuyTileProgressionManager:SetupFloorPrerequisites()
    log("Setting up floor prerequisites")
    
    -- Clear existing prerequisites
    self.floorPrerequisites = {}
    
    -- Get all tiles
    local tiles = {}
    for tileId, tile in pairs(BuyTileSystem.tiles) do
        if tile.floor then
            tiles[tile.floor] = tiles[tile.floor] or {}
            table.insert(tiles[tile.floor], {
                id = tileId,
                data = tile
            })
        end
    end
    
    -- Set up prerequisites for each floor
    for floor = 2, CONFIG.maxFloors do
        if tiles[floor] then
            for _, tile in ipairs(tiles[floor]) do
                -- Find a prerequisite from the previous floor
                if tiles[floor - 1] and #tiles[floor - 1] > 0 then
                    local prereq = tiles[floor - 1][1]
                    tile.data.requiredTiles = tile.data.requiredTiles or {}
                    table.insert(tile.data.requiredTiles, prereq.id)
                    
                    -- Update the tile in BuyTileSystem
                    BuyTileSystem:RegisterTile(tile.data)
                end
            end
        end
    end
    
    log("Set up floor prerequisites")
end

-- Identify required tiles
function BuyTileProgressionManager:IdentifyRequiredTiles()
    log("Identifying required tiles")
    
    -- Clear existing required tiles
    self.requiredTiles = {}
    
    -- Get all tiles
    local tiles = {}
    for tileId, tile in pairs(BuyTileSystem.tiles) do
        table.insert(tiles, {
            id = tileId,
            data = tile
        })
    end
    
    -- Calculate how many tiles should be required
    local requiredCount = math.ceil(#tiles * CONFIG.requiredTilePercentage)
    
    -- Sort tiles by importance (you can define your own importance criteria)
    table.sort(tiles, function(a, b)
        -- Prioritize tiles with more prerequisites
        local aPrereqs = a.data.requiredTiles and #a.data.requiredTiles or 0
        local bPrereqs = b.data.requiredTiles and #b.data.requiredTiles or 0
        if aPrereqs ~= bPrereqs then
            return aPrereqs > bPrereqs
        end
        -- Then by floor
        if a.data.floor ~= b.data.floor then
            return a.data.floor < b.data.floor
        end
        -- Then by build order
        return a.data.buildOrder < b.data.buildOrder
    end)
    
    -- Mark the top N tiles as required
    for i = 1, requiredCount do
        if tiles[i] then
            tiles[i].data.isRequired = true
            self.requiredTiles[tiles[i].id] = true
            
            -- Update the tile in BuyTileSystem
            BuyTileSystem:RegisterTile(tiles[i].data)
        end
    end
    
    log("Identified " .. #self.requiredTiles .. " required tiles")
end

-- Integrate with BuyTileSystem
function BuyTileProgressionManager:IntegrateWithBuyTileSystem()
    log("Integrating with BuyTileSystem")
    
    -- Register with BuyTileSystem
    if BuyTileSystem then
        -- Set up event handlers
        BuyTileSystem.OnTilePurchased = function(player, tileId)
            self:HandleTilePurchased(player, tileId)
        end
        
        -- Register our tiles
        for tileId, tile in pairs(self.buildOrder) do
            BuyTileSystem:RegisterTile(tile)
        end
        
        log("Successfully integrated with BuyTileSystem")
    else
        log("BuyTileSystem not found", "error")
    end
end

-- Handle tile purchased event
function BuyTileProgressionManager:HandleTilePurchased(player, tileId)
    if not player or not tileId then return end
    
    -- Get the purchased tile
    local tile = BuyTileSystem:GetTile(tileId)
    if not tile then return end
    
    -- Check if this unlocks any new tiles
    for _, potentialTile in pairs(BuyTileSystem.tiles) do
        if potentialTile.requiredTiles then
            local allPrereqsMet = true
            for _, prereqId in ipairs(potentialTile.requiredTiles) do
                if not BuyTileSystem:IsTileOwned(player, prereqId) then
                    allPrereqsMet = false
                    break
                end
            end
            
            if allPrereqsMet then
                -- Notify the player
                self:NotifyTileUnlocked(player, potentialTile.id)
            end
        end
    end
end

-- Create RemoteEvent for client notifications
local function setupRemotes()
    local remotes = ReplicatedStorage:FindFirstChild("BuyTileRemotes")
    if not remotes then
        remotes = Instance.new("Folder")
        remotes.Name = "BuyTileRemotes"
        remotes.Parent = ReplicatedStorage
    end
    
    local notificationRemote = remotes:FindFirstChild("TileNotification")
    if not notificationRemote then
        notificationRemote = Instance.new("RemoteEvent")
        notificationRemote.Name = "TileNotification"
        notificationRemote.Parent = remotes
    end
    
    return notificationRemote
end

-- Notify player of unlocked tile
function BuyTileProgressionManager:NotifyTileUnlocked(player, tileId)
    if not player or not tileId then return end
    
    -- Get the tile
    local tile = BuyTileSystem:GetTile(tileId)
    if not tile then return end
    
    -- Create notification
    local notification = {
        type = "tileUnlocked",
        tileId = tileId,
        tileName = tile.name,
        cost = tile.cost,
        floor = tile.floor,
        isRequired = tile.isRequired,
        duration = CONFIG.notificationDuration,
        sound = CONFIG.notificationSound
    }
    
    -- Send to client
    local notificationRemote = setupRemotes()
    notificationRemote:FireClient(player, notification)
    
    -- Check for progression milestones
    self:CheckProgressionMilestones(player)
end

-- Check for progression milestones
function BuyTileProgressionManager:CheckProgressionMilestones(player)
    if not player then return end
    
    -- Get owned tiles count
    local ownedTiles = BuyTileSystem:GetOwnedTiles(player)
    local tileCount = #ownedTiles
    
    -- Check each milestone
    for _, milestone in ipairs(CONFIG.progressionMilestones) do
        if tileCount >= milestone.tiles then
            -- Check if milestone was already awarded
            local playerData = DataAccessLayer:GetPlayerData(player)
            local awardedMilestones = playerData.awardedMilestones or {}
            
            if not awardedMilestones[milestone.tiles] then
                -- Award milestone
                local currentCash = playerData.cash or 0
                DataAccessLayer:UpdatePlayerData(player, "cash", currentCash + milestone.reward)
                
                -- Mark milestone as awarded
                awardedMilestones[milestone.tiles] = true
                DataAccessLayer:UpdatePlayerData(player, "awardedMilestones", awardedMilestones)
                
                -- Notify player
                local notification = {
                    type = "milestoneReached",
                    milestone = milestone.tiles,
                    reward = milestone.reward,
                    duration = CONFIG.notificationDuration,
                    sound = CONFIG.notificationSound
                }
                
                local notificationRemote = setupRemotes()
                notificationRemote:FireClient(player, notification)
            end
        end
    end
end

-- Get player progression stats
function BuyTileProgressionManager:GetPlayerProgression(player)
    if not player then return nil end
    
    local ownedTiles = BuyTileSystem:GetOwnedTiles(player)
    local availableTiles = self:GetNextAvailableTiles(player)
    
    -- Calculate floor progress
    local floorProgress = {}
    for floor = 1, CONFIG.maxFloors do
        local floorTiles = 0
        local totalFloorTiles = 0
        
        for _, tile in pairs(BuyTileSystem.tiles) do
            if tile.floor == floor then
                totalFloorTiles += 1
                if BuyTileSystem:IsTileOwned(player, tile.id) then
                    floorTiles += 1
                end
            end
        end
        
        floorProgress[floor] = {
            owned = floorTiles,
            total = totalFloorTiles,
            percentage = totalFloorTiles > 0 and (floorTiles / totalFloorTiles) * 100 or 0
        }
    end
    
    -- Calculate next milestone
    local nextMilestone = nil
    local ownedCount = #ownedTiles
    
    for _, milestone in ipairs(CONFIG.progressionMilestones) do
        if ownedCount < milestone.tiles then
            nextMilestone = {
                tiles = milestone.tiles,
                reward = milestone.reward,
                progress = (ownedCount / milestone.tiles) * 100
            }
            break
        end
    end
    
    return {
        ownedTiles = ownedTiles,
        availableTiles = availableTiles,
        floorProgress = floorProgress,
        nextMilestone = nextMilestone,
        totalTiles = #ownedTiles + #availableTiles
    }
end

-- Get next available tiles for a player
function BuyTileProgressionManager:GetNextAvailableTiles(player, limit)
    if not player then return {} end
    
    local availableTiles = {}
    local count = 0
    
    -- Get all tiles
    for tileId, tile in pairs(BuyTileSystem.tiles) do
        if not BuyTileSystem:IsTileOwned(player, tileId) then
            -- Check prerequisites
            local meetsPrerequisites = true
            if tile.requiredTiles then
                for _, prereqId in ipairs(tile.requiredTiles) do
                    if not BuyTileSystem:IsTileOwned(player, prereqId) then
                        meetsPrerequisites = false
                        break
                    end
                end
            end
            
            if meetsPrerequisites then
                table.insert(availableTiles, {
                    tileId = tileId,
                    data = tile
                })
                count = count + 1
                if limit and count >= limit then
                    break
                end
            end
        end
    end
    
    return availableTiles
end

-- Add progression command
function BuyTileProgressionManager:CreateCommands()
    log("Creating commands")
    
    -- Register with CommandService if available
    local CommandService = CoreRegistry:getSystem("CommandService")
    if not CommandService then
        log("CommandService not found", "warn")
        return
    end
    
    -- Register commands
    CommandService:RegisterCommand("checkProgression", {
        description = "Shows available tiles for player",
        parameters = {},
        handler = function(player)
            if not BuyTileSystem then
                return "BuyTileSystem not found"
            end
            
            local progression = self:GetPlayerProgression(player)
            if not progression then
                return "Failed to get progression data"
            end
            
            local result = "=== Progression Stats ===\n"
            
            -- Show floor progress
            result = result .. "\nFloor Progress:\n"
            for floor, progress in pairs(progression.floorProgress) do
                result = result .. string.format("Floor %d: %d/%d tiles (%.1f%%)\n",
                    floor, progress.owned, progress.total, progress.percentage)
            end
            
            -- Show next milestone
            if progression.nextMilestone then
                result = result .. string.format("\nNext Milestone: %d tiles (%.1f%%)\nReward: %d cash\n",
                    progression.nextMilestone.tiles,
                    progression.nextMilestone.progress,
                    progression.nextMilestone.reward)
            end
            
            -- Show available tiles
            result = result .. "\nAvailable Tiles:\n"
            for i, tileInfo in ipairs(progression.availableTiles) do
                if i <= 10 then
                    result = result .. string.format("%d. %s (Floor %d) - %d cash\n",
                        i, tileInfo.data.name, tileInfo.data.floor, tileInfo.data.cost)
                end
            end
            
            if #progression.availableTiles == 0 then
                result = result .. "No available tiles found"
            elseif #progression.availableTiles > 10 then
                result = result .. "... and " .. (#progression.availableTiles - 10) .. " more"
            end
            
            return result
        end
    })
    
    log("Created commands")
end

-- Initialize the system
function BuyTileProgressionManager:Initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing BuyTileProgressionManager v" .. self.Version)
    
    -- Set up build order
    self:GenerateBuildOrder()
    
    -- Set up floor progression
    self:SetupFloorPrerequisites()
    
    -- Identify required tiles
    self:IdentifyRequiredTiles()
    
    -- Integrate with BuyTileSystem
    self:IntegrateWithBuyTileSystem()
    
    -- Create commands
    self:CreateCommands()
    
    -- Register with CoreRegistry
    if CoreRegistry then
        CoreRegistry:registerSystem("BuyTileProgressionManager", self)
        log("Registered with CoreRegistry")
    end
    
    self.initialized = true
    log("BuyTileProgressionManager initialized successfully")
    return true
end

-- Get system health
function BuyTileProgressionManager:IsHealthy()
    return self.initialized
end

-- Recover from failure
function BuyTileProgressionManager:Recover()
    if not self.initialized then
        return self:Initialize()
    end
    return true
end

-- Initialize the BuyTileProgressionManager
BuyTileProgressionManager:Initialize()

return BuyTileProgressionManager