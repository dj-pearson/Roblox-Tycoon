--[[
    CoreRegistryMonitor.server.luau
    
    Monitor for the CoreRegistry that tracks its health and status.
    This monitor ensures the CoreRegistry is functioning correctly
    and provides real-time status updates.
    
    Features:
    - Health monitoring of CoreRegistry
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
local CoreRegistryMonitor = {
    status = "unknown",
    lastCheck = 0,
    errors = {},
    initialized = false
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[CoreRegistryMonitor]", ...)
    end
end

-- Get CoreRegistry
local function getCoreRegistry()
    -- Try to get from global first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        return coreRegistry
    end
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if core and core:FindFirstChild("CoreRegistry") then
        local success, result = pcall(function()
            return require(core.CoreRegistry)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Check CoreRegistry health
local function checkCoreRegistryHealth()
    local registry = getCoreRegistry()
    if not registry then
        return false, "CoreRegistry not found"
    end
    
    -- Check if initialized
    if not registry.initialized then
        return false, "CoreRegistry not initialized"
    end
    
    -- Check error count
    local errorCount = registry.getErrorCount()
    if errorCount > 0 then
        return false, "CoreRegistry has " .. errorCount .. " errors"
    end
    
    -- Check system initialization status
    local initStatus = registry.getInitStatus()
    local uninitialized = {}
    for systemName, status in pairs(initStatus) do
        if not status then
            table.insert(uninitialized, systemName)
        end
    end
    
    if #uninitialized > 0 then
        return false, "Systems not initialized: " .. table.concat(uninitialized, ", ")
    end
    
    return true, "Healthy"
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(CoreRegistryMonitor.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #CoreRegistryMonitor.errors > CONFIG.maxErrors do
        table.remove(CoreRegistryMonitor.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #CoreRegistryMonitor.errors, 1, -1 do
        if CoreRegistryMonitor.errors[i].timestamp < cutoff then
            table.remove(CoreRegistryMonitor.errors, i)
        end
    end
    
    log("Error recorded: " .. message)
end

-- Update status
local function updateStatus(status, message)
    CoreRegistryMonitor.status = status
    CoreRegistryMonitor.lastCheck = os.time()
    
    -- Create status folder if it doesn't exist
    local statusFolder = ReplicatedStorage:FindFirstChild("CoreRegistryStatus")
    if not statusFolder then
        statusFolder = Instance.new("Folder")
        statusFolder.Name = "CoreRegistryStatus"
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
    lastCheckValue.Value = CoreRegistryMonitor.lastCheck
    
    log("Status updated: " .. status .. " - " .. message)
end

-- Monitor health
local function monitorHealth()
    while true do
        local success, message = checkCoreRegistryHealth()
        
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
function CoreRegistryMonitor.initialize()
    if CoreRegistryMonitor.initialized then return true end
    
    log("Initializing CoreRegistryMonitor...")
    
    -- Check for CoreRegistry
    local registry = getCoreRegistry()
    if not registry then
        log("CoreRegistry not found, monitoring may be limited")
    end
    
    -- Start monitoring
    task.spawn(monitorHealth)
    
    CoreRegistryMonitor.initialized = true
    log("CoreRegistryMonitor initialized")
    return true
end

-- Get current status
function CoreRegistryMonitor.getStatus()
    return CoreRegistryMonitor.status
end

-- Get last check time
function CoreRegistryMonitor.getLastCheck()
    return CoreRegistryMonitor.lastCheck
end

-- Get error count
function CoreRegistryMonitor.getErrorCount()
    return #CoreRegistryMonitor.errors
end

-- Get recent errors
function CoreRegistryMonitor.getRecentErrors()
    return CoreRegistryMonitor.errors
end

-- Force a health check
function CoreRegistryMonitor.forceCheck()
    local success, message = checkCoreRegistryHealth()
    updateStatus(success and "healthy" or "error", message)
    return success
end

return CoreRegistryMonitor
