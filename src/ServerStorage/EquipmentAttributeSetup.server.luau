--[[
    EquipmentAttributeSetup.server.luau - 
    
    Command line script to add the necessary attributes to all equipment models
    in the GymParts folder. Just run this script once in Studio to set up 
    all equipment for the upgrade system.
    
    Created: April 2025
]]

-- Services
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- Only run in Studio
if not RunService:IsStudio() then
    warn("EquipmentAttributeSetup: This script should only be run in Studio")
    return
end

print("=== Equipment Attribute Setup ===")
print("Running attribute setup on GymParts folder...")

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
    {typeName = "SmithMachine", keywords = {"smith"}, category = "Strength", basePrice = 4000, incomeBonus = 9},
    
    -- Free Weights
    {typeName = "Dumbbells", keywords = {"dumbbell", "dumb bell", "free weight"}, category = "Free Weights", basePrice = 1000, incomeBonus = 3},
    {typeName = "WeightPlate", keywords = {"weight", "plate", "disc"}, category = "Free Weights", basePrice = 800, incomeBonus = 2},
    {typeName = "Kettlebell", keywords = {"kettle", "bell"}, category = "Free Weights", basePrice = 1200, incomeBonus = 3},
    
    -- Misc
    {typeName = "YogaMat", keywords = {"yoga", "mat"}, category = "Wellness", basePrice = 500, incomeBonus = 2},
    {typeName = "BoxingBag", keywords = {"box", "boxing", "punching"}, category = "Combat", basePrice = 1500, incomeBonus = 4},
    {typeName = "FoamRoller", keywords = {"foam", "roller"}, category = "Wellness", basePrice = 300, incomeBonus = 1}
}

-- Keep track of setup statistics
local stats = {
    total = 0,
    setupComplete = 0,
    partialSetup = 0,
    failed = 0,
    gymParts = 0
}

-- Determine equipment type from name
local function DetermineEquipmentType(name)
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

-- Add attributes to a model if needed
local function SetupEquipmentAttributes(item)
    stats.total += 1
    
    -- Skip if not a Model or BasePart
    if not (item:IsA("Model") or item:IsA("BasePart")) then
        stats.failed += 1
        return false
    end
    
    local attributes = {
        equipmentType = nil,
        category = nil,
        basePrice = nil,
        incomeBonus = nil,
        upgradeLevel = nil,
        ID = nil  -- Using "ID" instead of "EquipmentId" to match your existing attribute name
    }
    
    -- Check for existing attributes
    local hasAllAttributes = true
    local hasAnyAttribute = false
    
    for attrName, _ in pairs(attributes) do
        if item:GetAttribute(attrName) ~= nil then
            attributes[attrName] = item:GetAttribute(attrName)
            hasAnyAttribute = true
        else
            hasAllAttributes = false
        end
    end
    
    -- If already has all attributes, just count it
    if hasAllAttributes then
        stats.setupComplete += 1
        return true
    end
    
    -- Try to determine equipment type from name if needed
    if not attributes.equipmentType then
        local equipType, category, basePrice, incomeBonus = DetermineEquipmentType(item.Name)
        
        if equipType then
            attributes.equipmentType = equipType
            attributes.category = category
            attributes.basePrice = basePrice
            attributes.incomeBonus = incomeBonus
        else
            -- If can't determine type, use generic values
            attributes.equipmentType = "Generic"
            attributes.category = "Equipment"
            attributes.basePrice = 1000
            attributes.incomeBonus = 2
        end
    end
    
    -- Set default values for other missing attributes
    attributes.upgradeLevel = attributes.upgradeLevel or 0
    attributes.ID = attributes.ID or math.random(1000, 9999)  -- Using existing ID format
    
    -- Apply all attributes
    for attrName, value in pairs(attributes) do
        if item:GetAttribute(attrName) == nil and value ~= nil then
            item:SetAttribute(attrName, value)
        end
    end
    
    -- Count as success
    if hasAnyAttribute then
        stats.partialSetup += 1
    else
        stats.setupComplete += 1
    end
    
    return true
end

-- Find the GymParts folder
local gymParts = workspace:FindFirstChild("GymParts")

if not gymParts then
    warn("EquipmentAttributeSetup: Could not find GymParts folder in workspace!")
    
    -- Try to find any folder that might be it
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") then
            if string.find(string.lower(child.Name), "gym") or string.find(string.lower(child.Name), "equipment") then
                print("EquipmentAttributeSetup: Found potential gym equipment folder:", child.Name)
                print("EquipmentAttributeSetup: Processing this folder instead...")
                gymParts = child
                break
            end
        end
    end
    
    -- If still not found, try other common names
    if not gymParts then
        local potentialNames = {"Gym", "Equipment", "Fitness", "GymEquipment", "TycoonParts"}
        for _, name in ipairs(potentialNames) do
            local potential = workspace:FindFirstChild(name)
            if potential then
                print("EquipmentAttributeSetup: Found potential gym equipment folder:", potential.Name)
                print("EquipmentAttributeSetup: Processing this folder instead...")
                gymParts = potential
                break
            end
        end
    end
    
    -- If still not found, exit
    if not gymParts then
        print("EquipmentAttributeSetup: No suitable folders found. Please rename your gym equipment folder to 'GymParts'")
        return
    end
end

print("EquipmentAttributeSetup: Processing", gymParts.Name, "folder...")

-- Process all models in the GymParts folder (recursive)
local function ProcessFolder(folder, depth)
    depth = depth or 0
    stats.gymParts += 1
    
    -- Process all children
    for _, child in ipairs(folder:GetChildren()) do
        -- If it's a model, set up attributes
        if child:IsA("Model") or child:IsA("BasePart") then
            local success = SetupEquipmentAttributes(child)
            if success then
                print(string.rep("  ", depth) .. "✓ Set up", child.Name)
            else
                print(string.rep("  ", depth) .. "✗ Skipped", child.Name, "(not model or part)")
            end
        end
        
        -- If it's a folder, process recursively
        if child:IsA("Folder") or child:IsA("Model") then
            ProcessFolder(child, depth + 1)
        end
    end
end

-- Start processing
ProcessFolder(gymParts)

-- Report results
print("\n=== Equipment Attribute Setup Results ===")
print("Total items processed:", stats.total)
print("Complete setup:", stats.setupComplete)
print("Partial setup (some attributes existed):", stats.partialSetup)
print("Failed setup:", stats.failed)
print("Total GymParts folders processed:", stats.gymParts)
print("\nEquipment Attribute Setup complete!")

-- Self-destruct the script to avoid accidental re-running
script:Destroy()