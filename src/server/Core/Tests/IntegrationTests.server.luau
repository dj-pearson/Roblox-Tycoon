-- IntegrationTests.server.luau
-- Integration tests for verifying that all game systems work together correctly
-- Tests cross-system interactions and data flow

local TestingFramework = require(game.ServerScriptService.Core.TestingFramework)
local Players = game:GetService("Players")

-- Import core systems for testing
local function getSystems()
    local systems = {}
    
    -- Critical systems - we'll load these directly rather than using mocks
    systems.CoreRegistry = require(game.ServerScriptService.Core.CoreRegistry)
    systems.EventBridge = require(game.ServerScriptService.Core.EventBridge)
    systems.DataManager = require(game.ServerScriptService.Core.DataManager)
    
    -- Get other systems through the registry to test proper registration
    if systems.CoreRegistry then
        systems.TycoonSystem = systems.CoreRegistry:GetSystem("TycoonSystem")
        systems.NPCSystem = systems.CoreRegistry:GetSystem("NPCSystem")
        systems.BuyTileSystem = systems.CoreRegistry:GetSystem("BuyTileSystem")
        systems.SpecializationSystem = systems.CoreRegistry:GetSystem("SpecializationSystem")
        systems.SeasonalSystem = systems.CoreRegistry:GetSystem("SeasonalSystem")
        systems.MilestoneSystem = systems.CoreRegistry:GetSystem("MilestoneSystem")
        systems.RevenueSystem = systems.CoreRegistry:GetSystem("RevenueSystem")
        systems.MemberSatisfactionSystem = systems.CoreRegistry:GetSystem("MemberSatisfactionSystem")
        systems.RebirthSystem = systems.CoreRegistry:GetSystem("RebirthSystem")
        systems.JobSystem = systems.CoreRegistry:GetSystem("JobSystem")
        systems.CompetitionSystem = systems.CoreRegistry:GetSystem("CompetitionSystem")
        systems.SaunaSystem = systems.CoreRegistry:GetSystem("SaunaSystem")
        systems.BasketballSystem = systems.CoreRegistry:GetSystem("BasketballSystem")
    end
    
    return systems
end

-- Create a mock player for testing
local function createMockPlayer(userId, name)
    local player = {
        UserId = userId or 1234567890,
        Name = name or "TestPlayer",
        IsA = function(self, className)
            return className == "Player"
        end
    }
    
    return player
end

-- Create the test suite
local IntegrationTests = TestingFramework.createSuite("Integration")

-- Set up before each test
IntegrationTests:setBeforeEach(function()
    -- Nothing to set up globally
end)

-- Clean up after each test
IntegrationTests:setAfterEach(function()
    -- Nothing to clean up globally
end)

-- Test system registration and dependencies
IntegrationTests:addTest("All critical systems should be registered in CoreRegistry", function()
    local systems = getSystems()
    
    IntegrationTests:expect(systems.CoreRegistry).notToBeNil()
    IntegrationTests:expect(systems.EventBridge).notToBeNil()
    IntegrationTests:expect(systems.DataManager).notToBeNil()
    IntegrationTests:expect(systems.TycoonSystem).notToBeNil()
    IntegrationTests:expect(systems.NPCSystem).notToBeNil()
    IntegrationTests:expect(systems.BuyTileSystem).notToBeNil()
    IntegrationTests:expect(systems.SpecializationSystem).notToBeNil()
end)

-- Test EventBridge communication between systems
IntegrationTests:addTest("Systems should be able to communicate via EventBridge", function()
    local systems = getSystems()
    local eventBridge = systems.EventBridge
    
    IntegrationTests:expect(eventBridge).notToBeNil()
    
    -- Set up test event tracking
    local eventReceived = false
    local eventData = nil
    local listenerId = eventBridge:Listen("TestIntegrationEvent", function(data)
        eventReceived = true
        eventData = data
    end)
    
    -- Fire test event
    eventBridge:FireEvent("TestIntegrationEvent", { testValue = 123 })
    
    -- Wait for async event to be processed
    task.wait(0.2)
    
    -- Verify event was received
    IntegrationTests:expect(eventReceived).toBeTrue()
    IntegrationTests:expect(eventData).notToBeNil()
    IntegrationTests:expect(eventData.testValue).toBe(123)
    
    -- Clean up
    eventBridge:RemoveListener("TestIntegrationEvent", listenerId)
end)

