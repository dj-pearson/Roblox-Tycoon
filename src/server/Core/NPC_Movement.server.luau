--[[
    This module handles NPC movement within a tycoon gym environment.
    It is responsible for directing NPCs to use equipment, rest, or move between floors.
]]

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")

local CONFIG = {
	equipmentTargetChance = 0.7,
	interactionDistance = 6, -- Maximum distance in studs for interaction
	wanderRadius = 3, -- How far NPCs wander when they reach their destination
	interactionCooldown = 15, -- Seconds between interaction attempts
	interactionDuration = {
		min = 10, -- Minimum time to interact with an element
		max = 30  -- Maximum time to interact with an element
	}
}

local equipmentCache = {}

-- Debug function
local function debug(message)
	print("[NPC_Movement] " .. message)
end

-- Function to check if an element is interactive
-- Returns: boolean, string (isInteractive, interactionType)
local function isInteractiveElement(element)
	-- Check if the element has the IsInteractive attribute
	if not element:GetAttribute("IsInteractive") then
		return false, nil
	end
	
	-- Get the interaction type
	local interactionType = element:GetAttribute("InteractionType")
	if not interactionType or interactionType == "" then
		return true, "default" -- Interactive but no specific type
	end
	
	-- Check if the element is at max capacity
	local currentUsers = element:GetAttribute("CurrentUsers") or 0
	local maxUsers = element:GetAttribute("MaxUsers") or 1
	
	if currentUsers >= maxUsers then
		return false, interactionType -- At capacity
	end
	
	return true, interactionType
end

