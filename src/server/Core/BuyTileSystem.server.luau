-- BuyTileSystem.luau
-- Unified system for purchasing and managing gym equipment tiles
-- Place in ServerScriptService/Core

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- System status
local SystemStatus = {
    UNINITIALIZED = "UNINITIALIZED",
    INITIALIZING = "INITIALIZING",
    INITIALIZED = "INITIALIZED",
    DEGRADED = "DEGRADED",
    FAILED = "FAILED"
}

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
    placementDelay = 0.1,         -- Delay between equipment placements in seconds
    
    -- Dependencies
    maxRetries = 5,              -- Maximum number of retries for getting dependencies
    retryDelay = 1,              -- Delay between retries in seconds
    
    -- Required Dependencies
    requiredDependencies = {
        "EventBridge",
        "DataManager",
        "TycoonSystem"
    }
}

-- Create the BuyTileSystem
local BuyTileSystem = {
    -- Cache
    equipmentTemplates = {},
    equipmentPrices = {},
    specialEquipment = {},
    
    -- Status
    status = SystemStatus.UNINITIALIZED,
    dependencies = {},
    initializationErrors = {}
}

-- Debug function with log levels
local function log(level, ...)
    if CONFIG.debugEnabled or level == "ERROR" then
        local message = string.format("[BuyTileSystem][%s]", level)
        for _, v in ipairs({...}) do
            message = message .. " " .. tostring(v)
        end
        print(message)
    end
end

-- Get CoreRegistry safely
local function getCoreRegistry()
    local success, result = pcall(function()
        return require(ServerScriptService.Core.CoreRegistry)
    end)
    
    if not success then
        log("ERROR", "Failed to get CoreRegistry:", result)
        return nil
    end
    
    return result
end

-- Get dependency with retries
function BuyTileSystem:getDependency(dependencyName)
    local CoreRegistry = getCoreRegistry()
    if not CoreRegistry then
        log("ERROR", "Cannot get dependency", dependencyName, "- CoreRegistry not available")
        return nil
    end
    
    for i = 1, CONFIG.maxRetries do
        local success, result = pcall(function()
            return CoreRegistry.getSystem(dependencyName)
        end)
        
        if success and result then
            self.dependencies[dependencyName] = result
            log("INFO", "Successfully got dependency:", dependencyName)
            return result
        end
        
        if i < CONFIG.maxRetries then
            log("WARNING", "Retry", i, "getting dependency:", dependencyName)
            task.wait(CONFIG.retryDelay)
        end
    end
    
    log("ERROR", "Failed to get dependency after", CONFIG.maxRetries, "retries:", dependencyName)
    table.insert(self.initializationErrors, "Failed to get dependency: " .. dependencyName)
    return nil
end

-- Check dependencies
function BuyTileSystem:checkDependencies()
    local allDependenciesLoaded = true
    
    for _, dependencyName in ipairs(CONFIG.requiredDependencies) do
        if not self.dependencies[dependencyName] then
            local dependency = self:getDependency(dependencyName)
            if not dependency then
                allDependenciesLoaded = false
            end
        end
    end
    
    return allDependenciesLoaded
end

-- Initialize the module
function BuyTileSystem:initialize()
    if self.status == SystemStatus.INITIALIZING or self.status == SystemStatus.INITIALIZED then
        return true
    end
    
    self.status = SystemStatus.INITIALIZING
    log("INFO", "Initializing BuyTileSystem...")
    
    -- Clear any previous initialization errors
    self.initializationErrors = {}
    
    -- Check dependencies
    local dependenciesLoaded = self:checkDependencies()
    if not dependenciesLoaded then
        self.status = SystemStatus.DEGRADED
        log("WARNING", "Some dependencies failed to load. System will operate in degraded mode.")
    end
    
    -- Load equipment templates
    local templatesLoaded = self:loadEquipmentTemplates()
    if not templatesLoaded then
        table.insert(self.initializationErrors, "Failed to load equipment templates")
    end
    
    -- Setup remote events
    local eventsSetup = self:setupRemoteEvents()
    if not eventsSetup then
        table.insert(self.initializationErrors, "Failed to setup remote events")
    end
    
    -- Set final status
    if #self.initializationErrors == 0 then
        self.status = SystemStatus.INITIALIZED
        log("INFO", "BuyTileSystem initialized successfully")
        return true
    else
        self.status = SystemStatus.DEGRADED
        log("WARNING", "BuyTileSystem initialized in degraded state")
        for _, error in ipairs(self.initializationErrors) do
            log("ERROR", error)
        end
        return false
    end
end

-- Load equipment templates from ReplicatedStorage
function BuyTileSystem:loadEquipmentTemplates()
    local templateFolder = ReplicatedStorage:FindFirstChild(CONFIG.equipmentFolder)
    
    if not templateFolder then
        log("ERROR", "Equipment template folder not found")
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
    
    log("INFO", "Loaded " .. loadedCount .. " equipment templates")
    return loadedCount > 0
end

-- Setup remote events
function BuyTileSystem:setupRemoteEvents()
    local EventBridge = self.dependencies.EventBridge
    if not EventBridge then
        log("ERROR", "Cannot setup remote events - EventBridge not available")
        return false
    end
    
    -- Get or create remote event for buy tile requests
    local success, result = pcall(function()
        local buyTileEvent = EventBridge:getOrCreateRemoteEvent("BuyTile")
        
        -- Connect handler
        EventBridge:connectRemoteEvent("BuyTile", function(player, tileId)
            self:handleBuyTileRequest(player, tileId)
        end)
        
        return true
    end)
    
    if not success then
        log("ERROR", "Failed to setup remote events:", result)
        return false
    end
    
    log("INFO", "Remote events set up successfully")
    return true
