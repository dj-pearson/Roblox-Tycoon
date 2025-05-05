-- Sled Push Client Loader
-- Place this script directly in the SledPush model
-- It will load the client script from the client folder

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function findClientScript()
    -- Look in common client script locations
    local scriptPath = "client/Model Function/SledPush.client"
    
    -- Option 1: Check ReplicatedStorage
    local clientScript = ReplicatedStorage:FindFirstChild(scriptPath)
    if clientScript then
        return clientScript
    end
    
    -- Option 2: Check for a script in game.ServerStorage
    local ServerStorage = game:GetService("ServerStorage")
    clientScript = ServerStorage:FindFirstChild(scriptPath)
    if clientScript then
        return clientScript
    end
    
    -- Option 3: Try to find it in any parent
    local parent = script.Parent
    while parent and parent ~= game do
        local clientFolder = parent:FindFirstChild("client")
        if clientFolder then
            local modelFunctionFolder = clientFolder:FindFirstChild("Model Function")
            if modelFunctionFolder then
                clientScript = modelFunctionFolder:FindFirstChild("SledPush.client.luau")
                if clientScript then
                    return clientScript
                end
            end
        end
        parent = parent.Parent
    end
    
    -- Fallback: Create a temporary script with a warning
    warn("SledPush: Could not find the client script. Please ensure the client script is properly located at 'client/Model Function/SledPush.client.luau'")
    return nil
end

local function createLocalScript()
    -- Create a new LocalScript for client-side execution
    local localScript = Instance.new("LocalScript")
    localScript.Name = "SledPushHandler"
    
    -- Try to find the client script
    local clientScript = findClientScript()
    
    if clientScript then
        -- Reuse the source from the client script
        localScript.Source = clientScript.Source
    else
        -- Create a basic script if the client script can't be found
        localScript.Source = [[
-- Basic Client Script for Sled Push
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local sled = script.Parent
local actionName = "SledRelease"
local activeControlsSetup = false

-- Setup remote events
local remoteFolder = sled:FindFirstChild("Remotes")
if not remoteFolder then
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "Remotes"
    remoteFolder.Parent = sled
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

-- Handle prompt triggers
local function setupPrompts()
    local poleLeft = sled:FindFirstChild("Pole Left")
    local poleRight = sled:FindFirstChild("Pole Right")
    
    if poleLeft and poleLeft:FindFirstChild("LeftPrompt") then
        poleLeft.LeftPrompt.Triggered:Connect(function()
            startPushingRemote:FireServer(poleLeft)
            setupControls()
        end)
    end
    
    if poleRight and poleRight:FindFirstChild("RightPrompt") then
        poleRight.RightPrompt.Triggered:Connect(function()
            startPushingRemote:FireServer(poleRight)
            setupControls()
        end)
    end
end

-- Release controls
local function releaseControls()
    if not activeControlsSetup then return end
    
    ContextActionService:UnbindAction("SledMoveForward")
    ContextActionService:UnbindAction("SledSteerLeft")
    ContextActionService:UnbindAction("SledSteerRight")
    ContextActionService:UnbindAction(actionName)
    
    activeControlsSetup = false
end

-- Handle input
local function setupControls()
    local function handleInput(actionName, inputState, inputObject)
        if actionName == "SledMoveForward" then
            if inputState == Enum.UserInputState.Begin then
                pushForwardRemote:FireServer(true)
            elseif inputState == Enum.UserInputState.End then
                pushForwardRemote:FireServer(false)
            end
        elseif actionName == "SledSteerLeft" then
            if inputState == Enum.UserInputState.Begin then
                steerRemote:FireServer(-1)
            elseif inputState == Enum.UserInputState.End then
                steerRemote:FireServer(0)
            end
        elseif actionName == "SledSteerRight" then
            if inputState == Enum.UserInputState.Begin then
                steerRemote:FireServer(1)
            elseif inputState == Enum.UserInputState.End then
                steerRemote:FireServer(0)
            end
        elseif actionName == "SledRelease" then
            if inputState == Enum.UserInputState.Begin then
                stopPushingRemote:FireServer()
                releaseControls()
            end
        end
        
        return Enum.ContextActionResult.Sink
    end
    
    ContextActionService:BindAction("SledMoveForward", handleInput, false, Enum.KeyCode.W, Enum.KeyCode.Up)
    ContextActionService:BindAction("SledSteerLeft", handleInput, false, Enum.KeyCode.A, Enum.KeyCode.Left)
    ContextActionService:BindAction("SledSteerRight", handleInput, false, Enum.KeyCode.D, Enum.KeyCode.Right)
    ContextActionService:BindAction(actionName, handleInput, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonB)
    
    ContextActionService:SetTitle(actionName, "Stand Up")
    ContextActionService:SetPosition(actionName, UDim2.new(1, -10, 0, 10))
    
    activeControlsSetup = true
end

-- Handle character changes
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    
    if activeControlsSetup then
        stopPushingRemote:FireServer()
        releaseControls()
    end
end)

-- Setup prompts
setupPrompts()

warn("SledPush: Using basic client script. For full functionality, ensure the client script is properly located.")
        ]]
    end
    
    -- Add the local script to the model
    localScript.Parent = script.Parent
end

-- Create the local script
createLocalScript()

-- Self-destruct this script
script:Destroy()
