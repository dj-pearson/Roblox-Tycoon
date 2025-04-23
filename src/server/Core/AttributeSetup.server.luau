--luau
--[[
    This script is responsible for setting up the attributes of interactive elements
    in the game, such as equipment and seats.
]]

local GymStructure = require(script.Parent.GymStructureIntegration)
local GymPartsFinder = require(script.Parent.GymPartsFinder)

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


local function SetupSeatAttributes()
	-- Iterate through all models.
    for _, model in pairs(workspace:GetDescendants()) do
		-- Check if the model's name contains "Seat".
		if model.Name:lower():find("seat") then
            -- Call SetupInteractiveAttributes to set the basic interactive attributes.
			SetupInteractiveAttributes(model)
            -- Set the specific InteractionType for seats.
			model:SetAttribute("InteractionType", "Seat")
        end
	end
end

-- Call the SetupEquipmentAttributes and SetupSeatAttributes functions to initialize attributes.
SetupEquipmentAttributes()
SetupSeatAttributes()
