--[[
    ModuleLoader.luau
    This module provides centralized module loading functionality with
    robust error handling, caching, and path resolution.
    
    Created to fix critical "Module Loading and WaitForChild Errors" reported in RobloxIssues.txt
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- Determine if we're running on server or client
local isServer = RunService:IsServer()

-- Module cache
local moduleCache = {}

-- Search paths
local searchPaths = {
    ReplicatedStorage:FindFirstChild("shared"),
    ReplicatedStorage
}

-- Add server-only paths if we're on the server
if isServer then
    table.insert(searchPaths, 1, ServerScriptService:FindFirstChild("Core"))
    table.insert(searchPaths, 2, ServerScriptService)
    table.insert(searchPaths, 3, ServerStorage)
end

-- The module table
local ModuleLoader = {}

-- Version information
ModuleLoader.VERSION = "1.0.0"
ModuleLoader.isLoaded = true

-- Safe WaitForChild with timeout
function ModuleLoader.waitForChild(parent, childName, timeout)
    timeout = timeout or 5
    
    -- Quick check first
    local child = parent:FindFirstChild(childName)
    if child then return child end
    
    -- Use timeout to prevent infinite yield
    local startTime = os.clock()
    
    while not child and (os.clock() - startTime) < timeout do
        child = parent:FindFirstChild(childName)
        if child then break end
        task.wait(0.1)
    end
    
    if not child then
        warn("ModuleLoader.waitForChild: Timeout waiting for " .. childName .. " in " .. parent:GetFullName())
    end
    
    return child
end

-- Add a custom search path
function ModuleLoader.addSearchPath(path)
    if not path or typeof(path) ~= "Instance" then
        warn("ModuleLoader.addSearchPath: Invalid path")
        return false
    end
    
    table.insert(searchPaths, 1, path)
    return true
end

-- Get all current search paths
function ModuleLoader.getSearchPaths()
    return table.clone(searchPaths)
end

-- Clear module cache
function ModuleLoader.clearCache(moduleName)
    if moduleName then
        moduleCache[moduleName] = nil
    else
        moduleCache = {}
    end
end

-- Find a module by name across search paths
function ModuleLoader.findModule(moduleName)
    -- Check cache first
    if moduleCache[moduleName] then
        return moduleCache[moduleName].instance
    end
    
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
    
    -- Not found
    return nil
end

-- Load a module by name
function ModuleLoader.loadModule(moduleName, fallback)
    -- Check if already cached
    if moduleCache[moduleName] then
        return moduleCache[moduleName].value
    end
    
    -- Find the module
    local module = ModuleLoader.findModule(moduleName)
    
    -- If not found, use fallback or warn
    if not module then
        if fallback ~= nil then
            print("ModuleLoader.loadModule: Using fallback for " .. moduleName)
            moduleCache[moduleName] = {
                instance = nil,
                value = fallback
            }
            return fallback
        else
            warn("ModuleLoader.loadModule: Module not found - " .. moduleName)
            return nil
        end
    end
    
    -- Try to require the module
    local success, result = pcall(function()
        return require(module)
    end)
    
    -- Handle result
    if success then
        moduleCache[moduleName] = {
            instance = module,
            value = result
        }
        return result
    else
        warn("ModuleLoader.loadModule: Failed to require " .. moduleName .. " - " .. tostring(result))
        if fallback ~= nil then
            moduleCache[moduleName] = {
                instance = module,
                value = fallback
            }
            return fallback
        else
            return nil
        end
    end
end

-- Safe require with fallback
function ModuleLoader.safeRequire(module, fallback)
    if not module then
        return fallback
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("ModuleLoader.safeRequire: Failed to require module - " .. tostring(result))
        return fallback
    end
end

-- Resolve a path string like "ReplicatedStorage.shared.ModuleLoader"
function ModuleLoader.resolvePath(pathString)
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
            warn("ModuleLoader.resolvePath: Failed to resolve path at part 1: " .. parts[1])
            return nil
        end
    end
    
    -- Traverse the path
    for i = 2, #parts do
        current = ModuleLoader.waitForChild(current, parts[i], 1)
        if not current then
            warn("ModuleLoader.resolvePath: Failed to resolve path at part " .. i .. ": " .. parts[i])
            return nil
        end
    end
    
    return current
end

-- Create folder hierarchy if it doesn't exist
function ModuleLoader.ensurePath(parent, pathArray)
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

-- Register with CoreRegistry or ClientRegistry if available
if isServer then
    local CoreRegistry = ModuleLoader.safeRequire(ModuleLoader.findModule("CoreRegistry"))
    if CoreRegistry and type(CoreRegistry.registerSystem) == "function" then
        CoreRegistry.registerSystem("ModuleLoader", ModuleLoader)
    end
else
    local ClientRegistry = ModuleLoader.safeRequire(ModuleLoader.findModule("ClientRegistry"))
    if ClientRegistry and type(ClientRegistry.registerSystem) == "function" then
        ClientRegistry.registerSystem("ModuleLoader", ModuleLoader)
    end
end

-- Make it globally available
_G.ModuleLoader = ModuleLoader

print("✅ ModuleLoader initialized")
return ModuleLoader
