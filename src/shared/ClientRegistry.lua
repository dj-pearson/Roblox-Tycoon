--!strict
--[[
    ClientRegistry.lua
    
    This module serves as a bridge to access the ClientRegistry module
    from the client's PlayerScripts/Core directory.
    
    It uses SafeWaitForChild to avoid infinite yield issues and provides
    a fallback implementation to prevent errors when the actual module
    can't be found.
    
    Author: Pearson
    Date: April 25, 2025
]]

-- Get services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- The module table
local ClientRegistryBridge = {}

-- Returns the local player or nil if not on client
local function getLocalPlayer()
    if not RunService:IsClient() then
        warn("ClientRegistryBridge: Attempted to get LocalPlayer on server")
        return nil
    end
    
    return Players.LocalPlayer
end

-- Safely wait for a child with timeout
local function safeWaitForChild(parent, childName, timeout)
    timeout = timeout or 5
    
    local child = parent:FindFirstChild(childName)
    if child then return child end
    
    local startTime = os.clock()
    while os.clock() - startTime < timeout do
        child = parent:FindFirstChild(childName)
        if child then return child end
        task.wait(0.1)
    end
    
    warn("ClientRegistryBridge: Timed out waiting for " .. childName .. " in " .. parent:GetFullName())
    return nil
end

-- Attempt to find the real ClientRegistry module
local function findClientRegistry()
    -- Only attempt this on client
    local localPlayer = getLocalPlayer()
    if not localPlayer then
        return nil
    end
    
    -- First try the main expected path
    local playerScripts = localPlayer:FindFirstChild("PlayerScripts")
    if playerScripts then
        -- Try multiple possible paths for Core folder
        local coreFolders = {
            playerScripts:FindFirstChild("Core"),
            playerScripts:FindFirstChild("ClientCore"),
            playerScripts:FindFirstChild("client"):FindFirstChild("Core") 
        }
        
        for _, coreFolder in ipairs(coreFolders) do
            if coreFolder and coreFolder:FindFirstChild("ClientRegistry") then
                return coreFolder.ClientRegistry
            end
        end
    end
    
    -- Try the ClientReferences path
    local clientReferences = ReplicatedStorage:FindFirstChild("ClientReferences")
    if clientReferences and clientReferences:FindFirstChild("ClientRegistryReference") then
        return clientReferences.ClientRegistryReference
    end
    
    return nil
end

-- Create a mock ClientRegistry if needed
local function createMockClientRegistry()
    warn("ClientRegistryBridge: Creating fallback ClientRegistry")
    
    local mockRegistry = {
        systems = {},
        dependencies = {},
        initialized = {},
        loadingPromises = {}
    }
    
    function mockRegistry.registerSystem(systemName, systemModule)
        mockRegistry.systems[systemName] = systemModule
        return systemModule
    end
    
    function mockRegistry.getSystem(systemName)
        if mockRegistry.systems[systemName] then
            return mockRegistry.systems[systemName]
        end
        warn("Mock ClientRegistry: System not found: " .. systemName)
        return nil
    end
    
    function mockRegistry.waitForSystem(systemName, timeout)
        return mockRegistry.getSystem(systemName)
    end
    
    function mockRegistry.addDependencies(systemName, dependencies)
        mockRegistry.dependencies[systemName] = dependencies
    end
    
    function mockRegistry.initialize()
        -- No actual initialization needed for mock
        return true
    end
    
    return mockRegistry
end

-- Create a cache for the real module if we can find it
local cachedModule
local hasAttemptedLoad = false

-- Main getter function
local function getClientRegistryModule()
    if cachedModule then
        return cachedModule
    end
    
    if hasAttemptedLoad then
        return createMockClientRegistry()
    end
    
    hasAttemptedLoad = true
    
    local registryModule = findClientRegistry()
    if registryModule then
        -- Try to require the real module
        local success, result = pcall(function()
            return require(registryModule)
        end)
        
        if success and result then
            cachedModule = result
            return result
        else
            warn("ClientRegistryBridge: Failed to require ClientRegistry: ", result)
        end
    end
    
    return createMockClientRegistry()
end

-- Create a metatable to redirect all access to the real module
setmetatable(ClientRegistryBridge, {
    __index = function(_, key)
        local registry = getClientRegistryModule()
        return registry[key]
    end,
    
    __newindex = function(_, key, value)
        local registry = getClientRegistryModule()
        registry[key] = value
    end,
    
    __call = function(_, ...)
        local registry = getClientRegistryModule()
        if type(registry) == "function" then
            return registry(...)
        end
        error("ClientRegistryBridge: Cannot call ClientRegistry directly")
    end
})

-- If we're on the client, attempt to preload the real module
task.spawn(function()
    if RunService:IsClient() then
        getClientRegistryModule()
    end
end)

return ClientRegistryBridge
