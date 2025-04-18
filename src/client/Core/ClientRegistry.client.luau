-- ClientRegistry.luau
-- Manages client-side systems and dependencies
-- Place in StarterPlayer/StarterPlayerScripts/Core

-- Configuration
local CONFIG = {
    debugEnabled = true,
    systemLoadTimeout = 5 -- seconds to wait for a system to load
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[ClientRegistry]", ...)
    end
end

-- The ClientRegistry system
local ClientRegistry = {
    systems = {},          -- Registered systems
    dependencies = {},     -- System dependencies
    initialized = {},      -- Initialized systems
    loadingPromises = {}   -- Promises for systems that are loading
}

-- Register a system with the registry
function ClientRegistry.registerSystem(systemName, systemModule)
    if ClientRegistry.systems[systemName] then
        log("System already registered:", systemName)
        return ClientRegistry.systems[systemName]
    end
    
    log("Registering system:", systemName)
    ClientRegistry.systems[systemName] = systemModule
    return systemModule
end

-- Get a system from the registry
function ClientRegistry.getSystem(systemName)
    if not ClientRegistry.systems[systemName] then
        log("System not found:", systemName)
        return nil
    end
    
    return ClientRegistry.systems[systemName]
end

-- Define dependencies for a system
function ClientRegistry.defineDependencies(systemName, dependencyList)
    if not ClientRegistry.systems[systemName] then
        log("Cannot define dependencies - system not registered:", systemName)
        return false
    end
    
    ClientRegistry.dependencies[systemName] = dependencyList
    log("Dependencies defined for", systemName)
    return true
end

-- Initialize a system and its dependencies
function ClientRegistry.initializeSystem(systemName)
    -- Check if system is already initialized
    if ClientRegistry.initialized[systemName] then
        return ClientRegistry.systems[systemName]
    end
    
    -- Check if system exists
    if not ClientRegistry.systems[systemName] then
        log("System not found:", systemName)
        return nil
    end
    
    -- Get dependencies
    local dependencies = ClientRegistry.dependencies[systemName] or {}
    
    -- Initialize dependencies first
    for _, dependencyName in ipairs(dependencies) do
        local dependency = ClientRegistry.initializeSystem(dependencyName)
        if not dependency then
            log("Failed to initialize dependency:", dependencyName, "for system:", systemName)
            return nil
        end
    end
    
    -- Initialize the system
    log("Initializing system:", systemName)
    local system = ClientRegistry.systems[systemName]
    
    -- Check if system has an initialize function
    if system.initialize and type(system.initialize) == "function" then
        local success, result = pcall(system.initialize)
        if not success then
            log("Error initializing system:", systemName, result)
            return nil
        end
        
        if result == false then
            log("System initialization returned false:", systemName)
            return nil
        end
    end
    
    -- Mark as initialized
    ClientRegistry.initialized[systemName] = true
    log("System initialized:", systemName)
    
    return system
end

-- Initialize all registered systems
function ClientRegistry.initializeAllSystems()
    local allInitialized = true
    
    for systemName in pairs(ClientRegistry.systems) do
        if not ClientRegistry.initialized[systemName] then
            local system = ClientRegistry.initializeSystem(systemName)
            if not system then
                allInitialized = false
                log("Failed to initialize system:", systemName)
            end
        end
    end
    
    return allInitialized
end

-- Clear the registry
function ClientRegistry.clearRegistry()
    ClientRegistry.systems = {}
    ClientRegistry.dependencies = {}
    ClientRegistry.initialized = {}
    log("Registry cleared")
    return true
end

return ClientRegistry