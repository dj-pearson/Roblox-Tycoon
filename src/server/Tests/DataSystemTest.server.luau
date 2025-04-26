--!strict
--[[
    DataSystemTest.server.luau
    
    A test script for verifying the Data System is functioning correctly.
    
    Created: April 26, 2025
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Find CoreRegistry
local CoreRegistry = require(ServerScriptService.Core.CoreRegistry)

-- Load modules
local DataManager = require(ServerScriptService.Core.DataManager)
local DataBackup = require(ServerScriptService.Core.DataBackup)
local VersionedDataStore = require(ServerScriptService.Core.VersionedDataStore)
local DataValidator = require(ReplicatedStorage.shared.DataValidator)

-- Test status tracking
local TEST_RESULTS = {
    totalTests = 0,
    passedTests = 0,
    failedTests = 0,
    skippedTests = 0
}

-- Test runner
local function runTest(name, testFunction)
    TEST_RESULTS.totalTests = TEST_RESULTS.totalTests + 1
    
    print("\n=== Running test: " .. name .. " ===")
    
    local success, result = pcall(testFunction)
    
    if success and result == true then
        print("✓ PASS: " .. name)
        TEST_RESULTS.passedTests = TEST_RESULTS.passedTests + 1
    elseif success and result == "skip" then
        print("• SKIP: " .. name)
        TEST_RESULTS.skippedTests = TEST_RESULTS.skippedTests + 1
    else
        print("✗ FAIL: " .. name)
        if not success then
            print("  Error: " .. tostring(result))
        end
        TEST_RESULTS.failedTests = TEST_RESULTS.failedTests + 1
    end
end

-- Helper function to wait for a player
local function waitForPlayer(timeout)
    timeout = timeout or 10
    local startTime = os.clock()
    
    while #Players:GetPlayers() == 0 and (os.clock() - startTime) < timeout do
        task.wait(0.5)
    end
    
    if #Players:GetPlayers() == 0 then
        return nil
    end
    
    return Players:GetPlayers()[1]
end

-- Run all tests
local function runAllTests()
    print("\n=== Starting Data System Tests ===\n")
    
    -- Test 1: Module Loading
    runTest("Module Loading", function()
        if not DataManager then
            return false
        end
        
        if not DataBackup then
            return false
        end
        
        if not VersionedDataStore then
            return false
        end
        
        if not DataValidator then
            return false
        end
        
        if not CoreRegistry then
            return false
        end
        
        return true
    end)
    
    -- Test 2: System Registration
    runTest("System Registration with CoreRegistry", function()
        local hasDataManager = CoreRegistry.getSystem("DataManager") ~= nil
        local hasDataBackup = CoreRegistry.getSystem("DataBackup") ~= nil
        local hasVersionedStore = CoreRegistry.getSystem("VersionedDataStore") ~= nil
        
        return hasDataManager and hasDataBackup and hasVersionedStore
    end)
    
    -- Test 3: Data Validation
    runTest("Data Validation", function()
        -- Create valid data
        local validData = {
            cash = 1000,
            totalEarned = 500,
            equipmentPurchased = {["1"] = true, ["2"] = true},
            equipmentCount = 2,
            gymLevel = 1,
            memberCount = 5,
            vipCount = 1,
            playTime = 3600,
            lastPlayed = os.time(),
            dataVersion = 1
        }
        
        -- Test valid data
        local isValidData, _ = DataValidator.validatePlayerData(validData)
        if not isValidData then
            print("  Valid data failed validation")
            return false
        end
        
        -- Create corrupted data
        local corruptData = {
            cash = -500, -- Invalid negative value
            totalEarned = "invalid", -- Invalid type
            equipmentPurchased = {["1"] = "yes"}, -- Invalid equipment entry
            equipmentCount = 2, -- Mismatch with equipment purchased
            gymLevel = 0, -- Invalid level
            memberCount = 5,
            vipCount = 1,
            playTime = 3600,
            lastPlayed = os.time()
            -- Missing dataVersion field
        }
        
        -- Test corrupt data
        local isCorruptData, repairedData = DataValidator.validatePlayerData(corruptData)
        if isCorruptData then
            print("  Corrupt data passed validation")
            return false
        end
        
        -- Test repair functionality
        if not repairedData then
            print("  Failed to repair corrupt data")
            return false
        end
        
        -- Validate repaired data
        local isValidRepaired, _ = DataValidator.validatePlayerData(repairedData)
        if not isValidRepaired then
            print("  Repaired data is still invalid")
            return false
        end
        
        return true
    end)
    
    -- Test 4: Player Data Operations
    runTest("Player Data Operations", function()
        -- This test requires a player
        local player = waitForPlayer()
        if not player then
            print("  No player found to test with")
            return "skip"
        end
        
        -- Test data loading
        local data = DataManager.loadedData[player.UserId]
        if not data then
            print("  No data loaded for player")
            return false
        end
        
        -- Test data saving
        local saveSuccess = DataManager:SavePlayerData(player, true)
        if not saveSuccess then
            print("  Failed to save player data")
            return false
        end
        
        -- Test data updating
        data.cash = data.cash + 100
        local updateSuccess = DataManager:UpdateDataFromPlayer(player)
        if not updateSuccess then
            print("  Failed to update player data")
            return false
        end
        
        -- Test applying data to player
        local applySuccess = DataManager:ApplyDataToPlayer(player, data)
        if not applySuccess then
            print("  Failed to apply data to player")
            return false
        end
        
        return true
    end)
    
    -- Test 5: Backup Creation
    runTest("Backup Creation", function()
        -- This test requires a player
        local player = waitForPlayer()
        if not player then
            print("  No player found to test with")
            return "skip"
        end
        
        -- Create a backup
        local success, backupKey = DataBackup:CreateCriticalBackup(player, "TestBackup")
        if not success then
            print("  Failed to create backup")
            return false
        end
        
        -- Schedule regular backups
        local scheduleSuccess = DataBackup:ScheduleBackups(player)
        if not scheduleSuccess then
            print("  Failed to schedule backups")
            return false
        end
        
        return true
    end)
    
    -- Test 6: Version Creation
    runTest("Version Creation", function()
        -- This test requires a player
        local player = waitForPlayer()
        if not player then
            print("  No player found to test with")
            return "skip"
        end
        
        -- Create a version
        local success, versionNumber = VersionedDataStore:CreateVersion(player, "TestVersion")
        if not success then
            print("  Failed to create version")
            return false
        end
        
        -- List versions
        local versions = VersionedDataStore:ListVersions(player)
        if not versions or #versions == 0 then
            print("  No versions found after creation")
            return false
        end
        
        -- Create another version with a delay
        task.wait(1)
        local success2, versionNumber2 = VersionedDataStore:CreateVersion(player, "TestVersion2")
        if not success2 then
            print("  Failed to create second version")
            return false
        end
        
        -- Compare versions
        local comparison = VersionedDataStore:CompareVersions(player, versionNumber, versionNumber2)
        if not comparison then
            print("  Failed to compare versions")
            return false
        end
        
        return true
    end)
    
    -- Test 7: System Integration
    runTest("System Integration", function()
        -- This test requires a player
        local player = waitForPlayer()
        if not player then
            print("  No player found to test with")
            return "skip"
        end
        
        -- First create a backup
        local backupSuccess, backupKey = DataBackup:CreateCriticalBackup(player, "IntegrationTest")
        if not backupSuccess then
            print("  Failed to create backup")
            return false
        end
        
        -- Then create a version
        local versionSuccess, versionNumber = VersionedDataStore:CreateVersion(player, "IntegrationTest")
        if not versionSuccess then
            print("  Failed to create version")
            return false
        end
        
        -- Modify the player data
        local userId = player.UserId
        local originalCash = DataManager.loadedData[userId].cash
        DataManager.loadedData[userId].cash = originalCash + 5000
        
        -- Save the modified data
        local saveSuccess = DataManager:SavePlayerData(player, true)
        if not saveSuccess then
            print("  Failed to save modified data")
            return false
        end
        
        -- Create another version with the changes
        local versionSuccess2, versionNumber2 = VersionedDataStore:CreateVersion(player, "ModifiedData")
        if not versionSuccess2 then
            print("  Failed to create version with modified data")
            return false
        end
        
        -- Compare the versions
        local comparison = VersionedDataStore:CompareVersions(player, versionNumber, versionNumber2)
        if not comparison or not comparison.differences or not comparison.differences.cash then
            print("  Version comparison didn't detect cash change")
            return false
        end
        
        -- Verify the difference is 5000
        if comparison.differences.cash.diff ~= 5000 then
            print("  Expected cash difference of 5000, got " .. tostring(comparison.differences.cash.diff))
            return false
        end
        
        -- Restore to previous version
        local restoreSuccess = VersionedDataStore:ApplyVersion(player, versionNumber)
        if not restoreSuccess then
            print("  Failed to restore previous version")
            return false
        end
        
        -- Verify cash is back to original value
        if DataManager.loadedData[userId].cash ~= originalCash then
            print("  Cash not restored to original value")
            return false
        end
        
        return true
    end)
    
    -- Print test summary
    print("\n=== Data System Test Results ===")
    print("Total Tests: " .. TEST_RESULTS.totalTests)
    print("Passed: " .. TEST_RESULTS.passedTests)
    print("Failed: " .. TEST_RESULTS.failedTests)
    print("Skipped: " .. TEST_RESULTS.skippedTests)
    print("\nOverall Result: " .. (TEST_RESULTS.failedTests == 0 and "PASSED" or "FAILED"))
end

-- Run all tests and return results
return {
    runTests = runAllTests,
    results = TEST_RESULTS
}
