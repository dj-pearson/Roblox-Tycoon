--!strict
--[[
    CoreRegistryDiagnostic.luau
    
    A standalone diagnostic tool to verify that our CoreRegistry access fixes are working properly.
    This can be run from both server and client contexts.
    
    Created: April 26, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Define test utilities
local Tests = {}
local TestResults = {
    passed = 0,
    failed = 0,
    total = 0,
    details = {}
}

-- Debug print function
local function log(message)
    print("[CoreRegistryDiagnostic] " .. message)
end

-- Run a single test
local function runTest(name, testFunction)
    TestResults.total += 1
    
    local success, result = pcall(testFunction)
    
    if success and result then
        TestResults.passed += 1
        TestResults.details[name] = {
            success = true,
            message = "Passed"
        }
        log("✓ " .. name)
    else
        TestResults.failed += 1
        local errorMessage = typeof(result) == "boolean" and "Test failed" or tostring(result)
        TestResults.details[name] = {
            success = false,
            message = errorMessage
        }
        log("✗ " .. name .. " - " .. errorMessage)
    end
    
    return success and result or false
end

-- Test 1: Check if CoreRegistryAccess is available
function Tests.TestCoreRegistryAccess()
    local CoreRegistryAccess
    local success = pcall(function()
        CoreRegistryAccess = require(ReplicatedStorage.shared.CoreRegistryAccess)
    end)
    
    if not success or not CoreRegistryAccess then
        return false, "CoreRegistryAccess module not found"
    end
    
    if not CoreRegistryAccess.GetRegistry then
        return false, "CoreRegistryAccess is missing GetRegistry method"
    end
    
    return true
end

-- Test 2: Check if UniversalSystemFinder is available
function Tests.TestUniversalSystemFinder()
    local UniversalSystemFinder
    local success = pcall(function()
        UniversalSystemFinder = require(ReplicatedStorage.shared.UniversalSystemFinder)
    end)
    
    if not success or not UniversalSystemFinder then
        return false, "UniversalSystemFinder module not found"
    end
    
    if not UniversalSystemFinder.FindSystem then
        return false, "UniversalSystemFinder is missing FindSystem method"
    end
    
    return true
end

-- Test 3: Check if ModuleLoaderHelper is available
function Tests.TestModuleLoaderHelper()
    local ModuleLoaderHelper
    local success = pcall(function()
        ModuleLoaderHelper = require(ReplicatedStorage.shared.ModuleLoaderHelper)
    end)
    
    if not success or not ModuleLoaderHelper then
        return false, "ModuleLoaderHelper module not found"
    end
    
    return true
end

-- Test 4: Check CoreRegistry access through CoreRegistryAccess
function Tests.TestCoreRegistryAccessGetRegistry()
    local CoreRegistryAccess
    local success = pcall(function()
        CoreRegistryAccess = require(ReplicatedStorage.shared.CoreRegistryAccess)
    end)
    
    if not success or not CoreRegistryAccess then
        return false, "CoreRegistryAccess module not found"
    end
    
    local CoreRegistry = CoreRegistryAccess:GetRegistry()
    if not CoreRegistry then
        return false, "CoreRegistryAccess couldn't find CoreRegistry"
    end
    
    -- Check for key methods
    if not CoreRegistry.registerSystem or not CoreRegistry.getSystem then
        return false, "CoreRegistry found by CoreRegistryAccess is missing key methods"
    end
    
    return true
end

-- Test 5: Check EventBridge access
function Tests.TestEventBridgeAccess()
    -- Try multiple methods to get EventBridge
    local EventBridge
    
    -- Method 1: CoreRegistryAccess
    pcall(function()
        local CoreRegistryAccess = require(ReplicatedStorage.shared.CoreRegistryAccess)
        if CoreRegistryAccess then
            EventBridge = CoreRegistryAccess:GetSystem("EventBridge")
        end
    end)
    
    -- Method 2: UniversalSystemFinder
    if not EventBridge then
        pcall(function()
            local UniversalSystemFinder = require(ReplicatedStorage.shared.UniversalSystemFinder)
            if UniversalSystemFinder then
                EventBridge = UniversalSystemFinder:FindSystem("EventBridge")
            end
        end)
    end
    
    -- Method 3: Direct CoreRegistry
    if not EventBridge and RunService:IsServer() then
        pcall(function()
            local CoreRegistry = require(ServerScriptService.Core.CoreRegistry)
            if CoreRegistry and CoreRegistry.getSystem then
                EventBridge = CoreRegistry:getSystem("EventBridge")
            end
        end)
    end
    
    if not EventBridge then
        return false, "EventBridge not found through any method"
    end
    
    -- Check for key methods
    if typeof(EventBridge) ~= "table" or not EventBridge.fireEvent or not EventBridge.connectEvent then
        return false, "EventBridge found but missing key methods"
    end
    
    return true
end

-- Test 6: Test event functionality
function Tests.TestEventFunctionality()
    -- Get EventBridge
    local EventBridge
    local success = pcall(function()
        local CoreRegistryAccess = require(ReplicatedStorage.shared.CoreRegistryAccess)
        EventBridge = CoreRegistryAccess:GetSystem("EventBridge")
    end)
    
    if not success or not EventBridge then
        return false, "Could not get EventBridge"
    end
    
    -- Test event firing and connection
    local testPassed = false
    local testValue = "test_" .. os.time()
    
    EventBridge:connectEvent("DiagnosticTestEvent", function(value)
        if value == testValue then
            testPassed = true
        end
    end)
    
    EventBridge:fireEvent("DiagnosticTestEvent", testValue)
    
    -- Wait a bit for event to fire
    wait(0.1)
    
    return testPassed, "Event system test failed - event didn't fire correctly"
end

-- Run all tests and generate a report
local function runAllTests()
    log("Starting CoreRegistry Diagnostic Tests")
    
    -- Run all tests
    for name, testFunction in pairs(Tests) do
        runTest(name, testFunction)
    end
    
    -- Generate report
    log("\n--- CoreRegistry Diagnostic Report ---")
    log(string.format("Tests: %d | Passed: %d | Failed: %d", 
        TestResults.total, TestResults.passed, TestResults.failed))
    log(string.format("Pass rate: %.1f%%", 
        (TestResults.passed / TestResults.total) * 100))
    
    -- List failed tests
    if TestResults.failed > 0 then
        log("\nFailed Tests:")
        for name, details in pairs(TestResults.details) do
            if not details.success then
                log("- " .. name .. ": " .. details.message)
            end
        end
    end
    
    log("\n--- End of Report ---")
    
    return TestResults
end

-- Run all tests immediately
runAllTests()

-- Export test utilities
return {
    runTest = runTest,
    runAllTests = runAllTests,
    TestResults = TestResults
}
