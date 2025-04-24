-- BuyTileSystem.luau
-- Unified system for purchasing and managing gym equipment tiles
-- Place in ServerScriptService/Core

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Try to use ModuleLoader for better dependency management
local ModuleLoader
local CoreRegistry

-- First try to load ModuleLoader
local loaderSuccess, loaderResult = pcall(function()
    return require(ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("ModuleLoader"))
end)

if loaderSuccess and loaderResult then
    ModuleLoader = loaderResult
    print("[BuyTileSystem] Using ModuleLoader for dependencies")
    
    -- Load CoreRegistry using ModuleLoader
    CoreRegistry = ModuleLoader:LoadServerModule("Core", "CoreRegistry")
else
    print("[BuyTileSystem] ModuleLoader not found, using legacy loading")
    
    -- Legacy loading methods in order of preference
    if _G.CoreRegistry then
        CoreRegistry = _G.CoreRegistry
        print("[BuyTileSystem] Loaded CoreRegistry from _G")
    else
        -- Try to require directly from parent
        local success, result = pcall(function() 
            return require(script.Parent.CoreRegistry)
        end)
        
        if success then
            CoreRegistry = result
            print("[BuyTileSystem] Loaded CoreRegistry from parent")
        else
            -- Final fallback
            local finalSuccess, finalResult = pcall(function()
                return require(ServerScriptService.Core.CoreRegistry)
            end)
            
            if finalSuccess then
                CoreRegistry = finalResult
                print("[BuyTileSystem] Loaded CoreRegistry from ServerScriptService.Core")
            else
                warn("[BuyTileSystem] CRITICAL: Failed to load CoreRegistry!")
            end
        end
    end
end

-- Configuration
local CONFIG = {
    debugEnabled = true,          -- Enable debug logging
    
    -- Equipment templates
    equipmentFolder = "GymEquipment", -- Folder in ReplicatedStorage with equipment templates
    fallbackEquipmentFolder = "Equipment", -- Fallback folder name
    
    -- Pricing
    baseTilePrice = 100,          -- Base price for the first tile
    priceIncreaseFactor = 1.1,    -- Price multiplier for each subsequent tile
    specialEquipmentMultiplier = 2, -- Price multiplier for special equipment
    
    -- Economics
    cashAttributeName = "Cash",   -- Name of the cash attribute/value in leaderstats
    
    -- Visual Effects
    purchaseEffectEnabled = true, -- Whether to show purchase effects
    
    -- Equipment Constraints
    maxEquipmentPerTycoon = 100,  -- Maximum equipment pieces per tycoon
    
    -- Performance
    staggeredPlacement = true,    -- Whether to stagger equipment placement for performance
    placementDelay = 0.1          -- Delay between equipment placements in seconds
}

-- Create the BuyTileSystem
local BuyTileSystem = {
    -- Cache
    equipmentTemplates = {},
    equipmentPrices = {},
    specialEquipment = {},
    initialized = false
}

-- Debug function
local function Log(...)
    if CONFIG.debugEnabled then
        print("[BuyTileSystem]", ...)
    end
end

