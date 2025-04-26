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

-- Safe require utility
local function requireSafely(module)
    if not module then
        return nil
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        warn("[ClientRegistry] Failed to require module: " .. tostring(module:GetFullName()))
        return nil
    end
    
    return result
end

-- Find shared folder
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
if not sharedFolder then
    sharedFolder = Instance.new("Folder")
    sharedFolder.Name = "shared"
    sharedFolder.Parent = ReplicatedStorage
    print("[ClientRegistry] Created shared folder in ReplicatedStorage")
end

-- Try to get the ModuleLoader
local ModuleLoader = requireSafely(sharedFolder:FindFirstChild("ModuleLoader"))
if not ModuleLoader then
    print("[ClientRegistry] ModuleLoader not found, using direct requires")
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
        ClientRegistry.log("Warning: System '" .. systemName .. "' already registered, overwriting")
    end
    
    ClientRegistry.systems[systemName] = system
    ClientRegistry.log("Registered system: " .. systemName)
    return system
end

-- Register UI component
function ClientRegistry.registerUIComponent(componentName, component)
    if ClientRegistry.uiComponents[componentName] then
        ClientRegistry.log("Warning: UI component '" .. componentName .. "' already registered, overwriting")
    end
    
    ClientRegistry.uiComponents[componentName] = component
    ClientRegistry.log("Registered UI component: " .. componentName)
    return component
end

-- Get a system by name
function ClientRegistry.getSystem(systemName)
    local system = ClientRegistry.systems[systemName]
    
    -- If not found, try to load it
    if not system and ModuleLoader then
        local loadedSystem = ModuleLoader.tryRequire(systemName)
        if loadedSystem then
            ClientRegistry.registerSystem(systemName, loadedSystem)
            return loadedSystem
        end
    end
    
    return system
end

-- Get a UI component by name
function ClientRegistry.getUIComponent(componentName)
    local component = ClientRegistry.uiComponents[componentName]
    
    -- If not found, try to load it
    if not component and ModuleLoader then
        local loadedComponent = ModuleLoader.tryRequire(componentName)
        if loadedComponent then
            ClientRegistry.registerUIComponent(componentName, loadedComponent)
            return loadedComponent
        end
    end
    
    -- If still not found, try fallbacks for common components
    if not component and CONFIG.USE_FALLBACKS then
        if componentName == "UIStyle" then
            ClientRegistry.log("Creating fallback UIStyle")
            local fallbackStyle = {
                colors = {
                    background = Color3.fromRGB(40, 40, 60),
                    backgroundLight = Color3.fromRGB(60, 60, 80),
                    backgroundDark = Color3.fromRGB(30, 30, 45),
                    accent = Color3.fromRGB(80, 150, 255),
                    text = Color3.fromRGB(240, 240, 255),
                    textDimmed = Color3.fromRGB(180, 180, 200)
                },
                fonts = {
                    header = Enum.Font.GothamBold,
                    body = Enum.Font.Gotham,
                    button = Enum.Font.GothamMedium
                },
                padding = {
                    small = UDim.new(0, 4),
                    medium = UDim.new(0, 8),
                    large = UDim.new(0, 12)
                },
                cornerRadius = {
                    small = UDim.new(0, 4),
                    medium = UDim.new(0, 8),
                    large = UDim.new(0, 12)
                }
            }
            ClientRegistry.registerUIComponent("UIStyle", fallbackStyle)
            return fallbackStyle
        end
        
        if componentName == "IconSet" then
            ClientRegistry.log("Creating fallback IconSet")
            local fallbackIcons = {
                close = "rbxassetid://8093755787",
                settings = "rbxassetid://8093754726",
                info = "rbxassetid://8093754900",
                warning = "rbxassetid://8093755364"
            }
            ClientRegistry.registerUIComponent("IconSet", fallbackIcons)
            return fallbackIcons
        end
    end
    
    return component
end

-- Initialize a specific system
function ClientRegistry.initializeSystem(systemName)
    local system = ClientRegistry.getSystem(systemName)
    
    if not system then
        ClientRegistry.log("Cannot initialize system - " .. systemName .. " not found")
        return false
    end
    
    if typeof(system.initialize) == "function" then
        local success, result = pcall(function()
            return system:initialize()
        end)
        
        if success then
            ClientRegistry.log("System initialized: " .. systemName)
            return true
        else
            ClientRegistry.log("Failed to initialize system " .. systemName .. ": " .. tostring(result))
            return false
        end
    else
        ClientRegistry.log("System " .. systemName .. " has no initialize method")
        return false
    end
end

-- Initialize the registry
function ClientRegistry.initialize()
    if ClientRegistry.initialized then
        ClientRegistry.log("Already initialized, skipping")
        return
    end
    
    ClientRegistry.log("Initializing ClientRegistry...")
    
    -- Try to load UIComponents module first to get UI components
    local UIComponents = nil
    
    -- First try find in shared folder
    if sharedFolder:FindFirstChild("UIComponents") then
        UIComponents = requireSafely(sharedFolder.UIComponents)
    end
    
    -- If that fails, try ModuleLoader
    if not UIComponents and ModuleLoader then
        UIComponents = ModuleLoader.tryRequire("UIComponents")
    end
    
    -- If UIComponents found, register its components
    if UIComponents then
        ClientRegistry.log("Loading UI components from UIComponents module")
        
        -- Register all components if UIComponents exports them as a map
        if type(UIComponents.components) == "table" then
            for name, component in pairs(UIComponents.components) do
                ClientRegistry.registerUIComponent(name, component)
            end
        end
        
        -- Register individual components if exposed directly
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
    ClientRegistry.log("ClientRegistry initialization complete")
end

-- Initialize the ClientRegistry if AUTO_INITIALIZE is true
if CONFIG.AUTO_INITIALIZE then
    ClientRegistry.initialize()
end

return ClientRegistry
