--!strict
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
    Updated May 2025 - Simplified integration with CoreRegistry
]]

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Direct imports from Core
local CoreRegistry = require(script.Parent.CoreRegistry)
local BuyTileSystem = require(script.Parent.BuyTileSystem)
local EventBridge = require(script.Parent.EventBridge)

-- Module definition
local TileDataInitializer = {
    Version = "2.0.0",
    Debug = false
}

-- Configuration
local CONFIG = {
    ROOM_FOLDER_NAME = "Rooms",
    GYM_PARTS_FOLDER_NAME = "GymParts",
    FLOOR_ATTRIBUTES = {"1st_Floor", "2nd_Floor", "3rd_Floor", "4th_Floor", "5th_Floor"},
    COSTS = {
        FRONT_DESK = 500,
        WALL_BASE = 1000,
        EQUIPMENT_BASE = 2000,
        CEILING_BASE = 1500,
        STAIRS_BASE = 5000
    }
}

-- Debug logging
local function log(message, level)
    if not TileDataInitializer.Debug and level == "DEBUG" then
        return
    end
    
    level = level or "INFO"
    local timestamp = os.date("%H:%M:%S")
    print(string.format("[TileDataInitializer %s %s] %s", timestamp, level, message))
end

-- Initialize tile data from gym structure
function TileDataInitializer:InitializeTileData()
    if not BuyTileSystem then
        log("BuyTileSystem not found", "ERROR")
        return false
    end
    
    log("Initializing tile data from gym structure")
    
    -- Get gym structure folder
    local gymStructure = ServerStorage:FindFirstChild("GymStructure")
    if not gymStructure then
        log("GymStructure folder not found in ServerStorage", "ERROR")
        return false
    end
    
    -- Process front desk first
    local frontDesk = gymStructure:FindFirstChild("FrontDesk")
    if frontDesk then
        local tileInfo = {
            id = "FrontDesk",
            name = "Front Desk",
            cost = CONFIG.COSTS.FRONT_DESK,
            requiredLevel = 1,
            equipmentId = "FrontDesk",
            priority = 1,
            metadata = {
                floorNumber = 1,
                floorName = "1st Floor",
                roomType = "FrontDesk",
                equipmentType = "FrontDesk",
                path = "FrontDesk"
            }
        }
        
        if not BuyTileSystem:RegisterTile(tileInfo) then
            log("Failed to register front desk tile", "ERROR")
            return false
        end
    end
    
    -- Process each floor
    for floorIndex, floorAttr in ipairs(CONFIG.FLOOR_ATTRIBUTES) do
        local floorFolder = gymStructure:FindFirstChild(floorAttr)
        if not floorFolder then continue end
        
        local floorName = string.format("%s Floor", floorAttr)
        
        -- Process walls first
        if not self:ProcessWalls(floorFolder, floorIndex, floorName) then
            log("Failed to process walls for " .. floorName, "ERROR")
            continue
        end
        
        -- Process room contents
        if not self:ProcessRooms(floorFolder, floorIndex, floorName) then
            log("Failed to process rooms for " .. floorName, "ERROR")
            continue
        end
        
        -- Process ceiling
        if not self:ProcessCeiling(floorFolder, floorIndex, floorName) then
            log("Failed to process ceiling for " .. floorName, "ERROR")
            continue
        end
        
        -- Process stairs (if not last floor)
        if floorIndex < #CONFIG.FLOOR_ATTRIBUTES then
            if not self:ProcessStairs(floorFolder, floorIndex, floorName) then
                log("Failed to process stairs for " .. floorName, "ERROR")
                continue
            end
        end
    end
    
    log("Tile data initialization complete")
    
    -- Notify of completion
    EventBridge:FireEvent("TileDataInitializer_Complete", {
        success = true,
        timestamp = os.time()
    })
    
    return true
end

-- Process walls for a floor
function TileDataInitializer:ProcessWalls(floorFolder, floorIndex, floorName)
    local wallsFolder = floorFolder:FindFirstChild("Walls")
    if not wallsFolder then return true end
    
    for i, wall in ipairs(wallsFolder:GetChildren()) do
        if not wall:IsA("Model") and not wall:IsA("Part") then continue end
        
        local tileInfo = {
            id = string.format("Wall_%d_%d", floorIndex, i),
            name = string.format("Wall Section %d - %s", i, floorName),
            cost = CONFIG.COSTS.WALL_BASE * floorIndex,
            requiredLevel = math.max(1, floorIndex - 1),
            equipmentId = wall.Name,
            priority = 2,
            metadata = {
                floorNumber = floorIndex,
                floorName = floorName,
                roomType = "Walls",
                equipmentType = "Wall",
                path = string.format("%s/Walls/%s", floorName, wall.Name)
            }
        }
        
        if not BuyTileSystem:RegisterTile(tileInfo) then
            log("Failed to register wall tile: " .. tileInfo.id, "ERROR")
            return false
        end
    end
    
    return true
