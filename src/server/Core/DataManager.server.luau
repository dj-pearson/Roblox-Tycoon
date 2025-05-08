--!strict
--[[
    DataManager.server.luau
    
    Manages data persistence and recovery for the gym tycoon system.
    This system ensures reliable data storage and retrieval with proper
    validation and error recovery.
    
    Features:
    - Data persistence and recovery
    - Data validation and repair
    - Error tracking and reporting
    - Integration with CoreRegistry
    - Health monitoring
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Configuration
local CONFIG = {
    debug = true,
    checkInterval = 30, -- seconds
    maxRetries = 3,
    retryDelay = 1, -- seconds,
    maxErrors = 50,
    errorRetentionTime = 3600, -- 1 hour
    dataStoreName = "GymTycoonData",
    dataStoreScope = "v1",
    defaultData = {
        gymLayout = {},
        progress = {
            level = 1,
            experience = 0,
            currency = 0
        },
        settings = {
            musicVolume = 0.5,
            sfxVolume = 0.5
        }
    },
    fallbackAssets = {
        -- Map of asset IDs to fallback IDs
        [8093763464] = 1234567890 -- Example fallback
    }
}

-- Module state
local DataManager = {
    initialized = false,
    dataStore = nil,
    loadedData = {},      -- Cache of loaded data
    errors = {},         -- Error history
    lastCheck = 0,       -- Last health check time
    recoveryQueue = {}   -- Queue of data to recover
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[DataManager]", ...)
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
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
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

-- Validate data structure
local function validateData(data)
    if not data then return false, "No data provided" end
    
    -- Check required fields
    if not data.gymLayout then
        return false, "Missing gymLayout"
    end
    if not data.progress then
        return false, "Missing progress"
    end
    if not data.settings then
        return false, "Missing settings"
    end
    
    -- Validate progress
    if typeof(data.progress.level) ~= "number" then
        return false, "Invalid progress.level"
    end
    if typeof(data.progress.experience) ~= "number" then
        return false, "Invalid progress.experience"
    end
    if typeof(data.progress.currency) ~= "number" then
        return false, "Invalid progress.currency"
    end
    
    -- Validate settings
    if typeof(data.settings.musicVolume) ~= "number" then
        return false, "Invalid settings.musicVolume"
    end
    if typeof(data.settings.sfxVolume) ~= "number" then
        return false, "Invalid settings.sfxVolume"
    end
    
    return true
end

-- Repair data structure
local function repairData(data)
    local repaired = table.clone(CONFIG.defaultData)
    
    -- Merge existing data with defaults
    for key, value in pairs(data) do
        if typeof(value) == "table" then
            repaired[key] = repairData(value)
        else
            repaired[key] = value
        end
    end
    
    return repaired
end

-- Load data for a player
function DataManager.loadData(player)
    if not DataManager.initialized then
        DataManager.initialize()
    end
    
    local userId = player.UserId
    if DataManager.loadedData[userId] then
        return DataManager.loadedData[userId]
    end
    
    local success, data = pcall(function()
        return DataManager.dataStore:GetAsync(tostring(userId))
    end)
    
    if not success then
        local errorHandler = getErrorHandler()
        if errorHandler then
            errorHandler.recordError("Failed to load data for " .. userId, "data_load", {
                error = data,
                userId = userId
            })
        end
        return CONFIG.defaultData
    end
    
    -- Validate and repair data
    local isValid, error = validateData(data)
    if not isValid then
        log("Invalid data for " .. userId .. ": " .. error)
        data = repairData(data)
    end
    
    DataManager.loadedData[userId] = data
    return data
end

-- Save data for a player
function DataManager.saveData(player)
    if not DataManager.initialized then
        DataManager.initialize()
    end
    
    local userId = player.UserId
    local data = DataManager.loadedData[userId]
    if not data then
        return false, "No data to save"
    end
    
    local success, result = pcall(function()
        return DataManager.dataStore:SetAsync(tostring(userId), data)
    end)
    
    if not success then
        local errorHandler = getErrorHandler()
        if errorHandler then
            errorHandler.recordError("Failed to save data for " .. userId, "data_save", {
                error = result,
                userId = userId
            })
        end
        return false, result
    end
    
    return true
end

-- Update gym layout
function DataManager.updateGymLayout(player, layout)
    if not DataManager.initialized then
        DataManager.initialize()
    end
    
    local userId = player.UserId
    local data = DataManager.loadedData[userId]
    if not data then
        data = DataManager.loadData(player)
    end
    
    data.gymLayout = layout
    DataManager.loadedData[userId] = data
    
    -- Queue save
    table.insert(DataManager.recoveryQueue, {
        type = "save",
        userId = userId,
        timestamp = os.time()
    })
    
    return true
end

-- Update progress
function DataManager.updateProgress(player, progress)
    if not DataManager.initialized then
        DataManager.initialize()
    end
    
    local userId = player.UserId
    local data = DataManager.loadedData[userId]
    if not data then
        data = DataManager.loadData(player)
    end
    
    -- Merge progress
    for key, value in pairs(progress) do
        data.progress[key] = value
    end
    
    DataManager.loadedData[userId] = data
    
    -- Queue save
    table.insert(DataManager.recoveryQueue, {
        type = "save",
        userId = userId,
        timestamp = os.time()
    })
    
    return true
end

-- Update settings
function DataManager.updateSettings(player, settings)
    if not DataManager.initialized then
        DataManager.initialize()
    end
    
    local userId = player.UserId
    local data = DataManager.loadedData[userId]
    if not data then
        data = DataManager.loadData(player)
    end
    
    -- Merge settings
    for key, value in pairs(settings) do
        data.settings[key] = value
    end
    
    DataManager.loadedData[userId] = data
    
    -- Queue save
    table.insert(DataManager.recoveryQueue, {
        type = "save",
        userId = userId,
        timestamp = os.time()
    })
    
    return true
end

-- Process recovery queue
local function processRecoveryQueue()
    while true do
        if #DataManager.recoveryQueue > 0 then
            local item = table.remove(DataManager.recoveryQueue, 1)
            
            if item.type == "save" then
                local player = game.Players:GetPlayerByUserId(item.userId)
                if player then
                    DataManager.saveData(player)
                end
            end
        end
        
        task.wait(CONFIG.retryDelay)
    end
end

-- Initialize DataManager
function DataManager.initialize()
    if DataManager.initialized then return true end
    
    log("Initializing DataManager...")
    
    -- Initialize DataStore
    DataManager.dataStore = DataStoreService:GetDataStore(
        CONFIG.dataStoreName,
        CONFIG.dataStoreScope
    )
    
    -- Start recovery queue processing
    task.spawn(processRecoveryQueue)
    
    -- Start health monitoring
    task.spawn(function()
        while true do
            task.wait(CONFIG.checkInterval)
            DataManager.checkHealth()
        end
    end)
    
    DataManager.initialized = true
    log("DataManager initialized")
    return true
end

-- Check system health
function DataManager.checkHealth()
    local now = os.time()
    DataManager.lastCheck = now
    
    -- Check error count
    if #DataManager.errors > CONFIG.maxErrors then
        local errorHandler = getErrorHandler()
        if errorHandler then
            errorHandler.recordError("Too many errors: " .. #DataManager.errors, "health_check")
        end
    end
    
    -- Check recovery queue
    if #DataManager.recoveryQueue > 100 then
        local errorHandler = getErrorHandler()
        if errorHandler then
            errorHandler.recordError("Recovery queue too large: " .. #DataManager.recoveryQueue, "health_check")
        end
    end
    
    return true
end

-- Record an error
function DataManager.recordError(message, errorType, context)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(DataManager.errors, {
        message = message,
        type = errorType,
        context = context,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #DataManager.errors > CONFIG.maxErrors do
        table.remove(DataManager.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #DataManager.errors, 1, -1 do
        if DataManager.errors[i].timestamp < cutoff then
            table.remove(DataManager.errors, i)
        end
    end
    
    log("Error recorded: " .. message)
end

-- Get error count
function DataManager.getErrorCount()
    return #DataManager.errors
end

-- Get recent errors
function DataManager.getRecentErrors()
    return DataManager.errors
end

-- Force a health check
function DataManager.forceCheck()
    return DataManager.checkHealth()
end

return DataManager
