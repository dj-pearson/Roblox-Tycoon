--[[
    EquipmentManager.server.luau
    
    Unified equipment management system that consolidates functionality from:
    - EquipmentSetup.server.luau
    - EquipmentUpgradeSystem.server.luau
    
    This module provides a standardized interface for:
    - Setting up equipment attributes
    - Managing equipment upgrades
    - Determining equipment pricing and revenue
    - Integration with BuyTile system for progression
    
    Created: April 21, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
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

-- Find related systems
local BoundingBoxManager = CoreRegistry and CoreRegistry:GetSystem("BoundingBoxManager")
local FloorAttributeSetup = CoreRegistry and CoreRegistry:GetSystem("FloorAttributeSetup")
local BuyTileSystem = CoreRegistry and CoreRegistry:GetSystem("BuyTileSystem")
local TileDataGenerator = CoreRegistry and CoreRegistry:GetSystem("TileDataGenerator")

-- Configuration
local CONFIG = {
    -- Equipment type categories
    EQUIPMENT_CATEGORIES = {
        CARDIO = {"treadmill", "bike", "bicycle", "elliptical", "rowing", "cardio"},
        STRENGTH = {"bench", "press", "rack", "dumbbell", "barbell", "weight", "strength"},
        AMENITIES = {"water", "fountain", "locker", "towel", "shower", "amenity"},
        SPECIALTY = {"sauna", "pool", "spa", "basketball", "court", "specialty"},
    },
    
    -- Base prices for equipment by category and floor
    BASE_PRICES = {
        CARDIO = { basePrice = 500, floorMultiplier = 1.5 },
        STRENGTH = { basePrice = 800, floorMultiplier = 1.8 },
        SPECIALTY = { basePrice = 2000, floorMultiplier = 2.5 },
        AMENITIES = { basePrice = 300, floorMultiplier = 1.2 },
    },
    
    -- Income generation for equipment by category
    INCOME_RATES = {
        CARDIO = { baseIncome = 25, floorMultiplier = 1.3 },
        STRENGTH = { baseIncome = 40, floorMultiplier = 1.5 },
        SPECIALTY = { baseIncome = 100, floorMultiplier = 2.0 },
        AMENITIES = { baseIncome = 15, floorMultiplier = 1.1 },
    },
    
    -- Upgrade levels and multipliers
    UPGRADE_LEVELS = {
        { level = 1, name = "Basic", priceMultiplier = 1.0, incomeMultiplier = 1.0 },
        { level = 2, name = "Standard", priceMultiplier = 1.5, incomeMultiplier = 1.5 },
        { level = 3, name = "Premium", priceMultiplier = 2.5, incomeMultiplier = 2.5 },
        { level = 4, name = "Professional", priceMultiplier = 4.0, incomeMultiplier = 4.0 },
        { level = 5, name = "Elite", priceMultiplier = 6.0, incomeMultiplier = 6.0 },
    }
}

-- The EquipmentManager singleton
local EquipmentManager = {
    Debug = false,  -- Set to true for detailed logging
    EquipmentData = {},
    UpgradeCache = {},
}

-- Log messages if debug is enabled
function EquipmentManager:Log(message)
    if self.Debug then
        print("[EquipmentManager] " .. message)
    end
end

----------------------------------
-- EQUIPMENT DETECTION & CATEGORIZATION
----------------------------------

-- Detect equipment category based on name and attributes
function EquipmentManager:DetectEquipmentCategory(model)
    -- First check if category is already set as an attribute
    local category = model:GetAttribute("Category")
    if category and category ~= "" then
        return category
    end
    
    -- Otherwise detect from name
    local name = model.Name:lower()
    
    for catName, keywords in pairs(CONFIG.EQUIPMENT_CATEGORIES) do
        for _, keyword in ipairs(keywords) do
            if name:find(keyword) then
                return catName
            end
        end
    end
    
    -- Default to STRUCTURE if nothing else matches
    return "STRUCTURE"
end

-- Detect equipment type based on name and visual appearance
function EquipmentManager:DetectEquipmentType(model)
    -- Check if type is already defined
    local equipType = model:GetAttribute("EquipmentType")
    if equipType and equipType ~= "" then 
        return equipType
    end
    
    -- Otherwise get from name
    local name = model.Name:lower():gsub("%s+", "")
    local equipmentType = name:gsub("[^%w]", "")
    
    return equipmentType
end

-- Get floor number for equipment
function EquipmentManager:GetEquipmentFloor(model)
    -- Check if floor is already set
    local floor = model:GetAttribute("Floor")
    if floor and floor > 0 then
        return floor
    end
    
    -- Check if we can get it from FloorAttributeSetup
    if FloorAttributeSetup then
        local modelFloor = FloorAttributeSetup:GetFloorForPosition(model:GetPivot().Position)
        if modelFloor then
            return modelFloor
        end
    end
    
    -- Try to get from parent naming
    local parent = model.Parent
    while parent and parent ~= workspace do
        local parentName = parent.Name:lower()
        if parentName:match("(%d+)[snrt][tdht]%s+floor") then
            local floorNum = tonumber(parentName:match("(%d+)"))
            if floorNum then
                return floorNum
            end
        end
        parent = parent.Parent
    end
    
    -- Default to floor 1 if nothing else works
    return 1
end

----------------------------------
-- EQUIPMENT SETUP & ATTRIBUTES
----------------------------------

-- Extract base attributes for equipment
function EquipmentManager:ExtractEquipmentAttributes(model)
    local attrs = {}
    
    -- Already using TileDataGenerator if available
    if TileDataGenerator then
        attrs = TileDataGenerator:ExtractModelAttributes(model)
    else
        -- Fallback to manual extraction
        attrs.TileType = model:GetAttribute("TileType") or self:DetectEquipmentType(model)
        attrs.Category = model:GetAttribute("Category") or self:DetectEquipmentCategory(model)
        attrs.Floor = model:GetAttribute("Floor") or self:GetEquipmentFloor(model)
        attrs.ModelName = model:GetAttribute("ModelName") or model.Name
        attrs.Description = model:GetAttribute("Description") or model.Name
        
        -- Generate TileType from name if needed
        if not attrs.TileType or attrs.TileType == "" then
            local tileName = model.Name:gsub("%s+", ""):gsub("[^%w]", "")
            if tileName:match("^%d") then
                tileName = "Tile" .. tileName
            end
            attrs.TileType = tileName
        end
    end
    
    -- Add equipment-specific attributes
    attrs.EquipmentType = model:GetAttribute("EquipmentType") or self:DetectEquipmentType(model)
    attrs.UpgradeLevel = model:GetAttribute("UpgradeLevel") or 1
    attrs.MaxUpgradeLevel = model:GetAttribute("MaxUpgradeLevel") or 5
    
    -- Calculate price and income if not set
    if not attrs.Price then
        attrs.Price = self:CalculateEquipmentPrice(attrs)
    end
    
    if not attrs.IncomeBoost and not attrs.IncomeBonus then
        attrs.IncomeBoost = self:CalculateEquipmentIncome(attrs)
    end
    
    return attrs
end

-- Set up attributes for an equipment model
function EquipmentManager:SetupEquipmentAttributes(model)
    local attrs = self:ExtractEquipmentAttributes(model)
    
    -- Apply attributes to model
    for name, value in pairs(attrs) do
        if model:GetAttribute(name) == nil then
            model:SetAttribute(name, value)
        end
    end
    
    -- Cache data for future reference
    local equipmentId = model:GetAttribute("EquipmentId") or tostring(model:GetFullName():lower():gsub("[^%w]", ""))
    self.EquipmentData[equipmentId] = {
        instance = model,
        attributes = attrs,
        lastUpdated = os.time()
    }
    
    self:Log("Set up attributes for equipment: " .. model.Name)
    return attrs
end

-- Calculate pricing for equipment
function EquipmentManager:CalculateEquipmentPrice(attrs)
    local category = attrs.Category or "STRUCTURE"
    local floor = attrs.Floor or 1
    
    -- Use category pricing if available
    if CONFIG.BASE_PRICES[category] then
        local baseConfig = CONFIG.BASE_PRICES[category]
        local basePrice = baseConfig.basePrice
        local floorMultiplier = math.pow(baseConfig.floorMultiplier, floor - 1)
        
        -- Get upgrade level multiplier
        local upgradeLevel = attrs.UpgradeLevel or 1
        local upgradeMult = 1.0
        
        for _, levelData in ipairs(CONFIG.UPGRADE_LEVELS) do
            if levelData.level == upgradeLevel then
                upgradeMult = levelData.priceMultiplier
                break
            end
        end
        
        return math.floor(basePrice * floorMultiplier * upgradeMult)
    end
    
    -- Default pricing for structures and anything else
    return 100 * floor
end

-- Calculate income for equipment
function EquipmentManager:CalculateEquipmentIncome(attrs)
    local category = attrs.Category or "STRUCTURE"
    local floor = attrs.Floor or 1
    
    -- Use category income if available
    if CONFIG.INCOME_RATES[category] then
        local baseConfig = CONFIG.INCOME_RATES[category]
        local baseIncome = baseConfig.baseIncome
        local floorMultiplier = math.pow(baseConfig.floorMultiplier, floor - 1)
        
        -- Get upgrade level multiplier
        local upgradeLevel = attrs.UpgradeLevel or 1
        local upgradeMult = 1.0
        
        for _, levelData in ipairs(CONFIG.UPGRADE_LEVELS) do
            if levelData.level == upgradeLevel then
                upgradeMult = levelData.incomeMultiplier
                break
            end
        end
        
        return math.floor(baseIncome * floorMultiplier * upgradeMult)
    end
    
    -- Default income for structures and anything else
    return 5 * floor
end

----------------------------------
-- EQUIPMENT UPGRADES
----------------------------------

-- Get details about next upgrade for equipment
function EquipmentManager:GetNextUpgradeInfo(model)
    local currentLevel = model:GetAttribute("UpgradeLevel") or 1
    local maxLevel = model:GetAttribute("MaxUpgradeLevel") or 5
    
    -- Check if max level reached
    if currentLevel >= maxLevel then
        return nil
    end
    
    -- Find next level info
    for _, levelData in ipairs(CONFIG.UPGRADE_LEVELS) do
        if levelData.level == currentLevel + 1 then
            local basePrice = model:GetAttribute("BasePrice") or model:GetAttribute("Price") or 
                             self:CalculateEquipmentPrice({
                                 Category = model:GetAttribute("Category"),
                                 Floor = model:GetAttribute("Floor") or 1,
                                 UpgradeLevel = 1
                             })
            
            -- Calculate upgrade price (based on base price and upgrade multiplier)
            local upgradePrice = math.floor(basePrice * (levelData.priceMultiplier - 1))
            
            -- Calculate new income
            local currentIncome = model:GetAttribute("IncomeBoost") or model:GetAttribute("IncomeBonus") or 0
            local newIncome = math.floor(currentIncome * (levelData.incomeMultiplier / (currentLevel > 0 and CONFIG.UPGRADE_LEVELS[currentLevel].incomeMultiplier or 1)))
            
            return {
                level = levelData.level,
                name = levelData.name,
                price = upgradePrice,
                currentIncome = currentIncome,
                newIncome = newIncome,
                incomeIncrease = newIncome - currentIncome
            }
        end
    end
    
    return nil
end

-- Apply an upgrade to equipment
function EquipmentManager:UpgradeEquipment(model)
    -- Get next upgrade info
    local upgradeInfo = self:GetNextUpgradeInfo(model)
    if not upgradeInfo then
        self:Log("Equipment " .. model.Name .. " is already at max level")
        return false
    end
    
    -- Update attributes
    model:SetAttribute("UpgradeLevel", upgradeInfo.level)
    model:SetAttribute("UpgradeName", upgradeInfo.name)
    
    -- Update income
    local incomeAttrName = model:GetAttribute("IncomeBoost") and "IncomeBoost" or "IncomeBonus"
    model:SetAttribute(incomeAttrName, upgradeInfo.newIncome)
    
    -- Update equipment data cache
    local equipmentId = model:GetAttribute("EquipmentId") or tostring(model:GetFullName():lower():gsub("[^%w]", ""))
    if self.EquipmentData[equipmentId] then
        self.EquipmentData[equipmentId].attributes.UpgradeLevel = upgradeInfo.level
        self.EquipmentData[equipmentId].attributes[incomeAttrName] = upgradeInfo.newIncome
        self.EquipmentData[equipmentId].lastUpdated = os.time()
    end
    
    self:Log("Upgraded " .. model.Name .. " to level " .. upgradeInfo.level .. " (" .. upgradeInfo.name .. ")")
    return true
end

-- Process all equipment in a folder
function EquipmentManager:ProcessAllEquipment(folder, options)
    options = options or {}
    local setupAttributes = options.setupAttributes ~= false -- Default to true
    local generateInteractions = options.generateInteractions ~= false -- Default to true
    
    local stats = {
        processed = 0,
        upgraded = 0,
        skipped = 0
    }
    
    local function processModel(model)
        if not (model:IsA("Model") or model:IsA("BasePart")) then
            return
        end
        
        -- Detect if it's equipment
        local category = self:DetectEquipmentCategory(model)
        local isEquipment = category == "CARDIO" or category == "STRENGTH" or 
                           category == "SPECIALTY" or category == "AMENITIES"
        
        if isEquipment then
            -- Set up attributes
            if setupAttributes then
                self:SetupEquipmentAttributes(model)
            end
            
            -- Generate interaction boxes if needed
            if generateInteractions and BoundingBoxManager then
                BoundingBoxManager:CreateEquipmentInteractionBox(model, {
                    interactionType = model:GetAttribute("InteractionType") or "use",
                    actionText = model:GetAttribute("ActionText") or "Use",
                })
            end
            
            stats.processed += 1
        else
            stats.skipped += 1
        end
    end
    
    -- Process through the folder
    for _, child in ipairs(folder:GetDescendants()) do
        processModel(child)
    end
    
    self:Log("Processed " .. stats.processed .. " equipment, skipped " .. stats.skipped)
    return stats
end

----------------------------------
-- GLOBAL FUNCTIONS
----------------------------------

-- Register global functions for Studio use
function EquipmentManager:RegisterGlobalFunctions()
    if RunService:IsStudio() then
        -- Define global functions
        _G.ProcessEquipment = function(options)
            return EquipmentManager:ProcessAllEquipment(workspace, options)
        end
        
        _G.UpgradeEquipment = function(model)
            if typeof(model) == "string" then
                model = workspace:FindFirstChild(model, true)
            end
            
            if model then
                return EquipmentManager:UpgradeEquipment(model)
            else
                warn("Equipment model not found")
                return false
            end
        end
        
        _G.GetUpgradeInfo = function(model)
            if typeof(model) == "string" then
                model = workspace:FindFirstChild(model, true)
            end
            
            if model then
                return EquipmentManager:GetNextUpgradeInfo(model)
            else
                warn("Equipment model not found")
                return nil
            end
        end
        
        self:Log("Registered global functions for Studio use")
    end
end

----------------------------------
-- INTEGRATION WITH BUYTILE SYSTEM
----------------------------------

-- Initialize upgrade paths for BuyTile system (if available)
function EquipmentManager:InitializeUpgradePaths()
    if not BuyTileSystem or not BuyTileSystem.RegisterUpgradeHandler then
        self:Log("BuyTileSystem not available for registering upgrade handlers")
        return false
    end
    
    -- Register with BuyTileSystem
    BuyTileSystem:RegisterUpgradeHandler({
        name = "Equipment",
        canUpgrade = function(tileInstance)
            local category = tileInstance:GetAttribute("Category")
            if category == "CARDIO" or category == "STRENGTH" or 
               category == "SPECIALTY" or category == "AMENITIES" then
                
                local currentLevel = tileInstance:GetAttribute("UpgradeLevel") or 1
                local maxLevel = tileInstance:GetAttribute("MaxUpgradeLevel") or 5
                
                return currentLevel < maxLevel
            end
            return false
        end,
        
        getUpgradeInfo = function(tileInstance)
            return EquipmentManager:GetNextUpgradeInfo(tileInstance)
        end,
        
        performUpgrade = function(tileInstance)
            return EquipmentManager:UpgradeEquipment(tileInstance)
        end
    })
    
    self:Log("Registered equipment upgrade handler with BuyTileSystem")
    return true
end

----------------------------------
-- INITIALIZATION
----------------------------------

-- Initialize EquipmentManager
function EquipmentManager:Initialize()
    self:Log("Initializing EquipmentManager...")
    
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.RegisterSystem then
        CoreRegistry:RegisterSystem("EquipmentManager", self)
        self:Log("Registered with CoreRegistry")
    end
    
    -- Initialize BuyTile integration
    self:InitializeUpgradePaths()
    
    -- Register global functions
    self:RegisterGlobalFunctions()
    
    self:Log("EquipmentManager initialization complete")
    return self
end

-- Return the initialized singleton
return EquipmentManager:Initialize()