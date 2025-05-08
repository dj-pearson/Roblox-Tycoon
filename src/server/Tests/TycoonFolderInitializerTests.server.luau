--!strict
--[[
    TycoonFolderInitializerTests.server.luau
    
    Test suite for the TycoonFolderInitializer system.
    Verifies folder structure creation, validation, and integration with other systems.
    
    Created: May 2, 2025
    Author: N-DPEARSON
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Test configuration
local CONFIG = {
    debug = true,
    testTimeout = 30, -- Maximum time for tests to complete
    retryCount = 3,   -- Number of times to retry failed tests
    retryDelay = 1    -- Delay between retries
}

-- Logger for test results
local function log(...)
    if CONFIG.debug then
        print("[TycoonFolderInitializerTests]", ...)
    end
end

-- Test results tracker
local TestResults = {
    total = 0,
    passed = 0,
    failed = 0,
    skipped = 0,
    startTime = os.clock()
}

-- Record a test result
local function recordTestResult(testName, passed, reason)
    TestResults.total += 1
    
    if passed then
        TestResults.passed += 1
        log("✅", testName, "PASSED")
    else
        TestResults.failed += 1
        log("❌", testName, "FAILED" .. (reason and " - " .. reason or ""))
    end
end

-- Run a test with timeout protection
local function runTest(testName, testFunc)
    log("Running test:", testName)
    
    local startTime = os.clock()
    local success, result, reason = pcall(testFunc)
    
    if not success then
        recordTestResult(testName, false, "Error: " .. tostring(result))
        return false
    end
    
    local duration = os.clock() - startTime
    if duration > CONFIG.testTimeout then
        recordTestResult(testName, false, "Test timed out after " .. duration .. " seconds")
        return false
    end
    
    recordTestResult(testName, result, reason)
    return result
end

-- Test cases

-- Test basic folder structure creation
local function testBasicFolderStructure()
    -- Create a test player
    local testPlayer = Instance.new("Player")
    testPlayer.Name = "TestPlayer"
    testPlayer.UserId = 12345
    
    -- Get the TycoonFolderInitializer
    local initializer = require(ServerScriptService.Core.TycoonFolderInitializer)
    
    -- Initialize the folder structure
    local tycoonModel = initializer.initializeTycoonFolder(testPlayer)
    
    -- Verify the structure
    if not tycoonModel then
        return false, "Failed to create tycoon model"
    end
    
    -- Check required folders
    local requiredFolders = {
        "TycoonData",
        "Stats",
        "Purchases",
        "Equipment",
        "Staff",
        "Customers",
        "Progress",
        "Settings",
        "GymStructure"
    }
    
    for _, folderName in ipairs(requiredFolders) do
        local folder = tycoonModel:FindFirstChild(folderName)
        if not folder or not folder:IsA("Folder") then
            return false, "Missing required folder: " .. folderName
        end
    end
    
    -- Check required values
    local requiredValues = {
        {"TycoonData", "Level", "IntValue"},
        {"TycoonData", "Experience", "IntValue"},
        {"TycoonData", "Money", "NumberValue"},
        {"TycoonData", "GymName", "StringValue"},
        {"Stats", "MemberCount", "IntValue"},
        {"Stats", "EquipmentCount", "IntValue"},
        {"Progress", "GymTier", "IntValue"}
    }
    
    for _, valueInfo in ipairs(requiredValues) do
        local parent = tycoonModel
        for _, part in ipairs(string.split(valueInfo[1], "/")) do
            parent = parent:FindFirstChild(part)
            if not parent then
                return false, "Missing parent folder for value: " .. valueInfo[2]
            end
        end
        
        local value = parent:FindFirstChild(valueInfo[2])
        if not value or not value:IsA(valueInfo[3]) then
            return false, "Missing or invalid value: " .. valueInfo[2]
        end
    end
    
    -- Cleanup
    testPlayer:Destroy()
    return true
end

-- Test folder structure validation
local function testFolderValidation()
    -- Create a test player
    local testPlayer = Instance.new("Player")
    testPlayer.Name = "TestPlayer"
    testPlayer.UserId = 12345
    
    -- Get the TycoonFolderInitializer
    local initializer = require(ServerScriptService.Core.TycoonFolderInitializer)
    
    -- Initialize the folder structure
    local tycoonModel = initializer.initializeTycoonFolder(testPlayer)
    
    -- Verify initial validation
    local isValid = initializer.validateTycoonStructure(testPlayer)
    if not isValid then
        return false, "Initial validation failed"
    end
    
    -- Corrupt the structure
    local tycoonData = tycoonModel:FindFirstChild("TycoonData")
    if tycoonData then
        local level = tycoonData:FindFirstChild("Level")
        if level then
            level:Destroy()
        end
    end
    
    -- Verify validation catches the corruption
    isValid = initializer.validateTycoonStructure(testPlayer)
    if isValid then
        return false, "Validation failed to detect corruption"
    end
    
    -- Verify structure is fixed
    isValid = initializer.validateTycoonStructure(testPlayer)
    if not isValid then
        return false, "Structure not fixed after validation"
    end
    
    -- Cleanup
    testPlayer:Destroy()
    return true
end

-- Test integration with BuyTileSystem
local function testBuyTileIntegration()
    -- Create a test player
    local testPlayer = Instance.new("Player")
    testPlayer.Name = "TestPlayer"
    testPlayer.UserId = 12345
    
    -- Get the TycoonFolderInitializer
    local initializer = require(ServerScriptService.Core.TycoonFolderInitializer)
    
    -- Initialize the folder structure
    local tycoonModel = initializer.initializeTycoonFolder(testPlayer)
    
    -- Verify GymStructure folder
    local gymStructure = tycoonModel:FindFirstChild("GymStructure")
    if not gymStructure then
        return false, "Missing GymStructure folder"
    end
    
    -- Verify required subfolders
    local requiredSubfolders = {
        "Models",
        "Tiles",
        "Layout"
    }
    
    for _, folderName in ipairs(requiredSubfolders) do
        local folder = gymStructure:FindFirstChild(folderName)
        if not folder or not folder:IsA("Folder") then
            return false, "Missing GymStructure subfolder: " .. folderName
        end
    end
    
    -- Verify tile position attributes
    local modelsFolder = gymStructure:FindFirstChild("Models")
    if not modelsFolder:GetAttribute("TilePositions") then
        return false, "Missing TilePositions attribute"
    end
    
    local tilesFolder = gymStructure:FindFirstChild("Tiles")
    if not tilesFolder:GetAttribute("TileMetadata") then
        return false, "Missing TileMetadata attribute"
    end
    
    -- Cleanup
    testPlayer:Destroy()
    return true
end

-- Test retry mechanism
local function testRetryMechanism()
    -- Create a test player
    local testPlayer = Instance.new("Player")
    testPlayer.Name = "TestPlayer"
    testPlayer.UserId = 12345
    
    -- Get the TycoonFolderInitializer
    local initializer = require(ServerScriptService.Core.TycoonFolderInitializer)
    
    -- Initialize the folder structure
    local tycoonModel = initializer.initializeTycoonFolder(testPlayer)
    
    -- Corrupt the structure
    local tycoonData = tycoonModel:FindFirstChild("TycoonData")
    if tycoonData then
        local level = tycoonData:FindFirstChild("Level")
        if level then
            level:Destroy()
        end
    end
    
    -- Try to fix with retries
    local success = false
    for i = 1, CONFIG.retryCount do
        if initializer.validateTycoonStructure(testPlayer) then
            success = true
            break
        end
        
        if i < CONFIG.retryCount then
            task.wait(CONFIG.retryDelay)
        end
    end
    
    if not success then
        return false, "Retry mechanism failed to fix structure"
    end
    
    -- Cleanup
    testPlayer:Destroy()
    return true
end

-- Run all tests
local function runAllTests()
    log("Starting TycoonFolderInitializer tests...")
    
    -- Run test cases
    runTest("Basic Folder Structure", testBasicFolderStructure)
    runTest("Folder Validation", testFolderValidation)
    runTest("BuyTile Integration", testBuyTileIntegration)
    runTest("Retry Mechanism", testRetryMechanism)
    
    -- Print results
    local duration = os.clock() - TestResults.startTime
    log(string.format(
        "Test Results: %d Total, %d Passed, %d Failed, %d Skipped (%.2f seconds)",
        TestResults.total,
        TestResults.passed,
        TestResults.failed,
        TestResults.skipped,
        duration
    ))
    
    if TestResults.failed > 0 then
        warn("Some tests failed. Please review the logs for details.")
    else
        log("All tests passed successfully!")
    end
end

-- Run tests when script is executed
runAllTests()

return {
    runTests = runAllTests,
    testResults = TestResults
} 