-- UISystemEnhancer.client.luau
-- This script enhances the existing UISystem to better handle UI components
-- Created April 28, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
-- Note: PlayerGui reference removed since Emergency UI Access feature was removed

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
        ClientRegistry = result
    end
    
    -- Try player scripts
    if not ClientRegistry then
        success, result = pcall(function()
            return LocalPlayer.PlayerScripts:FindFirstChild("ClientRegistry")
        end)
        
        if success and result then
            ClientRegistry = result
        end
    end
    
    -- If we found the registry, try to get the system
    if ClientRegistry and ClientRegistry.getSystem then
        local system = ClientRegistry:getSystem(name)
        if system then
            return system
        end
    end
    
    return nil
end

-- Helper function to safely require modules
local function requireSafely(modulePath)
    if not modulePath or not modulePath:IsA("ModuleScript") then
        return nil
    end
    
    local success, result = pcall(function()
        return require(modulePath)
    end)
    
    if not success then
        log("Failed to require " .. modulePath:GetFullName() .. " - " .. tostring(result), "Warning")
        return nil
    end
    
    return result
end

-- Find all UI components in the Screens folder
local function findUIComponentModules()
    local components = {}
    
    local srcFolder = ReplicatedStorage:FindFirstChild("src")
    if not srcFolder then
        log("src folder not found", "Warning")
        return components
    end
    
    local clientFolder = srcFolder:FindFirstChild("client")
    if not clientFolder then
        log("client folder not found", "Warning")
        return components
    end
    
    local uiFolder = clientFolder:FindFirstChild("UI")
    if not uiFolder then
        log("UI folder not found", "Warning")
        return components
    end
    
    local screensFolder = uiFolder:FindFirstChild("Screens")
    if not screensFolder then
        log("Screens folder not found", "Warning")
        return components
    end
    
    log("Found Screens folder")
    
    for _, child in ipairs(screensFolder:GetChildren()) do
        if child:IsA("ModuleScript") then
            local name = child.Name:gsub("%.luau$", ""):gsub("%.lua$", "")
            components[name] = child
        end
    end
    
    local componentCount = 0
    for _ in pairs(components) do
        componentCount = componentCount + 1
    end
    
    log("Found " .. componentCount .. " UI component modules")
    return components
end

-- Load and register a UI component
local function loadUIComponent(name, modulePath)
    log("Loading component: " .. name)
    
    -- Skip if already loaded
    if loadedComponents[name] then
        log("Component already loaded: " .. name, "Debug")
        return loadedComponents[name]
    end
    
    -- Require the module
    local component = requireSafely(modulePath)
    if not component then
        log("Failed to load component: " .. name, "Warning")
        return nil
    end
    
    -- Initialize if it has initialize method and hasn't been initialized
    if component.initialize and not component.isInitialized then
        local success, result = pcall(function()
            return component:initialize()
        end)
        
        if not success then
            log("Failed to initialize component: " .. name .. " - " .. tostring(result), "Warning")
        end
    end
    
    -- Register with UIRegistry if available
    local uiRegistry = getSystem("UIRegistry")
    if uiRegistry and uiRegistry.registerComponent then
        local success = pcall(function()
            uiRegistry:registerComponent(name, component)
        end)
        
        if success then
            log("Registered component with UIRegistry: " .. name)
        end
    end
    
    -- Register with UIManager if available
    local uiManager = getSystem("UIManager")
    if uiManager and uiManager.registerUI then
        local success = pcall(function()
            uiManager:registerUI(name, component)
        end)
        
        if success then
            log("Registered component with UIManager: " .. name)
        end
    end
    
    -- Cache the component
    loadedComponents[name] = component
    
    return component
end

