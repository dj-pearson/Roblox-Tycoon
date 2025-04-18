-- AchievementNotification.luau
-- UI Module for displaying achievement unlock notifications
-- Place in ReplicatedStorage/UIModules

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    debugEnabled = true,
    notificationDuration = 6,          -- How long notification stays on screen (seconds)
    fadeInTime = 0.5,                  -- Time to fade in (seconds)
    fadeOutTime = 0.8,                 -- Time to fade out (seconds)
    slideDistance = 50,                -- Distance to slide in from (pixels)
    achievementSoundId = "rbxassetid://9125601193",  -- Achievement sound effect
    achievementColor = Color3.fromRGB(255, 215, 0),  -- Gold color for achievement text
    maxQueueSize = 5                   -- Maximum number of notifications in queue
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[AchievementNotification]", ...)
    end
end

-- Module table
local AchievementNotification = {
    notificationQueue = {},
    isDisplaying = false,
    activeNotification = nil
}

-- Show an achievement notification
function AchievementNotification.show(achievementData)
    -- Validate input
    if not achievementData or not achievementData.name then
        log("Invalid achievement data")
        return false
    end
    
    -- Queue the notification if one is already showing
    if AchievementNotification.isDisplaying then
        -- Don't queue if already at max
        if #AchievementNotification.notificationQueue >= CONFIG.maxQueueSize then
            log("Notification queue full, dropping: " .. achievementData.name)
            return false
        end
        
        log("Queueing notification: " .. achievementData.name)
        table.insert(AchievementNotification.notificationQueue, achievementData)
        return true
    end
    
    -- Mark as displaying
    AchievementNotification.isDisplaying = true
    
    -- Create the notification
    local notification = AchievementNotification.createNotification(achievementData)
    AchievementNotification.activeNotification = notification
    
    log("Showing notification: " .. achievementData.name)
    return true
end

-- Create a notification UI element
function AchievementNotification.createNotification(achievementData)
    -- Create the ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AchievementNotification"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 100 -- High display order to appear above other UIs
    screenGui.Parent = LocalPlayer.PlayerGui
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 350, 0, 100)
    mainFrame.Position = UDim2.new(0.5, 0, 0, -100) -- Start above screen
    mainFrame.AnchorPoint = Vector2.new(0.5, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Add gold accent at top
    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Size = UDim2.new(1, 0, 0, 6)
    accent.Position = UDim2.new(0, 0, 0, 0)
    accent.BackgroundColor3 = CONFIG.achievementColor
    accent.BorderSizePixel = 0
    accent.ZIndex = 2
    accent.Parent = mainFrame
    
    -- Add rounded corners to accent
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 4)
    accentCorner.Parent = accent
    
    -- Add trophy icon
    local trophy = Instance.new("ImageLabel")
    trophy.Name = "Trophy"
    trophy.Size = UDim2.new(0, 40, 0, 40)
    trophy.Position = UDim2.new(0, 20, 0.5, -20)
    trophy.BackgroundTransparency = 1
    trophy.Image = "rbxassetid://6031090990" -- Trophy icon
    trophy.ImageColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    trophy.Parent = mainFrame
    
    -- Add achievement icon if available
    if achievementData.icon then
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 30, 0, 30)
        icon.Position = UDim2.new(1, -40, 0, 20)
        icon.BackgroundTransparency = 1
        icon.Image = achievementData.icon
        icon.Parent = mainFrame
    end
    
    -- Add header text 
    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.Size = UDim2.new(0, 200, 0, 25)
    header.Position = UDim2.new(0, 75, 0, 15)
    header.BackgroundTransparency = 1
    header.TextColor3 = CONFIG.achievementColor
    header.TextSize = 18
    header.Font = Enum.Font.GothamBold
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = "Achievement Unlocked!"
    header.Parent = mainFrame
    
    -- Add achievement name
    local name = Instance.new("TextLabel")
    name.Name = "Name"
    name.Size = UDim2.new(0, 240, 0, 25)
    name.Position = UDim2.new(0, 75, 0, 40)
    name.BackgroundTransparency = 1
    name.TextColor3 = Color3.fromRGB(255, 255, 255)
    name.TextSize = 16
    name.Font = Enum.Font.GothamSemibold
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Text = achievementData.name
    name.Parent = mainFrame
    
    -- Add reward text if available
    if achievementData.reward then
        local reward = Instance.new("TextLabel")
        reward.Name = "Reward"
        reward.Size = UDim2.new(0, 240, 0, 20)
        reward.Position = UDim2.new(0, 75, 0, 65)
        reward.BackgroundTransparency = 1
        reward.TextColor3 = Color3.fromRGB(100, 255, 100)
        reward.TextSize = 14
        reward.Font = Enum.Font.Gotham
        reward.TextXAlignment = Enum.TextXAlignment.Left
        reward.Text = achievementData.reward
        reward.Parent = mainFrame
    end
    
    -- Play achievement sound
    local sound = Instance.new("Sound")
    sound.SoundId = CONFIG.achievementSoundId
    sound.Volume = 0.5
    sound.Parent = screenGui
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 3)
    
    -- Animate notification entry
    local targetY = 30 -- Final Y position
    
    -- Slide in from above with fade
    mainFrame.Position = UDim2.new(0.5, 0, 0, -mainFrame.Size.Y.Offset)
    mainFrame.BackgroundTransparency = 1
    accent.BackgroundTransparency = 1
    trophy.ImageTransparency = 1
    header.TextTransparency = 1
    name.TextTransparency = 1
    
    if achievementData.icon then
        mainFrame.Icon.ImageTransparency = 1
    end
    
    if achievementData.reward then
        mainFrame.Reward.TextTransparency = 1
    end
    
    -- Create entry tween
    local entryTween = TweenService:Create(
        mainFrame,
        TweenInfo.new(CONFIG.fadeInTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, 0, 0, targetY), BackgroundTransparency = 0.1}
    )
    
    -- Create fade-in tweens for UI elements
    local fadeTweens = {}
    fadeTweens[1] = TweenService:Create(accent, TweenInfo.new(CONFIG.fadeInTime, Enum.EasingStyle.Quad), {BackgroundTransparency = 0})
    fadeTweens[2] = TweenService:Create(trophy, TweenInfo.new(CONFIG.fadeInTime, Enum.EasingStyle.Quad), {ImageTransparency = 0})
    fadeTweens[3] = TweenService:Create(header, TweenInfo.new(CONFIG.fadeInTime, Enum.EasingStyle.Quad), {TextTransparency = 0})
    fadeTweens[4] = TweenService:Create(name, TweenInfo.new(CONFIG.fadeInTime, Enum.EasingStyle.Quad), {TextTransparency = 0})
    
    if achievementData.icon then
        fadeTweens[5] = TweenService:Create(mainFrame.Icon, TweenInfo.new(CONFIG.fadeInTime, Enum.EasingStyle.Quad), {ImageTransparency = 0})
    end
    
    if achievementData.reward then
        fadeTweens[6] = TweenService:Create(mainFrame.Reward, TweenInfo.new(CONFIG.fadeInTime, Enum.EasingStyle.Quad), {TextTransparency = 0})
    end
    
    -- Play entry tweens
    entryTween:Play()
    for _, tween in ipairs(fadeTweens) do
        tween:Play()
    end
    
    -- Schedule removal
    task.delay(CONFIG.notificationDuration, function()
        AchievementNotification.removeNotification(screenGui)
    end)
    
    return screenGui
