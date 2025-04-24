--!strict
--[[
    ModuleLoader.luau
    A utility to standardize module loading across the codebase and handle errors gracefully.
    
    Usage:
    local ModuleLoader = require(ReplicatedStorage.shared.ModuleLoader)
    local CoreRegistry = ModuleLoader:LoadModule("Core", "CoreRegistry")
    
    For server modules:
    local DataManager = ModuleLoader:LoadServerModule("Core", "DataManager")
    
    For client modules:
    local UIManager = ModuleLoader:LoadClientModule("UI", "UIManager")
    
    For shared modules:
    local Constants = ModuleLoader:LoadSharedModule("Constants")
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ModuleLoader = {}
ModuleLoader._moduleCache = {}
ModuleLoader._pathRegistry = {
    Server = {
        -- Default paths - will be populated by PathRegistration.server.luau
        Core = ServerScriptService:FindFirstChild("src"):FindFirstChild("server"):FindFirstChild("Core"),
        Connectors = ServerScriptService:FindFirstChild("src"):FindFirstChild("server"):FindFirstChild("Connectors"),
        Model = ServerScriptService:FindFirstChild("src"):FindFirstChild("server"):FindFirstChild("Model Function"),
    },
    Client = {
        -- Default client paths
        UI = ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("UI"),
    },
    Shared = {
        -- Default shared paths
        Shared = ReplicatedStorage:FindFirstChild("shared"),
    }
}

-- Log function to standardize logging
local function log(level: string, message: string)
    if level == "error" then
        warn("[ModuleLoader] ERROR: " .. message)
    elseif level == "warning" then
        warn("[ModuleLoader] Warning: " .. message)
    else
        print("[ModuleLoader] " .. message)
    end
end

-- Registers a path for a specific category and group
function ModuleLoader:RegisterPath(category: string, group: string, path: Instance)
    if not self._pathRegistry[category] then
        self._pathRegistry[category] = {}
    end
    
    self._pathRegistry[category][group] = path
    log("info", string.format("Registered path for %s.%s: %s", category, group, path:GetFullName()))
    return true
end

-- Gets the base folder for a category and group
function ModuleLoader:GetBasePath(category: string, group: string): Instance?
    if not self._pathRegistry[category] then
        log("error", string.format("Category '%s' not registered", category))
        return nil
    end
    
    if not self._pathRegistry[category][group] then
        log("error", string.format("Group '%s' not registered in category '%s'", group, category))
        return nil
    end
    
    return self._pathRegistry[category][group]
end

-- Internal function to load a module from a specific path
function ModuleLoader:_LoadFromPath(basePath: Instance?, moduleName: string)
    if not basePath then
        log("error", string.format("Cannot load module '%s': base path is nil", moduleName))
        return nil
    end
    
    local moduleInstance = basePath:FindFirstChild(moduleName)
    if not moduleInstance then
        -- Try with extensions
        moduleInstance = basePath:FindFirstChild(moduleName .. ".server")
        if not moduleInstance then
            moduleInstance = basePath:FindFirstChild(moduleName .. ".client")
        end
        if not moduleInstance then
            moduleInstance = basePath:FindFirstChild(moduleName .. ".luau")
        end
    end
    
    if not moduleInstance then
        log("error", string.format("Module '%s' not found in path '%s'", moduleName, basePath:GetFullName()))
        return nil
    end
    
    -- Check if the module is already cached
    local cacheKey = moduleInstance:GetFullName()
    if self._moduleCache[cacheKey] then
        return self._moduleCache[cacheKey]
    end
    
    -- Load the module
    local success, result = pcall(function()
        return require(moduleInstance)
    end)
    
    if not success then
        log("error", string.format("Failed to load module '%s': %s", moduleName, result))
        return nil
    end
    
    -- Cache the result
    self._moduleCache[cacheKey] = result
    return result
end

-- Load a server module
function ModuleLoader:LoadServerModule(group: string, moduleName: string)
    return self:_LoadFromPath(self:GetBasePath("Server", group), moduleName)
end

-- Load a client module
function ModuleLoader:LoadClientModule(group: string, moduleName: string)
    return self:_LoadFromPath(self:GetBasePath("Client", group), moduleName)
end

-- Load a shared module
function ModuleLoader:LoadSharedModule(moduleName: string)
    return self:_LoadFromPath(self:GetBasePath("Shared", "Shared"), moduleName)
end

-- General module loading function - will automatically determine the correct path based on specified category
function ModuleLoader:LoadModule(group: string, moduleName: string)
    -- Try server first, then client, then shared
    local module = self:LoadServerModule(group, moduleName)
    if module then
        return module
    end
    
    module = self:LoadClientModule(group, moduleName)
    if module then
        return module
    end
    
    return self:LoadSharedModule(moduleName)
end

-- Initialize and return the ModuleLoader singleton
local function init()
    -- Add additional initialization if needed
    return ModuleLoader
end

return init()
