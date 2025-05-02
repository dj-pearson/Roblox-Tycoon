--[[
    UIRegistry.luau
    
    A registry system for UI components and screens.
    Manages component registration, opening/closing screens, and UI state.
    
    Created: May 1, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    DEBUG = true,
    SCREEN_FADE_TIME = 0.3,
    MAX_SCREENS = 5,
    ALLOW_MULTIPLE_SCREENS = false
}

-- Make sure we're on the client
if not RunService:IsClient() then
    warn("[UIRegistry] UIRegistry should only be used on the client")
    return {
        RegisterComponent = function() return false end,
        OpenScreen = function() return false end,
        CloseScreen = function() return false end
    }
end

-- Try to load dependencies
local SafeRequire = nil
local success, result = pcall(function()
    return require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("SafeRequire"))
end)

if success then
    SafeRequire = result
end

-- Registry data structures
local registeredComponents = {}
local activeScreens = {}
local screenHistory = {}

local UIRegistry = {}

-- Helper function for logging
local function log(message, level)
    if not CONFIG.DEBUG and level ~= "Error" then return end
    
    local prefix = "[UIRegistry]"
    if level == "Error" then
        warn(prefix, message)
    elseif level == "Success" then
        print(prefix, "✓", message)
    else
        print(prefix, message)
    end
end

-- Register a UI component
function UIRegistry.RegisterComponent(componentName, componentConstructor, options)
    if type(componentName) ~= "string" then
        log("Invalid component name", "Error")
        return false
    end
    
    if type(componentConstructor) ~= "function" then
        log("Invalid component constructor for " .. componentName, "Error")
        return false
    end
    
    options = options or {}
    
    registeredComponents[componentName] = {
        constructor = componentConstructor,
        isScreen = options.isScreen or false,
        allowMultiple = options.allowMultiple or false,
        priority = options.priority or 0,
        metadata = options.metadata or {}
    }
    
    log("Registered component: " .. componentName, "Success")
    return true
end

-- Get a registered component
function UIRegistry.GetComponent(componentName)
    local component = registeredComponents[componentName]
    if not component then
        log("Component not found: " .. componentName, "Error")
        return nil
    end
    
    return component.constructor
end

-- Open a UI screen
function UIRegistry.OpenScreen(screenName, props)
    local screen = registeredComponents[screenName]
    if not screen or not screen.isScreen then
        log("Screen not found: " .. screenName, "Error")
        return false
    end
    
    -- Close other screens if we don't allow multiple
    if not CONFIG.ALLOW_MULTIPLE_SCREENS and not screen.allowMultiple then
        for name, _ in pairs(activeScreens) do
            UIRegistry.CloseScreen(name)
        end
    end
    
    -- Check if screen is already open
    if activeScreens[screenName] then
        log("Screen already open: " .. screenName, "Info")
        return true
    end
    
    -- Check if we've reached the maximum number of screens
    if #activeScreens >= CONFIG.MAX_SCREENS then
        log("Maximum number of screens reached", "Error")
        return false
    end
    
    -- Create the screen
    local screenInstance = screen.constructor(props)
    if not screenInstance then
        log("Failed to create screen: " .. screenName, "Error")
        return false
    end
    
    -- Add to active screens
    activeScreens[screenName] = {
        instance = screenInstance,
        props = props,
        openedAt = os.time()
    }
    
    -- Add to screen history
    table.insert(screenHistory, {
        name = screenName,
        action = "open",
        timestamp = os.time()
    })
    
    log("Opened screen: " .. screenName, "Success")
    return true
end

-- Close a UI screen
function UIRegistry.CloseScreen(screenName)
    local screen = activeScreens[screenName]
    if not screen then
        log("Screen not open: " .. screenName, "Error")
        return false
    end
    
    -- Remove from active screens
    activeScreens[screenName] = nil
    
    -- Add to screen history
    table.insert(screenHistory, {
        name = screenName,
        action = "close",
        timestamp = os.time()
    })
    
    log("Closed screen: " .. screenName, "Success")
    return true
end

-- Get all active screens
function UIRegistry.GetActiveScreens()
    return activeScreens
end

-- Get screen history
function UIRegistry.GetScreenHistory()
    return screenHistory
end

-- Check if a screen is open
function UIRegistry.IsScreenOpen(screenName)
    return activeScreens[screenName] ~= nil
end

-- Register with ClientRegistry if available
if RunService:IsClient() then
    task.spawn(function()
        -- Try to get ClientRegistry
        local ClientRegistry = nil
        
        if SafeRequire then
            ClientRegistry = SafeRequire.requireFromPath("ClientRegistry")
        end
        
        if ClientRegistry then
            ClientRegistry:Register("UIRegistry", UIRegistry)
            log("Registered with ClientRegistry", "Success")
        end
    end)
end

return UIRegistry
