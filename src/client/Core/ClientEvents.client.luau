local ClientEvents = {}

ClientEvents.events = {}

function ClientEvents.initialize()
    print("[ClientEvents] Initialized")
end

function ClientEvents.registerEvent(eventName, callback)
    if not ClientEvents.events[eventName] then
        ClientEvents.events[eventName] = {}
    end
    table.insert(ClientEvents.events[eventName], callback)
    print("[ClientEvents] Registered event: " .. eventName)
end

function ClientEvents.fireEvent(eventName, ...)
    local eventCallbacks = ClientEvents.events[eventName]
    if eventCallbacks then
        for _, callback in ipairs(eventCallbacks) do
            task.spawn(callback, ...)
        end
    end
end

return ClientEvents