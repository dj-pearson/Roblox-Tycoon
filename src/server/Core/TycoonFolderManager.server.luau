--[[
    TycoonFolderManager.server.luau
    
    Enhanced tycoon folder management system that ensures reliable folder structure
    and initialization for player tycoons.
    
    Features:
    - Reliable folder structure creation and validation
    - Default value initialization
    - Error recovery and repair
    - Integration with CoreRegistry
    - Health monitoring and status reporting
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    debug = true,
    checkInterval = 30, -- seconds
    maxRetries = 3,
    retryDelay = 1, -- seconds,
    requiredFolders = {
        "Equipment",
        "Stats",
        "Settings",
        "Data",
        "Upgrades"
    },
    defaultValues = {
        Stats = {
            Money = 0,
            Experience = 0,
            Level = 1
        },
        Settings = {
            AutoSave = true,
            Notifications = true
        },
        Data = {
            LastSave = 0,
            Created = 0
        }
    }
}

-- Module state
local TycoonFolderManager = {
    initialized = false,
    tycoons = {},      -- Active tycoon folders
    errors = {},       -- Error history
    lastCheck = 0      -- Last health check time
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[TycoonFolderManager]", ...)
    end
end

-- Get ModuleResolver
local function getModuleResolver()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local resolver = coreRegistry:getSystem("ModuleResolver")
        if resolver then
            return resolver
        end
    end
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if core and core:FindFirstChild("ModuleResolver") then
        local success, result = pcall(function()
            return require(core.ModuleResolver)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Create a folder
local function createFolder(name, parent)
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

-- Create a value
local function createValue(name, value, parent)
    local valueInstance
    
    if typeof(value) == "number" then
        valueInstance = Instance.new("NumberValue")
    elseif typeof(value) == "string" then
        valueInstance = Instance.new("StringValue")
    elseif typeof(value) == "boolean" then
        valueInstance = Instance.new("BoolValue")
    else
        valueInstance = Instance.new("ObjectValue")
    end
    
    valueInstance.Name = name
    valueInstance.Value = value
    valueInstance.Parent = parent
    
    return valueInstance
end

-- Initialize TycoonFolderManager
function TycoonFolderManager.initialize()
    if TycoonFolderManager.initialized then return true end
    
    log("Initializing TycoonFolderManager...")
    
    -- Get ModuleResolver
    local resolver = getModuleResolver()
    if not resolver then
        log("ModuleResolver not found, folder creation may be limited", true)
    end
    
    -- Start health monitoring
    task.spawn(function()
        while true do
            task.wait(CONFIG.checkInterval)
            TycoonFolderManager.checkHealth()
        end
    end)
    
    TycoonFolderManager.initialized = true
    log("TycoonFolderManager initialized")
    return true
end

-- Create tycoon folder structure
function TycoonFolderManager.createTycoonFolder(player)
    if not TycoonFolderManager.initialized then
        TycoonFolderManager.initialize()
    end
    
    local playerName = player.Name
    log("Creating tycoon folder for: " .. playerName)
    
    -- Check if tycoon already exists
    if TycoonFolderManager.tycoons[playerName] then
        log("Tycoon folder already exists for: " .. playerName)
        return TycoonFolderManager.tycoons[playerName]
    end
    
    -- Create root folder
    local rootFolder = createFolder(playerName, ServerStorage)
    
    -- Create required folders
    for _, folderName in ipairs(CONFIG.requiredFolders) do
        local folder = createFolder(folderName, rootFolder)
        
        -- Initialize default values
        if CONFIG.defaultValues[folderName] then
            for name, value in pairs(CONFIG.defaultValues[folderName]) do
                createValue(name, value, folder)
            end
        end
    end
    
    -- Set creation time
    local dataFolder = rootFolder:FindFirstChild("Data")
    if dataFolder then
        local createdValue = dataFolder:FindFirstChild("Created")
        if createdValue then
            createdValue.Value = os.time()
        end
    end
    
    -- Store tycoon folder
    TycoonFolderManager.tycoons[playerName] = rootFolder
    
    return rootFolder
end

-- Get tycoon folder
function TycoonFolderManager.getTycoonFolder(player)
    local playerName = player.Name
    return TycoonFolderManager.tycoons[playerName]
end

-- Remove tycoon folder
function TycoonFolderManager.removeTycoonFolder(player)
    local playerName = player.Name
    local folder = TycoonFolderManager.tycoons[playerName]
    if folder then
        folder:Destroy()
        TycoonFolderManager.tycoons[playerName] = nil
    end
end

-- Validate tycoon folder
function TycoonFolderManager.validateTycoonFolder(player)
    local playerName = player.Name
    local folder = TycoonFolderManager.tycoons[playerName]
    if not folder then
        return false, "Tycoon folder not found"
    end
    
    -- Check required folders
    for _, folderName in ipairs(CONFIG.requiredFolders) do
        local requiredFolder = folder:FindFirstChild(folderName)
        if not requiredFolder then
            return false, "Missing required folder: " .. folderName
        end
        
        -- Check default values
        if CONFIG.defaultValues[folderName] then
            for name, value in pairs(CONFIG.defaultValues[folderName]) do
                local valueInstance = requiredFolder:FindFirstChild(name)
                if not valueInstance then
                    return false, "Missing required value: " .. name .. " in " .. folderName
                end
            end
        end
    end
    
    return true, "Valid"
end

-- Repair tycoon folder
function TycoonFolderManager.repairTycoonFolder(player)
    local playerName = player.Name
    local folder = TycoonFolderManager.tycoons[playerName]
    if not folder then
        return false, "Tycoon folder not found"
    end
    
    log("Repairing tycoon folder for: " .. playerName)
    
    -- Check and create required folders
    for _, folderName in ipairs(CONFIG.requiredFolders) do
        local requiredFolder = folder:FindFirstChild(folderName)
        if not requiredFolder then
            requiredFolder = createFolder(folderName, folder)
            log("Created missing folder: " .. folderName)
        end
        
        -- Check and create default values
        if CONFIG.defaultValues[folderName] then
            for name, value in pairs(CONFIG.defaultValues[folderName]) do
                local valueInstance = requiredFolder:FindFirstChild(name)
                if not valueInstance then
                    createValue(name, value, requiredFolder)
                    log("Created missing value: " .. name .. " in " .. folderName)
                end
            end
        end
    end
    
    return true, "Repaired"
end

-- Check system health
function TycoonFolderManager.checkHealth()
    local now = os.time()
    TycoonFolderManager.lastCheck = now
    
    -- Check tycoon count
    local tycoonCount = 0
    for _ in pairs(TycoonFolderManager.tycoons) do
        tycoonCount = tycoonCount + 1
    end
    
    if tycoonCount > 100 then
        TycoonFolderManager.recordError("Too many tycoons: " .. tycoonCount)
    end
    
    -- Check error count
    if #TycoonFolderManager.errors > 50 then
        TycoonFolderManager.recordError("Too many errors: " .. #TycoonFolderManager.errors)
    end
    
    return true
end

-- Record an error
function TycoonFolderManager.recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(TycoonFolderManager.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #TycoonFolderManager.errors > 50 do
        table.remove(TycoonFolderManager.errors, 1)
    end
    
    log("Error recorded: " .. message)
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
    return TycoonFolderManager.checkHealth()
end

return TycoonFolderManager 