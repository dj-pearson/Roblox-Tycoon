--[[
    PathManagerMonitor.luau
    
    Monitor for the PathManager that tracks its health and status.
    This monitor ensures the PathManager is functioning correctly
    and provides real-time status updates.
    
    Features:
    - Health monitoring of PathManager
    - Error tracking and reporting
    - Integration with CoreRegistry
    - Status updates in ReplicatedStorage
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    debug = true,
    checkInterval = 30, -- seconds
    maxErrors = 50,
    errorRetentionTime = 3600 -- 1 hour
}

-- Module state
local PathManagerMonitor = {
    status = "unknown",
    lastCheck = 0,
    errors = {},
    initialized = false
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[PathManagerMonitor]", ...)
    end
end

-- Get PathManager
local function getPathManager()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local system = coreRegistry:getSystem("PathManager")
        if system then
            return system
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("PathManager") then
        local success, result = pcall(function()
            return require(core.PathManager)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Check PathManager health
local function checkPathManagerHealth()
    local system = getPathManager()
    if not system then
        return false, "PathManager not found"
    end
    
    -- Check if initialized
    if not system.initialized then
        return false, "PathManager not initialized"
    end
    
    -- Check error count
    local errorCount = system.getErrorCount()
    if errorCount > 0 then
        return false, "PathManager has " .. errorCount .. " errors"
    end
    
    -- Check required paths
    for category, paths in pairs(system.CONFIG.requiredPaths) do
        for _, path in ipairs(paths) do
            local success, result = system.validatePath(path)
            if not success then
                return false, "Required path not found: " .. path
            end
        end
    end
    
    return true, "Healthy"
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(PathManagerMonitor.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #PathManagerMonitor.errors > CONFIG.maxErrors do
        table.remove(PathManagerMonitor.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #PathManagerMonitor.errors, 1, -1 do
        if PathManagerMonitor.errors[i].timestamp < cutoff then
            table.remove(PathManagerMonitor.errors, i)
        end
    end
    
    log("Error recorded: " .. message)
end

-- Update status
local function updateStatus(status, message)
    PathManagerMonitor.status = status
    PathManagerMonitor.lastCheck = os.time()
    
    -- Create status folder if it doesn't exist
    local statusFolder = ReplicatedStorage:FindFirstChild("PathManagerStatus")
    if not statusFolder then
        statusFolder = Instance.new("Folder")
        statusFolder.Name = "PathManagerStatus"
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
    lastCheckValue.Value = PathManagerMonitor.lastCheck
    
    log("Status updated: " .. status .. " - " .. message)
end

-- Monitor health
local function monitorHealth()
    while true do
        local success, message = checkPathManagerHealth()
        
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
function PathManagerMonitor.initialize()
    if PathManagerMonitor.initialized then return true end
    
    log("Initializing PathManagerMonitor...")
    
    -- Check for PathManager
    local system = getPathManager()
    if not system then
        log("PathManager not found, monitoring may be limited")
    end
    
    -- Start monitoring
    task.spawn(monitorHealth)
    
    PathManagerMonitor.initialized = true
    log("PathManagerMonitor initialized")
    return true
end

-- Get current status
function PathManagerMonitor.getStatus()
    return PathManagerMonitor.status
end

-- Get last check time
function PathManagerMonitor.getLastCheck()
    return PathManagerMonitor.lastCheck
end

-- Get error count
function PathManagerMonitor.getErrorCount()
    return #PathManagerMonitor.errors
end

-- Get recent errors
function PathManagerMonitor.getRecentErrors()
    return PathManagerMonitor.errors
end

-- Force a health check
function PathManagerMonitor.forceCheck()
    local success, message = checkPathManagerHealth()
    updateStatus(success and "healthy" or "error", message)
    return success
end

return PathManagerMonitor 