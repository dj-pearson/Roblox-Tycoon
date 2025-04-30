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
    -- Search paths
    local searchPaths = {
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
    }
    
    -- Look in each path
    for _, path in ipairs(searchPaths) do
        if path then
            local moduleScript = path:FindFirstChild(moduleName)
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
    
    return registry[name]
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

-- Initialize with core systems
function ClientRegistry:Initialize()
    log("Initializing ClientRegistry...", "Info")
    
    -- Register self
    self:Register("ClientRegistry", self)
    
    -- Try to load and register essential modules
    local essentialModules = {
        "UIComponents", 
        "UIRegistry", 
        "AssetValidator",
        "ModuleLoader"
    }
    
    for _, moduleName in ipairs(essentialModules) do
        local moduleScript = findModule(moduleName)
        if moduleScript then
            local success, module = pcall(function()
                return require(moduleScript)
            end)
            
            if success and module then
                self:Register(moduleName, module)
                log("Auto-registered: " .. moduleName, "Success")
            else
                log("Failed to auto-register: " .. moduleName, "Error")
            end
        end
    end
    
    log("ClientRegistry initialization complete", "Success")
    return true
end

-- Auto-initialize
task.spawn(function()
    ClientRegistry:Initialize()
end)

return ClientRegistry
