--[[
    EquipmentSetup.server.luau

    Utility script to help set up existing equipment models
    for the EquipmentUpgradeSystem by adding necessary attributes.

    Created: April 2025
]]

local EquipmentSetup = {} -- Changed from local to Module

local Core = require(script.Parent.Parent.Core)
local AttributeSetup = Core.AttributeSetup
local GymPartsFinder = Core.GymPartsFinder

-- Process a folder of equipment and add appropriate attributes
function EquipmentSetup.SetupEquipmentFolder(folder)
	if not folder then
		warn("EquipmentSetup: Invalid folder provided")
		return 0
	end

	local setupCount = 0

	-- Process each item in the folder and its children
	local function processItem(item)
		if item:IsA("Model") or item:IsA("BasePart") then
			-- Skip if already has equipmentType set
			if not item:GetAttribute("equipmentType") then
				AttributeSetup.SetupModelAttributes(item)
				setupCount += 1
            end
		elseif item:IsA("Folder") then
			for _, child in ipairs(item:GetChildren()) do
				processItem(child)
			end
		end
	end

	for _, item in ipairs(folder:GetChildren()) do
		processItem(item)
	end

	print("EquipmentSetup: Completed setup for", setupCount, "items in", folder.Name)
	return setupCount
end

local function ProcessEquipmentFolder(folderPath)
	local success, folder = pcall(function()
		return game:GetService("Workspace"):FindFirstChild(folderPath, true)
	end)

	if success and folder then
		return EquipmentSetup.SetupEquipmentFolder(folder)
	else
		warn("ProcessEquipmentFolder: Could not find folder at", folderPath)
		return 0
	end
end

-- Export with command for developer console
return setmetatable(EquipmentSetup, {
	__call = function(_, folderPath)
		return ProcessEquipmentFolder(folderPath)
	end,
})