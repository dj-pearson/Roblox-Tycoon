--!strict
--[[
    UISystem.luau
    
    Core system for managing UI components and their lifecycle.
    Integrates with UIManager for display and transitions.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Import dependencies
local UIManager = require(script.Parent.UIManager)
local Constants = require(script.Parent.Parent.Constants)

-- Component registry
local components = {}
local visibleComponents = {}

-- UISystem class
local UISystem = {}
UISystem.__index = UISystem

-- Create new UISystem instance
function UISystem.new()
    local self = setmetatable({}, UISystem)
    self:initialize()
    return self
end

-- Initialize the system
function UISystem:initialize()
    -- Initialize UIManager if not already initialized
    if not UIManager.initialized then
        UIManager:initialize()
    end
    
    -- Clear any existing state
    components = {}
    visibleComponents = {}
end

-- Register a UI component
function UISystem:registerComponent(component)
    if not component or not component.name then
        warn("Invalid component registration: missing component or name")
        return false
    end
    
    components[component.name] = component
    return true
end

-- Get a registered component
function UISystem:getComponent(name)
    return components[name]
end

-- Show a UI component
function UISystem:showComponent(name, animation)
    local component = components[name]
    if not component then
        warn("Component not found:", name)
        return false
    end
    
    -- Check if already visible
    if visibleComponents[name] then
        return true
    end
    
    -- Show component using UIManager
    local success = UIManager:showUI(name, component, animation)
    if success then
        visibleComponents[name] = true
        component:onShow()
    end
    
    return success
end

-- Hide a UI component
function UISystem:hideComponent(name, animation)
    local component = components[name]
    if not component then
        warn("Component not found:", name)
        return false
    end
    
    -- Check if already hidden
    if not visibleComponents[name] then
        return true
    end
    
    -- Hide component using UIManager
    local success = UIManager:hideUI(name)
    if success then
        visibleComponents[name] = nil
        component:onHide()
    end
    
    return success
end

-- Check if a component is visible
function UISystem:isComponentVisible(name)
    return visibleComponents[name] == true
end

-- Update a component's data
function UISystem:updateComponent(name, data)
    local component = components[name]
    if not component then
        warn("Component not found:", name)
        return false
    end
    
    if component.update then
        component:update(data)
    end
    
    return true
end

-- Show a modal dialog
function UISystem:showModal(options)
    return UIManager:showModal(options)
end

-- Hide a modal dialog
function UISystem:hideModal(modal)
    return UIManager:hideModal(modal)
end

-- Hide all components
function UISystem:hideAllComponents()
    for name, _ in pairs(visibleComponents) do
        self:hideComponent(name)
    end
    return true
end

-- Close all modals
function UISystem:closeAllModals()
    return UIManager:closeAllModals()
end

-- Shutdown the system
function UISystem:shutdown()
    -- Hide all components
    self:hideAllComponents()
    
    -- Close all modals
    self:closeAllModals()
    
    -- Clear component registry
    components = {}
    visibleComponents = {}
    
    return true
end

return UISystem
