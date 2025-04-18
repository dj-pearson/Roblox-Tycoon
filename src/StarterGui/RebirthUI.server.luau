-- RebirthUI.lua
-- Client-side UI for interacting with the rebirth system
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Wait for the remote event
local RebirthRemote = ReplicatedStorage:WaitForChild("RebirthRemote")

-- Create the UI
local function createRebirthUI()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RebirthUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "RebirthFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 200)
    mainFrame.Position = UDim2.new(1, -320, 1, -220)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Add title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "Rebirth System"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 22
    titleLabel.Parent = mainFrame
    
    -- Add description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "DescriptionLabel"
    descLabel.Size = UDim2.new(1, -20, 0, 60)
    descLabel.Position = UDim2.new(0, 10, 0, 40)
    descLabel.BackgroundTransparency = 1
    descLabel.Font = Enum.Font.Gotham
    descLabel.Text = "Reset your progress to gain permanent bonuses to your gym!"
    descLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    descLabel.TextSize = 14
    descLabel.TextWrapped = true
    descLabel.TextXAlignment = Enum.TextXAlignment.Center
    descLabel.Parent = mainFrame
    
    -- Cost label
    local costLabel = Instance.new("TextLabel")
    costLabel.Name = "CostLabel"
    costLabel.Size = UDim2.new(1, -20, 0, 25)
    costLabel.Position = UDim2.new(0, 10, 0, 100)
    costLabel.BackgroundTransparency = 1
    costLabel.Font = Enum.Font.GothamSemibold
    costLabel.Text = "Cost: $100,000"
    costLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    costLabel.TextSize = 16
    costLabel.Parent = mainFrame
    
    -- Current rebirth count
    local rebirthCountLabel = Instance.new("TextLabel")
    rebirthCountLabel.Name = "RebirthCountLabel"
    rebirthCountLabel.Size = UDim2.new(1, -20, 0, 25)
    rebirthCountLabel.Position = UDim2.new(0, 10, 0, 125)
    rebirthCountLabel.BackgroundTransparency = 1
    rebirthCountLabel.Font = Enum.Font.Gotham
    rebirthCountLabel.Text = "Your Rebirth Level: 0"
    rebirthCountLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    rebirthCountLabel.TextSize = 14
    rebirthCountLabel.Parent = mainFrame
    
    -- Rebirth button
    local rebirthButton = Instance.new("TextButton")
    rebirthButton.Name = "RebirthButton"
    rebirthButton.Size = UDim2.new(0, 150, 0, 40)
    rebirthButton.Position = UDim2.new(0.5, -75, 1, -50)
    rebirthButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    rebirthButton.Font = Enum.Font.GothamBold
    rebirthButton.Text = "REBIRTH NOW"
    rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    rebirthButton.TextSize = 16
    rebirthButton.Parent = mainFrame
    
    -- Add corner rounding to button
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = rebirthButton
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton" 
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundTransparency = 1
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 100, 100)
    closeButton.TextSize = 18
    closeButton.Parent = mainFrame
    
    -- Toggle button (to open/close the main UI)
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "RebirthToggleButton"
    toggleButton.Size = UDim2.new(0, 120, 0, 40)
    toggleButton.Position = UDim2.new(1, -130, 0, 10)
    toggleButton.AnchorPoint = Vector2.new(1, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
    toggleButton.Font = Enum.Font.GothamSemibold
    toggleButton.Text = "Rebirth"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextSize = 16
    toggleButton.Parent = screenGui
    
    -- Add corner rounding to toggle button
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleButton
    
    -- Initially hide the main frame
    mainFrame.Visible = false
    
    -- Toggle visibility when button is clicked
    toggleButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
        
        -- Animate the opening/closing
        if mainFrame.Visible then
            -- Pop-in animation
            mainFrame.Size = UDim2.new(0, 280, 0, 180)
            mainFrame.BackgroundTransparency = 0.5
            
            local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(0, 300, 0, 200),
                BackgroundTransparency = 0.1
            })
            tween:Play()
            
            -- Update the rebirth count and cost
            updateRebirthInfo()
        end
    end)
    
    -- Close the UI when close button is clicked
    closeButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)
    
    -- Handle rebirth button click
    rebirthButton.MouseButton1Click:Connect(function()
        -- Disable the button temporarily
        rebirthButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        rebirthButton.Text = "Processing..."
        rebirthButton.Enabled = false
        
        -- Send rebirth request to server
        RebirthRemote:FireServer()
        
        -- Re-enable button after a delay
        task.delay(2, function()
            rebirthButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
            rebirthButton.Text = "REBIRTH NOW"
            rebirthButton.Enabled = true
        end)
    end)
    
    -- Function to update rebirth information
    function updateRebirthInfo()
        -- This will be updated when we receive info from the server
        -- We'll update it initially in the HandleRebirthInfo function
    end
    
    return {
        ScreenGui = screenGui,
        RebirthCountLabel = rebirthCountLabel,
        CostLabel = costLabel
    }
