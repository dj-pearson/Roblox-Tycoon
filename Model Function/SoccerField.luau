-- Interactive Soccer Game Script
-- Place this script inside the Soccer Ball

local SoccerGame = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

-- Configuration
local CONFIG = {
	-- Ball Physics
	BallMass = 2,
	BallElasticity = 0.8,
	BallFriction = 0.2,
	MaxSpeed = 60,

	-- Kicking
	KickRange = 5,
	KickForceNormal = 1600,
	KickForcePower = 3500,
	KickCooldown = 0.5,
	ControlsEnabled = true,
	KickKey = Enum.KeyCode.E,
	PowerKickKey = Enum.KeyCode.Q,

	-- Goals
	GoalScoringEnabled = true,
	CelebrationDuration = 5,
	ResetBallAfterGoal = true,
	ResetDelay = 3,

	-- Sound Effects
	SoundEnabled = true,
	KickSoundIds = {
		"rbxassetid://9119749149", -- Replace with kick sound IDs
		"rbxassetid://9119748924"
	},
	GoalSoundIds = {
		"rbxassetid://9125631529", -- Replace with goal celebration sound IDs
		"rbxassetid://9125629732"
	},
	CrowdCheerSoundId = "rbxassetid://7545569509", -- Crowd cheer sound

	-- Visual Effects
	KickEffectEnabled = true,
	GoalEffectEnabled = true,
	ShowTrail = true,
	ShowKickDirection = true,

	-- Scoreboard
	EnableScoreboard = true,
	Team1Name = "HOME",
	Team2Name = "AWAY",

	-- Debug
	DebugMode = false
}

-- Get references to game objects
local soccerBall = script.Parent
local soccerField = soccerBall.Parent
local goal1 = soccerField:FindFirstChild("Goal 1")
local goal2 = soccerField:FindFirstChild("Goal 2")

-- Internal variables
local ballPart = soccerBall:IsA("BasePart") and soccerBall or soccerBall.PrimaryPart or soccerBall:FindFirstChildWhichIsA("BasePart")
local originalBallPosition = ballPart.Position
local activeKickers = {}
local scoreTeam1 = 0
local scoreTeam2 = 0
local lastGoalTime = 0
local ballLastKicked = 0
local scoreboard
local sounds = {}
local effects = {}
local isReset = false

-- Initialize ball physics
local function setupBallPhysics()
	-- Set ball physical properties
	ballPart.CustomPhysicalProperties = PhysicalProperties.new(
		CONFIG.BallMass,     -- Density
		CONFIG.BallFriction, -- Friction
		CONFIG.BallElasticity, -- Elasticity (restitution)
		0.5,                 -- Friction weight
		0.7                  -- Elasticity weight
	)

	-- Ensure the ball has proper physics settings
	ballPart.Anchored = false
	ballPart.CanCollide = true

	-- Add constraints to prevent the ball from flying away forever
	local velocityConstraint = Instance.new("VectorForce")
	velocityConstraint.Name = "VelocityCap"
	velocityConstraint.RelativeTo = Enum.ActuatorRelativeTo.World
	velocityConstraint.ApplyAtCenterOfMass = true
	velocityConstraint.Visible = false

	local attachment = Instance.new("Attachment")
	attachment.Parent = ballPart

	velocityConstraint.Attachment0 = attachment
	velocityConstraint.Force = Vector3.new(0, 0, 0) -- Will be updated dynamically
	velocityConstraint.Parent = ballPart

	SoccerGame.velocityConstraint = velocityConstraint

	-- Create ball trail if enabled
	if CONFIG.ShowTrail then
		local trail = Instance.new("Trail")
		trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.7),
			NumberSequenceKeypoint.new(1, 1)
		})
		trail.Lifetime = 0.5
		trail.Enabled = true

		local trailAttach0 = Instance.new("Attachment")
		trailAttach0.Position = Vector3.new(-0.2, 0, 0)
		trailAttach0.Parent = ballPart

		local trailAttach1 = Instance.new("Attachment")
		trailAttach1.Position = Vector3.new(0.2, 0, 0)
		trailAttach1.Parent = ballPart

		trail.Attachment0 = trailAttach0
		trail.Attachment1 = trailAttach1
		trail.Parent = ballPart

		effects.trail = trail
	end

	-- Set up a force to keep the ball from rolling forever
	RunService.Heartbeat:Connect(function()
		-- Apply drag force based on current velocity
		local velocity = ballPart.AssemblyLinearVelocity
		local speed = velocity.Magnitude

		-- Keep ball from going too fast
		if speed > CONFIG.MaxSpeed then
			-- Apply opposing force to cap speed
			velocityConstraint.Force = -velocity * (speed - CONFIG.MaxSpeed) / 10
		else
			-- Apply slight friction to slow ball gradually
			velocityConstraint.Force = -velocity * 0.05
		end

		-- Make sure ball stays on field (basic boundary check)
		if ballPart.Position.Y < 0 then
			-- Reset ball if it falls below the field
			resetBall()
		end
	end)
