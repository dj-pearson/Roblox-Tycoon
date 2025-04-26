--[[
    ModuleFallbackGenerator.luau
    
    A utility for creating fallback modules when required dependencies are missing.
    This helps ensure the game can still function with minimal errors even when modules are missing.
    
    Created: April 25, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Constants
local IsServer = RunService:IsServer()
local IsStudio = RunService:IsStudio()

-- Create fallback modules when original is missing
local ModuleFallbackGenerator = {}

-- Debug output
local function log(message)
    print("[ModuleFallbackGenerator] " .. message)
end

local function warn_log(message)
    warn("[ModuleFallbackGenerator] " .. message)
end

-- Get the correct parent location for a system based on its type
local function getParentForSystem(systemName, systemType)
    systemType = systemType or "shared"
    
    if systemType == "shared" then
        local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
        if not sharedFolder then
            sharedFolder = Instance.new("Folder")
            sharedFolder.Name = "shared"
            sharedFolder.Parent = ReplicatedStorage
            log("Created shared folder in ReplicatedStorage")
        end
        return sharedFolder
    elseif systemType == "server" then
        if IsServer then
            local coreFolder = ServerScriptService:FindFirstChild("Core")
            if not coreFolder then
                coreFolder = Instance.new("Folder")
                coreFolder.Name = "Core"
                coreFolder.Parent = ServerScriptService
                log("Created Core folder in ServerScriptService")
            end
            return coreFolder
        else
            warn_log("Cannot create server module on client!")
            return nil
        end
    elseif systemType == "client" then
        if not IsServer then
            local Players = game:GetService("Players")
            local LocalPlayer = Players.LocalPlayer
            
            if LocalPlayer then
                local clientFolder = LocalPlayer.PlayerScripts:FindFirstChild("Client")
                if not clientFolder then
                    clientFolder = Instance.new("Folder")
                    clientFolder.Name = "Client"
                    clientFolder.Parent = LocalPlayer.PlayerScripts
                    log("Created Client folder in PlayerScripts")
                end
                
                local coreFolder = clientFolder:FindFirstChild("Core")
                if not coreFolder then
                    coreFolder = Instance.new("Folder")
                    coreFolder.Name = "Core"
                    coreFolder.Parent = clientFolder
                    log("Created Core folder in Client")
                end
                
                return coreFolder
            else
                warn_log("LocalPlayer not found!")
                return nil
            end
        else
            -- Allow creating client modules on server for replication
            local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
            if not sharedFolder then
                sharedFolder = Instance.new("Folder")
                sharedFolder.Name = "shared"
                sharedFolder.Parent = ReplicatedStorage
                log("Created shared folder in ReplicatedStorage")
            end
            return sharedFolder
        end
    end
    
    return nil
end

-- Create a fallback module with basic functionality
function ModuleFallbackGenerator.createFallbackModule(systemName, systemType, template)
    local parent = getParentForSystem(systemName, systemType)
    if not parent then
        warn_log("Cannot create fallback module - invalid parent location")
        return nil
    end
    
    -- Check if the module already exists
    if parent:FindFirstChild(systemName) then
        log("Module " .. systemName .. " already exists, not creating fallback")
        return parent[systemName]
    end
    
    -- Create the module
    local moduleScript = Instance.new("ModuleScript")
    moduleScript.Name = systemName
    
    -- Generate source based on template
    if template == "CoreRegistry" then
        moduleScript.Source = [[
-- Fallback CoreRegistry implementation
local Registry = {
    systems = {},
    initialized = {},
    loading = {}
}

function Registry.registerSystem(name, system, dependencies)
    Registry.systems[name] = {
        module = system,
        dependencies = dependencies or {}
    }
    print("[FallbackCoreRegistry] Registered system: " .. name)
    return system
end

function Registry.getSystem(name)
    if Registry.systems[name] then
        return Registry.systems[name].module
    end
    
    warn("[FallbackCoreRegistry] System not found: " .. name)
    return nil
end

return Registry
]]
    elseif template == "EventBridge" then
        moduleScript.Source = [[
-- Fallback EventBridge implementation
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IsServer = RunService:IsServer()

local EventBridge = {
    events = {},
    remoteEvents = {}
}

function EventBridge:initialize()
    print("[FallbackEventBridge] Initialized")
    return true
end

function EventBridge:connectEvent(eventName, callback)
    if not self.events[eventName] then
        self.events[eventName] = {
            callbacks = {}
        }
    end
    
    table.insert(self.events[eventName].callbacks, callback)
    return true
end

function EventBridge:fireEvent(eventName, ...)
    local event = self.events[eventName]
    if event then
        for _, callback in ipairs(event.callbacks) do
            task.spawn(function()
                callback(...)
            end)
        end
    end
    
    local remoteEvent = self.remoteEvents[eventName]
    if remoteEvent and IsServer then
        remoteEvent:FireAllClients(...)
    end
end

function EventBridge:registerRemoteEvent(eventName, remoteEvent)
    self.remoteEvents[eventName] = remoteEvent
    
    if not IsServer then
        remoteEvent.OnClientEvent:Connect(function(...)
            self:fireEvent(eventName, ...)
        end)
    else
        remoteEvent.OnServerEvent:Connect(function(player, ...)
            self:fireEvent(eventName, player, ...)
        end)
    end
end

return EventBridge
]]
    elseif template == "ModuleLoader" then
        moduleScript.Source = [[
-- Fallback ModuleLoader implementation
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local searchPaths = {
    ReplicatedStorage,
    ReplicatedStorage:FindFirstChild("shared")
}

local loadedModules = {}

local ModuleLoader = {
    searchPaths = searchPaths,
    loadedModules = loadedModules
}

function ModuleLoader.addSearchPath(path)
    if typeof(path) == "Instance" then
        table.insert(ModuleLoader.searchPaths, 1, path)
        return true
    end
    return false
end

function ModuleLoader.findModule(moduleName)
    for _, path in ipairs(ModuleLoader.searchPaths) do
        if not path then continue end
        
        local module = path:FindFirstChild(moduleName)
        if module and module:IsA("ModuleScript") then
            return module
        end
    end
    return nil
end

function ModuleLoader.tryRequire(moduleName)
    if loadedModules[moduleName] then
        return loadedModules[moduleName]
    end
    
    local moduleScript = ModuleLoader.findModule(moduleName)
    if not moduleScript then
        return nil
    end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if success then
        loadedModules[moduleName] = result
        return result
    end
    
    return nil
end

function ModuleLoader.RegisterPath(category, group, path)
    return ModuleLoader.addSearchPath(path)
end

function ModuleLoader.initialize()
    local ServerScriptService = game:GetService("ServerScriptService")
    if ServerScriptService then
        ModuleLoader.addSearchPath(ServerScriptService)
    end
    
    return ModuleLoader
end

ModuleLoader.require = ModuleLoader.tryRequire
return ModuleLoader
]]
    elseif template == "BuyTileSystem" then
        moduleScript.Source = [[
-- Fallback BuyTileSystem implementation
local BuyTileSystem = {
    tileData = {},
    initialized = false
}

function BuyTileSystem:initialize()
    if self.initialized then
        return
    end
    
    print("[FallbackBuyTileSystem] Initialized")
    self.initialized = true
end

function BuyTileSystem:getTileData(tileId)
    return self.tileData[tileId]
end

function BuyTileSystem:purchaseTile(player, tileId)
    warn("[FallbackBuyTileSystem] Attempt to purchase tile " .. tileId .. " by " .. player.Name)
    return false
end

return BuyTileSystem
]]
    elseif template == "ClientRegistry" then
        moduleScript.Source = [[
-- Fallback ClientRegistry implementation
local ClientRegistry = {
    systems = {},
    uiComponents = {},
    initialized = false
}

function ClientRegistry.registerSystem(systemName, system)
    ClientRegistry.systems[systemName] = system
    return system
end

function ClientRegistry.registerUIComponent(componentName, component)
    ClientRegistry.uiComponents[componentName] = component
    return component
end

function ClientRegistry.getSystem(systemName)
    return ClientRegistry.systems[systemName]
end

function ClientRegistry.getUIComponent(componentName)
    return ClientRegistry.uiComponents[componentName]
end

function ClientRegistry.initialize()
    if ClientRegistry.initialized then
        return
    end
    
    print("[FallbackClientRegistry] Initialized")
    ClientRegistry.initialized = true
end

return ClientRegistry
]]
    else
        -- Generic module template
        moduleScript.Source = [[
-- Fallback module for: ]] .. systemName .. [[

local Module = {
    initialized = false,
    name = "]] .. systemName .. [["
}

function Module:initialize()
    if self.initialized then
        return
    end
    
    print("[Fallback]] .. systemName .. [[] Initialized")
    self.initialized = true
end

return Module
]]
    end
    
    -- Set parent and return
    moduleScript.Parent = parent
    log("Created fallback module: " .. systemName)
    
    return moduleScript
end

-- Generate CoreRegistry fallback
function ModuleFallbackGenerator.createCoreRegistry()
    return ModuleFallbackGenerator.createFallbackModule("CoreRegistry", "server", "CoreRegistry")
end

-- Generate EventBridge fallback
function ModuleFallbackGenerator.createEventBridge()
    return ModuleFallbackGenerator.createFallbackModule("EventBridge", "server", "EventBridge")
end

-- Generate ModuleLoader fallback
function ModuleFallbackGenerator.createModuleLoader()
    return ModuleFallbackGenerator.createFallbackModule("ModuleLoader", "shared", "ModuleLoader")
end

-- Generate BuyTileSystem fallback
function ModuleFallbackGenerator.createBuyTileSystem()
    return ModuleFallbackGenerator.createFallbackModule("BuyTileSystem", "server", "BuyTileSystem")
end

-- Generate ClientRegistry fallback
function ModuleFallbackGenerator.createClientRegistry()
    return ModuleFallbackGenerator.createFallbackModule("ClientRegistry", "client", "ClientRegistry")
end

return ModuleFallbackGenerator
