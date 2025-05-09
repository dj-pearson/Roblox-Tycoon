--!strict
--[[
    UIInitializer.client.luau
    
    Initializes and connects all UI components and systems.
    This script serves as the main entry point for the UI system.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Get client-side systems
local ClientRegistry = require(script.Parent.Parent.Core.ClientRegistry)
local ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")

-- Import UI components
local UISystem = require(script.Parent.Core.UISystem)
local MainMenu = require(script.Parent.Components.MainMenu.MainMenu)
local SideMenu = require(script.Parent.Components.SideMenu.SideMenu)
local Achievements = require(script.Parent.Components.Achievements.Achievements)
local CommunityGoals = require(script.Parent.Components.CommunityGoals.CommunityGoals)
local Settings = require(script.Parent.Components.Settings.Settings)
local Tutorial = require(script.Parent.Components.Tutorial.Tutorial)

-- Initialize UI system
local function initialize()
    -- Create UI system instance
    local uiSystem = UISystem.new()
    
    -- Create and register components
    local mainMenu = MainMenu.new()
    local sideMenu = SideMenu.new()
    local achievements = Achievements.new()
    local communityGoals = CommunityGoals.new()
    local settings = Settings.new()
    local tutorial = Tutorial.new()
    
    -- Register components with the UI system
    uiSystem:registerComponent(mainMenu)
    uiSystem:registerComponent(sideMenu)
    uiSystem:registerComponent(achievements)
    uiSystem:registerComponent(communityGoals)
    uiSystem:registerComponent(settings)
    uiSystem:registerComponent(tutorial)
    
    -- Store UI system in registry
    ClientRegistry:registerSystem("UISystem", uiSystem)
    
    -- Connect to server events
    ClientEventBridge:connectEvent("ShowAchievementsUI", function()
        uiSystem:showComponent("Achievements")
    end)
    
    ClientEventBridge:connectEvent("ShowCommunityGoalsUI", function()
        uiSystem:showComponent("CommunityGoals")
    end)
    
    ClientEventBridge:connectEvent("ShowSettingsUI", function()
        uiSystem:showComponent("Settings")
    end)
    
    ClientEventBridge:connectEvent("ShowTutorialUI", function()
        uiSystem:showComponent("Tutorial")
    end)
    
    -- Connect to menu actions
    ClientEventBridge:connectEvent("MenuAction", function(data)
        if data.action == "achievements" then
            uiSystem:showComponent("Achievements")
        elseif data.action == "community_goals" then
            uiSystem:showComponent("CommunityGoals")
        elseif data.action == "settings" then
            uiSystem:showComponent("Settings")
        elseif data.action == "tutorial" then
            uiSystem:showComponent("Tutorial")
        end
    end)
    
    -- Connect to UI updates
    ClientEventBridge:connectEvent("AchievementsUpdated", function(data)
        if uiSystem:isComponentVisible("Achievements") then
            achievements:update(data)
        end
    end)
    
    ClientEventBridge:connectEvent("CommunityGoalsUpdated", function(data)
        if uiSystem:isComponentVisible("CommunityGoals") then
            communityGoals:update(data)
        end
    end)
    
    ClientEventBridge:connectEvent("SettingsUpdated", function(data)
        if uiSystem:isComponentVisible("Settings") then
            settings:update(data)
        end
    end)
    
    ClientEventBridge:connectEvent("TutorialUpdated", function(data)
        if uiSystem:isComponentVisible("Tutorial") then
            tutorial:update(data)
        end
    end)
    
    -- Show initial UI
    uiSystem:showComponent("MainMenu")
    uiSystem:showComponent("SideMenu")
    
    -- Request initial data from server
    ClientEventBridge:dispatchEvent("RequestInitialData")
end

-- Initialize when player is ready
local player = Players.LocalPlayer
if player then
    initialize()
else
    Players.PlayerAdded:Connect(function(newPlayer)
        if newPlayer == Players.LocalPlayer then
            initialize()
        end
    end)
end

return {
    initialize = initialize
} 