--[[
    CoreRegistry.luau
    This module serves as the central system registry for the game.
    It manages system dependencies, initialization order, and provides
    a unified way to access core systems.
    
    Created to fix critical "CoreRegistry Issues" reported in RobloxIssues.txt
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Internal state
local systems = {}
local initializedSystems = {}
local listeners = {}
local isInitialized = false

-- The module table
local CoreRegistry = {}

-- Version information
CoreRegistry.VERSION = "1.0.0"
CoreRegistry.isLoaded = true

-- Constants
CoreRegistry.STATUS = {
    AVAILABLE = "AVAILABLE",
    UNAVAILABLE = "UNAVAILABLE",
    INITIALIZING = "INITIALIZING",
    ERROR = "ERROR"
}

-- Current status
local status = CoreRegistry.STATUS.UNAVAILABLE

-- Register a system with the registry
function CoreRegistry.registerSystem(systemName, systemInstance)
    if not systemName or type(systemName) ~= "string" then
        warn("CoreRegistry.registerSystem: Invalid system name")
        return false
    end
    
    if systems[systemName] then
        warn("CoreRegistry.registerSystem: System already registered - " .. systemName)
        return false
    end
    
    systems[systemName] = systemInstance
    print("CoreRegistry: Registered system - " .. systemName)
    
    -- Notify listeners of new system
    for _, listener in ipairs(listeners) do
        task.spawn(function()
            listener(systemName, systemInstance)
        end)
    end
    
    return true
end

-- Get a registered system by name
function CoreRegistry.getSystem(systemName)
    if not systemName or not systems[systemName] then
        warn("CoreRegistry.getSystem: System not found - " .. tostring(systemName))
        return nil
    end
    
    return systems[systemName]
end

-- Check if a system is registered
function CoreRegistry.hasSystem(systemName)
    return systems[systemName] ~= nil
end

-- Get all registered systems
function CoreRegistry.getAllSystems()
    local allSystems = {}
    for name, system in pairs(systems) do
        allSystems[name] = system
    end
    return allSystems
end

-- Register a callback to be notified when new systems are registered
function CoreRegistry.addListener(callback)
    if type(callback) ~= "function" then
        warn("CoreRegistry.addListener: Listener must be a function")
        return false
    end
    
    table.insert(listeners, callback)
    return true
end

-- Mark a system as initialized
function CoreRegistry.markInitialized(systemName)
    if not systemName or not systems[systemName] then
        warn("CoreRegistry.markInitialized: System not found - " .. tostring(systemName))
        return false
    end
    
    initializedSystems[systemName] = true
    print("CoreRegistry: Marked system as initialized - " .. systemName)
    return true
end

-- Check if a system has been initialized
function CoreRegistry.isSystemInitialized(systemName)
    return initializedSystems[systemName] == true
end

-- Initialize the registry
function CoreRegistry.initialize()
    if isInitialized then
        return true
    end
    
    status = CoreRegistry.STATUS.INITIALIZING
    print("CoreRegistry: Initializing...")
    
    -- Setup registry in _G for easy access
    _G.CoreRegistry = CoreRegistry
    
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
    
    -- Ensure core paths exist
    ensurePath(ServerScriptService, {"Core"})
    ensurePath(ReplicatedStorage, {"shared"})
    
    -- Successfully initialized
    isInitialized = true
    status = CoreRegistry.STATUS.AVAILABLE
    print("CoreRegistry: Initialization complete")
    return true
end

-- Get the current status of the registry
function CoreRegistry.getStatus()
    return status
end

-- Set the current status
function CoreRegistry.setStatus(newStatus)
    if not CoreRegistry.STATUS[newStatus] then
        warn("CoreRegistry.setStatus: Invalid status - " .. tostring(newStatus))
        return false
    end
    
    status = CoreRegistry.STATUS[newStatus]
    return true
end

-- Initialize the registry on module load
CoreRegistry.initialize()

return CoreRegistry
