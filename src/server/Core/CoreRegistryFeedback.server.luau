--!strict
--[[
    CoreRegistryFeedback.server.luau
    
    Monitors the CoreRegistry loading status and provides feedback when issues are found.
    This script reports issues and resolution status to developers.
    
    Created: April 26, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Configuration
local Config = {
    ENABLE_TELEMETRY = true,          -- Whether to enable telemetry
    MONITOR_INTERVAL = 60,            -- Monitor interval in seconds
    ISSUE_THRESHOLD = 3,              -- Number of failures before reporting an issue
    NOTIFICATION_INTERVAL = 300,      -- Minimum interval between notifications (seconds)
    DEBUG_MODE = true                 -- Enable debug output
}

-- State tracking
local State = {
    lastNotificationTime = 0,         -- Last time a notification was sent
    failureCount = 0,                 -- Count of consecutive failures
    recoveryCount = 0,                -- Count of consecutive recoveries
    monitoringActive = false,         -- Whether monitoring is active
    systemsChecked = {},              -- Systems that have been checked
    reportedIssues = {},              -- Issues that have been reported
    fixesApplied = {}                 -- Fixes that have been applied
}

-- Debug logging
local function log(message)
    if Config.DEBUG_MODE then
        print("[CoreRegistryFeedback] " .. message)
    end
end

local function warn_log(message)
    warn("[CoreRegistryFeedback] " .. message)
end

-- Check if CoreRegistry is accessible
local function checkCoreRegistry()
    -- Try multiple methods to access CoreRegistry
    local methods = {
        -- Method 1: CoreRegistryAccess
        function()
            local CoreRegistryAccess = require(ReplicatedStorage.shared.CoreRegistryAccess)
            return CoreRegistryAccess:GetRegistry()
        end,
        
        -- Method 2: UniversalSystemFinder
        function()
            local UniversalSystemFinder = require(ReplicatedStorage.shared.UniversalSystemFinder) 
            return UniversalSystemFinder:GetCoreRegistry()
        end,
        
        -- Method 3: ModuleLoaderHelper
        function()
            local ModuleLoaderHelper = require(ReplicatedStorage.shared.ModuleLoaderHelper)
            return ModuleLoaderHelper.getCoreRegistry()
        end,
        
        -- Method 4: Direct require
        function()
            return require(ServerScriptService.Core.CoreRegistry)
        end
    }
    
    -- Try each method
    for i, method in ipairs(methods) do
        local success, result = pcall(method)
        
        if success and result then
            return true, result, "Method " .. i
        end
    end
    
    return false, nil, "All methods failed"
end

-- Check critical systems
local function checkCriticalSystems()
    local systemStatus = {}
    local criticalSystems = {
        "EventBridge",
        "DataThrottler",
        "ModuleLoaderHelper"
    }
    
    -- First try to get CoreRegistry
    local registrySuccess, registry = checkCoreRegistry()
    
    -- If CoreRegistry available, check systems through it
    if registrySuccess and registry then
        for _, systemName in ipairs(criticalSystems) do
            local success, system = pcall(function()
                return registry:getSystem(systemName)
            end)
            
            systemStatus[systemName] = success and system ~= nil
        end
    else
        -- Try with UniversalSystemFinder
        local UniversalSystemFinder
        pcall(function()
            UniversalSystemFinder = require(ReplicatedStorage.shared.UniversalSystemFinder)
        end)
        
        if UniversalSystemFinder then
            for _, systemName in ipairs(criticalSystems) do
                local system = UniversalSystemFinder:FindSystem(systemName)
                systemStatus[systemName] = system ~= nil
            end
        else
            -- All systems unavailable if we can't find either registry or finder
            for _, systemName in ipairs(criticalSystems) do
                systemStatus[systemName] = false
            end
        end
    end
    
    -- Count failures
    local failureCount = 0
    for _, available in pairs(systemStatus) do
        if not available then
            failureCount = failureCount + 1
        end
    end
    
    return systemStatus, failureCount
end

-- Generate detailed report
local function generateReport()
    local report = {
        timestamp = os.time(),
        registryStatus = false,
        systemsStatus = {},
        failureCount = 0,
        recoveryCount = State.recoveryCount,
        fixesApplied = State.fixesApplied
    }
    
    -- Check CoreRegistry
    local registrySuccess, registry, method = checkCoreRegistry()
    report.registryStatus = registrySuccess
    report.registryAccessMethod = method
    
    -- Check systems
    report.systemsStatus, report.failureCount = checkCriticalSystems()
    
    -- Add diagnostic test results if available
    pcall(function()
        local CoreRegistryDiagnostic = require(ReplicatedStorage.shared.CoreRegistryDiagnostic)
        local diagnosticResults = CoreRegistryDiagnostic.runAllTests()
        report.diagnosticResults = diagnosticResults
    end)
    
    return report
end

-- Notify admin of critical issues
local function notifyAdmin(message)
    -- Only send notifications at reasonable intervals
    local now = os.time()
    if now - State.lastNotificationTime < Config.NOTIFICATION_INTERVAL then
        return
    end
    
    -- Update notification time
    State.lastNotificationTime = now
    
    -- Find all admins in the server
    for _, player in pairs(Players:GetPlayers()) do
        -- Check if player is an admin (this would use your admin detection system)
        local isAdmin = player:GetAttribute("IsAdmin") == true
        
        if isAdmin then
            -- Send notification
            local notificationText = "SYSTEM NOTIFICATION: " .. message
            
            -- Try to use UI notification system if available
            if ReplicatedStorage:FindFirstChild("Events") and
               ReplicatedStorage.Events:FindFirstChild("ShowNotification") then
                ReplicatedStorage.Events.ShowNotification:FireClient(
                    player, 
                    notificationText,
                    Color3.fromRGB(255, 100, 100),
                    15 -- Duration in seconds
                )
            else
                -- Fallback to chat message
                local chatService = game:GetService("Chat")
                chatService:Chat(player.Character, notificationText, Enum.ChatColor.Red)
            end
        end
    end
end

-- Apply automated fixes when possible
local function tryApplyFixes()
    local fixesApplied = false
    
    -- Try to run SystemDiagnostics auto-fix if available
    pcall(function()
        local SystemDiagnostics = require(ServerScriptService.Core.SystemDiagnostics)
        if SystemDiagnostics.AutoFixIssues then
            local report = SystemDiagnostics:AutoFixIssues()
            
            if report.fixes and #table.keys(report.fixes) > 0 then
                fixesApplied = true
                
                -- Record applied fixes
                for fixName, fixDetails in pairs(report.fixes) do
                    State.fixesApplied[fixName] = fixDetails
                end
                
                log("Applied automated fixes: " .. table.concat(table.keys(report.fixes), ", "))
            end
        end
    end)
    
    return fixesApplied
end

-- Monitor CoreRegistry health
local function monitorHealth()
    if State.monitoringActive then
        return
    end
    
    State.monitoringActive = true
    log("Starting CoreRegistry health monitoring")
    
    -- Run monitoring loop
    task.spawn(function()
        while true do
            -- Check CoreRegistry
            local registrySuccess, _, method = checkCoreRegistry()
            
            if registrySuccess then
                if State.failureCount > 0 then
                    log("CoreRegistry recovered (using " .. method .. ")")
                    State.recoveryCount = State.recoveryCount + 1
                end
                
                State.failureCount = 0
            else
                State.failureCount = State.failureCount + 1
                warn_log("CoreRegistry check failed (" .. State.failureCount .. "/" .. Config.ISSUE_THRESHOLD .. ")")
                
                -- If we've hit the threshold, try to fix and notify
                if State.failureCount >= Config.ISSUE_THRESHOLD then
                    local fixesApplied = tryApplyFixes()
                    
                    if fixesApplied then
                        notifyAdmin("CoreRegistry issues detected. Automated fixes were applied.")
                    else
                        notifyAdmin("CoreRegistry issues detected. No automated fixes available.")
                    end
                    
                    -- Generate and log a detailed report
                    local report = generateReport()
                    warn_log("Detailed report: " .. game:GetService("HttpService"):JSONEncode(report))
                    
                    -- Reset failure count after attempting fixes
                    State.failureCount = 0
                end
            end
            
            -- Wait for next check
            wait(Config.MONITOR_INTERVAL)
        end
    end)
end

-- Initialize the feedback system
local function initialize()
    log("Initializing CoreRegistry feedback system")
    
    -- Wait a bit for systems to load
    wait(5)
    
    -- Generate initial report
    local initialReport = generateReport()
    log("Initial status: CoreRegistry " .. (initialReport.registryStatus and "AVAILABLE" or "UNAVAILABLE"))
    
    -- Start health monitoring
    monitorHealth()
    
    return true
end

-- Auto-initialize 
initialize()

-- Export the module
return {
    generateReport = generateReport,
    checkCoreRegistry = checkCoreRegistry,
    checkCriticalSystems = checkCriticalSystems
}
