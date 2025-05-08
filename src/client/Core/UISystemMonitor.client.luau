--[[
    UISystemMonitor.client.luau
    
    Monitors the health and status of the UISystem.
    Provides real-time monitoring, error tracking, and status reporting.
    
    Features:
    - Health monitoring of UI components
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
    maxErrors = 10,
    errorRetentionTime = 3600, -- 1 hour
    statusFolderName = "UISystemStatus"
}

-- Module state
local UISystemMonitor = {
    status = "unknown",
    lastCheck = 0,
    errors = {},
    initialized = false
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[UISystemMonitor]", ...)
    end
end

-- Get UISystem
local function getUISystem()
    -- Try to get from global
    if _G.UISystem then
        return _G.UISystem
    end
    
    -- Try to require from various paths
    local paths = {
        LocalPlayer.PlayerScripts,
        LocalPlayer.PlayerScripts:FindFirstChild("src") and LocalPlayer.PlayerScripts.src:FindFirstChild("client"),
        LocalPlayer.PlayerScripts:FindFirstChild("src") and LocalPlayer.PlayerScripts.src:FindFirstChild("client") and LocalPlayer.PlayerScripts.src.client:FindFirstChild("Core")
    }
    
    for _, path in ipairs(paths) do
        if path then
            local module = path:FindFirstChild("UISystem") or path:FindFirstChild("UISystem.client.luau")
            if module then
                local success, result = pcall(function()
                    return require(module)
                end)
                
                if success then
                    return result
                end
            end
        end
    end
    
    return nil
end

-- Check UISystem health
local function checkUISystemHealth()
    local uiSystem = getUISystem()
    if not uiSystem then
        return false, "UISystem not found"
    end
    
    -- Check if initialized
    if not uiSystem.initialized then
        return false, "UISystem not initialized"
    end
    
    -- Check error count
    local errorCount = uiSystem.getErrorCount()
    if errorCount > 0 then
        return false, "UISystem has " .. errorCount .. " errors"
    end
    
    -- Check components
    local components = uiSystem.getAllComponents()
    for name, component in pairs(components) do
        if not component.initialized then
            return false, "Component not initialized: " .. name
        end
        
        if component._isPlaceholder then
            return false, "Using placeholder for: " .. name
        end
    end
    
    return true, "UISystem healthy"
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(UISystemMonitor.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #UISystemMonitor.errors > CONFIG.maxErrors do
        table.remove(UISystemMonitor.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    while #UISystemMonitor.errors > 0 and UISystemMonitor.errors[1].timestamp < cutoff do
        table.remove(UISystemMonitor.errors, 1)
    end
    
    log("Error recorded: " .. message)
end

-- Update status
local function updateStatus(status, message)
    UISystemMonitor.status = status
    UISystemMonitor.lastCheck = os.time()
    
    -- Update status in ReplicatedStorage
    local statusFolder = ReplicatedStorage:FindFirstChild(CONFIG.statusFolderName)
    if not statusFolder then
        statusFolder = Instance.new("Folder")
        statusFolder.Name = CONFIG.statusFolderName
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
    
    -- Update last checked value
    local lastCheckedValue = statusFolder:FindFirstChild("LastChecked")
    if not lastCheckedValue then
        lastCheckedValue = Instance.new("NumberValue")
        lastCheckedValue.Name = "LastChecked"
        lastCheckedValue.Parent = statusFolder
    end
    lastCheckedValue.Value = UISystemMonitor.lastCheck
    
    -- Update message value
    local messageValue = statusFolder:FindFirstChild("Message")
    if not messageValue then
        messageValue = Instance.new("StringValue")
        messageValue.Name = "Message"
        messageValue.Parent = statusFolder
    end
    messageValue.Value = message or ""
    
    log("Status updated: " .. status .. (message and (" - " .. message) or ""))
end

-- Monitor health
local function monitorHealth()
    while true do
        local success, message = checkUISystemHealth()
        
        if success then
            updateStatus("healthy", message)
        else
            recordError(message)
            updateStatus("unhealthy", message)
        end
        
        task.wait(CONFIG.checkInterval)
    end
end

-- Initialize monitor
function UISystemMonitor.initialize()
    if UISystemMonitor.initialized then return true end
    
    log("Initializing UISystemMonitor...")
    
    -- Get CoreRegistry
    local coreRegistry = _G.CoreRegistry
    if not coreRegistry then
        log("CoreRegistry not found, monitoring may be limited", true)
    end
    
    -- Start monitoring
    task.spawn(monitorHealth)
    
    UISystemMonitor.initialized = true
    log("UISystemMonitor initialized")
    return true
end

-- Get current status
function UISystemMonitor.getStatus()
    return UISystemMonitor.status
end

-- Get last check time
function UISystemMonitor.getLastCheck()
    return UISystemMonitor.lastCheck
end

-- Get error count
function UISystemMonitor.getErrorCount()
    return #UISystemMonitor.errors
end

-- Get recent errors
function UISystemMonitor.getRecentErrors()
    return UISystemMonitor.errors
end

-- Force a health check
function UISystemMonitor.forceCheck()
    local success, message = checkUISystemHealth()
    
    if success then
        updateStatus("healthy", message)
    else
        recordError(message)
        updateStatus("unhealthy", message)
    end
    
    return success
end

return UISystemMonitor 