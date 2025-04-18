--[[
    BasketballClient.luau
    Client controller for basketball system functionality
    Handles UI interactions, visual effects, and player controls for basketball
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Client config
local CONFIG = {
    -- Visual settings
    shootingIndicatorSize = UDim2.new(0, 100, 0, 100),
    scorePopupDuration = 2, -- How long score popups stay visible
    
    -- Input settings
    throwDistanceMultiplier = 1.2, -- Controls how far the throw goes based on power
    
    -- Camera effects
    cameraShakeIntensity = 0.2, -- How much camera shakes on certain events
    
    -- Sound effects
    soundIds = {
        crowdCheer = "rbxassetid://5853344708",
        buzzer = "rbxassetid://1548304764",
        scoreNotification = "rbxassetid://2697295ơ"
    },
    
    -- Debug
    debug = true
}

-- Module table
local BasketballClient = {
    _courtInfo = {}, -- Stores information about courts
    _activeCourt = nil, -- The court the player is currently interacting with
    _connections = {} -- Stores event connections
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[BasketballClient]", ...)
    end
end

--[[ Core Functions ]]--

-- Handle when the player scores a basket
function BasketballClient:_handleBasketScored(data)
    -- Play sound
    local sound = Instance.new("Sound")
    sound.SoundId = CONFIG.soundIds.scoreNotification
    sound.Volume = 0.7
    sound.Parent = playerGui
    sound:Play()
    game.Debris:AddItem(sound, 2)
    
    -- Show score popup
    self:_showScorePopup(data.points)
    
    -- Play crowd cheer for good shots
    if data.points >= 3 then
        local cheerSound = Instance.new("Sound")
        cheerSound.SoundId = CONFIG.soundIds.crowdCheer
        cheerSound.Volume = 0.5
        cheerSound.Parent = playerGui
        cheerSound:Play()
        game.Debris:AddItem(cheerSound, 3)
    end
    
    -- Update UI if we have a basketball UI
    local basketballUI = playerGui:FindFirstChild("BasketballUI")
    if basketballUI then
        local statsFrame = basketballUI:FindFirstChild("StatsFrame")
        if statsFrame then
            -- Update stats display
            local pointsLabel = statsFrame:FindFirstChild("PointsLabel")
            if pointsLabel then
                pointsLabel.Text = "Points: " .. (data.gameStats.totalPoints or 0)
            end
            
            local basketsLabel = statsFrame:FindFirstChild("BasketsLabel") 
            if basketsLabel then
                basketsLabel.Text = "Baskets: " .. (data.gameStats.basketsMade or 0)
            end
        end
    end
end

-- Show a popup when player scores
function BasketballClient:_showScorePopup(points)
    -- Create popup frame
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ScorePopup"
    screenGui.ResetOnSpawn = false
    
    local popupFrame = Instance.new("Frame")
    popupFrame.Size = UDim2.new(0, 120, 0, 60)
    popupFrame.Position = UDim2.new(0.5, -60, 0.4, 0)
    popupFrame.BackgroundTransparency = 0.3
    popupFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    popupFrame.BorderSizePixel = 0
    popupFrame.Parent = screenGui
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 12)
    uiCorner.Parent = popupFrame
    
    local pointsLabel = Instance.new("TextLabel")
    pointsLabel.Size = UDim2.new(1, 0, 0.7, 0)
    pointsLabel.Position = UDim2.new(0, 0, 0, 0)
    pointsLabel.BackgroundTransparency = 1
    pointsLabel.Text = "+" .. points
    pointsLabel.TextColor3 = points >= 3 
        and Color3.fromRGB(255, 215, 0)  -- Gold for 3-pointers
        or Color3.fromRGB(255, 255, 255) -- White for regular shots
    pointsLabel.TextSize = 36
    pointsLabel.Font = Enum.Font.GothamBold
    pointsLabel.Parent = popupFrame
    
    local pointsDescription = Instance.new("TextLabel")
    pointsDescription.Size = UDim2.new(1, 0, 0.3, 0)
    pointsDescription.Position = UDim2.new(0, 0, 0.7, 0)
    pointsDescription.BackgroundTransparency = 1
    pointsDescription.Text = points >= 3 and "THREE-POINTER!" or "BASKET!"
    pointsDescription.TextColor3 = Color3.fromRGB(255, 255, 255)
    pointsDescription.TextSize = 14
    pointsDescription.Font = Enum.Font.Gotham
    pointsDescription.Parent = popupFrame
    
    screenGui.Parent = playerGui
    
    -- Animate popup
    popupFrame.Size = UDim2.new(0, 0, 0, 0)
    pointsLabel.TextTransparency = 1
    pointsDescription.TextTransparency = 1
    
    -- Initial expansion
    local expandTween = TweenService:Create(popupFrame, 
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 120, 0, 60)}
    )
    
    local textFadeTween = TweenService:Create(pointsLabel, 
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    )
    
    local descFadeTween = TweenService:Create(pointsDescription, 
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    )
    
    expandTween:Play()
    expandTween.Completed:Connect(function()
        textFadeTween:Play()
        descFadeTween:Play()
        
        -- Float up animation
        local floatTween = TweenService:Create(popupFrame, 
            TweenInfo.new(CONFIG.scorePopupDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = UDim2.new(0.5, -60, 0.3, 0)}
        )
        floatTween:Play()
        
        -- Fade out at end
        task.delay(CONFIG.scorePopupDuration - 0.5, function()
            local fadeOutTween = TweenService:Create(popupFrame, 
                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            )
            
            local textFadeOutTween = TweenService:Create(pointsLabel, 
                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {TextTransparency = 1}
            )
            
            local descFadeOutTween = TweenService:Create(pointsDescription, 
                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {TextTransparency = 1}
            )
            
            fadeOutTween:Play()
            textFadeOutTween:Play()
            descFadeOutTween:Play()
            
            fadeOutTween.Completed:Connect(function()
                screenGui:Destroy()
            end)
        end)
    end)
