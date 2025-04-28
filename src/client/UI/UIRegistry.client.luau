--[[
    UIRegistry.client.luau
    
    A central registry for managing all UI elements in the game.
    Handles UI registration, visibility, transitions, and state management.
    
    Updated April 2025 as part of critical fixes implementation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- UI Registry Module
local UIRegistry = {}

-- Component storage
UIRegistry.components = {}

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
    log("Registered UI component: " .. id){}
    return true
end

-- Get a registered componentIRegistry.activeScreens = {}
function UIRegistry.getComponent(id)UIRegistry.transitions = {}
    if not id or not UIRegistry.components[id] then
        return nil
    end
    
    return UIRegistry.components[id]ransition = "fade",
endultDuration = 0.3,
,
-- Initialize the registry
function UIRegistry.initialize()bled = true,
    log("UIRegistry initialized successfully") true
end

-- Initialize on module load-- Debug logger
UIRegistry.initialize()nfiguration

return UIRegistry