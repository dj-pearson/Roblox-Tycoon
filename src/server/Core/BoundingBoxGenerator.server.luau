--[[
    BoundingBoxGenerator.server.luau
    
    ===== DEPRECATION NOTICE =====
    This script has been deprecated and is scheduled for removal.
    It has been consolidated into the new BoundingBoxManager.server.luau module.
    Please use BoundingBoxManager:GenerateHitboxes() instead of functionality from this script.
    See ConsolidationPlan.md for details on the module consolidation project.
    ===== END NOTICE =====
    
    Automatically creates and positions bounding boxes for equipment placement.
    Analyzes GymParts folder structure and floor layouts to determine logical
    placement zones for different types of equipment.
    
    Features:
    - Scans floor layouts to identify usable placement areas
    - Creates visual bounding boxes for equipment placement
    - Applies intelligent spacing rules based on equipment categories
    - Integrates with the modular BuyTile system for better placement guidance
    - Auto-detects wall orientations for equipment that needs wall placement
    
    Part of the consolidated modular system including:
    - FloorAttributeSetup - Floor and room structure management
    - BuyTileProgressionManager - Build order and prerequisites
    - TileDataGenerator - Attribute and data generation
    
    Author: Created April 2025
    Updated: April 21, 2025
]]

local Workspace = game:GetService("Workspace")
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

-- Get system references from our modular framework
local BuyTileSystem = CoreRegistry and CoreRegistry:GetSystem("BuyTileSystem")
local FloorAttributeSetup = CoreRegistry and CoreRegistry:GetSystem("FloorAttributeSetup")
local TileDataGenerator = CoreRegistry and CoreRegistry:GetSystem("TileDataGenerator")
local BuyTileProgressionManager = CoreRegistry and CoreRegistry:GetSystem("BuyTileProgressionManager")

-- Constants
local CATEGORIES = {
    STRUCTURE = "Structure",
    CARDIO = "Cardio Equipment",
    STRENGTH = "Strength Equipment",
    AMENITIES = "Amenities",
    SPECIALTY = "Specialty Equipment",
    STAFF = "Staff Areas"
}

-- Equipment spacing requirements
local SPACING_REQUIREMENTS = {
    [CATEGORIES.STRUCTURE] = { minSpace = 1, idealSpace = 2 },
    [CATEGORIES.CARDIO] = { minSpace = 3, idealSpace = 4 },
    [CATEGORIES.STRENGTH] = { minSpace = 2.5, idealSpace = 3.5 },
    [CATEGORIES.AMENITIES] = { minSpace = 1.5, idealSpace = 2.5 },
    [CATEGORIES.SPECIALTY] = { minSpace = 4, idealSpace = 6 },
    [CATEGORIES.STAFF] = { minSpace = 2, idealSpace = 3 }
}

-- BoundingBoxGenerator singleton
local BoundingBoxGenerator = {}
BoundingBoxGenerator.BoxesByTycoon = {}
BoundingBoxGenerator.BoxesByType = {}

-- Function to get equipment dimensions from model
function BoundingBoxGenerator:GetEquipmentDimensions(model)
    if not model then return Vector3.new(2, 2, 2) end
    
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    
    -- Calculate bounds from all parts
    for _, part in pairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            local size = part.Size
            local pos = part.Position
            
            minX = math.min(minX, pos.X - size.X/2)
            minY = math.min(minY, pos.Y - size.Y/2)
            minZ = math.min(minZ, pos.Z - size.Z/2)
            
            maxX = math.max(maxX, pos.X + size.X/2)
            maxY = math.max(maxY, pos.Y + size.Y/2)
            maxZ = math.max(maxZ, pos.Z + size.Z/2)
        end
    end
    
    if minX == math.huge then
        -- Default size if no parts found
        return Vector3.new(2, 2, 2)
    end
    
    -- Calculate dimensions
    return Vector3.new(
        maxX - minX, 
        maxY - minY, 
        maxZ - minZ
    )
end

