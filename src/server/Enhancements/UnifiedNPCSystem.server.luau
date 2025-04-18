-- Enhanced NPC System
-- Place this script in ServerScriptService to replace or enhance your existing NPC system
-- Handles NPC creation, movement, and income generation with robust error handling

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")


-- Configuration
local CONFIG = {
	-- Debug
	debugEnabled = true,

	-- NPC creation
	npcFolderName = "NPC_Character",     -- Folder in ServerStorage containing NPC models
	maxNPCsPerGym = 15,                  -- Maximum NPCs per player gym
	spawnInterval = 60,                  -- How often to check for spawning new NPCs (seconds)
	initialSpawnDelay = 3,               -- Delay after player joins before spawning initial NPCs
	initialNPCCount = {min = 2, max = 4}, -- Initial NPC count range

	-- Income generation
	baseIncomeAmount = 15,               -- Base income per NPC
	vipChance = 0.1,                     -- Chance for VIP NPCs (10%)
	vipMultiplier = 3,                   -- Income multiplier for VIP NPCs
	incomeInterval = 60,                 -- How often NPCs generate income (seconds)

	-- Movement
	moveSpeed = 8,                       -- NPC walking speed
	minStayTime = 10,                    -- Min time at a destination (seconds)
	maxStayTime = 30,                    -- Max time at a destination (seconds)
	equipmentTargetChance = 0.7,         -- Chance NPC will target gym equipment
	minWanderRadius = 5,                 -- Minimum wander distance
	maxWanderRadius = 15,                -- Maximum wander distance

	-- Appearance
	nameColors = {                       -- Colors for NPC name tags
		normal = Color3.fromRGB(255, 255, 255),  -- White
		vip = Color3.fromRGB(255, 215, 0)        -- Gold
	},
	vipParticleEnabled = true,           -- Whether VIP NPCs have particles

	-- Visual effects
	spawnEffectEnabled = true,           -- Whether to show spawn effects

	-- Performance
	updateFrequency = 0.5,               -- How often to update NPCs (seconds)
	staggerUpdates = true,               -- Whether to stagger updates across NPCs
	movementCheckInterval = 1            -- How often to check if NPCs should move (seconds)
}

-- Load Economy System if available
local EconomySystem
pcall(function()
	EconomySystem = require(ServerScriptService:FindFirstChild("UnifiedGymEconomySystem"))
end)

-- Debug function
local function debugPrint(...)
	if CONFIG.debugEnabled then
		print("[NPC System]", ...)
	end
end

-- Initialize module table
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

-- Find floor parts in a tycoon
local function findFloorsInTycoon(tycoonModel)
	local floors = {}

	-- First look for parts with "floor" or "platform" in their name
	for _, part in pairs(tycoonModel:GetDescendants()) do
		if part:IsA("BasePart") and 
			(string.lower(part.Name):find("floor") or 
				string.lower(part.Name):find("platform") or 
				string.lower(part.Name):find("ground")) and
			part.Size.X >= 8 and part.Size.Z >= 8 then
			table.insert(floors, part)
		end
	end

	-- If no named floors found, look for any large horizontal surfaces
	if #floors == 0 then
		for _, part in pairs(tycoonModel:GetDescendants()) do
			if part:IsA("BasePart") and 
				part.Size.X >= 8 and part.Size.Z >= 8 and
				math.abs(part.CFrame.UpVector.Y) > 0.9 then
				table.insert(floors, part)
			end
		end
	end

	return floors
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

