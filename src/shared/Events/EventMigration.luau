--!strict
--[[
    EventMigration.luau
    
    A utility module that provides compatibility between the legacy event system
    and the new unified Event System. This module helps migrate code from the old 
    event patterns to the new system gradually.
    
    Features:
    - Legacy event adapter for old-style event connections
    - Automatic event forwarding to the new system
    - Event mapping between old and new event names
    - Migration statistics and reporting
    
    Created: May 2, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Import modules
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local EventsModule = SharedModules:WaitForChild("Events")

local EventTypes = require(EventsModule:WaitForChild("EventTypes"))
local EventBridge = require(EventsModule:WaitForChild("EventBridge"))

-- Determine context
local isServer = RunService:IsServer()

-- Import context-specific event implementation
local ContextEvents
if isServer then
    local ServerScriptService = game:GetService("ServerScriptService")
    local ServerCore = ServerScriptService:WaitForChild("src"):WaitForChild("server"):WaitForChild("Core")
    local ServerEventsModule = ServerCore:WaitForChild("Events"):WaitForChild("ServerEvents")
    ContextEvents = require(ServerEventsModule)
else
    local PlayerScripts = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts")
    local ClientCore = PlayerScripts:WaitForChild("src"):WaitForChild("client"):WaitForChild("Core") 
    local ClientEventsModule = ClientCore:WaitForChild("Events"):WaitForChild("ClientEvents")
    ContextEvents = require(ClientEventsModule)
end

-- Map of legacy event names to new event names
local EVENT_NAME_MAPPING = {
    -- UI Events
    ["UINotification"] = "ui.notification",
    ["OpenMenu"] = "ui.menu.open",
    ["CloseMenu"] = "ui.menu.close",
    
    -- Economy Events
    ["TransactionComplete"] = "economy.transaction.complete",
    ["ResourceUpdate"] = "economy.resource.update",
    
    -- Tycoon Events
    ["TycoonUpdate"] = "tycoon.update",
    ["EquipmentPurchase"] = "tycoon.equipment.purchase",
    ["StaffHire"] = "tycoon.staff.hire",
    
    -- Gym Events
    ["GymEquipmentInteraction"] = "gym.equipment.interaction", 
    ["WorkoutComplete"] = "gym.workout.complete",
    ["MemberSatisfactionChange"] = "gym.member.satisfaction.change",
    
    -- Player Events
    ["PlayerDataUpdate"] = "player.data.update",
    
    -- System Events
    ["SystemStatus"] = "system.status",
    ["ErrorReport"] = "system.error",
    ["DebugCommand"] = "system.debug.command"
}

-- The migration utility
local EventMigration = {}

-- Keep track of statistics
EventMigration.Stats = {
    legacyEventsConnected = 0,
    eventsForwarded = 0,
    remoteEventsProcessed = 0
}

-- Connect a handler to a legacy event while forwarding to the new system
function EventMigration:ConnectLegacyEvent(eventName, handler)
    -- Get the legacy event
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEvents then
        warn("EventMigration: RemoteEvents folder not found")
        return nil
    end
    
    local legacyEvent = remoteEvents:FindFirstChild(eventName)
    if not legacyEvent then
        warn("EventMigration: Legacy event not found: " .. eventName)
        return nil
    end
    
    -- Create connection to legacy event
    local connection
    if isServer then
        connection = legacyEvent.OnServerEvent:Connect(function(player, ...)
            -- Call handler with legacy format
            handler(player, ...)
            
            -- Forward to new event system if there's a mapping
            if EVENT_NAME_MAPPING[eventName] then
                local args = {...}
                ContextEvents:emit(EVENT_NAME_MAPPING[eventName], {
                    player = player,
                    args = args,
                    source = "legacy_event",
                    original_event = eventName
                })
                
                EventMigration.Stats.eventsForwarded += 1
            end
        end)
    else
        connection = legacyEvent.OnClientEvent:Connect(function(...)
            -- Call handler with legacy format
            handler(...)
            
            -- Forward to new event system if there's a mapping
            if EVENT_NAME_MAPPING[eventName] then
                local args = {...}
                ContextEvents:emit(EVENT_NAME_MAPPING[eventName], {
                    args = args,
                    source = "legacy_event",
                    original_event = eventName
                })
                
                EventMigration.Stats.eventsForwarded += 1
            end
        end)
    end
    
    EventMigration.Stats.legacyEventsConnected += 1
    return connection
end

-- Fire a legacy event while also firing the equivalent in the new system
function EventMigration:FireLegacyEvent(eventName, ...)
    -- Get the legacy event
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEvents then
        warn("EventMigration: RemoteEvents folder not found")
        return false
    end
    
    local legacyEvent = remoteEvents:FindFirstChild(eventName)
    if not legacyEvent then
        warn("EventMigration: Legacy event not found: " .. eventName)
        return false
    end
    
    -- Fire the legacy event
    local args = {...}
    if isServer then
        -- Server firing to clients
        if typeof(args[1]) == "Instance" and args[1]:IsA("Player") then
            -- Sending to specific player
            local player = args[1]
            table.remove(args, 1)
            legacyEvent:FireClient(player, unpack(args))
        else
            -- Sending to all players
            legacyEvent:FireAllClients(unpack(args))
        end
    else
        -- Client firing to server
        legacyEvent:FireServer(unpack(args))
    end
    
    -- Fire the equivalent event in the new system
    if EVENT_NAME_MAPPING[eventName] then
        local eventData = {
            args = args,
            source = "legacy_event",
            original_event = eventName
        }
        
        if isServer and typeof(args[1]) == "Instance" and args[1]:IsA("Player") then
            eventData.player = args[1]
        end
        
        ContextEvents:emit(EVENT_NAME_MAPPING[eventName], eventData)
        EventMigration.Stats.eventsForwarded += 1
    end
    
    return true
end

-- Get a function to replace a legacy RemoteFunction
function EventMigration:GetLegacyFunctionWrapper(functionName, handler)
    local remoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
    if not remoteFunctions then
        warn("EventMigration: RemoteFunctions folder not found")
        return nil
    end
    
    local legacyFunction = remoteFunctions:FindFirstChild(functionName)
    if not legacyFunction then
        warn("EventMigration: Legacy function not found: " .. functionName)
        return nil
    end
    
    if isServer then
        -- Set the OnServerInvoke function
        legacyFunction.OnServerInvoke = function(player, ...)
            return handler(player, ...)
        end
    else
        -- Return a wrapper for the client to call
        return function(...)
            return legacyFunction:InvokeServer(...)
        end
    end
    
    return handler
end

-- Generate a report about migration status
function EventMigration:GenerateReport()
    return {
        legacyEventsConnected = EventMigration.Stats.legacyEventsConnected,
        eventsForwarded = EventMigration.Stats.eventsForwarded,
        remoteEventsProcessed = EventMigration.Stats.remoteEventsProcessed,
        eventMappings = #EVENT_NAME_MAPPING,
        context = isServer and "Server" or "Client",
        timestamp = os.time()
    }
end

return EventMigration
