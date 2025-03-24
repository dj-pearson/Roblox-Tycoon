-- FrontDeskGuiFixer.lua
-- Place in ServerScriptService
-- Properly fixes front desk GUI without flashing

local Players = game:GetService("Players")

-- Configuration
local CONFIG = {
	fixDelay = 5,      -- One-time delay before applying fix
	debug = true       -- Show debug messages
}

-- Debug function
local function debugPrint(...)
	if CONFIG.debug then
		print("[FrontDeskFixer]", ...)
	end
end

-- Apply a permanent fix to a player's front desk GUI
local function applyPermanentFix(player)
	debugPrint("Applying permanent fix for " .. player.Name)

	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then return end

	local frontDesk = tycoon.Value:FindFirstChild("Front Desk")
	if not frontDesk then return end

	-- First step: Identify all GUIs
	local problematicGuis = {}

	for _, gui in pairs(frontDesk:GetChildren()) do
		if gui:IsA("BillboardGui") then
			-- Look for specific signs of the problematic GUI
			for _, textLabel in pairs(gui:GetDescendants()) do
				if textLabel:IsA("TextLabel") and
					(textLabel.Text:find("Collect Dues") or 
						textLabel.Text:find("Members")) then

					if gui.Name == "BillboardGui" then  -- This is usually the problematic one
						table.insert(problematicGuis, gui)
					end
				end
			end
		end
	end

	-- Second step: Find which one to remove (the larger one)
	local guiToRemove = nil

	if #problematicGuis > 1 then
		-- Find the larger GUI (usually the problematic one)
		for _, gui in ipairs(problematicGuis) do
			if not guiToRemove or 
				gui.Size.X.Offset > guiToRemove.Size.X.Offset or
				gui.Size.Y.Offset > guiToRemove.Size.Y.Offset then
				guiToRemove = gui
			end
		end
	elseif #problematicGuis == 1 then
		guiToRemove = problematicGuis[1]
	end

	-- Third step: Remove it and add attribute to prevent re-creation
	if guiToRemove then
		debugPrint("Removing problematic GUI: " .. guiToRemove.Name)
		guiToRemove:Destroy()

		-- Add an attribute to the front desk to mark that we've fixed it
		frontDesk:SetAttribute("GuiFixed", true)

		-- Also add protection against recreation
		local preventRecreation = Instance.new("BoolValue")
		preventRecreation.Name = "PreventGuiRecreation"
		preventRecreation.Value = true
		preventRecreation.Parent = frontDesk
	end
end

-- Function to fix all players
local function fixAllPlayers()
	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(function()
			applyPermanentFix(player)
		end)
	end
end

-- Apply fixes after a delay (to ensure everything is loaded)
task.delay(CONFIG.fixDelay, function()
	debugPrint("Running one-time front desk GUI fix")
	fixAllPlayers()
end)

-- Handle new players
Players.PlayerAdded:Connect(function(player)
	task.delay(CONFIG.fixDelay, function()
		applyPermanentFix(player)
	end)
end)

debugPrint("Front desk GUI fixer initialized")

return {
	applyPermanentFix = applyPermanentFix,
	fixAllPlayers = fixAllPlayers
}