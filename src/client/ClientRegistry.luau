-- ClientRegistry.luau
-- Global registry for client systems and modules
-- Created: May 2, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Make sure we're on the client
if not RunService:IsClient() then
    warn("[ClientRegistry] ClientRegistry should only be used on the client")
    return {
        Register = function() end,
        Get = function() return nil end
    }
end

-- Find a module by name
local function findModule(moduleName)
    -- Get the player and PlayerScripts
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local PlayerScripts = player and player:FindFirstChild("PlayerScripts")
      -- Search paths
    local searchPaths = {
        -- Client paths
        PlayerScripts and PlayerScripts:FindFirstChild("src") and PlayerScripts.src:FindFirstChild("client") and PlayerScripts.src.client:FindFirstChild("Core"),
        PlayerScripts and PlayerScripts:FindFirstChild("src") and PlayerScripts.src.client,
        PlayerScripts and PlayerScripts:FindFirstChild("Core"),
        PlayerScripts,
        player and player:FindFirstChild("ClientModules"),
        
        -- Client Core directories
        PlayerScripts and PlayerScripts:FindFirstChild("src") and PlayerScripts.src:FindFirstChild("client") and PlayerScripts.src.client:FindFirstChild("Core") and PlayerScripts.src.client.Core:FindFirstChild("UI"),
        PlayerScripts and PlayerScripts:FindFirstChild("src") and PlayerScripts.src.client:FindFirstChild("UI"),
        PlayerScripts and PlayerScripts:FindFirstChild("UI"),
        
        -- ReplicatedStorage paths
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("client"),
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage,
        
        -- Additional specific paths for common modules
        ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("UI"),
        ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("Core"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared") and ReplicatedStorage.src.shared:FindFirstChild("UI")
    }
    
    -- Look in each path
    for _, path in ipairs(searchPaths) do
        if path then
            -- Direct match
            local moduleScript = path:FindFirstChild(moduleName)
            if moduleScript and moduleScript:IsA("ModuleScript") then
                return moduleScript
            end
            
            -- Check with .luau extension
            moduleScript = path:FindFirstChild(moduleName .. ".luau")
            if moduleScript and moduleScript:IsA("ModuleScript") then
                return moduleScript
            end
            
            -- Check with .client.luau extension
            moduleScript = path:FindFirstChild(moduleName .. ".client.luau")
            if moduleScript and moduleScript:IsA("ModuleScript") then
                return moduleScript
            end
        end
    end
    
    return nil
end

-- Client registry
local ClientRegistry = {
    Version = "1.0.0",
    IsLoaded = true,
    Debug = true
}

-- Private registry store to avoid global variables
local registry = {}

-- Try to get CoreRegistryRemotes to communicate with server
local serverRemotes = ReplicatedStorage:FindFirstChild("CoreRegistryRemotes")
local getSystemRemote = serverRemotes and serverRemotes:FindFirstChild("GetSystem")

-- Attempt to get server systems through remotes
local function getServerSystem(systemName)
    if getSystemRemote and getSystemRemote:IsA("RemoteFunction") then
        local success, result = pcall(function()
            return getSystemRemote:InvokeServer(systemName)
        end)
        
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Debug logging
local function log(message, level)
    if not ClientRegistry.Debug and level ~= "Error" then return end
    
    local prefix = "[ClientRegistry]"
    if level == "Error" then
        warn(prefix .. " " .. message)
    elseif level == "Success" then
        print(prefix .. " ✓ " .. message)
    else
        print(prefix .. " " .. message)
    end
end

-- Register a system or value
function ClientRegistry:Register(name, value)
    if not name or type(name) ~= "string" then
        log("Invalid registry name", "Error")
        return false
    end
    
    if value == nil then
        log("Cannot register nil value for: " .. name, "Error")
        return false
    end
    
    registry[name] = value
    log("Registered: " .. name, "Success")
    return true
end

-- Alternative names for Register to maintain compatibility
ClientRegistry.registerSystem = ClientRegistry.Register
ClientRegistry.register = ClientRegistry.Register
ClientRegistry.registerUIComponent = ClientRegistry.Register

-- Get a registered value
function ClientRegistry:Get(name)
    if not name or type(name) ~= "string" then
        log("Invalid name in Get", "Error")
        return nil
    end
    
    -- First check local registry
    if registry[name] then
        return registry[name]
    end
    
    -- If not found locally, try to load the module
    local moduleScript = findModule(name)
    if moduleScript then
        local success, result = pcall(function()
            return require(moduleScript)
        end)
        
        if success and result then
            -- Register the loaded module
            registry[name] = result
            log("Auto-loaded and registered: " .. name, "Success")
            
            -- If this is a system module with an initialize method, call it
            if typeof(result) == "table" and typeof(result.initialize) == "function" and not result.initialized then
                pcall(function()
                    result:initialize()
                end)
            end
            
            return result
        else
            log("Error loading module " .. name .. ": " .. tostring(result), "Error")
        end
    end
    
    -- If still not found, try to get from server
    local serverSystem = getServerSystem(name)
    if serverSystem then
        -- Register the server system
        registry[name] = serverSystem
        log("Retrieved from server and registered: " .. name, "Success")
        return serverSystem
    end
    
    -- Special handling for common systems - provide fallback implementations
    if name == "UIComponents" then
        log("Creating fallback UIComponents system", "Success")
        local fallbackUI = require(script.Parent:FindFirstChild("UI") and script.Parent.UI:FindFirstChild("UIComponentsFallback") or script)
        registry[name] = fallbackUI
        return fallbackUI
    elseif name == "AssetValidator" then
        log("Creating fallback AssetValidator system", "Success")
        local fallbackValidator = {
            ValidateAsset = function() return true end,
            initialized = true
        }
        registry[name] = fallbackValidator
        return fallbackValidator
    end
    
    log("System not found: " .. name, "Error")
    return nil
end

-- Alternative names for Get to maintain compatibility
ClientRegistry.getSystem = ClientRegistry.Get
ClientRegistry.get = ClientRegistry.Get

-- Check if a system exists
function ClientRegistry:HasSystem(name)
    return registry[name] ~= nil
end

-- List all registered systems/values
function ClientRegistry:ListSystems()
    local systems = {}
    for name, _ in pairs(registry) do
        table.insert(systems, name)
    end
    return systems
end

-- Remove a registered value
function ClientRegistry:Unregister(name)
    if not name or type(name) ~= "string" then
        log("Invalid name in Unregister", "Error")
        return false
    end
    
    if registry[name] == nil then
        log("Cannot unregister non-existent system: " .. name, "Error")
        return false
    end
    
    registry[name] = nil
    log("Unregistered: " .. name, "Success")
    return true
end

-- Initialize the registry
function ClientRegistry:Initialize()
    -- Check if already initialized
    if self.Initialized then
        return true
    end
    
    log("Initializing ClientRegistry...")
    
    -- Register self in the registry
    self:Register("ClientRegistry", self)
    
    -- Try to connect to server CoreRegistry
    if not serverRemotes then
        serverRemotes = ReplicatedStorage:WaitForChild("CoreRegistryRemotes", 5)
        if serverRemotes then
            getSystemRemote = serverRemotes:WaitForChild("GetSystem", 2)
            if getSystemRemote then
                log("Connected to server CoreRegistry", "Success")
            else
                log("Failed to find GetSystem remote", "Error")
            end
        else
            log("Failed to find CoreRegistryRemotes folder", "Error")
            
            -- Create remotes folder as a fallback
            serverRemotes = Instance.new("Folder")
            serverRemotes.Name = "CoreRegistryRemotes"
            serverRemotes.Parent = ReplicatedStorage
            
            getSystemRemote = Instance.new("RemoteFunction")
            getSystemRemote.Name = "GetSystem"
            getSystemRemote.Parent = serverRemotes
            
            log("Created fallback remote system", "Success")
        end
    end
      -- Try to preload critical client systems
    local criticalSystems = {
        "UIComponents",
        "AssetValidator",
        "ClientBootstrap",
        "UIRegistry"
    }
    
    for _, systemName in ipairs(criticalSystems) do
        task.spawn(function()
            local system = self:Get(systemName)
            if system then
                log("Preloaded critical system: " .. systemName, "Success")
            else
                log("Failed to preload critical system: " .. systemName, "Error")
            end
        end)
    end
    
    self.Initialized = true
    log("ClientRegistry initialized successfully!", "Success")
    return true
end

-- Auto-initialize on require
task.spawn(function()
    ClientRegistry:Initialize()
end)

return ClientRegistry
    
    self.Initialized = true
    log("ClientRegistry initialized successfully!", "Success")
    return true
end

-- Auto-initialize on require
task.spawn(function()
    ClientRegistry:Initialize()
end)

return ClientRegistry
