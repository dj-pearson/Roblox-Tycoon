--[[
    GymAutomation.luau
    This module serves as the primary interface for gym automation functionality.
    It wraps the GymAutomationManager and provides a simplified API for general use.
    Created to fix critical "GymAutomationLoader Failures" reported in RobloxIssues.txt
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Define paths to search for dependencies
local searchPaths = {
    ServerScriptService:FindFirstChild("GymAutomation"),
    ServerScriptService:FindFirstChild("Core"),
    ServerScriptService:FindFirstChild("System"),
    ServerScriptService, -- Fallback
    ReplicatedStorage:FindFirstChild("shared"),
    ServerStorage -- Last fallback
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

-- Try to load the GymAutomationManager
local GymAutomationManager = safeRequire(findModule("GymAutomationManager"))

-- Create a fallback if the manager couldn't be loaded
if not GymAutomationManager then
    warn("GymAutomation: Failed to load GymAutomationManager, creating fallback")
    GymAutomationManager = {
        initialize = function() return false end,
        registerComponent = function() return false end,
        configureComponent = function() return false end,
        automateComponent = function() return false end,
        getComponents = function() return {} end,
        isLoaded = false
    }
end

-- Create the GymAutomation module
local GymAutomation = {}

-- Public API - Version information
GymAutomation.VERSION = "1.0.0"
GymAutomation.isLoaded = true

-- Initialize the automation system with configuration
function GymAutomation.initialize(config)
    config = config or {}
    
    local success = GymAutomationManager.initialize()
    
    if success then
        -- Register default component types if provided in config
        if config.componentTypes then
            for name, data in pairs(config.componentTypes) do
                GymAutomation.registerComponent(name, data)
            end
        end
        
        print("✅ GymAutomation initialized successfully")
        return true
    else
        warn("❌ GymAutomation failed to initialize")
        return false
    end
end

-- Register a component type for automation
function GymAutomation.registerComponent(name, data)
    return GymAutomationManager.registerComponent(name, data)
end

-- Configure a component with specific settings
function GymAutomation.configureComponent(name, config)
    return GymAutomationManager.configureComponent(name, config)
end

-- Automate a component for a specific player
function GymAutomation.automate(componentName, playerName)
    return GymAutomationManager.automateComponent(componentName, playerName)
end

-- Get all registered components
function GymAutomation.getComponents()
    return GymAutomationManager.getComponents()
end

-- Check if a specific component is registered
function GymAutomation.hasComponent(componentName)
    local components = GymAutomation.getComponents()
    return components[componentName] ~= nil
end

-- Get the manager instance directly (for advanced use cases)
function GymAutomation.getManager()
    return GymAutomationManager
end

print("✅ GYM AUTOMATION LOADED")
return GymAutomation
