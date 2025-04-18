-- SeasonalEventsUI.luau
-- UI module for Seasonal Events
-- Place in ReplicatedStorage/UIModules

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Configuration
local CONFIG = {
    frameSize = UDim2.new(0, 650, 0, 450),
    framePosition = UDim2.new(0.5, 0, 0.5, 0),
    frameAnchorPoint = Vector2.new(0.5, 0.5),
    headerHeight = 50,
    cardSize = UDim2.new(1, -40, 0, 120),
    cardSpacing = 10,
    buttonSize = UDim2.new(0, 120, 0, 36),
    animationDuration = 0.5,
    colors = {
        background = Color3.fromRGB(30, 30, 30),
        header = Color3.fromRGB(40, 40, 40),
        card = Color3.fromRGB(50, 50, 50),
        cardHighlight = Color3.fromRGB(60, 60, 60),
        cardSelected = Color3.fromRGB(70, 140, 70),
        textPrimary = Color3.fromRGB(240, 240, 240),
        textSecondary = Color3.fromRGB(180, 180, 180),
        buttonPrimary = Color3.fromRGB(0, 120, 180),
        buttonSuccess = Color3.fromRGB(0, 160, 70),
        buttonDanger = Color3.fromRGB(180, 40, 40),
        buttonDisabled = Color3.fromRGB(100, 100, 100),
        activeEvent = Color3.fromRGB(220, 120, 30)
    }
}

-- UI Module
local SeasonalEventsUI = {}