end

-- Create sound effects for kicking and goals
local function setupSounds()
	if not CONFIG.SoundEnabled then return end

	-- Create kick sounds
	for i, soundId in ipairs(CONFIG.KickSoundIds) do
		local sound = Instance.new("Sound")
		sound.Name = "KickSound" .. i
		sound.SoundId = soundId
		sound.Volume = 0.8
		sound.RollOffMode = Enum.RollOffMode.LinearSquare
		sound.RollOffMaxDistance = 100
		sound.RollOffMinDistance = 5
		sound.Parent = ballPart

		table.insert(sounds, sound)
	end

	-- Create goal sounds
	for i, soundId in ipairs(CONFIG.GoalSoundIds) do
		local sound = Instance.new("Sound")
		sound.Name = "GoalSound" .. i
		sound.SoundId = soundId
		sound.Volume = 1
		sound.RollOffMode = Enum.RollOffMode.LinearSquare
		sound.RollOffMaxDistance = 200
		sound.RollOffMinDistance = 10
		sound.Parent = soccerField

		table.insert(sounds, sound)
	end

	-- Create crowd cheer
	local crowdCheer = Instance.new("Sound")
	crowdCheer.Name = "CrowdCheer"
	crowdCheer.SoundId = CONFIG.CrowdCheerSoundId
	crowdCheer.Volume = 0.7
	crowdCheer.RollOffMode = Enum.RollOffMode.LinearSquare
	crowdCheer.RollOffMaxDistance = 200
	crowdCheer.RollOffMinDistance = 5
	crowdCheer.Parent = soccerField

	sounds.crowdCheer = crowdCheer
end

