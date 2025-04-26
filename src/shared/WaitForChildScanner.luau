--!strict
--[[
    WaitForChildScanner.luau
    
    A utility for scanning and fixing WaitForChild issues throughout the codebase.
    
    Created: April 26, 2025
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

-- Check if ModuleLoaderHelper is available
local ModuleLoaderHelper
local success, result = pcall(function()
    return require(ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("ModuleLoaderHelper"))
end)

if success then
    ModuleLoaderHelper = result
end

-- Configuration
local CONFIG = {
    SCAN_THRESHOLD = 0.1, -- Only report WaitForChild calls taking longer than this
    MAX_RESULTS = 100, -- Maximum number of results to return
    AUTO_FIX = false, -- Whether to automatically try to fix WaitForChild issues
    LOG_FIXES = true, -- Whether to log fixes made
    ANALYZE_CODE = true, -- Whether to analyze code for WaitForChild calls
    CREATE_MISSING = true, -- Whether to create missing folders/instances
}

-- Scanner module
local WaitForChildScanner = {
    results = {},
    fixes = {},
    config = CONFIG
}

-- Print a log message
local function log(message)
    print("[WaitForChildScanner] " .. message)
end

-- Scan for WaitForChild calls in a script source
local function scanSource(source, scriptPath)
    local results = {}
    
    -- Look for common WaitForChild patterns
    local patterns = {
        "(%w+):WaitForChild%(%s*[\"']([^\"']+)[\"']%s*%)",
        "(%w+)%.WaitForChild%(%s*[\"']([^\"']+)[\"']%s*%)",
        "(%w+):WaitForChild%(%s*\"([^\"]+)\"%s*%)",
        "(%w+)%.WaitForChild%(%s*\"([^\"]+)\"%s*%)",
        "(%w+):WaitForChild%(%s*'([^']+)'%s*%)",
        "(%w+)%.WaitForChild%(%s*'([^']+)'%s*%)"
    }
    
    for _, pattern in ipairs(patterns) do
        for parent, child in string.gmatch(source, pattern) do
            table.insert(results, {
                parent = parent,
                child = child,
                path = scriptPath,
                pattern = pattern
            })
        end
    end
    
    return results
end

-- Analyze a script for WaitForChild calls
local function analyzeScript(script)
    -- Skip if script isn't actually a script
    if not (script:IsA("Script") or script:IsA("LocalScript") or script:IsA("ModuleScript")) then
        return {}
    end
    
    -- Get the script source
    local source = script.Source
    
    -- Scan the source
    return scanSource(source, script:GetFullName())
end

-- Recursively analyze all scripts in a given instance
local function analyzeScriptsRecursive(instance, results)
    results = results or {}
    
    -- Analyze this instance if it's a script
    if instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript") then
        local scriptResults = analyzeScript(instance)
        for _, result in ipairs(scriptResults) do
            table.insert(results, result)
        end
    end
    
    -- Recursively analyze children
    for _, child in ipairs(instance:GetChildren()) do
        analyzeScriptsRecursive(child, results)
    end
    
    return results
end

-- Find or create important paths
local function ensureCriticalPaths()
    -- Ensure shared folder exists
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared then
        shared = Instance.new("Folder")
        shared.Name = "shared"
        shared.Parent = ReplicatedStorage
        log("Created shared folder in ReplicatedStorage")
    end
    
    -- Ensure Events folder exists
    local events = ReplicatedStorage:FindFirstChild("Events")
    if not events then
        events = Instance.new("Folder")
        events.Name = "Events"
        events.Parent = ReplicatedStorage
        log("Created Events folder in ReplicatedStorage")
    end
    
    -- Ensure Core folder exists in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if not core then
        core = Instance.new("Folder")
        core.Name = "Core"
        core.Parent = ServerScriptService
        log("Created Core folder in ServerScriptService")
    end
    
    -- Ensure src folder exists
    local src = ReplicatedStorage:FindFirstChild("src")
    if not src then
        src = Instance.new("Folder")
        src.Name = "src"
        src.Parent = ReplicatedStorage
        log("Created src folder in ReplicatedStorage")
    end
    
    -- Ensure client folder exists in src
    local client = src:FindFirstChild("client")
    if not client then
        client = Instance.new("Folder")
        client.Name = "client"
        client.Parent = src
        log("Created client folder in src")
    end
    
    -- Ensure server folder exists in src
    local server = src:FindFirstChild("server")
    if not server then
        server = Instance.new("Folder")
        server.Name = "server"
        server.Parent = src
        log("Created server folder in src")
    end
    
    -- Ensure shared folder exists in src
    local srcShared = src:FindFirstChild("shared")
    if not srcShared then
        srcShared = Instance.new("Folder")
        srcShared.Name = "shared"
        srcShared.Parent = src
        log("Created shared folder in src")
    end
end

-- Scan the entire codebase for WaitForChild issues
function WaitForChildScanner.scanCodebase()
    log("Starting full codebase scan...")
    
    -- Clear previous results
    WaitForChildScanner.results = {}
    WaitForChildScanner.fixes = {}
    
    -- Create critical paths if needed
    if CONFIG.CREATE_MISSING then
        ensureCriticalPaths()
    end
    
    -- Scan for static WaitForChild calls in scripts
    if CONFIG.ANALYZE_CODE then
        log("Analyzing scripts for WaitForChild calls...")
        
        -- Analyze all scripts in game
        local results = {}
        analyzeScriptsRecursive(game, results)
        
        log("Found " .. #results .. " WaitForChild calls in scripts")
        WaitForChildScanner.results = results
    end
    
    return WaitForChildScanner.results
end

-- Fix common WaitForChild issues
function WaitForChildScanner.fixCommonIssues()
    log("Fixing common WaitForChild issues...")
    
    -- Load SafeWaitForChild if available
    local SafeWaitForChild
    if ModuleLoaderHelper then
        SafeWaitForChild = ModuleLoaderHelper:GetModule("SafeWaitForChild")
    end
    
    if not SafeWaitForChild and ReplicatedStorage.shared:FindFirstChild("SafeWaitForChild") then
        SafeWaitForChild = require(ReplicatedStorage.shared.SafeWaitForChild)
    end
    
    if not SafeWaitForChild then
        log("SafeWaitForChild module not found, cannot perform some fixes")
        return
    end
    
    -- Ensure all common folders exist
    SafeWaitForChild.getOrCreateChild(ReplicatedStorage, "shared", "Folder")
    SafeWaitForChild.getOrCreateChild(ReplicatedStorage, "Events", "Folder")
    SafeWaitForChild.getOrCreateChild(ServerScriptService, "Core", "Folder")
    
    -- Fix common events
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    local commonEvents = {
        "PlaySoundEvent",
        "PlayerRemovedFromAllianceEvent", 
        "PlayerAddedToAllianceEvent",
        "AllianceUpdatedEvent",
        "UpdatedTycoonEvent",
        "RevenueUpdatedEvent",
        "MembershipUpdatedEvent"
    }
    
    for _, eventName in ipairs(commonEvents) do
        -- Check if the event exists in ReplicatedStorage directly
        local directEvent = ReplicatedStorage:FindFirstChild(eventName)
        
        -- If it exists directly but not in Events folder, move it
        if directEvent and directEvent:IsA("RemoteEvent") and not eventsFolder:FindFirstChild(eventName) then
            directEvent.Parent = eventsFolder
            log("Moved " .. eventName .. " to Events folder")
            table.insert(WaitForChildScanner.fixes, {
                type = "moved_event",
                name = eventName, 
                from = "ReplicatedStorage",
                to = "Events"
            })
        -- If it doesn't exist, create it in the Events folder
        elseif not directEvent and not eventsFolder:FindFirstChild(eventName) then
            local newEvent = Instance.new("RemoteEvent")
            newEvent.Name = eventName
            newEvent.Parent = eventsFolder
            log("Created missing event: " .. eventName)
            table.insert(WaitForChildScanner.fixes, {
                type = "created_event",
                name = eventName
            })
        end
    end
    
    -- Fix common modules
    local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
    local commonModules = {
        "ClientRegistry",
        "ModuleLoader",
        "SafeWaitForChild",
        "EventBridge",
        "UIComponents",
        "AssetValidator"
    }
    
    for _, moduleName in ipairs(commonModules) do
        if not sharedFolder:FindFirstChild(moduleName) then
            -- First check if it exists elsewhere
            local found = false
            
            -- Check if CoreRegistry can provide it
            if ModuleLoaderHelper then
                local module = ModuleLoaderHelper:GetSystem(moduleName)
                if module then
                    log("Module " .. moduleName .. " is available through CoreRegistry")
                    found = true
                end
            end
            
            -- If still not found, could create a stub module here
            if not found and CONFIG.CREATE_MISSING then
                log("Module " .. moduleName .. " not found, but would create a stub")
                -- Implementation for creating stubs would go here
            end
        end
    end
    
    return WaitForChildScanner.fixes
end

-- Generate a report of WaitForChild issues
function WaitForChildScanner.generateReport()
    local report = {
        totalIssues = #WaitForChildScanner.results,
        totalFixes = #WaitForChildScanner.fixes,
        byParent = {},
        byScript = {},
        fixes = WaitForChildScanner.fixes
    }
    
    -- Group by parent
    for _, result in ipairs(WaitForChildScanner.results) do
        report.byParent[result.parent] = report.byParent[result.parent] or {}
        table.insert(report.byParent[result.parent], result)
    end
    
    -- Group by script
    for _, result in ipairs(WaitForChildScanner.results) do
        report.byScript[result.path] = report.byScript[result.path] or {}
        table.insert(report.byScript[result.path], result)
    end
    
    return report
end

-- Configure the scanner
function WaitForChildScanner.configure(config)
    for key, value in pairs(config) do
        CONFIG[key] = value
    end
end

return WaitForChildScanner