end

-- Handle game start event
function BasketballClient:_handleGameStarted(data)
    debugPrint("Game started on court:", data.court)
    
    -- Set active court
    self._activeCourt = data.court
    
    -- Show game UI
    self:_showGameUI(data)
    
    -- Play sound
    local sound = Instance.new("Sound")
    sound.SoundId = CONFIG.soundIds.buzzer
    sound.Volume = 0.7
    sound.Parent = playerGui
    sound:Play()
    game.Debris:AddItem(sound, 2)
    
    -- Create notification
    local notification = Instance.new("ScreenGui")
    notification.Name = "GameStartNotification"
    notification.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 100)
    frame.Position = UDim2.new(0.5, -150, 0.2, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = notification
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 12)
    uiCorner.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "GAME STARTED"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 24
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = frame
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0.6, 0)
    infoLabel.Position = UDim2.new(0, 0, 0.4, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "Game Duration: " .. data.duration .. " seconds"
    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLabel.TextSize = 18
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.Parent = frame
    
    notification.Parent = playerGui
    
    -- Animate notification
    frame.Position = UDim2.new(0.5, -150, -0.2, 0)
    
    -- Slide down
    local slideTween = TweenService:Create(frame, 
        TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -150, 0.2, 0)}
    )
    
    slideTween:Play()
    
    -- Remove after delay
    task.delay(4, function()
        -- Slide up
        local slideOutTween = TweenService:Create(frame, 
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -150, -0.2, 0)}
        )
        
        slideOutTween:Play()
        slideOutTween.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end

