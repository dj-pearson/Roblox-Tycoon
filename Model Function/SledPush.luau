-- Fitness Sled Push Script
-- Place this script inside the Sled model

local SledPush = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

-- Configuration
local CONFIG = {
    -- Interaction settings
    MaxInteractionDistance = 6,
    InteractionCooldown = 0.5,
    
    -- Exercise settings
    MaxPushSpeed = 15,
    Acceleration = 2.5,
    Deceleration = 4.0,
    SteeringStrength = 1.2,
    WeightResistance = 0.7,  -- Higher values make it harder to push
    
    -- Control settings
    StandUpKey = Enum.KeyCode.Space,
    ReleaseControls = {
        Keyboard = Enum.KeyCode.Space,
        Gamepad = Enum.KeyCode.ButtonB
    },
    
    -- Physics
    SledMass = 120,  -- Higher values make it harder to push (visual only)
    FrictionFactor = 0.2,
    MaxPushForce = 8000,
    
    -- Animation settings
    EnableAnimations = true,
    
    -- Sound effects
    SoundEnabled = true,
    SledMoveSoundVolume = 0.6,
    
    -- Visual effects
    ShowWeightDisplay = true,
    UseStrainEffects = true,
    
    -- Stats tracking
    CaloriesBurnedPerSecond = 2.5,
    StrengthGainMultiplier = 0.05,
    
    -- Debug
    DebugMode = false
}

-- Internal variables
local sled = script.Parent
local primaryPart = sled.PrimaryPart or sled:FindFirstChild("SledBase") or sled:FindFirstChildWhichIsA("BasePart")
local poleLeft = sled:FindFirstChild("Pole Left")
local poleRight = sled:FindFirstChild("Pole Right")
local leftPrompt, rightPrompt
local activePlayers = {}
local sounds = {}
local exertionEffects = {}
local currentVelocity = Vector3.new(0, 0, 0)
local lastUpdateTime = tick()
local playerAnims = {}
local actionName = "SledRelease"

-- Character animation IDs
local ANIMATIONS = {
    SledGrab = 11712650405,  -- Replace with your animation ID for bent-over sled push position
    SledPush = 11712653634   -- Replace with your animation ID for pushing motion
}

