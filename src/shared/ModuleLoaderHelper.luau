--[[
    ModuleLoaderHelper.luau
    
    A utility module that helps with loading modules across both server and client.
    This module provides a consistent interface for requiring modules with good error handling.
    
    Created: April 25, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Constants
local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()

-- Cache to avoid requiring the same module multiple times
local moduleCache = {}

-- ModuleLoaderHelper singleton
local ModuleLoaderHelper = {}

-- Get the ModuleLoader instance
function ModuleLoaderHelper:GetModuleLoader()
    -- Return from cache if we've already loaded it
    if moduleCache.ModuleLoader then
        return moduleCache.ModuleLoader
    end
    
    -- Find the ModuleLoader in the shared folder
    local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
    if not sharedFolder then
        warn("[ModuleLoaderHelper] Shared folder not found, creating it")
        sharedFolder = Instance.new("Folder")
        sharedFolder.Name = "shared"
        sharedFolder.Parent = ReplicatedStorage
    end
    
    -- Try to require the ModuleLoader
    local moduleLoader = sharedFolder:FindFirstChild("ModuleLoader")
    if moduleLoader and moduleLoader:IsA("ModuleScript") then
        local success, result = pcall(function()
            return require(moduleLoader)
        end)
        
        if success then
            moduleCache.ModuleLoader = result
            print("[ModuleLoaderHelper] ModuleLoader loaded successfully")
            return result
        else
            warn("[ModuleLoaderHelper] Failed to load ModuleLoader: " .. tostring(result))
        end
    end
    
    warn("[ModuleLoaderHelper] ModuleLoader not found, using fallback methods")
    return nil
end

-- Safely require a module with fallbacks
function ModuleLoaderHelper:SafeRequire(modulePath)
    if not modulePath then
        return nil
    end
    
    -- If it's a string, try to find the module
    if type(modulePath) == "string" then
        -- Try ModuleLoader first
        local moduleLoader = self:GetModuleLoader()
        if moduleLoader then
            return moduleLoader.tryRequire(modulePath)
        end
        
        -- If that fails, we can't do much with just a string
        return nil
    end
    
    -- Otherwise, assume it's an instance and try to require it
    if typeof(modulePath) == "Instance" and modulePath:IsA("ModuleScript") then
        local success, result = pcall(function()
            return require(modulePath)
        end)
        
        if success then
            return result
        else
            warn("[ModuleLoaderHelper] Failed to require " .. modulePath:GetFullName() .. ": " .. tostring(result))
            return nil
        end
    end
    
    return nil
end

-- Get a module with multiple fallback paths
function ModuleLoaderHelper:GetModule(moduleName, alternativePaths)
    -- Return from cache if we've already loaded it
    if moduleCache[moduleName] then
        return moduleCache[moduleName]
    end
    
    -- Try ModuleLoader first (most reliable)
    local moduleLoader = self:GetModuleLoader()
    if moduleLoader then
        local module = moduleLoader.tryRequire(moduleName)
        if module then
            moduleCache[moduleName] = module
            return module
        end
    end
    
    -- Try alternative paths if provided
    if alternativePaths then
        for _, path in ipairs(alternativePaths) do
            if typeof(path) == "Instance" and path:IsA("ModuleScript") then
                local module = self:SafeRequire(path)
                if module then
                    moduleCache[moduleName] = module
                    return module
                end
            elseif typeof(path) == "function" then
                -- Allow providing a function to find the module
                local success, moduleOrPath = pcall(path)
                if success and moduleOrPath then
                    if typeof(moduleOrPath) == "table" then
                        -- Function returned a module directly
                        moduleCache[moduleName] = moduleOrPath
                        return moduleOrPath
                    else
                        -- Function returned a path to require
                        local module = self:SafeRequire(moduleOrPath)
                        if module then
                            moduleCache[moduleName] = module
                            return module
                        end
                    end
                end
            end
        end
    end
    
    warn("[ModuleLoaderHelper] Failed to find module: " .. moduleName)
    return nil
end

-- Get the CoreRegistry instance
function ModuleLoaderHelper:GetCoreRegistry()
    return self:GetModule("CoreRegistry", {
        function()
            if IsServer then
                local ServerScriptService = game:GetService("ServerScriptService")
                if ServerScriptService:FindFirstChild("Core") then
                    return ServerScriptService.Core:FindFirstChild("CoreRegistry")
                end
            else
                local ClientRegistry = nil
                if ReplicatedStorage:FindFirstChild("shared") then
                    ClientRegistry = ReplicatedStorage.shared:FindFirstChild("ClientRegistry")
                    if ClientRegistry then return ClientRegistry end
                end
                
                local Players = game:GetService("Players")
                local LocalPlayer = Players.LocalPlayer
                if LocalPlayer and LocalPlayer.PlayerScripts:FindFirstChild("Client") then
                    return LocalPlayer.PlayerScripts.Client.Core:FindFirstChild("ClientRegistry")
                end
            end
            return nil
        end
    })
end

-- Get the EventBridge instance
function ModuleLoaderHelper:GetEventBridge()
    return self:GetModule("EventBridge", {
        function()
            if IsServer then
                local ServerScriptService = game:GetService("ServerScriptService")
                if ServerScriptService:FindFirstChild("Core") then
                    return ServerScriptService.Core:FindFirstChild("EventBridge")
                end
            else
                -- For client, we need to use RemoteEvents
                local coreRegistry = self:GetCoreRegistry()
                if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
                    return coreRegistry:getSystem("EventBridge")
                end
            end
            return nil
        end
    })
end

-- Get any system from CoreRegistry
function ModuleLoaderHelper:GetSystem(systemName)
    local coreRegistry = self:GetCoreRegistry()
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        return coreRegistry:getSystem(systemName)
    end
    
    return self:GetModule(systemName)
end

-- Connect to an event with EventBridge or fallback to direct connection
function ModuleLoaderHelper:ConnectToEvent(eventName, callback)
    -- Try EventBridge first
    local eventBridge = self:GetEventBridge()
    if eventBridge and typeof(eventBridge.connectEvent) == "function" then
        eventBridge:connectEvent(eventName, callback)
        return true
    end
    
    -- Otherwise, try direct RemoteEvent connection
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    if eventsFolder then
        local remoteEvent = eventsFolder:FindFirstChild(eventName)
        if remoteEvent and remoteEvent:IsA("RemoteEvent") then
            remoteEvent.OnClientEvent:Connect(callback)
            return true
        end
    end
    
    -- Try directly in ReplicatedStorage as fallback
    local remoteEvent = ReplicatedStorage:FindFirstChild(eventName)
    if remoteEvent and remoteEvent:IsA("RemoteEvent") then
        if IsClient then
            remoteEvent.OnClientEvent:Connect(callback)
        else
            remoteEvent.OnServerEvent:Connect(callback)
        end
        return true
    end
    
    warn("[ModuleLoaderHelper] Failed to connect to event: " .. eventName)
    return false
end

-- Fire an event with EventBridge or fallback to direct firing
function ModuleLoaderHelper:FireEvent(eventName, ...)
    -- Try EventBridge first
    local eventBridge = self:GetEventBridge()
    if eventBridge and typeof(eventBridge.fireEvent) == "function" then
        eventBridge:fireEvent(eventName, ...)
        return true
    end
    
    -- Otherwise, try direct RemoteEvent firing
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    if eventsFolder then
        local remoteEvent = eventsFolder:FindFirstChild(eventName)
        if remoteEvent and remoteEvent:IsA("RemoteEvent") then
            if IsServer then
                remoteEvent:FireAllClients(...)
            else
                remoteEvent:FireServer(...)
            end
            return true
        end
    end
    
    -- Try directly in ReplicatedStorage as fallback
    local remoteEvent = ReplicatedStorage:FindFirstChild(eventName)
    if remoteEvent and remoteEvent:IsA("RemoteEvent") then
        if IsServer then
            remoteEvent:FireAllClients(...)
        else
            remoteEvent:FireServer(...)
        end
        return true
    end
    
    warn("[ModuleLoaderHelper] Failed to fire event: " .. eventName)
    return false
end

return ModuleLoaderHelper
