-- UISystemEnhancer.client.luau
-- This script enhances the existing UISystem to better handle UI components
-- Created April 28, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

print("UISystemEnhancer: Starting...")

-- Constants
local DEBUG = true
local RETRY_DELAY = 0.5
local MAX_RETRIES = 10

-- Store loaded components
local loadedComponents = {}

-- Store original method references if patching required
local originalMethods = {}

-- Helper function to log messages
local function log(message, level)
    level = level or "Info"
    
    if not DEBUG and level == "Debug" then
        return
    end
    
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

-- Helper function to safely get system from registry
local function getSystem(name)
    -- Try to get the registry from the environment
    local ClientRegistry = nil
    
    -- Use shared registry if available
    local success, result = pcall(function()
        return ReplicatedStorage:FindFirstChild("ClientRegistry")
    end)
    
    if success and result then
        ClientRegistry = require(result)
    else
        -- Try to find it in the player's scripts
        success, result = pcall(function()
            return LocalPlayer.PlayerScripts:FindFirstChild("ClientRegistry")
        end)
        
        if success and result then
            ClientRegistry = require(result)
        end
    end
    
    -- If registry found, use it to get the system
    if ClientRegistry and ClientRegistry.getSystem then
        local system = ClientRegistry:getSystem(name)
        if system then
            return system
        end
    end
    
    -- If still not found, try direct path to common locations
    local paths = {
        LocalPlayer.PlayerScripts:FindFirstChild(name),
        ReplicatedStorage:FindFirstChild(name),
        game:FindFirstChild(name)
    }
    
    for _, path in ipairs(paths) do
        if path and path:IsA("ModuleScript") then
            success, result = pcall(function()
                return require(path)
            end)
            
            if success then
                return result
            end
        end
    end
    
    -- Still not found, try to search more thoroughly
    log("Searching for " .. name .. " module...", "Debug")
    
    -- Try player scripts folder
    local scripts = LocalPlayer.PlayerScripts:GetDescendants()
    for _, script in ipairs(scripts) do
        if script:IsA("ModuleScript") and script.Name == name then
            success, result = pcall(function()
                return require(script)
            end)
            
            if success then
                return result
            end
        end
    end
    
    -- Not found
    log("System not found: " .. name, "Debug")
    return nil
end

-- Find UI component modules in the workspace
local function findUIComponentModules()
    local components = {}
    
    -- Try to find components in client/UI/Screens folder (new structure)
    local uiScreensFolder = nil
    
    -- Path 1: PlayerScripts/src/client/UI/Screens
    local src = LocalPlayer.PlayerScripts:FindFirstChild("src")
    if src then
        local client = src:FindFirstChild("client")
        if client then
            local ui = client:FindFirstChild("UI")
            if ui then
                uiScreensFolder = ui:FindFirstChild("Screens")
            end
        end
    end
    
    -- Path 2: PlayerScripts/UI/Screens
    if not uiScreensFolder then
        local ui = LocalPlayer.PlayerScripts:FindFirstChild("UI")
        if ui then
            uiScreensFolder = ui:FindFirstChild("Screens")
        end
    end
    
    -- If found UI Screens folder, load components
    if uiScreensFolder then
        for _, moduleScript in ipairs(uiScreensFolder:GetChildren()) do
            if moduleScript:IsA("ModuleScript") then
                components[moduleScript.Name] = moduleScript
                log("Found UI component module: " .. moduleScript.Name)
            end
        end
    end
    
    -- Also check StarterGui for legacy UI scripts
    local starterGui = game:GetService("StarterGui")
    for _, child in ipairs(starterGui:GetChildren()) do
        if child:IsA("ModuleScript") then
            components[child.Name] = child
            log("Found legacy UI component module in StarterGui: " .. child.Name)
        end
    end
    
    return components
end

-- Load a UI component by name and module reference
local function loadUIComponent(name, moduleScript)
    if loadedComponents[name] then
        log("Component " .. name .. " already loaded")
        return loadedComponents[name]
    end
    
    if not moduleScript then
        log("Module script for " .. name .. " not provided", "Warning")
        return nil
    end
    
    log("Loading UI component: " .. name)
    
    local success, component = pcall(function()
        return require(moduleScript)
    end)
    
    if not success then
        log("Failed to load component " .. name .. ": " .. tostring(component), "Warning")
        return nil
    end
    
    -- Initialize the component if it has an initialize method
    if component.initialize and type(component.initialize) == "function" then
        local initSuccess, result = pcall(function()
            return component:initialize()
        end)
        
        if not initSuccess then
            log("Failed to initialize component " .. name .. ": " .. tostring(result), "Warning")
        end
    end
    
    -- Store the component
    loadedComponents[name] = component
    log("Successfully loaded component: " .. name)
    
    return component
end

