--[[
    SystemDiagnostics.server.luau
    
    Diagnostic module to validate the CoreRegistry, ModuleLoader, and EventBridge systems.
    Run this script to check if the fixes have resolved the issues.
    
    Created: April 25, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local CONFIG = {
    RUN_ON_START = false,
    VERBOSE_LOGGING = true,
    CHECK_MODULE_PATHS = true,
    CHECK_CORE_SYSTEMS = true,
    CHECK_EVENTS = true
}

-- Health status tracking
local healthStatus = {
    moduleLoaderStatus = "unknown",
    coreRegistryStatus = "unknown",
    eventBridgeStatus = "unknown",
    systemsFound = 0,
    systemsTotal = 0,
    failures = {},
    criticalIssues = 0,
    warnings = 0
}

-- Logging
local function log(message)
    print("[SystemDiagnostics] " .. message)
end

local function warn_log(message)
    warn("[SystemDiagnostics] " .. message)
    healthStatus.warnings += 1
end

local function fail_log(message)
    warn("[SystemDiagnostics] CRITICAL: " .. message)
    healthStatus.criticalIssues += 1
    table.insert(healthStatus.failures, message)
end

-- Test ModuleLoader functionality
local function testModuleLoader()
    log("Testing ModuleLoader...")
    
    -- Try to find ModuleLoader in shared folder
    local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
    if not sharedFolder then
        fail_log("Shared folder not found in ReplicatedStorage!")
        return false
    end
    
    local moduleLoader = sharedFolder:FindFirstChild("ModuleLoader")
    if not moduleLoader then
        fail_log("ModuleLoader not found in shared folder!")
        return false
    end
    
    -- Try to require the ModuleLoader
    local success, ModuleLoader = pcall(function()
        return require(moduleLoader)
    end)
    
    if not success or not ModuleLoader then
        fail_log("Failed to require ModuleLoader: " .. tostring(ModuleLoader))
        return false
    end
    
    -- Test core functionality
    if typeof(ModuleLoader.tryRequire) ~= "function" then
        fail_log("ModuleLoader.tryRequire is not a function!")
        return false
    end
    
    if typeof(ModuleLoader.findModule) ~= "function" then
        warn_log("ModuleLoader.findModule is not a function!")
    end
    
    if typeof(ModuleLoader.initialize) ~= "function" then
        warn_log("ModuleLoader.initialize is not a function!")
    else
        -- Try to initialize
        success = pcall(function()
            ModuleLoader.initialize()
        end)
        
        if not success then
            warn_log("ModuleLoader.initialize failed to execute!")
        end
    end
    
    -- Test module loading
    local testModule = ModuleLoader.tryRequire("CoreRegistry")
    if not testModule then
        warn_log("ModuleLoader failed to find CoreRegistry!")
    else
        log("ModuleLoader successfully loaded CoreRegistry")
    end
    
    healthStatus.moduleLoaderStatus = "functional"
    return true
end

-- Test CoreRegistry functionality
local function testCoreRegistry()
    log("Testing CoreRegistry...")
    
    -- Try to find CoreRegistry in ServerScriptService/Core
    local CoreRegistry
    
    local coreFolder = ServerScriptService:FindFirstChild("Core")
    if not coreFolder then
        fail_log("Core folder not found in ServerScriptService!")
        return false
    end
    
    local coreRegistry = coreFolder:FindFirstChild("CoreRegistry")
    if not coreRegistry then
        fail_log("CoreRegistry not found in ServerScriptService/Core!")
        return false
    end
    
    -- Try to require the CoreRegistry
    local success
    success, CoreRegistry = pcall(function()
        return require(coreRegistry)
    end)
    
    if not success or not CoreRegistry then
        fail_log("Failed to require CoreRegistry: " .. tostring(CoreRegistry))
        return false
    end
    
    -- Test core functionality
    if typeof(CoreRegistry.registerSystem) ~= "function" then
        fail_log("CoreRegistry.registerSystem is not a function!")
        return false
    end
    
    if typeof(CoreRegistry.getSystem) ~= "function" then
        fail_log("CoreRegistry.getSystem is not a function!")
        return false
    end
    
    -- Test registration and retrieval
    local testSystem = {
        name = "TestSystem",
        initialize = function() return true end
    }
    
    CoreRegistry.registerSystem("TestSystem", testSystem)
    
    local retrievedSystem = CoreRegistry.getSystem("TestSystem")
    if not retrievedSystem then
        fail_log("CoreRegistry failed to retrieve registered system!")
        return false
    end
    
    if retrievedSystem.name ~= "TestSystem" then
        warn_log("Retrieved system does not match registered system!")
    end
    
    healthStatus.coreRegistryStatus = "functional"
    return true
end

-- Test EventBridge functionality
local function testEventBridge()
    log("Testing EventBridge...")
    
    -- Get CoreRegistry first
    local coreRegistry = ServerScriptService.Core:FindFirstChild("CoreRegistry")
    if not coreRegistry then
        fail_log("CoreRegistry not found, cannot test EventBridge!")
        return false
    end
    
    local success, CoreRegistry = pcall(function()
        return require(coreRegistry)
    end)
    
    if not success or not CoreRegistry then
        fail_log("Failed to require CoreRegistry: " .. tostring(CoreRegistry))
        return false
    end
    
    -- Get EventBridge through CoreRegistry
    local EventBridge = CoreRegistry.getSystem("EventBridge")
    if not EventBridge then
        fail_log("EventBridge not found in CoreRegistry!")
        return false
    end
    
    -- Test core functionality
    if typeof(EventBridge.connectEvent) ~= "function" then
        fail_log("EventBridge.connectEvent is not a function!")
        return false
    end
    
    if typeof(EventBridge.fireEvent) ~= "function" then
        fail_log("EventBridge.fireEvent is not a function!")
        return false
    end
    
    -- Test event connection and firing
    local testValue = 0
    
    EventBridge:connectEvent("TestEvent", function(value)
        testValue = value
    end)
    
    EventBridge:fireEvent("TestEvent", 42)
    
    -- Wait briefly for event to fire
    task.wait(0.1)
    
    if testValue ~= 42 then
        warn_log("EventBridge event didn't update test value correctly!")
    end
    
    -- Test RemoteEvent integration if events folder exists
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    if eventsFolder then
        local testEvent = eventsFolder:FindFirstChild("TestEvent")
        if not testEvent then
            testEvent = Instance.new("RemoteEvent")
            testEvent.Name = "TestEvent"
            testEvent.Parent = eventsFolder
            log("Created TestEvent RemoteEvent")
        end
        
        if typeof(EventBridge.registerRemoteEvent) == "function" then
            EventBridge:registerRemoteEvent("RemoteTestEvent", testEvent)
            log("Registered RemoteTestEvent with EventBridge")
        else
            warn_log("EventBridge.registerRemoteEvent is not a function!")
        end
    else
        warn_log("Events folder not found in ReplicatedStorage!")
    end
    
    healthStatus.eventBridgeStatus = "functional"
    return true
end

-- Check for all critical systems
local function checkCriticalSystems()
    log("Checking for critical systems...")
    
    -- Get CoreRegistry
    local coreRegistry = ServerScriptService.Core:FindFirstChild("CoreRegistry")
    if not coreRegistry then
        fail_log("CoreRegistry not found!")
        return false
    end
    
    local success, CoreRegistry = pcall(function()
        return require(coreRegistry)
    end)
    
    if not success or not CoreRegistry then
        fail_log("Failed to require CoreRegistry: " .. tostring(CoreRegistry))
        return false
    end
    
    -- List of all critical systems
    local criticalSystems = {
        "EventBridge",
        "CoreRegistry",
        "ModuleLoader",
        "DataThrottler",
        "DataManager", 
        "GymAutomation",
        "TutorialManager",
        "MigrationUtils",
        "BuyTileSystem",
        "EquipmentManager",
        "NPCSystem"
    }
    
    healthStatus.systemsTotal = #criticalSystems
    
    -- Check each system
    for _, systemName in ipairs(criticalSystems) do
        local system = CoreRegistry.getSystem(systemName)
        
        if system then
            log("Found system: " .. systemName)
            healthStatus.systemsFound += 1
        else
            warn_log("System not found: " .. systemName)
        end
    end
    
    log("Found " .. healthStatus.systemsFound .. "/" .. healthStatus.systemsTotal .. " critical systems")
    
    return healthStatus.systemsFound >= healthStatus.systemsTotal * 0.7 -- At least 70% of systems should be found
end

-- Check that expected folders exist
local function checkFolderStructure()
    log("Checking folder structure...")
    
    local expectedFolders = {
        ReplicatedStorage.shared,
        ReplicatedStorage.Events,
        ServerScriptService.Core,
        ServerScriptService.Systems,
        ServerScriptService.Data,
        ServerScriptService.Connectors
    }
    
    local foundCount = 0
    
    for _, folder in ipairs(expectedFolders) do
        if folder then
            foundCount += 1
        else
            local folderPath = "Unknown path"
            pcall(function()
                folderPath = folder:GetFullName()
            end)
            warn_log("Expected folder not found: " .. folderPath)
        end
    end
    
    log("Found " .. foundCount .. "/" .. #expectedFolders .. " expected folders")
    
    return foundCount >= #expectedFolders * 0.7 -- At least 70% of folders should be found
end

-- Check that events exist
local function checkEvents()
    log("Checking event structure...")
    
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    if not eventsFolder then
        fail_log("Events folder not found in ReplicatedStorage!")
        return false
    end
    
    -- List of events that should exist
    local expectedEvents = {
        "PlayerAddedToAllianceEvent",
        "PlayerRemovedFromAllianceEvent",
        "AllianceInviteEvent",
        "PurchaseTileEvent",
        "TileStateChangedEvent",
        "UIActionEvent"
    }
    
    local foundCount = 0
    
    for _, eventName in ipairs(expectedEvents) do
        local event = eventsFolder:FindFirstChild(eventName)
        
        if event and event:IsA("RemoteEvent") then
            foundCount += 1
        else
            warn_log("Expected event not found: " .. eventName)
        end
    end
      log("Found " .. foundCount .. "/" .. #expectedEvents .. " expected events")
    
    return foundCount >= #expectedEvents * 0.7 -- At least 70% of events should be found
end

-- Main diagnostics function
local function runDiagnostics()
    log("Starting system diagnostics...")
    
    -- Reset health status
    healthStatus = {
        moduleLoaderStatus = "unknown",
        coreRegistryStatus = "unknown",
        eventBridgeStatus = "unknown",
        systemsFound = 0,
        systemsTotal = 0,
        failures = {},
        criticalIssues = 0,
        warnings = 0
    }
    
    -- Run tests
    local moduleLoaderOK = testModuleLoader()
    local coreRegistryOK = testCoreRegistry()
    local eventBridgeOK = testEventBridge()
    
    if CONFIG.CHECK_MODULE_PATHS then
        checkFolderStructure()
    end
    
    if CONFIG.CHECK_CORE_SYSTEMS then
        checkCriticalSystems()
    end
    
    if CONFIG.CHECK_EVENTS then
        checkEvents()
    end
    
    -- Print summary
    log("========== DIAGNOSTICS SUMMARY ==========")
    log("ModuleLoader: " .. healthStatus.moduleLoaderStatus)
    log("CoreRegistry: " .. healthStatus.coreRegistryStatus)
    log("EventBridge: " .. healthStatus.eventBridgeStatus)
    log("Systems found: " .. healthStatus.systemsFound .. "/" .. healthStatus.systemsTotal)
    log("Critical issues: " .. healthStatus.criticalIssues)
    log("Warnings: " .. healthStatus.warnings)
    
    -- Show failures
    if #healthStatus.failures > 0 then
        log("The following critical issues were found:")
        for i, failure in ipairs(healthStatus.failures) do
            log("  " .. i .. ". " .. failure)
        end
    end
    
    -- Overall assessment
    local allPassed = moduleLoaderOK and coreRegistryOK and eventBridgeOK and healthStatus.criticalIssues == 0
    
    if allPassed then
        log("✅ All critical systems appear to be working correctly!")
    elseif healthStatus.criticalIssues > 0 then
        log("❌ Critical issues were found! Game functionality may be impaired.")
    else
        log("⚠️ Some non-critical issues were found. Game may work but with reduced functionality.")
    end
    
    return allPassed
end

-- Run diagnostics on script load if configured
if CONFIG.RUN_ON_START then
    task.spawn(function()
        -- Wait for systems to initialize
        task.wait(2)
        runDiagnostics()
    end)
end

return {
    runDiagnostics = runDiagnostics,
    getHealthStatus = function() 
        return healthStatus 
    end
}
