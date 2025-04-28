--[[
    ClientRegistry.luau
    This module serves as the central client-side system registry.
    It manages UI components, client systems, and their dependencies.
    
    Created to fix critical "ClientRegistry Module" issues reported in RobloxIssues.txt
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Internal state
local components = {}
local systems = {}
local initializedSystems = {}
local listeners = {}
local isInitialized = false

-- The module table
local ClientRegistry = {}

-- Version information
ClientRegistry.VERSION = "1.0.0"
ClientRegistry.isLoaded = true

-- Constants
ClientRegistry.STATUS = {
    AVAILABLE = "AVAILABLE",
    UNAVAILABLE = "UNAVAILABLE",
    INITIALIZING = "INITIALIZING",
    ERROR = "ERROR"
}

-- Current status
local status = ClientRegistry.STATUS.UNAVAILABLE

-- Register a UI component with the registry
function ClientRegistry.registerComponent(componentName, componentInstance)
    if not componentName or type(componentName) ~= "string" then
        warn("ClientRegistry.registerComponent: Invalid component name")
        return false
    end
    
    if components[componentName] then
        warn("ClientRegistry.registerComponent: Component already registered - " .. componentName)
        return false
    end
    
    components[componentName] = componentInstance
    print("ClientRegistry: Registered component - " .. componentName)
    
    -- Notify listeners of new component
    for _, listener in ipairs(listeners) do
        task.spawn(function()
            listener(componentName, componentInstance, "component")
        end)
    end
    
    return true
end

-- Get a registered component by name
function ClientRegistry.getComponent(componentName)
    if not componentName or not components[componentName] then
        warn("ClientRegistry.getComponent: Component not found - " .. tostring(componentName))
        return nil
    end
    
    return components[componentName]
end

-- Register a client system with the registry
function ClientRegistry.registerSystem(systemName, systemInstance)
    if not systemName or type(systemName) ~= "string" then
        warn("ClientRegistry.registerSystem: Invalid system name")
        return false
    end
    
    if systems[systemName] then
        warn("ClientRegistry.registerSystem: System already registered - " .. systemName)
        return false
    end
    
    systems[systemName] = systemInstance
    print("ClientRegistry: Registered system - " .. systemName)
    
    -- Notify listeners of new system
    for _, listener in ipairs(listeners) do
        task.spawn(function()
            listener(systemName, systemInstance, "system")
        end)
    end
    
    return true
end

-- Get a registered system by name
function ClientRegistry.getSystem(systemName)
    if not systemName or not systems[systemName] then
        warn("ClientRegistry.getSystem: System not found - " .. tostring(systemName))
        return nil
    end
    
    return systems[systemName]
end

-- Check if a component is registered
function ClientRegistry.hasComponent(componentName)
    return components[componentName] ~= nil
end

-- Check if a system is registered
function ClientRegistry.hasSystem(systemName)
    return systems[systemName] ~= nil
end

-- Get all registered components
function ClientRegistry.getAllComponents()
    local allComponents = {}
    for name, component in pairs(components) do
        allComponents[name] = component
    end
    return allComponents
end

-- Get all registered systems
function ClientRegistry.getAllSystems()
    local allSystems = {}
    for name, system in pairs(systems) do
        allSystems[name] = system
    end
    return allSystems
end

-- Register a callback to be notified when new components/systems are registered
function ClientRegistry.addListener(callback)
    if type(callback) ~= "function" then
        warn("ClientRegistry.addListener: Listener must be a function")
        return false
    end
    
    table.insert(listeners, callback)
    return true
end

-- Mark a system as initialized
function ClientRegistry.markInitialized(systemName)
    if not systemName or not systems[systemName] then
        warn("ClientRegistry.markInitialized: System not found - " .. tostring(systemName))
        return false
    end
    
    initializedSystems[systemName] = true
    print("ClientRegistry: Marked system as initialized - " .. systemName)
    return true
end

-- Check if a system has been initialized
function ClientRegistry.isSystemInitialized(systemName)
    return initializedSystems[systemName] == true
end

-- Initialize the registry
function ClientRegistry.initialize()
    if isInitialized then
        return true
    end
    
    status = ClientRegistry.STATUS.INITIALIZING
    print("ClientRegistry: Initializing...")
    
    -- Setup registry in _G for easy access
    _G.ClientRegistry = ClientRegistry
    
    -- Check essential paths and create if missing
    local function ensurePath(instance, path)
        local current = instance
        for _, name in ipairs(path) do
            local child = current:FindFirstChild(name)
            if not child then
                child = Instance.new("Folder")
                child.Name = name
                child.Parent = current
            end
            current = child
        end
        return current
    end
    
    -- Ensure shared folder exists in ReplicatedStorage
    local shared = ensurePath(ReplicatedStorage, {"shared"})
    
    -- Set up listeners for component notifications
    ClientRegistry.addListener(function(name, instance, entityType)
        print("ClientRegistry: New " .. entityType .. " registered - " .. name)
    end)
    
    -- Successfully initialized
    isInitialized = true
    status = ClientRegistry.STATUS.AVAILABLE
    print("ClientRegistry: Initialization complete")
    return true
end

-- Get the current status of the registry
function ClientRegistry.getStatus()
    return status
end

-- Set the current status
function ClientRegistry.setStatus(newStatus)
    if not ClientRegistry.STATUS[newStatus] then
        warn("ClientRegistry.setStatus: Invalid status - " .. tostring(newStatus))
        return false
    end
    
    status = ClientRegistry.STATUS[newStatus]
    return true
end

-- Initialize the registry on module load
ClientRegistry.initialize()

return ClientRegistry