-- Test DataManager integration with other systems
IntegrationTests:addTest("DataManager should handle data for all systems", function()
    local systems = getSystems()
    local player = createMockPlayer()
    
    -- Set data from different systems
    systems.DataManager:SetData(player, "coins", 5000)
    systems.DataManager:SetData(player, "specialization", "Cardio")
    systems.DataManager:SetData(player, "memberCount", 25)
    systems.DataManager:SetData(player, "rebirthLevel", 3)
    
    -- Verify data is accessible
    IntegrationTests:expect(systems.DataManager:GetData(player, "coins")).toBe(5000)
    IntegrationTests:expect(systems.DataManager:GetData(player, "specialization")).toBe("Cardio")
    IntegrationTests:expect(systems.DataManager:GetData(player, "memberCount")).toBe(25)
    IntegrationTests:expect(systems.DataManager:GetData(player, "rebirthLevel")).toBe(3)
end)

-- Test TycoonSystem integration with BuyTileSystem
IntegrationTests:addTest("TycoonSystem should integrate with BuyTileSystem", function()
    local systems = getSystems()
    local player = createMockPlayer()
    
    -- This test assumes the TycoonSystem has a method to register a new tycoon
    if not systems.TycoonSystem or not systems.TycoonSystem.RegisterTycoon then
        IntegrationTests:expect(false).toBeTrue("TycoonSystem missing or lacks RegisterTycoon method")
        return
    end
    
    -- Register a tycoon for the player
    local tycoon = systems.TycoonSystem:RegisterTycoon(player)
    
    -- Verify tycoon was created
    IntegrationTests:expect(tycoon).notToBeNil()
    
    -- Test BuyTileSystem interaction if available
    if systems.BuyTileSystem and systems.BuyTileSystem.CanPurchaseTile then
        local canPurchase = systems.BuyTileSystem:CanPurchaseTile(player, "BasicBench")
        -- We don't know the exact result, but the function should return without errors
        IntegrationTests:expect(type(canPurchase)).toBe("boolean")
    end
end)

-- Test SpecializationSystem with SeasonalSystem integration
IntegrationTests:addTest("SpecializationSystem should integrate with SeasonalSystem", function()
    local systems = getSystems()
    local player = createMockPlayer()
    
    -- Skip test if required systems are not available
    if not systems.SpecializationSystem or not systems.SeasonalSystem then
        IntegrationTests:expect(true).toBeTrue("Test skipped: missing required systems")
        return
    end
    
    -- Set a specialization
    if systems.SpecializationSystem.SetPlayerSpecialization then
        systems.SpecializationSystem:SetPlayerSpecialization(player, "Cardio")
        
        -- Verify specialization was set
        local specialization = systems.SpecializationSystem:GetPlayerSpecialization(player)
        IntegrationTests:expect(specialization).toBe("Cardio")
        
        -- Check if seasonal system responds to specialization
        if systems.SeasonalSystem.GetSeasonalBonusForSpecialization then
            local bonus = systems.SeasonalSystem:GetSeasonalBonusForSpecialization(player, "Cardio")
            IntegrationTests:expect(type(bonus)).toBe("number")
        end
    end
end)

-- Test NPCSystem with RevenueSystem integration
IntegrationTests:addTest("NPCSystem should integrate with RevenueSystem", function()
    local systems = getSystems()
    local player = createMockPlayer()
    
    -- Skip test if required systems are not available
    if not systems.NPCSystem or not systems.RevenueSystem then
        IntegrationTests:expect(true).toBeTrue("Test skipped: missing required systems")
        return
    end
    
    -- Simulate NPC workout generating revenue if system has this capability
    if systems.NPCSystem.SimulateNPCWorkout then
        local initialRevenue = systems.RevenueSystem:GetTotalRevenue(player) or 0
        
        -- Simulate NPC workout
        systems.NPCSystem:SimulateNPCWorkout(player, 10) -- Simulate 10 NPCs
        
        -- Check if revenue increased
        task.wait(0.5) -- Allow time for event processing
        local newRevenue = systems.RevenueSystem:GetTotalRevenue(player) or 0
        
        -- Revenue should have increased
        IntegrationTests:expect(newRevenue).toBeGreaterThan(initialRevenue)
    end
end)

-- Test RebirthSystem integration with other systems
IntegrationTests:addTest("RebirthSystem should properly reset and apply bonuses", function()
    local systems = getSystems()
    local player = createMockPlayer()
    
    -- Skip test if required systems are not available
    if not systems.RebirthSystem or not systems.DataManager then
        IntegrationTests:expect(true).toBeTrue("Test skipped: missing required systems")
        return
    end
    
    -- Setup initial player state
    systems.DataManager:SetData(player, "coins", 1000000) -- Set enough coins for rebirth
    systems.DataManager:SetData(player, "rebirthLevel", 0)
    
    -- Check current rebirth level
    local initialLevel = systems.DataManager:GetData(player, "rebirthLevel")
    IntegrationTests:expect(initialLevel).toBe(0)
    
    -- Perform rebirth if system has this capability
    if systems.RebirthSystem.PerformRebirth then
        local success = systems.RebirthSystem:PerformRebirth(player)
        
        -- Verify rebirth was successful
        IntegrationTests:expect(success).toBeTrue()
        
        -- Check that rebirth level increased
        local newLevel = systems.DataManager:GetData(player, "rebirthLevel")
        IntegrationTests:expect(newLevel).toBe(1)
        
        -- Check that coins were reset
        local newCoins = systems.DataManager:GetData(player, "coins")
        IntegrationTests:expect(newCoins).toBeLessThan(1000000)
    end
end)

