--[[
    AutoBuyTileSetup.server.luau - 
    
    Automates the process of connecting physical gym models with the BuyTileSystem data.
    This script automatically:
    1. Finds models in the workspace and matches them to BuyTile definitions
    2. Sets up all required attributes
    3. Creates BuyTile hitboxes for any missing ones
    4. Validates prerequisites are logically sound
    5. Creates bounding boxes for proper equipment placement
    
    Use in Studio: Run _G.AutoSetupBuyTiles() from command line
    
    Author: Created April 20, 2025
]]

local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

-- Try to get the CoreRegistry and necessary systems
local CoreRegistry = require(script.Parent.Parent:FindFirstChild("Core"):FindFirstChild("CoreRegistry") or {})
local BuyTileSystem = CoreRegistry and CoreRegistry:GetSystem("BuyTileSystem")
local GymStructureIntegration = CoreRegistry and CoreRegistry:GetSystem("GymStructureIntegration")
local EquipmentSetup = CoreRegistry and CoreRegistry:GetSystem("EquipmentSetup")

-- Keep track of statistics
local stats = {
    modelsFound = 0,
    modelsMatched = 0,
    attributesUpdated = 0,
    hitboxesCreated = 0,
    boundingBoxesCreated = 0,
    prerequisiteErrors = 0,
    duplicateWarnings = 0
}

-- Validate existence of required systems
local function ValidateSystems()
    if not BuyTileSystem then
        warn("AutoBuyTileSetup: BuyTileSystem not found, attempting to load directly")
        
        local buyTileModule = script.Parent.Parent:FindFirstChild("Core"):FindFirstChild("BuyTileSystem")
        if buyTileModule then
            BuyTileSystem = require(buyTileModule)
        else
            error("BuyTileSystem not found. Cannot continue with auto setup")
            return false
        end
    end
    
    -- Try to get GymStructureIntegration
    if not GymStructureIntegration then
        warn("AutoBuyTileSetup: GymStructureIntegration not found, attempting to load directly")
        
        local gymStructureModule = script.Parent.Parent:FindFirstChild("Core"):FindFirstChild("GymStructureIntegration")
        if gymStructureModule then
            GymStructureIntegration = require(gymStructureModule)
        else
            -- This is not critical, but helpful
            warn("GymStructureIntegration not found. Some features will be limited")
        end
    end
    
    -- Try to get EquipmentSetup
    if not EquipmentSetup then
        warn("AutoBuyTileSetup: EquipmentSetup not found, attempting to load directly")
        
        local equipmentSetupModule = script.Parent.Parent:FindFirstChild("Core"):FindFirstChild("EquipmentSetup")
        if equipmentSetupModule then
            EquipmentSetup = require(equipmentSetupModule)
        else
            warn("EquipmentSetup not found. Equipment bounding boxes will not be created")
        end
    end
    
    return true
end

-- Find the best matching BuyTile for a model based on name similarity
local function FindBestMatchingBuyTile(model)
    if not BuyTileSystem or not BuyTileSystem.tileData then
        return nil
    end
    
    local modelName = model.Name:lower()
    local bestMatch = nil
    local bestScore = 0
    
    -- Helper function to calculate string similarity (very basic)
    local function similarity(str1, str2)
        str1 = str1:lower()
        str2 = str2:lower()
        
        -- Direct match
        if str1 == str2 then 
            return 1.0 
        end
        
        -- Contains match
        if str1:find(str2, 1, true) or str2:find(str1, 1, true) then
            return 0.8
        end
        
        -- Words match
        local words1 = {}
        for word in str1:gmatch("%w+") do
            words1[word] = true
        end
        
        local matchingWords = 0
        local totalWords = 0
        for word in str2:gmatch("%w+") do
            if words1[word] then
                matchingWords += 1
            end
            totalWords += 1
        end
        
        if totalWords > 0 and matchingWords > 0 then
            return matchingWords / totalWords * 0.6
        end
        
        return 0
    end
    
    -- Try to match with each tile type
    for tileType, tileData in pairs(BuyTileSystem.tileData) do
        local score = 0
        
        -- Check similarity with tile type name
        score = math.max(score, similarity(modelName, tileType))
        
        -- Check similarity with model name in tile data
        if tileData.modelName then
            score = math.max(score, similarity(modelName, tileData.modelName))
        end
        
        -- Check similarity with description
        if tileData.description then
            score = math.max(score, similarity(modelName, tileData.description))
        end
        
        -- Consider room matching if GymStructureIntegration is available
        if GymStructureIntegration and GymStructureIntegration.FindTileTypeForRoom then
            local potentialRoomName = modelName:gsub("room", ""):gsub("area", ""):trim()
            local matchedTile = GymStructureIntegration:FindTileTypeForRoom(potentialRoomName, tileData.floor)
            if matchedTile and matchedTile == tileType then
                score = math.max(score, 0.7) -- Give room matching a good score
            end
        end
        
        -- Update best match if we found a better one
        if score > bestScore then
            bestScore = score
            bestMatch = {
                tileType = tileType,
                tileData = tileData,
                score = score
            }
        end
    end
    
    -- Only return matches with a reasonable score
    if bestScore >= 0.4 then
        return bestMatch
    end
    
    return nil
