-- Pool Swimming System
-- Place this script in ServerScriptService

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
	-- Pool detection
	poolTag = "SwimmingPool", -- Tag to identify pools
	waterSurfaceY = nil, -- Will be auto-detected if nil
	swimmingHeight = 2.5, -- Height to position player when swimming

	-- Swimming mechanics
	swimSpeed = 16, -- Swimming speed
	normalSpeed = 16, -- Normal walking speed
	buoyancyForce = 196.2, -- Force to keep player floating (gravity counterforce)
	swimUpForce = 50, -- Force when swimming upwards
	sinkRate = 5, -- How fast player sinks when not swimming

	-- Animations
	swimIdleAnimId = "rbxassetid://507784897", -- Swimming idle animation
	swimMoveAnimId = "rbxassetid://507785072", -- Swimming movement animation

	-- Effects
	enableSplashEffects = true, -- Enable splash effects
	enableRipples = true, -- Enable ripple effects
	enableBubbles = true, -- Enable bubble effects when underwater

	-- Sound effects
	enableSounds = true, -- Enable sound effects
	splashSoundId = "rbxassetid://3097652149", -- Splash sound
	underwaterAmbientId = "rbxassetid://5153478925", -- Underwater ambient sound

	-- Visuals
	underwaterTint = Color3.fromRGB(10, 126, 140), -- Color tint when underwater
	underwaterFogEnd = 60, -- Distance at which fog ends underwater
}

-- Variables
local swimmingPools = {}
local swimmingPlayers = {}
local currentlySwimming = {}
local remoteEvent

-- Create RemoteEvent for client-server communication
local function setupRemoteEvent()
	remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = "SwimmingSystemEvent"
	remoteEvent.Parent = ReplicatedStorage

	return remoteEvent
end

-- Find all swimming pools in the workspace
local function findSwimmingPools()
	local pools = {}

	-- First try to find by tag
	local taggedPools = CollectionService:GetTagged(CONFIG.poolTag)
	for _, pool in pairs(taggedPools) do
		table.insert(pools, pool)
	end

	-- If no tagged pools found, try to find by name
	if #pools == 0 then
		local function searchForPools(parent)
			for _, obj in pairs(parent:GetChildren()) do
				if (obj.Name:lower():find("pool") or obj.Name:lower():find("water")) and 
					(obj:IsA("BasePart") or obj:IsA("Model")) then
					table.insert(pools, obj)
				end

				if #obj:GetChildren() > 0 then
					searchForPools(obj)
				end
			end
		end

		searchForPools(workspace)
	end

	-- Process found pools
	for _, pool in pairs(pools) do
		local bounds = {}

		if pool:IsA("BasePart") then
			-- Get bounds from part
			local size = pool.Size
			local cf = pool.CFrame
			bounds = {
				min = cf * Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
				max = cf * Vector3.new(size.X/2, size.Y/2, size.Z/2),
				waterY = cf.Y + size.Y/2 -- Water level is at the top of the part
			}
		elseif pool:IsA("Model") then
			-- Calculate bounds from model
			bounds = {
				min = Vector3.new(math.huge, math.huge, math.huge),
				max = Vector3.new(-math.huge, -math.huge, -math.huge)
			}

			local waterParts = {}

			-- Find all water parts
			for _, part in pairs(pool:GetDescendants()) do
				if part:IsA("BasePart") and 
					(part.Name:lower():find("water") or 
						part.Transparency > 0.1 or
						part.Material == Enum.Material.Water) then
					table.insert(waterParts, part)
				end
			end

			-- If no specific water parts found, use all parts
			if #waterParts == 0 then
				for _, part in pairs(pool:GetDescendants()) do
					if part:IsA("BasePart") then
						table.insert(waterParts, part)
					end
				end
			end

			-- Calculate bounds from all found parts
			for _, part in pairs(waterParts) do
				local cf = part.CFrame
				local size = part.Size

				-- Check all 8 corners of the part
				for dx = -1, 1, 2 do
					for dy = -1, 1, 2 do
						for dz = -1, 1, 2 do
							local corner = cf * Vector3.new(dx * size.X/2, dy * size.Y/2, dz * size.Z/2)

							bounds.min = Vector3.new(
								math.min(bounds.min.X, corner.X),
								math.min(bounds.min.Y, corner.Y),
								math.min(bounds.min.Z, corner.Z)
							)

							bounds.max = Vector3.new(
								math.max(bounds.max.X, corner.X),
								math.max(bounds.max.Y, corner.Y),
								math.max(bounds.max.Z, corner.Z)
							)
						end
					end
				end
			end

			-- Determine the water surface Y position (highest Y of all water parts)
			local highestY = -math.huge
			for _, part in pairs(waterParts) do
				local topY = part.Position.Y + part.Size.Y/2
				if topY > highestY then
					highestY = topY
				end
			end

			bounds.waterY = highestY
		end

		-- Store pool info
		swimmingPools[pool] = bounds

		-- If a global water Y hasn't been set yet, use this one
		if CONFIG.waterSurfaceY == nil then
			CONFIG.waterSurfaceY = bounds.waterY
		end

		-- Auto-tag the pool if it wasn't tagged already
		if not CollectionService:HasTag(pool, CONFIG.poolTag) then
			CollectionService:AddTag(pool, CONFIG.poolTag)
		end

		print("Found swimming pool: " .. pool:GetFullName() .. " with water level at Y=" .. bounds.waterY)
	end

	return pools
