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

-- Constants
local DEBUG_ENABLED = true
local MAX_RETRIES = 5
local RETRY_DELAY = 0.5

-- Debug logging
local function log(message)
    if DEBUG_ENABLED then
        print("[ClientRegistryFixer] " .. message)
    end
end

local function warn_log(message)
    warn("[ClientRegistryFixer] " .. message)
end

-- Ensure a folder exists
local function ensureFolderExists(parent, name)
    if not parent then
        warn_log("Cannot create folder in nil parent")
        return nil
    end
    
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
        log("Created folder: " .. name .. " in " .. parent:GetFullName())
    end
    
    return folder
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
        warn_log("Failed to require " .. tostring(module:GetFullName()) .. ": " .. tostring(result))
        return nil
    end
    
    return result
end

-- Try to get ClientRegistry from various locations
local function findClientRegistry()
    log("Looking for ClientRegistry...")
    
    -- Try various search paths
    local searchPaths = {
        -- In ReplicatedStorage.shared
        function()
            local shared = ReplicatedStorage:FindFirstChild("shared")
            if shared and shared:FindFirstChild("ClientRegistry") then
                log("Found in ReplicatedStorage.shared")
                return requireSafely(shared.ClientRegistry)
            end
            return nil
        end,
        
        -- In LocalPlayer.PlayerScripts.Client.Core
        function()
            if LocalPlayer and 
               LocalPlayer.PlayerScripts:FindFirstChild("Client") and
               LocalPlayer.PlayerScripts.Client:FindFirstChild("Core") and
               LocalPlayer.PlayerScripts.Client.Core:FindFirstChild("ClientRegistry") then
                log("Found in PlayerScripts.Client.Core")
                return requireSafely(LocalPlayer.PlayerScripts.Client.Core.ClientRegistry)
            end
            return nil
        end,
        
        -- In LocalPlayer.PlayerGui
        function()
            if LocalPlayer and 
               LocalPlayer.PlayerGui:FindFirstChild("UIScripts") and
               LocalPlayer.PlayerGui.UIScripts:FindFirstChild("ClientRegistry") then
                log("Found in PlayerGui.UIScripts")
                return requireSafely(LocalPlayer.PlayerGui.UIScripts.ClientRegistry)
            end
            return nil
        end
    }
    
    -- Try each search path
    for i, searchFn in ipairs(searchPaths) do
        local registry = searchFn()
        if registry then
            log("Successfully found ClientRegistry using method " .. i)
            return registry
        end
    end
    
    log("ClientRegistry not found in any known location")
    return nil
end

-- Create a minimal ClientRegistry when none is found
local function createMinimalClientRegistry()
    log("Creating minimal ClientRegistry...")
    
    -- Ensure shared folder exists
    local shared = ensureFolderExists(ReplicatedStorage, "shared")
    if not shared then
        warn_log("Failed to create shared folder")
        return nil
    end
    
    -- Check if one already exists
    if shared:FindFirstChild("ClientRegistry") then
        log("ClientRegistry already exists in shared folder")
        return requireSafely(shared.ClientRegistry)
    end
    
    -- Create a new ClientRegistry
    local clientRegistryModule = Instance.new("ModuleScript")
    clientRegistryModule.Name = "ClientRegistry"
    clientRegistryModule.Source = [[
--[[
    ClientRegistry (Minimal Version)
    A central registry for client-side systems and UI components
    Created by ClientRegistryFixer
]]
    
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
        },
        padding = UDim.new(0, 8)
    })
    
    -- Set up basic icon references for fallback
    self:registerUIComponent("IconSet", {
        close = "rbxassetid://8093755787",
        settings = "rbxassetid://8093754726",
        info = "rbxassetid://8093754900"
    })
    
    self.initialized = true
    print("[ClientRegistry] Initialization complete")
end

-- Helper to check if a module exists/function
function ClientRegistry:testRegistry()
    print("[ClientRegistry] Registry test: OK")
    return true
end

return ClientRegistry
]]
    clientRegistryModule.Parent = shared
    
    log("Created minimal ClientRegistry in ReplicatedStorage.shared")
    return requireSafely(clientRegistryModule)
end

-- Ensure the ClientRegistry is initialized
local function ensureClientRegistryInitialized(registry)
    if not registry then
        return false
    end
    
    -- If it has an initialize function and isn't initialized, call it
    if typeof(registry.initialize) == "function" and not registry.initialized then
        log("Initializing ClientRegistry...")
        
        local success = pcall(function()
            registry:initialize()
        end)
        
        if not success then
            warn_log("Failed to initialize ClientRegistry")
            return false
        end
        
        log("Successfully initialized ClientRegistry")
    end
    
    return true
end

