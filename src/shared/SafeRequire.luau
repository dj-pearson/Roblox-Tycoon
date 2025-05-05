--[[
    SafeRequire.luau
    
    A utility module for safely requiring other modules with error handling,
    path resolution, and fallbacks.
    
    This addresses issues with "Infinite yield possible on WaitForChild"
    and missing modules throughout the codebase.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local isServer = RunService:IsServer()
local isClient = not isServer

-- Configuration
local CONFIG = {
    debug = true,
    defaultTimeout = 5,
    retryCount = 3,
    retryDelay = 1,
    trackDependencies = true,
    searchPaths = {
        -- Server paths (only used on server)
        ServerScriptService and ServerScriptService.Core,
        ServerScriptService,
        ServerStorage and ServerStorage.Modules,
        
        -- Shared paths (used on both server and client)
        ReplicatedStorage.shared,
        ReplicatedStorage
    }
}

-- Module table
local SafeRequire = {}
SafeRequire.version = "1.0.0"
SafeRequire.loaded = {} -- Cache of loaded modules
SafeRequire.loadErrors = {} -- Errors encountered while loading
SafeRequire.dependencyGraph = {} -- Tracks dependencies between modules

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[SafeRequire]", ...)
    end
end

-- Safe wait for child with timeout
function SafeRequire.waitForChild(parent, childName, timeout)
    if not parent then
        return nil
    end
    
    timeout = timeout or CONFIG.defaultTimeout
    
    -- Quick check first
    local child = parent:FindFirstChild(childName)
    if child then
        return child
    end
    
    -- Use timeout to prevent infinite yield
    local startTime = os.clock()
    local connection
    local foundChild = nil
    
    -- Create promise-like system
    local finished = false
    
    -- Set up ChildAdded connection
    connection = parent.ChildAdded:Connect(function(addedChild)
        if addedChild.Name == childName then
            foundChild = addedChild
            finished = true
        end
    end)
    
    -- Wait loop with timeout
    while not finished and (os.clock() - startTime) < timeout do
        task.wait(0.1)
        
        -- Check again in case we missed it
        foundChild = parent:FindFirstChild(childName)
        if foundChild then
            finished = true
            break
        end
    end
    
    -- Clean up
    connection:Disconnect()
    
    if not foundChild then
        log("Timeout waiting for", childName, "in", parent:GetFullName())
    end
    
    return foundChild
end

-- Find a module by name in various locations
function SafeRequire.findModule(moduleName)
    -- Filter search paths based on server/client
    local paths = {}
    for _, path in ipairs(CONFIG.searchPaths) do
        -- Skip nil paths
        if path then
            -- Skip server paths on client
            if isClient and (path == ServerScriptService or 
                             (typeof(path) == "Instance" and 
                              path:IsDescendantOf(ServerScriptService))) then
                -- Skip
            else
                table.insert(paths, path)
            end
        end
    end
      -- Search all paths
    for _, path in ipairs(paths) do
        if path then
            -- Direct module name
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
            
            -- Try with extensions
            for _, ext in ipairs({".luau", ".server.luau", ".client.luau", ".lua"}) do
                -- Skip server/client modules based on context
                if (isServer and ext == ".client.luau") or (isClient and ext == ".server.luau") then
                    continue
                end
                
                module = path:FindFirstChild(moduleName .. ext)
                if module and module:IsA("ModuleScript") then
                    return module
                end
            end
            
            -- Check common subfolders
            for _, subfolder in ipairs({"Core", "Systems", "UI", "Modules"}) do
                local folder = path:FindFirstChild(subfolder)
                if folder then
                    -- Check in subfolder
                    local subModule = folder:FindFirstChild(moduleName)
                    if subModule and subModule:IsA("ModuleScript") then
                        return subModule
                    end
                    
                    -- Try with extensions
                    for _, ext in ipairs({".luau", ".server.luau", ".client.luau", ".lua"}) do
                        -- Skip server/client modules based on context
                        if (isServer and ext == ".client.luau") or (isClient and ext == ".server.luau") then
                            continue
                        end
                        
                        subModule = folder:FindFirstChild(moduleName .. ext)
                        if subModule and subModule:IsA("ModuleScript") then
                            return subModule
                        end
                    end
                end
            end
            
            -- Check for path segments (e.g., "UI/Button" -> path/UI/Button)
            if string.find(moduleName, "/") then
                local segments = string.split(moduleName, "/")
                local currentPath = path
                
                -- Traverse through the segments
                local isValid = true
                for i, segment in ipairs(segments) do
                    if i == #segments then
                        -- Last segment - could be the module name
                        local lastModule = currentPath:FindFirstChild(segment)
                        if lastModule and lastModule:IsA("ModuleScript") then
                            return lastModule
                        end
                        
                        -- Try with extensions for the last segment
                        for _, ext in ipairs({".luau", ".server.luau", ".client.luau", ".lua"}) do
                            lastModule = currentPath:FindFirstChild(segment .. ext)
                            if lastModule and lastModule:IsA("ModuleScript") then
                                return lastModule
                            end
                        end
                    else
                        -- Intermediate segment - must be a folder
                        local nextFolder = currentPath:FindFirstChild(segment)
                        if nextFolder then
                            currentPath = nextFolder
                        else
                            isValid = false
                            break
                        end
                    end
                end
            end
        end
    end
    
    -- Try waiting for common paths
    if ReplicatedStorage:FindFirstChild("shared") then
        local module = SafeRequire.waitForChild(ReplicatedStorage.shared, moduleName)
        if module and module:IsA("ModuleScript") then
            return module
        end
    else
        local module = SafeRequire.waitForChild(ReplicatedStorage, moduleName)
        if module and module:IsA("ModuleScript") then
            return module
        end
    end
    
    return nil
end

-- Require a module with error handling
function SafeRequire.require(modulePathOrName, fallback, timeoutOverride)
    -- Handle different input types
    local modulePath
    
    if typeof(modulePathOrName) == "string" then
        -- It's a module name, try to find it
        modulePath = SafeRequire.findModule(modulePathOrName)
        if not modulePath then
            log("Could not find module:", modulePathOrName)
            SafeRequire.loadErrors[modulePathOrName] = "Module not found"
            return fallback
        end
    elseif typeof(modulePathOrName) == "Instance" then
        -- It's a direct path
        modulePath = modulePathOrName
    else
        -- Invalid input
        log("Invalid module path type:", typeof(modulePathOrName))
        return fallback
    end
    
    -- Skip if not a ModuleScript
    if not modulePath:IsA("ModuleScript") then
        log("Not a ModuleScript:", modulePath:GetFullName())
        SafeRequire.loadErrors[modulePath:GetFullName()] = "Not a ModuleScript"
        return fallback
    end
    
    -- Return from cache if already loaded
    if SafeRequire.loaded[modulePath] then
        return SafeRequire.loaded[modulePath]
    end
    
    -- Track the calling module if dependency tracking is enabled
    if CONFIG.trackDependencies then
        local calling = debug.info(2, "s")
        if calling and calling ~= "" then
            if not SafeRequire.dependencyGraph[calling] then
                SafeRequire.dependencyGraph[calling] = {}
            end
            table.insert(SafeRequire.dependencyGraph[calling], modulePath:GetFullName())
        end
    end
    
    -- Try to require the module
    local success, result
    
    -- Try multiple times if configured
    for i = 1, CONFIG.retryCount do
        success, result = pcall(function()
            return require(modulePath)
        end)
        
        if success then
            -- Cache the successful result
            SafeRequire.loaded[modulePath] = result
            return result
        end
        
        -- Wait before trying again
        if i < CONFIG.retryCount then
            log("Retry", i, "of", CONFIG.retryCount, "for", modulePath:GetFullName())
            task.wait(CONFIG.retryDelay)
        end
    end
    
    -- If we get here, all retries failed
    log("Failed to require", modulePath:GetFullName(), "-", result)
    SafeRequire.loadErrors[modulePath:GetFullName()] = result
    
    return fallback
end

-- Add a custom search path
function SafeRequire.addSearchPath(path)
    if typeof(path) == "Instance" then
        table.insert(CONFIG.searchPaths, path)
        log("Added search path:", path:GetFullName())
        return true
    end
    return false
end

-- Get a list of modules that failed to load and why
function SafeRequire.getLoadErrors()
    return SafeRequire.loadErrors
end

-- Get the dependency graph
function SafeRequire.getDependencyGraph()
    return SafeRequire.dependencyGraph
end

-- Check if a module is available
function SafeRequire.isAvailable(moduleName)
    return SafeRequire.findModule(moduleName) ~= nil
end

-- Preload a module (useful for critical modules)
function SafeRequire.preload(moduleName, fallback)
    log("Preloading:", moduleName)
    return SafeRequire.require(moduleName, fallback)
end

-- Add common paths to search paths
if ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared") then
    SafeRequire.addSearchPath(ReplicatedStorage.src.shared)
end

-- Create shared folder if it doesn't exist
if not ReplicatedStorage:FindFirstChild("shared") then
    local sharedFolder = Instance.new("Folder")
    sharedFolder.Name = "shared"
    sharedFolder.Parent = ReplicatedStorage
    log("Created shared folder in ReplicatedStorage")
end

-- Create a reference to SafeRequire in ReplicatedStorage for easy access
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
if sharedFolder then
    -- Create a reference ModuleScript
    local reference = sharedFolder:FindFirstChild("SafeRequire")
    if not reference then
        reference = Instance.new("ModuleScript")
        reference.Name = "SafeRequire"
        reference.Source = "return require(script.Parent.Parent:WaitForChild('SafeRequireModule'))"
        reference.Parent = sharedFolder
        log("Created SafeRequire reference in shared folder")
    end
end

-- Create the main module
local mainModule = ReplicatedStorage:FindFirstChild("SafeRequireModule")
if not mainModule then
    mainModule = Instance.new("ModuleScript")
    mainModule.Name = "SafeRequireModule"
    mainModule.Parent = ReplicatedStorage
    
    -- We'll update the source later
    log("Created SafeRequireModule in ReplicatedStorage")
end

return SafeRequire
