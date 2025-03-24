-- Simplified NPC System
-- Place in ServerScriptService
-- Handles NPC creation, movement, and income generation

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local TweenService = game:GetService("TweenService")


-- Configuration
local CONFIG = {
	-- NPC creation
	npcFolderName = "NPC_Character",      -- Folder in ServerStorage containing NPC models
	maxNPCsPerGym = 15,                   -- Maximum NPCs per player gym
	spawnInterval = 60,                   -- How often to check for spawning new NPCs (seconds)
	initialNPCCount = {min = 2, max = 4}, -- Initial NPC count range

	-- Income generation
	baseIncomeAmount = 15,                -- Base income per NPC
	vipChance = 0.1,                      -- Chance for VIP NPCs (10%)
	vipMultiplier = 3,                    -- Income multiplier for VIP NPCs

	-- Movement
	moveSpeed = 8,                        -- NPC walking speed
	minStayTime = 10,                     -- Min time at a destination (seconds)
	maxStayTime = 30,                     -- Max time at a destination (seconds)
	equipmentTargetChance = 0.7,          -- Chance NPC will target gym equipment
	wanderRadius = 15,                    -- Maximum wander distance

	-- Visual effects
	spawnEffectEnabled = true,            -- Whether to show spawn effects

	-- Debug
	debug = true                          -- Enable debug messages
}

-- Debug function
local function debugPrint(...)
	if CONFIG.debug then
		print("[NPC System]", ...)
	end
end

debugPrint("Initializing NPC System...")

-- Create module table
local NPCSystem = {}

-- Setup collision groups
local function setupCollisionGroups()
	debugPrint("Setting up collision groups...")

	-- Use pcall to handle potential errors
	local success = pcall(function()
		-- Check if groups already exist
		local npcGroupExists = PhysicsService:CollisionGroupExists("NPCs")
		local playerGroupExists = PhysicsService:CollisionGroupExists("Players")

		if not npcGroupExists then
			PhysicsService:RegisterCollisionGroup("NPCs")
			debugPrint("Created 'NPCs' collision group")
		end

		if not playerGroupExists then
			PhysicsService:RegisterCollisionGroup("Players")
			debugPrint("Created 'Players' collision group")
		end

		-- Set collision behavior
		PhysicsService:CollisionGroupSetCollidable("NPCs", "Players", false)
		debugPrint("Set NPCs and Players to not collide")
	end)

	if not success then
		debugPrint("Failed to set up collision groups. Using fallback method.")

		-- Fallback: Make NPCs non-collidable with other objects
		for _, player in pairs(Players:GetPlayers()) do
			local tycoon = player:FindFirstChild("Tycoon")
			if tycoon and tycoon.Value then
				local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
				if npcsFolder then
					for _, npc in pairs(npcsFolder:GetChildren()) do
						for _, part in pairs(npc:GetDescendants()) do
							if part:IsA("BasePart") then
								part.CanCollide = false
							end
						end
					end
				end
			end
		end
	end

	return success
end

