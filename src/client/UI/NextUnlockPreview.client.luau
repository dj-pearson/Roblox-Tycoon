-- NextUnlockPreview.client.luau
-- UI component to display the next unlock preview

local NextUnlockPreview = {}

-- Dependencies
local ClientRegistry = require(script.Parent.ClientRegistry)
local UIHub = ClientRegistry.getSystem("UIHub")

-- Initialize the module
function NextUnlockPreview:initialize()
	print("[NextUnlockPreview] Initializing...")

	-- Check if dependencies are initialized
	if not UIHub then
		error("[NextUnlockPreview] UIHub not found!")
	end

	-- Register this UI component with the UI Hub
	UIHub:registerUIComponent("NextUnlockPreview", self)

	print("[NextUnlockPreview] Initialized")
end

-- Function to update the next unlock preview
function NextUnlockPreview:updatePreview(featureName)
	-- Update the UI to show the next unlockable feature
    -- Add your code here to update the UI

	print("[NextUnlockPreview] Updated preview to: " .. tostring(featureName))
end

-- Public API
local PublicAPI = {
	initialize = function()
		NextUnlockPreview:initialize()
	end,

    updatePreview = function(featureName)
        NextUnlockPreview:updatePreview(featureName)
    end,
}

-- Return the public API
return PublicAPI