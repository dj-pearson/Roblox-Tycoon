--[[
    MenuButtonMonitor.client.luau
    
    Monitor for the MenuButtonManager that tracks its health and status.
    This monitor ensures the MenuButtonManager is functioning correctly
    and provides real-time status updates.
    
    Features:
    - Health monitoring of MenuButtonManager
    - Error tracking and reporting
    - Integration with CoreRegistry
    - Status updates in ReplicatedStorage
    
    Created: May 3, 2025
]]

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
local MenuButtonMonitor = {
    status = "unknown",
    lastCheck = 0,
    errors = {},
    initialized = false
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[MenuButtonMonitor]", ...)
    end
end

-- Get MenuButtonManager
local function getMenuButtonManager()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local manager = coreRegistry:getSystem("MenuButtonManager")
        if manager then
            return manager
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("MenuButtonManager") then
        local success, result = pcall(function()
            return require(core.MenuButtonManager)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Check MenuButtonManager health
local function checkMenuButtonManagerHealth()
    local manager = getMenuButtonManager()
    if not manager then
        return false, "MenuButtonManager not found"
    end
    
    -- Check if initialized
    if not manager.initialized then
        return false, "MenuButtonManager not initialized"
    end
    
    -- Check error count
    local errorCount = manager.getErrorCount()
    if errorCount > 0 then
        return false, "MenuButtonManager has " .. errorCount .. " errors"
    end
    
    -- Test button creation
    local testButton = manager.createMenuButton("TestButton", {
        createPlaceholder = true
    })
    if not testButton then
        return false, "Failed to create test button"
    end
    
    -- Clean up test button
    manager.removeButton("TestButton")
    
    return true, "Healthy"
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(MenuButtonMonitor.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #MenuButtonMonitor.errors > CONFIG.maxErrors do
        table.remove(MenuButtonMonitor.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #MenuButtonMonitor.errors, 1, -1 do
        if MenuButtonMonitor.errors[i].timestamp < cutoff then
            table.remove(MenuButtonMonitor.errors, i)
        end
    end
    
    log("Error recorded: " .. message)
end

-- Update status
local function updateStatus(status, message)
    MenuButtonMonitor.status = status
    MenuButtonMonitor.lastCheck = os.time()
    
    -- Create status folder if it doesn't exist
    local statusFolder = ReplicatedStorage:FindFirstChild("MenuButtonStatus")
    if not statusFolder then
        statusFolder = Instance.new("Folder")
        statusFolder.Name = "MenuButtonStatus"
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
    lastCheckValue.Value = MenuButtonMonitor.lastCheck
    
    log("Status updated: " .. status .. " - " .. message)
end

-- Monitor health
local function monitorHealth()
    while true do
        local success, message = checkMenuButtonManagerHealth()
        
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
function MenuButtonMonitor.initialize()
    if MenuButtonMonitor.initialized then return true end
    
    log("Initializing MenuButtonMonitor...")
    
    -- Check for CoreRegistry
    local coreRegistry = _G.CoreRegistry
    if not coreRegistry then
        log("CoreRegistry not found, monitoring may be limited")
    end
    
    -- Start monitoring
    task.spawn(monitorHealth)
    
    MenuButtonMonitor.initialized = true
    log("MenuButtonMonitor initialized")
    return true
end

-- Get current status
function MenuButtonMonitor.getStatus()
    return MenuButtonMonitor.status
end

-- Get last check time
function MenuButtonMonitor.getLastCheck()
    return MenuButtonMonitor.lastCheck
end

-- Get error count
function MenuButtonMonitor.getErrorCount()
    return #MenuButtonMonitor.errors
end

-- Get recent errors
function MenuButtonMonitor.getRecentErrors()
    return MenuButtonMonitor.errors
end

-- Force a health check
function MenuButtonMonitor.forceCheck()
    local success, message = checkMenuButtonManagerHealth()
    updateStatus(success and "healthy" or "error", message)
    return success
end

return MenuButtonMonitor 