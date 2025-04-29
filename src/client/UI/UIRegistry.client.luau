--[[
    UIRegistry.client.luau
    
    A central registry for managing all UI elements in the game.
    Handles UI registration, visibility, transitions, and state management.
    
    Updated April 2025 as part of critical fixes implementation
]]

-- Service declarations for future use
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- UI Registry Module
local UIRegistry = {}

-- Prevent unused variable warnings
UIRegistry._services = {
    ReplicatedStorage = ReplicatedStorage,
    Players = Players,
    TweenService = TweenService
}

-- Component storage
UIRegistry.components = {}

-- Screen management
UIRegistry.activeScreens = {}

-- Transition configuration
UIRegistry.transitions = {
    defaultTransition = "fade",
    defaultDuration = 0.3,
    enabled = true
}

-- Debug logger
local function log(message)
    print("[UIRegistry]", message)
end

-- Register a component
function UIRegistry.registerComponent(id, component)
    if not id or type(id) ~= "string" then
        warn("[UIRegistry] Invalid component ID")
        return false
    end
    
    if not component then
        warn("[UIRegistry] Component is nil")
        return false
    end
    
    -- Store component
    UIRegistry.components[id] = component
    log("Registered UI component: " .. id)
    return true
end

-- Get a registered component
function UIRegistry.getComponent(id)
    if not id or not UIRegistry.components[id] then
        return nil
    end
    
    return UIRegistry.components[id]
end

-- Initialize the registry
function UIRegistry.initialize()
    log("UIRegistry initialized successfully")
end

-- Initialize on module load
UIRegistry.initialize()

return UIRegistry