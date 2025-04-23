-- lua
--[[
	GymPartsFinder.server.luau

	Module script to find specific parts within the GymParts structure in the workspace.

	Updated: June 2025
]]--

local GymPartsFinder = {}

-- Retrieves a specific part by name from within the GymParts structure
function GymPartsFinder:GetPartByName(partName)
	local gymParts = self:GetGymPartsFolder()
	if gymParts then
		return gymParts:FindFirstChild(partName)
	else
		warn("GymParts folder not found in Workspace")
		return nil
	end
end

-- Retrieves the main GymParts folder from the workspace, creating it if it doesn't exist
function GymPartsFinder:GetGymPartsFolder()
	local world = game:GetService("Workspace").World
	if not world then
		warn("World not found in Workspace")
		return nil
	end

	local gymPartsFolder = world:FindFirstChild("GymParts")
	if not gymPartsFolder then
		gymPartsFolder = Instance.new("Folder")
		gymPartsFolder.Name = "GymParts"
		gymPartsFolder.Parent = world
		warn("GymParts folder not found, created a new one in World.")
	end
	return gymPartsFolder
end

-- Retrieves parts within a specific area (e.g., "WeightArea", "CardioArea") of the gym
function GymPartsFinder:GetPartsInArea(areaName)
	local gymParts = self:GetGymPartsFolder()
	if not gymParts then return {} end

	local areaFolder = gymParts:FindFirstChild(areaName)
	if not areaFolder then return {} end

	return areaFolder:GetChildren()
end

function GymPartsFinder:Initialize()
	local _ = self:GetGymPartsFolder() -- Ensure GymParts folder exists
end
return GymPartsFinder
