--!strict
--[[
    ModuleLoaderHelper.luau
    
    Helper utility for loading modules across both server and client.
    Provides consistent interface for requiring modules with error handling.
    
    Created: April 26, 2025
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,      -- Enable debug logging
    MAX_RETRY_COUNT = 2,       -- Number of retries for module loading
    RETRY_DELAY = 0.5,         -- Delay between retries (seconds)
    USE_MODULE_LOADER = true   -- Try to use ModuleLoader if available
}

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[ModuleLoaderHelper] " .. message)
    end
end

local function warn_log(message)
    warn("[ModuleLoaderHelper] " .. message)
end

-- Table of standard paths for module lookup
local standardPaths = {
    -- Core paths
    core = {
        RunService:IsServer() and ServerScriptService:FindFirstChild("Core"),
        RunService:IsServer() and ServerScriptService:FindFirstChild("Core"):FindFirstChild("Systems"),
        RunService:IsClient() and ReplicatedStorage:FindFirstChild("Core"),
        RunService:IsClient() and ReplicatedStorage:FindFirstChild("client"):FindFirstChild("Core")
    },
    
    -- Shared paths
    shared = {
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("src"):FindFirstChild("shared")
    },
    
    -- Client paths
    client = {
        RunService:IsClient() and ReplicatedStorage:FindFirstChild("client"),
        RunService:IsClient() and ReplicatedStorage:FindFirstChild("src"):FindFirstChild("client")
    },
    
    -- Server paths
    server = {
        RunService:IsServer() and ServerScriptService,
        RunService:IsServer() and ServerScriptService:FindFirstChild("Systems"),
        RunService:IsServer() and ServerScriptService:FindFirstChild("Core")
    }
}

-- Find module in standard locations
local function findModule(moduleName, context)
    context = context or "core"
    
    -- First, check direct path if provided with dot notation
    if string.find(moduleName, "%.") then
        local segments = string.split(moduleName, ".")
        local instance = game
        
        for _, segment in ipairs(segments) do
            instance = instance:FindFirstChild(segment)
            if not instance then
                break
            end
        end
        
        if instance and instance:IsA("ModuleScript") then
            return instance
        end
    end
    
    -- Then check standard paths based on context
    local paths = standardPaths[context:lower()] or standardPaths.core
    
    for _, path in ipairs(paths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    -- Special cases for common modules
    if moduleName == "CoreRegistry" and RunService:IsServer() then
        -- Direct path for CoreRegistry
        local coreRegistry = ServerScriptService:FindFirstChild("Core"):FindFirstChild("CoreRegistry")
        if coreRegistry and coreRegistry:IsA("ModuleScript") then
            return coreRegistry
        end
    elseif moduleName == "ClientRegistry" and RunService:IsClient() then
        -- Direct path for ClientRegistry
        local clientRegistry = ReplicatedStorage:FindFirstChild("client"):FindFirstChild("ClientRegistry")
        if clientRegistry and clientRegistry:IsA("ModuleScript") then
            return clientRegistry
        end
    end
    
    return nil
end

-- Try to load ModuleLoader
local ModuleLoader
local success, result = pcall(function()
    if ReplicatedStorage:FindFirstChild("shared") and 
       ReplicatedStorage.shared:FindFirstChild("ModuleLoader") then
        return require(ReplicatedStorage.shared.ModuleLoader)
    end
    return nil
end)

if success and result then
    ModuleLoader = result
    log("Found ModuleLoader")
else
    log("ModuleLoader not found, using direct requires")
end

-- Main module object
local ModuleLoaderHelper = {}

-- Load a module with error handling and retries
function ModuleLoaderHelper.require(moduleName, context)
    if not moduleName then
        warn_log("Module name is nil")
        return nil
    end
    
    -- Check if we have ModuleLoader and should use it
    if ModuleLoader and CONFIG.USE_MODULE_LOADER then
        local loaderResult
        
        if RunService:IsServer() then
            loaderResult = ModuleLoader.LoadServerModule and ModuleLoader:LoadServerModule(context, moduleName)
        else
            loaderResult = ModuleLoader.LoadClientModule and ModuleLoader:LoadClientModule(context, moduleName)
        end
        
        if loaderResult then
            return loaderResult
        end
        
        -- Fall through if ModuleLoader failed
        log("ModuleLoader failed to load " .. moduleName .. ", falling back to direct require")
    end
    
    -- Find the module instance
    local moduleInstance = findModule(moduleName, context)
    if not moduleInstance then
        warn_log("Module not found: " .. moduleName)
        return nil
    end
    
    -- Try to require the module
    local retryCount = 0
    while retryCount <= CONFIG.MAX_RETRY_COUNT do
        local requireSuccess, requireResult = pcall(function()
            return require(moduleInstance)
        end)
        
        if requireSuccess then
            return requireResult
        end
        
        -- Log failure and retry
        warn_log("Failed to require " .. moduleName .. " (attempt " .. (retryCount + 1) .. 
                "): " .. tostring(requireResult))
        
        retryCount = retryCount + 1
        
        if retryCount <= CONFIG.MAX_RETRY_COUNT then
            task.wait(CONFIG.RETRY_DELAY)
        end
    end
    
    warn_log("All attempts to load " .. moduleName .. " failed")
    return nil
end

-- Get CoreRegistry using the most reliable method
function ModuleLoaderHelper.getCoreRegistry()
    -- First check global registry (should have been set up by CoreRegistryInitializer)
    if _G.CoreRegistry then
        return _G.CoreRegistry
    end
    
    -- Next try to require it directly
    local coreRegistry = ModuleLoaderHelper.require("CoreRegistry", "core")
    if coreRegistry then
        -- Store for future quick access
        if _G then
            _G.CoreRegistry = coreRegistry
        end
        return coreRegistry
    end
    
    -- Final attempt with direct path
    if RunService:IsServer() and ServerScriptService:FindFirstChild("Core") then
        local success, result = pcall(function()
            return require(ServerScriptService.Core.CoreRegistry)
        end)
        
        if success and result then
            -- Store for future quick access
            if _G then
                _G.CoreRegistry = result
            end
            return result
        end
    end
    
    warn_log("Failed to get CoreRegistry through all available methods")
    return nil
end

-- Get ClientRegistry on the client
function ModuleLoaderHelper.getClientRegistry()
    if not RunService:IsClient() then
        warn_log("Attempted to get ClientRegistry from server")
        return nil
    end
    
    -- Try to require it directly
    local clientRegistry = ModuleLoaderHelper.require("ClientRegistry", "client")
    if clientRegistry then
        return clientRegistry
    end
    
    warn_log("Failed to get ClientRegistry")
    return nil
end

-- Module system detection and integration
function ModuleLoaderHelper.initialize()
    -- Detect loading system and set appropriate flags
    -- This integrates with core systems as needed
    
    -- Try CoreRegistry integration
    local CoreRegistry = ModuleLoaderHelper.getCoreRegistry()
    if CoreRegistry and CoreRegistry.registerSystem then
        CoreRegistry.registerSystem("ModuleLoaderHelper", ModuleLoaderHelper, {})
        log("Registered with CoreRegistry")
    end
    
    -- Try ClientRegistry integration
    if RunService:IsClient() then
        local ClientRegistry = ModuleLoaderHelper.getClientRegistry()
        if ClientRegistry and ClientRegistry.registerSystem then
            ClientRegistry.registerSystem("ModuleLoaderHelper", ModuleLoaderHelper, {})
            log("Registered with ClientRegistry")
        end
    end
    
    return ModuleLoaderHelper
end

return ModuleLoaderHelper