-- Verify that the NPC character folder exists, or create it
local function verifyNPCFolder()
	local npcFolder = ServerStorage:FindFirstChild(CONFIG.npcFolderName)

	if not npcFolder then
		debugPrint("NPC folder not found, creating it")
		npcFolder = Instance.new("Folder")
		npcFolder.Name = CONFIG.npcFolderName
		npcFolder.Parent = ServerStorage

		-- Create a default NPC model if none exists
		local defaultNPC = Instance.new("Model")
		defaultNPC.Name = "DefaultNPC"

		-- Add humanoid
		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = defaultNPC

		-- Add humanoid root part
		local hrp = Instance.new("Part")
		hrp.Name = "HumanoidRootPart"
		hrp.Size = Vector3.new(2, 2, 1)
		hrp.Transparency = 1
		hrp.CanCollide = false
		hrp.Parent = defaultNPC

		-- Add head
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Shape = Enum.PartType.Ball
		head.Size = Vector3.new(2, 2, 2)
		head.Position = hrp.Position + Vector3.new(0, 2, 0)
		head.BrickColor = BrickColor.new("Bright yellow")
		head.Parent = defaultNPC

		-- Add torso
		local torso = Instance.new("Part")
		torso.Name = "Torso"
		torso.Size = Vector3.new(2, 2, 1)
		torso.Position = hrp.Position + Vector3.new(0, 0, 0)
		torso.BrickColor = BrickColor.new("Bright blue")
		torso.Parent = defaultNPC

		defaultNPC.PrimaryPart = hrp
		defaultNPC.Parent = npcFolder

		debugPrint("Created default NPC model in " .. CONFIG.npcFolderName)
	elseif #npcFolder:GetChildren() == 0 then
		debugPrint("NPC folder exists but is empty, creating default NPC")

		-- Create a default NPC model
		local defaultNPC = Instance.new("Model")
		defaultNPC.Name = "DefaultNPC"

		-- Add humanoid
		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = defaultNPC

		-- Add humanoid root part
		local hrp = Instance.new("Part")
		hrp.Name = "HumanoidRootPart"
		hrp.Size = Vector3.new(2, 2, 1)
		hrp.Transparency = 1
		hrp.CanCollide = false
		hrp.Parent = defaultNPC

		-- Add head
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Shape = Enum.PartType.Ball
		head.Size = Vector3.new(2, 2, 2)
		head.Position = hrp.Position + Vector3.new(0, 2, 0)
		head.BrickColor = BrickColor.new("Bright yellow")
		head.Parent = defaultNPC

		-- Add torso
		local torso = Instance.new("Part")
		torso.Name = "Torso"
		torso.Size = Vector3.new(2, 2, 1)
		torso.Position = hrp.Position + Vector3.new(0, 0, 0)
		torso.BrickColor = BrickColor.new("Bright blue")
		torso.Parent = defaultNPC

		defaultNPC.PrimaryPart = hrp
		defaultNPC.Parent = npcFolder
	end

	return npcFolder
end

-- Count NPCs for a player
local function countNPCs(player)
	if not player then return 0 end

	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then return 0 end

	local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
	if not npcsFolder then return 0 end

	return #npcsFolder:GetChildren()
end

-- Find a spawn position for an NPC
local function findSpawnPosition(tycoonModel)
	if not tycoonModel then return Vector3.new(0, 5, 0) end

	-- Try to use platform
	local platform = tycoonModel:FindFirstChild("Platform")
	if platform and platform:IsA("BasePart") then
		return platform.Position + Vector3.new(math.random(-8, 8), 3, math.random(-8, 8))
	end

	-- If no platform, find any suitable part
	for _, part in pairs(tycoonModel:GetDescendants()) do
		if part:IsA("BasePart") and 
			part.Size.X > 8 and part.Size.Z > 8 and
			math.abs(part.CFrame.UpVector.Y) > 0.9 then
			return part.Position + Vector3.new(math.random(-5, 5), 3, math.random(-5, 5))
		end
	end

	-- Last resort
	return tycoonModel:GetPivot().Position + Vector3.new(0, 5, 0)
end

-- Find equipment in a tycoon
local function findEquipmentInTycoon(tycoonModel)
	local equipment = {}

	-- Search for equipment models
	for _, model in pairs(tycoonModel:GetDescendants()) do
		-- Check for common equipment names or attributes
		if (model:IsA("Model") or model:IsA("BasePart")) and 
			(string.lower(model.Name):find("treadmill") or
				string.lower(model.Name):find("weight") or
				string.lower(model.Name):find("bench") or
				string.lower(model.Name):find("machine") or
				string.lower(model.Name):find("equipment") or
				model:GetAttribute("IsEquipment")) then
			table.insert(equipment, model)
		end
	end

	return equipment
end

