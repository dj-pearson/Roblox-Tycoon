--[[
    EquipmentSetup.server.luau
    
    Utility script to help set up existing equipment models
    for the EquipmentUpgradeSystem by adding necessary attributes.
    
    Created: April 2025
]]

local EquipmentSetup = {}

-- Equipment type definitions - add more as needed
local EQUIPMENT_TYPES = {
    -- Cardio Equipment
    {typeName = "Treadmill", keywords = {"treadmill"}, category = "Cardio", basePrice = 2000, incomeBonus = 5},
    {typeName = "Elliptical", keywords = {"elliptical"}, category = "Cardio", basePrice = 2500, incomeBonus = 6},
    {typeName = "StationaryBike", keywords = {"bike", "stationary", "cycle"}, category = "Cardio", basePrice = 1800, incomeBonus = 4},
    {typeName = "StairClimber", keywords = {"stair", "climber", "stepper"}, category = "Cardio", basePrice = 3000, incomeBonus = 7},
    {typeName = "RowingMachine", keywords = {"row", "rowing"}, category = "Cardio", basePrice = 2800, incomeBonus = 6},
    
    -- Strength Equipment
    {typeName = "BenchPress", keywords = {"bench", "press"}, category = "Strength", basePrice = 2200, incomeBonus = 7},
    {typeName = "SquatRack", keywords = {"squat", "rack"}, category = "Strength", basePrice = 3500, incomeBonus = 9},
    {typeName = "DumbbellRack", keywords = {"dumbbell", "dumbell"}, category = "Strength", basePrice = 1500, incomeBonus = 5},
    {typeName = "LegPress", keywords = {"leg", "press"}, category = "Strength", basePrice = 2800, incomeBonus = 7},
    {typeName = "CableMachine", keywords = {"cable", "pulley"}, category = "Strength", basePrice = 3200, incomeBonus = 8},
    
    -- Add more equipment types as needed
}

-- Process a folder of equipment and add appropriate attributes
function EquipmentSetup.SetupEquipmentFolder(folder)
    if not folder then
        warn("EquipmentSetup: Invalid folder provided")
        return
    end
    
    local setupCount = 0
    
    -- Process each item in the folder
    for _, item in ipairs(folder:GetChildren()) do
        -- Only process Models and BaseParts
        if not (item:IsA("Model") or item:IsA("BasePart")) then
            continue
        end
        
        -- Skip if already has equipmentType set
        if item:GetAttribute("equipmentType") then
            continue
        end
        
        -- Try to determine equipment type from name
        local equipmentType, category, basePrice, incomeBonus = EquipmentSetup.DetermineEquipmentType(item.Name)
        
        if equipmentType then
            -- Add attributes
            item:SetAttribute("equipmentType", equipmentType)
            item:SetAttribute("category", category)
            item:SetAttribute("basePrice", basePrice)
            item:SetAttribute("incomeBonus", incomeBonus)
            item:SetAttribute("upgradeLevel", 0) -- Start at level 0 (base level)
            item:SetAttribute("EquipmentId", item.Name .. "_" .. tostring(math.random(1000, 9999)))
            
            setupCount += 1
            print("EquipmentSetup: Set up", item.Name, "as", equipmentType)
        else
            warn("EquipmentSetup: Could not determine type for", item.Name)
        end
    end
    
    print("EquipmentSetup: Completed setup for", setupCount, "items in", folder.Name)
    return setupCount
end

-- Determine equipment type from name
function EquipmentSetup.DetermineEquipmentType(name)
    local lowerName = string.lower(name)
    
    -- Check each equipment type
    for _, equipType in ipairs(EQUIPMENT_TYPES) do
        -- Check keywords
        for _, keyword in ipairs(equipType.keywords) do
            if string.find(lowerName, string.lower(keyword)) then
                return equipType.typeName, equipType.category, equipType.basePrice, equipType.incomeBonus
            end
        end
    end
    
    return nil
end

-- Manually set equipment type and attributes for a model
function EquipmentSetup.SetEquipmentType(model, equipmentType, category, basePrice, incomeBonus)
    if not model then
        warn("EquipmentSetup: Invalid model provided")
        return
    end
    
    -- Find the equipment type in our definitions
    local foundType
    for _, equipType in ipairs(EQUIPMENT_TYPES) do
        if equipType.typeName == equipmentType then
            foundType = equipType
            break
        end
    end
    
    -- Use provided values or defaults from found type
    category = category or (foundType and foundType.category) or "Misc"
    basePrice = basePrice or (foundType and foundType.basePrice) or 2000
    incomeBonus = incomeBonus or (foundType and foundType.incomeBonus) or 5
    
    -- Add attributes
    model:SetAttribute("equipmentType", equipmentType)
    model:SetAttribute("category", category)
    model:SetAttribute("basePrice", basePrice)
    model:SetAttribute("incomeBonus", incomeBonus)
    model:SetAttribute("upgradeLevel", 0) -- Start at level 0 (base level)
    
    -- Only set equipment ID if not already set
    if not model:GetAttribute("EquipmentId") then
        model:SetAttribute("EquipmentId", model.Name .. "_" .. tostring(math.random(1000, 9999)))
    end
    
    print("EquipmentSetup: Manually set up", model.Name, "as", equipmentType)
end

-- Process all equipment in a tycoon
function EquipmentSetup.SetupTycoonEquipment(tycoon)
    if not tycoon then
        warn("EquipmentSetup: Invalid tycoon provided")
        return
    end
    
    local equipmentFolder = tycoon:FindFirstChild("Equipment")
    if not equipmentFolder then
        warn("EquipmentSetup: Equipment folder not found in tycoon")
        return
    end
    
    return EquipmentSetup.SetupEquipmentFolder(equipmentFolder)
end

-- Command functions for developer console
local function ProcessEquipmentFolder(folderPath)
    local success, folder = pcall(function()
        return game:GetService("Workspace"):FindFirstChild(folderPath, true)
    end)
    
    if success and folder then
        return EquipmentSetup.SetupEquipmentFolder(folder)
    else
        warn("ProcessEquipmentFolder: Could not find folder at", folderPath)
        return 0
    end
end

-- Export with command for developer console
return setmetatable(EquipmentSetup, {
    __call = function(_, folderPath)
        return ProcessEquipmentFolder(folderPath)
    end
})