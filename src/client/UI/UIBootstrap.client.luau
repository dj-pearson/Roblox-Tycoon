--!strict
--[[
    UIBootstrap.client.luau
    
    Initializes and manages the UI system.
    Handles component registration and event routing.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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

-- Performance optimization
local DEBOUNCE_TIME = 0.1
local lastUpdateTime = {}
local isUpdating = {}

-- Error recovery
local MAX_RETRY_ATTEMPTS = 3
local retryAttempts = {}

-- Animation presets
local ANIMATION_PRESETS = {
    FADE_IN = {
        type = Constants.ANIMATIONS.FADE,
        duration = 0.5,
        properties = {
            BackgroundTransparency = { from = 1, to = 0 }
        }
    },
    FADE_OUT = {
        type = Constants.ANIMATIONS.FADE,
        duration = 0.5,
        properties = {
            BackgroundTransparency = { from = 0, to = 1 }
        }
    },
    SLIDE_IN_LEFT = {
        type = Constants.ANIMATIONS.SLIDE,
        duration = 0.5,
        properties = {
            Position = { from = UDim2.new(-0.2, 0, 0.5, 0), to = UDim2.new(0, 0, 0.5, 0) }
        }
    },
    SLIDE_OUT_LEFT = {
        type = Constants.ANIMATIONS.SLIDE,
        duration = 0.5,
        properties = {
            Position = { from = UDim2.new(0, 0, 0.5, 0), to = UDim2.new(-0.2, 0, 0.5, 0) }
        }
    },
    SCALE_IN = {
        type = Constants.ANIMATIONS.SCALE,
        duration = 0.3,
        properties = {
            Scale = { from = Vector3.new(0.8, 0.8, 1), to = Vector3.new(1, 1, 1) }
        }
    },
    SCALE_OUT = {
        type = Constants.ANIMATIONS.SCALE,
        duration = 0.3,
        properties = {
            Scale = { from = Vector3.new(1, 1, 1), to = Vector3.new(0.8, 0.8, 1) }
        }
    },
    -- New animation presets
    BOUNCE_IN = {
        type = Constants.ANIMATIONS.BOUNCE,
        duration = 0.5,
        properties = {
            Scale = { from = Vector3.new(0.5, 0.5, 1), to = Vector3.new(1, 1, 1) },
            Position = { from = UDim2.new(0.5, 0, 0.5, 0), to = UDim2.new(0.5, 0, 0.5, 0) }
        }
    },
    BOUNCE_OUT = {
        type = Constants.ANIMATIONS.BOUNCE,
        duration = 0.5,
        properties = {
            Scale = { from = Vector3.new(1, 1, 1), to = Vector3.new(0.5, 0.5, 1) },
            Position = { from = UDim2.new(0.5, 0, 0.5, 0), to = UDim2.new(0.5, 0, 0.5, 0) }
        }
    }
}

-- Helper functions
local function debounce(component, callback)
    local currentTime = os.clock()
    if not lastUpdateTime[component] or (currentTime - lastUpdateTime[component]) >= DEBOUNCE_TIME then
        lastUpdateTime[component] = currentTime
        callback()
    end
end

local function handleError(component, error, retryCallback)
    retryAttempts[component] = (retryAttempts[component] or 0) + 1
    
    if retryAttempts[component] <= MAX_RETRY_ATTEMPTS then
        -- Report error
        ClientEventBridge:dispatchEvent("ReportUIError", {
            component = component,
            error = error
        })
        
        -- Attempt recovery
        task.delay(1, function()
            retryCallback()
        end)
    else
        -- Max retries reached, show error UI
        ClientEventBridge:dispatchEvent("ShowErrorUI", {
            message = "Failed to load " .. component .. ". Please try again later.",
            retryCallback = retryCallback
        })
    end
end

-- Initialize UI system
local function initialize()
    -- Create UI system instance
    local uiSystem = UISystem.new()
    
    -- Create and register components with error handling
    local function createComponent(ComponentClass, name)
        local success, component = pcall(function()
            return ComponentClass.new()
        end)
        
        if success then
            uiSystem:registerComponent(component)
            return component
        else
            handleError(name, "Failed to create " .. name, function()
                return createComponent(ComponentClass, name)
            end)
            return nil
        end
    end
    
    -- Create components
    local mainMenu = createComponent(MainMenu, "MainMenu")
    local sideMenu = createComponent(SideMenu, "SideMenu")
    local achievements = createComponent(Achievements, "Achievements")
    local communityGoals = createComponent(CommunityGoals, "CommunityGoals")
    local settings = createComponent(Settings, "Settings")
    local tutorial = createComponent(Tutorial, "Tutorial")
    
    -- Show main menu with fade animation
    uiSystem:showComponent(Constants.COMPONENTS.MAIN_MENU, ANIMATION_PRESETS.FADE_IN)
    
    -- Show side menu with slide animation
    uiSystem:showComponent(Constants.COMPONENTS.SIDE_MENU, ANIMATION_PRESETS.SLIDE_IN_LEFT)
    
    -- Set up event handlers with debouncing
    ClientEventBridge:connectEvent("ShowUI", function(data)
        if data.component then
            debounce(data.component, function()
                local animation = data.animation or ANIMATION_PRESETS.FADE_IN
                uiSystem:showComponent(data.component, animation)
            end)
        end
    end)
    
    ClientEventBridge:connectEvent("HideUI", function(data)
        if data.component then
            debounce(data.component, function()
                local animation = data.animation or ANIMATION_PRESETS.FADE_OUT
                uiSystem:hideComponent(data.component, animation)
            end)
        end
    end)
    
    -- Handle menu actions with enhanced animations and error handling
    ClientEventBridge:connectEvent("MenuAction", function(data)
        if data.action then
            debounce(data.action, function()
                local component = nil
                local animation = nil
                
                if data.action == "achievements" then
                    component = Constants.COMPONENTS.ACHIEVEMENTS
                    animation = ANIMATION_PRESETS.BOUNCE_IN
                elseif data.action == "community_goals" then
                    component = Constants.COMPONENTS.COMMUNITY_GOALS
                    animation = ANIMATION_PRESETS.BOUNCE_IN
                elseif data.action == "settings" then
                    component = Constants.COMPONENTS.SETTINGS
                    animation = ANIMATION_PRESETS.SCALE_IN
                elseif data.action == "tutorial" then
                    component = Constants.COMPONENTS.TUTORIAL
                    animation = ANIMATION_PRESETS.SCALE_IN
                end
                
                if component then
                    uiSystem:showComponent(component, animation)
                end
            end)
        end
    end)
    
    -- Enhanced achievement updates with animations and error handling
    ClientEventBridge:connectEvent("AchievementUnlocked", function(data)
        if data.achievement then
            debounce("achievement", function()
                -- Show achievement notification with custom animation
                ClientEventBridge:dispatchEvent("ShowNotification", {
                    type = "achievement",
                    title = "Achievement Unlocked!",
                    message = data.achievement.name,
                    duration = 5,
                    animation = ANIMATION_PRESETS.BOUNCE_IN
                })
                
                -- Update achievements UI if visible
                if uiSystem:isComponentVisible(Constants.COMPONENTS.ACHIEVEMENTS) then
                    ClientEventBridge:dispatchEvent("AchievementsUpdated", data)
                end
            end)
        end
    end)
    
    -- Enhanced community goal updates with error handling
    ClientEventBridge:connectEvent("CommunityGoalUpdated", function(data)
        if data.goal then
            debounce("community_goal", function()
                -- Show goal notification with custom animation
                ClientEventBridge:dispatchEvent("ShowNotification", {
                    type = "community_goal",
                    title = "Community Goal Updated",
                    message = data.goal.name,
                    duration = 5,
                    animation = ANIMATION_PRESETS.SLIDE_IN_LEFT
                })
                
                -- Update community goals UI if visible
                if uiSystem:isComponentVisible(Constants.COMPONENTS.COMMUNITY_GOALS) then
                    ClientEventBridge:dispatchEvent("CommunityGoalsUpdated", data)
                end
            end)
        end
    end)
    
    -- Enhanced rebirth updates with error handling
    ClientEventBridge:connectEvent("RebirthCompleted", function(data)
        if data.rebirth then
            debounce("rebirth", function()
                -- Show rebirth notification with custom animation
                ClientEventBridge:dispatchEvent("ShowNotification", {
                    type = "rebirth",
                    title = "Rebirth Complete!",
                    message = "You've reached rebirth level " .. data.rebirth.level,
                    duration = 5,
                    animation = ANIMATION_PRESETS.BOUNCE_IN
                })
                
                -- Play rebirth effect
                ClientEventBridge:dispatchEvent("PlayEffect", {
                    type = "rebirth",
                    duration = 2
                })
            end)
        end
    end)
    
    -- Enhanced tutorial updates with error handling
    ClientEventBridge:connectEvent("TutorialStepCompleted", function(data)
        if data.step then
            debounce("tutorial", function()
                -- Show tutorial notification with custom animation
                ClientEventBridge:dispatchEvent("ShowNotification", {
                    type = "tutorial",
                    title = "Tutorial Progress",
                    message = data.step.description,
                    duration = 5,
                    animation = ANIMATION_PRESETS.FADE_IN
                })
                
                -- Update tutorial UI if visible
                if uiSystem:isComponentVisible(Constants.COMPONENTS.TUTORIAL) then
                    ClientEventBridge:dispatchEvent("TutorialUpdated", data)
                end
            end)
        end
    end)
    
    -- Enhanced settings updates with error handling
    ClientEventBridge:connectEvent("SettingsUpdated", function(data)
        if data.settings then
            debounce("settings", function()
                -- Update settings UI if visible
                if uiSystem:isComponentVisible(Constants.COMPONENTS.SETTINGS) then
                    ClientEventBridge:dispatchEvent("SettingsUpdated", data)
                end
            end)
        end
    end)
    
    -- New event handlers for UI interactions with error handling
    ClientEventBridge:connectEvent("UIHover", function(data)
        if data.component then
            debounce("hover_" .. data.component, function()
                local component = uiSystem:getComponent(data.component)
                if component then
                    pcall(function()
                        component:handleHover(data)
                    end)
                end
            end)
        end
    end)
    
    ClientEventBridge:connectEvent("UIClick", function(data)
        if data.component then
            debounce("click_" .. data.component, function()
                local component = uiSystem:getComponent(data.component)
                if component then
                    pcall(function()
                        component:handleClick(data)
                    end)
                end
            end)
        end
    end)
    
    -- New event handler for UI transitions with error handling
    ClientEventBridge:connectEvent("TransitionUI", function(data)
        if data.from and data.to then
            debounce("transition", function()
                -- Hide current UI
                uiSystem:hideComponent(data.from, ANIMATION_PRESETS.FADE_OUT)
                
                -- Show new UI after delay
                task.delay(0.3, function()
                    uiSystem:showComponent(data.to, ANIMATION_PRESETS.FADE_IN)
                end)
            end)
        end
    end)
    
    -- Performance monitoring
    RunService.Heartbeat:Connect(function()
        -- Monitor UI performance
        for component, lastUpdate in pairs(lastUpdateTime) do
            if os.clock() - lastUpdate > 5 then
                -- Component hasn't been updated in 5 seconds, clean up
                lastUpdateTime[component] = nil
                isUpdating[component] = nil
            end
        end
    end)
    
    -- Store UI system in registry
    ClientRegistry:registerSystem("UISystem", uiSystem)
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
    initialize = initialize,
    ANIMATION_PRESETS = ANIMATION_PRESETS
} 