-- Find a spawn position for an NPC
local function findSpawnPosition(tycoonModel)
	if not tycoonModel then return Vector3.new(0, 5, 0) end

	-- Find floors in the tycoon
	local floors = findFloorsInTycoon(tycoonModel)

	-- If floors found, choose a random one
	if #floors > 0 then
		local floor = floors[math.random(1, #floors)]
		local size = floor.Size
		local cf = floor.CFrame

		-- Get a random position on the floor, keeping away from edges
		local marginX = math.min(size.X * 0.4, 5)
		local marginZ = math.min(size.Z * 0.4, 5)
		local offsetX = (math.random() - 0.5) * (size.X - marginX)
		local offsetZ = (math.random() - 0.5) * (size.Z - marginZ)

		-- Calculate position (3 studs above the floor)
		local spawnPos = cf * CFrame.new(offsetX, size.Y/2 + 3, offsetZ)
		return spawnPos.Position
	end

	-- If no floors, use the tycoon's position
	local tycoonPosition = tycoonModel:GetPivot().Position
	return tycoonPosition + Vector3.new(0, 5, 0)
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

-- Create an NPC
local function createNPC(spawnPosition, tycoonModel, player, isVIP)
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
		badgeLabel.TextColor3 = CONFIG.nameColors.vip
		badgeLabel.Font = Enum.Font.GothamBold
		badgeLabel.Text = "★ VIP ★"
		badgeLabel.TextScaled = true
		badgeLabel.Parent = badge

		badge.Parent = hrp

		-- Add particles if enabled
		if CONFIG.vipParticleEnabled then
			local particle = Instance.new("ParticleEmitter")
			particle.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0)) -- Gold color
			particle.Size = NumberSequence.new(0.2)
			particle.Lifetime = NumberRange.new(1, 2)
			particle.Rate = 5
			particle.Speed = NumberRange.new(0.5, 1)
			particle.SpreadAngle = Vector2.new(0, 180)
			particle.Parent = hrp
		end
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
		spawn(function()
			for i = 1, 10 do
				effect.Size = Vector3.new(i/2, i/2, i/2)
				effect.Transparency = 0.5 + (i * 0.05)
				wait(0.05)
			end
			effect:Destroy()
		end)
	end

	-- Parent the NPC
	npc.Parent = npcsFolder

	debugPrint("Created " .. (isVIP and "VIP " or "") .. "NPC " .. npcName .. " for " .. player.Name)
	return npc
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
	local floors = findFloorsInTycoon(tycoonModel)

	if #floors > 0 then
		-- Choose a random floor
		local floor = floors[math.random(1, #floors)]
		local size = floor.Size
		local cf = floor.CFrame

		-- Get a random position on the floor, keeping away from edges
		local marginX = math.min(size.X * 0.4, 4)
		local marginZ = math.min(size.Z * 0.4, 4)
		local offsetX = (math.random() - 0.5) * (size.X - marginX)
		local offsetZ = (math.random() - 0.5) * (size.Z - marginZ)

		-- Calculate position (3 studs above the floor)
		local targetPos = cf * CFrame.new(offsetX, size.Y/2 + 3, offsetZ)
		return targetPos.Position
	else
		-- Random position in a radius
		local radius = math.random(CONFIG.minWanderRadius, CONFIG.maxWanderRadius)
		local angle = math.random() * math.pi * 2
		local offsetX = math.cos(angle) * radius
		local offsetZ = math.sin(angle) * radius

		return currentPosition + Vector3.new(offsetX, 0, offsetZ)
	end
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

	-- Optional: Play animation if needed
	-- TODO: Add animation support if needed
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

-- Generate income from NPCs
local function generateIncomeFromNPCs()
	for _, player in pairs(Players:GetPlayers()) do
		local tycoon = player:FindFirstChild("Tycoon")
		if not tycoon or not tycoon.Value then continue end

		-- Skip if player hasn't started their tycoon
		if EconomySystem and EconomySystem.hasPlayerStartedTycoon then
			if not EconomySystem.hasPlayerStartedTycoon(player) then
				continue
			end
		end

		local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
		if not npcsFolder then continue end

		local currentTime = os.time()
		local totalIncome = 0

		-- Calculate income from each NPC
		for _, npc in pairs(npcsFolder:GetChildren()) do
			if npc:IsA("Model") then
				local lastPaid = npc:GetAttribute("LastPaid") or 0
				local membershipFee = npc:GetAttribute("MembershipFee") or CONFIG.baseIncomeAmount

				-- Check if enough time has passed
				if currentTime - lastPaid >= CONFIG.incomeInterval then
					-- Update last paid time
					npc:SetAttribute("LastPaid", currentTime)

					-- Add income
					totalIncome = totalIncome + membershipFee
				end
			end
		end

		-- Apply income if there's any
		if totalIncome > 0 then
			-- Use economy system if available
			if EconomySystem then
				local currentDues = tycoon:GetAttribute("AccruedDues") or 0
				tycoon:SetAttribute("AccruedDues", currentDues + totalIncome)

				-- Update front desk display if possible
				pcall(function()
					local frontDeskSystem = require(ServerScriptService:FindFirstChild("UnifiedFrontDeskSystem"))
					if frontDeskSystem and frontDeskSystem.updateFrontDeskDisplay then
						frontDeskSystem.updateFrontDeskDisplay(player)
					end
				end)
			else
				-- Fallback direct method
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats and leaderstats:FindFirstChild("Cash") then
					leaderstats.Cash.Value = leaderstats.Cash.Value + totalIncome
				end
			end

			debugPrint(player.Name .. " earned $" .. totalIncome .. " from NPCs")
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

	-- Check if player has started their tycoon
	if EconomySystem and EconomySystem.hasPlayerStartedTycoon then
		if not EconomySystem.hasPlayerStartedTycoon(player) then
			debugPrint("Player hasn't started tycoon yet:", player.Name)
			return nil
		end
	end

	-- Check if at max NPCs
	local currentNPCCount = countNPCs(player)
	if currentNPCCount >= CONFIG.maxNPCsPerGym then 
		debugPrint("Max NPCs reached for player:", player.Name)
		return nil 
	end

	-- Validate NPC folder
	local npcFolder = verifyNPCFolder()
	if not npcFolder or #npcFolder:GetChildren() == 0 then
		debugPrint("No valid NPC models found")
		return nil
	end

	-- Find a spawn position
	local spawnPosition = findSpawnPosition(tycoon.Value)

	-- Determine if this should be a VIP
	local isVIP = math.random() < CONFIG.vipChance

	-- Create the NPC
	local npc = createNPC(spawnPosition, tycoon.Value, player, isVIP)

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

	-- Check if player has started their tycoon
	if EconomySystem and EconomySystem.hasPlayerStartedTycoon then
		if not EconomySystem.hasPlayerStartedTycoon(player) then
			debugPrint("Player hasn't started tycoon yet:", player.Name)
			return
		end
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
			wait(CONFIG.spawnInterval)

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
		local updateCounter = 0

		while true do
			wait(CONFIG.movementCheckInterval)
			updateCounter = updateCounter + 1

			-- Update NPCs for each player
			for i, player in ipairs(Players:GetPlayers()) do
				-- If staggering is enabled, only update some NPCs each tick
				if not CONFIG.staggerUpdates or 
					(updateCounter + i) % #Players:GetPlayers() == 0 then

					task.spawn(function()
						pcall(function()
							updatePlayerNPCs(player)
						end)
					end)
				end
			end
		end
	end)
end

-- Start the income generation loop
function NPCSystem.startIncomeLoop()
	debugPrint("Starting NPC income loop...")

	-- Run in a separate thread
	task.spawn(function()
		while true do
			wait(CONFIG.incomeInterval)

			-- Generate income from NPCs
			pcall(function()
				generateIncomeFromNPCs()
			end)
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
		wait(CONFIG.initialSpawnDelay)

		-- Initialize NPCs
		NPCSystem.initializePlayerNPCs(player)
	end)

	-- Initialize existing players
	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(function()
			wait(CONFIG.initialSpawnDelay)
			NPCSystem.initializePlayerNPCs(player)
		end)
	end

	-- Start system loops
	NPCSystem.startNPCSpawner()
	NPCSystem.startMovementLoop()
	NPCSystem.startIncomeLoop()

	-- Connect to EventBridge if it exists
	local EventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
	if EventBridge then
		-- Handle special events
		local specialEventStarted = EventBridge:FindFirstChild("SpecialEventStartedEvent")
		if specialEventStarted then
			specialEventStarted.OnServerEvent:Connect(function(player, eventName, duration)
				debugPrint("Special event started: " .. eventName)

				-- Spawn extra NPCs during event
				for _, p in pairs(Players:GetPlayers()) do
					for i = 1, 2 do -- Spawn 2 extra NPCs
						wait(math.random() * 2) -- Random delay
						NPCSystem.trySpawnNPC(p)
					end
				end
			end)
		end

		-- Handle gym level up
		local gymLevelUp = EventBridge:FindFirstChild("GymLevelUpEvent")
		if gymLevelUp then
			gymLevelUp.OnServerEvent:Connect(function(player, newLevel)
				debugPrint("Gym level up: " .. player.Name .. " reached level " .. newLevel)

				-- Spawn a new NPC to celebrate
				wait(1)
				NPCSystem.trySpawnNPC(player)
			end)
		end
	end

	debugPrint("NPC System initialization complete")
	return true
end

-- Expose public API
return {
	initialize = NPCSystem.initialize,
	trySpawnNPC = NPCSystem.trySpawnNPC,
	initializePlayerNPCs = NPCSystem.initializePlayerNPCs,
	fixNPCCollisions = NPCSystem.fixNPCCollisions,
	CONFIG = CONFIG -- Expose configuration for other scripts
}