-- LightToggleSystem
-- Server script that adds light toggle functionality to lamps

local LightToggleSystem = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Constants
local LIGHT_COLOR_ON = Color3.fromRGB(248, 248, 248)
local LIGHT_COLOR_OFF = Color3.fromRGB(100, 100, 100) -- Dark grey when off
local DEFAULT_BRIGHTNESS = 1 -- Default brightness of the PointLight
local DEFAULT_RANGE = 15 -- Default range of the PointLight

-- Initialize light toggle system
function LightToggleSystem.init()
    -- Find all lights in the workspace
    LightToggleSystem.setupAllLights()
    
    -- Connect to workspace changes to set up new lights
    workspace.DescendantAdded:Connect(function(descendant)
        if descendant.Name == "Light" and descendant:IsA("BasePart") then
            -- Wait a moment for the light to fully load its children
            task.delay(0.5, function()
                LightToggleSystem.setupLight(descendant)
            end)
        end
    end)
    
    print("Light Toggle System Initialized")
    return LightToggleSystem
end

-- Find and set up all lights in the workspace
function LightToggleSystem.setupAllLights()
    local lights = workspace:GetDescendants()
    local count = 0
    
    for _, instance in ipairs(lights) do
        if instance.Name == "Light" and instance:IsA("BasePart") then
            LightToggleSystem.setupLight(instance)
            count = count + 1
        end
    end
    
    print("Set up " .. count .. " lights")
end

-- Set up a single light with toggle functionality
function LightToggleSystem.setupLight(lightPart)
    -- Skip if already set up
    if lightPart:FindFirstChild("LightTogglePrompt") then
        return
    end
    
    -- Store original light properties
    local pointLight = lightPart:FindFirstChild("PointLight")
    if not pointLight and lightPart:FindFirstChild("Light") then
        -- Sometimes the hierarchy might be different
        pointLight = lightPart.Light:FindFirstChild("PointLight")
    end
    
    -- If no point light is found, check if it's under different hierarchy
    if not pointLight then
        for _, child in pairs(lightPart:GetDescendants()) do
            if child:IsA("PointLight") then
                pointLight = child
                break
            end
        end
    end
    
    -- Create a new point light if none exists
    if not pointLight then
        pointLight = Instance.new("PointLight")
        pointLight.Brightness = DEFAULT_BRIGHTNESS
        pointLight.Range = DEFAULT_RANGE
        pointLight.Parent = lightPart
    end
    
    -- Store original properties for toggling
    lightPart:SetAttribute("OriginalColor", lightPart.Color)
    lightPart:SetAttribute("OriginalBrightness", pointLight.Brightness)
    lightPart:SetAttribute("OriginalRange", pointLight.Range)
    lightPart:SetAttribute("IsOn", true)
    
    -- Create proximity prompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "LightTogglePrompt"
    prompt.ObjectText = "Light"
    prompt.ActionText = "Toggle"
    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = true
    prompt.MaxActivationDistance = 10
    prompt.Parent = lightPart
    
    -- Handle the toggle
    prompt.Triggered:Connect(function(player)
        LightToggleSystem.toggleLight(lightPart, pointLight)
    end)
    
    -- Create a RemoteEvent for client-side effects if needed
    local lightToggleEvent = ReplicatedStorage:FindFirstChild("LightToggleEvent")
    if not lightToggleEvent then
        lightToggleEvent = Instance.new("RemoteEvent")
        lightToggleEvent.Name = "LightToggleEvent"
        lightToggleEvent.Parent = ReplicatedStorage
    end
end

-- Toggle the light on or off
function LightToggleSystem.toggleLight(lightPart, pointLight)
    local isOn = lightPart:GetAttribute("IsOn")
    
    if isOn then
        -- Turn off
        lightPart.Color = LIGHT_COLOR_OFF
        pointLight.Enabled = false
        lightPart:SetAttribute("IsOn", false)
        
        -- Play turn off sound
        LightToggleSystem.playToggleSound(lightPart, false)
    else
        -- Turn on
        lightPart.Color = LIGHT_COLOR_ON
        pointLight.Enabled = true
        lightPart:SetAttribute("IsOn", true)
        
        -- Play turn on sound
        LightToggleSystem.playToggleSound(lightPart, true)
    end
    
    -- Fire event to all clients for additional effects
    local lightToggleEvent = ReplicatedStorage:FindFirstChild("LightToggleEvent")
    if lightToggleEvent then
        lightToggleEvent:FireAllClients(lightPart, not isOn)
    end
end

-- Play toggle sound
function LightToggleSystem.playToggleSound(lightPart, isOn)
    -- Create a sound instance
    local sound = Instance.new("Sound")
    sound.Volume = 0.5
    
    if isOn then
        -- Light turning on sound
        sound.SoundId = "rbxassetid://9116006408" -- Replace with appropriate sound ID
    else
        -- Light turning off sound
        sound.SoundId = "rbxassetid://9116006566" -- Replace with appropriate sound ID
    end
    
    sound.Parent = lightPart
    sound:Play()
    
    -- Clean up sound after playing
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- Optional: Add visual effects when toggling lights
function LightToggleSystem.createClientVisuals()
    local lightToggleEvent = ReplicatedStorage:FindFirstChild("LightToggleEvent")
    if not lightToggleEvent then
        lightToggleEvent = Instance.new("RemoteEvent")
        lightToggleEvent.Name = "LightToggleEvent"
        lightToggleEvent.Parent = ReplicatedStorage
    end
    
    -- Create a local script to handle client-side effects
    local clientScript = [[
    -- Light Toggle Client Effects
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- Listen for light toggle events
    local lightToggleEvent = ReplicatedStorage:WaitForChild("LightToggleEvent")
    lightToggleEvent.OnClientEvent:Connect(function(lightPart, isOn)
        if not lightPart or not lightPart.Parent then return end
        
        -- Create a flicker effect when turning on
        if isOn then
            local originalColor = lightPart.Color
            local pointLight = lightPart:FindFirstChildOfClass("PointLight")
            
            -- Only run effect if we have the point light
            if pointLight then
                -- Disable temporarily for flicker
                pointLight.Enabled = false
                
                -- Flicker sequence
                for i = 1, 3 do
                    task.wait(math.random(50, 150) / 1000)
                    pointLight.Enabled = true
                    
                    task.wait(math.random(50, 150) / 1000)
                    pointLight.Enabled = false
                end
                
                -- Finally turn on
                task.wait(0.1)
                pointLight.Enabled = true
            end
        end
    end)
    
    print("Light toggle client effects initialized")
    ]]
    
    -- Return the client script code to be used in a LocalScript
    return clientScript
end

-- Return the module
return LightToggleSystem