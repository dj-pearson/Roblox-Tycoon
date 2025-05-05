-- Fitness Sled Push Client Script
-- Place this script inside a LocalScript in the SledPush model

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Configuration
local CONFIG = {
    -- Control settings
    ReleaseControls = {
        Keyboard = Enum.KeyCode.Space,
        Gamepad = Enum.KeyCode.ButtonB
    },
    
    -- Animation settings
    EnableAnimations = true,
    
    -- Animation IDs with fallbacks
    AnimationIDs = {
        SledGrab = {
            11712650405,  -- Primary animation ID
            7814642228,   -- Fallback animation ID 1
            3695300085    -- Fallback animation ID 2
        },
        SledPush = {
            11712653634,  -- Primary animation ID
            7810277536,   -- Fallback animation ID 1
            3695333487    -- Fallback animation ID 2
        }
    },
    
    -- GUI Settings
    EnableGUI = true,
    ShowInstructions = true,
    InstructionDuration = 5, -- seconds
    
    -- Debug settings
    Debug = false
}

-- Variables
local activeControlsSetup = false
local isUsingLeftHandle = false
local animations = {}
local actionName = "SledRelease"
local currentPole = nil
local sledControlGui = nil
local instructionGui = nil

-- Debug function
local function debugPrint(...)
    if CONFIG.Debug then
        print("[SledPush]", ...)
    end
end

-- Forward declarations for functions that reference each other
local releaseControls
local releaseSled
local createSledGui
local destroySledGui

-- Remote events to communicate with server
local remoteFolder = script.Parent:FindFirstChild("Remotes")
if not remoteFolder then
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "Remotes"
    remoteFolder.Parent = script.Parent
end

local startPushingRemote = remoteFolder:FindFirstChild("StartPushing") or Instance.new("RemoteEvent")
startPushingRemote.Name = "StartPushing"
startPushingRemote.Parent = remoteFolder

local stopPushingRemote = remoteFolder:FindFirstChild("StopPushing") or Instance.new("RemoteEvent")
stopPushingRemote.Name = "StopPushing"
stopPushingRemote.Parent = remoteFolder

local pushForwardRemote = remoteFolder:FindFirstChild("PushForward") or Instance.new("RemoteEvent")
pushForwardRemote.Name = "PushForward"
pushForwardRemote.Parent = remoteFolder

local steerRemote = remoteFolder:FindFirstChild("Steer") or Instance.new("RemoteEvent")
steerRemote.Name = "Steer"
steerRemote.Parent = remoteFolder

-- Helper function to create GUI for instructions
local function createInstructionGui(message, duration)
    -- Remove existing instruction GUI if it exists
    if instructionGui then
        instructionGui:Destroy()
        instructionGui = nil
    end
    
    -- Create instruction GUI
    instructionGui = Instance.new("ScreenGui")
    instructionGui.Name = "SledInstructionGui"
    instructionGui.ResetOnSpawn = false
    instructionGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.4, 0, 0.1, 0)
    frame.Position = UDim2.new(0.3, 0, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 0
    frame.Parent = instructionGui
    
    local cornerRadius = Instance.new("UICorner")
    cornerRadius.CornerRadius = UDim.new(0, 8)
    cornerRadius.Parent = frame
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = message
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 18
    textLabel.TextWrapped = true
    textLabel.Parent = frame
    
    instructionGui.Parent = player:FindFirstChild("PlayerGui")
    
    -- Remove after duration
    if duration and duration > 0 then
        task.delay(duration, function()
            if instructionGui then
                instructionGui:Destroy()
                instructionGui = nil
            end
        end)
    end
    
    return instructionGui
end

-- Helper function to create controls GUI
local function createSledGui()
    -- Check if GUI should be enabled
    if not CONFIG.EnableGUI then return end
    
    -- Remove existing GUI if it exists
    if sledControlGui then
        sledControlGui:Destroy()
        sledControlGui = nil
    end
    
    -- Create the GUI
    sledControlGui = Instance.new("ScreenGui")
    sledControlGui.Name = "SledControlGui"
    sledControlGui.ResetOnSpawn = false
    sledControlGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create container frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 240, 0, 120)
    frame.Position = UDim2.new(1, -250, 1, -130)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = sledControlGui
    
    local cornerRadius = Instance.new("UICorner")
    cornerRadius.CornerRadius = UDim.new(0, 8)
    cornerRadius.Parent = frame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.25, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "SLED CONTROLS"
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.Parent = frame
    
    -- Controls list
    local controlsText = {
        "W - Push Forward",
        "A/D - Steer Left/Right",
        "Space - Release Sled"
    }
    
    -- Add control texts
    for i, controlText in ipairs(controlsText) do
        local controlLabel = Instance.new("TextLabel")
        controlLabel.Size = UDim2.new(0.95, 0, 0.2, 0)
        controlLabel.Position = UDim2.new(0.025, 0, 0.25 + (i-1) * 0.25, 0)
        controlLabel.BackgroundTransparency = 1
        controlLabel.Text = controlText
        controlLabel.Font = Enum.Font.SourceSans
        controlLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        controlLabel.TextSize = 16
        controlLabel.TextXAlignment = Enum.TextXAlignment.Left
        controlLabel.Parent = frame
    end
    
    -- Add the GUI to PlayerGui
    sledControlGui.Parent = player:FindFirstChild("PlayerGui")
    
    return sledControlGui