-- Setup the required components
local function setupComponents()
    -- Make sure sled parts are set up correctly
    for _, part in pairs(sled:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = true
        end
    end
    
    -- Create proximity prompts for both poles
    leftPrompt = Instance.new("ProximityPrompt")
    leftPrompt.ObjectText = "Sled"
    leftPrompt.ActionText = "Grab Left Handle"
    leftPrompt.KeyboardKeyCode = Enum.KeyCode.E
    leftPrompt.HoldDuration = 0
    leftPrompt.MaxActivationDistance = CONFIG.MaxInteractionDistance
    leftPrompt.RequiresLineOfSight = true
    leftPrompt.Parent = poleLeft
    
    rightPrompt = Instance.new("ProximityPrompt")
    rightPrompt.ObjectText = "Sled"
    rightPrompt.ActionText = "Grab Right Handle"
    rightPrompt.KeyboardKeyCode = Enum.KeyCode.E
    rightPrompt.HoldDuration = 0
    rightPrompt.MaxActivationDistance = CONFIG.MaxInteractionDistance
    rightPrompt.RequiresLineOfSight = true
    rightPrompt.Parent = poleRight
    
    -- Create sound effects
    local sledSound = Instance.new("Sound")
    sledSound.Name = "SledMoving"
    sledSound.SoundId = "rbxassetid://9114184632"  -- Replace with your sound ID
    sledSound.Volume = 0
    sledSound.Looped = true
    sledSound.Parent = primaryPart
    sounds.moving = sledSound
    
    -- Set up weight display if enabled
    if CONFIG.ShowWeightDisplay then
        local weightDisplay = Instance.new("BillboardGui")
        weightDisplay.Name = "WeightDisplay"
        weightDisplay.Size = UDim2.new(0, 150, 0, 50)
        weightDisplay.StudsOffset = Vector3.new(0, 2, 0)
        weightDisplay.Adornee = primaryPart
        weightDisplay.Parent = primaryPart
        
        local weightLabel = Instance.new("TextLabel")
        weightLabel.Name = "WeightLabel"
        weightLabel.Size = UDim2.new(1, 0, 1, 0)
        weightLabel.BackgroundTransparency = 0.5
        weightLabel.BackgroundColor3 = Color3.new(0, 0, 0)
        weightLabel.TextColor3 = Color3.new(1, 1, 1)
        weightLabel.TextScaled = true
        weightLabel.Text = CONFIG.SledMass .. " kg"
        weightLabel.Parent = weightDisplay
    end
    
    -- Start with sled sound stopped
    sounds.moving:Stop()
end

-- Handle player controls and animations
local function setupPlayerControls(player, initialPole)
    if activePlayers[player] then
        return false
    end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then
        return false
    end
    
    -- Create player data structure
    activePlayers[player] = {
        character = character,
        humanoid = character:FindFirstChild("Humanoid"),
        hrp = character:FindFirstChild("HumanoidRootPart"),
        initialPole = initialPole,
        grabTime = tick(),
        movingForward = false,
        steeringDirection = 0,
        animations = {},
        exerciseStartTime = tick(),
        caloriesBurned = 0,
        strengthGained = 0
    }
    
    local playerData = activePlayers[player]
    
    -- Position the character at the pole
    local polePos = initialPole.Position
    local sledFacing = primaryPart.CFrame.LookVector
    local characterPos = polePos - (sledFacing * 1.2)  -- Stand slightly behind the pole
    characterPos = Vector3.new(characterPos.X, primaryPart.Position.Y, characterPos.Z)
    
    -- Face the character toward the sled
    local facingCFrame = CFrame.lookAt(characterPos, polePos)
    playerData.hrp.CFrame = CFrame.new(characterPos) * CFrame.Angles(0, facingCFrame.Y, 0)
    
    -- Set up animations if enabled
    if CONFIG.EnableAnimations then
        -- Load the grab animation
        local grabAnim = Instance.new("Animation")
        grabAnim.AnimationId = "rbxassetid://" .. ANIMATIONS.SledGrab
        playerData.animations.grab = playerData.humanoid:LoadAnimation(grabAnim)
        
        -- Load the push animation
        local pushAnim = Instance.new("Animation")
        pushAnim.AnimationId = "rbxassetid://" .. ANIMATIONS.SledPush
        playerData.animations.push = playerData.humanoid:LoadAnimation(pushAnim)
        
        -- Play the grab animation immediately
        playerData.animations.grab:Play()
    end
    
    -- Disable default controls
    playerData.humanoid.WalkSpeed = 0
    playerData.humanoid.JumpPower = 0
    
    -- Set up custom controls
    local function handleInput(actionName, inputState, inputObject)
        if inputState == Enum.UserInputState.Begin then
            if actionName == "SledMoveForward" then
                playerData.movingForward = true
            elseif actionName == "SledSteerLeft" then
                playerData.steeringDirection = -1
            elseif actionName == "SledSteerRight" then
                playerData.steeringDirection = 1
            elseif actionName == "SledRelease" then
                releaseSled(player)
                return Enum.ContextActionResult.Sink
            end
        elseif inputState == Enum.UserInputState.End then
            if actionName == "SledMoveForward" then
                playerData.movingForward = false
                
                -- Stop push animation
                if playerData.animations.push and playerData.animations.push.IsPlaying then
                    playerData.animations.push:Stop()
                end
                
                -- Resume grab animation
                if playerData.animations.grab and not playerData.animations.grab.IsPlaying then
                    playerData.animations.grab:Play()
                end
            elseif actionName == "SledSteerLeft" and playerData.steeringDirection == -1 then
                playerData.steeringDirection = 0
            elseif actionName == "SledSteerRight" and playerData.steeringDirection == 1 then
                playerData.steeringDirection = 0
            end
        end
        
        return Enum.ContextActionResult.Sink
    end
    
    -- Bind custom controls
    ContextActionService:BindAction("SledMoveForward", handleInput, false, Enum.KeyCode.W, Enum.KeyCode.Up)
    ContextActionService:BindAction("SledSteerLeft", handleInput, false, Enum.KeyCode.A, Enum.KeyCode.Left)
    ContextActionService:BindAction("SledSteerRight", handleInput, false, Enum.KeyCode.D, Enum.KeyCode.Right)
    ContextActionService:BindAction(actionName, handleInput, false, CONFIG.ReleaseControls.Keyboard, CONFIG.ReleaseControls.Gamepad)
    
    -- Update help text
    ContextActionService:SetTitle(actionName, "Stand Up")
    ContextActionService:SetPosition(actionName, UDim2.new(1, -10, 0, 10))
    
    -- Set up exertion effects if enabled
    if CONFIG.UseStrainEffects then
        local exertionParticle = Instance.new("ParticleEmitter")
        exertionParticle.Name = "ExertionParticles"
        exertionParticle.Texture = "rbxassetid://278066302"  -- Sweat droplet
        exertionParticle.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 0.3)
        })
        exertionParticle.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.7, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        })
        exertionParticle.Lifetime = NumberRange.new(0.5, 1)
        exertionParticle.Rate = 0  -- Start with particles off
        exertionParticle.Speed = NumberRange.new(2, 4)
        exertionParticle.SpreadAngle = Vector2.new(35, 35)
        exertionParticle.Parent = character:FindFirstChild("Head")
        
        exertionEffects[player] = exertionParticle
    end
    
    -- Hide prompts while player is using the sled
    leftPrompt.Enabled = false
    rightPrompt.Enabled = false
    
    return true
