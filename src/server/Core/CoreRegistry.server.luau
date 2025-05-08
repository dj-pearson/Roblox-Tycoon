--!strict
--[[
    CoreRegistry.server.luau
    
    Central registry for managing and coordinating all game systems.
    Handles system initialization, dependency management, and system communication.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Major overhaul for improved reliability
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    debug = true,
    maxInitAttempts = 3,
    initTimeout = 10, -- seconds
    healthCheckInterval = 30, -- seconds
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
        UIComponents = {"ModuleLoader", "DataManager"},
        AssetValidator = {"ModuleLoader", "DataManager"},
        BuyTileSystem = {"ModuleLoader", "DataManager", "AssetValidator"},
        TycoonSystem = {"ModuleLoader", "DataManager", "BuyTileSystem"},
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
    healthCheckInterval = CONFIG.healthCheckInterval
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
        healthStatus = "Unknown"
    }
    
    -- Track dependencies
    registry.dependencies[name] = systemDependencies
    
    log("Registered system: " .. name)
    return true
end

-- Initialize a single system
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
    
    -- Initialize the system
    local system = registry.systems[name].module
    if type(system.initialize) == "function" then
        log("Initializing system: " .. name)
        
        local success, result = pcall(function()
            return system:initialize()
        end)
        
        if not success then
            log("Error initializing system '" .. name .. "': " .. tostring(result), "error")
            registry.loading[name] = nil
            return false
        end
        
        if result == false then
            log("System initialization returned false: " .. name, "error")
            registry.loading[name] = nil
            return false
        end
    end
    
    -- Mark as initialized and no longer loading
    registry.initialized[name] = system
    registry.loading[name] = nil
    registry.failed[name] = nil
    
    log("Successfully initialized system: " .. name)
    return true
end

-- Initialize all systems
function CoreRegistry.initializeAll()
    log("Starting system initialization...")
    
    -- Initialize critical systems first
    for _, systemName in ipairs(CONFIG.criticalSystems) do
        if not CoreRegistry.initializeSystem(systemName) then
            log("Failed to initialize critical system: " .. systemName, "error")
        end
    end
    
    -- Initialize remaining systems
    for name, _ in pairs(registry.systems) do
        if not table.find(CONFIG.criticalSystems, name) then
            if not CoreRegistry.initializeSystem(name) then
                log("Failed to initialize system: " .. name, "warn")
            end
        end
    end
    
    -- Run health check
    CoreRegistry.runHealthCheck()
    
    return registry.status ~= "Critical"
end

-- Run health check
function CoreRegistry.runHealthCheck()
    local now = os.time()
    if now - registry.lastHealthCheck < registry.healthCheckInterval then
        return
    end
    
    log("Running health check...")
    registry.lastHealthCheck = now
    
    local criticalCount = 0
    local totalCritical = #CONFIG.criticalSystems
    local failedSystems = {}
    
    -- Check critical systems
    for _, systemName in ipairs(CONFIG.criticalSystems) do
        local system = registry.systems[systemName]
        if system then
            if registry.initialized[systemName] then
                -- Check system health if available
                if type(system.module.isHealthy) == "function" then
                    local isHealthy = system.module:isHealthy()
                    if not isHealthy then
                        log("System unhealthy: " .. systemName, "warn")
                        failedSystems[systemName] = "Unhealthy"
                    end
                end
                criticalCount += 1
            else
                log("Critical system not initialized: " .. systemName, "error")
                failedSystems[systemName] = "Not Initialized"
            end
        else
            log("Critical system not found: " .. systemName, "error")
            failedSystems[systemName] = "Not Found"
        end
    end
    
    -- Update registry status
    if criticalCount == totalCritical then
        registry.status = "Ready"
    elseif criticalCount > 0 then
        registry.status = "Degraded"
    else
        registry.status = "Critical"
    end
    
    -- Attempt recovery for failed systems
    for systemName, reason in pairs(failedSystems) do
        log("Attempting recovery for system: " .. systemName .. " (Reason: " .. reason .. ")")
        local system = registry.systems[systemName]
        if system and type(system.module.recover) == "function" then
            local success = system.module:recover()
            if success then
                log("Successfully recovered system: " .. systemName)
                failedSystems[systemName] = nil
            else
                log("Failed to recover system: " .. systemName, "error")
            end
        end
    end
    
    return criticalCount, totalCritical
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
