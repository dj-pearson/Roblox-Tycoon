-- Giant Beach Ball Interactive Physics Script
-- Place this script inside the Beach Ball model

local BeachBall = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local DebugService = game:GetService("DebugService")

-- Configuration
local CONFIG = {
    -- Physics properties
    Mass = 20,              -- Higher = harder to move
    Elasticity = 1.0,       -- Bounciness factor (0-1)
    MaxVelocity = 50,       -- Max speed the ball can travel
    
    -- Interaction properties
    WalkPushForce = 800,    -- Force applied when walking into ball
    JumpBounceForce = 3000, -- Force applied when jumping on ball
    JumpBoostForce = 1800,  -- Force applied to player when bouncing
    
    -- Detection settings
    InteractionRadius = 6,  -- Radius from ball center to detect players
    JumpDetectionHeight = 2,-- Height above ball to detect jumps
    
    -- Collision settings
    CustomCollisionGroup = "BeachBall",
    
    -- Visual effects
    SquishFactor = 0.15,    -- How much the ball squishes on impact (0-1)
    SquishRecoveryTime = 0.3, -- How quickly the ball returns to shape
    
    -- Sound effects
    SoundEnabled = true,
    BounceSoundIds = {
        "rbxassetid://6607204501", -- Replace with your bounce sound IDs
        "rbxassetid://6607204119"
    },
    SquishSoundIds = {
        "rbxassetid://6264371142", -- Replace with your squish sound IDs
        "rbxassetid://6264371346"
    },
    
    -- Fun features
    EnableSplashEffect = true,
    EnableBeachParticles = true,
    EnableWaterDroplets = true,
    
    -- Debug
    DebugMode = false
}

-- Internal variables
local ball = script.Parent
local ballPart = ball:FindFirstChild("Beach Ball") or ball.PrimaryPart or ball:FindFirstChildWhichIsA("BasePart")
local originalSize = ballPart.Size
local activePlayers = {}
local sounds = {}
local effects = {}
local lastPlayerJump = {}
local ballVelocity = Vector3.new(0, 0, 0)
local lastPosition = ballPart.Position
local lastUpdateTime = tick()
local isSquishedFromJump = false

-- Initialize physics properties
local function setupPhysics()
    -- Ensure the ball has proper physics properties
    ballPart.CustomPhysicalProperties = PhysicalProperties.new(
        CONFIG.Mass / 100, -- Density
        0.3,               -- Friction
        CONFIG.Elasticity, -- Elasticity (restitution)
        1,                 -- Friction weight
        CONFIG.Elasticity  -- Elasticity weight
    )
    
    -- Make parts unanchored for physics
    ballPart.Anchored = false
    
    -- Make sure collision is enabled
    ballPart.CanCollide = true
    
    -- Adjust collision properties
    if PhysicsService:IsCollisionGroupRegistered(CONFIG.CustomCollisionGroup) == false then
        PhysicsService:RegisterCollisionGroup(CONFIG.CustomCollisionGroup)
        PhysicsService:CollisionGroupSetCollidable(CONFIG.CustomCollisionGroup, "Default", true)
    end
    PhysicsService:SetPartCollisionGroup(ballPart, CONFIG.CustomCollisionGroup)
    
    -- Set up custom constraints to limit rotation/movement if needed
    local attachment = Instance.new("Attachment")
    attachment.Parent = ballPart
    
    -- Add linear velocity constraint to prevent excessive sliding
    local velocityConstraint = Instance.new("LinearVelocity")
    velocityConstraint.MaxForce = 1000
    velocityConstraint.VectorVelocity = Vector3.new(0, 0, 0) -- Will be updated during play
    velocityConstraint.Attachment0 = attachment
    velocityConstraint.RelativeTo = Enum.ActuatorRelativeTo.World
    velocityConstraint.Parent = ballPart
    
    -- Track this for later updates
    BeachBall.velocityConstraint = velocityConstraint
end

