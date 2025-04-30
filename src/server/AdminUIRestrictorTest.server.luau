--!strict
--[[
    AdminUIRestrictorTest.server.luau
    Test script for verifying the admin UI restriction fixes
    
    Created: April 29, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local isStudio = RunService:IsStudio()

-- Configuration
local TEST_WAIT_TIME = 5
local VERBOSE_LOGGING = true

-- Utility functions
local function log(message, level)
    level = level or "info"
    local prefix = "[AdminUIRestrictorTest]"
    
    if level == "error" then
        warn(prefix .. " ❌ " .. message)
    elseif level == "success" then
        print(prefix .. " ✅ " .. message)
    elseif level == "warn" then
        warn(prefix .. " ⚠️ " .. message)
    else
        if VERBOSE_LOGGING then
            print(prefix .. " ℹ️ " .. message)
        end
    end
end

-- Set up test admin user
local function setupTestAdminUser()
    -- Only run this test in Studio for safety
    if not isStudio then
        log("Test can only be run in Studio", "error")
        return false
    end
    
    -- Set up admin users for testing
    local adminUsers = ReplicatedStorage:FindFirstChild("AdminUsers")
    if not adminUsers then
        adminUsers = Instance.new("ModuleScript")
        adminUsers.Name = "AdminUsers"
        adminUsers.Source = "return {1, 2, 3}" -- Sample admin user IDs
        adminUsers.Parent = ReplicatedStorage
        log("Created AdminUsers module for testing", "info")
    end
    
    return true
end

-- Test client-side fix scripts distribution
local function testScriptsDistribution()
    log("Testing client-side fix scripts distribution")
    
    local passed = true
    local playerCount = 0
    
    -- Check each player
    for _, player in ipairs(Players:GetPlayers()) do
        playerCount += 1
        local playerScripts = player:FindFirstChild("PlayerScripts")
        if not playerScripts then
            log("Player " .. player.Name .. " does not have PlayerScripts", "warn")
            continue
        end
        
        -- Check for UIAccessRestrictor
        local uiRestrictor = playerScripts:FindFirstChild("UIAccessRestrictor.client")
        if not uiRestrictor then
            log("UIAccessRestrictor not found for player: " .. player.Name, "error")
            passed = false
        else
            log("UIAccessRestrictor found for player: " .. player.Name, "success")
        end
        
        -- Check for AdminAccessRestrictor
        local adminRestrictor = playerScripts:FindFirstChild("AdminAccessRestrictor.client")
        if not adminRestrictor then
            log("AdminAccessRestrictor not found for player: " .. player.Name, "error")
            passed = false
        else
            log("AdminAccessRestrictor found for player: " .. player.Name, "success")
        end
    end
    
    if playerCount == 0 then
        log("No players found to test script distribution", "warn")
        return false
    end
    
    return passed
end

-- Test ReplicatedStorage configuration
local function testReplicatedStorageConfig()
    log("Testing ReplicatedStorage configuration")
    
    local clientConfig = ReplicatedStorage:FindFirstChild("ClientConfig")
    if not clientConfig then
        log("ClientConfig folder not found in ReplicatedStorage", "error")
        return false
    end
    
    local uiAccessFlag = clientConfig:FindFirstChild("EnableUIAccessRestrictor")
    if not uiAccessFlag or not uiAccessFlag.Value then
        log("EnableUIAccessRestrictor flag not set or disabled", "error")
        return false
    end
    
    local adminRestrictionFlag = clientConfig:FindFirstChild("RestrictAdminPanel")
    if not adminRestrictionFlag or not adminRestrictionFlag.Value then
        log("RestrictAdminPanel flag not set or disabled", "error")
        return false
    end
    
    log("ReplicatedStorage configuration is correct", "success")
    return true
end

-- Run all tests
local function runTests()
    log("Starting Admin UI restriction tests")
    
    -- Wait for any ongoing setup to complete
    task.wait(TEST_WAIT_TIME)
    
    -- Set up test environment
    if not setupTestAdminUser() then
        log("Failed to set up test environment", "error")
        return false
    end
    
    -- Run test suite
    local results = {
        scriptsDistribution = testScriptsDistribution(),
        replicatedStorageConfig = testReplicatedStorageConfig()
    }
    
    -- Summarize results
    local passCount = 0
    local totalTests = 0
    
    log("Test Results:", "info")
    for testName, passed in pairs(results) do
        totalTests += 1
        if passed then
            passCount += 1
            log("✅ " .. testName .. ": PASSED", "success")
        else
            log("❌ " .. testName .. ": FAILED", "error")
        end
    end
    
    local percentage = totalTests > 0 and (passCount / totalTests * 100) or 0
    log(string.format("Tests completed: %d/%d passed (%.1f%%)", passCount, totalTests, percentage), "info")
    
    if passCount == totalTests then
        log("All admin UI restriction tests passed!", "success")
        return true
    else
        log("Some admin UI restriction tests failed", "error")
        return false
    end
}

-- Run tests with a delay
if isStudio then
    task.delay(TEST_WAIT_TIME, runTests)
end

return {
    runTests = runTests
}
