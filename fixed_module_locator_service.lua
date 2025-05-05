-- Create module locator service without nested multiline strings
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
    
    -- Define the module source without nested multiline strings
    moduleLocatorService.Source = [[
-- ModuleLocatorService.luau
-- 
-- This module provides robust module discovery and path resolution services.
-- Created as part of the May 2, 2025 fixes to address module discovery issues.

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
