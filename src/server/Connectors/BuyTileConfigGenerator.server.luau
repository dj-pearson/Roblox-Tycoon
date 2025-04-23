--[[
    BuyTileConfigGenerator.server.luau - 
    
    Automatically analyzes your gym models and generates BuyTile configuration data.
    Instead of manually defining every tile in BuyTileSystem, this script:
    1. Scans the physical gym models in your game
    2. Auto-detects equipment types, floors, and categories
    3. Generates a complete tileData configuration table
    4. Detects logical prerequisites based on positioning
    5. Suggests a build order
    
    Usage: Run _G.GenerateBuyTileConfig() from the command bar
    
    Author: Created April 20, 2025
]]

local ServerStorage = game:GetService("ServerStorage")
local GymStructure = require(ServerStorage.AutomationLoader.Core.GymStructureIntegration)

-- Constants for categorization
local CATEGORY_KEYWORDS = {
    STRUCTURE = {"wall", "floor", "ceiling", "door", "window", "stairs", "foundation", "column", "beam", "pillar", "roof"},
    CARDIO = {"treadmill", "bike", "bicycle", "elliptical", "rowing", "stair", "climber", "cardio"},
    STRENGTH = {"bench", "press", "rack", "dumbbell", "barbell", "weight", "smith", "squat", "deadlift", "leg", "cable", "pulldown", "curl", "strength"},
    AMENITIES = {"water", "fountain", "locker", "towel", "shower", "bathroom", "restroom", "changing", "amenity"},
    SPECIALTY = {"sauna", "pool", "spa", "basketball", "court", "massage", "specialty", "yoga", "pilates", "stretching"},
    STAFF = {"desk", "reception", "office", "trainer", "staff", "employee"}
}

-- Detection thresholds
local PROXIMITY_THRESHOLD = 15 -- Units for detecting nearby models as prerequisites
local BUILD_ORDER_SPACING = 5  -- Gap between build order numbers for buffer

