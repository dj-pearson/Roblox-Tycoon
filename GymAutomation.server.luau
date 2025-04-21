--[[
    GymAutomation.server.luau
    
    Automates the process of setting up gym tycoons by assigning attributes
    and configuring tiles for proper progression.
    
    Now uses the consolidated modular system including:
    - FloorAttributeSetup - Floor and room structure management
    - BuyTileProgressionManager - Build order and prerequisites
    - TileDataGenerator - Attribute and data generation
    - BoundingBoxManager - Equipment placement visualization (consolidated)
    - EquipmentManager - Equipment setup and upgrades (consolidated)
    
    Author: Created April 2025
    Updated: April 21, 2025 (Integrated with consolidated modular systems)
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Locate CoreRegistry to get access to our modular systems
local CoreRegistry = nil
local systemFolder = ServerScriptService:FindFirstChild("Systems") or ServerScriptService

for _, folder in pairs(systemFolder:GetDescendants()) do
    if folder:IsA("ModuleScript") and folder.Name == "CoreRegistry" then
        CoreRegistry = require(folder)
        break
    end
end

-- Get references to our modular systems
local FloorAttributeSetup = CoreRegistry and CoreRegistry:GetSystem("FloorAttributeSetup")
local BuyTileProgressionManager = CoreRegistry and CoreRegistry:GetSystem("BuyTileProgressionManager") 
local TileDataGenerator = CoreRegistry and CoreRegistry:GetSystem("TileDataGenerator")
-- Use the newly consolidated systems
local BoundingBoxManager = CoreRegistry and CoreRegistry:GetSystem("BoundingBoxManager")
local EquipmentManager = CoreRegistry and CoreRegistry:GetSystem("EquipmentManager")
local BuyTileSystem = CoreRegistry and CoreRegistry:GetSystem("BuyTileSystem")

-- Configuration for gym structure
local GYM_CONFIG = {
    FLOOR_HEIGHT = 10,
    DEFAULT_PRICE_MULTIPLIER = 2.5,
    DEFAULT_INCOME_MULTIPLIER = 1.2,
    REQUIRED_STRUCTURES = {"Walls", "Floor", "Door"},
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

-- GymAutomation singleton
local GymAutomation = {}

-- Helper function to find all GymParts instances in the workspace
function GymAutomation:FindGymParts()
    local gymParts = {}
    
    for _, child in pairs(Workspace:GetChildren()) do
        if child.Name == "GymParts" or child.Name == "Tycoon" then
            table.insert(gymParts, child)
        end
    end
    
    return gymParts
end

-- Function to apply floor attributes to a tycoon's parts
function GymAutomation:ApplyFloorAttributes(tycoon)
    if FloorAttributeSetup then
        -- Let the FloorAttributeSetup module handle floor detection and attribute application
        print("Applying floor attributes to " .. tycoon.Name .. " using FloorAttributeSetup")
        local floorCount = FloorAttributeSetup:ProcessTycoon(tycoon)
        print("Processed " .. floorCount .. " floors in " .. tycoon.Name)
        return floorCount
    else
        -- If FloorAttributeSetup is not available, use minimal local implementation
        print("Warning: FloorAttributeSetup not available. Using minimal local implementation.")
        
        -- Basic floor detection based on Y position
        local floorCount = 0
        local highestY = 0
        
        -- Group parts by their Y position to identify floors
        local floorsByHeight = {}
        
        for _, part in ipairs(tycoon:GetDescendants()) do
            if part:IsA("BasePart") then
                local y = math.floor(part.Position.Y / GYM_CONFIG.FLOOR_HEIGHT + 0.5)
                
                if not floorsByHeight[y] then
                    floorsByHeight[y] = {}
                    floorCount = floorCount + 1
                end
                
                table.insert(floorsByHeight[y], part)
                highestY = math.max(highestY, y)
            end
        end
        
        -- Apply floor attributes to parts
        for y, parts in pairs(floorsByHeight) do
            local floorNumber = y + 1
            
            for _, part in ipairs(parts) do
                part:SetAttribute("Floor", floorNumber)
            end
        end
        
        print("Applied basic floor attributes to " .. floorCount .. " floors in " .. tycoon.Name)
        return floorCount
    end
end

-- Function to detect room layouts in a tycoon
function GymAutomation:DetectRooms(tycoon)
    if FloorAttributeSetup then
        -- Let FloorAttributeSetup handle room detection
        print("Detecting rooms in " .. tycoon.Name .. " using FloorAttributeSetup")
        local rooms = FloorAttributeSetup:IdentifyRooms(tycoon)
        local roomCount = 0
        
        for floor, floorRooms in pairs(rooms) do
            roomCount = roomCount + #floorRooms
        end
        
        print("Detected " .. roomCount .. " rooms in " .. tycoon.Name)
        return rooms
    else
        -- Simplified room detection if FloorAttributeSetup is not available
        print("Warning: FloorAttributeSetup not available. Using minimal room detection.")
        local rooms = {}
        
        -- Get all parts with Floor attribute
        local floorParts = {}
        for _, part in ipairs(tycoon:GetDescendants()) do
            if part:IsA("BasePart") and part:GetAttribute("Floor") then
                local floor = part:GetAttribute("Floor")
                
                if not floorParts[floor] then
                    floorParts[floor] = {}
                end
                
                table.insert(floorParts[floor], part)
            end
        end
        
        -- For each floor, create a default room
        for floor, parts in pairs(floorParts) do
            if not rooms[floor] then
                rooms[floor] = {}
            end
            
            -- Create a default room for the floor
            local roomName = "Floor" .. floor .. "_Main"
            rooms[floor][roomName] = {
                name = roomName,
                floor = floor,
                parts = parts
            }
        end
        
        return rooms
    end
end

-- Function to create hitboxes for BuyTile interaction
function GymAutomation:CreateHitboxes(tycoon, tileData)
    if BoundingBoxManager then
        -- Use the newly consolidated BoundingBoxManager
        print("Creating hitboxes for " .. tycoon.Name .. " using BoundingBoxManager")
        local options = {
            showDebug = true,
            autoSetAttributes = true
        }
        local stats = BoundingBoxManager:GenerateHitboxes(tycoon, options)
        print("Created " .. stats.created .. " hitboxes for " .. tycoon.Name)
        return stats.created
    else
        -- If BoundingBoxManager is not available, use minimal local implementation
        print("Warning: BoundingBoxManager not available. Using minimal hitbox creation.")
        
        -- Create a folder to store hitboxes if it doesn't exist
        local hitboxFolder = tycoon:FindFirstChild("BuyTileHitboxes")
        if not hitboxFolder then
            hitboxFolder = Instance.new("Folder")
            hitboxFolder.Name = "BuyTileHitboxes"
            hitboxFolder.Parent = tycoon
        else
            -- Clear existing hitboxes
            hitboxFolder:ClearAllChildren()
        end
        
        local count = 0
        
        -- Tile data should come from BuyTileSystem
        if not tileData and BuyTileSystem then
            tileData = BuyTileSystem.tileData
        end
        
        -- If we still don't have tile data, we can't create hitboxes
        if not tileData then
            print("Error: No tile data available to create hitboxes")
            return 0
        end
        
        -- Create a hitbox for each tile type
        for tileType, data in pairs(tileData) do
            local hitbox = Instance.new("Part")
            hitbox.Name = "BuyTile_" .. tileType
            hitbox.Anchored = true
            hitbox.CanCollide = true
            hitbox.Size = Vector3.new(4, 4, 4)
            hitbox.Transparency = 0.8
            hitbox.BrickColor = BrickColor.Red()
            
            -- Set the hitbox position based on floor
            local floor = data.floor or 1
            local yPosition = (floor - 1) * GYM_CONFIG.FLOOR_HEIGHT + 2
            
            -- Find a suitable position on the floor
            local suitable = false
            for _, part in ipairs(tycoon:GetDescendants()) do
                if part:IsA("BasePart") and part:GetAttribute("Floor") == floor then
                    hitbox.Position = Vector3.new(part.Position.X, yPosition, part.Position.Z)
                    suitable = true
                    break
                end
            end
            
            if not suitable then
                -- Default position if no suitable part found
                hitbox.Position = Vector3.new(0, yPosition, 0)
            end
            
            -- Set attributes
            hitbox:SetAttribute("TileType", tileType)
            hitbox:SetAttribute("Price", data.price)
            hitbox:SetAttribute("Description", data.description)
            hitbox:SetAttribute("IncomeBoost", data.incomeBoost)
            
            hitbox.Parent = hitboxFolder
            count = count + 1
        end
        
        print("Created " .. count .. " basic hitboxes for " .. tycoon.Name)
        return count
    end
end

-- Function to set up equipment in the tycoon
function GymAutomation:SetupEquipment(tycoon)
    if EquipmentManager then
        -- Use the newly consolidated EquipmentManager
        print("Setting up equipment for " .. tycoon.Name .. " using EquipmentManager")
        local options = {
            setupAttributes = true,
            generateInteractions = true
        }
        local stats = EquipmentManager:ProcessAllEquipment(tycoon, options)
        print("Processed " .. stats.processed .. " equipment pieces in " .. tycoon.Name)
        return stats.processed
    else
        print("Warning: EquipmentManager not available. Equipment setup skipped.")
        return 0
    end
end

-- Function to generate buy tile data based on equipment models
function GymAutomation:GenerateTileData(equipmentFolder)
    if TileDataGenerator then
        -- Let TileDataGenerator handle tile data generation
        print("Generating tile data using TileDataGenerator")
        local stats = TileDataGenerator:UpdateBuyTileSystem(equipmentFolder)
        print("Generated data for " .. stats.total .. " tiles (" .. stats.new .. " new)")
        return BuyTileSystem and BuyTileSystem.tileData
    else
        -- If TileDataGenerator is not available, use minimal local implementation
        print("Warning: TileDataGenerator not available. Using minimal tile data generation.")
        
        local tileData = {}
        
        -- Try to find equipment in ServerStorage if no folder provided
        if not equipmentFolder then
            equipmentFolder = ServerStorage:FindFirstChild("BuyTiles") or 
                             ServerStorage:FindFirstChild("Equipment") or
                             ServerStorage:FindFirstChild("TileModels")
        end
        
        if not equipmentFolder then
            print("Error: No equipment folder found")
            return tileData
        end
        
        -- Process each model in the equipment folder
        for _, model in ipairs(equipmentFolder:GetChildren()) do
            if model:IsA("Model") then
                local tileType = model.Name
                
                -- Skip if already exists in BuyTileSystem
                if BuyTileSystem and BuyTileSystem.tileData and BuyTileSystem.tileData[tileType] then
                    tileData[tileType] = BuyTileSystem.tileData[tileType]
                    continue
                end
                
                -- Generate tile data from model attributes or use defaults
                local price = model:GetAttribute("Price") or 100
                local incomeBoost = model:GetAttribute("IncomeBoost") or 10
                local floor = model:GetAttribute("Floor") or 1
                local category = model:GetAttribute("Category") or "Equipment"
                
                tileData[tileType] = {
                    tileType = tileType,
                    price = price,
                    incomeBoost = incomeBoost,
                    floor = floor,
                    category = category,
                    description = model:GetAttribute("Description") or tileType,
                    modelName = tileType
                }
            end
        end
        
        print("Generated basic data for " .. #tileData .. " tiles")
        
        -- Update BuyTileSystem if available
        if BuyTileSystem then
            BuyTileSystem.tileData = tileData
        end
        
        return tileData
    end
end

-- Function to generate build order progression
function GymAutomation:GenerateBuildOrder()
    if BuyTileProgressionManager then
        -- Let BuyTileProgressionManager handle progression generation
        print("Generating build order using BuyTileProgressionManager")
        BuyTileProgressionManager:GenerateBuildOrder()
        BuyTileProgressionManager:SetupFloorPrerequisites()
        BuyTileProgressionManager:IdentifyRequiredTiles()
        return true
    else
        -- If BuyTileProgressionManager is not available, use minimal local implementation
        print("Warning: BuyTileProgressionManager not available. Using minimal build order generation.")
        
        if not BuyTileSystem or not BuyTileSystem.tileData then
            print("Error: No BuyTileSystem or tile data available")
            return false
        end
        
        -- Sort tiles by floor and then by price
        local sortedTiles = {}
        for tileType, data in pairs(BuyTileSystem.tileData) do
            table.insert(sortedTiles, {
                tileType = tileType,
                floor = data.floor or 1,
                price = data.price or 100
            })
        end
        
        table.sort(sortedTiles, function(a, b)
            if a.floor == b.floor then
                return a.price < b.price
            end
            return a.floor < b.floor
        end)
        
        -- Assign build order
        for i, tileInfo in ipairs(sortedTiles) do
            local tileData = BuyTileSystem.tileData[tileInfo.tileType]
            if tileData then
                tileData.buildOrder = i
            end
        end
        
        print("Generated basic build order for " .. #sortedTiles .. " tiles")
        return true
    end
end

-- Function to automate gym setup for a specific tycoon
function GymAutomation:AutomateGym(tycoon)
    if not tycoon then
        print("Error: No tycoon provided")
        return
    end
    
    print("Automating gym setup for: " .. tycoon.Name)
    
    -- Step 1: Apply floor attributes
    local floorCount = self:ApplyFloorAttributes(tycoon)
    
    -- Step 2: Detect rooms
    local rooms = self:DetectRooms(tycoon)
    
    -- Step 3: Generate tile data
    local tileData = self:GenerateTileData()
    
    -- Step 4: Set up equipment (NEW STEP using consolidated EquipmentManager)
    local equipmentCount = self:SetupEquipment(tycoon)
    
    -- Step 5: Create hitboxes (using consolidated BoundingBoxManager)
    local hitboxCount = self:CreateHitboxes(tycoon, tileData)
    
    -- Step 6: Generate build order
    self:GenerateBuildOrder()
    
    print("Gym automation complete for " .. tycoon.Name)
    print("- Floor count: " .. floorCount)
    print("- Equipment count: " .. equipmentCount)
    print("- Hitbox count: " .. hitboxCount)
    
    return {
        floorCount = floorCount,
        equipmentCount = equipmentCount,
        hitboxCount = hitboxCount
    }
end

-- Function to automate all gyms in the workspace
function GymAutomation:AutomateAllGyms()
    local gymParts = self:FindGymParts()
    
    if #gymParts == 0 then
        print("No gym tycoons found in workspace")
        return
    end
    
    for _, tycoon in ipairs(gymParts) do
        self:AutomateGym(tycoon)
    end
    
    print("All gyms automated: " .. #gymParts .. " gyms processed")
end

-- Register global functions for convenience (Studio only)
if game:GetService("RunService"):IsStudio() then
    _G.AutomateGym = function(tycoonName)
        local tycoon
        
        if tycoonName then
            tycoon = Workspace:FindFirstChild(tycoonName)
            if not tycoon then
                print("Error: Tycoon '" .. tycoonName .. "' not found")
                return
            end
        else
            -- Find first gym tycoon
            local gymParts = GymAutomation:FindGymParts()
            if #gymParts > 0 then
                tycoon = gymParts[1]
            else
                print("Error: No gym tycoons found")
                return
            end
        end
        
        GymAutomation:AutomateGym(tycoon)
    end
    
    _G.AutomateAllGyms = function()
        GymAutomation:AutomateAllGyms()
    end
    
    _G.GenerateBuildOrder = function()
        GymAutomation:GenerateBuildOrder()
        print("Build order generated.")
        
        -- Display first 10 items in build order if BuyTileSystem is available
        if BuyTileSystem and BuyTileSystem.tileData then
            local sorted = {}
            for tileType, data in pairs(BuyTileSystem.tileData) do
                table.insert(sorted, {
                    tileType = tileType,
                    buildOrder = data.buildOrder or 999
                })
            end
            
            table.sort(sorted, function(a, b)
                return a.buildOrder < b.buildOrder
            end)
            
            print("First 10 items in build order:")
            for i = 1, math.min(10, #sorted) do
                print(i .. ". " .. sorted[i].tileType .. " (Order: " .. sorted[i].buildOrder .. ")")
            end
        end
    end
    
    -- Access to our consolidated systems
    _G.ShowHitboxes = function()
        if BoundingBoxManager then
            return BoundingBoxManager:ShowHitboxes()
        else
            print("BoundingBoxManager not available")
        end
    end
    
    _G.HideHitboxes = function()
        if BoundingBoxManager then
            return BoundingBoxManager:HideHitboxes()
        else
            print("BoundingBoxManager not available")
        end
    end
    
    _G.ProcessEquipment = function()
        if EquipmentManager then
            return EquipmentManager:ProcessAllEquipment(workspace)
        else
            print("EquipmentManager not available")
        end
    end
    
    -- Debug function to show information about tycoon structure
    _G.ShowTycoonInfo = function(tycoonName)
        local tycoon
        
        if tycoonName then
            tycoon = Workspace:FindFirstChild(tycoonName)
            if not tycoon then
                print("Error: Tycoon '" .. tycoonName .. "' not found")
                return
            end
        else
            -- Find first gym tycoon
            local gymParts = GymAutomation:FindGymParts()
            if #gymParts > 0 then
                tycoon = gymParts[1]
            else
                print("Error: No gym tycoons found")
                return
            end
        end
        
        print("\n=== TYCOON INFO: " .. tycoon.Name .. " ===")
        
        -- Floor info
        if FloorAttributeSetup then
            local floorData = FloorAttributeSetup:GetAllFloorData(tycoon)
            print("\nFloors:")
            
            for floor, data in pairs(floorData) do
                print("- Floor " .. floor .. ":")
                print("  - Floor parts: " .. #(data.floorParts or {}))
                print("  - Wall parts: " .. #(data.wallParts or {}))
                
                if data.rooms then
                    print("  - Rooms: " .. #data.rooms)
                    for roomName, roomData in pairs(data.rooms) do
                        print("    - " .. roomName .. " (" .. #(roomData.floorParts or {}) .. " floor parts, " .. #(roomData.wallParts or {}) .. " wall parts)")
                    end
                end
            end
        else
            print("\nFloor information not available (FloorAttributeSetup not found)")
        end
        
        -- Equipment info (NEW SECTION)
        if EquipmentManager then
            print("\nEquipment:")
            local equipStats = {
                CARDIO = 0,
                STRENGTH = 0,
                SPECIALTY = 0,
                AMENITIES = 0,
                STRUCTURE = 0
            }
            
            -- Count equipment by category
            for _, model in pairs(tycoon:GetDescendants()) do
                if model:IsA("Model") then
                    local category = model:GetAttribute("Category")
                    if category and equipStats[category] then
                        equipStats[category] = equipStats[category] + 1
                    end
                end
            end
            
            -- Report counts
            local totalEquipment = 0
            for cat, count in pairs(equipStats) do
                print("- " .. cat .. ": " .. count)
                totalEquipment = totalEquipment + count
            end
            
            print("Total equipment: " .. totalEquipment)
        else
            print("\nEquipment information not available (EquipmentManager not found)")
        end
        
        -- Tile info
        if BuyTileSystem and BuyTileSystem.tileData then
            local tileCount = 0
            local floorTiles = {}
            
            for tileType, data in pairs(BuyTileSystem.tileData) do
                tileCount = tileCount + 1
                local floor = data.floor or 1
                
                if not floorTiles[floor] then
                    floorTiles[floor] = 0
                end
                floorTiles[floor] = floorTiles[floor] + 1
            end
            
            print("\nTile Data:")
            print("- Total tiles: " .. tileCount)
            
            for floor, count in pairs(floorTiles) do
                print("- Floor " .. floor .. ": " .. count .. " tiles")
            end
        else
            print("\nTile information not available (BuyTileSystem not found)")
        end
        
        -- Hitbox info
        local hitboxCount = 0
        for _, desc in pairs(tycoon:GetDescendants()) do
            if desc.Name == "Hitbox" and desc:IsA("BasePart") then
                hitboxCount = hitboxCount + 1
            end
        end
        
        print("\nHitboxes:")
        print("- Total hitboxes: " .. hitboxCount)
    end
    
    print("✓ Registered global function: _G.AutomateGym(tycoonName)")
    print("✓ Registered global function: _G.AutomateAllGyms()")
    print("✓ Registered global function: _G.GenerateBuildOrder()")
    print("✓ Registered global function: _G.ShowTycoonInfo(tycoonName)")
    print("✓ Registered global function: _G.ShowHitboxes()")
    print("✓ Registered global function: _G.HideHitboxes()")
    print("✓ Registered global function: _G.ProcessEquipment()")
end

-- Return the GymAutomation module
return GymAutomation