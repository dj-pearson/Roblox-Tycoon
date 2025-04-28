--!strict
--[[
    ModuleLoader.luau
    
    A utility for loading modules by name from configured search paths.
    Provides robust error handling and fallback mechanisms for module loading.
    
    Created: April 27, 2025
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    ALWAYS_RELOAD = false
}

-- Internal state
local searchPaths = {}
local moduleCache = {}
local aliases = {}
local initialized = false

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[ModuleLoader] " .. message)
    end
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
        warn("[ModuleLoader] Failed to require " .. module:GetFullName() .. ": " .. tostring(result))
        return fallback
    end
end

-- Register default search paths
local function registerDefaultPaths()
    log("Registering default search paths")
    
    -- Shared paths (available to both server and client)
    searchPaths = {
        ["shared"] = ReplicatedStorage:FindFirstChild("shared"),
        ["ReplicatedStorage"] = ReplicatedStorage,
    }
    
    -- Create SharedFolder if it doesn't exist
    if not searchPaths["shared"] then
        log("Creating missing SharedFolder in ReplicatedStorage")
        local sharedFolder = Instance.new("Folder")
        sharedFolder.Name = "shared"
        sharedFolder.Parent = ReplicatedStorage
        searchPaths["shared"] = sharedFolder
    end
    
    -- Server-specific paths
    if RunService:IsServer() then
        searchPaths["ServerScriptService"] = ServerScriptService
        searchPaths["ServerCore"] = ServerScriptService:FindFirstChild("Core")
        
        -- Create Server Core folder if it doesn't exist
        if not searchPaths["ServerCore"] then
            log("Creating missing Core folder in ServerScriptService")
            local coreFolder = Instance.new("Folder")
            coreFolder.Name = "Core"
            coreFolder.Parent = ServerScriptService
            searchPaths["ServerCore"] = coreFolder
        end
        
        -- Look for server folder in src
        if ServerScriptService:FindFirstChild("src") and 
           ServerScriptService.src:FindFirstChild("server") then
            searchPaths["ServerSrc"] = ServerScriptService.src.server
        end
    end
    
    -- Look for src in ReplicatedStorage
    if ReplicatedStorage:FindFirstChild("src") then
        searchPaths["Src"] = ReplicatedStorage.src
        
        -- Look for shared folder in src
        if ReplicatedStorage.src:FindFirstChild("shared") then
            searchPaths["SrcShared"] = ReplicatedStorage.src.shared
        end
    end
    
    log("Registered " .. tostring(table.getn(searchPaths)) .. " search paths")
end

-- Initialize the module loader
local function initialize()
    if initialized then
        return
    end
    
    log("Initializing ModuleLoader")
    registerDefaultPaths()
    initialized = true
end

-- Register a new search path
local function registerPath(name, path)
    if not name or not path then
        warn("[ModuleLoader] Invalid path registration parameters")
        return false
    end
    
    if searchPaths[name] then
        log("Updating existing path: " .. name)
    else
        log("Registering new path: " .. name)
    end
    
    searchPaths[name] = path
    return true
end

-- Register an alias for a module
local function registerAlias(aliasName, moduleName)
    if not aliasName or not moduleName then
        warn("[ModuleLoader] Invalid alias registration parameters")
        return false
    end
    
    log("Registering alias: " .. aliasName .. " → " .. moduleName)
    aliases[aliasName] = moduleName
    return true
end

-- Resolve the true module name from an alias
local function resolveAlias(moduleName)
    -- Check if this name is an alias
    if aliases[moduleName] then
        log("Resolved alias: " .. moduleName .. " → " .. aliases[moduleName])
        return aliases[moduleName]
    end
    
    return moduleName
end

-- Find a module script in the registered paths
local function findModule(moduleName)
    if not moduleName then
        warn("[ModuleLoader] moduleName is nil")
        return nil
    end
    
    -- Resolve alias if one exists
    moduleName = resolveAlias(moduleName)
    
    -- Check each registered path
    for pathName, path in pairs(searchPaths) do
        if path then
            local moduleScript = path:FindFirstChild(moduleName)
            if moduleScript and moduleScript:IsA("ModuleScript") then
                log("Found module " .. moduleName .. " in path: " .. pathName)
                return moduleScript
            end
        end
    end
    
    -- Special case: check for path-like module names (e.g., "Utils.StringUtil")
    for pathName, path in pairs(searchPaths) do
        if path then
            local segments = string.split(moduleName, ".")
            if #segments > 1 then
                -- Try to navigate the path
                local current = path
                local found = true
                
                for i = 1, #segments - 1 do
                    current = current:FindFirstChild(segments[i])
                    if not current then
                        found = false
                        break
                    end
                end
                
                if found and current then
                    local moduleScript = current:FindFirstChild(segments[#segments])
                    if moduleScript and moduleScript:IsA("ModuleScript") then
                        log("Found module " .. moduleName .. " as path in: " .. pathName)
                        return moduleScript
                    end
                end
            end
        end
    end
    
    log("Module not found: " .. moduleName)
    return nil
end

-- Load a module by name
local function loadModule(moduleName, fallback)
    if not initialized then
        initialize()
    end
    
    if not moduleName then
        warn("[ModuleLoader] moduleName is nil")
        return fallback
    end
    
    -- Check cache first unless we're always reloading
    if not CONFIG.ALWAYS_RELOAD and moduleCache[moduleName] then
        return moduleCache[moduleName]
    end
    
    -- Find the module
    local moduleScript = findModule(moduleName)
    if not moduleScript then
        warn("[ModuleLoader] Module not found: " .. moduleName)
        return fallback
    end
    
    -- Try to require the module
    local module = safeRequire(moduleScript, fallback)
    
    -- Cache the result if not nil
    if module ~= nil then
        moduleCache[moduleName] = module
    end
    
    return module
end

-- Clear the module cache
local function clearCache(moduleName)
    if moduleName then
        moduleCache[moduleName] = nil
        log("Cleared cache for module: " .. moduleName)
    else
        moduleCache = {}
        log("Cleared entire module cache")
    end
end

-- Return the API
local ModuleLoader = {
    LoadModule = loadModule,
    RegisterPath = registerPath,
    RegisterAlias = registerAlias,
    FindModule = findModule,
    ClearCache = clearCache,
    Initialize = initialize,
    SetDebugLogging = function(enabled)
        CONFIG.DEBUG_LOGGING = enabled
    end,
    SetAlwaysReload = function(enabled)
        CONFIG.ALWAYS_RELOAD = enabled
    end
}

-- Auto-initialize if loaded from require
initialize()

return ModuleLoader
