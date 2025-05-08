--[[
    ModuleResolverMonitor.server.luau
    
    Monitor for the ModuleResolver system that tracks its health and status.
    This monitor ensures the ModuleResolver system is functioning correctly
    and provides real-time status updates.
    
    Features:
    - Health monitoring of ModuleResolver
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
local ModuleResolverMonitor = {
    status = "unknown",
    lastCheck = 0,
    errors = {},
    initialized = false
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[ModuleResolverMonitor]", ...)
    end
end

-- Get ModuleResolver
local function getModuleResolver()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local system = coreRegistry:getSystem("ModuleResolver")
        if system then
            return system
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
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

-- Check ModuleResolver health
local function checkModuleResolverHealth()
    local system = getModuleResolver()
    if not system then
        return false, "ModuleResolver not found"
    end
    
    -- Check if initialized
    if not system.initialized then
        return false, "ModuleResolver not initialized"
    end
    
    -- Check error count
    local errorCount = system.getErrorCount()
    if errorCount > 0 then
        return false, "ModuleResolver has " .. errorCount .. " errors"
    end
    
    -- Check module cache
    local moduleCache = system.moduleCache
    if not moduleCache then
        return false, "Module cache not found"
    end
    
    -- Check module timestamps
    local moduleTimestamps = system.moduleTimestamps
    if not moduleTimestamps then
        return false, "Module timestamps not found"
    end
    
    return true, "Healthy"
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(ModuleResolverMonitor.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #ModuleResolverMonitor.errors > CONFIG.maxErrors do
        table.remove(ModuleResolverMonitor.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #ModuleResolverMonitor.errors, 1, -1 do
        if ModuleResolverMonitor.errors[i].timestamp < cutoff then
            table.remove(ModuleResolverMonitor.errors, i)
        end
    end
    
    log("Error recorded: " .. message)
end

-- Update status
local function updateStatus(status, message)
    ModuleResolverMonitor.status = status
    ModuleResolverMonitor.lastCheck = os.time()
    
    -- Create status folder if it doesn't exist
    local statusFolder = ReplicatedStorage:FindFirstChild("ModuleResolverStatus")
    if not statusFolder then
        statusFolder = Instance.new("Folder")
        statusFolder.Name = "ModuleResolverStatus"
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
    lastCheckValue.Value = ModuleResolverMonitor.lastCheck
    
    log("Status updated: " .. status .. " - " .. message)
end

-- Monitor health
local function monitorHealth()
    while true do
        local success, message = checkModuleResolverHealth()
        
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
function ModuleResolverMonitor.initialize()
    if ModuleResolverMonitor.initialized then return true end
    
    log("Initializing ModuleResolverMonitor...")
    
    -- Check for ModuleResolver
    local system = getModuleResolver()
    if not system then
        log("ModuleResolver not found, monitoring may be limited")
    end
    
    -- Start monitoring
    task.spawn(monitorHealth)
    
    ModuleResolverMonitor.initialized = true
    log("ModuleResolverMonitor initialized")
    return true
end

-- Get current status
function ModuleResolverMonitor.getStatus()
    return ModuleResolverMonitor.status
end

-- Get last check time
function ModuleResolverMonitor.getLastCheck()
    return ModuleResolverMonitor.lastCheck
end

-- Get error count
function ModuleResolverMonitor.getErrorCount()
    return #ModuleResolverMonitor.errors
end

-- Get recent errors
function ModuleResolverMonitor.getRecentErrors()
    return ModuleResolverMonitor.errors
end

-- Force a health check
function ModuleResolverMonitor.forceCheck()
    local success, message = checkModuleResolverHealth()
    updateStatus(success and "healthy" or "error", message)
    return success
end

return ModuleResolverMonitor 