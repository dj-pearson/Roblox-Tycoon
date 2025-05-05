-- Create module locator service - simplified test
local function createModuleLocatorService()
    print("Creating ModuleLocatorService...")
    
    -- Create the module content as separate strings
    local header = [[
-- ModuleLocatorService.luau
-- 
-- This module provides robust module discovery and path resolution services.
-- Created as part of the May 2, 2025 fixes to address module discovery issues.
]]

    local imports = [[
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
]]

    local moduleDefinition = [[
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
]]

    local debugFunction = [[
-- Debug function
local function log(...)
    if ModuleLocatorService.debug then
        print("[ModuleLocatorService]", ...)
    end
end
]]

    local otherFunctions = [[
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
]]

    local requireFunction = [[
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
]]

    local cacheFunction = [[
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
]]

    local initFunction = [[
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
]]

    local returnStatement = [[
return ModuleLocatorService
]]

    -- Create the complete module source by concatenating all parts
    local moduleSource = header .. "\n" .. imports .. "\n" .. moduleDefinition .. 
                        "\n" .. debugFunction .. "\n" .. otherFunctions .. 
                        "\n" .. requireFunction .. "\n" .. cacheFunction .. 
                        "\n" .. initFunction .. "\n" .. returnStatement
    
    print("Module content created successfully")
    print("First 50 characters: " .. string.sub(moduleSource, 1, 50))
    
    -- Return final module content
    return moduleSource
end

-- Test the function
local moduleContent = createModuleLocatorService()
print("Function executed successfully")
