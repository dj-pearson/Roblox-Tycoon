-- GymTycoonConnector.luau
-- Central hub system for managing all game systems
-- Place in ServerScriptService/Core

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the CoreRegistry
local CoreRegistry = require(script.Parent.CoreRegistry)
local EventBridge = CoreRegistry.getSystem("EventBridge")

local GymTycoonConnector = {}

-- Debug function
local function log(...)
    print("[GymTycoonConnector]", ...)
end

-- Function to safely require a module
local function safeRequire(path, systemName)
    if not path then 
        return nil
    end
    
    local success, result = pcall(function()
        return require(path)
    end)
    
    if success then
        log("Successfully loaded: " .. systemName)
        return result
    else
        log("Failed to load " .. systemName .. ": " .. tostring(result))
        return nil
    end
end

-- Initialize the connector
function GymTycoonConnector:initialize()
    log("Initializing GymTycoonConnector...")
    
    -- Register core systems (order matters for dependencies)
    -- First, find and register existing systems
    self:registerExistingSystems()
    
    -- Connect to player events
    self:connectPlayerEvents()
    
    -- Initialize all remaining systems
    CoreRegistry.initializeAll()
    
    -- Make connector globally accessible for legacy scripts
    _G.GymTycoonConnector = self
    
    log("GymTycoonConnector initialized successfully")
    return true
end

-- Find and register existing systems
function GymTycoonConnector:registerExistingSystems()
    -- Set up structured paths to look for systems
    local systemPaths = {
        -- Core Systems
        {name = "DataManager", paths = {
            ServerScriptService.Data and ServerScriptService.Data:FindFirstChild("GymTycoonDataManager"),
            ServerScriptService:FindFirstChild("DataStorageSystem"),
            script.Parent:FindFirstChild("DataManager")
        }},
        
        -- NPC Systems - prioritize the unified version
        {name = "NPCSystem", paths = {
            ServerScriptService.Enhancements and ServerScriptService.Enhancements:FindFirstChild("UnifiedNPCSystem"),
            ServerScriptService:FindFirstChild("UnifiedNPCSystem"),
            ServerScriptService:FindFirstChild("NPCSystemIntegration")
        }},
        
        -- Tycoon Management
        {name = "TycoonSystem", paths = {
            ServerScriptService:FindFirstChild("UnifiedTycoonSystem"),
            script.Parent:FindFirstChild("TycoonSystem")
        }},
        
        -- Economy Systems
        {name = "RevenueSystem", paths = {
            ServerScriptService.Essentials and ServerScriptService.Essentials:FindFirstChild("GymRevenueSystem"),
            ServerScriptService:FindFirstChild("GymRevenueSystem")
        }},
        
        {name = "EconomyBalancer", paths = {
            ServerScriptService.Enhancements and ServerScriptService.Enhancements:FindFirstChild("DynamicEconomyBalancer"),
            ServerScriptService:FindFirstChild("DynamicEconomyBalancer")
        }},
        
        -- Feature Systems
        {name = "BuyTileSystem", paths = {
            ServerScriptService.Essentials and ServerScriptService.Essentials:FindFirstChild("BuyTile"),
            ServerScriptService:FindFirstChild("BuyTile")
        }},
        
        {name = "MilestoneSystem", paths = {
            ServerScriptService:FindFirstChild("GymMilestonesSystem")
        }},
        
        {name = "SpecializationSystem", paths = {
            ServerScriptService:FindFirstChild("GymSpecializationSystem"),
            ServerScriptService:FindFirstChild("SpecializationIntegration")
        }},
        
        {name = "SeasonalSystem", paths = {
            ServerScriptService:FindFirstChild("SeasonalSpecializationSystem")
        }},
        
        {name = "FrontDeskSystem", paths = {
            ServerScriptService:FindFirstChild("FrontDeskPrompt")
        }},
        
        {name = "CompetitionSystem", paths = {
            ServerScriptService:FindFirstChild("CompetitionSystem")
        }},
    }
    
    -- Register systems with their dependencies
    for _, systemInfo in ipairs(systemPaths) do
        -- Find the first valid path
        local systemModule = nil
        for _, path in ipairs(systemInfo.paths) do
            if path then
                systemModule = safeRequire(path, systemInfo.name)
                if systemModule then break end
            end
        end
        
        -- Register the system if found
        if systemModule then
            local dependencies = {}
            
            -- Define dependencies based on system type
            if systemInfo.name == "RevenueSystem" then
                dependencies = {"EventBridge"}
            elseif systemInfo.name == "NPCSystem" then
                dependencies = {"EventBridge", "DataManager"}
            elseif systemInfo.name == "TycoonSystem" then
                dependencies = {"EventBridge", "DataManager"}
            elseif systemInfo.name == "MilestoneSystem" then
                dependencies = {"EventBridge", "DataManager", "RevenueSystem"}
            elseif systemInfo.name == "SpecializationSystem" then
                dependencies = {"EventBridge", "DataManager", "RevenueSystem"}
            elseif systemInfo.name == "SeasonalSystem" then
                dependencies = {"EventBridge", "DataManager", "SpecializationSystem"}
            elseif systemInfo.name == "BuyTileSystem" then
                dependencies = {"EventBridge", "DataManager", "TycoonSystem"}
            elseif systemInfo.name == "CompetitionSystem" then
                dependencies = {"EventBridge", "RevenueSystem"}
            end
            
            -- Register with CoreRegistry
            CoreRegistry.registerSystem(systemInfo.name, systemModule, dependencies)
        else
            log("Warning: Could not find " .. systemInfo.name)
        end
    end