end

-- Helper function to remove the GUI
local function destroySledGui()
    if sledControlGui then
        sledControlGui:Destroy()
        sledControlGui = nil
    end
    
    if instructionGui then
        instructionGui:Destroy()
        instructionGui = nil
    end
end

-- Helper function to load animations with fallbacks
local function loadAnimations()
    if not CONFIG.EnableAnimations then return end
    
    -- Load grab animation with fallbacks
    local grabAnimLoaded = false
    animations.grab = nil
    
    for _, animId in ipairs(CONFIG.AnimationIDs.SledGrab) do
        if grabAnimLoaded then break end
        
        local grabAnim = Instance.new("Animation")
        grabAnim.AnimationId = "rbxassetid://" .. animId
        
        local success, anim = pcall(function()
            return humanoid:LoadAnimation(grabAnim)
        end)
        
        if success and anim then
            animations.grab = anim
            grabAnimLoaded = true
            debugPrint("Successfully loaded grab animation with ID:", animId)
        else
            debugPrint("Failed to load grab animation with ID:", animId)
        end
    end
    
    -- Load push animation with fallbacks
    local pushAnimLoaded = false
    animations.push = nil
    
    for _, animId in ipairs(CONFIG.AnimationIDs.SledPush) do
        if pushAnimLoaded then break end
        
        local pushAnim = Instance.new("Animation")
        pushAnim.AnimationId = "rbxassetid://" .. animId
        
        local success, anim = pcall(function()
            return humanoid:LoadAnimation(pushAnim)
        end)
        
        if success and anim then
            animations.push = anim
            pushAnimLoaded = true
            debugPrint("Successfully loaded push animation with ID:", animId)
        else
            debugPrint("Failed to load push animation with ID:", animId)
        end
    end
    
    -- Verify animations loaded successfully
    if not animations.grab then
        warn("Failed to load any grab animations. Using no animation.")
    end
    
    if not animations.push then
        warn("Failed to load any push animations. Using no animation.")
    end
end

-- Set up the control handlers
local function setupControls()
    local movingForward = false
    local steeringDirection = 0
    
    -- Create the control GUI
    createSledGui()
    
    -- Show instructions if enabled
    if CONFIG.ShowInstructions then
        createInstructionGui("Use W to push forward, A/D to steer, and SPACE to release the sled.", CONFIG.InstructionDuration)
    end
    
    -- Handle input for sled controls
    local function handleInput(actionName, inputState, inputObject)
        if actionName == "SledMoveForward" then
            if inputState == Enum.UserInputState.Begin then
                movingForward = true
                pushForwardRemote:FireServer(true)
                
                -- Play push animation if not already playing
                if animations.push then
                    local success, errorMsg = pcall(function()
                        if not animations.push.IsPlaying then
                            if animations.grab and animations.grab.IsPlaying then
                                animations.grab:Stop()
                            end
                            animations.push:Play()
                        end
                    end)
                    
                    if not success then
                        warn("Failed to play push animation:", errorMsg)
                    end
                end
            elseif inputState == Enum.UserInputState.End then
                movingForward = false
                pushForwardRemote:FireServer(false)
                
                -- Switch back to grab animation
                local success, errorMsg = pcall(function()
                    if animations.push and animations.push.IsPlaying then
                        animations.push:Stop()
                    end
                    
                    if animations.grab and not animations.grab.IsPlaying then
                        animations.grab:Play()
                    end
                end)
                
                if not success then
                    warn("Failed to switch back to grab animation:", errorMsg)
                end
            end
        elseif actionName == "SledSteerLeft" then
            if inputState == Enum.UserInputState.Begin then
                steeringDirection = -1
                steerRemote:FireServer(-1)
            elseif inputState == Enum.UserInputState.End and steeringDirection == -1 then
                steeringDirection = 0
                steerRemote:FireServer(0)
            end
        elseif actionName == "SledSteerRight" then
            if inputState == Enum.UserInputState.Begin then
                steeringDirection = 1
                steerRemote:FireServer(1)
            elseif inputState == Enum.UserInputState.End and steeringDirection == 1 then
                steeringDirection = 0
                steerRemote:FireServer(0)
            end
        elseif actionName == "SledRelease" then
            if inputState == Enum.UserInputState.Begin then
                releaseSled()
            end
        end
        
        return Enum.ContextActionResult.Sink
    end
    
    -- Bind control actions
    ContextActionService:BindAction("SledMoveForward", handleInput, false, Enum.KeyCode.W, Enum.KeyCode.Up)
    ContextActionService:BindAction("SledSteerLeft", handleInput, false, Enum.KeyCode.A, Enum.KeyCode.Left)
    ContextActionService:BindAction("SledSteerRight", handleInput, false, Enum.KeyCode.D, Enum.KeyCode.Right)
    ContextActionService:BindAction(actionName, handleInput, false, CONFIG.ReleaseControls.Keyboard, CONFIG.ReleaseControls.Gamepad)
    
    -- Set help text
    ContextActionService:SetTitle(actionName, "Stand Up")
    ContextActionService:SetPosition(actionName, UDim2.new(1, -10, 0, 10))
    
    activeControlsSetup = true
