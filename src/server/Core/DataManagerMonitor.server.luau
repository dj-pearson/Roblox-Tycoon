--[[
    DataManagerMonitor.server.luau
    
    Monitor for the DataManager that tracks its health and status.
    This monitor ensures the DataManager is functioning correctly
    and provides real-time status updates.
    
    Features:
    - Health monitoring of DataManager
    - Error tracking and reporting
    - Integration with CoreRegistry
    - Status updates in ReplicatedStorage
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    debug = true,
    checkInterval = 30, -- seconds
    maxErrors = 50,
    errorRetentionTime = 3600 -- 1 hour
}

-- Module state
local DataManagerMonitor = {
    status = "unknown",
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

-- Get DataManager
local function getDataManager()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local manager = coreRegistry:getSystem("DataManager")
        if manager then
            return manager
        end
    end
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if core and core:FindFirstChild("DataManager") then
        local success, result = pcall(function()
            return require(core.DataManager)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Check DataManager health
local function checkDataManagerHealth()
    local manager = getDataManager()
    if not manager then
        return false, "DataManager not found"
    end
    
    -- Check if initialized
    if not manager.initialized then
        return false, "DataManager not initialized"
    end
    
    -- Check error count
    local errorCount = manager.getErrorCount()
    if errorCount > 0 then
        return false, "DataManager has " .. errorCount .. " errors"
    end
    
    -- Check recovery queue
    if #manager.recoveryQueue > 100 then
        return false, "Recovery queue too large: " .. #manager.recoveryQueue
    end
    
    return true, "Healthy"
end

-- Record an error
local function recordError(message)
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
local function updateStatus(status, message)
    DataManagerMonitor.status = status
    DataManagerMonitor.lastCheck = os.time()
    
    -- Create status folder if it doesn't exist
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
    statusValue.Value = status
    
    -- Update message value
    local messageValue = statusFolder:FindFirstChild("Message")
    if not messageValue then
        messageValue = Instance.new("StringValue")
        messageValue.Name = "Message"
        messageValue.Parent = statusFolder
    end
    messageValue.Value = message
    
    -- Update last check value
    local lastCheckValue = statusFolder:FindFirstChild("LastCheck")
    if not lastCheckValue then
        lastCheckValue = Instance.new("NumberValue")
        lastCheckValue.Name = "LastCheck"
        lastCheckValue.Parent = statusFolder
    end
    lastCheckValue.Value = DataManagerMonitor.lastCheck
    
    log("Status updated: " .. status .. " - " .. message)
end

-- Monitor health
local function monitorHealth()
    while true do
        local success, message = checkDataManagerHealth()
        
        if success then
            updateStatus("healthy", message)
        else
            recordError(message)
            updateStatus("error", message)
        end
        
        task.wait(CONFIG.checkInterval)
    end
end

-- Initialize monitor
function DataManagerMonitor.initialize()
    if DataManagerMonitor.initialized then return true end
    
    log("Initializing DataManagerMonitor...")
    
    -- Check for DataManager
    local manager = getDataManager()
    if not manager then
        log("DataManager not found, monitoring may be limited")
    end
    
    -- Start monitoring
    task.spawn(monitorHealth)
    
    DataManagerMonitor.initialized = true
    log("DataManagerMonitor initialized")
    return true
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
    local success, message = checkDataManagerHealth()
    updateStatus(success and "healthy" or "error", message)
    return success
end

return DataManagerMonitor 