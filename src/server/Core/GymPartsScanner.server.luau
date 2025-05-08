--!strict
--[[
    GymPartsScanner.server.luau
    
    This automation script scans the GymParts folder structure and automatically applies
    the appropriate tags and attributes needed for the BuyTile system.
    
    Structure expected:
    - GymParts/
      - Floor 1/
        - Cardio/
          - Treadmills/
            (equipment models)
          - Bikes/
            (equipment models)
        - Strength/
          - Weights/
            (equipment models)
      - Floor 2/
        ...etc
    
    Created April 28, 2025
    Updated May 2025 - Simplified integration with CoreRegistry
]]

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Direct imports from Core
local CoreRegistry = require(script.Parent.CoreRegistry)
local BuyTileSystem = require(script.Parent.BuyTileSystem)
local EventBridge = require(script.Parent.EventBridge)

-- Module definition
local GymPartsScanner = {
    Version = "2.0.0",
    Debug = false
}

-- Configuration
local CONFIG = {
    GYM_PARTS_FOLDER_NAME = "GymParts",
    DEFAULT_COSTS = {
        [1] = 500,   -- Floor 1 base cost
        [2] = 1500,  -- Floor 2 base cost
        [3] = 3500,  -- Floor 3 base cost
        [4] = 7500,  -- Floor 4 base cost
        [5] = 15000  -- Floor 5 base cost
    },
    ROOM_MULTIPLIERS = {
        ["FrontDesk"] = 1.0,
        ["Entrance"] = 1.2,
        ["Cardio"] = 1.5,
        ["Strength"] = 1.8,
        ["Lockers"] = 2.0,
        ["Specialty"] = 2.5,
        ["VIP"] = 3.0
    },
    ROOM_PRIORITIES = {
        ["FrontDesk"] = 1,
        ["Entrance"] = 2,
        ["Walls"] = 3,
        ["Cardio"] = 4,
        ["Strength"] = 5,
        ["Lockers"] = 6,
        ["Specialty"] = 7,
        ["Ceiling"] = 8,
        ["Stairs"] = 9
    }
}

-- Debug logging
local function log(message, level)
    if not GymPartsScanner.Debug and level == "DEBUG" then
        return
    end
    
    level = level or "INFO"
    local timestamp = os.date("%H:%M:%S")
    print(string.format("[GymPartsScanner %s %s] %s", timestamp, level, message))
end

-- Extract floor number from folder name (e.g., "Floor 1" -> 1)
local function extractFloorNumber(floorName)
    local number = floorName:match("(%d+)")
    return number and tonumber(number) or 1
end

-- Get base cost for a floor
local function getBaseCost(floorNumber)
    return CONFIG.DEFAULT_COSTS[floorNumber] or (CONFIG.DEFAULT_COSTS[5] * math.ceil(floorNumber / 5))
end

-- Get cost multiplier for a room type
local function getRoomMultiplier(roomType)
    return CONFIG.ROOM_MULTIPLIERS[roomType] or 1.0
end

-- Get room priority (lower number = higher priority)
local function getRoomPriority(roomType)
    return CONFIG.ROOM_PRIORITIES[roomType] or 99
end

-- Map floor name to ordinalized string (1 -> "1st", 2 -> "2nd", etc.)
local function ordinalizeFloor(floorNumber)
    local suffix
    if floorNumber % 100 >= 11 and floorNumber % 100 <= 13 then
        suffix = "th"
    else
        local lastDigit = floorNumber % 10
        if lastDigit == 1 then suffix = "st"
        elseif lastDigit == 2 then suffix = "nd"
        elseif lastDigit == 3 then suffix = "rd"
        else suffix = "th"
        end
    end
    return tostring(floorNumber) .. suffix
end

-- Process a room folder and its equipment
local function processRoomFolder(roomFolder, floorNumber, floorName, structureData, idCounter)
    local roomType = roomFolder.Name
    local roomMultiplier = getRoomMultiplier(roomType)
    local baseCost = getBaseCost(floorNumber)
    
    -- Process equipment in the room
    for _, equipment in ipairs(roomFolder:GetDescendants()) do
        if equipment:IsA("Model") or equipment:IsA("Part") then
            idCounter = (idCounter or 0) + 1
            
            -- Calculate unique ID and cost
            local id = string.format("%s_%d_%s_%d", 
                roomType,
                floorNumber,
                equipment.Name:gsub("%s+", "_"),
                idCounter
            )
            
            local cost = math.floor(baseCost * roomMultiplier)
            
            -- Create structure data entry
            structureData[#structureData + 1] = {
                id = id,
                name = string.format("%s - %s (%s)", 
                    equipment.Name,
                    roomType,
                    floorName
                ),
                path = string.format("%s/%s/%s",
                    "Floor " .. floorNumber,
                    roomType,
                    equipment.Name
                ),
                floorNumber = floorNumber,
                floorName = floorName,
                roomType = roomType,
                equipmentType = equipment.Name,
                cost = cost,
                priority = getRoomPriority(roomType),
                idAttribute = idCounter,
                instance = equipment
            }
        end
    end
    
    return idCounter
end

