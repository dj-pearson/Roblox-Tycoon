--[[
    TileDataGenerator.server.luau
    
    Automatically generates BuyTileSystem data from models in the game.
    This module analyzes models in ServerStorage and workspace to extract
    attributes and create complete tile data entries for the BuyTile system.
    
    Features:
    - Auto-scans model files in ServerStorage folders
    - Extracts embedded attributes from models
    - Auto-categorizes equipment based on naming patterns
    - Determines appropriate build orders
    - Generates logical prerequisites
    
    Author: Created May 2025
]]

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

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
local FloorAttributeSetup = CoreRegistry and CoreRegistry:GetSystem("FloorAttributeSetup")
local BuyTileProgressionManager = CoreRegistry and CoreRegistry:GetSystem("BuyTileProgressionManager")

-- Category based on names and attributes
local CATEGORY_KEYWORDS = {
    STRUCTURE = {"wall", "floor", "ceiling", "door", "window", "stairs", "foundation", "pillar", "beam", "support", "column"},
    CARDIO = {"treadmill", "bike", "bicycle", "elliptical", "rowing", "cardio", "run", "jog", "aerobic"},
    STRENGTH = {"bench", "press", "rack", "dumbbell", "barbell", "weight", "strength", "power", "lift"},
    AMENITIES = {"water", "fountain", "locker", "towel", "shower", "amenity", "vending", "counter", "desk"},
    SPECIALTY = {"sauna", "pool", "spa", "basketball", "court", "specialty", "yoga", "pilates", "stretch"},
    STAFF = {"desk", "reception", "office", "trainer", "staff", "employee", "manager", "admin"}
}

-- Price multipliers by category
local PRICE_MULTIPLIERS = {
    STRUCTURE = 1.0,
    CARDIO = 1.5,
    STRENGTH = 1.75,
    AMENITIES = 1.25,
    SPECIALTY = 2.0,
    STAFF = 1.0
}

-- Price base by floor
local BASE_PRICE_BY_FLOOR = {
    [1] = 100,  -- 1st Floor
    [2] = 250,  -- 2nd Floor
    [3] = 500,  -- 3rd Floor
    [4] = 750,  -- 4th Floor
    [5] = 1000, -- Roof
    [6] = 1500  -- Outside
}

-- TileDataGenerator singleton
local TileDataGenerator = {
    Debug = false
}

-- Log messages if debug is enabled
function TileDataGenerator:Log(message)
    if self.Debug then
        print("[TileDataGenerator] " .. message)
    end
end