-- Create the UI elements
function SeasonalEventsUI.create(data)
    local ui = {}
    ui.data = data
    
    -- Main container
    ui.screenGui = Instance.new("ScreenGui")
    ui.screenGui.Name = "SeasonalEventsUI"
    ui.screenGui.ResetOnSpawn = false
    ui.screenGui.DisplayOrder = 10
    ui.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main frame
    ui.mainFrame = Instance.new("Frame")
    ui.mainFrame.Name = "MainFrame"
    ui.mainFrame.Size = CONFIG.frameSize
    ui.mainFrame.Position = CONFIG.framePosition
    ui.mainFrame.AnchorPoint = CONFIG.frameAnchorPoint
    ui.mainFrame.BackgroundColor3 = CONFIG.colors.background
    ui.mainFrame.BorderSizePixel = 0
    ui.mainFrame.Parent = ui.screenGui
    
    -- Rounded corners
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = ui.mainFrame
    
    -- Header
    ui.header = Instance.new("Frame")
    ui.header.Name = "Header"
    ui.header.Size = UDim2.new(1, 0, 0, CONFIG.headerHeight)
    ui.header.BackgroundColor3 = CONFIG.colors.header
    ui.header.BorderSizePixel = 0
    ui.header.Parent = ui.mainFrame
    
    -- Header rounded corners
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = ui.header
    
    -- Title
    ui.title = Instance.new("TextLabel")
    ui.title.Name = "Title"
    ui.title.Size = UDim2.new(1, -100, 1, 0)
    ui.title.Position = UDim2.new(0, 20, 0, 0)
    ui.title.BackgroundTransparency = 1
    ui.title.Font = Enum.Font.GothamBold
    ui.title.TextColor3 = CONFIG.colors.textPrimary
    ui.title.TextSize = 24
    ui.title.TextXAlignment = Enum.TextXAlignment.Left
    ui.title.Text = "Seasonal Events"
    ui.title.Parent = ui.header
    
    -- Close button
    ui.closeButton = Instance.new("TextButton")
    ui.closeButton.Name = "CloseButton"
    ui.closeButton.Size = UDim2.new(0, 36, 0, 36)
    ui.closeButton.Position = UDim2.new(1, -40, 0, 7)
    ui.closeButton.BackgroundColor3 = CONFIG.colors.buttonDanger
    ui.closeButton.Font = Enum.Font.GothamBold
    ui.closeButton.TextColor3 = CONFIG.colors.textPrimary
    ui.closeButton.TextSize = 18
    ui.closeButton.Text = "X"
    ui.closeButton.Parent = ui.header
    
    -- Close button rounded corners
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 18)
    closeCorner.Parent = ui.closeButton
    
    -- Active season info
    ui.activeInfo = Instance.new("Frame")
    ui.activeInfo.Name = "ActiveInfo"
    ui.activeInfo.Size = UDim2.new(1, -40, 0, 80)
    ui.activeInfo.Position = UDim2.new(0, 20, 0, CONFIG.headerHeight + 10)
    ui.activeInfo.BackgroundColor3 = CONFIG.colors.activeEvent
    ui.activeInfo.BackgroundTransparency = 0.5
    ui.activeInfo.BorderSizePixel = 0
    ui.activeInfo.Visible = data.activeSeason ~= nil
    ui.activeInfo.Parent = ui.mainFrame
    
    -- Active info rounded corners
    local activeCorner = Instance.new("UICorner")
    activeCorner.CornerRadius = UDim.new(0, 8)
    activeCorner.Parent = ui.activeInfo
    
    -- Active season title
    ui.activeTitle = Instance.new("TextLabel")
    ui.activeTitle.Name = "ActiveTitle"
    ui.activeTitle.Size = UDim2.new(1, -20, 0, 30)
    ui.activeTitle.Position = UDim2.new(0, 10, 0, 5)
    ui.activeTitle.BackgroundTransparency = 1
    ui.activeTitle.Font = Enum.Font.GothamBold
    ui.activeTitle.TextColor3 = CONFIG.colors.textPrimary
    ui.activeTitle.TextSize = 18
    ui.activeTitle.TextXAlignment = Enum.TextXAlignment.Left
    ui.activeTitle.Text = data.activeSeason and "Active Season: " .. data.activeSeason.name or "No Active Season"
    ui.activeTitle.Parent = ui.activeInfo
    
    -- Time remaining
    ui.timeRemaining = Instance.new("TextLabel")
    ui.timeRemaining.Name = "TimeRemaining"
    ui.timeRemaining.Size = UDim2.new(1, -20, 0, 20)
    ui.timeRemaining.Position = UDim2.new(0, 10, 0, 35)
    ui.timeRemaining.BackgroundTransparency = 1
    ui.timeRemaining.Font = Enum.Font.Gotham
    ui.timeRemaining.TextColor3 = CONFIG.colors.textPrimary
    ui.timeRemaining.TextSize = 14
    ui.timeRemaining.TextXAlignment = Enum.TextXAlignment.Left
    ui.timeRemaining.Text = data.timeRemaining or ""
    ui.timeRemaining.Parent = ui.activeInfo
    
    -- Leave button
    ui.leaveButton = Instance.new("TextButton")
    ui.leaveButton.Name = "LeaveButton"
    ui.leaveButton.Size = CONFIG.buttonSize
    ui.leaveButton.Position = UDim2.new(1, -130, 0, 20)
    ui.leaveButton.BackgroundColor3 = CONFIG.colors.buttonDanger
    ui.leaveButton.Font = Enum.Font.GothamBold
    ui.leaveButton.TextColor3 = CONFIG.colors.textPrimary
    ui.leaveButton.TextSize = 14
    ui.leaveButton.Text = "Leave Season"
    ui.leaveButton.Visible = data.activeSeason ~= nil
    ui.leaveButton.Parent = ui.activeInfo
    
    -- Leave button rounded corners
    local leaveCorner = Instance.new("UICorner")
    leaveCorner.CornerRadius = UDim.new(0, 6)
    leaveCorner.Parent = ui.leaveButton
    
    -- Global season info
    ui.globalInfo = Instance.new("Frame")
    ui.globalInfo.Name = "GlobalInfo"
    ui.globalInfo.Size = UDim2.new(1, -40, 0, 40)
    ui.globalInfo.Position = UDim2.new(0, 20, 0, data.activeSeason and (CONFIG.headerHeight + 100) or (CONFIG.headerHeight + 10))
    ui.globalInfo.BackgroundColor3 = CONFIG.colors.header
    ui.globalInfo.BackgroundTransparency = 0.5
    ui.globalInfo.BorderSizePixel = 0
    ui.globalInfo.Visible = data.globalSeason ~= nil
    ui.globalInfo.Parent = ui.mainFrame
    
    -- Global info rounded corners
    local globalCorner = Instance.new("UICorner")
    globalCorner.CornerRadius = UDim.new(0, 8)
    globalCorner.Parent = ui.globalInfo
    
    -- Global season text
    ui.globalText = Instance.new("TextLabel")
    ui.globalText.Name = "GlobalText"
    ui.globalText.Size = UDim2.new(1, -20, 1, 0)
    ui.globalText.Position = UDim2.new(0, 10, 0, 0)
    ui.globalText.BackgroundTransparency = 1
    ui.globalText.Font = Enum.Font.GothamSemibold
    ui.globalText.TextColor3 = CONFIG.colors.textPrimary
    ui.globalText.TextSize = 16
    ui.globalText.TextXAlignment = Enum.TextXAlignment.Left
    ui.globalText.Text = data.globalSeason and "Global Event: " .. data.globalSeason.name or ""
    ui.globalText.Parent = ui.globalInfo
    
    -- Available seasons container
    ui.container = Instance.new("ScrollingFrame")
    ui.container.Name = "SeasonsContainer"
    ui.container.Size = UDim2.new(1, -40, 1, (data.globalSeason and -210 or -170) - (data.activeSeason and 90 or 0))
    ui.container.Position = UDim2.new(0, 20, 0, (CONFIG.headerHeight + 60) + (data.activeSeason and 90 or 0) + (data.globalSeason and 50 or 0))
    ui.container.BackgroundTransparency = 1
    ui.container.BorderSizePixel = 0
    ui.container.ScrollBarThickness = 4
    ui.container.ScrollingDirection = Enum.ScrollingDirection.Y
    ui.container.Parent = ui.mainFrame
    
    -- Layout for the container
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, CONFIG.cardSpacing)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = ui.container
    
    -- Description at the bottom
    ui.description = Instance.new("TextLabel")
    ui.description.Name = "Description"
    ui.description.Size = UDim2.new(1, -40, 0, 40)
    ui.description.Position = UDim2.new(0, 20, 1, -50)
    ui.description.BackgroundTransparency = 1
    ui.description.Font = Enum.Font.Gotham
    ui.description.TextColor3 = CONFIG.colors.textSecondary
    ui.description.TextSize = 14
    ui.description.TextWrapped = true
    ui.description.Text = "Join a seasonal event to receive special bonuses for your gym!"
    ui.description.Parent = ui.mainFrame
    
    -- Create season cards
    ui.cards = {}
    if data.availableSeasons then
        for i, season in ipairs(data.availableSeasons) do
            ui.cards[season.id] = SeasonalEventsUI.createSeasonCard(ui.container, season, i)
            
            -- Add join button functionality
            if season.available and not (data.activeSeason and data.activeSeason.id == season.id) then
                local joinButton = ui.cards[season.id].JoinButton
                joinButton.MouseButton1Click:Connect(function()
                    if data.onJoinSeason then
                        data.onJoinSeason(season.id)
                    end
                end)
            end
        end
    end
    
    -- Connect leave button
    ui.leaveButton.MouseButton1Click:Connect(function()
        if data.onLeaveSeason then
            data.onLeaveSeason()
        end
    end)
    
    -- Connect close button
    ui.closeButton.MouseButton1Click:Connect(function()
        if data.onClose then
            data.onClose()
        end
        SeasonalEventsUI.close(ui)
    end)
    
    -- Update scroll frame canvas size
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ui.container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
    end)
    
    return ui
