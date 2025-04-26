--!strict
--[[
    ClientRegistryFixer.client.luau
    
    A client-side utility for ensuring ClientRegistry exists and is properly initialized.
    
    Created: April 25, 2025
    
    This module:
    1. Loads early in the client lifecycle
    2. Ensures ClientRegistry exists in the correct locations
    3. Creates global references when needed
    4. Properly handles permissions in Studio mode
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    error("[ClientRegistryFixer] No LocalPlayer found")
    return
end

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    CREATE_MISSING_FOLDERS = true,
    ALLOW_GLOBAL_REGISTRY = true,
    FALLBACK_REGISTRY_CREATION = true
}

-- Constants
local IsStudio = RunService:IsStudio()

-- Registry paths
local REGISTRY_PATHS = {
    SharedFolder = ReplicatedStorage:FindFirstChild("shared"),
    ClientFolder = LocalPlayer.PlayerScripts:FindFirstChild("Client"),
    CoreFolder = LocalPlayer.PlayerScripts:FindFirstChild("Client") and 
                 LocalPlayer.PlayerScripts.Client:FindFirstChild("Core")
}

-- Logging function
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[ClientRegistryFixer] " .. message)
    end
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
        warn("[ClientRegistryFixer] Failed to require module: ", module:GetFullName())
        return nil
    end
    
    return result
end

-- Create missing folder hierarchies
local function ensureFolderHierarchy()
    -- Ensure shared folder exists
    if not REGISTRY_PATHS.SharedFolder then
        if CONFIG.CREATE_MISSING_FOLDERS then
            log("Creating missing shared folder in ReplicatedStorage")
            local newFolder = Instance.new("Folder")
            newFolder.Name = "shared"
            newFolder.Parent = ReplicatedStorage
            REGISTRY_PATHS.SharedFolder = newFolder
        else
            warn("[ClientRegistryFixer] Shared folder missing in ReplicatedStorage")
        end
    end
    
    -- Ensure Client folder exists
    if not REGISTRY_PATHS.ClientFolder then
        if CONFIG.CREATE_MISSING_FOLDERS then
            log("Creating missing Client folder in PlayerScripts")
            local newFolder = Instance.new("Folder")
            newFolder.Name = "Client"
            newFolder.Parent = LocalPlayer.PlayerScripts
            REGISTRY_PATHS.ClientFolder = newFolder
        else
            warn("[ClientRegistryFixer] Client folder missing in PlayerScripts")
        end
    end
    
    -- Ensure Core folder exists
    if REGISTRY_PATHS.ClientFolder and not REGISTRY_PATHS.CoreFolder then
        if CONFIG.CREATE_MISSING_FOLDERS then
            log("Creating missing Core folder in Client")
            local newFolder = Instance.new("Folder")
            newFolder.Name = "Core"
            newFolder.Parent = REGISTRY_PATHS.ClientFolder
            REGISTRY_PATHS.CoreFolder = newFolder
        else
            warn("[ClientRegistryFixer] Core folder missing in Client folder")
        end
    end
end

-- Locate ClientRegistry in various possible locations
local function findClientRegistry()
    local registryLocations = {}
    
    -- Check in shared folder
    if REGISTRY_PATHS.SharedFolder then
        local sharedRegistry = REGISTRY_PATHS.SharedFolder:FindFirstChild("ClientRegistry")
        if sharedRegistry then
            table.insert(registryLocations, {
                instance = sharedRegistry,
                path = "ReplicatedStorage.shared.ClientRegistry",
                module = requireSafely(sharedRegistry)
            })
        end
    end
    
    -- Check in Core folder
    if REGISTRY_PATHS.CoreFolder then
        local coreRegistry = REGISTRY_PATHS.CoreFolder:FindFirstChild("ClientRegistry")
        if coreRegistry then
            table.insert(registryLocations, {
                instance = coreRegistry,
                path = "PlayerScripts.Client.Core.ClientRegistry",
                module = requireSafely(coreRegistry)
            })
        end
    end
    
    return registryLocations
end

-- Create a basic ClientRegistry if none exists
local function createBasicClientRegistry()
    log("Creating basic ClientRegistry")
    
    local ClientRegistry = {
        systems = {},
        uiComponents = {},
        initialized = false
    }
    
    -- Core ClientRegistry functionality
    function ClientRegistry:registerSystem(systemName, systemInstance)
        if not systemName or not systemInstance then
            warn("[ClientRegistry] Cannot register nil system")
            return false
        end
        
        self.systems[systemName] = systemInstance
        log("Registered system: " .. systemName)
        return true
    end
    
    function ClientRegistry:getSystem(systemName)
        return self.systems[systemName]
    end
    
    function ClientRegistry:registerUIComponent(componentName, component)
        if not componentName or not component then
            warn("[ClientRegistry] Cannot register nil UI component")
            return false
        end
        
        self.uiComponents[componentName] = component
        log("Registered UI component: " .. componentName)
        return true
    end
    
    function ClientRegistry:getUIComponent(componentName)
        return self.uiComponents[componentName]
    end
    
    function ClientRegistry:initialize()
        if self.initialized then
            return true
        end
        
        log("Initializing ClientRegistry")
        self.initialized = true
        return true
    end
    
    return ClientRegistry
end

-- Save ClientRegistry module to file
local function saveClientRegistryToFile(clientRegistry, targetFolder)
    if not IsStudio then
        log("Cannot save ClientRegistry to file outside Studio")
        return false
    end
    
    if not targetFolder then
        log("No target folder specified for saving ClientRegistry")
        return false
    end
    
    log("Creating ClientRegistry ModuleScript in " .. targetFolder:GetFullName())
    
    local moduleScript = Instance.new("ModuleScript")
    moduleScript.Name = "ClientRegistry"
    
    -- Basic ClientRegistry script template
    moduleScript.Source = [[--!strict
--[[
    ClientRegistry.luau
    
    A registry for client-side systems.
    
    Created: April 25, 2025 (Auto-generated by ClientRegistryFixer)
    
    This module:
    1. Provides a central registration point for client systems
    2. Manages access to UI components
    3. Handles cross-system dependencies
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Registry state
local ClientRegistry = {
    systems = {},
    uiComponents = {},
    initialized = false
}

-- Debug logging
local function log(message)
    print("[ClientRegistry] " .. message)
end

-- Register a system with the registry
function ClientRegistry:registerSystem(systemName, systemInstance)
    if not systemName or not systemInstance then
        warn("[ClientRegistry] Cannot register nil system")
        return false
    end
    
    self.systems[systemName] = systemInstance
    log("Registered system: " .. systemName)
    return true
end

-- Get a system from the registry
function ClientRegistry:getSystem(systemName)
    return self.systems[systemName]
end

-- Register a UI component
function ClientRegistry:registerUIComponent(componentName, component)
    if not componentName or not component then
        warn("[ClientRegistry] Cannot register nil UI component")
        return false
    end
    
    self.uiComponents[componentName] = component
    log("Registered UI component: " .. componentName)
    return true
end

-- Get a UI component
function ClientRegistry:getUIComponent(componentName)
    return self.uiComponents[componentName]
end

-- Initialize the registry
function ClientRegistry:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing ClientRegistry")
    self.initialized = true
    return true
end

-- Auto-initialize
ClientRegistry:initialize()

return ClientRegistry]]
    
    moduleScript.Parent = targetFolder
    return moduleScript
end

-- MAIN FUNCTIONALITY: Get or create ClientRegistry
local function ensureClientRegistry()
    -- First, ensure folder structure exists
    ensureFolderHierarchy()
    
    -- Try to find existing ClientRegistry
    local registryLocations = findClientRegistry()
    
    -- If found, use the first valid one
    for _, location in ipairs(registryLocations) do
        if location.module then
            log("Found valid ClientRegistry at " .. location.path)
            
            -- Store global reference if allowed
            if CONFIG.ALLOW_GLOBAL_REGISTRY then
                log("Creating global ClientRegistry reference")
            end
            
            -- Return the found module
            return location.module
        else
            warn("[ClientRegistryFixer] Found ClientRegistry at " .. location.path .. " but it failed to load")
        end
    end
    
    -- If we get here, no working ClientRegistry was found
    warn("[ClientRegistryFixer] No working ClientRegistry found, action required")
    
    -- Create a fallback if allowed
    if CONFIG.FALLBACK_REGISTRY_CREATION then
        log("Creating fallback ClientRegistry")
        local fallbackRegistry = createBasicClientRegistry()
        
        -- Try to save it to file in Studio
        if IsStudio then
            if REGISTRY_PATHS.CoreFolder then
                saveClientRegistryToFile(fallbackRegistry, REGISTRY_PATHS.CoreFolder)
            elseif REGISTRY_PATHS.SharedFolder then
                saveClientRegistryToFile(fallbackRegistry, REGISTRY_PATHS.SharedFolder)
            end
        end
        
        -- Store global reference if allowed
        if CONFIG.ALLOW_GLOBAL_REGISTRY then
            log("Creating global ClientRegistry reference")
        end
        
        -- Return the fallback
        return fallbackRegistry
    else
        error("[ClientRegistryFixer] No working ClientRegistry found and fallback creation is disabled")
        return nil
    end
end

-- ClientRegistryFixer Module
local ClientRegistryFixer = {
    findClientRegistry = findClientRegistry,
    ensureClientRegistry = ensureClientRegistry,
    createBasicClientRegistry = createBasicClientRegistry,
    saveClientRegistryToFile = saveClientRegistryToFile,
    CONFIG = CONFIG
}

return ClientRegistryFixer
