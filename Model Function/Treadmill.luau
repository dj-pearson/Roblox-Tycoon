-- Ultra Simple Treadmill Script - Direct Replacement
local Treadmill = script.Parent
local Conveyor = Treadmill:FindFirstChild("Conveyor")
local Screen = Treadmill:FindFirstChild("Screen")
local GreenButton = Treadmill:FindFirstChild("GreenButton")
local RedButton = Treadmill:FindFirstChild("RedButton")

-- Check if we have all required parts
if not (Conveyor and Screen and GreenButton and RedButton) then
    warn("Treadmill missing required parts. Script cannot run.")
    return
end

-- Make sure we have a text label
local TextLabel
if Screen:FindFirstChild("SurfaceGui") and Screen.SurfaceGui:FindFirstChild("TextLabel") then
    TextLabel = Screen.SurfaceGui.TextLabel
else
    -- Create necessary UI elements
    local SurfaceGui = Instance.new("SurfaceGui")
    SurfaceGui.Parent = Screen
    SurfaceGui.Name = "SurfaceGui"

    TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, 0, 1, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextScaled = true
    TextLabel.Name = "TextLabel"
    TextLabel.Parent = SurfaceGui
end

-- Setup variables
local Speed = 0
local MaxSpeed = 16
local Increment = 4
local Calories = 0
local LastUpdate = tick()

-- Initialize display
TextLabel.Text = "SPEED: 0"

-- USING SIMPLE CLICKDETECTOR APPROACH
-- Add ClickDetectors to buttons if they don't exist
local GreenClickDetector = GreenButton:FindFirstChild("ClickDetector") or Instance.new("ClickDetector", GreenButton)
GreenClickDetector.MaxActivationDistance = 10

local RedClickDetector = RedButton:FindFirstChild("ClickDetector") or Instance.new("ClickDetector", RedButton)
RedClickDetector.MaxActivationDistance = 10

-- Add ClickDetector to the conveyor for player interaction
local ConveyorClick = Conveyor:FindFirstChild("ClickDetector") or Instance.new("ClickDetector", Conveyor)
ConveyorClick.MaxActivationDistance = 10

-- Handle the green button (speed up)
GreenClickDetector.MouseClick:Connect(function()
    if Speed < MaxSpeed then
        Speed = Speed + Increment
        TextLabel.Text = "SPEED: " .. Speed
    end
end)

-- Handle the red button (slow down)
RedClickDetector.MouseClick:Connect(function()
    if Speed > 0 then
        Speed = Speed - Increment
        TextLabel.Text = "SPEED: " .. Speed
        
        -- If we're now stopped, reset calories
        if Speed == 0 then
            Calories = 0
        end
    end
end)

-- Handle conveyor click (toggle on/off)
ConveyorClick.MouseClick:Connect(function()
    if Speed > 0 then
        -- Turn off
        Speed = 0
        Calories = 0
        TextLabel.Text = "SPEED: 0"
    else
        -- Turn on at minimum speed
        Speed = Increment
        TextLabel.Text = "SPEED: " .. Speed
    end
end)

-- Main loop using simple while/wait approach like the original
while true do
    -- Update conveyor
    Conveyor.Velocity = Conveyor.CFrame.lookVector * Speed
    
    -- Calculate calories if moving
    if Speed > 0 then
        local CurrentTime = tick()
        local TimePassed = CurrentTime - LastUpdate
        LastUpdate = CurrentTime
        
        Calories = Calories + (Speed * 0.1 * TimePassed)
        TextLabel.Text = "SPEED: " .. Speed .. "\nCAL: " .. math.floor(Calories)
    end
    
    wait(0.1) -- Original wait time
end