end

-- Ensure player has a tycoon reference
function GymTycoonConnector:fixTycoonReference(player)
    if not player then return false end
    
    -- Get TycoonSystem
    local TycoonSystem = CoreRegistry.getSystem("TycoonSystem")
    if TycoonSystem and TycoonSystem.fixTycoonReference then
        return TycoonSystem.fixTycoonReference(player)
    end
    
    -- Legacy fallback implementation
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon then
        tycoon = Instance.new("ObjectValue")
        tycoon.Name = "Tycoon"
        tycoon.Parent = player
        log("Created Tycoon value for " .. player.Name)
    end
    
    -- Check if tycoon is incorrectly set to character
    if tycoon.Value == player.Character then
        log("Fixing incorrect tycoon reference for " .. player.Name)
        
        -- Try to find correct tycoon
        local tycoonName = player.Name .. "'s Gym"
        local playerTycoon = workspace:FindFirstChild(tycoonName)
        
        if playerTycoon then
            tycoon.Value = playerTycoon
            log("Found existing tycoon for " .. player.Name)
            return true
        else
            log("Could not find tycoon for " .. player.Name)
            return false
        end
    end
    
    return tycoon.Value ~= nil
end

-- Setup player with all required components
function GymTycoonConnector:setupPlayer(player)
    if not player then return false end
    
    log("Setting up " .. player.Name)
    
    -- Ensure tycoon reference is correct
    self:fixTycoonReference(player)
    
    -- Create basic leaderstats if missing
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
        
        local cashValue = Instance.new("IntValue")
        cashValue.Name = "Cash"
        cashValue.Value = 1000 -- Default starting cash
        cashValue.Parent = leaderstats
    end
    
    -- Load player data
    local DataManager = CoreRegistry.getSystem("DataManager")
    if DataManager then
        task.spawn(function()
            if DataManager.loadData then
                DataManager.loadData(player)
            elseif DataManager.setupPlayer then
                DataManager.setupPlayer(player)
            end
        end)
    end
    
    -- Setup player tycoon
    local TycoonSystem = CoreRegistry.getSystem("TycoonSystem")
    if TycoonSystem then
        task.spawn(function()
            task.wait(1) -- Brief delay to ensure player is fully loaded
            
            if TycoonSystem.ensurePlayerTycoon then
                TycoonSystem.ensurePlayerTycoon(player)
            end
            
            -- Update front desk if available
            local FrontDeskSystem = CoreRegistry.getSystem("FrontDeskSystem")
            if FrontDeskSystem and FrontDeskSystem.updateFrontDeskDisplay then
                task.wait(1) -- Wait for tycoon to be ready
                FrontDeskSystem.updateFrontDeskDisplay(player)
            end
        end)
    end
    
    -- Initialize NPCs after a delay
    local NPCSystem = CoreRegistry.getSystem("NPCSystem")
    if NPCSystem then
        task.spawn(function()
            task.wait(3) -- Wait for tycoon to be fully set up
            
            if NPCSystem.initializePlayerNPCs then
                NPCSystem.initializePlayerNPCs(player)
            end
        end)
    end
    
    return true
end

