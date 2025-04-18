-- EventBridgeTests.luau
-- Unit tests for the EventBridge system
-- Place in ServerScriptService/Core/Tests

local TestingFramework = require(game.ServerScriptService.Core.TestingFramework)

-- Create a mock EventBridge for testing
local function createMockEventBridge()
    local eventBridge = {
        events = {},
        listenerId = 0
    }
    
    -- Register an event
    function eventBridge:RegisterEvent(eventName)
        if self.events[eventName] then
            return false -- Event already exists
        end
        
        self.events[eventName] = {
            listeners = {}
        }
        
        return true
    end
    
    -- Listen to an event
    function eventBridge:Listen(eventName, callback)
        if not self.events[eventName] then
            self:RegisterEvent(eventName)
        end
        
        -- Generate unique listener ID
        self.listenerId = self.listenerId + 1
        local id = self.listenerId
        
        -- Add the callback to listeners
        self.events[eventName].listeners[id] = callback
        
        -- Return listener ID for future removal
        return id
    end
    
    -- Remove a listener
    function eventBridge:RemoveListener(eventName, listenerId)
        if not self.events[eventName] or not self.events[eventName].listeners[listenerId] then
            return false
        end
        
        self.events[eventName].listeners[listenerId] = nil
        return true
    end
    
    -- Fire an event
    function eventBridge:FireEvent(eventName, ...)
        if not self.events[eventName] then
            return false
        end
        
        local eventData = {...}
        local callCount = 0
        
        -- Call all listeners
        for _, callback in pairs(self.events[eventName].listeners) do
            task.spawn(function()
                callback(unpack(eventData))
            end)
            callCount = callCount + 1
        end
        
        return callCount
    end
    
    -- Count listeners for an event
    function eventBridge:CountListeners(eventName)
        if not self.events[eventName] then
            return 0
        end
        
        local count = 0
        for _ in pairs(self.events[eventName].listeners) do
            count = count + 1
        end
        
        return count
    end
    
    -- Check if an event exists
    function eventBridge:HasEvent(eventName)
        return self.events[eventName] ~= nil
    end
    
    return eventBridge
end

-- Create the test suite
local EventBridgeTests = TestingFramework.createSuite("EventBridge")

-- Set up before each test
EventBridgeTests:setBeforeEach(function()
    -- Nothing to set up globally
end)

-- Clean up after each test
EventBridgeTests:setAfterEach(function()
    -- Nothing to clean up globally
end)

-- Test event registration
EventBridgeTests:addTest("Should register events correctly", function()
    local eventBridge = createMockEventBridge()
    
    local result1 = eventBridge:RegisterEvent("TestEvent")
    local result2 = eventBridge:RegisterEvent("TestEvent") -- Duplicate
    
    EventBridgeTests:expect(result1).toBeTrue()
    EventBridgeTests:expect(result2).toBeFalse() -- Should not allow duplicates
    EventBridgeTests:expect(eventBridge:HasEvent("TestEvent")).toBeTrue()
    EventBridgeTests:expect(eventBridge:HasEvent("NonExistentEvent")).toBeFalse()
end)

-- Test event listening
EventBridgeTests:addTest("Should add listeners correctly", function()
    local eventBridge = createMockEventBridge()
    
    -- Register event and add listener
    eventBridge:RegisterEvent("TestEvent")
    local listenerId = eventBridge:Listen("TestEvent", function() end)
    
    -- Check listener was added
    EventBridgeTests:expect(listenerId).toBeType("number")
    EventBridgeTests:expect(eventBridge:CountListeners("TestEvent")).toBe(1)
    
    -- Add another listener
    local listenerId2 = eventBridge:Listen("TestEvent", function() end)
    
    -- Check second listener was added
    EventBridgeTests:expect(listenerId2).toBeType("number")
    EventBridgeTests:expect(listenerId2).notToBe(listenerId) -- IDs should be different
    EventBridgeTests:expect(eventBridge:CountListeners("TestEvent")).toBe(2)
end)

-- Test listener removal
EventBridgeTests:addTest("Should remove listeners correctly", function()
    local eventBridge = createMockEventBridge()
    
    -- Register event and add listeners
    eventBridge:RegisterEvent("TestEvent")
    local listenerId1 = eventBridge:Listen("TestEvent", function() end)
    local listenerId2 = eventBridge:Listen("TestEvent", function() end)
    
    -- Remove first listener
    local removed = eventBridge:RemoveListener("TestEvent", listenerId1)
    
    -- Check removal
    EventBridgeTests:expect(removed).toBeTrue()
    EventBridgeTests:expect(eventBridge:CountListeners("TestEvent")).toBe(1)
    
    -- Try to remove again (should fail)
    removed = eventBridge:RemoveListener("TestEvent", listenerId1)
    EventBridgeTests:expect(removed).toBeFalse()
    
    -- Remove second listener
    removed = eventBridge:RemoveListener("TestEvent", listenerId2)
    EventBridgeTests:expect(removed).toBeTrue()
    EventBridgeTests:expect(eventBridge:CountListeners("TestEvent")).toBe(0)
end)

