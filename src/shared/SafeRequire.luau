--!strict
--[[
    SafeRequire.luau
    
    A utility module for safely requiring modules with timeout handling
    and error recovery. This works alongside ModuleLoader but focuses
    specifically on safety during module loading.
    
    Created: April 26, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local DEFAULT_TIMEOUT = 5 -- Default timeout in seconds
local DEBUG_LOGGING = true
local CACHE_MODULES = true

-- Cache to prevent redundant requires
local cachedModules = {}

-- SafeRequire utility
local SafeRequire = {}

-- Internal logging function
local function log(message)
    if DEBUG_LOGGING then
        print("[SafeRequire] " .. message)
    end
end

-- Safely wait for a module to become available with timeout
function SafeRequire.waitForModule(parent, moduleName, timeoutSeconds)
    timeoutSeconds = timeoutSeconds or DEFAULT_TIMEOUT
    
    if not parent then
        warn("[SafeRequire] Parent is nil while waiting for module: " .. moduleName)
        return nil
    end
    
    local startTime = os.clock()
    local module = parent:FindFirstChild(moduleName)
    
    -- If module already exists, return it
    if module then
        return module
    end
    
    -- Set up a flag to track if we've found the module
    local found = false
    local connection
    
    -- Create function to handle when a child is added
    connection = parent.ChildAdded:Connect(function(child)
        if child.Name == moduleName then
            found = true
            module = child
        end
    end)
    
    -- Wait until we find the module or timeout
    while not found and (os.clock() - startTime) < timeoutSeconds do
        task.wait(0.1)
        
        -- Double-check if module exists directly
        if not module then
            module = parent:FindFirstChild(moduleName)
            if module then
                found = true
                break
            end
        end
    end
    
    -- Clean up the connection
    connection:Disconnect()
    
    -- Handle timeout
    if not found then
        warn("[SafeRequire] Timed out waiting for module: " .. moduleName .. 
             " in parent: " .. parent:GetFullName() .. 
             " (timeout: " .. timeoutSeconds .. "s)")
        return nil
    end
    
    return module
end

-- Safely require a module with timeout
function SafeRequire.requireWithTimeout(parent, moduleName, timeoutSeconds)
    -- First check cache
    local cacheKey = parent:GetFullName() .. "." .. moduleName
    if CACHE_MODULES and cachedModules[cacheKey] then
        return cachedModules[cacheKey]
    end
    
    -- Wait for the module
    local moduleScript = SafeRequire.waitForModule(parent, moduleName, timeoutSeconds)
    if not moduleScript then
        return nil
    end
    
    -- Try to require it
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if success then
        if CACHE_MODULES then
            cachedModules[cacheKey] = result
        end
        return result
    else
        warn("[SafeRequire] Failed to require module: " .. moduleName .. " - " .. tostring(result))
        return nil
    end
end

-- Safely require a module by path (string format like "ReplicatedStorage.shared.ModuleLoader")
function SafeRequire.byPath(path, timeoutSeconds)
    -- Split the path into parts
    local pathParts = string.split(path, ".")
    if #pathParts < 2 then
        warn("[SafeRequire] Invalid path: " .. path .. " (needs at least two parts)")
        return nil
    end
    
    -- Start with the first part (should be a service or top-level object)
    local current
    
    -- Handle standard services and locations
    if pathParts[1] == "ReplicatedStorage" then
        current = ReplicatedStorage
    elseif pathParts[1] == "ServerScriptService" then
        current = game:GetService("ServerScriptService")
    elseif pathParts[1] == "ServerStorage" then
        current = game:GetService("ServerStorage")
    elseif pathParts[1] == "Players" and RunService:IsClient() then
        -- Client-specific path
        current = game:GetService("Players").LocalPlayer
    else
        -- Try to get as a service
        local success, service = pcall(function()
            return game:GetService(pathParts[1])
        end)
        
        if success then
            current = service
        else
            warn("[SafeRequire] Invalid service in path: " .. pathParts[1])
            return nil
        end
    end
    
    -- Navigate through path parts using waitForModule
    for i = 2, #pathParts - 1 do
        if not current then return nil end
        
        local next = SafeRequire.waitForModule(current, pathParts[i], timeoutSeconds)
        if not next then
            return nil
        end
        
        current = next
    end
    
    -- Require the final module
    if not current then return nil end
    
    return SafeRequire.requireWithTimeout(current, pathParts[#pathParts], timeoutSeconds)
end

-- Try multiple paths in order until one succeeds
function SafeRequire.tryPaths(paths, timeoutSeconds)
    for _, path in ipairs(paths) do
        local result = SafeRequire.byPath(path, timeoutSeconds)
        if result then
            log("Successfully required: " .. path)
            return result
        end
    end
    
    warn("[SafeRequire] All paths failed: " .. table.concat(paths, ", "))
    return nil
end

-- Clear the module cache
function SafeRequire.clearCache()
    cachedModules = {}
    log("Module cache cleared")
end

-- Set default timeout
function SafeRequire.setDefaultTimeout(seconds)
    DEFAULT_TIMEOUT = seconds
    log("Default timeout set to " .. seconds .. " seconds")
end

-- Initialize the module
function SafeRequire.initialize(config)
    config = config or {}
    
    if config.defaultTimeout then
        DEFAULT_TIMEOUT = config.defaultTimeout
    end
    
    if config.debugLogging ~= nil then
        DEBUG_LOGGING = config.debugLogging
    end
    
    if config.cacheModules ~= nil then
        CACHE_MODULES = config.cacheModules
    end
    
    log("SafeRequire initialized")
end

-- Integration with ModuleLoader if available
do
    local success, ModuleLoader = pcall(function()
        return require(ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("ModuleLoader"))
    end)
    
    if success and ModuleLoader then
        log("ModuleLoader integration enabled")
        
        -- Register with ModuleLoader
        if typeof(ModuleLoader.addSearchPath) == "function" then
            ModuleLoader.addSearchPath(ReplicatedStorage.shared)
        end
    end
end

return SafeRequire
