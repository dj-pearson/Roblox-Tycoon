-- ClientFunctions.client.luau  -
-- Module to handle client-side functions callable from the server

local ClientFunctions = {}

-- Import necessary modules
local CoreRegistry = require(script.Parent.ClientRegistry)
local ClientEventBridge = CoreRegistry.getSystem("ClientEventBridge")

-- Table to store registered functions
local registeredFunctions = {}

-- Initialize the module
function ClientFunctions:initialize()
	print("[ClientFunctions] Initializing...")
	if not ClientEventBridge then
		error("[ClientFunctions] ClientEventBridge not found!")
	end
	print("[ClientFunctions] Initialized")
end

-- Register a function with a callback
function ClientFunctions:registerFunction(functionName, callback)
	if not ClientEventBridge.isInitialized then
		error("[ClientFunctions] ClientEventBridge is not initialized!")
		return
	end
	
	if type(functionName) ~= "string" then
		error("[ClientFunctions] functionName must be a string")
		return
	end
	
	if type(callback) ~= "function" then
		error("[ClientFunctions] callback must be a function")
		return
	end

	registeredFunctions[functionName] = callback
	
	-- Connect to the server function response event.
	local responseEventName = functionName .. "Response"
	ClientEventBridge:createEvent(responseEventName)
	ClientEventBridge:connectEvent(responseEventName, function(...)
		local result = callback(...)
		
		ClientEventBridge:fireServerEvent(functionName .. "Result", result)
	end)

	print("[ClientFunctions] Registered function: " .. functionName)
end

-- Public API
local PublicAPI = {
	initialize = function()
		ClientFunctions:initialize()
	end,

	registerFunction = function(functionName, callback)
		ClientFunctions:registerFunction(functionName, callback)
	end,
}

-- Register with CoreRegistry
return CoreRegistry.registerSystem("ClientFunctions", PublicAPI)