--[[
    CoreRegistryMonitor.server.luau
    
    A monitoring system for CoreRegistry that provides real-time feedback
    about the health and status of the registry and its components.
    
    Created to address CoreRegistry System Failure identified in RobloxIssues.txt
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    debug = true,                -- Enable debug prints
    checkInterval = 10,          -- How often to check registry health
    maxAttempts = 3,             -- Maximum attempts to check registry
    initialDelay = 2,            -- Initial delay before first check
    checkDelay = 5,              -- Delay between checks
    criticalSystems = {          -- Systems considered critical
        "CoreRegistry",
        "DataManager",
        "TycoonSystem"
    }
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[CoreRegistryMonitor]", ...)
    end
end

-- Attempt to get CoreRegistry
local function getCoreRegistry()
    -- Try direct access first
    if _G.CoreRegistry then
        return _G.CoreRegistry
    end
    
    -- Try to require CoreRegistry
    local coreRegistryModule
    
    -- Search in multiple locations
    local searchPaths = {
        ServerScriptService.Core,
        ServerScriptService,
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild("CoreRegistry")
            if module and module:IsA("ModuleScript") then
                coreRegistryModule = module
                break
            end
        end
    end
    
    if coreRegistryModule then
        local success, registry = pcall(function()
            return require(coreRegistryModule)
        end)
        
        if success and registry then
            return registry
        end
    end
    
    -- Try SharedRegistry if available
    local sharedRegistry = ReplicatedStorage:FindFirstChild("SharedRegistry")
    if sharedRegistry and sharedRegistry:FindFirstChild("GetSystem") then
        local success, registry = pcall(function()
            return sharedRegistry.GetSystem:Invoke("CoreRegistry")
        end)
        
        if success and registry then
            return registry
        end
    end
    
    return nil
end

-- Check registry health
local function checkRegistryHealth()
    local registry = getCoreRegistry()
    if not registry then
        log("CoreRegistry UNAVAILABLE")
        return "UNAVAILABLE"
    end
    
    -- Check if registry functions are available
    if type(registry.getStatus) ~= "function" then
        log("CoreRegistry missing getStatus function")
        return "DEGRADED"
    end
    
    -- Get registry status
    local status = registry.getStatus()
    
    -- Check critical systems
    local missingCritical = false
    for _, system in ipairs(CONFIG.criticalSystems) do
        if not registry.hasSystem or not registry.hasSystem(system) then
            missingCritical = true
            log("Critical system missing:", system)
        end
    end
    
    if missingCritical then
        return "DEGRADED"
    end
    
    return status or "UNKNOWN"
end

-- Create status folder
local statusFolder = Instance.new("Folder")
statusFolder.Name = "CoreRegistryStatus"
statusFolder.Parent = ReplicatedStorage

-- Create status value object
local statusValue = Instance.new("StringValue")
statusValue.Name = "Status"
statusValue.Value = "Initializing"
statusValue.Parent = statusFolder

-- Create timestamp
local timestampValue = Instance.new("NumberValue")
timestampValue.Name = "LastChecked"
timestampValue.Value = os.time()
timestampValue.Parent = statusFolder

-- Update status with timestamp
local function updateStatus(status)
    statusValue.Value = status
    timestampValue.Value = os.time()
end

-- Monitor health
local function monitorHealth()
    local attempts = 0
    
    while attempts < CONFIG.maxAttempts do
        local status = checkRegistryHealth()
        updateStatus(status)
        
        if status == "Ready" then
            log("CoreRegistry is healthy")
            break
        end
        
        attempts += 1
        if attempts < CONFIG.maxAttempts then
            log("Waiting before next check...")
            task.wait(CONFIG.checkDelay)
        end
    end
    
    if attempts >= CONFIG.maxAttempts then
        log("Failed to get healthy CoreRegistry after", CONFIG.maxAttempts, "attempts")
    end
end

-- Initialize
local function initialize()
    log("Initializing CoreRegistryMonitor...")
    
    -- Wait initial delay
    task.wait(CONFIG.initialDelay)
    
    -- Start monitoring
    monitorHealth()
    
    -- Set up periodic checks
    RunService.Heartbeat:Connect(function()
        if os.time() - timestampValue.Value >= CONFIG.checkInterval then
            monitorHealth()
        end
    end)
    
    log("CoreRegistryMonitor initialized")
end

-- Start monitoring
initialize()

return {
    getStatus = function() return statusValue.Value end,
    getLastChecked = function() return timestampValue.Value end,
    forceCheck = monitorHealth
}
