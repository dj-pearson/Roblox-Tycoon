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
local GuestPass = require(script.Parent.Components.GuestPass.GuestPass)
local GymMenu = require(script.Parent.Components.GymMenu.GymMenu)
local MemberSatisfaction = require(script.Parent.Components.MemberSatisfaction.MemberSatisfaction)
local PlayerStats = require(script.Parent.Components.PlayerStats.PlayerStats)
local ProgressBar = require(script.Parent.Components.ProgressBar.ProgressBar)

-- Import systems
local ClientRegistry = require(ReplicatedStorage.Shared.Systems.ClientRegistry)
local ClientEventBridge = ClientRegistry:GetSystem("ClientEventBridge")

-- Initialize UI system
local function initialize()
    -- Create UI system instance
    local uiSystem = UISystem.new()
    
    -- Register UI components
    uiSystem:registerComponent(MainMenu.new())
    uiSystem:registerComponent(SideMenu.new())
    uiSystem:registerComponent(Achievements.new())
    uiSystem:registerComponent(CommunityGoals.new())
    uiSystem:registerComponent(Settings.new())
    uiSystem:registerComponent(Tutorial.new())
    uiSystem:registerComponent(GuestPass.new())
    uiSystem:registerComponent(GymMenu.new())
    uiSystem:registerComponent(MemberSatisfaction.new())
    uiSystem:registerComponent(PlayerStats.new())
    uiSystem:registerComponent(ProgressBar.new())
    
    -- Connect server events to UI actions
    local ClientEventBridge = require(ReplicatedStorage.Shared.Systems.ClientRegistry):GetSystem("ClientEventBridge")
    
    -- Connect UI events
    ClientEventBridge:Connect("ShowUI", function(data)
        uiSystem:showComponent(data.componentName)
    end)
    
    ClientEventBridge:Connect("HideUI", function(data)
        uiSystem:hideComponent(data.componentName)
    end)
    
    ClientEventBridge:Connect("UpdateUI", function(data)
        uiSystem:updateComponent(data.componentName, data)
    end)
    
    -- Connect component-specific events
    ClientEventBridge:Connect("MemberSatisfactionUpdate", function(data)
        uiSystem:updateComponent(UIConstants.ComponentNames.MemberSatisfaction, data)
    end)
    
    ClientEventBridge:Connect("PlayerStatsUpdate", function(data)
        uiSystem:updateComponent(UIConstants.ComponentNames.PlayerStats, data)
    end)
    
    ClientEventBridge:Connect("ProgressBarUpdate", function(data)
        uiSystem:updateComponent(UIConstants.ComponentNames.ProgressBar, data)
    end)
    
    -- Show initial UI components
    uiSystem:showComponent(UIConstants.ComponentNames.PlayerStats)
    uiSystem:showComponent(UIConstants.ComponentNames.ProgressBar)
    
    -- Request initial data from server
    ClientEventBridge:Fire("RequestInitialData")
end

-- Initialize when player is ready
local player = Players.LocalPlayer

if player:IsDescendantOf(game) then
    initialize()
else
    player.ChildAdded:Connect(function(child)
        if child:IsA("PlayerGui") then
            initialize()
        end
    end)
end

return {
    initialize = initialize
} 