-- Set up visual and audio effects
local function setupEffects()
    -- Create bounce sounds
    for i, soundId in ipairs(CONFIG.BounceSoundIds) do
        local sound = Instance.new("Sound")
        sound.Name = "BounceSound" .. i
        sound.SoundId = soundId
        sound.Volume = 0.8
        sound.RollOffMode = Enum.RollOffMode.LinearSquare
        sound.RollOffMaxDistance = 100
        sound.RollOffMinDistance = 5
        sound.Parent = ballPart
        
        table.insert(sounds, sound)
    end
    
    -- Create squish sounds
    for i, soundId in ipairs(CONFIG.SquishSoundIds) do
        local sound = Instance.new("Sound")
        sound.Name = "SquishSound" .. i
        sound.SoundId = soundId
        sound.Volume = 0.6
        sound.RollOffMode = Enum.RollOffMode.LinearSquare
        sound.RollOffMaxDistance = 100
        sound.RollOffMinDistance = 5
        sound.Parent = ballPart
        
        table.insert(sounds, sound)
    end
    
    -- Create splash effect
    if CONFIG.EnableSplashEffect then
        local splashEffect = Instance.new("ParticleEmitter")
        splashEffect.Name = "SplashEffect"
        splashEffect.Texture = "rbxassetid://141116476" -- Water splash texture
        splashEffect.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
        splashEffect.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 1),
            NumberSequenceKeypoint.new(1, 0)
        })
        splashEffect.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.7, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        })
        splashEffect.Lifetime = NumberRange.new(0.5, 1)
        splashEffect.Speed = NumberRange.new(10, 15)
        splashEffect.SpreadAngle = Vector2.new(50, 50)
        splashEffect.Rate = 0 -- Only emit when jumped on
        splashEffect.Parent = ballPart
        
        effects.splash = splashEffect
    end
    
    -- Create beach particles (sand/dust)
    if CONFIG.EnableBeachParticles then
        local beachParticles = Instance.new("ParticleEmitter")
        beachParticles.Name = "BeachParticles"
        beachParticles.Texture = "rbxassetid://95648201" -- Dust/sand texture
        beachParticles.Color = ColorSequence.new(Color3.fromRGB(245, 224, 179)) -- Sandy color
        beachParticles.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 0.1)
        })
        beachParticles.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(0.8, 0.7),
            NumberSequenceKeypoint.new(1, 1)
        })
        beachParticles.Lifetime = NumberRange.new(1, 2)
        beachParticles.Speed = NumberRange.new(1, 3)
        beachParticles.SpreadAngle = Vector2.new(40, 40)
        beachParticles.Rate = 5 -- Continuous low emission
        beachParticles.Parent = ballPart
        
        effects.beach = beachParticles
    end
    
    -- Create water droplet trail effect
    if CONFIG.EnableWaterDroplets then
        local waterTrail = Instance.new("Trail")
        waterTrail.Name = "WaterTrail"
        waterTrail.Color = ColorSequence.new(Color3.fromRGB(79, 167, 255)) -- Light blue water color
        waterTrail.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.7),
            NumberSequenceKeypoint.new(1, 1)
        })
        waterTrail.WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0)
        })
        waterTrail.Lifetime = 0.5
        waterTrail.Enabled = false -- Only enable when ball is moving fast
        
        local trailAttach0 = Instance.new("Attachment")
        trailAttach0.Position = Vector3.new(0, 0, -ballPart.Size.Z/2)
        trailAttach0.Parent = ballPart
        
        local trailAttach1 = Instance.new("Attachment")
        trailAttach1.Position = Vector3.new(0, 0, ballPart.Size.Z/2)
        trailAttach1.Parent = ballPart
        
        waterTrail.Attachment0 = trailAttach0
        waterTrail.Attachment1 = trailAttach1
        waterTrail.Parent = ballPart
        
        effects.waterTrail = waterTrail
    end
end

