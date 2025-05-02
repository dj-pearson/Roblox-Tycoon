--[[
    TycoonSystem.luau
    
    Core system for managing tycoons in the game.
    This module handles tycoon creation, player ownership, and interactions.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TycoonSystem = {}
TycoonSystem.initialized = false

-- Configuration
local CONFIG = {
    TYCOON_TEMPLATE_LOCATION = ServerStorage:FindFirstChild("TycoonTemplates"),
    TYCOONS_FOLDER_NAME = "Tycoons",
    MAX_TYCOONS = 20,
    SAVE_KEY = "tycoonData",
    DEFAULT_SPAWN_LOCATIONS = {
        Vector3.new(0, 10, 0),
        Vector3.new(100, 10, 0),
        Vector3.new(0, 10, 100),
        Vector3.new(100, 10, 100),
        Vector3.new(-100, 10, 0),
        Vector3.new(0, 10, -100),
        Vector3.new(-100, 10, -100),
        Vector3.new(100, 10, -100),
        Vector3.new(-100, 10, 100)
    },
    AUTO_CLEANUP_ABANDONED = true,
    ABANDONED_TIMEOUT = 300 -- 5 minutes
}

-- Debug settings
TycoonSystem.DEBUG = true

-- Internal state
local tycoons = {}
local playerTycoons = {}
local availableSpawnPoints = {}
local customSpawnPoints = {}
local lastPlayerSeen = {}

-- Log a message to the output
local function log(message)
    if TycoonSystem.DEBUG then
        print("[TycoonSystem] " .. message)
    end
end

-- Get the CoreRegistry if available
local function getCoreRegistry()
    -- Try to use SafeRequire first
    local safeRequirePaths = {
        ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("SafeRequire"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared") and ReplicatedStorage.src.shared:FindFirstChild("SafeRequire"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("shared") and ServerScriptService.src.shared:FindFirstChild("SafeRequire")
    }
    
    for _, path in ipairs(safeRequirePaths) do
        if path then
            local success, safeRequire = pcall(function()
                return require(path)
            end)
            
            if success and safeRequire and typeof(safeRequire.requireFromPath) == "function" then
                local CoreRegistry = safeRequire.requireFromPath("CoreRegistry")
                if CoreRegistry then
                    log("Found CoreRegistry via SafeRequire")
                    return CoreRegistry
                end
            end
        end
    end
    
    -- Try standard paths
    local standardPaths = {
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry")
    }
    
    for _, path in ipairs(standardPaths) do
        if path and path:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(path)
            end)
            
            if success and result then
                return result
            end
        end
    end
    
    return nil
end

-- Get the DataManager if available
local function getDataManager()
    local CoreRegistry = getCoreRegistry()
    if CoreRegistry and typeof(CoreRegistry.getSystem) == "function" then
        return CoreRegistry.getSystem("DataManager")
    end
    
    -- Try direct paths
    local standardPaths = {
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("DataManager"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("DataManager")
    }
    
    for _, path in ipairs(standardPaths) do
        if path and path:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(path)
            end)
            
            if success and result then
                return result
            end
        end
    end
    
    return nil
end

-- Initialize the TycoonSystem
function TycoonSystem.initialize()
    if TycoonSystem.initialized then
        return true
    end
    
    log("Initializing TycoonSystem...")
    
    -- Register with CoreRegistry if available
    local CoreRegistry = getCoreRegistry()
    if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
        CoreRegistry.registerSystem("TycoonSystem", TycoonSystem)
        log("Registered with CoreRegistry")
    else
        log("CoreRegistry not found, but TycoonSystem will still function")
    end
    
    -- Create tycoons container if it doesn't exist
    local tycoonsFolder = Workspace:FindFirstChild(CONFIG.TYCOONS_FOLDER_NAME)
    if not tycoonsFolder then
        tycoonsFolder = Instance.new("Folder")
        tycoonsFolder.Name = CONFIG.TYCOONS_FOLDER_NAME
        tycoonsFolder.Parent = Workspace
        log("Created Tycoons folder in Workspace")
    end
    
    -- Initialize spawn points
    TycoonSystem.initializeSpawnPoints()
    
    -- Set up player events
    Players.PlayerAdded:Connect(function(player)
        task.wait(1) -- Allow time for player data to load
        TycoonSystem.handlePlayerJoin(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        TycoonSystem.handlePlayerLeave(player)
    end)
    
    -- Set up regular update for abandoned tycoons
    if CONFIG.AUTO_CLEANUP_ABANDONED then
        task.spawn(function()
            while true do
                task.wait(30) -- Check every 30 seconds
                TycoonSystem.checkAbandonedTycoons()
            end
        end)
    end
    
    -- Set up remotes for client communication
    local remotes = ReplicatedStorage:FindFirstChild("TycoonRemotes")
    if not remotes then
        remotes = Instance.new("Folder")
        remotes.Name = "TycoonRemotes"
        remotes.Parent = ReplicatedStorage
        
        -- Create remote for getting player tycoon
        local getPlayerTycoonRemote = Instance.new("RemoteFunction")
        getPlayerTycoonRemote.Name = "GetPlayerTycoon"
        getPlayerTycoonRemote.Parent = remotes
        
        -- Create remote for interacting with tycoon
        local interactWithTycoonRemote = Instance.new("RemoteFunction")
        interactWithTycoonRemote.Name = "InteractWithTycoon"
        interactWithTycoonRemote.Parent = remotes
        
        -- Handle remote calls
        getPlayerTycoonRemote.OnServerInvoke = function(player)
            local tycoonId = playerTycoons[player.UserId]
            if tycoonId then
                -- Return basic info about the tycoon
                local tycoon = tycoons[tycoonId]
                if tycoon then
                    return {
                        id = tycoonId,
                        name = tycoon.name,
                        locationCFrame = tycoon.instance and tycoon.instance:GetPivot() or nil
                    }
                end
            end
            return nil
        end
        
        interactWithTycoonRemote.OnServerInvoke = function(player, tycoonId, action, data)
            -- Security check - only owner can interact
            if playerTycoons[player.UserId] ~= tycoonId then
                return false, "Not owner of this tycoon"
            end
            
            local tycoon = tycoons[tycoonId]
            if not tycoon then
                return false, "Tycoon not found"
            end
            
            -- Handle different actions
            if action == "rename" then
                return TycoonSystem.renameTycoon(tycoonId, data)
            elseif action == "upgrade" then
                return TycoonSystem.upgradeTycoon(tycoonId, data)
            elseif action == "customize" then
                return TycoonSystem.customizeTycoon(tycoonId, data)
            end
            
            return false, "Unknown action"
        end
    end
    
    TycoonSystem.initialized = true
    log("TycoonSystem initialized")
    
    return true
end

-- Initialize spawn points
function TycoonSystem.initializeSpawnPoints()
    availableSpawnPoints = {}
    
    -- Check for custom spawn points
    if CONFIG.TYCOON_TEMPLATE_LOCATION and CONFIG.TYCOON_TEMPLATE_LOCATION:FindFirstChild("SpawnPoints") then
        local spawnPointsFolder = CONFIG.TYCOON_TEMPLATE_LOCATION.SpawnPoints
        
        for _, spawnPoint in ipairs(spawnPointsFolder:GetChildren()) do
            if spawnPoint:IsA("BasePart") then
                table.insert(customSpawnPoints, spawnPoint.CFrame)
                table.insert(availableSpawnPoints, spawnPoint.CFrame)
            end
        end
        
        log("Loaded " .. #customSpawnPoints .. " custom spawn points")
    end
    
    -- If no custom spawn points, use defaults
    if #availableSpawnPoints == 0 then
        for _, position in ipairs(CONFIG.DEFAULT_SPAWN_LOCATIONS) do
            local spawnCFrame = CFrame.new(position)
            table.insert(availableSpawnPoints, spawnCFrame)
        end
        
        log("Using " .. #availableSpawnPoints .. " default spawn points")
    end
end

-- Get a random available spawn point
function TycoonSystem.getAvailableSpawnPoint()
    if #availableSpawnPoints > 0 then
        local index = math.random(1, #availableSpawnPoints)
        local spawnPoint = availableSpawnPoints[index]
        table.remove(availableSpawnPoints, index)
        return spawnPoint
    end
    
    -- If all spawn points are used, find an unused one from the originals
    local usedPositions = {}
    for _, tycoon in pairs(tycoons) do
        if tycoon.instance then
            local position = tycoon.instance:GetPivot().Position
            usedPositions[tostring(position)] = true
        end
    end
    
    -- Check custom points first
    for _, spawnCFrame in ipairs(customSpawnPoints) do
        local position = spawnCFrame.Position
        if not usedPositions[tostring(position)] then
            return spawnCFrame
        end
    end
    
    -- Then check defaults
    for _, position in ipairs(CONFIG.DEFAULT_SPAWN_LOCATIONS) do
        if not usedPositions[tostring(position)] then
            return CFrame.new(position)
        end
    end
    
    -- Last resort: create a random position
    log("No available spawn points, using random position")
    return CFrame.new(
        math.random(-500, 500),
        10,
        math.random(-500, 500)
    )
end

-- Generate a unique tycoon ID
function TycoonSystem.generateTycoonId()
    return "tycoon_" .. math.random(100000, 999999) .. "_" .. os.time()
end

-- Handle a player joining
function TycoonSystem.handlePlayerJoin(player)
    if not player or not player.UserId then
        return
    end
    
    -- Record player presence
    lastPlayerSeen[player.UserId] = os.time()
    
    -- Check if player has a tycoon already
    local hasExistingTycoon = false
    for tycoonId, tycoon in pairs(tycoons) do
        if tycoon.ownerId == player.UserId then
            playerTycoons[player.UserId] = tycoonId
            hasExistingTycoon = true
            log("Player " .. player.Name .. " reconnected to existing tycoon: " .. tycoonId)
            
            -- Update tycoon state
            TycoonSystem.updateTycoonState(tycoonId, "active")
            break
        end
    end
    
    -- If no existing tycoon, check saved data
    if not hasExistingTycoon then
        local DataManager = getDataManager()
        if DataManager then
            local playerData = DataManager.getPlayerData(player)
            if playerData and playerData[CONFIG.SAVE_KEY] then
                local savedTycoonData = playerData[CONFIG.SAVE_KEY]
                
                -- Create tycoon from saved data
                local tycoonId = TycoonSystem.createTycoon({
                    ownerId = player.UserId,
                    ownerName = player.Name,
                    template = savedTycoonData.template or "DefaultTycoon",
                    name = savedTycoonData.name or player.Name .. "'s Tycoon",
                    data = savedTycoonData.data or {}
                })
                
                if tycoonId then
                    log("Created tycoon for " .. player.Name .. " from saved data: " .. tycoonId)
                    playerTycoons[player.UserId] = tycoonId
                    
                    -- Teleport player to tycoon
                    task.delay(1, function()
                        TycoonSystem.teleportToTycoon(player, tycoonId)
                    end)
                    
                    return
                end
            end
        end
        
        -- If no saved data or creation failed, create a new tycoon
        local tycoonId = TycoonSystem.createTycoon({
            ownerId = player.UserId,
            ownerName = player.Name,
            template = "DefaultTycoon",
            name = player.Name .. "'s Tycoon"
        })
        
        if tycoonId then
            log("Created new tycoon for " .. player.Name .. ": " .. tycoonId)
            playerTycoons[player.UserId] = tycoonId
            
            -- Teleport player to tycoon
            task.delay(1, function()
                TycoonSystem.teleportToTycoon(player, tycoonId)
            end)
        else
            warn("[TycoonSystem] Failed to create tycoon for " .. player.Name)
        end
    else
        -- Teleport to existing tycoon
        task.delay(1, function()
            local tycoonId = playerTycoons[player.UserId]
            if tycoonId then
                TycoonSystem.teleportToTycoon(player, tycoonId)
            end
        end)
    end
end

-- Handle a player leaving
function TycoonSystem.handlePlayerLeave(player)
    if not player or not player.UserId then
        return
    end
    
    local userId = player.UserId
    local tycoonId = playerTycoons[userId]
    
    if tycoonId and tycoons[tycoonId] then
        -- Save tycoon data
        TycoonSystem.saveTycoonData(tycoonId)
        
        -- Update tycoon state
        TycoonSystem.updateTycoonState(tycoonId, "inactive")
        
        log("Player " .. player.Name .. " left, tycoon set to inactive: " .. tycoonId)
    end
    
    -- Clean up
    playerTycoons[userId] = nil
    lastPlayerSeen[userId] = nil
end

-- Create a new tycoon
function TycoonSystem.createTycoon(options)
    if not options or type(options) ~= "table" then
        warn("[TycoonSystem] Invalid tycoon options")
        return nil
    end
    
    -- Required properties
    if not options.ownerId then
        warn("[TycoonSystem] Tycoon missing owner ID")
        return nil
    end
    
    -- Check if we're at tycoon limit
    if table.getn(tycoons) >= CONFIG.MAX_TYCOONS then
        -- Try to find an abandoned tycoon to replace
        local replacedTycoon = false
        for id, tycoon in pairs(tycoons) do
            if tycoon.state == "abandoned" then
                TycoonSystem.removeTycoon(id)
                replacedTycoon = true
                log("Removed abandoned tycoon to make room: " .. id)
                break
            end
        end
        
        if not replacedTycoon then
            for id, tycoon in pairs(tycoons) do
                if tycoon.state == "inactive" then
                    TycoonSystem.removeTycoon(id)
                    replacedTycoon = true
                    log("Removed inactive tycoon to make room: " .. id)
                    break
                end
            end
        end
        
        if not replacedTycoon then
            warn("[TycoonSystem] Cannot create tycoon, at maximum capacity and no removable tycoons")
            return nil
        end
    end
    
    -- Generate a unique ID for the tycoon
    local tycoonId = TycoonSystem.generateTycoonId()
    
    -- Get a spawn point
    local spawnPoint = options.spawnPoint or TycoonSystem.getAvailableSpawnPoint()
    
    -- Set up default options
    local tycoonOptions = {
        id = tycoonId,
        ownerId = options.ownerId,
        ownerName = options.ownerName or "Unknown",
        template = options.template or "DefaultTycoon",
        name = options.name or "New Tycoon",
        spawnPoint = spawnPoint,
        state = "active",
        createdAt = os.time(),
        data = options.data or {}
    }
    
    -- Find the template
    local templateModel
    if CONFIG.TYCOON_TEMPLATE_LOCATION then
        templateModel = CONFIG.TYCOON_TEMPLATE_LOCATION:FindFirstChild(tycoonOptions.template)
    end
    
    if not templateModel then
        -- Try standard locations
        local locations = {
            ServerStorage:FindFirstChild("TycoonTemplates"),
            ServerStorage:FindFirstChild("Templates"),
            ReplicatedStorage:FindFirstChild("TycoonTemplates")
        }
        
        for _, location in ipairs(locations) do
            if location then
                templateModel = location:FindFirstChild(tycoonOptions.template)
                if templateModel then
                    break
                end
            end
        end
    end
    
    if not templateModel then
        warn("[TycoonSystem] Tycoon template not found: " .. tycoonOptions.template)
        return nil
    end
    
    -- Clone the template
    local tycoonInstance = templateModel:Clone()
    tycoonInstance.Name = tycoonOptions.name
    
    -- Update ownerId attributes
    local function tagWithOwnerId(instance)
        instance:SetAttribute("TycoonId", tycoonId)
        instance:SetAttribute("OwnerId", tycoonOptions.ownerId)
        
        for _, child in ipairs(instance:GetChildren()) do
            tagWithOwnerId(child)
        end
    end
    
    tagWithOwnerId(tycoonInstance)
    
    -- Position the tycoon
    tycoonInstance:PivotTo(spawnPoint)
    
    -- Parent to tycoons folder
    local tycoonsFolder = Workspace:FindFirstChild(CONFIG.TYCOONS_FOLDER_NAME) or Workspace
    tycoonInstance.Parent = tycoonsFolder
    
    -- Store in tycoons table
    tycoonOptions.instance = tycoonInstance
    tycoons[tycoonId] = tycoonOptions
    
    -- Run any initialization scripts in the tycoon
    local initScript = tycoonInstance:FindFirstChild("TycoonInit")
    if initScript and initScript:IsA("Script") then
        task.spawn(function()
            initScript.Disabled = false
        end)
    end
    
    log("Created tycoon: " .. tycoonId .. " for player " .. tycoonOptions.ownerName)
    return tycoonId
end

-- Remove a tycoon
function TycoonSystem.removeTycoon(tycoonId)
    if not tycoonId or not tycoons[tycoonId] then
        return false
    end
    
    local tycoon = tycoons[tycoonId]
    
    -- Save data before removing
    TycoonSystem.saveTycoonData(tycoonId)
    
    -- Clean up
    if tycoon.instance then
        tycoon.instance:Destroy()
    end
    
    -- Remove from player mapping
    if tycoon.ownerId then
        playerTycoons[tycoon.ownerId] = nil
    end
    
    -- Remove from tycoons table
    tycoons[tycoonId] = nil
    
    log("Removed tycoon: " .. tycoonId)
    return true
end

-- Update a tycoon's state
function TycoonSystem.updateTycoonState(tycoonId, state)
    if not tycoonId or not tycoons[tycoonId] then
        return false
    end
    
    local tycoon = tycoons[tycoonId]
    local oldState = tycoon.state
    tycoon.state = state
    
    -- Update visuals based on state
    if tycoon.instance then
        if state == "inactive" then
            -- Apply visual effect for inactive
            for _, child in ipairs(tycoon.instance:GetDescendants()) do
                if child:IsA("BasePart") and not child:GetAttribute("KeepActive") then
                    child.Transparency = math.min(0.5, child.Transparency + 0.3)
                end
            end
            
            -- Disable scripts
            for _, child in ipairs(tycoon.instance:GetDescendants()) do
                if child:IsA("Script") and not child:GetAttribute("KeepActive") then
                    child.Disabled = true
                end
            end
        elseif state == "active" and oldState ~= "active" then
            -- Remove visual effect for inactive
            for _, child in ipairs(tycoon.instance:GetDescendants()) do
                if child:IsA("BasePart") and not child:GetAttribute("KeepActive") then
                    -- Restore original transparency (might need to store these somewhere)
                    child.Transparency = math.max(0, child.Transparency - 0.3)
                end
            end
            
            -- Enable scripts
            for _, child in ipairs(tycoon.instance:GetDescendants()) do
                if child:IsA("Script") and not child:GetAttribute("KeepActive") then
                    child.Disabled = false
                end
            end
        elseif state == "abandoned" then
            -- Apply more pronounced visual effect for abandoned
            for _, child in ipairs(tycoon.instance:GetDescendants()) do
                if child:IsA("BasePart") and not child:GetAttribute("KeepActive") then
                    child.Transparency = math.min(0.8, child.Transparency + 0.5)
                end
            end
            
            -- Disable scripts
            for _, child in ipairs(tycoon.instance:GetDescendants()) do
                if child:IsA("Script") then
                    child.Disabled = true
                end
            end
        end
    end
    
    log("Updated tycoon state: " .. tycoonId .. " from " .. oldState .. " to " .. state)
    return true
end

-- Check for abandoned tycoons
function TycoonSystem.checkAbandonedTycoons()
    if not CONFIG.AUTO_CLEANUP_ABANDONED then
        return
    end
    
    local currentTime = os.time()
    local abandonedCount = 0
    
    for tycoonId, tycoon in pairs(tycoons) do
        if tycoon.state == "inactive" then
            local ownerId = tycoon.ownerId
            local lastSeen = lastPlayerSeen[ownerId] or 0
            
            if currentTime - lastSeen > CONFIG.ABANDONED_TIMEOUT then
                -- Mark as abandoned
                TycoonSystem.updateTycoonState(tycoonId, "abandoned")
                abandonedCount = abandonedCount + 1
            end
        end
    end
    
    if abandonedCount > 0 then
        log("Marked " .. abandonedCount .. " tycoons as abandoned")
    end
end

-- Save a tycoon's data
function TycoonSystem.saveTycoonData(tycoonId)
    if not tycoonId or not tycoons[tycoonId] then
        return false
    end
    
    local tycoon = tycoons[tycoonId]
    local ownerId = tycoon.ownerId
    
    if not ownerId then
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
    
    -- Get the player if they're still online
    local player = Players:GetPlayerByUserId(ownerId)
    
    -- Save using DataManager
    local DataManager = getDataManager()
    if DataManager and player then
        local success = DataManager.updateValue(player, CONFIG.SAVE_KEY, saveData)
        if success then
            log("Saved tycoon data for " .. tycoonId)
            return true
        end
    end
    
    return false
end

-- Teleport a player to a tycoon
function TycoonSystem.teleportToTycoon(player, tycoonId)
    if not player or not tycoonId or not tycoons[tycoonId] then
        return false
    end
    
    local tycoon = tycoons[tycoonId]
    if not tycoon.instance then
        return false
    end
    
    -- Look for spawn point
    local spawnLocation = tycoon.instance:FindFirstChild("SpawnLocation")
    if not spawnLocation then
        spawnLocation = tycoon.instance:FindFirstChild("PlayerSpawn")
    end
    
    local targetCFrame
    if spawnLocation and spawnLocation:IsA("BasePart") then
        targetCFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
    else
        -- Use tycoon pivot if no spawn point
        targetCFrame = tycoon.instance:GetPivot() + Vector3.new(0, 5, 0)
    end
    
    -- Teleport player
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        humanoidRootPart.CFrame = targetCFrame
        log("Teleported " .. player.Name .. " to tycoon: " .. tycoonId)
        return true
    end
    
    return false
end

-- Rename a tycoon
function TycoonSystem.renameTycoon(tycoonId, newName)
    if not tycoonId or not tycoons[tycoonId] or not newName or type(newName) ~= "string" then
        return false, "Invalid parameters"
    end
    
    -- Check name length and filter
    if #newName < 3 or #newName > 50 then
        return false, "Name must be between 3 and 50 characters"
    end
    
    local tycoon = tycoons[tycoonId]
    tycoon.name = newName
    
    -- Update instance name
    if tycoon.instance then
        tycoon.instance.Name = newName
    end
    
    log("Renamed tycoon " .. tycoonId .. " to: " .. newName)
    return true, "Tycoon renamed successfully"
end

-- Upgrade a tycoon
function TycoonSystem.upgradeTycoon(tycoonId, upgradeData)
    if not tycoonId or not tycoons[tycoonId] or not upgradeData then
        return false, "Invalid parameters"
    end
    
    local tycoon = tycoons[tycoonId]
    
    -- Check for upgrade handler in tycoon instance
    if tycoon.instance then
        local upgradeScript = tycoon.instance:FindFirstChild("TycoonUpgrade")
        if upgradeScript and upgradeScript:IsA("ModuleScript") then
            local success, upgradeModule = pcall(function()
                return require(upgradeScript)
            end)
            
            if success and upgradeModule and typeof(upgradeModule.upgrade) == "function" then
                local result, message = upgradeModule.upgrade(tycoon.instance, upgradeData)
                
                if result then
                    -- Save after successful upgrade
                    TycoonSystem.saveTycoonData(tycoonId)
                    log("Upgraded tycoon " .. tycoonId .. ": " .. (message or "success"))
                    return true, message or "Upgrade successful"
                else
                    return false, message or "Upgrade failed"
                end
            end
        end
    end
    
    return false, "Tycoon doesn't support upgrades"
end

-- Customize a tycoon
function TycoonSystem.customizeTycoon(tycoonId, customizationData)
    if not tycoonId or not tycoons[tycoonId] or not customizationData then
        return false, "Invalid parameters"
    end
    
    local tycoon = tycoons[tycoonId]
    
    -- Check for customization handler in tycoon instance
    if tycoon.instance then
        local customizeScript = tycoon.instance:FindFirstChild("TycoonCustomize")
        if customizeScript and customizeScript:IsA("ModuleScript") then
            local success, customizeModule = pcall(function()
                return require(customizeScript)
            end)
            
            if success and customizeModule and typeof(customizeModule.customize) == "function" then
                local result, message = customizeModule.customize(tycoon.instance, customizationData)
                
                if result then
                    -- Save after successful customization
                    TycoonSystem.saveTycoonData(tycoonId)
                    log("Customized tycoon " .. tycoonId .. ": " .. (message or "success"))
                    return true, message or "Customization successful"
                else
                    return false, message or "Customization failed"
                end
            end
        end
    end
    
    return false, "Tycoon doesn't support customization"
end

-- Client interface that's safe to expose to clients
function TycoonSystem:getClientInterface()
    local clientInterface = {
        getTycoonInfo = function(tycoonId)
            local tycoon = tycoons[tycoonId]
            if tycoon then
                return {
                    id = tycoonId,
                    name = tycoon.name,
                    owner = tycoon.ownerName,
                    template = tycoon.template
                }
            end
            return nil
        end
    }
    
    return clientInterface
end

-- Get the CoreRegistry if available
local function getCoreRegistry()
    -- Try standard paths
    local standardPaths = {
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("server") and ServerScriptService.server:FindFirstChild("Core") and ServerScriptService.server.Core:FindFirstChild("CoreRegistry")
    }
    
    -- Try to find via ModuleLoader if available
    local moduleLoaderSuccess, ModuleLoader = pcall(function()
        return require(ReplicatedStorage:FindFirstChild("shared", true) and ReplicatedStorage:FindFirstChild("shared", true):FindFirstChild("ModuleLoader"))
    end)
    
    if moduleLoaderSuccess and ModuleLoader then
        local coreRegistrySuccess, CoreRegistry = pcall(function() 
            return ModuleLoader.require("CoreRegistry")
        end)
        if coreRegistrySuccess and CoreRegistry then
            log("Found CoreRegistry via ModuleLoader")
            return CoreRegistry
        end
    end
    
    for _, path in ipairs(standardPaths) do
        if path and path:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(path)
            end)
            
            if success and result then
                return result
            end
        end
    end
    
    -- Try to find in any module with the name CoreRegistry
    local function searchInDescendants(parent)
        for _, child in ipairs(parent:GetDescendants()) do
            if child:IsA("ModuleScript") and child.Name == "CoreRegistry" then
                local success, result = pcall(function()
                    return require(child)
                end)
                
                if success and result then
                    return result
                end
            end
        end
        return nil
    end
    
    return searchInDescendants(game)
end

-- Initialize the TycoonSystem
function TycoonSystem.initialize()
    if TycoonSystem.initialized then
        log("TycoonSystem already initialized")
        return true
    end
    
    log("Initializing TycoonSystem...")
    
    -- Create tycoons folder in workspace if it doesn't exist
    local tycoonsFolder = Workspace:FindFirstChild(CONFIG.TYCOONS_FOLDER_NAME)
    if not tycoonsFolder then
        tycoonsFolder = Instance.new("Folder")
        tycoonsFolder.Name = CONFIG.TYCOONS_FOLDER_NAME
        tycoonsFolder.Parent = Workspace
        log("Created tycoons folder")
    end
    
    -- Register with CoreRegistry if available
    local CoreRegistry = getCoreRegistry()
    if CoreRegistry then
        if typeof(CoreRegistry.Register) == "function" then
            CoreRegistry:Register("TycoonSystem", TycoonSystem)
            log("Registered with CoreRegistry using Register function")
        elseif typeof(CoreRegistry.registerSystem) == "function" then
            CoreRegistry.registerSystem("TycoonSystem", TycoonSystem)
            log("Registered with CoreRegistry using registerSystem function")
        else
            log("CoreRegistry found but no registration function available")
        end
    else
        log("CoreRegistry not found, but TycoonSystem will still function")
    end
    
    -- Set up player added/removed events
    Players.PlayerAdded:Connect(function(player)
        task.spawn(function()
            TycoonSystem:setupPlayerTycoon(player)
        end)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        TycoonSystem:cleanupPlayerTycoon(player)
    end)
    
    -- Set up auto cleanup for abandoned tycoons
    if CONFIG.AUTO_CLEANUP_ABANDONED then
        task.spawn(function()
            while true do
                wait(60) -- Check every minute
                TycoonSystem:checkForAbandonedTycoons()
            end
        end)
    end
    
    -- Initialize existing players
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            TycoonSystem:setupPlayerTycoon(player)
        end)
    end
    
    TycoonSystem.initialized = true
    log("TycoonSystem initialized successfully")
    return true
end

-- Initialize the TycoonSystem
TycoonSystem.initialize()

-- Try to register with CoreRegistry
task.spawn(function()
    local CoreRegistry = getCoreRegistry()
    if CoreRegistry then
        if typeof(CoreRegistry.registerSystem) == "function" then
            CoreRegistry.registerSystem("TycoonSystem", TycoonSystem)
            log("Successfully registered with CoreRegistry via registerSystem")
        elseif typeof(CoreRegistry.Register) == "function" then
            CoreRegistry:Register("TycoonSystem", TycoonSystem)
            log("Successfully registered with CoreRegistry via Register")
        else
            warn("[TycoonSystem] CoreRegistry found but no registration method available")
        end
    else
        warn("[TycoonSystem] Could not find CoreRegistry for registration")
    end
end)

return TycoonSystem
