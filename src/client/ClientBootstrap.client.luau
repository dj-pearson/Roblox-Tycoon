--[[
    ClientBootstrap.client.luau
    
    Enhanced client initialization system for properly loading client-side
    modules and systems. Handles dependencies, error recovery,
    and provides diagnostic feedback.
    
    Created: April 27, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    RETRY_COUNT = 3,
    RETRY_DELAY = 1,
    DEFAULT_TIMEOUT = 5
}

-- Core modules to load
local CORE_MODULES = {
    "ClientRegistry",
    "UIComponents", 
    "EventBridge",
    "UIUtils",
    "DataManager"
}

-- Internal state
local initialized = false
local clientRegistry = nil
local moduleLoader = nil

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[ClientBootstrap] " .. message)
    end
end

-- Safe require utility
local function safeRequire(module, fallback)
    if not module then
        return fallback
    end
    
    if not module:IsA("ModuleScript") then
        return fallback
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("[ClientBootstrap] Failed to require module: " .. module:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
end

-- Safe wait for child with timeout
local function safeWaitForChild(parent, childName, timeoutSecs)
    if not parent then
        warn("[ClientBootstrap] Parent is nil when waiting for: " .. childName)
        return nil
    end
    
    -- Check if child already exists
    local child = parent:FindFirstChild(childName)
    if child then
        return child
    end
    
    timeoutSecs = timeoutSecs or CONFIG.DEFAULT_TIMEOUT
    
    -- Try using WaitForChild with a timeout
    local startTime = os.clock()
    local connection
    local foundChild
    
    connection = parent.ChildAdded:Connect(function(newChild)
        if newChild.Name == childName then
            foundChild = newChild
        end
    end)
    
    -- Wait until timeout or child is found
    while os.clock() - startTime < timeoutSecs and not foundChild do
        -- Check again in the loop
        child = parent:FindFirstChild(childName)
        if child then
            foundChild = child
            break
        end
        
        task.wait(0.1)
    end
    
    connection:Disconnect()
    
    if foundChild then
        return foundChild
    else
        warn("[ClientBootstrap] Timed out waiting for " .. childName .. " in " .. parent:GetFullName())
        return nil
    end
end

-- Ensure shared folder exists
local function getSharedFolder()
    return safeWaitForChild(ReplicatedStorage, "shared")
end

-- Find ModuleLoader and initialize it
local function initializeModuleLoader()
    log("Initializing ModuleLoader...")
    
    -- Try to find ModuleLoader in shared
    local shared = getSharedFolder()
    if not shared then
        warn("[ClientBootstrap] Shared folder not found, some functionality will be limited")
        return nil
    end
    
    local moduleLoaderScript = shared:FindFirstChild("ModuleLoader")
    if moduleLoaderScript then
        -- Try to require it
        moduleLoader = safeRequire(moduleLoaderScript)
        if moduleLoader then
            if typeof(moduleLoader.Initialize) == "function" then
                moduleLoader.Initialize()
            end
            log("ModuleLoader initialized successfully")
            return moduleLoader
        end
    end
    
    -- Look in other locations if not found
    local srcFolder = ReplicatedStorage:FindFirstChild("src")
    if srcFolder and srcFolder:FindFirstChild("shared") then
        moduleLoaderScript = srcFolder.shared:FindFirstChild("ModuleLoader")
        if moduleLoaderScript then
            moduleLoader = safeRequire(moduleLoaderScript)
            if moduleLoader then
                if typeof(moduleLoader.Initialize) == "function" then
                    moduleLoader.Initialize()
                end
                log("ModuleLoader initialized from src/shared")
                return moduleLoader
            end
        end
    end
    
    warn("[ClientBootstrap] ModuleLoader not found, some system initialization may fail")
    return nil
end

-- Find and require a module
local function findAndRequireModule(moduleName, fallback)
    -- Try using ModuleLoader if available
    if moduleLoader and typeof(moduleLoader.LoadModule) == "function" then
        local module = moduleLoader.LoadModule(moduleName, fallback)
        if module then
            return module
        end
    end
    
    -- Try shared folder
    local shared = getSharedFolder()
    if shared then
        local moduleScript = shared:FindFirstChild(moduleName)
        if moduleScript then
            return safeRequire(moduleScript, fallback)
        end
    end
    
    -- Try ReplicatedStorage root
    local rootModule = ReplicatedStorage:FindFirstChild(moduleName)
    if rootModule then
        return safeRequire(rootModule, fallback)
    end
    
    -- Try player scripts
    local core = Player.PlayerScripts:FindFirstChild("Core")
    if core then
        local moduleScript = core:FindFirstChild(moduleName)
        if moduleScript then
            return safeRequire(moduleScript, fallback)
        end
    end
    
    -- Try client scripts
    local client = Player.PlayerScripts:FindFirstChild("Client")
    if client and client:FindFirstChild("Core") then
        local moduleScript = client.Core:FindFirstChild(moduleName)
        if moduleScript then
            return safeRequire(moduleScript, fallback)
        end
    end
    
    warn("[ClientBootstrap] Could not find module for system: " .. moduleName)
    return fallback
end

-- Initialize client registry
local function initializeClientRegistry()
    log("Initializing ClientRegistry...")
    
    -- Look for ClientRegistry in shared folder
    clientRegistry = findAndRequireModule("ClientRegistry")
    
    -- Check if it's a valid registry
    if clientRegistry and typeof(clientRegistry.registerSystem) == "function" then
        log("ClientRegistry initialized successfully")
        
        -- Register ModuleLoader with the registry
        if moduleLoader then
            clientRegistry.registerSystem("ModuleLoader", moduleLoader, {})
        end
        
        return clientRegistry
    end
    
    -- Try to find ClientRegistryFixer as a fallback
    log("ClientRegistry not found or invalid, trying ClientRegistryFixer...")
    local fixer = findAndRequireModule("ClientRegistryFixer")
    if fixer and typeof(fixer.createRegistry) == "function" then
        clientRegistry = fixer.createRegistry()
        if clientRegistry then
            log("Created ClientRegistry using ClientRegistryFixer")
            return clientRegistry
        end
    end
    
    -- Create minimal registry if all else fails
    log("Creating minimal ClientRegistry...")
    clientRegistry = {
        systems = {},
        initialized = {},
        
        registerSystem = function(name, system, dependencies)
            clientRegistry.systems[name] = {
                module = system,
                dependencies = dependencies or {}
            }
            return system
        end,
        
        getSystem = function(name)
            if clientRegistry.initialized[name] then
                return clientRegistry.initialized[name]
            end
            
            if clientRegistry.systems[name] then
                local system = clientRegistry.systems[name].module
                if typeof(system.initialize) == "function" then
                    system:initialize()
                end
                clientRegistry.initialized[name] = system
                return system
            end
            
            return nil
        end,
        
        hasSystem = function(name)
            return clientRegistry.systems[name] ~= nil or clientRegistry.initialized[name] ~= nil
        end
    }
    
    log("Minimal ClientRegistry created")
    return clientRegistry
end

-- Initialize core systems
local function initializeCoreModules()
    log("Initializing core modules...")
    
    -- Initialize all core modules
    for _, moduleName in ipairs(CORE_MODULES) do
        log("Loading module: " .. moduleName)
        
        -- Skip if already registered
        if clientRegistry and clientRegistry.hasSystem and clientRegistry.hasSystem(moduleName) then
            log("Module already registered: " .. moduleName)
            continue
        end
        
        -- Try to load the module
        local module = findAndRequireModule(moduleName)
        if module then
            -- Register with ClientRegistry
            if clientRegistry and clientRegistry.registerSystem then
                clientRegistry.registerSystem(moduleName, module, {})
                log("Registered module: " .. moduleName)
            end
            
            -- Initialize if it has an initialize method
            if typeof(module.initialize) == "function" then
                local success, result = pcall(function()
                    return module:initialize()
                end)
                
                if not success then
                    warn("[ClientBootstrap] Failed to initialize module " .. moduleName .. ": " .. tostring(result))
                end
            end
        else
            warn("[ClientBootstrap] Failed to load core module: " .. moduleName)
        end
    end
end

-- Main initialization function
local function initialize()
    if initialized then
        return
    end
    
    log("Initializing client bootstrap...")
    
    -- Initialize ModuleLoader
    initializeModuleLoader()
    
    -- Initialize ClientRegistry
    initializeClientRegistry()
    
    -- Initialize core modules
    initializeCoreModules()
    
    -- Set initialization flag
    initialized = true
    
    log("Client bootstrap initialization complete")
    
    -- Store client registry in player
    Player:SetAttribute("ClientBootstrapInitialized", true)
    
    return true
end

-- Create a diagnostic report
local function createDiagnosticReport()
    local report = {
        moduleLoaderAvailable = moduleLoader ~= nil,
        clientRegistryAvailable = clientRegistry ~= nil,
        loadedSystems = {},
        missingCoreSystems = {}
    }
    
    -- List loaded systems
    if clientRegistry and clientRegistry.systems then
        for name, _ in pairs(clientRegistry.systems) do
            table.insert(report.loadedSystems, name)
        end
    end
    
    -- List missing core systems
    for _, moduleName in ipairs(CORE_MODULES) do
        if not clientRegistry or not clientRegistry.hasSystem or not clientRegistry.hasSystem(moduleName) then
            table.insert(report.missingCoreSystems, moduleName)
        end
    end
    
    return report
end

-- Run the initialization
local success, result = pcall(initialize)
if not success then
    warn("[ClientBootstrap] Error during initialization: " .. tostring(result))
end

-- Return the module API
return {
    getDiagnosticReport = createDiagnosticReport,
    getClientRegistry = function() return clientRegistry end,
    getModuleLoader = function() return moduleLoader end,
    reinitialize = initialize
}
