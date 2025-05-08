--[[
    ErrorHandlerMonitor.luau
    
    Monitor for the ErrorHandler that tracks its health and status.
    This monitor ensures the ErrorHandler is functioning correctly
    and provides real-time status updates.
    
    Features:
    - Health monitoring of ErrorHandler
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
local ErrorHandlerMonitor = {
    status = "unknown",
    lastCheck = 0,
    errors = {},
    initialized = false
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[ErrorHandlerMonitor]", ...)
    end
end

-- Get ErrorHandler
local function getErrorHandler()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local system = coreRegistry:getSystem("ErrorHandler")
        if system then
            return system
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

-- Check ErrorHandler health
local function checkErrorHandlerHealth()
    local system = getErrorHandler()
    if not system then
        return false, "ErrorHandler not found"
    end
    
    -- Check if initialized
    if not system.initialized then
        return false, "ErrorHandler not initialized"
    end
    
    -- Check error count
    local errorCount = system.getErrorCount()
    if errorCount > 0 then
        return false, "ErrorHandler has " .. errorCount .. " errors"
    end
    
    -- Check recovery attempts
    local recoveryAttempts = system.recoveryAttempts
    if not recoveryAttempts then
        return false, "Recovery attempts not found"
    end
    
    -- Check for too many recovery attempts
    for key, attempts in pairs(recoveryAttempts) do
        if attempts > system.CONFIG.maxRetries then
            return false, "Too many recovery attempts for: " .. key
        end
    end
    
    return true, "Healthy"
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(ErrorHandlerMonitor.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #ErrorHandlerMonitor.errors > CONFIG.maxErrors do
        table.remove(ErrorHandlerMonitor.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #ErrorHandlerMonitor.errors, 1, -1 do
        if ErrorHandlerMonitor.errors[i].timestamp < cutoff then
            table.remove(ErrorHandlerMonitor.errors, i)
        end
    end
    
    log("Error recorded: " .. message)
end

-- Update status
local function updateStatus(status, message)
    ErrorHandlerMonitor.status = status
    ErrorHandlerMonitor.lastCheck = os.time()
    
    -- Create status folder if it doesn't exist
    local statusFolder = ReplicatedStorage:FindFirstChild("ErrorHandlerStatus")
    if not statusFolder then
        statusFolder = Instance.new("Folder")
        statusFolder.Name = "ErrorHandlerStatus"
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
    lastCheckValue.Value = ErrorHandlerMonitor.lastCheck
    
    log("Status updated: " .. status .. " - " .. message)
end

-- Monitor health
local function monitorHealth()
    while true do
        local success, message = checkErrorHandlerHealth()
        
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
function ErrorHandlerMonitor.initialize()
    if ErrorHandlerMonitor.initialized then return true end
    
    log("Initializing ErrorHandlerMonitor...")
    
    -- Check for ErrorHandler
    local system = getErrorHandler()
    if not system then
        log("ErrorHandler not found, monitoring may be limited")
    end
    
    -- Start monitoring
    task.spawn(monitorHealth)
    
    ErrorHandlerMonitor.initialized = true
    log("ErrorHandlerMonitor initialized")
    return true
end

-- Get current status
function ErrorHandlerMonitor.getStatus()
    return ErrorHandlerMonitor.status
end

-- Get last check time
function ErrorHandlerMonitor.getLastCheck()
    return ErrorHandlerMonitor.lastCheck
end

-- Get error count
function ErrorHandlerMonitor.getErrorCount()
    return #ErrorHandlerMonitor.errors
end

-- Get recent errors
function ErrorHandlerMonitor.getRecentErrors()
    return ErrorHandlerMonitor.errors
end

-- Force a health check
function ErrorHandlerMonitor.forceCheck()
    local success, message = checkErrorHandlerHealth()
    updateStatus(success and "healthy" or "error", message)
    return success
end

return ErrorHandlerMonitor 