-- Handle game end event
function BasketballClient:_handleGameEnded(data)
    debugPrint("Game ended on court:", data.court)
    
    -- Clear active court if it matches
    if self._activeCourt == data.court then
        self._activeCourt = nil
    end
    
    -- Play sound
    local sound = Instance.new("Sound")
    sound.SoundId = CONFIG.soundIds.buzzer
    sound.Volume = 1
    sound.Parent = playerGui
    sound:Play()
    game.Debris:AddItem(sound, 2)
    
    -- Show end game UI
    local endGameGui = Instance.new("ScreenGui")
    endGameGui.Name = "GameEndScreen"
    endGameGui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 250)
    frame.Position = UDim2.new(0.5, -200, 0.5, -125)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = endGameGui
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 16)
    uiCorner.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.2, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "GAME OVER"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
    titleLabel.TextSize = 36
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = frame
    
    -- Determine winner text
    local winnerText = "It's a tie!"
    local winnerColor = Color3.fromRGB(255, 255, 255)
    
    if data.winner == "team1" then
        winnerText = "Team 1 Wins!"
        winnerColor = Color3.fromRGB(85, 170, 255) -- Blue
    elseif data.winner == "team2" then
        winnerText = "Team 2 Wins!"
        winnerColor = Color3.fromRGB(255, 76, 76) -- Red
    end
    
    local winnerLabel = Instance.new("TextLabel")
    winnerLabel.Size = UDim2.new(1, 0, 0.2, 0)
    winnerLabel.Position = UDim2.new(0, 0, 0.2, 0)
    winnerLabel.BackgroundTransparency = 1
    winnerLabel.Text = winnerText
    winnerLabel.TextColor3 = winnerColor
    winnerLabel.TextSize = 28
    winnerLabel.Font = Enum.Font.GothamBold
    winnerLabel.Parent = frame
    
    local scoreFrame = Instance.new("Frame")
    scoreFrame.Size = UDim2.new(0.8, 0, 0.35, 0)
    scoreFrame.Position = UDim2.new(0.1, 0, 0.45, 0)
    scoreFrame.BackgroundTransparency = 0.5
    scoreFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    scoreFrame.BorderSizePixel = 0
    scoreFrame.Parent = frame
    
    local scoreCorner = Instance.new("UICorner")
    scoreCorner.CornerRadius = UDim.new(0, 8)
    scoreCorner.Parent = scoreFrame
    
    local team1Label = Instance.new("TextLabel")
    team1Label.Size = UDim2.new(0.4, 0, 0.8, 0)
    team1Label.Position = UDim2.new(0.1, 0, 0.1, 0)
    team1Label.BackgroundTransparency = 1
    team1Label.Text = "Team 1: " .. data.team1Score
    team1Label.TextColor3 = Color3.fromRGB(85, 170, 255) -- Blue
    team1Label.TextSize = 24
    team1Label.Font = Enum.Font.Gotham
    team1Label.TextXAlignment = Enum.TextXAlignment.Left
    team1Label.Parent = scoreFrame
    
    local team2Label = Instance.new("TextLabel")
    team2Label.Size = UDim2.new(0.4, 0, 0.8, 0)
    team2Label.Position = UDim2.new(0.5, 0, 0.1, 0)
    team2Label.BackgroundTransparency = 1
    team2Label.Text = "Team 2: " .. data.team2Score
    team2Label.TextColor3 = Color3.fromRGB(255, 76, 76) -- Red
    team2Label.TextSize = 24
    team2Label.Font = Enum.Font.Gotham
    team2Label.TextXAlignment = Enum.TextXAlignment.Left
    team2Label.Parent = scoreFrame
    
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0.4, 0, 0.15, 0)
    closeButton.Position = UDim2.new(0.3, 0, 0.8, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(59, 59, 59)
    closeButton.Text = "CLOSE"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = frame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = closeButton
    
    -- Button click event
    closeButton.MouseButton1Click:Connect(function()
        -- Fade out
        local fadeOutTween = TweenService:Create(frame, 
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        )
        
        local labelsTween = TweenService:Create(titleLabel, 
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextTransparency = 1}
        )
        
        local winnerTween = TweenService:Create(winnerLabel, 
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextTransparency = 1}
        )
        
        fadeOutTween:Play()
        labelsTween:Play()
        winnerTween:Play()
        
        team1Label.TextTransparency = 1
        team2Label.TextTransparency = 1
        closeButton.BackgroundTransparency = 1
        closeButton.TextTransparency = 1
        
        fadeOutTween.Completed:Connect(function()
            endGameGui:Destroy()
        end)
    end)
    
    -- Animate in
    frame.BackgroundTransparency = 1
    titleLabel.TextTransparency = 1
    winnerLabel.TextTransparency = 1
    scoreFrame.BackgroundTransparency = 1
    team1Label.TextTransparency = 1
    team2Label.TextTransparency = 1
    closeButton.BackgroundTransparency = 1
    closeButton.TextTransparency = 1
    
    endGameGui.Parent = playerGui
    
    -- Fade in
    local fadeInTween = TweenService:Create(frame, 
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.2}
    )
    
    local titleFadeTween = TweenService:Create(titleLabel, 
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    )
    
    local winnerFadeTween = TweenService:Create(winnerLabel, 
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    )
    
    local scoreFrameTween = TweenService:Create(scoreFrame, 
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.5}
    )
    
    fadeInTween:Play()
    titleFadeTween:Play()
    winnerFadeTween:Play()
    scoreFrameTween:Play()
    
    -- Delay other elements
    task.delay(0.2, function()
        local team1Tween = TweenService:Create(team1Label, 
            TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextTransparency = 0}
        )
        
        local team2Tween = TweenService:Create(team2Label, 
            TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextTransparency = 0}
        )
        
        team1Tween:Play()
        team2Tween:Play()
        
        task.delay(0.2, function()
            local buttonBackTween = TweenService:Create(closeButton, 
                TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 0}
            )
            
            local buttonTextTween = TweenService:Create(closeButton, 
                TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {TextTransparency = 0}
            )
            
            buttonBackTween:Play()
            buttonTextTween:Play()
        end)
    end)
    
    -- Auto close after 15 seconds
    task.delay(15, function()
        if endGameGui and endGameGui.Parent then
            endGameGui:Destroy()
        end
    end)