-- Connect player events
function GymTycoonConnector:connectPlayerEvents()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        task.wait(1) -- Wait for player to load
        self:setupPlayer(player)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        -- Save player data
        local DataManager = CoreRegistry.getSystem("DataManager")
        if DataManager then
            if DataManager.saveData then
                DataManager.saveData(player, true) -- Save immediately
            elseif DataManager.savePlayerData then
                DataManager.savePlayerData(player, true)
            end
        end
    end)
    
    -- Handle character respawning (to fix tycoon references)
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            task.wait(1)
            self:fixTycoonReference(player)
        end)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            self:setupPlayer(player)
        end)
    end
end

-- Handle tile purchase event
function GymTycoonConnector:onTilePurchased(player, tileId)
    if not player or not tileId then
        log("Invalid parameters for onTilePurchased")
        return false
    end
    
    log(player.Name .. " purchased tile " .. tileId)
    
    -- Fire event through EventBridge
    if EventBridge then
        EventBridge:fireEvent("TilePurchased", player, tileId)
    end
    
    -- Get tycoon reference
    local tycoon = player:FindFirstChild("Tycoon")
    if tycoon then
        -- Update equipment count
        local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
        tycoon:SetAttribute("EquipmentCount", equipmentCount + 1)
        
        -- Check if we need to update gym tier
        local currentTier = tycoon:GetAttribute("GymTier") or 1
        local newTier = math.floor(equipmentCount / 5) + 1
        
        if newTier > currentTier then
            tycoon:SetAttribute("GymTier", newTier)
            
            -- Fire level up event
            if EventBridge then
                EventBridge:fireEvent("GymLevelUp", player, newTier)
            end
            
            log(player.Name .. " advanced to gym tier " .. newTier)
        end
    end
    
    -- Update systems that respond to tile purchases
    local DataManager = CoreRegistry.getSystem("DataManager")
    if DataManager and DataManager.recordEquipmentPurchase then
        DataManager.recordEquipmentPurchase(player, tileId)
    end
    
    local RevenueSystem = CoreRegistry.getSystem("RevenueSystem")
    if RevenueSystem and RevenueSystem.onTilePurchased then
        RevenueSystem.onTilePurchased(player, tileId)
    end
    
    local FrontDeskSystem = CoreRegistry.getSystem("FrontDeskSystem")
    if FrontDeskSystem and FrontDeskSystem.updateFrontDeskDisplay then
        FrontDeskSystem.updateFrontDeskDisplay(player)
    end
    
    return true
end

-- Handle collecting dues
function GymTycoonConnector:onDuesCollected(player, amount)
    if not player then return false end
    
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon then return false end
    
    -- If amount not specified, use accrued dues
    if not amount then
        amount = tycoon:GetAttribute("AccruedDues") or 0
    end
    
    -- Skip if no dues
    if amount <= 0 then
        log("No dues to collect for " .. player.Name)
        return false
    end
    
    -- Reset accrued dues
    tycoon:SetAttribute("AccruedDues", 0)
    
    -- Add to player's cash
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        -- Create leaderstats if missing
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end
    
    local cashValue = leaderstats:FindFirstChild("Cash")
    if not cashValue then
        -- Create Cash if missing
        cashValue = Instance.new("IntValue")
        cashValue.Name = "Cash"
        cashValue.Parent = leaderstats
        cashValue.Value = 0
    end
    
    -- Update cash
    cashValue.Value = cashValue.Value + amount
    log(player.Name .. " collected $" .. amount .. " in dues")
    
    -- Fire event
    if EventBridge then
        EventBridge:fireEvent("DuesCollected", player, amount)
    end
    
    -- Update front desk if available
    local FrontDeskSystem = CoreRegistry.getSystem("FrontDeskSystem")
    if FrontDeskSystem and FrontDeskSystem.updateFrontDeskDisplay then
        FrontDeskSystem.updateFrontDeskDisplay(player)
    end
    
    return true
end

-- Legacy function access pattern
function GymTycoonConnector:getLegacyFunctionTable()
    return {
        onTilePurchased = function(player, tileId)
            return self:onTilePurchased(player, tileId)
        end,
        
        onDuesCollected = function(player, amount)
            return self:onDuesCollected(player, amount)
        end,
        
        fixTycoonReference = function(player)
            return self:fixTycoonReference(player)
        end,
        
        setupPlayer = function(player)
            return self:setupPlayer(player)
        end
    }
end

-- Register with CoreRegistry
CoreRegistry.registerSystem("GymTycoonConnector", GymTycoonConnector, {"EventBridge"})

return GymTycoonConnector