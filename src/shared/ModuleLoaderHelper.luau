--[[
    ModuleLoaderHelper.luau
    
    Helper utility for loading modules across both server and client.
    Provides consistent interface for requiring modules with error handling.
    
    Created as part of the CoreRegistry fix documented in CoreRegistry_Fix_Solution.md
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local isServer = RunService:IsServer()
local ServerScriptService = isServer and game:GetService("ServerScriptService") or nil

-- The module
local ModuleLoaderHelper = {}

-- Version information
ModuleLoaderHelper.VERSION = "1.0.0"

-- Default search paths
local defaultSearchPaths = {
    ReplicatedStorage:FindFirstChild("shared"),
    ReplicatedStorage
}

-- Add server paths if on server
if isServer then
    table.insert(defaultSearchPaths, 1, ServerScriptService:FindFirstChild("Core"))
    table.insert(defaultSearchPaths, 2, ServerScriptService)
end

-- Safely wait for child with timeout
function ModuleLoaderHelper.waitForChild(parent, childName, timeout)
    timeout = timeout or 5 -- Default timeout of 5 seconds
    
    -- Quick check
    local child = parent:FindFirstChild(childName)
    if child then return child end
    
    -- Use timeout to prevent infinite yield
    local startTime = os.clock()
    while not child and (os.clock() - startTime) < timeout do
        child = parent:FindFirstChild(childName)
        if child then break end
        task.wait(0.1)
    end
    
    return child
end

-- Find a module by name in search paths
function ModuleLoaderHelper.findModule(moduleName, searchPaths)
    searchPaths = searchPaths or defaultSearchPaths
    
    -- Search all paths
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    -- Try resolving a path like "folder.subfolder.module"
    local parts = string.split(moduleName, ".")
    if #parts > 1 then
        for _, basePath in ipairs(searchPaths) do
            local current = basePath
            local found = true
            
            for i = 1, #parts - 1 do
                current = current:FindFirstChild(parts[i])
                if not current then
                    found = false
                    break
                end
            end
            
            if found then
                local module = current:FindFirstChild(parts[#parts])
                if module and module:IsA("ModuleScript") then
                    return module
                end
            end
        end
    end
    
    return nil
end

-- Safe require with fallback
function ModuleLoaderHelper.safeRequire(moduleInstance, fallback)
    if not moduleInstance then
        return fallback
    end
    
    if not moduleInstance:IsA("ModuleScript") then
        warn("ModuleLoaderHelper: Expected ModuleScript but got " .. moduleInstance.ClassName .. " for " .. moduleInstance:GetFullName())
        return fallback
    end
    
    local success, result = pcall(function()
        return require(moduleInstance)
    end)
    
    if success then
        return result
    else
        warn("ModuleLoaderHelper: Failed to require " .. moduleInstance:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
end

-- Load a module by name
function ModuleLoaderHelper.loadModule(moduleName, fallback, searchPaths)
    -- Find the module
    local module = ModuleLoaderHelper.findModule(moduleName, searchPaths)
    
    -- If not found, use fallback or warn
    if not module then
        if fallback ~= nil then
            print("ModuleLoaderHelper.loadModule: Using fallback for " .. moduleName)
            return fallback
        else
            warn("ModuleLoaderHelper.loadModule: Module not found - " .. moduleName)
            return nil
        end
    end
    
    -- Try to require the module
    return ModuleLoaderHelper.safeRequire(module, fallback)
end

-- Resolve a path string like "ReplicatedStorage.shared.ModuleLoader"
function ModuleLoaderHelper.resolvePath(pathString)
    if typeof(pathString) == "Instance" then
        return pathString
    end
    
    if type(pathString) ~= "string" then
        return nil
    end
    
    local parts = string.split(pathString, ".")
    if #parts == 0 then
        return nil
    end
    
    -- See if the first part is a service name
    local current
    local success, service = pcall(function()
        return game:GetService(parts[1])
    end)
    
    if success and service then
        current = service
    else
        -- Try finding it in the game
        current = game:FindFirstChild(parts[1])
        if not current then
            warn("ModuleLoaderHelper.resolvePath: Failed to resolve path at part 1: " .. parts[1])
            return nil
        end
    end
    
    -- Traverse the path
    for i = 2, #parts do
        current = ModuleLoaderHelper.waitForChild(current, parts[i], 1)
        if not current then
            warn("ModuleLoaderHelper.resolvePath: Failed to resolve path at part " .. i .. ": " .. parts[i])
            return nil
        end
    end
    
    return current
end

-- Create folder hierarchy if it doesn't exist
function ModuleLoaderHelper.ensurePath(parent, pathArray)
    local current = parent
    for _, name in ipairs(pathArray) do
        local child = current:FindFirstChild(name)
        if not child then
            child = Instance.new("Folder")
            child.Name = name
            child.Parent = current
        end
        current = child
    end
    return current
end

-- Try to load a module that's part of the registry system
function ModuleLoaderHelper.loadSystemModule(systemName, fallback)
    -- Try to get the module loader
    local ModuleLoader = _G.ModuleLoader
    
    -- If module loader is available, use it
    if ModuleLoader and typeof(ModuleLoader.loadModule) == "function" then
        return ModuleLoader.loadModule(systemName, fallback)
    end
    
    -- Otherwise use our built-in module loading
    return ModuleLoaderHelper.loadModule(systemName, fallback)
end

return ModuleLoaderHelper
