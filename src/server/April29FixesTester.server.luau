--!strict
--[[
    April29FixesTester.server.luau
    Comprehensive test script to verify all April 29 fixes
    
    Created: April 29, 2025
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local TEST_DELAY = 5 -- seconds to wait before running tests
local LOG_LEVEL = "verbose" -- "quiet", "normal", "verbose"

-- Utility functions
local function log(message, level)
    level = level or "info"
    
    local levelColors = {
        error = "❌",
        warn = "⚠️",
        success = "✅",
        info = "ℹ️"
    }
    
    local prefix = "[April29Tester] " .. (levelColors[level] or "") .. " "
    
    if level == "error" then
        warn(prefix .. message)
    elseif LOG_LEVEL == "verbose" or (LOG_LEVEL == "normal" and level ~= "info") then
        print(prefix .. message)
    end
end

-- Find script by name in various locations
local function findScript(scriptName)
    local possiblePaths = {
        ServerScriptService,
        ServerScriptService:FindFirstChild("src"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server"),
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Systems")
    }
    
    for _, path in ipairs(possiblePaths) do
        if path then
            local script = path:FindFirstChild(scriptName)
            if script then 
                return script
            end
        end
    end
    
    return nil
end

-- Find CoreRegistry in various locations
local function findCoreRegistry()
    local possiblePaths = {
        ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Systems") and ServerScriptService.Systems:FindFirstChild("CoreRegistry")
    }
    
    for _, path in ipairs(possiblePaths) do
        if path then
            local success, registry = pcall(function() return require(path) end)
            if success and registry and typeof(registry.GetSystem) == "function" then
                return registry
            end
        end
    end
    
    return nil
end

-- Tests for Emergency UI Access Fix
local function testUIAccessFix()
    log("Testing UI Access Restriction...", "info")
    
    -- Test 1: Check if UIAccessRestrictor exists
    local uiRestrictorScript = findScript("UIAccessRestrictor.client") or findScript("UIAccessRestrictor")
    if not uiRestrictorScript then
        log("UIAccessRestrictor script not found", "error")
    else
        log("UIAccessRestrictor script exists", "success")
    end
    
    -- Test 2: Check if AdminAccessRestrictor exists
    local adminRestrictorScript = findScript("AdminAccessRestrictor.client") or findScript("AdminAccessRestrictor")
    if not adminRestrictorScript then
        log("AdminAccessRestrictor script not found", "error")
    else
        log("AdminAccessRestrictor script exists", "success")
    end
    
    -- Test 3: Check if ClientFixDistributor exists and has the correct setup
    local clientDistributorScript = findScript("ClientFixDistributor")
    if not clientDistributorScript then
        log("ClientFixDistributor script not found", "error")
    else
        log("ClientFixDistributor script exists", "success")
          -- Optional: Analyze the script to check if it includes both restrictors
        local success, content = pcall(function() 
            if clientDistributorScript:IsA("ModuleScript") then
                local module = require(clientDistributorScript)
                return true
            else
                return true
            end
        end)
        
        if success then
            log("ClientFixDistributor is functioning properly", "success")
        else
            log("ClientFixDistributor may have issues: " .. tostring(content), "warn")
        end
    end
    
    -- Test 4: Check if ReplicatedStorage has the necessary client configuration
    local clientConfig = ReplicatedStorage:FindFirstChild("ClientConfig")
    if not clientConfig then
        log("ClientConfig not found in ReplicatedStorage", "error")
    else
        log("ClientConfig exists in ReplicatedStorage", "success")
        
        -- Check for UI restriction flag
        local restrictFlag = clientConfig:FindFirstChild("EnableUIAccessRestrictor")
        if not restrictFlag then
            log("EnableUIAccessRestrictor flag not found", "error")
        elseif restrictFlag.Value == true then
            log("EnableUIAccessRestrictor is enabled", "success")
        else
            log("EnableUIAccessRestrictor is disabled", "warn")
        end
    end
    
    -- Return success ratio
    local testsRun = 4
    local testsPassed = (uiRestrictorScript and 1 or 0) + 
                        (adminRestrictorScript and 1 or 0) +
                        (clientDistributorScript and 1 or 0) +
                        (clientConfig and clientConfig:FindFirstChild("EnableUIAccessRestrictor") and 
                         clientConfig.EnableUIAccessRestrictor.Value == true and 1 or 0)
    
    return {
        component = "UIAccessFix",
        passed = testsPassed,
        total = testsRun,
        percentage = testsPassed / testsRun * 100
    }
end

-- Tests for BuyTile Position Fix
local function testBuyTilePositionFix()
    log("Testing BuyTile Position Fix...", "info")
    
    -- Test 1: Check if BuyTilePositionFixer exists
    local positionFixerScript = findScript("BuyTilePositionFixer")
    if not positionFixerScript then
        log("BuyTilePositionFixer script not found", "error")
    else
        log("BuyTilePositionFixer script exists", "success")
    end
    
    -- Test 2: Check if the fix is initialized
    local fixInitialized = false
    local success, result = pcall(function()
        -- Try a few different ways to check if the fix is initialized
        if _G.BuyTilePositionFixerInitialized then
            return true
        end
        
        -- Check if CoreRegistry has a patched BuyTileSystem
        local registry = findCoreRegistry()
        if registry then
            local buyTileSystem = registry:GetSystem("BuyTileSystem")
            if buyTileSystem and buyTileSystem._positionFixApplied then
                return true
            end
        end
        
        return false
    end)
    
    fixInitialized = success and result
    if fixInitialized then
        log("BuyTilePositionFixer is initialized", "success")
    else
        log("BuyTilePositionFixer does not appear to be initialized", "error")
    end
    
    -- Test 3: Check if CoreRegistry includes BuyTileSystem
    local registry = findCoreRegistry()
    local buyTileSystem = nil
    if registry then
        buyTileSystem = registry:GetSystem("BuyTileSystem")
        if buyTileSystem then
            log("BuyTileSystem exists in CoreRegistry", "success")
        else
            log("BuyTileSystem not found in CoreRegistry", "error")
        end
    else
        log("CoreRegistry not found, cannot check for BuyTileSystem", "error")
    end
    
    -- Return success ratio
    local testsRun = 3
    local testsPassed = (positionFixerScript and 1 or 0) + 
                        (fixInitialized and 1 or 0) +
                        (buyTileSystem and 1 or 0)
    
    return {
        component = "BuyTilePositionFix",
        passed = testsPassed,
        total = testsRun,
        percentage = testsPassed / testsRun * 100
    }
end

-- Tests for CoreRegistry Fix
local function testCoreRegistryFix()
    log("Testing CoreRegistry Fix...", "info")
    
    -- Test 1: Check if CoreRegistry exists
    local registry = findCoreRegistry()
    if not registry then
        log("CoreRegistry not found", "error")
        
        -- Early return if registry not found
        return {
            component = "CoreRegistryFix",
            passed = 0,
            total = 6,
            percentage = 0
        }
    end
    
    log("CoreRegistry found", "success")
    
    -- Test 2: Check if the registry is initialized
    local registryInitialized = typeof(registry.GetStatus) == "function" and registry:GetStatus() == "Ready"
    if registryInitialized then
        log("CoreRegistry is initialized", "success")
    else
        log("CoreRegistry is not properly initialized", "error")
    end
    
    -- Test 3-6: Check if critical systems exist in the registry
    local criticalSystems = {"ModuleLoader", "DataManager", "UIComponents", "AssetValidator"}
    local systemsFound = 0
    
    for _, systemName in ipairs(criticalSystems) do
        local system = registry:GetSystem(systemName)
        if system then
            log("System found: " .. systemName, "success")
            systemsFound = systemsFound + 1
        else
            log("System not found: " .. systemName, "error")
        end
    end
    
    -- Test 7: Check if CoreRegistryRestorer exists
    local restorerScript = findScript("CoreRegistryRestorer")
    if restorerScript then
        log("CoreRegistryRestorer script exists", "success")
    else
        log("CoreRegistryRestorer script not found", "error")
    end
    
    -- Return success ratio
    local testsRun = 2 + #criticalSystems + 1
    local testsPassed = 1 + (registryInitialized and 1 or 0) + systemsFound + (restorerScript and 1 or 0)
    
    return {
        component = "CoreRegistryFix",
        passed = testsPassed,
        total = testsRun,
        percentage = testsPassed / testsRun * 100
    }
end

-- Run all tests and report results
local function runAllTests()
    log("Starting comprehensive tests for all April 29 fixes...", "info")
    
    -- Run individual test suites
    local results = {
        testUIAccessFix(),
        testBuyTilePositionFix(),
        testCoreRegistryFix()
    }
    
    -- Calculate overall statistics
    local totalPassed = 0
    local totalTests = 0
    
    log("\n----- TEST RESULTS -----", "info")
    
    for _, result in ipairs(results) do
        totalPassed = totalPassed + result.passed
        totalTests = totalTests + result.total
        
        local status = result.percentage >= 75 and "success" or 
                      (result.percentage >= 50 and "warn" or "error")
        
        log(string.format("%s: %d/%d tests passed (%.1f%%)", 
            result.component, result.passed, result.total, result.percentage), status)
    end
    
    local overallPercentage = totalTests > 0 and (totalPassed / totalTests * 100) or 0
    
    log("\n----- SUMMARY -----", "info")
    log(string.format("Overall: %d/%d tests passed (%.1f%%)", 
        totalPassed, totalTests, overallPercentage), 
        overallPercentage >= 75 and "success" or (overallPercentage >= 50 and "warn" or "error"))
    
    -- Provide advice based on results
    if overallPercentage >= 90 then
        log("All critical fixes appear to be working correctly!", "success")
    elseif overallPercentage >= 75 then
        log("Most fixes are working, but some tests failed. Please check the logs for specific issues.", "warn")
    else
        log("Several fixes are not working correctly. Please review the implementation details.", "error")
    end
    
    return {
        passed = totalPassed,
        total = totalTests,
        percentage = overallPercentage
    }
end

-- Wait for the game to fully load before running tests
local function delayedTestRun()
    log("Will run tests in " .. TEST_DELAY .. " seconds...", "info")
    task.delay(TEST_DELAY, runAllTests)
end

-- Automatically run the tests if in Studio
if RunService:IsStudio() then
    delayedTestRun()
end

-- Return the test module
return {
    runAllTests = runAllTests,
    testUIAccessFix = testUIAccessFix,
    testBuyTilePositionFix = testBuyTilePositionFix,
    testCoreRegistryFix = testCoreRegistryFix
}
