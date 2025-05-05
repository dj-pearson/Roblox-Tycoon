-- Soccer Field Client Loader
-- Place this script directly in the SoccerField model
-- It will load the client script from the client folder

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function findClientScript()
    -- Look in common client script locations
    local scriptPath = "client/Model Function/SoccerField.client"
    
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
                clientScript = modelFunctionFolder:FindFirstChild("SoccerField.client.luau")
                if clientScript then
                    return clientScript
                end
            end
        end
        parent = parent.Parent
    end
    
    -- Fallback: Create a temporary script with a warning
    warn("SoccerField: Could not find the client script. Please ensure the client script is properly located at 'client/Model Function/SoccerField.client.luau'")
    return nil
end

local function createLocalScript()
    -- Create a new LocalScript for client-side execution
    local localScript = Instance.new("LocalScript")
    localScript.Name = "SoccerFieldProximityHandler"
    
    -- Try to find the client script
    local clientScript = findClientScript()
    
    if clientScript then
        -- Reuse the source from the client script
        localScript.Source = clientScript.Source
    else
        -- Create a basic proximity script if the client script can't be found
        localScript.Source = [[
-- Basic Proximity Script for Soccer Field Scoreboard
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local soccerField = script.Parent
local scoreboard = soccerField:FindFirstChild("Scoreboard")

-- If scoreboard exists, make it only visible when player is close
if scoreboard then
    scoreboard.Enabled = false
    
    RunService.Heartbeat:Connect(function()
        if character and character:FindFirstChild("HumanoidRootPart") and scoreboard then
            local distance = (humanoidRootPart.Position - soccerField.PrimaryPart.Position).Magnitude
            scoreboard.Enabled = (distance < 30)
        end
    end)
end

-- Handle character changes
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end)

warn("SoccerField: Using basic proximity script. For full functionality, ensure the client script is properly located.")
        ]]
    end
    
    -- Add the local script to the model
    localScript.Parent = script.Parent
end

-- Create the local script
createLocalScript()

-- Self-destruct this script
script:Destroy()
