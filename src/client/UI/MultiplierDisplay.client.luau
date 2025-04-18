-- MultiplierDisplay.client.luau
-- Module to manage the Multiplier Display UI component

local MultiplierDisplay = {}

-- Dependencies
local ClientRegistry = require(script.Parent.ClientRegistry)
local UIHub = ClientRegistry.getSystem("UIHub")

-- Initialize the module
function MultiplierDisplay:initialize()
	print("[MultiplierDisplay] Initializing...")

	-- Check if dependencies are initialized
	if not UIHub then
		error("[MultiplierDisplay] UIHub not found!")
	end
	-- Register the component
	UIHub:registerUIComponent("MultiplierDisplay", self)

	print("[MultiplierDisplay] Initialized")
end

-- Function to register the component
function MultiplierDisplay:register()
	-- Create UI elements here and store them in the module
	-- Example:
	-- self.frame = Instance.new("Frame")
	-- self.label = Instance.new("TextLabel")
	-- ...
	-- self.frame.Parent = playerGui
	print("[MultiplierDisplay] Registered")
end

-- Function to update the multiplier display
function MultiplierDisplay:updateMultiplier(multiplier)
	-- Update UI elements here
	-- Example:
	-- self.label.Text = "Multiplier: " .. tostring(multiplier)
	print("[MultiplierDisplay] Updated multiplier to: " .. tostring(multiplier))
end

-- Public API
local PublicAPI = {
	initialize = function()
		MultiplierDisplay:initialize()
	end,
	register = function()
		MultiplierDisplay:register()
	end,
	updateMultiplier = function(multiplier)
		MultiplierDisplay:updateMultiplier(multiplier)
	end,
}

return PublicAPI