-- Generate unique NPC name
local function generateNPCName(isVIP)
	local prefixes = {"Gym", "Fitness", "Health", "Power", "Iron", "Muscle"}
	local suffixes = {"Member", "User", "Fan", "Enthusiast", "Pro", "Expert"}

	if isVIP then
		prefixes = {"VIP", "Elite", "Premium", "Gold", "Deluxe", "Champion"}
	end

	local prefix = prefixes[math.random(1, #prefixes)]
	local suffix = suffixes[math.random(1, #suffixes)]
	local number = tostring(math.random(1000, 9999))

	return prefix .. "_" .. suffix .. "_" .. number
end

-- Find a destination for an NPC to move to
local function findNPCDestination(npc, tycoonModel)
	if not npc or not tycoonModel then return nil end

	-- Get current position
	local currentPosition
	if npc:FindFirstChild("HumanoidRootPart") then
		currentPosition = npc.HumanoidRootPart.Position
	else
		currentPosition = npc:GetPivot().Position
	end

	-- Decide if we should target equipment
	local shouldTargetEquipment = math.random() <= CONFIG.equipmentTargetChance

	if shouldTargetEquipment then
		-- Find equipment in the tycoon
		local equipment = findEquipmentInTycoon(tycoonModel)

		if #equipment > 0 then
			-- Choose a random piece of equipment
			local targetEquipment = equipment[math.random(1, #equipment)]

			-- Get position of the equipment
			local equipmentPosition

			if targetEquipment:IsA("Model") and targetEquipment.PrimaryPart then
				equipmentPosition = targetEquipment.PrimaryPart.Position
			elseif targetEquipment:IsA("BasePart") then
				equipmentPosition = targetEquipment.Position
			else
				-- Find any part
				for _, part in pairs(targetEquipment:GetDescendants()) do
					if part:IsA("BasePart") then
						equipmentPosition = part.Position
						break
					end
				end
			end

			if equipmentPosition then
				-- Add a small random offset to prevent NPCs from stacking
				local offsetX = (math.random() - 0.5) * 4
				local offsetZ = (math.random() - 0.5) * 4
				return equipmentPosition + Vector3.new(offsetX, 0, offsetZ)
			end
		end
	end

	-- Fallback to random wandering
	local radius = math.random(5, CONFIG.wanderRadius)
	local angle = math.random() * math.pi * 2
	local offsetX = math.cos(angle) * radius
	local offsetZ = math.sin(angle) * radius

	return currentPosition + Vector3.new(offsetX, 0, offsetZ)
end

-- Create an NPC
function NPCSystem.createNPC(spawnPosition, tycoonModel, player, isVIP)
	if not player or not tycoonModel then return nil end

	-- Determine if NPC should be VIP if not specified
	if isVIP == nil then
		isVIP = math.random() < CONFIG.vipChance
	end

	-- Get NPC folder
	local npcFolder = verifyNPCFolder()
	if not npcFolder or #npcFolder:GetChildren() == 0 then
		debugPrint("NPC folder is empty or invalid")
		return nil
	end

	-- Get a random NPC model
	local templates = npcFolder:GetChildren()
	local modelTemplate = templates[math.random(1, #templates)]

	-- Clone the model
	local npc = modelTemplate:Clone()

	-- Set NPC name
	local npcName = generateNPCName(isVIP)
	npc.Name = npcName

	-- Make sure it has a humanoid
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		humanoid.Parent = npc
	end

	-- Set walk speed
	humanoid.WalkSpeed = CONFIG.moveSpeed

	-- Make sure it has a HumanoidRootPart
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	if not hrp then
		-- Create a root part if missing
		hrp = Instance.new("Part")
		hrp.Name = "HumanoidRootPart"
		hrp.Size = Vector3.new(2, 2, 1)
		hrp.Transparency = 1
		hrp.CanCollide = false

		-- Find a part to position relative to
		local refPart
		for _, part in pairs(npc:GetDescendants()) do
			if part:IsA("BasePart") then
				refPart = part
				break
			end
		end

		if refPart then
			hrp.CFrame = refPart.CFrame
		else
			hrp.Position = spawnPosition
		end

		hrp.Parent = npc
	end

	-- Set Position
	hrp.CFrame = CFrame.new(spawnPosition)

	-- Update collision groups
	for _, part in pairs(npc:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Try to set collision group
			pcall(function()
				part.CollisionGroup = "NPCs"
			end)

			-- Always make HRP non-collidable
			if part.Name == "HumanoidRootPart" then
				part.CanCollide = false
			end
		end
	end

	-- Apply VIP appearance if needed
	if isVIP then
		-- Create a VIP badge
		local badge = Instance.new("BillboardGui")
		badge.Name = "VIPBadge"
		badge.Size = UDim2.new(0, 100, 0, 30)
		badge.StudsOffset = Vector3.new(0, 3, 0)
		badge.AlwaysOnTop = true

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.new(1, 0, 1, 0)
		badgeLabel.BackgroundTransparency = 0.5
		badgeLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		badgeLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
		badgeLabel.Font = Enum.Font.GothamBold
		badgeLabel.Text = "★ VIP ★"
		badgeLabel.TextScaled = true
		badgeLabel.Parent = badge

		badge.Parent = hrp
	end

	-- Set attributes for income generation
	local membershipFee = isVIP 
		and CONFIG.baseIncomeAmount * CONFIG.vipMultiplier 
		or CONFIG.baseIncomeAmount

	npc:SetAttribute("MembershipFee", membershipFee)
	npc:SetAttribute("LastPaid", os.time())
	npc:SetAttribute("IsVIP", isVIP)
	npc:SetAttribute("NextMoveTime", os.time() + math.random(CONFIG.minStayTime, CONFIG.maxStayTime))
	npc:SetAttribute("OwnerUserId", player.UserId)

	-- Create NPCs folder if it doesn't exist
	local npcsFolder = tycoonModel:FindFirstChild("NPCs")
	if not npcsFolder then
		npcsFolder = Instance.new("Folder")
		npcsFolder.Name = "NPCs"
		npcsFolder.Parent = tycoonModel
	end

	-- Create spawn effect if enabled
	if CONFIG.spawnEffectEnabled then
		-- Create effect part
		local effect = Instance.new("Part")
		effect.Size = Vector3.new(1, 1, 1)
		effect.Anchored = true
		effect.CanCollide = false
		effect.Transparency = 0.5
		effect.Shape = Enum.PartType.Ball
		effect.Material = Enum.Material.Neon
		effect.BrickColor = isVIP and BrickColor.new("Bright yellow") or BrickColor.new("Bright blue")
		effect.Position = spawnPosition
		effect.Parent = workspace

		-- Animate the effect
		task.spawn(function()
			for i = 1, 10 do
				effect.Size = Vector3.new(i/2, i/2, i/2)
				effect.Transparency = 0.5 + (i * 0.05)
				task.wait(0.05)
			end
			effect:Destroy()
		end)
	end

	-- Parent the NPC
	npc.Parent = npcsFolder

	debugPrint("Created " .. (isVIP and "VIP " or "") .. "NPC " .. npcName .. " for " .. player.Name)
	return npc
end

-- Update an NPC's movement
local function updateNPCMovement(npc)
	if not npc or not npc.Parent then return end

	-- Get references to humanoid and root part
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local rootPart = npc:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then return end

	-- Check if it's time to move
	local nextMoveTime = npc:GetAttribute("NextMoveTime") or 0
	if os.time() < nextMoveTime then return end

	-- Get the tycoon model
	local tycoonModel = npc.Parent.Parent
	if not tycoonModel or not tycoonModel:IsA("Model") then return end

	-- Find a destination
	local destination = findNPCDestination(npc, tycoonModel)
	if not destination then return end

	-- Move to the destination
	humanoid:MoveTo(destination)

	-- Set next move time
	npc:SetAttribute("NextMoveTime", os.time() + math.random(CONFIG.minStayTime, CONFIG.maxStayTime))
end

-- Update all NPCs for a player
local function updatePlayerNPCs(player)
	if not player then return end

	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then return end

	local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
	if not npcsFolder then return end

	for _, npc in pairs(npcsFolder:GetChildren()) do
		if npc:IsA("Model") then
			-- Use pcall to prevent one NPC error from affecting others
			pcall(function()
				updateNPCMovement(npc)
			end)
		end
	end
end

-- Try to spawn an NPC for a player
function NPCSystem.trySpawnNPC(player)
	if not player then return nil end

	-- Make sure the player has a valid tycoon
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then 
		debugPrint("Player has no tycoon:", player.Name)
		return nil 
	end

	-- Check if at max NPCs
	local currentNPCCount = countNPCs(player)
	if currentNPCCount >= CONFIG.maxNPCsPerGym then 
		debugPrint("Max NPCs reached for player:", player.Name)
		return nil 
	end

	-- Find a spawn position
	local spawnPosition = findSpawnPosition(tycoon.Value)

	-- Create the NPC
	local npc = NPCSystem.createNPC(spawnPosition, tycoon.Value, player)

	return npc
end

-- Initialize NPCs for a player
function NPCSystem.initializePlayerNPCs(player)
	if not player then return end

	-- Make sure the player has a valid tycoon
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then
		debugPrint("No valid tycoon for player:", player.Name)
		return
	end

	-- Create NPCs folder if it doesn't exist
	local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
	if not npcsFolder then
		npcsFolder = Instance.new("Folder")
		npcsFolder.Name = "NPCs"
		npcsFolder.Parent = tycoon.Value
	end

	-- Determine number of initial NPCs
	local initialCount = math.random(
		CONFIG.initialNPCCount.min, 
		CONFIG.initialNPCCount.max
	)

	debugPrint("Spawning " .. initialCount .. " initial NPCs for " .. player.Name)

	-- Spawn NPCs one at a time with delay
	for i = 1, initialCount do
		task.spawn(function()
			local npc = NPCSystem.trySpawnNPC(player)
			if npc then
				debugPrint("Spawned initial NPC #" .. i .. " for " .. player.Name)
			end
		end)

		-- Small delay between spawns
		task.wait(0.5)
	end
end

-- Fix any collision issues with existing NPCs
function NPCSystem.fixNPCCollisions()
	debugPrint("Fixing NPC collisions...")

	local fixCount = 0

	-- Find all NPCs
	for _, player in pairs(Players:GetPlayers()) do
		local tycoon = player:FindFirstChild("Tycoon")
		if tycoon and tycoon.Value then
			local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
			if npcsFolder then
				for _, npc in pairs(npcsFolder:GetChildren()) do
					if npc:IsA("Model") then
						-- Fix parts
						for _, part in pairs(npc:GetDescendants()) do
							if part:IsA("BasePart") then
								-- Try to set collision group
								pcall(function() 
									part.CollisionGroup = "NPCs" 
								end)

								-- Ensure HumanoidRootPart is non-collidable
								if part.Name == "HumanoidRootPart" then
									part.CanCollide = false
								end

								fixCount = fixCount + 1
							end
						end

						-- Make sure NPC has a humanoid
						if not npc:FindFirstChildOfClass("Humanoid") then
							local humanoid = Instance.new("Humanoid")
							humanoid.WalkSpeed = CONFIG.moveSpeed
							humanoid.Parent = npc
							debugPrint("Added missing Humanoid to " .. npc.Name)
						end

						-- Make sure NPC has HumanoidRootPart
						if not npc:FindFirstChild("HumanoidRootPart") then
							local hrp = Instance.new("Part")
							hrp.Name = "HumanoidRootPart"
							hrp.Size = Vector3.new(2, 2, 1)
							hrp.Transparency = 1
							hrp.CanCollide = false

							-- Find a suitable position
							local position
							for _, part in pairs(npc:GetDescendants()) do
								if part:IsA("BasePart") then
									position = part.Position
									break
								end
							end

							if position then
								hrp.Position = position
							else
								hrp.Position = npc:GetPivot().Position
							end

							hrp.Parent = npc
							debugPrint("Added missing HumanoidRootPart to " .. npc.Name)
						end
					end
				end
			end
		end
	end

	debugPrint("Fixed " .. fixCount .. " NPC parts")
	return fixCount
end

-- Start the NPC spawner loop
function NPCSystem.startNPCSpawner()
	debugPrint("Starting NPC spawner loop...")

	-- Run in a separate thread
	task.spawn(function()
		while true do
			task.wait(CONFIG.spawnInterval)

			for _, player in pairs(Players:GetPlayers()) do
				-- Use pcall to prevent errors from affecting other players
				pcall(function()
					-- Random chance to spawn an NPC
					if math.random() < 0.7 then -- 70% chance per interval
						NPCSystem.trySpawnNPC(player)
					end
				end)
			end
		end
	end)
end

-- Start the NPC movement update loop
function NPCSystem.startMovementLoop()
	debugPrint("Starting NPC movement loop...")

	-- Run in a separate thread
	task.spawn(function()
		while true do
			task.wait(1) -- Update every second

			-- Update NPCs for each player
			for _, player in ipairs(Players:GetPlayers()) do
				task.spawn(function()
					pcall(function()
						updatePlayerNPCs(player)
					end)
				end)
			end
		end
	end)
end

-- Initialize the NPC system
function NPCSystem.initialize()
	debugPrint("Initializing NPC System...")

	-- Set up collision groups
	setupCollisionGroups()

	-- Verify NPC folder exists
	verifyNPCFolder()

	-- Fix any existing NPCs
	NPCSystem.fixNPCCollisions()

	-- Create event connections
	Players.PlayerAdded:Connect(function(player)
		-- Wait for player to fully load
		task.wait(5)

		-- Initialize NPCs
		NPCSystem.initializePlayerNPCs(player)
	end)

	-- Initialize existing players
	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(function()
			task.wait(5)
			NPCSystem.initializePlayerNPCs(player)
		end)
	end

	-- Start system loops
	NPCSystem.startNPCSpawner()
	NPCSystem.startMovementLoop()

	debugPrint("NPC System initialization complete!")
	return true
end

-- Run initialization automatically
NPCSystem.initialize()

-- Return public API
return NPCSystem