end

-- Calculate price for a tile
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

-- Deduct cash from player
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

-- Handle a buy tile request
function BuyTileSystem:handleBuyTileRequest(player, tileId)
    if not player or not tileId then
        log("ERROR", "Invalid buy tile request")
        return false
    end
    
    log("INFO", player.Name .. " requested to buy tile: " .. tileId)
    
    -- Check if tile template exists
    if not self.equipmentTemplates[tileId] then
        log("ERROR", "Tile template not found: " .. tileId)
        return false
    end
    
    -- Get player's tycoon
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then
        log("ERROR", "Player has no tycoon")
        return false
    end
    
    -- Check if player has reached the equipment limit
    local equipmentCount = tycoon.Value:GetAttribute("EquipmentCount") or 0
    if equipmentCount >= CONFIG.maxEquipmentPerTycoon then
        log("WARNING", "Player has reached the equipment limit")
        return false
    end
    
    -- Calculate price
    local price = self:calculateTilePrice(player, tileId)
    
    -- Check if player can afford it
    if not self:canPlayerAfford(player, price) then
        log("INFO", "Player cannot afford this tile")
        return false
    end
    
    -- Deduct cash
    if not self:deductPlayerCash(player, price) then
        log("ERROR", "Failed to deduct cash")
        return false
    end
    
    -- Place the equipment
    local success = self:placeEquipment(player, tileId)
    
    if success then
        -- Record purchase
        local DataManager = self.dependencies.DataManager
        if DataManager and DataManager.recordEquipmentPurchase then
            pcall(function()
                DataManager.recordEquipmentPurchase(player, tileId)
            end)
        end
        
        -- Fire event
        local EventBridge = self.dependencies.EventBridge
        if EventBridge then
            pcall(function()
                EventBridge:fireEvent("TilePurchased", player, tileId, price)
                EventBridge:fireClientEvent("TilePurchasedClient", player, tileId, price)
            end)
        end
        
        log("INFO", player.Name .. " successfully purchased tile: " .. tileId)
        return true
    else
        -- Refund cash if placement failed
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local cashValue = leaderstats:FindFirstChild(CONFIG.cashAttributeName)
            if cashValue then
                cashValue.Value = cashValue.Value + price
                log("INFO", "Refunded " .. price .. " to " .. player.Name)
            end
        end
        
        log("ERROR", "Failed to place equipment for " .. player.Name)
        return false
    end
end

-- Find a suitable placement position in the tycoon
function BuyTileSystem:findPlacementPosition(tycoon, equipment)
    if not tycoon or not equipment then return nil end
    
    -- Try to find a predefined equipment spot
    local equipmentSpots = tycoon:FindFirstChild("EquipmentSpots")
    if equipmentSpots then
        -- Find an unoccupied spot
        for _, spot in ipairs(equipmentSpots:GetChildren()) do
            if spot:IsA("BasePart") and not spot:GetAttribute("Occupied") then
                -- Mark as occupied
                spot:SetAttribute("Occupied", true)
                
                -- Return spot position and orientation
                return spot.CFrame
            end
        end
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
        
        return position
    end
    
    -- Fallback to tycoon origin with some offset
    local origin = tycoon:GetPivot()
    local offsetX = (math.random() - 0.5) * 20
    local offsetZ = (math.random() - 0.5) * 20
    
    return origin * CFrame.new(offsetX, 3, offsetZ)
end

-- Place equipment in tycoon
function BuyTileSystem:placeEquipment(player, tileId)
    if not player or not tileId then return false end
    
    -- Get player's tycoon
    local tycoonValue = player:FindFirstChild("Tycoon")
    if not tycoonValue or not tycoonValue.Value then
        log("Player has no tycoon")
        return false
    end
    
    local tycoon = tycoonValue.Value
    
    -- Get equipment template
    local template = self.equipmentTemplates[tileId]
    if not template then
        log("Equipment template not found")
        return false
    end
    
    -- Clone equipment
    local equipment = template:Clone()
    
    -- Set up equipment properties
    equipment.Name = tileId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
    equipment:SetAttribute("EquipmentId", tileId)
    equipment:SetAttribute("PurchaseTime", os.time())
    equipment:SetAttribute("OwnerUserId", player.UserId)
    
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
    
    log("Placed equipment " .. tileId .. " in " .. player.Name .. "'s tycoon")
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
    if not player or not equipmentList then 
        log("ERROR", "Invalid parameters for restoreEquipment")
        return false 
    end
    
    log("INFO", "Restoring " .. #equipmentList .. " pieces of equipment for " .. player.Name)
    
    -- Get player's tycoon
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then
        log("ERROR", "Player has no tycoon")
        return false
    end
    
    -- Process equipment list with staggered placement
    task.spawn(function()
        local successCount = 0
        local failureCount = 0
        
        for i, tileId in ipairs(equipmentList) do
            -- Place equipment
            local success = self:placeEquipment(player, tileId)
            if success then
                successCount = successCount + 1
            else
                failureCount = failureCount + 1
            end
            
            -- Stagger placements if enabled
            if CONFIG.staggeredPlacement and i < #equipmentList then
                task.wait(CONFIG.placementDelay)
            end
        end
        
        log("INFO", string.format("Finished restoring equipment for %s (Success: %d, Failed: %d)", 
            player.Name, successCount, failureCount))
    end)
    
    return true
end

-- Public API
return {
    initialize = function()
        return BuyTileSystem:initialize()
    end,
    
    getStatus = function()
        return BuyTileSystem.status
    end,
    
    getInitializationErrors = function()
        return BuyTileSystem.initializationErrors
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
    end
}