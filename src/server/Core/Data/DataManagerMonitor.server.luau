--[[
    DataManagerMonitor.server.luau
    
    Monitors the health and status of the DataManager system.
    Provides real-time status updates and error reporting.
    
    Features:
    - Health monitoring
    - Error tracking
    - Status reporting
    - Integration with CoreRegistry
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    debug = true,
    checkInterval = 30, -- seconds
    maxErrors = 10,
    errorRetentionTime = 300, -- seconds
    criticalSystems = {
        "DataManager",
        "BuyTileSystem",
        "TycoonStructure"
    }
}

-- Module state
local DataManagerMonitor = {
    status = "initializing",
    lastCheck = 0,
    errors = {},
    initialized = false
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[DataManagerMonitor]", ...)
    end
end

-- Get DataManager instance
local function getDataManager()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry then
        local dataManager = coreRegistry.getSystem("DataManager")
        if dataManager then
            return dataManager
        end
    end
    
    -- Try to get from global
    if _G.DataManager then
        return _G.DataManager
    end
    
    -- Try to require from ServerScriptService
    local success, result = pcall(function()
        return require(game:GetService("ServerScriptService").Core.Data.DataManager)
    end)
    
    if success and result then
        return result
    end
    
    return nil
end

-- Check DataManager health
function DataManagerMonitor.checkHealth()
    local dataManager = getDataManager()
    if not dataManager then
        DataManagerMonitor.recordError("DataManager not found")
        return false
    end
    
    -- Check if DataManager is initialized
    if not dataManager.initialized then
        DataManagerMonitor.recordError("DataManager not initialized")
        return false
    end
    
    -- Check if DataStore is available
    if not dataManager.dataStore then
        DataManagerMonitor.recordError("DataStore not available")
        return false
    end
    
    -- Check if backup store is available
    if not dataManager.backupStore then
        DataManagerMonitor.recordError("Backup store not available")
        return false
    end
    
    -- Check critical systems
    for _, systemName in ipairs(CONFIG.criticalSystems) do
        local system = CoreRegistry.getSystem(systemName)
        if not system then
            DataManagerMonitor.recordError("Critical system not found: " .. systemName)
            return false
        end
    end
    
    -- Check for any players with unloaded data
    local players = game:GetService("Players"):GetPlayers()
    for _, player in ipairs(players) do
        if not dataManager.loaded[player.UserId] then
            DataManagerMonitor.recordError("Player data not loaded: " .. player.Name)
            return false
        end
    end
    
    return true
end

-- Record an error
function DataManagerMonitor.recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(DataManagerMonitor.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #DataManagerMonitor.errors > CONFIG.maxErrors do
        table.remove(DataManagerMonitor.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #DataManagerMonitor.errors, 1, -1 do
        if DataManagerMonitor.errors[i].timestamp < cutoff then
            table.remove(DataManagerMonitor.errors, i)
        end
    end
    
    log("Error recorded: " .. message)
end

-- Update status
function DataManagerMonitor.updateStatus()
    local statusFolder = ReplicatedStorage:FindFirstChild("DataManagerStatus")
    if not statusFolder then
        statusFolder = Instance.new("Folder")
        statusFolder.Name = "DataManagerStatus"
        statusFolder.Parent = ReplicatedStorage
    end
    
    -- Update status value
    local statusValue = statusFolder:FindFirstChild("Status")
    if not statusValue then
        statusValue = Instance.new("StringValue")
        statusValue.Name = "Status"
        statusValue.Parent = statusFolder
    end
    statusValue.Value = DataManagerMonitor.status
    
    -- Update last checked value
    local lastCheckedValue = statusFolder:FindFirstChild("LastChecked")
    if not lastCheckedValue then
        lastCheckedValue = Instance.new("NumberValue")
        lastCheckedValue.Name = "LastChecked"
        lastCheckedValue.Parent = statusFolder
    end
    lastCheckedValue.Value = DataManagerMonitor.lastCheck
    
    -- Update error count
    local errorCountValue = statusFolder:FindFirstChild("ErrorCount")
    if not errorCountValue then
        errorCountValue = Instance.new("IntValue")
        errorCountValue.Name = "ErrorCount"
        errorCountValue.Parent = statusFolder
    end
    errorCountValue.Value = #DataManagerMonitor.errors
end

-- Monitor health
function DataManagerMonitor.monitorHealth()
    if DataManagerMonitor.initialized then return end
    
    log("Starting health monitoring...")
    
    -- Initial delay to allow systems to initialize
    task.wait(5)
    
    -- Start monitoring loop
    RunService.Heartbeat:Connect(function()
        local now = os.time()
        if now - DataManagerMonitor.lastCheck >= CONFIG.checkInterval then
            DataManagerMonitor.lastCheck = now
            
            -- Check health
            local isHealthy = DataManagerMonitor.checkHealth()
            DataManagerMonitor.status = isHealthy and "healthy" or "unhealthy"
            
            -- Update status
            DataManagerMonitor.updateStatus()
            
            -- Log status
            log("Health check completed. Status: " .. DataManagerMonitor.status)
        end
    end)
    
    DataManagerMonitor.initialized = true
    log("Health monitoring started")
end

-- Get current status
function DataManagerMonitor.getStatus()
    return DataManagerMonitor.status
end

-- Get last check time
function DataManagerMonitor.getLastCheck()
    return DataManagerMonitor.lastCheck
end

-- Get error count
function DataManagerMonitor.getErrorCount()
    return #DataManagerMonitor.errors
end

-- Get recent errors
function DataManagerMonitor.getRecentErrors()
    return DataManagerMonitor.errors
end

-- Force a health check
function DataManagerMonitor.forceCheck()
    DataManagerMonitor.lastCheck = 0
    return DataManagerMonitor.checkHealth()
end

return DataManagerMonitor 