-- MainTab.client.luau
-- Main Tab UI component - Displays progress and current multipliers

local MainTab = {}

-- Dependencies
local ClientRegistry = require(script.Parent.ClientRegistry)
local ClientEvents = ClientRegistry.getSystem("ClientEvents")
local ClientFunctions = ClientRegistry.getSystem("ClientFunctions")
local UIHub = ClientRegistry.getSystem("UIHub")

-- UI Elements (will be initialized in initialize function)
local mainFrame -- Main frame for the tab
local progressBar -- Progress bar towards next rebirth
local currentMultiplierLabel -- Label displaying current multiplier
local nextUnlockLabel -- Label displaying the next unlock

-- Initialize the module
function MainTab:initialize()
	print("[MainTab] Initializing...")
	-- Check if dependencies are initialized
	if not ClientEvents then
		error("[MainTab] ClientEvents not found!")
	end
	if not ClientFunctions then
		error("[MainTab] ClientFunctions not found!")
	end
	if not UIHub then
		error("[MainTab] UIHub not found!")
	end

	-- Create the UI elements
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainTabFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.Position = UDim2.new(0, 0, 0, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	mainFrame.Visible = false -- Initially hidden, managed by UIHub

	progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(0, 0, 0.1, 0) -- Initial size 0, will be updated
	progressBar.Position = UDim2.new(0.25, 0, 0.2, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	progressBar.Parent = mainFrame

	local progressBarBackground = Instance.new("Frame")
	progressBarBackground.Name = "ProgressBarBackground"
	progressBarBackground.Size = UDim2.new(0.5, 0, 0.1, 0)
	progressBarBackground.Position = UDim2.new(0.25, 0, 0.2, 0)
	progressBarBackground.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	progressBarBackground.Parent = mainFrame

	progressBar.Parent = progressBarBackground

	currentMultiplierLabel = Instance.new("TextLabel")
	currentMultiplierLabel.Name = "CurrentMultiplierLabel"
	currentMultiplierLabel.Size = UDim2.new(0.4, 0, 0.1, 0)
	currentMultiplierLabel.Position = UDim2.new(0.3, 0, 0.4, 0)
	currentMultiplierLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	currentMultiplierLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	currentMultiplierLabel.Text = "Multiplier: 1x" -- Default value
	currentMultiplierLabel.TextScaled = true
	currentMultiplierLabel.Parent = mainFrame

	nextUnlockLabel = Instance.new("TextLabel")
	nextUnlockLabel.Name = "NextUnlockLabel"
	nextUnlockLabel.Size = UDim2.new(0.4, 0, 0.1, 0)
	nextUnlockLabel.Position = UDim2.new(0.3, 0, 0.6, 0)
	nextUnlockLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	nextUnlockLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	nextUnlockLabel.Text = "Next Unlock: None" -- Default value
	nextUnlockLabel.TextScaled = true
	nextUnlockLabel.Parent = mainFrame

	print("[MainTab] Initialized")
end

-- Register the UI component in the UIHub
function MainTab:register()
	UIHub:registerUIComponent("MainTab", mainFrame)

	-- Event handling and UI updates

	-- Update progress bar when rebirth is completed
	ClientEvents:registerEvent("RebirthCompleted", function(rebirths)
		print("[MainTab] Rebirth completed. Total rebirths: " .. rebirths)
		-- Update the UI with the new number of rebirths
		-- Example: progress bar is full after rebirth, then resets to 0
		MainTab:updateProgressBar(0) -- Reset progress bar
	end)

	-- Get initial multiplier from the server and update UI
	ClientFunctions:callServerFunction("GetCurrentMultipliers", {}) -- Assuming no arguments needed
	ClientEvents:registerEvent("CurrentMultipliersUpdated", function(multipliers)
		if multipliers then
			local multiplierText = string.format("Cash: %.2f, Speed: %.2f", multipliers.cashMultiplier, multipliers.speedMultiplier)
			MainTab:updateCurrentMultiplier(multiplierText)
		else
			MainTab:updateCurrentMultiplier("Error fetching multipliers")
		end
	end)

	-- Example next unlock (replace with actual logic from FeatureManager)
	MainTab:updateNextUnlock("Unlock new Tycoon Plot")

	print("[MainTab] Registered")
end

-- Update the progress bar
function MainTab:updateProgressBar(progressPercentage)
	if progressBar then
		-- Ensure progress is within 0-1 range
		local progress = math.clamp(progressPercentage, 0, 1)
		progressBar.Size = UDim2.new(progress, 0, 1, 0)
	end
end

-- Update the current multiplier label
function MainTab:updateCurrentMultiplier(multiplier)
	if currentMultiplierLabel then
		currentMultiplierLabel.Text = "Multipliers: " .. multiplier
	end
end

-- Update the next unlock label
function MainTab:updateNextUnlock(nextUnlock)
	if nextUnlockLabel then
		nextUnlockLabel.Text = "Next Unlock: " .. nextUnlock
	end
end

-- Public API
local PublicAPI = {
    initialize = function()
        MainTab:initialize()
    end,
    register = function()
        MainTab:register()
    end,
	updateProgressBar = function(progressPercentage)
		MainTab:updateProgressBar(progressPercentage)
	end,
    updateCurrentMultiplier = function(multiplier)
        MainTab:updateCurrentMultiplier(multiplier)
    end,
    updateNextUnlock = function(nextUnlock)
        MainTab:updateNextUnlock(nextUnlock)
    end,
    getFrame = function()
        return mainFrame
    end,
}

return PublicAPI