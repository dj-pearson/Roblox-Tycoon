--[[
    GymAutomationMonitor.server.luau
    
    Monitor for the GymAutomation system that tracks its health and status.
    This monitor ensures the GymAutomation system is functioning correctly
    and provides real-time status updates.
    
    Features:
    - Health monitoring of GymAutomation
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
local GymAutomationMonitor = {
    status = "unknown",
    lastCheck = 0,
    errors = {},
    initialized = false
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[GymAutomationMonitor]", ...)
    end
end

-- Get GymAutomation
local function getGymAutomation()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local system = coreRegistry:getSystem("GymAutomation")
        if system then
            return system
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("GymAutomation") then
        local success, result = pcall(function()
            return require(core.GymAutomation)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Check GymAutomation health
local function checkGymAutomationHealth()
    local system = getGymAutomation()
    if not system then
        return false, "GymAutomation not found"
    end
    
    -- Check if initialized
    if not system.initialized then
        return false, "GymAutomation not initialized"
    end
    
    -- Check error count
    local errorCount = system.getErrorCount()
    if errorCount > 0 then
        return false, "GymAutomation has " .. errorCount .. " errors"
    end
    
    -- Check maintenance schedule
    local maintenanceSchedule = system.getMaintenanceSchedule()
    if not maintenanceSchedule then
        return false, "Maintenance schedule not found"
    end
    
    -- Check staff schedule
    local staffSchedule = system.getStaffSchedule()
    if not staffSchedule then
        return false, "Staff schedule not found"
    end
    
    return true, "Healthy"
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(GymAutomationMonitor.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #GymAutomationMonitor.errors > CONFIG.maxErrors do
        table.remove(GymAutomationMonitor.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #GymAutomationMonitor.errors, 1, -1 do
        if GymAutomationMonitor.errors[i].timestamp < cutoff then
            table.remove(GymAutomationMonitor.errors, i)
        end
    end
    
    log("Error recorded: " .. message)
end

-- Update status
local function updateStatus(status, message)
    GymAutomationMonitor.status = status
    GymAutomationMonitor.lastCheck = os.time()
    
    -- Create status folder if it doesn't exist
    local statusFolder = ReplicatedStorage:FindFirstChild("GymAutomationStatus")
    if not statusFolder then
        statusFolder = Instance.new("Folder")
        statusFolder.Name = "GymAutomationStatus"
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
    lastCheckValue.Value = GymAutomationMonitor.lastCheck
    
    log("Status updated: " .. status .. " - " .. message)
end

-- Monitor health
local function monitorHealth()
    while true do
        local success, message = checkGymAutomationHealth()
        
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
function GymAutomationMonitor.initialize()
    if GymAutomationMonitor.initialized then return true end
    
    log("Initializing GymAutomationMonitor...")
    
    -- Check for GymAutomation
    local system = getGymAutomation()
    if not system then
        log("GymAutomation not found, monitoring may be limited")
    end
    
    -- Start monitoring
    task.spawn(monitorHealth)
    
    GymAutomationMonitor.initialized = true
    log("GymAutomationMonitor initialized")
    return true
end

-- Get current status
function GymAutomationMonitor.getStatus()
    return GymAutomationMonitor.status
end

-- Get last check time
function GymAutomationMonitor.getLastCheck()
    return GymAutomationMonitor.lastCheck
end

-- Get error count
function GymAutomationMonitor.getErrorCount()
    return #GymAutomationMonitor.errors
end

-- Get recent errors
function GymAutomationMonitor.getRecentErrors()
    return GymAutomationMonitor.errors
end

-- Force a health check
function GymAutomationMonitor.forceCheck()
    local success, message = checkGymAutomationHealth()
    updateStatus(success and "healthy" or "error", message)
    return success
end

return GymAutomationMonitor 