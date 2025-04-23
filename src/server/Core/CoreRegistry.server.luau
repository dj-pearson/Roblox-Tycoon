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
        -- Try to load it directly for certain core systems
        if name == "DataThrottler" then
            local success, result = pcall(function()
                return require(script.Parent.DataThrottler)
            end)
            
            if success then
                CoreRegistry.registerSystem(name, result, {})
                log("Auto-loaded system: " .. name)
            else
                log("Error: Failed to auto-load system: " .. name)
                return nil
            end
        else
            log("Error: System not found: " .. name)
            return nil
        end
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
        local dependency = CoreRegistry.getSystem(dependencyName)
        if not dependency then
            log("Warning: Failed to load dependency '" .. dependencyName .. "' for system '" .. name .. "'")
        end
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

-- Create a basic EventBridge system if it doesn't exist yet
-- This is critical as many systems depend on it
local EventBridge = {
    events = {},
    remoteEvents = {},
    
    initialize = function(self)
        log("EventBridge initialized")
        return true
    end,
    
    getOrCreateEvent = function(self, eventName)
        if not self.events[eventName] then
            self.events[eventName] = {
                callbacks = {}
            }
        end
        return self.events[eventName]
    end,
    
    fireEvent = function(self, eventName, ...)
        local event = self.events[eventName]
        if event then
            for _, callback in ipairs(event.callbacks) do
                task.spawn(function()
                    callback(...)
                end)
            end
        end
    end,
    
    connectEvent = function(self, eventName, callback)
        local event = self:getOrCreateEvent(eventName)
        table.insert(event.callbacks, callback)
    end,
    
    getOrCreateRemoteEvent = function(self, eventName)
        if not self.remoteEvents[eventName] then
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            
            -- Create events folder if it doesn't exist
            local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
            if not eventsFolder then
                eventsFolder = Instance.new("Folder")
                eventsFolder.Name = "Events"
                eventsFolder.Parent = ReplicatedStorage
            end
            
            -- Create or get remote event
            local remoteEvent = eventsFolder:FindFirstChild(eventName)
            if not remoteEvent then
                remoteEvent = Instance.new("RemoteEvent")
                remoteEvent.Name = eventName
                remoteEvent.Parent = eventsFolder
            end
            
            self.remoteEvents[eventName] = remoteEvent
        end
        
        return self.remoteEvents[eventName]
    end,
    
    fireClientEvent = function(self, eventName, player, ...)
        local remoteEvent = self:getOrCreateRemoteEvent(eventName)
        if player then
            remoteEvent:FireClient(player, ...)
        else
            remoteEvent:FireAllClients(...)
        end
    end,
    
    connectRemoteEvent = function(self, eventName, callback)
        local remoteEvent = self:getOrCreateRemoteEvent(eventName)
        
        remoteEvent.OnServerEvent:Connect(function(player, ...)
            callback(player, ...)
        end)
    end
}

-- Register core EventBridge system first
CoreRegistry.registerSystem("EventBridge", EventBridge, {})

-- Register DataThrottler early to ensure it's available for other systems
pcall(function()
    local DataThrottler = require(script.Parent:FindFirstChild("DataThrottler"))
    CoreRegistry.registerSystem("DataThrottler", DataThrottler, {"CoreRegistry"})
    log("Registered DataThrottler system")
end)

-- Register the AdminDashboardSystem
local AdminDashboardSystem = require(script.Parent:FindFirstChild("AdminDashboardSystem"))
CoreRegistry.registerSystem("AdminDashboardSystem", AdminDashboardSystem, {"DataManager", "TycoonSystem", "NPCSystem", "RevenueSystem"})

-- Make CoreRegistry available to _G for emergency access
_G.CoreRegistry = CoreRegistry

return CoreRegistry