end

-- Clean up controls when released
local function releaseControls()
    if not activeControlsSetup then return end
    
    ContextActionService:UnbindAction("SledMoveForward")
    ContextActionService:UnbindAction("SledSteerLeft")
    ContextActionService:UnbindAction("SledSteerRight")
    ContextActionService:UnbindAction(actionName)
    
    -- Stop animations
    if animations.grab then
        animations.grab:Stop()
    end
    if animations.push then
        animations.push:Stop()
    end
    
    -- Remove the GUI
    destroySledGui()
    
    activeControlsSetup = false
end

-- Handler for when player starts using the sled
local function startUsingSled(pole)
    -- Double-check we're not already using the sled
    if activeControlsSetup then
        warn("Already using sled, ignoring additional request")
        return
    end
    
    -- Validate pole
    if not pole or not pole:IsA("BasePart") then
        warn("Invalid pole passed to startUsingSled")
        return
    end
    
    -- Load animations with error handling
    local success, errorMsg = pcall(loadAnimations)
    if not success then
        warn("Failed to load animations:", errorMsg)
        -- Continue anyway, animations aren't critical
    end
    
    -- Setup controls
    success, errorMsg = pcall(setupControls)
    if not success then
        warn("Failed to setup controls:", errorMsg)
        -- If controls fail, we should abort
        return
    end
    
    -- Play grab animation with error handling
    if animations.grab then
        success, errorMsg = pcall(function()
            animations.grab:Play()
        end)
        
        if not success then
            warn("Failed to play grab animation:", errorMsg)
            -- Continue anyway, animation isn't critical
        end
    end
    
    -- Track which pole we're using
    currentPole = pole
    isUsingLeftHandle = (pole.Name == "Pole Left")
    
    -- Tell server we're using the sled
    success, errorMsg = pcall(function()
        startPushingRemote:FireServer(pole)
    end)
    
    if not success then
        warn("Failed to notify server about starting to push:", errorMsg)
        -- This is a critical failure, cleanup and abort
        releaseControls()
        currentPole = nil
        isUsingLeftHandle = false
    end
end

-- Handler for when player stops using the sled
local function releaseSled()
    releaseControls()
    
    -- Tell server we're done using the sled
    local success, errorMsg = pcall(function()
        stopPushingRemote:FireServer()
    end)
    
    if not success then
        warn("Failed to notify server about stopping:", errorMsg)
    end
    
    -- Reset state
    currentPole = nil
    isUsingLeftHandle = false
end