-- Function to find floor parts in a tycoon - leveraging FloorAttributeSetup
function BoundingBoxGenerator:FindFloorParts(tycoon, floorNumber)
    if not tycoon then return {} end
    
    -- First try to use FloorAttributeSetup to get floor references
    if FloorAttributeSetup then
        local floorData = FloorAttributeSetup:GetFloorData(tycoon, floorNumber)
        if floorData and floorData.floorParts and #floorData.floorParts > 0 then
            -- Return floor parts found by FloorAttributeSetup
            return floorData.floorParts
        end
        
        -- Try to use room data if floor parts not found directly
        if floorData and floorData.rooms then
            local floorParts = {}
            for _, roomData in pairs(floorData.rooms) do
                if roomData.floorParts then
                    for _, part in ipairs(roomData.floorParts) do
                        table.insert(floorParts, part)
                    end
                end
            end
            if #floorParts > 0 then
                return floorParts
            end
        end
    end
    
    -- Fallback to manual search if FloorAttributeSetup didn't return parts
    local floorParts = {}
    
    -- Find parts that match floor criteria
    for _, part in pairs(tycoon:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Check if part has floor attribute
            if part:GetAttribute("Floor") == floorNumber then
                -- Check if it's likely a floor (horizontal surface)
                local isHorizontal = part.CFrame.UpVector:Dot(Vector3.new(0, 1, 0)) > 0.9
                if isHorizontal and part.Size.Y < 2 then
                    table.insert(floorParts, part)
                end
            end
        end
    end
    
    -- If no floor parts found with attribute, try to find by Y position
    if #floorParts == 0 then
        local baseY = 0
        if floorNumber > 1 then
            baseY = (floorNumber - 1) * 10 -- Assume floors are 10 studs apart
        end
        
        for _, part in pairs(tycoon:GetDescendants()) do
            if part:IsA("BasePart") then
                -- Check if near expected floor height
                if math.abs(part.Position.Y - baseY) < 2 then
                    -- Check if it's likely a floor (horizontal surface)
                    local isHorizontal = part.CFrame.UpVector:Dot(Vector3.new(0, 1, 0)) > 0.9
                    if isHorizontal and part.Size.Y < 2 then
                        table.insert(floorParts, part)
                    end
                end
            end
        end
    end
    
    return floorParts
end

-- Function to find wall parts in a tycoon - leveraging FloorAttributeSetup
function BoundingBoxGenerator:FindWallParts(tycoon, floorNumber)
    if not tycoon then return {} end
    
    -- First try to use FloorAttributeSetup to get wall references
    if FloorAttributeSetup then
        local floorData = FloorAttributeSetup:GetFloorData(tycoon, floorNumber)
        if floorData and floorData.wallParts and #floorData.wallParts > 0 then
            -- Return wall parts found by FloorAttributeSetup
            return floorData.wallParts
        end
        
        -- Try to use room data if wall parts not found directly
        if floorData and floorData.rooms then
            local wallParts = {}
            for _, roomData in pairs(floorData.rooms) do
                if roomData.wallParts then
                    for _, part in ipairs(roomData.wallParts) do
                        table.insert(wallParts, part)
                    end
                end
            end
            if #wallParts > 0 then
                return wallParts
            end
        end
    end
    
    -- Fallback to manual search if FloorAttributeSetup didn't return parts
    local wallParts = {}
    
    -- Find parts that match wall criteria
    for _, part in pairs(tycoon:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Check if part has floor attribute
            if part:GetAttribute("Floor") == floorNumber then
                -- Check if it's likely a wall (vertical surface)
                local isVertical = math.abs(part.CFrame.UpVector:Dot(Vector3.new(0, 1, 0))) < 0.1
                if isVertical and part.Size.Y > 2 then
                    table.insert(wallParts, part)
                end
            end
        end
    end
    
    -- If no wall parts found with attribute, try to find by model name and Y position
    if #wallParts == 0 then
        local baseY = 0
        if floorNumber > 1 then
            baseY = (floorNumber - 1) * 10 -- Assume floors are 10 studs apart
        end
        
        for _, part in pairs(tycoon:GetDescendants()) do
            if part:IsA("BasePart") then
                -- Check if near expected floor height
                if part.Position.Y > baseY and part.Position.Y < baseY + 10 then
                    -- Check if it's likely a wall (vertical surface)
                    local isVertical = math.abs(part.CFrame.UpVector:Dot(Vector3.new(0, 1, 0))) < 0.1
                    if isVertical and part.Size.Y > 2 then
                        table.insert(wallParts, part)
                    end
                end
            end
        end
    end
    
    return wallParts
end

-- Function to get room data from FloorAttributeSetup
function BoundingBoxGenerator:GetRoomData(tycoon, floorNumber, roomName)
    if not FloorAttributeSetup then return nil end
    
    local floorData = FloorAttributeSetup:GetFloorData(tycoon, floorNumber)
    if not floorData or not floorData.rooms then return nil end
    
    if roomName then
        -- Return specific room
        return floorData.rooms[roomName]
    else
        -- Return all rooms
        return floorData.rooms
    end
end

-- Function to calculate available placement areas, now with room awareness
function BoundingBoxGenerator:CalculatePlacementAreas(tycoon, floorNumber)
    if not tycoon then return {} end
    
    local placementAreas = {}
    
    -- First try to use FloorAttributeSetup to get room-based placement areas
    if FloorAttributeSetup then
        local rooms = self:GetRoomData(tycoon, floorNumber)
        
        if rooms then
            -- Process each room to create placement areas
            for roomName, roomData in pairs(rooms) do
                -- Only consider rooms with floor parts
                if roomData.floorParts and #roomData.floorParts > 0 then
                    -- Calculate room bounds
                    local minBound, maxBound = FloorAttributeSetup:CalculateRoomBounds(roomData)
                    
                    if minBound and maxBound then
                        -- Create a placement area for the room
                        local size = maxBound - minBound
                        local position = minBound + size/2
                        
                        -- Skip tiny rooms
                        if size.X < 2 or size.Z < 2 then
                            continue
                        end
                        
                        local area = {
                            position = position,
                            size = Vector3.new(size.X, 0, size.Z),
                            room = roomName,
                            floorParts = roomData.floorParts,
                            nearWalls = {},
                            isCorner = false
                        }
                        
                        -- Add wall data
                        if roomData.wallParts then
                            for _, wallPart in pairs(roomData.wallParts) do
                                local wallPos = wallPart.Position
                                
                                -- Check horizontal distance
                                local horizontalDistance = Vector3.new(
                                    wallPos.X - position.X,
                                    0,
                                    wallPos.Z - position.Z
                                ).Magnitude
                                
                                if horizontalDistance < size.X/2 + 2 then
                                    table.insert(area.nearWalls, {
                                        part = wallPart,
                                        distance = horizontalDistance,
                                        normal = (position - wallPos).Unit
                                    })
                                end
                            end
                        end
                        
                        -- Determine if corner
                        if #area.nearWalls >= 2 then
                            area.isCorner = true
                        end
                        
                        table.insert(placementAreas, area)
                    end
                end
            end
        end
    end
    
    -- If we have areas from FloorAttributeSetup, return them
    if #placementAreas > 0 then
        return placementAreas
    end
    
    -- Fallback to legacy method if no areas found from FloorAttributeSetup
    local floorParts = self:FindFloorParts(tycoon, floorNumber)
    local wallParts = self:FindWallParts(tycoon, floorNumber)
    
    -- Process each floor part as a potential placement area
    for _, floorPart in pairs(floorParts) do
        local size = floorPart.Size
        local position = floorPart.Position
        
        -- Skip very small floor parts
        if size.X < 2 or size.Z < 2 then
            continue
        end
        
        -- Create a placement area
        local area = {
            position = position,
            size = Vector3.new(size.X, 0, size.Z),
            cframe = floorPart.CFrame,
            nearWalls = {},
            isCorner = false
        }
        
        -- Find nearby walls
        for _, wallPart in pairs(wallParts) do
            local wallPos = wallPart.Position
            
            -- Check horizontal distance to see if wall is nearby
            local horizontalDistance = Vector3.new(
                wallPos.X - position.X,
                0,
                wallPos.Z - position.Z
            ).Magnitude
            
            if horizontalDistance < size.X/2 + 2 then
                table.insert(area.nearWalls, {
                    part = wallPart,
                    distance = horizontalDistance,
                    normal = (position - wallPos).Unit
                })
            end
        end
        
        -- Determine if this is a corner area
        if #area.nearWalls >= 2 then
            area.isCorner = true
        end
        
        table.insert(placementAreas, area)
    end
    
    return placementAreas
end

-- Create a bounding box for equipment
function BoundingBoxGenerator:CreateBoundingBox(position, size, tileType, tycoon)
    -- Get tile data from BuyTileSystem
    local tileData = BuyTileSystem and BuyTileSystem.tileData and BuyTileSystem.tileData[tileType]
    
    -- Create the box part
    local box = Instance.new("Part")
    box.Name = "BoundingBox_" .. tileType
    box.Anchored = true
    box.CanCollide = false
    box.Size = size
    box.Position = position
    box.Transparency = 0.8
    
    -- Determine color based on category or progression status
    local color = BrickColor.Red()
    
    if tileData then
        -- If we have BuyTileProgressionManager, use it to check if tile can be purchased
        if BuyTileProgressionManager then
            local canBuy = BuyTileProgressionManager:CanBuyTile(tileType, tycoon)
            local isRequired = BuyTileProgressionManager:IsTileRequired(tileType)
            
            if canBuy then
                -- Can buy now
                color = BrickColor.Green()
            elseif isRequired then
                -- Required but can't buy yet
                color = BrickColor.Yellow()
            else
                -- Optional and can't buy yet
                color = BrickColor.Red()
            end
        else
            -- Without progression manager, use category for color
            local category = tileData.category
            if category == CATEGORIES.STRUCTURE then
                color = BrickColor.new("Bright blue")
            elseif category == CATEGORIES.CARDIO then
                color = BrickColor.new("Lime green")
            elseif category == CATEGORIES.STRENGTH then
                color = BrickColor.new("Bright red")
            elseif category == CATEGORIES.AMENITIES then
                color = BrickColor.new("Bright yellow")
            elseif category == CATEGORIES.SPECIALTY then
                color = BrickColor.new("Royal purple")
            else
                color = BrickColor.new("Medium stone grey")
            end
        end
    end
    
    box.BrickColor = color
    box.Material = Enum.Material.Neon
    box.TopSurface = Enum.SurfaceType.Smooth
    box.BottomSurface = Enum.SurfaceType.Smooth
    
    -- Add attributes
    box:SetAttribute("TileType", tileType)
    if tileData then
        box:SetAttribute("TileName", tileData.description or tileType)
        box:SetAttribute("TileCategory", tileData.category)
        box:SetAttribute("TilePrice", tileData.price)
        box:SetAttribute("TileBuildOrder", tileData.buildOrder)
    end
    
    -- Add visual guide
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "Label"
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, size.Y/2 + 1, 0)
    billboardGui.AlwaysOnTop = true
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Text = tileData and tileData.description or tileType
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = billboardGui
    
    billboardGui.Parent = box
    
    -- Store reference
    if not self.BoxesByTycoon[tycoon] then
        self.BoxesByTycoon[tycoon] = {}
    end
    table.insert(self.BoxesByTycoon[tycoon], box)
    
    if not self.BoxesByType[tileType] then
        self.BoxesByType[tileType] = {}
    end
    table.insert(self.BoxesByType[tileType], box)
    
    -- Parent to tycoon
    box.Parent = tycoon
    
    return box
end

-- Generate bounding boxes for a specific equipment type - now leveraging TileDataGenerator
function BoundingBoxGenerator:GenerateBoundingBoxesForType(tileType, tycoon)
    if not tileType or not tycoon then return {} end
    
    -- Get tile data from BuyTileSystem
    local tileData = BuyTileSystem and BuyTileSystem.tileData and BuyTileSystem.tileData[tileType]
    if not tileData then 
        -- Try to generate data if we have TileDataGenerator
        if TileDataGenerator then
            tileData = TileDataGenerator:GenerateTileData(tileType)
        end
        
        if not tileData then
            return {}
        end
    end
    
    -- Find model for size calculation
    local model = nil
    
    -- Try to find model in ServerStorage
    local buyTilesFolder = ServerStorage:FindFirstChild("BuyTiles")
    if buyTilesFolder then
        model = buyTilesFolder:FindFirstChild(tileData.modelName) or buyTilesFolder:FindFirstChild(tileType)
    end
    
    -- Try to find in TileModels folder
    if not model then
        local tileModelsFolder = ServerStorage:FindFirstChild("TileModels")
        if tileModelsFolder then
            model = tileModelsFolder:FindFirstChild(tileData.modelName) or tileModelsFolder:FindFirstChild(tileType)
        end
    end
    
    -- Try to find in Equipment folder
    if not model then
        local equipmentFolder = ServerStorage:FindFirstChild("Equipment")
        if equipmentFolder then
            model = equipmentFolder:FindFirstChild(tileData.modelName) or equipmentFolder:FindFirstChild(tileType)
        end
    end
    
    -- Get equipment dimensions
    local dimensions = self:GetEquipmentDimensions(model)
    
    -- Add spacing requirements
    local category = tileData.category
    local spacing = SPACING_REQUIREMENTS[category] or { minSpace = 1, idealSpace = 2 }
    
    -- Add padding to dimensions for spacing
    local boxSize = Vector3.new(
        dimensions.X + spacing.minSpace * 2,
        dimensions.Y,
        dimensions.Z + spacing.minSpace * 2
    )
    
    -- Calculate placement areas for the relevant floor
    local floorNumber = tileData.floor or 1
    local room = tileData.room -- Some tiles may have specific room requirements
    
    -- If we know the specific room, only generate areas in that room
    local placementAreas
    if room and FloorAttributeSetup then
        local roomData = self:GetRoomData(tycoon, floorNumber, room)
        if roomData and roomData.floorParts and #roomData.floorParts > 0 then
            -- Only generate placement areas for the specific room
            placementAreas = {}
            
            -- Calculate room bounds
            local minBound, maxBound = FloorAttributeSetup:CalculateRoomBounds(roomData)
            
            if minBound and maxBound then
                -- Create a placement area for the room
                local size = maxBound - minBound
                local position = minBound + size/2
                
                local area = {
                    position = position,
                    size = Vector3.new(size.X, 0, size.Z),
                    room = room,
                    floorParts = roomData.floorParts,
                    nearWalls = {},
                    isCorner = false
                }
                
                -- Add wall data
                if roomData.wallParts then
                    for _, wallPart in pairs(roomData.wallParts) do
                        local wallPos = wallPart.Position
                        
                        -- Check horizontal distance
                        local horizontalDistance = Vector3.new(
                            wallPos.X - position.X,
                            0,
                            wallPos.Z - position.Z
                        ).Magnitude
                        
                        if horizontalDistance < size.X/2 + 2 then
                            table.insert(area.nearWalls, {
                                part = wallPart,
                                distance = horizontalDistance,
                                normal = (position - wallPos).Unit
                            })
                        end
                    end
                end
                
                -- Determine if corner
                if #area.nearWalls >= 2 then
                    area.isCorner = true
                end
                
                table.insert(placementAreas, area)
            end
        end
    end
    
    -- If we don't have room-specific areas yet, get all areas
    if not placementAreas or #placementAreas == 0 then
        placementAreas = self:CalculatePlacementAreas(tycoon, floorNumber)
    end
    
    -- Boxes we'll create
    local boxes = {}
    
    -- Determine best placement based on equipment category and structure type
    if category == CATEGORIES.STRUCTURE then
        -- Check if we have a specific structure type from FloorAttributeSetup
        local structureType = tileData.structureType
        
        if structureType == "Wall" then
            -- Walls tend to go on edges
            for _, area in ipairs(placementAreas) do
                -- Place near edges but not in corners
                if #area.nearWalls == 0 then
                    -- Calculate position along edge
                    local placementPos = area.position + Vector3.new(area.size.X/2 - 1, dimensions.Y/2, 0)
                    
                    -- Create box
                    local box = self:CreateBoundingBox(placementPos, boxSize, tileType, tycoon)
                    table.insert(boxes, box)
                end
            end
        elseif structureType == "Floor" then
            -- Floors tend to go in the center
            for _, area in ipairs(placementAreas) do
                local placementPos = area.position + Vector3.new(0, dimensions.Y/2, 0)
                
                -- Create box
                local box = self:CreateBoundingBox(placementPos, boxSize, tileType, tycoon)
                table.insert(boxes, box)
            end
        elseif structureType == "Door" then
            -- Doors always go on walls
            for _, area in ipairs(placementAreas) do
                if #area.nearWalls > 0 then
                    -- Place along wall
                    for _, wall in ipairs(area.nearWalls) do
                        -- Calculate position along wall
                        local wallPos = wall.part.Position
                        local placementPos = wallPos + wall.normal * (dimensions.Z/2 + 0.2)
                        placementPos = Vector3.new(placementPos.X, area.position.Y + dimensions.Y/2, placementPos.Z)
                        
                        -- Create box
                        local box = self:CreateBoundingBox(placementPos, boxSize, tileType, tycoon)
                        table.insert(boxes, box)
                        
                        break -- Only create one box per area for doors
                    end
                end
            end
        else
            -- General structure items often go along walls
            for _, area in ipairs(placementAreas) do
                if #area.nearWalls > 0 then
                    -- Place along wall
                    for _, wall in ipairs(area.nearWalls) do
                        -- Calculate position along wall
                        local wallPos = wall.part.Position
                        local placementPos = wallPos + wall.normal * (dimensions.Z/2 + 0.5)
                        placementPos = Vector3.new(placementPos.X, area.position.Y + dimensions.Y/2, placementPos.Z)
                        
                        -- Create box
                        local box = self:CreateBoundingBox(placementPos, boxSize, tileType, tycoon)
                        table.insert(boxes, box)
                        
                        -- Only create one box per area for structural items
                        break
                    end
                end
            end
        end
    elseif category == CATEGORIES.CARDIO then
        -- Cardio equipment often in open areas with spacing
        for _, area in ipairs(placementAreas) do
            -- Place in center of large open areas
            if area.size.X > 6 and area.size.Z > 6 and #area.nearWalls == 0 then
                local placementPos = area.position + Vector3.new(0, dimensions.Y/2, 0)
                
                -- Create box
                local box = self:CreateBoundingBox(placementPos, boxSize, tileType, tycoon)
                table.insert(boxes, box)
            end
        end
    elseif category == CATEGORIES.STRENGTH then
        -- Strength equipment often along walls but not in corners
        for _, area in ipairs(placementAreas) do
            if #area.nearWalls > 0 and not area.isCorner then
                -- Place along wall
                for _, wall in ipairs(area.nearWalls) do
                    -- Calculate position along wall
                    local wallPos = wall.part.Position
                    local placementPos = wallPos + wall.normal * (dimensions.Z/2 + 1)
                    placementPos = Vector3.new(placementPos.X, area.position.Y + dimensions.Y/2, placementPos.Z)
                    
                    -- Create box
                    local box = self:CreateBoundingBox(placementPos, boxSize, tileType, tycoon)
                    table.insert(boxes, box)
                    
                    -- Only create one box per wall
                    break
                end
            end
        end
    elseif category == CATEGORIES.AMENITIES then
        -- Amenities often in corners
        for _, area in ipairs(placementAreas) do
            if area.isCorner then
                -- Place in corner
                local placementPos = area.position + Vector3.new(0, dimensions.Y/2, 0)
                
                -- Create box
                local box = self:CreateBoundingBox(placementPos, boxSize, tileType, tycoon)
                table.insert(boxes, box)
            end
        end
    elseif category == CATEGORIES.SPECIALTY then
        -- Specialty equipment needs large open spaces
        for _, area in ipairs(placementAreas) do
            -- Place in center of very large open areas
            if area.size.X > 10 and area.size.Z > 10 then
                local placementPos = area.position + Vector3.new(0, dimensions.Y/2, 0)
                
                -- Create box
                local box = self:CreateBoundingBox(placementPos, boxSize, tileType, tycoon)
                table.insert(boxes, box)
            end
        end
    elseif category == CATEGORIES.STAFF then
        -- Staff areas often against walls or in corners
        for _, area in ipairs(placementAreas) do
            if #area.nearWalls > 0 then
                -- Place along wall
                for _, wall in ipairs(area.nearWalls) do
                    -- Calculate position along wall
                    local wallPos = wall.part.Position
                    local placementPos = wallPos + wall.normal * (dimensions.Z/2 + 0.5)
                    placementPos = Vector3.new(placementPos.X, area.position.Y + dimensions.Y/2, placementPos.Z)
                    
                    -- Create box
                    local box = self:CreateBoundingBox(placementPos, boxSize, tileType, tycoon)
                    table.insert(boxes, box)
                    
                    -- Only create one box per area for staff items
                    break
                end
            end
        end
    end
    
    -- If no suitable locations found, place in center of largest area
    if #boxes == 0 then
        local largestArea = nil
        local maxSize = 0
        
        for _, area in ipairs(placementAreas) do
            local areaSize = area.size.X * area.size.Z
            if areaSize > maxSize then
                maxSize = areaSize
                largestArea = area
            end
        end
        
        if largestArea then
            local placementPos = largestArea.position + Vector3.new(0, dimensions.Y/2, 0)
            local box = self:CreateBoundingBox(placementPos, boxSize, tileType, tycoon)
            table.insert(boxes, box)
        end
    end
    
    return boxes
end

-- Function to clear existing bounding boxes
function BoundingBoxGenerator:ClearBoundingBoxes(tycoon)
    if tycoon then
        -- Clear boxes for specific tycoon
        local boxes = self.BoxesByTycoon[tycoon] or {}
        for _, box in ipairs(boxes) do
            box:Destroy()
        end
        self.BoxesByTycoon[tycoon] = {}
    else
        -- Clear all boxes
        for _, boxes in pairs(self.BoxesByTycoon) do
            for _, box in ipairs(boxes) do
                box:Destroy()
            end
        end
        self.BoxesByTycoon = {}
        self.BoxesByType = {}
    end
end

-- Function to generate bounding boxes for all equipment types
function BoundingBoxGenerator:GenerateAllBoundingBoxes(tycoon)
    if not tycoon then return end
    
    -- Clear existing boxes
    self:ClearBoundingBoxes(tycoon)
    
    local tileCount = 0
    
    -- If we have BuyTileSystem, use its data
    if BuyTileSystem and BuyTileSystem.tileData then
        -- Generate boxes for each tile type
        for tileType, _ in pairs(BuyTileSystem.tileData) do
            local boxes = self:GenerateBoundingBoxesForType(tileType, tycoon)
            tileCount = tileCount + #boxes
        end
    end
    
    -- If we have BuyTileProgressionManager, use it to only show available tiles
    elseif BuyTileProgressionManager then
        -- Get next purchasable tiles
        local nextTiles = BuyTileProgressionManager:GetNextPurchasableTiles(tycoon)
        
        -- Generate boxes only for available tiles
        for _, tileType in ipairs(nextTiles) do
            local boxes = self:GenerateBoundingBoxesForType(tileType, tycoon)
            tileCount = tileCount + #boxes
        end
    end
    
    return tileCount
end

-- Generate bounding boxes for next progression tiles
function BoundingBoxGenerator:GenerateNextProgressionBoxes(tycoon)
    if not tycoon or not BuyTileProgressionManager then return 0 end
    
    -- Clear existing boxes
    self:ClearBoundingBoxes(tycoon)
    
    -- Get next purchasable tiles
    local nextTiles = BuyTileProgressionManager:GetNextPurchasableTiles(tycoon)
    
    local tileCount = 0
    
    -- Generate boxes only for available tiles
    for _, tileType in ipairs(nextTiles) do
        local boxes = self:GenerateBoundingBoxesForType(tileType, tycoon)
        tileCount = tileCount + #boxes
    end
    
    return tileCount
end

-- Function to create a command for bounding box generation
function BoundingBoxGenerator:CreateCommand()
    local CommandService = CoreRegistry and CoreRegistry:GetSystem("CommandService")
    
    if not CommandService then
        warn("CommandService not found, bounding box commands won't be available")
        return false
    end
    
    -- Register a command to generate bounding boxes
    CommandService:RegisterCommand("generateBoundingBoxes", {
        description = "Generates bounding boxes for equipment placement",
        parameters = {
            {name = "tileType", type = "string", description = "Optional specific tile type", default = ""}
        },
        handler = function(player, tileType)
            -- Check if player is authorized to run admin commands
            local AdminService = CoreRegistry:GetSystem("AdminService")
            if AdminService and not AdminService:IsAdmin(player) then
                return "You don't have permission to use this command"
            end
            
            -- Get player's tycoon
            local TycoonSystem = CoreRegistry:GetSystem("TycoonSystem")
            local tycoon = TycoonSystem and TycoonSystem:GetPlayerTycoon(player)
            
            if not tycoon then
                return "Could not find your tycoon"
            end
            
            if tileType and tileType ~= "" then
                -- Generate boxes for specific tile type
                self:GenerateBoundingBoxesForType(tileType, tycoon)
                return "Generated bounding boxes for " .. tileType
            else
                -- Generate boxes for all types
                local count = self:GenerateAllBoundingBoxes(tycoon)
                return "Generated " .. count .. " bounding boxes"
            end
        end
    })
    
    -- Register a command to show next progression tiles
    CommandService:RegisterCommand("showNextTiles", {
        description = "Shows bounding boxes for next purchasable tiles",
        parameters = {},
        handler = function(player)
            -- Check if player is authorized to run admin commands
            local AdminService = CoreRegistry:GetSystem("AdminService")
            if AdminService and not AdminService:IsAdmin(player) then
                return "You don't have permission to use this command"
            end
            
            -- Get player's tycoon
            local TycoonSystem = CoreRegistry:GetSystem("TycoonSystem")
            local tycoon = TycoonSystem and TycoonSystem:GetPlayerTycoon(player)
            
            if not tycoon then
                return "Could not find your tycoon"
            end
            
            -- Show next progression tiles
            local count = self:GenerateNextProgressionBoxes(tycoon)
            if count > 0 then
                return "Showing " .. count .. " next purchasable tiles"
            else
                return "No next purchasable tiles found"
            end
        end
    })
    
    -- Register a command to clear bounding boxes
    CommandService:RegisterCommand("clearBoundingBoxes", {
        description = "Clears bounding boxes for equipment placement",
        parameters = {},
        handler = function(player)
            -- Check if player is authorized to run admin commands
            local AdminService = CoreRegistry:GetSystem("AdminService")
            if AdminService and not AdminService:IsAdmin(player) then
                return "You don't have permission to use this command"
            end
            
            -- Get player's tycoon
            local TycoonSystem = CoreRegistry:GetSystem("TycoonSystem")
            local tycoon = TycoonSystem and TycoonSystem:GetPlayerTycoon(player)
            
            if not tycoon then
                return "Could not find your tycoon"
            end
            
            self:ClearBoundingBoxes(tycoon)
            return "Cleared bounding boxes"
        end
    })
    
    return true
end

-- Function to show/hide all bounding boxes
function BoundingBoxGenerator:SetBoxesVisibility(visible, tycoon)
    if tycoon then
        -- Set visibility for specific tycoon
        local boxes = self.BoxesByTycoon[tycoon] or {}
        for _, box in ipairs(boxes) do
            box.Transparency = visible and 0.8 or 1
            local label = box:FindFirstChild("Label")
            if label then
                label.Enabled = visible
            end
        end
    else
        -- Set visibility for all boxes
        for _, boxes in pairs(self.BoxesByTycoon) do
            for _, box in ipairs(boxes) do
                box.Transparency = visible and 0.8 or 1
                local label = box:FindFirstChild("Label")
                if label then
                    label.Enabled = visible
                end
            end
        end
    end
end

-- Add global functions for studio usage
function BoundingBoxGenerator:CreateGlobalFunctions()
    if not game:GetService("RunService"):IsStudio() then
        return
    end
    
    -- Global studio functions
    _G.GenerateBoundingBoxes = function(tileType, tycoon)
        tycoon = tycoon or workspace:FindFirstChild("Tycoon") or workspace:FindFirstChild("GymParts")
        
        if not tycoon then
            warn("No tycoon found in workspace")
            return
        end
        
        if tileType then
            BoundingBoxGenerator:GenerateBoundingBoxesForType(tileType, tycoon)
            print("Generated bounding boxes for " .. tileType)
        else
            local count = BoundingBoxGenerator:GenerateAllBoundingBoxes(tycoon)
            print("Generated " .. count .. " bounding boxes")
        end
    end
    
    _G.ShowNextTiles = function(tycoon)
        tycoon = tycoon or workspace:FindFirstChild("Tycoon") or workspace:FindFirstChild("GymParts")
        
        if not tycoon then
            warn("No tycoon found in workspace")
            return
        end
        
        local count = BoundingBoxGenerator:GenerateNextProgressionBoxes(tycoon)
        print("Showing " .. count .. " next purchasable tiles")
    end
    
    _G.ClearBoundingBoxes = function(tycoon)
        tycoon = tycoon or workspace:FindFirstChild("Tycoon") or workspace:FindFirstChild("GymParts")
        
        if not tycoon then
            BoundingBoxGenerator:ClearBoundingBoxes()
            print("Cleared all bounding boxes")
            return
        end
        
        BoundingBoxGenerator:ClearBoundingBoxes(tycoon)
        print("Cleared bounding boxes for " .. tycoon.Name)
    end
    
    print("✓ Registered global function: _G.GenerateBoundingBoxes(tileType, tycoon)")
    print("✓ Registered global function: _G.ShowNextTiles(tycoon)")
    print("✓ Registered global function: _G.ClearBoundingBoxes(tycoon)")
end

-- Initialize
function BoundingBoxGenerator:Initialize()
    print("BoundingBoxGenerator: Initializing...")
    self:CreateCommand()
    self:CreateGlobalFunctions()
    
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.RegisterSystem then
        CoreRegistry:RegisterSystem("BoundingBoxGenerator", self)
        print("BoundingBoxGenerator: Registered with CoreRegistry")
    end
    
    print("BoundingBoxGenerator: Ready!")
    return self
end

return BoundingBoxGenerator:Initialize()