end

-- Create the UI
local rebirthUIElements = createRebirthUI()

-- Function to handle rebirth responses from server
local function handleRebirthInfo(messageType, data)
    if messageType == "RebirthSuccess" then
        -- Update UI with new info
        rebirthUIElements.RebirthCountLabel.Text = "Your Rebirth Level: " .. data.rebirthCount
        
        -- Show success message
        local successMessage = Instance.new("TextLabel")
        successMessage.Name = "SuccessMessage"
        successMessage.Size = UDim2.new(1, -40, 0, 60)
        successMessage.Position = UDim2.new(0.5, 0, 0.5, 0)
        successMessage.AnchorPoint = Vector2.new(0.5, 0.5)
        successMessage.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
        successMessage.BackgroundTransparency = 0.2
        successMessage.Font = Enum.Font.GothamBold
        successMessage.Text = "Rebirth Successful!\nNew Multiplier: " .. string.format("%.2f", data.newMultiplier) .. "x"
        successMessage.TextColor3 = Color3.fromRGB(255, 255, 255)
        successMessage.TextSize = 18
        successMessage.Parent = rebirthUIElements.ScreenGui
        
        -- Add corner rounding
        local messageCorner = Instance.new("UICorner")
        messageCorner.CornerRadius = UDim.new(0, 8)
        messageCorner.Parent = successMessage
        
        -- Remove after a few seconds
        task.delay(3, function()
            if successMessage and successMessage.Parent then
                -- Fade out animation
                local tween = TweenService:Create(successMessage, TweenInfo.new(1), {
                    BackgroundTransparency = 1,
                    TextTransparency = 1
                })
                tween:Play()
                
                task.delay(1, function()
                    if successMessage and successMessage.Parent then
                        successMessage:Destroy()
                    end
                end)
            end
        end)
    elseif messageType == "NotEnoughCash" then
        -- Show not enough cash message
        local errorMessage = Instance.new("TextLabel")
        errorMessage.Name = "ErrorMessage"
        errorMessage.Size = UDim2.new(1, -40, 0, 60)
        errorMessage.Position = UDim2.new(0.5, 0, 0.5, 0)
        errorMessage.AnchorPoint = Vector2.new(0.5, 0.5)
        errorMessage.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
        errorMessage.BackgroundTransparency = 0.2
        errorMessage.Font = Enum.Font.GothamBold
        errorMessage.Text = "Not enough cash!\nYou need $" .. string.format("%d", data.required)
        errorMessage.TextColor3 = Color3.fromRGB(255, 255, 255)
        errorMessage.TextSize = 18
        errorMessage.Parent = rebirthUIElements.ScreenGui
        
        -- Add corner rounding
        local messageCorner = Instance.new("UICorner")
        messageCorner.CornerRadius = UDim.new(0, 8)
        messageCorner.Parent = errorMessage
        
        -- Remove after a few seconds
        task.delay(3, function()
            if errorMessage and errorMessage.Parent then
                -- Fade out animation
                local tween = TweenService:Create(errorMessage, TweenInfo.new(1), {
                    BackgroundTransparency = 1,
                    TextTransparency = 1
                })
                tween:Play()
                
                task.delay(1, function()
                    if errorMessage and errorMessage.Parent then
                        errorMessage:Destroy()
                    end
                end)
            end
        end)
    elseif messageType == "RebirthInfo" then
        -- Update cost and rebirth count display
        rebirthUIElements.CostLabel.Text = "Cost: $" .. string.format("%d", data.cost)
        rebirthUIElements.RebirthCountLabel.Text = "Your Rebirth Level: " .. data.rebirthCount
    end
end

-- Listen for server messages
RebirthRemote.OnClientEvent:Connect(handleRebirthInfo)

-- Request initial rebirth information
task.delay(2, function()
    RebirthRemote:FireServer("GetInfo")
end)

-- Add UI to PlayerGui
rebirthUIElements.ScreenGui.Parent = LocalPlayer.PlayerGui