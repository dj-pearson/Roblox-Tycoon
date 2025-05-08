--!strict
--[[
    CoreRegistry.server.luau
    
    Central registry for managing and coordinating all game systems.
    Handles system initialization, dependency management, and system communication.
    
    Created: April 26, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    debug = true,
    maxInitAttempts = 3,
    initTimeout = 10, -- seconds
    criticalSystems = {
        "DataManager",
        "UIComponents",
        "AssetValidator",
        "BuyTileSystem",
        "TycoonSystem",
        "EventBridge"
    }
}

-- Debug logging
local function log(message)
    if CONFIG.debug then
        print("[CoreRegistry] " .. message)
    end
end

-- Registry state
local registry = {
    systems = {},           -- All registered systems
    dependencies = {},      -- System dependencies
    initialized = {},       -- Successfully initialized systems
    failed = {},           -- Failed initialization attempts
    loading = {},          -- Systems currently being initialized
    initAttempts = {},     -- Number of initialization attempts per system
    status = "Initializing" -- Current registry status
}

-- CoreRegistry module
local CoreRegistry = {}

-- Register a system
function CoreRegistry.registerSystem(name, system, dependencies)
    if not name or not system then
        warn("Invalid system registration: name and system required")
        return false
    end
    
    -- Check if already registered
    if registry.systems[name] then
        log("System already registered: " .. name)
        return false
    end
    
    -- Register system
    registry.systems[name] = {
        module = system,
        dependencies = dependencies or {}
    }
    
    -- Track dependencies
    registry.dependencies[name] = dependencies or {}
    
    log("Registered system: " .. name)
    return true
end

-- Check if a system is registered
function CoreRegistry.hasSystem(name)
    return registry.systems[name] ~= nil
end

-- Get a system
function CoreRegistry.getSystem(name)
    -- Return already initialized system
    if registry.initialized[name] then
        return registry.initialized[name]
    end
    
    -- Check if system exists
    if not registry.systems[name] then
        log("Error: System not found: " .. name)
        return nil
    end
    
    -- Detect circular dependencies
    if registry.loading[name] then
        log("Error: Circular dependency detected for system: " .. name)
        return nil
    end
    
    -- Mark as loading
    registry.loading[name] = true
    
    -- Initialize dependencies first
    local dependencies = registry.dependencies[name] or {}
    for _, dependencyName in ipairs(dependencies) do
        local dependency = CoreRegistry.getSystem(dependencyName)
        if not dependency then
            log("Error: Failed to initialize dependency: " .. dependencyName)
            registry.loading[name] = nil
            return nil
        end
    end
    
    -- Initialize the system
    local system = registry.systems[name].module
    if type(system.initialize) == "function" then
        log("Initializing system: " .. name)
        
        -- Check initialization attempts
        registry.initAttempts[name] = (registry.initAttempts[name] or 0) + 1
        if registry.initAttempts[name] > CONFIG.maxInitAttempts then
            log("Error: Max initialization attempts exceeded for: " .. name)
            registry.failed[name] = true
            registry.loading[name] = nil
            return nil
        end
        
        -- Attempt initialization with timeout
        local initSuccess = false
        local initError = nil
        
        local initThread = task.spawn(function()
            local success, error = pcall(function()
                return system:initialize()
            end)
            
            if success then
                initSuccess = error ~= false
            else
                initError = error
            end
        end)
        
        -- Wait for initialization with timeout
        local startTime = os.clock()
        while task.status(initThread) == "running" do
            if os.clock() - startTime > CONFIG.initTimeout then
                log("Error: Initialization timed out for: " .. name)
                registry.failed[name] = true
                registry.loading[name] = nil
                return nil
            end
            task.wait(0.1)
        end
        
        if not initSuccess then
            log("Error initializing system '" .. name .. "': " .. tostring(initError))
            registry.failed[name] = true
            registry.loading[name] = nil
            return nil
        end
    end
    
    -- Mark as initialized and no longer loading
    registry.initialized[name] = system
    registry.loading[name] = nil
    log("Successfully initialized system: " .. name)
    
    return system
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
    log("Running health check...")
    
    -- Check critical systems
    local missingCritical = false
    local failedCritical = false
    
    for _, systemName in ipairs(CONFIG.criticalSystems) do
        if not CoreRegistry.hasSystem(systemName) then
            log("Critical system missing: " .. systemName)
            missingCritical = true
        elseif registry.failed[systemName] then
            log("Critical system failed: " .. systemName)
            failedCritical = true
        end
    end
    
    -- Update status
    if missingCritical then
        registry.status = "Critical"
    elseif failedCritical then
        registry.status = "Degraded"
    else
        registry.status = "Available"
    end
    
    -- Log status
    log("Registry status: " .. registry.status)
    
    return registry.status
end

-- Get registry status
function CoreRegistry.getStatus()
    return registry.status
end

-- Initialize all systems
function CoreRegistry.initializeAll()
    log("Initializing all systems...")
    
    -- Initialize critical systems first
    for _, systemName in ipairs(CONFIG.criticalSystems) do
        if not CoreRegistry.getSystem(systemName) then
            log("Failed to initialize critical system: " .. systemName)
        end
    end
    
    -- Initialize remaining systems
    for name, _ in pairs(registry.systems) do
        if not CoreRegistry.getSystem(name) then
            log("Failed to initialize system: " .. name)
        end
    end
    
    -- Run health check
    CoreRegistry.runHealthCheck()
    
    return registry.status ~= "Critical"
end

return CoreRegistry
