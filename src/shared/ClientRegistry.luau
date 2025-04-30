--!strict
--[[
    ClientRegistry.luau
    
    Central registry for client-side systems and UI components.
    Manages dependencies, initialization order, and provides
    fallbacks for missing components.
    
    Created: April 27, 2025
]]

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true
}

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[ClientRegistry] " .. message)
    end
end

-- Create the registry table
local ClientRegistry = {
    systems = {},     -- Systems that have been registered
    initialized = {}, -- Systems that have been initialized
    loading = {},     -- Systems currently being initialized (to detect circular dependencies)
    events = {}       -- Event connections
}

-- Register a system with the registry
function ClientRegistry.registerSystem(name, system, dependencies)
    if ClientRegistry.systems[name] then
        log("Warning: System '" .. name .. "' already registered, overwriting")
    end
    
    ClientRegistry.systems[name] = {
        module = system,
        dependencies = dependencies or {}
    }
    
    log("Registered system: " .. name)
    return system
end

-- Check if a system exists
function ClientRegistry.hasSystem(name)
    return ClientRegistry.systems[name] ~= nil or ClientRegistry.initialized[name] ~= nil
end

-- Get a system and ensure it's initialized
function ClientRegistry.getSystem(name)
    -- Return already initialized system
    if ClientRegistry.initialized[name] then
        return ClientRegistry.initialized[name]
    end
    
    -- Check if system exists
    if not ClientRegistry.systems[name] then
        log("System not found: " .. name)
        return nil
    end
    
    -- Detect circular dependencies
    if ClientRegistry.loading[name] then
        log("Error: Circular dependency detected for system: " .. name)
        return nil
    end
    
    -- Mark as loading
    ClientRegistry.loading[name] = true
    
    -- Load dependencies first
    local system = ClientRegistry.systems[name]
    if system and system.dependencies then
        for _, depName in ipairs(system.dependencies) do
            local depSystem = ClientRegistry.getSystem(depName)
            if not depSystem then
                log("Warning: Could not load dependency '" .. depName .. "' for system '" .. name .. "'")
            end
        end
    end
    
    -- Initialize the system
    system = ClientRegistry.systems[name].module
    if type(system.initialize) == "function" then
        log("Initializing system: " .. name)
        local success, errorMsg = pcall(function()
            return system:initialize()
        end)
        
        if not success then
            log("Error initializing system '" .. name .. "': " .. tostring(errorMsg))
        end
    end
    
    -- Mark as initialized and no longer loading
    ClientRegistry.initialized[name] = system
    ClientRegistry.loading[name] = nil
    
    return system
end

-- Get all registered systems
function ClientRegistry.getAllSystems()
    local result = {}
    for name, _ in pairs(ClientRegistry.systems) do
        table.insert(result, name)
    end
    return result
end

-- Create or get an event
function ClientRegistry.getOrCreateEvent(eventName)
    if not ClientRegistry.events[eventName] then
        ClientRegistry.events[eventName] = {
            callbacks = {}
        }
    end
    return ClientRegistry.events[eventName]
end

-- Fire an event
function ClientRegistry.fireEvent(eventName, ...)
    local args = {...} -- Store varargs in a local table
    
    local event = ClientRegistry.events[eventName]
    if event then
        for _, callback in ipairs(event.callbacks) do
            task.spawn(function()
                callback(table.unpack(args))
            end)
        end
    end
end

-- Connect to an event
function ClientRegistry.connectEvent(eventName, callback)
    local event = ClientRegistry.getOrCreateEvent(eventName)
    table.insert(event.callbacks, callback)
    
    -- Return a connection object
    return {
        disconnect = function()
            for i, cb in ipairs(event.callbacks) do
                if cb == callback then
                    table.remove(event.callbacks, i)
                    break
                end
            end
        end
    }
end

-- Initialize the registry
function ClientRegistry.initialize()
    log("Initializing ClientRegistry")
    
    -- Register itself with itself
    ClientRegistry.registerSystem("ClientRegistry", ClientRegistry, {})
    
    -- Connect to client lifecycle events
    Player.CharacterAdded:Connect(function(character)
        ClientRegistry.fireEvent("CharacterAdded", character)
    end)
    
    Player.CharacterRemoving:Connect(function(character)
        ClientRegistry.fireEvent("CharacterRemoving", character)
    end)
    
    -- Fire initialization complete event
    ClientRegistry.fireEvent("ClientRegistryInitialized", ClientRegistry)
    
    log("ClientRegistry initialized successfully")
    return true
end

-- Return the registry
return ClientRegistry
