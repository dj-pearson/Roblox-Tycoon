--!strict
--[[
    ClientRegistry.luau
    
    A central registry for client-side systems and UI components.
    
    Created: April 25, 2025
    
    This module:
    1. Provides a central access point for client systems
    2. Manages dependencies between systems
    3. Handles initialization order
    4. Creates fallbacks for missing components
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Constants
local IsClient = RunService:IsClient()
local IsStudio = RunService:IsStudio()
local LocalPlayer = Players.LocalPlayer

-- Find shared folder
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
if not sharedFolder then
    sharedFolder = Instance.new("Folder")
    sharedFolder.Name = "shared"
    sharedFolder.Parent = ReplicatedStorage
    print("[ClientRegistry] Created shared folder in ReplicatedStorage")
end

-- Safe require utility
local function requireSafely(module)
    if not module then
        return nil
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        warn("[ClientRegistry] Failed to require module: ", module:GetFullName())
        return nil
    end
    
    return result
end

-- Try to get the ModuleLoader
local ModuleLoader = requireSafely(sharedFolder:FindFirstChild("ModuleLoader"))
if not ModuleLoader then
    warn("[ClientRegistry] ModuleLoader not found, using direct requires")
end

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    USE_FALLBACKS = true,
    AUTO_INITIALIZE = false
}

-- ClientRegistry Module
local ClientRegistry = {
    systems = {},
    uiComponents = {},
    initialized = false,
    systemDependencies = {},
    moduleLoader = ModuleLoader
}

-- Debug logging
function ClientRegistry.log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[ClientRegistry] " .. message)
    end
end

-- Register a client-side system
function ClientRegistry.registerSystem(systemName, system)
    if ClientRegistry.systems[systemName] then
        ClientRegistry.log("System already registered: " .. systemName)
        return false
    end
    
    ClientRegistry.log("Registering system: " .. systemName)
    ClientRegistry.systems[systemName] = system
    
    -- Call initialize if it exists and we're set to auto-initialize
    if CONFIG.AUTO_INITIALIZE and system.initialize and typeof(system.initialize) == "function" then
        ClientRegistry.log("Auto-initializing system: " .. systemName)
        system:initialize(ClientRegistry)
    end
    
    return true
end

-- Get a registered system
function ClientRegistry.getSystem(systemName)
    local system = ClientRegistry.systems[systemName]
    
    if not system and CONFIG.USE_FALLBACKS then
        -- Try to load the system from ModuleLoader
        if ModuleLoader then
            system = ModuleLoader.tryRequire(systemName)
            if system then
                ClientRegistry.log("Lazy-loaded system: " .. systemName)
                ClientRegistry.registerSystem(systemName, system)
                return system
            end
        end
        
        -- Create a simple fallback system
        ClientRegistry.log("Creating fallback system: " .. systemName)
        system = {
            name = systemName,
            isFallback = true,
            initialize = function() return true end,
            getStatus = function() return "fallback" end
        }
        
        ClientRegistry.registerSystem(systemName, system)
    end
    
    return system
end

-- Register a UI component
function ClientRegistry.registerUIComponent(componentName, component)
    if ClientRegistry.uiComponents[componentName] then
        ClientRegistry.log("UI component already registered: " .. componentName)
        return false
    end
    
    ClientRegistry.log("Registering UI component: " .. componentName)
    ClientRegistry.uiComponents[componentName] = component
    return true
end

-- Get a UI component
function ClientRegistry.getUIComponent(componentName)
    local component = ClientRegistry.uiComponents[componentName]
    
    if not component and CONFIG.USE_FALLBACKS then
        -- Try to load the component from ModuleLoader
        if ModuleLoader then
            component = ModuleLoader.tryRequire(componentName)
            if component then
                ClientRegistry.log("Lazy-loaded UI component: " .. componentName)
                ClientRegistry.registerUIComponent(componentName, component)
                return component
            end
        end
        
        -- Create a simple fallback component
        ClientRegistry.log("Creating fallback UI component: " .. componentName)
        component = {
            name = componentName,
            isFallback = true,
            initialize = function() return true end
        }
        
        -- Special handling for common UI components
        if componentName == "UIStyle" then
            component.Colors = {
                Background = Color3.fromRGB(40, 40, 60),
                BackgroundLight = Color3.fromRGB(60, 60, 80),
                BackgroundDark = Color3.fromRGB(30, 30, 45),
                ButtonDefault = Color3.fromRGB(60, 60, 80),
                ButtonHover = Color3.fromRGB(70, 70, 90),
                Text = Color3.fromRGB(240, 240, 255),
                TextSecondary = Color3.fromRGB(180, 180, 200),
                Danger = Color3.fromRGB(220, 50, 50),
                Success = Color3.fromRGB(40, 180, 100),
                Warning = Color3.fromRGB(255, 190, 0),
                Info = Color3.fromRGB(80, 170, 240)
            }
        elseif componentName == "IconSet" then
            component.createIcon = function() return Instance.new("ImageLabel") end
            component.getIconId = function() return "" end
        elseif componentName == "ButtonFactory" then
            component.createButton = function() return Instance.new("TextButton") end
            component.createIconButton = function() return Instance.new("TextButton") end
            component.createCloseButton = function() return Instance.new("TextButton") end
        elseif componentName == "DialogFactory" then
            component.createNotification = function() return end
            component.createMessageDialog = function() return end
            component.createConfirmDialog = function() return end
        end
        
        ClientRegistry.registerUIComponent(componentName, component)
    end
    
    return component
end

-- Set a system dependency
function ClientRegistry.setSystemDependency(systemName, dependencyName)
    if not ClientRegistry.systemDependencies[systemName] then
        ClientRegistry.systemDependencies[systemName] = {}
    end
    
    table.insert(ClientRegistry.systemDependencies[systemName], dependencyName)
    ClientRegistry.log("Added dependency: " .. systemName .. " depends on " .. dependencyName)
    
    return true
end

-- Initialize a system and its dependencies
function ClientRegistry.initializeSystem(systemName)
    local system = ClientRegistry.getSystem(systemName)
    if not system then
        warn("[ClientRegistry] Cannot initialize system (not found): " .. systemName)
        return false
    end
    
    -- Check if system is already initialized
    if system.initialized then
        ClientRegistry.log("System already initialized: " .. systemName)
        return true
    end
    
    -- Initialize dependencies first
    local dependencies = ClientRegistry.systemDependencies[systemName] or {}
    for _, dependencyName in ipairs(dependencies) do
        local success = ClientRegistry.initializeSystem(dependencyName)
        if not success then
            warn("[ClientRegistry] Failed to initialize dependency: " .. dependencyName .. " for system: " .. systemName)
            return false
        end
    end
    
    -- Initialize the system
    if system.initialize and typeof(system.initialize) == "function" then
        ClientRegistry.log("Initializing system: " .. systemName)
        local success, result = pcall(function()
            return system:initialize(ClientRegistry)
        end)
        
        if success then
            system.initialized = true
            ClientRegistry.log("System initialized: " .. systemName)
            return true
        else
            warn("[ClientRegistry] Failed to initialize system: " .. systemName .. " - " .. tostring(result))
            return false
        end
    else
        ClientRegistry.log("System does not have initialize method: " .. systemName)
        system.initialized = true
        return true
    end
end

-- Initialize all registered systems
function ClientRegistry.initializeAllSystems()
    ClientRegistry.log("Initializing all systems")
    
    local initializedCount = 0
    local failedCount = 0
    
    for systemName, _ in pairs(ClientRegistry.systems) do
        local success = ClientRegistry.initializeSystem(systemName)
        if success then
            initializedCount += 1
        else
            failedCount += 1
        end
    end
    
    ClientRegistry.log("Initialization complete: " .. initializedCount .. " systems initialized, " .. failedCount .. " failed")
    return initializedCount, failedCount
end

-- Get the UI Style module
function ClientRegistry.getUIStyle()
    return ClientRegistry.getUIComponent("UIStyle")
end

-- Get the Icon Set module
function ClientRegistry.getIconSet()
    return ClientRegistry.getUIComponent("IconSet")
end

-- Get the Button Factory module
function ClientRegistry.getButtonFactory()
    return ClientRegistry.getUIComponent("ButtonFactory")
end

-- Get the Dialog Factory module
function ClientRegistry.getDialogFactory()
    return ClientRegistry.getUIComponent("DialogFactory")
end

-- Initialize the registry
function ClientRegistry.initialize()
    if ClientRegistry.initialized then
        return true
    end
    
    ClientRegistry.log("Initializing ClientRegistry")
    
    -- Register this module in global context for easier accessibility
    if _G then
        _G.ClientRegistry = ClientRegistry
        ClientRegistry.log("Registered in global context (_G)")
    end
    
    -- Register core UI components
    local UIComponents = requireSafely(sharedFolder:FindFirstChild("UIComponents"))
    if UIComponents then
        ClientRegistry.log("Found UIComponents, registering UI components")
        
        -- Register core UI components if they exist
        if UIComponents.UIStyle then
            ClientRegistry.registerUIComponent("UIStyle", UIComponents.UIStyle)
        end
        
        if UIComponents.IconSet then
            ClientRegistry.registerUIComponent("IconSet", UIComponents.IconSet)
        end
        
        if UIComponents.ButtonFactory then
            ClientRegistry.registerUIComponent("ButtonFactory", UIComponents.ButtonFactory)
        end
        
        if UIComponents.DialogFactory then
            ClientRegistry.registerUIComponent("DialogFactory", UIComponents.DialogFactory)
        end
        
        -- Call the registration function if it exists
        if UIComponents.registerWithClientRegistry then
            UIComponents.registerWithClientRegistry(ClientRegistry)
        end
    else
        -- Try to load individual UI components
        local UIStyle = requireSafely(sharedFolder:FindFirstChild("UIStyle"))
        if UIStyle then
            ClientRegistry.registerUIComponent("UIStyle", UIStyle)
        end
        
        local IconSet = requireSafely(sharedFolder:FindFirstChild("IconSet"))
        if IconSet then
            ClientRegistry.registerUIComponent("IconSet", IconSet)
        end
        
        local ButtonFactory = requireSafely(sharedFolder:FindFirstChild("ButtonFactory"))
        if ButtonFactory then
            ClientRegistry.registerUIComponent("ButtonFactory", ButtonFactory)
        end
        
        local DialogFactory = requireSafely(sharedFolder:FindFirstChild("DialogFactory"))
        if DialogFactory then
            ClientRegistry.registerUIComponent("DialogFactory", DialogFactory)
        end
    end
    
    -- Try to find and register common systems
    if ModuleLoader then
        -- Look for essential systems
        local essentialSystems = {
            "UIManager", 
            "DataManager", 
            "NotificationManager", 
            "InputManager"
        }
        
        for _, systemName in ipairs(essentialSystems) do
            local system = ModuleLoader.tryRequire(systemName)
            if system then
                ClientRegistry.registerSystem(systemName, system)
            end
        end
    end
    
    ClientRegistry.initialized = true
    ClientRegistry.log("ClientRegistry initialized successfully")
    
    return true
end

-- Hook for Studio hot-reloading
if IsStudio and IsClient and ClientRegistry.initialized then
    print("[ClientRegistry] Hot-reload detected, refreshing registry")
    -- Refresh registrations on hot reload
    for systemName, system in pairs(ClientRegistry.systems) do
        -- If the system is new and not already in the global registry, add it
        if _G.ClientRegistry and not _G.ClientRegistry.systems[systemName] then
            _G.ClientRegistry.registerSystem(systemName, system)
        end
    end
    
    for componentName, component in pairs(ClientRegistry.uiComponents) do
        -- If the component is new and not already in the global registry, add it
        if _G.ClientRegistry and not _G.ClientRegistry.uiComponents[componentName] then
            _G.ClientRegistry.registerUIComponent(componentName, component)
        end
    end
end

-- Auto-initialize based on configuration
if CONFIG.AUTO_INITIALIZE then
    ClientRegistry.initialize()
end

return ClientRegistry
