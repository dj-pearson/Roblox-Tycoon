-- ServerFunctions.server.luau
-- Module to handle server-side functions

local ServerFunctions = {}

-- Import EventBridge
local CoreRegistry = require(script.Parent.CoreRegistry)
local EventBridge = CoreRegistry.getSystem("EventBridge")

-- Table to store function callbacks
local functionCallbacks = {}

-- Initialize the module
function ServerFunctions:initialize()
    print("[ServerFunctions] Initializing...")
    -- Initialize the EventBridge
    if not EventBridge then
        error("[ServerFunctions] EventBridge not found!")
    end
    print("[ServerFunctions] Initialized")
end

-- Register a function with a callback
function ServerFunctions:registerFunction(functionName, callback)
    -- Check if EventBridge is initialized
    if not EventBridge then
        error("[ServerFunctions] EventBridge is not initialized!")
        return
    end

    -- Store the callback
    functionCallbacks[functionName] = callback

    -- Connect to the remote event to receive the call
    EventBridge:connectRemoteEvent(functionName .. "Request", function(player, requestData)
        -- Call the function and return the result
        local success, result = pcall(function()
            return callback(player, unpack(requestData))
        end)

        -- Send the response to the client
        EventBridge:fireClientEvent(functionName .. "Response", player, { Success = success, Result = result })
    end)
    print("[ServerFunctions] Registered remote function: " .. functionName)
end

-- Public API
local PublicAPI = {
    initialize = function()
        ServerFunctions:initialize()
    end,

    registerFunction = function(functionName, callback)
        ServerFunctions:registerFunction(functionName, callback)
    end
}

-- Register with CoreRegistry
return CoreRegistry.registerSystem("ServerFunctions", PublicAPI)