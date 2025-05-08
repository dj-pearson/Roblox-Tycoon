--[[
    MenuButtonSystemMonitor.client.luau
    
    Monitor for the MenuButtonSystem that tracks its health and status.
    This monitor ensures the MenuButtonSystem is functioning correctly
    and provides real-time status updates.
    
    Features:
    - Health monitoring of MenuButtonSystem
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
local MenuButtonSystemMonitor = {
    status = "unknown",
    lastCheck = 0,
    errors = {},
    initialized = false
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[MenuButtonSystemMonitor]", ...)
    end
end

-- Get MenuButtonSystem
local function getMenuButtonSystem()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local system = coreRegistry:getSystem("MenuButtonSystem")
        if system then
            return system
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("MenuButtonSystem") then
        local success, result = pcall(function()
            return require(core.MenuButtonSystem)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Check MenuButtonSystem health
local function checkMenuButtonSystemHealth()
    local system = getMenuButtonSystem()
    if not system then
        return false, "MenuButtonSystem not found"
    end
    
    -- Check if initialized
    if not system.initialized then
        return false, "MenuButtonSystem not initialized"
    end
    
    -- Check error count
    local errorCount = system.getErrorCount()
    if errorCount > 0 then
        return false, "MenuButtonSystem has " .. errorCount .. " errors"
    end
    
    -- Check button states
    local buttons = system.buttons
    if not buttons then
        return false, "Button list not found"
    end
    
    -- Check button callbacks
    local callbacks = system.buttonCallbacks
    if not callbacks then
        return false, "Button callbacks not found"
    end
    
    return true, "Healthy"
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(MenuButtonSystemMonitor.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #MenuButtonSystemMonitor.errors > CONFIG.maxErrors do
        table.remove(MenuButtonSystemMonitor.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #MenuButtonSystemMonitor.errors, 1, -1 do
        if MenuButtonSystemMonitor.errors[i].timestamp < cutoff then
            table.remove(MenuButtonSystemMonitor.errors, i)
        end
    end
    
    log("Error recorded: " .. message)
end

-- Update status
local function updateStatus(status, message)
    MenuButtonSystemMonitor.status = status
    MenuButtonSystemMonitor.lastCheck = os.time()
    
    -- Create status folder if it doesn't exist
    local statusFolder = ReplicatedStorage:FindFirstChild("MenuButtonSystemStatus")
    if not statusFolder then
        statusFolder = Instance.new("Folder")
        statusFolder.Name = "MenuButtonSystemStatus"
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
    lastCheckValue.Value = MenuButtonSystemMonitor.lastCheck
    
    log("Status updated: " .. status .. " - " .. message)
end

-- Monitor health
local function monitorHealth()
    while true do
        local success, message = checkMenuButtonSystemHealth()
        
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
function MenuButtonSystemMonitor.initialize()
    if MenuButtonSystemMonitor.initialized then return true end
    
    log("Initializing MenuButtonSystemMonitor...")
    
    -- Check for MenuButtonSystem
    local system = getMenuButtonSystem()
    if not system then
        log("MenuButtonSystem not found, monitoring may be limited")
    end
    
    -- Start monitoring
    task.spawn(monitorHealth)
    
    MenuButtonSystemMonitor.initialized = true
    log("MenuButtonSystemMonitor initialized")
    return true
end

-- Get current status
function MenuButtonSystemMonitor.getStatus()
    return MenuButtonSystemMonitor.status
end

-- Get last check time
function MenuButtonSystemMonitor.getLastCheck()
    return MenuButtonSystemMonitor.lastCheck
end

-- Get error count
function MenuButtonSystemMonitor.getErrorCount()
    return #MenuButtonSystemMonitor.errors
end

-- Get recent errors
function MenuButtonSystemMonitor.getRecentErrors()
    return MenuButtonSystemMonitor.errors
end

-- Force a health check
function MenuButtonSystemMonitor.forceCheck()
    local success, message = checkMenuButtonSystemHealth()
    updateStatus(success and "healthy" or "error", message)
    return success
end

return MenuButtonSystemMonitor 