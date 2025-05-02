--[[
    CoreRegistry.server.luau
    
    A foundation module for the Roblox game that provides centralized registration
    and retrieval of game systems. This version includes robust error handling,
    health monitoring, and diagnostics.
    
    Created to fix CoreRegistry System Failure identified in RobloxIssues.txt
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    debug = true, -- Enable debug logging
    healthCheckInterval = 30, -- How often to run health checks in seconds
    registerShared = true, -- Whether to register this module in shared registry
    forwardEvents = true -- Whether to forward events to other registry systems
}

-- Registry table that holds all registered systems
local registry = {
    systems = {}, -- Registered systems
    dependencies = {}, -- Dependencies between systems
    initialized = {}, -- Tracks which systems have been initialized
    failedSystems = {}, -- Systems that failed to initialize
    registryStatus = "Available" -- Overall registry status
}

-- Logger function
local function log(...)
    if CONFIG.debug then
        print("[CoreRegistry]", ...)
    end
end

-- Error handler
local function handleError(errorMessage, system, context)
    warn("[CoreRegistry] Error:", errorMessage, "| System:", system or "unknown", "| Context:", context or "unknown")
    
    -- Track failed system
    if system then
        registry.failedSystems[system] = {
            message = errorMessage,
            context = context,
            time = os.time()
        }
    end
    
    return false
end

-- The public API
local CoreRegistry = {}
CoreRegistry.VERSION = "2.0.0"
CoreRegistry.isLoaded = true -- Flag to indicate the module is loaded

-- Register a system with the registry
function CoreRegistry.registerSystem(systemName, systemTable)
    if type(systemName) ~= "string" then
        return handleError("System name must be a string", systemName, "registerSystem")
    end
    
    if type(systemTable) ~= "table" then
        return handleError("System table must be a table", systemName, "registerSystem")
    end
    
    -- Check if system already exists
    if registry.systems[systemName] then
        log("System", systemName, "is being re-registered")
    end
    
    -- Register the system
    registry.systems[systemName] = systemTable
    log("Registered system:", systemName)
    
    -- Forward to shared registry if configured
    if CONFIG.registerShared and CONFIG.forwardEvents then
        pcall(function()
            local sharedRegistry = ReplicatedStorage:FindFirstChild("SharedRegistry")
            if sharedRegistry and sharedRegistry:FindFirstChild("RegisterSystem") then
                sharedRegistry.RegisterSystem:Fire(systemName, systemTable)
            end
        end)
    end
    
    return true
end

-- Get a system from the registry
function CoreRegistry.getSystem(systemName)
    if type(systemName) ~= "string" then
        handleError("System name must be a string", systemName, "getSystem")
        return nil
    end
    
    local system = registry.systems[systemName]
    if not system then
        log("System not found:", systemName)
        return nil
    end
    
    return system
end

-- Check if a system exists in the registry
function CoreRegistry.hasSystem(systemName)
    if type(systemName) ~= "string" then
        return false
    end
    
    return registry.systems[systemName] ~= nil
end

-- Initialize a system with dependencies
function CoreRegistry.initSystem(systemName, dependencies, initFunc)
    if type(systemName) ~= "string" then
        return handleError("System name must be a string", systemName, "initSystem")
    end
    
    -- Skip if already initialized
    if registry.initialized[systemName] then
        log("System", systemName, "already initialized")
        return true
    end
    
    -- Register dependencies
    if dependencies and type(dependencies) == "table" then
        registry.dependencies[systemName] = dependencies
        
        -- Check if dependencies are available
        for _, depName in ipairs(dependencies) do
            if not CoreRegistry.hasSystem(depName) then
                return handleError("Required dependency not found: " .. depName, systemName, "initSystem")
            end
        end
    end
    
    -- Initialize the system
    if initFunc and type(initFunc) == "function" then
        log("Initializing system:", systemName)
        
        local success, result = pcall(initFunc)
        if not success then
            return handleError("Failed to initialize: " .. result, systemName, "initSystem")
        end
        
        -- Mark as initialized
        registry.initialized[systemName] = true
        log("System initialized:", systemName)
        return true
    end
    
    -- No init function provided, just mark as initialized
    registry.initialized[systemName] = true
    return true
end

-- Get the registry status
function CoreRegistry.getStatus()
    return registry.registryStatus
end

-- Set the registry status
function CoreRegistry.setStatus(status)
    registry.registryStatus = status
    log("Registry status set to:", status)
    return true
end

-- Get all registered system names
function CoreRegistry.getRegisteredSystems()
    local systems = {}
    for systemName, _ in pairs(registry.systems) do
        table.insert(systems, systemName)
    end
    return systems
end

-- Get initialization status of all systems
function CoreRegistry.getInitStatus()
    local status = {
        initialized = {},
        pending = {},
        failed = {}
    }
    
    for systemName, _ in pairs(registry.systems) do
        if registry.initialized[systemName] then
            table.insert(status.initialized, systemName)
        elseif registry.failedSystems[systemName] then
            table.insert(status.failed, systemName)
        else
            table.insert(status.pending, systemName)
        end
    end
    
    return status
end

-- Run health check
function CoreRegistry.runHealthCheck()
    log("Running health check...")
    
    -- Check if critical systems are registered
    local criticalSystems = {
        "DataManager",
        "TycoonSystem",
        "EventBridge"
    }
    
    local missingCritical = false
    for _, systemName in ipairs(criticalSystems) do
        if not CoreRegistry.hasSystem(systemName) then
            log("Critical system missing:", systemName)
            missingCritical = true
        end
    end
    
    -- Update status based on health check
    if missingCritical then
        CoreRegistry.setStatus("Degraded")
    else
        CoreRegistry.setStatus("Available")
    end
    
    return not missingCritical
end

-- Create remote events/functions for cross-boundary access
function CoreRegistry.createRemoteAccess()
    local remoteFolder = ReplicatedStorage:FindFirstChild("CoreRegistryRemotes")
    if not remoteFolder then
        remoteFolder = Instance.new("Folder")
        remoteFolder.Name = "CoreRegistryRemotes"
        remoteFolder.Parent = ReplicatedStorage
    end
    
    -- Create GetSystem RemoteFunction
    if not remoteFolder:FindFirstChild("GetSystem") then
        local getSystemRemote = Instance.new("RemoteFunction")
        getSystemRemote.Name = "GetSystem"
        getSystemRemote.Parent = remoteFolder
    end
    
    -- Create HasSystem RemoteFunction
    if not remoteFolder:FindFirstChild("HasSystem") then
        local hasSystemRemote = Instance.new("RemoteFunction")
        hasSystemRemote.Name = "HasSystem"
        hasSystemRemote.Parent = remoteFolder
    end
    
    -- Create GetStatus RemoteFunction
    if not remoteFolder:FindFirstChild("GetStatus") then
        local getStatusRemote = Instance.new("RemoteFunction")
        getStatusRemote.Name = "GetStatus"
        getStatusRemote.Parent = remoteFolder
    end
    
    -- Connect functions to remotes
    remoteFolder.GetSystem.OnServerInvoke = function(player, systemName)
        local system = CoreRegistry.getSystem(systemName)
        -- Only return public API if defined, otherwise nil
        return system and system.publicAPI
    end
    
    remoteFolder.HasSystem.OnServerInvoke = function(_, systemName)
        return CoreRegistry.hasSystem(systemName)
    end
    
    remoteFolder.GetStatus.OnServerInvoke = function(_)
        return CoreRegistry.getStatus()
    end
    
    log("Remote access created")
    return true
end

-- Create events for health monitoring
function CoreRegistry.createHealthMonitoring()
    local monitorFolder = ServerScriptService:FindFirstChild("CoreRegistryMonitoring")
    if not monitorFolder then
        monitorFolder = Instance.new("Folder")
        monitorFolder.Name = "CoreRegistryMonitoring"
        monitorFolder.Parent = ServerScriptService
    end
    
    -- Create StatusChanged BindableEvent
    if not monitorFolder:FindFirstChild("StatusChanged") then
        local statusChangedEvent = Instance.new("BindableEvent")
        statusChangedEvent.Name = "StatusChanged"
        statusChangedEvent.Parent = monitorFolder
    end
    
    -- Create RunHealthCheck BindableFunction
    if not monitorFolder:FindFirstChild("RunHealthCheck") then
        local runHealthCheckFunc = Instance.new("BindableFunction")
        runHealthCheckFunc.Name = "RunHealthCheck"
        runHealthCheckFunc.Parent = monitorFolder
    end
    
    -- Connect functions
    monitorFolder.RunHealthCheck.OnInvoke = function()
        return CoreRegistry.runHealthCheck()
    end
    
    -- Store old setStatus function
    local oldSetStatus = CoreRegistry.setStatus
    
    -- Override setStatus to fire event
    CoreRegistry.setStatus = function(status)
        local oldStatus = registry.registryStatus
        oldSetStatus(status)
        
        if oldStatus ~= status then
            monitorFolder.StatusChanged:Fire(status, oldStatus)
        end
        
        return true
    end
    
    log("Health monitoring created")
    return true
end

-- Create shared registry for cross-boundary access
function CoreRegistry.createSharedRegistry()
    if not CONFIG.registerShared then
        return true
    end
    
    local sharedRegistry = ReplicatedStorage:FindFirstChild("SharedRegistry")
    if not sharedRegistry then
        sharedRegistry = Instance.new("Folder")
        sharedRegistry.Name = "SharedRegistry"
        sharedRegistry.Parent = ReplicatedStorage
    end
    
    -- Create RegisterSystem BindableEvent
    if not sharedRegistry:FindFirstChild("RegisterSystem") then
        local registerSystemEvent = Instance.new("BindableEvent")
        registerSystemEvent.Name = "RegisterSystem"
        registerSystemEvent.Parent = sharedRegistry
    end
    
    -- Create GetSystem BindableFunction
    if not sharedRegistry:FindFirstChild("GetSystem") then
        local getSystemFunc = Instance.new("BindableFunction")
        getSystemFunc.Name = "GetSystem"
        getSystemFunc.Parent = sharedRegistry
    end
    
    -- Create HasSystem BindableFunction
    if not sharedRegistry:FindFirstChild("HasSystem") then
        local hasSystemFunc = Instance.new("BindableFunction")
        hasSystemFunc.Name = "HasSystem"
        hasSystemFunc.Parent = sharedRegistry
    end
    
    -- Connect functions
    sharedRegistry.GetSystem.OnInvoke = function(systemName)
        return CoreRegistry.getSystem(systemName)
    end
    
    sharedRegistry.HasSystem.OnInvoke = function(systemName)
        return CoreRegistry.hasSystem(systemName)
    end
    
    -- Connect to registration events
    sharedRegistry.RegisterSystem.Event:Connect(function(systemName, systemTable)
        -- Only register if we don't have it already to avoid loops
        if not CoreRegistry.hasSystem(systemName) then
            CoreRegistry.registerSystem(systemName, systemTable)
        end
    end)
    
    log("Shared registry created")
    return true
end

-- Start periodic health checks
function CoreRegistry.startHealthChecks()
    task.spawn(function()
        while true do
            task.wait(CONFIG.healthCheckInterval)
            CoreRegistry.runHealthCheck()
        end
    end)
    
    log("Health checks started")
    return true
end

-- Initialize the registry
function CoreRegistry.initialize()
    -- Create remote access
    CoreRegistry.createRemoteAccess()
    
    -- Create health monitoring
    CoreRegistry.createHealthMonitoring()
    
    -- Create shared registry
    CoreRegistry.createSharedRegistry()
    
    -- Start health checks
    CoreRegistry.startHealthChecks()
    
    -- Register self
    CoreRegistry.registerSystem("CoreRegistry", CoreRegistry)
    
    -- Set initial status
    CoreRegistry.setStatus("Available")
    
    log("CoreRegistry initialized successfully")
    return true
end

-- Initialize the registry
CoreRegistry.initialize()

-- Create a shared reference to CoreRegistry for critical systems
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
if not sharedFolder then
    sharedFolder = Instance.new("Folder")
    sharedFolder.Name = "shared"
    sharedFolder.Parent = ReplicatedStorage
end

-- Create a ModuleScript that returns this CoreRegistry
local coreRegistryRef = sharedFolder:FindFirstChild("CoreRegistryRef")
if not coreRegistryRef then
    coreRegistryRef = Instance.new("ModuleScript")
    coreRegistryRef.Name = "CoreRegistryRef"
    coreRegistryRef.Source = "return require(game:GetService('ServerScriptService').Core.CoreRegistry)"
    coreRegistryRef.Parent = sharedFolder
end

return CoreRegistry
