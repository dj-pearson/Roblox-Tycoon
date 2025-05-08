--!strict
--[[
    UIComponents.server.luau
    
    Core system for managing UI components on the server.
    This module handles UI component registration, validation, and server-side UI logic.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Fixed initialization and CoreRegistry integration
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Get CoreRegistry
local CoreRegistry
local success, result = pcall(function()
    return require(script.Parent.CoreRegistry)
end)
if success then
    CoreRegistry = result
end

local UIComponents = {}
UIComponents.initialized = false

-- Configuration
local CONFIG = {
    DEBUG = true,
    COMPONENT_FOLDER_NAME = "UIComponents",
    VALIDATE_COMPONENTS = true,
    AUTO_REGISTER = true
}

-- Component registry
local registeredComponents = {}

-- Log a message to the output
local function log(message)
    if CONFIG.DEBUG then
        print("[UIComponents] " .. message)
    end
end

-- Initialize the UI components system
function UIComponents:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing UIComponents...")
    
    -- Create UI components folder in ReplicatedStorage if it doesn't exist
    local uiFolder = ReplicatedStorage:FindFirstChild(CONFIG.COMPONENT_FOLDER_NAME)
    if not uiFolder then
        uiFolder = Instance.new("Folder")
        uiFolder.Name = CONFIG.COMPONENT_FOLDER_NAME
        uiFolder.Parent = ReplicatedStorage
        log("Created UI components folder in ReplicatedStorage")
    end
    
    -- Register with CoreRegistry
    if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
        CoreRegistry:registerSystem("UIComponents", self)
        log("Registered with CoreRegistry")
        
        -- Mark as initialized in CoreRegistry
        if typeof(CoreRegistry.markInitialized) == "function" then
            CoreRegistry:markInitialized("UIComponents")
            log("Marked as initialized in CoreRegistry")
        end
    else
        log("CoreRegistry not found, but UIComponents will still function")
    end
    
    self.initialized = true
    log("UIComponents initialized successfully")
    return true
end

-- Register a UI component
function UIComponents:registerComponent(name, component)
    if not name or typeof(name) ~= "string" then
        warn("[UIComponents] Invalid component name")
        return false
    end
    
    if not component then
        warn("[UIComponents] Cannot register nil component: " .. name)
        return false
    end
    
    registeredComponents[name] = component
    log("Registered component: " .. name)
    return true
end

-- Get a registered component
function UIComponents:getComponent(name)
    return registeredComponents[name]
end

-- Get all registered components
function UIComponents:getComponents()
    local components = {}
    for name, component in pairs(registeredComponents) do
        components[name] = component
    end
    return components
end

-- Validate a component
function UIComponents:validateComponent(component)
    if not component then
        return false
    end
    
    -- Check for required methods
    local requiredMethods = {
        "initialize",
        "show",
        "hide",
        "update"
    }
    
    for _, method in ipairs(requiredMethods) do
        if typeof(component[method]) ~= "function" then
            warn("[UIComponents] Component missing required method: " .. method)
            return false
        end
    end
    
    return true
end

-- Check if a component is registered
function UIComponents:hasComponent(name)
    return registeredComponents[name] ~= nil
end

-- Get component count
function UIComponents:getComponentCount()
    local count = 0
    for _ in pairs(registeredComponents) do
        count = count + 1
    end
    return count
end

-- Get configuration
function UIComponents:getConfig()
    return CONFIG
end

-- Check if initialized
function UIComponents:isInitialized()
    return self.initialized
end

return UIComponents 