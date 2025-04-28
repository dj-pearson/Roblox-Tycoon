--!strict
--[[
    ModuleLoaderHelper.luau
    
    Helper utility for loading modules consistently across both server and client.
    Provides a simplified interface for finding and requiring modules with error handling.
    
    Created: April 27, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    DEBUG_MODE = true,
    DEFAULT_TIMEOUT = 5
}

-- Internal state
local moduleCache = {}
local coreRegistry = nil
local moduleLoader = nil

-- Logging
local function log(message)
    if CONFIG.DEBUG_MODE then
        print("[ModuleLoaderHelper] " .. message)
    end
end

-- Get shared folder with retry
local function getSharedFolder()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared then
        return shared
    end
    
    -- Try to wait for it with timeout
    local startTime = os.clock()
    while os.clock() - startTime < CONFIG.DEFAULT_TIMEOUT do
        shared = ReplicatedStorage:FindFirstChild("shared")
        if shared then
            return shared
        end
        task.wait(0.1)
    end
    
    warn("[ModuleLoaderHelper] Failed to find shared folder")
    return nil
end

-- Safe require utility (inline implementation to avoid circular dependencies)
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
        warn("[ModuleLoaderHelper] Failed to require " .. module:GetFullName() .. ": " .. tostring(result))
        return fallback
    end
end

-- Get the ModuleLoader reference
local function getModuleLoader()
    if moduleLoader then
        return moduleLoader
    end
    
    local shared = getSharedFolder()
    if not shared then
        warn("[ModuleLoaderHelper] Shared folder not found")
        return nil
    end
    
    local moduleLoaderScript = shared:FindFirstChild("ModuleLoader")
    if not moduleLoaderScript then
        warn("[ModuleLoaderHelper] ModuleLoader not found")
        return nil
    end
    
    moduleLoader = safeRequire(moduleLoaderScript)
    return moduleLoader
end

-- Get module using either ModuleLoader or direct require
local function getModule(moduleName, fallback)
    -- Check cache first
    if moduleCache[moduleName] then
        return moduleCache[moduleName]
    end
    
    -- Try using ModuleLoader first
    local loader = getModuleLoader()
    if loader and loader.LoadModule then
        local module = loader.LoadModule(moduleName, fallback)
        if module then
            moduleCache[moduleName] = module
            return module
        end
    end
    
    -- Fallback to direct require from shared folder
    local shared = getSharedFolder()
    if shared then
        local moduleScript = shared:FindFirstChild(moduleName)
        if moduleScript then
            local module = safeRequire(moduleScript, fallback)
            if module then
                moduleCache[moduleName] = module
                return module
            end
        end
    end
    
    -- Try in ReplicatedStorage root as last resort
    local rootModule = ReplicatedStorage:FindFirstChild(moduleName)
    if rootModule then
        local module = safeRequire(rootModule, fallback)
        if module then
            moduleCache[moduleName] = module
            return module
        end
    end
    
    -- Return fallback if all else fails
    return fallback
end

-- Get the CoreRegistry instance
local function getCoreRegistry()
    -- Return cached instance if available
    if coreRegistry then
        return coreRegistry
    end
    
    -- Check global registry first
    if _G.CoreRegistry then
        coreRegistry = _G.CoreRegistry
        return coreRegistry
    end
    
    -- Try to load through ModuleLoader
    local loader = getModuleLoader()
    if loader then
        coreRegistry = loader.LoadModule("CoreRegistry")
        if coreRegistry then
            return coreRegistry
        end
    end
      -- Try direct require from ServerScriptService.Core
    local ServerScriptService = game:GetService("ServerScriptService")
    if ServerScriptService:FindFirstChild("Core") then
        local registryModule = ServerScriptService.Core:FindFirstChild("CoreRegistry")
        if registryModule then
            coreRegistry = safeRequire(registryModule)
            if coreRegistry then
                return coreRegistry
            end
        end
    end
    
    warn("[ModuleLoaderHelper] CoreRegistry not found")
    return nil
end

-- Get a system from CoreRegistry
local function getSystem(systemName, fallback)
    local registry = getCoreRegistry()
    if not registry then
        return fallback
    end
    
    if typeof(registry.getSystem) ~= "function" then
        warn("[ModuleLoaderHelper] Invalid CoreRegistry - missing getSystem method")
        return fallback
    end
    
    return registry.getSystem(systemName) or fallback
end

-- Register a system with CoreRegistry
local function registerSystem(systemName, system, dependencies)
    local registry = getCoreRegistry()
    if not registry then
        warn("[ModuleLoaderHelper] Cannot register system - CoreRegistry not found")
        return false
    end
      if typeof(registry.registerSystem) ~= "function" then
        warn("[ModuleLoaderHelper] Invalid CoreRegistry - missing registerSystem method")
        return false
    end
    
    registry.registerSystem(systemName, system, dependencies)
    return true
end

-- Return the module API
return {
    GetModule = getModule,
    GetCoreRegistry = getCoreRegistry,
    GetSystem = getSystem,
    RegisterSystem = registerSystem,
    SafeRequire = safeRequire,
    SetDebugMode = function(enabled)
        CONFIG.DEBUG_MODE = enabled
    end
}
