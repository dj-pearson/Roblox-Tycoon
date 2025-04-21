--[[
    FloorAttributeSetup.server.luau
    
    Automatically processes the GymParts structure to set up floor attributes
    for all objects in the gym. This enables floor-based progression and
    integrates with the BuyTileSystem for automated purchase sequencing.
    
    Features:
    - Auto-detects floor structure from GymParts folder
    - Sets Floor and FloorName attributes on all objects
    - Processes Room attributes for room-based organization
    - Integrates with BuyTileSystem for floor unlocking
    - Provides admin commands for attribute management
    
    Author: Created April 2025
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

-- Get system references
local BuyTileSystem = CoreRegistry and CoreRegistry:GetSystem("BuyTileSystem")

-- Floor name mapping for UI display
local FLOOR_NAMES = {
    [1] = "1st", 
    [2] = "2nd",
    [3] = "3rd",
    [4] = "4th",
    [5] = "Roof",
    [6] = "Outside"
}

-- FloorAttributeSetup singleton
local FloorAttributeSetup = {}

-- Helper function to get floor number from string
function FloorAttributeSetup:GetFloorNumberFromName(floorName)
    if not floorName or typeof(floorName) ~= "string" then return nil end
    
    -- Extract digit from floor name
    local num = floorName:match("(%d+)[stndrh]")
    if num then
        return tonumber(num)
    end
    
    -- Check for specific floor names
    if floorName:lower():find("ground") or floorName:lower():find("first") or floorName:lower():find("1st") then
        return 1
    elseif floorName:lower():find("second") or floorName:lower():find("2nd") then
        return 2
    elseif floorName:lower():find("third") or floorName:lower():find("3rd") then
        return 3
    elseif floorName:lower():find("fourth") or floorName:lower():find("4th") then
        return 4
    elseif floorName:lower():find("roof") then
        return 5
    elseif floorName:lower():find("outside") or floorName:lower():find("exterior") then
        return 6
    end
    
    return nil
end

-- Helper function to get floor name from number
function FloorAttributeSetup:GetFloorNameFromNumber(floorNumber)
    return FLOOR_NAMES[floorNumber] or tostring(floorNumber) .. "th"
end

-- Function to find the GymParts folder
function FloorAttributeSetup:FindGymPartsFolder()
    local gymParts = Workspace:FindFirstChild("GymParts")
    if not gymParts then
        -- Try to find it in other common locations
        local serverStorage = game:GetService("ServerStorage")
        gymParts = serverStorage:FindFirstChild("GymParts")
        
        if not gymParts then
            -- Look for it in replicated storage
            local replicatedStorage = game:GetService("ReplicatedStorage")
            gymParts = replicatedStorage:FindFirstChild("GymParts")
        end
    end
    
    return gymParts
end

-- Function to process a room folder and its descendants
function FloorAttributeSetup:ProcessRoomFolder(roomFolder, floorNumber, floorName)
    -- Set attributes on the room folder
    roomFolder:SetAttribute("Floor", floorNumber)
    roomFolder:SetAttribute("FloorName", floorName)
    roomFolder:SetAttribute("Room", roomFolder.Name)
    
    -- Process all descendants
    for _, descendant in pairs(roomFolder:GetDescendants()) do
        if descendant:IsA("BasePart") or descendant:IsA("Model") then
            -- Only set attribute if it doesn't already exist
            if descendant:GetAttribute("Floor") == nil then
                descendant:SetAttribute("Floor", floorNumber)
            end
            
            if descendant:GetAttribute("FloorName") == nil then
                descendant:SetAttribute("FloorName", floorName)
            end
            
            if descendant:GetAttribute("Room") == nil then
                descendant:SetAttribute("Room", roomFolder.Name)
            end
        end
    end
    
    print("Processed room: " .. roomFolder.Name .. " on floor: " .. floorName)
end

-- Function to process a floor folder and its contents
function FloorAttributeSetup:ProcessFloorFolder(floorFolder)
    -- Determine floor number from name
    local floorNumber = self:GetFloorNumberFromName(floorFolder.Name)
    if not floorNumber then
        warn("Could not determine floor number from: " .. floorFolder.Name)
        return
    end
    
    -- Get floor name
    local floorName = self:GetFloorNameFromNumber(floorNumber)
    
    -- Set floor attributes on floor folder
    floorFolder:SetAttribute("Floor", floorNumber)
    floorFolder:SetAttribute("FloorName", floorName)
    
    print("Processing floor: " .. floorName .. " (" .. floorFolder.Name .. ")")
    
    -- Look for rooms folder first
    local roomsFolder = floorFolder:FindFirstChild("Rooms")
    if roomsFolder then
        -- Process rooms and their contents
        for _, room in pairs(roomsFolder:GetChildren()) do
            self:ProcessRoomFolder(room, floorNumber, floorName)
        end
    end
    
    -- Process other direct children (walls, floor, ceiling)
    for _, child in pairs(floorFolder:GetChildren()) do
        if child.Name ~= "Rooms" then
            -- Set floor attributes
            child:SetAttribute("Floor", floorNumber)
            child:SetAttribute("FloorName", floorName)
            
            -- Set structure type attribute
            if child.Name:lower():match("wall") then
                child:SetAttribute("StructureType", "Walls")
            elseif child.Name:lower():match("floor") then
                child:SetAttribute("StructureType", "Floor")
            elseif child.Name:lower():match("ceil") then
                child:SetAttribute("StructureType", "Ceiling")
            else
                -- Try to determine by checking first letter
                local firstLetter = child.Name:sub(1, 1):upper()
                if firstLetter == "W" then
                    child:SetAttribute("StructureType", "Walls")
                elseif firstLetter == "F" then
                    child:SetAttribute("StructureType", "Floor")
                elseif firstLetter == "C" then
                    child:SetAttribute("StructureType", "Ceiling")
                end
            end
            
            -- Process descendants
            for _, descendant in pairs(child:GetDescendants()) do
                if descendant:IsA("BasePart") or descendant:IsA("Model") then
                    -- Only set if not already set
                    if descendant:GetAttribute("Floor") == nil then
                        descendant:SetAttribute("Floor", floorNumber)
                    end
                    
                    if descendant:GetAttribute("FloorName") == nil then
                        descendant:SetAttribute("FloorName", floorName)
                    end
                    
                    -- Set structure type from parent
                    if descendant:GetAttribute("StructureType") == nil and child:GetAttribute("StructureType") then
                        descendant:SetAttribute("StructureType", child:GetAttribute("StructureType"))
                    end
                end
            end
            
            print("Processed structure element: " .. child.Name)
        end
    end
    
    print("Completed processing floor: " .. floorName)
end

-- Main function to process the entire GymParts structure
function FloorAttributeSetup:ProcessGymPartsStructure()
    local gymParts = self:FindGymPartsFolder()
    if not gymParts then
        warn("GymParts folder not found in workspace or storage")
        return
    end
    
    print("Processing GymParts structure...")
    
    -- Process each floor folder
    for _, child in pairs(gymParts:GetChildren()) do
        if self:GetFloorNumberFromName(child.Name) then
            self:ProcessFloorFolder(child)
        end
    end
    
    print("GymParts structure processing complete")
    
    -- Return stats
    return {
        floorCount = #gymParts:GetChildren(),
        objectsProcessed = self:CountProcessedObjects(gymParts)
    }
end

-- Function to count processed objects (with floor attributes)
function FloorAttributeSetup:CountProcessedObjects(root)
    local count = 0
    
    for _, descendant in pairs(root:GetDescendants()) do
        if descendant:GetAttribute("Floor") ~= nil then
            count = count + 1
        end
    end
    
    return count
end

-- Function to integrate with BuyTileSystem
function FloorAttributeSetup:IntegrateWithBuyTileSystem()
    if not BuyTileSystem then
        warn("BuyTileSystem not found, cannot integrate")
        return
    end
    
    print("Integrating FloorAttributeSetup with BuyTileSystem...")
    
    -- Override GetFloorName to use our implementation
    local originalGetFloorName = BuyTileSystem.GetFloorName
    BuyTileSystem.GetFloorName = function(self, floorNumber)
        -- Use our implementation first
        local floorName = FloorAttributeSetup:GetFloorNameFromNumber(floorNumber)
        if floorName then
            return floorName
        end
        
        -- Fall back to original if needed
        return originalGetFloorName(self, floorNumber)
    end
    
    -- Add BuyTileSystem hooks for floor attributes
    BuyTileSystem.SetTileFloorAttributes = function(self, tile, tileType, position)
        -- Skip if no tile created
        if not tile then return end
        
        -- Get floor number based on position if not specified in tile data
        local tileData = self.tileData[tileType]
        local floorNumber = tileData and tileData.floor or 1
        
        -- If position is provided, try to determine floor based on Y position
        if position and not tileData.floor then
            -- Rough estimation: assume each floor is about 10 studs high
            floorNumber = math.floor(position.Y / 10) + 1
            if floorNumber < 1 then 
                floorNumber = 1
            elseif floorNumber > 6 then
                floorNumber = 6
            end
        end
        
        -- Set floor attributes
        tile:SetAttribute("Floor", floorNumber)
        tile:SetAttribute("FloorName", FloorAttributeSetup:GetFloorNameFromNumber(floorNumber))
        
        -- Set category if available
        if tileData and tileData.category then
            tile:SetAttribute("Category", tileData.category)
        end
        
        return tile
    end
    
    -- Hook into CreateTile to set floor attributes
    local originalCreateTile = BuyTileSystem.CreateTile
    BuyTileSystem.CreateTile = function(self, tileType, position, rotation)
        local tile = originalCreateTile(self, tileType, position, rotation)
        return self:SetTileFloorAttributes(tile, tileType, position)
    end
    
    print("FloorAttributeSetup integration with BuyTileSystem complete")
end

-- Function to create a command for attribute management
function FloorAttributeSetup:CreateCommands()
    local CommandService = CoreRegistry and CoreRegistry:GetSystem("CommandService")
    
    if not CommandService then
        warn("CommandService not found, floor attribute commands won't be available")
        return false
    end
    
    -- Register a command to set floor attributes
    CommandService:RegisterCommand("setFloorAttributes", {
        description = "Sets floor attributes on an object and its descendants",
        parameters = {
            {name = "objectPath", type = "string", description = "Path to the object"},
            {name = "floorNumber", type = "number", description = "Floor number to set"}
        },
        handler = function(player, objectPath, floorNumber)
            -- Check if player is authorized to run admin commands
            local AdminService = CoreRegistry:GetSystem("AdminService")
            if AdminService and not AdminService:IsAdmin(player) then
                return "You don't have permission to use this command"
            end
            
            -- Find object
            local object = Workspace
            for part in objectPath:gmatch("[^%.]+") do
                object = object:FindFirstChild(part)
                if not object then
                    return "Object not found: " .. objectPath
                end
            end
            
            -- Set attributes
            local floorName = self:GetFloorNameFromNumber(floorNumber)
            object:SetAttribute("Floor", floorNumber)
            object:SetAttribute("FloorName", floorName)
            
            -- Set on descendants
            for _, descendant in pairs(object:GetDescendants()) do
                if descendant:IsA("BasePart") or descendant:IsA("Model") then
                    descendant:SetAttribute("Floor", floorNumber)
                    descendant:SetAttribute("FloorName", floorName)
                end
            end
            
            return "Set floor attributes on " .. object.Name .. " and its descendants"
        end
    })
    
    -- Register a command to process the GymParts structure
    CommandService:RegisterCommand("processGymParts", {
        description = "Processes the GymParts structure to set floor attributes",
        parameters = {},
        handler = function(player)
            -- Check if player is authorized to run admin commands
            local AdminService = CoreRegistry:GetSystem("AdminService")
            if AdminService and not AdminService:IsAdmin(player) then
                return "You don't have permission to use this command"
            end
            
            local stats = self:ProcessGymPartsStructure()
            return string.format("Processed GymParts structure: %d floors, %d objects updated", 
                stats.floorCount, stats.objectsProcessed)
        end
    })
    
    return true
end

-- Initialize
function FloorAttributeSetup:Initialize()
    print("FloorAttributeSetup: Initializing...")
    
    -- Process the GymParts structure
    self:ProcessGymPartsStructure()
    
    -- Integrate with BuyTileSystem
    self:IntegrateWithBuyTileSystem()
    
    -- Register commands
    self:CreateCommands()
    
    print("FloorAttributeSetup: Ready!")
    
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.RegisterSystem then
        CoreRegistry:RegisterSystem("FloorAttributeSetup", self)
    end
    
    return self
end

return FloorAttributeSetup:Initialize()