--!strict
--[[
    UISystem.luau
    
    The main entry point for the UI system. Initializes all UI components,
    manages their lifecycle, and provides access to the core UI services.
    
    Features:
    - Centralized UI initialization
    - Service locator for UI components
    - Integration with other game systems
    - Logging and error handling
    - Performance monitoring
    
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

local sharedFolder = srcFolder:FindFirstChild("shared")
if not sharedFolder then
    error("Shared folder not found")
    return
end

local clientFolder = srcFolder:FindFirstChild("client")
local clientUIFolder = clientFolder and clientFolder:FindFirstChild("UI")
local uiCoreFolder = clientUIFolder and clientUIFolder:FindFirstChild("Core")

-- Module and state variables
local UISystem = {}
local initialized = false
local startTime = os.clock()
local componentInitTimes = {}
local loadErrors = {}

-- Required core modules
local UIRegistry = requireSafely(uiCoreFolder and uiCoreFolder:FindFirstChild("UIRegistry"))
local UIManager = requireSafely(uiCoreFolder and uiCoreFolder:FindFirstChild("UIManager"))
local UIHub = requireSafely(clientUIFolder and clientUIFolder:FindFirstChild("UIHub"))
local ButtonFactory = requireSafely(sharedFolder and sharedFolder:FindFirstChild("ButtonFactory"))

-- Optional UI components that will be auto-discovered and loaded
local autoLoadComponents = true
local componentLoadOrder = {
    "MainMenu",
    "Settings",
    "Stats",
    "Rebirth",
    "Equipment",
    "Specialization"
}

-- Verify core dependencies
if not UIRegistry then
    error("Required core module UIRegistry not found")
    return
end

if not UIManager then
    error("Required core module UIManager not found")
    return
end

-- Configuration
local CONFIG = {
    debugMode = false,
    autoShowMainMenu = true,
    initializationTimeout = 10, -- seconds
    loadRetries = 3
}

--[[ Logging Functions ]]--

-- Log a message with level
local function logMessage(message, level)
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

-- Debug timing information
local function logTiming(component, startTime)
    local endTime = os.clock()
    local duration = endTime - startTime
    componentInitTimes[component] = duration
    
    if CONFIG.debugMode then
        logMessage(string.format("Initialized %s in %.2f ms", component, duration * 1000), "Info")
    end
end

--[[ Initialization Functions ]]--

-- Initialize the registry
local function initializeRegistry()
    local registryStart = os.clock()
    
    -- Register core components
    UIRegistry:registerComponent("UIManager", UIManager, "1.0.0")
    UIRegistry:registerComponent("ButtonFactory", ButtonFactory, "1.0.0")
    if UIHub then
        UIRegistry:registerComponent("UIHub", UIHub, "1.0.0")
    end
    
    -- Register dependencies
    if UIHub then
        UIRegistry:registerDependency("UIHub", "UIManager", "1.0.0")
    end
    
    -- Register self
    UIRegistry:registerComponent("UISystem", UISystem, "1.0.0")
    
    logTiming("UIRegistry", registryStart)
    return true
end

-- Auto-discover UI components
local function discoverComponents()
    if not autoLoadComponents then
        return {}
    end
    
    local discoveryStart = os.clock()
    local discovered = UIRegistry:discoverUIModules()
    
    logTiming("ComponentDiscovery", discoveryStart)
    return discovered
end

-- Initialize components in the specified order
local function initializeComponents()
    local initStart = os.clock()
    
    -- Initialize core components first
    if UIManager.initialize then
        UIManager:initialize()
    end
    
    if UIHub and UIHub.initialize then
        UIHub:initialize()
    end
    
    -- Explicitly load MainMenuUI to ensure it's available
    local clientFolder = srcFolder:FindFirstChild("client")
    if clientFolder then
        local uiFolder = clientFolder:FindFirstChild("UI")
        if uiFolder then
            local screensFolder = uiFolder:FindFirstChild("Screens")
            if screensFolder then
                local mainMenuModule = screensFolder:FindFirstChild("MainMenuUI")
                if mainMenuModule and mainMenuModule:IsA("ModuleScript") then
                    local success, mainMenuUI = pcall(function()
                        return require(mainMenuModule)
                    end)
                    
                    if success and mainMenuUI then
                        if mainMenuUI.initialize then
                            mainMenuUI:initialize()
                        end
                        
                        -- Register with both names to ensure compatibility
                        UIRegistry:registerComponent("MainMenuUI", mainMenuUI)
                        UIRegistry:registerComponent("MainMenu", mainMenuUI) -- Also register as MainMenu
                        
                        logMessage("Explicitly loaded and registered MainMenuUI", "Info")
                    else
                        logMessage("Failed to load MainMenuUI module: " .. tostring(mainMenuUI), "Warning")
                    end
                else
                    logMessage("MainMenuUI module not found in Screens folder", "Warning")
                end
            else
                logMessage("Screens folder not found in UI folder", "Warning")
            end
        end
    end
    
    -- Auto-initialize discovered components
    local initialized, failed = UIRegistry:initializeAllComponents()
    
    if #failed > 0 then
        logMessage("Failed to initialize " .. #failed .. " components", "Warning")
        for _, name in ipairs(failed) do
            table.insert(loadErrors, name)
        end
    end
    
    logTiming("ComponentInitialization", initStart)
    return #failed == 0
end

-- Connect signals
local function connectSignals()
    local signalStart = os.clock()
    
    -- Connect to UI lifecycle events
    local clientEvents = sharedFolder and sharedFolder:FindFirstChild("ClientEvents")
    if clientEvents and requireSafely(clientEvents) then
        local Events = require(clientEvents)
        
        -- Example event connections
        Events.OnPlayerReady:Connect(function(player)
            if player == LocalPlayer and CONFIG.autoShowMainMenu then
                UISystem:showMainMenu()
            end
        end)
        
        Events.OnPlayerLeaving:Connect(function(player)
            if player == LocalPlayer then
                UISystem:shutdown()
            end
        end)
    end
    
    logTiming("SignalConnections", signalStart)
    return true
end

-- Integrate with other systems
local function integrateWithSystems()
    local integrationStart = os.clock()
    
    -- Connect to game systems as needed
    local gameSystem = srcFolder:FindFirstChild("GameSystem")
    if gameSystem and requireSafely(gameSystem) then
        local GameSystem = require(gameSystem)
        
        -- Register with game system if it has a UI registration point
        if GameSystem.registerUISystem then
            GameSystem:registerUISystem(UISystem)
            logMessage("Registered with GameSystem", "Info")
        end
    end
    
    logTiming("SystemIntegration", integrationStart)
    return true
end

--[[ Public API Functions ]]--

-- Initialize the UI system
function UISystem:initialize()
    if initialized then
        logMessage("UISystem already initialized", "Warning")
        return true
    end
    
    logMessage("Initializing UI System", "Info")
    local success = true
    
    -- Step 1: Initialize registry
    success = success and initializeRegistry()
    
    -- Step 2: Discover components
    local discovered = discoverComponents()
    logMessage("Discovered " .. #discovered .. " UI modules", "Info")
    
    -- Step 3: Initialize components
    success = success and initializeComponents()
    
    -- Step 4: Connect signals
    success = success and connectSignals()
    
    -- Step 5: Integrate with other systems
    success = success and integrateWithSystems()
    
    -- Calculate initialization time
    local totalTime = os.clock() - startTime
    logMessage(string.format("UI System initialization completed in %.2f ms", totalTime * 1000), "Info")
    
    initialized = success
    return success
end

-- Show the main menu
function UISystem:showMainMenu()
    if not initialized then
        logMessage("Cannot show main menu, UI System not initialized", "Warning")
        return false
    end
    
    local UIHub = UIRegistry:getComponent("UIHub")
    if UIHub and UIHub.showScreen then
        return UIHub:showScreen("MainMenuUI")
    end
    
    -- Fallback if UIHub not available
    local mainMenu = UIRegistry:getComponent("MainMenuUI")
    if mainMenu and mainMenu.show then
        return mainMenu:show()
    end
    
    -- Extra fallback for legacy naming
    local legacyMainMenu = UIRegistry:getComponent("MainMenu")
    if legacyMainMenu and legacyMainMenu.show then
        return legacyMainMenu:show()
    end
    
    logMessage("Main menu component not found - checked both MainMenuUI and MainMenu", "Warning")
    return false
end

-- Show specific UI by name
function UISystem:showUI(name, ...)
    if not initialized then
        logMessage("Cannot show UI, UI System not initialized", "Warning")
        return false
    end
    
    -- Multi-path approach to find and show the UI
    
    -- Path 1: Try through UIManager first (preferred approach)
    local UIManager = UIRegistry:getComponent("UIManager")
    if UIManager and UIManager.showUI then
        -- First, try to get the component from registry
        local component = UIRegistry:getComponent(name)
        if component then
            local success = UIManager:showUI(name, component, ...)
            if success then
                logMessage("Successfully showed UI via UIManager with component from registry: " .. name, "Info")
                return true
            end
        end
        
        -- Try showing by name directly
        local success = UIManager:showUI(name, nil, ...)
        if success then
            logMessage("Successfully showed UI via UIManager direct path: " .. name, "Info")
            return true
        end
    end
    
    -- Path 2: Get component directly and call show method
    local component = UIRegistry:getComponent(name)
    if component and component.show then
        local success, result = pcall(function()
            return component:show(...)
        end)
        
        if success then
            logMessage("Successfully showed UI via direct component show method: " .. name, "Info")
            return true
        else
            logMessage("Error showing UI " .. name .. ": " .. tostring(result), "Warning")
        end
    end
    
    -- Path 3: Try global fallback
    if _G[name] and _G[name].show then
        local success, result = pcall(function()
            return _G[name]:show(...)
        end)
        
        if success then
            logMessage("Successfully showed UI via global fallback: " .. name, "Info")
            return true
        end
    end
    
    logMessage("Failed to show UI: " .. name .. " (tried all paths)", "Warning")
    return false
end

-- Hide specific UI by name
function UISystem:hideUI(name)
    if not initialized then
        logMessage("Cannot hide UI, UI System not initialized", "Warning")
        return false
    end
    
    local UIManager = UIRegistry:getComponent("UIManager")
    if UIManager and UIManager.hideUI then
        return UIManager:hideUI(name)
    end
    
    logMessage("UIManager not found", "Warning")
    return false
end

-- Get a UI component by name
function UISystem:getComponent(name)
    if not initialized then
        logMessage("Cannot get component, UI System not initialized", "Warning")
        return nil
    end
    
    return UIRegistry:getComponent(name)
end

-- Create a notification
function UISystem:notify(options)
    if not initialized then
        logMessage("Cannot create notification, UI System not initialized", "Warning")
        return nil
    end
    
    local UIManager = UIRegistry:getComponent("UIManager")
    if UIManager and UIManager.createNotification then
        return UIManager:createNotification(options)
    end
    
    logMessage("UIManager not found", "Warning")
    return nil
end

-- Show a modal dialog
function UISystem:showModal(options)
    if not initialized then
        logMessage("Cannot show modal, UI System not initialized", "Warning")
        return nil
    end
    
    local UIManager = UIRegistry:getComponent("UIManager")
    if UIManager and UIManager.createModal then
        return UIManager:createModal(options)
    end
    
    logMessage("UIManager not found", "Warning")
    return nil
end

-- Get initialization status
function UISystem:isInitialized()
    return initialized
end

-- Get performance metrics
function UISystem:getPerformanceMetrics()
    return {
        totalInitTime = os.clock() - startTime,
        componentTimes = componentInitTimes,
        errors = loadErrors
    }
end

-- Get button factory (convenience method)
function UISystem:getButtonFactory()
    return UIRegistry:getComponent("ButtonFactory")
end

-- Reset UI system
function UISystem:reset()
    if not initialized then
        return true
    end
    
    -- Hide all UIs
    local UIManager = UIRegistry:getComponent("UIManager")
    if UIManager and UIManager.hideAllUIs then
        UIManager:hideAllUIs()
    end
    
    -- Close all modals
    if UIManager and UIManager.closeAllModals then
        UIManager:closeAllModals()
    end
    
    -- Re-initialize components
    return initializeComponents()
end

-- Shutdown UI system
function UISystem:shutdown()
    if not initialized then
        return true
    end
    
    logMessage("Shutting down UI System", "Info")
    
    -- Clean up resources
    local UIManager = UIRegistry:getComponent("UIManager")
    if UIManager then
        -- Hide all UIs
        if UIManager.hideAllUIs then
            UIManager:hideAllUIs()
        end
        
        -- Close all modals
        if UIManager.closeAllModals then
            UIManager:closeAllModals()
        end
    end
    
    -- Mark as uninitialized
    initialized = false
    return true
end

-- Build diagnostic report
function UISystem:getDiagnosticReport()
    local report = {
        initialized = initialized,
        components = {},
        errors = loadErrors,
        performanceMetrics = componentInitTimes
    }
    
    -- Get components status
    if UIRegistry then
        local componentNames = UIRegistry:getAllComponentNames()
        for _, name in ipairs(componentNames) do
            report.components[name] = {
                state = UIRegistry:getComponentState(name),
                version = UIRegistry:getComponentVersion(name)
            }
        end
        
        -- Get dependency status
        report.dependencies = {}
        for _, name in ipairs(componentNames) do
            report.dependencies[name] = UIRegistry:getDependencies(name)
        end
        
        -- Get version conflicts
        report.conflicts = UIRegistry:checkVersionConflicts()
    end
    
    return report
end

-- Auto-initialize on module load
task.spawn(function()
    -- Give the system a moment to fully load before initializing
    task.wait(0.5)
    UISystem:initialize()
    
    -- Show main menu if configured
    if CONFIG.autoShowMainMenu and initialized then
        UISystem:showMainMenu()
    end
end)

-- Return the module
return UISystem
