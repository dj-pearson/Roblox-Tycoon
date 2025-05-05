-- Light Toggle Client Effects
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create the remote event if it doesn't exist
local lightToggleEvent = ReplicatedStorage:FindFirstChild("LightToggleEvent")
if not lightToggleEvent then
    lightToggleEvent = Instance.new("RemoteEvent")
    lightToggleEvent.Name = "LightToggleEvent"
    lightToggleEvent.Parent = ReplicatedStorage
end

-- Listen for light toggle events
lightToggleEvent.OnClientEvent:Connect(function(lightPart, isOn)
    if not lightPart or not lightPart.Parent then return end
    
    -- Create a flicker effect when turning on
    if isOn then
        local pointLight = lightPart:FindFirstChildOfClass("PointLight")
        
        -- Only run effect if we have the point light
        if pointLight then
            -- Store original properties
            local originalEnabled = pointLight.Enabled
            
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