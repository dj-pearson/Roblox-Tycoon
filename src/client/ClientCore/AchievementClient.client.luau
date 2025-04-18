-- AchievementClient.luau
-- Client-side handler for the achievement system
-- Place in StarterPlayer/StarterPlayerScripts/ClientCore

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Modules
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local CoreFolder = PlayerScripts:WaitForChild("Core") 
local ClientRegistry = require(CoreFolder:WaitForChild("ClientRegistry"))

-- Get UI Modules
local UIModules = ReplicatedStorage:WaitForChild("UIModules")
local AchievementNotification = require(UIModules:WaitForChild("AchievementNotification"))
local AchievementsMenu = require(UIModules:WaitForChild("AchievementsMenu"))

-- Configuration
local CONFIG = {
    debugEnabled = true,
    menuKey = Enum.KeyCode.J,  -- Key to toggle achievements menu
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[AchievementClient]", ...)
    end
end

-- Achievement Client
local AchievementClient = {
    initialized = false,
    achievementData = {
        unlocked = {},
        progress = {},
        definitions = {}
    }
}

-- Initialize the client
function AchievementClient:initialize()
    if self.initialized then return true end
    
    log("Initializing AchievementClient...")
    
    -- Get required client systems
    self.UIManager = ClientRegistry.getSystem("UIManager")
    self.ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")
    self.NotificationSystem = ClientRegistry.getSystem("NotificationSystem")
    
    if not self.UIManager or not self.ClientEventBridge then
        log("Failed to get required systems")
        return false
    end
    
    -- Register the achievements menu with UIManager
    self.UIManager.registerUI("AchievementsMenu", AchievementsMenu)
    
    -- Connect to events
    self:connectToEvents()
    
    -- Request initial achievement data
    task.spawn(function()
        task.wait(2) -- Wait a moment for connections to establish
        self:requestAchievementData()
    end)
    
    -- Setup input handling for menu toggle
    self:setupInputHandling()
    
    self.initialized = true
    log("AchievementClient initialized")
    return true
end

-- Connect to achievement-related events
function AchievementClient:connectToEvents()
    if not self.ClientEventBridge then return end
    
    -- Handle achievement unlocked
    self.ClientEventBridge.connectEvent("AchievementUnlocked", function(achievementId, achievementData)
        log("Achievement Unlocked: " .. achievementId)
        
        -- Add to local data
        if achievementData then
            self.achievementData.definitions[achievementId] = achievementData
            self.achievementData.unlocked[achievementId] = true
            self.achievementData.progress[achievementId] = achievementData.progressMax or 1
            
            -- Show notification
            self:showAchievementNotification(achievementData)
        end
    end)
    
    -- Handle achievement progress updated
    self.ClientEventBridge.connectEvent("AchievementProgressUpdated", function(achievementId, progress, maxProgress)
        log("Achievement Progress: " .. achievementId .. " - " .. progress .. "/" .. (maxProgress or "?"))
        
        -- Update local data
        self.achievementData.progress[achievementId] = progress
    end)
    
    -- Handle receiving full achievement data
    self.ClientEventBridge.connectEvent("AchievementDataReceived", function(achievementData)
        log("Received achievement data")
        
        if achievementData then
            self.achievementData = achievementData
        end
    end)
    
    log("Connected to achievement events")
end

-- Set up input handling
function AchievementClient:setupInputHandling()
    -- Handle input to toggle menu
    LocalPlayer:GetMouse().KeyDown:Connect(function(key)
        if key:lower() == CONFIG.menuKey.Name:lower() then
            self:toggleAchievementsMenu()
        end
    end)
    
    log("Set up input handling")
end

-- Toggle achievements menu
function AchievementClient:toggleAchievementsMenu()
    if not self.UIManager then return end
    
    if self.UIManager.isUIOpen("AchievementsMenu") then
        self.UIManager.closeUI("AchievementsMenu")
    else
        self.UIManager.openUI("AchievementsMenu", self.achievementData)
    end
end

-- Show achievement notification
function AchievementClient:showAchievementNotification(achievementData)
    if not achievementData then return end
    
    local notificationData = {
        name = achievementData.name,
        description = achievementData.description,
        icon = achievementData.icon,
        reward = achievementData.rewardCash and ("Reward: $" .. achievementData.rewardCash) or nil
    }
    
    -- Use the notification system
    AchievementNotification.show(notificationData)
    
    -- Also send to general notification system if available
    if self.NotificationSystem then
        self.NotificationSystem.showNotification({
            title = "Achievement Unlocked!",
            message = achievementData.name,
            duration = 5,
            type = "success"
        })
    end
    
    log("Showed notification for: " .. achievementData.name)
end

-- Request achievement data from server
function AchievementClient:requestAchievementData()
    if not self.ClientEventBridge then return end
    
    log("Requesting achievement data")
    self.ClientEventBridge.fireServerEvent("GetPlayerAchievements")
end

-- Return the module for ClientRegistry
return AchievementClient