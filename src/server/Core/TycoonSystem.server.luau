--!strict
--[[
    TycoonSystem.server.luau
    
    Core system for managing tycoons in the game.
    This module handles tycoon creation, player ownership, and interactions.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Unified implementation with DataAccessLayer integration
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Import CoreRegistry and DataAccessLayer
local CoreRegistry = require(script.Parent.CoreRegistry)
local DataAccessLayer = require(script.Parent.DataAccessLayer)

-- Configuration
local CONFIG = {
    debug = true,
    maxRetries = 3,
    retryDelay = 1, -- seconds
    dataKey = "tycoonData",
    tycoonFolder = "Tycoons",
    tycoonTemplate = "GymTemplate",
    baseOffset = Vector3.new(0, 0, 100),
    tycoonSpacing = 200,
    maxTycoonsPerRow = 5,
    enableAutomaticRevenue = true,
    revenueInterval = 60,
    baseRevenueAmount = 5,
    gymTierMultiplier = 1.2,
    equipmentRevenueMultiplier = 0.1,
    checkInterval = 10,
    enablePartCulling = true,
    cullingDistance = 500,
    autoCleanupAbandoned = true,
    abandonedTimeout = 300 -- 5 minutes
}

-- TycoonSystem module
local TycoonSystem = {
    Version = "2.0.0",
    initialized = false,
    tycoons = {},
    playerTycoons = {},
    stats = {
        created = 0,
        removed = 0,
        errors = 0
    }
}

-- Debug logging
local function log(message, level)
    if CONFIG.debug then
        local prefix = "[TycoonSystem]"
        if level == "error" then
            warn(prefix .. " ERROR: " .. message)
        elseif level == "warn" then
            warn(prefix .. " WARNING: " .. message)
        else
            print(prefix .. " " .. message)
        end
    end
end

-- Initialize the TycoonSystem
function TycoonSystem:Initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing TycoonSystem v" .. self.Version)
    
    -- Register with CoreRegistry
    if CoreRegistry then
        CoreRegistry.registerSystem("TycoonSystem", self)
        log("Registered with CoreRegistry")
    end
    
    -- Create tycoon folder if it doesn't exist
    local tycoonsFolder = Workspace:FindFirstChild(CONFIG.tycoonFolder)
    if not tycoonsFolder then
        tycoonsFolder = Instance.new("Folder")
        tycoonsFolder.Name = CONFIG.tycoonFolder
        tycoonsFolder.Parent = Workspace
        log("Created tycoons folder in workspace")
    end
    
    -- Set up player events
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayer(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayer(player)
    end)
    
    -- Set up game shutdown handler
    game:BindToClose(function()
        self:HandleShutdown()
    end)
    
    -- Start maintenance tasks
    if CONFIG.enableAutomaticRevenue then
        self:StartRevenueGeneration()
    end
    
    if CONFIG.autoCleanupAbandoned then
        self:StartAbandonedCheck()
    end
    
    self.initialized = true
    log("TycoonSystem initialized successfully")
    return true
end

-- Initialize a player
function TycoonSystem:InitializePlayer(player)
    if not player then return false end
    
    local userId = player.UserId
    
    -- Load tycoon data from DataAccessLayer
    local tycoonData = DataAccessLayer:GetPlayerData(player, CONFIG.dataKey)
    if tycoonData then
        -- Create tycoon from saved data
        local tycoonId = self:CreateTycoon({
            ownerId = userId,
            ownerName = player.Name,
            template = tycoonData.template or CONFIG.tycoonTemplate,
            name = tycoonData.name or player.Name .. "'s Tycoon",
            data = tycoonData.data or {}
        })
        
        if tycoonId then
            self.playerTycoons[userId] = tycoonId
            log("Created tycoon for " .. player.Name .. " from saved data: " .. tycoonId)
            
            -- Teleport player to tycoon
            task.delay(1, function()
                self:TeleportToTycoon(player, tycoonId)
            end)
            
            return true
        end
    end
    
    -- Create new tycoon if no saved data or creation failed
    local tycoonId = self:CreateTycoon({
        ownerId = userId,
        ownerName = player.Name,
        template = CONFIG.tycoonTemplate,
        name = player.Name .. "'s Tycoon"
    })
    
    if tycoonId then
        self.playerTycoons[userId] = tycoonId
        log("Created new tycoon for " .. player.Name .. ": " .. tycoonId)
        
        -- Teleport player to tycoon
        task.delay(1, function()
            self:TeleportToTycoon(player, tycoonId)
        end)
        
        return true
    end
    
    log("Failed to create tycoon for " .. player.Name, "error")
    return false
end

-- Clean up player data
function TycoonSystem:CleanupPlayer(player)
    if not player then return false end
    
    local userId = player.UserId
    local tycoonId = self.playerTycoons[userId]
    
    if tycoonId then
        -- Save tycoon data
        self:SaveTycoonData(tycoonId)
        
        -- Clean up
        self.playerTycoons[userId] = nil
        log("Cleaned up tycoon data for " .. player.Name)
    end
    
    return true
end

-- Create a new tycoon
function TycoonSystem:CreateTycoon(options)
    if not options or not options.ownerId then
        log("Invalid tycoon options", "error")
        return nil
    end
    
    -- Generate unique ID
    local tycoonId = "Tycoon_" .. options.ownerId .. "_" .. os.time()
    
    -- Get template
    local template = ServerStorage:FindFirstChild(options.template)
    if not template then
        log("Tycoon template not found: " .. options.template, "error")
        return nil
    end
    
    -- Clone template
    local tycoonInstance = template:Clone()
    
    -- Set up tycoon
    tycoonInstance.Name = tycoonId
    
    -- Calculate position
    local position = self:GetNextTycoonPosition()
    tycoonInstance:PivotTo(CFrame.new(position))
    
    -- Set parent
    local tycoonsFolder = Workspace:FindFirstChild(CONFIG.tycoonFolder)
    tycoonInstance.Parent = tycoonsFolder
    
    -- Store tycoon data
    self.tycoons[tycoonId] = {
        instance = tycoonInstance,
        ownerId = options.ownerId,
        ownerName = options.ownerName,
        template = options.template,
        name = options.name,
        data = options.data or {},
        created = os.time()
    }
    
    -- Run initialization script if it exists
    local initScript = tycoonInstance:FindFirstChild("TycoonInit")
    if initScript and initScript:IsA("Script") then
        task.spawn(function()
            initScript.Disabled = false
        end)
    end
    
    self.stats.created += 1
    log("Created tycoon: " .. tycoonId .. " for player " .. options.ownerName)
    
    return tycoonId
end

-- Remove a tycoon
function TycoonSystem:RemoveTycoon(tycoonId)
    if not tycoonId or not self.tycoons[tycoonId] then
        return false
    end
    
    local tycoon = self.tycoons[tycoonId]
    
    -- Save data before removing
    self:SaveTycoonData(tycoonId)
    
    -- Clean up
    if tycoon.instance then
        tycoon.instance:Destroy()
    end
    
    -- Remove from player mapping
    if tycoon.ownerId then
        self.playerTycoons[tycoon.ownerId] = nil
    end
    
    -- Remove from tycoons table
    self.tycoons[tycoonId] = nil
    
    self.stats.removed += 1
    log("Removed tycoon: " .. tycoonId)
    
    return true
end

-- Save tycoon data
function TycoonSystem:SaveTycoonData(tycoonId)
    if not tycoonId or not self.tycoons[tycoonId] then
        return false
    end
    
    local tycoon = self.tycoons[tycoonId]
    local ownerId = tycoon.ownerId
    
    if not ownerId then
        return false
    end
    
    -- Get the player if they're still online
    local player = Players:GetPlayerByUserId(ownerId)
    if not player then
        return false
    end
    
    -- Gather tycoon data to save
    local saveData = {
        template = tycoon.template,
        name = tycoon.name,
        data = tycoon.data or {}
    }
    
    -- Try to run save hooks in the tycoon instance
    if tycoon.instance then
        local saveScript = tycoon.instance:FindFirstChild("TycoonSave")
        if saveScript and saveScript:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(saveScript)
            end)
            
            if success and result and typeof(result.onSave) == "function" then
                local additionalData = result.onSave(tycoon.instance)
                if additionalData and type(additionalData) == "table" then
                    for key, value in pairs(additionalData) do
                        saveData.data[key] = value
                    end
                end
            end
        end
    end
    
    -- Save using DataAccessLayer
    local success = DataAccessLayer:UpdatePlayerData(player, CONFIG.dataKey, saveData)
    if success then
        log("Saved tycoon data for " .. tycoonId)
        return true
    end
    
    log("Failed to save tycoon data for " .. tycoonId, "error")
    return false
end

-- Get next tycoon position
function TycoonSystem:GetNextTycoonPosition()
    local row = math.floor(self.stats.created / CONFIG.maxTycoonsPerRow)
    local col = self.stats.created % CONFIG.maxTycoonsPerRow
    
    return CONFIG.baseOffset + Vector3.new(
        col * CONFIG.tycoonSpacing,
        0,
        row * CONFIG.tycoonSpacing
    )
end

-- Teleport player to tycoon
function TycoonSystem:TeleportToTycoon(player, tycoonId)
    if not player or not tycoonId or not self.tycoons[tycoonId] then
        return false
    end
    
    local tycoon = self.tycoons[tycoonId]
    if not tycoon.instance then
        return false
    end
    
    -- Find spawn point
    local spawnPoint = tycoon.instance:FindFirstChild("SpawnPoint")
    if not spawnPoint then
        spawnPoint = tycoon.instance:FindFirstChild("HumanoidRootPart")
    end
    
    if spawnPoint then
        player.Character:SetPrimaryPartCFrame(spawnPoint.CFrame)
        log("Teleported " .. player.Name .. " to tycoon: " .. tycoonId)
        return true
    end
    
    log("No spawn point found in tycoon: " .. tycoonId, "error")
    return false
end

-- Start revenue generation
function TycoonSystem:StartRevenueGeneration()
    if not CONFIG.enableAutomaticRevenue then
        return
    end
    
    task.spawn(function()
        while true do
            task.wait(CONFIG.revenueInterval)
            
            for tycoonId, tycoon in pairs(self.tycoons) do
                if tycoon.instance then
                    local ownerId = tycoon.ownerId
                    local player = Players:GetPlayerByUserId(ownerId)
                    
                    if player then
                        -- Calculate revenue
                        local baseRevenue = CONFIG.baseRevenueAmount
                        local tierMultiplier = tycoon.data.tier or 1
                        local equipmentCount = #tycoon.instance:GetChildren()
                        
                        local revenue = baseRevenue * 
                            (CONFIG.gymTierMultiplier ^ (tierMultiplier - 1)) * 
                            (1 + (equipmentCount * CONFIG.equipmentRevenueMultiplier))
                        
                        -- Add revenue to player
                        local playerData = DataAccessLayer:GetPlayerData(player)
                        if playerData then
                            local newCash = (playerData.cash or 0) + revenue
                            DataAccessLayer:UpdatePlayerData(player, "cash", newCash)
                        end
                    end
                end
            end
        end
    end)
end

-- Start abandoned tycoon check
function TycoonSystem:StartAbandonedCheck()
    if not CONFIG.autoCleanupAbandoned then
        return
    end
    
    task.spawn(function()
        while true do
            task.wait(30) -- Check every 30 seconds
            
            local currentTime = os.time()
            
            for tycoonId, tycoon in pairs(self.tycoons) do
                if tycoon.instance then
                    local ownerId = tycoon.ownerId
                    local player = Players:GetPlayerByUserId(ownerId)
                    
                    if not player then
                        -- Check if tycoon has been abandoned
                        local lastSeen = tycoon.data.lastSeen or tycoon.created
                        if currentTime - lastSeen > CONFIG.abandonedTimeout then
                            log("Removing abandoned tycoon: " .. tycoonId)
                            self:RemoveTycoon(tycoonId)
                        end
                    else
                        -- Update last seen time
                        tycoon.data.lastSeen = currentTime
                    end
                end
            end
        end
    end)
end

-- Handle game shutdown
function TycoonSystem:HandleShutdown()
    log("Handling game shutdown")
    
    -- Save all tycoon data
    for tycoonId, _ in pairs(self.tycoons) do
        self:SaveTycoonData(tycoonId)
    end
end

-- Get system health
function TycoonSystem:IsHealthy()
    return self.initialized
end

-- Recover from failure
function TycoonSystem:Recover()
    if not self.initialized then
        return self:Initialize()
    end
    return true
end

-- Initialize the TycoonSystem
TycoonSystem:Initialize()

return TycoonSystem