-- Create a resilient showUI function that will always work
local function showUI(name, ...)
    log("Attempting to show UI: " .. name)
    
    -- Store the varargs in a table we can use throughout the function
    local args = table.pack(...)
    
    -- First try: UISystem (proper way)
    local uiSystem = getSystem("UISystem")
    if uiSystem and uiSystem.showUI then
        local success, result = pcall(function()
            local packed = args
            return uiSystem:showUI(name, table.unpack(packed, 1, packed.n))
        end)
        
        if success and result then
            log("Successfully showed UI via UISystem: " .. name)
            return true
        end
    end
    
    -- Second try: Direct component access via registry
    local uiRegistry = getSystem("UIRegistry")
    if uiRegistry and uiRegistry.getComponent then
        local component = uiRegistry:getComponent(name)
        if component and component.show then
            local success, result = pcall(function()
                local packed = args
                return component:show(table.unpack(packed, 1, packed.n))
            end)
            
            if success and result ~= false then
                log("Successfully showed UI via direct component access: " .. name)
                return true
            end
        end
    end
    
    -- Third try: Cached components from our loader
    local component = loadedComponents[name]
    if component and component.show then
        local success, result = pcall(function()
            local packed = args
            return component:show(table.unpack(packed, 1, packed.n))
        end)
        
        if success and result ~= false then
            log("Successfully showed UI via cached component: " .. name)
            return true
        end
    end
    
    -- Fourth try: Load the component if not loaded yet
    local componentModules = findUIComponentModules()
    local modulePath = componentModules[name]
    if modulePath then
        component = loadUIComponent(name, modulePath)
        if component and component.show then
            local success, result = pcall(function()
                local packed = args
                return component:show(table.unpack(packed, 1, packed.n))
            end)
            
            if success and result ~= false then
                log("Successfully showed UI via freshly loaded component: " .. name)
                return true
            end
        end
    end
    
    log("All attempts to show UI failed: " .. name, "Warning")
    return false
end

-- Create a helper for hiding UIs
local function hideUI(name)
    log("Attempting to hide UI: " .. name)
    
    -- First try: UISystem
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
        "SettingsUI",
        "RebirthUI"
    }
    
    -- Load priority components first
    for _, name in ipairs(priorityComponents) do
        if componentModules[name] then
            loadUIComponent(name, componentModules[name])
        end
    end
    
    -- Load remaining components
    for name, modulePath in pairs(componentModules) do
        if not loadedComponents[name] then
            loadUIComponent(name, modulePath)
        end
    end
    
    local componentCount = 0
    for _ in pairs(loadedComponents) do
        componentCount = componentCount + 1
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
        uiSystem.showUI = function(self, name, ...)
            -- Acknowledge self parameter to avoid unused variable warning
            if self then end
            return showUI(name, ...)
        end
        
        log("Patched UISystem.showUI with enhanced version")
    end
    
    if uiSystem.hideUI then
        originalMethods.hideUI = uiSystem.hideUI
        
        -- Replace with our enhanced version
        uiSystem.hideUI = function(self, name)
            -- Acknowledge self parameter to avoid unused variable warning
            if self then end
            return hideUI(name)
        end
        
        log("Patched UISystem.hideUI with enhanced version")
    end
    
    -- Add method to show main menu if missing
    if not uiSystem.showMainMenu then
        uiSystem.showMainMenu = function(self)
            -- Acknowledge self parameter to avoid unused variable warning
            if self then end
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
    
    -- Patch UISystem
    patchUISystem()
    
    -- Attempt to show main menu after a delay
    task.delay(1, function()
        local retryCount = 0
        
        local function tryShowMainMenu()
            if showUI("MainMenuUI") then
                log("Successfully showed MainMenuUI")
                return
            end
            
            retryCount = retryCount + 1
            if retryCount < MAX_RETRIES then
                log("Retry " .. retryCount .. " of " .. MAX_RETRIES .. " to show MainMenuUI")
                task.delay(RETRY_DELAY, tryShowMainMenu)
            else
                log("Failed to show MainMenuUI after " .. MAX_RETRIES .. " attempts", "Warning")
            end
        end
        
        tryShowMainMenu()
    end)      -- Emergency UI Access has been removed to avoid exposing development-only features to players
    
    log("UISystemEnhancer initialization complete")
end

-- Run initialization
initialize()

-- Return the module API for other scripts to use
return EnhancedUISystem
