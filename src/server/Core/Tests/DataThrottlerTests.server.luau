--!strict
--[[
    DataThrottlerTests.server.luau
    
    Tests for the DataThrottler module to ensure it's working correctly.
    
    Author: Pearson
    Date: April 25, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")

-- Load the DataThrottler module
local DataThrottler
local success, result = pcall(function()
    return require(script.Parent.Parent.Core.DataThrottler)
end)

if success then
    DataThrottler = result
    print("DataThrottler module loaded successfully for testing")
else
    warn("Failed to load DataThrottler module:", result)
    return
end

-- Test Functions
local Tests = {}

-- Test registration
function Tests.testRegistration()
    local system = DataThrottler.registerSystem("TestSystem")
    
    if not system then
        warn("Failed: System registration returned nil")
        return false
    end
    
    if system.name ~= "TestSystem" then
        warn("Failed: System name mismatch")
        return false
    end
    
    print("Passed: System registration")
    return true
end

-- Test basic request queuing
function Tests.testBasicRequest()
    local success, result = DataThrottler.queueRequest("TestSystem", function()
        return "Test result"
    end, false) -- false = read operation
    
    if not success then
        warn("Failed: Basic request failed:", result)
        return false
    end
    
    if result ~= "Test result" then
        warn("Failed: Basic request returned unexpected result:", result)
        return false
    end
    
    print("Passed: Basic request")
    return true
end

-- Test priority system
function Tests.testPriority()
    -- Queue a low priority request
    local lowPriorityStarted = false
    local lowPriorityCompleted = false
    
    task.spawn(function()
        DataThrottler.queueRequestWithPriority("TestSystem", 5, function()
            lowPriorityStarted = true
            task.wait(0.5) -- Simulate work
            lowPriorityCompleted = true
            return "Low priority completed"
        end)
    end)
    
    task.wait(0.1) -- Give time for the request to be queued
    
    -- Queue a high priority request
    local highPriorityCompleted = false
    local success, result = DataThrottler.queueRequestWithPriority("TestSystem", 1, function()
        if lowPriorityStarted and not lowPriorityCompleted then
            -- This is wrong, low priority should not start before high priority completes
            return false, "Low priority was processed before high priority"
        end
        
        highPriorityCompleted = true
        return true, "High priority completed"
    end)
    
    if not success then
        warn("Failed: Priority test failed:", result)
        return false
    end
    
    task.wait(1) -- Wait for both to complete
    
    if not highPriorityCompleted or not lowPriorityCompleted then
        warn("Failed: Not all priority requests completed")
        return false
    end
    
    print("Passed: Priority system test")
    return true
end

-- Test rate limiting
function Tests.testRateLimiting()
    -- Queue many requests to test rate limiting
    local completedRequests = 0
    local startTime = os.time()
    
    -- Queue 30 requests quickly
    for i = 1, 30 do
        task.spawn(function()
            local success = DataThrottler.queueRequest("TestSystem", function()
                task.wait(0.1) -- Small delay
                completedRequests = completedRequests + 1
                return true
            end)
            
            if not success then
                warn("Request " .. i .. " failed")
            end
        end)
    end
    
    -- Wait for processing
    task.wait(3)
    
    -- Check completions vs time
    local elapsedTime = os.time() - startTime
    print("Completed " .. completedRequests .. " requests in " .. elapsedTime .. " seconds")
    
    -- We should see rate limiting in effect
    if completedRequests >= 30 and elapsedTime < 2 then
        warn("Failed: Rate limiting doesn't appear to be working")
        return false
    end
    
    print("Passed: Rate limiting test")
    return true
end

-- Run the tests
print("Starting DataThrottler tests...")

local allTestsPassed = true
for name, testFunc in pairs(Tests) do
    print("\nRunning test:", name)
    local success, result = pcall(testFunc)
    
    if not success then
        warn("Test crashed:", result)
        allTestsPassed = false
    elseif not result then
        allTestsPassed = false
    end
end

if allTestsPassed then
    print("\n✅ All DataThrottler tests passed!")
else
    warn("\n❌ Some DataThrottler tests failed!")
end

-- Get stats at the end
local stats = DataThrottler.getStats()
print("\nDataThrottler Stats:")
print("Active requests:", stats.activeRequests)
print("Queue length:", stats.queueLength)

for name, system in pairs(stats.systems) do
    print("\nSystem:", name)
    print("  Requests made:", system.requestsMade)
    print("  Succeeded:", system.requestsSucceeded)
    print("  Failed:", system.requestsFailed)
end