end

-- Create a season card
function SeasonalEventsUI.createSeasonCard(parent, season, index)
    local card = Instance.new("Frame")
    card.Name = season.id .. "Card"
    card.Size = CONFIG.cardSize
    card.BackgroundColor3 = season.active and CONFIG.colors.cardSelected or CONFIG.colors.card
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    
    -- Rounded corners
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    -- Season name
    local name = Instance.new("TextLabel")
    name.Name = "Name"
    name.Size = UDim2.new(1, -150, 0, 30)
    name.Position = UDim2.new(0, 15, 0, 10)
    name.BackgroundTransparency = 1
    name.Font = Enum.Font.GothamBold
    name.TextColor3 = CONFIG.colors.textPrimary
    name.TextSize = 18
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.TextYAlignment = Enum.TextYAlignment.Center
    name.Text = season.name
    name.Parent = card
    
    -- Duration
    local duration = Instance.new("TextLabel")
    duration.Name = "Duration"
    duration.Size = UDim2.new(0, 120, 0, 20)
    duration.Position = UDim2.new(1, -135, 0, 15)
    duration.BackgroundTransparency = 1
    duration.Font = Enum.Font.Gotham
    duration.TextColor3 = CONFIG.colors.textSecondary
    duration.TextSize = 14
    duration.TextXAlignment = Enum.TextXAlignment.Left
    duration.Text = "Duration: " .. season.duration .. " days"
    duration.Parent = card
    
    -- Description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, -150, 0, 50)
    description.Position = UDim2.new(0, 15, 0, 40)
    description.BackgroundTransparency = 1
    description.Font = Enum.Font.Gotham
    description.TextColor3 = CONFIG.colors.textSecondary
    description.TextSize = 14
    description.TextWrapped = true
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.Text = season.description
    description.Parent = card
    
    -- Active label (if this season is active)
    if season.active then
        local activeLabel = Instance.new("TextLabel")
        activeLabel.Name = "ActiveLabel"
        activeLabel.Size = UDim2.new(0, 80, 0, 24)
        activeLabel.Position = UDim2.new(1, -95, 0, 45)
        activeLabel.BackgroundColor3 = CONFIG.colors.activeEvent
        activeLabel.Font = Enum.Font.GothamBold
        activeLabel.TextColor3 = CONFIG.colors.textPrimary
        activeLabel.TextSize = 14
        activeLabel.Text = "ACTIVE"
        activeLabel.Parent = card
        
        -- Rounded corners for active label
        local labelCorner = Instance.new("UICorner")
        labelCorner.CornerRadius = UDim.new(0, 4)
        labelCorner.Parent = activeLabel
    else
        -- Join button (if not active and requirements are met)
        local joinButton = Instance.new("TextButton")
        joinButton.Name = "JoinButton"
        joinButton.Size = UDim2.new(0, 80, 0, 32)
        joinButton.Position = UDim2.new(1, -95, 0, 45)
        joinButton.BackgroundColor3 = season.available and CONFIG.colors.buttonPrimary or CONFIG.colors.buttonDisabled
        joinButton.Font = Enum.Font.GothamBold
        joinButton.TextColor3 = CONFIG.colors.textPrimary
        joinButton.TextSize = 14
        joinButton.Text = "Join"
        joinButton.AutoButtonColor = season.available
        joinButton.Enabled = season.available
        joinButton.Parent = card
        
        -- Rounded corners for join button
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = joinButton
        
        -- Requirements text (if not available)
        if not season.available then
            local requirements = Instance.new("TextLabel")
            requirements.Name = "Requirements"
            requirements.Size = UDim2.new(1, -30, 0, 20)
            requirements.Position = UDim2.new(0, 15, 1, -25)
            requirements.BackgroundTransparency = 1
            requirements.Font = Enum.Font.Gotham
            requirements.TextColor3 = Color3.fromRGB(255, 100, 100)
            requirements.TextSize = 12
            requirements.TextXAlignment = Enum.TextXAlignment.Left
            requirements.Text = season.reason or "Requirements not met"
            requirements.Parent = card
        end
    end
    
    card.Parent = parent
    return card
end

-- Open the UI
function SeasonalEventsUI.open(ui)
    -- Initial position
    ui.mainFrame.Position = UDim2.new(0.5, 0, 1.1, 0)
    
    -- Parent to PlayerGui
    ui.screenGui.Parent = LocalPlayer.PlayerGui
    
    -- Animate open
    local openTween = TweenService:Create(
        ui.mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = CONFIG.framePosition}
    )
    openTween:Play()
end

-- Close the UI
function SeasonalEventsUI.close(ui)
    -- Animate close
    local closeTween = TweenService:Create(
        ui.mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Position = UDim2.new(0.5, 0, 1.1, 0)}
    )
    closeTween:Play()
    
    -- Clean up after animation
    closeTween.Completed:Connect(function()
        ui.screenGui:Destroy()
    end)
end

-- Module Interface
return {
    create = SeasonalEventsUI.create,
    open = SeasonalEventsUI.open,
    close = SeasonalEventsUI.close
}