-- Enhanced Decorative NPC System
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
	-- Spawning
	initialSpawnDelay = 10,       -- Seconds to wait after player joins
	spawnInterval = 45,           -- Seconds between NPC spawns

	-- Progression
	baseNPCCount = 3,             -- Start with this many NPCs
	maxNPCCount = 25,             -- Maximum NPCs per floor
	equipmentRequiredForNextNPC = 2, -- Equipment pieces needed per additional NPC

	-- Movement
	wanderRadius = 20,            -- How far NPCs will wander from their starting point
	minMoveDelay = 15,            -- Minimum seconds NPCs wait before moving
	maxMoveDelay = 45,            -- Maximum seconds NPCs wait before moving
	moveSpeed = 5,                -- Walking speed of NPCs

	-- Seat usage
	seatCheckRadius = 12,         -- How far NPCs check for available seats
	minSeatTime = 30,             -- Minimum seconds NPCs sit
	maxSeatTime = 180,            -- Maximum seconds NPCs sit
	seatSearchInterval = 20,      -- How often NPCs look for seats
	seatProbability = 0.7,        -- Probability an NPC will sit when finding a seat

	-- Appearance
	npcScaleMin = 0.9,            -- Minimum scale for NPCs
	npcScaleMax = 1.1,            -- Maximum scale for NPCs

	-- Debug
	debugMode = true,             -- Show debug prints
}

-- Debug function
local function debugPrint(...)
	if CONFIG.debugMode then
		print("[Decorative NPC System]", ...)
	end
end

-- Startup delay to let everything load
task.wait(5)
debugPrint("Initializing Decorative NPC System...")

-- Get max NPCs based on equipment count
local function getMaxNPCs(player)
	-- Get equipment count
	local tycoon = player:FindFirstChild("Tycoon")
	local equipmentCount = 0

	if tycoon then
		equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
	end

	-- Calculate max NPCs based on equipment
	local maxNPCs = CONFIG.baseNPCCount + math.floor(equipmentCount / CONFIG.equipmentRequiredForNextNPC)

	-- Cap at the absolute maximum
	return math.min(maxNPCs, CONFIG.maxNPCCount)
end

-- Count current NPCs for a player
local function countNPCs(player)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then return 0 end

	local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
	if not npcsFolder then return 0 end

	return #npcsFolder:GetChildren()
end

