--!strict
--[[
    UISystemEnhancer.client.luau
    
    Enhanced UI system with fallback mechanisms and improved error handling.
    Provides a robust way to show/hide UI components with multiple fallback paths.
    
    Created: April 30, 2025
    Updated: May 3, 2025 - Fixed fallback menu issues and added proper cleanup
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Import required modules
local Systems = require(ReplicatedStorage:WaitForChild("Systems"))
local getSystem = Systems.getSystem

-- Configuration
local CONFIG = {
    MAX_RETRIES = 3,
    RETRY_DELAY = 1,
    MAX_INIT_ATTEMPTS = 3,
    UI_TRANSITION_DURATION = 0.3,
    ERROR_DISPLAY_DURATION = 5,
    HEALTH_CHECK_INTERVAL = 30,
    MAX_ERROR_COUNT = 5,
    ERROR_RESET_TIME = 300, -- 5 minutes
    FALLBACK_CLEANUP_DELAY = 10, -- 10 seconds before auto-cleaning fallback UIs
    TRANSITION_TYPES = {
        FADE = "fade",
        SLIDE = "slide",
        SCALE = "scale",
        ROTATE = "rotate",
        BOUNCE = "bounce",
        ELASTIC = "elastic",
        SPRING = "spring",
        COMBINED = "combined"
    },
    DEFAULT_TRANSITION = {
        duration = 0.3,
        easing = Enum.EasingStyle.Quad,
        direction = Enum.EasingDirection.Out,
        repeatCount = 0,
        reverses = false,
        delayTime = 0
    }
}

-- State tracking
local state = {
    initialized = false,
    initializationAttempts = 0,
    isInitializing = false,
    loadedComponents = {},
    fallbackUIs = {},
    errorCount = 0,
    lastErrorTime = 0,
    originalMethods = {}
}

-- Helper function to log messages
local function log(message, level)
    level = level or "Info"
    local prefix = "[UISystemEnhancer] "
    
    if level == "Info" then
        print(prefix .. message)
    elseif level == "Warning" then
        warn(prefix .. message)
    elseif level == "Error" then
        error(prefix .. message)
    else
        print(prefix .. "[" .. level .. "] " .. message)
    end
end

-- Clean up fallback UI
local function cleanupFallbackUI(uiName)
    if not state.fallbackUIs[uiName] then
        return
    end
    
    local fallbackUI = state.fallbackUIs[uiName]
    if fallbackUI and fallbackUI:isVisible() then
        log("Cleaning up fallback UI: " .. uiName)
        fallbackUI:hide()
        state.fallbackUIs[uiName] = nil
    end
end

-- Clean up all fallback UIs
local function cleanupAllFallbackUIs()
    for uiName, _ in pairs(state.fallbackUIs) do
        cleanupFallbackUI(uiName)
    end
end

-- Create fallback UI
local function createFallbackUI(uiName)
    if state.fallbackUIs[uiName] then
        cleanupFallbackUI(uiName)
    end
    
    local fallbackUI = Instance.new("ScreenGui")
    fallbackUI.Name = uiName .. "Fallback"
    fallbackUI.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0.4, 0, 0.3, 0)
    frame.Position = UDim2.new(0.3, 0, 0.35, 0)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.Parent = fallbackUI
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0.2, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    title.BorderSizePixel = 0
    title.Text = "UI System Error"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, 0, 0.4, 0)
    message.Position = UDim2.new(0, 0, 0.2, 0)
    message.BackgroundTransparency = 1
    message.Text = "Failed to load " .. uiName .. "\nAttempting to recover..."
    message.TextColor3 = Color3.fromRGB(255, 255, 255)
    message.TextSize = 14
    message.Font = Enum.Font.Gotham
    message.TextWrapped = true
    message.Parent = frame
    
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.4, 0, 0.2, 0)
    closeButton.Position = UDim2.new(0.3, 0, 0.7, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "Close"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 14
    closeButton.Font = Enum.Font.Gotham
    closeButton.Parent = frame
    
    -- Set up close button functionality
    closeButton.MouseButton1Click:Connect(function()
        cleanupFallbackUI(uiName)
    end)
    
    -- Auto-cleanup after delay
    task.delay(CONFIG.FALLBACK_CLEANUP_DELAY, function()
        cleanupFallbackUI(uiName)
    end)
    
    state.fallbackUIs[uiName] = {
        gui = fallbackUI,
        show = function()
            fallbackUI.Parent = playerGui
        end,
        hide = function()
            fallbackUI.Parent = nil
        end,
        isVisible = function()
            return fallbackUI.Parent ~= nil
        end
    }
    
    return state.fallbackUIs[uiName]
end

-- Show UI with fallback
local function showUI(name: string, ...: any): boolean
    log("Attempting to show UI: " .. name)
    
    -- First try: Use UISystem
    local uiSystem = getSystem("UISystem")
    if uiSystem and uiSystem.showUI then
        local success, result = pcall(function()
            return uiSystem:showUI(name, ...)
        end)
        
        if success and result then
            log("Successfully showed UI via UISystem: " .. name)
            return true
        end
    end
    
    -- Second try: Direct component access
    local component = state.loadedComponents[name]
    if component and component.show then
        local success, result = pcall(function()
            return component:show(...)
        end)
        
        if success and result then
            log("Successfully showed UI via direct component access: " .. name)
            return true
        end
    end
    
    -- Create fallback UI as last resort
    log("All attempts to show UI failed: " .. name .. ", creating fallback", "Warning")
    local fallbackUI = createFallbackUI(name)
    if fallbackUI then
        fallbackUI:show()
    end
    
    return false
end

-- Hide UI
local function hideUI(name: string): boolean
    log("Attempting to hide UI: " .. name)
    
    -- First try: Use UISystem
    local uiSystem = getSystem("UISystem")
    if uiSystem and uiSystem.hideUI then
        local success, result = pcall(function()
            return uiSystem:hideUI(name)
        end)
        
        if success and result then
            log("Successfully hid UI via UISystem: " .. name)
            return true
        end
    end
    
    -- Second try: Direct component access
    local component = state.loadedComponents[name]
    if component and component.hide then
        local success, result = pcall(function()
            return component:hide()
        end)
        
        if success and result then
            log("Successfully hid UI via direct component access: " .. name)
            return true
        end
    end
    
    -- Clean up fallback UI if it exists
    cleanupFallbackUI(name)
    
    return false
end

-- Preload UI components
local function preloadComponents()
    -- Implementation for preloading components
    log("Preloading UI components")
    -- Add your component preloading logic here
end

-- Patch UISystem with enhanced functionality
local function patchUISystem()
    -- Implementation for patching UISystem
    log("Patching UISystem with enhanced functionality")
    -- Add your UISystem patching logic here
end

-- Initialize UI system
local function initialize()
    if state.isInitializing then
        log("Initialization already in progress", "Warning")
        return
    end
    
    state.isInitializing = true
    state.initializationAttempts += 1
    
    log("Initializing UISystemEnhancer (Attempt " .. state.initializationAttempts .. ")")
    
    -- Clean up any existing fallback UIs first
    cleanupAllFallbackUIs()
    
    -- Preload components
    preloadComponents()
    
    -- Patch UISystem
    patchUISystem()
    
    -- Attempt to show main menu after a delay
    task.delay(1, function()
        local retryCount = 0
        local MAX_RETRIES = CONFIG.MAX_RETRIES
        local RETRY_DELAY = CONFIG.RETRY_DELAY
        
        local function tryShowMainMenu()
            -- Check if any fallback UIs are visible
            for uiName, fallbackUI in pairs(state.fallbackUIs) do
                if fallbackUI:isVisible() then
                    log("Found visible fallback UI: " .. uiName .. ", cleaning up")
                    cleanupFallbackUI(uiName)
                end
            end
            
            if showUI("MainMenuUI") then
                log("Successfully showed MainMenuUI")
                state.isInitializing = false
                state.initialized = true
                return
            end
            
            retryCount = retryCount + 1
            if retryCount < MAX_RETRIES then
                log("Retry " .. retryCount .. " of " .. MAX_RETRIES .. " to show MainMenuUI")
                task.delay(RETRY_DELAY, tryShowMainMenu)
            else
                log("Failed to show MainMenuUI after " .. MAX_RETRIES .. " attempts", "Warning")
                -- Create fallback UI as last resort
                local fallbackUI = createFallbackUI("MainMenuUI")
                if fallbackUI then
                    fallbackUI:show()
                end
                state.isInitializing = false
            end
        end
        
        tryShowMainMenu()
    end)
end

-- Run initialization
initialize()

-- Return the module API
return {
    showUI = showUI,
    hideUI = hideUI,
    cleanupFallbackUI = cleanupFallbackUI,
    cleanupAllFallbackUIs = cleanupAllFallbackUIs
}
