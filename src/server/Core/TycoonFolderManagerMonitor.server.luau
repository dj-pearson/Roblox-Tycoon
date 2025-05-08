--[[
    TycoonFolderManagerMonitor.server.luau
    
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

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    debug = true,
    checkInterval = 30, -- seconds
    maxErrors = 50,
    errorRetentionTime = 3600 -- 1 hour
}

-- Module state
local TycoonFolderManagerMonitor = {
    status = "unknown",
    lastCheck = 0,
    errors = {},
    initialized = false
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[TycoonFolderManagerMonitor]", ...)
    end
end

-- Get TycoonFolderManager
local function getTycoonFolderManager()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local system = coreRegistry:getSystem("TycoonFolderManager")
        if system then
            return system
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
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
    local system = getTycoonFolderManager()
    if not system then
        return false, "TycoonFolderManager not found"
    end
    
    -- Check if initialized
    if not system.initialized then
        return false, "TycoonFolderManager not initialized"
    end
    
    -- Check error count
    local errorCount = system.getErrorCount()
    if errorCount > 0 then
        return false, "TycoonFolderManager has " .. errorCount .. " errors"
    end
    
    -- Check player folders
    local playerFolders = system.playerFolders
    if not playerFolders then
        return false, "Player folders not found"
    end
    
    -- Check each player's folder structure
    for userId, folder in pairs(playerFolders) do
        if not folder.Parent then
            return false, "Invalid folder structure for player " .. userId
        end
        
        -- Check required folders
        for _, folderName in ipairs(system.CONFIG.requiredFolders) do
            if not folder:FindFirstChild(folderName) then
                return false, "Missing required folder: " .. folderName .. " for player " .. userId
            end
        end
        
        -- Check required values
        for folderName, values in pairs(system.CONFIG.requiredValues) do
            local folder = folder:FindFirstChild(folderName)
            if folder then
                for _, valueName in ipairs(values) do
                    if not folder:FindFirstChild(valueName) then
                        return false, "Missing required value: " .. valueName .. " in " .. folderName .. " for player " .. userId
                    end
                end
            end
        end
    end
    
    return true, "Healthy"
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(TycoonFolderManagerMonitor.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #TycoonFolderManagerMonitor.errors > CONFIG.maxErrors do
        table.remove(TycoonFolderManagerMonitor.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #TycoonFolderManagerMonitor.errors, 1, -1 do
        if TycoonFolderManagerMonitor.errors[i].timestamp < cutoff then
            table.remove(TycoonFolderManagerMonitor.errors, i)
        end
    end
    
    log("Error recorded: " .. message)
end

-- Update status
local function updateStatus(status, message)
    TycoonFolderManagerMonitor.status = status
    TycoonFolderManagerMonitor.lastCheck = os.time()
    
    -- Create status folder if it doesn't exist
    local statusFolder = ReplicatedStorage:FindFirstChild("TycoonFolderManagerStatus")
    if not statusFolder then
        statusFolder = Instance.new("Folder")
        statusFolder.Name = "TycoonFolderManagerStatus"
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
    lastCheckValue.Value = TycoonFolderManagerMonitor.lastCheck
    
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
function TycoonFolderManagerMonitor.initialize()
    if TycoonFolderManagerMonitor.initialized then return true end
    
    log("Initializing TycoonFolderManagerMonitor...")
    
    -- Check for TycoonFolderManager
    local system = getTycoonFolderManager()
    if not system then
        log("TycoonFolderManager not found, monitoring may be limited")
    end
    
    -- Start monitoring
    task.spawn(monitorHealth)
    
    TycoonFolderManagerMonitor.initialized = true
    log("TycoonFolderManagerMonitor initialized")
    return true
end

-- Get current status
function TycoonFolderManagerMonitor.getStatus()
    return TycoonFolderManagerMonitor.status
end

-- Get last check time
function TycoonFolderManagerMonitor.getLastCheck()
    return TycoonFolderManagerMonitor.lastCheck
end

-- Get error count
function TycoonFolderManagerMonitor.getErrorCount()
    return #TycoonFolderManagerMonitor.errors
end

-- Get recent errors
function TycoonFolderManagerMonitor.getRecentErrors()
    return TycoonFolderManagerMonitor.errors
end

-- Force a health check
function TycoonFolderManagerMonitor.forceCheck()
    local success, message = checkTycoonFolderManagerHealth()
    updateStatus(success and "healthy" or "error", message)
    return success
end

return TycoonFolderManagerMonitor 