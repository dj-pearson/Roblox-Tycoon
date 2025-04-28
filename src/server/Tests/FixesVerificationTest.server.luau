--[[
    FixesVerificationTest.server.luau
    
    This script verifies that the critical fixes have been successfully applied.
    It tests each component and reports the results.
    
    Place in ServerScriptService.Tests
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    waitTime = 5, -- Time to wait before running tests to ensure everything has loaded
    debug = true
}

-- Test results
local results = {
    passCount = 0,
    failCount = 0,
    tests = {}
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[FixesVerificationTest]", ...)
    end
end

-- Record a test result
local function recordTest(name, passed, details)
    local result = {
        name = name,
        passed = passed,
        details = details or ""
    }
    
    table.insert(results.tests, result)
    
    if passed then
        results.passCount = results.passCount + 1
        log("✓ PASS:", name)
    else
        results.failCount = results.failCount + 1
        log("✗ FAIL:", name, "-", details or "")
    end
    
    return passed
end

-- Test if folder exists
local function testFolderExists(parent, name)
    local testName = parent:GetFullName() .. "." .. name .. " Folder Exists"
    local folder = parent:FindFirstChild(name)
    
    if folder and folder:IsA("Folder") then
        return recordTest(testName, true)
    else
        return recordTest(testName, false, "Folder not found or not a Folder")
    end
end

-- Test if module exists and can be required
local function testModuleExists(parent, name)
    local testName = parent:GetFullName() .. "." .. name .. " Module Exists"
    local module = parent:FindFirstChild(name)
    
    if not module then
        return recordTest(testName, false, "Module not found")
    end
    
    if not module:IsA("ModuleScript") then
        return recordTest(testName, false, "Not a ModuleScript")
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        return recordTest(testName, false, "Failed to require: " .. tostring(result))
    end
    
    if type(result) ~= "table" then
        return recordTest(testName, false, "Did not return a table")
    end
    
    return recordTest(testName, true)
end

-- Test CoreRegistry
local function testCoreRegistry()
    -- First test if the module exists
    local coreRegistry
    local testName = "CoreRegistry Module Test"
    
    local coreFolder = ServerScriptService:FindFirstChild("Core")
    if not coreFolder then
        return recordTest(testName, false, "Core folder not found in ServerScriptService")
    end
    
    local coreRegistryModule = coreFolder:FindFirstChild("CoreRegistry")
    if not coreRegistryModule then
        coreRegistryModule = coreFolder:FindFirstChild("CoreRegistry.server")
    end
    
    if not coreRegistryModule then
        return recordTest(testName, false, "CoreRegistry module not found")
    end
    
    if not coreRegistryModule:IsA("ModuleScript") then
        return recordTest(testName, false, "CoreRegistry is not a ModuleScript")
    end
    
    local success, result = pcall(function()
        return require(coreRegistryModule)
    end)
    
    if not success then
        return recordTest(testName, false, "Failed to require CoreRegistry: " .. tostring(result))
    end
    
    if type(result) ~= "table" then
        return recordTest(testName, false, "CoreRegistry did not return a table")
    end
    
    coreRegistry = result
    
    -- Test CoreRegistry functionality
    if not coreRegistry.registerSystem or not coreRegistry.getSystem then
        return recordTest(testName, false, "CoreRegistry missing required methods")
    end
    
    -- Test registration and retrieval
    local testSystem = {
        name = "TestSystem",
        version = "1.0.0"
    }
    
    coreRegistry.registerSystem("TestSystem", testSystem)
    local retrievedSystem = coreRegistry.getSystem("TestSystem")
    
    if retrievedSystem ~= testSystem then
        return recordTest(testName, false, "CoreRegistry failed to retrieve registered system")
    end
    
    return recordTest(testName, true)
end

-- Test Tycoon folder structure for players
local function testTycoonFolderStructure()
    local testName = "Tycoon Folder Structure Test"
    
    -- If no players, the test is inconclusive
    if #Players:GetPlayers() == 0 then
        return recordTest(testName, false, "No players to test with")
    end
    
    local allValid = true
    local failReason = ""
    
    for _, player in ipairs(Players:GetPlayers()) do
        -- Check if player has a Tycoon value
        local tycoon = player:FindFirstChild("Tycoon")
        if not tycoon then
            allValid = false
            failReason = "Player " .. player.Name .. " missing Tycoon value"
            break
        end
        
        -- Check if it's an ObjectValue
        if not tycoon:IsA("ObjectValue") then
            allValid = false
            failReason = "Player " .. player.Name .. " has Tycoon that is not an ObjectValue"
            break
        end
    end
    
    return recordTest(testName, allValid, failReason)
end

-- Test SafeRequire module
local function testSafeRequire()
    local testName = "SafeRequire Module Test"
    
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared then
        return recordTest(testName, false, "shared folder not found in ReplicatedStorage")
    end
    
    local safeRequire = shared:FindFirstChild("SafeRequire")
    if not safeRequire then
        return recordTest(testName, false, "SafeRequire module not found in shared folder")
    end
    
    if not safeRequire:IsA("ModuleScript") then
        return recordTest(testName, false, "SafeRequire is not a ModuleScript")
    end
    
    local success, result = pcall(function()
        return require(safeRequire)
    end)
    
    if not success then
        return recordTest(testName, false, "Failed to require SafeRequire: " .. tostring(result))
    end
    
    if type(result) ~= "table" then
        return recordTest(testName, false, "SafeRequire did not return a table")
    end
    
    if not result.require or not result.findModule then
        return recordTest(testName, false, "SafeRequire missing required methods")
    end
    
    return recordTest(testName, true)
end

-- Test DataPersistenceManager
local function testDataPersistenceManager()
    local testName = "DataPersistenceManager Test"
    
    local coreFolder = ServerScriptService:FindFirstChild("Core")
    if not coreFolder then
        return recordTest(testName, false, "Core folder not found in ServerScriptService")
    end
    
    local dataManager = coreFolder:FindFirstChild("DataPersistenceManager")
    if not dataManager and coreFolder:FindFirstChild("DataPersistenceManager.server") then
        dataManager = coreFolder:FindFirstChild("DataPersistenceManager.server")
    end
    
    if not dataManager then
        return recordTest(testName, false, "DataPersistenceManager module not found")
    end
    
    if not dataManager:IsA("ModuleScript") then
        return recordTest(testName, false, "DataPersistenceManager is not a ModuleScript")
    end
    
    local success, result = pcall(function()
        return require(dataManager)
    end)
    
    if not success then
        return recordTest(testName, false, "Failed to require DataPersistenceManager: " .. tostring(result))
    end
    
    if type(result) ~= "table" then
        return recordTest(testName, false, "DataPersistenceManager did not return a table")
    end
    
    if not result.loadData or not result.saveData then
        return recordTest(testName, false, "DataPersistenceManager missing required methods")
    end
    
    return recordTest(testName, true)
end

-- Run all tests
local function runAllTests()
    log("Starting verification tests...")
    
    -- Test folder structure
    testFolderExists(ReplicatedStorage, "shared")
    testFolderExists(ServerScriptService, "Core")
    testFolderExists(ServerStorage, "GymParts")
    testFolderExists(ServerStorage, "BuyTiles")
    
    -- Test critical modules
    testCoreRegistry()
    testSafeRequire()
    testDataPersistenceManager()
    testTycoonFolderStructure()
    
    -- Report overall results
    log("Tests complete:")
    log("Passed:", results.passCount, "tests")
    log("Failed:", results.failCount, "tests")
    log("Success rate:", string.format("%.2f%%", (results.passCount / (results.passCount + results.failCount)) * 100))
    
    -- Create a status value
    local statusValue = Instance.new("StringValue")
    statusValue.Name = "FixesVerificationStatus"
    statusValue.Value = string.format("Passed: %d, Failed: %d", results.passCount, results.failCount)
    statusValue.Parent = script
    
    return results
end

-- Wait for the game to fully load before testing
task.wait(CONFIG.waitTime)
return runAllTests()
