--luau
--[[
    This script is responsible for setting up the attributes of interactive elements
    in the game, such as equipment and seats.
]]

local GymStructure = require(script.Parent.GymStructureIntegration)
local GymPartsFinder = require(script.Parent.GymPartsFinder)

--[[
    Checks if a model has a descendant named "Seat" and adds the "HasSeatLayer" attribute.
    @param model The model to check and add the attribute to.
]]
local function CheckForSeatLayer(model)
	-- Iterate through the descendants of the model.
	for _, descendant in ipairs(model:GetDescendants()) do
		-- Check if the descendant is named "Seat".
		if descendant.Name == "Seat" then
			-- Add the "HasSeatLayer" attribute and set it to true.
			model:SetAttribute("HasSeatLayer", true)
			return -- Exit the function early since we found a "Seat".
		end
	end
	-- If no "Seat" descendant is found, don't add the attribute (it defaults to nil).
end

--[[
    Adds the IsInteractive, InteractionType, and CurrentUsers attributes to a model.
    @param model The model to which attributes will be added.
]]
local function SetupInteractiveAttributes(model)
	-- Adds the IsInteractive attribute and sets it to true.
	model:SetAttribute("IsInteractive", true)

	-- Adds the InteractionType attribute and sets a default value of "Unknown".
	model:SetAttribute("InteractionType", "Unknown")

	-- Adds the CurrentUsers attribute and sets the initial count to 0.
	model:SetAttribute("CurrentUsers", 0)
end

--[[
    Iterates through all equipment models and sets their interactive attributes.
]]
local function SetupEquipmentAttributes()
	local equipmentAreas = {
		GymStructure.Rooms.WeightRoom,
		GymStructure.Rooms.CardioArea,
		GymStructure.Rooms.FunctionalTraining,
		GymStructure.Rooms.SpecializedTraining
	}

	for _, area in ipairs(equipmentAreas) do
		local equipment = GymPartsFinder.GetInstancesInArea(area, "Equipment")
		for _, model in ipairs(equipment) do
			SetupInteractiveAttributes(model)
			model:SetAttribute("InteractionType", "Equipment")
		end
	end
end

--[[
    Sets up the attributes for seat models.
]]
local function SetupSeatAttributes()
	for _, model in ipairs(workspace:GetDescendants()) do
		if model:IsA("Model") then
			CheckForSeatLayer(model)
			if model:GetAttribute("HasSeatLayer") then
			SetupInteractiveAttributes(model)
			model:SetAttribute("InteractionType", "Seat")
			end
		end
	end
end

-- Call the SetupEquipmentAttributes and SetupSeatAttributes functions to initialize attributes.
SetupEquipmentAttributes()
SetupSeatAttributes()
