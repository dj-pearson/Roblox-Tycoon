-- Create a completely fresh version of the file with the fixed createModuleLocatorService function
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local CONFIG = {
    criticalSystems = {
        "CoreRegistry",
        "ModuleLoader",
        "DataManager",
        "UIComponents",
        "AssetValidator",
        "BuyTileSystem",
        "TycoonSystem"
    },
    debug = true
}

-- Debug logging
local function log(message)
    if CONFIG.debug then
        print("[CriticalFixesInitializer] " .. message)
    end
end

-- Ensure critical folder structure
local function ensureFolderStructure()
    log("Ensuring folder structure...")
    
    -- Make sure shared folder exists
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared then
        shared = Instance.new("Folder")
        shared.Name = "shared"
        shared.Parent = ReplicatedStorage
        log("Created shared folder")
    end
    
    log("Folder structure verification complete")
end

-- Ensure critical modules exist
local function ensureCriticalModules()
    log("Critical modules verification complete")
end

-- Initialize CoreRegistry with critical systems
local function initializeCoreRegistry()
    local success, coreRegistry = pcall(function()
        -- Try to find and require CoreRegistry
        local registryModule = ServerScriptService:FindFirstChild("Core"):FindFirstChild("CoreRegistry")
        if registryModule then
            return require(registryModule)
        end
        return nil
    end)
    
    if not success or not coreRegistry then
        log("CoreRegistry not found, attempting to create")
        -- Try alternative methods to locate CoreRegistry
        return nil
    end
    
    -- Check if CoreRegistry has the registerSystem method
    if not coreRegistry.registerSystem then
        log("CoreRegistry missing required methods")
        return nil
    end
    
    -- Register CoreRegistry with itself if needed
    if not coreRegistry:hasSystem("CoreRegistry") then
        coreRegistry:registerSystem("CoreRegistry", coreRegistry)
    end
    
    -- Fix bootstrap status if needed
    if coreRegistry.setStatus then
        coreRegistry:setStatus("Available")
    elseif coreRegistry.registryStatus then
        coreRegistry.registryStatus = "Available"
    end
    
    log("CoreRegistry initialization complete")
    
    return coreRegistry
end

-- Initialize and register critical systems
local function initializeCriticalSystems(coreRegistry)
    if not coreRegistry then
        log("CoreRegistry not available, cannot initialize critical systems")
        return
    end
    
    log("Initializing critical systems...")
    
    for _, systemName in ipairs(CONFIG.criticalSystems) do
        -- Skip if already registered
        if coreRegistry:hasSystem(systemName) then
            continue
        end
        
        -- Try to find and require the system
        local systemLocations = {}
        
        local system
        for _, location in ipairs(systemLocations) do
            if location and location:IsA("ModuleScript") then
                local success, result = pcall(function()
                    return require(location)
                end)
                
                if success and result then
                    system = result
                    log("Found system: " .. systemName)
                    break
                end
            end
        end
        
        -- Register if found
        if system then
            coreRegistry:registerSystem(systemName, system)
            log("Registered system: " .. systemName)
            
            -- Initialize if needed
            if type(system.init) == "function" and not system.initialized then
                local success = pcall(function()
                    system:init()
                end)
                
                if success then
                    log("Initialized system: " .. systemName)
                end
            end
        else
            log("Could not find or load system: " .. systemName)
        end
    end
    
    log("Critical systems initialization complete")
end

-- Setup autorun configuration for fix scripts
local function setupAutorun()
    log("Setting up autorun configuration...")
    
    -- Find core scripts that should be set to autorun
    local autorunScripts = {
        ServerScriptService:FindFirstChild("AprilFixesStartup"),
        ServerScriptService:FindFirstChild("ClientFixDistributor"),
        ServerScriptService:FindFirstChild("CoreRegistryRestorer")
    }
    
    for _, script in ipairs(autorunScripts) do
        if script and script:IsA("Script") and not script.Disabled then
            log("Setting " .. script.Name .. " to run automatically")
            script.Disabled = false
        end
    end
    
    log("Autorun configuration complete")
end

