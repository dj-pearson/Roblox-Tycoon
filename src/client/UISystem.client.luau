--!strict
--[[
    UISystem.client.luau
    
    Centralized initialization and management of the UI system.
    This is the main entry point for the UI framework.
    
    Features:
    - Automatic UI component initialization
    - Registration of all UI components
    - Error handling for UI loading issues
    - Debugging capabilities for UI system
    
    Author: Updated April 26, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Find paths to important folders
local srcFolder = ReplicatedStorage:FindFirstChild("src") 
if not srcFolder then
    warn("Source folder not found")
    return
end

local sharedFolder = srcFolder:FindFirstChild("shared")
if not sharedFolder then
    warn("Shared folder not found")
    return
end

local clientFolder = srcFolder:FindFirstChild("client")
if not clientFolder then
    warn("Client folder not found")
    return
end

local clientUIFolder = clientFolder:FindFirstChild("UI")
if not clientUIFolder then
    warn("UI folder not found")
    clientUIFolder = Instance.new("Folder")
    clientUIFolder.Name = "UI"
    clientUIFolder.Parent = clientFolder
end

-- Create Core and Screens folders if they don't exist
local uiCoreFolder = clientUIFolder:FindFirstChild("Core")
if not uiCoreFolder then
    uiCoreFolder = Instance.new("Folder")
    uiCoreFolder.Name = "Core"
    uiCoreFolder.Parent = clientUIFolder
end

local uiScreensFolder = clientUIFolder:FindFirstChild("Screens")
if not uiScreensFolder then
    uiScreensFolder = Instance.new("Folder")
    uiScreensFolder.Name = "Screens"
    uiScreensFolder.Parent = clientUIFolder
end

local uiComponentsFolder = clientUIFolder:FindFirstChild("Components")
if not uiComponentsFolder then
    uiComponentsFolder = Instance.new("Folder")
    uiComponentsFolder.Name = "Components"
    uiComponentsFolder.Parent = clientUIFolder
end

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

-- Required core modules
local UIManager, UIRegistry, UIHub

-- Configuration
local CONFIG = {
    enableLegacySupport = true,
    autoInitializeComponents = true,
    coreUIModules = {
        "UIManager",
        "UIRegistry",
        "UIHub"
    },
    screenModules = {
        "MainMenuUI",
        "RebirthUI",
        "SettingsUI",
        "StatisticsDisplay"
    },
    defaultScreen = "MainMenuUI"
}

-- Initialize Core UI Modules
local function initializeCoreModules()
    local successCount = 0
    
    -- UIManager is first because other modules might depend on it
    local managerModule = uiCoreFolder:FindFirstChild("UIManager")
    if managerModule then
        UIManager = requireSafely(managerModule)
        if UIManager then
            successCount += 1
            print("Initialized UIManager")
        end
    else
        warn("UIManager module not found")
    end
    
    -- UIRegistry is second because UI components will register with it
    local registryModule = uiCoreFolder:FindFirstChild("UIRegistry")
    if registryModule then
        UIRegistry = requireSafely(registryModule)
        if UIRegistry then
            successCount += 1
            print("Initialized UIRegistry")
        end
    else
        warn("UIRegistry module not found")
    end
    
    -- UIHub is third because it depends on both UIManager and UIRegistry
    local hubModule = uiCoreFolder:FindFirstChild("UIHub")
    if hubModule then
        UIHub = requireSafely(hubModule)
        if UIHub then
            successCount += 1
            print("Initialized UIHub")
            
            -- Set default screen
            if UIHub.setDefaultScreen then
                UIHub:setDefaultScreen(CONFIG.defaultScreen)
            end
        end
    else
        warn("UIHub module not found")
    end
    
    return successCount
end

-- Initialize Screen UI Modules
local function initializeScreenModules()
    local successCount = 0
    
    -- Gather all module scripts in the Screens folder
    local screenModules = {}
    for _, instance in ipairs(uiScreensFolder:GetChildren()) do
        if instance:IsA("ModuleScript") then
            table.insert(screenModules, instance)
        end
    end
    
    -- Initialize each screen module
    for _, module in ipairs(screenModules) do
        local screenUI = requireSafely(module)
        if screenUI then
            if typeof(screenUI) == "table" and screenUI.initialize then
                screenUI:initialize()
            end
            successCount += 1
            print("Initialized screen UI: " .. module.Name)
        end
    end
    
    return successCount
end

-- Initialize Component UI Modules
local function initializeComponentModules()
    local successCount = 0
    
    -- Gather all module scripts in the Components folder
    local componentModules = {}
    for _, instance in ipairs(uiComponentsFolder:GetChildren()) do
        if instance:IsA("ModuleScript") then
            table.insert(componentModules, instance)
        end
    end
    
    -- Initialize each component module
    for _, module in ipairs(componentModules) do
        local componentUI = requireSafely(module)
        if componentUI then
            if typeof(componentUI) == "table" and componentUI.initialize then
                componentUI:initialize()
            end
            successCount += 1
            print("Initialized component UI: " .. module.Name)
        end
    end
    
    return successCount
end

-- Set up legacy UI compatibility
local function setupLegacyCompatibility()
    if not CONFIG.enableLegacySupport then
        return
    end
    
    -- Redirect legacy StarterGui UI scripts to the new system
    if not UIManager then
        return
    end
    
    -- Get all UI modules from StarterGui
    local legacyModuleNames = {
        "RebirthUI",
        "RebirthUIFixes",
        "RebirthUI_Enhanced",
        "RebirthMenuUI",
        "MainMenuUI",
        "SettingsUI",
        "StatsGui"
    }
    
    -- Create compatibility layer for each legacy module
    for _, moduleName in ipairs(legacyModuleNames) do
        local legacyModule = StarterGui:FindFirstChild(moduleName)
        if legacyModule and legacyModule:IsA("ModuleScript") then
            -- Override module with compatibility wrapper
            local originalModule = requireSafely(legacyModule)
            if originalModule then
                -- Create proxy table that forwards to new implementation
                local proxy = setmetatable({}, {
                    __index = function(_, key)
                        local newImplementation = UIRegistry and UIRegistry:getComponent(moduleName:gsub(".client", ""))
                        if newImplementation and newImplementation[key] then
                            return newImplementation[key]
                        elseif originalModule[key] then
                            return originalModule[key]
                        end
                        return nil
                    end,
                    __newindex = function(_, key, value)
                        originalModule[key] = value
                    end,
                    __call = function(_, ...)
                        if type(originalModule) == "function" then
                            return originalModule(...)
                        end
                        return nil
                    end
                })
                
                -- Replace original require result with our proxy
                _G["Legacy_" .. moduleName] = proxy
                
                print("Set up legacy compatibility for " .. moduleName)
            end
        end
    end
end

-- Show initial UI
local function showInitialUI()
    -- Wait a bit to ensure all systems are loaded
    task.wait(1)
    
    if UIHub then
        UIHub:showDefaultScreen()
        print("Showed default screen: " .. CONFIG.defaultScreen)
    end
end

-- Main initialization function
local function initialize()
    print("Initializing UI System...")
    
    -- Initialize core modules
    local coreSuccess = initializeCoreModules()
    if coreSuccess == 0 then
        warn("Failed to initialize any core UI modules!")
        return false
    end
    
    -- Initialize screen modules if auto-initialize is enabled
    local screenSuccess = 0
    if CONFIG.autoInitializeComponents then
        screenSuccess = initializeScreenModules()
        print("Initialized " .. screenSuccess .. " screen modules")
    end
    
    -- Initialize component modules if auto-initialize is enabled
    local componentSuccess = 0
    if CONFIG.autoInitializeComponents then
        componentSuccess = initializeComponentModules()
        print("Initialized " .. componentSuccess .. " component modules")
    end
    
    -- Set up legacy compatibility
    setupLegacyCompatibility()
    
    -- Show default UI after a short delay
    task.spawn(showInitialUI)
    
    print("UI System initialization complete!")
    return true
end

-- Export UISystem
local UISystem = {
    initialize = initialize,
    UIManager = function() return UIManager end,
    UIRegistry = function() return UIRegistry end,
    UIHub = function() return UIHub end,
    
    -- Helper methods
    showScreen = function(screenName)
        if UIHub then
            return UIHub:navigateTo(screenName)
        end
        return false
    end,
    
    hideScreen = function(screenName)
        if UIManager then
            return UIManager:hideUI(screenName)
        end
        return false
    end,
    
    refreshUI = function()
        initialize()
    end
}

-- Initialize when the module loads
initialize()

-- Return the module
return UISystem
