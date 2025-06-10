-- DataStore Manager GUI (No Plugin Required)
-- Place this script in ServerScriptService

print("DataStore Manager GUI Loading...")

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Create ScreenGui for all players
local function createDataStoreGUI(player)
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DataStoreManager"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 800, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.Text = "DataStore Manager (No Plugin Required)"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 14
    closeBtn.Parent = titleBar
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 4)
    closeBtnCorner.Parent = closeBtn
    
    -- Content Area
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, -20, 1, -60)
    contentFrame.Position = UDim2.new(0, 10, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 8
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 1000)
    contentFrame.Parent = mainFrame
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 30)
    statusLabel.Position = UDim2.new(0, 0, 0, 10)
    statusLabel.Text = "DataStore Manager Ready - Press F1 to toggle interface"
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextSize = 14
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = contentFrame
    
    -- Test Section
    local testSection = Instance.new("Frame")
    testSection.Size = UDim2.new(1, 0, 0, 200)
    testSection.Position = UDim2.new(0, 0, 0, 50)
    testSection.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    testSection.BorderSizePixel = 1
    testSection.BorderColor3 = Color3.fromRGB(70, 70, 70)
    testSection.Parent = contentFrame
    
    local testSectionCorner = Instance.new("UICorner")
    testSectionCorner.CornerRadius = UDim.new(0, 6)
    testSectionCorner.Parent = testSection
    
    local testTitle = Instance.new("TextLabel")
    testTitle.Size = UDim2.new(1, 0, 0, 30)
    testTitle.Text = "DataStore Testing"
    testTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    testTitle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    testTitle.BorderSizePixel = 0
    testTitle.Font = Enum.Font.SourceSansBold
    testTitle.TextSize = 14
    testTitle.Parent = testSection
    
    local testTitleCorner = Instance.new("UICorner")
    testTitleCorner.CornerRadius = UDim.new(0, 6)
    testTitleCorner.Parent = testTitle
    
    -- Test Buttons
    local function createButton(text, position, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 180, 0, 35)
        btn.Position = position
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 12
        btn.Parent = testSection
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    local testBasicBtn = createButton("Test Basic DataStore", UDim2.new(0, 10, 0, 40), function()
        statusLabel.Text = "Testing Basic DataStore..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        
        local success, result = pcall(function()
            local store = DataStoreService:GetDataStore("TestStore")
            store:SetAsync("TestKey", "Hello DataStore!")
            return store:GetAsync("TestKey")
        end)
        
        if success then
            statusLabel.Text = "✓ Basic DataStore Test Successful: " .. tostring(result)
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            statusLabel.Text = "✗ Basic DataStore Test Failed: " .. tostring(result)
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
    
    local testOrderedBtn = createButton("Test Ordered DataStore", UDim2.new(0, 200, 0, 40), function()
        statusLabel.Text = "Testing Ordered DataStore..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        
        local success, result = pcall(function()
            local store = DataStoreService:GetOrderedDataStore("Leaderboard")
            store:SetAsync("Player1", 100)
            store:SetAsync("Player2", 250)
            local pages = store:GetSortedAsync(false, 5)
            return "Ordered DataStore working"
        end)
        
        if success then
            statusLabel.Text = "✓ Ordered DataStore Test Successful"
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            statusLabel.Text = "✗ Ordered DataStore Test Failed: " .. tostring(result)
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
    
    local testGlobalBtn = createButton("Test Global DataStore", UDim2.new(0, 390, 0, 40), function()
        statusLabel.Text = "Testing Global DataStore..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        
        local success, result = pcall(function()
            local store = DataStoreService:GetGlobalDataStore()
            store:SetAsync("GlobalTest", {message = "Global works!", time = os.time()})
            return store:GetAsync("GlobalTest")
        end)
        
        if success then
            statusLabel.Text = "✓ Global DataStore Test Successful"
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            statusLabel.Text = "✗ Global DataStore Test Failed: " .. tostring(result)
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
    
    -- Toggle functionality
    local isVisible = false
    
    local function toggleGUI()
        isVisible = not isVisible
        mainFrame.Visible = isVisible
        
        if isVisible then
            mainFrame.Position = UDim2.new(0.5, -400, 0, -600)
            local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, -400, 0.5, -300)
            })
            tween:Play()
        end
    end
    
    -- Close button functionality
    closeBtn.MouseButton1Click:Connect(function()
        local tween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -400, 0, -600)
        })
        tween:Play()
        tween.Completed:Connect(function()
            mainFrame.Visible = false
            isVisible = false
        end)
    end)
    
    -- F1 key binding
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F1 then
            toggleGUI()
        end
    end)
    
    print("DataStore Manager GUI created for player:", player.Name)
    print("Press F1 to toggle the interface")
end

-- Create GUI for players
Players.PlayerAdded:Connect(createDataStoreGUI)
for _, player in pairs(Players:GetPlayers()) do
    createDataStoreGUI(player)
end

print("DataStore Manager GUI System Loaded!")
print("All players can press F1 to access DataStore testing tools") 