-- Play a random sound from a sound category
local function playRandomSound(category)
    if not CONFIG.SoundEnabled then return end
    
    local soundsToChooseFrom = {}
    
    if category == "bounce" then
        soundsToChooseFrom = CONFIG.BounceSoundIds
    elseif category == "squish" then
        soundsToChooseFrom = CONFIG.SquishSoundIds
    end
    
    if #soundsToChooseFrom == 0 then return end
    
    local randomIndex = math.random(1, #soundsToChooseFrom)
    local soundId = soundsToChooseFrom[randomIndex]
    
    for _, sound in ipairs(sounds) do
        if sound.SoundId == soundId then
            sound:Play()
            break
        end
    end
end

-- Apply squish effect to the ball
local function squishBall(direction, strength)
    if isSquishedFromJump then return end -- Don't squish if already squished
    
    local squishAmount = strength * CONFIG.SquishFactor
    
    -- Calculate the squish direction based on impact
    local squishDirection = direction.Unit
    
    -- Create a new size that's squished in the impact direction
    local newSizeX = originalSize.X * (1 - squishAmount * math.abs(squishDirection.X))
    local newSizeY = originalSize.Y * (1 - squishAmount * math.abs(squishDirection.Y))
    local newSizeZ = originalSize.Z * (1 - squishAmount * math.abs(squishDirection.Z))
    
    local newSize = Vector3.new(newSizeX, newSizeY, newSizeZ)
    
    -- Tween the ball to the squished size
    local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local sizeTween = TweenService:Create(ballPart, tweenInfo, {Size = newSize})
    sizeTween:Play()
    
    -- Play squish sound
    playRandomSound("squish")
    
    -- Return to original size after a delay
    task.delay(CONFIG.SquishRecoveryTime, function()
        if not ballPart or not ballPart.Parent then return end
        
        local recoverTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
        local recoverTween = TweenService:Create(ballPart, recoverTweenInfo, {Size = originalSize})
        recoverTween:Play()
        
        isSquishedFromJump = false
    end)
end

-- Detect if a player is jumping onto the ball
local function detectPlayerJump(player, character)
    if not character or not player then return false end
    
    -- Get necessary parts
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return false end
    
    -- Check if player is falling onto the ball
    local verticalVelocity = humanoid.FloorMaterial == Enum.Material.Air and rootPart.AssemblyLinearVelocity.Y or 0
    local distanceAboveBall = (rootPart.Position.Y - ballPart.Position.Y) - (rootPart.Size.Y/2 + ballPart.Size.Y/2)
    
    -- Detect if player was on ground recently and is now in air above ball
    local isJumpingOnBall = verticalVelocity < -5 and
                           distanceAboveBall < CONFIG.JumpDetectionHeight and
                           distanceAboveBall > 0 and
                           (rootPart.Position - ballPart.Position).Magnitude < ballPart.Size.Magnitude/2 + 3
    
    -- Prevent multiple jump detections in a short period
    if isJumpingOnBall then
        local currentTime = tick()
        if lastPlayerJump[player.UserId] and (currentTime - lastPlayerJump[player.UserId]) < 1 then
            return false
        end
        lastPlayerJump[player.UserId] = currentTime
        return true
    end
    
    return false
end

-- Handle player walking into the ball
local function handlePlayerWalk(player, character, contactPoint)
    if not character or not player then return end
    
    -- Get necessary parts
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    -- Only consider players on the ground
    if humanoid.FloorMaterial == Enum.Material.Air then return end
    
    -- Calculate push direction
    local pushDirection = (ballPart.Position - rootPart.Position).Unit
    pushDirection = Vector3.new(pushDirection.X, 0, pushDirection.Z).Unit -- Keep it horizontal
    
    -- Calculate push force based on player's movement
    local playerVelocity = rootPart.AssemblyLinearVelocity
    local playerSpeed = Vector3.new(playerVelocity.X, 0, playerVelocity.Z).Magnitude
    local pushForce = pushDirection * CONFIG.WalkPushForce * (playerSpeed / 16)
    
    -- Apply force to the ball
    ballPart:ApplyImpulse(pushForce)
    
    -- Apply slight visual effects
    squishBall(pushDirection * -1, 0.3)
    
    -- Play soft bounce sound if moving fast enough
    if playerSpeed > 8 then
        playRandomSound("bounce")
    end
    
    -- Debug visualization
    if CONFIG.DebugMode then
        local arrowLength = pushForce.Magnitude / 100
        local arrow = Instance.new("Part")
        arrow.Size = Vector3.new(0.2, 0.2, arrowLength)
        arrow.Anchored = true
        arrow.CanCollide = false
        arrow.BrickColor = BrickColor.new("Bright blue")
        arrow.Material = Enum.Material.Neon
        arrow.CFrame = CFrame.new(contactPoint, contactPoint + pushDirection) * CFrame.new(0, 0, -arrowLength/2)
        arrow.Parent = workspace
        game:GetService("Debris"):AddItem(arrow, 1)
    end
end

-- Handle player jumping onto the ball
local function handlePlayerJump(player, character)
    if not character or not player then return end
    
    -- Get necessary parts
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    -- Set jump flag to prevent multiple squishes
    isSquishedFromJump = true
    
    -- Calculate bounce direction (mostly upward)
    local bounceDirection = Vector3.new(
        (rootPart.Position.X - ballPart.Position.X) * 0.2, 
        1, 
        (rootPart.Position.Z - ballPart.Position.Z) * 0.2
    ).Unit
    
    -- Apply strong force to the ball
    ballPart:ApplyImpulse(bounceDirection * -CONFIG.JumpBounceForce)
    
    -- Apply upward force to the player
    rootPart:ApplyImpulse(Vector3.new(0, CONFIG.JumpBoostForce, 0))
    
    -- Apply strong squish effect
    squishBall(Vector3.new(0, -1, 0), 0.8)
    
    -- Play bounce sound
    playRandomSound("bounce")
    
    -- Create splash effect
    if CONFIG.EnableSplashEffect and effects.splash then
        -- Burst particles
        effects.splash:Emit(30)
    end
    
    -- Debug visualization
    if CONFIG.DebugMode then
        local bouncePoint = rootPart.Position - Vector3.new(0, rootPart.Size.Y/2, 0)
        
        local jumpSphere = Instance.new("Part")
        jumpSphere.Shape = Enum.PartType.Ball
        jumpSphere.Size = Vector3.new(1, 1, 1)
        jumpSphere.Anchored = true
        jumpSphere.CanCollide = false
        jumpSphere.BrickColor = BrickColor.new("Bright red")
        jumpSphere.Material = Enum.Material.Neon
        jumpSphere.Position = bouncePoint
        jumpSphere.Parent = workspace
        game:GetService("Debris"):AddItem(jumpSphere, 1)
    end
end

-- Update ball physics and effects
local function updateBall()
    -- Calculate actual velocity
    local currentTime = tick()
    local deltaTime = currentTime - lastUpdateTime
    lastUpdateTime = currentTime
    
    if deltaTime > 0 then
        local currentPosition = ballPart.Position
        local positionDelta = currentPosition - lastPosition
        ballVelocity = positionDelta / deltaTime
        lastPosition = currentPosition
        
        -- Update velocity constraint if needed
        if ballVelocity.Magnitude > CONFIG.MaxVelocity then
            ballVelocity = ballVelocity.Unit * CONFIG.MaxVelocity
            if BeachBall.velocityConstraint then
                BeachBall.velocityConstraint.VectorVelocity = ballVelocity
            end
        end
        
        -- Update water trail effect based on speed
        if CONFIG.EnableWaterDroplets and effects.waterTrail then
            effects.waterTrail.Enabled = ballVelocity.Magnitude > 15
        end
        
        -- Update beach particles based on movement
        if CONFIG.EnableBeachParticles and effects.beach then
            effects.beach.Rate = math.min(5 + ballVelocity.Magnitude, 40)
        end
    end
    
    -- Check for player collisions
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local character = player.Character
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            
            -- Check distance to ball
            local distanceToPlayer = (rootPart.Position - ballPart.Position).Magnitude
            if distanceToPlayer < CONFIG.InteractionRadius + ballPart.Size.Magnitude/2 then
                -- First check for jumps
                if detectPlayerJump(player, character) then
                    handlePlayerJump(player, character)
                else
                    -- Then check if they're walking into the ball (within collision distance)
                    if distanceToPlayer < ballPart.Size.Magnitude/2 + rootPart.Size.Magnitude/2 + 1 then
                        local contactPoint = ballPart.Position + (rootPart.Position - ballPart.Position).Unit * ballPart.Size.Magnitude/2
                        handlePlayerWalk(player, character, contactPoint)
                    end
                end
            end
        end
    end
    
    -- Keep ball above ground level
    if ballPart.Position.Y < ballPart.Size.Y/2 + 0.5 then
        local groundHeight = ballPart.Size.Y/2 + 0.5
        ballPart.Position = Vector3.new(ballPart.Position.X, groundHeight, ballPart.Position.Z)
        
        -- Bounce if hitting ground with velocity
        if ballVelocity.Y < -5 then
            -- Apply upward impulse
            local bounceForce = Vector3.new(ballVelocity.X * 0.3, -ballVelocity.Y * 0.8, ballVelocity.Z * 0.3)
            ballPart:ApplyImpulse(bounceForce)
            
            -- Play bounce sound
            if ballVelocity.Y < -10 then
                playRandomSound("bounce")
            end
            
            -- Apply squish effect if impact is strong
            if ballVelocity.Y < -15 then
                squishBall(Vector3.new(0, -1, 0), 0.5)
            end
        end
    end
end

-- Initialize the system
local function init()
    -- Verify we have the ball part
    if not ballPart then
        error("Beach Ball Script: No valid ball part found.")
        return
    end
    
    -- Store original properties
    originalSize = ballPart.Size
    
    -- Set up physics and effects
    setupPhysics()
    setupEffects()
    
    -- Create a physics update loop
    RunService.Heartbeat:Connect(updateBall)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        lastPlayerJump[player.UserId] = nil
    end)
    
    -- Debug mode display
    if CONFIG.DebugMode then
        local debugAttach = Instance.new("Attachment")
        debugAttach.Parent = ballPart
        
        local debugVector = Instance.new("VectorForce")
        debugVector.Attachment0 = debugAttach
        debugVector.Force = Vector3.new(0, 0, 0)
        debugVector.RelativeTo = Enum.ActuatorRelativeTo.World
        debugVector.Visible = true
        debugVector.Parent = ballPart
        
        RunService.Heartbeat:Connect(function()
            debugVector.Force = ballVelocity * 10
        end)
    end
    
    print("Beach Ball Interactive Physics initialized successfully!")
end

-- Clean up function
local function cleanup()
    -- Nothing specific needed for cleanup in this case
    -- Physics objects are automatically cleaned up when the ball is removed
end

-- Run initialization
init()

-- Handle script removal
script.AncestryChanged:Connect(function(_, parent)
    if not parent then
        cleanup()
    end
end)