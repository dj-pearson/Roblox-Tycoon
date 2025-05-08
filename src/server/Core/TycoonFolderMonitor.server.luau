--[[
    TycoonFolderMonitor.server.luau
    
    Monitor for the TycoonFolderManager that tracks its health and status.
    This monitor ensures the TycoonFolderManager is functioning correctly
    and provides real-time status updates.
    
    Features:
    - Health monitoring of TycoonFolderManager
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
local TycoonFolderMonitor = {
    status = "unknown",
    lastCheck = 0,
    errors = {},
    initialized = false
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[TycoonFolderMonitor]", ...)
    end
end

-- Get TycoonFolderManager
local function getTycoonFolderManager()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local manager = coreRegistry:getSystem("TycoonFolderManager")
        if manager then
            return manager
        end
    end
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if core and core:FindFirstChild("TycoonFolderManager") then
        local success, result = pcall(function()
            return require(core.TycoonFolderManager)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Check TycoonFolderManager health
local function checkTycoonFolderManagerHealth()
    local manager = getTycoonFolderManager()
    if not manager then
        return false, "TycoonFolderManager not found"
    end
    
    -- Check if initialized
    if not manager.initialized then
        return false, "TycoonFolderManager not initialized"
    end
    
    -- Check error count
    local errorCount = manager.getErrorCount()
    if errorCount > 0 then
        return false, "TycoonFolderManager has " .. errorCount .. " errors"
    end
    
    -- Test folder creation
    local testPlayer = {
        Name = "TestPlayer"
    }
    local testFolder = manager.createTycoonFolder(testPlayer)
    if not testFolder then
        return false, "Failed to create test folder"
    end
    
    -- Validate test folder
    local valid, message = manager.validateTycoonFolder(testPlayer)
    if not valid then
        return false, "Test folder validation failed: " .. message
    end
    
    -- Clean up test folder
    manager.removeTycoonFolder(testPlayer)
    
    return true, "Healthy"
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(TycoonFolderMonitor.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #TycoonFolderMonitor.errors > CONFIG.maxErrors do
        table.remove(TycoonFolderMonitor.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #TycoonFolderMonitor.errors, 1, -1 do
        if TycoonFolderMonitor.errors[i].timestamp < cutoff then
            table.remove(TycoonFolderMonitor.errors, i)
        end
    end
    
    log("Error recorded: " .. message)
end

-- Update status
local function updateStatus(status, message)
    TycoonFolderMonitor.status = status
    TycoonFolderMonitor.lastCheck = os.time()
    
    -- Create status folder if it doesn't exist
    local statusFolder = ReplicatedStorage:FindFirstChild("TycoonFolderStatus")
    if not statusFolder then
        statusFolder = Instance.new("Folder")
        statusFolder.Name = "TycoonFolderStatus"
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
    lastCheckValue.Value = TycoonFolderMonitor.lastCheck
    
    log("Status updated: " .. status .. " - " .. message)
end

-- Monitor health
local function monitorHealth()
    while true do
        local success, message = checkTycoonFolderManagerHealth()
        
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
function TycoonFolderMonitor.initialize()
    if TycoonFolderMonitor.initialized then return true end
    
    log("Initializing TycoonFolderMonitor...")
    
    -- Check for CoreRegistry
    local coreRegistry = _G.CoreRegistry
    if not coreRegistry then
        log("CoreRegistry not found, monitoring may be limited")
    end
    
    -- Start monitoring
    task.spawn(monitorHealth)
    
    TycoonFolderMonitor.initialized = true
    log("TycoonFolderMonitor initialized")
    return true
end

-- Get current status
function TycoonFolderMonitor.getStatus()
    return TycoonFolderMonitor.status
end

-- Get last check time
function TycoonFolderMonitor.getLastCheck()
    return TycoonFolderMonitor.lastCheck
end

-- Get error count
function TycoonFolderMonitor.getErrorCount()
    return #TycoonFolderMonitor.errors
end

-- Get recent errors
function TycoonFolderMonitor.getRecentErrors()
    return TycoonFolderMonitor.errors
end

-- Force a health check
function TycoonFolderMonitor.forceCheck()
    local success, message = checkTycoonFolderManagerHealth()
    updateStatus(success and "healthy" or "error", message)
    return success
end

return TycoonFolderMonitor 