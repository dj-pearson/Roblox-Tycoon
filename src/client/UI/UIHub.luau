--!strict
--[[
    UIHub.luau
    
    Central navigation controller for the UI system. Manages transitions between
    screens, maintains screen history, and coordinates UI flows.
    
    Features:
    - Screen transition management
    - History tracking for navigation
    - Screen preloading
    - Animation coordination 
    - State preservation between screens
    
    Author: Updated April 26, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Safe require utility
local function requireSafely(moduleScript)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        warn("Invalid module script provided to requireSafely")
        return nil
    end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if not success then
        warn("Failed to load module: " .. moduleScript.Name .. " - " .. tostring(result))
        return nil
    end
    
    return result
end

-- Find paths to important folders
local srcFolder = ReplicatedStorage:FindFirstChild("src") 
if not srcFolder then
    error("Source folder not found")
    return
end

local clientFolder = srcFolder:FindFirstChild("client")
local clientUIFolder = clientFolder and clientFolder:FindFirstChild("UI")
local uiCoreFolder = clientUIFolder and clientUIFolder:FindFirstChild("Core")

-- Required modules
local UIRegistry = requireSafely(uiCoreFolder and uiCoreFolder:FindFirstChild("UIRegistry"))
local UIManager = requireSafely(uiCoreFolder and uiCoreFolder:FindFirstChild("UIManager"))

-- Module and state variables
local UIHub = {}
local screens = {}
local screenHistory = {}
local currentScreen = nil
local transitionInProgress = false
local defaultTransition = "fade" -- "fade", "slide", "scale"
local defaultTransitionDuration = 0.3

-- Screen configuration presets
local SCREEN_PRESETS = {
    MainMenu = {
        name = "MainMenu",
        transition = "fade",
        transitionDuration = 0.5,
        exclusive = true, -- Hides all other screens when shown
        modal = false, -- Whether it's a modal screen that can be closed with Escape
        cacheable = true -- Whether the screen should be cached after hiding
    },
    Settings = {
        name = "Settings",
        transition = "scale",
        transitionDuration = 0.3,
        exclusive = false,
        modal = true,
        cacheable = true
    },
    Stats = {
        name = "Stats",
        transition = "slide",
        transitionDuration = 0.3,
        exclusive = false,
        modal = false,
        cacheable = true
    },
    Rebirth = {
        name = "Rebirth",
        transition = "fade",
        transitionDuration = 0.5,
        exclusive = true,
        modal = false,
        cacheable = false
    },
    Equipment = {
        name = "Equipment",
        transition = "slide",
        transitionDuration = 0.3,
        exclusive = false,
        modal = true,
        cacheable = true
    }
}

--[[ Private Helper Functions ]]--

-- Get screen configuration
local function getScreenConfig(screenName)
    return SCREEN_PRESETS[screenName] or {
        name = screenName,
        transition = defaultTransition,
        transitionDuration = defaultTransitionDuration,
        exclusive = false,
        modal = false,
        cacheable = true
    }
end

-- Set current screen
local function setCurrentScreen(screenName)
    currentScreen = screenName
    
    -- Add to history if not already the last item
    if #screenHistory == 0 or screenHistory[#screenHistory] ~= screenName then
        table.insert(screenHistory, screenName)
        
        -- Trim history if it gets too long
        if #screenHistory > 10 then
            table.remove(screenHistory, 1)
        end
    end
end

-- Hide all screens except exclusions
local function hideAllScreens(except)
    local exceptions = except or {}
    
    for name, _ in pairs(screens) do
        if not table.find(exceptions, name) then
            local screen = UIRegistry:getComponent(name)
            if screen and screen.hide then
                screen:hide()
            end
        end
    end
end

-- Show a screen with transition
local function showScreenWithTransition(screenName, transitionType, duration, ...)
    local screen = UIRegistry:getComponent(screenName)
    if not screen or not screen.show then
        warn("Screen not found or missing show method: " .. screenName)
        transitionInProgress = false
        return false
    end
    
    -- Get screen configuration
    local config = getScreenConfig(screenName)
    
    -- Hide other screens if this is exclusive
    if config.exclusive then
        hideAllScreens({screenName})
    end
    
    -- Determine transition method
    transitionType = transitionType or config.transition
    duration = duration or config.transitionDuration
    
    local transitionMethod
    if transitionType == "fade" then
        transitionMethod = UIManager.fadeIn
    elseif transitionType == "slide" then
        transitionMethod = function(instance, duration, callback)
            UIManager:slideIn(instance, "right", duration, callback)
        end
    elseif transitionType == "scale" then
        transitionMethod = UIManager.scaleIn
    else
        transitionMethod = UIManager.fadeIn
    end
    
    -- Mark this screen as shown
    screens[screenName] = true
    
    -- Show the screen with transition
    screen:show(...)
    
    if screen.instance and transitionMethod then
        transitionMethod(UIManager, screen.instance, duration, function()
            -- Update current screen and history
            setCurrentScreen(screenName)
            transitionInProgress = false
        end)
    else
        -- No instance to animate or no transition method, just update current screen
        setCurrentScreen(screenName)
        transitionInProgress = false
    end
    
    return true
end

-- Hide a screen with transition
local function hideScreenWithTransition(screenName, transitionType, duration, callback)
    local screen = UIRegistry:getComponent(screenName)
    if not screen or not screen.hide then
        warn("Screen not found or missing hide method: " .. screenName)
        transitionInProgress = false
        if callback then callback() end
        return false
    end
    
    -- Get screen configuration
    local config = getScreenConfig(screenName)
    
    -- Determine transition method
    transitionType = transitionType or config.transition
    duration = duration or config.transitionDuration
    
    local transitionMethod
    if transitionType == "fade" then
        transitionMethod = UIManager.fadeOut
    elseif transitionType == "slide" then
        transitionMethod = function(instance, duration, callback)
            UIManager:slideOut(instance, "right", duration, callback)
        end
    elseif transitionType == "scale" then
        transitionMethod = UIManager.scaleOut
    else
        transitionMethod = UIManager.fadeOut
    end
    
    -- Hide with transition if possible
    if screen.instance and transitionMethod then
        transitionMethod(UIManager, screen.instance, duration, function()
            -- Actually hide the UI
            screen:hide()
            
            -- Mark as hidden
            screens[screenName] = nil
            
            -- Execute callback
            if callback then callback() end
            
            transitionInProgress = false
        end)
    else
        -- No instance to animate or no transition method, just hide
        screen:hide()
        
        -- Mark as hidden
        screens[screenName] = nil
        
        -- Execute callback
        if callback then callback() end
        
        transitionInProgress = false
    end
    
    return true
end

-- Register screen event handlers
local function registerScreenEvents()
    -- Set up escape key handling for modal screens
    local UserInputService = game:GetService("UserInputService")
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Escape then
            -- Check if current screen is modal
            if currentScreen then
                local config = getScreenConfig(currentScreen)
                if config.modal then
                    UIHub:goBack()
                end
            end
        end
    end)
    
    -- Set up window size change handling
    UserInputService.WindowFocused:Connect(function()
        -- Refresh current screen when window is focused
        if currentScreen then
            local screen = UIRegistry:getComponent(currentScreen)
            if screen and screen.refresh then
                screen:refresh()
            end
        end
    end)
    
    UserInputService.WindowSizeChanged:Connect(function()
        -- Refresh all visible screens when window size changes
        for name, visible in pairs(screens) do
            if visible then
                local screen = UIRegistry:getComponent(name)
                if screen and screen.refresh then
                    screen:refresh()
                end
            end
        end
    end)
end

--[[ Public API Functions ]]--

-- Register a screen
function UIHub:registerScreen(name, screen, config)
    if not name or not screen then
        warn("Cannot register screen without name or component")
        return false
    end
    
    -- Register with UIRegistry if available
    if UIRegistry and UIRegistry.registerComponent then
        UIRegistry:registerComponent(name, screen)
    end
    
    -- Store custom configuration if provided
    if config then
        SCREEN_PRESETS[name] = config
        SCREEN_PRESETS[name].name = name -- Ensure name is set correctly
    end
    
    return true
end

-- Show a screen
function UIHub:showScreen(screenName, ...)
    if not screenName then
        warn("Cannot show screen without name")
        return false
    end
    
    if transitionInProgress then
        warn("Cannot show screen while transition is in progress")
        return false
    end
    
    transitionInProgress = true
    
    return showScreenWithTransition(screenName, nil, nil, ...)
end

-- Hide a screen
function UIHub:hideScreen(screenName)
    if not screenName then
        warn("Cannot hide screen without name")
        return false
    end
    
    if transitionInProgress then
        warn("Cannot hide screen while transition is in progress")
        return false
    end
    
    transitionInProgress = true
    
    return hideScreenWithTransition(screenName)
end

-- Toggle a screen
function UIHub:toggleScreen(screenName, ...)
    if screens[screenName] then
        return self:hideScreen(screenName)
    else
        return self:showScreen(screenName, ...)
    end
end

-- Check if a screen is visible
function UIHub:isScreenVisible(screenName)
    return screens[screenName] == true
end

-- Get the current screen name
function UIHub:getCurrentScreen()
    return currentScreen
end

-- Navigate to previous screen
function UIHub:goBack()
    if #screenHistory <= 1 then
        -- No history to go back to
        return false
    end
    
    -- Remove current screen from history
    table.remove(screenHistory)
    
    -- Get previous screen
    local previousScreen = screenHistory[#screenHistory]
    
    -- Hide current screen
    self:hideScreen(currentScreen)
    
    -- Show previous screen
    self:showScreen(previousScreen)
    
    return true
end

-- Show multiple screens in sequence (e.g., for tutorials or onboarding)
function UIHub:showScreenSequence(screenNames, delay, callback)
    if not screenNames or #screenNames == 0 then
        if callback then callback() end
        return false
    end
    
    delay = delay or 0.5
    
    local function showNextScreen(index)
        if index > #screenNames then
            if callback then callback() end
            return
        end
        
        self:showScreen(screenNames[index], function()
            task.delay(delay, function()
                showNextScreen(index + 1)
            end)
        end)
    end
    
    showNextScreen(1)
    return true
end

-- Preload screens
function UIHub:preloadScreens(screenNames)
    if not screenNames or #screenNames == 0 then
        return false
    end
    
    local loaded = {}
    
    for _, name in ipairs(screenNames) do
        local screen = UIRegistry:getComponent(name)
        if screen and screen.preload then
            local success = screen:preload()
            if success then
                table.insert(loaded, name)
            end
        end
    end
    
    return #loaded > 0, loaded
end

-- Reset the history
function UIHub:resetHistory()
    screenHistory = {}
    if currentScreen then
        table.insert(screenHistory, currentScreen)
    end
    return true
end

-- Get screen transition status
function UIHub:isTransitioning()
    return transitionInProgress
end

-- Set default transition
function UIHub:setDefaultTransition(transition, duration)
    defaultTransition = transition or "fade"
    defaultTransitionDuration = duration or 0.3
    return true
end

-- Hide all screens
function UIHub:hideAllScreens()
    hideAllScreens()
    currentScreen = nil
    screenHistory = {}
    return true
end

-- Initialize the hub
function UIHub:initialize()
    -- Register with UIRegistry if available
    if UIRegistry and UIRegistry.registerComponent then
        UIRegistry:registerComponent("UIHub", self, "1.0.0")
        
        -- Register dependencies
        UIRegistry:registerDependency("UIHub", "UIManager", "1.0.0")
    end
    
    -- Register screen event handlers
    registerScreenEvents()
    
    return true
end

-- Return the module
return UIHub