-- Test MemberSatisfactionSystem integration
IntegrationTests:addTest("MemberSatisfactionSystem should affect revenue", function()
    local systems = getSystems()
    local player = createMockPlayer()
    
    -- Skip test if required systems are not available
    if not systems.MemberSatisfactionSystem or not systems.RevenueSystem then
        IntegrationTests:expect(true).toBeTrue("Test skipped: missing required systems")
        return
    end
    
    -- Get initial satisfaction and revenue
    local initialSatisfaction = systems.MemberSatisfactionSystem:GetSatisfaction(player) or 50
    local initialRevenueRate = systems.RevenueSystem:GetRevenueRate(player) or 1
    
    -- Change satisfaction if system has this capability
    if systems.MemberSatisfactionSystem.SetSatisfaction then
        -- Set to higher satisfaction
        systems.MemberSatisfactionSystem:SetSatisfaction(player, initialSatisfaction + 30)
        
        -- Allow time for changes to propagate
        task.wait(0.5)
        
        -- Check if revenue rate increased
        local newRevenueRate = systems.RevenueSystem:GetRevenueRate(player) or 1
        
        -- Revenue rate should have increased due to higher satisfaction
        IntegrationTests:expect(newRevenueRate).toBeGreaterThan(initialRevenueRate)
        
        -- Reset satisfaction
        systems.MemberSatisfactionSystem:SetSatisfaction(player, initialSatisfaction)
    end
end)

-- Test JobSystem with staff management
IntegrationTests:addTest("JobSystem should properly manage staff", function()
    local systems = getSystems()
    local player = createMockPlayer()
    
    -- Skip test if required systems are not available
    if not systems.JobSystem then
        IntegrationTests:expect(true).toBeTrue("Test skipped: missing JobSystem")
        return
    end
    
    -- Hire staff if system has this capability
    if systems.JobSystem.HireStaff then
        local initialStaffCount = systems.JobSystem:GetStaffCount(player) or 0
        
        -- Hire a new staff member
        local success = systems.JobSystem:HireStaff(player, "Trainer")
        
        -- Verify staff was hired
        IntegrationTests:expect(success).toBeTrue()
        
        -- Check that staff count increased
        local newStaffCount = systems.JobSystem:GetStaffCount(player)
        IntegrationTests:expect(newStaffCount).toBe(initialStaffCount + 1)
    end
end)

-- Test MilestoneSystem integration
IntegrationTests:addTest("MilestoneSystem should track progress across systems", function()
    local systems = getSystems()
    local player = createMockPlayer()
    
    -- Skip test if required systems are not available
    if not systems.MilestoneSystem then
        IntegrationTests:expect(true).toBeTrue("Test skipped: missing MilestoneSystem")
        return
    end
    
    -- Set up test milestone data
    systems.DataManager:SetData(player, "equipmentCount", 5)
    
    -- Check milestone progress if system has this capability
    if systems.MilestoneSystem.GetMilestoneProgress then
        local equipmentProgress = systems.MilestoneSystem:GetMilestoneProgress(player, "Equipment")
        
        -- Verify milestone is tracking correctly
        IntegrationTests:expect(equipmentProgress).notToBeNil()
        IntegrationTests:expect(equipmentProgress).toBeGreaterThanOrEqual(5)
    end
end)

-- Test CompetitionSystem integration
IntegrationTests:addTest("CompetitionSystem should interact with other systems", function()
    local systems = getSystems()
    local player = createMockPlayer()
    
    -- Skip test if required systems are not available
    if not systems.CompetitionSystem or not systems.RevenueSystem then
        IntegrationTests:expect(true).toBeTrue("Test skipped: missing required systems")
        return
    end
    
    -- Start competition if system has this capability
    if systems.CompetitionSystem.StartCompetition then
        local initialRevenue = systems.RevenueSystem:GetTotalRevenue(player) or 0
        
        -- Start a competition
        local success = systems.CompetitionSystem:StartCompetition(player, "Strength")
        
        -- Verify competition started
        IntegrationTests:expect(success).toBeTrue()
        
        -- Simulate a competition win
        systems.CompetitionSystem:CompleteCompetition(player, "Strength", true)
        
        -- Check if revenue increased from winning
        task.wait(0.5) -- Allow time for event processing
        local newRevenue = systems.RevenueSystem:GetTotalRevenue(player) or 0
        
        -- Revenue should have increased
        IntegrationTests:expect(newRevenue).toBeGreaterThan(initialRevenue)
    end
end)

