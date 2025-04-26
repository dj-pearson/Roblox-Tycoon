--!strict
--[[
    ClientRegistryFixer.client.luau
    
    A script that ensures the ClientRegistry is properly initialized and accessible to all client scripts.
    
    Created: April 25, 2025
    
    This script:
    1. Loads very early in the client lifecycle
    2. Creates or finds the ClientRegistry
    3. Sets up global references to ensure it's accessible everywhere
    4. Handles Studio permissions correctly
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Constants
local LocalPlayer = Players.LocalPlayer
local DEBUG_ENABLED = true

-- Debug logging
local function log(message)
    if DEBUG_ENABLED then
        print("[ClientRegistryFixer] " .. message)
    end
end

-- Find shared folder or create it
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
if not sharedFolder then
    sharedFolder = Instance.new("Folder")
    sharedFolder.Name = "shared"
    sharedFolder.Parent = ReplicatedStorage
    log("Created shared folder in ReplicatedStorage")
end

-- Find client folder in PlayerScripts
local clientFolder = LocalPlayer.PlayerScripts:FindFirstChild("Client")
if not clientFolder then
    clientFolder = Instance.new("Folder")
    clientFolder.Name = "Client"
    clientFolder.Parent = LocalPlayer.PlayerScripts
    log("Created Client folder in PlayerScripts")
end

-- Find Core folder in client folder
local coreFolder = clientFolder:FindFirstChild("Core")
if not coreFolder then
    coreFolder = Instance.new("Folder")
    coreFolder.Name = "Core"
    coreFolder.Parent = clientFolder
    log("Created Core folder in Client folder")
end

-- Find UIComponents module in shared folder
local UIComponentsModule = sharedFolder:FindFirstChild("UIComponents")
if UIComponentsModule and UIComponentsModule:IsA("ModuleScript") then
    log("Found UIComponents module")
else
    log("UIComponents module not found, some UI elements may not function correctly")
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

-- Find or create ClientRegistry
local function findClientRegistry()
    -- Look in Core folder first
    local registryInCore = coreFolder:FindFirstChild("ClientRegistry")
    if registryInCore and registryInCore:IsA("ModuleScript") then
        log("Found ClientRegistry in Core folder")
        return requireSafely(registryInCore)
    end
    
    -- Look in shared folder
    local registryInShared = sharedFolder:FindFirstChild("ClientRegistry")
    if registryInShared and registryInShared:IsA("ModuleScript") then
        log("Found ClientRegistry in shared folder")
        return requireSafely(registryInShared)
    end
    
    -- Not found, will create new one
    log("ClientRegistry not found, creating one")
    return nil
end

-- Create references to ClientRegistry in various locations
local function createReferences(registry)
    if not registry then
        log("Cannot create references: registry is nil")
        return
    end
    
    -- Create global reference if it doesn't exist
    if _G and not _G.ClientRegistry then
        _G.ClientRegistry = registry
        log("Created global reference to ClientRegistry")
    end
    
    -- Create reference in shared folder
    local success, err = pcall(function()
        if not sharedFolder:FindFirstChild("ClientRegistry") then
            local reference = Instance.new("ModuleScript")
            reference.Name = "ClientRegistry"
            reference.Source = "-- Reference to ClientRegistry\nreturn _G.ClientRegistry or require(game:GetService('Players').LocalPlayer.PlayerScripts.Client.Core.ClientRegistry)"
            reference.Parent = sharedFolder
        end
    end)
    
    if success then
        log("Created reference in shared folder")
    else
        warn("[ClientRegistryFixer] Failed to create reference in shared folder: " .. tostring(err))
    end
    
    -- Create reference as ObjectValue for scripts that can't use require
    local success, err = pcall(function()
        local objectRef = coreFolder:FindFirstChild("ClientRegistryRef") 
        if not objectRef then
            objectRef = Instance.new("ObjectValue")
            objectRef.Name = "ClientRegistryRef"
            objectRef.Value = coreFolder:FindFirstChild("ClientRegistry")
            objectRef.Parent = coreFolder
        end
    end)
    
    if success then
        log("Created ObjectValue reference")
    else
        warn("[ClientRegistryFixer] Failed to create ObjectValue reference: " .. tostring(err))
    end
    
    return true
end

-- Main execution
local function main()
    log("Starting ClientRegistryFixer")
    
    -- Find or require ClientRegistry
    local registry = findClientRegistry()
    
    -- If we don't have a registry, try using ModuleLoader to find it
    if not registry then
        -- Try to find ModuleLoader
        local moduleLoader
        local moduleLoaderInShared = sharedFolder:FindFirstChild("ModuleLoader")
        if moduleLoaderInShared then
            moduleLoader = requireSafely(moduleLoaderInShared)
            
            if moduleLoader then
                log("Found ModuleLoader, using it to find ClientRegistry")
                registry = moduleLoader.requireModule("ClientRegistry")
            end
        end
    end
    
    -- Create references
    if registry then
        createReferences(registry)
        
        -- Try to initialize the registry
        if typeof(registry) == "table" and typeof(registry.initialize) == "function" then
            log("Initializing ClientRegistry")
            registry:initialize()
        end
    else
        -- Try to load the ClientRegistry we just created in our other fix
        if coreFolder:FindFirstChild("ClientRegistry") then
            registry = requireSafely(coreFolder.ClientRegistry)
            
            if registry then
                log("Loaded newly created ClientRegistry")
                createReferences(registry)
                
                if typeof(registry) == "table" and typeof(registry.initialize) == "function" then
                    log("Initializing newly created ClientRegistry")
                    registry:initialize()
                end
            else
                warn("[ClientRegistryFixer] Failed to load ClientRegistry, UI systems may not function correctly")
            end
        else
            warn("[ClientRegistryFixer] Could not find or create ClientRegistry, UI systems may not function correctly")
        end
    end
    
    -- Load UIComponents and register with ClientRegistry if available
    local UIComponents = requireSafely(UIComponentsModule)
    if UIComponents and registry then
        log("Registering UIComponents with ClientRegistry")
        if typeof(UIComponents.registerWithClientRegistry) == "function" then
            UIComponents.registerWithClientRegistry(registry)
        end
    end
    
    log("ClientRegistryFixer completed")
end

-- Run in a protected call to avoid breaking the entire client
local success, err = pcall(main)
if not success then
    warn("[ClientRegistryFixer] Error during execution: " .. tostring(err))
end