-- Enhanced showUI function with multiple fallback paths
local function showUI(name, ...)
    local args = {...}
    log("Attempting to show UI: " .. name)
    
    -- First try: Use UISystem
    local uiSystem = getSystem("UISystem")
    if uiSystem and uiSystem.showUI then
        local success, result = pcall(function()
            return uiSystem:showUI(name, unpack(args))
        end)
        
        if success and result ~= false then
            log("Successfully showed UI via UISystem: " .. name)
            return true
        end
    end
    
    -- Second try: Direct component access
    local component = nil
    local uiRegistry = getSystem("UIRegistry")
    
    if uiRegistry and uiRegistry.getComponent then
        component = uiRegistry:getComponent(name)
    end
    
    if not component then
        component = loadedComponents[name]
    end
    
    if component and component.show then
        local success, result = pcall(function()
            if #args > 0 then
                return component:show(unpack(args))
            else
                return component:show()
            end
        end)
        
        if success and result ~= false then
            log("Successfully showed UI via direct component access: " .. name)
            return true
        end
    end
    
    -- Third try: Try to load component first
    if not component then
        log("Component " .. name .. " not loaded, attempting to find and load it", "Debug")
        
        local componentModules = findUIComponentModules()
        if componentModules[name] then
            component = loadUIComponent(name, componentModules[name])
            
            if component and component.show then
                local success, result = pcall(function()
                    if #args > 0 then
                        return component:show(unpack(args))
                    else
                        return component:show()
                    end
                end)
                
                if success and result ~= false then
                    log("Successfully showed UI after loading component: " .. name)
                    return true
                end
            end
        end
    end
    
    -- Last try: Look for a global reference
    if _G[name] and _G[name].show then
        local success, result = pcall(function()
            if #args > 0 then
                return _G[name]:show(unpack(args))
            else
                return _G[name]:show()
            end
        end)
        
        if success and result ~= false then
            log("Successfully showed UI via global reference: " .. name)
            return true
        end
    end
    
    log("Failed to show UI: " .. name, "Warning")
    return false
end

-- Enhanced hideUI function with multiple fallback paths
local function hideUI(name)
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
    local component = nil
    local uiRegistry = getSystem("UIRegistry")
    
    if uiRegistry and uiRegistry.getComponent then
        component = uiRegistry:getComponent(name)
    end
    
    if not component then
        component = loadedComponents[name]
    end
    
    if component and component.hide then
        local success, result = pcall(function()
            return component:hide()
        end)
        
        if success and result ~= false then
            log("Successfully hid UI via direct component access: " .. name)
            return true
        end
    end
    
    log("Failed to hide UI: " .. name, "Warning")
    return false
end

-- Helper function to restore original methods if needed
local function restoreOriginalMethods()
    local uiSystem = getSystem("UISystem")
    if not uiSystem then
        return false
    end
    
    local restored = false
    
    -- Restore original showUI if we have it
    if originalMethods.showUI and uiSystem.showUI then
        uiSystem.showUI = originalMethods.showUI
        restored = true
    end
    
    -- Restore original hideUI if we have it
    if originalMethods.hideUI and uiSystem.hideUI then
        uiSystem.hideUI = originalMethods.hideUI
        restored = true
    end
    
    return restored
end

-- Create module API for other scripts to use
local EnhancedUISystem = {
    showUI = showUI,
    hideUI = hideUI,
    loadUIComponent = loadUIComponent,
    findUIComponentModules = findUIComponentModules,
    getLoadedComponents = function() return loadedComponents end,
    restoreOriginalMethods = restoreOriginalMethods
}

-- Pre-load critical UI components
local function preloadComponents()
    log("Preloading UI components...")
    local componentModules = findUIComponentModules()
    
    -- Priority components to load first
    local priorityComponents = {
        "MainMenuUI",
        "SettingsUI"
    }
    -- Note: "RebirthUI" has been removed from the priority components list
    
    -- Load priority components first
    for _, name in ipairs(priorityComponents) do
        if componentModules[name] then
            loadUIComponent(name, componentModules[name])
        end
    end
    
    -- Load remaining components
    local componentCount = 0
    for name, moduleScript in pairs(componentModules) do
        if not loadedComponents[name] then
            loadUIComponent(name, moduleScript)
            componentCount = componentCount + 1
        end
    end
    
    log("Preloaded " .. componentCount .. " UI components")
end

-- Patch existing UISystem methods if needed
local function patchUISystem()
    local uiSystem = getSystem("UISystem")
    if not uiSystem then
        log("UISystem not found, cannot patch", "Warning")
        return
    end
    
    -- Store original methods before patching
    if uiSystem.showUI then
        originalMethods.showUI = uiSystem.showUI
        -- Replace with our enhanced version
        uiSystem.showUI = function(_, name, ...)
            return showUI(name, ...)
        end
        
        log("Patched UISystem.showUI with enhanced version")
    end
    
    if uiSystem.hideUI then
        originalMethods.hideUI = uiSystem.hideUI
        
        -- Replace with our enhanced version
        uiSystem.hideUI = function(_, name)
            return hideUI(name)
        end
        
        log("Patched UISystem.hideUI with enhanced version")
    end
    
    -- Add method to show main menu if missing
    if not uiSystem.showMainMenu then
        uiSystem.showMainMenu = function(_)
            return showUI("MainMenuUI")
        end
        
        log("Added showMainMenu method to UISystem")
    end
end

-- Main execution sequence
local function initialize()
    log("Initializing UISystemEnhancer...")
    
    -- Preload components
    preloadComponents()
    
    -- Try to patch UISystem methods
    patchUISystem()
    
    -- Try to show main menu if no UI visible yet
    local function tryShowMainMenu()
        -- Check if any UI is already visible
        local anyUIVisible = false
        for name, component in pairs(loadedComponents) do
            if component.isVisible and component.isVisible == true then
                anyUIVisible = true
                break
            end
        end
        
        if not anyUIVisible then
            showUI("MainMenuUI")
        end
    end
    
    -- Delay slightly to allow game to initialize fully
    task.delay(1, function()
        tryShowMainMenu()
    end)
    
    -- Emergency UI Access has been removed to avoid exposing development-only features to players
    
    log("UISystemEnhancer initialization complete")
end

-- Run initialization
initialize()

-- Return the module API for other scripts to use
return EnhancedUISystem