-- Find a suitable spawn position
local function findSpawnPosition(tycoon)
	-- Try to find spawn points first (for better control)
	local spawnPoints = tycoon:FindFirstChild("NPCSpawnPoints")
	if spawnPoints and #spawnPoints:GetChildren() > 0 then
		local points = spawnPoints:GetChildren()
		local chosenPoint = points[math.random(1, #points)]
		return chosenPoint.Position + Vector3.new(0, 3, 0)
	end

	-- Try to use platform
	local platform = tycoon:FindFirstChild("Platform")
	if platform and platform:IsA("BasePart") then
		return platform.Position + Vector3.new(math.random(-8, 8), 3, math.random(-8, 8))
	end

	-- Find any floor parts
	local floorParts = {}
	for _, part in pairs(tycoon:GetDescendants()) do
		if part:IsA("BasePart") and 
			string.lower(part.Name):find("floor") or
			(part.Size.X > 8 and part.Size.Z > 8 and math.abs(part.CFrame.UpVector.Y) > 0.9) then
			table.insert(floorParts, part)
		end
	end

	if #floorParts > 0 then
		local chosenFloor = floorParts[math.random(1, #floorParts)]
		return chosenFloor.Position + Vector3.new(math.random(-5, 5), 3, math.random(-5, 5))
	end

	-- Last resort
	return tycoon:GetPivot().Position + Vector3.new(0, 5, 0)
end

-- Find a good wander position
local function findWanderPosition(npc)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	local rootPart = npc:FindFirstChild("HumanoidRootPart")
	if not rootPart then return nil end

	-- Get tycoon model
	local tycoon = npc.Parent and npc.Parent.Parent
	if not tycoon or not tycoon:IsA("Model") then return nil end

	-- Choose a random direction and distance
	local angle = math.random() * math.pi * 2
	local distance = math.random(5, CONFIG.wanderRadius)

	-- Calculate the target position
	local startPos = rootPart.Position
	local targetPos = startPos + Vector3.new(
		math.cos(angle) * distance,
		0,
		math.sin(angle) * distance
	)

	-- Raycast to find floor
	local raycastResult = workspace:Raycast(
		targetPos + Vector3.new(0, 10, 0),
		Vector3.new(0, -30, 0)
	)

	if raycastResult and raycastResult.Instance:IsDescendantOf(tycoon) then
		return Vector3.new(targetPos.X, raycastResult.Position.Y + 3, targetPos.Z)
	end

	-- If no floor found, stay close to current position
	return startPos + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
end

-- Find nearby seats for NPCs to sit on
local function findNearbySeats(npc)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	local rootPart = npc:FindFirstChild("HumanoidRootPart")
	if not rootPart then return nil end

	-- Get tycoon model
	local tycoon = npc.Parent and npc.Parent.Parent
	if not tycoon or not tycoon:IsA("Model") then return nil end

	-- Find all seats within range
	local availableSeats = {}

	for _, desc in pairs(tycoon:GetDescendants()) do
		-- Check for actual Seats or parts with "seat", "bench", etc. in name
		local isSeat = desc:IsA("Seat") or desc:IsA("VehicleSeat") or 
			(desc:IsA("Part") and (
				string.lower(desc.Name):find("seat") or
				string.lower(desc.Name):find("bench") or
				string.lower(desc.Name):find("chair")))

		if isSeat then
			-- Check if seat is already occupied
			local occupied = false
			for _, sitter in pairs(Players:GetPlayers()) do
				if sitter.Character and sitter.Character:IsA("Model") then
					if desc.Occupant == sitter.Character:FindFirstChildOfClass("Humanoid") then
						occupied = true
						break
					end
				end
			end

			for _, otherNPC in pairs(tycoon:FindFirstChild("NPCs"):GetChildren()) do
				if otherNPC ~= npc and otherNPC:GetAttribute("SittingOn") == desc:GetFullName() then
					occupied = true
					break
				end
			end

			-- Check distance
			if not occupied then
				local distance = (desc.Position - rootPart.Position).Magnitude
				if distance <= CONFIG.seatCheckRadius then
					table.insert(availableSeats, desc)
				end
			end
		end
	end

	if #availableSeats > 0 then
		return availableSeats[math.random(1, #availableSeats)]
	end

	return nil
end

-- Make an NPC sit on a seat
local function sitOnSeat(npc, seat)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	-- Stop current movement and set state
	npc:SetAttribute("CurrentAction", "GoingToSeat")

	-- First walk to the seat
	humanoid:MoveTo(seat.Position)

	-- Wait for NPC to reach the seat
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local rootPart = npc:FindFirstChild("HumanoidRootPart")
		if not rootPart or not seat or not seat.Parent then
			if connection then connection:Disconnect() end
			return
		end

		local distance = (rootPart.Position - seat.Position).Magnitude
		if distance < 4 then
			connection:Disconnect()

			-- Now sit on the seat
			if seat:IsA("Seat") or seat:IsA("VehicleSeat") then
				-- Use built-in sitting for actual Seats
				humanoid.Sit = true
				task.wait(0.2)
				seat:Sit(humanoid)
				npc:SetAttribute("SittingOn", seat:GetFullName())
				npc:SetAttribute("CurrentAction", "Sitting")
				debugPrint("NPC " .. npc.Name .. " is now sitting on " .. seat.Name)

				-- Set a timer to get up
				local sitTime = math.random(CONFIG.minSeatTime, CONFIG.maxSeatTime)
				task.delay(sitTime, function()
					if npc and npc.Parent and humanoid then
						humanoid.Jump = true
						humanoid.Sit = false
						npc:SetAttribute("SittingOn", nil)
						npc:SetAttribute("CurrentAction", "Idle")
						npc:SetAttribute("NextMoveTime", os.time() + math.random(5, 15))
						debugPrint("NPC " .. npc.Name .. " got up from " .. seat.Name)
					end
				end)
			else
				-- For parts that aren't actual seats, position NPC on top with sit animation
				local cf = seat.CFrame * CFrame.new(0, seat.Size.Y/2 + 1, 0)
				rootPart.CFrame = cf

				-- Try to play a sitting animation if available
				local animation = Instance.new("Animation")
				animation.AnimationId = "rbxassetid://4097910771" -- Generic sitting animation
				local animTrack = humanoid:LoadAnimation(animation)
				animTrack:Play()

				-- Store animation track and other sitting info
				npc:SetAttribute("SittingOn", seat:GetFullName())
				npc:SetAttribute("SittingAnimTrack", animTrack)
				npc:SetAttribute("CurrentAction", "Sitting")
				debugPrint("NPC " .. npc.Name .. " is now positioned on " .. seat.Name)

				-- Set a timer to get up
				local sitTime = math.random(CONFIG.minSeatTime, CONFIG.maxSeatTime)
				task.delay(sitTime, function()
					if npc and npc.Parent then
						if animTrack then
							animTrack:Stop()
							animation:Destroy()
						end
						npc:SetAttribute("SittingOn", nil)
						npc:SetAttribute("SittingAnimTrack", nil)
						npc:SetAttribute("CurrentAction", "Idle")
						npc:SetAttribute("NextMoveTime", os.time() + math.random(5, 15))
						debugPrint("NPC " .. npc.Name .. " got up from " .. seat.Name)
					end
				end)
			end

			return true
		end
	end)

	-- In case something goes wrong, clean up after a timeout
	task.delay(10, function()
		if connection then
			connection:Disconnect()
			npc:SetAttribute("CurrentAction", "Idle")
		end
	end)

	return true
end

-- Spawn a single NPC
local function spawnNPC(player)
	debugPrint("Attempting to spawn NPC for " .. player.Name)

	-- Check if player has a tycoon
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then
		debugPrint("No tycoon found for " .. player.Name)
		return nil
	end

	-- Create NPCs folder if needed
	local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
	if not npcsFolder then
		npcsFolder = Instance.new("Folder")
		npcsFolder.Name = "NPCs"
		npcsFolder.Parent = tycoon.Value
		debugPrint("Created NPCs folder for " .. player.Name)
	end

	-- Check if at or above max NPCs for this player's progression
	local currentNPCs = countNPCs(player)
	local maxNPCs = getMaxNPCs(player)

	if currentNPCs >= maxNPCs then
		debugPrint(player.Name .. " has reached NPC limit: " .. currentNPCs .. "/" .. maxNPCs)
		return nil
	end

	-- Get NPC template
	local npcFolder = ServerStorage:FindFirstChild("NPC_Character")
	if not npcFolder or #npcFolder:GetChildren() == 0 then
		debugPrint("No NPC models found in ServerStorage")
		return nil
	end

	-- Select a random model
	local models = npcFolder:GetChildren()
	local modelTemplate = models[math.random(1, #models)]
	debugPrint("Selected model: " .. modelTemplate.Name)

	-- Clone the model
	local npc = modelTemplate:Clone()

	-- Give it a name with random activity
	local activities = {
		"Exerciser", "Member", "Trainer", "Athlete", "Visitor", 
		"Fitness", "Runner", "Lifter", "Client", "Guest"
	}
	local activity = activities[math.random(1, #activities)]
	npc.Name = activity .. "_" .. math.random(1000, 9999)

	-- Find spawn position
	local spawnPos = findSpawnPosition(tycoon.Value)

	-- Set up humanoid
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		humanoid.Parent = npc
	end

	-- Set walk speed
	humanoid.WalkSpeed = CONFIG.moveSpeed

	-- Make sure HumanoidRootPart exists
	local hrp = npc:FindFirstChild("HumanoidRootPart") 
	if not hrp then
		-- Find an existing part to rename
		for _, part in pairs(npc:GetDescendants()) do
			if part:IsA("BasePart") and 
				(part.Name:lower():find("root") or part.Name:lower():find("torso")) then
				part.Name = "HumanoidRootPart"
				hrp = part
				break
			end
		end

		-- If no suitable part found, create one
		if not hrp then
			hrp = Instance.new("Part")
			hrp.Name = "HumanoidRootPart"
			hrp.Size = Vector3.new(2, 2, 1)
			hrp.Transparency = 1
			hrp.CanCollide = false

			-- Find a part to position next to
			local refPart = nil
			for _, part in pairs(npc:GetDescendants()) do
				if part:IsA("BasePart") then
					refPart = part
					break
				end
			end

			if refPart then
				hrp.CFrame = refPart.CFrame
			else
				hrp.Position = spawnPos
			end

			hrp.Parent = npc
		end
	end

	-- Position the NPC
	if hrp then
		hrp.CFrame = CFrame.new(spawnPos)
	end

	-- Randomize the NPC scale slightly
	local scale = math.random() * (CONFIG.npcScaleMax - CONFIG.npcScaleMin) + CONFIG.npcScaleMin
	for _, part in pairs(npc:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Size = part.Size * scale

			-- Disable collision with players but allow collision with environment
			part.CanCollide = part.Name ~= "HumanoidRootPart"

			-- Try to use collision groups if possible
			pcall(function()
				part.CollisionGroup = "NPCs"
			end)
		end
	end

	-- Remove any existing scripts that might interfere with movement
	for _, script in pairs(npc:GetDescendants()) do
		if script:IsA("Script") or script:IsA("LocalScript") then
			script:Destroy()
		end
	end

	-- Set attributes for NPC behavior
	npc:SetAttribute("NextMoveTime", os.time() + math.random(CONFIG.minMoveDelay, CONFIG.maxMoveDelay))
	npc:SetAttribute("NextSeatCheckTime", os.time() + math.random(10, CONFIG.seatSearchInterval))
	npc:SetAttribute("HomePosition", spawnPos)
	npc:SetAttribute("CurrentAction", "Idle")
	npc:SetAttribute("SittingOn", nil)

	-- Parent the NPC
	npc.Parent = npcsFolder

	debugPrint("Successfully spawned NPC " .. npc.Name .. " for " .. player.Name)
	return npc
end

-- Function to update NPC behaviors
local function updateNPCBehaviors()
	for _, player in pairs(Players:GetPlayers()) do
		local tycoon = player:FindFirstChild("Tycoon")
		if not tycoon or not tycoon.Value then continue end

		local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
		if not npcsFolder then continue end

		for _, npc in pairs(npcsFolder:GetChildren()) do
			-- Skip if not a valid NPC
			if not npc:IsA("Model") or not npc:FindFirstChildOfClass("Humanoid") then continue end

			-- Skip if NPC is already performing an action
			local currentAction = npc:GetAttribute("CurrentAction")
			if currentAction == "GoingToSeat" or currentAction == "Sitting" then continue end

			-- Check if it's time to look for a seat
			local nextSeatCheck = npc:GetAttribute("NextSeatCheckTime") or 0
			if os.time() >= nextSeatCheck then
				-- Reset the seat check timer
				npc:SetAttribute("NextSeatCheckTime", os.time() + math.random(10, CONFIG.seatSearchInterval))

				-- Only try to sit if probability check passes
				if math.random() <= CONFIG.seatProbability then
					local seat = findNearbySeats(npc)
					if seat then
						sitOnSeat(npc, seat)
						continue -- Skip movement check
					end
				end
			end

			-- Check if it's time to move
			local nextMoveTime = npc:GetAttribute("NextMoveTime") or 0
			if os.time() >= nextMoveTime then
				-- Get a new destination
				local destination = findWanderPosition(npc)
				if destination then
					-- Move the NPC
					local humanoid = npc:FindFirstChildOfClass("Humanoid")
					humanoid:MoveTo(destination)

					-- Set the next move time
					npc:SetAttribute("NextMoveTime", os.time() + math.random(CONFIG.minMoveDelay, CONFIG.maxMoveDelay))
					npc:SetAttribute("CurrentAction", "Walking")

					-- Check when reached destination
					task.spawn(function()
						local startTime = os.time()
						while true do
							task.wait(0.5)
							if os.time() - startTime > 30 then break end -- Timeout after 30 seconds

							if not npc or not npc.Parent then break end
							if npc:GetAttribute("CurrentAction") ~= "Walking" then break end

							-- Check if NPC reached destination
							local hrp = npc:FindFirstChild("HumanoidRootPart")
							if hrp and (hrp.Position - destination).Magnitude < 3 then
								npc:SetAttribute("CurrentAction", "Idle")
								break
							end
						end
					end)
				end
			end
		end
	end
end

-- Function to spawn initial NPCs for a player
local function spawnInitialNPCs(player)
	task.wait(CONFIG.initialSpawnDelay) -- Wait for tycoon to be ready

	local maxInitialNPCs = getMaxNPCs(player)
	debugPrint("Spawning " .. maxInitialNPCs .. " initial NPCs for " .. player.Name)

	for i = 1, maxInitialNPCs do
		spawnNPC(player)
		task.wait(0.5) -- Space out spawns
	end
end

-- Function to progressively spawn NPCs over time
local function startProgressiveSpawning()
	while true do
		task.wait(CONFIG.spawnInterval)

		for _, player in pairs(Players:GetPlayers()) do
			-- Only attempt to spawn if player has room for more NPCs
			local currentNPCs = countNPCs(player)
			local maxNPCs = getMaxNPCs(player)

			if currentNPCs < maxNPCs then
				spawnNPC(player)
			end
		end
	end
end

-- Set up NPC behavior update loop
task.spawn(function()
	while true do
		task.wait(0.5)
		updateNPCBehaviors()
	end
end)

-- Connect player events
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		spawnInitialNPCs(player)
	end)

	-- Track equipment purchases to potentially spawn more NPCs
	local function checkEquipment()
		local tycoon = player:FindFirstChild("Tycoon")
		if tycoon then
			tycoon.AttributeChanged:Connect(function(attribute)
				if attribute == "EquipmentCount" then
					-- Check if player can have more NPCs now
					local currentNPCs = countNPCs(player)
					local maxNPCs = getMaxNPCs(player)

					if currentNPCs < maxNPCs then
						-- Try to spawn a new NPC with the new equipment count
						task.wait(3) -- Wait a bit for equipment to be placed
						spawnNPC(player)
					end
				end
			end)
		else
			-- If tycoon isn't ready yet, try again soon
			task.delay(5, checkEquipment)
		end
	end

	checkEquipment()
end)

-- Initialize for existing players
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		spawnInitialNPCs(player)
	end)
end

-- Create CollisionGroup for NPCs if it doesn't exist
pcall(function()
	local PhysicsService = game:GetService("PhysicsService")

	-- Try to create collision group for NPCs
	if not pcall(function() PhysicsService:GetCollisionGroupId("NPCs") end) then
		PhysicsService:CreateCollisionGroup("NPCs")
		PhysicsService:CollisionGroupSetCollidable("NPCs", "Players", false)
	end
end)

-- Start progressive spawning
task.spawn(startProgressiveSpawning)

debugPrint("Decorative NPC System initialized")

-- Return the API
return {
	spawnNPC = spawnNPC,
	getMaxNPCs = getMaxNPCs,
	countNPCs = countNPCs
}