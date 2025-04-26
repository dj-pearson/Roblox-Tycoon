--!strict
--[[
    UIHub.luau
    
    Central navigation system for UI elements. Manages screen history,
    transitions between screens, and keyboard shortcuts.
    
    Features:
    - Screen history tracking
    - Back navigation
    - Keyboard shortcuts
    - Smooth transitions
    - Screen preloading
    
    Author: Updated April 26, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local LocalPlayer = Players.LocalPlayer

-- Safe require utility
local function requireSafely(moduleScript)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
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

local sharedFolder = srcFolder:FindFirstChild("shared")
if not sharedFolder then
    error("Shared folder not found")
    return
end

local clientFolder = srcFolder:FindFirstChild("client")
local clientUIFolder = clientFolder and clientFolder:FindFirstChild("UI")
local clientCoreFolder = clientFolder and clientFolder:FindFirstChild("Core")
local uiCoreFolder = clientUIFolder and clientUIFolder:FindFirstChild("Core")

-- Required modules
local UIManager = requireSafely(uiCoreFolder and uiCoreFolder:FindFirstChild("UIManager"))
local UIRegistry = requireSafely(uiCoreFolder and uiCoreFolder:FindFirstChild("UIRegistry"))
local ClientRegistry = requireSafely(clientCoreFolder and clientCoreFolder:FindFirstChild("ClientRegistry"))

-- Module and state variables
local UIHub = {}
local screenHistory = {}
local currentScreen = nil
local MAX_HISTORY = 20 -- Maximum number of screens to keep in history
local preloadedScreens = {}
local screenShortcuts = {}
local isTransitioning = false

-- Configuration
local CONFIG = {
    defaultScreen = "MainMenuUI",
    transitionTime = 0.3, -- Seconds
    preloadEnabled = true,
    shortcutsEnabled = true
}

--[[ Private Functions ]]--

-- Handle back navigation
local function handleBackNavigation()
    if #screenHistory == 0 or isTransitioning then
        return
    end
    
    isTransitioning = true
    
    local previousScreen = table.remove(screenHistory)
    
    -- Close current screen
    if currentScreen and UIManager then
        UIManager:hideUI(currentScreen)
    end
    
    -- Open previous screen
    if UIManager then
        UIManager:showUI(previousScreen)
    end
    
    currentScreen = previousScreen
    isTransitioning = false
end

-- Handle keyboard shortcuts
local function handleKeyboardShortcuts(input, gameProcessed)
    if gameProcessed or not CONFIG.shortcutsEnabled then
        return
    end
    
    -- ESC key for back navigation
    if input.KeyCode == Enum.KeyCode.Escape then
        if #screenHistory > 0 then
            handleBackNavigation()
            return
        end
    end
    
    -- Check registered shortcuts
    for screen, shortcut in pairs(screenShortcuts) do
        if input.KeyCode == shortcut then
            UIHub:navigateTo(screen)
            return
        end
    end
end

-- Preload a screen
local function preloadScreen(screenName)
    if not CONFIG.preloadEnabled or preloadedScreens[screenName] then
        return
    end
    
    if UIRegistry then
        local screen = UIRegistry:getComponent(screenName)
        if screen and typeof(screen) == "table" and screen.initialize then
            screen:initialize()
            preloadedScreens[screenName] = true
        end
    end
end

-- Set up default keyboard shortcuts
local function setupDefaultShortcuts()
    -- M for Main Menu
    screenShortcuts["MainMenuUI"] = Enum.KeyCode.M
    
    -- S for Settings
    screenShortcuts["SettingsUI"] = Enum.KeyCode.S
    
    -- Register input handler
    UserInputService.InputBegan:Connect(handleKeyboardShortcuts)
    
    -- Mobile back button for Android
    ContextActionService:BindAction("UIHub_BackAction", function(_, state, _)
        if state == Enum.UserInputState.Begin then
            handleBackNavigation()
        end
    end, false, Enum.KeyCode.ButtonB) -- Android back button
end

--[[ Public API Functions ]]--

-- Initialize the UIHub
function UIHub:initialize()
    -- Register with UIRegistry if available
    if UIRegistry and UIRegistry.registerComponent then
        UIRegistry:registerComponent("UIHub", self)
    end
    
    -- Set up shortcuts
    setupDefaultShortcuts()
    
    -- Preload common screens
    if CONFIG.preloadEnabled then
        task.spawn(function()
            preloadScreen("MainMenuUI")
            preloadScreen("SettingsUI")
        end)
    end
    
    return self
end

-- Navigate to a screen
function UIHub:navigateTo(screenName, keepInHistory)
    if not screenName or isTransitioning then
        return false
    end
    
    isTransitioning = true
    
    -- Add current screen to history if it exists and if we want to keep history
    if currentScreen and keepInHistory ~= false then
        table.insert(screenHistory, currentScreen)
        
        -- Trim history if it gets too long
        if #screenHistory > MAX_HISTORY then
            table.remove(screenHistory, 1)
        end
    end
    
    -- Hide current screen
    if currentScreen and UIManager then
        UIManager:hideUI(currentScreen)
    end
    
    -- Show new screen
    if UIManager then
        local success = UIManager:showUI(screenName)
        if not success then
            warn("Failed to navigate to screen:", screenName)
            isTransitioning = false
            return false
        end
    else
        isTransitioning = false
        return false
    end
    
    currentScreen = screenName
    isTransitioning = false
    
    -- Preload related screens
    if CONFIG.preloadEnabled then
        task.spawn(function()
            -- Preload screens commonly accessed after this one
            -- This would be customized based on your navigation patterns
            if screenName == "MainMenuUI" then
                preloadScreen("SettingsUI")
                preloadScreen("StatsGui")
            elseif screenName == "RebirthUI" then
                preloadScreen("MainMenuUI")
            end
        end)
    end
    
    return true
end

-- Go back to previous screen
function UIHub:goBack()
    handleBackNavigation()
    return #screenHistory > 0 -- Return whether there's still history
end

-- Clear screen history
function UIHub:clearHistory()
    screenHistory = {}
end

-- Get current screen
function UIHub:getCurrentScreen()
    return currentScreen
end

-- Get screen history
function UIHub:getScreenHistory()
    return table.clone(screenHistory)
end

-- Register a keyboard shortcut for a screen
function UIHub:registerShortcut(screenName, keyCode)
    if typeof(keyCode) == "EnumItem" and keyCode.EnumType == Enum.KeyCode then
        screenShortcuts[screenName] = keyCode
        return true
    end
    return false
end

-- Remove a keyboard shortcut
function UIHub:removeShortcut(screenName)
    if screenShortcuts[screenName] then
        screenShortcuts[screenName] = nil
        return true
    end
    return false
end

-- Enable/disable shortcuts
function UIHub:setShortcutsEnabled(enabled)
    CONFIG.shortcutsEnabled = enabled and true or false
end

-- Enable/disable preloading
function UIHub:setPreloadEnabled(enabled)
    CONFIG.preloadEnabled = enabled and true or false
end

-- Show default screen
function UIHub:showDefaultScreen()
    return self:navigateTo(CONFIG.defaultScreen, false)
end

-- Set default screen
function UIHub:setDefaultScreen(screenName)
    CONFIG.defaultScreen = screenName
end

-- Check if a screen is in history
function UIHub:isInHistory(screenName)
    for _, name in ipairs(screenHistory) do
        if name == screenName then
            return true
        end
    end
    return false
end

-- Navigate to a screen and clear history
function UIHub:navigateToAndClear(screenName)
    screenHistory = {}
    return self:navigateTo(screenName, false)
end

-- Initialize on module load
UIHub:initialize()

-- Return the module
return UIHub
