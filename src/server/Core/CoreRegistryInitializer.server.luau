--[[
    CoreRegistryInitializer.server.luau
    
    A robust initializer for the CoreRegistry that ensures it's properly loaded
    early in the game lifecycle and handles dependency resolution.
    
    Created: April 25, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    RETRY_COUNT = 3,
    RETRY_DELAY = 1,
    ENSURE_CRITICAL_SYSTEMS = true
}

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[CoreRegistryInitializer] " .. message)
    end
end

local function warn_log(message)
    warn("[CoreRegistryInitializer] " .. message)
end

-- Safe require utility
local function safeRequire(module)
    if not module then
        return nil
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        warn_log("Failed to require module: " .. module:GetFullName() .. " - " .. tostring(result))
        return nil
    end
    
    return result
end

-- Find folder with fallbacks
local function findFolder(parent, childName, createIfMissing)
    local child = parent:FindFirstChild(childName)
    if child and child:IsA("Folder") then
        return child
    end
    
    -- Try alternative casing
    if childName:lower() == "core" then
        child = parent:FindFirstChild("Core")
        if child and child:IsA("Folder") then
            return child
        end
    end
    
    -- Create if requested and not found
    if createIfMissing then
        log("Creating missing folder: " .. childName .. " in " .. parent:GetFullName())
        local newFolder = Instance.new("Folder")
        newFolder.Name = childName
        newFolder.Parent = parent
        return newFolder
    end
    
    return nil
end

-- Ensure ModuleLoader is available
local function ensureModuleLoader()
    log("Ensuring ModuleLoader is available...")
    
    -- Find shared folder or create it
    local shared = findFolder(ReplicatedStorage, "shared", true)
    
    -- Check if ModuleLoader exists
    local moduleLoader = shared:FindFirstChild("ModuleLoader")
    if moduleLoader and moduleLoader:IsA("ModuleScript") then
        log("Found existing ModuleLoader")
        
        -- Initialize ModuleLoader
        local success, loader = pcall(function()
            local ml = require(moduleLoader)
            if typeof(ml.initialize) == "function" then
                ml.initialize()
            end
            return ml
        end)
        
        if success then
            log("Successfully initialized ModuleLoader")
            return loader
        else
            warn_log("Failed to initialize existing ModuleLoader: " .. tostring(loader))
        end
    end
    
    -- Look for ModuleLoader in src/shared
    local srcShared = ServerScriptService:FindFirstChild("src") and 
                      ServerScriptService.src:FindFirstChild("shared")
    
    if srcShared and srcShared:FindFirstChild("ModuleLoader") then
        log("Found ModuleLoader in src/shared, copying to ReplicatedStorage.shared")
        local sourceMl = srcShared.ModuleLoader
        local copiedMl = sourceMl:Clone()
        copiedMl.Parent = shared
        
        -- Initialize ModuleLoader
        local success, loader = pcall(function()
            local ml = require(copiedMl)
            if typeof(ml.initialize) == "function" then
                ml.initialize()
            end
            return ml
        end)
        
        if success then
            log("Successfully initialized ModuleLoader from src/shared")
            return loader
        else
            warn_log("Failed to initialize ModuleLoader from src/shared: " .. tostring(loader))
        end
    end
    
    -- Create minimal ModuleLoader if necessary
    warn_log("Could not find ModuleLoader, creating a minimal version")
    
    local minimalModuleLoader = Instance.new("ModuleScript")
    minimalModuleLoader.Name = "ModuleLoader"
    minimalModuleLoader.Source = [[
--!strict
-- Minimal ModuleLoader implementation
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Default search paths
local searchPaths = {
    ReplicatedStorage,
    ReplicatedStorage:FindFirstChild("shared"),
    ServerScriptService,
    ServerScriptService:FindFirstChild("Core")
}

local ModuleLoader = {
    searchPaths = searchPaths,
    loadedModules = {}
}

function ModuleLoader.tryRequire(moduleName)
    -- Try each search path
    for _, path in ipairs(searchPaths) do
        if path then
            local moduleScript = path:FindFirstChild(moduleName)
            if moduleScript and moduleScript:IsA("ModuleScript") then
                local success, result = pcall(function()
                    return require(moduleScript)
                end)
                
                if success then
                    return result
                end
            end
        end
    end
    
    return nil
end

function ModuleLoader.initialize()
    -- Add more search paths
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared then
        table.insert(searchPaths, 1, shared)
    end
    
    local core = ServerScriptService:FindFirstChild("Core")
    if core then
        table.insert(searchPaths, 1, core)
    end
    
    return ModuleLoader
end

-- Backwards compatibility
ModuleLoader.require = ModuleLoader.tryRequire
ModuleLoader.LoadServerModule = function(_, _, name) 
    return ModuleLoader.tryRequire(name)
end

return ModuleLoader
]]
    minimalModuleLoader.Parent = shared
    
    -- Initialize minimal ModuleLoader
    local success, loader = pcall(function()
        local ml = require(minimalModuleLoader)
        if typeof(ml.initialize) == "function" then
            ml.initialize()
        end
        return ml
    end)
    
    if success then
        log("Created and initialized minimal ModuleLoader")
        return loader
    else
        warn_log("Failed to initialize minimal ModuleLoader: " .. tostring(loader))
        return nil
    end
end

-- Find or create the CoreRegistry
local function initializeCoreRegistry()
    log("Initializing CoreRegistry...")
    
    -- Ensure Core folder exists
    local core = findFolder(ServerScriptService, "Core", true)
    
    -- Check if CoreRegistry already exists
    local existingRegistry = core:FindFirstChild("CoreRegistry")
    if existingRegistry and existingRegistry:IsA("ModuleScript") then
        log("Found existing CoreRegistry")
        
        -- Try to require it
        local success, registry = pcall(function()
            return require(existingRegistry)
        end)
        
        if success and registry then
            log("Successfully loaded existing CoreRegistry")
            _G.CoreRegistry = registry
            return registry
        else
            warn_log("Failed to load existing CoreRegistry: " .. tostring(registry))
        end
    end
    
    -- Look for CoreRegistry in src/server/Core
    local srcRegistry = ServerScriptService:FindFirstChild("src") and
                        ServerScriptService.src:FindFirstChild("server") and
                        ServerScriptService.src.server:FindFirstChild("Core") and
                        ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry")
    
    if srcRegistry and srcRegistry:IsA("ModuleScript") then
        log("Found CoreRegistry in src/server/Core, copying to ServerScriptService.Core")
        local copiedRegistry = srcRegistry:Clone()
        copiedRegistry.Parent = core
        
        -- Try to require it
        local success, registry = pcall(function()
            return require(copiedRegistry)
        end)
        
        if success and registry then
            log("Successfully loaded CoreRegistry from src/server/Core")
            _G.CoreRegistry = registry
            return registry
        else
            warn_log("Failed to load CoreRegistry from src/server/Core: " .. tostring(registry))
        end
    end
    
    -- Create a minimal CoreRegistry if necessary
    warn_log("Could not find CoreRegistry, creating a minimal version")
    
    local minimalRegistry = Instance.new("ModuleScript")
    minimalRegistry.Name = "CoreRegistry"
    minimalRegistry.Source = [[
-- Minimal CoreRegistry implementation
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Try to use ModuleLoader if it exists
local ModuleLoader
local loaderSuccess, loaderResult = pcall(function()
    return require(ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("ModuleLoader"))
end)

if loaderSuccess then
    ModuleLoader = loaderResult
    print("[CoreRegistry] Successfully loaded ModuleLoader")
else
    print("[CoreRegistry] ModuleLoader not found, using legacy loading")
end

-- Create the registry table
local CoreRegistry = {
    systems = {},     -- Systems that have been registered
    initialized = {}, -- Systems that have been initialized
    loading = {},     -- Systems currently being initialized (to detect circular dependencies)
    moduleLoader = ModuleLoader -- Store ModuleLoader reference for other systems to use
}

-- Debug function
local function log(...)
    print("[CoreRegistry]", ...)
end

-- Register a system with the registry
function CoreRegistry.registerSystem(name, system, dependencies)
    if CoreRegistry.systems[name] then
        log("Warning: System '" .. name .. "' already registered, overwriting")
    end
    
    CoreRegistry.systems[name] = {
        module = system,
        dependencies = dependencies or {}
    }
    
    log("Registered system: " .. name)
    return system
end

-- Get a system and ensure it's initialized
function CoreRegistry.getSystem(name)
    -- Return already initialized system
    if CoreRegistry.initialized[name] then
        return CoreRegistry.initialized[name]
    end
    
    -- Check if system exists
    if not CoreRegistry.systems[name] then
        -- Try to load it directly using ModuleLoader if available
        if ModuleLoader then
            local module = ModuleLoader.tryRequire(name)
            if module then
                CoreRegistry.registerSystem(name, module, {})
                log("Auto-loaded system '" .. name .. "' using ModuleLoader")
            else
                -- Try direct requires as a last resort
                local success, result = pcall(function()
                    if ServerScriptService.Core and ServerScriptService.Core:FindFirstChild(name) then
                        return require(ServerScriptService.Core:FindFirstChild(name))
                    end
                    return nil
                end)
                
                if success and result then
                    CoreRegistry.registerSystem(name, result, {})
                    log("Auto-loaded system '" .. name .. "' using direct require")
                else
                    log("System not found: " .. name)
                    return nil
                end
            end
        else
            log("System not found and ModuleLoader not available: " .. name)
            return nil
        end
    end
    
    -- Detect circular dependencies
    if CoreRegistry.loading[name] then
        log("Error: Circular dependency detected for system: " .. name)
        return nil
    end
    
    -- Mark as loading
    CoreRegistry.loading[name] = true
    
    -- Initialize the system
    local system = CoreRegistry.systems[name].module
    if type(system.initialize) == "function" then
        log("Initializing system: " .. name)
        local success, errorMsg = pcall(function()
            system:initialize()
        end)
        
        if not success then
            log("Error initializing system '" .. name .. "': " .. tostring(errorMsg))
        end
    end
    
    -- Mark as initialized and no longer loading
    CoreRegistry.initialized[name] = system
    CoreRegistry.loading[name] = nil
    
    return system
end

-- Create a basic EventBridge system if it doesn't exist yet
local EventBridge = {
    events = {},
    remoteEvents = {},
    
    initialize = function()
        log("EventBridge initialized")
        return true
    end,
    
    getOrCreateEvent = function(self, eventName)
        if not self.events[eventName] then
            self.events[eventName] = {
                callbacks = {}
            }
        end
        return self.events[eventName]
    end,
    
    fireEvent = function(self, eventName, ...)
        local event = self.events[eventName]
        if event then
            for _, callback in ipairs(event.callbacks) do
                task.spawn(function()
                    callback(...)
                end)
            end
        end
    end,
    
    connectEvent = function(self, eventName, callback)
        local event = self:getOrCreateEvent(eventName)
        table.insert(event.callbacks, callback)
    end
}

-- Register core EventBridge system first
CoreRegistry.registerSystem("EventBridge", EventBridge, {})

return CoreRegistry
]]
    minimalRegistry.Parent = core
    
    -- Try to require it
    local success, registry = pcall(function()
        return require(minimalRegistry)
    end)
    
    if success and registry then
        log("Created and initialized minimal CoreRegistry")
        _G.CoreRegistry = registry
        return registry
    else
        warn_log("Failed to initialize minimal CoreRegistry: " .. tostring(registry))
        return nil
    end
end

-- Ensure critical systems exist and are registered
local function ensureCriticalSystems(registry)
    if not registry then
        warn_log("Cannot ensure critical systems - CoreRegistry is nil")
        return false
    end
    
    log("Ensuring critical systems are available...")
    
    -- List of critical systems to check
    local criticalSystems = {
        -- Core systems
        {name = "EventBridge", moduleName = "EventBridge", dependencies = {}},
        {name = "DataThrottler", moduleName = "DataThrottler", dependencies = {}},
        {name = "TutorialManager", moduleName = "TutorialManager", dependencies = {"EventBridge"}},
        {name = "CoreRegistry", moduleName = "CoreRegistry", dependencies = {}},
        {name = "MigrationUtils", moduleName = "MigrationUtils", dependencies = {}},
        
        -- Path registration and module loading helpers
        {name = "ModuleLoaderHelper", moduleName = "ModuleLoaderHelper", dependencies = {}},
        {name = "PathRegistration", moduleName = "PathRegistration", dependencies = {}},
        {name = "FolderSetup", moduleName = "FolderSetup", dependencies = {}}
    }
    
    -- Check each critical system
    for _, system in ipairs(criticalSystems) do
        -- Check if already registered
        if registry.systems[system.name] or registry.initialized[system.name] then
            log("System already registered: " .. system.name)
            continue
        end
        
        -- Try to load the system
        log("Looking for system: " .. system.name)
        
        -- Look for the module
        local core = findFolder(ServerScriptService, "Core", false)
        local moduleScript = nil
        
        if core then
            moduleScript = core:FindFirstChild(system.moduleName)
        end
        
        -- If found, require and register
        if moduleScript and moduleScript:IsA("ModuleScript") then
            local success, module = pcall(function()
                return require(moduleScript)
            end)
            
            if success and module then
                registry.registerSystem(system.name, module, system.dependencies)
                log("Registered critical system: " .. system.name)
            else
                warn_log("Failed to load critical system: " .. system.name)
            end
        else
            log("Module not found for critical system: " .. system.name)
        end
    end
    
    return true
end

-- Main initialization function
local function initialize()
    log("Starting Core Registry initialization...")
    
    -- Ensure the ModuleLoader is available
    local moduleLoader = ensureModuleLoader()
    if not moduleLoader then
        warn_log("Failed to initialize ModuleLoader, continuing with limited functionality")
    end
    
    -- Initialize the CoreRegistry
    local registry = initializeCoreRegistry()
    if not registry then
        warn_log("Failed to initialize CoreRegistry! Game systems may not function correctly.")
        return false
    end
    
    -- Store in global scope for emergency access
    if _G then
        _G.CoreRegistry = registry
        log("CoreRegistry stored in _G for global access")
    end
    
    -- Ensure critical systems exist
    if CONFIG.ENSURE_CRITICAL_SYSTEMS then
        ensureCriticalSystems(registry)
    end
    
    log("CoreRegistry initialization complete")
    return true
end

-- Run the initializer
local success, result = pcall(initialize)
if not success then
    warn_log("Error during initialization: " .. tostring(result))
end

return {
    ensureModuleLoader = ensureModuleLoader,
    initializeCoreRegistry = initializeCoreRegistry,
    ensureCriticalSystems = ensureCriticalSystems
}