end

-- Process rooms for a floor
function TileDataInitializer:ProcessRooms(floorFolder, floorIndex, floorName)
    local roomsFolder = floorFolder:FindFirstChild(CONFIG.ROOM_FOLDER_NAME)
    if not roomsFolder then return true end
    
    for _, room in ipairs(roomsFolder:GetChildren()) do
        local roomName = room.Name
        
        for _, equipment in ipairs(room:GetChildren()) do
            if not equipment:IsA("Model") and not equipment:IsA("Part") then continue end
            
            local tileInfo = {
                id = string.format("%s_%s_%d", roomName, equipment.Name, floorIndex),
                name = string.format("%s - %s (%s)", equipment.Name, roomName, floorName),
                cost = CONFIG.COSTS.EQUIPMENT_BASE * floorIndex,
                requiredLevel = math.max(1, floorIndex),
                equipmentId = equipment.Name,
                priority = 3,
                metadata = {
                    floorNumber = floorIndex,
                    floorName = floorName,
                    roomType = roomName,
                    equipmentType = equipment.Name,
                    path = string.format("%s/%s/%s/%s", 
                        floorName, 
                        CONFIG.ROOM_FOLDER_NAME,
                        roomName,
                        equipment.Name
                    )
                }
            }
            
            if not BuyTileSystem:RegisterTile(tileInfo) then
                log("Failed to register equipment tile: " .. tileInfo.id, "ERROR")
                return false
            end
        end
    end
    
    return true
end

-- Process ceiling for a floor
function TileDataInitializer:ProcessCeiling(floorFolder, floorIndex, floorName)
    local ceilingFolder = floorFolder:FindFirstChild("Ceiling")
    if not ceilingFolder then return true end
    
    for i, ceiling in ipairs(ceilingFolder:GetChildren()) do
        if not ceiling:IsA("Model") and not ceiling:IsA("Part") then continue end
        
        local tileInfo = {
            id = string.format("Ceiling_%d_%d", floorIndex, i),
            name = string.format("Ceiling Section %d - %s", i, floorName),
            cost = CONFIG.COSTS.CEILING_BASE * floorIndex,
            requiredLevel = math.max(1, floorIndex),
            equipmentId = ceiling.Name,
            priority = 4,
            metadata = {
                floorNumber = floorIndex,
                floorName = floorName,
                roomType = "Ceiling",
                equipmentType = "Ceiling",
                path = string.format("%s/Ceiling/%s", floorName, ceiling.Name)
            }
        }
        
        if not BuyTileSystem:RegisterTile(tileInfo) then
            log("Failed to register ceiling tile: " .. tileInfo.id, "ERROR")
            return false
        end
    end
    
    return true
end

-- Process stairs for a floor
function TileDataInitializer:ProcessStairs(floorFolder, floorIndex, floorName)
    local stairsFolder = floorFolder:FindFirstChild("Stairs")
    if not stairsFolder then return true end
    
    for _, stairs in ipairs(stairsFolder:GetChildren()) do
        if not stairs:IsA("Model") and not stairs:IsA("Part") then continue end
        
        local tileInfo = {
            id = string.format("Stairs_%d", floorIndex),
            name = string.format("Stairs to Floor %d", floorIndex + 1),
            cost = CONFIG.COSTS.STAIRS_BASE * floorIndex,
            requiredLevel = math.max(1, floorIndex),
            equipmentId = stairs.Name,
            priority = 5,
            metadata = {
                floorNumber = floorIndex,
                floorName = floorName,
                roomType = "Stairs",
                equipmentType = "Stairs",
                path = string.format("%s/Stairs/%s", floorName, stairs.Name),
                unlockNextFloor = true
            }
        }
        
        if not BuyTileSystem:RegisterTile(tileInfo) then
            log("Failed to register stairs tile: " .. tileInfo.id, "ERROR")
            return false
        end
    end
    
    return true
end

-- Register with CoreRegistry
if CoreRegistry then
    CoreRegistry:RegisterSystem("TileDataInitializer", TileDataInitializer)
end

return TileDataInitializer
