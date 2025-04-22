--[[
    BuyTileProgressionManager.server.luau
    
    Manages the progression sequence for BuyTile purchases based on the physical gym structure.
    This system ensures logical build order based on floors, rooms, and structure types.
    
    Features:
    - Analyzes gym structure to determine logical purchase sequence
    - Creates dependencies between areas (walls before equipment)
    - Enforces floor progression (complete one floor before the next)
    - Provides intelligent prerequisites for tiles based on location
    - Automatic integrated into the existing BuyTileSystem
    
    Author: Created May 2025
]]

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Find CoreRegistry
local CoreRegistry = nil
local systemFolder = ServerScriptService:FindFirstChild("Systems") or ServerScriptService

for _, folder in pairs(systemFolder:GetDescendants()) do
    if folder:IsA("ModuleScript") and folder.Name == "CoreRegistry" then
        CoreRegistry = require(folder)
        break
    end
end

-- Get system references
local BuyTileSystem = CoreRegistry and CoreRegistry:GetSystem("BuyTileSystem")
local FloorAttributeSetup = CoreRegistry and CoreRegistry:GetSystem("FloorAttributeSetup")

-- Progression order constants
local STRUCTURE_BUILD_ORDER = {
    "Walls", -- Walls first
    "Floor", -- Then floors
    "Ceiling", -- Then ceilings
    "Room", -- Then room-specific items
    "Equipment", -- Then equipment
    "Amenity", -- Then amenities
    "Stairs" -- Stairs last (to next floor)
}

local ROOM_PRIORITY = {
    "Entrance", -- Entrance first
    "Main", -- Main areas
    "Cardio", -- Cardio zones
    "Strength", -- Strength training
    "Specialty", -- Specialty areas
    "Locker", -- Locker rooms
    "Staff", -- Staff areas
    "Amenities" -- Amenities last
}

-- BuyTileProgressionManager singleton
local BuyTileProgressionManager = {
    Debug = false -- Set to true for detailed logging
}

-- Log messages if debug is enabled
function BuyTileProgressionManager:Log(message)
    if self.Debug then
        print("[BuyTileProgressionManager] " .. message)
    end
end

