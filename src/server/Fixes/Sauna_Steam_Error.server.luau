-- Fix Sauna and Steam Room Errors
-- Place in ServerScriptService

-- Fix heater element position issues
local function fixHeaterElements()
	local modelsToFix = {}
	for _, model in pairs(game.Workspace:GetDescendants()) do
		if model:IsA("Model") and (model.Name == "Heater" or model.Name == "Sauna Bench") then
			table.insert(modelsToFix, model)
		end
	end

	for _, model in ipairs(modelsToFix) do
		if model.Name == "Heater" then
			-- Check if Heater Element exists, create if not
			local heaterElement = model:FindFirstChild("Heater Element")
			if not heaterElement then
				heaterElement = Instance.new("Model")
				heaterElement.Name = "Heater Element"
				heaterElement.Parent = model
				print("Created missing Heater Element in " .. model:GetFullName())
			end

			if heaterElement:IsA("Model") then
				-- Check for ReferencePosition, create if not
				local referencePart = heaterElement:FindFirstChild("ReferencePosition")
				if not referencePart then
					referencePart = Instance.new("Part")
					referencePart.Name = "ReferencePosition"
					referencePart.Size = Vector3.new(1, 1, 1)
					referencePart.Transparency = 1
					referencePart.Anchored = true
					referencePart.CanCollide = false
					referencePart.Parent = heaterElement
					print("Added ReferencePosition to Heater Element in " .. model:GetFullName())
				end

				if heaterElement:IsA("Model") then
					heaterElement.PrimaryPart = referencePart
				end
		elseif model.Name == "Sauna Bench" then
			if model:IsA("Model") then
				-- Check for BenchPart, create if not
				local benchPart = model:FindFirstChild("BenchPart")
				if not benchPart then
					benchPart = Instance.new("Part")
					benchPart.Name = "BenchPart"
					benchPart.Size = Vector3.new(5, 1, 2)
					benchPart.Anchored = true
					benchPart.CanCollide = true
					benchPart.Parent = model
					print("Added BenchPart to " .. model:GetFullName())
				end

				if model:IsA("Model") then
					model.PrimaryPart = benchPart
				end
			end
		end
	end
end

-- Fix sound asset issues
local function fixSoundIDs()
	local invalidSoundID = "rbxassetid://9116569437"  -- The problematic sound ID
	local replacementSoundID = "rbxassetid://5153478925" -- A temporary replacement, ideally find a better one

	for _, sound in pairs(game:GetDescendants()) do
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