end

-- Create a hitbox for a model if it doesn't have one
local function EnsureHitbox(model, tileType)
    -- Check if model already has a hitbox
    local existingHitbox = model:FindFirstChild("Hitbox")
    if existingHitbox then return existingHitbox end
    
    -- Create a new hitbox
    local hitbox = Instance.new("Part")
    hitbox.Name = "Hitbox"
    hitbox.Transparency = 1
    hitbox.CanCollide = false
    hitbox.Anchored = true
    hitbox.CastShadow = false
    
    -- Set the size based on model bounds
    local modelSize
    if model:IsA("Model") and model.PrimaryPart then
        -- Use primary part as reference
        local primaryCFrame = model.PrimaryPart.CFrame
        local modelBounds = model:GetExtentsSize()
        
        hitbox.Size = modelBounds + Vector3.new(2, 1, 2) -- Make hitbox slightly larger
        hitbox.CFrame = primaryCFrame - Vector3.new(0, 1, 0) -- Offset down slightly
    elseif model:IsA("BasePart") then
        -- For a single part, use its size
        hitbox.Size = model.Size + Vector3.new(2, 1, 2)
        hitbox.CFrame = model.CFrame - Vector3.new(0, 1, 0)
    else
        -- For models without primary part, try to calculate bounds
        local minX, minY, minZ = math.huge, math.huge, math.huge
        local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
        
        -- Find all descendant parts and calculate bounds
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                local pos = part.Position
                local size = part.Size
                
                minX = math.min(minX, pos.X - size.X/2)
                minY = math.min(minY, pos.Y - size.Y/2)
                minZ = math.min(minZ, pos.Z - size.Z/2)
                
                maxX = math.max(maxX, pos.X + size.X/2)
                maxY = math.max(maxY, pos.Y + size.Y/2)
                maxZ = math.max(maxZ, pos.Z + size.Z/2)
            end
        end
        
        -- Create a hitbox based on the bounds
        local center = Vector3.new(
            (minX + maxX) / 2,
            (minY + maxY) / 2,
            (minZ + maxZ) / 2
        )
        
        local size = Vector3.new(
            maxX - minX,
            maxY - minY,
            maxZ - minZ
        )
        
        hitbox.Size = size + Vector3.new(2, 1, 2)
        hitbox.CFrame = CFrame.new(center) - Vector3.new(0, 1, 0)
    end
    
    -- Set attributes on the hitbox
    hitbox:SetAttribute("TileType", tileType)
    
    -- Parent the hitbox to the model
    hitbox.Parent = model
    
    stats.hitboxesCreated += 1
    return hitbox
end

-- Validate prerequisites are logically sound
local function ValidatePrerequisites(tileType, tileData)
    if not tileData.prerequisites or #tileData.prerequisites == 0 then
        return true
    end
    
    for _, prereqType in ipairs(tileData.prerequisites) do
        -- Make sure prerequisite exists
        if not BuyTileSystem.tileData[prereqType] then
            warn("AutoBuyTileSetup: Tile " .. tileType .. " has non-existent prerequisite: " .. prereqType)
            stats.prerequisiteErrors += 1
            return false
        end
        
        -- Check that prerequisite is on same or lower floor
        local prereqData = BuyTileSystem.tileData[prereqType]
        if prereqData.floor > tileData.floor then
            warn("AutoBuyTileSetup: Tile " .. tileType .. " has prerequisite " .. prereqType .. " on a higher floor (" .. prereqData.floor .. " > " .. tileData.floor .. ")")
            stats.prerequisiteErrors += 1
            return false
        end
        
        -- Check that buildOrder makes sense
        if prereqData.buildOrder >= tileData.buildOrder then
            warn("AutoBuyTileSetup: Tile " .. tileType .. " (buildOrder " .. tileData.buildOrder .. ") has prerequisite " .. prereqType .. " with higher or equal buildOrder (" .. prereqData.buildOrder .. ")")
            stats.prerequisiteErrors += 1
            return false
        end
    end
    
    return true
end

-- Update a model with BuyTile data
local function UpdateModelWithBuyTileData(model, match)
    local tileType = match.tileType
    local tileData = match.tileData
    
    -- Validate prerequisites
    ValidatePrerequisites(tileType, tileData)
    
    -- Update attributes
    model:SetAttribute("TileType", tileType)
    model:SetAttribute("ModelName", tileData.modelName)
    model:SetAttribute("Price", tileData.basePrice)
    model:SetAttribute("IncomeBonus", tileData.incomeBonus)
    model:SetAttribute("NextItem", tileData.nextItem)
    model:SetAttribute("Description", tileData.description)
    model:SetAttribute("Category", tileData.category)
    model:SetAttribute("Floor", tileData.floor)
    model:SetAttribute("FloorName", BuyTileSystem:GetFloorName(tileData.floor))
    model:SetAttribute("BuildOrder", tileData.buildOrder)
    
    -- Add additional attributes if present
    if tileData.equipmentType then model:SetAttribute("equipmentType", tileData.equipmentType) end
    if tileData.satisfactionBonus then model:SetAttribute("satisfactionBonus", tileData.satisfactionBonus) end
    if tileData.specialFeature then model:SetAttribute("specialFeature", tileData.specialFeature) end
    if tileData.staffRequired then model:SetAttribute("staffRequired", tileData.staffRequired) end
    
    -- Make sure it has a hitbox
    EnsureHitbox(model, tileType)
    
    stats.attributesUpdated += 1
    return true