-- Create scoreboard
local function createScoreboard()
	if not CONFIG.EnableScoreboard then return end

	-- Create billboard GUI for scoreboard
	local board = Instance.new("BillboardGui")
	board.Name = "SoccerScoreboard"
	board.Size = UDim2.new(0, 200, 0, 80)
	board.StudsOffset = Vector3.new(0, 5, 0)
	board.AlwaysOnTop = true
	board.Adornee = soccerField:FindFirstChild("Part") or soccerField -- Attach to some part of the field

	-- Create background
	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	background.BackgroundTransparency = 0.3
	background.BorderSizePixel = 2
	background.BorderColor3 = Color3.fromRGB(255, 255, 255)
	background.Parent = board

	-- Create title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.3, 0)
	title.BackgroundTransparency = 1
	title.Text = "SCOREBOARD"
	title.Font = Enum.Font.SourceSansBold
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Parent = background

	-- Create team names
	local team1Label = Instance.new("TextLabel")
	team1Label.Size = UDim2.new(0.45, 0, 0.5, 0)
	team1Label.Position = UDim2.new(0.025, 0, 0.4, 0)
	team1Label.BackgroundTransparency = 1
	team1Label.Text = CONFIG.Team1Name
	team1Label.Font = Enum.Font.SourceSans
	team1Label.TextColor3 = Color3.fromRGB(255, 255, 255)
	team1Label.TextScaled = true
	team1Label.Parent = background

	local team2Label = Instance.new("TextLabel")
	team2Label.Size = UDim2.new(0.45, 0, 0.5, 0)
	team2Label.Position = UDim2.new(0.525, 0, 0.4, 0)
	team2Label.BackgroundTransparency = 1
	team2Label.Text = CONFIG.Team2Name
	team2Label.Font = Enum.Font.SourceSans
	team2Label.TextColor3 = Color3.fromRGB(255, 255, 255)
	team2Label.TextScaled = true
	team2Label.Parent = background

	-- Create score displays
	local score1 = Instance.new("TextLabel")
	score1.Size = UDim2.new(0.2, 0, 0.5, 0)
	score1.Position = UDim2.new(0.15, 0, 0.7, 0)
	score1.BackgroundTransparency = 1
	score1.Text = "0"
	score1.Font = Enum.Font.SourceSansBold
	score1.TextColor3 = Color3.fromRGB(255, 255, 100)
	score1.TextScaled = true
	score1.Name = "Score1"
	score1.Parent = background

	local score2 = Instance.new("TextLabel")
	score2.Size = UDim2.new(0.2, 0, 0.5, 0)
	score2.Position = UDim2.new(0.65, 0, 0.7, 0)
	score2.BackgroundTransparency = 1
	score2.Text = "0"
	score2.Font = Enum.Font.SourceSansBold
	score2.TextColor3 = Color3.fromRGB(255, 255, 100)
	score2.TextScaled = true
	score2.Name = "Score2"
	score2.Parent = background

	-- Create divider
	local divider = Instance.new("TextLabel")
	divider.Size = UDim2.new(0.1, 0, 0.5, 0)
	divider.Position = UDim2.new(0.45, 0, 0.7, 0)
	divider.BackgroundTransparency = 1
	divider.Text = "-"
	divider.Font = Enum.Font.SourceSansBold
	divider.TextColor3 = Color3.fromRGB(255, 255, 255)
	divider.TextScaled = true
	divider.Parent = background

	board.Parent = soccerField
	scoreboard = board
end

-- Update the scoreboard
local function updateScoreboard()
	if not scoreboard then return end

	local score1Display = scoreboard:FindFirstChild("Background"):FindFirstChild("Score1")
	local score2Display = scoreboard:FindFirstChild("Background"):FindFirstChild("Score2")

	if score1Display then
		score1Display.Text = tostring(scoreTeam1)
	end

	if score2Display then
		score2Display.Text = tostring(scoreTeam2)
	end
end

