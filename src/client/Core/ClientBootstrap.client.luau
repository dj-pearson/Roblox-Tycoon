--!strict
--[[
    ClientBootstrap.client.luau
    
    The main initialization script for the client-side systems.
    
    Created: April 25, 2025
    
    This script:
    1. Initializes ClientRegistry before any other client systems
    2. Adds robust error handling for failed system initializations
    3. Implements a dependency management system for correct loading order
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    error("[ClientBootstrap] No LocalPlayer found")
    return
end

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    RETRY_SYSTEM_INIT = true,
    MAX_RETRIES = 3,
    RETRY_DELAY = 1, -- seconds
    LOAD_TIMEOUT = 10 -- seconds for the total bootstrap process
}

-- Find shared folder
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
if not sharedFolder then
    warn("[ClientBootstrap] Shared folder not found, creating one")
    sharedFolder = Instance.new("Folder")
    sharedFolder.Name = "shared"
    sharedFolder.Parent = ReplicatedStorage
end

-- System initialization state tracking
local systemInitState = {
    complete = false,
    startTime = tick(),
    initializedSystems = {},
    failedSystems = {},
    pendingSystems = {},
    systemDependencies = {}
}

-- Logging function
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[ClientBootstrap] " .. message)
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
        warn("[ClientBootstrap] Failed to require module: ", module:GetFullName())
        return nil
    end
    
    return result
end

-- Check if system is initialized
local function isSystemInitialized(systemName)
    return systemInitState.initializedSystems[systemName] ~= nil
end

-- Register system dependencies
local function registerSystemDependencies(systemName, dependencies)
    if type(dependencies) ~= "table" then
        return false
    end
    
    systemInitState.systemDependencies[systemName] = dependencies
    return true
end

-- Check if all dependencies for a system are initialized
local function areDependenciesMet(systemName)
    local dependencies = systemInitState.systemDependencies[systemName]
    if not dependencies then
        return true -- No dependencies registered
    end
    
    for _, dependency in ipairs(dependencies) do
        if not isSystemInitialized(dependency) then
            return false
        end
    end
    
    return true
end

-- Try to get ModuleLoader
local ModuleLoader = requireSafely(sharedFolder:FindFirstChild("ModuleLoader"))
if not ModuleLoader then
    warn("[ClientBootstrap] ModuleLoader not found, some system initialization may fail")
end

-- Try to get ClientRegistryFixer
local ClientRegistryFixer = nil
if LocalPlayer.PlayerScripts:FindFirstChild("Client") and
   LocalPlayer.PlayerScripts.Client:FindFirstChild("Core") and
   LocalPlayer.PlayerScripts.Client.Core:FindFirstChild("ClientRegistryFixer") then
    ClientRegistryFixer = requireSafely(LocalPlayer.PlayerScripts.Client.Core.ClientRegistryFixer)
end

if not ClientRegistryFixer then
    warn("[ClientBootstrap] ClientRegistryFixer not found, attempting to continue without it")
end

-- Try to get ClientRegistry
local ClientRegistry = nil

-- If we have ClientRegistryFixer, use it to ensure ClientRegistry exists
if ClientRegistryFixer and typeof(ClientRegistryFixer.ensureClientRegistry) == "function" then
    log("Getting ClientRegistry through ClientRegistryFixer")
    ClientRegistry = ClientRegistryFixer.ensureClientRegistry()
else
    -- Try ModuleLoader first
    if ModuleLoader and typeof(ModuleLoader.tryRequire) == "function" then
        log("Trying to get ClientRegistry through ModuleLoader")
        ClientRegistry = ModuleLoader.tryRequire("ClientRegistry")
    end
    
    -- Try direct require as backup
    if not ClientRegistry then
        log("Trying to get ClientRegistry through direct require")
        -- Try in ReplicatedStorage
        if sharedFolder:FindFirstChild("ClientRegistry") then
            ClientRegistry = requireSafely(sharedFolder.ClientRegistry)
        end
        
        -- Try in PlayerScripts
        if not ClientRegistry then
            if LocalPlayer.PlayerScripts:FindFirstChild("Client") and 
               LocalPlayer.PlayerScripts.Client:FindFirstChild("Core") and
               LocalPlayer.PlayerScripts.Client.Core:FindFirstChild("ClientRegistry") then
                ClientRegistry = requireSafely(LocalPlayer.PlayerScripts.Client.Core.ClientRegistry)
            end
        end
    end
    
    if not ClientRegistry then
        error("[ClientBootstrap] Failed to get ClientRegistry, cannot proceed with initialization")
        return
    end
end

log("ClientRegistry found, proceeding with system initialization")

-- Initialize a system
local function initializeSystem(systemName, systemModule, dependencies)
    -- Skip if already initialized
    if isSystemInitialized(systemName) then
        return true
    end
    
    -- Register dependencies if provided
    if dependencies then
        registerSystemDependencies(systemName, dependencies)
    end
    
    -- Check if dependencies are met
    if not areDependenciesMet(systemName) then
        systemInitState.pendingSystems[systemName] = systemModule
        log("System " .. systemName .. " is waiting for dependencies")
        return false
    end
    
    log("Initializing system: " .. systemName)
    
    -- Try to initialize
    local success = pcall(function()
        -- If system has an initialize method, call it
        if systemModule and typeof(systemModule.initialize) == "function" then
            systemModule.initialize()
        end
        
        -- Register with ClientRegistry if available
        if ClientRegistry and typeof(ClientRegistry.registerSystem) == "function" then
            ClientRegistry:registerSystem(systemName, systemModule)
        end
    end)
    
    -- Track result
    if success then
        systemInitState.initializedSystems[systemName] = systemModule
        log("Successfully initialized system: " .. systemName)
        
        -- Remove from pending if it was there
        systemInitState.pendingSystems[systemName] = nil
        
        -- Check if we can initialize any pending systems now
        for pendingName, pendingModule in pairs(systemInitState.pendingSystems) do
            if areDependenciesMet(pendingName) then
                -- Try to initialize this pending system
                initializeSystem(pendingName, pendingModule)
            end
        end
        
        return true
    else
        systemInitState.failedSystems[systemName] = {
            module = systemModule,
            attempts = (systemInitState.failedSystems[systemName] and 
                        systemInitState.failedSystems[systemName].attempts or 0) + 1
        }
        
        warn("[ClientBootstrap] Failed to initialize system: " .. systemName)
        
        -- Retry if configured
        if CONFIG.RETRY_SYSTEM_INIT and 
           systemInitState.failedSystems[systemName].attempts < CONFIG.MAX_RETRIES then
            log("Will retry initializing " .. systemName .. " in " .. CONFIG.RETRY_DELAY .. " seconds")
            
            task.delay(CONFIG.RETRY_DELAY, function()
                initializeSystem(systemName, systemModule)
            end)
        end
        
        return false
    end
end

-- Core systems to initialize in order
local coreSystems = {
    -- UIComponents with no dependencies
    {
        name = "UIComponents",
        getModule = function()
            return ModuleLoader and ModuleLoader.tryRequire("UIComponents") or
                   requireSafely(sharedFolder:FindFirstChild("UIComponents"))
        end,
        dependencies = {}
    },
    
    -- AssetValidator with no dependencies
    {
        name = "AssetValidator",
        getModule = function()
            return ModuleLoader and ModuleLoader.tryRequire("AssetValidator") or
                   requireSafely(sharedFolder:FindFirstChild("AssetValidator"))
        end,
        dependencies = {}
    },
    
    -- UIRegistry depends on UIComponents
    {
        name = "UIRegistry",
        getModule = function()
            -- Try to find in PlayerScripts client folder
            if LocalPlayer.PlayerScripts:FindFirstChild("Client") and 
               LocalPlayer.PlayerScripts.Client:FindFirstChild("UI") and
               LocalPlayer.PlayerScripts.Client.UI:FindFirstChild("UIRegistry") then
                return requireSafely(LocalPlayer.PlayerScripts.Client.UI.UIRegistry)
            end
            
            -- Fallback to ModuleLoader
            return ModuleLoader and ModuleLoader.tryRequire("UIRegistry")
        end,
        dependencies = {"UIComponents"}
    },
    
    -- AssetHealthDashboard depends on AssetValidator and UIRegistry
    {
        name = "AssetHealthDashboard",
        getModule = function()
            -- Try to find in PlayerScripts client folder
            if LocalPlayer.PlayerScripts:FindFirstChild("Client") and 
               LocalPlayer.PlayerScripts.Client:FindFirstChild("UI") and
               LocalPlayer.PlayerScripts.Client.UI:FindFirstChild("AssetHealthDashboard") then
                return requireSafely(LocalPlayer.PlayerScripts.Client.UI.AssetHealthDashboard)
            end
            
            -- Fallback to ModuleLoader
            return ModuleLoader and ModuleLoader.tryRequire("AssetHealthDashboard")
        end,
        dependencies = {"AssetValidator", "UIRegistry"}
    },
    
    -- UISystemTester should be last as it tests all other systems
    {
        name = "UISystemTester",
        getModule = function()
            -- Try to find in PlayerScripts client folder
            if LocalPlayer.PlayerScripts:FindFirstChild("Client") and 
               LocalPlayer.PlayerScripts.Client:FindFirstChild("UI") and
               LocalPlayer.PlayerScripts.Client.UI:FindFirstChild("UISystemTester") then
                return requireSafely(LocalPlayer.PlayerScripts.Client.UI.UISystemTester)
            end
            
            -- Fallback to ModuleLoader
            return ModuleLoader and ModuleLoader.tryRequire("UISystemTester")
        end,
        dependencies = {"UIComponents", "UIRegistry", "AssetValidator"}
    }
}

-- Initialize core systems
log("Starting core system initialization...")

-- First initialize systems in order of dependencies
for _, system in ipairs(coreSystems) do
    local systemModule = system.getModule()
    if systemModule then
        initializeSystem(system.name, systemModule, system.dependencies)
    else
        warn("[ClientBootstrap] Could not find module for system: " .. system.name)
    end
end

-- Wait for remaining pending systems to initialize
task.spawn(function()
    local startWaitTime = tick()
    local maxWaitTime = CONFIG.LOAD_TIMEOUT
    
    while tick() - startWaitTime < maxWaitTime do
        -- Count pending systems
        local pendingCount = 0
        for _ in pairs(systemInitState.pendingSystems) do
            pendingCount += 1
        end
        
        if pendingCount == 0 then
            break
        end
        
        task.wait(0.5)
    end
    
    -- Check for any systems that didn't initialize
    local pendingCount = 0
    local pendingSystems = {}
    
    for systemName in pairs(systemInitState.pendingSystems) do
        pendingCount += 1
        table.insert(pendingSystems, systemName)
    end
    
    if pendingCount > 0 then
        warn("[ClientBootstrap] " .. pendingCount .. " systems did not initialize within timeout: " .. 
              table.concat(pendingSystems, ", "))
    end
    
    -- Generate final report
    local failedCount = 0
    local failedSystems = {}
    
    for systemName in pairs(systemInitState.failedSystems) do
        failedCount += 1
        table.insert(failedSystems, systemName)
    end
    
    local initCount = 0
    local initializedSystems = {}
    
    for systemName in pairs(systemInitState.initializedSystems) do
        initCount += 1
        table.insert(initializedSystems, systemName)
    end
    
    log("Initialization complete:")
    log("- Initialized Systems: " .. initCount .. " (" .. table.concat(initializedSystems, ", ") .. ")")
    
    if failedCount > 0 then
        warn("[ClientBootstrap] Failed Systems: " .. failedCount .. " (" .. table.concat(failedSystems, ", ") .. ")")
    else
        log("- All systems initialized successfully!")
    end
    
    if pendingCount > 0 then
        warn("[ClientBootstrap] Pending Systems: " .. pendingCount .. " (" .. table.concat(pendingSystems, ", ") .. ")")
    else
        log("- No pending systems remaining")
    end
    
    systemInitState.complete = true
    systemInitState.endTime = tick()
    log("Total initialization time: " .. string.format("%.2f", systemInitState.endTime - systemInitState.startTime) .. " seconds")
end)

-- Dynamic system loader function for other scripts to use
local function initializeAdditionalSystem(systemName, systemModule, dependencies)
    return initializeSystem(systemName, systemModule, dependencies)
end

-- Return the bootstrap interface
local ClientBootstrap = {
    initializeSystem = initializeAdditionalSystem,
    registerSystemDependencies = registerSystemDependencies,
    isSystemInitialized = isSystemInitialized,
    getSystemInitState = function() return systemInitState end,
    getClientRegistry = function() return ClientRegistry end
}

-- Register with ClientRegistry
if ClientRegistry and typeof(ClientRegistry.registerSystem) == "function" then
    ClientRegistry:registerSystem("ClientBootstrap", ClientBootstrap)
end

return ClientBootstrap