end

-- Create swimming animation for a player
local function setupSwimmingAnimations(player)
	if not player.Character then return end

	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Create animator if needed
	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	-- Create animation objects
	local swimIdleAnim = Instance.new("Animation")
	swimIdleAnim.AnimationId = CONFIG.swimIdleAnimId

	local swimMoveAnim = Instance.new("Animation")
	swimMoveAnim.AnimationId = CONFIG.swimMoveAnimId

	-- Load animations
	local swimIdleTrack = animator:LoadAnimation(swimIdleAnim)
	local swimMoveTrack = animator:LoadAnimation(swimMoveAnim)

	-- Adjust animation properties
	swimIdleTrack.Looped = true
	swimMoveTrack.Looped = true

	return {
		idle = swimIdleTrack,
		move = swimMoveTrack
	}
end

-- Create underwater effect for a player
local function setupUnderwaterEffect(player)
	-- Create and send a local script to handle first-person underwater effects
	local clientScript = [[
		local Players = game:GetService("Players")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local TweenService = game:GetService("TweenService")
		local Lighting = game:GetService("Lighting")
		
		local player = Players.LocalPlayer
		local remoteEvent = ReplicatedStorage:WaitForChild("SwimmingSystemEvent")
		
		-- Configuration from server
		local CONFIG = {
			underwaterTint = Color3.fromRGB(10, 126, 140),
			underwaterFogEnd = 60,
			enableSounds = true,
			underwaterAmbientId = "rbxassetid://5153478925",
		}
		
		-- Create underwater overlay GUI
		local underwaterGui = Instance.new("ScreenGui")
		underwaterGui.Name = "UnderwaterEffect"
		underwaterGui.ResetOnSpawn = false
		underwaterGui.Enabled = false
		underwaterGui.Parent = player.PlayerGui
		
		local blueOverlay = Instance.new("Frame")
		blueOverlay.Name = "BlueOverlay"
		blueOverlay.Size = UDim2.new(1, 0, 1, 0)
		blueOverlay.BackgroundColor3 = CONFIG.underwaterTint
		blueOverlay.BackgroundTransparency = 0.5
		blueOverlay.BorderSizePixel = 0
		blueOverlay.Parent = underwaterGui
		
		-- Create underwater sound
		local underwaterSound
		if CONFIG.enableSounds then
			underwaterSound = Instance.new("Sound")
			underwaterSound.Name = "UnderwaterAmbient"
			underwaterSound.SoundId = CONFIG.underwaterAmbientId
			underwaterSound.Volume = 0.5
			underwaterSound.Looped = true
			underwaterSound.Parent = player.PlayerGui
		end
		
		-- Original lighting properties
		local originalFogEnd
		local originalFogColor
		
		-- Function to handle underwater state change
		local function onUnderwaterChanged(isUnderwater)
			underwaterGui.Enabled = isUnderwater
			
			if isUnderwater then
				-- Save original lighting properties
				originalFogEnd = Lighting.FogEnd
				originalFogColor = Lighting.FogColor
				
				-- Apply underwater lighting
				Lighting.FogEnd = CONFIG.underwaterFogEnd
				Lighting.FogColor = CONFIG.underwaterTint
				
				-- Play underwater sound
				if underwaterSound then
					underwaterSound:Play()
				end
			else
				-- Restore original lighting
				if originalFogEnd then
					Lighting.FogEnd = originalFogEnd
				end
				
				if originalFogColor then
					Lighting.FogColor = originalFogColor
				end
				
				-- Stop underwater sound
				if underwaterSound then
					underwaterSound:Stop()
				end
			end
		end
		
		-- Connect to remote event
		remoteEvent.OnClientEvent:Connect(function(action, ...)
			if action == "UnderwaterChanged" then
				onUnderwaterChanged(...)
			elseif action == "UpdateConfig" then
				CONFIG = ...
			end
		end)
	]]

	-- Send the client-side script to the player
	remoteEvent:FireClient(player, "SetupUnderwaterEffect", clientScript)
