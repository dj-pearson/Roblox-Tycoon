-- RebirthUI.lua
-- Enhanced client-side UI for interacting with the rebirth system with unlockable content progression
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
    mainFrame.Size = UDim2.new(0, 500, 0, 400)  -- Increased size for more content
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)  -- Centered on screen
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
    titleLabel.TextSize = 24
    titleLabel.Parent = mainFrame
    
    -- Add description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "DescriptionLabel"
    descLabel.Size = UDim2.new(1, -20, 0, 40)
    descLabel.Position = UDim2.new(0, 10, 0, 40)
    descLabel.BackgroundTransparency = 1
    descLabel.Font = Enum.Font.Gotham
    descLabel.Text = "Reset your progress to gain permanent bonuses and unlock new features!"
    descLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    descLabel.TextSize = 14
    descLabel.TextWrapped = true
    descLabel.TextXAlignment = Enum.TextXAlignment.Center
    descLabel.Parent = mainFrame
    
    -- Tab buttons container
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Name = "TabsContainer"
    tabsContainer.Size = UDim2.new(1, -20, 0, 40)
    tabsContainer.Position = UDim2.new(0, 10, 0, 90)
    tabsContainer.BackgroundTransparency = 1
    tabsContainer.Parent = mainFrame
    
    -- Create tab buttons
    local function createTabButton(name, text, position)
        local button = Instance.new("TextButton")
        button.Name = name .. "TabButton"
        button.Size = UDim2.new(0.25, -10, 1, 0)
        button.Position = UDim2.new(0.25 * position, position > 0 and 5 or 0, 0, 0)
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
        button.Font = Enum.Font.GothamSemibold
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 14
        button.Parent = tabsContainer
        
        -- Add corner rounding
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = button
        
        return button
    end
    
    -- Create tab buttons
    local mainTabButton = createTabButton("Main", "Main", 0)
    local featuresTabButton = createTabButton("Features", "Features", 1)
    local perksTabButton = createTabButton("Perks", "Perks", 2)
    local achievementsTabButton = createTabButton("Achievements", "Achievements", 3)
    
    -- Content container for tab content
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -20, 0, 220)
    contentContainer.Position = UDim2.new(0, 10, 0, 140)
    contentContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = mainFrame
    
    -- Add corner rounding to content container
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = contentContainer
    
    -- Create content for each tab
    -- 1. Main tab content
    local mainTabContent = Instance.new("Frame")
    mainTabContent.Name = "MainTabContent"
    mainTabContent.Size = UDim2.new(1, 0, 1, 0)
    mainTabContent.BackgroundTransparency = 1
    mainTabContent.Parent = contentContainer
    
    -- Cost label
    local costLabel = Instance.new("TextLabel")
    costLabel.Name = "CostLabel"
    costLabel.Size = UDim2.new(1, -20, 0, 25)
    costLabel.Position = UDim2.new(0, 10, 0, 20)
    costLabel.BackgroundTransparency = 1
    costLabel.Font = Enum.Font.GothamSemibold
    costLabel.Text = "Cost: $100,000"
    costLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    costLabel.TextSize = 18
    costLabel.Parent = mainTabContent
    
    -- Current rebirth count
    local rebirthCountLabel = Instance.new("TextLabel")
    rebirthCountLabel.Name = "RebirthCountLabel"
    rebirthCountLabel.Size = UDim2.new(1, -20, 0, 25)
    rebirthCountLabel.Position = UDim2.new(0, 10, 0, 50)
    rebirthCountLabel.BackgroundTransparency = 1
    rebirthCountLabel.Font = Enum.Font.Gotham
    rebirthCountLabel.Text = "Your Rebirth Level: 0"
    rebirthCountLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    rebirthCountLabel.TextSize = 16
    rebirthCountLabel.Parent = mainTabContent
    
    -- Rebirth multiplier
    local multiplierLabel = Instance.new("TextLabel")
    multiplierLabel.Name = "MultiplierLabel"
    multiplierLabel.Size = UDim2.new(1, -20, 0, 25)
    multiplierLabel.Position = UDim2.new(0, 10, 0, 80)
    multiplierLabel.BackgroundTransparency = 1
    multiplierLabel.Font = Enum.Font.Gotham
    multiplierLabel.Text = "Revenue Multiplier: 0%"
    multiplierLabel.TextColor3 = Color3.fromRGB(100, 255, 255)
    multiplierLabel.TextSize = 16
    multiplierLabel.Parent = mainTabContent
    
    -- Progress bar container
    local progressBarContainer = Instance.new("Frame")
    progressBarContainer.Name = "ProgressBarContainer"
    progressBarContainer.Size = UDim2.new(1, -20, 0, 20)
    progressBarContainer.Position = UDim2.new(0, 10, 0, 115)
    progressBarContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
    progressBarContainer.BorderSizePixel = 0
    progressBarContainer.Parent = mainTabContent
    
    -- Progress bar corner
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 4)
    progressCorner.Parent = progressBarContainer
    
    -- Progress bar fill
    local progressBarFill = Instance.new("Frame")
    progressBarFill.Name = "ProgressBarFill"
    progressBarFill.Size = UDim2.new(0, 0, 1, 0)
    progressBarFill.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    progressBarFill.BorderSizePixel = 0
    progressBarFill.Parent = progressBarContainer
    
    -- Progress bar fill corner
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = progressBarFill
    
    -- Progress label
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Name = "ProgressLabel"
    progressLabel.Size = UDim2.new(1, -20, 0, 20)
    progressLabel.Position = UDim2.new(0, 10, 0, 140)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Font = Enum.Font.Gotham
    progressLabel.Text = "Progress: 0%"
    progressLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    progressLabel.TextSize = 14
    progressLabel.Parent = mainTabContent
    
    -- Next unlock info
    local nextUnlockLabel = Instance.new("TextLabel")
    nextUnlockLabel.Name = "NextUnlockLabel"
    nextUnlockLabel.Size = UDim2.new(1, -20, 0, 40)
    nextUnlockLabel.Position = UDim2.new(0, 10, 0, 165)
    nextUnlockLabel.BackgroundTransparency = 1
    nextUnlockLabel.Font = Enum.Font.Gotham
    nextUnlockLabel.Text = "Next Unlock: None"
    nextUnlockLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    nextUnlockLabel.TextSize = 14
    nextUnlockLabel.TextWrapped = true
    nextUnlockLabel.Parent = mainTabContent
    
    -- 2. Features tab content
    local featuresTabContent = Instance.new("Frame")
    featuresTabContent.Name = "FeaturesTabContent"
    featuresTabContent.Size = UDim2.new(1, 0, 1, 0)
    featuresTabContent.BackgroundTransparency = 1
    featuresTabContent.Visible = false
    featuresTabContent.Parent = contentContainer
    
    -- Features scroll frame
    local featuresScrollFrame = Instance.new("ScrollingFrame")
    featuresScrollFrame.Name = "FeaturesScrollFrame"
    featuresScrollFrame.Size = UDim2.new(1, -20, 1, -20)
    featuresScrollFrame.Position = UDim2.new(0, 10, 0, 10)
    featuresScrollFrame.BackgroundTransparency = 1
    featuresScrollFrame.ScrollBarThickness = 6
    featuresScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    featuresScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
    featuresScrollFrame.Parent = featuresTabContent
    
    -- Feature list layout
    local featuresListLayout = Instance.new("UIListLayout")
    featuresListLayout.Padding = UDim.new(0, 10)
    featuresListLayout.FillDirection = Enum.FillDirection.Vertical
    featuresListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    featuresListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    featuresListLayout.Parent = featuresScrollFrame
    
    -- 3. Perks tab content
    local perksTabContent = Instance.new("Frame")
    perksTabContent.Name = "PerksTabContent"
    perksTabContent.Size = UDim2.new(1, 0, 1, 0)
    perksTabContent.BackgroundTransparency = 1
    perksTabContent.Visible = false
    perksTabContent.Parent = contentContainer
    
    -- Perks scroll frame
    local perksScrollFrame = Instance.new("ScrollingFrame")
    perksScrollFrame.Name = "PerksScrollFrame"
    perksScrollFrame.Size = UDim2.new(1, -20, 1, -20)
    perksScrollFrame.Position = UDim2.new(0, 10, 0, 10)
    perksScrollFrame.BackgroundTransparency = 1
    perksScrollFrame.ScrollBarThickness = 6
    perksScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    perksScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
    perksScrollFrame.Parent = perksTabContent
    
    -- Perk list layout
    local perksListLayout = Instance.new("UIListLayout")
    perksListLayout.Padding = UDim.new(0, 10)
    perksListLayout.FillDirection = Enum.FillDirection.Vertical
    perksListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    perksListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    perksListLayout.Parent = perksScrollFrame
    
    -- 4. Achievements tab content
    local achievementsTabContent = Instance.new("Frame")
    achievementsTabContent.Name = "AchievementsTabContent"
    achievementsTabContent.Size = UDim2.new(1, 0, 1, 0)
    achievementsTabContent.BackgroundTransparency = 1
    achievementsTabContent.Visible = false
    achievementsTabContent.Parent = contentContainer
    
    -- Achievements scroll frame
    local achievementsScrollFrame = Instance.new("ScrollingFrame")
    achievementsScrollFrame.Name = "AchievementsScrollFrame"
    achievementsScrollFrame.Size = UDim2.new(1, -20, 1, -20)
    achievementsScrollFrame.Position = UDim2.new(0, 10, 0, 10)
    achievementsScrollFrame.BackgroundTransparency = 1
    achievementsScrollFrame.ScrollBarThickness = 6
    achievementsScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    achievementsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
    achievementsScrollFrame.Parent = achievementsTabContent
    
    -- Achievement list layout
    local achievementsListLayout = Instance.new("UIListLayout")
    achievementsListLayout.Padding = UDim.new(0, 10)
    achievementsListLayout.FillDirection = Enum.FillDirection.Vertical
    achievementsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    achievementsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    achievementsListLayout.Parent = achievementsScrollFrame
    
    -- Rebirth button
    local rebirthButton = Instance.new("TextButton")
    rebirthButton.Name = "RebirthButton"
    rebirthButton.Size = UDim2.new(0, 200, 0, 50)
    rebirthButton.Position = UDim2.new(0.5, -100, 1, -70)
    rebirthButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    rebirthButton.Font = Enum.Font.GothamBold
    rebirthButton.Text = "REBIRTH NOW"
    rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    rebirthButton.TextSize = 18
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
    
    -- Stats section at the bottom
    local statsContainer = Instance.new("Frame")
    statsContainer.Name = "StatsContainer"
    statsContainer.Size = UDim2.new(1, -20, 0, 30)
    statsContainer.Position = UDim2.new(0, 10, 1, -30)
    statsContainer.BackgroundTransparency = 1
    statsContainer.Parent = mainFrame
    
    -- Total rebirths
    local totalRebirthsLabel = Instance.new("TextLabel")
    totalRebirthsLabel.Name = "TotalRebirthsLabel"
    totalRebirthsLabel.Size = UDim2.new(0.5, -10, 1, 0)
    totalRebirthsLabel.Position = UDim2.new(0, 0, 0, 0)
    totalRebirthsLabel.BackgroundTransparency = 1
    totalRebirthsLabel.Font = Enum.Font.Gotham
    totalRebirthsLabel.Text = "Total Rebirths: 0"
    totalRebirthsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    totalRebirthsLabel.TextSize = 12
    totalRebirthsLabel.TextXAlignment = Enum.TextXAlignment.Left
    totalRebirthsLabel.Parent = statsContainer
    
    -- Fastest rebirth
    local fastestRebirthLabel = Instance.new("TextLabel")
    fastestRebirthLabel.Name = "FastestRebirthLabel"
    fastestRebirthLabel.Size = UDim2.new(0.5, -10, 1, 0)
    fastestRebirthLabel.Position = UDim2.new(0.5, 10, 0, 0)
    fastestRebirthLabel.BackgroundTransparency = 1
    fastestRebirthLabel.Font = Enum.Font.Gotham
    fastestRebirthLabel.Text = "Fastest Rebirth: None"
    fastestRebirthLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    fastestRebirthLabel.TextSize = 12
    fastestRebirthLabel.TextXAlignment = Enum.TextXAlignment.Left
    fastestRebirthLabel.Parent = statsContainer
    
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
    
    -- Function to switch between tabs
    local function switchToTab(tabName)
        -- Hide all tab contents
        mainTabContent.Visible = false
        featuresTabContent.Visible = false
        perksTabContent.Visible = false
        achievementsTabContent.Visible = false
        
        -- Reset all tab button colors
        mainTabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
        featuresTabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
        perksTabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
        achievementsTabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
        
        -- Show selected tab content and highlight button
        if tabName == "Main" then
            mainTabContent.Visible = true
            mainTabButton.BackgroundColor3 = Color3.fromRGB(80, 80, 160)
        elseif tabName == "Features" then
            featuresTabContent.Visible = true
            featuresTabButton.BackgroundColor3 = Color3.fromRGB(80, 80, 160)
        elseif tabName == "Perks" then
            perksTabContent.Visible = true
            perksTabButton.BackgroundColor3 = Color3.fromRGB(80, 80, 160)
        elseif tabName == "Achievements" then
            achievementsTabContent.Visible = true
            achievementsTabButton.BackgroundColor3 = Color3.fromRGB(80, 80, 160)
        end
    end
    
    -- Tab button click events
    mainTabButton.MouseButton1Click:Connect(function()
        switchToTab("Main")
    end)
    
    featuresTabButton.MouseButton1Click:Connect(function()
        switchToTab("Features")
    end)
    
    perksTabButton.MouseButton1Click:Connect(function()
        switchToTab("Perks")
    end)
    
    achievementsTabButton.MouseButton1Click:Connect(function()
        switchToTab("Achievements")
    end)
    
    -- Toggle visibility when button is clicked
    toggleButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
        
        -- Animate the opening/closing
        if mainFrame.Visible then
            -- Pop-in animation
            mainFrame.Size = UDim2.new(0, 480, 0, 380)
            mainFrame.BackgroundTransparency = 0.5
            
            local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(0, 500, 0, 400),
                BackgroundTransparency = 0.1
            })
            tween:Play()
            
            -- Update the rebirth info
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
        RebirthRemote:FireServer("Rebirth")
        
        -- Re-enable button after a delay
        task.delay(2, function()
            rebirthButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
            rebirthButton.Text = "REBIRTH NOW"
            rebirthButton.Enabled = true
        end)
    end)
    
    -- Function to create a feature card
    local function createFeatureCard(feature)
        local featureCard = Instance.new("Frame")
        featureCard.Name = "FeatureCard_" .. feature.level
        featureCard.Size = UDim2.new(1, -20, 0, 80)
        featureCard.BackgroundColor3 = feature.info.model and Color3.fromRGB(80, 50, 100) or Color3.fromRGB(60, 60, 90)
        featureCard.BorderSizePixel = 0
        
        -- Add corner rounding
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 8)
        cardCorner.Parent = featureCard
        
        -- Feature icon
        if feature.info.icon then
            local icon = Instance.new("ImageLabel")
            icon.Name = "FeatureIcon"
            icon.Size = UDim2.new(0, 50, 0, 50)
            icon.Position = UDim2.new(0, 10, 0, 15)
            icon.BackgroundTransparency = 1
            icon.Image = feature.info.icon
            icon.Parent = featureCard
        end
        
        -- Feature name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "FeatureName"
        nameLabel.Size = UDim2.new(1, -80, 0, 25)
        nameLabel.Position = UDim2.new(0, 70, 0, 10)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Text = feature.info.name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 16
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = featureCard
        
        -- Feature description
        local descLabel = Instance.new("TextLabel")
        descLabel.Name = "FeatureDesc"
        descLabel.Size = UDim2.new(1, -80, 0, 40)
        descLabel.Position = UDim2.new(0, 70, 0, 35)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Enum.Font.Gotham
        descLabel.Text = feature.info.description
        descLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        descLabel.TextSize = 12
        descLabel.TextWrapped = true
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = featureCard
        
        -- Level indicator
        local levelLabel = Instance.new("TextLabel")
        levelLabel.Name = "LevelLabel"
        levelLabel.Size = UDim2.new(0, 50, 0, 20)
        levelLabel.Position = UDim2.new(1, -60, 0, 10)
        levelLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
        levelLabel.Font = Enum.Font.GothamSemibold
        levelLabel.Text = "Lvl " .. feature.level
        levelLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
        levelLabel.TextSize = 12
        levelLabel.Parent = featureCard
        
        -- Level indicator corner
        local levelCorner = Instance.new("UICorner")
        levelCorner.CornerRadius = UDim.new(0, 4)
        levelCorner.Parent = levelLabel
        
        return featureCard
    end
    
    -- Function to create a perk card
    local function createPerkCard(perk)
        local perkCard = Instance.new("Frame")
        perkCard.Name = "PerkCard_" .. perk.level
        perkCard.Size = UDim2.new(1, -20, 0, 80)
        perkCard.BackgroundColor3 = Color3.fromRGB(40, 80, 60)
        perkCard.BorderSizePixel = 0
        
        -- Add corner rounding
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 8)
        cardCorner.Parent = perkCard
        
        -- Perk icon
        if perk.info.icon then
            local icon = Instance.new("ImageLabel")
            icon.Name = "PerkIcon"
            icon.Size = UDim2.new(0, 50, 0, 50)
            icon.Position = UDim2.new(0, 10, 0, 15)
            icon.BackgroundTransparency = 1
            icon.Image = perk.info.icon
            icon.Parent = perkCard
        end
        
        -- Perk name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "PerkName"
        nameLabel.Size = UDim2.new(1, -80, 0, 25)
        nameLabel.Position = UDim2.new(0, 70, 0, 10)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Text = perk.info.name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 16
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = perkCard
        
        -- Perk description
        local descLabel = Instance.new("TextLabel")
        descLabel.Name = "PerkDesc"
        descLabel.Size = UDim2.new(1, -80, 0, 40)
        descLabel.Position = UDim2.new(0, 70, 0, 35)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Enum.Font.Gotham
        descLabel.Text = perk.info.description
        descLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        descLabel.TextSize = 12
        descLabel.TextWrapped = true
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = perkCard
        
        -- Level indicator
        local levelLabel = Instance.new("TextLabel")
        levelLabel.Name = "LevelLabel"
        levelLabel.Size = UDim2.new(0, 50, 0, 20)
        levelLabel.Position = UDim2.new(1, -60, 0, 10)
        levelLabel.BackgroundColor3 = Color3.fromRGB(30, 60, 50)
        levelLabel.Font = Enum.Font.GothamSemibold
        levelLabel.Text = "Lvl " .. perk.level
        levelLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
        levelLabel.TextSize = 12
        levelLabel.Parent = perkCard
        
        -- Level indicator corner
        local levelCorner = Instance.new("UICorner")
        levelCorner.CornerRadius = UDim.new(0, 4)
        levelCorner.Parent = levelLabel
        
        return perkCard
    end
    
    -- Function to create an achievement card
    local function createAchievementCard(achievement)
        local achievementCard = Instance.new("Frame")
        achievementCard.Name = "AchievementCard_" .. achievement.id
        achievementCard.Size = UDim2.new(1, -20, 0, 80)
        achievementCard.BackgroundColor3 = achievement.earned and Color3.fromRGB(60, 80, 40) or Color3.fromRGB(70, 70, 70)
        achievementCard.BorderSizePixel = 0
        
        -- Add corner rounding
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 8)
        cardCorner.Parent = achievementCard
        
        -- Achievement icon
        if achievement.info.icon then
            local icon = Instance.new("ImageLabel")
            icon.Name = "AchievementIcon"
            icon.Size = UDim2.new(0, 50, 0, 50)
            icon.Position = UDim2.new(0, 10, 0, 15)
            icon.BackgroundTransparency = 1
            icon.Image = achievement.info.icon
            icon.ImageTransparency = achievement.earned and 0 or 0.5
            icon.Parent = achievementCard
        end
        
        -- Achievement name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "AchievementName"
        nameLabel.Size = UDim2.new(1, -80, 0, 25)
        nameLabel.Position = UDim2.new(0, 70, 0, 10)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Text = achievement.info.name
        nameLabel.TextColor3 = achievement.earned and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
        nameLabel.TextSize = 16
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = achievementCard
        
        -- Achievement description
        local descLabel = Instance.new("TextLabel")
        descLabel.Name = "AchievementDesc"
        descLabel.Size = UDim2.new(1, -80, 0, 40)
        descLabel.Position = UDim2.new(0, 70, 0, 35)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Enum.Font.Gotham
        descLabel.Text = achievement.info.description
        descLabel.TextColor3 = achievement.earned and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(150, 150, 150)
        descLabel.TextSize = 12
        descLabel.TextWrapped = true
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = achievementCard
        
        -- Status indicator
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "StatusLabel"
        statusLabel.Size = UDim2.new(0, 70, 0, 20)
        statusLabel.Position = UDim2.new(1, -80, 0, 10)
        statusLabel.BackgroundColor3 = achievement.earned and Color3.fromRGB(40, 80, 40) or Color3.fromRGB(80, 40, 40)
        statusLabel.Font = Enum.Font.GothamSemibold
        statusLabel.Text = achievement.earned and "Completed" or "Locked"
        statusLabel.TextColor3 = achievement.earned and Color3.fromRGB(200, 255, 200) or Color3.fromRGB(255, 200, 200)
        statusLabel.TextSize = 12
        statusLabel.Parent = achievementCard
        
        -- Status indicator corner
        local statusCorner = Instance.new("UICorner")
        statusCorner.CornerRadius = UDim.new(0, 4)
        statusCorner.Parent = statusLabel
        
        -- Reward display if applicable
        if achievement.info.reward and achievement.info.reward > 0 then
            local rewardLabel = Instance.new("TextLabel")
            rewardLabel.Name = "RewardLabel"
            rewardLabel.Size = UDim2.new(0, 70, 0, 20)
            rewardLabel.Position = UDim2.new(1, -80, 0, 35)
            rewardLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 40)
            rewardLabel.Font = Enum.Font.GothamSemibold
            rewardLabel.Text = "$" .. formatNumber(achievement.info.reward)
            rewardLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
            rewardLabel.TextSize = 12
            rewardLabel.Parent = achievementCard
            
            -- Reward label corner
            local rewardCorner = Instance.new("UICorner")
            rewardCorner.CornerRadius = UDim.new(0, 4)
            rewardCorner.Parent = rewardLabel
        end
        
        return achievementCard
    end
    
    -- Function to format numbers with commas
    function formatNumber(num)
        local formatted = tostring(math.floor(num))
        local i = #formatted % 3
        if i == 0 then i = 3 end
        local result = formatted:sub(1, i)
        for j = i + 1, #formatted, 3 do
            result = result .. "," .. formatted:sub(j, j + 2)
        end
        return result
    end
    
    -- Function to format time
    function formatTime(seconds)
        if not seconds or seconds == math.huge then
            return "Never"
        end
        
        local days = math.floor(seconds / 86400)
        seconds = seconds % 86400
        local hours = math.floor(seconds / 3600)
        seconds = seconds % 3600
        local minutes = math.floor(seconds / 60)
        seconds = math.floor(seconds % 60)
        
        local result = ""
        if days > 0 then
            result = result .. days .. "d "
        end
        if hours > 0 or days > 0 then
            result = result .. hours .. "h "
        end
        if minutes > 0 or hours > 0 or days > 0 then
            result = result .. minutes .. "m "
        end
        result = result .. seconds .. "s"
        
        return result
    end
    
    -- Function to update UI based on rebirth data
    function updateRebirthInfo(data)
        if not data then return end
        
        -- Update main tab info
        costLabel.Text = "Cost: $" .. formatNumber(data.cost or 100000)
        rebirthCountLabel.Text = "Your Rebirth Level: " .. (data.rebirthCount or 0)
        multiplierLabel.Text = "Revenue Multiplier: " .. string.format("%.1f", (data.multiplier or 0) * 100) .. "%"
        
        -- Update progress bar
        local progress = data.progress or 0
        TweenService:Create(progressBarFill, TweenInfo.new(0.5), {
            Size = UDim2.new(progress, 0, 1, 0)
        }):Play()
        progressLabel.Text = "Progress: " .. string.format("%.1f", progress * 100) .. "%"
        
        -- Update next unlock info
        if data.nextFeature then
            nextUnlockLabel.Text = "Next Feature: " .. data.nextFeature.name .. " (Level " .. (data.rebirthCount + 1) .. ")"
        elseif data.nextPerk then
            nextUnlockLabel.Text = "Next Perk: " .. data.nextPerk.name .. " (Level " .. (data.rebirthCount + 1) .. ")"
        else
            nextUnlockLabel.Text = "Next Unlock: None"
        end
        
        -- Update stats
        totalRebirthsLabel.Text = "Total Rebirths: " .. (data.totalRebirths or 0)
        fastestRebirthLabel.Text = "Fastest Rebirth: " .. formatTime(data.fastestTime)
        
        -- Clear existing feature cards
        for _, child in ipairs(featuresScrollFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Add feature cards
        if data.unlockedFeatures and #data.unlockedFeatures > 0 then
            for i, feature in ipairs(data.unlockedFeatures) do
                local featureCard = createFeatureCard(feature)
                featureCard.LayoutOrder = feature.level
                featureCard.Parent = featuresScrollFrame
            end
            
            -- Update canvas size
            featuresScrollFrame.CanvasSize = UDim2.new(0, 0, 0, (#data.unlockedFeatures * 90))
        else
            -- Show "No features unlocked yet" message
            local noFeaturesLabel = Instance.new("TextLabel")
            noFeaturesLabel.Name = "NoFeaturesLabel"
            noFeaturesLabel.Size = UDim2.new(1, -20, 0, 40)
            noFeaturesLabel.BackgroundTransparency = 1
            noFeaturesLabel.Font = Enum.Font.GothamItalic
            noFeaturesLabel.Text = "No features unlocked yet. Rebirth to unlock special features!"
            noFeaturesLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            noFeaturesLabel.TextSize = 14
            noFeaturesLabel.TextWrapped = true
            noFeaturesLabel.Parent = featuresScrollFrame
        end
        
        -- Clear existing perk cards
        for _, child in ipairs(perksScrollFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Add perk cards
        if data.activePerks and #data.activePerks > 0 then
            for i, perk in ipairs(data.activePerks) do
                local perkCard = createPerkCard(perk)
                perkCard.LayoutOrder = perk.level
                perkCard.Parent = perksScrollFrame
            end
            
            -- Update canvas size
            perksScrollFrame.CanvasSize = UDim2.new(0, 0, 0, (#data.activePerks * 90))
        else
            -- Show "No perks unlocked yet" message
            local noPerksLabel = Instance.new("TextLabel")
            noPerksLabel.Name = "NoPerksLabel"
            noPerksLabel.Size = UDim2.new(1, -20, 0, 40)
            noPerksLabel.BackgroundTransparency = 1
            noPerksLabel.Font = Enum.Font.GothamItalic
            noPerksLabel.Text = "No perks unlocked yet. Reach higher rebirth levels to unlock perks!"
            noPerksLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            noPerksLabel.TextSize = 14
            noPerksLabel.TextWrapped = true
            noPerksLabel.Parent = perksScrollFrame
        end
        
        -- Clear existing achievement cards
        for _, child in ipairs(achievementsScrollFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Add achievement cards
        if data.achievements and #data.achievements > 0 then
            for i, achievement in ipairs(data.achievements) do
                local achievementCard = createAchievementCard(achievement)
                -- Sort by earned status (earned first), then by ID
                achievementCard.LayoutOrder = achievement.earned and i or (1000 + i)
                achievementCard.Parent = achievementsScrollFrame
            end
            
            -- Update canvas size
            achievementsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, (#data.achievements * 90))
        else
            -- Show "No achievements yet" message
            local noAchievementsLabel = Instance.new("TextLabel")
            noAchievementsLabel.Name = "NoAchievementsLabel"
            noAchievementsLabel.Size = UDim2.new(1, -20, 0, 40)
            noAchievementsLabel.BackgroundTransparency = 1
            noAchievementsLabel.Font = Enum.Font.GothamItalic
            noAchievementsLabel.Text = "No achievements yet. Complete rebirths to earn achievements!"
            noAchievementsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            noAchievementsLabel.TextSize = 14
            noAchievementsLabel.TextWrapped = true
            noAchievementsLabel.Parent = achievementsScrollFrame
        end
    end
    
    return {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        RebirthCountLabel = rebirthCountLabel,
        CostLabel = costLabel,
        MultiplierLabel = multiplierLabel,
        ProgressBarFill = progressBarFill,
        ProgressLabel = progressLabel,
        NextUnlockLabel = nextUnlockLabel,
        TotalRebirthsLabel = totalRebirthsLabel,
        FastestRebirthLabel = fastestRebirthLabel,
        UpdateRebirthInfo = updateRebirthInfo
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
        successMessage.Text = "Rebirth Successful!\nNew Multiplier: " .. string.format("%.1f", data.newMultiplier * 100) .. "%"
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
        
        -- Request updated info
        RebirthRemote:FireServer("GetInfo")
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
        errorMessage.Text = "Not enough cash!\nYou need $" .. formatNumber(data.required)
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
        -- Update all UI elements with the rebirth data
        rebirthUIElements.UpdateRebirthInfo(data)
    end
end

-- Format numbers with commas
function formatNumber(num)
    local formatted = tostring(math.floor(num))
    local i = #formatted % 3
    if i == 0 then i = 3 end
    local result = formatted:sub(1, i)
    for j = i + 1, #formatted, 3 do
        result = result .. "," .. formatted:sub(j, j + 2)
    end
    return result
end

-- Listen for server messages
RebirthRemote.OnClientEvent:Connect(handleRebirthInfo)

-- Request initial rebirth information
task.delay(2, function()
    RebirthRemote:FireServer("GetInfo")
end)

-- Add UI to PlayerGui
rebirthUIElements.ScreenGui.Parent = LocalPlayer.PlayerGui