-- Function to find all the floors inside the target
local function findFloors(target)
	local floors = {}
	for _, descendant in pairs(target:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("IsFloor") then
			table.insert(floors, descendant)
		end
	end
	return floors
end

-- Function to find the target position of the model
local function findTargetPosition(model)
	-- Check if the model has a specific interaction point
	if model:FindFirstChild("InteractionPoint") then
		return model.InteractionPoint.WorldPosition
	end
	
	-- Get the interaction type
	local _, interactionType = isInteractiveElement(model)
	
	--Check if the target is a seat
	if interactionType == "Seat" then
		local position = model.PrimaryPart and model.PrimaryPart.Position or model:GetPivot().Position
		return Vector3.new(position.X, position.Y + 2, position.Z) -- Return a position above the seat
	elseif interactionType == "Cardio" or interactionType == "Weights" or interactionType == "Spa" then
		-- Calculate a position in front of the model using its orientation
		local modelCFrame = model.PrimaryPart and model.PrimaryPart.CFrame or model:GetPivot()
		local offset = modelCFrame.LookVector * -4 -- Offset to be in front of the model
		return modelCFrame.Position + Vector3.new(offset.X, 0, offset.Z) -- Return position in front of the equipment
	else
		-- Default behavior for other interaction types
		local position = model.PrimaryPart and model.PrimaryPart.Position or model:GetPivot().Position
		return Vector3.new(position.X + math.random(-2,2), position.Y, position.Z + math.random(-2,2))
	end
end

-- Function to find all equipment in a tycoon
local function cacheEquipment(tycoon)
	if equipmentCache[tycoon] then return equipmentCache[tycoon] end

	local equipment = {}

	-- Look for equipment models with the EquipmentId attribute and the IsInteractive attribute set to true
	for _, descendant in pairs(tycoon:GetDescendants()) do
		if descendant:IsA("Model") and descendant:GetAttribute("EquipmentId") and descendant:GetAttribute("IsInteractive") then
			table.insert(equipment, descendant)
		end
	end

	debug("Cached " .. #equipment .. " equipment pieces in " .. tycoon.Name)
	equipmentCache[tycoon] = equipment
	return equipment
end

--Get the correct stats
local function GetStats(npc)
	return npc:FindFirstChild("Stats")
end

-- Check if the NPC can use equipment or should rest
local function canUseEquipment(npc)
    -- Get the stats of the NPC
    local stats = GetStats(npc)

    -- Check if the NPC is tired (energy is 0)
    if stats and stats.Energy.Value <= 0 then
        return false -- NPC is too tired
    end

    -- Random check to decide if NPC will use equipment or rest
    return math.random() < CONFIG.equipmentTargetChance -- 70% chance to use equipment
end

-- Move the NPC to the given target using PathfindingService
local function moveNPCToTarget(npc, targetPosition)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local rootPart = npc:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	-- Create a path
	local path = PathfindingService:CreatePath()
	path:ComputeAsync(rootPart.Position, targetPosition)
	
	-- Check if path is computed successfully
	if path.Status == Enum.PathStatus.Success then
		-- Get waypoints
		local waypoints = path:GetWaypoints()
		
		-- Move the NPC along the path
		for _, waypoint in ipairs(waypoints) do
			humanoid:MoveTo(waypoint.Position)
			
			-- Wait until we're near the waypoint or a timeout occurs
			local startTime = os.clock()
			while (rootPart.Position - waypoint.Position).Magnitude > 2 and os.clock() - startTime < 5 do
				task.wait(0.1)
			end
			
			-- If we're at the last waypoint, we've reached our destination
			if waypoint == waypoints[#waypoints] then
				-- Add some random wandering behavior at the destination
				humanoid:MoveTo(targetPosition + Vector3.new(
					math.random(-CONFIG.wanderRadius, CONFIG.wanderRadius),
					0,
					math.random(-CONFIG.wanderRadius, CONFIG.wanderRadius)
				))
			end
		end
	else
		-- Fallback to direct movement if pathfinding fails
		humanoid:MoveTo(targetPosition)
	end
	
	npc:SetAttribute("NextMoveTime", os.time() + 3)
end

--Make the NPC rest
local function restNPC(npc)
	local tycoon = npc.Parent.Parent
	local floors = findFloors(tycoon)
	if #floors == 0 then return end

	local floor = floors[math.random(1, #floors)]
	local size = floor.Size
	local cf = floor.CFrame

	local offsetX = (math.random() - 0.5) * (size.X - 4)  -- Keep away from edges
	local offsetZ = (math.random() - 0.5) * (size.Z - 4)

	local targetPosition = cf * CFrame.new(offsetX, size.Y/2 + 3, offsetZ)
	moveNPCToTarget(npc, targetPosition.Position)
end

--Function to find any gym with a specialization
local function findGymBySpecialization(specialization)
	--Look for any gym that has the tag Tycoon, and the tag of the correct specialization
	local gyms = CollectionService:GetTagged("Tycoon")
	for _, gym in ipairs(gyms) do
		if CollectionService:HasTag(gym, "SpecializationType_"..specialization) then
			return gym
		end
	end

	return nil
end

-- Function to find matching equipment based on specialization
local function findMatchingEquipment(npc, specialization)
	local tycoon = npc.Parent.Parent
	local equipment = cacheEquipment(tycoon)

	local matchingEquipment = {}
	for _, equip in pairs(equipment) do
		--Check if the equipment has the correct specialization tag
		if equip:IsA("Model") and equip:GetAttribute("EquipmentId") and CollectionService:HasTag(equip, specialization) then
			-- Check if the equipment isn't at max capacity
			local currentUsers = equip:GetAttribute("CurrentUsers") or 0
			local maxUsers = equip:GetAttribute("MaxUsers") or 1
			
			if currentUsers < maxUsers then
				table.insert(matchingEquipment, equip)
			end
		end
	end

	if #matchingEquipment == 0 then return nil end
	return matchingEquipment[math.random(1, #matchingEquipment)]
end

--Function to make the NPC move to the equipment
local function moveToEquipment(npc, equipment)
    if not equipment then return end -- Ensure equipment is valid
    local targetPosition = findTargetPosition(equipment)
    moveNPCToTarget(npc, targetPosition)
end

-- Function to move the NPC to the correct target
local function moveToTarget(npc)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local targetGym = findGymBySpecialization(npc:GetAttribute("SpecializationPreference"))
	if not targetGym then
		restNPC(npc)
		return
	end

	local floors = findFloors(targetGym)
	if #floors == 0 then
		restNPC(npc)
		return
	end

	local floor = floors[math.random(1, #floors)]
	local size = floor.Size
	local cf = floor.CFrame
	local offsetX = (math.random() - 0.5) * (size.X - 4)  -- Keep away from edges
	local offsetZ = (math.random() - 0.5) * (size.Z - 4)
	local targetPosition = cf * CFrame.new(offsetX, size.Y/2 + 3, offsetZ)

	moveNPCToTarget(npc, targetPosition.Position)
end

-- Function to find the nearest interactive element
local function findNearestInteractiveElement(npc)
	local rootPart = npc:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local nearbyParts = workspace:GetPartsInPart(rootPart, OverlapParams.new())
	local nearestElement = nil
	local nearestDistance = math.huge

	for _, part in ipairs(nearbyParts) do
		local element = part:FindFirstAncestorOfClass("Model") or part
		local isInteractive, _ = isInteractiveElement(element)
		
		if isInteractive then
			local distance = (rootPart.Position - part.Position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestElement = element
			end
		end
	end
	return nearestElement
end

-- Function to interact with an element
local function interactWithElement(npc, interactiveElement)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local rootPart = npc:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	-- Check if the element is actually interactive
	local isInteractive, interactionType = isInteractiveElement(interactiveElement)
	if not isInteractive then
		debug(npc.Name .. " tried to interact with " .. interactiveElement.Name .. " but it's not interactive or at max capacity")
		return
	end
	
	local targetPosition = findTargetPosition(interactiveElement)

	-- Check if the NPC is close enough to interact
	local distance = (rootPart.Position - targetPosition).Magnitude
	if distance <= CONFIG.interactionDistance then
		-- Update the CurrentUsers attribute
		local currentUsers = interactiveElement:GetAttribute("CurrentUsers") or 0
		interactiveElement:SetAttribute("CurrentUsers", currentUsers + 1)
		
		-- Set the NPC's state
		npc:SetAttribute("TargetType", interactionType)
		npc:SetAttribute("CurrentInteractiveElement", interactiveElement:GetFullName())
		
		-- Handle different interaction types
		if interactionType == "Seat" then
			humanoid.Sit = true
			
			-- Sit for a random duration
			local sitDuration = math.random(CONFIG.interactionDuration.min, CONFIG.interactionDuration.max)
			task.delay(sitDuration, function()
				-- Only stand up if we're still sitting on this same element
				if npc:GetAttribute("CurrentInteractiveElement") == interactiveElement:GetFullName() then
					humanoid.Sit = false
					npc:SetAttribute("TargetType", nil)
					npc:SetAttribute("CurrentInteractiveElement", nil)
					
					-- Update CurrentUsers
					local users = interactiveElement:GetAttribute("CurrentUsers") or 1
					interactiveElement:SetAttribute("CurrentUsers", math.max(0, users - 1))
				end
			end)
		elseif interactionType == "Cardio" or interactionType == "Weights" or interactionType == "Spa" then
			-- Play appropriate animation based on equipment type
			local animationController = npc:FindFirstChildOfClass("AnimationController") or 
			                          humanoid:FindFirstChildOfClass("Animator")
			
			if animationController then
				local animationTrack
				if interactionType == "Cardio" then
					-- Play running animation
					animationTrack = animationController:LoadAnimation(script.Animations.Running)
				elseif interactionType == "Weights" then
					-- Play weight lifting animation
					animationTrack = animationController:LoadAnimation(script.Animations.WeightLifting)
				elseif interactionType == "Spa" then
					-- Play relaxing animation
					animationTrack = animationController:LoadAnimation(script.Animations.Relaxing)
				end
				
				if animationTrack then
					animationTrack:Play()
					
					-- Interact for a random duration
					local interactDuration = math.random(CONFIG.interactionDuration.min, CONFIG.interactionDuration.max)
					task.delay(interactDuration, function()
						-- Only stop if we're still interacting with this same element
						if npc:GetAttribute("CurrentInteractiveElement") == interactiveElement:GetFullName() then
							animationTrack:Stop()
							npc:SetAttribute("TargetType", nil)
							npc:SetAttribute("CurrentInteractiveElement", nil)
							
							-- Update CurrentUsers
							local users = interactiveElement:GetAttribute("CurrentUsers") or 1
							interactiveElement:SetAttribute("CurrentUsers", math.max(0, users - 1))
						end
					end)
				end
			end
		else
			-- Generic interaction for other types
			local interactDuration = math.random(CONFIG.interactionDuration.min, CONFIG.interactionDuration.max)
			task.delay(interactDuration, function()
				-- Only reset if we're still interacting with this same element
				if npc:GetAttribute("CurrentInteractiveElement") == interactiveElement:GetFullName() then
					npc:SetAttribute("TargetType", nil)
					npc:SetAttribute("CurrentInteractiveElement", nil)
					
					-- Update CurrentUsers
					local users = interactiveElement:GetAttribute("CurrentUsers") or 1
					interactiveElement:SetAttribute("CurrentUsers", math.max(0, users - 1))
				end
			end)
		end
		
		-- Apply specialization benefits if applicable
		local npcSpecialization = npc:GetAttribute("SpecializationPreference")
		if npcSpecialization and interactiveElement:GetAttribute("SpecializationType") == npcSpecialization then
			-- Add bonus stats for specialized equipment use
			local stats = GetStats(npc)
			if stats then
				if npcSpecialization == "Weights" and stats:FindFirstChild("Strength") then
					stats.Strength.Value = stats.Strength.Value * 1.1 -- 10% bonus
				elseif npcSpecialization == "Cardio" and stats:FindFirstChild("Endurance") then
					stats.Endurance.Value = stats.Endurance.Value * 1.1 -- 10% bonus
				elseif npcSpecialization == "Spa" and stats:FindFirstChild("Energy") then
					stats.Energy.Value = stats.Energy.Value * 1.1 -- 10% bonus
				end
			end
		end
	else
		-- Move closer to the element
		humanoid:MoveTo(targetPosition)
	end
end

-- Function to check if an NPC should start moving
local function checkNPCMovement(npc)
	-- Skip if NPC is already moving
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Check if it's time to move
	local nextMoveTime = npc:GetAttribute("NextMoveTime") or 0
	if os.time() < nextMoveTime then return end
	
	-- Skip if NPC is already interacting with something
	if npc:GetAttribute("CurrentInteractiveElement") then return end

	local npcPreference = npc:GetAttribute("SpecializationPreference") or "no_preference"

	-- Check for nearby interactive elements first
	local interactiveElement = findNearestInteractiveElement(npc)
	if interactiveElement then
		interactWithElement(npc, interactiveElement) -- Interact if close enough
		return -- Skip normal movement this cycle
	end

	-- Check if the NPC can use equipment or should rest (if not already interacting)
	if not canUseEquipment(npc) then
		restNPC(npc)
		return
	end

	-- If we get here the NPC can try to use a piece of equipment
	local targetEquipment
	if npcPreference ~= "no_preference" then
		targetEquipment = findMatchingEquipment(npc, npcPreference)
	end

	-- If no matching equipment or no preference, use the general target logic
	if targetEquipment then
		moveToEquipment(npc, targetEquipment)
	else
		moveToTarget(npc)
	end
end

-- Function to setup the NPC
local function setupNPC(npc)
	-- Ensure we have a HumanoidRootPart
	npc.PrimaryPart = npc:WaitForChild("HumanoidRootPart")
	
	-- Initialize attributes if not already set
	if not npc:GetAttribute("SpecializationPreference") then
		npc:SetAttribute("SpecializationPreference", "no_preference")
	end
	
	if not npc:GetAttribute("NextMoveTime") then
		npc:SetAttribute("NextMoveTime", os.time())
	end

	-- Update movement every second
	task.spawn(function()
		while true do
			checkNPCMovement(npc)
			task.wait(1)
		end
	end)
end

return {
	setupNPC = setupNPC,
	isInteractiveElement = isInteractiveElement,
	interactWithElement = interactWithElement
}
