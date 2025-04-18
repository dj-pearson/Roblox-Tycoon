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
local IntegrationTests = require(script.Parent.IntegrationTests)

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
        EventBridgeTests,
        IntegrationTests
        -- Add more test suites here as they are created
    }
    
    for _, suite in ipairs(testSuites) do
        local suiteResults = suite:runAll()
        
        -- Update overall results
        results.total = results.total + suiteResults.total
        results.passed = results.passed + suiteResults.passed
        results.failed = results.failed + suiteResults.failed
        
        -- Store suite results
        table.insert(results.suites, {
            name = suite.name,
            passed = suiteResults.passed,
            failed = suiteResults.failed,
            total = suiteResults.total
        })
    end
    
    -- Calculate time taken
    local elapsed = tick() - startTime
    print("\n\n==================================================")
    print("TEST RESULTS")
    print("==================================================")
    print("Total tests: " .. results.total)
    print("Passed: " .. results.passed)
    print("Failed: " .. results.failed)
    print("Time taken: " .. string.format("%.2f", elapsed) .. "s")
    print("==================================================\n")
    
    -- Print individual suite results
    print("Suite results:")
    for _, suite in ipairs(results.suites) do
        if suite.failed > 0 then
            print("  - " .. suite.name .. ": " .. suite.passed .. "/" .. suite.total .. " passed (FAILED)")
        else
            print("  - " .. suite.name .. ": " .. suite.passed .. "/" .. suite.total .. " passed")
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
        elseif suiteName == "Integration" then
            return IntegrationTests:runAll()
        else
            warn("Unknown test suite: " .. suiteName)
            return false
        end
    end,
    getAvailableSuites = function()
        return {"DataManager", "EventBridge", "Integration"}
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