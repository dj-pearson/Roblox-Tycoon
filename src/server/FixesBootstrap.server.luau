--[[
    FixesBootstrap.server.luau
    
    This script ensures that all critical fixes are loaded in the correct order.
    It has a high RunContext priority to ensure it loads early in the game lifecycle.
    
    Created to address critical issues identified in RobloxIssues.txt
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    debug = true,
    fixScriptNames = {
        -- Order matters! Scripts are initialized in this order
        "FolderSetup", -- Must be first to create required folder structure
        "SafeRequire", -- Must be loaded early for other modules to use
        "CoreRegistry", -- Core dependency system
        "CoreRegistryMonitor", -- Monitors CoreRegistry health
        "TycoonFolderFixer", -- Fixes Tycoon folder structure issues
        "DataPersistenceManager" -- Ensures data persistence works correctly
    }
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[FixesBootstrap]", ...)
    end
end

-- Safely require a module
local function safeRequire(modulePath)
    if not modulePath then
        return nil
    end
    
    -- Check if it's a ModuleScript
    if not modulePath:IsA("ModuleScript") and not modulePath:IsA("Script") then
        log("Not a ModuleScript or Script:", modulePath:GetFullName())
        return nil
    end
    
    -- Try to require the module
    local success, result = pcall(function()
        -- Only try to require ModuleScripts
        if modulePath:IsA("ModuleScript") then
            return require(modulePath)
        else
            -- For regular scripts, they should auto-execute, return true
            return true
        end
    end)
    
    if success then
        return result
    else
        log("Failed to require", modulePath:GetFullName(), "-", result)
        return nil
    end
end

-- Find a module with the given name in common locations
local function findModule(name)
    -- First search standard locations for server modules
    local serverLocations = {
        ServerScriptService.Core,
        ServerScriptService
    }
    
    -- Add ".server" to the name for server scripts
    local serverName = name .. ".server"
    
    for _, location in ipairs(serverLocations) do
        if location then
            -- Try with .server suffix first
            local module = location:FindFirstChild(serverName)
            if module then
                return module
            end
            
            -- Then try without suffix
            module = location:FindFirstChild(name)
            if module then
                return module
            end
        end
    end
    
    -- Search for shared modules
    local sharedLocations = {
        ReplicatedStorage.shared,
        ReplicatedStorage
    }
    
    for _, location in ipairs(sharedLocations) do
        if location then
            local module = location:FindFirstChild(name)
            if module then
                return module
            end
        end
    end
    
    return nil
end

-- Initialize fixes in order
log("Starting initialization of critical fixes")

local loadedFixModules = {}

-- Try to find and require each fix script in order
for _, fixName in ipairs(CONFIG.fixScriptNames) do
    log("Looking for fix:", fixName)
    
    local fixModule = findModule(fixName)
    if fixModule then
        log("Found", fixName, "at:", fixModule:GetFullName())
        
        local fixAPI = safeRequire(fixModule)
        if fixAPI then
            loadedFixModules[fixName] = fixAPI
            log("Successfully loaded", fixName)
        else
            warn("[FixesBootstrap] Failed to load", fixName)
        end
    else
        warn("[FixesBootstrap] Could not find", fixName, "module")
    end
end

log("Completed initialization of critical fixes")

-- Return the loaded modules for other scripts to use if needed
return loadedFixModules