end

-- Process all models in a tycoon
local function ProcessTycoon(tycoon)
    if not tycoon then return 0 end
    
    print("AutoBuyTileSetup: Processing tycoon: " .. tycoon.Name)
    
    -- Keep track of matched models to avoid duplicates
    local matchedTypes = {}
    local processedCount = 0
    
    -- Function to check if model contains any parts
    local function HasParts(model)
        for _, child in ipairs(model:GetDescendants()) do
            if child:IsA("BasePart") then
                return true
            end
        end
        return false
    end
    
    -- Process all descendants that look like models
    for _, model in ipairs(tycoon:GetDescendants()) do
        -- Only process models with parts
        if (model:IsA("Model") or model:IsA("BasePart")) and HasParts(model) then
            stats.modelsFound += 1
            
            -- Skip models that already have TileType attribute
            if model:GetAttribute("TileType") then
                -- Still count these as processed
                processedCount += 1
                continue
            end
            
            -- Try to find matching BuyTile
            local match = FindBestMatchingBuyTile(model)
            if match then
                -- Check for duplicate tile types in this tycoon
                if matchedTypes[match.tileType] then
                    warn("AutoBuyTileSetup: Duplicate match for tile type " .. match.tileType .. 
                         " between models " .. model.Name .. " and " .. matchedTypes[match.tileType])
                    stats.duplicateWarnings += 1
                else
                    matchedTypes[match.tileType] = model.Name
                end
                
                -- Update model with BuyTile data
                if UpdateModelWithBuyTileData(model, match) then
                    processedCount += 1
                    stats.modelsMatched += 1
                    print("  - Matched " .. model.Name .. " with " .. match.tileType .. " (score: " .. match.score .. ")")
                end
            end
        end
    end
    
    -- Create bounding boxes if EquipmentSetup is available
    if EquipmentSetup and typeof(EquipmentSetup.GenerateBoundingBoxes) == "function" then
        print("AutoBuyTileSetup: Generating bounding boxes for equipment")
        local boxCount = EquipmentSetup:GenerateBoundingBoxes(tycoon)
        if boxCount then
            stats.boundingBoxesCreated += boxCount
        end
    end
    
    return processedCount
end

-- Main function to auto-setup all tycoons
local function AutoSetupAllTycoons()
    -- Validate that we have necessary systems
    if not ValidateSystems() then
        return
    end
    
    print("AutoBuyTileSetup: Starting auto-setup process")
    
    -- Find all tycoons in the workspace
    local tycoons = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") then
            -- Look for names containing "Tycoon"
            if string.find(child.Name, "Tycoon") then
                table.insert(tycoons, child)
            end
        end
    end
    
    -- If no tycoons found, try to look for a template or other common names
    if #tycoons == 0 then
        local templateNames = {"GymTemplate", "Template", "Gym", "GymParts"}
        for _, name in ipairs(templateNames) do
            local template = workspace:FindFirstChild(name)
            if template then
                table.insert(tycoons, template)
                print("AutoBuyTileSetup: No tycoons found, using " .. name .. " as template")
                break
            end
        end
    end
    
    -- Process each tycoon
    local totalProcessed = 0
    for _, tycoon in ipairs(tycoons) do
        totalProcessed += ProcessTycoon(tycoon)
    end
    
    -- Process GymParts folder if it exists
    local gymParts = workspace:FindFirstChild("GymParts")
    if gymParts then
        totalProcessed += ProcessTycoon(gymParts)
    end
    
    -- Print summary
    print("\nAutoSetupBuyTiles: Process complete!")
    print("Models found: " .. stats.modelsFound)
    print("Models matched: " .. stats.modelsMatched)
    print("Attributes updated: " .. stats.attributesUpdated)
    print("Hitboxes created: " .. stats.hitboxesCreated)
    print("Bounding boxes created: " .. stats.boundingBoxesCreated)
    
    if stats.prerequisiteErrors > 0 then
        warn("Prerequisite errors found: " .. stats.prerequisiteErrors)
    end
    
    if stats.duplicateWarnings > 0 then
        warn("Duplicate matches found: " .. stats.duplicateWarnings)
    end
    
    return totalProcessed
end

-- Export with global function for command line
_G.AutoSetupBuyTiles = function()
    AutoSetupAllTycoons()
end

-- Return the module
local AutoBuyTileSetup = {
    AutoSetupAllTycoons = AutoSetupAllTycoons,
    ProcessTycoon = ProcessTycoon
}

return AutoBuyTileSetup