-- Generate build order for tiles based on structure
function BuyTileProgressionManager:GenerateBuildOrder()
    if not BuyTileSystem or not BuyTileSystem.tileData then
        warn("BuyTileSystem not found, cannot generate build order")
        return false
    end
    
    self:Log("Generating intelligent build order based on gym structure...")
    
    -- Sort by floor first, then structure type, then room priority
    local tilesInfo = {}
    
    for tileType, tileData in pairs(BuyTileSystem.tileData) do
        table.insert(tilesInfo, {
            tileType = tileType,
            tileData = tileData,
            floor = tileData.floor or 1,
            structureType = self:DetermineStructureType(tileData),
            roomPriority = self:DetermineRoomPriority(tileData)
        })
    end
    
    -- Sort tiles
    table.sort(tilesInfo, function(a, b)
        -- Sort by floor first
        if a.floor ~= b.floor then
            return a.floor < b.floor
        end
        
        -- Then by structure type priority
        local aTypeIndex = self:GetStructurePriorityIndex(a.structureType)
        local bTypeIndex = self:GetStructurePriorityIndex(b.structureType)
        if aTypeIndex ~= bTypeIndex then
            return aTypeIndex < bTypeIndex
        end
        
        -- Then by room priority
        if a.roomPriority ~= b.roomPriority then
            return a.roomPriority < b.roomPriority
        end
        
        -- Finally by existing build order if it exists
        return (a.tileData.buildOrder or 9999) < (b.tileData.buildOrder or 9999)
    end)
    
    -- Assign new build orders
    local buildOrderSpacing = 10 -- Leave gaps for future insertions
    local currentBuildOrder = 1
    
    for _, tileInfo in ipairs(tilesInfo) do
        -- Update build order in tile data
        BuyTileSystem.tileData[tileInfo.tileType].buildOrder = currentBuildOrder
        
        -- Generate prerequisites based on structure
        self:GeneratePrerequisites(tileInfo.tileType, tilesInfo)
        
        currentBuildOrder += buildOrderSpacing
    end
    
    self:Log("Successfully generated build order for " .. #tilesInfo .. " tiles")
    return true
end

-- Generate prerequisites for a tile based on structure
function BuyTileProgressionManager:GeneratePrerequisites(tileType, tilesInfo)
    if not BuyTileSystem or not BuyTileSystem.tileData then return end
    
    local tileData = BuyTileSystem.tileData[tileType]
    if not tileData then return end
    
    -- Start with empty prerequisites unless they already exist
    local prerequisites = tileData.prerequisites or {}
    
    -- Find structure dependencies
    local currentStructureType = self:DetermineStructureType(tileData)
    local floor = tileData.floor or 1
    
    -- If this is not a wall and not on the first floor, require previous floor
    if floor > 1 and currentStructureType ~= "Walls" and currentStructureType ~= "Stairs" then
        -- Find the stairs/elevator from previous floor
        for _, tileInfo in ipairs(tilesInfo) do
            if tileInfo.floor == floor - 1 and tileInfo.structureType == "Stairs" then
                -- Add stair prerequisite if not already in the list
                local found = false
                for _, prereq in ipairs(prerequisites) do
                    if prereq == tileInfo.tileType then
                        found = true
                        break
                    end
                end
                
                if not found then
                    table.insert(prerequisites, tileInfo.tileType)
                end
                
                break
            end
        end
    end
    
    -- If this is equipment/amenity and floor > 1, require a "Floor" tile on this floor
    if floor > 1 and (currentStructureType == "Equipment" or currentStructureType == "Amenity") then
        local floorTileFound = false
        for _, tileInfo in ipairs(tilesInfo) do
            if tileInfo.floor == floor and tileInfo.structureType == "Floor" then
                local found = false
                for _, prereq in ipairs(prerequisites) do
                    if prereq == tileInfo.tileType then
                        found = true
                        break
                    end
                end
                if not found and #prerequisites < 3 then -- Limit to 3 prerequisites
                    table.insert(prerequisites, tileInfo.tileType)
                    floorTileFound = true
                    break
                end
            end
        end
    end
    -- If this is equipment/amenity, require walls on this floor
    if currentStructureType == "Equipment" or currentStructureType == "Amenity" then
        -- Find Walls tiles on this floor
        for _, tileInfo in ipairs(sortedTiles) do
            if tileInfo.floor == floor and tileInfo.structureType == "Walls" then
                -- Add wall prerequisite if not already in list
                local found = false
                for _, prereq in ipairs(prerequisites) do
                    if prereq == tileInfo.tileType then
                        found = true
                        break
                    end
                end
                
                if not found and #prerequisites < 3 then -- Limit to 3 prerequisites max
                    table.insert(prerequisites, tileInfo.tileType)
                    break
                end
            end
        end
    end
    
    -- Update prerequisites in tile data
    BuyTileSystem.tileData[tileType].prerequisites = prerequisites
end

-- Determine structure type from tile data
function BuyTileProgressionManager:DetermineStructureType(tileData)
    if not tileData then return "Equipment" end
    
    -- Use existing structure type if available
    if tileData.structureType then
        return tileData.structureType
    end
    
    -- Check category first
    if tileData.category then
        local category = tileData.category:lower()
        if category:find("structure") then
            local description = tileData.description and tileData.description:lower() or ""
            if description:find("wall") then
                return "Walls"
            elseif description:find("floor") then
                return "Floor"
            elseif description:find("ceiling") then
                return "Ceiling"
            elseif description:find("stair") or description:find("elevator") then
                return "Stairs"
            end
            return "Structure"
        elseif category:find("amenity") or category:find("amenities") then
            return "Amenity"
        end
    end
    
    -- Check description for structure hints
    if tileData.description then
        local description = tileData.description:lower()
        if description:find("wall") then
            return "Walls"
        elseif description:find("floor") then
            return "Floor"
        elseif description:find("ceiling") then
            return "Ceiling"
        elseif description:find("stair") or description:find("elevator") then
            return "Stairs"
        end
    end
    
    -- Check tile type for structure hints
    local tileTypeLower = tileData.tileType and string.lower(tileData.tileType) or ""
    if tileTypeLower:find("wall") then
        return "Walls"
    elseif tileTypeLower:find("floor") then
        return "Floor"
    elseif tileTypeLower:find("ceiling") then
        return "Ceiling"
    elseif tileTypeLower:find("stair") or tileTypeLower:find("elevator") then
        return "Stairs"
    end
    
    -- Check model name if available
    if tileData.modelName then
        local modelName = string.lower(tileData.modelName)
        if modelName:find("wall") then
            return "Walls"
        elseif modelName:find("floor") then
            return "Floor"
        elseif modelName:find("ceiling") then
            return "Ceiling"
        elseif modelName:find("stair") or modelName:find("elevator") then
            return "Stairs"
        end
    end
    
    -- Default to equipment
    return "Equipment"
end

-- Determine room priority based on tile data and name
function BuyTileProgressionManager:DetermineRoomPriority(tileData)
    if not tileData then return 5 end
    
    -- Check room attribute first
    if tileData.room then
        local roomName = string.lower(tileData.room)
        
        for i, priority in ipairs(ROOM_PRIORITY) do
            if roomName:find(string.lower(priority)) then
                return i
            end
        end
    end
    
    -- Check description for room hints
    if tileData.description then
        local description = string.lower(tileData.description)
        
        for i, priority in ipairs(ROOM_PRIORITY) do
            if description:find(string.lower(priority)) then
                return i
            end
        end
    end
    
    -- Check tile type for room hints
    if tileData.tileType then
        local tileType = string.lower(tileData.tileType)
        
        for i, priority in ipairs(ROOM_PRIORITY) do
            if tileType:find(string.lower(priority)) then
                return i
            end
        end
    end
    
    -- Default to middle priority
    return 5
end

-- Helper to get structure priority index
function BuyTileProgressionManager:GetStructurePriorityIndex(structureType)
    for i, structure in ipairs(STRUCTURE_BUILD_ORDER) do
        if structure == structureType then
            return i
        end
    end
    
    -- Default to middle priority
    return 4 -- Equipment
end

-- Generate basic build order without complex structure analysis
function BuyTileProgressionManager:GenerateBasicBuildOrder()
    if not BuyTileSystem or not BuyTileSystem.tileData then
        warn("BuyTileSystem not found, cannot generate build order")
        return false
    end
    
    self:Log("Generating basic build order...")
    
    -- Sort by floor first, then predefined order
    local orderedTiles = {}
    
    for tileType, tileData in pairs(BuyTileSystem.tileData) do
        table.insert(orderedTiles, {
            tileType = tileType,
            data = tileData,
            floor = tileData.floor or 1,
            buildOrder = tileData.buildOrder or 9999
        })
    end
    
    -- Sort by floor then by existing build order
    table.sort(orderedTiles, function(a, b)
        if a.floor ~= b.floor then
            return a.floor < b.floor
        end
        return a.buildOrder < b.buildOrder
    end)
    
    -- Assign new sequential build orders
    local currentBuildOrder = 1
    local buildOrderSpacing = 10
    
    for _, tile in ipairs(orderedTiles) do
        BuyTileSystem.tileData[tile.tileType].buildOrder = currentBuildOrder
        currentBuildOrder += buildOrderSpacing
    end
    
    self:Log("Assigned basic build order to " .. #orderedTiles .. " tiles")
    return true
end

-- Create floor prerequisites - each floor requires completion of previous floor
function BuyTileProgressionManager:SetupFloorPrerequisites()
    if not BuyTileSystem or not BuyTileSystem.tileData then
        warn("BuyTileSystem not found, cannot set up floor prerequisites")
        return false
    end
    
    self:Log("Setting up floor prerequisites...")
    
    -- Find key tile for each floor
    local floorGateways = {}
    
    -- First pass to categorize tiles by floor
    local tilesByFloor = {}
    for tileType, tileData in pairs(BuyTileSystem.tileData) do
        local floor = tileData.floor or 1
        
        if not tilesByFloor[floor] then
            tilesByFloor[floor] = {}
        end
        
        table.insert(tilesByFloor[floor], {
            tileType = tileType,
            data = tileData
        })
        
        -- Look for stair/elevator tiles that lead to next floor
        local structureType = self:DetermineStructureType(tileData)
        if structureType == "Stairs" then
            floorGateways[floor] = tileType
            tileData.isFloorGateway = true
            tileData.unlockNextFloor = true
            tileData.isRequired = true
            
            self:Log("Floor " .. floor .. " gateway: " .. tileType)
        end
    end
    
    -- If gateway tiles are not found, use last tile of each floor by build order
    for floor, tiles in pairs(tilesByFloor) do
        if not floorGateways[floor] and #tiles > 0 then
            -- Sort tiles by build order
            table.sort(tiles, function(a, b)
                return (a.data.buildOrder or 9999) < (b.data.buildOrder or 9999)
            end)
            
            -- Use the last tile as gateway
            local lastTile = tiles[#tiles]
            floorGateways[floor] = lastTile.tileType
            lastTile.data.isFloorGateway = true
            lastTile.data.unlockNextFloor = true
            
            self:Log("No stair found - Using " .. lastTile.tileType .. " as floor " .. floor .. " gateway")
        end
    end
    
    -- Now set up prerequisites for each floor
    for floor = 2, 6 do -- Process floors 2-6 (assuming floor 1 is available from start)
        if not tilesByFloor[floor] then continue end
        
        local previousFloorGateway = floorGateways[floor - 1]
        if not previousFloorGateway then continue end
        
        for _, tile in ipairs(tilesByFloor[floor]) do
            -- Only add prerequisite to the "first" tile of each type on this floor
            local isFirstTileOfItsType = true -- Simple for now, could be expanded
            
            if isFirstTileOfItsType then
                local prerequisites = tile.data.prerequisites or {}
                
                -- Add gateway from previous floor as prerequisite if not present
                local alreadyInList = false
                for _, prereq in ipairs(prerequisites) do
                    if prereq == previousFloorGateway then
                        alreadyInList = true
                        break
                    end
                end
                
                if not alreadyInList then
                    table.insert(prerequisites, previousFloorGateway)
                    tile.data.prerequisites = prerequisites
                    self:Log("Added prerequisite " .. previousFloorGateway .. " to " .. tile.tileType)
                end
            end
        end
    end
    
    self:Log("Floor prerequisites setup complete")
    return true
end

-- Detect required tiles for floor progression
function BuyTileProgressionManager:IdentifyRequiredTiles()
    if not BuyTileSystem or not BuyTileSystem.tileData then
        warn("BuyTileSystem not found, cannot identify required tiles")
        return false
    end
    
    self:Log("Identifying required tiles...")
    
    -- Initialize required items table if not exists
    if not BuyTileSystem.requiredItems then
        BuyTileSystem.requiredItems = {}
    end
    
    -- Reset required tiles by floor
    for i = 1, 6 do
        BuyTileSystem.requiredItems[i] = {}
    end
    
    -- Go through all tiles
    for tileType, tileData in pairs(BuyTileSystem.tileData) do
        local floor = tileData.floor or 1
        
        -- Mark essential structure tiles as required
        local structureType = self:DetermineStructureType(tileData)
        if structureType == "Walls" or structureType == "Floor" or structureType == "Ceiling" or
           structureType == "Stairs" or tileData.isRequired == true then
            
            -- Add to required items for this floor
            table.insert(BuyTileSystem.requiredItems[floor], tileType)
            tileData.isRequired = true
            
            self:Log("Marked " .. tileType .. " as required for floor " .. floor)
        end
    end
    
    -- Ensure at least one required item per floor
    for floor, requiredItems in pairs(BuyTileSystem.requiredItems) do
        if #requiredItems == 0 and BuyTileSystem.tileData then
            -- Find any tile on this floor
            for tileType, tileData in pairs(BuyTileSystem.tileData) do
                if (tileData.floor or 1) == floor then
                    table.insert(BuyTileSystem.requiredItems[floor], tileType)
                    tileData.isRequired = true
                    self:Log("Added " .. tileType .. " as required item for floor " .. floor .. " (no required items found)")
                    break
                end
            end
        end
    end
    
    self:Log("Required tiles identification complete")
    return true
end

-- Hook BuyTileSystem to use floor-based progression
function BuyTileProgressionManager:IntegrateWithBuyTileSystem()
    if not BuyTileSystem then
        warn("BuyTileSystem not found, cannot integrate")
        return false
    end
    
    self:Log("Integrating with BuyTileSystem...")
    
    -- Add method to check if floor is completed
    BuyTileSystem.IsFloorCompleted = function(self, player, floorNumber)
        local playerData = self:GetPlayerData(player)
        if not playerData or not self.requiredItems then
            return false
        end
        
        -- Check if all required items for this floor are owned
        local requiredItems = self.requiredItems[floorNumber] or {}
        for _, tileType in ipairs(requiredItems) do
            if not playerData.ownedTiles[tileType] then
                return false
            end
        end
        
        return true
    end
    
    -- Add method to check if floor is available for purchase
    BuyTileSystem.IsFloorAvailable = function(self, player, floorNumber)
        if floorNumber == 1 then
            return true -- First floor always available
        end
        
        -- Check if previous floor is completed
        return self:IsFloorCompleted(player, floorNumber - 1)
    end
    
    -- Add method to get next available tiles
    BuyTileSystem.GetNextAvailableTiles = function(self, player, maxCount)
        maxCount = maxCount or 5
        local availableTiles = {}
        local playerData = self:GetPlayerData(player)
        
        if not playerData then
            return availableTiles
        end
        
        -- Make sure ordered tiles is up-to-date
        if not self.orderedTiles or #self.orderedTiles == 0 then
            if self.SortTilesByBuildOrder then
                self:SortTilesByBuildOrder()
            end
        end
        
        -- Go through all sorted tiles
        for _, tileInfo in ipairs(self.orderedTiles) do
            local tileType = tileInfo.tileType
            local data = self.tileData[tileType]
            
            -- Skip if already owned
            if playerData.ownedTiles[tileType] then
                continue
            end
            
            -- Check if floor is available
            local floor = data.floor or 1
            if not self:IsFloorAvailable(player, floor) then
                continue
            end
            
            -- Check prerequisites
            if self:AreRequirementsMet(player, tileType) then
                table.insert(availableTiles, {
                    tileType = tileType,
                    data = data
                })
                
                -- Return when we have enough
                if #availableTiles >= maxCount then
                    break
                end
            end
        end
        
        return availableTiles
    end
    
    -- Hook into BuyTile to update floor unlocks
    if BuyTileSystem.BuyTile then
        local originalBuyTile = BuyTileSystem.BuyTile
        BuyTileSystem.BuyTile = function(self, player, tileType, ...)
            local result = originalBuyTile(self, player, tileType, ...)
            
            -- If purchase successful, check if this unlocks the next floor
            if result and self.tileData and self.tileData[tileType] then
                local tileData = self.tileData[tileType]
                
                -- Check if this tile unlocks next floor
                if tileData.unlockNextFloor and tileData.floor then
                    local currentFloor = tileData.floor
                    local nextFloor = currentFloor + 1
                    
                    -- Unlock next floor in player data
                    local playerData = self:GetPlayerData(player)
                    if playerData then
                        if not playerData.unlockedFloors then
                            playerData.unlockedFloors = {}
                        end
                        
                        playerData.unlockedFloors[nextFloor] = true
                        
                        -- Fire event for floor unlock
                        if self.Events and self.Events.FloorUnlocked then
                            self.Events.FloorUnlocked:Fire(player, nextFloor)
                        end
                        
                        self:Log("Player " .. player.Name .. " unlocked floor " .. nextFloor)
                    end
                end
            end
            
            return result
        end
    end
    
    self:Log("BuyTileSystem integration complete")
    return true
end

-- Setup progression commands
function BuyTileProgressionManager:CreateCommands()
    local CommandService = CoreRegistry and CoreRegistry:GetSystem("CommandService")
    
    if not CommandService then
        warn("CommandService not found, progression commands won't be available")
        return false
    end
    
    -- Register a command to generate build order
    CommandService:RegisterCommand("generateBuildOrder", {
        description = "Generates intelligent build order for BuyTiles",
        parameters = {},
        handler = function(player)
            -- Check if player is authorized to run admin commands
            local AdminService = CoreRegistry:GetSystem("AdminService")
            if AdminService and not AdminService:IsAdmin(player) then
                return "You don't have permission to use this command"
            end
            
            self:GenerateBuildOrder()
            self:SetupFloorPrerequisites()
            self:IdentifyRequiredTiles()
            
            return "Generated build order and progression requirements"
        end
    })
    
    -- Register a command to test progression
    CommandService:RegisterCommand("checkProgression", {
        description = "Shows available tiles for player",
        parameters = {},
        handler = function(player)
            if not BuyTileSystem then
                return "BuyTileSystem not found"
            end
            
            local result = "=== Available Tiles ===\n"
            local availableTiles = BuyTileSystem:GetNextAvailableTiles(player, 10)
            
            for i, tileInfo in ipairs(availableTiles) do
                result = result .. i .. ". " .. tileInfo.tileType
                if tileInfo.data.floor then
                    result = result .. " (Floor " .. tileInfo.data.floor .. ")"
                end
                if tileInfo.data.isRequired then
                    result = result .. " [REQUIRED]"
                end
                result = result .. "\n"
            end
            
            if #availableTiles == 0 then
                result = result .. "No available tiles found"
            end
            
            return result
        end
    })
    
    return true
end

-- Complete system initialization
function BuyTileProgressionManager:Initialize()
    self:Log("Initializing...")
    
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
    
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.RegisterSystem then
        CoreRegistry:RegisterSystem("BuyTileProgressionManager", self)
        self:Log("Registered with CoreRegistry")
    end
    
    self:Log("Initialization complete")
    return self
end

return BuyTileProgressionManager:Initialize()