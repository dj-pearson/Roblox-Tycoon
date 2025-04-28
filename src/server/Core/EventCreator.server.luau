--[[
    EventCreator.server.luau
    
    Creates all required remote events early in game lifecycle
    to prevent "Infinite yield possible on WaitForChild" errors
    for events.
    
    Created: April 27, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true
}

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[EventCreator] " .. message)
    end
end

-- List of events to create
local EVENTS_TO_CREATE = {
    -- Core events
    { name = "PlaySoundEvent", className = "RemoteEvent", parent = ReplicatedStorage },
    
    -- Player events
    { name = "PlayerDataLoaded", className = "RemoteEvent", parent = ReplicatedStorage },
    { name = "PlayerDataUpdated", className = "RemoteEvent", parent = ReplicatedStorage },
    { name = "PlayerMoneyChanged", className = "RemoteEvent", parent = ReplicatedStorage },
    
    -- Tycoon events
    { name = "TycoonUpdated", className = "RemoteEvent", parent = ReplicatedStorage },
    { name = "TycoonPurchased", className = "RemoteEvent", parent = ReplicatedStorage },
    { name = "TycoonCollected", className = "RemoteEvent", parent = ReplicatedStorage },
    
    -- UI events
    { name = "UINotification", className = "RemoteEvent", parent = ReplicatedStorage },
    { name = "UIUpdate", className = "RemoteEvent", parent = ReplicatedStorage },
    { name = "UIAction", className = "RemoteEvent", parent = ReplicatedStorage },
    
    -- Game events
    { name = "GameStateChanged", className = "RemoteEvent", parent = ReplicatedStorage }
}

-- Create an instance if it doesn't exist
local function createIfMissing(parent, name, className)
    if not parent then return nil end
    
    -- Check if the instance already exists
    local instance = parent:FindFirstChild(name)
    if instance then
        log("Instance already exists: " .. name .. " in " .. parent:GetFullName())
        return instance
    end
    
    -- Create the instance
    instance = Instance.new(className)
    instance.Name = name
    instance.Parent = parent
    
    log("Created " .. className .. ": " .. name .. " in " .. parent:GetFullName())
    return instance
end

-- Create an event folder if it doesn't exist
local function getOrCreateEventsFolder()
    -- Check if Events folder already exists
    local events = ReplicatedStorage:FindFirstChild("Events")
    if events and events:IsA("Folder") then
        return events
    end
    
    -- Create Events folder
    events = Instance.new("Folder")
    events.Name = "Events"
    events.Parent = ReplicatedStorage
    
    log("Created Events folder in ReplicatedStorage")
    return events
end

-- Create all events
local function createAllEvents()
    log("Creating all required events...")
    
    -- Make sure Events folder exists
    local eventsFolder = getOrCreateEventsFolder()
    
    -- Create each event
    for _, eventInfo in ipairs(EVENTS_TO_CREATE) do
        -- Use specified parent or default to Events folder
        local parent = eventInfo.parent or eventsFolder
        createIfMissing(parent, eventInfo.name, eventInfo.className)
    end
    
    log("All required events created")
end

-- Register event creation with CoreRegistry
local function registerWithCoreRegistry()
    -- Check if CoreRegistry is available
    if _G.CoreRegistry then
        log("Registering with CoreRegistry")
        _G.CoreRegistry.registerSystem("EventCreator", {
            createEvent = function(eventName, parent)
                parent = parent or ReplicatedStorage
                return createIfMissing(parent, eventName, "RemoteEvent")
            end,
            
            createFunction = function(functionName, parent)
                parent = parent or ReplicatedStorage
                return createIfMissing(parent, functionName, "RemoteFunction")
            end,
            
            initialize = function()
                log("EventCreator initialized through CoreRegistry")
                return true
            end
        }, {})
    end
end

-- Initialize
local function initialize()
    log("Initializing event creation...")
    
    -- Create all events
    createAllEvents()
    
    -- Register with CoreRegistry
    registerWithCoreRegistry()
    
    log("Event creation complete")
end

-- Run initialization
initialize()

-- Return API for anyone requiring this module
return {
    createEvent = function(eventName, parent)
        parent = parent or ReplicatedStorage
        return createIfMissing(parent, eventName, "RemoteEvent")
    end,
    
    createFunction = function(functionName, parent)
        parent = parent or ReplicatedStorage
        return createIfMissing(parent, functionName, "RemoteFunction")
    end
}
