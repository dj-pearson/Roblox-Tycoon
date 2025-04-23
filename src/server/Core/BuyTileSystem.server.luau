-- BuyTileSystem.luau
-- Unified system for purchasing and managing gym equipment tiles
-- Place in ServerScriptService/Core

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the CoreRegistry and dependencies, including the GymStructureIntegration
local CoreRegistry = require(game:GetService("ServerScriptService").Core.CoreRegistry)
local EventBridge = CoreRegistry.getSystem("EventBridge")
local DataManager = CoreRegistry.getSystem("DataManager") 
local TycoonSystem = CoreRegistry.getSystem("TycoonSystem")

-- Configuration
local CONFIG = {
    debugEnabled = true,          -- Enable debug logging
    
    -- Equipment templates
    equipmentFolder = "GymEquipment", -- Folder in ReplicatedStorage with equipment templates
    
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
    specialEquipment = {}
}

-- Debug function
local Log = function(...)
    if CONFIG.debugEnabled then
        print("[BuyTileSystem]", ...)
    end
end
-- Load equipment templates from ReplicatedStorage, now local and private
local function loadEquipmentTemplates(self)
        local templateFolder = ReplicatedStorage:FindFirstChild(CONFIG.equipmentFolder)
    
    if not templateFolder then
        Log("Equipment template folder not found")
        return false
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
    return true
end 

-- Check if player can afford a tile, now a private method
local function canPlayerAfford(self, player, price)
    if not player or not price then return false end
    
    -- Get player's cash
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return false end
    
    local cashValue = leaderstats:FindFirstChild(CONFIG.cashAttributeName)
    if not cashValue then return false end
    
    -- Check if player has enough cash
    return cashValue.Value >= price
end

--Find spot in area, now a method
local function findSpotInArea(self, gymStructureIntegration, tycoon, areaName)    
    local area = gymStructureIntegration:getArea(tycoon, areaName)
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
-- Initialize the module
function BuyTileSystem:initialize()
    Log("Initializing BuyTileSystem...")
    
    -- Load equipment templates
    self:loadEquipmentTemplates()
    
    -- Register remote events
    self:setupRemoteEvents()
    
    log("BuyTileSystem initialized")
    return true
end

-- Setup remote events 
function BuyTileSystem:setupRemoteEvents()
    -- Get or create remote event for buy tile requests
    local buyTileEvent = EventBridge:getOrCreateRemoteEvent("BuyTile")
    
    -- Connect handler
    EventBridge:connectRemoteEvent("BuyTile", function(player, tileId) self:handleBuyTileRequest(player, tileId) end) -- Corrected call
    
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

    local tycoon = TycoonSystem and TycoonSystem:GetPlayerTycoon(player)
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

    if not canPlayerAfford(self,player, price) then
        Log("Player cannot afford this tile")
        return false
    end
    local success = self:placeEquipment(player, tileId)

    if success then
        if not self.deductPlayerCash(player, price) then
            Log("Failed to deduct cash AFTER successful placement. This is unexpected and requires investigation.")
        end

        if DataManager and DataManager.recordEquipmentPurchase then
            DataManager.recordEquipmentPurchase(player, tileId)
        end

        if EventBridge and EventBridge.fireEvent then
            EventBridge:fireEvent("TilePurchased", player, tileId, price)
            EventBridge:fireClientEvent("TilePurchasedClient", player, tileId, price)
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
        placementCFrame = findSpotInArea(self, GymStructureIntegration, tycoon, equipmentType)
    end
    
    if not placementCFrame then   
        placementCFrame = findSpotInArea(self, GymStructureIntegration, tycoon, "Gym Floor")
    end    

    
    -- No spots available, find floor space
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
        
        return position
    end
    
    local origin = tycoon:GetPivot()
        local offsetX = (math.random() - 0.5) * 20
        local offsetZ = (math.random() - 0.5) * 20
    
    return origin * CFrame.new(offsetX, 3, offsetZ)
end
-- Place equipment in tycoon

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
        log("Could not find placement position")
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
function BuyTileSystem:createPurchaseEffect(self, equipment)
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

-- Restore purchased equipment from data --
function BuyTileSystem:restoreEquipment(self, player, equipmentList)
    if not player or not equipmentList then return false end
    
    log("Restoring " .. #equipmentList .. " pieces of equipment for " .. player.Name)
    
    -- Get player's tycoon
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then
        log("Player has no tycoon")
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
        
        log("Finished restoring equipment for " .. player.Name)
    end)
    
    return true
end

-- Public API
local PublicAPI = {
    initialize = function()
        return BuyTileSystem:initialize()
    end,
    
    calculateTilePrice = function(player, tileId)
        return self:calculateTilePrice(player, tileId)
    end,
    
    handleBuyTileRequest = function(player, tileId)
        return self:handleBuyTileRequest(player, tileId)
    end,
    
    placeEquipment = function(player, tileId)
         return self:placeEquipment(player, tileId)
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
    end
}

-- Register with CoreRegistry
return CoreRegistry.registerSystem("BuyTileSystem", PublicAPI, {"EventBridge", "DataManager", "TycoonSystem", "GymStructureIntegration"})
