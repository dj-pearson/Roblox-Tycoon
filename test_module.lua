local function createModuleLocatorService()
    local sharedFolder = {}  -- Mock for testing
    local function log(...) end  -- Mock for testing
    
    local moduleLocatorService = Instance.new("ModuleScript")
    moduleLocatorService.Name = "ModuleLocatorService"
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
    }
}

-- Debug logger
local function log(...)
    if ModuleLocatorService.debug then
        print("[ModuleLocatorService]", ...)
    end
end

-- Add a path to search for modules
function ModuleLocatorService:addSearchPath(path)
    if path and typeof(path) == "Instance" then
        table.insert(self.searchPaths, path)
        log("Added search path:", path:GetFullName())
    end
end

-- Find a module by name in any search path
function ModuleLocatorService:findModule(moduleName)
    -- Check cache first
    if self.cachedModules[moduleName] then
        log("Found cached module:", moduleName)
        return self.cachedModules[moduleName]
    end
    
    -- Search for module
    for _, path in ipairs(self.searchPaths) do
        if path and typeof(path) == "Instance" then
            -- Direct child
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                log("Found module:", moduleName, "at", module:GetFullName())
                self.cachedModules[moduleName] = module
                return module
            end
            
            -- Check one level deeper
            for _, child in ipairs(path:GetChildren()) do
                if child:IsA("Folder") or child:IsA("Configuration") then
                    local module = child:FindFirstChild(moduleName)
                    if module and module:IsA("ModuleScript") then
                        log("Found module:", moduleName, "at", module:GetFullName())
                        self.cachedModules[moduleName] = module
                        return module
                    end
                end
            end
        end
    end
    
    log("Module not found:", moduleName)
    return nil
end

-- Require a module by name
function ModuleLocatorService:requireModule(moduleName)
    local module = self:findModule(moduleName)
    if not module then
        log("Failed to find module:", moduleName)
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

return ModuleLocatorService:init()
]]

    moduleLocatorService.Parent = sharedFolder
    
    log("ModuleLocatorService created")
end

createModuleLocatorService()
