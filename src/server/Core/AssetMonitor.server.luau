--[[
    AssetMonitor.server.luau
    
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
local AssetMonitor = {
    status = "unknown",
    lastCheck = 0,
    errors = {},
    initialized = false
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[AssetMonitor]", ...)
    end
end

-- Get AssetManager
local function getAssetManager()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local manager = coreRegistry:getSystem("AssetManager")
        if manager then
            return manager
        end
    end
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
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
    local manager = getAssetManager()
    if not manager then
        return false, "AssetManager not found"
    end
    
    -- Check if initialized
    if not manager.initialized then
        return false, "AssetManager not initialized"
    end
    
    -- Check error count
    local errorCount = manager.getErrorCount()
    if errorCount > 0 then
        return false, "AssetManager has " .. errorCount .. " errors"
    end
    
    -- Test asset loading
    local testAssetId = 1234567890 -- Example test asset
    local asset = manager.getAsset(testAssetId)
    if not asset then
        return false, "Failed to load test asset"
    end
    
    -- Clean up test asset
    if typeof(asset) == "Instance" then
        asset:Destroy()
    end
    
    return true, "Healthy"
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(AssetMonitor.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #AssetMonitor.errors > CONFIG.maxErrors do
        table.remove(AssetMonitor.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #AssetMonitor.errors, 1, -1 do
        if AssetMonitor.errors[i].timestamp < cutoff then
            table.remove(AssetMonitor.errors, i)
        end
    end
    
    log("Error recorded: " .. message)
end

-- Update status
local function updateStatus(status, message)
    AssetMonitor.status = status
    AssetMonitor.lastCheck = os.time()
    
    -- Create status folder if it doesn't exist
    local statusFolder = ReplicatedStorage:FindFirstChild("AssetStatus")
    if not statusFolder then
        statusFolder = Instance.new("Folder")
        statusFolder.Name = "AssetStatus"
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
    lastCheckValue.Value = AssetMonitor.lastCheck
    
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
function AssetMonitor.initialize()
    if AssetMonitor.initialized then return true end
    
    log("Initializing AssetMonitor...")
    
    -- Check for CoreRegistry
    local coreRegistry = _G.CoreRegistry
    if not coreRegistry then
        log("CoreRegistry not found, monitoring may be limited")
    end
    
    -- Start monitoring
    task.spawn(monitorHealth)
    
    AssetMonitor.initialized = true
    log("AssetMonitor initialized")
    return true
end

-- Get current status
function AssetMonitor.getStatus()
    return AssetMonitor.status
end

-- Get last check time
function AssetMonitor.getLastCheck()
    return AssetMonitor.lastCheck
end

-- Get error count
function AssetMonitor.getErrorCount()
    return #AssetMonitor.errors
end

-- Get recent errors
function AssetMonitor.getRecentErrors()
    return AssetMonitor.errors
end

-- Force a health check
function AssetMonitor.forceCheck()
    local success, message = checkAssetManagerHealth()
    updateStatus(success and "healthy" or "error", message)
    return success
end

return AssetMonitor 