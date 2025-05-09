-- TycoonSystem.luau
-- Unified system for tycoon management
-- Place in ServerScriptService/Core

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the CoreRegistry
local CoreRegistry = require(script.Parent.CoreRegistry)

-- Configuration
local CONFIG = {
    debugEnabled = true,           -- Enable debug logging
    
    -- Tycoon creation
    tycoonFolder = "Tycoons",      -- Name of the folder in workspace where tycoons are stored
    tycoonTemplate = "GymTemplate", -- Name of the tycoon template in ReplicatedStorage
    baseOffset = Vector3.new(0, 0, 100), -- Base offset for the first tycoon
    tycoonSpacing = 200,           -- Distance between tycoons
    maxTycoonsPerRow = 5,          -- How many tycoons per row before starting new row
    
    -- Tycoon features
    enableAutomaticRevenue = true, -- Whether tycoons generate revenue passively
    revenueInterval = 60,          -- How often to generate revenue (seconds)
    baseRevenueAmount = 5,         -- Base revenue amount per interval
    gymTierMultiplier = 1.2,       -- Revenue multiplier per gym tier
    equipmentRevenueMultiplier = 0.1, -- Revenue multiplier per equipment piece
    
    -- Performance
    checkInterval = 10,            -- How often to check tycoon states (seconds)
    enablePartCulling = true,      -- Whether to enable part culling for distant tycoons
    cullingDistance = 500,         -- Distance at which to stop rendering tycoon parts
    
    -- Error handling
    maxRetries = 3,                -- Maximum number of retries for operations
    retryDelay = 1                 -- Delay between retries (seconds)
}

-- Create the TycoonSystem
local TycoonSystem = {
    -- Internal state
    tycoonInstances = {},
    tycoonOwners = {},
    playerTycoons = {},
    nextTycoonPosition = 0,
    status = "uninitialized",      -- Current system status
    dependencies = {},             -- Required system dependencies
    revenueTask = nil,             -- Revenue generation task
    maintenanceTask = nil          -- Maintenance task
}

-- Debug function with log levels
local function log(level, ...)
    if CONFIG.debugEnabled then
        local args = {...}
        local message = table.concat(args, " ")
        print("[TycoonSystem][" .. level .. "]", message)
    end
end

-- Get a system dependency with retries
function TycoonSystem:getDependency(systemName)
    if not self.dependencies[systemName] then
        local retries = 0
        while retries < CONFIG.maxRetries do
            local success, system = pcall(function()
                return CoreRegistry.getSystem(systemName)
            end)
            
            if success and system then
                self.dependencies[systemName] = system
                log("INFO", "Successfully loaded dependency: " .. systemName)
                return system
            end
            
            retries += 1
            if retries < CONFIG.maxRetries then
                log("WARNING", "Failed to load " .. systemName .. ", retrying... (" .. retries .. "/" .. CONFIG.maxRetries .. ")")
                task.wait(CONFIG.retryDelay)
            end
        end
        
        log("ERROR", "Failed to load dependency after " .. CONFIG.maxRetries .. " retries: " .. systemName)
        return nil
    end
    
    return self.dependencies[systemName]
end

-- Initialize the module
function TycoonSystem:initialize()
    log("INFO", "Initializing TycoonSystem...")
    
    -- Set status to initializing
    self.status = "initializing"
    
    -- Load dependencies
    local EventBridge = self:getDependency("EventBridge")
    if not EventBridge then
        log("ERROR", "Failed to initialize: EventBridge dependency not available")
        self.status = "failed"
        return false
    end
    
    -- Create tycoon folder if it doesn't exist
    local success, err = pcall(function()
        self:ensureTycoonFolder()
    end)
    
    if not success then
        log("ERROR", "Failed to create tycoon folder: " .. tostring(err))
        self.status = "failed"
        return false
    end
    
    -- Build owner lookup table
    success, err = pcall(function()
        self:buildOwnershipTable()
    end)
    
    if not success then
        log("ERROR", "Failed to build ownership table: " .. tostring(err))
        self.status = "failed"
        return false
    end
    
    -- Start passive revenue generation
    if CONFIG.enableAutomaticRevenue then
        success, err = pcall(function()
            self:startRevenueGeneration()
        end)
        
        if not success then
            log("ERROR", "Failed to start revenue generation: " .. tostring(err))
            self.status = "degraded"
        end
    end
    
    -- Set up tycoon maintenance
    success, err = pcall(function()
        self:startTycoonMaintenance()
    end)
    
    if not success then
        log("ERROR", "Failed to start tycoon maintenance: " .. tostring(err))
        self.status = "degraded"
    end
    
    -- Set status to initialized
    self.status = "initialized"
    log("INFO", "TycoonSystem initialized successfully")
    return true
