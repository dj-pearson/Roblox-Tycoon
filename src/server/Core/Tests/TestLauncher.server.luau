-- TestLauncher.luau
-- GUI for launching tests in-game
-- Place in ServerScriptService/Core/Tests

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Only enable in Studio to prevent testing in production
if not RunService:IsStudio() then return end

-- Import test runner
local TestRunner = require(script.Parent.RunTests)

-- Create the test launcher GUI
local function createTestLauncherGui(player)
    -- Only create for the local player in studio
    if not player or not player:IsA("Player") or not RunService:IsStudio() then return end
    
    print("Creating Test Launcher GUI for " .. player.Name)
    
    -- Create the GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TestLauncher"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 1000 -- Ensure it's on top
    
    -- Creating the main panel
    local frame = Instance.new("Frame")
    frame.Name = "MainPanel"
    frame.Size = UDim2.new(0, 300, 0, 400)
    frame.Position = UDim2.new(1, -320, 0.5, -200)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = frame
    
    -- Add rounded corners to title bar
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    -- Fix bottom corners of title bar
    local bottomFix = Instance.new("Frame")
    bottomFix.Name = "BottomFix"
    bottomFix.Size = UDim2.new(1, 0, 0.5, 0)
    bottomFix.Position = UDim2.new(0, 0, 0.5, 0)
    bottomFix.BackgroundColor3 = titleBar.BackgroundColor3
    bottomFix.BorderSizePixel = 0
    bottomFix.Parent = titleBar
    
    -- Title text
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Text = "Test Launcher"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    -- Minimize button
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Name = "MinimizeButton"
    minimizeButton.Size = UDim2.new(0, 30, 0, 30)
    minimizeButton.Position = UDim2.new(1, -35, 0, 5)
    minimizeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    minimizeButton.Text = "-"
    minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizeButton.TextSize = 18
    minimizeButton.Font = Enum.Font.GothamBold
    minimizeButton.Parent = titleBar
    
    -- Add rounded corners to minimize button
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 6)
    minimizeCorner.Parent = minimizeButton
    
    -- Content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -50)
    content.Position = UDim2.new(0, 10, 0, 45)
    content.BackgroundTransparency = 1
    content.Parent = frame
    
    -- Introduction text
    local intro = Instance.new("TextLabel")
    intro.Name = "Intro"
    intro.Size = UDim2.new(1, 0, 0, 40)
    intro.BackgroundTransparency = 1
    intro.TextColor3 = Color3.fromRGB(200, 200, 200)
    intro.TextSize = 14
    intro.Font = Enum.Font.Gotham
    intro.TextWrapped = true
    intro.Text = "Select a test suite to run or click 'Run All Tests' to execute all test suites."
    intro.Parent = content
    
    -- Status container
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Size = UDim2.new(1, 0, 0, 30)
    statusFrame.Position = UDim2.new(0, 0, 0, 45)
    statusFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = content
    
    -- Status indicator
    local statusIndicator = Instance.new("Frame")
    statusIndicator.Name = "StatusIndicator"
    statusIndicator.Size = UDim2.new(0, 10, 0, 10)
    statusIndicator.Position = UDim2.new(0, 10, 0.5, 0)
    statusIndicator.AnchorPoint = Vector2.new(0, 0.5)
    statusIndicator.BackgroundColor3 = Color3.fromRGB(150, 150, 150) -- Gray by default
    statusIndicator.BorderSizePixel = 0
    statusIndicator.Parent = statusFrame
    
    -- Make the indicator a circle
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(1, 0)
    indicatorCorner.Parent = statusIndicator
    
    -- Status text
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, -30, 1, 0)
    statusText.Position = UDim2.new(0, 30, 0, 0)
    statusText.BackgroundTransparency = 1
    statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusText.TextSize = 14
    statusText.Font = Enum.Font.Gotham
    statusText.Text = "Ready"
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = statusFrame
    
    -- Test suites list
    local suitesContainer = Instance.new("ScrollingFrame")
    suitesContainer.Name = "SuitesContainer"
    suitesContainer.Size = UDim2.new(1, 0, 0, 180)
    suitesContainer.Position = UDim2.new(0, 0, 0, 85)
    suitesContainer.BackgroundTransparency = 1
    suitesContainer.ScrollBarThickness = 6
    suitesContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    suitesContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    suitesContainer.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be set automatically
    suitesContainer.Parent = content
    
    -- Layout for suites list
    local suitesLayout = Instance.new("UIListLayout")
    suitesLayout.Padding = UDim.new(0, 5)
    suitesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    suitesLayout.Parent = suitesContainer
    
    -- Get available test suites
    local testSuites = TestRunner.getAvailableSuites()
    
    -- Create buttons for each test suite
    for i, suiteName in ipairs(testSuites) do
        local suiteButton = Instance.new("TextButton")
        suiteButton.Name = suiteName .. "Button"
        suiteButton.Size = UDim2.new(1, 0, 0, 40)
        suiteButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        suiteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        suiteButton.TextSize = 16
        suiteButton.Font = Enum.Font.GothamMedium
        suiteButton.Text = "Run " .. suiteName .. " Tests"
        suiteButton.LayoutOrder = i
        
        -- Add rounded corners
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = suiteButton
        
        -- Status indicator for this suite
        local suiteStatus = Instance.new("Frame")
        suiteStatus.Name = "Status"
        suiteStatus.Size = UDim2.new(0, 10, 0, 10)
        suiteStatus.Position = UDim2.new(1, -20, 0.5, 0)
        suiteStatus.AnchorPoint = Vector2.new(0, 0.5)
        suiteStatus.BackgroundColor3 = Color3.fromRGB(150, 150, 150) -- Gray by default
        suiteStatus.BorderSizePixel = 0
        suiteStatus.Parent = suiteButton
        
        -- Make the status indicator a circle
        local suiteStatusCorner = Instance.new("UICorner")
        suiteStatusCorner.CornerRadius = UDim.new(1, 0)
        suiteStatusCorner.Parent = suiteStatus
        
        -- Connect button to run this suite's tests
        suiteButton.MouseButton1Click:Connect(function()
            -- Update status
            statusIndicator.BackgroundColor3 = Color3.fromRGB(255, 180, 0) -- Amber
            statusText.Text = "Running " .. suiteName .. " tests..."
            suiteStatus.BackgroundColor3 = Color3.fromRGB(255, 180, 0) -- Amber
            
            -- Use deferred to allow UI to update
            task.defer(function()
                -- Run the test suite
                local success = TestRunner.runSuite(suiteName)
                
                -- Update status based on result
                suiteStatus.BackgroundColor3 = success and 
                    Color3.fromRGB(0, 200, 0) or -- Green for success
                    Color3.fromRGB(200, 0, 0)    -- Red for failure
                
                statusIndicator.BackgroundColor3 = Color3.fromRGB(150, 150, 150) -- Gray
                statusText.Text = "Ready"
            end)
        end)
        
        suiteButton.Parent = suitesContainer
    end
    
    -- Run all tests button
    local allTestsButton = Instance.new("TextButton")
    allTestsButton.Name = "AllTestsButton"
    allTestsButton.Size = UDim2.new(1, 0, 0, 50)
    allTestsButton.Position = UDim2.new(0, 0, 0, 275)
    allTestsButton.BackgroundColor3 = Color3.fromRGB(70, 90, 170) -- Blue
    allTestsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    allTestsButton.TextSize = 18
    allTestsButton.Font = Enum.Font.GothamBold
    allTestsButton.Text = "Run All Tests"
    allTestsButton.Parent = content
    
    -- Add rounded corners
    local allTestsCorner = Instance.new("UICorner")
    allTestsCorner.CornerRadius = UDim.new(0, 8)
    allTestsCorner.Parent = allTestsButton
    
    -- Connect button to run all tests
    allTestsButton.MouseButton1Click:Connect(function()
        -- Update status
        statusIndicator.BackgroundColor3 = Color3.fromRGB(255, 180, 0) -- Amber
        statusText.Text = "Running all tests..."
        
        -- Reset all suite statuses to amber
        for _, child in ipairs(suitesContainer:GetChildren()) do
            if child:IsA("TextButton") then
                local statusDot = child:FindFirstChild("Status")
                if statusDot then
                    statusDot.BackgroundColor3 = Color3.fromRGB(255, 180, 0) -- Amber
                end
            end
        end
        
        -- Use deferred to allow UI to update
        task.defer(function()
            -- Run all tests
            local success = TestRunner.runAll()
            
            -- Update overall status
            statusIndicator.BackgroundColor3 = success and 
                Color3.fromRGB(0, 200, 0) or -- Green for success
                Color3.fromRGB(200, 0, 0)    -- Red for failure
                
            statusText.Text = success and "All tests passed!" or "Some tests failed"
        end)
    end)
    
    -- Test output display
    local outputLabel = Instance.new("TextLabel")
    outputLabel.Name = "OutputLabel"
    outputLabel.Size = UDim2.new(1, 0, 0, 20)
    outputLabel.Position = UDim2.new(0, 0, 0, 335)
    outputLabel.BackgroundTransparency = 1
    outputLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    outputLabel.TextSize = 12
    outputLabel.Font = Enum.Font.Gotham
    outputLabel.Text = "Output:"
    outputLabel.TextXAlignment = Enum.TextXAlignment.Left
    outputLabel.Parent = content
    
    -- Handle minimize/expand functionality
    local isMinimized = false
    local originalSize = frame.Size
    local minimizedSize = UDim2.new(0, 300, 0, 40)
    
    minimizeButton.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        
        if isMinimized then
            minimizeButton.Text = "+"
            frame.Size = minimizedSize
            content.Visible = false
        else
            minimizeButton.Text = "-"
            frame.Size = originalSize
            content.Visible = true
        end
    end)
    
    -- Make the panel draggable
    local isDragging = false
    local dragInput
    local dragStart
    local startPos
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)
    
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and isDragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Parent the GUI to the player
    screenGui.Parent = player.PlayerGui
    return screenGui
end

-- Create the GUI for the local player when they join
local function onPlayerAdded(player)
    if RunService:IsStudio() then
        -- Wait a bit to ensure systems are loaded
        task.delay(1, function()
            createTestLauncherGui(player)
        end)
    end
end

-- Handle existing players (in case script loads after player joins)
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

-- Handle future players
Players.PlayerAdded:Connect(onPlayerAdded)

return {
    createTestLauncherGui = createTestLauncherGui
}