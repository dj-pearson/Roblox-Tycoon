-- CoreRegistry.luau
-- Central registry for managing system dependencies and initialization
-- Place in ServerScriptService/Core

local CoreRegistry = {
    systems = {},     -- Systems that have been registered
    initialized = {}, -- Systems that have been initialized
    loading = {},     -- Systems currently being initialized (to detect circular dependencies)
    status = "Initializing", -- Current status of the registry
    criticalSystems = {      -- List of critical systems that must be present
        "DataManager",
        "TycoonSystem",
        "EventBridge",
        "BuyTileSystem",
        "UIRegistry"
    }
}

-- Debug function with enhanced logging
local function log(level, ...)
    local prefix = "[CoreRegistry]"
    if level == "ERROR" then
        warn(prefix, "ERROR:", ...)
    elseif level == "WARNING" then
        warn(prefix, "WARNING:", ...)
    else
        print(prefix, ...)
    end
end

-- Check if a system is critical
local function isCriticalSystem(name)
    for _, criticalName in ipairs(CoreRegistry.criticalSystems) do
        if name == criticalName then
            return true
        end
    end
    return false
end

-- Register a system with the registry
function CoreRegistry.registerSystem(name, system, dependencies)
    if CoreRegistry.systems[name] then
        log("WARNING", "System '" .. name .. "' already registered, overwriting")
    end
    
    CoreRegistry.systems[name] = {
        module = system,
        dependencies = dependencies or {},
        status = "Registered"
    }
    
    log("INFO", "Registered system: " .. name)
    return system
end

-- Get a system and ensure it's initialized
function CoreRegistry.getSystem(name)
    -- Return already initialized system
    if CoreRegistry.initialized[name] then
        return CoreRegistry.initialized[name]
    end
    
    -- Check if system exists
    if not CoreRegistry.systems[name] then
        log("ERROR", "System not found: " .. name)
        if isCriticalSystem(name) then
            CoreRegistry.status = "Degraded"
            log("ERROR", "Critical system missing: " .. name)
        end
        return nil
    end
    
    -- Detect circular dependencies
    if CoreRegistry.loading[name] then
        log("ERROR", "Circular dependency detected for system: " .. name)
        return nil
    end
    
    -- Mark as loading
    CoreRegistry.loading[name] = true
    CoreRegistry.systems[name].status = "Loading"
    
    -- Initialize dependencies first
    local dependencyErrors = {}
    for _, dependencyName in ipairs(CoreRegistry.systems[name].dependencies) do
        local dependency = CoreRegistry.getSystem(dependencyName)
        if not dependency then
            table.insert(dependencyErrors, dependencyName)
        end
    end
    
    -- Check for dependency errors
    if #dependencyErrors > 0 then
        log("ERROR", "Failed to initialize dependencies for " .. name .. ": " .. table.concat(dependencyErrors, ", "))
        CoreRegistry.loading[name] = nil
        CoreRegistry.systems[name].status = "Failed"
        return nil
    end
    
    -- Initialize the system
    local system = CoreRegistry.systems[name].module
    if type(system.initialize) == "function" then
        log("INFO", "Initializing system: " .. name)
        local success, errorMsg = pcall(function()
            system:initialize()
        end)
        
        if not success then
            log("ERROR", "Error initializing system '" .. name .. "': " .. tostring(errorMsg))
            CoreRegistry.systems[name].status = "Failed"
            CoreRegistry.loading[name] = nil
            if isCriticalSystem(name) then
                CoreRegistry.status = "Degraded"
            end
            return nil
        end
    end
    
    -- Mark as initialized and no longer loading
    CoreRegistry.initialized[name] = system
    CoreRegistry.loading[name] = nil
    CoreRegistry.systems[name].status = "Initialized"
    
    return system
end

-- Initialize all registered systems
function CoreRegistry.initializeAll()
    log("INFO", "Initializing all registered systems...")
    CoreRegistry.status = "Initializing"
    
    local initialized = 0
    local failed = 0
    local criticalFailed = false
    
    -- First pass: Initialize all non-critical systems
    for name, _ in pairs(CoreRegistry.systems) do
        if not isCriticalSystem(name) then
            if CoreRegistry.getSystem(name) then
                initialized = initialized + 1
            else
                failed = failed + 1
            end
        end
    end
    
    -- Second pass: Initialize critical systems
    for _, name in ipairs(CoreRegistry.criticalSystems) do
        if CoreRegistry.systems[name] then
            if CoreRegistry.getSystem(name) then
                initialized = initialized + 1
            else
                failed = failed + 1
                criticalFailed = true
            end
        end
    end
    
    -- Update registry status
    if criticalFailed then
        CoreRegistry.status = "Degraded"
        log("ERROR", "Critical systems failed to initialize")
    elseif failed > 0 then
        CoreRegistry.status = "Partial"
        log("WARNING", "Some systems failed to initialize")
    else
        CoreRegistry.status = "Ready"
        log("INFO", "All systems initialized successfully")
    end
    
    log("INFO", "Initialized " .. initialized .. " systems, " .. failed .. " failed")
    return initialized, failed
end

-- Get system status
function CoreRegistry.getSystemStatus(name)
    if not CoreRegistry.systems[name] then
        return "Not Found"
    end
    return CoreRegistry.systems[name].status
end

-- Get registry status
function CoreRegistry.getStatus()
    return CoreRegistry.status
end

-- Get all registered system names
function CoreRegistry.getSystemNames()
    local names = {}
    for name, _ in pairs(CoreRegistry.systems) do
        table.insert(names, name)
    end
    return names
end

-- Register critical systems
local function registerCriticalSystems()
    -- Try to require critical systems
    local criticalModules = {
        DataManager = script.Parent:FindFirstChild("DataManager"),
        TycoonSystem = script.Parent:FindFirstChild("TycoonSystem"),
        EventBridge = script.Parent:FindFirstChild("EventBridge"),
        BuyTileSystem = script.Parent:FindFirstChild("BuyTileSystem"),
        UIRegistry = script.Parent:FindFirstChild("UIRegistry")
    }
    
    for name, module in pairs(criticalModules) do
        if module then
            local success, system = pcall(require, module)
            if success then
                CoreRegistry.registerSystem(name, system)
            else
                log("ERROR", "Failed to load critical system: " .. name)
            end
        else
            log("ERROR", "Critical system module not found: " .. name)
        end
    end
end

-- Initialize critical systems
registerCriticalSystems()

return CoreRegistry