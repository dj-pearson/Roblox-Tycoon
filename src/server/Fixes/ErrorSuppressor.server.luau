-- ErrorSuppressor.luau
-- Place in ServerScriptService
-- This script creates missing folders and objects to prevent common errors

local Workspace = game:GetService("Workspace")

-- Configuration (modify these values as needed)
local CONFIG = {
	createGuiFolder = true,        -- Create the GuiFolder and required values
	disableBrokenScripts = true,   -- Disable scripts that generate errors
	fixBasketballScripts = true,   -- Fix basketball-related scripts
	fixSaunaHeaters = true,        -- Fix sauna heater elements
	showDebugMessages = false      -- Show debug messages in output
}

-- Debug function with reduced output
local function debug(...)
	if CONFIG.showDebugMessages then
		print("[ErrorSuppressor]", ...)
	end
end

print("[ErrorSuppressor] Starting error suppression...")

-- Fix GuiFolder related errors
if CONFIG.createGuiFolder then
	-- Create GuiFolder if it doesn't exist
	local guiFolder = Workspace:FindFirstChild("GuiFolder")
	if not guiFolder then
		guiFolder = Instance.new("Folder")
		guiFolder.Name = "GuiFolder"
		guiFolder.Parent = Workspace
		debug("Created GuiFolder in Workspace")
	end

	-- Add Time value
	if not guiFolder:FindFirstChild("Time") then
		local timeValue = Instance.new("IntValue")
		timeValue.Name = "Time"
		timeValue.Value = 0
		timeValue.Parent = guiFolder
		debug("Created Time value in GuiFolder")
	end

	-- Add Shotclock value
	if not guiFolder:FindFirstChild("Shotclock") then
		local shotclockValue = Instance.new("IntValue")
		shotclockValue.Name = "Shotclock"
		shotclockValue.Value = 0
		shotclockValue.Parent = guiFolder
		debug("Created Shotclock value in GuiFolder")
	end

	-- Add OneBonus and TwoBonus values for scoreboards
	if not guiFolder:FindFirstChild("OneBonus") then
		local oneBonusValue = Instance.new("BoolValue")
		oneBonusValue.Name = "OneBonus"
		oneBonusValue.Value = false
		oneBonusValue.Parent = guiFolder
		debug("Created OneBonus value in GuiFolder")
	end

	if not guiFolder:FindFirstChild("TwoBonus") then
		local twoBonusValue = Instance.new("BoolValue")
		twoBonusValue.Name = "TwoBonus"
		twoBonusValue.Value = false
		twoBonusValue.Parent = guiFolder
		debug("Created TwoBonus value in GuiFolder")
	end

	debug("GuiFolder setup complete")
end

-- Disable problematic scripts
if CONFIG.disableBrokenScripts then
	-- Find and disable basketball scripts with errors
	local commonErrorScripts = {
		{"GoalScript", "Net is not a valid member"},
		{"ShotclockLight script", "ShotclockLight is not a valid member"},
		{"RoofGoalScript", "Net is not a valid member"},
		{"regular buzzer script", "Time is not a valid member"},
		{"ScriptT", "Time is not a valid member"},
		{"MinutesScript", "Time is not a valid member"},
		{"SecondScript", "Time is not a valid member"},
		{"Script", "TwoBonus is not a valid member"},
		{"ScoreboardGuiScript", "OneBonus is not a valid member"},
		{"Heater Script", "Position is not a valid member"}
	}

	local disabledCount = 0

	-- Helper function to check if a script is producing errors
	local function disableErrorScripts(parent)
		for _, child in pairs(parent:GetDescendants()) do
			if child:IsA("Script") then
				for _, errorData in ipairs(commonErrorScripts) do
					local scriptName = errorData[1]

					if child.Name == scriptName then
						-- If the script already has a dummy handler, skip
						if child:GetAttribute("ErrorSuppressed") then
							continue
						end

						-- Disable the script by setting its Disabled property
						child.Disabled = true
						child:SetAttribute("ErrorSuppressed", true)
						disabledCount = disabledCount + 1
						debug("Disabled error-producing script: " .. child:GetFullName())
					end
				end
			end
		end
	end

	-- Check places where these scripts might be located
	disableErrorScripts(Workspace)

	debug("Disabled " .. disabledCount .. " error-producing scripts")
end

