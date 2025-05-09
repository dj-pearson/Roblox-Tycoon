--!strict
--[[
    UIServerHandler.server.luau
    
    Server-side handler for UI events and system interactions.
    Manages communication between UI components and game systems.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Get server-side systems
local ServerRegistry = require(script.Parent.Parent.Core.ServerRegistry)
local ServerEventBridge = ServerRegistry.getSystem("ServerEventBridge")
local AchievementSystem = ServerRegistry.getSystem("AchievementSystem")
local CommunityGoalSystem = ServerRegistry.getSystem("CommunityGoalSystem")
local RebirthSystem = ServerRegistry.getSystem("RebirthSystem")
local TutorialManager = ServerRegistry.getSystem("TutorialManager")
local SettingsManager = ServerRegistry.getSystem("SettingsManager")
local PlayerDataService = ServerRegistry.getSystem("PlayerDataService")
local NotificationSystem = ServerRegistry.getSystem("NotificationSystem")
local AnalyticsSystem = ServerRegistry.getSystem("AnalyticsSystem")

-- Handle UI events
local function handleUIEvents()
    -- Handle initial data request
    ServerEventBridge:connectEvent("RequestInitialData", function(player)
        -- Get all initial data
        local achievements = AchievementSystem:getPlayerAchievements(player)
        local goals = CommunityGoalSystem:getActiveGoals()
        local settings = SettingsManager:getPlayerSettings(player)
        local tutorialData = TutorialManager:getPlayerTutorialData(player)
        local playerData = PlayerDataService:getPlayerData(player)
        local playerProgress = {
            achievements = AchievementSystem:getPlayerProgress(player),
            communityGoals = CommunityGoalSystem:getPlayerProgress(player),
            tutorial = TutorialManager:getPlayerProgress(player)
        }
        
        -- Send all data to client
        ServerEventBridge:dispatchEvent(player, "AchievementsUpdated", {
            achievements = achievements,
            playerData = playerData,
            playerProgress = playerProgress.achievements
        })
        
        ServerEventBridge:dispatchEvent(player, "CommunityGoalsUpdated", {
            goals = goals,
            playerProgress = playerProgress.communityGoals
        })
        
        ServerEventBridge:dispatchEvent(player, "SettingsUpdated", {
            settings = settings,
            availableSettings = SettingsManager:getAvailableSettings()
        })
        
        ServerEventBridge:dispatchEvent(player, "TutorialUpdated", {
            tutorial = tutorialData,
            playerProgress = playerProgress.tutorial
        })
        
        -- Track analytics
        AnalyticsSystem:trackEvent(player, "UI_Initialization", {
            timestamp = os.time()
        })
    end)
    
    -- Handle achievement events
    ServerEventBridge:connectEvent("ShowAchievementsUI", function(player)
        local achievements = AchievementSystem:getPlayerAchievements(player)
        local playerData = PlayerDataService:getPlayerData(player)
        local playerProgress = AchievementSystem:getPlayerProgress(player)
        
        ServerEventBridge:dispatchEvent(player, "AchievementsUpdated", {
            achievements = achievements,
            playerData = playerData,
            playerProgress = playerProgress
        })
        
        -- Track analytics
        AnalyticsSystem:trackEvent(player, "UI_Interaction", {
            action = "view_achievements",
            timestamp = os.time()
        })
    end)
    
    -- Handle community goal events
    ServerEventBridge:connectEvent("ShowCommunityGoalsUI", function(player)
        local goals = CommunityGoalSystem:getActiveGoals()
        local playerProgress = CommunityGoalSystem:getPlayerProgress(player)
        
        ServerEventBridge:dispatchEvent(player, "CommunityGoalsUpdated", {
            goals = goals,
            playerProgress = playerProgress
        })
        
        -- Track analytics
        AnalyticsSystem:trackEvent(player, "UI_Interaction", {
            action = "view_community_goals",
            timestamp = os.time()
        })
    end)
    
    -- Handle settings events
    ServerEventBridge:connectEvent("ShowSettingsUI", function(player)
        local settings = SettingsManager:getPlayerSettings(player)
        local availableSettings = SettingsManager:getAvailableSettings()
        
        ServerEventBridge:dispatchEvent(player, "SettingsUpdated", {
            settings = settings,
            availableSettings = availableSettings
        })
        
        -- Track analytics
        AnalyticsSystem:trackEvent(player, "UI_Interaction", {
            action = "view_settings",
            timestamp = os.time()
        })
    end)
    
    -- Handle tutorial events
    ServerEventBridge:connectEvent("ShowTutorialUI", function(player)
        local tutorialData = TutorialManager:getPlayerTutorialData(player)
        local playerProgress = TutorialManager:getPlayerProgress(player)
        
        ServerEventBridge:dispatchEvent(player, "TutorialUpdated", {
            tutorial = tutorialData,
            playerProgress = playerProgress
        })
        
        -- Track analytics
        AnalyticsSystem:trackEvent(player, "UI_Interaction", {
            action = "view_tutorial",
            timestamp = os.time()
        })
    end)
    
    -- Handle settings updates
    ServerEventBridge:connectEvent("UpdateSettings", function(player, data)
        if data.settings then
            local success = SettingsManager:updatePlayerSettings(player, data.settings)
            
            if success then
                -- Notify all clients of settings update
                ServerEventBridge:dispatchEvent(player, "SettingsUpdated", {
                    settings = data.settings
                })
                
                -- Track analytics
                AnalyticsSystem:trackEvent(player, "Settings_Update", {
                    settings = data.settings,
                    timestamp = os.time()
                })
            end
        end
    end)
    
    -- Handle community goal participation
    ServerEventBridge:connectEvent("ParticipateInGoal", function(player, data)
        if data.goalId then
            local success = CommunityGoalSystem:participateInGoal(player, data.goalId)
            if success then
                -- Get updated goals and progress
                local goals = CommunityGoalSystem:getActiveGoals()
                local playerProgress = CommunityGoalSystem:getPlayerProgress(player)
                
                -- Notify all clients of goal update
                ServerEventBridge:dispatchEvent(player, "CommunityGoalsUpdated", {
                    goals = goals,
                    playerProgress = playerProgress
                })
                
                -- Track analytics
                AnalyticsSystem:trackEvent(player, "CommunityGoal_Participation", {
                    goalId = data.goalId,
                    timestamp = os.time()
                })
            end
        end
    end)
    
    -- Handle rebirth requests
    ServerEventBridge:connectEvent("RequestRebirth", function(player)
        local success, rebirthData = RebirthSystem:attemptRebirth(player)
        if success then
            -- Get updated player data
            local playerData = PlayerDataService:getPlayerData(player)
            local achievements = AchievementSystem:getPlayerAchievements(player)
            
            -- Notify player of successful rebirth
            ServerEventBridge:dispatchEvent(player, "RebirthCompleted", {
                rebirth = rebirthData,
                playerData = playerData
            })
            
            -- Update achievements
            ServerEventBridge:dispatchEvent(player, "AchievementsUpdated", {
                achievements = achievements
            })
            
            -- Track analytics
            AnalyticsSystem:trackEvent(player, "Rebirth_Complete", {
                level = rebirthData.level,
                timestamp = os.time()
            })
        end
    end)
    
    -- Handle tutorial step completion
    ServerEventBridge:connectEvent("CompleteTutorialStep", function(player, data)
        if data.stepId then
            local success = TutorialManager:completeStep(player, data.stepId)
            if success then
                -- Get updated tutorial data
                local tutorialData = TutorialManager:getPlayerTutorialData(player)
                local playerProgress = TutorialManager:getPlayerProgress(player)
                
                -- Notify player of step completion
                ServerEventBridge:dispatchEvent(player, "TutorialStepCompleted", {
                    step = tutorialData.steps[data.stepId]
                })
                
                -- Update tutorial UI
                ServerEventBridge:dispatchEvent(player, "TutorialUpdated", {
                    tutorial = tutorialData,
                    playerProgress = playerProgress
                })
                
                -- Track analytics
                AnalyticsSystem:trackEvent(player, "Tutorial_Step_Complete", {
                    stepId = data.stepId,
                    timestamp = os.time()
                })
            end
        end
    end)
    
    -- Handle UI interaction tracking
    ServerEventBridge:connectEvent("TrackUIInteraction", function(player, data)
        if data.interaction then
            AnalyticsSystem:trackEvent(player, "UI_Interaction", {
                action = data.interaction,
                component = data.component,
                timestamp = os.time()
            })
        end
    end)
    
    -- Handle UI error reporting
    ServerEventBridge:connectEvent("ReportUIError", function(player, data)
        if data.error then
            -- Log error
            warn("UI Error for player", player.Name, ":", data.error)
            
            -- Track error in analytics
            AnalyticsSystem:trackEvent(player, "UI_Error", {
                error = data.error,
                component = data.component,
                timestamp = os.time()
            })
            
            -- Notify player
            NotificationSystem:sendNotification(player, {
                type = "error",
                message = "An error occurred. Please try again.",
                duration = 5
            })
        end
    end)
end

-- Initialize when the script runs
handleUIEvents()

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
    -- Wait for player data to load
    task.wait(1)
    
    -- Send initial data to player
    local achievements = AchievementSystem:getPlayerAchievements(player)
    local goals = CommunityGoalSystem:getActiveGoals()
    local settings = SettingsManager:getPlayerSettings(player)
    local tutorialData = TutorialManager:getPlayerTutorialData(player)
    local playerData = PlayerDataService:getPlayerData(player)
    local playerProgress = {
        achievements = AchievementSystem:getPlayerProgress(player),
        communityGoals = CommunityGoalSystem:getPlayerProgress(player),
        tutorial = TutorialManager:getPlayerProgress(player)
    }
    
    -- Dispatch initial data
    ServerEventBridge:dispatchEvent(player, "AchievementsUpdated", {
        achievements = achievements,
        playerData = playerData,
        playerProgress = playerProgress.achievements
    })
    
    ServerEventBridge:dispatchEvent(player, "CommunityGoalsUpdated", {
        goals = goals,
        playerProgress = playerProgress.communityGoals
    })
    
    ServerEventBridge:dispatchEvent(player, "SettingsUpdated", {
        settings = settings,
        availableSettings = SettingsManager:getAvailableSettings()
    })
    
    ServerEventBridge:dispatchEvent(player, "TutorialUpdated", {
        tutorial = tutorialData,
        playerProgress = playerProgress.tutorial
    })
    
    -- Track player join
    AnalyticsSystem:trackEvent(player, "Player_Join", {
        timestamp = os.time()
    })
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
    -- Track player leave
    AnalyticsSystem:trackEvent(player, "Player_Leave", {
        timestamp = os.time()
    })
end)

return {
    handleUIEvents = handleUIEvents
} 