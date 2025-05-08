--!strict
-- RunTests.server.luau
-- Test runner for all test suites

local ServerScriptService = game:GetService("ServerScriptService")

-- Test configuration
local CONFIG = {
    testTimeout = 10, -- Maximum time in seconds for a test suite to complete
    verbose = true,   -- Whether to show detailed test output
}

-- Test results structure
type TestResult = {
    name: string,
    passed: number,
    failed: number,
    skipped: number,
    total: number,
    duration: number,
    errors: {string}
}

local TestRunner = {}

-- Available test suites
local TEST_SUITES = {
    BuyTileSystem = "Tests/BuyTileSystemTests",
    -- Add other test suites here as they are created
}

-- Run a specific test suite
function TestRunner.runSuite(suiteName: string): TestResult?
    local suite = TEST_SUITES[suiteName]
    if not suite then
        warn("Test suite not found:", suiteName)
        return nil
    end
    
    print(string.format("\n=== Running %s Test Suite ===\n", suiteName))
    
    local startTime = os.clock()
    local success, result = pcall(function()
        return require(ServerScriptService[suite])
    end)
    local duration = os.clock() - startTime
    
    if not success then
        warn("Failed to run test suite:", result)
        return {
            name = suiteName,
            passed = 0,
            failed = 1,
            skipped = 0,
            total = 1,
            duration = duration,
            errors = {tostring(result)}
        }
    end
    
    return result
end

-- Run all test suites
function TestRunner.runAll(): {TestResult}
    local results = {}
    
    for suiteName, _ in pairs(TEST_SUITES) do
        local result = TestRunner.runSuite(suiteName)
        if result then
            table.insert(results, result)
        end
    end
    
    return results
end

-- Print test results
function TestRunner.printResults(results: {TestResult})
    print("\n=== Test Results Summary ===\n")
    
    local totalPassed = 0
    local totalFailed = 0
    local totalSkipped = 0
    local totalTests = 0
    local totalDuration = 0
    
    for _, result in ipairs(results) do
        print(string.format(
            "%s: %d passed, %d failed, %d skipped (%.2fs)",
            result.name,
            result.passed,
            result.failed,
            result.skipped,
            result.duration
        ))
        
        if CONFIG.verbose and #result.errors > 0 then
            print("Errors:")
            for _, error in ipairs(result.errors) do
                print("  -", error)
            end
        end
        
        totalPassed += result.passed
        totalFailed += result.failed
        totalSkipped += result.skipped
        totalTests += result.total
        totalDuration += result.duration
    end
    
    print(string.format(
        "\nTotal: %d tests (%d passed, %d failed, %d skipped) in %.2fs",
        totalTests,
        totalPassed,
        totalFailed,
        totalSkipped,
        totalDuration
    ))
    
    if totalFailed > 0 then
        warn("\nSome tests failed! Please review the logs above.")
    else
        print("\nAll tests passed successfully!")
    end
end

-- Run tests with timeout protection
local function runWithTimeout(callback)
    local completed = false
    local results
    
    -- Run the tests in a separate thread
    task.spawn(function()
        results = callback()
        completed = true
    end)
    
    -- Wait for completion or timeout
    local startTime = os.clock()
    while not completed and (os.clock() - startTime) < CONFIG.testTimeout do
        task.wait(0.1)
    end
    
    if not completed then
        warn("Tests timed out after", CONFIG.testTimeout, "seconds")
        return {{
            name = "TIMEOUT",
            passed = 0,
            failed = 1,
            skipped = 0,
            total = 1,
            duration = CONFIG.testTimeout,
            errors = {"Test execution timed out"}
        }}
    end
    
    return results
end

-- Command-line interface for running tests
local function runTests(targetSuite: string?)
    local results
    
    if targetSuite then
        -- Run specific suite
        results = runWithTimeout(function()
            local result = TestRunner.runSuite(targetSuite)
            return result and {result} or {}
        end)
    else
        -- Run all suites
        results = runWithTimeout(function()
            return TestRunner.runAll()
        end)
    end
    
    TestRunner.printResults(results)
end

-- Export the test runner
return {
    runSuite = TestRunner.runSuite,
    runAll = TestRunner.runAll,
    printResults = TestRunner.printResults,
    run = runTests
} 