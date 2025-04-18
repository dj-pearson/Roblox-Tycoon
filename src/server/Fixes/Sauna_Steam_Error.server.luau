-- Fix Sauna and Steam Room Errors
-- Place in ServerScriptService

local errorPaths = {
	-- Sauna heater models with position errors
	"Workspace.GymParts.3rd Floor.Massage and Wellness.Steam and Sauna.Sauna Mens.Heater.Heater Element",
	"Workspace.GymParts.3rd Floor.Massage and Wellness.Steam and Sauna.Sauna Womens.Heater.Heater Element",

	-- Models with size errors
	"Workspace.GymParts.3rd Floor.Massage and Wellness.Steam and Sauna.Sauna Mens.Sauna Bench",
	"Workspace.GymParts.3rd Floor.Massage and Wellness.Steam and Sauna.Sauna Womens.Sauna Bench"
}

-- Function to find instance from path
local function getInstanceFromPath(path)
	local parts = string.split(path, ".")
	local current = game

	for i, part in ipairs(parts) do
		current = current:FindFirstChild(part)
		if not current then
			return nil
		end
	end

	return current
end

-- Fix heater element position issues
local function fixHeaterElements()
	for _, path in ipairs(errorPaths) do
		local model = getInstanceFromPath(path)

		if model then
			-- Check if it's a model with position error
			if model.Name == "Heater Element" then
				-- Add a part that can be used for position reference
				local mainPart = model:FindFirstChildOfClass("Part")

				if not mainPart then
					-- Create a reference part if none exists
					mainPart = Instance.new("Part")
					mainPart.Name = "ReferencePosition"
					mainPart.Size = Vector3.new(1, 1, 1)
					mainPart.Transparency = 1
					mainPart.Anchored = true
					mainPart.CanCollide = false

					-- Calculate position based on parent
					local parent = model.Parent
					if parent and parent:IsA("Model") and parent.PrimaryPart then
						mainPart.Position = parent.PrimaryPart.Position
					else
						-- Find any part to use as reference
						for _, obj in pairs(parent:GetDescendants()) do
							if obj:IsA("BasePart") then
								mainPart.Position = obj.Position
								break
							end
						end
					end

					mainPart.Parent = model
					print("Added position reference part to " .. path)
				end

				-- Set as primary part
				model.PrimaryPart = mainPart

				-- Check if it's a model with size error
			elseif model.Name == "Sauna Bench" then
				-- Add a part with size if missing
				local mainPart = model:FindFirstChildOfClass("Part")

				if not mainPart then
					-- Create a part with size if none exists
					mainPart = Instance.new("Part")
					mainPart.Name = "BenchPart"
					mainPart.Size = Vector3.new(5, 1, 2)
					mainPart.Anchored = true
					mainPart.CanCollide = true

					-- Calculate position based on parent
					local parent = model.Parent
					if parent and parent:IsA("Model") and parent.PrimaryPart then
						mainPart.Position = parent.PrimaryPart.Position
					end

					mainPart.Parent = model
					print("Added size reference part to " .. path)
				end

				-- Set as primary part
				model.PrimaryPart = mainPart
			end
		else
			print("Could not find: " .. path)
		end
	end
end

-- Fix sound asset issues
local function fixSoundIDs()
	-- Find all sounds with invalid IDs
	local invalidSoundID = "rbxassetid://9116569437"
	local replacementSoundID = "rbxassetid://5153478925" -- Use a known working sound ID

	for _, sound in pairs(workspace:GetDescendants()) do
		if sound:IsA("Sound") and sound.SoundId == invalidSoundID then
			sound.SoundId = replacementSoundID
			print("Fixed invalid sound ID in " .. sound:GetFullName())
		end
	end
end

-- Run the fixes
fixHeaterElements()
fixSoundIDs()

print("Finished fixing sauna and steam room errors")