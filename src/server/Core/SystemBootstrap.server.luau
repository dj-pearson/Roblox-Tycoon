--[[
    SystemBootstrap.server.luau
    
    Initializes all core systems in the correct order.
    Sets up the server environment with proper dependencies.
    
    Created: April 27, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    INITIALIZATION_RETRIES = 3,
    INITIALIZATION_RETRY_DELAY = 2,
}

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[SystemBootstrap] " .. message)
    end
end

-- System initialization order
local SYSTEM_INIT_ORDER = {
    -- Core infrastructure
    "FolderSetup",
    "CoreRegistryInitializer",
    "ModuleLoader",
    "EventCreator",
    "PathRegistration",
    
    -- Game systems
    "DataManager",
    "TycoonManager",
    "PlayerManager",
    "MigrationUtils",
    "TutorialManager"
}

-- Safe wait for child with timeout
local function safeWaitForChild(parent, childName, timeoutSecs)
    if not parent then
        warn("[SystemBootstrap] Parent is nil when waiting for: " .. childName)
        return nil
    end
    
    -- Check if child already exists
    local child = parent:FindFirstChild(childName)
    if child then
        return child
    end
    
    timeoutSecs = timeoutSecs or 5
    
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
        warn("[SystemBootstrap] Timed out waiting for " .. childName .. " in " .. parent:GetFullName())
        return nil
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
        warn("[SystemBootstrap] Failed to require module: " .. module:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
end

-- Find and initialize CoreRegistry
local function initializeCoreRegistry()
    log("Initializing CoreRegistry...")
    
    -- Check if already in global scope
    if _G.CoreRegistry then
        log("CoreRegistry already initialized in global scope")
        return _G.CoreRegistry
    end
    
    -- Look for CoreRegistryInitializer
    local core = safeWaitForChild(ServerScriptService, "Core")
    if not core then
        warn("[SystemBootstrap] Core folder not found in ServerScriptService")
        return nil
    end
    
    local initializerScript = core:FindFirstChild("CoreRegistryInitializer")
    if initializerScript and initializerScript:IsA("ModuleScript") then
        log("Found CoreRegistryInitializer module, requiring it")
        safeRequire(initializerScript)
        
        -- Wait a moment for initialization to complete
        task.wait(0.5)
        
        -- Check if CoreRegistry is now available
        if _G.CoreRegistry then
            log("CoreRegistry initialized through CoreRegistryInitializer")
            return _G.CoreRegistry
        end
    end
    
    -- Try direct require of CoreRegistry
    local registryModule = core:FindFirstChild("CoreRegistry")
    if registryModule and registryModule:IsA("ModuleScript") then
        log("Found CoreRegistry module, requiring it directly")
        local registry = safeRequire(registryModule)
        
        if registry then
            -- Store in global scope for emergency access
            _G.CoreRegistry = registry
            log("CoreRegistry stored in _G for global access")
            return registry
        end
    end
    
    warn("[SystemBootstrap] Failed to initialize CoreRegistry")
    return nil
end

-- Find and initialize a module from the Core folder
local function initializeModule(moduleName)
    log("Initializing module: " .. moduleName)
    
    -- Find the module in Core
    local core = safeWaitForChild(ServerScriptService, "Core")
    if not core then
        warn("[SystemBootstrap] Core folder not found when initializing " .. moduleName)
        return nil
    end
    
    -- Look for the module in multiple locations
    local moduleScript = core:FindFirstChild(moduleName)
    if not moduleScript then
        local scriptModule = ServerScriptService:FindFirstChild(moduleName)
        if scriptModule and scriptModule:IsA("Script") then
            log("Found " .. moduleName .. " as a Script, cannot require")
            return true -- Script will run automatically, not a module
        end
    end
    
    -- If found as a ModuleScript, require it
    if moduleScript and moduleScript:IsA("ModuleScript") then
        local module = safeRequire(moduleScript)
        if module then
            -- If it's a proper system module with initialization
            if module.initialize and type(module.initialize) == "function" then
                log("Initializing system module: " .. moduleName)
                local success, result = pcall(function()
                    return module:initialize()
                end)
                
                if not success then
                    warn("[SystemBootstrap] Failed to initialize " .. moduleName .. ": " .. tostring(result))
                    return nil
                end
                
                log("Successfully initialized: " .. moduleName)
                return module
            end
            
            log("Module loaded but has no initialize method: " .. moduleName)
            return module
        end
    end
    
    warn("[SystemBootstrap] Could not find or initialize module: " .. moduleName)
    return nil
end

-- Initialize ModuleLoader system
local function initializeModuleLoader()
    log("Initializing ModuleLoader and registering paths...")
    
    -- Check if already available globally
    if _G.ModuleLoader then
        log("ModuleLoader already available globally")
        return _G.ModuleLoader
    end
    
    -- Try shared folder
    local shared = safeWaitForChild(ReplicatedStorage, "shared")
    if shared then
        local moduleLoaderScript = shared:FindFirstChild("ModuleLoader")
        if moduleLoaderScript and moduleLoaderScript:IsA("ModuleScript") then
            local moduleLoader = safeRequire(moduleLoaderScript)
            
            if moduleLoader then
                if type(moduleLoader.Initialize) == "function" then
                    moduleLoader.Initialize()
                end
                
                -- Store globally for convenience
                _G.ModuleLoader = moduleLoader
                
                -- Register module loader with CoreRegistry if available
                if _G.CoreRegistry and _G.CoreRegistry.registerSystem then
                    _G.CoreRegistry.registerSystem("ModuleLoader", moduleLoader, {})
                end
                
                log("ModuleLoader initialized successfully")
                return moduleLoader
            end
        end
    end
    
    warn("[SystemBootstrap] Failed to initialize ModuleLoader")
    return nil
end

-- Initialize necessary systems for server startup
local function initializeSystems()
    log("Initializing systems...")
    
    -- Initialize systems in the defined order
    for _, systemName in ipairs(SYSTEM_INIT_ORDER) do
        -- Skip CoreRegistry, handle it specially
        if systemName == "CoreRegistry" or systemName == "CoreRegistryInitializer" then
            continue
        end
        
        -- Skip ModuleLoader, handled specially
        if systemName == "ModuleLoader" then
            initializeModuleLoader()
            continue
        end
        
        -- Initialize regular module
        local system = initializeModule(systemName)
        
        -- Register with CoreRegistry if available
        if system and _G.CoreRegistry and _G.CoreRegistry.registerSystem and 
           systemName ~= "CoreRegistry" and systemName ~= "CoreRegistryInitializer" then
            _G.CoreRegistry.registerSystem(systemName, system, {})
            log("Registered system with CoreRegistry: " .. systemName)
        end
    end
    
    log("System initialization complete")
end

-- Main bootstrap function
local function bootstrap()
    log("Starting system bootstrap...")
    
    -- Initialize CoreRegistry first
    local registry = initializeCoreRegistry()
    if not registry then
        warn("[SystemBootstrap] CoreRegistry initialization failed")
        -- Retry CoreRegistry initialization
        for i = 1, CONFIG.INITIALIZATION_RETRIES do
            log("Retrying CoreRegistry initialization (" .. i .. "/" .. CONFIG.INITIALIZATION_RETRIES .. ")")
            task.wait(CONFIG.INITIALIZATION_RETRY_DELAY)
            
            registry = initializeCoreRegistry()
            if registry then
                log("CoreRegistry initialized successfully on retry " .. i)
                break
            end
        end
    end
    
    -- Initialize other systems
    initializeSystems()
    
    -- Final health check
    if not _G.CoreRegistry then
        warn("[SystemBootstrap] CRITICAL: CoreRegistry not available after initialization!")
    else
        log("CoreRegistry available in global scope")
    end
    
    log("System bootstrap complete")
end

-- Run the bootstrap
bootstrap()

return {
    reinitialize = bootstrap
}
