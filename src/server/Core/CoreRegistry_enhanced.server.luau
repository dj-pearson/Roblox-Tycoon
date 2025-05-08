--!strict
--[[
    CoreRegistry_enhanced.server.luau
    
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
    if not registry.systems[name] then
        log("System not found: " .. name, "error")
        return false
    end
    
    -- Check if already initialized
    if registry.initialized[name] then
        return true
    end
    
    -- Check if already loading
    if registry.loading[name] then
        log("System already being initialized: " .. name, "warn")
        return false
    end
    
    -- Check initialization attempts
    registry.initAttempts[name] = (registry.initAttempts[name] or 0) + 1
    if registry.initAttempts[name] > CONFIG.maxInitAttempts then
        log("Max initialization attempts reached for: " .. name, "error")
        registry.failed[name] = true
        return false
    end
    
    -- Mark as loading
    registry.loading[name] = true
    
    -- Check dependencies
    local dependencies = registry.dependencies[name] or {}
    for _, depName in ipairs(dependencies) do
        if not registry.initialized[depName] then
            local success = CoreRegistry.initializeSystem(depName)
            if not success then
                log("Dependency initialization failed: " .. depName .. " for " .. name, "error")
                registry.loading[name] = nil
                return false
            end
        end
    end
    
    -- Initialize the system
    local success, result = pcall(function()
        if typeof(registry.systems[name].module.initialize) == "function" then
            return registry.systems[name].module:initialize()
        end
        return true
    end)
    
    -- Handle initialization result
    if success then
        registry.initialized[name] = registry.systems[name].module
        registry.loading[name] = nil
        log("System initialized: " .. name)
        return true
    else
        log("System initialization failed: " .. name .. " - " .. tostring(result), "error")
        registry.errorHistory[name] = registry.errorHistory[name] or {}
        table.insert(registry.errorHistory[name], {
            time = os.time(),
            error = tostring(result)
        })
        registry.loading[name] = nil
        return false
    end
end

-- Run health check on a system
function CoreRegistry.checkSystemHealth(name)
    if not registry.systems[name] then
        return "Unknown"
    end
    
    local system = registry.systems[name]
    local currentTime = os.time()
    
    -- Check if system has health check function
    if typeof(system.module.healthCheck) == "function" then
        local success, status = pcall(function()
            return system.module:healthCheck()
        end)
        
        if success then
            system.healthStatus = status
            system.lastHealthCheck = currentTime
            return status
        else
            system.healthStatus = "Error"
            system.lastError = tostring(status)
            return "Error"
        end
    end
    
    -- Basic health check if no health check function
    if not registry.initialized[name] then
        return "Not Initialized"
    end
    
    return "Healthy"
end

-- Run health check on all systems
function CoreRegistry.runHealthCheck()
    local currentTime = os.time()
    if currentTime - registry.lastHealthCheck < registry.healthCheckInterval then
        return registry.status
    end
    
    registry.lastHealthCheck = currentTime
    local criticalIssues = 0
    local warnings = 0
    
    -- Check all systems
    for name, _ in pairs(registry.systems) do
        local status = CoreRegistry.checkSystemHealth(name)
        
        if status == "Critical" or status == "Error" then
            criticalIssues += 1
            -- Attempt recovery for critical systems
            if table.find(CONFIG.criticalSystems, name) then
                CoreRegistry.recoverSystem(name)
            end
        elseif status == "Degraded" then
            warnings += 1
        end
    end
    
    -- Update registry status
    if criticalIssues > 0 then
        registry.status = "Critical"
    elseif warnings > 0 then
        registry.status = "Degraded"
    else
        registry.status = "Healthy"
    end
    
    return registry.status
end

-- Attempt to recover a system
function CoreRegistry.recoverSystem(name)
    if not registry.systems[name] then
        return false
    end
    
    local system = registry.systems[name]
    registry.recoveryAttempts[name] = (registry.recoveryAttempts[name] or 0) + 1
    
    if registry.recoveryAttempts[name] > CONFIG.recoveryAttempts then
        log("Max recovery attempts reached for: " .. name, "error")
        return false
    end
    
    -- Check if system has recovery function
    if typeof(system.module.recover) == "function" then
        local success, result = pcall(function()
            return system.module:recover()
        end)
        
        if success and result then
            log("System recovered: " .. name)
            return true
        else
            log("System recovery failed: " .. name .. " - " .. tostring(result), "error")
            return false
        end
    end
    
    -- Basic recovery: reinitialize
    registry.initialized[name] = nil
    registry.failed[name] = nil
    registry.initAttempts[name] = 0
    
    return CoreRegistry.initializeSystem(name)
end

-- Get registry status
function CoreRegistry.getStatus()
    return registry.status
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

-- Get system health status
function CoreRegistry.getSystemHealth(name)
    if not registry.systems[name] then
        return nil
    end
    
    return {
        status = registry.systems[name].healthStatus,
        lastCheck = registry.systems[name].lastHealthCheck,
        errorCount = registry.systems[name].errorCount,
        lastError = registry.systems[name].lastError,
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

return CoreRegistry 