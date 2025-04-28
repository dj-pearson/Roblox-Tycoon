--[[
    BuyTileSystem.server.luau
    
    Enhanced version of the BuyTile system with improved error handling and diagnostics.
    This module addresses the BuyTile System Errors identified in RobloxIssues.txt.
    
    Fixed issues with gym part spawning and tracking.
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    debug = true,
    gymPartsFolder = "GymParts", -- Folder containing gym parts
    buyTilesFolder = "BuyTiles", -- Folder containing buy tiles
    defaultPrice = 100, -- Default price for tiles
    searchLocations = {
        ServerStorage,
        Workspace
    },
    
    -- For automatic creation/fallbacks
    defaultGymPartModel = {
        size = Vector3.new(5, 1, 5),
        color = Color3.fromRGB(0, 170, 255),
        transparency = 0
    }
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[BuyTileSystem]", ...)
    end
end

-- Find folder in various locations
local function findFolder(folderName)
    for _, location in ipairs(CONFIG.searchLocations) do
        local folder = location:FindFirstChild(folderName)
        if folder then
            log("Found", folderName, "in", location:GetFullName())
            return folder
        end
    end
    
    -- Not found, create it in ServerStorage
    log(folderName, "not found, creating in ServerStorage")
    local newFolder = Instance.new("Folder")
    newFolder.Name = folderName
    newFolder.Parent = ServerStorage
    
    return newFolder
end

-- Get the GymParts folder
local function getGymPartsFolder()
    local folder = findFolder(CONFIG.gymPartsFolder)
    return folder
end

-- Get the BuyTiles folder
local function getBuyTilesFolder()
    local folder = findFolder(CONFIG.buyTilesFolder)
    return folder
end

-- Find a gym part by ID
local function findGymPartById(id)
    local gymPartsFolder = getGymPartsFolder()
    
    -- First try direct child lookup
    local directPart = gymPartsFolder:FindFirstChild("GymPart" .. id) or 
                      gymPartsFolder:FindFirstChild("Gym_Part_" .. id) or
                      gymPartsFolder:FindFirstChild("GymPart_" .. id)
    
    if directPart then
        log("Found gym part with direct lookup:", directPart:GetFullName())
        return directPart
    end
    
    -- Then try deep search with attribute
    for _, item in ipairs(gymPartsFolder:GetDescendants()) do
        if item:IsA("Model") or item:IsA("Part") then
            local itemId = item:GetAttribute("ID") or item:GetAttribute("Id") or item:GetAttribute("id")
            
            -- Convert to string for comparison if it's a number
            if type(itemId) == "number" then
                itemId = tostring(itemId)
            end
            
            if itemId == tostring(id) then
                log("Found gym part with attribute:", item:GetFullName())
                return item
            end
        end
    end
    
    -- Not found, log and try fallback
    log("Could not find gym part with ID:", id, "- looking for alternate IDs")
    
    -- Try some common alternate formats
    local alternateIds = {
        "GymPart" .. id,
        id .. "_GymPart",
        "Part_" .. id
    }
    
    for _, altId in ipairs(alternateIds) do
        for _, item in ipairs(gymPartsFolder:GetDescendants()) do
            if (item:IsA("Model") or item:IsA("Part")) and item.Name == altId then
                log("Found gym part with alternate name:", item:GetFullName())
                return item
            end
        end
    end
    
    log("Could not find gym part with ID:", id, "- after trying alternates")
    return nil
end

-- Create a default gym part if one isn't found
local function createDefaultGymPart(id)
    log("Creating default gym part for ID:", id)
    
    -- Create a basic model
    local model = Instance.new("Model")
    model.Name = "GymPart_" .. id
    
    -- Create the main part
    local part = Instance.new("Part")
    part.Anchored = true
    part.Size = CONFIG.defaultGymPartModel.size
    part.Color = CONFIG.defaultGymPartModel.color
    part.Transparency = CONFIG.defaultGymPartModel.transparency
    part.Material = Enum.Material.SmoothPlastic
    part.Parent = model
    
    -- Set the primary part
    model.PrimaryPart = part
    
    -- Add attributes
    model:SetAttribute("ID", id)
    model:SetAttribute("Price", CONFIG.defaultPrice * id) -- Higher ID = higher price
    model:SetAttribute("Type", "GymPart")
    model:SetAttribute("IsDefault", true) -- Flag that this is a default model
    
    -- Add a text label to indicate it's a default part
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(2, 0, 1, 0)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.LightInfluence = 0
    billboard.Parent = part
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.Text = "Gym Equipment #" .. id
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = billboard
    
    -- Add to GymParts folder
    model.Parent = getGymPartsFolder()
    
    log("Created default gym part for ID:", id)
    return model
end

-- Find a buy tile by ID
local function findBuyTileById(id)
    local buyTilesFolder = getBuyTilesFolder()
    
    -- First try direct child lookup
    local directTile = buyTilesFolder:FindFirstChild("BuyTile" .. id) or 
                        buyTilesFolder:FindFirstChild("Buy_Tile_" .. id) or
                        buyTilesFolder:FindFirstChild("BuyTile_" .. id)
    
    if directTile then
        log("Found buy tile with direct lookup:", directTile:GetFullName())
        return directTile
    end
    
    -- Then try deep search with attribute
    for _, item in ipairs(buyTilesFolder:GetDescendants()) do
        if item:IsA("Model") or item:IsA("Part") then
            local itemId = item:GetAttribute("ID") or item:GetAttribute("Id") or item:GetAttribute("id")
            
            -- Convert to string for comparison if it's a number
            if type(itemId) == "number" then
                itemId = tostring(itemId)
            end
            
            if itemId == tostring(id) then
                log("Found buy tile with attribute:", item:GetFullName())
                return item
            end
        end
    end
    
    log("Could not find buy tile with ID:", id)
    return nil
end

-- Create a default buy tile if one isn't found
local function createDefaultBuyTile(id)
    log("Creating default buy tile for ID:", id)
    
    -- Create a basic model
    local model = Instance.new("Model")
    model.Name = "BuyTile_" .. id
    
    -- Create the main part
    local part = Instance.new("Part")
    part.Anchored = true
    part.Size = Vector3.new(6, 0.5, 6)
    part.Color = Color3.fromRGB(255, 223, 0) -- Gold color for buy tiles
    part.Transparency = 0.2
    part.Material = Enum.Material.Neon
    part.Parent = model
    
    -- Set the primary part
    model.PrimaryPart = part
    
    -- Add attributes
    model:SetAttribute("ID", id)
    model:SetAttribute("Price", CONFIG.defaultPrice * id) -- Higher ID = higher price
    model:SetAttribute("Type", "BuyTile")
    model:SetAttribute("IsDefault", true) -- Flag that this is a default model
    
    -- Add a text label to indicate it's a buy tile
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(2, 0, 1, 0)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.LightInfluence = 0
    billboard.Parent = part
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(0, 0, 0)
    textLabel.Text = "Buy Tile #" .. id .. "\nPrice: $" .. (CONFIG.defaultPrice * id)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = billboard
    
    -- Add a ClickDetector
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = part
    
    -- Add to BuyTiles folder
    model.Parent = getBuyTilesFolder()
    
    log("Created default buy tile for ID:", id)
    return model
end

-- Spawn a gym part at a position
local function spawnGymPart(player, id, position)
    log("Attempting to spawn gym part for ID:", id)
    
    -- Validate parameters
    if not id then
        log("No ID provided for gym part")
        return nil
    end
    
    -- Convert ID to number first, then to string for consistent comparison
    local numericId = tonumber(id)
    if not numericId then
        log("Invalid ID format:", id)
        return nil
    end
    
    -- Convert back to string for consistent lookup
    id = tostring(numericId)
    
    -- Find the gym part model
    local template = findGymPartById(id)
    
    -- Create a default if not found
    if not template then
        log("Gym part template not found for ID:", id, "- creating default")
        template = createDefaultGymPart(id)
    end
    
    -- Clone the template
    local gymPart = template:Clone()
    
    -- Position if provided
    if position and gymPart.PrimaryPart then
        gymPart:SetPrimaryPartCFrame(CFrame.new(position))
    end
    
    -- Add owner attribute
    if player then
        gymPart:SetAttribute("Owner", player.UserId)
    end
    
    -- Try to find the player's tycoon to parent the gym part to
    local success = false
    if player then
        local tycoon = player:FindFirstChild("Tycoon")
        if tycoon and tycoon:IsA("ObjectValue") and tycoon.Value then
            -- Parent to tycoon model
            gymPart.Parent = tycoon.Value
            success = true
            log("Spawned gym part for ID:", id, "in", player.Name, "'s tycoon")
        end
    end
    
    -- Fallback if no tycoon found
    if not success then
        gymPart.Parent = Workspace
        log("Spawned gym part for ID:", id, "in Workspace (no tycoon found)")
    end
    
    -- Fire event for gym part spawned
    local eventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
    if eventBridge then
        local spawnedEvent = eventBridge:FindFirstChild("GymPartSpawned")
        if spawnedEvent and spawnedEvent:IsA("BindableEvent") then
            spawnedEvent:Fire(player, id, gymPart)
        end
    end
    
    return gymPart
end

-- Spawn a buy tile at a position
local function spawnBuyTile(id, position)
    log("Attempting to spawn buy tile for ID:", id)
    
    -- Validate parameters
    if not id then
        log("No ID provided for buy tile")
        return nil
    end
    
    -- Convert ID to number first, then to string for consistent comparison
    local numericId = tonumber(id)
    if not numericId then
        log("Invalid ID format:", id)
        return nil
    end
    
    -- Convert back to string for consistent lookup
    id = tostring(numericId)
    
    -- Find the buy tile model
    local template = findBuyTileById(id)
    
    -- Create a default if not found
    if not template then
        log("Buy tile template not found for ID:", id, "- creating default")
        template = createDefaultBuyTile(id)
    end
    
    -- Clone the template
    local buyTile = template:Clone()
    
    -- Position if provided
    if position and buyTile.PrimaryPart then
        buyTile:SetPrimaryPartCFrame(CFrame.new(position))
    end
    
    -- Parent to Workspace
    buyTile.Parent = Workspace
    log("Spawned buy tile for ID:", id, "in Workspace")
    
    -- Set up click handler
    local clickDetector = buyTile.PrimaryPart:FindFirstChild("ClickDetector")
    if not clickDetector then
        clickDetector = Instance.new("ClickDetector")
        clickDetector.MaxActivationDistance = 20
        clickDetector.Parent = buyTile.PrimaryPart
    end
    
    -- Connect click handler
    clickDetector.MouseClick:Connect(function(player)
        handleBuyTileClick(player, buyTile, id)
    end)
    
    return buyTile
end

-- Handle click on buy tile
local function handleBuyTileClick(player, buyTile, id)
    log("Player", player.Name, "clicked buy tile with ID:", id)
    
    -- Get the price from the tile
    local price = buyTile:GetAttribute("Price") or (CONFIG.defaultPrice * tonumber(id))
    
    -- Check if player can afford it
    local leaderstats = player:FindFirstChild("leaderstats")
    local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")
    
    if not cashValue then
        log("Player", player.Name, "does not have a Cash value")
        return false
    end
    
    if cashValue.Value < price then
        log("Player", player.Name, "cannot afford tile (has", cashValue.Value, ", needs", price, ")")
        return false
    end
    
    -- Deduct cash
    cashValue.Value = cashValue.Value - price
    
    -- Spawn the gym part
    local gymPart = spawnGymPart(player, id, buyTile.PrimaryPart.Position + Vector3.new(0, 5, 0))
    
    if not gymPart then
        log("Failed to spawn gym part for ID:", id, "- refunding player")
        cashValue.Value = cashValue.Value + price
        return false
    end
    
    -- Record the purchase in data system if available
    local dataManager = getDataManager()
    if dataManager and dataManager.recordEquipmentPurchase then
        dataManager.recordEquipmentPurchase(player, id)
    end
    
    -- Spawn the next buy tile
    local nextId = tonumber(id) + 1
    local nextPosition = buyTile.PrimaryPart.Position + Vector3.new(10, 0, 0)
    
    -- Remove the current buy tile
    buyTile:Destroy()
    
    -- Spawn the next buy tile with a delay
    task.delay(0.5, function()
        spawnBuyTile(nextId, nextPosition)
    end)
    
    -- Fire event for purchase
    local eventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
    if eventBridge then
        local purchasedEvent = eventBridge:FindFirstChild("TilePurchased")
        if purchasedEvent and purchasedEvent:IsA("BindableEvent") then
            purchasedEvent:Fire(player, id)
        end
        
        -- Also fire milestone event for first purchase
        if id == "1" then
            local milestoneEvent = eventBridge:FindFirstChild("MilestoneAchieved")
            if milestoneEvent and milestoneEvent:IsA("BindableEvent") then
                milestoneEvent:Fire(player, "First Steps")
            end
        end
    end
    
    return true
end

-- Try to get the data manager for recording purchases
local function getDataManager()
    local dataManagerPaths = {
        ServerScriptService.Core.DataPersistenceManager,
        ServerScriptService.Data.GymTycoonDataManager,
        ServerScriptService.Core.Data.TycoonDataService
    }
    
    for _, path in ipairs(dataManagerPaths) do
        if path then
            local success, manager = pcall(function()
                return require(path)
            end)
            
            if success and manager then
                return manager
            end
        end
    end
    
    return nil
end

-- Initialize the system
local function initialize()
    log("Initializing BuyTileSystem...")
    
    -- Create basic folders if they don't exist
    getGymPartsFolder()
    getBuyTilesFolder()
    
    -- Create event bridge if it doesn't exist
    local eventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
    if not eventBridge then
        eventBridge = Instance.new("Folder")
        eventBridge.Name = "EventBridge"
        eventBridge.Parent = ReplicatedStorage
        log("Created EventBridge folder in ReplicatedStorage")
    end
    
    -- Create events if they don't exist
    local events = {
        "TilePurchased",
        "GymPartSpawned",
        "MilestoneAchieved"
    }
    
    for _, eventName in ipairs(events) do
        if not eventBridge:FindFirstChild(eventName) then
            local event = Instance.new("BindableEvent")
            event.Name = eventName
            event.Parent = eventBridge
            log("Created event:", eventName)
        end
    end
    
    log("BuyTileSystem initialized successfully")
end

-- Initialize the system
initialize()

-- Export the module
return {
    spawnGymPart = spawnGymPart,
    spawnBuyTile = spawnBuyTile,
    findGymPartById = findGymPartById,
    findBuyTileById = findBuyTileById,
    handleBuyTileClick = handleBuyTileClick,
    
    -- System state/helpers
    getGymPartsFolder = getGymPartsFolder,
    getBuyTilesFolder = getBuyTilesFolder,
    
    -- Debug helpers
    createDefaultGymPart = createDefaultGymPart,
    createDefaultBuyTile = createDefaultBuyTile
}
