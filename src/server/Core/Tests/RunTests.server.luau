-- RunTests.luau
-- Central test runner for executing all test suites
-- Place in ServerScriptService/Core/Tests

local TestingFramework = require(game.ServerScriptService.Core.TestingFramework)

-- Configure the testing framework
TestingFramework.configure({
    showPassedTests = true,
    showFailedTests = true,
    stopOnFirstFailure = false,
    runInSequence = true
})

-- Import all test suites
local DataManagerTests = require(script.Parent.DataManagerTests)
local EventBridgeTests = require(script.Parent.EventBridgeTests)

-- Track results
local results = {
    total = 0,
    passed = 0,
    failed = 0,
    suites = {}
}

-- Run all test suites
local function runAllTests()
    print("\n\n==================================================")
    print("RUNNING ALL TEST SUITES")
    print("==================================================\n")
    
    local startTime = tick()
    local testSuites = {
        DataManagerTests,
        EventBridgeTests
        -- Add more test suites here as they are created
    }
    
    for _, suite in ipairs(testSuites) do
        local suiteResult = {
            name = suite.name,
            passed = true
        }
        
        local suiteSuccess = suite:runAll()
        if not suiteSuccess then
            suiteResult.passed = false
            results.failed = results.failed + 1
        else
            results.passed = results.passed + 1
        end
        
        results.total = results.total + 1
        table.insert(results.suites, suiteResult)
    end
    
    local endTime = tick()
    local duration = endTime - startTime
    
    -- Print summary
    print("\n==================================================")
    print("TEST SUMMARY")
    print("==================================================")
    print(string.format("Duration: %.2f seconds", duration))
    print(string.format("Test Suites: %d total, %d passed, %d failed", results.total, results.passed, results.failed))
    
    -- Print failed suites if any
    if results.failed > 0 then
        print("\nFailed Suites:")
        for _, suite in ipairs(results.suites) do
            if not suite.passed then
                print("  - " .. suite.name)
            end
        end
    end
    
    print("\nTesting complete!")
    return results.failed == 0
end

-- Expose public API
local RunTests = {
    runAll = runAllTests,
    runSuite = function(suiteName)
        if suiteName == "DataManager" then
            return DataManagerTests:runAll()
        elseif suiteName == "EventBridge" then
            return EventBridgeTests:runAll()
        else
            warn("Unknown test suite: " .. suiteName)
            return false
        end
    end,
    getAvailableSuites = function()
        return {"DataManager", "EventBridge"}
    end
}

-- Auto-run on script load in Studio (disable for production)
local RunService = game:GetService("RunService")
if RunService:IsStudio() then
    local autoRun = false -- Set to true to auto-run tests when script loads
    if autoRun then
        -- Delay to allow all systems to initialize
        task.spawn(function()
            task.wait(2)
            runAllTests()
        end)
    end
end

return RunTests