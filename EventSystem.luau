-- EventSystem.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventSystem = {
	events = {},
	remoteEvents = {}
}

-- Initialize common events
function EventSystem.initialize()
	local eventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
	if not eventBridge then
		eventBridge = Instance.new("Folder")
		eventBridge.Name = "EventBridge"
		eventBridge.Parent = ReplicatedStorage
	end

	-- Define standard events
	local standardEvents = {
		"TilePurchased",
		"DuesCollected",
		"NPCSpawned",
		"GymLevelUp",
		"CleanlinessChanged",
		"SpecialEventStarted",
		"SpecialEventEnded"
	}

	-- Create events if they don't exist
	for _, eventName in ipairs(standardEvents) do
		-- Server events (BindableEvent)
		if not EventSystem.events[eventName] then
			local event = eventBridge:FindFirstChild(eventName)
			if not event then
				event = Instance.new("BindableEvent")
				event.Name = eventName
				event.Parent = eventBridge
			end
			EventSystem.events[eventName] = event
		end

		-- Client events (RemoteEvent)
		local remoteName = eventName .. "Event"
		if not EventSystem.remoteEvents[eventName] then
			local event = eventBridge:FindFirstChild(remoteName)
			if not event then
				event = Instance.new("RemoteEvent")
				event.Name = remoteName
				event.Parent = eventBridge
			end
			EventSystem.remoteEvents[eventName] = event
		end
	end
end

-- Fire an event
function EventSystem.fireEvent(eventName, ...)
	local event = EventSystem.events[eventName]
	if event then
		event:Fire(...)
	end
end

-- Fire an event to a specific client
function EventSystem.fireClientEvent(eventName, player, ...)
	local event = EventSystem.remoteEvents[eventName]
	if event then
		event:FireClient(player, ...)
	end
end

-- Connect to an event
function EventSystem.connect(eventName, callback)
	local event = EventSystem.events[eventName]
	if event then
		return event.Event:Connect(callback)
	end
	return nil
end

-- Initialize the system
EventSystem.initialize()

return EventSystem