-- Function to handle proximity prompt interactions
local function handlePromptTrigger(prompt)
    -- Check if we're already using the sled
    if activeControlsSetup then
        debugPrint("Already using the sled, ignoring additional prompt.")
        return
    end
    
    -- Make sure the prompt exists and is the correct type
    if not prompt or not prompt:IsA("ProximityPrompt") then
        warn("Invalid prompt received in handlePromptTrigger")
        return
    end
    
    -- Verify it's one of our prompts
    if prompt.Name ~= "LeftPrompt" and prompt.Name ~= "RightPrompt" then
        warn("Unknown prompt triggered:", prompt.Name)
        return
    end
    
    -- Get the pole
    local pole = prompt.Parent
    if not pole then
        warn("Prompt has no parent (pole)")
        return
    end
    
    -- Start using the sled with error handling
    local success, errorMsg = pcall(function()
        startUsingSled(pole)
    end)
    
    if not success then
        warn("Failed to start using sled:", errorMsg)
        -- Try to reset state in case of error
        if activeControlsSetup then
            releaseControls()
        end
    end
end

-- Listen for proximity prompt triggers
local function setupPromptListeners()
    local sled = script.Parent
    
    -- Safely find the poles and prompts
    local poleLeft = sled:FindFirstChild("Pole Left")
    local poleRight = sled:FindFirstChild("Pole Right")
    
    -- Setup left prompt connection
    if poleLeft then
        local leftPrompt = poleLeft:FindFirstChild("LeftPrompt") 
        if leftPrompt and leftPrompt:IsA("ProximityPrompt") then
            leftPrompt.Triggered:Connect(function()
                handlePromptTrigger(leftPrompt)
            end)
            debugPrint("Connected left prompt")
        else
            warn("SledPush.client: Left prompt not found or not a ProximityPrompt")
            
            -- Create a prompt if it doesn't exist
            if not leftPrompt then
                leftPrompt = Instance.new("ProximityPrompt")
                leftPrompt.Name = "LeftPrompt"
                leftPrompt.ActionText = "Grab Left Handle"
                leftPrompt.ObjectText = "Fitness Sled"
                leftPrompt.KeyboardKeyCode = Enum.KeyCode.E
                leftPrompt.HoldDuration = 0
                leftPrompt.MaxActivationDistance = 6
                leftPrompt.Parent = poleLeft
                
                leftPrompt.Triggered:Connect(function()
                    handlePromptTrigger(leftPrompt)
                end)
                debugPrint("Created and connected left prompt")
            end
        end
    else
        warn("SledPush.client: Pole Left not found")
    end
    
    -- Setup right prompt connection
    if poleRight then
        local rightPrompt = poleRight:FindFirstChild("RightPrompt")
        if rightPrompt and rightPrompt:IsA("ProximityPrompt") then
            rightPrompt.Triggered:Connect(function()
                handlePromptTrigger(rightPrompt)
            end)
            debugPrint("Connected right prompt")
        else
            warn("SledPush.client: Right prompt not found or not a ProximityPrompt")
            
            -- Create a prompt if it doesn't exist
            if not rightPrompt then
                rightPrompt = Instance.new("ProximityPrompt")
                rightPrompt.Name = "RightPrompt"
                rightPrompt.ActionText = "Grab Right Handle"
                rightPrompt.ObjectText = "Fitness Sled"
                rightPrompt.KeyboardKeyCode = Enum.KeyCode.E
                rightPrompt.HoldDuration = 0
                rightPrompt.MaxActivationDistance = 6
                rightPrompt.Parent = poleRight
                
                rightPrompt.Triggered:Connect(function()
                    handlePromptTrigger(rightPrompt)
                end)
                debugPrint("Created and connected right prompt")
            end
        end
    else
        warn("SledPush.client: Pole Right not found")
    end
    
    -- Wait for poles to be added if they don't exist yet
    if not poleLeft or not poleRight then
        sled.ChildAdded:Connect(function(child)
            if child.Name == "Pole Left" or child.Name == "Pole Right" then
                -- Re-run setup after a short delay to allow all children to be added
                task.delay(0.5, setupPromptListeners)
            end
        end)
    end
end

-- Clean up any existing UI when script is destroyed
local function cleanupOnDestroy()
    destroySledGui()
    
    if activeControlsSetup then
        releaseControls()
    end
end

-- Handle character changes
local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    
    -- If we were using the sled, release it
    if activeControlsSetup then
        releaseSled()
    end
    
    -- Re-load animations for new character
    loadAnimations()
end

-- Connect character changes
player.CharacterAdded:Connect(onCharacterAdded)

-- Handle connection cleanup when script is destroyed
script.AncestryChanged:Connect(function(_, newParent)
    if not newParent then
        cleanupOnDestroy()
    end
end)

-- Check for existing proximity prompts
setupPromptListeners()

-- Debug message on initialization
debugPrint("SledPush client script initialized successfully")
