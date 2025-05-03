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

-- Register a component with enhanced validation and compatibility
function UIRegistry.registerComponent(id, component)
    if not id or type(id) ~= "string" then
        warn("[UIRegistry] Invalid component ID")
        return false
    end
    
    if not component then
        warn("[UIRegistry] Component is nil")
        return false
    end
    
    -- Check if this is a UI module with standard interface
    local isUIModule = false
    if typeof(component) == "table" then
        local hasToggleUI = typeof(component.ToggleUI) == "function"
        local hasShowUI = typeof(component.ShowUI) == "function" 
        local hasHideUI = typeof(component.HideUI) == "function"
        
        if hasToggleUI or (hasShowUI and hasHideUI) then
            isUIModule = true
            log("Detected UI module interface for component: " .. id, "Success")
        end
    end
    
    -- Store component with metadata
    UIRegistry.components[id] = {
        instance = component,
        isUIModule = isUIModule,
        registeredAt = os.time()
    }
    
    -- For compatibility with shared UIRegistry
    -- Also register using alternative naming convention
    local altId = id:gsub("UI$", "")  -- Remove UI suffix if present
    if altId ~= id then
        UIRegistry.components[altId] = UIRegistry.components[id]
        log("Also registered under alternative ID: " .. altId)
    end
    
    log("Registered UI component: " .. id, "Success")
    return true
end

-- Get a registered component with enhanced lookup
function UIRegistry.getComponent(id)
    -- Direct lookup
    if UIRegistry.components[id] then
        return UIRegistry.components[id].instance or UIRegistry.components[id]
    end
    
    -- Try alternatives if not found
    local alternatives = {
        id .. "UI",              -- Add UI suffix
        id:gsub("UI$", ""),      -- Remove UI suffix
        id:gsub("Menu$", ""),    -- Remove Menu suffix
        id:gsub("Menu$", "UI"),  -- Replace Menu with UI
        id:gsub("^UI", ""),      -- Remove UI prefix
        "UI" .. id               -- Add UI prefix
    }
    
    for _, altId in ipairs(alternatives) do
        if UIRegistry.components[altId] then
            log("Found component " .. id .. " under alternative ID: " .. altId)
            return UIRegistry.components[altId].instance or UIRegistry.components[altId]
        end
    end
    
    -- Not found after all attempts
    log("Component not found: " .. id, "Warning")
    return nil
end

-- Initialize the registry
function UIRegistry.initialize()
    log("UIRegistry initialized successfully")
    
    -- Ensure transitions are properly configured
    UIRegistry.transitions = {
        defaultTransition = "fade",
        defaultDuration = 0.3,
        enabled = true
    }
    
    return true
end

-- Initialize on module load
UIRegistry.initialize()

return UIRegistry