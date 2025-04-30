--!strict
--[[
    AprilFixesTestSuite.server.luau
    Comprehensive test suite for April 29, 2025 fixes
    
    Created: April 29, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Test configuration
local CONFIG = {
    waitBeforeStart = 10, -- seconds to wait before starting tests
    testTimeout = 30, -- seconds before a test times out
    autoRun = true, -- automatically run tests on script load
    logDetailedResults = true -- log detailed test results
}

-- Test state
local state = {
    testsRun = 0,
    testsPassed = 0,
    testsFailed = 0,
    startTime = 0,
    isRunning = false,
    results = {}
}

-- A simple testing framework
local TestSuite = {}

-- Logging function with formatting
local function log(message, level)
    local levels = {
        info = {prefix = "ℹ️", func = print},
        warn = {prefix = "⚠️", func = warn},
        error = {prefix = "❌", func = error},
        success = {prefix = "✅", func = print},
        result = {prefix = "🔍", func = print}
    }
    
    local levelInfo = levels[level] or levels.info
    local prefix = "[AprilFixesTestSuite] " .. levelInfo.prefix .. " "
    levelInfo.func(prefix .. message)
end

-- Find script by name in various locations
local function findScript(scriptName)
    local searchPaths = {
        ServerScriptService,
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("src"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and 
            ServerScriptService.src.server:FindFirstChild("Core")
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local script = path:FindFirstChild(scriptName)
            if script then
                return script
            end
        end
    end
    
    return nil
end

-- Find CoreRegistry
local function findCoreRegistry()
    local paths = {
        ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("CoreRegistry"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared") and
            ReplicatedStorage.src.shared:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Systems") and ServerScriptService.Systems:FindFirstChild("CoreRegistry")
    }
    
    for _, path in ipairs(paths) do
        if path then
            local success, registry = pcall(function()
                return require(path)
            end)
            
            if success and registry and typeof(registry.GetSystem) == "function" then
                return registry
            end
        end
    end
    
    return nil
end

-- Define individual tests
local tests = {
    -- Test CoreRegistry fixes
    testCoreRegistryExists = function()
        local registry = findCoreRegistry()
        return {
            pass = registry ~= nil,
            message = registry and "CoreRegistry found" or "CoreRegistry not found"
        }
    end,
    
    testCriticalSystemsExist = function()
        local registry = findCoreRegistry()
        if not registry then
            return {
                pass = false,
                message = "CoreRegistry not found, cannot test critical systems"
            }
        end
        
        local criticalSystems = {
            "ModuleLoader",
            "DataManager",
            "UIComponents",
            "AssetValidator",
            "BuyTileSystem"
        }
        
        local missingCount = 0
        local missingList = {}
        
        for _, systemName in ipairs(criticalSystems) do
            local system = registry:GetSystem(systemName)
            if not system then
                missingCount = missingCount + 1
                table.insert(missingList, systemName)
            end
        end
        
        return {
            pass = missingCount == 0,
            message = missingCount == 0 
                and "All critical systems found" 
                or ("Missing " .. missingCount .. " critical systems: " .. table.concat(missingList, ", "))
        }
    end,
    
    testSystemFunctions = function()
        local registry = findCoreRegistry()
        if not registry then
            return {
                pass = false,
                message = "CoreRegistry not found, cannot test system functions"
            }
        end
        
        local functionTests = {
            {system = "ModuleLoader", func = "loadModule"},
            {system = "DataManager", func = "getPlayerData"},
            {system = "UIComponents", func = "createButton"},
            {system = "AssetValidator", func = "validateAsset"}
        }
        
        local missingCount = 0
        local missingFuncs = {}
        
        for _, test in ipairs(functionTests) do
            local system = registry:GetSystem(test.system)
            if not system or typeof(system[test.func]) ~= "function" then
                missingCount = missingCount + 1
                table.insert(missingFuncs, test.system .. "." .. test.func)
            end
        end
        
        return {
            pass = missingCount == 0,
            message = missingCount == 0 
                and "All system functions are available" 
                or ("Missing " .. missingCount .. " functions: " .. table.concat(missingFuncs, ", "))
        }
    end,
    
    -- Test BuyTile position fixing
    testBuyTilePositionFixerExists = function()
        local fixerScript = findScript("BuyTilePositionFixer")
        return {
            pass = fixerScript ~= nil,
            message = fixerScript and "BuyTilePositionFixer script found" or "BuyTilePositionFixer script not found"
        }
    end,
    
    testBuyTileSystemPatched = function()
        -- Check for global flag
        local fixerInitialized = _G.BuyTilePositionFixerInitialized == true
        
        -- Check BuyTileSystem if CoreRegistry is available
        local registry = findCoreRegistry()
        local buyTileSystem = registry and registry:GetSystem("BuyTileSystem")
        local systemPatched = buyTileSystem and buyTileSystem._positionFixApplied == true
        
        return {
            pass = fixerInitialized or systemPatched,
            message = (fixerInitialized or systemPatched)
                and "BuyTile position fixer initialized"
                or "BuyTile position fixer not initialized"
        }
    end,
    
    -- Test UI access restriction
    testUIAccessRestrictorExists = function()
        local restrictorScript = findScript("UIAccessRestrictor")
        return {
            pass = restrictorScript ~= nil,
            message = restrictorScript and "UIAccessRestrictor script found" or "UIAccessRestrictor script not found"
        }
    end,
    
    testClientFixDistributorExists = function()
        local distributorScript = findScript("ClientFixDistributor")
        return {
            pass = distributorScript ~= nil,
            message = distributorScript and "ClientFixDistributor script found" or "ClientFixDistributor script not found"
        }
    end,
    
    testClientConfigEnabled = function()
        local clientConfig = ReplicatedStorage:FindFirstChild("ClientConfig")
        local flag = clientConfig and clientConfig:FindFirstChild("EnableUIAccessRestrictor")
        local enabled = flag and flag.Value == true
        
        return {
            pass = enabled,
            message = enabled 
                and "UI access restriction enabled in client config"
                or "UI access restriction not enabled in client config"
        }
    end,
    
    -- Test overall fix controller
    testFixesControllerExists = function()
        local controllerScript = findScript("AprilFixesController")
        return {
            pass = controllerScript ~= nil,
            message = controllerScript and "AprilFixesController script found" or "AprilFixesController script not found"
        }
    end,
    
    testFixesInitialized = function()
        local initialized = _G.AprilFixesController and _G.AprilFixesController.initialized == true
        return {
            pass = initialized,
            message = initialized 
                and "April fixes controller initialized" 
                or "April fixes controller not initialized"
        }
    end
}

-- Run a single test with timeout protection
function TestSuite:RunTest(testName, testFunction)
    state.testsRun = state.testsRun + 1
    log("Running test: " .. testName, "info")
    
    local completed = false
    local result = nil
    
    -- Create a wrapped function for the test with timeout protection
    local testThread = coroutine.create(function()
        local success, testResult = pcall(function()
            return testFunction()
        end)
        
        if success then
            result = testResult
        else
            result = {
                pass = false,
                message = "Test threw an error: " .. tostring(testResult)
            }
        end
        
        completed = true
    end)
    
    -- Start the test
    coroutine.resume(testThread)
    
    -- Wait for test completion or timeout
    local startTime = os.clock()
    while not completed and (os.clock() - startTime) < CONFIG.testTimeout do
        RunService.Heartbeat:Wait()
    end
    
    -- Handle timeout
    if not completed then
        result = {
            pass = false,
            message = "Test timed out after " .. CONFIG.testTimeout .. " seconds"
        }
    end
    
    -- Record result
    if result.pass then
        state.testsPassed = state.testsPassed + 1
        log(testName .. ": PASSED - " .. result.message, "success")
    else
        state.testsFailed = state.testsFailed + 1
        log(testName .. ": FAILED - " .. result.message, "error")
    end
    
    -- Store the result
    state.results[testName] = result
    
    return result
end

-- Run all tests
function TestSuite:RunAllTests()
    if state.isRunning then
        return false
    end
    
    state.isRunning = true
    state.testsRun = 0
    state.testsPassed = 0
    state.testsFailed = 0
    state.results = {}
    state.startTime = os.clock()
    
    log("Starting April fixes test suite...", "info")
    
    -- Run each test
    for testName, testFunction in pairs(tests) do
        self:RunTest(testName, testFunction)
    end
    
    -- Calculate results
    local passRate = state.testsRun > 0 and (state.testsPassed / state.testsRun * 100) or 0
    local duration = os.clock() - state.startTime
    
    -- Log results
    log(string.format("Tests completed in %.2f seconds", duration), "info")
    log(string.format("Tests run: %d, Tests passed: %d, Tests failed: %d", 
        state.testsRun, state.testsPassed, state.testsFailed), "result")
    log(string.format("Pass rate: %.1f%%", passRate), "result")
    
    -- Log individual test results if configured
    if CONFIG.logDetailedResults then
        log("Detailed test results:", "info")
        for testName, result in pairs(state.results) do
            log("  " .. (result.pass and "✅" or "❌") .. " " .. testName, result.pass and "success" or "error")
        end
    end
    
    state.isRunning = false
    
    -- Return test success status
    return state.testsFailed == 0
end

-- Auto run if configured
if CONFIG.autoRun then
    task.delay(CONFIG.waitBeforeStart, function()
        TestSuite:RunAllTests()
    end)
end

-- Return the test suite object
return TestSuite