end

-- Ensure the tycoons folder exists in workspace
function TycoonSystem:ensureTycoonFolder()
    local tycoonsFolder = Workspace:FindFirstChild(CONFIG.tycoonFolder)
    
    if not tycoonsFolder then
        tycoonsFolder = Instance.new("Folder")
        tycoonsFolder.Name = CONFIG.tycoonFolder
        tycoonsFolder.Parent = Workspace
        log("INFO", "Created tycoons folder in workspace")
    end
    
    return tycoonsFolder
end

-- Build a lookup table for tycoon ownership
function TycoonSystem:buildOwnershipTable()
    local tycoonsFolder = self:ensureTycoonFolder()
    
    -- Clear existing tables
    self.tycoonInstances = {}
    self.tycoonOwners = {}
    self.playerTycoons = {}
    
    -- Scan for existing tycoons
    for _, tycoon in ipairs(tycoonsFolder:GetChildren()) do
        if tycoon:IsA("Model") then
            local ownerName = tycoon.Name:match("(.+)'s Gym")
            
            if ownerName then
                -- Find the owner
                local ownerPlayer
                for _, player in ipairs(Players:GetPlayers()) do
                    if player.Name == ownerName then
                        ownerPlayer = player
                        break
                    end
                end
                
                if ownerPlayer then
                    -- Register the tycoon
                    self.tycoonInstances[tycoon.Name] = tycoon
                    self.tycoonOwners[tycoon.Name] = ownerPlayer
                    self.playerTycoons[ownerPlayer.UserId] = tycoon
                    
                    -- Update player's Tycoon ObjectValue
                    local tycoonValue = ownerPlayer:FindFirstChild("Tycoon")
                    if tycoonValue then
                        tycoonValue.Value = tycoon
                    else
                        tycoonValue = Instance.new("ObjectValue")
                        tycoonValue.Name = "Tycoon"
                        tycoonValue.Value = tycoon
                        tycoonValue.Parent = ownerPlayer
                    end
                    
                    log("INFO", "Registered existing tycoon: " .. tycoon.Name)
                else
                    log("INFO", "Found tycoon without owner: " .. tycoon.Name)
                end
            end
        end
    end
    
    -- Calculate next position
    self.nextTycoonPosition = #tycoonsFolder:GetChildren()
    
    log("INFO", "Built ownership table with " .. #self.tycoonInstances .. " tycoons")
end

-- Find the position for a new tycoon
function TycoonSystem:getNextTycoonPosition()
    local position = self.nextTycoonPosition
    self.nextTycoonPosition = position + 1
    
    -- Calculate grid position
    local rowIndex = math.floor(position / CONFIG.maxTycoonsPerRow)
    local colIndex = position % CONFIG.maxTycoonsPerRow
    
    local xOffset = colIndex * CONFIG.tycoonSpacing
    local zOffset = rowIndex * CONFIG.tycoonSpacing
    
    return CONFIG.baseOffset + Vector3.new(xOffset, 0, zOffset)
end

-- Create a new tycoon for a player
function TycoonSystem:createNewTycoon(player)
    if not player then return nil end
    
    log("INFO", "Creating new tycoon for " .. player.Name)
    
    -- Check if player already has a tycoon
    if self.playerTycoons[player.UserId] then
        log("INFO", player.Name .. " already has a tycoon")
        return self.playerTycoons[player.UserId]
    end
    
    -- Get the template
    local template = ReplicatedStorage:FindFirstChild(CONFIG.tycoonTemplate)
    if not template then
        log("ERROR", "Tycoon template not found")
        return nil
    end
    
    -- Clone the template
    local newTycoon = template:Clone()
    newTycoon.Name = player.Name .. "'s Gym"
    
    -- Position the tycoon
    local position = self:getNextTycoonPosition()
    newTycoon:SetPrimaryPartCFrame(CFrame.new(position))
    
    -- Parent the tycoon
    local tycoonsFolder = self:ensureTycoonFolder()
    newTycoon.Parent = tycoonsFolder
    
    -- Register the tycoon
    self.tycoonInstances[newTycoon.Name] = newTycoon
    self.tycoonOwners[newTycoon.Name] = player
    self.playerTycoons[player.UserId] = newTycoon
    
    -- Set up initial tycoon properties
    newTycoon:SetAttribute("OwnerUserId", player.UserId)
    newTycoon:SetAttribute("GymTier", 1)
    newTycoon:SetAttribute("EquipmentCount", 0)
    newTycoon:SetAttribute("TycoonStarted", false)
    newTycoon:SetAttribute("DateCreated", os.time())
    newTycoon:SetAttribute("AccruedDues", 0)
    
    -- Create NPCs folder
    local npcsFolder = Instance.new("Folder")
    npcsFolder.Name = "NPCs"
    npcsFolder.Parent = newTycoon
    
    -- Create equipment folder
    local equipmentFolder = Instance.new("Folder")
    equipmentFolder.Name = "Equipment"
    equipmentFolder.Parent = newTycoon
    
    -- Create spawn location
    local spawnLocation = Instance.new("SpawnLocation")
    spawnLocation.Name = "SpawnLocation"
    spawnLocation.Neutral = false
    spawnLocation.TeamColor = player.TeamColor
    spawnLocation.CanCollide = false
    spawnLocation.Anchored = true
    spawnLocation.Transparency = 1
    
    -- Find spawn point in tycoon
    local spawnPoint = newTycoon:FindFirstChild("SpawnPoint") or newTycoon:FindFirstChild("SpawnLocation")
    if spawnPoint then
        spawnLocation.CFrame = spawnPoint.CFrame
        if spawnPoint:IsA("BasePart") then
            spawnPoint.Transparency = 1
            spawnPoint.CanCollide = false
        end
    else
        local primaryPart = newTycoon.PrimaryPart
        if primaryPart then
            spawnLocation.CFrame = primaryPart.CFrame * CFrame.new(0, 5, 0)
        else
            spawnLocation.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
        end
    end
    
    spawnLocation.Parent = newTycoon
    
    -- Fire event
    if EventBridge then
        local success, err = pcall(function()
            EventBridge:fireEvent("TycoonCreated", player, newTycoon)
        end)
        
        if not success then
            log("ERROR", "Failed to fire TycoonCreated event for " .. player.Name .. ": " .. tostring(err))
        end
    end
    
    log("INFO", "Created new tycoon for " .. player.Name)
    return newTycoon
end

-- Ensure a player has a tycoon
function TycoonSystem:ensurePlayerTycoon(player)
    if not player then return nil end
    
    -- Check if player already has a tycoon reference
    local tycoonValue = player:FindFirstChild("Tycoon")
    if tycoonValue and tycoonValue.Value and tycoonValue.Value:IsA("Model") and Workspace:IsAncestorOf(tycoonValue.Value) then
        -- Tycoon reference exists and is valid
        return tycoonValue.Value
    end
    
    -- Check if tycoon exists in our registry
    local existingTycoon = self.playerTycoons[player.UserId]
    if existingTycoon and existingTycoon:IsA("Model") and Workspace:IsAncestorOf(existingTycoon) then
        -- Create or update Tycoon value
        if not tycoonValue then
            tycoonValue = Instance.new("ObjectValue")
            tycoonValue.Name = "Tycoon"
            tycoonValue.Parent = player
        end
        tycoonValue.Value = existingTycoon
        
        log("INFO", "Found existing tycoon for " .. player.Name)
        return existingTycoon
    end
    
    -- Create a new tycoon
    local newTycoon = self:createNewTycoon(player)
    
    -- Update player's Tycoon value
    if newTycoon then
        if not tycoonValue then
            tycoonValue = Instance.new("ObjectValue")
            tycoonValue.Name = "Tycoon"
            tycoonValue.Parent = player
        end
        tycoonValue.Value = newTycoon
    end
    
    return newTycoon
end

-- Fix tycoon reference if it's pointing to character
function TycoonSystem:fixTycoonReference(player)
    if not player then return false end
    
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon then
        tycoon = Instance.new("ObjectValue")
        tycoon.Name = "Tycoon"
        tycoon.Parent = player
        log("INFO", "Created Tycoon value for " .. player.Name)
    end
    
    -- Check if tycoon is incorrectly set to character
    if tycoon.Value == player.Character then
        log("INFO", "Fixing incorrect tycoon reference for " .. player.Name)
        
        -- Try to find correct tycoon
        local correctTycoon = self.playerTycoons[player.UserId]
        
        -- If not found in registry, search for it
        if not correctTycoon then
            local tycoonsFolder = Workspace:FindFirstChild(CONFIG.tycoonFolder)
            if tycoonsFolder then
                correctTycoon = tycoonsFolder:FindFirstChild(player.Name .. "'s Gym")
            end
        end
        
        if correctTycoon then
            tycoon.Value = correctTycoon
            log("INFO", "Fixed tycoon reference for " .. player.Name)
            return true
        else
            log("INFO", "Could not find tycoon for " .. player.Name)
            return false
        end
    end
    
    return tycoon.Value ~= nil
end

-- Start the revenue generation loop
function TycoonSystem:startRevenueGeneration()
    if not CONFIG.enableAutomaticRevenue then return end
    
    -- Stop existing task if any
    if self.revenueTask then
        task.cancel(self.revenueTask)
    end
    
    log("INFO", "Starting revenue generation loop...")
    
    self.revenueTask = task.spawn(function()
        while true do
            local success, err = pcall(function()
                task.wait(CONFIG.revenueInterval)
                
                for _, player in pairs(Players:GetPlayers()) do
                    task.spawn(function()
                        local success, revenue = pcall(function()
                            return self:generateRevenue(player)
                        end)
                        
                        if not success then
                            log("ERROR", "Failed to generate revenue for " .. player.Name .. ": " .. tostring(revenue))
                        end
                    end)
                end
            end)
            
            if not success then
                log("ERROR", "Revenue generation loop error: " .. tostring(err))
                task.wait(CONFIG.retryDelay)
            end
        end
    end)
end

-- Generate revenue for a player's tycoon
function TycoonSystem:generateRevenue(player)
    if not player then return 0 end
    
    local tycoonValue = player:FindFirstChild("Tycoon")
    if not tycoonValue or not tycoonValue.Value then return 0 end
    
    local tycoon = tycoonValue.Value
    
    -- Skip if tycoon hasn't been started
    if not tycoon:GetAttribute("TycoonStarted") then
        return 0
    end
    
    -- Calculate base revenue
    local gymTier = tycoon:GetAttribute("GymTier") or 1
    local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
    
    local baseRevenue = CONFIG.baseRevenueAmount
    local tierBonus = baseRevenue * (gymTier - 1) * CONFIG.gymTierMultiplier
    local equipmentBonus = baseRevenue * equipmentCount * CONFIG.equipmentRevenueMultiplier
    
    local totalRevenue = math.floor(baseRevenue + tierBonus + equipmentBonus)
    
    -- Add to accrued dues
    local currentDues = tycoon:GetAttribute("AccruedDues") or 0
    tycoon:SetAttribute("AccruedDues", currentDues + totalRevenue)
    
    log("INFO", player.Name .. " generated " .. totalRevenue .. " revenue")
    
    -- Update front desk if available
    local GymTycoonConnector = self:getDependency("GymTycoonConnector")
    if GymTycoonConnector and GymTycoonConnector.updateFrontDesk then
        local success, err = pcall(function()
            GymTycoonConnector.updateFrontDesk(player)
        end)
        
        if not success then
            log("ERROR", "Failed to update front desk for " .. player.Name .. ": " .. tostring(err))
        end
    end
    
    -- Fire event
    local EventBridge = self:getDependency("EventBridge")
    if EventBridge then
        local success, err = pcall(function()
            EventBridge:fireEvent("TycoonRevenueGenerated", player, totalRevenue)
        end)
        
        if not success then
            log("ERROR", "Failed to fire revenue event for " .. player.Name .. ": " .. tostring(err))
        end
    end
    
    return totalRevenue
end

-- Start the tycoon maintenance loop
function TycoonSystem:startTycoonMaintenance()
    -- Stop existing task if any
    if self.maintenanceTask then
        task.cancel(self.maintenanceTask)
    end
    
    log("INFO", "Starting tycoon maintenance loop...")
    
    self.maintenanceTask = task.spawn(function()
        while true do
            local success, err = pcall(function()
                task.wait(CONFIG.checkInterval)
                
                -- Check all tycoons
                for _, tycoon in pairs(self.tycoonInstances) do
                    task.spawn(function()
                        local success, err = pcall(function()
                            self:performTycoonMaintenance(tycoon)
                        end)
                        
                        if not success then
                            log("ERROR", "Failed to perform maintenance on tycoon " .. tycoon.Name .. ": " .. tostring(err))
                        end
                    end)
                end
                
                -- Rebuild ownership table occasionally to catch any issues
                task.wait(CONFIG.checkInterval * 10) -- Less frequent rebuilds
                self:buildOwnershipTable()
            end)
            
            if not success then
                log("ERROR", "Maintenance loop error: " .. tostring(err))
                task.wait(CONFIG.retryDelay)
            end
        end
    end)
end

-- Perform maintenance on a tycoon
function TycoonSystem:performTycoonMaintenance(tycoon)
    if not tycoon or not tycoon:IsA("Model") then return end
    
    -- Find owner
    local owner = self.tycoonOwners[tycoon.Name]
    
    -- Skip if no owner found
    if not owner then return end
    
    -- Check if owner is still in game
    if not Players:FindFirstChild(owner.Name) then
        -- Player left but this runs after PlayerRemoving event
        -- Don't remove tycoon as they might rejoin
        return
    end
    
    -- Apply part culling if enabled
    if CONFIG.enablePartCulling then
        self:applyCulling(tycoon, owner)
    end
    
    -- Any other maintenance tasks
end

-- Apply culling to distant tycoons for performance
function TycoonSystem:applyCulling(tycoon, owner)
    if not CONFIG.enablePartCulling then return end
    
    -- Skip if no character
    if not owner.Character or not owner.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local playerPosition = owner.Character.HumanoidRootPart.Position
    local tycoonPosition = tycoon:GetPivot().Position
    local distance = (playerPosition - tycoonPosition).Magnitude
    
    -- Determine if parts should be culled
    local shouldCull = distance > CONFIG.cullingDistance
    
    -- Apply culling only to decorative parts
    for _, part in pairs(tycoon:GetDescendants()) do
        if part:IsA("BasePart") and part.Name:lower():find("decorative") then
            part.LocalTransparencyModifier = shouldCull and 1 or 0
        end
    end
end

-- Public API
local PublicAPI = {
    initialize = function()
        return TycoonSystem:initialize()
    end,
    
    createNewTycoon = function(player)
        return TycoonSystem:createNewTycoon(player)
    end,
    
    ensurePlayerTycoon = function(player)
        return TycoonSystem:ensurePlayerTycoon(player)
    end,
    
    fixTycoonReference = function(player)
        return TycoonSystem:fixTycoonReference(player)
    end,
    
    generateRevenue = function(player)
        return TycoonSystem:generateRevenue(player)
    end,
    
    getTycoonOwner = function(tycoon)
        if typeof(tycoon) == "string" then
            return TycoonSystem.tycoonOwners[tycoon]
        else
            return TycoonSystem.tycoonOwners[tycoon.Name]
        end
    end,
    
    getPlayerTycoon = function(player)
        if not player then return nil end
        return TycoonSystem.playerTycoons[player.UserId]
    end,
    
    getConfig = function()
        return CONFIG
    end,
    
    getStatus = function()
        return TycoonSystem.status
    end
}

return PublicAPI