-- ModuleLoader.luau
-- Utility for loading modules with robust error handling and fallbacks
-- Created: April 30, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Module loader with error handling and caching
local ModuleLoader = {
    Version = "1.0.0",
    IsLoaded = true,
    Cache = {},
    SearchPaths = {
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
    }
}

-- Configuration
local CONFIG = {
    cacheEnabled = true, -- Enable module caching
    debugLogging = true, -- Enable detailed logs
    retryCount = 3,      -- Number of times to retry loading a module
    retryDelay = 0.5     -- Seconds to wait between retries
}

-- Debug logging function
local function log(message, level)
    if not CONFIG.debugLogging and level ~= "Error" then return end
    
    local prefix = "[ModuleLoader]"
    if level == "Error" then
        warn(prefix .. " " .. message)
    elseif level == "Success" then
        print(prefix .. " " .. message)
    else
        print(prefix .. " " .. message)
    end
end

-- Find a module by name
function ModuleLoader.findModule(moduleName)
    -- Check cache first
    if CONFIG.cacheEnabled and ModuleLoader.Cache[moduleName] then
        return ModuleLoader.Cache[moduleName]
    end
    
    -- Search in predefined paths
    for _, path in ipairs(ModuleLoader.SearchPaths) do
        if path then
            local moduleScript = path:FindFirstChild(moduleName)
            if moduleScript and moduleScript:IsA("ModuleScript") then
                if CONFIG.cacheEnabled then
                    ModuleLoader.Cache[moduleName] = moduleScript
                end
                log("Found module: " .. moduleName .. " at " .. moduleScript:GetFullName(), "Success")
                return moduleScript
            end
        end
    end
    
    -- Search in common locations
    local commonLocations = {}
    
    -- Add client paths if running on client
    if RunService:IsClient() then
        local player = game:GetService("Players").LocalPlayer
        if player then
            table.insert(commonLocations, player:FindFirstChild("PlayerScripts"))
        end
        
        -- Add StarterPlayerScripts paths
        table.insert(commonLocations, game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts"))
    end
    
    -- Add server paths if running on server
    if RunService:IsServer() then
        table.insert(commonLocations, game:GetService("ServerStorage"))
        table.insert(commonLocations, game:GetService("ServerScriptService"))
    end
    
    -- Search in ReplicatedStorage subfolders
    local subfolders = {"Modules", "Scripts", "Framework", "Libraries"}
    for _, subfolder in ipairs(subfolders) do
        table.insert(commonLocations, ReplicatedStorage:FindFirstChild(subfolder))
    end
    
    -- Find in common locations
    for _, location in ipairs(commonLocations) do
        if location then
            local moduleScript = location:FindFirstChild(moduleName, true) -- true = recursive
            if moduleScript and moduleScript:IsA("ModuleScript") then
                if CONFIG.cacheEnabled then
                    ModuleLoader.Cache[moduleName] = moduleScript
                end
                log("Found module: " .. moduleName .. " at " .. moduleScript:GetFullName(), "Success")
                return moduleScript
            end
        end
    end
    
    log("Could not find module: " .. moduleName, "Error")
    return nil
end

-- Safely require a module with retry logic
function ModuleLoader.requireSafely(moduleScript, maxRetries)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        return nil, "Invalid module"
    end
    
    maxRetries = maxRetries or CONFIG.retryCount
    
    -- Try multiple times if needed
    for attempt = 1, maxRetries do
        local success, result = pcall(function()
            return require(moduleScript)
        end)
        
        if success then
            if attempt > 1 then
                log("Successfully loaded module on attempt " .. attempt .. ": " .. moduleScript.Name, "Success")
            end
            return result
        else
            log("Failed to load module: " .. moduleScript.Name .. " (Attempt " .. attempt .. "/" .. maxRetries .. ")", "Error")
            log("Error: " .. tostring(result), "Error")
            
            if attempt < maxRetries then
                task.wait(CONFIG.retryDelay)
            end
        end
    end
    
    return nil, "Failed to load after " .. maxRetries .. " attempts"
end

-- Require a module by name (throws error if not found)
function ModuleLoader.require(moduleName)
    local moduleScript = ModuleLoader.findModule(moduleName)
    if not moduleScript then
        error("Could not find module: " .. moduleName)
    end
    
    local result, errorMessage = ModuleLoader.requireSafely(moduleScript)
    if not result then
        error("Failed to load module: " .. moduleName .. " (" .. errorMessage .. ")")
    end
    
    return result
end

-- Try to require a module by name (returns nil if not found)
function ModuleLoader.tryRequire(moduleName)
    local moduleScript = ModuleLoader.findModule(moduleName)
    if not moduleScript then
        return nil, "Module not found"
    end
    
    return ModuleLoader.requireSafely(moduleScript)
end

-- Add a search path to the module loader
function ModuleLoader.addSearchPath(path)
    if typeof(path) == "Instance" then
        table.insert(ModuleLoader.SearchPaths, path)
        log("Added search path: " .. path:GetFullName(), "Success")
        return true
    end
    return false
end

-- Clear the module cache
function ModuleLoader.clearCache()
    ModuleLoader.Cache = {}
    log("Module cache cleared", "Success")
    return true
end

-- Get a module from the cache
function ModuleLoader.getCachedModule(moduleName)
    return ModuleLoader.Cache[moduleName]
end

-- Initialize the module
log("ModuleLoader initialized (v" .. ModuleLoader.Version .. ")", "Success")

return ModuleLoader