-- Scan the GymParts folder and collect structure information
function GymPartsScanner:ScanGymPartsStructure()
    log("Starting scan of GymParts folder")
    
    local gymPartsFolder = ServerStorage:FindFirstChild(CONFIG.GYM_PARTS_FOLDER_NAME)
    if not gymPartsFolder then
        gymPartsFolder = Instance.new("Folder")
        gymPartsFolder.Name = CONFIG.GYM_PARTS_FOLDER_NAME
        gymPartsFolder.Parent = ServerStorage
        warn("Created GymParts folder as it didn't exist")
        return {}
    end
    
    local structureData = {}
    local idCounter = 1
    
    -- Process front desk first (special case)
    local frontDesk = gymPartsFolder:FindFirstChild("FrontDesk")
    if frontDesk then
        log("Found FrontDesk in root")
        if frontDesk:IsA("Model") or frontDesk:IsA("Part") then
            structureData[1] = {
                id = "FrontDesk",
                name = "Front Desk",
                path = "FrontDesk",
                floorNumber = 1,
                floorName = "1st Floor",
                roomType = "FrontDesk",
                equipmentType = "FrontDesk",
                cost = getBaseCost(1),
                priority = 1,
                idAttribute = 1,
                instance = frontDesk
            }
        else
            for _, item in ipairs(frontDesk:GetChildren()) do
                if item:IsA("Model") or item:IsA("Part") then
                    structureData[#structureData + 1] = {
                        id = "FrontDesk_" .. item.Name,
                        name = "Front Desk - " .. item.Name,
                        path = "FrontDesk/" .. item.Name,
                        floorNumber = 1,
                        floorName = "1st Floor",
                        roomType = "FrontDesk",
                        equipmentType = "FrontDesk",
                        cost = getBaseCost(1),
                        priority = 1,
                        idAttribute = idCounter,
                        instance = item
                    }
                    idCounter = idCounter + 1
                end
            end
        end
    end
    
    -- Process floor folders
    for _, floorFolder in ipairs(gymPartsFolder:GetChildren()) do
        if not floorFolder:IsA("Folder") or floorFolder.Name == "FrontDesk" then
            continue
        end
        
        local isFloorFolder = floorFolder.Name:match("Floor")
        if not isFloorFolder then
            idCounter = processRoomFolder(floorFolder, 1, "1st Floor", structureData, idCounter)
            continue
        end
        
        local floorNumber = extractFloorNumber(floorFolder.Name)
        local floorName = ordinalizeFloor(floorNumber) .. " Floor"
        log("Processing " .. floorName)
        
        -- Process walls first
        local wallsFolder = floorFolder:FindFirstChild("Walls")
        if wallsFolder then
            for i, wall in ipairs(wallsFolder:GetChildren()) do
                if wall:IsA("Model") or wall:IsA("Part") then
                    structureData[#structureData + 1] = {
                        id = "Wall_" .. floorNumber .. "_" .. i,
                        name = "Wall Section " .. i .. " - " .. floorName,
                        path = floorFolder.Name .. "/Walls/" .. wall.Name,
                        floorNumber = floorNumber,
                        floorName = floorName,
                        roomType = "Walls",
                        equipmentType = "Wall",
                        cost = math.floor(getBaseCost(floorNumber) * 0.8),
                        priority = getRoomPriority("Walls"),
                        idAttribute = idCounter,
                        instance = wall
                    }
                    idCounter = idCounter + 1
                end
            end
        end
        
        -- Process room folders
        for _, roomFolder in ipairs(floorFolder:GetChildren()) do
            if roomFolder:IsA("Folder") and roomFolder.Name ~= "Walls" and 
               roomFolder.Name ~= "Ceiling" and roomFolder.Name ~= "Stairs" then
                idCounter = processRoomFolder(roomFolder, floorNumber, floorName, structureData, idCounter)
            end
        end
    end
    
    log("Scan complete - Found " .. #structureData .. " items")
    return structureData
end

-- Set up BuyTileSystem with scanned data
function GymPartsScanner:SetupBuyTileSystem()
    if not BuyTileSystem then
        log("BuyTileSystem not found", "ERROR")
        return false
    end
    
    log("Setting up BuyTileSystem with scanned data")
    
    -- Scan for structure data
    local structureData = self:ScanGymPartsStructure()
    if #structureData == 0 then
        log("No structure data found", "ERROR")
        return false
    end
    
    -- Register tiles with BuyTileSystem
    local registeredCount = 0
    for _, itemData in ipairs(structureData) do
        -- Create tile info
        local tileInfo = {
            id = itemData.id,
            name = itemData.name,
            cost = itemData.cost,
            requiredLevel = math.max(1, math.floor(itemData.floorNumber * 0.7)),
            equipmentId = itemData.id,
            priority = itemData.priority,
            metadata = {
                floorNumber = itemData.floorNumber,
                floorName = itemData.floorName,
                roomType = itemData.roomType,
                equipmentType = itemData.equipmentType,
                path = itemData.path
            }
        }
        
        -- Register the tile
        if BuyTileSystem:RegisterTile(tileInfo) then
            registeredCount = registeredCount + 1
            
            -- Tag the instance for easy finding
            CollectionService:AddTag(itemData.instance, "BuyableTile")
            itemData.instance:SetAttribute("TileId", itemData.id)
        end
    end
    
    log("Successfully registered " .. registeredCount .. " tiles")
    
    -- Notify of completion
    EventBridge:FireEvent("GymPartsScanner_SetupComplete", {
        success = true,
        tilesRegistered = registeredCount,
        timestamp = os.time()
    })
    
    return true
end

-- Register with CoreRegistry
if CoreRegistry then
    CoreRegistry:RegisterSystem("GymPartsScanner", GymPartsScanner)
end

return GymPartsScanner
