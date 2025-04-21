--[[
    FloorAttributeSetup.server.luau
    
    Core module for floor and room structure management.
    Analyzes tycoon structures to identify floors, walls, and rooms,
    then applies appropriate attributes for use by other systems.
    
    Part of the consolidated modular system including:
    - BuyTileProgressionManager - Build order and prerequisites
    - TileDataGenerator - Attribute and data generation
    - BoundingBoxGenerator - Equipment placement visualization
    
    Author: Created April 2025
    Updated: April 21, 2025 (Integrated with modular BuyTile system)
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

-- Locate CoreRegistry
local CoreRegistry = nil
local systemFolder = ServerScriptService:FindFirstChild("Systems") or ServerScriptService

for _, folder in pairs(systemFolder:GetDescendants()) do
    if folder:IsA("ModuleScript") and folder.Name == "CoreRegistry" then
        CoreRegistry = require(folder)
        break
    end
end

-- Configuration
local CONFIG = {
    FLOOR_HEIGHT = 10,
    WALL_HEIGHT_MIN = 2,
    ROOM_TYPE_ATTR = "RoomType",
    FLOOR_ATTR = "Floor",
    WALL_ATTR = "Wall",
    EDGE_ATTR = "Edge",
    CORNER_ATTR = "Corner",
    ROOM_ATTR = "Room",
    ROOM_TYPES = {
        "Entrance",
        "Reception",
        "Cardio",
        "Weights",
        "Classroom",
        "Locker",
        "Office",
        "Bathroom",
        "Sauna",
        "Nutrition"
    }
}

-- FloorAttributeSetup singleton
local FloorAttributeSetup = {}

-- Cache of processed tycoons
FloorAttributeSetup.TycoonData = {}

-- Helper function to determine if a part is likely a floor
function FloorAttributeSetup:IsFloorPart(part)
    if not part:IsA("BasePart") then
        return false
    end
    
    -- Check if it's horizontal
    local isHorizontal = part.CFrame.UpVector:Dot(Vector3.new(0, 1, 0)) > 0.9
    
    -- Check if it's thin (typical for floors)
    local isThin = part.Size.Y < 2
    
    -- Check naming conventions
    local nameMatch = string.find(string.lower(part.Name), "floor") or 
                      string.find(string.lower(part.Name), "ground")
    
    -- Check material
    local typicalFloorMaterial = part.Material == Enum.Material.Wood or 
                                 part.Material == Enum.Material.Concrete or
                                 part.Material == Enum.Material.Tile
    
    -- Calculate likelihood
    local likelihood = 0
    if isHorizontal then likelihood = likelihood + 2 end
    if isThin then likelihood = likelihood + 1 end
    if nameMatch then likelihood = likelihood + 1 end
    if typicalFloorMaterial then likelihood = likelihood + 1 end
    
    -- Get existing attribute if any
    if part:GetAttribute(CONFIG.FLOOR_ATTR) then
        likelihood = likelihood + 3
    end
    
    return likelihood >= 2
end

-- Helper function to determine if a part is likely a wall
function FloorAttributeSetup:IsWallPart(part)
    if not part:IsA("BasePart") then
        return false
    end
    
    -- Check if it's vertical
    local isVertical = math.abs(part.CFrame.UpVector:Dot(Vector3.new(0, 1, 0))) < 0.1
    
    -- Check if it's tall (typical for walls)
    local isTall = part.Size.Y >= CONFIG.WALL_HEIGHT_MIN
    
    -- Check naming conventions
    local nameMatch = string.find(string.lower(part.Name), "wall")
    
    -- Calculate likelihood
    local likelihood = 0
    if isVertical then likelihood = likelihood + 2 end
    if isTall then likelihood = likelihood + 1 end
    if nameMatch then likelihood = likelihood + 1 end
    
    -- Get existing attribute if any
    if part:GetAttribute(CONFIG.WALL_ATTR) then
        likelihood = likelihood + 3
    end
    
    return likelihood >= 2
end

-- Function to find all floor and wall parts in a tycoon
function FloorAttributeSetup:FindStructuralParts(tycoon)
    local floorParts = {}
    local wallParts = {}
    
    for _, part in pairs(tycoon:GetDescendants()) do
        if part:IsA("BasePart") then
            if self:IsFloorPart(part) then
                table.insert(floorParts, part)
            elseif self:IsWallPart(part) then
                table.insert(wallParts, part)
            end
        end
    end
    
    return floorParts, wallParts
end

-- Function to group floor and wall parts into floors based on Y position
function FloorAttributeSetup:GroupPartsByFloor(floorParts, wallParts)
    local floorsByHeight = {}
    local wallsByHeight = {}
    
    -- Group floor parts by Y coordinate
    for _, part in pairs(floorParts) do
        local y = math.floor(part.Position.Y / CONFIG.FLOOR_HEIGHT + 0.5)
        
        if not floorsByHeight[y] then
            floorsByHeight[y] = {}
        end
        
        table.insert(floorsByHeight[y], part)
    end
    
    -- Group wall parts by Y coordinate (using bottom of part)
    for _, part in pairs(wallParts) do
        local yBottom = part.Position.Y - part.Size.Y/2
        local floorY = math.floor(yBottom / CONFIG.FLOOR_HEIGHT + 0.5)
        
        if not wallsByHeight[floorY] then
            wallsByHeight[floorY] = {}
        end
        
        table.insert(wallsByHeight[floorY], part)
    end
    
    return floorsByHeight, wallsByHeight
end

-- Function to calculate bounding box for a set of parts
function FloorAttributeSetup:CalculateBounds(parts)
    if #parts == 0 then
        return nil, nil
    end
    
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    
    for _, part in pairs(parts) do
        local size = part.Size
        local pos = part.Position
        local cf = part.CFrame
        
        -- Get corners of the part
        local corners = {
            cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
            cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
            cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
            cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
            cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
            cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
            cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
            cf * CFrame.new(size.X/2, size.Y/2, size.Z/2)
        }
        
        for _, corner in pairs(corners) do
            local x, y, z = corner.Position.X, corner.Position.Y, corner.Position.Z
            
            minX = math.min(minX, x)
            minY = math.min(minY, y)
            minZ = math.min(minZ, z)
            
            maxX = math.max(maxX, x)
            maxY = math.max(maxY, y)
            maxZ = math.max(maxZ, z)
        end
    end
    
    return Vector3.new(minX, minY, minZ), Vector3.new(maxX, maxY, maxZ)
end

-- Function to calculate room bounds
function FloorAttributeSetup:CalculateRoomBounds(roomData)
    if not roomData or not roomData.floorParts or #roomData.floorParts == 0 then
        return nil, nil
    end
    
    return self:CalculateBounds(roomData.floorParts)
end

-- Function to identify rooms based on floor and wall parts
function FloorAttributeSetup:IdentifyRooms(tycoon)
    -- Get tycoon data if already processed
    if self.TycoonData[tycoon] then
        return self.TycoonData[tycoon].rooms
    end
    
    -- Find structural parts
    local floorParts, wallParts = self:FindStructuralParts(tycoon)
    
    -- Group parts by floor
    local floorsByHeight, wallsByHeight = self:GroupPartsByFloor(floorParts, wallParts)
    
    -- Initialize rooms map
    local rooms = {}
    
    -- For each floor, identify rooms
    for y, floorPartsForHeight in pairs(floorsByHeight) do
        local floorNumber = y + 1
        
        if not rooms[floorNumber] then
            rooms[floorNumber] = {}
        end
        
        -- Get walls for this floor
        local wallsForFloor = wallsByHeight[y] or {}
        
        -- If we have no walls, treat entire floor as one room
        if #wallsForFloor == 0 then
            local roomName = "Floor" .. floorNumber .. "_Main"
            
            rooms[floorNumber][roomName] = {
                name = roomName,
                floor = floorNumber,
                floorParts = floorPartsForHeight,
                wallParts = {},
                type = "Main"
            }
        else
            -- Try to cluster floor parts into rooms based on proximity and wall boundaries
            -- This is a simplified algorithm - real room detection would be more complex
            local assignedParts = {}
            local roomIndex = 1
            
            -- Use existing room attributes if present
            for _, part in ipairs(floorPartsForHeight) do
                local roomName = part:GetAttribute(CONFIG.ROOM_ATTR)
                if roomName then
                    if not rooms[floorNumber][roomName] then
                        rooms[floorNumber][roomName] = {
                            name = roomName,
                            floor = floorNumber,
                            floorParts = {},
                            wallParts = {},
                            type = part:GetAttribute(CONFIG.ROOM_TYPE_ATTR) or "Unknown"
                        }
                    end
                    
                    table.insert(rooms[floorNumber][roomName].floorParts, part)
                    assignedParts[part] = true
                end
            end
            
            -- For parts without room attributes, use clustering
            for _, part in ipairs(floorPartsForHeight) do
                if assignedParts[part] then
                    continue
                end
                
                local roomName = "Floor" .. floorNumber .. "_Room" .. roomIndex
                local room = {
                    name = roomName,
                    floor = floorNumber,
                    floorParts = {part},
                    wallParts = {},
                    type = "Unknown"
                }
                
                -- Find other connected floor parts
                local partsToCheck = {part}
                assignedParts[part] = true
                
                while #partsToCheck > 0 do
                    local currentPart = table.remove(partsToCheck)
                    
                    -- Find connected floor parts within reasonable distance
                    for _, otherPart in ipairs(floorPartsForHeight) do
                        if not assignedParts[otherPart] then
                            local distance = (currentPart.Position - otherPart.Position).Magnitude
                            
                            -- Check if parts are close enough and not separated by a wall
                            local isSeparatedByWall = false
                            local direction = (otherPart.Position - currentPart.Position).Unit
                            local distanceToCheck = (otherPart.Position - currentPart.Position).Magnitude
                            
                            -- Check if any wall is between these parts
                            for _, wall in ipairs(wallsForFloor) do
                                local wallDistance = (wall.Position - currentPart.Position).Magnitude
                                
                                if wallDistance < distanceToCheck then
                                    -- Check if wall is between the parts
                                    local wallDirection = (wall.Position - currentPart.Position).Unit
                                    local dotProduct = direction:Dot(wallDirection)
                                    
                                    if dotProduct > 0.7 then -- Wall is roughly in same direction
                                        isSeparatedByWall = true
                                        break
                                    end
                                end
                            end
                            
                            -- If parts are close and not separated by wall, add to room
                            if distance < 10 and not isSeparatedByWall then
                                table.insert(room.floorParts, otherPart)
                                table.insert(partsToCheck, otherPart)
                                assignedParts[otherPart] = true
                            end
                        end
                    end
                end
                
                -- Only create the room if we have at least one floor part
                if #room.floorParts > 0 then
                    rooms[floorNumber][roomName] = room
                    roomIndex = roomIndex + 1
                end
            end
            
            -- Assign walls to rooms
            for _, wall in ipairs(wallsForFloor) do
                -- Find nearest room
                local nearestRoom = nil
                local minDistance = math.huge
                
                for _, room in pairs(rooms[floorNumber]) do
                    -- Calculate distance to room center
                    local roomCenter = Vector3.new(0, 0, 0)
                    for _, part in ipairs(room.floorParts) do
                        roomCenter = roomCenter + part.Position
                    end
                    roomCenter = roomCenter / #room.floorParts
                    
                    local distance = (wall.Position - roomCenter).Magnitude
                    
                    if distance < minDistance then
                        minDistance = distance
                        nearestRoom = room
                    end
                end
                
                -- Assign wall to nearest room if found
                if nearestRoom then
                    table.insert(nearestRoom.wallParts, wall)
                end
            end
        end
    end
    
    -- Store rooms in tycoon data
    if not self.TycoonData[tycoon] then
        self.TycoonData[tycoon] = {}
    end
    self.TycoonData[tycoon].rooms = rooms
    
    return rooms
end

-- Function to apply attributes to floor and wall parts
function FloorAttributeSetup:ApplyAttributes(tycoon, floorsByHeight, wallsByHeight)
    -- For each floor, apply floor attributes
    for y, floorPartsForHeight in pairs(floorsByHeight) do
        local floorNumber = y + 1
        
        for _, part in ipairs(floorPartsForHeight) do
            part:SetAttribute(CONFIG.FLOOR_ATTR, floorNumber)
        end
    end
    
    -- For each floor, apply wall attributes
    for y, wallsForFloor in pairs(wallsByHeight) do
        local floorNumber = y + 1
        
        for _, part in ipairs(wallsForFloor) do
            part:SetAttribute(CONFIG.WALL_ATTR, floorNumber)
            part:SetAttribute(CONFIG.FLOOR_ATTR, floorNumber)
        end
    end
    
    -- Apply room attributes based on identified rooms
    local rooms = self:IdentifyRooms(tycoon)
    
    for floorNumber, floorRooms in pairs(rooms) do
        for roomName, room in pairs(floorRooms) do
            -- Apply room attribute to floor parts
            for _, part in ipairs(room.floorParts) do
                part:SetAttribute(CONFIG.ROOM_ATTR, roomName)
                if room.type and room.type ~= "Unknown" then
                    part:SetAttribute(CONFIG.ROOM_TYPE_ATTR, room.type)
                end
            end
            
            -- Apply room attribute to wall parts
            for _, part in ipairs(room.wallParts) do
                part:SetAttribute(CONFIG.ROOM_ATTR, roomName)
                if room.type and room.type ~= "Unknown" then
                    part:SetAttribute(CONFIG.ROOM_TYPE_ATTR, room.type)
                end
            end
        end
    end
    
    return floorsByHeight, wallsByHeight, rooms
end

-- Function to identify edge and corner pieces
function FloorAttributeSetup:IdentifyEdgesAndCorners(tycoon)
    -- Get tycoon data if already processed
    if not self.TycoonData[tycoon] or not self.TycoonData[tycoon].rooms then
        self:IdentifyRooms(tycoon)
    end
    
    local rooms = self.TycoonData[tycoon].rooms
    
    -- Process each room to identify edges and corners
    for floorNumber, floorRooms in pairs(rooms) do
        for roomName, room in pairs(floorRooms) do
            -- Calculate room bounds
            local minBound, maxBound = self:CalculateBounds(room.floorParts)
            
            -- Skip if we couldn't calculate bounds
            if not minBound or not maxBound then
                continue
            end
            
            -- Store bounds in room data
            room.bounds = {
                min = minBound,
                max = maxBound
            }
            
            -- Find edge pieces - these are floor parts near the walls
            for _, part in ipairs(room.floorParts) do
                local isEdge = false
                
                -- Check if this part is near the edge of the room
                if math.abs(part.Position.X - minBound.X) < 2 or
                   math.abs(part.Position.X - maxBound.X) < 2 or
                   math.abs(part.Position.Z - minBound.Z) < 2 or
                   math.abs(part.Position.Z - maxBound.Z) < 2 then
                    isEdge = true
                    part:SetAttribute(CONFIG.EDGE_ATTR, true)
                end
                
                -- Check if this part is in a corner
                if (math.abs(part.Position.X - minBound.X) < 2 and math.abs(part.Position.Z - minBound.Z) < 2) or
                   (math.abs(part.Position.X - minBound.X) < 2 and math.abs(part.Position.Z - maxBound.Z) < 2) or
                   (math.abs(part.Position.X - maxBound.X) < 2 and math.abs(part.Position.Z - minBound.Z) < 2) or
                   (math.abs(part.Position.X - maxBound.X) < 2 and math.abs(part.Position.Z - maxBound.Z) < 2) then
                    part:SetAttribute(CONFIG.CORNER_ATTR, true)
                end
            end
        end
    end
end

-- Function to process a tycoon and apply all attributes
function FloorAttributeSetup:ProcessTycoon(tycoon)
    if not tycoon then
        return 0
    end
    
    -- Find structural parts
    local floorParts, wallParts = self:FindStructuralParts(tycoon)
    
    -- Group parts by floor
    local floorsByHeight, wallsByHeight = self:GroupPartsByFloor(floorParts, wallParts)
    
    -- Apply attributes
    floorsByHeight, wallsByHeight, rooms = self:ApplyAttributes(tycoon, floorsByHeight, wallsByHeight)
    
    -- Identify edges and corners
    self:IdentifyEdgesAndCorners(tycoon)
    
    -- Cache data for the tycoon
    self.TycoonData[tycoon] = {
        floorsByHeight = floorsByHeight,
        wallsByHeight = wallsByHeight,
        rooms = rooms
    }
    
    -- Return floor count
    return #floorsByHeight
end

-- Function to get floor data for a specific floor
function FloorAttributeSetup:GetFloorData(tycoon, floorNumber)
    if not self.TycoonData[tycoon] then
        self:ProcessTycoon(tycoon)
    end
    
    if not self.TycoonData[tycoon] then
        return nil
    end
    
    local floorData = {
        floorParts = {},
        wallParts = {},
        rooms = {}
    }
    
    -- Get floor parts
    local y = floorNumber - 1
    if self.TycoonData[tycoon].floorsByHeight[y] then
        floorData.floorParts = self.TycoonData[tycoon].floorsByHeight[y]
    end
    
    -- Get wall parts
    if self.TycoonData[tycoon].wallsByHeight[y] then
        floorData.wallParts = self.TycoonData[tycoon].wallsByHeight[y]
    end
    
    -- Get rooms
    if self.TycoonData[tycoon].rooms[floorNumber] then
        floorData.rooms = self.TycoonData[tycoon].rooms[floorNumber]
    end
    
    return floorData
end

-- Function to get all floor data
function FloorAttributeSetup:GetAllFloorData(tycoon)
    if not self.TycoonData[tycoon] then
        self:ProcessTycoon(tycoon)
    end
    
    if not self.TycoonData[tycoon] then
        return {}
    end
    
    local allFloorData = {}
    
    -- Calculate floor count
    local maxFloor = 0
    for y, _ in pairs(self.TycoonData[tycoon].floorsByHeight) do
        maxFloor = math.max(maxFloor, y + 1)
    end
    
    -- Get data for each floor
    for floorNumber = 1, maxFloor do
        allFloorData[floorNumber] = self:GetFloorData(tycoon, floorNumber)
    end
    
    return allFloorData
end

-- Function to analyze an existing room and suggest a room type
function FloorAttributeSetup:SuggestRoomType(room)
    if not room or not room.floorParts or #room.floorParts == 0 then
        return "Unknown"
    end
    
    -- Calculate room size
    local minBound, maxBound = self:CalculateBounds(room.floorParts)
    
    if not minBound or not maxBound then
        return "Unknown"
    end
    
    local size = maxBound - minBound
    local area = size.X * size.Z
    
    -- Check room attributes for existing type
    for _, part in ipairs(room.floorParts) do
        local roomType = part:GetAttribute(CONFIG.ROOM_TYPE_ATTR)
        if roomType and roomType ~= "Unknown" then
            return roomType
        end
    end
    
    -- Analyze room shape and size
    if area < 20 then
        -- Small rooms are likely bathrooms or storage
        return "Bathroom"
    elseif area > 100 then
        -- Large rooms are likely main gym areas
        return "Weights"
    elseif area > 50 then
        -- Medium-large rooms could be cardio areas
        return "Cardio"
    elseif room.floor == 1 then
        -- Ground floor medium rooms might be reception
        return "Reception"
    else
        -- Default to classroom for medium rooms on upper floors
        return "Classroom"
    end
end

-- Function to check if a room has a specific attribute (on any of its parts)
function FloorAttributeSetup:RoomHasAttribute(room, attributeName)
    if not room or not room.floorParts then
        return false
    end
    
    for _, part in ipairs(room.floorParts) do
        if part:GetAttribute(attributeName) ~= nil then
            return true
        end
    end
    
    return false
end

-- Function to get rooms of a specific type
function FloorAttributeSetup:GetRoomsByType(tycoon, roomType)
    if not self.TycoonData[tycoon] then
        self:ProcessTycoon(tycoon)
    end
    
    if not self.TycoonData[tycoon] or not self.TycoonData[tycoon].rooms then
        return {}
    end
    
    local matchingRooms = {}
    
    for floorNumber, floorRooms in pairs(self.TycoonData[tycoon].rooms) do
        for roomName, room in pairs(floorRooms) do
            if room.type == roomType then
                table.insert(matchingRooms, room)
            else
                -- Check if any floor part has the room type attribute
                for _, part in ipairs(room.floorParts) do
                    if part:GetAttribute(CONFIG.ROOM_TYPE_ATTR) == roomType then
                        table.insert(matchingRooms, room)
                        break
                    end
                end
            end
        end
    end
    
    return matchingRooms
end

-- Function to set room type
function FloorAttributeSetup:SetRoomType(room, roomType)
    if not room or not room.floorParts then
        return false
    end
    
    -- Update room.type in our data structure
    room.type = roomType
    
    -- Apply room type attribute to all parts in the room
    for _, part in ipairs(room.floorParts) do
        part:SetAttribute(CONFIG.ROOM_TYPE_ATTR, roomType)
    end
    
    for _, part in ipairs(room.wallParts or {}) do
        part:SetAttribute(CONFIG.ROOM_TYPE_ATTR, roomType)
    end
    
    return true
end

-- Function to create global functions for studio use
function FloorAttributeSetup:CreateGlobalFunctions()
    if not game:GetService("RunService"):IsStudio() then
        return
    end
    
    -- Process a tycoon
    _G.ProcessTycoon = function(tycoonName)
        local tycoon
        
        if tycoonName then
            tycoon = Workspace:FindFirstChild(tycoonName)
        else
            tycoon = Workspace:FindFirstChild("GymParts") or Workspace:FindFirstChild("Tycoon")
        end
        
        if not tycoon then
            print("Error: Tycoon not found")
            return
        end
        
        local floorCount = FloorAttributeSetup:ProcessTycoon(tycoon)
        print("Processed tycoon: " .. tycoon.Name)
        print("Floor count: " .. floorCount)
    end
    
    -- Show room information for a tycoon
    _G.ShowRoomInfo = function(tycoonName)
        local tycoon
        
        if tycoonName then
            tycoon = Workspace:FindFirstChild(tycoonName)
        else
            tycoon = Workspace:FindFirstChild("GymParts") or Workspace:FindFirstChild("Tycoon")
        end
        
        if not tycoon then
            print("Error: Tycoon not found")
            return
        end
        
        if not FloorAttributeSetup.TycoonData[tycoon] then
            FloorAttributeSetup:ProcessTycoon(tycoon)
        end
        
        local rooms = FloorAttributeSetup.TycoonData[tycoon].rooms
        if not rooms then
            print("No room data found for tycoon: " .. tycoon.Name)
            return
        end
        
        print("\n=== ROOM INFORMATION FOR " .. tycoon.Name .. " ===")
        
        for floorNumber, floorRooms in pairs(rooms) do
            print("\nFloor " .. floorNumber .. ":")
            
            for roomName, room in pairs(floorRooms) do
                local roomType = room.type or "Unknown"
                local floorCount = #room.floorParts
                local wallCount = #(room.wallParts or {})
                
                print("  - " .. roomName .. " (" .. roomType .. "):")
                print("    - Floor parts: " .. floorCount)
                print("    - Wall parts: " .. wallCount)
                
                -- Calculate room dimensions
                local minBound, maxBound = FloorAttributeSetup:CalculateBounds(room.floorParts)
                if minBound and maxBound then
                    local size = maxBound - minBound
                    print("    - Size: " .. math.floor(size.X) .. " x " .. math.floor(size.Z))
                    print("    - Area: " .. math.floor(size.X * size.Z))
                end
            end
        end
    end
    
    -- Set room type
    _G.SetRoomType = function(tycoonName, floorNumber, roomName, roomType)
        local tycoon
        
        if tycoonName then
            tycoon = Workspace:FindFirstChild(tycoonName)
        else
            tycoon = Workspace:FindFirstChild("GymParts") or Workspace:FindFirstChild("Tycoon")
        end
        
        if not tycoon then
            print("Error: Tycoon not found")
            return
        end
        
        if not FloorAttributeSetup.TycoonData[tycoon] then
            FloorAttributeSetup:ProcessTycoon(tycoon)
        end
        
        local rooms = FloorAttributeSetup.TycoonData[tycoon].rooms
        if not rooms or not rooms[floorNumber] or not rooms[floorNumber][roomName] then
            print("Room not found: Floor " .. floorNumber .. ", " .. roomName)
            return
        end
        
        local room = rooms[floorNumber][roomName]
        FloorAttributeSetup:SetRoomType(room, roomType)
        
        print("Set room type for " .. roomName .. " to " .. roomType)
    end
    
    -- Highlight a room
    _G.HighlightRoom = function(tycoonName, floorNumber, roomName, duration)
        duration = duration or 5
        
        local tycoon
        
        if tycoonName then
            tycoon = Workspace:FindFirstChild(tycoonName)
        else
            tycoon = Workspace:FindFirstChild("GymParts") or Workspace:FindFirstChild("Tycoon")
        end
        
        if not tycoon then
            print("Error: Tycoon not found")
            return
        end
        
        if not FloorAttributeSetup.TycoonData[tycoon] then
            FloorAttributeSetup:ProcessTycoon(tycoon)
        end
        
        local rooms = FloorAttributeSetup.TycoonData[tycoon].rooms
        if not rooms or not rooms[floorNumber] or not rooms[floorNumber][roomName] then
            print("Room not found: Floor " .. floorNumber .. ", " .. roomName)
            return
        end
        
        local room = rooms[floorNumber][roomName]
        
        -- Create highlights for floor parts
        local highlights = {}
        
        for _, part in ipairs(room.floorParts) do
            local highlight = Instance.new("Highlight")
            highlight.FillColor = Color3.fromRGB(0, 255, 0)
            highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Adornee = part
            highlight.Parent = part
            
            table.insert(highlights, highlight)
        end
        
        -- Create highlights for wall parts
        for _, part in ipairs(room.wallParts or {}) do
            local highlight = Instance.new("Highlight")
            highlight.FillColor = Color3.fromRGB(255, 255, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Adornee = part
            highlight.Parent = part
            
            table.insert(highlights, highlight)
        end
        
        print("Highlighting room: " .. roomName .. " for " .. duration .. " seconds")
        
        -- Remove highlights after duration
        task.delay(duration, function()
            for _, highlight in ipairs(highlights) do
                highlight:Destroy()
            end
        end)
    end
    
    print("✓ Registered global function: _G.ProcessTycoon(tycoonName)")
    print("✓ Registered global function: _G.ShowRoomInfo(tycoonName)")
    print("✓ Registered global function: _G.SetRoomType(tycoonName, floorNumber, roomName, roomType)")
    print("✓ Registered global function: _G.HighlightRoom(tycoonName, floorNumber, roomName, duration)")
end

-- Function to register with CoreRegistry if available
function FloorAttributeSetup:Initialize()
    print("FloorAttributeSetup: Initializing...")
    
    -- Create global functions for studio
    self:CreateGlobalFunctions()
    
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.RegisterSystem then
        CoreRegistry:RegisterSystem("FloorAttributeSetup", self)
        print("FloorAttributeSetup: Registered with CoreRegistry")
    end
    
    print("FloorAttributeSetup: Ready!")
    return self
end

return FloorAttributeSetup:Initialize()