-- CoreRegistry.luau
-- Central registry for managing system dependencies and initialization
-- Place in ServerScriptService/Core

local CoreRegistry = {
    systems = {},     -- Systems that have been registered
    initialized = {}, -- Systems that have been initialized
    loading = {}      -- Systems currently being initialized (to detect circular dependencies)
}

-- Debug function
local function log(...)
    print("[CoreRegistry]", ...)
end

-- Register a system with the registry
function CoreRegistry.registerSystem(name, system, dependencies)
    if CoreRegistry.systems[name] then
        log("Warning: System '" .. name .. "' already registered, overwriting")
    end
    
    CoreRegistry.systems[name] = {
        module = system,
        dependencies = dependencies or {}
    }
    
    log("Registered system: " .. name)
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
        log("Error: System not found: " .. name)
        return nil
    end
    
    -- Detect circular dependencies
    if CoreRegistry.loading[name] then
        log("Error: Circular dependency detected for system: " .. name)
        return nil
    end
    
    -- Mark as loading
    CoreRegistry.loading[name] = true
    
    -- Initialize dependencies first
    for _, dependencyName in ipairs(CoreRegistry.systems[name].dependencies) do
        CoreRegistry.getSystem(dependencyName)
    end
    
    -- Initialize the system
    local system = CoreRegistry.systems[name].module
    if type(system.initialize) == "function" then
        log("Initializing system: " .. name)
        local success, errorMsg = pcall(function()
            system:initialize()
        end)
        
        if not success then
            log("Error initializing system '" .. name .. "': " .. tostring(errorMsg))
        end
    end
    
    -- Mark as initialized and no longer loading
    CoreRegistry.initialized[name] = system
    CoreRegistry.loading[name] = nil
    
    return system
end

-- Initialize all registered systems
function CoreRegistry.initializeAll()
    log("Initializing all registered systems...")
    
    local initialized = 0
    for name, _ in pairs(CoreRegistry.systems) do
        if CoreRegistry.getSystem(name) then
            initialized = initialized + 1
        end
    end
    
    log("Initialized " .. initialized .. " systems")
    return initialized
end

-- Get all registered system names
function CoreRegistry.getSystemNames()
    local names = {}
    for name, _ in pairs(CoreRegistry.systems) do
        table.insert(names, name)
    end
    return names
end

-- Register the AdminDashboardSystem
local AdminDashboardSystem = require(script.Parent:FindFirstChild("AdminDashboardSystem"))
CoreRegistry.registerSystem("AdminDashboardSystem", AdminDashboardSystem, {"DataManager", "TycoonSystem", "NPCSystem", "RevenueSystem"})

return CoreRegistry