end

-- Create splash effect at a position
local function createSplashEffect(position)
	if not CONFIG.enableSplashEffects then return end

	-- Create splash particles
	local splashPart = Instance.new("Part")
	splashPart.Name = "SplashEffect"
	splashPart.Anchored = true
	splashPart.CanCollide = false
	splashPart.Transparency = 1
	splashPart.Size = Vector3.new(1, 1, 1)
	splashPart.Position = Vector3.new(position.X, CONFIG.waterSurfaceY, position.Z)
	splashPart.Parent = workspace

	-- Create splash particle emitter
	local splash = Instance.new("ParticleEmitter")
	splash.Texture = "rbxassetid://4801874364" -- Water splash texture
	splash.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	splash.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 1.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	splash.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	splash.Lifetime = NumberRange.new(0.5, 1)
	splash.Rate = 0
	splash.Speed = NumberRange.new(5, 10)
	splash.SpreadAngle = Vector2.new(45, 45)
	splash.Drag = 5
	splash.Acceleration = Vector3.new(0, -workspace.Gravity/2, 0)
	splash.Parent = splashPart

	-- Create one-time burst
	splash:Emit(30)

	-- Create splash sound
	if CONFIG.enableSounds then
		local splashSound = Instance.new("Sound")
		splashSound.SoundId = CONFIG.splashSoundId
		splashSound.Volume = 0.8
		splashSound.PlaybackSpeed = math.random(80, 120) / 100 -- Random pitch
		splashSound.Parent = splashPart
		splashSound:Play()
	end

	-- Create ripple effect
	if CONFIG.enableRipples then
		local ripple = Instance.new("Part")
		ripple.Name = "RippleEffect"
		ripple.Shape = Enum.PartType.Cylinder
		ripple.Orientation = Vector3.new(0, 0, 90)
		ripple.Anchored = true
		ripple.CanCollide = false
		ripple.Material = Enum.Material.SmoothPlastic
		ripple.Size = Vector3.new(0.1, 1, 1)
		ripple.Position = Vector3.new(position.X, CONFIG.waterSurfaceY + 0.05, position.Z)
		ripple.Transparency = 0.3
		ripple.Parent = workspace

		-- Animate ripple expansion
		spawn(function()
			for i = 1, 10 do
				ripple.Size = Vector3.new(0.1, i * 0.5, i * 0.5)
				ripple.Transparency = 0.3 + (i * 0.07)
				wait(0.05)
			end
			ripple:Destroy()
		end)
	end

	-- Clean up after a short time
	game:GetService("Debris"):AddItem(splashPart, 1.5)
end

-- Create bubble effect for underwater player
local function createBubbleEffect(character)
	if not CONFIG.enableBubbles or not character then return end

	local head = character:FindFirstChild("Head")
	if not head then return end

	-- Check if bubbles already exist
	if head:FindFirstChild("UnderwaterBubbles") then return end

	-- Create bubble emitter
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Name = "UnderwaterBubbles"
	bubbles.Texture = "rbxassetid://133619974" -- Bubble texture
	bubbles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	bubbles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 0.1)
	})
	bubbles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0.8)
	})
	bubbles.Lifetime = NumberRange.new(1, 2)
	bubbles.Rate = 2
	bubbles.Speed = NumberRange.new(1, 2)
	bubbles.SpreadAngle = Vector2.new(25, 25)
	bubbles.Acceleration = Vector3.new(0, 5, 0) -- Bubbles rise
	bubbles.Parent = head

	return bubbles
end

-- Remove bubble effect
local function removeBubbleEffect(character)
	if not character then return end

	local head = character:FindFirstChild("Head")
	if not head then return end

	local bubbles = head:FindFirstChild("UnderwaterBubbles")
	if bubbles then
		bubbles:Destroy()
	end
end

-- Check if player is in a swimming pool
local function isPlayerInPool(player)
	if not player.Character then return false end

	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	local position = rootPart.Position

	for pool, bounds in pairs(swimmingPools) do
		if position.X >= bounds.min.X and position.X <= bounds.max.X and
			position.Z >= bounds.min.Z and position.Z <= bounds.max.Z and
			position.Y >= bounds.min.Y and position.Y <= bounds.max.Y then
			return true, bounds.waterY
		end
	end

	return false
end

-- Check if position is underwater
local function isPositionUnderwater(position, waterY)
	return position.Y < waterY