end

-- Show Game UI
function BasketballClient:_showGameUI(data)
    -- Check if UI already exists
    local existingUI = playerGui:FindFirstChild("BasketballUI")
    if existingUI then
        existingUI:Destroy()
    end
    
    -- Create main UI
    local basketballUI = Instance.new("ScreenGui")
    basketballUI.Name = "BasketballUI"
    basketballUI.ResetOnSpawn = false
    
    -- Create timer frame
    local timerFrame = Instance.new("Frame")
    timerFrame.Name = "TimerFrame"
    timerFrame.Size = UDim2.new(0, 200, 0, 80)
    timerFrame.Position = UDim2.new(0.5, -100, 0, 10)
    timerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    timerFrame.BackgroundTransparency = 0.5
    timerFrame.BorderSizePixel = 0
    timerFrame.Parent = basketballUI
    
    local timerCorner = Instance.new("UICorner")
    timerCorner.CornerRadius = UDim.new(0, 10)
    timerCorner.Parent = timerFrame
    
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "TimeLabel"
    timeLabel.Size = UDim2.new(1, 0, 0.6, 0)
    timeLabel.Position = UDim2.new(0, 0, 0, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = self:_formatTime(data.duration or 120)
    timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timeLabel.TextSize = 36
    timeLabel.Font = Enum.Font.GothamBold
    timeLabel.Parent = timerFrame
    
    local shotClockLabel = Instance.new("TextLabel")
    shotClockLabel.Name = "ShotClockLabel"
    shotClockLabel.Size = UDim2.new(1, 0, 0.4, 0)
    shotClockLabel.Position = UDim2.new(0, 0, 0.6, 0)
    shotClockLabel.BackgroundTransparency = 1
    shotClockLabel.Text = "Shot: 24"
    shotClockLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    shotClockLabel.TextSize = 20
    shotClockLabel.Font = Enum.Font.Gotham
    shotClockLabel.Parent = timerFrame
    
    -- Create score frame
    local scoreFrame = Instance.new("Frame")
    scoreFrame.Name = "ScoreFrame"
    scoreFrame.Size = UDim2.new(0, 200, 0, 60)
    scoreFrame.Position = UDim2.new(0.5, -100, 0, 100)
    scoreFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    scoreFrame.BackgroundTransparency = 0.5
    scoreFrame.BorderSizePixel = 0
    scoreFrame.Parent = basketballUI
    
    local scoreCorner = Instance.new("UICorner")
    scoreCorner.CornerRadius = UDim.new(0, 8)
    scoreCorner.Parent = scoreFrame
    
    -- Team 1 score
    local team1Frame = Instance.new("Frame")
    team1Frame.Size = UDim2.new(0.5, -1, 1, 0)
    team1Frame.Position = UDim2.new(0, 0, 0, 0)
    team1Frame.BackgroundColor3 = Color3.fromRGB(0, 80, 200)
    team1Frame.BackgroundTransparency = 0.7
    team1Frame.BorderSizePixel = 0
    team1Frame.Parent = scoreFrame
    
    local team1Corner = Instance.new("UICorner")
    team1Corner.CornerRadius = UDim.new(0, 8)
    team1Corner.Parent = team1Frame
    
    local team1Label = Instance.new("TextLabel")
    team1Label.Size = UDim2.new(1, 0, 0.4, 0)
    team1Label.Position = UDim2.new(0, 0, 0, 0)
    team1Label.BackgroundTransparency = 1
    team1Label.Text = "TEAM 1"
    team1Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    team1Label.TextSize = 16
    team1Label.Font = Enum.Font.GothamBold
    team1Label.Parent = team1Frame
    
    local team1ScoreLabel = Instance.new("TextLabel")
    team1ScoreLabel.Name = "ScoreLabel"
    team1ScoreLabel.Size = UDim2.new(1, 0, 0.6, 0)
    team1ScoreLabel.Position = UDim2.new(0, 0, 0.4, 0)
    team1ScoreLabel.BackgroundTransparency = 1
    team1ScoreLabel.Text = "0"
    team1ScoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    team1ScoreLabel.TextSize = 28
    team1ScoreLabel.Font = Enum.Font.GothamBold
    team1ScoreLabel.Parent = team1Frame
    
    -- Team 2 score
    local team2Frame = Instance.new("Frame")
    team2Frame.Size = UDim2.new(0.5, -1, 1, 0)
    team2Frame.Position = UDim2.new(0.5, 1, 0, 0)
    team2Frame.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    team2Frame.BackgroundTransparency = 0.7
    team2Frame.BorderSizePixel = 0
    team2Frame.Parent = scoreFrame
    
    local team2Corner = Instance.new("UICorner")
    team2Corner.CornerRadius = UDim.new(0, 8)
    team2Corner.Parent = team2Frame
    
    local team2Label = Instance.new("TextLabel")
    team2Label.Size = UDim2.new(1, 0, 0.4, 0)
    team2Label.Position = UDim2.new(0, 0, 0, 0)
    team2Label.BackgroundTransparency = 1
    team2Label.Text = "TEAM 2"
    team2Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    team2Label.TextSize = 16
    team2Label.Font = Enum.Font.GothamBold
    team2Label.Parent = team2Frame
    
    local team2ScoreLabel = Instance.new("TextLabel")
    team2ScoreLabel.Name = "ScoreLabel"
    team2ScoreLabel.Size = UDim2.new(1, 0, 0.6, 0)
    team2ScoreLabel.Position = UDim2.new(0, 0, 0.4, 0)
    team2ScoreLabel.BackgroundTransparency = 1
    team2ScoreLabel.Text = "0"
    team2ScoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    team2ScoreLabel.TextSize = 28
    team2ScoreLabel.Font = Enum.Font.GothamBold
    team2ScoreLabel.Parent = team2Frame
    
    -- Create stats frame
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(0, 180, 0, 100)
    statsFrame.Position = UDim2.new(0, 10, 0.5, -50)
    statsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    statsFrame.BackgroundTransparency = 0.7
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = basketballUI
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 8)
    statsCorner.Parent = statsFrame
    
    local statsTitle = Instance.new("TextLabel")
    statsTitle.Size = UDim2.new(1, 0, 0.3, 0)
    statsTitle.Position = UDim2.new(0, 0, 0, 0)
    statsTitle.BackgroundTransparency = 1
    statsTitle.Text = "YOUR STATS"
    statsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    statsTitle.TextSize = 16
    statsTitle.Font = Enum.Font.GothamBold
    statsTitle.Parent = statsFrame
    
    local pointsLabel = Instance.new("TextLabel")
    pointsLabel.Name = "PointsLabel"
    pointsLabel.Size = UDim2.new(0.9, 0, 0.2, 0)
    pointsLabel.Position = UDim2.new(0.05, 0, 0.35, 0)
    pointsLabel.BackgroundTransparency = 1
    pointsLabel.Text = "Points: 0"
    pointsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    pointsLabel.TextSize = 14
    pointsLabel.Font = Enum.Font.Gotham
    pointsLabel.TextXAlignment = Enum.TextXAlignment.Left
    pointsLabel.Parent = statsFrame
    
    local basketsLabel = Instance.new("TextLabel")
    basketsLabel.Name = "BasketsLabel"
    basketsLabel.Size = UDim2.new(0.9, 0, 0.2, 0)
    basketsLabel.Position = UDim2.new(0.05, 0, 0.55, 0)
    basketsLabel.BackgroundTransparency = 1
    basketsLabel.Text = "Baskets: 0"
    basketsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    basketsLabel.TextSize = 14
    basketsLabel.Font = Enum.Font.Gotham
    basketsLabel.TextXAlignment = Enum.TextXAlignment.Left
    basketsLabel.Parent = statsFrame
    
    local bestLabel = Instance.new("TextLabel")
    bestLabel.Name = "BestLabel"
    bestLabel.Size = UDim2.new(0.9, 0, 0.2, 0)
    bestLabel.Position = UDim2.new(0.05, 0, 0.75, 0)
    bestLabel.BackgroundTransparency = 1
    bestLabel.Text = "Best: 0"
    bestLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    bestLabel.TextSize = 14
    bestLabel.Font = Enum.Font.Gotham
    bestLabel.TextXAlignment = Enum.TextXAlignment.Left
    bestLabel.Parent = statsFrame
    
    -- Get player stats to update display
    self:_requestPlayerStats()
    
    -- Parent UI to player
    basketballUI.Parent = playerGui
    
    -- Start timer updater
    local connection = game:GetService("RunService").Heartbeat:Connect(function()
        local guiFolder = workspace:FindFirstChild("GuiFolder")
        if guiFolder then
            local timeValue = guiFolder:FindFirstChild("Time")
            if timeValue and timeLabel then
                timeLabel.Text = self:_formatTime(timeValue.Value)
            end
            
            local shotClockValue = guiFolder:FindFirstChild("ShotClock")
            if shotClockValue and shotClockLabel then
                shotClockLabel.Text = "Shot: " .. math.floor(shotClockValue.Value)
                
                -- Turn red when shot clock is low
                if shotClockValue.Value <= 5 then
                    shotClockLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                else
                    shotClockLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end
            
            local team1Score = guiFolder:FindFirstChild("Team1Score")
            if team1Score and team1ScoreLabel then
                team1ScoreLabel.Text = team1Score.Value
            end
            
            local team2Score = guiFolder:FindFirstChild("Team2Score")
            if team2Score and team2ScoreLabel then
                team2ScoreLabel.Text = team2Score.Value
            end
        end
    end)
    
    -- Store connection for cleanup
    table.insert(self._connections, connection)
    
    -- Animate UI in
    timerFrame.Position = UDim2.new(0.5, -100, -0.2, 0)
    scoreFrame.Position = UDim2.new(0.5, -100, -0.2, 0)
    statsFrame.Position = UDim2.new(-0.2, 0, 0.5, -50)
    
    local timerTween = TweenService:Create(timerFrame, 
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -100, 0, 10)}
    )
    
    local scoreTween = TweenService:Create(scoreFrame, 
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -100, 0, 100)}
    )
    
    local statsTween = TweenService:Create(statsFrame, 
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 10, 0.5, -50)}
    )
    
    timerTween:Play()
    
    task.delay(0.1, function()
        scoreTween:Play()
        
        task.delay(0.1, function()
            statsTween:Play()
        end)
    end)
