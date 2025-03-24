-- Enhanced NPC Movement System
-- Place this in ServerScriptService
-- This script specifically manages NPC movement for better exploration

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")


-- Configuration
local CONFIG = {
	updateFrequency = 1,       -- How often to update NPCs (seconds)
	moveCheckFrequency = 10,   -- How often to check if NPCs should move (seconds)
	equipmentTargetChance = 0.7, -- Chance NPC will target equipment
	minStayTime = 15,          -- Min time at destination (seconds)
	maxStayTime = 45,          -- Max time at destination (seconds)
	maxPathfindingDistance = 100, -- Max distance for pathfinding
	debugEnabled = true        -- Show debug messages
}

-- Debug function
local function debug(...)
	if CONFIG.debugEnabled then
		print("[NPC Movement]", ...)
	end
end

debug("Initializing Enhanced NPC Movement System...")

-- Cache equipment in tycoons for faster targeting
local equipmentCache = {}

-- Function to find all equipment in a tycoon
local function cacheEquipment(tycoon)
	if equipmentCache[tycoon] then return equipmentCache[tycoon] end

	local equipment = {}

	-- Look for equipment models
	for _, descendant in pairs(tycoon:GetDescendants()) do
		-- Check if it's an equipment model by name keywords
		if descendant:IsA("Model") and 
			(descendant.Name:lower():find("treadmill") or
				descendant.Name:lower():find("weight") or
				descendant.Name:lower():find("bench") or
				descendant.Name:lower():find("machine") or
				descendant.Name:lower():find("equipment") or
				descendant.Name:lower():find("rack") or
				descendant:GetAttribute("IsEquipment")) then

			table.insert(equipment, descendant)
		end
	end

	-- Also look for parts that might be equipment
	if #equipment == 0 then
		for _, descendant in pairs(tycoon:GetDescendants()) do
			if descendant:IsA("BasePart") and
				(descendant.Name:lower():find("treadmill") or
					descendant.Name:lower():find("weight") or
					descendant.Name:lower():find("bench") or
					descendant.Name:lower():find("equipment")) then

				table.insert(equipment, descendant)
			end
		end
	end

	debug("Cached " .. #equipment .. " equipment pieces in " .. tycoon.Name)
	equipmentCache[tycoon] = equipment
	return equipment
end

-- Function to find floors in a tycoon
local function findFloors(tycoon)
	local floors = {}

	for _, descendant in pairs(tycoon:GetDescendants()) do
		if descendant:IsA("BasePart") and
			descendant.Size.X >= 8 and descendant.Size.Z >= 8 and
			math.abs(descendant.CFrame.UpVector.Y) > 0.9 and
			(descendant.Name:lower():find("floor") or
				descendant.Name:lower():find("platform") or
				descendant.Name:lower():find("ground") or
				descendant.Name == "Platform") then

			table.insert(floors, descendant)
		end
	end

	-- If no named floors found, use any large horizontal surface
	if #floors == 0 then
		for _, descendant in pairs(tycoon:GetDescendants()) do
			if descendant:IsA("BasePart") and
				descendant.Size.X >= 8 and descendant.Size.Z >= 8 and
				math.abs(descendant.CFrame.UpVector.Y) > 0.9 then

				table.insert(floors, descendant)
			end
		end
	end

	return floors
end

-- Function to find a good target position for an NPC
local function findTargetPosition(npc)
	-- Get the tycoon model
	local npcsFolder = npc.Parent
	if not npcsFolder then return nil end

	local tycoon = npcsFolder.Parent
	if not tycoon or not tycoon:IsA("Model") then return nil end
	local function findFloorsInTycoon(tycoonModel)
		local floors = {}

		-- Look for parts with specific attributes or names indicating floors
		for _, part in pairs(tycoonModel:GetDescendants()) do
			if part:IsA("BasePart") then
				-- Strict floor detection criteria
				if part.Size.X >= 10 and part.Size.Z >= 10 and 
					math.abs(part.CFrame.UpVector.Y) > 0.9 and 
					part.Size.Y < 2 then
					table.insert(floors, part)
				end
			end
		end

		return floors
	end
	-- Decide whether to target equipment or a random position
	local targetEquipment = math.random() < CONFIG.equipmentTargetChance

	if targetEquipment then
		-- Get cached equipment or cache it if needed
		local equipment = cacheEquipment(tycoon)

		if #equipment > 0 then
			-- Choose a random equipment
			local targetEquip = equipment[math.random(1, #equipment)]
			local targetPos

			-- Get position based on equipment type
			if targetEquip:IsA("Model") then
				if targetEquip.PrimaryPart then
					targetPos = targetEquip.PrimaryPart.Position
				else
					-- Find any part to use
					for _, part in pairs(targetEquip:GetDescendants()) do
						if part:IsA("BasePart") then
							targetPos = part.Position
							break
						end
					end
				end
			else
				-- It's a BasePart
				targetPos = targetEquip.Position
			end

			if targetPos then
				-- Add random offset around equipment
				local offsetX = math.random(-3, 3)
				local offsetZ = math.random(-3, 3)

				return targetPos + Vector3.new(offsetX, 0, offsetZ), "equipment"
			end
		end
	end

	-- If we get here, either we're not targeting equipment or we failed to find equipment
	-- Look for floors to walk on instead
	local floors = findFloors(tycoon)

	if #floors > 0 then
		-- Pick a random floor
		local floor = floors[math.random(1, #floors)]

		-- Get a random position on the floor
		local size = floor.Size
		local cf = floor.CFrame

		-- Keep away from edges
		local marginX = math.min(size.X * 0.4, 4)
		local marginZ = math.min(size.Z * 0.4, 4)

		local offsetX = (math.random() - 0.5) * (size.X - marginX)
		local offsetZ = (math.random() - 0.5) * (size.Z - marginZ)

		local targetPos = cf * CFrame.new(offsetX, size.Y/2 + 3, offsetZ)

		return targetPos.Position, "floor"
	end

	-- Last resort - wander randomly around current position
	local rootPart = npc:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local currentPos = rootPart.Position
		local radius = math.random(5, 15)
		local angle = math.random() * math.pi * 2

		return currentPos + Vector3.new(
			math.cos(angle) * radius,
			0,
			math.sin(angle) * radius
		), "random"
	end

	return nil, nil
end

-- Function to make an NPC move to a target
local function moveNPCToTarget(npc, targetPosition)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	local rootPart = npc:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	-- Check if targetPosition is too far away
	local distance = (targetPosition - rootPart.Position).Magnitude
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

	-- Move the NPC
	humanoid:MoveTo(targetPosition)
	debug(npc.Name .. " moving to new position: " .. tostring(targetPosition))

	return true
end

-- Function to check if an NPC should start moving
local function checkNPCMovement(npc)
	-- Skip if NPC is already moving
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Check if it's time to move
	local nextMoveTime = npc:GetAttribute("NextMoveTime") or 0
	if os.time() < nextMoveTime then return end

	-- Find a target position
	local targetPosition, targetType = findTargetPosition(npc)
	if not targetPosition then return end

	-- Move the NPC
	local success = moveNPCToTarget(npc, targetPosition)

	if success then
		-- Set the next move time
		local stayTime = math.random(CONFIG.minStayTime, CONFIG.maxStayTime)
		npc:SetAttribute("NextMoveTime", os.time() + stayTime)
		npc:SetAttribute("TargetType", targetType)

		-- Connect to MoveToFinished to handle arrival
		humanoid.MoveToFinished:Connect(function(reached)
			if reached then
				debug(npc.Name .. " reached destination: " .. (targetType or "unknown"))
			end
		end)
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

-- Function to reset the equipment cache periodically
local function resetEquipmentCache()
	equipmentCache = {}
	debug("Equipment cache reset")
end

-- Start the update loop
spawn(function()
	while true do
		wait(CONFIG.updateFrequency)
		updateNPCs()
	end
end)

-- Periodically reset the equipment cache to account for new equipment
spawn(function()
	while true do
		wait(60) -- Reset cache every minute
		resetEquipmentCache()
	end
end)

-- Fix any existing NPCs immediately
local function fixExistingNPCs()
	for _, player in pairs(Players:GetPlayers()) do
		local tycoon = player:FindFirstChild("Tycoon")
		if not tycoon or not tycoon.Value then continue end

		local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
		if not npcsFolder then continue end

		for _, npc in pairs(npcsFolder:GetChildren()) do
			if npc:IsA("Model") then
				-- Set initial NextMoveTime if missing
				if not npc:GetAttribute("NextMoveTime") then
					npc:SetAttribute("NextMoveTime", os.time() + math.random(5, 15))
				end

				-- Clear any existing movement scripts
				for _, script in pairs(npc:GetDescendants()) do
					if script:IsA("Script") and (
						script.Name == "nottooclose" or 
							script.Name:lower():find("movement") or
							script.Name:lower():find("wander")) then
						script:Destroy()
					end
				end

				-- Make sure humanoid exists
				if not npc:FindFirstChildOfClass("Humanoid") then
					local humanoid = Instance.new("Humanoid")
					humanoid.WalkSpeed = 8
					humanoid.Parent = npc
				end

				-- Make sure HumanoidRootPart exists
				if not npc:FindFirstChild("HumanoidRootPart") then
					-- Try to find a suitable part
					local foundPart = false
					for _, part in pairs(npc:GetDescendants()) do
						if part:IsA("BasePart") and 
							(part.Name:lower():find("root") or part.Name:lower():find("torso")) then
							part.Name = "HumanoidRootPart"
							foundPart = true
							break
						end
					end

					-- If no suitable part found, create one
					if not foundPart then
						local hrp = Instance.new("Part")
						hrp.Name = "HumanoidRootPart"
						hrp.Size = Vector3.new(2, 2, 1)
						hrp.Transparency = 1
						hrp.CanCollide = false
						hrp.Position = npc:GetPivot().Position
						hrp.Parent = npc
					end
				end
			end
		end
	end
end

-- Fix existing NPCs
fixExistingNPCs()

debug("Enhanced NPC Movement System initialized!")