end

-- Remove a notification and show the next one in queue if available
function AchievementNotification.removeNotification(notification)
    if not notification or not notification.Parent then return end
    
    -- Get main frame
    local mainFrame = notification:FindFirstChild("MainFrame")
    if not mainFrame then 
        notification:Destroy()
        AchievementNotification.activeNotification = nil
        AchievementNotification.isDisplaying = false
        AchievementNotification.processQueue()
        return 
    end
    
    -- Animate out
    local exitTween = TweenService:Create(
        mainFrame,
        TweenInfo.new(CONFIG.fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(0.5, 0, 0, -100), BackgroundTransparency = 1}
    )
    
    -- Create fade-out tweens for UI elements
    local fadeTweens = {}
    for _, child in ipairs(mainFrame:GetChildren()) do
        if child:IsA("Frame") or child:IsA("ImageLabel") or child:IsA("TextLabel") then
            fadeTweens[#fadeTweens + 1] = TweenService:Create(
                child,
                TweenInfo.new(CONFIG.fadeOutTime * 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {BackgroundTransparency = 1, ImageTransparency = 1, TextTransparency = 1}
            )
        end
    end
    
    -- Play exit tweens
    exitTween:Play()
    for _, tween in ipairs(fadeTweens) do
        tween:Play()
    end
    
    -- Destroy after tween completes
    task.delay(CONFIG.fadeOutTime, function()
        notification:Destroy()
        AchievementNotification.activeNotification = nil
        AchievementNotification.isDisplaying = false
        AchievementNotification.processQueue()
    end)
end

-- Process the notification queue
function AchievementNotification.processQueue()
    if #AchievementNotification.notificationQueue > 0 and not AchievementNotification.isDisplaying then
        -- Get the next notification
        local nextAchievement = table.remove(AchievementNotification.notificationQueue, 1)
        AchievementNotification.show(nextAchievement)
    end
end

-- Clear all notifications
function AchievementNotification.clearAll()
    -- Clear queue
    AchievementNotification.notificationQueue = {}
    
    -- Remove active notification
    if AchievementNotification.activeNotification then
        AchievementNotification.removeNotification(AchievementNotification.activeNotification)
    end
end

return AchievementNotification