end

-- Format time for display (MM:SS)
function BasketballClient:_formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    
    -- Format with leading zeros
    return string.format("%02d:%02d", minutes, secs)
end

-- Request player stats from server
function BasketballClient:_requestPlayerStats()
    -- Fire remote to server to request stats
    if self._eventsInitialized then
        self._remoteEvents.RequestPlayerStats:FireServer()
    end
end

-- Set up remote events
function BasketballClient:_setupRemoteEvents()
    -- Create a folder for remote events if it doesn't exist
    local remoteFolder = ReplicatedStorage:FindFirstChild("BasketballRemotes")
    if not remoteFolder then
        remoteFolder = Instance.new("Folder")
        remoteFolder.Name = "BasketballRemotes"
        remoteFolder.Parent = ReplicatedStorage
        
        -- Create required remote events
        for _, eventName in pairs({
            "RequestPlayerStats",
            "RequestSpawnBall",
            "RequestStartGame",
            "RequestEndGame",
            "RequestJoinTeam"
        }) do
            local event = Instance.new("RemoteEvent")
            event.Name = eventName
            event.Parent = remoteFolder
        end
    end
    
    -- Store references to remote events
    self._remoteEvents = {
        RequestPlayerStats = remoteFolder:WaitForChild("RequestPlayerStats"),
        RequestSpawnBall = remoteFolder:WaitForChild("RequestSpawnBall"),
        RequestStartGame = remoteFolder:WaitForChild("RequestStartGame"),
        RequestEndGame = remoteFolder:WaitForChild("RequestEndGame"),
        RequestJoinTeam = remoteFolder:WaitForChild("RequestJoinTeam")
    }
    
    -- Listen for server events
    self._eventsInitialized = true
