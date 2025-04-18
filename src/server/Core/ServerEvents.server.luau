-- ServerEvents.server.luau
-- Module to handle server-side events

local ServerEvents = {}

-- Import EventBridge
local CoreRegistry = require(script.Parent.CoreRegistry)
local EventBridge = CoreRegistry.getSystem("EventBridge")

-- Table to store event callbacks
local eventCallbacks = {}

-- Initialize the module
function ServerEvents:initialize()
	print("[ServerEvents] Initializing...")
	-- Initialize the EventBridge
	if not EventBridge then
		error("[ServerEvents] EventBridge not found!")
	end
	print("[ServerEvents] Initialized")
end

-- Register an event with a callback
function ServerEvents:registerEvent(eventName, callback)
	-- Check if EventBridge is initialized
	if not EventBridge then
		error("[ServerEvents] EventBridge is not initialized!")
		return
	end
	-- Connect to the remote event using EventBridge
	local connection = EventBridge:connectRemoteEvent(eventName, callback)
	if connection then
		eventCallbacks[eventName] = connection
	else
		error("[ServerEvents] Failed to connect to event: " .. eventName)
	end
	print("[ServerEvents] Registered event: " .. eventName)
end

-- Public API
local PublicAPI = {
	initialize = function()
		ServerEvents:initialize()
	end,

	registerEvent = function(eventName, callback)
		ServerEvents:registerEvent(eventName, callback)
	end,
}

-- Register with CoreRegistry
return CoreRegistry.registerSystem("ServerEvents", PublicAPI, {"EventBridge"})