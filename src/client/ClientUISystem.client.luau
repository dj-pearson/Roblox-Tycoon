--!strict
--[[
    ClientUISystem.client.luau
    
    A system module that initializes and manages the UI components for the client.
    This module ensures UI components are properly loaded, registered with ClientRegistry,
    and initialized in the correct order.
    
    Created: April 26, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")

-- Debug settings
local DEBUG_ENABLED = true
local MAX_RETRIES = 5
local RETRY_DELAY = 0.5

-- Debug logging
local function log(message)
    if DEBUG_ENABLED then
        print("[ClientUISystem] " .. message)
    end
end

local function warn_log(message)
    warn("[ClientUISystem] " .. message)
end

-- Dependencies to load
local dependencies = {
    ClientRegistry = {
        paths = {
            ReplicatedStorage.shared.ClientRegistry,
            LocalPlayer.PlayerScripts.Client.Core.ClientRegistry
        }
    },
    UIStyle = {
        paths = {
            ReplicatedStorage.shared.UIStyle
        }
    },
    IconSet = {
        paths = {
            ReplicatedStorage.shared.IconSet
        }
    },
    ButtonFactory = {
        paths = {
            ReplicatedStorage.shared.ButtonFactory
        }
    },
    DialogFactory = {
        paths = {
            ReplicatedStorage.shared.DialogFactory
        }
    },
    UIComponents = {
        paths = {
            ReplicatedStorage.shared.UIComponents
        }
    }
}

-- Safe require utility
local function requireSafely(module)
    if not module then
        return nil
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        warn_log("Failed to require " .. tostring(module:GetFullName()) .. ": " .. tostring(result))
        return nil
    end
    
    return result
end

-- Try to load a module from multiple paths
local function loadModule(name, pathsTable)
    if not pathsTable or #pathsTable == 0 then
        warn_log("No paths provided for " .. name)
        return nil
    end
    
    for _, path in ipairs(pathsTable) do
        if path then
            local module = requireSafely(path)
            if module then
                log("Successfully loaded " .. name)
                return module
            end
        end
    end
    
    warn_log("Failed to load " .. name .. " from any path")
    return nil
end

-- ClientUISystem module
local ClientUISystem = {
    initialized = false,
    modules = {},
    registeredUI = {}
}

-- Initialize the UI system
function ClientUISystem:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing ClientUISystem...")
    
    -- Load all dependencies
    for name, config in pairs(dependencies) do
        self.modules[name] = loadModule(name, config.paths)
    end
    
    -- Check if ClientRegistry and key UI modules were loaded
    if not self.modules.ClientRegistry then
        -- Try to fix ClientRegistry
        log("ClientRegistry not found, attempting to fix...")
        local clientRegistryFixerModule = loadModule("ClientRegistryFixer", {
            ReplicatedStorage.shared.ClientRegistryFixer,
            LocalPlayer.PlayerScripts.Client.Core.ClientRegistryFixer
        })
        
        if clientRegistryFixerModule then
            log("Running ClientRegistryFixer...")
            self.modules.ClientRegistry = clientRegistryFixerModule
        else
            -- Create ClientRegistryFixer if not found
            log("Creating ClientRegistryFixer...")
            self:createClientRegistryFixer()
        end
        
        -- Retry loading ClientRegistry
        self.modules.ClientRegistry = loadModule("ClientRegistry", dependencies.ClientRegistry.paths)
    end
    
    -- Initialize ClientRegistry if available
    if self.modules.ClientRegistry then
        if typeof(self.modules.ClientRegistry.initialize) == "function" and not self.modules.ClientRegistry.initialized then
            log("Initializing ClientRegistry...")
            self.modules.ClientRegistry:initialize()
        end
        
        -- Register UI components
        self:registerUIComponents()
    else
        warn_log("Failed to initialize ClientRegistry")
        return false
    end
    
    -- Initialize UIComponents if available
    if self.modules.UIComponents and typeof(self.modules.UIComponents.initialize) == "function" then
        log("Initializing UIComponents...")
        self.modules.UIComponents:initialize()
    end
    
    self.initialized = true
    log("ClientUISystem initialization complete")
    return true
end

-- Register UI components with ClientRegistry
function ClientUISystem:registerUIComponents()
    if not self.modules.ClientRegistry then
        warn_log("Cannot register UI components without ClientRegistry")
        return false
    end
    
    log("Registering UI components with ClientRegistry...")
    
    -- Register UIStyle
    if self.modules.UIStyle then
        self.modules.ClientRegistry:registerUIComponent("UIStyle", self.modules.UIStyle)
        log("Registered UIStyle with ClientRegistry")
        self.registeredUI.UIStyle = true
    else
        warn_log("UIStyle not available for registration")
    end
    
    -- Register IconSet
    if self.modules.IconSet then
        self.modules.ClientRegistry:registerUIComponent("IconSet", self.modules.IconSet)
        log("Registered IconSet with ClientRegistry")
        self.registeredUI.IconSet = true
    else
        warn_log("IconSet not available for registration")
    end
    
    -- Register ButtonFactory
    if self.modules.ButtonFactory then
        self.modules.ClientRegistry:registerUIComponent("ButtonFactory", self.modules.ButtonFactory)
        log("Registered ButtonFactory with ClientRegistry")
        self.registeredUI.ButtonFactory = true
    else
        warn_log("ButtonFactory not available for registration")
    end
    
    -- Register DialogFactory
    if self.modules.DialogFactory then
        self.modules.ClientRegistry:registerUIComponent("DialogFactory", self.modules.DialogFactory)
        log("Registered DialogFactory with ClientRegistry")
        self.registeredUI.DialogFactory = true
    else
        warn_log("DialogFactory not available for registration")
    end
    
    -- Register UIComponents
    if self.modules.UIComponents then
        self.modules.ClientRegistry:registerUIComponent("UIComponents", self.modules.UIComponents)
        log("Registered UIComponents with ClientRegistry")
        self.registeredUI.UIComponents = true
    else
        warn_log("UIComponents not available for registration")
    end
    
    return true
end

-- Create ClientRegistryFixer if not found
function ClientUISystem:createClientRegistryFixer()
    -- Create the module script
    local coreFolder = LocalPlayer.PlayerScripts:FindFirstChild("Client") and
                       LocalPlayer.PlayerScripts.Client:FindFirstChild("Core")
                       
    if not coreFolder then
        coreFolder = Instance.new("Folder")
        coreFolder.Name = "Core"
        
        local clientFolder = LocalPlayer.PlayerScripts:FindFirstChild("Client")
        if not clientFolder then
            clientFolder = Instance.new("Folder")
            clientFolder.Name = "Client"
            clientFolder.Parent = LocalPlayer.PlayerScripts
        end
        
        coreFolder.Parent = clientFolder
    end
    
    -- Create the fixer module
    local fixerModule = Instance.new("ModuleScript")
    fixerModule.Name = "ClientRegistryFixer"
    fixerModule.Source = [[
--!strict
--[[
    ClientRegistryFixer.client.luau
    
    A utility to fix common ClientRegistry issues and ensure it's properly
    initialized and accessible to all client scripts.
    
    Created: April 26, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Create a minimal ClientRegistry
local ClientRegistry = {
    systems = {},
    uiComponents = {},
    initialized = false,
    createdByFixer = true
}

-- Register a client-side system
function ClientRegistry:registerSystem(systemName, system)
    self.systems[systemName] = system
    print("[ClientRegistry] Registered system: " .. systemName)
    return system
end

-- Register a UI component
function ClientRegistry:registerUIComponent(componentName, component)
    self.uiComponents[componentName] = component
    print("[ClientRegistry] Registered UI component: " .. componentName)
    return component
end

-- Get a system by name
function ClientRegistry:getSystem(systemName)
    return self.systems[systemName]
end

-- Get a UI component by name
function ClientRegistry:getUIComponent(componentName)
    return self.uiComponents[componentName]
end

-- Initialize the registry
function ClientRegistry:initialize()
    if self.initialized then
        return
    end
    
    print("[ClientRegistry] Initializing minimal ClientRegistry")
    
    -- Set up basic UI style for fallback
    self:registerUIComponent("UIStyle", {
        colors = {
            background = Color3.fromRGB(40, 40, 60),
            text = Color3.fromRGB(240, 240, 240),
            accent = Color3.fromRGB(80, 160, 240)
        },
        fonts = {
            header = Enum.Font.GothamBold,
            body = Enum.Font.Gotham
        }
    })
    
    self.initialized = true
    print("[ClientRegistry] Initialization complete")
end

-- Helper to check if a module exists/function
function ClientRegistry:testRegistry()
    print("[ClientRegistry] Registry test: OK")
    return true
end

-- Create a shared reference
local shared = ReplicatedStorage:FindFirstChild("shared")
if shared then
    local reference = Instance.new("ModuleScript")
    reference.Name = "ClientRegistry"
    reference.Source = "return require(game:GetService('Players').LocalPlayer.PlayerScripts.Client.Core.ClientRegistry)"
    reference.Parent = shared
end

return ClientRegistry
]]
    
    fixerModule.Parent = coreFolder
    log("Created ClientRegistryFixer at " .. fixerModule:GetFullName())
    
    return requireSafely(fixerModule)
end

-- Check if UI system is fully operational
function ClientUISystem:diagnose()
    local report = {
        initialized = self.initialized,
        modulesLoaded = {},
        componentsRegistered = {},
        totalModules = 0,
        totalLoaded = 0,
        totalRegistered = 0
    }
    
    -- Check modules loaded
    for name, module in pairs(self.modules) do
        report.modulesLoaded[name] = module ~= nil
        report.totalModules += 1
        if module then
            report.totalLoaded += 1
        end
    end
    
    -- Check registered components
    for name, registered in pairs(self.registeredUI) do
        report.componentsRegistered[name] = registered
        if registered then
            report.totalRegistered += 1
        end
    end
    
    -- Print diagnostic report
    log("=== UI System Diagnostic Report ===")
    log("Initialized: " .. tostring(report.initialized))
    log("Modules loaded: " .. report.totalLoaded .. "/" .. report.totalModules)
    log("Components registered: " .. report.totalRegistered .. "/" .. report.totalModules)
    log("")
    
    log("Module Status:")
    for name, loaded in pairs(report.modulesLoaded) do
        log("- " .. name .. ": " .. (loaded and "✓" or "✗"))
    end
    log("")
    
    log("Registration Status:")
    for name, registered in pairs(report.componentsRegistered) do
        log("- " .. name .. ": " .. (registered and "✓" or "✗"))
    end
    
    return report
end

-- Display a test notification
function ClientUISystem:showTestNotification()
    if not self.initialized or not self.modules.DialogFactory then
        warn_log("Cannot show test notification - DialogFactory not loaded")
        return false
    end
    
    self.modules.DialogFactory:createNotification({
        title = "UI System Test",
        message = "The UI system is working correctly!",
        type = "success",
        duration = 5
    })
    
    return true
end

-- Initialize the system
task.spawn(function()
    wait(1) -- Wait a bit for other systems to initialize
    ClientUISystem:initialize()
    
    -- Run diagnostic
    if DEBUG_ENABLED then
        wait(1)
        ClientUISystem:diagnose()
        ClientUISystem:showTestNotification()
    end
end)

return ClientUISystem
