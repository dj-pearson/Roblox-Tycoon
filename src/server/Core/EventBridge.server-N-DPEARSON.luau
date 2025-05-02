-- EventBridge.luau
-- Central event management system for cross-system communication
-- Place in ServerScriptService/Core

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Try to load ModuleLoader first
local ModuleLoader
local loaderSuccess, loaderResult = pcall(function()
    return require(ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("ModuleLoader"))
end)

if loaderSuccess and loaderResult then
    ModuleLoader = loaderResult
    print("[EventBridge] Successfully loaded ModuleLoader")
end

local EventBridge = {
    events = {},
    remoteEvents = {},
    moduleLoader = ModuleLoader -- Store ModuleLoader for other modules to use
}

-- Debug function
local function log(...)
    print("[EventBridge]", ...)
end

-- Initialize the module
function EventBridge:initialize()
    -- Create EventBridge folder in ReplicatedStorage if it doesn't exist
    if not ReplicatedStorage:FindFirstChild("EventBridge") then
        local eventFolder = Instance.new("Folder")
        eventFolder.Name = "EventBridge"
        eventFolder.Parent = ReplicatedStorage
        log("Created EventBridge folder in ReplicatedStorage")
    end
    
    -- Create or get core events
    self:getOrCreateEvent("TilePurchased")
    self:getOrCreateEvent("DuesCollected")
    self:getOrCreateEvent("NPCSpawned")
    self:getOrCreateEvent("GymLevelUp")
    self:getOrCreateEvent("MilestoneReached")
    self:getOrCreateEvent("SpecializationChanged")
    self:getOrCreateEvent("SeasonalEventStarted")
    self:getOrCreateEvent("SeasonalEventEnded")
    
    log("EventBridge initialized")
    return true
end

-- Get or create an event
function EventBridge:getOrCreateEvent(eventName)
    -- Check if we already have this event cached
    if self.events[eventName] then
        return self.events[eventName]
    end
    
    local eventFolder = ReplicatedStorage:FindFirstChild("EventBridge")
    if not eventFolder then
        log("EventBridge folder not found!")
        return nil
    end
    
    -- Check if event already exists
    local existingEvent = eventFolder:FindFirstChild(eventName)
    if existingEvent then
        self.events[eventName] = existingEvent
        return existingEvent
    end
    
    -- Create new event
    local newEvent = Instance.new("BindableEvent")
    newEvent.Name = eventName
    newEvent.Parent = eventFolder
    
    self.events[eventName] = newEvent
    log("Created event: " .. eventName)
    
    return newEvent
end

-- Create a remote event (for client-server communication)
function EventBridge:getOrCreateRemoteEvent(eventName)
    -- Check if we already have this remote event cached
    if self.remoteEvents[eventName] then
        return self.remoteEvents[eventName]
    end
    
    local eventFolder = ReplicatedStorage:FindFirstChild("EventBridge")
    if not eventFolder then
        log("EventBridge folder not found!")
        return nil
    end
    
    -- Check if remote event already exists
    local existingEvent = eventFolder:FindFirstChild(eventName .. "Remote")
    if existingEvent then
        self.remoteEvents[eventName] = existingEvent
        return existingEvent
    end
    
    -- Create new remote event
    local newEvent = Instance.new("RemoteEvent")
    newEvent.Name = eventName .. "Remote"
    newEvent.Parent = eventFolder
    
    self.remoteEvents[eventName] = newEvent
    log("Created remote event: " .. eventName .. "Remote")
    
    return newEvent
end

-- Fire an event
function EventBridge:fireEvent(eventName, ...)
    local event = self:getOrCreateEvent(eventName)
    if event then
        event:Fire(...)
    else
        log("Failed to fire event: " .. eventName)
    end
end

-- Connect to an event
function EventBridge:connectEvent(eventName, callback)
    local event = self:getOrCreateEvent(eventName)
    if event then
        return event.Event:Connect(callback)
    else
        log("Failed to connect to event: " .. eventName)
        return nil
    end
end

-- Fire a remote event to clients
function EventBridge:fireClientEvent(eventName, player, ...)
    local event = self:getOrCreateRemoteEvent(eventName)
    if event then
        if player then
            -- Fire to specific player
            event:FireClient(player, ...)
        else
            -- Fire to all players
            event:FireAllClients(...)
        end
    else
        log("Failed to fire remote event: " .. eventName)
    end
end

-- Connect a server handler to a remote event
function EventBridge:connectRemoteEvent(eventName, callback)
    local event = self:getOrCreateRemoteEvent(eventName)
    if event then
        return event.OnServerEvent:Connect(callback)
    else
        log("Failed to connect to remote event: " .. eventName)
        return nil
    end
end

-- Initialize Event Bridge
EventBridge:initialize()

-- Register with CoreRegistry
local function registerWithCoreRegistry()
    -- Try to find CoreRegistry in standard locations
    local CoreRegistry = nil
    
    -- Try ReplicatedStorage/shared/SafeRequire first
    local success, result = pcall(function()
        local shared = ReplicatedStorage:FindFirstChild("shared")
        if shared and shared:FindFirstChild("SafeRequire") then
            local SafeRequire = require(shared.SafeRequire)
            if SafeRequire and SafeRequire.requireFromPath then
                return SafeRequire.requireFromPath("CoreRegistry")
            end
        end
        return nil
    end)
    
    if success and result then
        CoreRegistry = result
        log("Found CoreRegistry via SafeRequire")
    end
    
    -- Try script.Parent approach
    if not CoreRegistry then
        local CoreRegistryModule = script.Parent:FindFirstChild("CoreRegistry")
        if CoreRegistryModule then
            local success, result = pcall(function()
                return require(CoreRegistryModule)
            end)
            
            if success and result then
                CoreRegistry = result
                log("Found CoreRegistry in parent folder")
            end
        end
    end
    
    if CoreRegistry then
        -- Check for register or registerSystem method (account for both naming conventions)
        if type(CoreRegistry.registerSystem) == "function" then
            CoreRegistry.registerSystem("EventBridge", EventBridge)
            log("Successfully registered with CoreRegistry using registerSystem")
            return true
        elseif type(CoreRegistry.Register) == "function" then
            CoreRegistry:Register("EventBridge", EventBridge)
            log("Successfully registered with CoreRegistry using Register")
            return true
        else
            warn("[EventBridge] CoreRegistry found but has no registration method")
            return false
        end
    else
        warn("[EventBridge] Could not find CoreRegistry to register with")
        return false
    end
end

-- Register with CoreRegistry after initialization
task.spawn(function()
    -- Wait a moment to ensure CoreRegistry is loaded
    task.wait(1)
    local success = registerWithCoreRegistry()
    
    if not success then
        -- Try again with a longer delay
        task.wait(3)
        registerWithCoreRegistry()
    end
end)

return EventBridge