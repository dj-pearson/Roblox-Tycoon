-- Enhanced NPC Movement System
-- This script manages NPC movement using PathfindingService for better navigation.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")


-- Configuration
local CONFIG = {
	updateFrequency = 1, -- How often to update NPCs (seconds)
	equipmentTargetChance = 0.7, -- Chance NPC will target equipment, reduced for more varied behavior
	minStayTime = 10, -- Min time at destination (seconds), reduced for quicker turnover
	maxStayTime = 30, -- Max time at destination (seconds), reduced for quicker turnover
	maxPathfindingDistance = 80, -- Max distance for pathfinding, reduced for more local movement
	debugEnabled = false, -- Show debug messages, disabled by default
	wanderRadius = 4 -- Radius for wandering around a target position, slightly reduced
}

local DEBUG_ENABLED = CONFIG.debugEnabled

-- Debug function
local function debug(...)
	if DEBUG_ENABLED then
		print("[NPC Movement]", ...)
	end
end


-- Cache equipment in tycoons for faster targeting
local equipmentCache = {}

-- Function to find all equipment in a tycoon
local function cacheEquipment(tycoon)
	if equipmentCache[tycoon] then return equipmentCache[tycoon] end

	local equipment = {}
	-- Iterate through the descendants of the tycoon
	for _, descendant in pairs(tycoon:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("IsInteractive") then -- Check for BaseParts that are interactive
			table.insert(equipment, descendant)
			end
		end
	end

	debug("Cached " .. #equipment .. " equipment pieces in " .. tycoon.Name)
	equipmentCache[tycoon] = equipment
	return equipment
end

-- Function to find all floors in a tycoon
local function findFloors(tycoon)
	local floors = {}
	local GymStructureIntegration = require(script.Parent.Parent.GymStructureIntegration)
	local floorAreas = GymStructureIntegration.getAreasByType(tycoon, "Floor") -- Assuming "Floor" is the area type for walkable surfaces

	if floorAreas then
		for _, area in ipairs(floorAreas) do
			local areaModel = tycoon:FindFirstChild(area)
			if areaModel then
				for _, descendant in pairs(areaModel:GetDescendants()) do
					if descendant:IsA("BasePart") then
						table.insert(floors, descendant)
					end
				end
			end
		end
	end
	return floors -- Return the collected floors
end

local function findSeats(tycoonModel)
	local seats = {}
	for _, model in ipairs(tycoonModel:GetDescendants()) do
		if model:IsA("Model") and model:GetAttribute("InteractionType") == "Seat" then
			table.insert(seats, model)
		end
	end
	return seats
end

local function getPositionFromModel(model)
	if model.PrimaryPart then
		return model.PrimaryPart.Position
	else
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				return part.Position
			end
		end
	end
	return nil
end

local function getPositionFromEquipment(tycoon, equipment)
	local position = getPositionFromModel(equipment)
	if position then
		local offsetX = math.random(-3, 3)
		local offsetZ = math.random(-3, 3)
		return position + Vector3.new(offsetX, 0, offsetZ)
	end
	return nil
end

local function findTargetPositionForEquipment(tycoon)
	local equipment = cacheEquipment(tycoon)
	if #equipment > 0 then
		local targetEquipment = equipment[math.random(1, #equipment)] 
		if targetEquipment then
			return position, "equipment"
		end
	end
	return nil, nil
end

local function findTargetPositionOnFloor(tycoon)
	local floors = findFloors(tycoon)
	if #floors > 0 then
		local floor = floors[math.random(1, #floors)]
		local size = floor.Size -- Use actual floor part size for accurate positioning
		local marginX, marginZ = math.min(size.X * 0.4, 4), math.min(size.Z * 0.4, 4)
		local offsetX, offsetZ = (math.random() - 0.5) * (size.X - marginX), (math.random() - 0.5) * (size.Z - marginZ)
		local position = floor.CFrame * CFrame.new(offsetX, size.Y / 2 + 3, offsetZ)
		return position.Position, "floor"
	end
	return nil, nil
end

local function findTargetPositionAtSeat(tycoon)
	local seats = findSeats(tycoon)
	if #seats > 0 then
		local seat = seats[math.random(1, #seats)]
		local position = getPositionFromModel(seat)
		if position then
			return position, "sitting"
		end
	end
	return nil, nil
end

local function findRandomPositionNearNPC(npc)
	local rootPart = npc:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local currentPos = rootPart.Position
		local radius = math.random(5, 15)
		local angle = math.random() * math.pi * 2
		local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		return currentPos + offset, "random"
	end
	return nil, nil
end

local function findTargetPosition(npc)
	local npcsFolder = npc.Parent
	if not npcsFolder then return nil, nil end

	local tycoon = npcsFolder.Parent
	if not tycoon or not tycoon:IsA("Model") then return nil, nil end

	local targetPosition, targetType
	if math.random() < CONFIG.equipmentTargetChance then
		targetPosition, targetType = findTargetPositionForEquipment(tycoon) -- Send in tycoon
	end

	if not targetPosition then
		targetPosition, targetType = findTargetPositionOnFloor(tycoon)
	end

	if not targetPosition then
		targetPosition, targetType = findTargetPositionAtSeat(tycoon)
	end

	if not targetPosition then
		targetPosition, targetType = findRandomPositionNearNPC(npc)
	end

	return targetPosition, targetType
end

-- Function to make an NPC move to a target
local function moveNPCToTarget(npc, targetPosition)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	local rootPart = npc:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	-- Check if targetPosition is too far away
	local distance = (rootPart.Position - targetPosition).Magnitude
	if distance > CONFIG.maxPathfindingDistance then
		debug("Target too far for " .. npc.Name .. ": " .. math.floor(distance) .. " studs")
		return false
	end

	-- Calculate correct Y position with raycast
	local raycastResult = workspace:Raycast(
		targetPosition + Vector3.new(0, 10, 0),
		Vector3.new(0, -30, 0)
	)

	if raycastResult then
		targetPosition = Vector3.new(
			targetPosition.X,
			raycastResult.Position.Y + 3,
			targetPosition.Z
		)
	end

	-- Use pathfinding to navigate to the target
	local success = _followPath(npc, targetPosition)
	if success then
		debug(npc.Name .. " moving to new position: " .. tostring(targetPosition))
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

	-- Get NPC's specialization preference
	local preference = npc:GetAttribute("SpecializationPreference") or "no_preference"

	-- Check for nearby interactive elements first
	-- local interactiveElement = findNearestInteractiveElement(npc)
	-- if interactiveElement then
	-- 	interactWithElement(npc, interactiveElement) -- Interact if close enough
	-- 	return -- Skip normal movement this cycle
	-- end

	-- Decide whether to target equipment, a gym, or a random spot
	local targetPosition, targetType = findTargetPosition(npc)

	if targetPosition then
		local success = moveNPCToTarget(npc, targetPosition)
		if success then
			local stayTime = math.random(CONFIG.minStayTime, CONFIG.maxStayTime)
			npc:SetAttribute("NextMoveTime", os.time() + stayTime)
			npc:SetAttribute("TargetType", targetType)
		end
	end
end

-- Function to find a gym with a specific specialization
local function findGymBySpecialization(specialization)
	local SpecializationSystem = require(script.Parent.SpecializationSystem)
	local gyms = SpecializationSystem:getGyms()  -- Assuming this function exists
	local matchingGym
	-- Iterate through all models to find a tycoon with the right tag
	for _, model in pairs(workspace:GetDescendants()) do
		if model:IsA("Model") and CollectionService:HasTag(model, "Tycoon") and CollectionService:HasTag(model, "SpecializationType_" .. specialization) then
			matchingGym = model
			break
		end
	end
	return matchingGym
end


















































-- Function to find a path for the NPC
local function findPath(npc, targetPosition)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local rootPart = npc:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return nil end

	local startPosition = rootPart.Position
	if (startPosition - targetPosition).Magnitude > CONFIG.maxPathfindingDistance then
		return nil -- Target is too far, avoid pathfinding
	end

	local pathParams = {
		AgentRadius = 2,          -- Adjust as needed for NPC size
		AgentHeight = 5,
		AgentCanJump = false,     -- NPCs typically shouldn't jump
		WaypointSpacing = 5       -- Shorter for more precise paths
	}

	local path = PathfindingService:CreatePath(pathParams)
	local success, errorMessage = pcall(function()
		path:ComputeAsync(startPosition, targetPosition)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		return path
	else
		warn("Pathfinding failed for " .. npc.Name .. ": " .. (errorMessage or "Unknown error"))
		return nil
	end
end

-- Function to make the NPC follow a given path
local function followPath(npc, targetPosition)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	local path = findPath(npc, targetPosition)
	if not path then
		-- Fallback: If pathfinding fails, move directly to the target (might get stuck))\t
		humanoid:MoveTo(targetPosition)
		debug(npc.Name .. " moving directly to target (pathfinding failed). Target: " .. tostring(targetPosition))
		return true
	end

	local waypoints = path:GetWaypoints()
	if #waypoints == 0 then
		debug(npc.Name .. " no waypoints found in path.")
		return false
	end

	local function moveAlongWaypoints(waypointIndex)
		if not humanoid or not humanoid.Parent then return end -- NPC might be gone

		if waypointIndex <= #waypoints then
			local waypoint = waypoints[waypointIndex]
			humanoid:MoveTo(waypoint.Position)

			if waypointIndex < #waypoints then  -- If not the last waypoint
				humanoid.MoveToFinished:Wait()
				moveAlongWaypoints(waypointIndex + 1)  -- Recursively move to the next waypoint
			else
				-- Reached the final waypoint, now wander around it
				_wanderAroundPosition(npc, targetPosition, CONFIG.wanderRadius)
				debug(npc.Name .. " reached destination and is now wandering.")
			end
		end
	end

	moveAlongWaypoints(1)  -- Start moving from the first waypoint
	return true
end

-- Function to make the NPC wander around a position
local function _wanderAroundPosition(npc, center, radius)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local rootPart = npc:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return false end

	local wanderDuration = math.random(3, 7)  -- Wander for a bit
	local startTime = os.clock()

	while os.clock() - startTime < wanderDuration do
		local randomAngle = math.random() * 2 * math.pi
		local randomDistance = math.random() * radius

		local wanderPosition = center + Vector3.new(
			math.cos(randomAngle) * randomDistance,
			0,
			math.sin(randomAngle) * randomDistance
		)

		humanoid:MoveTo(wanderPosition)
		humanoid.MoveToFinished:Wait()
	end
end

-- Main update function to process all NPCs
local function updateNPCs()
	for _, player in pairs(Players:GetPlayers()) do
		local tycoon = player:FindFirstChild("Tycoon")
		if not tycoon or not tycoon.Value then continue end

		local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
		if not npcsFolder then continue end

		for _, npc in pairs(npcsFolder:GetChildren()) do
			if npc:IsA("Model") and npc:FindFirstChildOfClass("Humanoid") then
				checkNPCMovement(npc)
			end
		end
	end
end

-- Periodically clear the equipment cache
local function resetEquipmentCache()
	equipmentCache = {}
	debug("Equipment cache reset")
end

debug("Initializing Enhanced NPC Movement System...")


-- Start the update loop
spawn(function()
	while true do
		wait(CONFIG.updateFrequency)
		updateNPCs()
	end
end)

-- Schedule periodic cache resets
spawn(function()
	while true do
		wait(60) -- Reset cache every minute
		resetEquipmentCache()
	end
end)

-- Check and fix existing NPCs in the game
local function fixExistingNPCs()
	for _, player in pairs(Players:GetPlayers()) do
		local tycoon = player:FindFirstChild("Tycoon")
		if not tycoon or not tycoon.Value then continue end

		local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
		if not npcsFolder then continue end

		for _, npc in pairs(npcsFolder:GetChildren()) do
			if npc:IsA("Model") then
				if not npc:GetAttribute("NextMoveTime") then
					npc:SetAttribute("NextMoveTime", os.time() + math.random(5, 15))
				end

				-- Remove potentially conflicting scripts from older versions
				for _, script in pairs(npc:GetDescendants()) do
					if script:IsA("Script") and (
						script.Name == "nottooclose" or 
							script.Name:lower():find("movement") or
							script.Name:lower():find("wander")) then
						script:Destroy()
						debug("Removed old movement script: " .. script.Name .. " from " .. npc.Name)
					end
				end

				-- Ensure a Humanoid exists
				if not npc:FindFirstChildOfClass("Humanoid") then
					local humanoid = Instance.new("Humanoid")
					humanoid.WalkSpeed = 8
					humanoid.Parent = npc
					debug("Added missing Humanoid to: " .. npc.Name)
				end

				-- Ensure a HumanoidRootPart exists
				if not npc:FindFirstChild("HumanoidRootPart") then
					local rootPart = npc:FindFirstChild("Torso") or npc:FindFirstChild("UpperTorso")
					if rootPart and rootPart:IsA("BasePart") then
						rootPart.Name = "HumanoidRootPart" -- Rename existing part if suitable
						debug("Renamed " .. rootPart.Name .. " to HumanoidRootPart for: " .. npc.Name)
					else
						local hrp = Instance.new("Part")
						hrp.Name = "HumanoidRootPart"
						hrp.Size = Vector3.new(2, 2, 1)
						hrp.Transparency = 1
						hrp.CanCollide = false
						hrp.Position = npc:GetPivot().Position
						local primaryPart = npc.PrimaryPart
						if primaryPart then
							hrp.CFrame = primaryPart.CFrame
						end
						hrp.Parent = npc
					end
				end
			end
		end
	end
end

fixExistingNPCs()