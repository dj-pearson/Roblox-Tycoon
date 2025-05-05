-- Tire Flip Exercise Script
-- Provides realistic tire-flipping mechanics for fitness games
-- Place this script inside the Tire model

local TireFlip = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Configuration
local CONFIG = {
    -- Interaction settings
    MaxInteractionDistance = 8,
    InteractionCooldown = 0.5,
    
    -- Exercise settings
    FlipDuration = 1.2,
    FlipRotation = 180, -- Degrees
    FlipHeight = 3,
    FlipForwardDistance = 2,
    
    -- Statistics
    CaloriesBurnedPerFlip = 8,
    StrengthGainPerFlip = 2,
    
    -- Sound effects
    SoundEnabled = true,
    TireImpactVolume = 0.8,
    TireFlipVolume = 0.6,
    
    -- Physics
    TireMass = 150, -- Visual effect only (for animation)
    GravityFactor = 1.2,
    
    -- Prompts
    PromptText = "Flip Tire",
    PromptKeyCode = Enum.KeyCode.E,
    PromptHoldDuration = 0,
    
    -- Visual effects
    ShowTrajectory = false,
    UseSweatParticles = true,
    
    -- Debug
    DebugMode = false
}

-- Internal variables
local tire = script.Parent
local primaryPart = tire.PrimaryPart or tire:FindFirstChildWhichIsA("BasePart")
local attachments = {}
local activePlayers = {}
local proximityPrompt
local sounds = {}
local particles = {}
local currentlyFlipping = false
local lastFlipTime = 0
local flipCount = 0
local originalCFrame

-- Create visual elements
local function setupVisuals()
    -- Create proximity prompt for interaction
    proximityPrompt = Instance.new("ProximityPrompt")
    proximityPrompt.ObjectText = "Exercise Tire"
    proximityPrompt.ActionText = CONFIG.PromptText
    proximityPrompt.KeyboardKeyCode = CONFIG.PromptKeyCode
    proximityPrompt.HoldDuration = CONFIG.PromptHoldDuration
    proximityPrompt.MaxActivationDistance = CONFIG.MaxInteractionDistance
    proximityPrompt.RequiresLineOfSight = true
    proximityPrompt.Parent = primaryPart
    
    -- Create sound effects
    local impactSound = Instance.new("Sound")
    impactSound.Name = "TireImpact"
    impactSound.SoundId = "rbxassetid://9125573719" -- Heavy impact sound
    impactSound.Volume = CONFIG.TireImpactVolume
    impactSound.Parent = primaryPart
    sounds.impact = impactSound
    
    local flipSound = Instance.new("Sound")
    flipSound.Name = "TireFlip"
    flipSound.SoundId = "rbxassetid://9114221327" -- Whoosh sound
    flipSound.Volume = CONFIG.TireFlipVolume
    flipSound.Parent = primaryPart
    sounds.flip = flipSound
    
    -- Create sweat particles if enabled
    if CONFIG.UseSweatParticles then
        local particle = Instance.new("ParticleEmitter")
        particle.Name = "ExertionParticles"
        particle.Texture = "rbxassetid://278066302" -- Sweat droplet
        particle.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 0.4)
        })
        particle.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.7, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        })
        particle.Lifetime = NumberRange.new(0.5, 1)
        particle.Rate = 0 -- Will be enabled during flipping
        particle.Speed = NumberRange.new(3, 5)
        particle.SpreadAngle = Vector2.new(35, 35)
        particle.Parent = primaryPart
        particles.sweat = particle
    end
end