-- Test firing events
EventBridgeTests:addTest("Should fire events and call all listeners", function()
    local eventBridge = createMockEventBridge()
    
    -- Create tracking variables
    local callCount = 0
    local receivedArgs = {}
    
    -- Register event and add listeners
    eventBridge:RegisterEvent("TestEvent")
    eventBridge:Listen("TestEvent", function(arg1, arg2)
        callCount = callCount + 1
        receivedArgs = {arg1, arg2}
    end)
    
    -- Add a second listener
    eventBridge:Listen("TestEvent", function()
        callCount = callCount + 1
    end)
    
    -- Fire the event
    local firedCount = eventBridge:FireEvent("TestEvent", "test", 123)
    
    -- The listeners run in separate threads, so wait a bit
    task.wait(0.1)
    
    -- Check that both listeners were called
    EventBridgeTests:expect(firedCount).toBe(2) -- Should return number of listeners called
    EventBridgeTests:expect(callCount).toBe(2)
    EventBridgeTests:expect(receivedArgs[1]).toBe("test")
    EventBridgeTests:expect(receivedArgs[2]).toBe(123)
end)

-- Test firing non-existent event
EventBridgeTests:addTest("Should handle firing non-existent events", function()
    local eventBridge = createMockEventBridge()
    
    -- Try to fire event that doesn't exist
    local result = eventBridge:FireEvent("NonExistentEvent")
    
    EventBridgeTests:expect(result).toBeFalse()
end)

-- Test auto-registering events when listening
EventBridgeTests:addTest("Should auto-register events when listening", function()
    local eventBridge = createMockEventBridge()
    
    -- Listen to event that hasn't been registered yet
    local listenerId = eventBridge:Listen("AutoRegisterEvent", function() end)
    
    -- Check that event was auto-registered
    EventBridgeTests:expect(listenerId).toBeType("number")
    EventBridgeTests:expect(eventBridge:HasEvent("AutoRegisterEvent")).toBeTrue()
    EventBridgeTests:expect(eventBridge:CountListeners("AutoRegisterEvent")).toBe(1)
end)

-- Test multiple events
EventBridgeTests:addTest("Should handle multiple events independently", function()
    local eventBridge = createMockEventBridge()
    
    -- Register multiple events
    eventBridge:RegisterEvent("EventA")
    eventBridge:RegisterEvent("EventB")
    
    -- Add listeners
    local listenerA = eventBridge:Listen("EventA", function() end)
    local listenerB1 = eventBridge:Listen("EventB", function() end)
    local listenerB2 = eventBridge:Listen("EventB", function() end)
    
    -- Check listeners were added correctly
    EventBridgeTests:expect(eventBridge:CountListeners("EventA")).toBe(1)
    EventBridgeTests:expect(eventBridge:CountListeners("EventB")).toBe(2)
    
    -- Remove a listener from EventB
    eventBridge:RemoveListener("EventB", listenerB1)
    
    -- Check only EventB was affected
    EventBridgeTests:expect(eventBridge:CountListeners("EventA")).toBe(1)
    EventBridgeTests:expect(eventBridge:CountListeners("EventB")).toBe(1)
end)

-- Test async event handling
EventBridgeTests:addTest("Should handle events asynchronously", function(done)
    local eventBridge = createMockEventBridge()
    
    -- Create tracking variables
    local callOrder = {}
    
    -- Register event and add listeners with different delays
    eventBridge:RegisterEvent("AsyncEvent")
    
    -- Listener 1 - Will complete last
    eventBridge:Listen("AsyncEvent", function()
        task.wait(0.2) -- Delay execution
        table.insert(callOrder, "listener1")
    end)
    
    -- Listener 2 - Will complete first
    eventBridge:Listen("AsyncEvent", function()
        task.wait(0.1) -- Shorter delay
        table.insert(callOrder, "listener2")
    end)
    
    -- Fire the event
    eventBridge:FireEvent("AsyncEvent")
    
    -- Wait for all listeners to complete
    task.wait(0.3)
    
    -- Verify both listeners were called (order doesn't matter)
    EventBridgeTests:expect(#callOrder).toBe(2)
    EventBridgeTests:expect(callOrder).toContain("listener1")
    EventBridgeTests:expect(callOrder).toContain("listener2")
    done()
end):async()

return EventBridgeTests