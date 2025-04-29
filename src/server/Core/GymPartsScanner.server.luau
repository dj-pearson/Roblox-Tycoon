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
]]

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

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
        warn("GymPartsScanner: Failed to require " .. moduleInstance:GetFullName() .. " - " .. tostring(result))
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

-- Configuration
local GYM_PARTS_FOLDER_NAME = "GymParts"
local DEFAULT_COSTS = {
    [1] = 500, -- Floor 1 base cost
    [2] = 1500, -- Floor 2 base cost
    [3] = 3500, -- Floor 3 base cost
    [4] = 7500, -- Floor 4 base cost
    [5] = 15000 -- Floor 5 base cost
}

local ROOM_MULTIPLIERS = {
    ["FrontDesk"] = 1.0,
    ["Entrance"] = 1.2,
    ["Cardio"] = 1.5,
    ["Strength"] = 1.8,
    ["Lockers"] = 2.0,
    ["Specialty"] = 2.5,
    ["VIP"] = 3.0
}

local ROOM_PRIORITIES = {
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

-- Extract floor number from folder name (e.g., "Floor 1" -> 1)
local function extractFloorNumber(floorName)
    local number = floorName:match("(%d+)")
    return number and tonumber(number) or 1
end

-- Get base cost for a floor
local function getBaseCost(floorNumber)
    return DEFAULT_COSTS[floorNumber] or (DEFAULT_COSTS[5] * math.ceil(floorNumber / 5))
end

-- Get cost multiplier for a room type
local function getRoomMultiplier(roomType)
    return ROOM_MULTIPLIERS[roomType] or 1.0
end

-- Get room priority (lower number = higher priority)
local function getRoomPriority(roomType)
    return ROOM_PRIORITIES[roomType] or 99
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

-- Scan the GymParts folder and collect structure information
local function scanGymPartsStructure()
    print("GymPartsScanner: Starting scan of GymParts folder")
    
    local gymPartsFolder = ServerStorage:FindFirstChild(GYM_PARTS_FOLDER_NAME)
    if not gymPartsFolder then
        gymPartsFolder = Instance.new("Folder")
        gymPartsFolder.Name = GYM_PARTS_FOLDER_NAME
        gymPartsFolder.Parent = ServerStorage
        warn("GymPartsScanner: Created GymParts folder as it didn't exist")
        return {}
    end
    
    local structureData = {}
    local idCounter = 1
    
    -- Check if we have a FrontDesk folder or item first (special case)
    local frontDesk = gymPartsFolder:FindFirstChild("FrontDesk")
    if frontDesk then
        print("GymPartsScanner: Found FrontDesk in root")
        
        -- Process front desk as a special case
        if frontDesk:IsA("Model") or frontDesk:IsA("Part") then
            -- Single front desk item
            structureData[#structureData + 1] = {
                id = "FrontDesk",
                name = "Front Desk",
                path = "FrontDesk",
                floorNumber = 1,
                floorName = "1st Floor",
                roomType = "FrontDesk",
                equipmentType = "FrontDesk",
                cost = getBaseCost(1),
                priority = 1,
                idAttribute = 1, -- Special ID for front desk
                instance = frontDesk
            }
        else
            -- Folder of front desk items
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
                        idAttribute = 1, -- Special ID for front desk
                        instance = item
                    }
                end
            end
        end
    end
    
    -- Scan floor folders
    for _, floorFolder in ipairs(gymPartsFolder:GetChildren()) do
        -- Skip non-folders and FrontDesk (already handled)
        if not floorFolder:IsA("Folder") or floorFolder.Name == "FrontDesk" then
            continue
        end
        
        -- Check if it's a floor folder (contains "Floor" in name)
        local isFloorFolder = floorFolder.Name:match("Floor")
        if not isFloorFolder then
            -- Process as a room directly
            processRoomFolder(floorFolder, 1, "1st Floor", structureData)
            continue
        end
        
        local floorNumber = extractFloorNumber(floorFolder.Name)
        local floorName = ordinalizeFloor(floorNumber) .. " Floor"
        print("GymPartsScanner: Processing " .. floorName)
        
        -- Process walls first if they exist
        local wallsFolder = floorFolder:FindFirstChild("Walls")
        if wallsFolder then
            for i, wall in ipairs(wallsFolder:GetChildren()) do
                if wall:IsA("Model") or wall:IsA("Part") then
                    idCounter = idCounter + 1
                    structureData[#structureData + 1] = {
                        id = "Wall_" .. floorNumber .. "_" .. i,
                        name = "Wall Section " .. i .. " - " .. floorName,
                        path = floorFolder.Name .. "/Walls/" .. wall.Name,
                        floorNumber = floorNumber,
                        floorName = floorName,
                        roomType = "Walls",
                        equipmentType = "Wall",
                        cost = getBaseCost(floorNumber) * 0.8, -- Walls are slightly cheaper
                        priority = getRoomPriority("Walls"),
                        idAttribute = idCounter,
                        instance = wall
                    }
                end
            end
        end
        
        -- Process room folders
        for _, roomFolder in ipairs(floorFolder:GetChildren()) do
            if roomFolder:IsA("Folder") and roomFolder.Name ~= "Walls" and roomFolder.Name ~= "Ceiling" and roomFolder.Name ~= "Stairs" then
                processRoomFolder(roomFolder, floorNumber, floorName, structureData, idCounter)
                idCounter = idCounter + #roomFolder:GetDescendants()
            end
        end
        
        -- Process ceiling after rooms
        local ceilingFolder = floorFolder:FindFirstChild("Ceiling")
        if ceilingFolder then
            for i, ceiling in ipairs(ceilingFolder:GetChildren()) do
                if ceiling:IsA("Model") or ceiling:IsA("Part") then
                    idCounter = idCounter + 1
                    structureData[#structureData + 1] = {
                        id = "Ceiling_" .. floorNumber .. "_" .. i,
                        name = "Ceiling Section " .. i .. " - " .. floorName,
                        path = floorFolder.Name .. "/Ceiling/" .. ceiling.Name,
                        floorNumber = floorNumber,
                        floorName = floorName,
                        roomType = "Ceiling",
                        equipmentType = "Ceiling",
                        cost = getBaseCost(floorNumber) * 0.9, -- Ceilings are slightly cheaper
                        priority = getRoomPriority("Ceiling"),
                        idAttribute = idCounter,
                        instance = ceiling
                    }
                end
            end
        end
        
        -- Process stairs last
        local stairsFolder = floorFolder:FindFirstChild("Stairs")
        if stairsFolder then
            for i, stairs in ipairs(stairsFolder:GetChildren()) do
                if stairs:IsA("Model") or stairs:IsA("Part") then
                    idCounter = idCounter + 1
                    structureData[#structureData + 1] = {
                        id = "Stairs_" .. floorNumber,
                        name = "Stairs to " .. ordinalizeFloor(floorNumber + 1) .. " Floor",
                        path = floorFolder.Name .. "/Stairs/" .. stairs.Name,
                        floorNumber = floorNumber,
                        floorName = floorName,
                        roomType = "Stairs",
                        equipmentType = "Stairs",
                        cost = getBaseCost(floorNumber) * 2.5, -- Stairs are expensive
                        priority = getRoomPriority("Stairs"),
                        idAttribute = idCounter,
                        instance = stairs
                    }
                end
            end
        end
    end
    
    print("GymPartsScanner: Found " .. #structureData .. " items in GymParts structure")
    return structureData
end

-- Process a room folder and its contents
function processRoomFolder(roomFolder, floorNumber, floorName, structureData, startIdCounter)
    local idCounter = startIdCounter or 100 -- Start with a high number if not provided
    local roomType = roomFolder.Name
    local roomPriority = getRoomPriority(roomType)
    local roomMultiplier = getRoomMultiplier(roomType)
    local baseCost = getBaseCost(floorNumber)
    
    print("GymPartsScanner: Processing room " .. roomType .. " on " .. floorName)
    
    -- Check if folder contains direct equipment or has subfolders
    local hasSubfolders = false
    for _, child in ipairs(roomFolder:GetChildren()) do
        if child:IsA("Folder") then
            hasSubfolders = true
            break
        end
    end
    
    if hasSubfolders then
        -- Process each equipment type subfolder
        for _, equipFolder in ipairs(roomFolder:GetChildren()) do
            if equipFolder:IsA("Folder") then
                local equipType = equipFolder.Name
                
                -- Process equipment in this folder
                for i, equip in ipairs(equipFolder:GetChildren()) do
                    if equip:IsA("Model") or equip:IsA("Part") then
                        idCounter = idCounter + 1
                        
                        -- Determine cost based on floor, room and size
                        local size = 1
                        if equip:IsA("Model") and equip.PrimaryPart then
                            size = math.max(1, equip.PrimaryPart.Size.X * equip.PrimaryPart.Size.Z / 16)
                        elseif equip:IsA("Part") then
                            size = math.max(1, equip.Size.X * equip.Size.Z / 16)
                        end
                        
                        local cost = baseCost * roomMultiplier * math.max(0.5, size * 0.8)
                        
                        structureData[#structureData + 1] = {
                            id = roomType .. "_" .. equipType .. "_" .. idCounter,
                            name = equipType .. " " .. i .. " - " .. roomType .. " - " .. floorName,
                            path = roomFolder.Parent.Name .. "/" .. roomType .. "/" .. equipType .. "/" .. equip.Name,
                            floorNumber = floorNumber,
                            floorName = floorName,
                            roomType = roomType,
                            equipmentType = equipType,
                            cost = math.floor(cost),
                            priority = roomPriority,
                            idAttribute = idCounter,
                            instance = equip
                        }
                    end
                end
            end
        end
    else
        -- Process equipment directly in room folder
        for i, equip in ipairs(roomFolder:GetChildren()) do
            if equip:IsA("Model") or equip:IsA("Part") then
                idCounter = idCounter + 1
                
                -- Determine cost based on floor and room
                local cost = baseCost * roomMultiplier
                
                structureData[#structureData + 1] = {
                    id = roomType .. "_" .. equip.Name .. "_" .. idCounter,
                    name = equip.Name .. " - " .. roomType .. " - " .. floorName,
                    path = roomFolder.Parent.Name .. "/" .. roomType .. "/" .. equip.Name,
                    floorNumber = floorNumber,
                    floorName = floorName,
                    roomType = roomType,
                    equipmentType = equip.Name,
                    cost = math.floor(cost),
                    priority = roomPriority,
                    idAttribute = idCounter,
                    instance = equip
                }
            end
        end
    end
end

-- Apply tags and attributes to the gym parts
local function applyTagsAndAttributes(structureData)
    print("GymPartsScanner: Applying tags and attributes to " .. #structureData .. " items")
    
    -- First, remove any existing BuyTile tags to avoid duplicates
    for _, item in ipairs(CollectionService:GetTagged("BuyTile")) do
        CollectionService:RemoveTag(item, "BuyTile")
    end
    for _, item in ipairs(CollectionService:GetTagged("GymPart")) do
        CollectionService:RemoveTag(item, "GymPart")
    end
    
    for _, data in ipairs(structureData) do
        local instance = data.instance
        if instance then
            -- Add tags
            CollectionService:AddTag(instance, "GymPart")
            CollectionService:AddTag(instance, "BuyTile")
            
            -- Add specific tags for easier filtering
            CollectionService:AddTag(instance, "Floor_" .. data.floorNumber)
            CollectionService:AddTag(instance, "Room_" .. data.roomType)
            
            if data.equipmentType then
                CollectionService:AddTag(instance, "Equipment_" .. data.equipmentType)
            end
            
            -- Add specific tag for front desk
            if data.idAttribute == 1 then
                CollectionService:AddTag(instance, "FrontDesk")
            end
            
            -- Add attributes
            instance:SetAttribute("BuyTileId", data.id)
            instance:SetAttribute("TileFloor", data.floorNumber)
            instance:SetAttribute("TileRoom", data.roomType)
            instance:SetAttribute("TileEquipment", data.equipmentType)
            instance:SetAttribute("TileCost", data.cost)
            instance:SetAttribute("TilePriority", data.priority)
            instance:SetAttribute("TileIdAttribute", data.idAttribute)
            instance:SetAttribute("TileName", data.name)
            instance:SetAttribute("TilePath", data.path)
            
            print("Applied attributes to: " .. data.path)
        end
    end
    
    print("GymPartsScanner: Successfully applied tags and attributes to all gym parts")
    return true
end

-- Generate BuyTile system configuration data
local function generateBuyTileConfig(structureData)
    print("GymPartsScanner: Generating BuyTile configuration data")
    
    if not BuyTileSystem then
        warn("GymPartsScanner: BuyTileSystem not available, cannot generate config")
        return false
    end
    
    local tileData = {}
    
    for _, data in ipairs(structureData) do
        -- Use the ID as the tile ID
        local tileId = data.id
        
        -- Generate prerequisites based on progression order
        local prerequisites = {}
        
        -- Front desk has no prerequisites
        if data.idAttribute == 1 then
            prerequisites = {}
        elseif data.roomType == "Walls" then
            -- Walls on higher floors require stairs from previous floor
            if data.floorNumber > 1 then
                table.insert(prerequisites, "Stairs_" .. (data.floorNumber - 1))
            else
                -- First floor walls require front desk
                table.insert(prerequisites, "FrontDesk")
            end
        elseif data.roomType == "Ceiling" then
            -- Ceiling requires walls on same floor
            for _, otherData in ipairs(structureData) do
                if otherData.floorNumber == data.floorNumber and otherData.roomType == "Walls" then
                    table.insert(prerequisites, otherData.id)
                    break
                end
            end
        elseif data.roomType == "Stairs" then
            -- Stairs require ceiling on same floor
            for _, otherData in ipairs(structureData) do
                if otherData.floorNumber == data.floorNumber and otherData.roomType == "Ceiling" then
                    table.insert(prerequisites, otherData.id)
                    break
                end
            end
        else
            -- Regular equipment requires walls on same floor
            for _, otherData in ipairs(structureData) do
                if otherData.floorNumber == data.floorNumber and otherData.roomType == "Walls" then
                    table.insert(prerequisites, otherData.id)
                    break
                end
            end
        end
        
        -- Create tile data entry
        tileData[tileId] = {
            cost = data.cost,
            requiredLevel = math.max(1, data.floorNumber - 1), -- Higher floors need higher level
            gymPartId = data.instance.Name,
            category = data.roomType,
            structureType = data.roomType == "Walls" and "Walls" or 
                            data.roomType == "Ceiling" and "Ceiling" or
                            data.roomType == "Stairs" and "Stairs" or
                            data.idAttribute == 1 and "FrontDesk" or "Equipment",
            description = data.name,
            unlockMessage = "You've unlocked " .. data.name .. "!",
            order = data.idAttribute,
            isRequired = (data.roomType == "Walls" or 
                          data.roomType == "Ceiling" or 
                          data.roomType == "Stairs" or 
                          data.idAttribute == 1),
            floor = data.floorNumber,
            room = data.roomType,
            equipmentType = data.equipmentType,
            prerequisites = prerequisites,
            idAttribute = data.idAttribute
        }
    end
    
    -- Set the tile data in BuyTileSystem
    if BuyTileSystem.setTileData then
        local success = BuyTileSystem.setTileData(tileData)
        if success then
            print("GymPartsScanner: Successfully set tile data in BuyTileSystem")
            
            -- Refresh the ordering if available
            if BuyTileSystem.refreshOrderedTiles then
                BuyTileSystem.refreshOrderedTiles()
            end
        else
            warn("GymPartsScanner: Failed to set tile data in BuyTileSystem")
        end
        return success
    else
        warn("GymPartsScanner: BuyTileSystem.setTileData method not found")
        return false
    end
end

-- Main function to run the entire process
local function setupBuyTileSystem()
    print("GymPartsScanner: Starting BuyTile system setup from GymParts folder")
    
    -- Scan the structure
    local structureData = scanGymPartsStructure()
    if #structureData == 0 then
        warn("GymPartsScanner: No items found in GymParts folder")
        return false
    end
    
    -- Apply tags and attributes
    local tagsApplied = applyTagsAndAttributes(structureData)
    if not tagsApplied then
        warn("GymPartsScanner: Failed to apply tags and attributes")
        return false
    end
    
    -- Generate BuyTile configuration
    local configGenerated = generateBuyTileConfig(structureData)
    if not configGenerated then
        warn("GymPartsScanner: Failed to generate BuyTile configuration")
        return false
    end
    
    print("GymPartsScanner: BuyTile system setup complete!")
    print("Found and configured " .. #structureData .. " items across all floors")
    
    return true
end

-- Register with EventBridge if available
if EventBridge.registerEvent then
    EventBridge.registerEvent("GymPartsScanner_SetupComplete")
end

-- Create global function for command bar access
_G.ScanGymPartsStructure = function()
    local structureData = scanGymPartsStructure()
    print("Found " .. #structureData .. " items in GymParts structure")
    return structureData
end

_G.SetupBuyTileSystem = function()
    local success = setupBuyTileSystem()
    if success and EventBridge.fireEvent then
        EventBridge.fireEvent("GymPartsScanner_SetupComplete", {
            success = true
        })
    end
    return success
end

-- Register command if CommandService is available
local CommandService = CoreRegistry and CoreRegistry:GetSystem("CommandService")
if CommandService then
    CommandService:RegisterCommand("setupBuyTiles", {
        description = "Sets up the BuyTile system using the GymParts folder structure",
        handler = function(player)
            -- Check if player is admin
            local AdminService = CoreRegistry:GetSystem("AdminService")
            if AdminService and not AdminService:IsAdmin(player) then
                return "You don't have permission to use this command"
            end
            
            local success = setupBuyTileSystem()
            return success 
                and "Successfully set up BuyTile system from GymParts folder structure" 
                or "Failed to set up BuyTile system"
        end
    })
end

-- Run the setup
setupBuyTileSystem()

return {
    scanGymPartsStructure = scanGymPartsStructure,
    applyTagsAndAttributes = applyTagsAndAttributes,
    generateBuyTileConfig = generateBuyTileConfig,
    setupBuyTileSystem = setupBuyTileSystem
}