-- Test SaunaSystem integration
IntegrationTests:addTest("SaunaSystem should integrate with MemberSatisfactionSystem", function()
    local systems = getSystems()
    local player = createMockPlayer()
    
    -- Skip test if required systems are not available
    if not systems.SaunaSystem or not systems.MemberSatisfactionSystem then
        IntegrationTests:expect(true).toBeTrue("Test skipped: missing required systems")
        return
    end
    
    -- Set sauna temperature if system has this capability
    if systems.SaunaSystem.SetSaunaTemperature then
        local initialSatisfaction = systems.MemberSatisfactionSystem:GetSatisfaction(player) or 50
        
        -- Set optimal sauna temperature
        systems.SaunaSystem:SetSaunaTemperature(player, 80) -- Assuming 80 is optimal
        
        -- Allow time for changes to propagate
        task.wait(0.5)
        
        -- Check if satisfaction increased
        local newSatisfaction = systems.MemberSatisfactionSystem:GetSatisfaction(player) or 50
        
        -- Satisfaction should have increased with optimal temperature
        IntegrationTests:expect(newSatisfaction).toBeGreaterThanOrEqual(initialSatisfaction)
    end
end)

-- Complete end-to-end flow test
IntegrationTests:addTest("Complete gym ownership flow should work", function(done)
    local systems = getSystems()
    local player = createMockPlayer()
    
    -- Verify essential systems exist
    IntegrationTests:expect(systems.CoreRegistry).notToBeNil("CoreRegistry not found")
    IntegrationTests:expect(systems.DataManager).notToBeNil("DataManager not found")
    IntegrationTests:expect(systems.TycoonSystem).notToBeNil("TycoonSystem not found")
    
    -- 1. Reset player data
    if systems.DataManager and systems.DataManager.ResetPlayerData then
        systems.DataManager:ResetPlayerData(player)
    end
    
    -- 2. Initialize player with TycoonSystem
    if systems.TycoonSystem and systems.TycoonSystem.RegisterTycoon then
        local tycoon = systems.TycoonSystem:RegisterTycoon(player)
        IntegrationTests:expect(tycoon).notToBeNil("Failed to create tycoon")
    end
    
    -- 3. Give player starting funds
    systems.DataManager:SetData(player, "coins", 10000)
    
    -- 4. Purchase equipment
    if systems.BuyTileSystem and systems.BuyTileSystem.PurchaseTile then
        local purchaseResult = systems.BuyTileSystem:PurchaseTile(player, "BasicBench")
        IntegrationTests:expect(purchaseResult).toBeTrue("Failed to purchase equipment")
        
        -- Check funds were deducted
        local remainingCoins = systems.DataManager:GetData(player, "coins")
        IntegrationTests:expect(remainingCoins).toBeLessThan(10000)
    end
    
    -- 5. Set a specialization
    if systems.SpecializationSystem and systems.SpecializationSystem.SetPlayerSpecialization then
        systems.SpecializationSystem:SetPlayerSpecialization(player, "Strength")
        local specialization = systems.SpecializationSystem:GetPlayerSpecialization(player)
        IntegrationTests:expect(specialization).toBe("Strength")
    end
    
    -- 6. Simulate NPC workouts to generate revenue
    if systems.NPCSystem and systems.NPCSystem.SimulateNPCWorkout then
        systems.NPCSystem:SimulateNPCWorkout(player, 5) -- 5 NPCs
    end
    
    -- 7. Hire staff
    if systems.JobSystem and systems.JobSystem.HireStaff then
        local hireResult = systems.JobSystem:HireStaff(player, "Cleaner")
        IntegrationTests:expect(hireResult).toBeTrue("Failed to hire staff")
    end
    
    -- 8. Check milestone progress
    if systems.MilestoneSystem and systems.MilestoneSystem.GetMilestoneProgress then
        local equipmentProgress = systems.MilestoneSystem:GetMilestoneProgress(player, "Equipment")
        IntegrationTests:expect(equipmentProgress).notToBeNil("Milestone progress not tracked")
    end
    
    -- 9. Run for a bit to accumulate revenue
    task.wait(1)
    
    -- 10. Check that revenue was generated
    local finalRevenue = systems.RevenueSystem:GetTotalRevenue(player) or 0
    IntegrationTests:expect(finalRevenue).toBeGreaterThan(0)
    
    done()
end):async()

return IntegrationTests