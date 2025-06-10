-- GetPlayerID.lua
-- A simple script to get a player's ID in Roblox

-- IMPORTANT: THIS IS NOT A STANDALONE SCRIPT
-- You need to use this inside Roblox Studio!

--[[
HOW TO USE THIS SCRIPT:

Method 1: Command Bar (Easiest & Fastest)
1. Open Roblox Studio and any place file
2. Press F9 to open the Output window
3. Click on the "Command" tab
4. Copy and paste JUST THESE TWO LINES:

local player = game:GetService("Players").LocalPlayer
print("Your Player ID is: " .. player.UserId)

5. Press Enter to run

Method 2: LocalScript
1. In Explorer window, insert a LocalScript into StarterPlayerScripts
2. Copy this entire script
3. Test the game

Method 3: Chat Command
1. Insert this in a Script inside ServerScriptService:

game:GetService("Players").PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        if message == "/id" then
            player:SetAttribute("LastCommand", "ID Check")
            local success, error = pcall(function()
                -- Tell the player their ID
                local playerID = player.UserId
                player:WaitForChild("PlayerGui")
                game:GetService("ReplicatedStorage").Events.Notification:FireClient(
                    player, 
                    "Your Player ID is: " .. playerID, 
                    "ID Information"
                )
            end)
            if not success then
                warn("Error showing player ID: " .. tostring(error))
            end
        end
    end)
end)

]]--

-- THIS IS THE ACTUAL SCRIPT:
-- If you're in a LocalScript:
local player = game:GetService("Players").LocalPlayer
if player then
    print("Your Player ID is: " .. player.UserId)
    -- Create a notification GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PlayerIDGui"
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 100)
    frame.Position = UDim2.new(0.5, -125, 0.5, -50)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local cornerRadius = Instance.new("UICorner")
    cornerRadius.CornerRadius = UDim.new(0, 8)
    cornerRadius.Parent = frame
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 1, -20)
    textLabel.Position = UDim2.new(0, 10, 0, 10)
    textLabel.Text = "Your Player ID is:\n" .. player.UserId
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 18
    textLabel.Parent = frame
    
    screenGui.Parent = player.PlayerGui
    
    -- Auto remove after 5 seconds
    task.delay(5, function()
        screenGui:Destroy()
    end)
    
    return player.UserId
else
    warn("Cannot get player ID - LocalPlayer not found")
    return nil
end
