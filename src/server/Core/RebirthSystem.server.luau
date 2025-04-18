lua
-- RebirthSystem.server.luau
-- Module to manage the rebirths

local RebirthSystem = {}

-- Import EventBridge
local CoreRegistry = require(script.Parent.CoreRegistry)
local EventBridge = CoreRegistry.getSystem("EventBridge")

-- Initialize the module
function RebirthSystem:initialize()
	print("[RebirthSystem] Initializing...")
	-- Initialize the EventBridge
	if not EventBridge then
		error("[RebirthSystem] EventBridge not found!")
	end
	print("[RebirthSystem] Initialized")
end

-- Public API
local PublicAPI = {
	initialize = function()
		RebirthSystem:initialize()
	end,
}

-- Register with CoreRegistry
return CoreRegistry.registerSystem("RebirthSystem", PublicAPI, { "EventBridge" })