end

-- Init functions
function BasketballClient:init()
    -- Set up remote events
    self:_setupRemoteEvents()
    
    -- Set up client event listeners
    local EventBridge = require(ReplicatedStorage:WaitForChild("EventBridge"))
    
    EventBridge:listenToEvent("BasketballGameStarted", function(data)
        self:_handleGameStarted(data)
    end)
    
    EventBridge:listenToEvent("BasketballGameEnded", function(data)
        self:_handleGameEnded(data)
    end)
    
    EventBridge:listenToEvent("BasketScored", function(data)
        self:_handleBasketScored(data)
    end)
    
    EventBridge:listenToEvent("PlayerStatsResponse", function(stats)
        -- Update stats display on UI
        local basketballUI = playerGui:FindFirstChild("BasketballUI")
        if basketballUI then
            local statsFrame = basketballUI:FindFirstChild("StatsFrame")
            if statsFrame then
                local pointsLabel = statsFrame:FindFirstChild("PointsLabel")
                if pointsLabel then
                    pointsLabel.Text = "Points: " .. (stats.totalPoints or 0)
                end
                
                local basketsLabel = statsFrame:FindFirstChild("BasketsLabel")
                if basketsLabel then
                    basketsLabel.Text = "Baskets: " .. (stats.basketsMade or 0)
                end
                
                local bestLabel = statsFrame:FindFirstChild("BestLabel")
                if bestLabel then
                    bestLabel.Text = "Best: " .. (stats.personalBest or 0)
                end
            end
        end
    end)
end

function BasketballClient:start()
    -- Request initial stats
    self:_requestPlayerStats()
    
    return true
end

return BasketballClient