--[[
    EquipmentSetup.server.luau
    
    ===== DEPRECATION NOTICE =====
    This script has been deprecated and is scheduled for removal.
    It has been consolidated into the new EquipmentManager.server.luau module.
    Please use EquipmentManager:SetupEquipmentAttributes() instead of functionality from this script.
    See ConsolidationPlan.md for details on the module consolidation project.
    ===== END NOTICE =====
    
    Original script documentation follows:
    
    A utility script that helps integrate existing equipment models with the new BuyTileSystem 
    and EquipmentUpgradeSystem. This script generates bounding boxes for equipment and prepares
    models for the upgrade system.
    
    Author: Created April 2025
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Attempt to get modules
local EquipmentBoundingBox = require(script.Parent:FindFirstChild("EquipmentBoundingBox"))
local CoreRegistry = require(script.Parent:FindFirstChild("CoreRegistry") or {})

local EquipmentSetup = {}
EquipmentSetup.__index = EquipmentSetup

-- Equipment categories for organization
local CATEGORIES = {
    STRUCTURE = "Structure",
    CARDIO = "Cardio Equipment",
    STRENGTH = "Strength Equipment",
    AMENITIES = "Amenities",
    SPECIALTY = "Specialty Equipment",
    STAFF = "Staff"
}

-- Equipment types for upgrade paths
local EQUIPMENT_TYPES = {
    TREADMILL = "Treadmill",
    ELLIPTICAL = "Elliptical",
    BIKE = "Bike",
    ROWING_MACHINE = "RowingMachine",
    LEG_PRESS = "LegPress",
    CHEST_PRESS = "ChestPress",
    WEIGHT_RACK = "WeightRack",
    BENCH = "Bench"
}

-- Initialize the system
function EquipmentSetup:Initialize()
    -- Register this system with CoreRegistry if it exists
    if CoreRegistry and CoreRegistry.RegisterSystem then
        CoreRegistry:RegisterSystem("EquipmentSetup", self)
    end
    
    -- Store reference to other systems if they exist
    self.buyTileSystem = CoreRegistry and CoreRegistry:GetSystem("BuyTileSystem")
    self.equipmentUpgradeSystem = CoreRegistry and CoreRegistry:GetSystem("EquipmentUpgradeSystem")
    
    return self
end

-- Setup equipment for all player tycoons
function EquipmentSetup:SetupAllTycoons()
    local tycoonSystem = CoreRegistry and CoreRegistry:GetSystem("TycoonSystem")
    if not tycoonSystem then
        warn("EquipmentSetup: TycoonSystem not found")
        return
    end
    
    -- Process each tycoon
    local tycoons = tycoonSystem:GetAllTycoons()
    for _, tycoon in pairs(tycoons) do
        self:SetupTycoonEquipment(tycoon)
    end
end

-- Setup equipment for a specific tycoon
function EquipmentSetup:SetupTycoonEquipment(tycoon)
    if not tycoon then return end
    
    -- Create equipment folders if they don't exist
    local equipmentFolder = tycoon:FindFirstChild("Equipment")
    if not equipmentFolder then
        equipmentFolder = Instance.new("Folder")
        equipmentFolder.Name = "Equipment"
        equipmentFolder.Parent = tycoon
    end
    
    -- Create bounding boxes folder
    local boundingBoxesFolder = tycoon:FindFirstChild("EquipmentBoundingBoxes")
    if not boundingBoxesFolder then
        boundingBoxesFolder = Instance.new("Folder")
        boundingBoxesFolder.Name = "EquipmentBoundingBoxes"
        boundingBoxesFolder.Parent = tycoon
    end
    
    -- Scan for existing equipment and add attributes
    self:ProcessExistingEquipment(tycoon, equipmentFolder)
    
    -- Generate bounding boxes for equipment
    EquipmentBoundingBox.GenerateEquipmentBoundingBoxes(tycoon, equipmentFolder, ServerStorage)
    
    -- Create BuyTiles folder if needed
    local buyTilesFolder = tycoon:FindFirstChild("BuyTiles")
    if not buyTilesFolder then
        buyTilesFolder = Instance.new("Folder")
        buyTilesFolder.Name = "BuyTiles"
        buyTilesFolder.Parent = tycoon
    end
end

-- Process existing equipment in the tycoon
function EquipmentSetup:ProcessExistingEquipment(tycoon, equipmentFolder)
    -- Names of equipment to look for
    local equipmentNames = {
        -- Cardio equipment
        [EQUIPMENT_TYPES.TREADMILL] = {category = CATEGORIES.CARDIO, basePrice = 100, incomeBonus = 10},
        [EQUIPMENT_TYPES.ELLIPTICAL] = {category = CATEGORIES.CARDIO, basePrice = 150, incomeBonus = 15},
        [EQUIPMENT_TYPES.BIKE] = {category = CATEGORIES.CARDIO, basePrice = 120, incomeBonus = 12},
        [EQUIPMENT_TYPES.ROWING_MACHINE] = {category = CATEGORIES.CARDIO, basePrice = 180, incomeBonus = 18},
        
        -- Strength equipment
        [EQUIPMENT_TYPES.LEG_PRESS] = {category = CATEGORIES.STRENGTH, basePrice = 200, incomeBonus = 20},
        [EQUIPMENT_TYPES.CHEST_PRESS] = {category = CATEGORIES.STRENGTH, basePrice = 220, incomeBonus = 22},
        [EQUIPMENT_TYPES.WEIGHT_RACK] = {category = CATEGORIES.STRENGTH, basePrice = 250, incomeBonus = 25},
        [EQUIPMENT_TYPES.BENCH] = {category = CATEGORIES.STRENGTH, basePrice = 80, incomeBonus = 8}
        
        -- Add more equipment as needed
    }
    
    -- Scan through all tycoon descendants
    local equipmentCount = 0
    for _, child in ipairs(tycoon:GetDescendants()) do
        -- Check if this is a model or part that matches equipment names
        if (child:IsA("Model") or child:IsA("BasePart")) and equipmentNames[child.Name] then
            -- Get equipment data
            local equipmentData = equipmentNames[child.Name]
            
            -- Skip if this already has equipment attributes
            if child:GetAttribute("equipmentType") then
                continue
            end
            
            -- Set attributes for equipment
            child:SetAttribute("equipmentType", child.Name)
            child:SetAttribute("category", equipmentData.category)
            child:SetAttribute("basePrice", equipmentData.basePrice)
            child:SetAttribute("incomeBonus", equipmentData.incomeBonus)
            child:SetAttribute("upgradeLevel", 1) -- Default to level 1
            child:SetAttribute("EquipmentId", equipmentCount + 1)
            
            -- Create a unique ID for this piece of equipment
            equipmentCount = equipmentCount + 1
            
            -- Move to equipment folder if not already there
            if child.Parent ~= equipmentFolder then
                -- Store original parent and position
                local originalParent = child.Parent
                local originalCFrame
                
                if child:IsA("Model") and child.PrimaryPart then
                    originalCFrame = child:GetPivot()
                elseif child:IsA("BasePart") then
                    originalCFrame = child.CFrame
                end
                
                -- Create bounding box to remember position
                local boundingBox = EquipmentBoundingBox.CreateBoundingBox(child, child.Name)
                if boundingBox then
                    boundingBox.Parent = tycoon:FindFirstChild("EquipmentBoundingBoxes") or tycoon
                end
                
                -- Only move if not already in equipment folder
                if not self:IsInEquipmentFolder(child) then
                    child.Parent = equipmentFolder
                    
                    -- Restore original position
                    if originalCFrame then
                        if child:IsA("Model") and child.PrimaryPart then
                            child:PivotTo(originalCFrame)
                        elseif child:IsA("BasePart") then
                            child.CFrame = originalCFrame
                        end
                    end
                end
            end
        end
    end
    
    print("EquipmentSetup: Processed " .. equipmentCount .. " pieces of equipment in tycoon")
end

-- Check if an object is already in the equipment folder
function EquipmentSetup:IsInEquipmentFolder(object)
    local current = object.Parent
    while current do
        if current.Name == "Equipment" then
            return true
        end
        current = current.Parent
    end
    return false
end

-- Create a tool to help place bounding boxes manually
function EquipmentSetup:CreateBoundingBoxTool()
    -- This would be used if you want to manually place bounding boxes
    local tool = Instance.new("Tool")
    tool.Name = "BoundingBoxCreator"
    tool.CanBeDropped = false
    
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 2)
    handle.Parent = tool
    
    -- Tool functionality would go here
    
    return tool
end

-- Visualize all bounding boxes for debugging
function EquipmentSetup:VisualizeBoxes(tycoon, show)
    if not tycoon then return end
    EquipmentBoundingBox.VisualizeBoxes(tycoon, show)
end

-- Integrate with the BuyTileSystem
function EquipmentSetup:IntegrateWithBuyTileSystem()
    local buyTileSystem = self.buyTileSystem
    if not buyTileSystem then
        warn("EquipmentSetup: BuyTileSystem not found")
        return
    end
    
    -- Hook into the CreateTile function of BuyTileSystem
    local originalCreateTile = buyTileSystem.CreateTile
    buyTileSystem.CreateTile = function(self, tileType, position, rotation)
        local tile = originalCreateTile(self, tileType, position, rotation)
        
        if tile then
            -- Set equipment attributes if this is equipment
            local equipmentData = EQUIPMENT_TYPES[tileType:upper()]
            if equipmentData then
                tile:SetAttribute("equipmentType", tileType)
                tile:SetAttribute("upgradeLevel", 1) -- Default to level 1
            end
        end
        
        return tile
    end
    
    -- Hook into the HandleTilePurchase function to use bounding boxes
    local originalHandlePurchase = buyTileSystem.HandleTilePurchase
    buyTileSystem.HandleTilePurchase = function(self, player, tileType, position, rotation)
        local tycoonSystem = CoreRegistry and CoreRegistry:GetSystem("TycoonSystem")
        local playerTycoon = tycoonSystem and tycoonSystem:GetPlayerTycoon(player)
        
        if not playerTycoon then
            return originalHandlePurchase(self, player, tileType, position, rotation)
        end
        
        -- Check for bounding box first
        local boundingBoxCFrame = EquipmentBoundingBox.GetBoundingBoxTransform(playerTycoon, tileType)
        if boundingBoxCFrame then
            position = boundingBoxCFrame.Position
            rotation = boundingBoxCFrame - boundingBoxCFrame.Position -- Extract rotation
        end
        
        return originalHandlePurchase(self, player, tileType, position, rotation)
    end
    
    print("EquipmentSetup: Successfully integrated with BuyTileSystem")
end

-- Integrate with the EquipmentUpgradeSystem
function EquipmentSetup:IntegrateWithUpgradeSystem()
    local upgradeSystem = self.equipmentUpgradeSystem
    if not upgradeSystem then
        warn("EquipmentSetup: EquipmentUpgradeSystem not found")
        return
    end
    
    -- Hook into the UpgradeEquipment function
    local originalUpgrade = upgradeSystem.UpgradeEquipment
    upgradeSystem.UpgradeEquipment = function(self, player, equipment, equipmentType, targetLevel)
        -- Preserve position using the original equipment position
        local originalCFrame
        if equipment:IsA("Model") and equipment.PrimaryPart then
            originalCFrame = equipment:GetPivot()
        elseif equipment:IsA("BasePart") then
            originalCFrame = equipment.CFrame
        end
        
        -- Check for bounding box if we don't have position
        if not originalCFrame then
            local tycoonSystem = CoreRegistry and CoreRegistry:GetSystem("TycoonSystem")
            local playerTycoon = tycoonSystem and tycoonSystem:GetPlayerTycoon(player)
            if playerTycoon then
                originalCFrame = EquipmentBoundingBox.GetBoundingBoxTransform(playerTycoon, equipmentType)
            end
        end
        
        -- Call original upgrade method
        local success, result = originalUpgrade(self, player, equipment, equipmentType, targetLevel)
        
        -- Restore position if upgrade successful and we have original position
        if success and originalCFrame and result and (result:IsA("Model") or result:IsA("BasePart")) then
            if result:IsA("Model") and result.PrimaryPart then
                result:PivotTo(originalCFrame)
            elseif result:IsA("BasePart") then
                result.CFrame = originalCFrame
            end
        end
        
        return success, result
    end
    
    print("EquipmentSetup: Successfully integrated with EquipmentUpgradeSystem")
end

-- Setup everything
function EquipmentSetup:Setup()
    self:SetupAllTycoons()
    self:IntegrateWithBuyTileSystem()
    self:IntegrateWithUpgradeSystem()
    return self
end

-- Auto-run on script load
return EquipmentSetup:Initialize():Setup()