end

-- Handle when a player enters the swimming state
local function enterSwimmingState(player, waterY)
	if not player.Character then return end

	local humanoid = player.Character:FindFirstChild("Humanoid")
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then return end

	-- Already swimming
	if currentlySwimming[player] then return end

	currentlySwimming[player] = true
	print(player.Name .. " entered swimming state")

	-- Store original values
	local originalJumpPower = humanoid.JumpPower
	local originalWalkSpeed = humanoid.WalkSpeed
	local originalGravity = rootPart.CustomPhysicalProperties and 
		rootPart.CustomPhysicalProperties.Density or 0.7

	-- Set up swimming animations
	local animations = swimmingPlayers[player]
	if not animations then
		animations = setupSwimmingAnimations(player)
		swimmingPlayers[player] = animations
	end

	-- Start swimming idle animation
	if animations and animations.idle then
		animations.idle:Play()
	end

	-- Adjust physics
	humanoid.JumpPower = 0
	humanoid.WalkSpeed = CONFIG.swimSpeed

	-- Apply buoyancy with custom physical properties
	rootPart.CustomPhysicalProperties = PhysicalProperties.new(
		0.1, -- Density (light to float)
		0.3, -- Friction
		0.5, -- Elasticity
		1,   -- FrictionWeight
		1    -- ElasticityWeight
	)

	-- Create splash effect
	createSplashEffect(rootPart.Position)

	-- Check if player is underwater
	local isUnderwater = isPositionUnderwater(rootPart.Position, waterY)
	if isUnderwater then
		-- Create bubble effect
		createBubbleEffect(player.Character)

		-- Send underwater effect to client
		remoteEvent:FireClient(player, "UnderwaterChanged", true)
	end

	-- Store the original values for restoring later
	swimmingPlayers[player] = {
		animations = animations,
		originalJumpPower = originalJumpPower,
		originalWalkSpeed = originalWalkSpeed,
		originalGravity = originalGravity,
		isUnderwater = isUnderwater,
		waterY = waterY
	}

	-- Apply swimming force to stay afloat
	local swimConnection
	swimConnection = RunService.Heartbeat:Connect(function(dt)
		if not player.Character or not rootPart or not rootPart.Parent or not currentlySwimming[player] then
			-- Player left swimming or character was destroyed
			if swimConnection then
				swimConnection:Disconnect()
			end
			return
		end

		-- Get move direction
		local moveDir = humanoid.MoveDirection
		local isMoving = moveDir.Magnitude > 0.1

		-- Determine if underwater
		local position = rootPart.Position
		local playerIsUnderwater = isPositionUnderwater(position, waterY)

		-- Update underwater state if changed
		if playerIsUnderwater ~= swimmingPlayers[player].isUnderwater then
			swimmingPlayers[player].isUnderwater = playerIsUnderwater

			if playerIsUnderwater then
				-- Create bubble effect
				createBubbleEffect(player.Character)

				-- Send underwater effect to client
				remoteEvent:FireClient(player, "UnderwaterChanged", true)
			else
				-- Remove bubble effect
				removeBubbleEffect(player.Character)

				-- Send underwater effect to client
				remoteEvent:FireClient(player, "UnderwaterChanged", false)

				-- Create small splash when surfacing
				if math.abs(position.Y - waterY) < 1 then
					createSplashEffect(position)
				end
			end
		end

		-- Apply animations based on movement
		if animations then
			if isMoving and not animations.move.IsPlaying then
				animations.idle:Stop()
				animations.move:Play()
			elseif not isMoving and not animations.idle.IsPlaying then
				animations.move:Stop()
				animations.idle:Play()
			end
		end

		-- Apply swimming forces
		local targetY = waterY - CONFIG.swimmingHeight
		local verticalForce = 0

		-- Apply buoyancy force to counteract gravity and keep player at swimming height
		if playerIsUnderwater then
			-- When underwater, apply buoyancy force to rise up to swimming height
			local depthRatio = math.min(1, (position.Y - targetY) / 5)
			verticalForce = CONFIG.buoyancyForce * (1 - depthRatio)

			-- Apply upward force if jump key is pressed
			if humanoid.Jump then
				verticalForce = verticalForce + CONFIG.swimUpForce
			end
		else
			-- When at surface, apply gentler force to maintain position
			local heightDiff = targetY - position.Y
			verticalForce = CONFIG.buoyancyForce * 0.2 + heightDiff * 10

			-- Apply slight sink when not moving
			if not isMoving and not humanoid.Jump then
				verticalForce = verticalForce - CONFIG.sinkRate
			end
		end

		-- Apply forces
		local swimForce = Vector3.new(0, verticalForce, 0)
		rootPart:ApplyImpulse(swimForce * dt)

		-- Limit maximum depth
		if position.Y < targetY - 10 then
			rootPart.Position = Vector3.new(position.X, targetY - 10, position.Z)
		end

		-- Create occasional bubbles when swimming
		if playerIsUnderwater and isMoving and math.random(1, 100) < 5 then
			local bubble = Instance.new("Part")
			bubble.Shape = Enum.PartType.Ball
			bubble.Name = "SwimBubble"
			bubble.Size = Vector3.new(0.2, 0.2, 0.2)
			bubble.Transparency = 0.3
			bubble.CanCollide = false
			bubble.Anchored = true
			bubble.Position = position + Vector3.new(math.random(-1, 1), 0, math.random(-1, 1))
			bubble.Material = Enum.Material.SmoothPlastic
			bubble.Parent = workspace

			-- Animate bubble rising
			spawn(function()
				for i = 1, 10 do
					bubble.Position = bubble.Position + Vector3.new(0, 0.1, 0)
					bubble.Transparency = 0.3 + (i * 0.07)
					wait(0.05)
				end
				bubble:Destroy()
			end)
		end
	end)
