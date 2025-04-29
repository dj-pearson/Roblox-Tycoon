--[[
    TileDataInitializer.server.luau
    
    This script initializes and sets up tile data for the BuyTileSystem based on the physical
    structure of the gym. It follows the new progression rules:
    
    1. Front Desk first (ID attribute 1)
    2. Walls for each room
    3. Room contents in order of folder structure
    4. Ceiling for each floor
    5. Stairs to next floor
    
    Created April 28, 2025
]]

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Find a module
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
        warn("TileDataInitializer: Failed to require " .. moduleInstance:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
end

-- Find CoreRegistry and key systems
local CoreRegistry = safeRequire(findModule("CoreRegistry"))
local BuyTileSystem = CoreRegistry and CoreRegistry:GetSystem("BuyTileSystem")
local EventBridge = CoreRegistry and CoreRegistry:GetSystem("EventBridge") or {
    fireEvent = function() end,
    registerEvent = function() end
}

-- Constants
local ROOM_FOLDER_NAME = "Rooms"
local GYM_PARTS_FOLDER_NAME = "GymParts"
local FLOOR_ATTRIBUTES = {"1st_Floor", "2nd_Floor", "3rd_Floor", "4th_Floor", "5th_Floor"}

-- Initialize tile data from gym structure
local function initializeTileData()
    if not BuyTileSystem then
        warn("TileDataInitializer: BuyTileSystem not found, cannot initialize tile data")
        return false
    end
    
    print("TileDataInitializer: Initializing tile data from gym structure")
    
    -- Initialize tile data table if not exists
    local tileData = {}
    
    -- Get gym structure folder
    local gymStructure = ServerStorage:FindFirstChild("GymStructure")
    if not gymStructure then
        warn("TileDataInitializer: GymStructure folder not found in ServerStorage")
        return false
    end
    
    -- Process front desk first (ID attribute 1)
    local frontDesk = gymStructure:FindFirstChild("FrontDesk")
    if frontDesk then
        tileData["FrontDesk"] = {
            idAttribute = 1,
            cost = 500, -- Starting cost
            requiredLevel = 1,
            gymPartId = "FrontDesk",
            category = "Structure",
            structureType = "FrontDesk",
            description = "Start your gym business with a front desk",
            unlockMessage = "Welcome to your gym!",
            floor = 1,
            isRequired = true,
            prerequisites = {}
        }
    end
    
    local tileIdCounter = 1000 -- Starting ID for other tiles
    
    -- Process each floor
    for floorIndex, floorAttr in ipairs(FLOOR_ATTRIBUTES) do
        local floorFolder = gymStructure:FindFirstChild(floorAttr)
        if not floorFolder then continue end
        
        -- Process walls first
        local wallsFolder = floorFolder:FindFirstChild("Walls")
        if wallsFolder then
            for _, wall in ipairs(wallsFolder:GetChildren()) do
                local tileId = "Wall_" .. floorIndex .. "_" .. tileIdCounter
                tileIdCounter = tileIdCounter + 1
                
                -- Create wall tile data
                tileData[tileId] = {
                    idAttribute = tileIdCounter,
                    cost = 1000 * floorIndex, -- Increases by floor
                    requiredLevel = math.max(1, floorIndex - 1), -- Higher floors need higher level
                    gymPartId = wall.Name,
                    category = "Structure",
                    structureType = "Walls",
                    description = "Wall section for Floor " .. floorIndex,
                    unlockMessage = "Building your gym structure",
                    floor = floorIndex,
                    isRequired = true,
                    prerequisites = floorIndex > 1 and {"Stairs_" .. (floorIndex-1)} or {}
                }
            end
        end
        
        -- Process room contents
        local roomsFolder = floorFolder:FindFirstChild(ROOM_FOLDER_NAME)
        if roomsFolder then
            for _, room in ipairs(roomsFolder:GetChildren()) do
                local roomName = room.Name
                
                -- Process each equipment in the room
                for _, equipment in ipairs(room:GetChildren()) do
                    local tileId = roomName .. "_" .. equipment.Name .. "_" .. tileIdCounter
                    tileIdCounter = tileIdCounter + 1
                    
                    -- Find any wall tile for this floor as prerequisite
                    local wallPrereq = nil
                    for id, data in pairs(tileData) do
                        if data.floor == floorIndex and data.structureType == "Walls" then
                            wallPrereq = id
                            break
                        end
                    end
                    
                    -- Create equipment tile data
                    tileData[tileId] = {
                        idAttribute = tileIdCounter,
                        cost = 2000 * floorIndex, -- Increases by floor
                        requiredLevel = math.max(1, floorIndex),
                        gymPartId = equipment.Name,
                        category = roomName,
                        structureType = "Equipment",
                        room = roomName,
                        folder = equipment.Parent.Name, -- Store parent folder name
                        description = equipment.Name .. " for your " .. roomName,
                        unlockMessage = "New equipment for your " .. roomName,
                        floor = floorIndex,
                        isRequired = false,
                        prerequisites = wallPrereq and {wallPrereq} or {}
                    }
                end
            end
        end
        
        -- Process ceiling
        local ceilingFolder = floorFolder:FindFirstChild("Ceiling")
        if ceilingFolder then
            for _, ceiling in ipairs(ceilingFolder:GetChildren()) do
                local tileId = "Ceiling_" .. floorIndex .. "_" .. tileIdCounter
                tileIdCounter = tileIdCounter + 1
                
                -- Create ceiling tile data - requires walls to be completed
                tileData[tileId] = {
                    idAttribute = tileIdCounter,
                    cost = 1500 * floorIndex, -- Increases by floor
                    requiredLevel = math.max(1, floorIndex),
                    gymPartId = ceiling.Name,
                    category = "Structure",
                    structureType = "Ceiling",
                    description = "Ceiling section for Floor " .. floorIndex,
                    unlockMessage = "Finishing the structure of your gym",
                    floor = floorIndex,
                    isRequired = true,
                    prerequisites = {} -- Will be filled based on build order
                }
            end
        end
        
        -- Process stairs last (if not last floor)
        if floorIndex < #FLOOR_ATTRIBUTES then
            local stairsFolder = floorFolder:FindFirstChild("Stairs")
            if stairsFolder then
                for _, stairs in ipairs(stairsFolder:GetChildren()) do
                    local tileId = "Stairs_" .. floorIndex
                    
                    -- Create stairs tile data - requires ceiling to be completed
                    tileData[tileId] = {
                        idAttribute = tileIdCounter + 500, -- Higher ID to ensure last
                        cost = 5000 * floorIndex, -- Increases by floor
                        requiredLevel = math.max(1, floorIndex),
                        gymPartId = stairs.Name,
                        category = "Structure",
                        structureType = "Stairs",
                        description = "Stairs to Floor " .. (floorIndex + 1),
                        unlockMessage = "You've unlocked access to Floor " .. (floorIndex + 1) .. "!",
                        floor = floorIndex,
                        isRequired = true,
                        unlockNextFloor = true,
                        prerequisites = {} -- Will be filled based on build order
                    }
                    
                    tileIdCounter = tileIdCounter + 1
                end
            end
        end
    end
    
    -- Set tile data in BuyTileSystem
    if BuyTileSystem.setTileData then
        BuyTileSystem.setTileData(tileData)
        print("TileDataInitializer: Successfully set tile data with " .. table.maxn(tileData) .. " tiles")
        
        -- Ensure the progression ordering is applied
        if BuyTileSystem.refreshOrderedTiles then
            BuyTileSystem.refreshOrderedTiles()
            
            -- Generate prerequisites based on the order
            generatePrerequisitesFromOrder()
        end
        
        return true
    else
        warn("TileDataInitializer: BuyTileSystem.setTileData not found")
        return false
    end
end

-- Generate prerequisites based on ordered tiles
local function generatePrerequisitesFromOrder()
    if not BuyTileSystem or not BuyTileSystem.orderedTiles then return false end
    
    print("TileDataInitializer: Generating prerequisites from build order")
    
    local orderedTiles = BuyTileSystem.orderedTiles
    local tileData = BuyTileSystem.getTileData and BuyTileSystem.getAllTileData()
    
    if not tileData then
        warn("TileDataInitializer: No tile data available for prerequisite generation")
        return false
    end
    
    -- Track last tile by floor and room
    local lastTileByFloor = {}
    local lastTileByRoom = {}
    
    for i, tile in ipairs(orderedTiles) do
        local tileId = tile.tileId
        local tileInfo = tileData[tileId]
        
        if not tileInfo then continue end
        
        local floor = tileInfo.floor or 1
        local room = tileInfo.room or "Main"
        local structureType = tileInfo.structureType or "Equipment"
        
        -- Initialize prerequisites if not exists
        tileInfo.prerequisites = tileInfo.prerequisites or {}
        
        -- Special case for front desk - no prerequisites
        if tileInfo.idAttribute == 1 or i == 1 then
            tileInfo.prerequisites = {}
            lastTileByFloor[floor] = tileId
            lastTileByRoom[room] = tileId
            continue
        end
        
        -- Add prerequisite based on structure type and floor
        if structureType == "Walls" then
            -- Walls only depend on previous floor's stairs or front desk
            if floor > 1 and lastTileByFloor[floor-1] then
                table.insert(tileInfo.prerequisites, lastTileByFloor[floor-1])
            end
        elseif structureType == "Equipment" then
            -- Equipment depends on walls of the same floor
            if lastTileByRoom[room] then
                table.insert(tileInfo.prerequisites, lastTileByRoom[room])
            end
        elseif structureType == "Ceiling" then
            -- Ceiling depends on completing all rooms
            local roomsOnThisFloor = {}
            
            for _, otherTile in ipairs(orderedTiles) do
                local otherInfo = tileData[otherTile.tileId]
                if otherInfo and otherInfo.floor == floor and 
                   otherInfo.structureType ~= "Ceiling" and
                   otherInfo.structureType ~= "Stairs" then
                    if otherInfo.room and not roomsOnThisFloor[otherInfo.room] then
                        roomsOnThisFloor[otherInfo.room] = otherTile.tileId
                    end
                end
            end
            
            -- Add one prerequisite from each room if available
            for _, roomTileId in pairs(roomsOnThisFloor) do
                if #tileInfo.prerequisites < 3 then -- Limit to 3 prerequisites
                    table.insert(tileInfo.prerequisites, roomTileId)
                end
            end
        elseif structureType == "Stairs" then
            -- Stairs depend on ceiling
            for _, otherTile in ipairs(orderedTiles) do
                local otherInfo = tileData[otherTile.tileId]
                if otherInfo and otherInfo.floor == floor and 
                   otherInfo.structureType == "Ceiling" then
                    table.insert(tileInfo.prerequisites, otherTile.tileId)
                    break
                end
            end
        end
        
        -- Update tracker
        lastTileByFloor[floor] = tileId
        lastTileByRoom[room] = tileId
    end
    
    -- Update tile data with new prerequisites
    if BuyTileSystem.setTileData then
        BuyTileSystem.setTileData(tileData)
    end
    
    print("TileDataInitializer: Prerequisites generation completed")
    return true
end

-- Create a function to scan ServerStorage for gym parts
local function scanGymParts()
    local gymPartsFolder = ServerStorage:FindFirstChild(GYM_PARTS_FOLDER_NAME)
    if not gymPartsFolder then
        gymPartsFolder = Instance.new("Folder")
        gymPartsFolder.Name = GYM_PARTS_FOLDER_NAME
        gymPartsFolder.Parent = ServerStorage
    end
    
    print("TileDataInitializer: Scanning gym parts in ServerStorage")
    
    -- Count the number of parts found
    local partCount = 0
    
    -- Scan each subfolder
    for _, folder in ipairs(gymPartsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, part in ipairs(folder:GetChildren()) do
                partCount = partCount + 1
            end
        else
            partCount = partCount + 1
        end
    end
    
    print("TileDataInitializer: Found " .. partCount .. " gym parts in ServerStorage")
    return partCount > 0
end

-- Register commands if CommandService is available
local function registerCommands()
    local CommandService = CoreRegistry and CoreRegistry:GetSystem("CommandService")
    if not CommandService then return end
    
    -- Register command to regenerate tile data
    CommandService:RegisterCommand("generateTileData", {
        description = "Regenerates tile data from gym structure",
        handler = function(player)
            -- Check if player is admin
            local AdminService = CoreRegistry:GetSystem("AdminService")
            if AdminService and not AdminService:IsAdmin(player) then
                return "You don't have permission to use this command"
            end
            
            local success = initializeTileData()
            return success 
                and "Successfully regenerated tile data from gym structure" 
                or "Failed to regenerate tile data"
        end
    })
    
    -- Register command to show tile progression
    CommandService:RegisterCommand("showTileProgression", {
        description = "Shows the current tile progression order",
        handler = function(player)
            if not BuyTileSystem or not BuyTileSystem.orderedTiles then
                return "Tile progression not available"
            end
            
            local result = "=== Tile Progression Order ===\n"
            for i, tile in ipairs(BuyTileSystem.orderedTiles) do
                if i > 20 then
                    result = result .. "... and " .. (#BuyTileSystem.orderedTiles - 20) .. " more tiles"
                    break
                end
                
                local tileData = BuyTileSystem.getTileData(tile.tileId)
                result = result .. i .. ". " .. tile.tileId
                
                if tileData then
                    result = result .. " (Floor: " .. (tileData.floor or 1)
                    if tileData.room then
                        result = result .. ", Room: " .. tileData.room
                    end
                    result = result .. ")\n"
                else
                    result = result .. "\n"
                end
            end
            
            return result
        end
    })
end

-- Initialize when the script runs
local function initialize()
    print("TileDataInitializer: Initializing...")
    
    -- Scan for gym parts first
    scanGymParts()
    
    -- Initialize tile data
    local success = initializeTileData()
    
    -- Register commands
    registerCommands()
    
    -- Register with EventBridge
    if EventBridge.registerEvent then
        EventBridge.registerEvent("TileData_Initialized")
        EventBridge.registerEvent("TileData_Regenerated")
    end
    
    -- Fire event to notify systems of initialization
    if EventBridge.fireEvent then
        EventBridge.fireEvent("TileData_Initialized", {success = success})
    end
    
    print("TileDataInitializer: Initialization " .. (success and "successful" or "failed"))
    
    -- Create global function for use in Command Bar
    _G.GenerateBuyTileConfig = function()
        local result = initializeTileData()
        print("GenerateBuyTileConfig: " .. (result and "Success" or "Failed"))
        return result
    end
    
    _G.AutoSetupBuyTiles = function()
        local result = initializeTileData()
        print("AutoSetupBuyTiles: " .. (result and "Success" or "Failed"))
        return result
    end
    
    return success
end

-- Run initialization
initialize()
