-- NotificationSystem.luau
-- Handles different types of notifications to the player
-- Place in StarterPlayer/StarterPlayerScripts/Core

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local SoundService = game:GetService("SoundService")

-- Import client-side systems
local ClientRegistry = require(script.Parent.ClientRegistry)
local UIManager = ClientRegistry.getSystem("UIManager")
local ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")

-- Configuration
local CONFIG = {
    debugEnabled = true,
    defaultDuration = 5,            -- Default notification duration in seconds
    maxNotificationsAtOnce = 5,     -- Maximum number of notifications to show at once
    
    -- Sound configuration
    sounds = {
        info = "rbxassetid://6026984224",
        success = "rbxassetid://6026984224",
        warning = "rbxassetid://6026984224",
        error = "rbxassetid://6026984224"
    },
    
    -- Animation configuration
    animations = {
        defaultDuration = 0.5,
        defaultEasingStyle = Enum.EasingStyle.Back,
        defaultEasingDirection = Enum.EasingDirection.Out
    },
    
    -- Appearance configuration
    appearance = {
        infoColor = Color3.fromRGB(0, 120, 215),
        successColor = Color3.fromRGB(0, 180, 0),
        warningColor = Color3.fromRGB(255, 150, 0),
        errorColor = Color3.fromRGB(255, 50, 50)
    }
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[NotificationSystem]", ...)
    end
end

-- The NotificationSystem
local NotificationSystem = {
    notificationQueue = {},
    activeNotifications = {},
    notificationCounter = 0,
    sounds = {}
}

-- Initialize the system
function NotificationSystem:initialize()
    log("Initializing NotificationSystem...")
    
    -- Create sounds
    self:createSounds()
    
    -- Setup event handlers
    self:setupEventHandlers()
    
    log("NotificationSystem initialized successfully")
    return true
end

-- Create notification sounds
function NotificationSystem:createSounds()
    if not SoundService:FindFirstChild("NotificationSounds") then
        local folder = Instance.new("Folder")
        folder.Name = "NotificationSounds"
        folder.Parent = SoundService
        
        -- Create sounds for each notification type
        for type, soundId in pairs(CONFIG.sounds) do
            local sound = Instance.new("Sound")
            sound.Name = type
            sound.SoundId = soundId
            sound.Volume = 0.5
            sound.Parent = folder
            
            self.sounds[type] = sound
        end
    else
        -- Get existing sounds
        local folder = SoundService:FindFirstChild("NotificationSounds")
        for _, sound in pairs(folder:GetChildren()) do
            if sound:IsA("Sound") then
                self.sounds[sound.Name] = sound
            end
        end
    end
    
    log("Created notification sounds")
end

-- Setup event handlers
function NotificationSystem:setupEventHandlers()
    if not ClientEventBridge then
        log("ClientEventBridge not available, couldn't set up event handlers")
        return
    end
    
    -- Handle server notifications
    ClientEventBridge.connectEvent("ServerNotification", function(data)
        self:showNotification(data)
    end)
    
    -- Handle achievement notifications
    ClientEventBridge.connectEvent("AchievementUnlocked", function(data)
        self:showAchievementNotification(data)
    end)
    
    -- Handle milestone notifications
    ClientEventBridge.connectEvent("MilestoneReached", function(data)
        self:showMilestoneNotification(data)
    end)
    
    log("Set up event handlers")
end

-- Show a notification
function NotificationSystem:showNotification(data)
    -- Verify UIManager is available
    if not UIManager then
        log("UIManager not available, cannot show notification")
        return
    end
    
    -- Standard notification data
    local notificationType = data.type or "info"
    local title = data.title or "Notification"
    local message = data.message or ""
    local duration = data.duration or CONFIG.defaultDuration
    
    -- Play sound
    local sound = self.sounds[notificationType]
    if sound then
        sound:Play()
    end
    
    -- Create notification counter and ID
    self.notificationCounter = self.notificationCounter + 1
    local id = "notification_" .. self.notificationCounter
    
    -- Show notification via UIManager
    return UIManager.showNotification({
        id = id,
        title = title,
        message = message,
        duration = duration,
        type = notificationType
    })
end

-- Show an achievement notification (special formatting)
function NotificationSystem:showAchievementNotification(data)
    if not data then return end
    
    -- Achievement specifics
    local achievementName = data.name or "Achievement Unlocked"
    local description = data.description or ""
    local xpReward = data.xpReward or 0
    local coinReward = data.coinReward or 0
    
    -- Create enhanced message
    local message = description
    
    if xpReward > 0 or coinReward > 0 then
        message = message .. "\n\nRewards:"
        
        if xpReward > 0 then
            message = message .. "\n• " .. xpReward .. " XP"
        end
        
        if coinReward > 0 then
            message = message .. "\n• " .. coinReward .. " Coins"
        end
    end
    
    -- Show the achievement with success type
    return self:showNotification({
        title = "🏆 " .. achievementName,
        message = message,
        duration = 7, -- Longer duration for achievements
        type = "success"
    })
end

-- Show a milestone notification
function NotificationSystem:showMilestoneNotification(data)
    if not data then return end
    
    -- Milestone specifics
    local milestoneName = data.name or "Milestone Reached"
    local description = data.description or ""
    local rewards = data.rewards or {}
    
    -- Create enhanced message
    local message = description
    
    if #rewards > 0 then
        message = message .. "\n\nRewards:"
        
        for _, reward in ipairs(rewards) do
            message = message .. "\n• " .. reward
        end
    end
    
    -- Show the milestone with success type
    return self:showNotification({
        title = "🎯 " .. milestoneName,
        message = message,
        duration = 7, -- Longer duration for milestones
        type = "success"
    })
end

-- Show a tutorial notification
function NotificationSystem:showTutorialTip(data)
    if not data then return end
    
    local title = data.title or "Tip"
    local message = data.message or ""
    
    -- Show the tutorial tip with info type
    return self:showNotification({
        title = "💡 " .. title,
        message = message,
        duration = 10, -- Longer duration for tutorial tips
        type = "info"
    })
end

-- Show a warning notification
function NotificationSystem:showWarning(data)
    if not data then return end
    
    local title = data.title or "Warning"
    local message = data.message or ""
    
    -- Show the warning with warning type
    return self:showNotification({
        title = "⚠️ " .. title,
        message = message,
        duration = data.duration or CONFIG.defaultDuration,
        type = "warning"
    })
end

-- Show an error notification
function NotificationSystem:showError(data)
    if not data then return end
    
    local title = data.title or "Error"
    local message = data.message or ""
    
    -- Show the error with error type
    return self:showNotification({
        title = "❌ " .. title,
        message = message,
        duration = data.duration or CONFIG.defaultDuration,
        type = "error"
    })
end

-- Get notification configuration
function NotificationSystem:getConfig()
    return CONFIG
end

-- Set notification configuration
function NotificationSystem:setConfig(newConfig)
    for key, value in pairs(newConfig) do
        CONFIG[key] = value
    end
    return CONFIG
end

-- Public API
local PublicAPI = {
    initialize = function()
        return NotificationSystem:initialize()
    end,
    
    showNotification = function(data)
        return NotificationSystem:showNotification(data)
    end,
    
    showAchievementNotification = function(data)
        return NotificationSystem:showAchievementNotification(data)
    end,
    
    showMilestoneNotification = function(data)
        return NotificationSystem:showMilestoneNotification(data)
    end,
    
    showTutorialTip = function(data)
        return NotificationSystem:showTutorialTip(data)
    end,
    
    showWarning = function(data)
        return NotificationSystem:showWarning(data)
    end,
    
    showError = function(data)
        return NotificationSystem:showError(data)
    end,
    
    getConfig = function()
        return NotificationSystem:getConfig()
    end,
    
    setConfig = function(newConfig)
        return NotificationSystem:setConfig(newConfig)
    end
}

-- Register with ClientRegistry
return ClientRegistry.registerSystem("NotificationSystem", PublicAPI, {"UIManager", "ClientEventBridge"})