-- Load equipment templates from ReplicatedStorage, now local and private
function BuyTileSystem:loadEquipmentTemplates()
    local templateFolder = ReplicatedStorage:FindFirstChild(CONFIG.equipmentFolder)
    
    -- Try fallback folder if main one not found
    if not templateFolder then
        templateFolder = ReplicatedStorage:FindFirstChild(CONFIG.fallbackEquipmentFolder)
    end
    
    -- Create folder if it doesn't exist
    if not templateFolder then
        Log("Equipment template folder not found, creating one")
        templateFolder = Instance.new("Folder")
        templateFolder.Name = CONFIG.equipmentFolder
        templateFolder.Parent = ReplicatedStorage
        
        -- Create a basic template for testing
        local basicEquipment = Instance.new("Model")
        basicEquipment.Name = "BasicBench"
        
        local part = Instance.new("Part")
        part.Size = Vector3.new(2, 1, 4)
        part.Anchored = true
        part.CanCollide = true
        part.BrickColor = BrickColor.new("Brown")
        part.Parent = basicEquipment
        
        basicEquipment:SetAttribute("Price", 100)
        basicEquipment.Parent = templateFolder
    end
    
    -- Clear existing templates
    self.equipmentTemplates = {}
    self.equipmentPrices = {}
    self.specialEquipment = {}
    
    -- Load templates
    local loadedCount = 0
    
    for _, template in ipairs(templateFolder:GetChildren()) do
        if template:IsA("Model") then
            -- Store template
            self.equipmentTemplates[template.Name] = template
            
            -- Get custom price if set
            local customPrice = template:GetAttribute("Price")
            if customPrice and type(customPrice) == "number" then
                self.equipmentPrices[template.Name] = customPrice
            end
            
            -- Check if special equipment
            if template:GetAttribute("IsSpecial") then
                self.specialEquipment[template.Name] = true
            end
            
            loadedCount = loadedCount + 1
        end
    end
    
    Log("Loaded " .. loadedCount .. " equipment templates")
    return loadedCount > 0
end

-- Check if player can afford a tile
function BuyTileSystem:canPlayerAfford(player, price)
    if not player or not price then return false end
    
    -- Get player's cash
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return false end
    
    local cashValue = leaderstats:FindFirstChild(CONFIG.cashAttributeName)
    if not cashValue then return false end
    
    -- Check if player has enough cash
    return cashValue.Value >= price
end

-- Find spot in area
function BuyTileSystem:findSpotInArea(gymStructureIntegration, tycoon, areaName)  
    if not gymStructureIntegration or not tycoon or not areaName then
        return nil
    end
      
    local area
    
    -- Try directly accessing the area if structure integration is not available
    if not gymStructureIntegration.getArea then
        area = tycoon:FindFirstChild(areaName, true)
    else
        area = gymStructureIntegration:getArea(tycoon, areaName)
    end
    
    if area then
        local equipmentSpots = area:FindFirstChild("EquipmentSpots")
        if equipmentSpots then
            for _, spot in ipairs(equipmentSpots:GetChildren()) do
                if spot:IsA("BasePart") and not spot:GetAttribute("Occupied") then
                    spot:SetAttribute("Occupied", true)
                    return spot.CFrame
                end
            end
        end
    end
    return nil
end

-- Initialize the module
function BuyTileSystem:initialize()
    if self.initialized then
        return true
    end

    Log("Initializing BuyTileSystem...")
    
    -- Load equipment templates
    if not self:loadEquipmentTemplates() then
        Log("Warning: Failed to load equipment templates")
    end
    
    -- Register remote events
    self:setupRemoteEvents()
    
    -- Create a basic GymStructureIntegration if it doesn't exist
    local GymStructureIntegration = CoreRegistry.getSystem("GymStructureIntegration")
    if not GymStructureIntegration then
        Log("GymStructureIntegration not found, creating a basic version")
        
        local BasicGymStructureIntegration = {
            getArea = function(self, tycoon, areaName)
                -- Simple implementation to find an area by name in the tycoon
                return tycoon:FindFirstChild(areaName, true)
            end,
            
            initialize = function()
                return true
            end
        }
        
        CoreRegistry.registerSystem("GymStructureIntegration", BasicGymStructureIntegration, {})
    end
    
    self.initialized = true
    Log("BuyTileSystem initialized")
    return true
end

-- Setup remote events 
function BuyTileSystem:setupRemoteEvents()
    -- Wait for EventBridge to be available
    local attempts = 0
    local EventBridge
    
    while not EventBridge and attempts < 5 do
        EventBridge = CoreRegistry.getSystem("EventBridge")
        if not EventBridge then
            attempts = attempts + 1
            task.wait(0.5)
        end
    end
    
    if not EventBridge then
        Log("Warning: EventBridge not found after multiple attempts")
        return
    end
    
    -- Get or create remote event for buy tile requests
    local buyTileEvent = EventBridge:getOrCreateRemoteEvent("BuyTile")
    
    -- Connect handler
    EventBridge:connectRemoteEvent("BuyTile", function(player, tileId) 
        self:handleBuyTileRequest(player, tileId) 
    end)
    
    Log("Remote events set up")