end

-- Release the sled and restore normal player control
local function releaseSled(player)
    local playerData = activePlayers[player]
    if not playerData then return end
    
    -- Restore normal character control
    if playerData.humanoid then
        playerData.humanoid.WalkSpeed = 16  -- Default walk speed
        playerData.humanoid.JumpPower = 50  -- Default jump power
    end
    
    -- Stop animations
    if playerData.animations.grab then
        playerData.animations.grab:Stop()
    end
    if playerData.animations.push then
        playerData.animations.push:Stop()
    end
    
    -- Unbind controls
    ContextActionService:UnbindAction("SledMoveForward")
    ContextActionService:UnbindAction("SledSteerLeft")
    ContextActionService:UnbindAction("SledSteerRight")
    ContextActionService:UnbindAction(actionName)
    
    -- Remove exertion effects
    if exertionEffects[player] then
        exertionEffects[player]:Destroy()
        exertionEffects[player] = nil
    end
    
    -- Calculate and award exercise stats
    local exerciseDuration = tick() - playerData.exerciseStartTime
    local caloriesBurned = exerciseDuration * CONFIG.CaloriesBurnedPerSecond
    local strengthGained = exerciseDuration * CONFIG.StrengthGainMultiplier
    
    -- Update player stats (integrate with your game's stat system)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local calories = leaderstats:FindFirstChild("CaloriesBurned")
        if calories and calories:IsA("IntValue") then
            calories.Value = calories.Value + math.floor(caloriesBurned)
        end
        
        local strength = leaderstats:FindFirstChild("Strength")
        if strength and strength:IsA("IntValue") or strength:IsA("NumberValue") then
            strength.Value = strength.Value + math.floor(strengthGained)
        end
    end
    
    -- Remove player from active players list
    activePlayers[player] = nil
    
    -- Re-enable prompts
    leftPrompt.Enabled = true
    rightPrompt.Enabled = true
end

-- Update sled physics
local function updateSledPhysics()
    local currentTime = tick()
    local deltaTime = currentTime - lastUpdateTime
    lastUpdateTime = currentTime
    
    -- Don't update if no time has passed or delta is unusually large
    if deltaTime <= 0 or deltaTime > 0.1 then
        return
    end
    
    -- Check if any players are pushing the sled
    local totalPushForce = Vector3.new(0, 0, 0)
    local totalSteeringDirection = 0
    local anyonePushing = false
    local activePlayerCount = 0
    
    for player, playerData in pairs(activePlayers) do
        if playerData.movingForward then
            anyonePushing = true
            activePlayerCount = activePlayerCount + 1
            
            -- Get sled facing direction
            local sledFacing = primaryPart.CFrame.LookVector
            
            -- Apply player's push force
            totalPushForce = totalPushForce + (sledFacing * CONFIG.MaxPushForce)
            
            -- Add steering influence
            totalSteeringDirection = totalSteeringDirection + playerData.steeringDirection
            
            -- Play push animation if not already playing
            if CONFIG.EnableAnimations and playerData.animations.push and not playerData.animations.push.IsPlaying then
                playerData.animations.grab:Stop()
                playerData.animations.push:Play()
            end
            
            -- Enable exertion particles
            if CONFIG.UseStrainEffects and exertionEffects[player] then
                exertionEffects[player].Rate = 10
            end
        else
            -- Disable exertion particles when not pushing
            if CONFIG.UseStrainEffects and exertionEffects[player] then
                exertionEffects[player].Rate = 0
            end
        end
    end
    
    -- Normalize the steering direction if multiple players
    if activePlayerCount > 0 then
        totalSteeringDirection = totalSteeringDirection / activePlayerCount
    end
    
    -- Calculate resistance based on sled weight
    local resistanceFactor = CONFIG.WeightResistance * CONFIG.SledMass / 100
    
    -- Apply physics
    if anyonePushing then
        -- Calculate acceleration with resistance
        local accelerationForce = totalPushForce / (CONFIG.SledMass * resistanceFactor)
        local maxAcceleration = CONFIG.Acceleration / resistanceFactor
        
        -- Limit maximum acceleration
        if accelerationForce.Magnitude > maxAcceleration then
            accelerationForce = accelerationForce.Unit * maxAcceleration
        end
        
        -- Apply acceleration
        currentVelocity = currentVelocity + (accelerationForce * deltaTime)
        
        -- Apply friction to limit max speed
        local maxSpeed = CONFIG.MaxPushSpeed / resistanceFactor
        if currentVelocity.Magnitude > maxSpeed then
            currentVelocity = currentVelocity.Unit * maxSpeed
        end
    else
        -- Apply deceleration when not pushing
        local currentSpeed = currentVelocity.Magnitude
        if currentSpeed > 0 then
            local decelerationAmount = CONFIG.Deceleration * deltaTime
            
            if currentSpeed <= decelerationAmount then
                currentVelocity = Vector3.new(0, 0, 0)
            else
                currentVelocity = currentVelocity * (1 - (decelerationAmount / currentSpeed))
            end
        end
    end
    
    -- Apply steering
    if totalSteeringDirection ~= 0 and currentVelocity.Magnitude > 0.1 then
        -- Rotate the sled direction based on steering input
        local rotationAngle = totalSteeringDirection * CONFIG.SteeringStrength * deltaTime
        local rotationCFrame = CFrame.Angles(0, rotationAngle, 0)
        
        -- Apply rotation to velocity vector
        currentVelocity = (rotationCFrame * CFrame.new(currentVelocity)).Position
        
        -- Also rotate the sled model
        primaryPart.CFrame = primaryPart.CFrame * rotationCFrame
    end
    
    -- Move the sled
    if currentVelocity.Magnitude > 0.01 then
        local movement = currentVelocity * deltaTime
        primaryPart.CFrame = primaryPart.CFrame + movement
        
        -- Update all attached players' positions
        for player, playerData in pairs(activePlayers) do
            local pole = playerData.initialPole
            local polePos = pole.Position
            
            -- Keep player's position relative to their pole
            local sledFacing = primaryPart.CFrame.LookVector
            local characterPos = polePos - (sledFacing * 1.2)
            characterPos = Vector3.new(characterPos.X, primaryPart.Position.Y, characterPos.Z)
            
            -- Update character position
            if playerData.hrp then
                -- Face the character toward the sled
                local facingCFrame = CFrame.lookAt(characterPos, polePos)
                playerData.hrp.CFrame = CFrame.new(characterPos) * CFrame.Angles(0, facingCFrame.Y, 0)
            end
        end
        
        -- Update sound based on movement speed
        if CONFIG.SoundEnabled then
            local speedRatio = math.min(currentVelocity.Magnitude / CONFIG.MaxPushSpeed, 1)
            
            if speedRatio > 0.05 then
                sounds.moving.Volume = CONFIG.SledMoveSoundVolume * speedRatio
                if not sounds.moving.IsPlaying then
                    sounds.moving:Play()
                end
            else
                sounds.moving.Volume = 0
                if sounds.moving.IsPlaying then
                    sounds.moving:Stop()
                end
            end
        end
    else
        -- Stop sound when not moving
        if CONFIG.SoundEnabled and sounds.moving.IsPlaying then
            sounds.moving:Stop()
        end
    end
end

-- Clean up when a player leaves
local function handlePlayerRemoving(player)
    if activePlayers[player] then
        releaseSled(player)
    end
end

-- Initialize the sled system
local function init()
    -- Ensure we have required parts
    if not primaryPart then
        error("Sled Push Script: No primary part found for the sled model.")
        return
    end
    
    if not poleLeft or not poleRight then
        warn("Sled Push Script: Pole Left or Pole Right not found. Make sure they are named correctly.")
        return
    end
    
    -- Set up components
    setupComponents()
    
    -- Connect proximity prompt events
    leftPrompt.Triggered:Connect(function(player)
        setupPlayerControls(player, poleLeft)
    end)
    
    rightPrompt.Triggered:Connect(function(player)
        setupPlayerControls(player, poleRight)
    end)
    
    -- Set up physics update loop
    RunService.Heartbeat:Connect(updateSledPhysics)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(handlePlayerRemoving)
    
    -- Handle character respawns
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            if activePlayers[player] then
                releaseSled(player)
            end
        end)
    end)
    
    for _, player in ipairs(Players:GetPlayers()) do
        player.CharacterAdded:Connect(function()
            if activePlayers[player] then
                releaseSled(player)
            end
        end)
    end
end

-- Clean up function
local function cleanup()
    -- Stop all sounds
    for _, sound in pairs(sounds) do
        sound:Stop()
    end
    
    -- Release all players
    for player, _ in pairs(activePlayers) do
        releaseSled(player)
    end
    
    -- Remove prompts
    if leftPrompt then
        leftPrompt:Destroy()
    end
    if rightPrompt then
        rightPrompt:Destroy()
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