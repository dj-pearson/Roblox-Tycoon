--[[
    AssetManagerMonitor.luau
    
    Monitor for the AssetManager that tracks its health and status.
    This monitor ensures the AssetManager is functioning correctly
    and provides real-time status updates.
    
    Features:
    - Health monitoring of AssetManager
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
local AssetManagerMonitor = {
    status = "unknown",
    lastCheck = 0,
    errors = {},
    initialized = false
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[AssetManagerMonitor]", ...)
    end
end

-- Get AssetManager
local function getAssetManager()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local system = coreRegistry:getSystem("AssetManager")
        if system then
            return system
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("AssetManager") then
        local success, result = pcall(function()
            return require(core.AssetManager)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Check AssetManager health
local function checkAssetManagerHealth()
    local system = getAssetManager()
    if not system then
        return false, "AssetManager not found"
    end
    
    -- Check if initialized
    if not system.initialized then
        return false, "AssetManager not initialized"
    end
    
    -- Check error count
    local errorCount = system.getErrorCount()
    if errorCount > 0 then
        return false, "AssetManager has " .. errorCount .. " errors"
    end
    
    -- Check asset cache
    local assetCache = system.assetCache
    if not assetCache then
        return false, "Asset cache not found"
    end
    
    -- Check asset timestamps
    local assetTimestamps = system.assetTimestamps
    if not assetTimestamps then
        return false, "Asset timestamps not found"
    end
    
    -- Check asset permissions
    local assetPermissions = system.assetPermissions
    if not assetPermissions then
        return false, "Asset permissions not found"
    end
    
    return true, "Healthy"
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(AssetManagerMonitor.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #AssetManagerMonitor.errors > CONFIG.maxErrors do
        table.remove(AssetManagerMonitor.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #AssetManagerMonitor.errors, 1, -1 do
        if AssetManagerMonitor.errors[i].timestamp < cutoff then
            table.remove(AssetManagerMonitor.errors, i)
        end
    end
    
    log("Error recorded: " .. message)
end

-- Update status
local function updateStatus(status, message)
    AssetManagerMonitor.status = status
    AssetManagerMonitor.lastCheck = os.time()
    
    -- Create status folder if it doesn't exist
    local statusFolder = ReplicatedStorage:FindFirstChild("AssetManagerStatus")
    if not statusFolder then
        statusFolder = Instance.new("Folder")
        statusFolder.Name = "AssetManagerStatus"
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
    lastCheckValue.Value = AssetManagerMonitor.lastCheck
    
    log("Status updated: " .. status .. " - " .. message)
end

-- Monitor health
local function monitorHealth()
    while true do
        local success, message = checkAssetManagerHealth()
        
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
function AssetManagerMonitor.initialize()
    if AssetManagerMonitor.initialized then return true end
    
    log("Initializing AssetManagerMonitor...")
    
    -- Check for AssetManager
    local system = getAssetManager()
    if not system then
        log("AssetManager not found, monitoring may be limited")
    end
    
    -- Start monitoring
    task.spawn(monitorHealth)
    
    AssetManagerMonitor.initialized = true
    log("AssetManagerMonitor initialized")
    return true
end

-- Get current status
function AssetManagerMonitor.getStatus()
    return AssetManagerMonitor.status
end

-- Get last check time
function AssetManagerMonitor.getLastCheck()
    return AssetManagerMonitor.lastCheck
end

-- Get error count
function AssetManagerMonitor.getErrorCount()
    return #AssetManagerMonitor.errors
end

-- Get recent errors
function AssetManagerMonitor.getRecentErrors()
    return AssetManagerMonitor.errors
end

-- Force a health check
function AssetManagerMonitor.forceCheck()
    local success, message = checkAssetManagerHealth()
    updateStatus(success and "healthy" or "error", message)
    return success
end

return AssetManagerMonitor 