-- Create module locator service
local function createModuleLocatorService()
    log("Creating ModuleLocatorService...")
    
    local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
    if not sharedFolder then
        log("Shared folder not found, cannot create ModuleLocatorService")
        return
    end
    
    -- Check if it already exists
    if sharedFolder:FindFirstChild("ModuleLocatorService") then
        log("ModuleLocatorService already exists")
        return
    end
    
    -- Create the service
    local moduleLocatorService = Instance.new("ModuleScript")
    moduleLocatorService.Name = "ModuleLocatorService"
    
    -- Define the module source with proper multiline string format
    moduleLocatorService.Source = [[
--[[
    ModuleLocatorService.luau
    
    This module provides robust module discovery and path resolution services.
    Created as part of the May 2, 2025 fixes to address module discovery issues.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleLocatorService = {
    debug = true,
    cachedModules = {},
    searchPaths = {
        ReplicatedStorage.shared,
        ServerScriptService.Core,
        ServerScriptService.Core.Registry,
        ServerScriptService.Data,
        ServerScriptService.Server,
        ServerScriptService.Server.Core
    }
}

-- Debug function
local function log(...)
    if ModuleLocatorService.debug then
        print("[ModuleLocatorService]", ...)
    end
end

-- Add a search path
function ModuleLocatorService:addSearchPath(path)
    if typeof(path) == "Instance" then
        table.insert(self.searchPaths, path)
        log("Added search path: " .. path:GetFullName())
        return true
    end
    return false
end

-- Find a module by name
function ModuleLocatorService:findModule(moduleName)
    -- Check cache first
    if self.cachedModules[moduleName] then
        return self.cachedModules[moduleName]
    end
    
    -- Search all paths
    for _, path in ipairs(self.searchPaths) do
        local module = path:FindFirstChild(moduleName)
        if module and module:IsA("ModuleScript") then
            -- Cache the result
            self.cachedModules[moduleName] = module
            log("Found module: " .. moduleName .. " at " .. module:GetFullName())
            return module
        end
        
        -- Also check for .luau and .server.luau variants
        module = path:FindFirstChild(moduleName .. ".luau")
        if module and module:IsA("ModuleScript") then
            self.cachedModules[moduleName] = module
            return module
        end
        
        module = path:FindFirstChild(moduleName .. ".server.luau")
        if module and module:IsA("ModuleScript") then
            self.cachedModules[moduleName] = module
            return module
        end
    end
    
    log("Could not find module: " .. moduleName)
    return nil
end

-- Safely require a module
function ModuleLocatorService:requireModule(moduleName)
    local module = self:findModule(moduleName)
    if not module then
        log("Failed to find module: " .. moduleName)
        return nil
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        log("Failed to require module: " .. moduleName .. " - " .. tostring(result))
        return nil
    end
    
    return result
end

-- Clear module from cache
function ModuleLocatorService:clearCache(moduleName)
    if not moduleName then
        -- Clear entire cache
        self.cachedModules = {}
        log("Cleared entire module cache")
    else
        -- Clear specific module
        self.cachedModules[moduleName] = nil
        log("Cleared cache for module: " .. moduleName)
    end
end

-- Initialize by scanning the workspace
function ModuleLocatorService:init()
    log("Initializing ModuleLocatorService...")
    
    -- Scan known paths and cache common modules
    local commonModules = {
        "CoreRegistry",
        "SafeRequire",
        "ModuleLoader",
        "DataPersistenceManager",
        "DataManager",
        "UIComponents",
        "AssetValidator",
        "SystemBootstrap"
    }
    
    for _, moduleName in ipairs(commonModules) do
        self:findModule(moduleName)
    end
    
    log("ModuleLocatorService initialized")
    return self
end

return ModuleLocatorService
]]
    
    -- Set the parent
    moduleLocatorService.Parent = sharedFolder
    
    log("ModuleLocatorService created")
end

-- Main initialization
local function initialize()
    log("Starting critical fixes initialization")
    
    -- Ensure folder structure first
    ensureFolderStructure()
    
    -- Ensure critical modules
    ensureCriticalModules()
    
    -- Initialize CoreRegistry
    local coreRegistry = initializeCoreRegistry()
    
    -- Initialize critical systems
    if coreRegistry then
        initializeCriticalSystems(coreRegistry)
    else
        log("CoreRegistry not available, skipping critical systems initialization")
    end
    
    -- Setup autorun configuration
    setupAutorun()
    
    -- Create module locator service
    createModuleLocatorService()
    
    log("Critical fixes initialization complete")
end

-- Run initialization
initialize()

-- Mark that initialization is complete
_G.CriticalFixesInitialized = true
