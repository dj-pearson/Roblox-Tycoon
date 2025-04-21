--[[
    GymPartsSetupCommand.luau
    
    Command line script to add necessary attributes to models in the GymParts folder.
    Copy and paste this entire function into the Roblox Studio Command Bar to run it.
    
    Created: April 19, 2025
]]

-- Equipment type definitions with defaults
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
    
    -- Miscellaneous Equipment
    {typeName = "WaterFountain", keywords = {"water", "fountain"}, category = "Amenities", basePrice = 500, incomeBonus = 1},
    {typeName = "LockerRoom", keywords = {"locker"}, category = "Amenities", basePrice = 1500, incomeBonus = 3},
    
    -- Default for unknown equipment
    {typeName = "GenericEquipment", keywords = {}, category = "Misc", basePrice = 1000, incomeBonus = 2}
}

-- Function to determine equipment type from name
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
    
    -- Return default values if no match
    local default = EQUIPMENT_TYPES[#EQUIPMENT_TYPES]
    return default.typeName, default.category, default.basePrice, default.incomeBonus
end

-- Setup attributes for a model
local function SetupModelAttributes(model)
    -- Check if it's a valid model
    if not (model:IsA("Model") or model:IsA("BasePart")) then
        print("Skipping " .. model.Name .. " - Not a model or part")
        return false
    end
    
    local changed = false
    
    -- Try to determine equipment type from name
    local equipmentType, category, basePrice, incomeBonus = DetermineEquipmentType(model.Name)
    
    -- Add equipmentType attribute if missing
    if not model:GetAttribute("equipmentType") then
        model:SetAttribute("equipmentType", equipmentType)
        changed = true
    end
    
    -- Add category attribute if missing
    if not model:GetAttribute("category") then
        model:SetAttribute("category", category)
        changed = true
    end
    
    -- Add basePrice attribute if missing
    if not model:GetAttribute("basePrice") then
        model:SetAttribute("basePrice", basePrice)
        changed = true
    end
    
    -- Add incomeBonus attribute if missing
    if not model:GetAttribute("incomeBonus") then
        model:SetAttribute("incomeBonus", incomeBonus)
        changed = true
    end
    
    -- Add upgradeLevel attribute if missing
    if not model:GetAttribute("upgradeLevel") then
        model:SetAttribute("upgradeLevel", 0)
        changed = true
    end
    
    -- Add EquipmentId attribute if missing
    if not model:GetAttribute("EquipmentId") then
        model:SetAttribute("EquipmentId", model.Name .. "_" .. tostring(math.random(1000, 9999)))
        changed = true
    end
    
    return changed
end

-- Main function to process all models in GymParts
local function ProcessGymParts()
    -- Find GymParts folder
    local gymPartsFolder = workspace:FindFirstChild("GymParts")
    
    if not gymPartsFolder then
        print("GymParts folder not found in workspace!")
        return
    end
    
    local count = 0
    
    -- Process each item in GymParts
    for _, item in ipairs(gymPartsFolder:GetDescendants()) do
        if item:IsA("Model") or item:IsA("BasePart") then
            if SetupModelAttributes(item) then
                count = count + 1
                print("Setup attributes for: " .. item:GetFullName())
            end
        end
    end
    
    print("Completed! Added attributes to " .. count .. " models in GymParts")
end

-- Run the function
ProcessGymParts()