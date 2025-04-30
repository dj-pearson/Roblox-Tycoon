-- UIComponentLoader.client.luau
-- This script ensures that all UI components in the Screens folder are properly loaded and registered
-- Fix for UI components not showing up - April 28, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("UIComponentLoader: Starting...")

-- Function to find UI Registry
local function waitForRegistry()
    local registry
    local startTime = os.clock()
    local timeout = 10 -- seconds
    
    while not registry and os.clock() - startTime < timeout do
        -- Try to get registry from global
        if _G.UIRegistry then
            registry = _G.UIRegistry
            break
        end
        
        -- Try to find in client registry
        if _G.ClientRegistry and _G.ClientRegistry.getSystem then
            registry = _G.ClientRegistry:getSystem("UIRegistry")
            if registry then
                break
            end
        end
        
        task.wait(0.1)
    end
    
    return registry
end

-- Function to find UIManager
local function waitForUIManager()
    local manager
    local startTime = os.clock()
    local timeout = 10 -- seconds
    
    while not manager and os.clock() - startTime < timeout do
        -- Try to get manager from global
        if _G.UIManager then
            manager = _G.UIManager
            break
        end
        
        -- Try to find in registry
        local registry = waitForRegistry()
        if registry then
            manager = registry:getComponent("UIManager")
            if manager then
                break
            end
        end
        
        task.wait(0.1)
    end
    
    return manager
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
        warn("UIComponentLoader: Failed to require " .. modulePath:GetFullName() .. " - " .. tostring(result))
        return nil
    end
    
    return result
end

-- Find all UI components in the Screens folder
local function findUIComponents()
    local components = {}
    
    -- Find src path
    local srcFolder = ReplicatedStorage:FindFirstChild("src")
    if not srcFolder then
        warn("UIComponentLoader: src folder not found")
        return components
    end
    
    -- Find client path
    local clientFolder = srcFolder:FindFirstChild("client")
    if not clientFolder then
        warn("UIComponentLoader: client folder not found")
        return components
    end
    
    -- Find UI path
    local uiFolder = clientFolder:FindFirstChild("UI")
    if not uiFolder then
        warn("UIComponentLoader: UI folder not found")
        return components
    end
    
    -- Find Screens path
    local screensFolder = uiFolder:FindFirstChild("Screens")
    if not screensFolder then
        warn("UIComponentLoader: Screens folder not found")
        return components
    end
    
    print("UIComponentLoader: Found Screens folder")
    
    -- Get all modules in the Screens folder
    for _, child in ipairs(screensFolder:GetChildren()) do
        if child:IsA("ModuleScript") then
            local name = child.Name:gsub("%.luau$", ""):gsub("%.lua$", "")
            table.insert(components, {name = name, path = child})
        end
    end
    
    print("UIComponentLoader: Found " .. #components .. " UI component modules")
    return components
end

-- Load and initialize all UI components
local function loadUIComponents()
    local registry = waitForRegistry()
    if not registry then
        warn("UIComponentLoader: Could not find UIRegistry after timeout")
        return {}
    end
    
    print("UIComponentLoader: Found UIRegistry")
    
    local manager = waitForUIManager()
    if not manager then
        warn("UIComponentLoader: Could not find UIManager after timeout")
        -- Continue anyway as registry might be enough
    else
        print("UIComponentLoader: Found UIManager")
    end
    
    -- Find UI components
    local componentInfos = findUIComponents()
    local loadedComponents = {}
    
    -- Load each component
    for _, info in ipairs(componentInfos) do
        print("UIComponentLoader: Loading " .. info.name)
        
        -- Load the component module
        local component = requireSafely(info.path)        if not component then
            warn("UIComponentLoader: Failed to load " .. info.name)
            goto continue
        end
        
        -- Initialize the component if not already initialized
        if component.initialize and not component.isInitialized then
            pcall(function()
                component:initialize()
            end)
        end
        
        -- Register with registry
        if registry and registry.registerComponent then
            pcall(function()
                registry:registerComponent(info.name, component)
            end)
            print("UIComponentLoader: Registered " .. info.name .. " with UIRegistry")
        end
        
        -- Also register with manager
        if manager and manager.registerUI then
            pcall(function()
                manager:registerUI(info.name, component)
            end)
            print("UIComponentLoader: Registered " .. info.name .. " with UIManager")
        end
        
        -- Create global access point for emergency fallback
        _G[info.name] = component
        print("UIComponentLoader: Created global access point _G." .. info.name)
        
        -- Add to loaded components
        loadedComponents[info.name] = component
        
        ::continue::
    end
    
    return loadedComponents
end

-- Main execution
local loadedComponents = loadUIComponents()

-- Wait a moment for everything to initialize before attempting to show main menu
task.delay(2, function()
    -- Try to access UISystem
    local uiSystem
    
    if _G.UISystem then
        uiSystem = _G.UISystem
    elseif _G.ClientRegistry and _G.ClientRegistry.getSystem then
        uiSystem = _G.ClientRegistry:getSystem("UISystem")
    end
    
    if uiSystem and uiSystem.showMainMenu then
        print("UIComponentLoader: Attempting to show main menu via UISystem")
        uiSystem:showMainMenu()
    elseif loadedComponents["MainMenuUI"] and loadedComponents["MainMenuUI"].show then
        print("UIComponentLoader: Showing MainMenuUI directly")
        loadedComponents["MainMenuUI"]:show()
    end
end)

print("UIComponentLoader: Setup complete")
