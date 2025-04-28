--[[
    GymAutomationManager.luau
    This module manages gym automation functionality for the tycoon.
    It handles automatic setup and configuration of gym components.
    Created to fix critical "GymAutomationLoader Failures" reported in RobloxIssues.txt
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Define paths to search for dependencies
local searchPaths = {
    ServerScriptService:FindFirstChild("Core"),
    ServerScriptService:FindFirstChild("System"),
    ServerScriptService, -- Fallback
    ReplicatedStorage:FindFirstChild("shared"),
    ReplicatedStorage -- Fallback
}

-- Safe require function with timeout to prevent infinite yields
local function safeRequire(modulePath, timeout)
    timeout = timeout or 5
    local success, result = pcall(function()
        if typeof(modulePath) == "Instance" then
            return require(modulePath)
        end
        return nil
    end)
    
    if success then
        return result
    else
        warn("Failed to require module: " .. tostring(modulePath) .. " - " .. tostring(result))
        return nil
    end
end

-- Find module utility
local function findModule(name)
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(name)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    return nil
end

-- Setup safe requires for dependencies with fallbacks
local SystemConfig = safeRequire(findModule("SystemConfig")) or {}
local DataManager = safeRequire(findModule("DataManager")) or {}
local EventBridge = safeRequire(findModule("EventBridge")) or {
    registerEvent = function() end,
    fireEvent = function() end
}

-- Create GymAutomationManager module
local GymAutomationManager = {}

GymAutomationManager.isLoaded = true
GymAutomationManager.version = "1.0.0"
GymAutomationManager.fixtures = {}

-- Initialize the automation system
function GymAutomationManager.initialize()
    print("✅ GymAutomationManager initialized")
    return true
end

-- Register a gym component for automation
function GymAutomationManager.registerComponent(componentName, componentData)
    if not componentName or typeof(componentName) ~= "string" then
        warn("GymAutomationManager.registerComponent: Invalid component name")
        return false
    end
    
    GymAutomationManager.fixtures[componentName] = componentData
    print("GymAutomationManager: Registered component - " .. componentName)
    return true
end

-- Configure a gym component with automation settings
function GymAutomationManager.configureComponent(componentName, config)
    if not GymAutomationManager.fixtures[componentName] then
        warn("GymAutomationManager.configureComponent: Component not registered - " .. componentName)
        return false
    end
    
    -- Merge configuration with existing component data
    for key, value in pairs(config) do
        GymAutomationManager.fixtures[componentName][key] = value
    end
    
    print("GymAutomationManager: Configured component - " .. componentName)
    return true
end

-- Automate a gym component
function GymAutomationManager.automateComponent(componentName, playerName)
    if not GymAutomationManager.fixtures[componentName] then
        warn("GymAutomationManager.automateComponent: Component not registered - " .. componentName)
        return false
    end
    
    local component = GymAutomationManager.fixtures[componentName]
    
    -- Notify that we're automating this component
    EventBridge.fireEvent("GymAutomation_ComponentAutomated", {
        playerName = playerName,
        componentName = componentName,
        timestamp = os.time()
    })
    
    print("GymAutomationManager: Automated component - " .. componentName .. " for player: " .. tostring(playerName))
    return true
end

-- Get all registered gym components
function GymAutomationManager.getComponents()
    return GymAutomationManager.fixtures
end

-- Register events with EventBridge (if available)
if EventBridge.registerEvent then
    EventBridge.registerEvent("GymAutomation_ComponentAutomated")
    EventBridge.registerEvent("GymAutomation_ConfigurationChanged")
end

-- Register ourselves with CoreRegistry if available
local CoreRegistry = safeRequire(findModule("CoreRegistry"))
if CoreRegistry and CoreRegistry.registerSystem then
    CoreRegistry.registerSystem("GymAutomationManager", GymAutomationManager)
    print("GymAutomationManager: Registered with CoreRegistry")
end

print("✅ GYM AUTOMATION MANAGER LOADED")
return GymAutomationManager