-- Play a random kick sound
local function playKickSound()
	if not CONFIG.SoundEnabled then return end

	local randomIndex = math.random(1, #CONFIG.KickSoundIds)
	for _, sound in ipairs(sounds) do
		if sound.Name == "KickSound" .. randomIndex then
			sound:Play()
			break
		end
	end
end

-- Play a goal celebration sound
local function playGoalSound()
	if not CONFIG.SoundEnabled then return end

	local randomIndex = math.random(1, #CONFIG.GoalSoundIds)
	for _, sound in ipairs(sounds) do
		if sound.Name == "GoalSound" .. randomIndex then
			sound:Play()

			-- Also play crowd cheer
			if sounds.crowdCheer then
				sounds.crowdCheer:Play()
			end

			break
		end
	end
end

-- Reset the ball to the center of the field
local function resetBall()
	if isReset then return end
	isReset = true

	-- Calculate center of field
	local centerPos = originalBallPosition

	-- Tween ball back to center
	local resetTween = TweenService:Create(
		ballPart,
		TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
		{Position = centerPos + Vector3.new(0, 3, 0)} -- Lift slightly above field
	)

	-- Reset velocity
	ballPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	ballPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

	-- Play tween
	resetTween:Play()
	resetTween.Completed:Wait()

	-- Let gravity drop the ball
	task.wait(0.5)
	isReset = false
end

-- Show kick direction indicator
local function showKickDirectionIndicator(player, direction)
	if not CONFIG.ShowKickDirection then return end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	-- Create arrow to show kick direction
	local arrow = Instance.new("Part")
	arrow.Name = "KickDirectionArrow"
	arrow.Size = Vector3.new(0.2, 0.2, 3)
	arrow.Anchored = true
	arrow.CanCollide = false
	arrow.Material = Enum.Material.Neon
	arrow.BrickColor = BrickColor.new("Bright blue")

	-- Position arrow to point in kick direction
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local startPos = rootPart.Position
	local endPos = startPos + direction * 4

	-- Calculate CFrame to position and orient arrow
	arrow.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -1.5)
	arrow.Parent = workspace

	-- Remove after a short time
	Debris:AddItem(arrow, 0.3)
end

-- Show kick effect
local function showKickEffect(position)
	if not CONFIG.KickEffectEnabled then return end

	-- Create a small visual burst effect at kick location
	local burst = Instance.new("Part")
	burst.Name = "KickEffect"
	burst.Shape = Enum.PartType.Ball
	burst.Size = Vector3.new(1, 1, 1)
	burst.Anchored = true
	burst.CanCollide = false
	burst.Material = Enum.Material.Neon
	burst.BrickColor = BrickColor.new("White")
	burst.Transparency = 0.3
	burst.Position = position
	burst.Parent = workspace

	-- Animate the burst
	local growTween = TweenService:Create(
		burst,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(2, 2, 2), Transparency = 1}
	)

	growTween:Play()
	Debris:AddItem(burst, 0.2)

	-- Create dust effect
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = "rbxassetid://284205403" -- Smoke/dust texture
	dust.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	dust.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	dust.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	dust.Lifetime = NumberRange.new(0.3, 0.6)
	dust.Speed = NumberRange.new(3, 6)
	dust.SpreadAngle = Vector2.new(180, 180)
	dust.Acceleration = Vector3.new(0, 2, 0)
	dust.Rate = 0
	dust.Parent = burst

	-- Emit a burst of particles
	dust:Emit(15)
end

-- Handle goal celebrations
local function handleGoal(goalNumber)
	if not CONFIG.GoalScoringEnabled or (tick() - lastGoalTime < 1) then return end

	-- Update score
	if goalNumber == 1 then
		scoreTeam2 = scoreTeam2 + 1
	else
		scoreTeam1 = scoreTeam1 + 1
	end

	-- Update scoreboard
	updateScoreboard()

	-- Play celebration sounds
	playGoalSound()

	-- Show goal effects
	if CONFIG.GoalEffectEnabled then
		-- Create a flashing effect on the goal
		local goalParts = goalNumber == 1 and goal1:GetDescendants() or goal2:GetDescendants()

		for _, part in ipairs(goalParts) do
			if part:IsA("BasePart") then
				-- Store original color
				local originalColor = part.Color

				-- Flash the goal
				for i = 1, 5 do
					part.Color = Color3.fromRGB(255, 255, 0) -- Yellow flash
					task.wait(0.1)
					part.Color = originalColor
					task.wait(0.1)
				end
			end
		end

		-- Create particle effect at the goal
		local goalPosition = goalNumber == 1 and goal1.PrimaryPart.Position or goal2.PrimaryPart.Position

		local celebration = Instance.new("Part")
		celebration.Name = "GoalCelebration"
		celebration.Anchored = true
		celebration.CanCollide = false
		celebration.Transparency = 1
		celebration.Position = goalPosition
		celebration.Parent = workspace

		-- Create confetti particles
		local confetti = Instance.new("ParticleEmitter")
		confetti.Texture = "rbxassetid://8177240723" -- Confetti texture
		confetti.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(50, 255, 50)),
			ColorSequenceKeypoint.new(0.66, Color3.fromRGB(50, 50, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 50))
		})
		confetti.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 0.1)
		})
		confetti.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.8, 0.5),
			NumberSequenceKeypoint.new(1, 1)
		})
		confetti.Lifetime = NumberRange.new(2, 4)
		confetti.Speed = NumberRange.new(10, 20)
		confetti.SpreadAngle = Vector2.new(180, 180)
		confetti.Acceleration = Vector3.new(0, -10, 0)
		confetti.Rate = 50
		confetti.Parent = celebration

		-- Emit for a short time then clean up
		task.delay(2, function()
			confetti.Enabled = false
		end)

		Debris:AddItem(celebration, 5)
	end

	-- Reset the ball if configured
	if CONFIG.ResetBallAfterGoal then
		task.delay(CONFIG.ResetDelay, resetBall)
	end

	-- Update goal time tracker
	lastGoalTime = tick()

	-- Broadcast goal message to all players
	for _, player in ipairs(Players:GetPlayers()) do
		-- Create a goal notification
		local scoringTeam = goalNumber == 1 and CONFIG.Team2Name or CONFIG.Team1Name
		local notification = Instance.new("Message")
		notification.Text = "GOAL! " .. scoringTeam .. " scores!"
		notification.Parent = player

		-- Remove after a few seconds
		task.delay(3, function()
			notification:Destroy()
		end)
	end