end

function BuyTileSystem:calculateTilePrice(player, tileId)    
    if not player or not tileId then return 0 end
    
    -- Get player's tycoon
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then return 0 end
    
    -- Get equipment count
    local equipmentCount = tycoon.Value:GetAttribute("EquipmentCount") or 0
    
    -- Get base price
    local basePrice = self.equipmentPrices[tileId] or CONFIG.baseTilePrice
    
    -- Apply progression multiplier
    local priceMultiplier = CONFIG.priceIncreaseFactor ^ equipmentCount
    
    -- Apply special equipment multiplier if applicable
    if self.specialEquipment[tileId] then
        priceMultiplier = priceMultiplier * CONFIG.specialEquipmentMultiplier
    end
    
    -- Calculate final price
    local finalPrice = math.floor(basePrice * priceMultiplier)
    
    return finalPrice
end

-- Deduct cash from player, now a method
function BuyTileSystem:deductPlayerCash(player, amount)
    if not player or not amount then return false end
    
    -- Get player's cash
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return false end
    
    local cashValue = leaderstats:FindFirstChild(CONFIG.cashAttributeName)
    if not cashValue then return false end
    
    -- Check if player has enough cash
    if cashValue.Value < amount then return false end
    
    -- Deduct cash
    cashValue.Value = cashValue.Value - amount
    
    return true
end 

-- Handle a buy tile request, now a method
function BuyTileSystem:handleBuyTileRequest(player, tileId)
    if not player or not tileId then
        Log("Invalid buy tile request")
        return false
    end
    
    Log(player.Name .. " requested to buy tile: " .. tileId)
    
    if not self.equipmentTemplates[tileId] then
        Log("Tile template not found: " .. tileId)
        return false
    end

    -- Get TycoonSystem safely
    local TycoonSystem = CoreRegistry.getSystem("TycoonSystem")
    local tycoon
    
    if TycoonSystem and TycoonSystem.GetPlayerTycoon then
        tycoon = TycoonSystem:GetPlayerTycoon(player)
    else
        -- Fallback to direct lookup
        local tycoonValue = player:FindFirstChild("Tycoon")
        if tycoonValue then
            tycoon = tycoonValue.Value
        end
    end
    
    if not tycoon then
        Log("Player has no tycoon")
        return false
    end

    local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
    if equipmentCount >= CONFIG.maxEquipmentPerTycoon then
        Log("Player has reached the equipment limit")
        return false
    end

    local price = self:calculateTilePrice(player, tileId)

    if not self:canPlayerAfford(player, price) then
        Log("Player cannot afford this tile")
        return false
    end
    
    local success = self:placeEquipment(player, tileId)

    if success then
        if not self:deductPlayerCash(player, price) then
            Log("Failed to deduct cash AFTER successful placement. This is unexpected and requires investigation.")
        end

        -- Try to record the purchase in DataManager
        local DataManager = CoreRegistry.getSystem("DataManager")
        if DataManager and DataManager.recordEquipmentPurchase then
            DataManager.recordEquipmentPurchase(player, tileId)
        end

        -- Fire purchase events
        local EventBridge = CoreRegistry.getSystem("EventBridge")
        if EventBridge then
            if EventBridge.fireEvent then
                EventBridge:fireEvent("TilePurchased", player, tileId, price)
            end
            
            if EventBridge.fireClientEvent then
                EventBridge:fireClientEvent("TilePurchasedClient", player, tileId, price)
            end
        end

        -- Update gym tycoon connector
        local GymTycoonConnector = CoreRegistry.getSystem("GymTycoonConnector")
        if GymTycoonConnector and GymTycoonConnector.onTilePurchased then
            GymTycoonConnector:onTilePurchased(player, tileId)
        end

        Log(player.Name .. " successfully purchased tile: " .. tileId)
        return true
    else
        Log("Failed to place equipment for " .. player.Name)
        return false
    end
end

