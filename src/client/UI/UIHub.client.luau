-- UIHub.client.luau
-- Central hub for managing UI elements

local UIHub = {}

local CoreRegistry = require(script.Parent.ClientRegistry)
local ClientEvents = CoreRegistry.getSystem("ClientEvents")
local ClientFunctions = CoreRegistry.getSystem("ClientFunctions")

-- Initialize the UI Hub
function UIHub:initialize()
	print("[UIHub] Initializing...")

	if not ClientEvents then
		error("[UIHub] ClientEvents not found!")
	end

	if not ClientFunctions then
		error("[UIHub] ClientFunctions not found!")
	end

	print("[UIHub] Initialized")
end

-- Public API
local PublicAPI = {
	initialize = function()
		UIHub:initialize()
	end,
}

-- Register with CoreRegistry
return CoreRegistry.registerSystem("UIHub", PublicAPI)