end

-- Detect if a goal has been scored
local function detectGoals()
	-- Only check if goal scoring is enabled
	if not CONFIG.GoalScoringEnabled then return end

	-- Set up goal detection
	RunService.Heartbeat:Connect(function()
		-- Check if ball is inside either goal
		if goal1 and ballPart then
			-- Simple goal detection by checking if ball center is within goal bounds
			local goal1Bounds = goal1.PrimaryPart.CFrame
			local goal1Size = goal1.PrimaryPart.Size

			-- Calculate goal boundaries
			local goal1Min = goal1Bounds.Position - goal1Size/2
			local goal1Max = goal1Bounds.Position + goal1Size/2

			-- Check if ball is inside goal1
			if ballPart.Position.X > goal1Min.X and ballPart.Position.X < goal1Max.X and
				ballPart.Position.Y > goal1Min.Y and ballPart.Position.Y < goal1Max.Y and
				ballPart.Position.Z > goal1Min.Z and ballPart.Position.Z < goal1Max.Z then
				handleGoal(1)
			end
		end

		if goal2 and ballPart then
			-- Detect goal2 scoring
			local goal2Bounds = goal2.PrimaryPart.CFrame
			local goal2Size = goal2.PrimaryPart.Size

			-- Calculate goal boundaries
			local goal2Min = goal2Bounds.Position - goal2Size/2
			local goal2Max = goal2Bounds.Position + goal2Size/2

			-- Check if ball is inside goal2
			if ballPart.Position.X > goal2Min.X and ballPart.Position.X < goal2Max.X and
				ballPart.Position.Y > goal2Min.Y and ballPart.Position.Y < goal2Max.Y and
				ballPart.Position.Z > goal2Min.Z and ballPart.Position.Z < goal2Max.Z then
				handleGoal(2)
			end
		end
	end)
end

-- Handle player kicking the ball
local function handleKick(player, isPowerKick)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	-- Get player position
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local playerPos = rootPart.Position

	-- Check if player is close enough to the ball
	local distToBall = (playerPos - ballPart.Position).Magnitude
	if distToBall > CONFIG.KickRange then
		return false -- Too far to kick
	end

	-- Check cooldown
	if (tick() - ballLastKicked) < CONFIG.KickCooldown then
		return false -- Kick is on cooldown
	end

	-- Calculate kick direction and force
	local kickDirection = (ballPart.Position - playerPos).Unit
	kickDirection = Vector3.new(kickDirection.X, 0.1, kickDirection.Z).Unit -- Add slight upward angle

	-- Apply the kick force
	local kickForce = isPowerKick and CONFIG.KickForcePower or CONFIG.KickForceNormal
	ballPart:ApplyImpulse(kickDirection * kickForce)

	-- Add a bit of spin
	local spinFactor = math.random(-10, 10)
	ballPart:ApplyAngularImpulse(Vector3.new(spinFactor, spinFactor, spinFactor))

	-- Update last kicked time
	ballLastKicked = tick()

	-- Play kick sound
	playKickSound()

	-- Show kick visual effects
	showKickDirectionIndicator(player, kickDirection)
	showKickEffect(ballPart.Position)

	-- Track last kicker for goal attribution
	activeKickers[player.UserId] = tick()

	return true
