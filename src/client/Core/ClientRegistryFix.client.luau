--[[
    ClientRegistryFix.client.luau
    
    This script fixes the ClientRegistry issues by ensuring it exists as a proper ModuleScript
    and handles the client-side registry functionality.
    
    Created to address Client System Missing Components issue identified in RobloxIssues.txt
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    debug = true,
    retryAttempts = 5,
    retryDelay = 1,
    forceFix = true -- Force fix even if it appears to exist
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[ClientRegistryFix]", ...)
    end
end

-- Create shared folder if it doesn't exist
local function ensureSharedFolder()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared then
        shared = Instance.new("Folder")
        shared.Name = "shared"
        shared.Parent = ReplicatedStorage
        log("Created shared folder in ReplicatedStorage")
    end
    return shared
end

-- Check if ClientRegistry exists and is valid
local function checkClientRegistry()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared then
        log("Shared folder does not exist")
        return false
    end
    
    local clientRegistry = shared:FindFirstChild("ClientRegistry")
    if not clientRegistry then
        log("ClientRegistry does not exist in shared folder")
        return false
    end
    
    if not clientRegistry:IsA("ModuleScript") then
        log("ClientRegistry exists but is not a ModuleScript, it's a", clientRegistry.ClassName)
        return false
    end
    
    -- Try to require it
    local success, result = pcall(function()
        return require(clientRegistry)
    end)
    
    if not success then
        log("ClientRegistry exists but failed to require:", result)
        return false
    end
    
    if type(result) ~= "table" then
        log("ClientRegistry did not return a table, it returned a", type(result))
        return false
    end
    
    log("ClientRegistry exists and is valid")
    return true
end

-- Fix the ClientRegistry
local function fixClientRegistry()
    local shared = ensureSharedFolder()
    
    -- Remove existing ClientRegistry if it's not a ModuleScript
    local existing = shared:FindFirstChild("ClientRegistry")
    if existing and not existing:IsA("ModuleScript") then
        log("Removing non-ModuleScript ClientRegistry")
        existing:Destroy()
        existing = nil
    end
    
    -- Create ClientRegistry if needed
    if not existing or CONFIG.forceFix then
        local clientRegistry = existing or Instance.new("ModuleScript")
        clientRegistry.Name = "ClientRegistry"
        
        -- Create a basic ClientRegistry module
        clientRegistry.Source = [[
-- ClientRegistry Module
-- A registry for client-side systems and components

local ClientRegistry = {}
ClientRegistry.VERSION = "1.0.0"
ClientRegistry.systems = {}
ClientRegistry.initialized = {}
ClientRegistry.isLoaded = true

-- Register a system
function ClientRegistry.registerSystem(name, system)
    if type(name) ~= "string" then
        warn("ClientRegistry: System name must be a string")
        return false
    end
    
    if type(system) ~= "table" then
        warn("ClientRegistry: System must be a table")
        return false
    end
    
    ClientRegistry.systems[name] = system
    print("ClientRegistry: Registered system:", name)
    return true
end

-- Get a system
function ClientRegistry.getSystem(name)
    if type(name) ~= "string" then
        warn("ClientRegistry: System name must be a string")
        return nil
    end
    
    local system = ClientRegistry.systems[name]
    if not system then
        -- Only warn if not in first 5 seconds of execution to reduce spam
        if os.clock() > 5 then
            warn("ClientRegistry: System not found:", name)
        end
        return nil
    end
    
    return system
end

-- Check if system exists
function ClientRegistry.hasSystem(name)
    return ClientRegistry.systems[name] ~= nil
end

-- Initialize a system
function ClientRegistry.initSystem(name, dependencies, initFunc)
    if ClientRegistry.initialized[name] then
        return true -- Already initialized
    end
    
    -- Check dependencies
    if dependencies and type(dependencies) == "table" then
        for _, depName in ipairs(dependencies) do
            if not ClientRegistry.hasSystem(depName) then
                warn("ClientRegistry: Required dependency not found:", depName, "for system:", name)
                return false
            end
        end
    end
    
    -- Initialize if function provided
    if initFunc and type(initFunc) == "function" then
        local success, result = pcall(initFunc)
        if not success then
            warn("ClientRegistry: Failed to initialize:", name, "-", result)
            return false
        end
    end
    
    -- Mark as initialized
    ClientRegistry.initialized[name] = true
    print("ClientRegistry: Initialized system:", name)
    return true
end

-- Get a list of all registered systems
function ClientRegistry.getRegisteredSystems()
    local systems = {}
    for name in pairs(ClientRegistry.systems) do
        table.insert(systems, name)
    end
    return systems
end

return ClientRegistry
]]
        
        clientRegistry.Parent = shared
        log("Created/Updated ClientRegistry module")
        
        -- Make sure it requires properly
        local success, result = pcall(function()
            return require(clientRegistry)
        end)
        
        if success then
            log("ClientRegistry requires successfully")
            return true
        else
            log("Failed to require new ClientRegistry:", result)
            return false
        end
    end
    
    return true
end

-- Ensure ClientRegistry in PlayerScripts.shared
local function ensureClientScriptRegistries()
    local player = Players.LocalPlayer
    if not player then
        log("LocalPlayer not found")
        return false
    end
    
    -- Ensure PlayerScripts.shared exists
    local playerScripts = player:FindFirstChild("PlayerScripts") or Instance.new("Folder")
    playerScripts.Name = "PlayerScripts"
    playerScripts.Parent = player
    
    local sharedFolder = playerScripts:FindFirstChild("shared") or Instance.new("Folder")
    sharedFolder.Name = "shared"
    sharedFolder.Parent = playerScripts
    
    -- Create a reference to ClientRegistry in ReplicatedStorage
    local clientRegistryRef = sharedFolder:FindFirstChild("ClientRegistry")
    if not clientRegistryRef and ReplicatedStorage.shared:FindFirstChild("ClientRegistry") then
        -- Create a reference ModuleScript
        clientRegistryRef = Instance.new("ModuleScript")
        clientRegistryRef.Name = "ClientRegistry"
        clientRegistryRef.Source = "return require(game:GetService('ReplicatedStorage').shared.ClientRegistry)"
        clientRegistryRef.Parent = sharedFolder
        log("Created ClientRegistry reference in PlayerScripts.shared")
    end
    
    return true
end

-- Main fix function with retries
local function runFix()
    local fixed = false
    
    for attempt = 1, CONFIG.retryAttempts do
        log("Fix attempt", attempt, "of", CONFIG.retryAttempts)
        
        if checkClientRegistry() and not CONFIG.forceFix then
            log("ClientRegistry already valid, no fix needed")
            fixed = true
            break
        end
        
        log("Attempting to fix ClientRegistry")
        fixed = fixClientRegistry()
        
        if fixed then
            -- Also ensure client script registries
            ensureClientScriptRegistries()
            log("Fix successful on attempt", attempt)
            break
        else
            log("Fix failed, retrying in", CONFIG.retryDelay, "seconds")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    if fixed then
        log("ClientRegistry fix completed successfully")
    else
        warn("[ClientRegistryFix] Failed to fix ClientRegistry after", CONFIG.retryAttempts, "attempts")
    end
    
    return fixed
end

-- Wait for player to be available
if not Players.LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

-- Run the fix
task.spawn(runFix)

-- Return a simple API
return {
    checkClientRegistry = checkClientRegistry,
    fixClientRegistry = fixClientRegistry,
    runFix = runFix
}
