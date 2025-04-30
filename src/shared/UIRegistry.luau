-- UIRegistry.luau
-- Registry for UI components and styles that avoids global variable usage
-- Created: May 2, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Registry container
local UIRegistry = {
    Version = "1.0.0",
    IsLoaded = true,
    Components = {},     -- Stores UI components
    Styles = {},         -- Stores UI styles
    GlobalConfig = {},   -- Stores global configuration
}

-- Private cache to avoid global variables
local componentCache = {}
local styleCache = {}
local configCache = {}
local instanceCache = {}

-- Find a module by name
local function findModule(moduleName)
    -- Search paths
    local searchPaths = {
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
    }
    
    -- Look in each path
    for _, path in ipairs(searchPaths) do
        if path then
            local moduleScript = path:FindFirstChild(moduleName)
            if moduleScript and moduleScript:IsA("ModuleScript") then
                return moduleScript
            end
        end
    end
    
    return nil
end

-- Try to load module
local function tryRequire(moduleScript)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        return nil
    end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if success then
        return result
    else
        warn("[UIRegistry] Failed to load module: " .. moduleScript.Name .. " - " .. tostring(result))
        return nil
    end
end

-- Register a component with the registry
function UIRegistry.RegisterComponent(name, component)
    if not name or type(name) ~= "string" then
        warn("[UIRegistry] Invalid component name")
        return false
    end
    
    if not component then
        warn("[UIRegistry] Cannot register nil component: " .. name)
        return false
    end
    
    componentCache[name] = component
    UIRegistry.Components[name] = true -- We just store a flag for existence checking
    
    print("[UIRegistry] Registered component: " .. name)
    return true
end

-- Get a component from the registry
function UIRegistry.GetComponent(name)
    return componentCache[name]
end

-- Get all registered components
function UIRegistry.GetComponents()
    local result = {}
    for name, _ in pairs(UIRegistry.Components) do
        result[name] = componentCache[name]
    end
    return result
end

-- Register a style with the registry
function UIRegistry.RegisterStyle(name, style)
    if not name or type(name) ~= "string" then
        warn("[UIRegistry] Invalid style name")
        return false
    end
    
    if not style then
        warn("[UIRegistry] Cannot register nil style: " .. name)
        return false
    end
    
    styleCache[name] = style
    UIRegistry.Styles[name] = true -- We just store a flag for existence checking
    
    print("[UIRegistry] Registered style: " .. name)
    return true
end

-- Get a style from the registry
function UIRegistry.GetStyle(name)
    return styleCache[name]
end

-- Get all registered styles
function UIRegistry.GetStyles()
    local result = {}
    for name, _ in pairs(UIRegistry.Styles) do
        result[name] = styleCache[name]
    end
    return result
end

-- Set global configuration
function UIRegistry.SetConfig(name, value)
    configCache[name] = value
    UIRegistry.GlobalConfig[name] = true -- We just store a flag for existence checking
    
    return true
end

-- Get global configuration
function UIRegistry.GetConfig(name)
    return configCache[name]
end

-- Register a UI instance (actual UI elements)
function UIRegistry.RegisterUIInstance(name, instance)
    if not name or type(name) ~= "string" then
        warn("[UIRegistry] Invalid instance name")
        return false
    end
    
    if not instance then
        warn("[UIRegistry] Cannot register nil instance: " .. name)
        return false
    end
    
    instanceCache[name] = instance
    
    print("[UIRegistry] Registered UI instance: " .. name)
    return true
end

-- Get a UI instance from the registry
function UIRegistry.GetUIInstance(name)
    return instanceCache[name]
end

-- Clear all registrations
function UIRegistry.Clear()
    UIRegistry.Components = {}
    UIRegistry.Styles = {}
    UIRegistry.GlobalConfig = {}
    
    componentCache = {}
    styleCache = {}
    configCache = {}
    instanceCache = {}
    
    print("[UIRegistry] Registry cleared")
    return true
end

-- Load default components
function UIRegistry.LoadDefaults()
    print("[UIRegistry] Loading default components...")
    
    -- Try to load UIComponents
    local uiComponents = tryRequire(findModule("UIComponents"))
    if uiComponents then
        UIRegistry.RegisterComponent("UIComponents", uiComponents)
        
        -- Register components provided by UIComponents
        for name, component in pairs(uiComponents.GetComponents()) do
            UIRegistry.RegisterComponent(name, component)
        end
    end
    
    -- Try to load UIStyle
    local uiStyle = tryRequire(findModule("UIStyle"))
    if uiStyle then
        UIRegistry.RegisterStyle("Default", uiStyle)
    end
    
    -- Try to load AssetValidator
    local assetValidator = tryRequire(findModule("AssetValidator"))
    if assetValidator then
        UIRegistry.RegisterComponent("AssetValidator", assetValidator)
    end
    
    print("[UIRegistry] Default components loaded")
    return true
end

-- Initialize the module
function UIRegistry.Initialize()
    print("[UIRegistry] Initializing...")
    
    -- Load defaults
    UIRegistry.LoadDefaults()
    
    -- Try to register with ClientRegistry if available
    local clientRegistry = tryRequire(findModule("ClientRegistry"))
    if clientRegistry then
        if typeof(clientRegistry.Register) == "function" then
            clientRegistry:Register("UIRegistry", UIRegistry)
            print("[UIRegistry] Registered with ClientRegistry")
        else
            print("[UIRegistry] ClientRegistry found but no registration method available")
        end
    else
        print("[UIRegistry] ClientRegistry not found, but UIRegistry will still function")
    end
    
    print("[UIRegistry] Initialization complete")
    return true
end

-- Auto-initialize on load
task.spawn(function()
    UIRegistry.Initialize()
end)

return UIRegistry
