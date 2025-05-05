-- Fitness Sled Push Server Script
-- Place this script inside a Script in the SledPush model

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

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
    
    -- Physics
    SledMass = 120,  -- Higher values make it harder to push (visual only)
    FrictionFactor = 0.2,
    MaxPushForce = 8000,
    
    -- Sound effects
    SoundEnabled = true,
    SledMoveSoundVolume = 0.6,
    
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
local activePlayers = {}
local sounds = {}
local currentVelocity = Vector3.new(0, 0, 0)
local lastUpdateTime = tick()

-- Setup proximity prompts
local function setupProximityPrompts()
    -- Create proximity prompts for both poles
    local leftPrompt = Instance.new("ProximityPrompt")
    leftPrompt.Name = "LeftPrompt"
    leftPrompt.ObjectText = "Sled"
    leftPrompt.ActionText = "Grab Left Handle"
    leftPrompt.KeyboardKeyCode = Enum.KeyCode.E
    leftPrompt.HoldDuration = 0
    leftPrompt.MaxActivationDistance = CONFIG.MaxInteractionDistance
    leftPrompt.RequiresLineOfSight = true
    leftPrompt.Parent = poleLeft
    
    local rightPrompt = Instance.new("ProximityPrompt")
    rightPrompt.Name = "RightPrompt"
    rightPrompt.ObjectText = "Sled"
    rightPrompt.ActionText = "Grab Right Handle"
    rightPrompt.KeyboardKeyCode = Enum.KeyCode.E
    rightPrompt.HoldDuration = 0
    rightPrompt.MaxActivationDistance = CONFIG.MaxInteractionDistance
    rightPrompt.RequiresLineOfSight = true
    rightPrompt.Parent = poleRight
end

-- Create or find the BillboardGui for weight display
local function setupWeightDisplay()
    -- Remove any existing weight display
    if primaryPart:FindFirstChild("WeightDisplay") then
        primaryPart.WeightDisplay:Destroy()
    end
    
    -- Create a new weight display that's only visible when nearby
    local weightDisplay = Instance.new("BillboardGui")
    weightDisplay.Name = "WeightDisplay"
    weightDisplay.Size = UDim2.new(0, 150, 0, 50)
    weightDisplay.StudsOffset = Vector3.new(0, 2, 0)
    weightDisplay.Adornee = primaryPart
    weightDisplay.MaxDistance = 15  -- Only visible when player is within 15 studs
    weightDisplay.AlwaysOnTop = true
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
    
    return weightDisplay
end

-- Create sound effects
local function setupSounds()
    local sledSound = Instance.new("Sound")
    sledSound.Name = "SledMoving"
    sledSound.SoundId = "rbxassetid://9114184632"  -- Replace with your sound ID
    sledSound.Volume = 0
    sledSound.Looped = true
    sledSound.Parent = primaryPart
    sounds.moving = sledSound
    
    -- Start with sled sound stopped
    sounds.moving:Stop()
end

-- Set up player data when they start using the sled
local function setupPlayerForSled(player, pole)
    if activePlayers[player] then return end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then
        return
    end
    
    -- Create player data structure
    activePlayers[player] = {
        character = character,
        humanoid = character:FindFirstChild("Humanoid"),
        hrp = character:FindFirstChild("HumanoidRootPart"),
        initialPole = pole,
        grabTime = tick(),
        movingForward = false,
        steeringDirection = 0,
        exerciseStartTime = tick(),
        caloriesBurned = 0,
        strengthGained = 0
    }
    
    local playerData = activePlayers[player]
    
    -- Position the character at the pole
    local polePos = pole.Position
    local sledFacing = primaryPart.CFrame.LookVector
    local characterPos = polePos - (sledFacing * 1.2)  -- Stand slightly behind the pole
    characterPos = Vector3.new(characterPos.X, primaryPart.Position.Y, characterPos.Z)
    
    -- Face the character toward the sled
    local facingCFrame = CFrame.lookAt(characterPos, polePos)
    playerData.hrp.CFrame = CFrame.new(characterPos) * CFrame.Angles(0, facingCFrame.Y, 0)
    
    -- Disable default character controls (will be controlled by client)
    playerData.humanoid.WalkSpeed = 0
    playerData.humanoid.JumpPower = 0
    
    -- Disable prompts while player is using the sled
    pole:FindFirstChild(pole.Name == "Pole Left" and "LeftPrompt" or "RightPrompt").Enabled = false
    local otherPole = pole.Name == "Pole Left" and poleRight or poleLeft
    otherPole:FindFirstChild(otherPole.Name == "Pole Left" and "LeftPrompt" or "RightPrompt").Enabled = false