-- Generate BuyTile configuration from workspace models
local function GenerateBuyTileConfig()
    print("BuyTileConfigGenerator: Starting configuration generation...")
    
    -- Collection of all models
    local allModels = {}
    local floors = {}
    local nextBuildOrder = 1
    
    local gymAreas = GymStructure.getAreas()

    -- Floor detection
    local function detectFloor(model)
        -- Try to get from attribute first
        local floorAttr = model:GetAttribute("Floor")
        if floorAttr and type(floorAttr) == "number" then
            print("Floor attribute found:", floorAttr)
            return floorAttr
        end
        
        -- Check if the model is within a defined area and get the floor from there
        local position = model:GetPivot().Position
        for areaName, area in pairs(gymAreas) do
            if area.Bounds then
                local cf = area.Bounds.CFrame
                local size = area.Bounds.Size

                local objectToWorld = cf:ToObjectSpace(CFrame.new(position))
                local x, y, z = objectToWorld:ToWorldCoordinates()

                if math.abs(x) <= size.X / 2 and math.abs(y) <= size.Y / 2 and math.abs(z) <= size.Z / 2 then
                    if area.Floor then
                        print("Detected area:", areaName, "Floor:", area.Floor)
                        return area.Floor
                    end
                end
            end
        else
            -- Calculate average position of all parts
            local totalPos = Vector3.new(0, 0, 0)
            local partCount = 0
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    totalPos += part.Position
                    partCount += 1
                end
            end
            
            position = partCount > 0 and totalPos / partCount or position -- Use original position if no parts found
        end
        
        -- Detect floor based on Y position
        local floorNumber = math.floor(position.Y / 20) + 1 -- Assuming 20 units per floor

        print("Detected floor by Y position:", floorNumber)
        
        -- Clamp to reasonable range (1-6)
        return math.clamp(floorNumber, 1, 6)
    end
    
    -- Detect category based on model name and attributes
    local function detectCategory(model)
        local name = model.Name:lower()
        
        -- Check existing category attribute
        local categoryAttr = model:GetAttribute("Category")
        if categoryAttr and type(categoryAttr) == "string" then
            return categoryAttr
        end
        
        -- Check keywords
        for category, keywords in pairs(CATEGORY_KEYWORDS) do
            for _, keyword in ipairs(keywords) do
                if string.find(name, keyword) then
                    return category
                end
            end
        end
        
        -- Default to STRUCTURE if uncertain
        return "STRUCTURE"
    end
    
    -- Function to estimate if a model is required (essential)
    local function isRequiredModel(model, floor, category)
        -- Structure elements on the ground floor are usually required
        if category == "STRUCTURE" and floor == 1 then
            return true
        end
        
        -- Check name for keywords suggesting requirements
        local name = model.Name:lower()
        local requiredKeywords = {"main", "entrance", "required", "essential", "core", "primary", "base", "foundation"}
        for _, keyword in ipairs(requiredKeywords) do
            if string.find(name, keyword) then
                return true
            end
        end
        
        -- Otherwise, assume optional
        return false
    end
    
    -- Generate a clean tile type name
    local function generateTileTypeName(model)
        -- Remove spaces and special characters
        local name = model.Name:gsub("%s+", ""):gsub("[^%w]", "")
        
        -- If the name starts with a number, prefix it
        if name:match("^%d") then
            name = "Tile" .. name
        end
        
        return name
    end
    
    -- Detect proximity-based prerequisites
    local function detectPrerequisites(model, floor, allModels)
        local prerequisites = {}
        
        local modelPosition
        if model:IsA("Model") and model.PrimaryPart then
            modelPosition = model.PrimaryPart.Position
        elseif model:IsA("BasePart") then
            modelPosition = model.Position
        else
            -- Calculate average position of all parts
            local totalPos = Vector3.new(0, 0, 0)
            local partCount = 0
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    totalPos += part.Position
                    partCount += 1
                end
            end
            
            if partCount > 0 then
                modelPosition = totalPos / partCount
            else
                return {} -- Can't determine position
            end
        end
        
        -- Look for nearby models on same or lower floors
        for _, otherModel in ipairs(allModels) do
            if otherModel.model == model then continue end
            if otherModel.floor > floor then continue end

            local otherPosition
            local otherModelObj = otherModel.model
            if otherModelObj:IsA("Model") and otherModelObj.PrimaryPart then
                otherPosition = otherModelObj.PrimaryPart.Position
            elseif otherModelObj:IsA("BasePart") then
                otherPosition = otherModelObj.Position
            else
                -- Skip if position can't be determined
                continue
            end

            -- Check if within proximity threshold
            local distance = (modelPosition - otherPosition).Magnitude
            if distance < PROXIMITY_THRESHOLD and otherModel.buildOrder < nextBuildOrder then
                table.insert(prerequisites, otherModel.tileType)
                
                -- Limit to 3 prerequisites max for cleanliness
                if #prerequisites >= 3 then
                    break
                end
            end
        end
        
        return prerequisites
    end
    
    -- Get base price based on category and floor
    local function estimateBasePrice(category, floor, isRequired)
        local basePrice = 250
        
        -- Adjust base price by category
        local categoryMultipliers = {
            STRUCTURE = 0.75,
            CARDIO = 1.25,
            STRENGTH = 1.5,
            AMENITIES = 1.0,
            SPECIALTY = 2.0,
            STAFF = 1.75
        }
        
        basePrice *= categoryMultipliers[category] or 1.0
        
        -- Higher floors cost slightly more
        basePrice *= (1.0 + (floor - 1) * 0.25)
        
        -- Required items are slightly cheaper
        if not isRequired then
            basePrice *= 1.2
        end
        
        -- Round to nearest 25
        return math.floor((basePrice + 12.5) / 25) * 25
    end
    
    -- Collect all model information
    local function scanModels(parent, currentFloor)
        currentFloor = currentFloor or 0
        
        -- Check if this is a floor folder
        local isFloorFolder = string.find(parent.Name:lower(), "floor") or 
                             string.find(parent.Name:lower(), "level") or
                             string.find(parent.Name:lower(), "story") or
                             parent.Name:lower() == "roof" or
                             parent.Name:lower() == "ground"
        
        if isFloorFolder then
            -- Try to extract floor number
            local floorNum = string.match(parent.Name, "(%d+)")
            if floorNum then
                currentFloor = tonumber(floorNum)
            elseif parent.Name:lower() == "ground" then
                currentFloor = 0
            elseif parent.Name:lower() == "roof" then
                currentFloor = 5
            end
        end
        
        -- Process children
        for _, child in ipairs(parent:GetChildren()) do
            -- Skip non-model objects and empty containers
            if not (child:IsA("Model") or child:IsA("BasePart") or child:IsA("Folder")) then
                continue
            end
            
            -- Recursively scan folders
            if child:IsA("Folder") then
                scanModels(child, currentFloor)
                continue
            end
            
            -- Skip invisible or tiny models
            local hasParts = false
            for _, desc in ipairs(child:GetDescendants()) do
                if desc:IsA("BasePart") then
                    hasParts = true
                    break
                end
            end
            
            if not hasParts then
                continue
            end
            
            -- Detect model properties
            local floor = detectFloor(child)
            local category = detectCategory(child)
            
            -- Keep track of floors
            if not floors[floor] then
                floors[floor] = true
            end
            
            -- Generate tile type name
            local tileType = generateTileTypeName(child)
            
            -- Check for duplicates and adjust name if needed
            local nameCount = 1
            local baseTileType = tileType
            while true do
                local isDuplicate = false
                for _, existingModel in ipairs(allModels) do
                    if existingModel.tileType == tileType then
                        isDuplicate = true
                        break
                    end
                end
                
                if not isDuplicate then
                    break
                end
                
                nameCount += 1
                tileType = baseTileType .. tostring(nameCount)
            end
            
            -- Store model info
            table.insert(allModels, {
                model = child,
                name = child.Name,
                tileType = tileType,
                floor = floor,
                category = category,
                buildOrder = nextBuildOrder,
                position = child:GetPivot().Position
            })
            
            -- Increment build order for next item
            nextBuildOrder += BUILD_ORDER_SPACING
        end
    end
    
    -- Scan all models in the gym
    scanModels(GymStructure.getGymParts())
    
    -- Sort models by floor and then by approximate position on each floor
    table.sort(allModels, function(a, b)
        if a.floor ~= b.floor then
            return a.floor < b.floor
        end
        
        -- On the same floor, sort by approximate position (X+Z)
        local aPos = a.position
        local bPos = b.position
        return (aPos.X + aPos.Z) < (bPos.X + bPos.Z)
    end)
    
    -- Re-assign build orders based on sorted position
    for i, model in ipairs(allModels) do
        model.buildOrder = i * BUILD_ORDER_SPACING
    end
    
    -- Detect prerequisites based on proximity
    for i, model in ipairs(allModels) do
        model.prerequisites = detectPrerequisites(model.model, model.floor, allModels)
    end
    
    -- Generate the BuyTileSystem configuration table
    local tableCode = "--[[" .. "\n"
    tableCode = tableCode .. "    BuyTileSystem.tileData - Auto-generated on " .. os.date() .. "\n"
    tableCode = tableCode .. "    Generated from " .. #allModels .. " models across " .. #floors .. " floors" .. "\n"
    tableCode = tableCode .. "]]" .. "\n\n"
    tableCode = tableCode .. "BuyTileSystem.tileData = {" .. "\n"
    
    for _, model in ipairs(allModels) do
        local isRequired = isRequiredModel(model.model, model.floor, model.category)
        local basePrice = estimateBasePrice(model.category, model.floor, isRequired)
        local incomeBonus = math.floor(basePrice / 25) -- Simple ratio-based bonus
        
        -- Determine next item
        local nextItem = nil
        for i, nextModel in ipairs(allModels) do
            if nextModel.buildOrder > model.buildOrder then
                nextItem = nextModel.tileType
                break
            end
        end
        
        -- Format prerequisites string
        local prerequisitesString = "nil"
        if #model.prerequisites > 0 then
            prerequisitesString = "{"
            for i, prereq in ipairs(model.prerequisites) do
                prerequisitesString = prerequisitesString .. "\"" .. prereq .. "\""
                if i < #model.prerequisites then
                    prerequisitesString = prerequisitesString .. ", "
                end
            end
            prerequisitesString = prerequisitesString .. "}"
        end
        
        -- Add model entry
        tableCode = tableCode .. "    [\"" .. model.tileType .. "\"] = {" .. "\n"
        tableCode = tableCode .. "        basePrice = " .. basePrice .. "," .. "\n"
        tableCode = tableCode .. "        incomeBonus = " .. incomeBonus .. "," .. "\n"
        if nextItem then
            tableCode = tableCode .. "        nextItem = \"" .. nextItem .. "\"," .. "\n"
        else
            tableCode = tableCode .. "        nextItem = nil," .. "\n"
        end
        tableCode = tableCode .. "        category = CATEGORIES." .. model.category .. "," .. "\n"
        tableCode = tableCode .. "        description = \"" .. model.name .. "\"," .. "\n"
        tableCode = tableCode .. "        modelName = \"" .. model.tileType .. "\"," .. "\n"
        tableCode = tableCode .. "        floor = FLOORS." .. (model.floor == 1 and "GROUND" or model.floor == 5 and "ROOF" or "FLOOR_" .. model.floor) .. "," .. "\n"
        tableCode = tableCode .. "        buildOrder = " .. model.buildOrder .. "," .. "\n"
        
        if #model.prerequisites > 0 then
            tableCode = tableCode .. "        prerequisites = " .. prerequisitesString .. "," .. "\n"
        end
        
        tableCode = tableCode .. "        isRequired = " .. tostring(isRequired) .. "," .. "\n"
        tableCode = tableCode .. "    }," .. "\n"
    end
    
    tableCode = tableCode .. "}" .. "\n"
    
    -- Create StringValue in ServerStorage to store the generated code
    local configValue = ServerStorage:FindFirstChild("GeneratedBuyTileConfig")
    if not configValue then
        configValue = Instance.new("StringValue")
        configValue.Name = "GeneratedBuyTileConfig"
        configValue.Parent = ServerStorage
    end
    
    configValue.Value = tableCode
    
    -- Print summary
    print("BuyTileConfigGenerator: Generated configuration for " .. #allModels .. " models across " .. #floors .. " floors")
    print("Stored in ServerStorage.GeneratedBuyTileConfig")
    print("To use this configuration, copy the content and replace BuyTileSystem.tileData in your BuyTileSystem.server.luau file")
    
    return tableCode
end

-- Export global function for command line
_G.GenerateBuyTileConfig = function()
    return GenerateBuyTileConfig()
end

-- Return module
return {
    GenerateConfig = GenerateBuyTileConfig
}