end

-- Set up kicking controls for a player
local function setupPlayerControls(player)
	local function onNormalKick(actionName, inputState)
		if inputState ~= Enum.UserInputState.Begin then return end
		if not CONFIG.ControlsEnabled then return end

		handleKick(player, false)
		return Enum.ContextActionResult.Sink
	end

	local function onPowerKick(actionName, inputState)
		if inputState ~= Enum.UserInputState.Begin then return end
		if not CONFIG.ControlsEnabled then return end

		handleKick(player, true)
		return Enum.ContextActionResult.Sink
	end

	-- Bind kick actions for this player
	local kickActionName = "SoccerKick_" .. player.UserId
	local powerKickActionName = "SoccerPowerKick_" .. player.UserId

	ContextActionService:BindAction(kickActionName, onNormalKick, false, CONFIG.KickKey)
	ContextActionService:BindAction(powerKickActionName, onPowerKick, false, CONFIG.PowerKickKey)

	-- Set title for action
	ContextActionService:SetTitle(kickActionName, "Kick Ball")
	ContextActionService:SetTitle(powerKickActionName, "Power Kick")

	-- Clean up bindings when player leaves
	player.CharacterRemoving:Connect(function()
		ContextActionService:UnbindAction(kickActionName)
		ContextActionService:UnbindAction(powerKickActionName)
		activeKickers[player.UserId] = nil
	end)

	player.CharacterAdded:Connect(function()
		ContextActionService:BindAction(kickActionName, onNormalKick, false, CONFIG.KickKey)
		ContextActionService:BindAction(powerKickActionName, onPowerKick, false, CONFIG.PowerKickKey)
	end)
end

-- Clean up when a player leaves
local function handlePlayerRemoving(player)
	activeKickers[player.UserId] = nil
end

-- Initialize the whole system
local function init()
	-- Store original ball position for resets
	originalBallPosition = ballPart.Position

	-- Set up all major components
	setupBallPhysics()
	setupSounds()
	createScoreboard()
	detectGoals()

	-- Set up controls for all current players
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayerControls(player)
	end

	-- Set up controls for new players
	Players.PlayerAdded:Connect(function(player)
		setupPlayerControls(player)
	end)

	-- Clean up for leaving players
	Players.PlayerRemoving:Connect(handlePlayerRemoving)

	-- Display instructions to players
	Players.PlayerAdded:Connect(function(player)
		-- Create instructions for the player
		local instructions = Instance.new("Message")
		instructions.Text = "Press E to kick the ball\nPress Q for a power kick!"
		instructions.Parent = player

		-- Remove after a few seconds
		task.delay(5, function()
			instructions:Destroy()
		end)
	end)

	print("Soccer Game initialized successfully!")
end

-- Clean up function
local function cleanup()
	for _, player in ipairs(Players:GetPlayers()) do
		local kickActionName = "SoccerKick_" .. player.UserId
		local powerKickActionName = "SoccerPowerKick_" .. player.UserId

		ContextActionService:UnbindAction(kickActionName)
		ContextActionService:UnbindAction(powerKickActionName)
	end

	-- Clean up scoreboard
	if scoreboard then
		scoreboard:Destroy()
	end

	-- Stop all sounds
	for _, sound in ipairs(sounds) do
		if sound:IsA("Sound") and sound.IsPlaying then
			sound:Stop()
		end
	end
end

-- Run initialization
init()

-- Handle script removal
script.AncestryChanged:Connect(function(_, parent)
	if not parent then
		cleanup()
	end
end)