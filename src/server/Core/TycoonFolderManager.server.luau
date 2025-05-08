--[[
    TycoonFolderManager.server.luau
    
    Core system for managing tycoon folder structure and initialization.
    This system ensures proper folder creation, value initialization,
    and error recovery for player tycoons.
    
    Features:
    - Folder structure management
    - Value initialization
    - Error recovery
    - Health monitoring
    - Integration with CoreRegistry
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Configuration
local CONFIG = {
    debug = true,
    checkInterval = 30, -- seconds
    maxErrors = 50,
    errorRetentionTime = 3600, -- 1 hour
    maxRetries = 3,
    retryDelay = 1, -- seconds
    requiredFolders = {
        "Equipment",
        "Staff",
        "Stats",
        "Settings",
        "Upgrades"
    },
    requiredValues = {
        Stats = {
            "TotalVisitors",
            "TotalIncome",
            "TotalExpenses",
            "LastUpdated"
        },
        Settings = {
            "AutoMaintenance",
            "StaffRotation",
            "EquipmentUpgrades"
        }
    },
    defaultValues = {
        TotalVisitors = 0,
        TotalIncome = 0,
        TotalExpenses = 0,
        LastUpdated = 0,
        AutoMaintenance = false,
        StaffRotation = false,
        EquipmentUpgrades = false
    }
}

-- Module state
local TycoonFolderManager = {
    initialized = false,
    errors = {},
    lastCheck = 0,
    playerFolders = {}
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[TycoonFolderManager]", ...)
    end
end

-- Get ErrorHandler
local function getErrorHandler()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local handler = coreRegistry:getSystem("ErrorHandler")
        if handler then
            return handler
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("ErrorHandler") then
        local success, result = pcall(function()
            return require(core.ErrorHandler)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Create folder structure
local function createFolderStructure(player)
    if not player then return false end
    
    local success = true
    local createdFolders = {}
    
    -- Create main tycoon folder
    local tycoonFolder = player:FindFirstChild("Tycoon")
    if not tycoonFolder then
        tycoonFolder = Instance.new("Folder")
        tycoonFolder.Name = "Tycoon"
        tycoonFolder.Parent = player
    end
    
    -- Create required folders
    for _, folderName in ipairs(CONFIG.requiredFolders) do
        local folder = tycoonFolder:FindFirstChild(folderName)
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = folderName
            folder.Parent = tycoonFolder
            table.insert(createdFolders, folderName)
        end
    end
    
    -- Create required values
    for folderName, values in pairs(CONFIG.requiredValues) do
        local folder = tycoonFolder:FindFirstChild(folderName)
        if folder then
            for _, valueName in ipairs(values) do
                local value = folder:FindFirstChild(valueName)
                if not value then
                    value = Instance.new("NumberValue")
                    value.Name = valueName
                    value.Value = CONFIG.defaultValues[valueName] or 0
                    value.Parent = folder
                end
            end
        else
            success = false
            log("Missing required folder: " .. folderName .. " for " .. player.Name)
        end
    end
    
    -- Store reference
    TycoonFolderManager.playerFolders[player.UserId] = tycoonFolder
    
    if #createdFolders > 0 then
        log("Created folders for " .. player.Name .. ": " .. table.concat(createdFolders, ", "))
    end
    
    return success
end

-- Fix folder structure
local function fixFolderStructure(player)
    if not player then return false end
    
    log("Fixing folder structure for " .. player.Name)
    
    -- Remove invalid folders
    local tycoonFolder = player:FindFirstChild("Tycoon")
    if tycoonFolder then
        for _, child in ipairs(tycoonFolder:GetChildren()) do
            if child:IsA("Folder") and not table.find(CONFIG.requiredFolders, child.Name) then
                child:Destroy()
            end
        end
    end
    
    -- Create proper structure
    return createFolderStructure(player)
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(TycoonFolderManager.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #TycoonFolderManager.errors > CONFIG.maxErrors do
        table.remove(TycoonFolderManager.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #TycoonFolderManager.errors, 1, -1 do
        if TycoonFolderManager.errors[i].timestamp < cutoff then
            table.remove(TycoonFolderManager.errors, i)
        end
    end
    
    -- Report to ErrorHandler
    local errorHandler = getErrorHandler()
    if errorHandler then
        errorHandler:recordError(message, "tycoon_folder_manager", {
            timestamp = timestamp
        })
    end
    
    log("Error recorded: " .. message)
end

-- Check system health
local function checkHealth()
    local now = os.time()
    TycoonFolderManager.lastCheck = now
    
    -- Check all player folders
    for userId, folder in pairs(TycoonFolderManager.playerFolders) do
        if not folder.Parent then
            -- Folder was removed, try to fix
            local player = game.Players:GetPlayerByUserId(userId)
            if player then
                fixFolderStructure(player)
            else
                -- Player left, remove from tracking
                TycoonFolderManager.playerFolders[userId] = nil
            end
        end
    end
    
    return true
end

-- Initialize TycoonFolderManager
function TycoonFolderManager.initialize()
    if TycoonFolderManager.initialized then return true end
    
    log("Initializing TycoonFolderManager...")
    
    -- Get required systems
    local errorHandler = getErrorHandler()
    if not errorHandler then
        log("ErrorHandler not found, error reporting may be limited")
    end
    
    -- Start health monitoring
    task.spawn(function()
        while true do
            task.wait(CONFIG.checkInterval)
            checkHealth()
        end
    end)
    
    -- Handle player joining
    game.Players.PlayerAdded:Connect(function(player)
        task.spawn(function()
            local success = createFolderStructure(player)
            if not success then
                recordError("Failed to create folder structure for " .. player.Name)
            end
        end)
    end)
    
    -- Handle player leaving
    game.Players.PlayerRemoving:Connect(function(player)
        TycoonFolderManager.playerFolders[player.UserId] = nil
    end)
    
    -- Initialize existing players
    for _, player in ipairs(game.Players:GetPlayers()) do
        task.spawn(function()
            local success = createFolderStructure(player)
            if not success then
                recordError("Failed to create folder structure for " .. player.Name)
            end
        end)
    end
    
    TycoonFolderManager.initialized = true
    log("TycoonFolderManager initialized")
    return true
end

-- Get player's tycoon folder
function TycoonFolderManager.getTycoonFolder(player)
    if not player then return nil end
    
    local folder = TycoonFolderManager.playerFolders[player.UserId]
    if not folder then
        -- Try to create if missing
        if createFolderStructure(player) then
            folder = TycoonFolderManager.playerFolders[player.UserId]
        end
    end
    
    return folder
end

-- Fix player's folder structure
function TycoonFolderManager.fixPlayerFolders(player)
    if not player then return false end
    return fixFolderStructure(player)
end

-- Get error count
function TycoonFolderManager.getErrorCount()
    return #TycoonFolderManager.errors
end

-- Get recent errors
function TycoonFolderManager.getRecentErrors()
    return TycoonFolderManager.errors
end

-- Force a health check
function TycoonFolderManager.forceCheck()
    return checkHealth()
end

return TycoonFolderManager 