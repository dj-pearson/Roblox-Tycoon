--!strict
--[[
    UISystem.luau
    
    The main entry point for the UI system. This module is responsible for:
    - Initializing and managing the UI framework
    - Loading and registering UI components
    - Managing UI lifecycle
    - Providing a consistent API for UI operations
    
    Author: Updated May 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Module dependencies
local UIRegistry = require(script.Parent.UIRegistry)
local UIManager = require(script.Parent.UIManager)

-- Configuration
local CONFIG = {
    debugMode = true,
    autoInitialize = true,
    defaultScreen = "MainMenuUI",
    initializationTimeout = 10, -- seconds
    loadRetries = 3
}

-- State
local UISystem = {
    initialized = false,
    components = {},
    screens = {},
    activeScreen = nil
}

-- Logging
local function log(message, level)
    level = level or "Info"
    local prefix = "[UISystem] "
    
    if level == "Info" and CONFIG.debugMode then
        print(prefix .. message)
    elseif level == "Warning" then
        warn(prefix .. message)
    elseif level == "Error" then
        error(prefix .. message)
    end
end

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

-- Initialize the UI system
function UISystem:initialize()
    if self.initialized then
        log("UISystem already initialized", "Warning")
        return true
    end
    
    log("Initializing UI System...")
    
    -- Initialize core modules
    if not UIRegistry:initialize() then
        log("Failed to initialize UIRegistry", "Error")
        return false
    end
    
    if not UIManager:initialize() then
        log("Failed to initialize UIManager", "Error")
        return false
    end
    
    -- Load and register UI components
    self:loadUIComponents()
    
    -- Show default screen if configured
    if CONFIG.autoInitialize then
        task.spawn(function()
            task.wait(1) -- Wait for other systems to initialize
            self:showScreen(CONFIG.defaultScreen)
        end)
    end
    
    self.initialized = true
    log("UI System initialization complete")
    return true
end

-- Load UI components from the Components folder
function UISystem:loadUIComponents()
    local componentsFolder = script.Parent.Parent.Components
    if not componentsFolder then
        log("Components folder not found", "Warning")
        return
    end
    
    for _, module in ipairs(componentsFolder:GetChildren()) do
        if module:IsA("ModuleScript") then
            local component = requireSafely(module)
            if component then
                self.components[module.Name] = component
                UIRegistry:registerComponent(module.Name, component)
                log("Loaded component: " .. module.Name)
            end
        end
    end
end

-- Load UI screens from the Screens folder
function UISystem:loadUIScreens()
    local screensFolder = script.Parent.Parent.Screens
    if not screensFolder then
        log("Screens folder not found", "Warning")
        return
    end
    
    for _, module in ipairs(screensFolder:GetChildren()) do
        if module:IsA("ModuleScript") then
            local screen = requireSafely(module)
            if screen then
                self.screens[module.Name] = screen
                UIRegistry:registerComponent(module.Name, screen)
                log("Loaded screen: " .. module.Name)
            end
        end
    end
end

-- Show a UI screen
function UISystem:showScreen(screenName)
    if not self.initialized then
        log("Cannot show screen, UI System not initialized", "Warning")
        return false
    end
    
    -- Get the screen component
    local screen = self.screens[screenName]
    if not screen then
        log("Screen not found: " .. screenName, "Warning")
        return false
    end
    
    -- Hide current screen if any
    if self.activeScreen then
        self:hideScreen(self.activeScreen)
    end
    
    -- Show the new screen
    local success = UIManager:showUI(screenName, screen)
    if success then
        self.activeScreen = screenName
        log("Showing screen: " .. screenName)
    end
    
    return success
end

-- Hide a UI screen
function UISystem:hideScreen(screenName)
    if not self.initialized then
        return false
    end
    
    local success = UIManager:hideUI(screenName)
    if success and self.activeScreen == screenName then
        self.activeScreen = nil
        log("Hiding screen: " .. screenName)
    end
    
    return success
end

-- Get a UI component
function UISystem:getComponent(componentName)
    return UIRegistry:getComponent(componentName)
end

-- Get the current active screen
function UISystem:getActiveScreen()
    return self.activeScreen
end

-- Shutdown the UI system
function UISystem:shutdown()
    if not self.initialized then
        return true
    end
    
    log("Shutting down UI System...")
    
    -- Hide all screens
    for screenName, _ in pairs(self.screens) do
        self:hideScreen(screenName)
    end
    
    -- Shutdown core modules
    UIManager:shutdown()
    UIRegistry:shutdown()
    
    self.initialized = false
    log("UI System shutdown complete")
    return true
end

-- Auto-initialize on module load
task.spawn(function()
    task.wait(0.5) -- Give other systems time to load
    UISystem:initialize()
end)

return UISystem