end

-- Release a player from the sled
local function releaseSled(player)
    local playerData = activePlayers[player]
    if not playerData then return end
    
    -- Restore normal character control
    if playerData.humanoid then
        playerData.humanoid.WalkSpeed = 16  -- Default walk speed
        playerData.humanoid.JumpPower = 50  -- Default jump power
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
        if strength and (strength:IsA("IntValue") or strength:IsA("NumberValue")) then
            strength.Value = strength.Value + math.floor(strengthGained)
        end
    end
    
    -- Get pole references before removing player data
    local leftPole = playerData.initialPole.Name == "Pole Left" and playerData.initialPole or poleLeft
    local rightPole = playerData.initialPole.Name == "Pole Right" and playerData.initialPole or poleRight
    
    -- Remove player from active players list
    activePlayers[player] = nil
    
    -- Re-enable prompts
    if leftPole:FindFirstChild("LeftPrompt") then
        leftPole.LeftPrompt.Enabled = true
    end
    
    if rightPole:FindFirstChild("RightPrompt") then
        rightPole.RightPrompt.Enabled = true
    end
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

-- Set up RemoteEvents for client-server communication
local function setupRemoteEvents()
    -- Create a folder to hold all the RemoteEvents
    local remoteFolder = script.Parent:FindFirstChild("Remotes")
    if not remoteFolder then
        remoteFolder = Instance.new("Folder")
        remoteFolder.Name = "Remotes"
        remoteFolder.Parent = script.Parent
    end
    
    -- Create RemoteEvent for starting to push the sled
    local startPushingRemote = remoteFolder:FindFirstChild("StartPushing") or Instance.new("RemoteEvent")
    startPushingRemote.Name = "StartPushing"
    startPushingRemote.Parent = remoteFolder
    
    -- Create RemoteEvent for stopping pushing the sled
    local stopPushingRemote = remoteFolder:FindFirstChild("StopPushing") or Instance.new("RemoteEvent")
    stopPushingRemote.Name = "StopPushing"
    stopPushingRemote.Parent = remoteFolder
    
    -- Create RemoteEvent for push forward action
    local pushForwardRemote = remoteFolder:FindFirstChild("PushForward") or Instance.new("RemoteEvent")
    pushForwardRemote.Name = "PushForward"
    pushForwardRemote.Parent = remoteFolder
    
    -- Create RemoteEvent for steering
    local steerRemote = remoteFolder:FindFirstChild("Steer") or Instance.new("RemoteEvent")
    steerRemote.Name = "Steer"
    steerRemote.Parent = remoteFolder
    
    -- Connect the RemoteEvents to their handlers
    startPushingRemote.OnServerEvent:Connect(function(player, pole)
        if pole and pole:IsDescendantOf(sled) then
            setupPlayerForSled(player, pole)
        end
    end)
    
    stopPushingRemote.OnServerEvent:Connect(function(player)
        releaseSled(player)
    end)
    
    pushForwardRemote.OnServerEvent:Connect(function(player, isPushing)
        if activePlayers[player] then
            activePlayers[player].movingForward = isPushing
        end
    end)
    
    steerRemote.OnServerEvent:Connect(function(player, direction)
        if activePlayers[player] then
            activePlayers[player].steeringDirection = direction
        end
    end)
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
    
    -- Set up all components
    setupProximityPrompts()
    setupWeightDisplay()
    setupSounds()
    setupRemoteEvents()
    
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
end

-- Run initialization
init()

-- Handle script removal
script.AncestryChanged:Connect(function(_, parent)
    if not parent then
        cleanup()
    end
end)