-- Initialize the physics constraints
local function setupPhysics()
    -- Make sure tire is anchored initially
    for _, part in pairs(tire:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = true
        end
    end
    
    -- Store original position
    originalCFrame = primaryPart.CFrame
end

-- Handle the tire flipping animation
local function flipTire(player)
    if currentlyFlipping or (tick() - lastFlipTime < CONFIG.InteractionCooldown) then
        return false
    end
    
    currentlyFlipping = true
    lastFlipTime = tick()
    flipCount = flipCount + 1
    
    -- Calculate the flip trajectory
    local currentCFrame = primaryPart.CFrame
    local forward = currentCFrame.LookVector
    local up = currentCFrame.UpVector
    local right = currentCFrame.RightVector
    
    -- Determine which way to flip (alternating between forward and backward)
    local flipDirection = forward
    if flipCount % 2 == 0 then
        flipDirection = forward.Unit * -1 -- Flip backward on even counts
    end
    
    -- Define the flip animation keyframes
    local midpointCFrame = currentCFrame
        * CFrame.new(flipDirection * (CONFIG.FlipForwardDistance * 0.5), CONFIG.FlipHeight, 0)
        * CFrame.Angles(math.rad(CONFIG.FlipRotation * 0.5), 0, 0)
    
    local endpointCFrame = currentCFrame
        * CFrame.new(flipDirection * CONFIG.FlipForwardDistance, 0, 0)
        * CFrame.Angles(math.rad(CONFIG.FlipRotation), 0, 0)
    
    -- Create tweening info
    local tweenInfo = TweenInfo.new(
        CONFIG.FlipDuration,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    -- Play the flip sound
    if CONFIG.SoundEnabled then
        sounds.flip:Play()
    end
    
    -- Enable sweat particles
    if CONFIG.UseSweatParticles and particles.sweat then
        particles.sweat.Rate = 20
    end
    
    -- Execute the first half of the flip
    local midTween = TweenService:Create(primaryPart, tweenInfo, {
        CFrame = midpointCFrame
    })
    
    midTween:Play()
    midTween.Completed:Wait()
    
    -- Execute the second half of the flip
    local endTween = TweenService:Create(primaryPart, tweenInfo, {
        CFrame = endpointCFrame
    })
    
    endTween:Play()
    endTween.Completed:Wait()
    
    -- Play impact sound when tire hits the ground
    if CONFIG.SoundEnabled then
        sounds.impact:Play()
    end
    
    -- Reset particles
    if CONFIG.UseSweatParticles and particles.sweat then
        particles.sweat.Rate = 0
    end
    
    -- Grant rewards to the player for completing a flip
    if player then
        -- You can integrate with your game's stat system here
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local strength = leaderstats:FindFirstChild("Strength")
            if strength and strength:IsA("IntValue") then
                strength.Value = strength.Value + CONFIG.StrengthGainPerFlip
            end
            
            local calories = leaderstats:FindFirstChild("CaloriesBurned")
            if calories and calories:IsA("IntValue") then
                calories.Value = calories.Value + CONFIG.CaloriesBurnedPerFlip
            end
        end
    end
    
    currentlyFlipping = false
    return true
end

-- Handle player interactions
local function handlePlayerInteraction()
    proximityPrompt.Triggered:Connect(function(player)
        if not currentlyFlipping then
            -- Optional: play character animation here
            flipTire(player)
        end
    end)
end

-- Debug visualization
local function setupDebug()
    if not CONFIG.DebugMode then return end
    
    -- Create visual indicators for flip trajectory
    local debugFolder = Instance.new("Folder")
    debugFolder.Name = "TireFlipDebug"
    debugFolder.Parent = tire
    
    local startMarker = Instance.new("Part")
    startMarker.Name = "StartPosition"
    startMarker.Size = Vector3.new(0.2, 0.2, 0.2)
    startMarker.Anchored = true
    startMarker.CanCollide = false
    startMarker.BrickColor = BrickColor.new("Bright red")
    startMarker.Material = Enum.Material.Neon
    startMarker.Shape = Enum.PartType.Ball
    startMarker.Parent = debugFolder
    
    local endMarker = startMarker:Clone()
    endMarker.Name = "EndPosition"
    endMarker.BrickColor = BrickColor.new("Bright green")
    endMarker.Parent = debugFolder
    
    -- Update debug markers
    RunService.Heartbeat:Connect(function()
        if not CONFIG.DebugMode then return end
        
        startMarker.Position = primaryPart.Position
        
        local forward = primaryPart.CFrame.LookVector
        if flipCount % 2 == 0 then
            forward = forward * -1
        end
        
        endMarker.Position = primaryPart.Position + (forward * CONFIG.FlipForwardDistance)
    end)
end

-- Reset the tire if it gets stuck or moved too far
local function setupResetHandling()
    RunService.Heartbeat:Connect(function()
        -- Check if tire has fallen below the terrain or moved too far
        if primaryPart.Position.Y < -10 then
            primaryPart.CFrame = originalCFrame
        end
    end)
end

-- Initialize everything
local function init()
    -- Ensure we have a valid primary part
    if not primaryPart then
        if tire:IsA("BasePart") then
            primaryPart = tire
        else
            primaryPart = tire:FindFirstChildWhichIsA("BasePart")
            if not primaryPart then
                warn("Tire Flip Script: No primary part found. Please set a primary part for the tire model.")
                return
            end
        end
    end
    
    setupVisuals()
    setupPhysics()
    handlePlayerInteraction()
    setupDebug()
    setupResetHandling()
    
    -- Store original CFrame for reset functionality
    originalCFrame = primaryPart.CFrame
end

-- Clean up function for when the script is destroyed
local function cleanup()
    if proximityPrompt then
        proximityPrompt:Destroy()
    end
    
    for _, sound in pairs(sounds) do
        sound:Destroy()
    end
    
    for _, particle in pairs(particles) do
        particle:Destroy()
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