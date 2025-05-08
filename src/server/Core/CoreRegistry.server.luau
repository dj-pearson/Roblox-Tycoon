--!strict
--[[
    CoreRegistry.server.luau
    
    Enhanced registry for managing system dependencies and initialization.
    This module provides centralized system management with improved health checks,
    recovery mechanisms, and dependency tracking.
    
    Features:
    - System registration and dependency management
    - Health monitoring and reporting
    - Automatic recovery mechanisms
    - System initialization tracking
    - Error handling and logging
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

-- Configuration
local CONFIG = {
    debug = true,
    healthCheckInterval = 30, -- seconds
    maxInitAttempts = 3,
    initTimeout = 10, -- seconds
    recoveryAttempts = 3,
    recoveryDelay = 2, -- seconds,
    criticalSystems = {
        "ModuleLoader",
        "DataManager",
        "UIComponents",
        "AssetValidator",
        "BuyTileSystem",
        "TycoonSystem",
        "EventBridge"
    },
    systemDependencies = {
        DataManager = {"ModuleLoader"},
        UIComponents = {"ModuleLoader"},
        AssetValidator = {"ModuleLoader"},
        BuyTileSystem = {"DataManager", "ModuleLoader"},
        TycoonSystem = {"DataManager", "ModuleLoader"},
        EventBridge = {"ModuleLoader"}
    }
}

-- Registry state
local registry = {
    systems = {},           -- All registered systems
    dependencies = {},      -- System dependencies
    initialized = {},       -- Successfully initialized systems
    failed = {},           -- Failed initialization attempts
    loading = {},          -- Systems currently being initialized
    initAttempts = {},     -- Number of initialization attempts per system
    status = "Initializing", -- Current registry status
    lastHealthCheck = 0,    -- Timestamp of last health check
    healthCheckInterval = CONFIG.healthCheckInterval,
    recoveryAttempts = {}, -- Number of recovery attempts per system
    errorHistory = {},     -- History of initialization errors
    systemHealth = {}      -- Health status of each system
}

-- Debug logging
local function log(message, level)
    if CONFIG.debug then
        local prefix = "[CoreRegistry]"
        if level == "error" then
            warn(prefix .. " ERROR: " .. message)
        elseif level == "warn" then
            warn(prefix .. " WARNING: " .. message)
        else
            print(prefix .. " " .. message)
        end
    end
end

-- CoreRegistry module
local CoreRegistry = {}

-- Register a system
function CoreRegistry.registerSystem(name, system, dependencies)
    if not name or not system then
        log("Invalid system registration: name and system required", "error")
        return false
    end
    
    -- Check if already registered
    if registry.systems[name] then
        log("System already registered: " .. name, "warn")
        return false
    end
    
    -- Get dependencies from config or parameter
    local systemDependencies = CONFIG.systemDependencies[name] or dependencies or {}
    
    -- Register system
    registry.systems[name] = {
        module = system,
        dependencies = systemDependencies,
        lastHealthCheck = 0,
        healthStatus = "Unknown",
        errorCount = 0,
        lastError = nil
    }
    
    -- Track dependencies
    registry.dependencies[name] = systemDependencies
    
    log("Registered system: " .. name)
    return true
end

-- Initialize a single system with enhanced error handling
function CoreRegistry.initializeSystem(name)
    -- Check if already initialized
    if registry.initialized[name] then
        return true
    end
    
    -- Check if system exists
    if not registry.systems[name] then
        log("System not found: " .. name, "error")
        return false
    end
    
    -- Check initialization attempts
    registry.initAttempts[name] = (registry.initAttempts[name] or 0) + 1
    if registry.initAttempts[name] > CONFIG.maxInitAttempts then
        log("Max initialization attempts reached for system: " .. name, "error")
        registry.failed[name] = true
        return false
    end
    
    -- Detect circular dependencies
    if registry.loading[name] then
        log("Circular dependency detected for system: " .. name, "error")
        return false
    end
    
    -- Mark as loading
    registry.loading[name] = true
    
    -- Initialize dependencies first
    local dependencies = registry.dependencies[name] or {}
    for _, depName in ipairs(dependencies) do
        if not CoreRegistry.initializeSystem(depName) then
            log("Failed to initialize dependency: " .. depName .. " for system: " .. name, "error")
            registry.loading[name] = nil
            return false
        end
    end
    
    -- Initialize the system with timeout
    local system = registry.systems[name].module
    local success, result = pcall(function()
        if typeof(system.initialize) == "function" then
            return system:initialize()
        end
        return true
    end)
    
    -- Handle initialization result
    if success then
        registry.initialized[name] = system
        registry.loading[name] = nil
        registry.systemHealth[name] = "Healthy"
        log("System initialized: " .. name)
        return true
    else
        registry.loading[name] = nil
        registry.errorHistory[name] = result
        registry.systemHealth[name] = "Error"
        log("Failed to initialize system: " .. name .. " - " .. tostring(result), "error")
        return false
    end
end

-- Get a system
function CoreRegistry.getSystem(name)
    if not registry.systems[name] then
        log("System not found: " .. name, "warn")
        return nil
    end
    
    -- Try to initialize if not already initialized
    if not registry.initialized[name] then
        CoreRegistry.initializeSystem(name)
    end
    
    return registry.initialized[name]
end

-- Check if a system exists
function CoreRegistry.hasSystem(name)
    return registry.systems[name] ~= nil
end

-- Get initialization status
function CoreRegistry.getInitStatus()
    local status = {
        initialized = {},
        pending = {},
        failed = {},
        loading = {}
    }
    
    for name, _ in pairs(registry.systems) do
        if registry.initialized[name] then
            table.insert(status.initialized, name)
        elseif registry.failed[name] then
            table.insert(status.failed, name)
        elseif registry.loading[name] then
            table.insert(status.loading, name)
        else
            table.insert(status.pending, name)
        end
    end
    
    return status
end

-- Run health check
function CoreRegistry.runHealthCheck()
    local criticalCount = 0
    local totalCritical = #CONFIG.criticalSystems
    
    for _, name in ipairs(CONFIG.criticalSystems) do
        if registry.initialized[name] then
            criticalCount = criticalCount + 1
        end
    end
    
    -- Update registry status
    if criticalCount == totalCritical then
        registry.status = "Ready"
    elseif criticalCount > 0 then
        registry.status = "Degraded"
    else
        registry.status = "Error"
    end
    
    registry.lastHealthCheck = os.time()
    
    return criticalCount, totalCritical
end

-- Initialize the registry
function CoreRegistry.initialize()
    if CoreRegistry.initialized then
        return true
    end
    
    log("Initializing CoreRegistry...")
    
    -- Self-register
    CoreRegistry.registerSystem("CoreRegistry", CoreRegistry)
    CoreRegistry.initialized = true
    
    -- Start periodic health checks
    task.spawn(function()
        while true do
            task.wait(registry.healthCheckInterval)
            CoreRegistry.runHealthCheck()
        end
    end)
    
    log("CoreRegistry initialized")
    return true
end

-- Get registry status
function CoreRegistry.getStatus()
    return registry.status
end

-- Get system health status
function CoreRegistry.getSystemHealth(name)
    if not registry.systems[name] then
        return nil
    end
    
    return {
        status = registry.systemHealth[name],
        lastCheck = registry.systems[name].lastHealthCheck,
        errorCount = registry.systems[name].errorCount,
        lastError = registry.errorHistory[name],
        recoveryAttempts = registry.recoveryAttempts[name] or 0
    }
end

-- Get all system health statuses
function CoreRegistry.getAllSystemHealth()
    local health = {}
    for name, _ in pairs(registry.systems) do
        health[name] = CoreRegistry.getSystemHealth(name)
    end
    return health
end

return CoreRegistry