-- Find a suitable placement position in the tycoon, now a method
function BuyTileSystem:findPlacementPosition(tycoon, equipment)
    -- Find a suitable placement position in the tycoon
    if not tycoon or not equipment then
        Log("Invalid tycoon or equipment")
        return nil
    end

    -- Order of priority for placement:
    -- 1. EquipmentSpots within a specific area
    -- 2. Specific equipment type areas (if applicable)
    -- 3. General Gym Floor
    -- 4. Fallback to tycoon origin (if everything else fails)
    
    local GymStructureIntegration = CoreRegistry.getSystem("GymStructureIntegration")
    if not GymStructureIntegration then
        Log("GymStructureIntegration system not found")
        return nil
    end
    local placementCFrame = nil

    
    -- First, check if equipment requires a specific placement area
    local equipmentType = equipment:GetAttribute("EquipmentType")
    if equipmentType then
        placementCFrame = self:findSpotInArea(GymStructureIntegration, tycoon, equipmentType)
    end
    
    if not placementCFrame then   
        placementCFrame = self:findSpotInArea(GymStructureIntegration, tycoon, "Gym Floor")
    end    

    
    -- No spots available, find floor space
    if not placementCFrame then
        local floorParts = {}
        for _, part in ipairs(tycoon:GetDescendants()) do
            if part:IsA("BasePart") and 
               (part.Name:lower():find("floor") or
                part.Name:lower():find("ground")) then
                
                table.insert(floorParts, part)
            end
        end
            
        if #floorParts > 0 then
            -- Choose a random floor part
            local floor = floorParts[math.random(1, #floorParts)]
            
            -- Get a random position on the floor
            local size = floor.Size
            local offsetX = (math.random() - 0.5) * (size.X * 0.8)
            local offsetZ = (math.random() - 0.5) * (size.Z * 0.8)
            
            local position = floor.CFrame * CFrame.new(offsetX, size.Y/2 + 1, offsetZ)
            
            -- Random rotation around Y axis
            local angle = math.random() * math.pi * 2
            position = position * CFrame.Angles(0, angle, 0)
            
            placementCFrame = position
        end
    end
    
    -- Fallback to tycoon origin with some offset
    if not placementCFrame then
        local origin = tycoon:GetPivot()
        local offsetX = (math.random() - 0.5) * 20
        local offsetZ = (math.random() - 0.5) * 20
        placementCFrame = origin * CFrame.new(offsetX, 3, offsetZ)
    end
    
    return placementCFrame or tycoon:GetPivot() * CFrame.new(0, 2, 0)
end

-- Place equipment in tycoon, now a method
function BuyTileSystem:placeEquipment(player, tileId)
    if not player or not tileId then return false end
    
    -- Get player's tycoon
    local tycoonValue = player:FindFirstChild("Tycoon")
    if not tycoonValue or not tycoonValue.Value then
        Log("Player has no tycoon")
        return false
    end
    
    local tycoon = tycoonValue.Value
    
    -- Get equipment template
    local template = self.equipmentTemplates[tileId] or nil
     if not template then
        Log("Equipment template not found")
        return false
     end
    
    -- Clone equipment
    local equipment = template:Clone()
    
    equipment.Name = tileId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)

    -- Find placement position
    local placementCFrame = self:findPlacementPosition(tycoon, equipment)
    
     if not placementCFrame then
        Log("Could not find placement position")
        equipment:Destroy()
        return false
    end
    
    -- Position the equipment
    if equipment.PrimaryPart then
        equipment:SetPrimaryPartCFrame(placementCFrame)
    else
        -- No primary part, try to position using the first part found
        for _, part in ipairs(equipment:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CFrame = placementCFrame
                break
            end
        end
    end
    
    -- Get or create equipment folder
    local equipmentFolder = tycoon:FindFirstChild("Equipment")
    if not equipmentFolder then
        equipmentFolder = Instance.new("Folder")
        equipmentFolder.Name = "Equipment"
        equipmentFolder.Parent = tycoon
    end
    
    -- Parent the equipment
    equipment.Parent = equipmentFolder
    
    -- Update equipment count
    local currentCount = tycoon:GetAttribute("EquipmentCount") or 0
    tycoon:SetAttribute("EquipmentCount", currentCount + 1)
    
    -- Update gym tier
    local newTier = math.floor((currentCount + 1) / 5) + 1
    tycoon:SetAttribute("GymTier", newTier)
    
    -- Create purchase effect if enabled
    if CONFIG.purchaseEffectEnabled then
        task.spawn(function()
            self:createPurchaseEffect(equipment)
        end)
    end
    
    Log("Placed equipment " .. tileId .. " in " .. player.Name .. "'s tycoon")
    return true
end

-- Create visual effect for equipment purchase
function BuyTileSystem:createPurchaseEffect(equipment)
    if not equipment then return end
    
    -- Find a suitable part for the effect
    local targetPart
    if equipment.PrimaryPart then
        targetPart = equipment.PrimaryPart
    else
        for _, part in ipairs(equipment:GetDescendants()) do
            if part:IsA("BasePart") then
                targetPart = part
                break
            end
        end
    end
    
    if not targetPart then return end
    
    -- Create effect part
    local effect = Instance.new("Part")
    effect.Name = "PurchaseEffect"
    effect.Anchored = true
    effect.CanCollide = false
    effect.Size = Vector3.new(1, 1, 1)
    effect.Material = Enum.Material.Neon
    effect.Shape = Enum.PartType.Ball
    effect.BrickColor = BrickColor.new("Bright green")
    effect.Transparency = 0.3
    effect.CFrame = targetPart.CFrame
    effect.Parent = targetPart
    
    -- Animate the effect
    task.spawn(function()
        for i = 1, 10 do
            effect.Size = Vector3.new(i/2, i/2, i/2)
            effect.Transparency = 0.3 + (i * 0.07)
            task.wait(0.05)
        end
        effect:Destroy()
    end)
end

-- Restore purchased equipment from data
function BuyTileSystem:restoreEquipment(player, equipmentList)
    if not player or not equipmentList then return false end
    
    Log("Restoring " .. #equipmentList .. " pieces of equipment for " .. player.Name)
    
    -- Get player's tycoon
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then
        Log("Player has no tycoon")
        return false
    end
    
    -- Process equipment list with staggered placement
    task.spawn(function()
        for i, tileId in ipairs(equipmentList) do
            -- Place equipment
            self:placeEquipment(player, tileId)
            
            -- Stagger placements if enabled
            if CONFIG.staggeredPlacement and i < #equipmentList then
                task.wait(CONFIG.placementDelay)
            end
        end
        
        Log("Finished restoring equipment for " .. player.Name)
    end)
    
    return true
end

-- Public API
local PublicAPI = {
    initialize = function()
        return BuyTileSystem:initialize()
    end,
    
    calculateTilePrice = function(player, tileId)
        return BuyTileSystem:calculateTilePrice(player, tileId)
    end,
    
    handleBuyTileRequest = function(player, tileId)
        return BuyTileSystem:handleBuyTileRequest(player, tileId)
    end,
    
    placeEquipment = function(player, tileId)
         return BuyTileSystem:placeEquipment(player, tileId)
    end, 
    
    restoreEquipment = function(player, equipmentList)
        return BuyTileSystem:restoreEquipment(player, equipmentList)
    end,
    
    getEquipmentTemplates = function()
        return BuyTileSystem.equipmentTemplates
    end,
    
    getEquipmentPrices = function()
        return BuyTileSystem.equipmentPrices
    end,
    
    getConfig = function()
        return CONFIG
    end,
    
    -- Add this critical function that was missing
    spawnGymPart = function(player, tileId)
        -- This is a compatibility function for legacy code
        return BuyTileSystem:placeEquipment(player, tileId)
    end
}

-- Make BuyTileSystem globally accessible for emergency access
_G.BuyTileSystem = BuyTileSystem

-- Register with CoreRegistry
return CoreRegistry.registerSystem("BuyTileSystem", PublicAPI, {"EventBridge"})
