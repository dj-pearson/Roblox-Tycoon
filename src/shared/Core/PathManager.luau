--[[
    PathManager.luau
    
    Core system for managing and validating paths in the game.
    This system ensures proper path resolution and structure.
    
    Features:
    - Path validation and resolution
    - Directory structure management
    - Path caching
    - Error handling
    - Integration with CoreRegistry
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Configuration
local CONFIG = {
    debug = true,
    checkInterval = 30, -- seconds
    maxErrors = 50,
    errorRetentionTime = 3600, -- 1 hour
    requiredPaths = {
        server = {
            "ServerScriptService.server",
            "ServerScriptService.Core",
            "ServerScriptService.Data",
            "ServerScriptService.Fixes"
        },
        client = {
            "PlayerScripts.client",
            "PlayerScripts.Core",
            "PlayerScripts.UI",
            "PlayerScripts.Fixes"
        },
        shared = {
            "ReplicatedStorage.shared",
            "ReplicatedStorage.Core",
            "ReplicatedStorage.UI"
        }
    },
    pathAliases = {
        ["ServerScriptService.server"] = "ServerScriptService.server",
        ["ServerScriptService.Core"] = "ServerScriptService.Core",
        ["PlayerScripts.client"] = "PlayerScripts.client",
        ["PlayerScripts.Core"] = "PlayerScripts.Core",
        ["ReplicatedStorage.shared"] = "ReplicatedStorage.shared",
        ["ReplicatedStorage.Core"] = "ReplicatedStorage.Core"
    }
}

-- Module state
local PathManager = {
    initialized = false,
    errors = {},
    lastCheck = 0,
    pathCache = {},
    createdPaths = {}
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[PathManager]", ...)
    end
end

-- Split path into parts
local function splitPath(path)
    local parts = {}
    for part in string.gmatch(path, "[^%.]+") do
        table.insert(parts, part)
    end
    return parts
end

-- Get parent instance from path
local function getParentFromPath(path)
    local parts = splitPath(path)
    local current = game
    
    for i = 1, #parts - 1 do
        current = current:FindFirstChild(parts[i])
        if not current then
            return nil
        end
    end
    
    return current
end

-- Create path if it doesn't exist
local function createPath(path)
    if PathManager.createdPaths[path] then
        return true
    end
    
    local parts = splitPath(path)
    local current = game
    
    for i = 1, #parts do
        local part = parts[i]
        local next = current:FindFirstChild(part)
        
        if not next then
            -- Determine the type of instance to create
            local instanceType = "Folder"
            if i == #parts then
                if string.match(part, "%.lua$") or string.match(part, "%.luau$") then
                    instanceType = "ModuleScript"
                end
            end
            
            next = Instance.new(instanceType)
            next.Name = part
            next.Parent = current
            
            log("Created " .. instanceType .. ": " .. part .. " in " .. current:GetFullName())
        end
        
        current = next
    end
    
    PathManager.createdPaths[path] = true
    return true
end

-- Validate path
local function validatePath(path)
    local parts = splitPath(path)
    local current = game
    
    for _, part in ipairs(parts) do
        current = current:FindFirstChild(part)
        if not current then
            return false, "Path not found: " .. part .. " in " .. current:GetFullName()
        end
    end
    
    return true, current
end

-- Resolve path
local function resolvePath(path)
    -- Check cache first
    if PathManager.pathCache[path] then
        return PathManager.pathCache[path]
    end
    
    -- Check aliases
    local aliasedPath = CONFIG.pathAliases[path]
    if aliasedPath then
        path = aliasedPath
    end
    
    -- Validate path
    local success, result = validatePath(path)
    if success then
        PathManager.pathCache[path] = result
        return result
    end
    
    -- Try to create path
    if createPath(path) then
        success, result = validatePath(path)
        if success then
            PathManager.pathCache[path] = result
            return result
        end
    end
    
    return nil
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(PathManager.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #PathManager.errors > CONFIG.maxErrors do
        table.remove(PathManager.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #PathManager.errors, 1, -1 do
        if PathManager.errors[i].timestamp < cutoff then
            table.remove(PathManager.errors, i)
        end
    end
    
    log("Error recorded: " .. message)
end

-- Check system health
local function checkHealth()
    local now = os.time()
    PathManager.lastCheck = now
    
    -- Check required paths
    for category, paths in pairs(CONFIG.requiredPaths) do
        for _, path in ipairs(paths) do
            local success, result = validatePath(path)
            if not success then
                recordError("Required path not found: " .. path)
                createPath(path)
            end
        end
    end
    
    return true
end

-- Initialize PathManager
function PathManager.initialize()
    if PathManager.initialized then return true end
    
    log("Initializing PathManager...")
    
    -- Create required paths
    for category, paths in pairs(CONFIG.requiredPaths) do
        for _, path in ipairs(paths) do
            createPath(path)
        end
    end
    
    -- Start health monitoring
    task.spawn(function()
        while true do
            task.wait(CONFIG.checkInterval)
            checkHealth()
        end
    end)
    
    PathManager.initialized = true
    log("PathManager initialized")
    return true
end

-- Resolve a path
function PathManager.resolvePath(path)
    return resolvePath(path)
end

-- Validate a path
function PathManager.validatePath(path)
    return validatePath(path)
end

-- Create a path
function PathManager.createPath(path)
    return createPath(path)
end

-- Get error count
function PathManager.getErrorCount()
    return #PathManager.errors
end

-- Get recent errors
function PathManager.getRecentErrors()
    return PathManager.errors
end

-- Force a health check
function PathManager.forceCheck()
    return checkHealth()
end

return PathManager 