end

-- Handle when a player exits the swimming state
local function exitSwimmingState(player)
	if not currentlySwimming[player] then return end

	currentlySwimming[player] = nil
	print(player.Name .. " exited swimming state")

	if not player.Character then return end

	local humanoid = player.Character:FindFirstChild("Humanoid")
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then return end

	local data = swimmingPlayers[player]
	if not data then return end

	-- Stop swimming animations
	if data.animations then
		if data.animations.idle then
			data.animations.idle:Stop()
		end
		if data.animations.move then
			data.animations.move:Stop()
		end
	end

	-- Restore original values
	humanoid.JumpPower = data.originalJumpPower
	humanoid.WalkSpeed = data.originalWalkSpeed

	-- Restore physical properties
	rootPart.CustomPhysicalProperties = PhysicalProperties.new(
		data.originalGravity, -- Density
		0.3, -- Friction
		0.5, -- Elasticity
		1,   -- FrictionWeight
		1    -- ElasticityWeight
	)

	-- Remove bubble effect
	removeBubbleEffect(player.Character)

	-- Turn off underwater effect
	remoteEvent:FireClient(player, "UnderwaterChanged", false)

	-- Create exit splash if near water surface
	if rootPart.Position.Y < data.waterY + 5 then
		createSplashEffect(rootPart.Position)
	end
end

-- Update swimming state for all players
local function updateSwimmingPlayers()
	for _, player in pairs(Players:GetPlayers()) do
		local inPool, waterY = isPlayerInPool(player)

		if inPool then
			if not currentlySwimming[player] then
				enterSwimmingState(player, waterY)
			end
		else
			if currentlySwimming[player] then
				exitSwimmingState(player)
			end
		end
	end
end

-- Initialize for a player
local function initializeForPlayer(player)
	-- Wait for character to load
	if not player.Character then
		player.CharacterAdded:Wait()
	end

	-- Set up underwater effect
	setupUnderwaterEffect(player)

	-- Check if player is already in a pool
	local inPool, waterY = isPlayerInPool(player)
	if inPool then
		enterSwimmingState(player, waterY)
	end
end

-- Clean up when a player leaves
local function cleanupForPlayer(player)
	if currentlySwimming[player] then
		exitSwimmingState(player)
	end

	currentlySwimming[player] = nil
	swimmingPlayers[player] = nil
end

-- Initialize for existing players
for _, player in pairs(Players:GetPlayers()) do
	spawn(function()
		initializeForPlayer(player)
	end)
end

-- Set up player events
Players.PlayerAdded:Connect(initializeForPlayer)
Players.PlayerRemoving:Connect(cleanupForPlayer)

-- Set up heartbeat for continuous updates
RunService.Heartbeat:Connect(function()
	updateSwimmingPlayers()
end)

-- Create RemoteEvent for underwater effects
remoteEvent = setupRemoteEvent()

-- Find all pools
local pools = findSwimmingPools()

print("Swimming system initialized with " .. #pools .. " pools")

-- Tag a part as a swimming pool
local function tagAsSwimmingPool(part)
	CollectionService:AddTag(part, CONFIG.poolTag)
	findSwimmingPools() -- Refresh pool list
	print("Tagged " .. part:GetFullName() .. " as swimming pool")
	return true
end

return {
	tagAsSwimmingPool = tagAsSwimmingPool
}