-- Find all model folders that could contain BuyTile models
function TileDataGenerator:FindModelFolders()
    local folders = {}
    
    -- Check ServerStorage/BuyTiles
    local buyTilesFolder = ServerStorage:FindFirstChild("BuyTiles")
    if buyTilesFolder then
        table.insert(folders, {folder = buyTilesFolder, source = "ServerStorage.BuyTiles"})
    end
    
    -- Check other common locations
    for _, path in ipairs({"Models", "EquipmentModels", "GymEquipment", "TileModels"}) do
        local folder = ServerStorage:FindFirstChild(path)
        if folder then
            table.insert(folders, {folder = folder, source = "ServerStorage." .. path})
        end
    end
    
    -- Check ReplicatedStorage if no folders found in ServerStorage
    if #folders == 0 then
        for _, path in ipairs({"BuyTiles", "Models", "EquipmentModels", "GymEquipment", "TileModels"}) do
            local folder = ReplicatedStorage:FindFirstChild(path)
            if folder then
                table.insert(folders, {folder = folder, source = "ReplicatedStorage." .. path})
            end
        end
    end
    
    self:Log("Found " .. #folders .. " model folders")
    return folders
end

-- Extract attributes from a model
function TileDataGenerator:ExtractModelAttributes(model)
    if not model then return {} end
    
    local attributes = {}
    
    -- Function to copy attributes from an instance to our table
    local function copyAttributes(instance)
        for name, value in pairs(instance:GetAttributes()) do
            -- Don't overwrite existing values from higher up in hierarchy
            if attributes[name] == nil then
                attributes[name] = value
            end
        end
    end
    
    -- First, get attributes from the model itself
    copyAttributes(model)
    
    -- For normal Studio models with a PrimaryPart
    if model:IsA("Model") and model.PrimaryPart then
        copyAttributes(model.PrimaryPart)
    end
    
    -- If no TileType found, generate one from name
    if not attributes.TileType then
        local tileType = model.Name:gsub("%s+", ""):gsub("[^%w]", "")
        if tileType:match("^%d") then
            tileType = "Tile" .. tileType -- Ensure it doesn't start with a number
        end
        attributes.TileType = tileType
    end
    
    -- If no ModelName found, use the model's name
    if not attributes.ModelName then
        attributes.ModelName = model.Name
    end
    
    -- If no Description found, use the model name
    if not attributes.Description then
        attributes.Description = model.Name:gsub("([A-Z])", " %1"):gsub("^%s+", "")  -- Add spaces before capital letters for readability
    end
    
    -- Check for floor assignment
    if not attributes.Floor then
        -- Try to derive floor from parent folder name
        local parent = model.Parent
        while parent and not attributes.Floor do
            -- Check if parent name contains floor info
            if FloorAttributeSetup then
                local floorNumber = FloorAttributeSetup:GetFloorNumberFromName(parent.Name)
                if floorNumber then
                    attributes.Floor = floorNumber
                    break
                end
            end
            parent = parent.Parent
        end
        
        -- Default to 1st floor if not found
        if not attributes.Floor then
            attributes.Floor = 1
        end
    end
    
    -- Detect category if not specified
    if not attributes.Category then
        attributes.Category = self:DetectCategory(model)
    end
    
    -- Size-based attributes
    if model:IsA("Model") then
        local size = self:CalculateModelSize(model)
        if size then
            attributes.ModelSize = size
            attributes.ClearanceRequired = math.ceil(math.max(size.X, size.Z) / 2)
        end
    end
    
    return attributes
end

-- Calculate the approximate size of a model
function TileDataGenerator:CalculateModelSize(model)
    if not model then return nil end
    
    local minBound = Vector3.new(math.huge, math.huge, math.huge)
    local maxBound = Vector3.new(-math.huge, -math.huge, -math.huge)
    local hasParts = false
    
    -- Check all parts for bounds
    for _, part in pairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            hasParts = true
            local size = part.Size
            local pos = part.Position
            
            minBound = Vector3.new(
                math.min(minBound.X, pos.X - size.X/2),
                math.min(minBound.Y, pos.Y - size.Y/2),
                math.min(minBound.Z, pos.Z - size.Z/2)
            )
            
            maxBound = Vector3.new(
                math.max(maxBound.X, pos.X + size.X/2),
                math.max(maxBound.Y, pos.Y + size.Y/2),
                math.max(maxBound.Z, pos.Z + size.Z/2)
            )
        end
    end
    
    if not hasParts then
        return nil
    end
    
    -- Calculate dimensions
    return maxBound - minBound
end

-- Detect category based on model name and other attributes
function TileDataGenerator:DetectCategory(model)
    if not model then return "STRUCTURE" end
    
    -- Check if model already has a Category attribute
    local existingCategory = model:GetAttribute("Category")
    if existingCategory then
        return existingCategory
    end
    
    local modelName = model.Name:lower()
    
    -- Check for matches in category keywords
    for category, keywords in pairs(CATEGORY_KEYWORDS) do
        for _, keyword in ipairs(keywords) do
            if modelName:find(keyword) then
                return category
            end
        end
    end
    
    -- Check parent folder for context
    local parent = model.Parent
    if parent then
        local parentName = parent.Name:lower()
        for category, keywords in pairs(CATEGORY_KEYWORDS) do
            for _, keyword in ipairs(keywords) do
                if parentName:find(keyword) then
                    return category
                end
            end
        end
    end
    
    -- Default to STRUCTURE for unclassified models
    return "STRUCTURE"
end

-- Calculate price based on model complexity and category
function TileDataGenerator:CalculatePrice(attributes)
    if not attributes then return 100 end
    
    -- Use existing price if specified
    if attributes.Price and attributes.Price > 0 then
        return attributes.Price
    end
    
    -- Base price depends on floor
    local floor = attributes.Floor or 1
    local basePrice = BASE_PRICE_BY_FLOOR[floor] or 100
    
    -- Apply category multiplier
    local category = attributes.Category or "STRUCTURE"
    local multiplier = PRICE_MULTIPLIERS[category] or 1.0
    
    -- Calculate final price
    local price = math.floor(basePrice * multiplier)
    
    -- Adjust by size if available (bigger = more expensive)
    if attributes.ModelSize then
        local size = attributes.ModelSize
        local volume = size.X * size.Y * size.Z
        local sizeMultiplier = 1 + (volume / 1000) -- 1000 is a baseline volume
        price = math.floor(price * math.min(3, sizeMultiplier)) -- Cap at 3x multiplier
    end
    
    -- Round to nearest 10
    return math.floor(price / 10) * 10
end

-- Calculate income boost based on price and category
function TileDataGenerator:CalculateIncome(attributes)
    if not attributes then return 1 end
    
    -- Use existing income if specified
    if attributes.IncomeBoost and attributes.IncomeBoost > 0 then
        return attributes.IncomeBoost
    end
    
    -- Base on price
    local price = attributes.Price or self:CalculatePrice(attributes)
    local baseIncome = math.floor(price / 40) -- 2.5% of price by default
    
    -- Extra income for key categories
    local category = attributes.Category or "STRUCTURE"
    if category == "CARDIO" or category == "STRENGTH" then
        baseIncome = baseIncome * 1.5
    elseif category == "SPECIALTY" then
        baseIncome = baseIncome * 2
    end
    
    -- Structure generates less income
    if category == "STRUCTURE" then
        baseIncome = math.max(1, math.floor(baseIncome / 2))
    end
    
    return math.max(1, math.floor(baseIncome))
end

-- Process all models in a folder and generate tile data
function TileDataGenerator:ProcessModelsInFolder(folderInfo)
    local folder = folderInfo.folder
    local source = folderInfo.source
    local models = {}
    
    self:Log("Processing models in " .. source)
    
    -- Process each child that's a Model
    for _, child in pairs(folder:GetChildren()) do
        if child:IsA("Model") then
            local attributes = self:ExtractModelAttributes(child)
            
            -- Skip if no valid TileType
            if not attributes.TileType then
                self:Log("Skipping " .. child.Name .. " - no TileType")
                continue
            end
            
            -- Fill in missing attributes
            if not attributes.Price then
                attributes.Price = self:CalculatePrice(attributes)
            end
            
            if not attributes.IncomeBoost then
                attributes.IncomeBoost = self:CalculateIncome(attributes)
            end
            
            -- Record model info
            models[attributes.TileType] = {
                instance = child,
                attributes = attributes,
                source = source
            }
            
            self:Log("Processed " .. child.Name .. " (TileType: " .. attributes.TileType .. ")")
        end
    end
    
    return models
end

-- Update BuyTileSystem with generated data
function TileDataGenerator:UpdateBuyTileSystem()
    if not BuyTileSystem then
        warn("BuyTileSystem not found, cannot update")
        return {}
    end
    
    -- Find model folders
    local folders = self:FindModelFolders()
    if #folders == 0 then
        warn("No model folders found")
        return {}
    end
    
    -- Process models in all folders
    local allModels = {}
    local modelByTileType = {}
    
    for _, folderInfo in ipairs(folders) do
        local models = self:ProcessModelsInFolder(folderInfo)
        for tileType, modelInfo in pairs(models) do
            modelByTileType[tileType] = modelInfo
            table.insert(allModels, modelInfo)
        end
    end
    
    -- Create or update BuyTileSystem.tileData
    if not BuyTileSystem.tileData then
        BuyTileSystem.tileData = {}
    end
    
    -- Process each model into tile data
    local updateCount = 0
    local addCount = 0
    local totalCount = 0
    
    for tileType, modelInfo in pairs(modelByTileType) do
        local attrs = modelInfo.attributes
        
        -- Create new entry or update existing
        if not BuyTileSystem.tileData[tileType] then
            -- Create new tile data entry
            BuyTileSystem.tileData[tileType] = {
                tileType = tileType,
                description = attrs.Description or attrs.ModelName or tileType,
                price = attrs.Price,
                incomeBoost = attrs.IncomeBoost,
                floor = attrs.Floor or 1,
                category = attrs.Category or "STRUCTURE",
                modelName = attrs.ModelName or tileType,
                buildOrder = attrs.BuildOrder,
                prerequisites = attrs.Prerequisites or {},
                structureType = attrs.StructureType,
                room = attrs.Room,
                clearanceRequired = attrs.ClearanceRequired,
                isWallItem = attrs.IsWallItem or attrs.NeedsWall or false,
                isCornerItem = attrs.IsCornerItem or attrs.IsCorner or false,
                isRequired = attrs.IsRequired or false
            }
            addCount += 1
        else
            -- Update existing entry, but don't overwrite specific fields if already set
            local existingData = BuyTileSystem.tileData[tileType]
            
            existingData.description = attrs.Description or existingData.description or tileType
            existingData.price = attrs.Price or existingData.price
            existingData.incomeBoost = attrs.IncomeBoost or existingData.incomeBoost
            existingData.floor = attrs.Floor or existingData.floor or 1
            existingData.category = attrs.Category or existingData.category or "STRUCTURE"
            existingData.modelName = attrs.ModelName or existingData.modelName or tileType
            existingData.structureType = attrs.StructureType or existingData.structureType
            existingData.room = attrs.Room or existingData.room
            existingData.clearanceRequired = attrs.ClearanceRequired or existingData.clearanceRequired
            existingData.isWallItem = attrs.IsWallItem or attrs.NeedsWall or existingData.isWallItem or false
            existingData.isCornerItem = attrs.IsCornerItem or attrs.IsCorner or existingData.isCornerItem or false
            existingData.isRequired = attrs.IsRequired or existingData.isRequired or false
            
            -- Only update buildOrder and prerequisites if explicitly set on the model
            if attrs.BuildOrder then
                existingData.buildOrder = attrs.BuildOrder
            end
            
            if attrs.Prerequisites and #attrs.Prerequisites > 0 then
                existingData.prerequisites = attrs.Prerequisites
            end
            
            updateCount += 1
        end
        
        totalCount += 1
    end
    
    -- Save back into BuyTileSystem
    self:Log("Updated tile data: " .. updateCount .. " updated, " .. addCount .. " added, " .. totalCount .. " total")
    
    -- Return stats
    return {
        updated = updateCount,
        added = addCount,
        total = totalCount,
        models = allModels
    }
end

-- Sort tile data by floor and category
function TileDataGenerator:SortTileData()
    if not BuyTileSystem or not BuyTileSystem.tileData then
        return false
    end
    
    -- Call SortTilesByBuildOrder if it exists
    if BuyTileSystem.SortTilesByBuildOrder then
        BuyTileSystem:SortTilesByBuildOrder()
    end
    
    return true
end

-- Generate a script containing the tile data
function TileDataGenerator:ExportTileDataToFile()
    if not BuyTileSystem or not BuyTileSystem.tileData then
        warn("BuyTileSystem not found, cannot export tile data")
        return nil
    end
    
    -- Only allowed in Studio
    if not RunService:IsStudio() then
        warn("ExportTileDataToFile can only be used in Studio")
        return nil
    end
    
    -- Create formatted Lua table string
    local lines = {
        "--[[\n",
        "    TileData.lua\n",
        "    Auto-generated tile data for BuyTileSystem\n",
        "    Generated: " .. os.date() .. "\n",
        "]]--\n\n",
        "return {\n"
    }
    
    local function valueToString(value)
        if typeof(value) == "string" then
            return string.format("%q", value)
        elseif typeof(value) == "table" then
            if #value == 0 then
                return "{}"
            end
            
            local tableStr = "{"
            for i, v in ipairs(value) do
                tableStr = tableStr .. valueToString(v)
                if i < #value then
                    tableStr = tableStr .. ", "
                end
            end
            return tableStr .. "}"
        else
            return tostring(value)
        end
    end
    
    -- Add each tile data entry
    for tileType, data in pairs(BuyTileSystem.tileData) do
        table.insert(lines, "    [\"" .. tileType .. "\"] = {\n")
        
        -- Add each property
        local properties = {
            "tileType", "description", "price", "incomeBoost", "floor", "category",
            "modelName", "buildOrder", "prerequisites", "structureType", "room",
            "clearanceRequired", "isWallItem", "isCornerItem", "isRequired"
        }
        
        for _, prop in ipairs(properties) do
            if data[prop] ~= nil then
                table.insert(lines, "        " .. prop .. " = " .. valueToString(data[prop]) .. ",\n")
            end
        end
        
        table.insert(lines, "    },\n")
    end
    
    table.insert(lines, "}\n")
    
    -- Join all lines
    local scriptContent = table.concat(lines)
    
    -- Create script instance
    local scriptInstance = Instance.new("ModuleScript")
    scriptInstance.Name = "TileData"
    scriptInstance.Source = scriptContent
    
    -- Return the script instance
    return scriptInstance
end

-- Create commands for generating tile data
function TileDataGenerator:CreateCommands()
    local CommandService = CoreRegistry and CoreRegistry:GetSystem("CommandService")
    
    if not CommandService then
        warn("CommandService not found, commands won't be available")
        return false
    end
    
    -- Register a command to generate tile data
    CommandService:RegisterCommand("generateTileData", {
        description = "Generates BuyTileSystem data from models",
        parameters = {
            {name = "exportToFile", type = "boolean", description = "Whether to export data to a file", default = false}
        },
        handler = function(player, exportToFile)
            -- Check if player is authorized to run admin commands
            local AdminService = CoreRegistry:GetSystem("AdminService")
            if AdminService and not AdminService:IsAdmin(player) then
                return "You don't have permission to use this command"
            end
            
            local stats = self:UpdateBuyTileSystem()
            
            -- Also update with floor attributes and build order
            if FloorAttributeSetup and FloorAttributeSetup.UpdateSystemData then
                FloorAttributeSetup:UpdateSystemData()
            end
            
            -- Generate build order
            if BuyTileProgressionManager and BuyTileProgressionManager.GenerateBuildOrder then
                BuyTileProgressionManager:GenerateBuildOrder()
            end
            
            -- Sort the tile data
            self:SortTileData()
            
            -- Export to file if requested
            if exportToFile and RunService:IsStudio() then
                local scriptInstance = self:ExportTileDataToFile()
                if scriptInstance then
                    scriptInstance.Parent = ServerStorage
                    return "Generated tile data: " .. stats.added .. " added, " .. stats.updated .. " updated, " .. stats.total .. " total. Export saved to ServerStorage.TileData"
                end
            end
            
            return "Generated tile data: " .. stats.added .. " added, " .. stats.updated .. " updated, " .. stats.total .. " total"
        end
    })
    
    return true
end

-- Initialize the system
function TileDataGenerator:Initialize()
    self:Log("Initializing...")
    
    -- Generate initial data
    self:UpdateBuyTileSystem()
    
    -- Create commands
    self:CreateCommands()
    
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.RegisterSystem then
        CoreRegistry:RegisterSystem("TileDataGenerator", self)
        self:Log("Registered with CoreRegistry")
    end
    
    self:Log("Initialization complete")
    return self
end

return TileDataGenerator:Initialize()