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
            "ServerScriptService.Fixes",
            "ServerScriptService.src",
            "ServerScriptService.src.server",
            "ServerScriptService.src.server.Core",
            "ServerScriptService.src.server.Systems",
            "ServerScriptService.src.server.Fixes"
        },
        client = {
            "PlayerScripts.client",
            "PlayerScripts.Core",
            "PlayerScripts.UI",
            "PlayerScripts.Fixes",
            "PlayerScripts.client.Core",
            "PlayerScripts.client.UI",
            "PlayerScripts.client.Fixes",
            "PlayerScripts.client.Systems"
        },
        shared = {
            "ReplicatedStorage.shared",
            "ReplicatedStorage.Core",
            "ReplicatedStorage.UI",
            "ReplicatedStorage.shared.Core",
            "ReplicatedStorage.shared.UI",
            "ReplicatedStorage.shared.Systems"
        }
    },
    pathAliases = {
        ["ServerScriptService.server"] = "ServerScriptService.server",
        ["ServerScriptService.Core"] = "ServerScriptService.Core",
        ["ServerScriptService.src"] = "ServerScriptService.src",
        ["PlayerScripts.client"] = "PlayerScripts.client",
        ["PlayerScripts.Core"] = "PlayerScripts.Core",
        ["ReplicatedStorage.shared"] = "ReplicatedStorage.shared",
        ["ReplicatedStorage.Core"] = "ReplicatedStorage.Core"
    },
    pathRules = {
        -- Rules for path creation and validation
        moduleScripts = {
            pattern = "%.lua$|%.luau$",
            type = "ModuleScript"
        },
        scripts = {
            pattern = "Script$",
            type = "Script"
        },
        localScripts = {
            pattern = "Client$|ClientScript$",
            type = "LocalScript"
        },
        folders = {
            pattern = "^[^%.]+$",
            type = "Folder"
        }
    },
    pathMappings = {
        -- Maps common path patterns to their actual locations
        ["Core"] = {
            server = "ServerScriptService.Core",
            client = "PlayerScripts.Core",
            shared = "ReplicatedStorage.Core"
        },
        ["Client"] = {
            server = "ServerScriptService.server",
            client = "PlayerScripts.client",
            shared = "ReplicatedStorage.shared"
        },
        ["UI"] = {
            server = "ServerScriptService.UI",
            client = "PlayerScripts.UI",
            shared = "ReplicatedStorage.UI"
        }
    }
}

-- Module state
local PathManager = {
    initialized = false,
    errors = {},
    lastCheck = 0,
    pathCache = {},
    createdPaths = {},
    routeCache = {}
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

-- Determine instance type from path
local function determineInstanceType(path)
    for _, rule in pairs(CONFIG.pathRules) do
        if string.match(path, rule.pattern) then
            return rule.type
        end
    end
    return "Folder" -- Default to Folder if no rules match
end

-- Get mapped path
local function getMappedPath(path, context)
    for pattern, mappings in pairs(CONFIG.pathMappings) do
        if string.match(path, "^" .. pattern) then
            return mappings[context] or path
        end
    end
    return path
end

-- Create path if it doesn't exist
local function createPath(path, context)
    if PathManager.createdPaths[path] then
        return true
    end
    
    -- Get mapped path based on context
    local mappedPath = getMappedPath(path, context)
    local parts = splitPath(mappedPath)
    local current = game
    
    for i = 1, #parts do
        local part = parts[i]
        local next = current:FindFirstChild(part)
        
        if not next then
            -- Determine the type of instance to create
            local instanceType = determineInstanceType(part)
            
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

-- Route path to appropriate location
local function routePath(path, context)
    -- Check cache first
    local cacheKey = path .. "_" .. (context or "default")
    if PathManager.routeCache[cacheKey] then
        return PathManager.routeCache[cacheKey]
    end
    
    -- Get mapped path
    local mappedPath = getMappedPath(path, context)
    
    -- Validate and create if needed
    local success, result = validatePath(mappedPath)
    if not success then
        createPath(mappedPath, context)
        success, result = validatePath(mappedPath)
    end
    
    if success then
        PathManager.routeCache[cacheKey] = result
        return result
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
    
    -- Handle specific error patterns
    if message:match("is not a valid member of") then
        local parent, child = message:match("is not a valid member of ([^\"]+) \"([^\"]+)\"")
        if parent and child then
            -- Try to create the missing path
            local path = child .. "." .. parent
            log("Attempting to create missing path: " .. path)
            createPath(path)
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
    
    -- Check for common error patterns
    local commonErrors = {
        "Core is not a valid member of ServerScriptService",
        "Client is not a valid member of PlayerScripts",
        "Server is not a valid member of ServerScriptService",
        "ClientRegistry is not a valid member of LocalScript"
    }
    
    for _, errorPattern in ipairs(commonErrors) do
        local success, result = validatePath(errorPattern:match("([^ ]+) is not a valid member of ([^ ]+)"))
        if not success then
            recordError(errorPattern)
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

-- Resolve path with context
function PathManager.resolvePath(path, context)
    return routePath(path, context)
end

-- Validate a path
function PathManager.validatePath(path)
    return validatePath(path)
end

-- Create path with context
function PathManager.createPath(path, context)
    return createPath(path, context)
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

-- Get path mapping
function PathManager.getPathMapping(path, context)
    return getMappedPath(path, context)
end

-- Clear path cache
function PathManager.clearCache()
    PathManager.pathCache = {}
    PathManager.routeCache = {}
    log("Path cache cleared")
end

-- Get all created paths
function PathManager.getCreatedPaths()
    return PathManager.createdPaths
end

-- Get path statistics
function PathManager.getStats()
    return {
        totalPaths = #PathManager.createdPaths,
        cachedPaths = #PathManager.pathCache,
        cachedRoutes = #PathManager.routeCache,
        errorCount = #PathManager.errors
    }
end

return PathManager 