--!strict
--[[
    UIBootstrap.client.luau
    
    Main entry point for the UI system.
    Initializes and manages all UI components.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Import core UI modules
local UISystem = require(script.Parent.Core.UISystem)
local UIManager = require(script.Parent.Core.UIManager)
local UIUtils = require(script.Parent.Core.UIUtils)
local UIConstants = require(script.Parent.Core.UIConstants)

-- Import UI components
local MainMenu = require(script.Parent.Components.MainMenu.MainMenu)
local SideMenu = require(script.Parent.Components.SideMenu.SideMenu)
local Achievements = require(script.Parent.Components.Achievements.Achievements)
local CommunityGoals = require(script.Parent.Components.CommunityGoals.CommunityGoals)
local Settings = require(script.Parent.Components.Settings.Settings)
local Tutorial = require(script.Parent.Components.Tutorial.Tutorial)

-- Import systems
local ClientRegistry = require(ReplicatedStorage.Shared.Systems.ClientRegistry)
local ClientEventBridge = ClientRegistry:GetSystem("ClientEventBridge")

-- Create UI system instance
local uiSystem = UISystem.new()

-- Initialize UI components
local function initializeComponents()
    -- Register all UI components
    uiSystem:registerComponent(MainMenu)
    uiSystem:registerComponent(SideMenu)
    uiSystem:registerComponent(Achievements)
    uiSystem:registerComponent(CommunityGoals)
    uiSystem:registerComponent(Settings)
    uiSystem:registerComponent(Tutorial)
    
    -- Show initial UI
    uiSystem:showComponent(UIConstants.ComponentNames.MainMenu)
    uiSystem:showComponent(UIConstants.ComponentNames.SideMenu)
end

-- Connect server events to UI actions
local function connectEvents()
    -- Show UI events
    ClientEventBridge:Connect("ShowUI", function(componentName, data)
        uiSystem:showComponent(componentName)
        if data then
            uiSystem:updateComponent(componentName, data)
        end
    end)
    
    -- Hide UI events
    ClientEventBridge:Connect("HideUI", function(componentName)
        uiSystem:hideComponent(componentName)
    end)
    
    -- Update UI events
    ClientEventBridge:Connect("UpdateUI", function(componentName, data)
        uiSystem:updateComponent(componentName, data)
    end)
    
    -- Achievement events
    ClientEventBridge:Connect("AchievementUnlocked", function(achievement)
        uiSystem:updateComponent(UIConstants.ComponentNames.Achievements, {
            unlockedAchievements = {achievement}
        })
    end)
    
    -- Community goal events
    ClientEventBridge:Connect("CommunityGoalUpdate", function(goal)
        uiSystem:updateComponent(UIConstants.ComponentNames.CommunityGoals, {
            activeGoals = {goal}
        })
    end)
    
    -- Rebirth events
    ClientEventBridge:Connect("RebirthUpdate", function(data)
        uiSystem:updateComponent(UIConstants.ComponentNames.SideMenu, {
            rebirthData = data
        })
    end)
    
    -- Tutorial events
    ClientEventBridge:Connect("TutorialUpdate", function(data)
        uiSystem:updateComponent(UIConstants.ComponentNames.Tutorial, data)
    end)
    
    -- Settings events
    ClientEventBridge:Connect("SettingsUpdate", function(settings)
        uiSystem:updateComponent(UIConstants.ComponentNames.Settings, settings)
    end)
    
    -- UI interaction events
    ClientEventBridge:Connect("UIInteraction", function(componentName, interactionType, data)
        -- Track UI interactions
        ClientEventBridge:Fire("TrackUIInteraction", {
            component = componentName,
            type = interactionType,
            data = data
        })
    end)
    
    -- UI error events
    ClientEventBridge:Connect("UIError", function(error)
        -- Show error modal
        uiSystem:showModal({
            title = "Error",
            message = error.message,
            buttons = {
                {
                    text = "OK",
                    action = function()
                        uiSystem:hideModal()
                    end
                }
            }
        })
        
        -- Report error
        ClientEventBridge:Fire("ReportUIError", error)
    end)
end

-- Request initial data from server
local function requestInitialData()
    ClientEventBridge:Fire("RequestInitialData")
end

-- Initialize UI system
local function initialize()
    -- Initialize components
    initializeComponents()
    
    -- Connect events
    connectEvents()
    
    -- Request initial data
    requestInitialData()
end

-- Initialize when player is ready
local function onPlayerReady()
    initialize()
end

-- Check if player is ready
local function checkPlayerReady()
    local player = Players.LocalPlayer
    if player and player:IsDescendantOf(game) then
        onPlayerReady()
    else
        Players.PlayerAdded:Connect(function(newPlayer)
            if newPlayer == player then
                onPlayerReady()
            end
        end)
    end
end

-- Start initialization
checkPlayerReady()

return uiSystem 