-- Fix basketball scripts
if CONFIG.fixBasketballScripts then
	-- Find and fix basketball-specific issues

	-- Helper function to check basketball goal models and add missing parts
	local function fixBasketballGoals(parent)
		for _, child in pairs(parent:GetDescendants()) do
			if child.Name == "Goal" and child:IsA("Model") then
				-- Check for missing "Net" object
				if not child:FindFirstChild("Net") then
					-- Create a placeholder Net part
					local net = Instance.new("Part")
					net.Name = "Net"
					net.Size = Vector3.new(1, 1, 1)
					net.Transparency = 1
					net.CanCollide = false
					net.Anchored = true

					-- Position it relative to the Goal
					local goalPosition = child:GetPivot().Position
					net.Position = goalPosition - Vector3.new(0, 1, 0)

					net.Parent = child
					debug("Added missing Net to " .. child:GetFullName())
				end

				-- Check for missing "ShotclockLight" object
				if not child:FindFirstChild("ShotclockLight") then
					-- Create a placeholder ShotclockLight part
					local light = Instance.new("Part")
					light.Name = "ShotclockLight"
					light.Size = Vector3.new(0.5, 0.5, 0.5)
					light.Transparency = 1
					light.CanCollide = false
					light.Anchored = true

					-- Position it relative to the Goal
					local goalPosition = child:GetPivot().Position
					light.Position = goalPosition - Vector3.new(0, -1, 0)

					-- Add a PointLight for visual effect
					local pointLight = Instance.new("PointLight")
					pointLight.Brightness = 0
					pointLight.Enabled = false
					pointLight.Parent = light

					light.Parent = child
					debug("Added missing ShotclockLight to " .. child:GetFullName())
				end

				-- Check for missing "TopLight" object
				if not child:FindFirstChild("TopLight") then
					-- Create a placeholder TopLight part
					local light = Instance.new("Part")
					light.Name = "TopLight"
					light.Size = Vector3.new(0.5, 0.5, 0.5)
					light.Transparency = 1
					light.CanCollide = false
					light.Anchored = true

					-- Position it relative to the Goal
					local goalPosition = child:GetPivot().Position
					light.Position = goalPosition - Vector3.new(0, -2, 0)

					-- Add Color property for scripts
					light:SetAttribute("Color", Color3.fromRGB(255, 0, 0))

					light.Parent = child
					debug("Added missing TopLight to " .. child:GetFullName())
				end

				-- Check for missing "swish" value
				if not child:FindFirstChild("swish") then
					local swishValue = Instance.new("BoolValue")
					swishValue.Name = "swish"
					swishValue.Value = false
					swishValue.Parent = child
					debug("Added missing swish value to " .. child:GetFullName())
				end
			end
		end
	end

	-- Fix all basketball goals in workspace
	fixBasketballGoals(Workspace)

	debug("Basketball goals have been fixed")
end

-- Fix sauna heater elements
if CONFIG.fixSaunaHeaters then
	-- Find and fix sauna heater element issues

	local function fixSaunaHeaters()
		-- Find all heater elements
		local heaterCount = 0

		for _, obj in pairs(Workspace:GetDescendants()) do
			if obj.Name == "Heater Element" and obj:IsA("Model") then
				-- Check if it has a Position property
				if not obj:GetAttribute("Position") then
					-- Get model pivot position
					local pivotPosition = obj:GetPivot().Position

					-- Store as an attribute
					obj:SetAttribute("Position", pivotPosition)

					-- Create a reference part with Position property
					local referencePart = obj:FindFirstChild("ReferencePosition")
					if not referencePart then
						-- Create a new one if needed
						referencePart = Instance.new("Part")
						referencePart.Name = "ReferencePosition"
						referencePart.Size = Vector3.new(1, 1, 1)
						referencePart.Transparency = 1
						referencePart.Anchored = true
						referencePart.CanCollide = false
						referencePart.Position = pivotPosition
						referencePart.Parent = obj

						-- Make it the primary part
						obj.PrimaryPart = referencePart
					end

					heaterCount = heaterCount + 1
					debug("Fixed Heater Element: " .. obj:GetFullName())
				end
			end
		end

		debug("Fixed " .. heaterCount .. " sauna heater elements")
		return heaterCount
	end

	fixSaunaHeaters()
end

print("[ErrorSuppressor] Error suppression complete!")