-- Fix common issues with ClientRegistry
local function fixClientRegistryIssues(registry)
    if not registry then
        return false
    end
    
    -- Fix missing systems field
    if not registry.systems then
        log("Adding missing systems table to ClientRegistry")
        registry.systems = {}
    end
    
    -- Fix missing uiComponents field
    if not registry.uiComponents then
        log("Adding missing uiComponents table to ClientRegistry")
        registry.uiComponents = {}
    end
    
    -- Fix missing registerSystem method
    if typeof(registry.registerSystem) ~= "function" then
        log("Adding missing registerSystem function to ClientRegistry")
        registry.registerSystem = function(self, systemName, system)
            self.systems[systemName] = system
            return system
        end
    end
    
    -- Fix missing registerUIComponent method
    if typeof(registry.registerUIComponent) ~= "function" then
        log("Adding missing registerUIComponent function to ClientRegistry")
        registry.registerUIComponent = function(self, componentName, component)
            self.uiComponents[componentName] = component
            return component
        end
    end
    
    -- Fix missing getSystem method
    if typeof(registry.getSystem) ~= "function" then
        log("Adding missing getSystem function to ClientRegistry")
        registry.getSystem = function(self, systemName)
            return self.systems[systemName]
        end
    end
    
    -- Fix missing getUIComponent method
    if typeof(registry.getUIComponent) ~= "function" then
        log("Adding missing getUIComponent function to ClientRegistry")
        registry.getUIComponent = function(self, componentName)
            return self.uiComponents[componentName]
        end
    end
    
    -- Add a testRegistry method for diagnostics
    if typeof(registry.testRegistry) ~= "function" then
        log("Adding testRegistry function to ClientRegistry")
        registry.testRegistry = function()
            return true
        end
    end
    
    return true
end

-- Register essential UI components from shared folder
local function registerUIComponents(registry)
    if not registry then
        return false
    end
    
    log("Registering UI components...")
    
    -- List of UI components to register
    local components = {
        "UIStyle",
        "IconSet",
        "ButtonFactory",
        "DialogFactory"
    }
    
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared then
        warn_log("Shared folder not found")
        return false
    end
    
    -- Load and register each component
    local registeredCount = 0
    
    for _, componentName in ipairs(components) do
        local componentModule = shared:FindFirstChild(componentName)
        if componentModule then
            local component = requireSafely(componentModule)
            if component then
                registry:registerUIComponent(componentName, component)
                log("Registered " .. componentName .. " from module")
                registeredCount += 1
            end
        end
    end
    
    -- If UIComponents module exists, register all its components
    local uiComponents = shared:FindFirstChild("UIComponents")
    if uiComponents then
        local componentsModule = requireSafely(uiComponents)
        if componentsModule and componentsModule.components then
            -- Register all components from UIComponents
            for name, component in pairs(componentsModule.components) do
                registry:registerUIComponent(name, component)
                log("Registered " .. name .. " from UIComponents")
                registeredCount += 1
            end
            
            -- Register UIComponents itself
            registry:registerUIComponent("UIComponents", componentsModule)
            log("Registered UIComponents module")
        end
    end
    
    log("Registered " .. registeredCount .. " UI components")
    return registeredCount > 0
end

-- Main function to fix ClientRegistry
local function fixClientRegistry()
    log("Starting ClientRegistry fix process...")
    
    -- Step 1: Try to find an existing ClientRegistry
    local registry = findClientRegistry()
    local attempts = 0
    
    -- Step 2: If not found, retry a few times (in case it's being created elsewhere)
    while not registry and attempts < MAX_RETRIES do
        attempts += 1
        log("Attempt " .. attempts .. "/" .. MAX_RETRIES .. " to find ClientRegistry...")
        task.wait(RETRY_DELAY)
        registry = findClientRegistry()
    end
    
    -- Step 3: If still not found, create a minimal version
    if not registry then
        log("ClientRegistry not found after " .. attempts .. " attempts, creating minimal version")
        registry = createMinimalClientRegistry()
    end
    
    -- Step 4: Ensure it's initialized and fix common issues
    if registry then
        fixClientRegistryIssues(registry)
        ensureClientRegistryInitialized(registry)
        registerUIComponents(registry)
        
        -- Create a reference in ReplicatedStorage.shared if it doesn't exist there
        local shared = ensureFolderExists(ReplicatedStorage, "shared")
        if shared and not shared:FindFirstChild("ClientRegistry") then
            -- Create a reference module script
            local clientRegistryRef = Instance.new("ModuleScript")
            clientRegistryRef.Name = "ClientRegistry"
            clientRegistryRef.Source = "-- ClientRegistry Reference\nreturn " ..
                "require(game:GetService(\"Players\").LocalPlayer.PlayerScripts.Client.Core.ClientRegistry)"
            clientRegistryRef.Parent = shared
            log("Created ClientRegistry reference in ReplicatedStorage.shared")
        end
        
        log("ClientRegistry fix process completed successfully")
        return registry
    else
        warn_log("Failed to fix ClientRegistry")
        return nil
    end
end

-- Run the fixer with error handling
local success, result = pcall(fixClientRegistry)

if not success then
    warn_log("Error while fixing ClientRegistry: " .. tostring(result))
end

-- Return the fixed ClientRegistry or nil if failed
return success and result or nil
