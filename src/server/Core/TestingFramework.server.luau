--[[
    TestingFramework.server.luau
    Provides testing utilities for server-side systems and modules.
    Part of the Core systems architecture.
]]

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module dependencies
local CoreRegistry

-- Configuration
local CONFIG = {
    -- Test environment
    mockServices    = true,     -- Whether to mock services or use real ones
    isolateTests    = true,     -- Whether to run tests in isolation

    -- Reporting
    detailedReports = true,     -- Whether to include detailed reports
    logToOutput     = true,     -- Whether to log to output window

    -- Performance
    timeoutSeconds  = 10,       -- Maximum time for a test to run

    -- Debug
    debug           = false     -- Enable debug logging
}

-- Module table
local TestingFramework = {
    _name            = "TestingFramework",
    _version         = "1.0.0",
    _dependencies    = {"CoreRegistry"},

    -- Internal state
    _mocks           = {},      -- Mocked objects and services
    _tests           = {},      -- Test definitions
    _results         = {},      -- Test results
    _currentSuite    = nil,     -- Current test suite being defined
    _suites          = {},      -- Test suites
    _runningTest     = false,   -- Whether a test is currently running
    _runningTestName = "",      -- Name of the currently running test

    -- Constants
    TEST_STATUSES = {
        PASS    = "PASS",
        FAIL    = "FAIL",
        ERROR   = "ERROR",
        SKIPPED = "SKIPPED",
        TIMEOUT = "TIMEOUT"
    }
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[Testing Framework]", ...)
    end
end

--[[ Test Suite Creation ]]--

function TestingFramework:describeSuite(suiteName, callback)
    assert(type(suiteName) == "string", "Suite name must be a string")
    assert(type(callback)  == "function", "Suite callback must be a function")

    local suite = {
        name       = suiteName,
        tests      = {},
        beforeEach = nil,
        afterEach  = nil,
        beforeAll  = nil,
        afterAll   = nil
    }

    local previousSuite   = self._currentSuite
    self._currentSuite    = suite

    local success, err    = pcall(callback)
    if not success then
        warn("Error defining test suite '" .. suiteName .. "': " .. err)
    end

    table.insert(self._suites, suite)
    self._currentSuite = previousSuite

    return suite
end

function TestingFramework:it(testName, testFunc)
    assert(type(testName) == "string",   "Test name must be a string")
    assert(type(testFunc) == "function", "Test function must be a function")

    if not self._currentSuite then
        error("Cannot define a test outside of a suite. Use describeSuite first.")
    end

    table.insert(self._currentSuite.tests, {
        name = testName,
        func = testFunc,
        skip = false
    })

    debugPrint("Defined test:", testName, "in suite:", self._currentSuite.name)
end

function TestingFramework:xit(testName, testFunc)
    assert(type(testName) == "string",   "Test name must be a string")
    assert(type(testFunc) == "function", "Test function must be a function")

    if not self._currentSuite then
        error("Cannot define a test outside of a suite. Use describeSuite first.")
    end

    table.insert(self._currentSuite.tests, {
        name = testName,
        func = testFunc,
        skip = true
    })

    debugPrint("Defined skipped test:", testName, "in suite:", self._currentSuite.name)
end

function TestingFramework:beforeEach(setupFunc)
    assert(type(setupFunc) == "function", "Setup function must be a function")

    if not self._currentSuite then
        error("Cannot define beforeEach outside of a suite. Use describeSuite first.")
    end

    self._currentSuite.beforeEach = setupFunc
end

function TestingFramework:afterEach(teardownFunc)
    assert(type(teardownFunc) == "function", "Teardown function must be a function")

    if not self._currentSuite then
        error("Cannot define afterEach outside of a suite. Use describeSuite first.")
    end

    self._currentSuite.afterEach = teardownFunc
end

function TestingFramework:beforeAll(setupFunc)
    assert(type(setupFunc) == "function", "Setup function must be a function")

    if not self._currentSuite then
        error("Cannot define beforeAll outside of a suite. Use describeSuite first.")
    end

    self._currentSuite.beforeAll = setupFunc
end

function TestingFramework:afterAll(teardownFunc)
    assert(type(teardownFunc) == "function", "Teardown function must be a function")

    if not self._currentSuite then
        error("Cannot define afterAll outside of a suite. Use describeSuite first.")
    end

    self._currentSuite.afterAll = teardownFunc
end

--[[ Test Assertions ]]--

function TestingFramework:expect(value)
    local assertion = {
        value    = value,
        inverted = false
    }

    -- Negate the next assertion
    assertion["not"] = function(self)
        self.inverted = not self.inverted
        return self
    end

    function assertion:toBe(expected)
        local pass = (self.value == expected)
        pass = self.inverted and not pass or pass

        if not pass then
            local msg = self.inverted
                and ("Expected " .. tostring(self.value) .. " not to be " .. tostring(expected))
                or  ("Expected " .. tostring(self.value) .. " to be "     .. tostring(expected))
            error(msg)
        end

        return true
    end

    function assertion:toBeCloseTo(expected, precision)
        precision = precision or 0.0001
        if type(self.value) ~= "number" or type(expected) ~= "number" then
            error("toBeCloseTo can only be used with numbers")
        end

        local pass = math.abs(self.value - expected) < precision
        pass = self.inverted and not pass or pass

        if not pass then
            local msg = self.inverted
                and ("Expected " .. tostring(self.value) .. " not to be close to " .. tostring(expected))
                or  ("Expected " .. tostring(self.value) .. " to be close to "     .. tostring(expected))
            error(msg)
        end

        return true
    end

    function assertion:toBeNil()
        local pass = (self.value == nil)
        pass = self.inverted and not pass or pass

        if not pass then
            local msg = self.inverted
                and ("Expected " .. tostring(self.value) .. " not to be nil")
                or  "Expected value to be nil"
            error(msg)
        end

        return true
    end

    function assertion:toBeTruthy()
        local pass = not not self.value
        pass = self.inverted and not pass or pass

        if not pass then
            local msg = self.inverted
                and ("Expected " .. tostring(self.value) .. " not to be truthy")
                or  ("Expected " .. tostring(self.value) .. " to be truthy")
            error(msg)
        end

        return true
    end

    function assertion:toBeFalsy()
        local pass = not self.value
        pass = self.inverted and not pass or pass

        if not pass then
            local msg = self.inverted
                and ("Expected " .. tostring(self.value) .. " not to be falsy")
                or  ("Expected " .. tostring(self.value) .. " to be falsy")
            error(msg)
        end

        return true
    end

    function assertion:toBeA(expected)
        local t    = type(self.value)
        local pass = (t == expected)
        pass = self.inverted and not pass or pass

        if not pass then
            local msg = self.inverted
                and ("Expected " .. tostring(self.value) .. " not to be a " .. expected)
                or  ("Expected " .. tostring(self.value) .. " to be a " .. expected .. " but got " .. t)
            error(msg)
        end

        return true
    end

    function assertion:toContain(expected)
        if type(self.value) ~= "table" then
            error("toContain can only be used with tables")
        end

        local found = false
        for _, item in pairs(self.value) do
            if item == expected then
                found = true
                break
            end
        end

        local pass = found
        pass = self.inverted and not pass or pass

        if not pass then
            local msg = self.inverted
                and ("Expected table not to contain " .. tostring(expected))
                or  ("Expected table to contain "     .. tostring(expected))
            error(msg)
        end

        return true
    end

    function assertion:toHaveLength(expected)
        local len
        if type(self.value) == "table" then
            len = #self.value
        elseif type(self.value) == "string" then
            len = string.len(self.value)
        else
            error("toHaveLength can only be used with tables and strings")
        end

        local pass = (len == expected)
        pass = self.inverted and not pass or pass

        if not pass then
            local msg = self.inverted
                and ("Expected value not to have length " .. tostring(expected))
                or  ("Expected value to have length " .. tostring(expected) .. " but got " .. tostring(len))
            error(msg)
        end

        return true
    end

    function assertion:toThrow(expectedError)
        if type(self.value) ~= "function" then
            error("toThrow can only be used with functions")
        end

        local success, err = pcall(self.value)
        local throws      = not success
        local match       = not expectedError or (throws and type(err) == "string" and string.find(err, expectedError))
        local pass        = throws and (not expectedError or match)
        pass = self.inverted and not pass or pass

        if not pass then
            local msg
            if self.inverted then
                msg = expectedError
                    and ("Expected function not to throw error matching '" .. expectedError .. "'")
                    or  "Expected function not to throw any error"
            else
                msg = expectedError
                    and ( throws
                        and ("Expected error to match '" .. expectedError .. "' but got '" .. tostring(err) .. "'")
                        or "Expected function to throw error matching '" .. expectedError .. "' but it did not throw"
                      )
                    or "Expected function to throw an error"
            end
            error(msg)
        end

        return true
    end

    function assertion:toMatch(pattern)
        if type(self.value) ~= "string" then
            error("toMatch can only be used with strings")
        end

        local matches = string.match(self.value, pattern) ~= nil
        local pass    = matches
        pass = self.inverted and not pass or pass

        if not pass then
            local msg = self.inverted
                and ("Expected '" .. tostring(self.value) .. "' not to match pattern '" .. pattern .. "'")
                or  ("Expected '" .. tostring(self.value) .. "' to match pattern '" .. pattern .. "'")
            error(msg)
        end

        return true
    end

    return assertion
end

--[[ Mock Utilities ]]--

function TestingFramework:createSpy(name)
    name = name or "unnamed spy"

    local calls = {}

    local spy = function(...)
        local args = {...}
        table.insert(calls, { args = args, timestamp = tick() })

        if spy.returnValue ~= nil then
            return spy.returnValue
        end

        if spy.implementation then
            return spy.implementation(...)
        end
    end

    spy.name           = name
    spy.calls          = calls
    spy.returnValue    = nil
    spy.implementation = nil

    spy.andReturn = function(value)
        spy.returnValue = value
        return spy
    end

    spy.andImplement = function(impl)
        assert(type(impl) == "function", "Implementation must be a function")
        spy.implementation = impl
        return spy
    end

    spy.reset = function()
        table.clear(calls)
        spy.returnValue    = nil
        spy.implementation = nil
    end

    spy.toHaveBeenCalled      = function() return #calls > 0 end
    spy.toHaveBeenCalledTimes = function(times) return #calls == times end
    spy.toHaveBeenCalledWith  = function(...)
        local expectedArgs = {...}
        for _, call in ipairs(calls) do
            local match = true
            for i, arg in ipairs(expectedArgs) do
                if call.args[i] ~= arg then
                    match = false
                    break
                end
            end
            if match then return true end
        end
        return false
    end

    return spy
end

function TestingFramework:createMockSystem(name, methods)
    name    = name or "MockSystem"
    methods = methods or {}

    local mockSystem = {
        _name    = name,
        _version = "1.0.0-mock"
    }

    for _, methodName in ipairs(methods) do
        mockSystem[methodName] = self:createSpy(name .. "." .. methodName)
    end

    setmetatable(mockSystem, {
        __index = function(tbl, key)
            if type(key) == "string" then
                local spyObj = self:createSpy(name .. "." .. key)
                rawset(tbl, key, spyObj)
                return spyObj
            end
        end
    })

    return mockSystem
end

function TestingFramework:mock(target, methods)
    if type(target) == "string" then
        local mock = self:createMockSystem(target, methods)
        self._mocks[target] = mock
        return mock
    elseif type(target) == "table" then
        local name = target._name or "UnnamedObject"
        local mock = {}
        for key, value in pairs(target) do
            if type(value) == "function" then
                mock[key] = self:createSpy(name .. "." .. key)
                    :andImplement(function(...) return value(...) end)
            else
                mock[key] = value
            end
        end
        return mock
    else
        error("Cannot mock " .. type(target))
    end
end

function TestingFramework:resetMocks()
    for _, mock in pairs(self._mocks) do
        for _, value in pairs(mock) do
            if type(value) == "table" and value.reset then
                value:reset()
            end
        end
    end

    debugPrint("Reset all mocks")
end

--[[ Test Running ]]--

function TestingFramework:runTest(suite, test)
    if test.skip then
        return {
            name    = test.name,
            status  = self.TEST_STATUSES.SKIPPED,
            time    = 0,
            message = "Test was skipped"
        }
    end

    local result = {
        name    = test.name,
        status  = nil,
        time    = 0,
        message = nil
    }

    self._runningTest     = true
    self._runningTestName = test.name

    local startTime = tick()
    local thread = coroutine.create(function()
        if suite.beforeEach then
            local ok, err = pcall(suite.beforeEach)
            if not ok then
                return false, "beforeEach failed: " .. err
            end
        end

        local ok, err = pcall(test.func)

        if suite.afterEach then
            local aok, aerr = pcall(suite.afterEach)
            if not aok and ok then
                return false, "afterEach failed: " .. aerr
            end
        end

        return ok, err
    end)

    coroutine.resume(thread)

    local completed = false
    local elapsedTime = 0
    local testResult, errorMsg

    while not completed and elapsedTime < CONFIG.timeoutSeconds do
        elapsedTime = tick() - startTime
        if coroutine.status(thread) == "dead" then
            completed, testResult, errorMsg = coroutine.resume(thread)
            break
        end
        task.wait(0.1)
    end

    result.time = tick() - startTime

    if not completed then
        result.status  = self.TEST_STATUSES.TIMEOUT
        result.message = "Test timed out after " .. CONFIG.timeoutSeconds .. " seconds"
    elseif testResult then
        result.status = self.TEST_STATUSES.PASS
    else
        result.status  = self.TEST_STATUSES.FAIL
        result.message = errorMsg or "Test failed without an error message"
    end

    self._runningTest     = false
    self._runningTestName = ""

    debugPrint("Test '" .. test.name .. "' " .. result.status .. " (" .. result.time .. "s)")

    return result
end

function TestingFramework:runSuite(suite)
    local suiteResults = {
        name    = suite.name,
        tests   = {},
        time    = 0,
        passed  = 0,
        failed  = 0,
        skipped = 0,
        total   = #suite.tests
    }

    debugPrint("Running suite: " .. suite.name .. " (" .. #suite.tests .. " tests)")

    local startTime = tick()

    if suite.beforeAll then
        local ok, err = pcall(suite.beforeAll)
        if not ok then
            for _, test in ipairs(suite.tests) do
                table.insert(suiteResults.tests, {
                    name    = test.name,
                    status  = self.TEST_STATUSES.ERROR,
                    time    = 0,
                    message = "beforeAll failed: " .. err
                })
                suiteResults.failed = suiteResults.failed + 1
            end
            suiteResults.time = tick() - startTime
            return suiteResults
        end
    end

    for _, test in ipairs(suite.tests) do
        if CONFIG.isolateTests then
            self:resetMocks()
        end

        local result = self:runTest(suite, test)

        if result.status == self.TEST_STATUSES.PASS then
            suiteResults.passed = suiteResults.passed + 1
        elseif result.status == self.TEST_STATUSES.SKIPPED then
            suiteResults.skipped = suiteResults.skipped + 1
        else
            suiteResults.failed = suiteResults.failed + 1
        end

        table.insert(suiteResults.tests, result)
    end

    if suite.afterAll then
        local ok, err = pcall(suite.afterAll)
        if not ok then
            warn("afterAll failed in suite '" .. suite.name .. "': " .. err)
        end
    end

    suiteResults.time = tick() - startTime

    debugPrint(
        "Suite '" .. suite.name .. "' completed: " ..
        suiteResults.passed .. " passed, " ..
        suiteResults.failed .. " failed, " ..
        suiteResults.skipped .. " skipped (" ..
        suiteResults.time .. "s)"
    )

    return suiteResults
end

function TestingFramework:runAllTests()
    print("Running all tests...")

    local startTime = tick()
    local results = {
        suites  = {},
        summary = {
            passed  = 0,
            failed  = 0,
            skipped = 0,
            total   = 0,
            time    = 0
        }
    }

    for _, suite in ipairs(self._suites) do
        self:resetMocks()
        local suiteResult = self:runSuite(suite)

        results.summary.passed  = results.summary.passed  + suiteResult.passed
        results.summary.failed  = results.summary.failed  + suiteResult.failed
        results.summary.skipped = results.summary.skipped + suiteResult.skipped
        results.summary.total   = results.summary.total   + suiteResult.total

        table.insert(results.suites, suiteResult)
    end

    results.summary.time = tick() - startTime
    self._results       = results

    print(
        "Test run completed in " .. results.summary.time .. "s\n" ..
        "Total: " .. results.summary.total ..
        " | Passed: " .. results.summary.passed ..
        " | Failed: " .. results.summary.failed ..
        " | Skipped: " .. results.summary.skipped
    )

    if results.summary.failed > 0 then
        print("\nFailures:")
        for _, suite in ipairs(results.suites) do
            for _, test in ipairs(suite.tests) do
                if test.status ~= self.TEST_STATUSES.PASS and test.status ~= self.TEST_STATUSES.SKIPPED then
                    print(
                        "  - " .. suite.name .. " > " .. test.name ..
                        " (" .. test.status .. ")\n      " .. (test.message or "No error message")
                    )
                end
            end
        end
    end

    return results
end

function TestingFramework:getResults(format)
    format = format or "summary"

    if format == "summary" then
        return self._results.summary
    elseif format == "full" then
        return self._results
    elseif format == "failures" then
        local failures = {}
        for _, suite in ipairs(self._results.suites) do
            for _, test in ipairs(suite.tests) do
                if test.status ~= self.TEST_STATUSES.PASS and test.status ~= self.TEST_STATUSES.SKIPPED then
                    table.insert(failures, {
                        suite   = suite.name,
                        test    = test.name,
                        status  = test.status,
                        message = test.message
                    })
                end
            end
        end
        return failures
    end
end

--[[ Public API ]]--

function TestingFramework:init()
    debugPrint("Initializing TestingFramework v" .. self._version)
    CoreRegistry = self.CoreRegistry
    return true
end

function TestingFramework:start()
    debugPrint("TestingFramework started")
    return true
end

function TestingFramework:stop()
    debugPrint("TestingFramework stopped")
    table.clear(self._tests)
    table.clear(self._results)
    table.clear(self._mocks)
    return true
end

-- Module exports
return TestingFramework
