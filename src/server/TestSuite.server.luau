--!strict
--[[
    TestSuite.server.luau
    Comprehensive test suite for the consolidated gym automation system
    Part of Phase 4: Testing & Validation
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Only run in Studio
if not RunService:IsStudio() then
    warn("TestSuite is designed to run only in Studio mode")
    return
end

-- Load modules to test
local function TryRequire(path)
    local success, result = pcall(function()
        return require(path)
    end)
    return success and result or nil
end

-- Try to find CoreRegistry to access all systems
local CoreRegistry
local coreFolder = ServerScriptService:FindFirstChild("Core") 
    or ServerScriptService:FindFirstChild("Systems")
    or ServerScriptService:FindFirstChild("server")
    
if coreFolder then
    for _, module in ipairs(coreFolder:GetDescendants()) do
        if module:IsA("ModuleScript") and module.Name == "CoreRegistry" then
            CoreRegistry = TryRequire(module)
            break
        end
    end
end

-- Test setup variables
local TestConfig = {
    SampleTycoonName = "TestTycoon",
    CreateSampleTycoon = true,
    CleanupAfterTests = true,
    LogLevel = 2, -- 0: Errors only, 1: Important, 2: All
    TestGroups = {
        UnitTests = true,
        IntegrationTests = true,
        EdgeCaseTests = true
    }
}

-- Test framework
local TestSuite = {
    TotalTests = 0,
    PassedTests = 0,
    FailedTests = 0,
    SkippedTests = 0
}

-- Modules to test (try to get from CoreRegistry if available)
local Modules = {
    BoundingBoxManager = CoreRegistry and CoreRegistry:GetSystem("BoundingBoxManager") 
        or TryRequire(coreFolder:FindFirstChild("BoundingBoxManager")),
    EquipmentManager = CoreRegistry and CoreRegistry:GetSystem("EquipmentManager") 
        or TryRequire(coreFolder:FindFirstChild("EquipmentManager")),
    BuyTileSystem = CoreRegistry and CoreRegistry:GetSystem("BuyTileSystem") 
        or TryRequire(coreFolder:FindFirstChild("BuyTileSystem")),
    TileDataGenerator = CoreRegistry and CoreRegistry:GetSystem("TileDataGenerator")
        or TryRequire(coreFolder.Core.TileDataGenerator),
    FloorAttributeSetup = CoreRegistry and CoreRegistry:GetSystem("FloorAttributeSetup") 
        or TryRequire(coreFolder.FloorAttributeSetup)
}

-- Sample test tycoon
local TestTycoon

-- Logging
function TestSuite:Log(message, level)
    level = level or 2
    if level <= TestConfig.LogLevel then
        if level == 0 then
            warn("[TestSuite] " .. message)
        else
            print("[TestSuite] " .. message)
        end
    end
end

-- Assertion utility
function TestSuite:Assert(condition, message)
    self.TotalTests += 1
    
    if condition then
        self.PassedTests += 1
        self:Log("✅ PASS - " .. message, 2)
        return true
    else
        self.FailedTests += 1
        self:Log("❌ FAIL - " .. message, 0)
        return false
    end
end

-- Test grouping
function TestSuite:StartGroup(groupName)
    self:Log("\n=== " .. groupName .. " ===", 1)
end

-- Create a sample tycoon for testing
function TestSuite:CreateTestTycoon()
    if not TestConfig.CreateSampleTycoon then
        return
    end
    
    self:Log("Creating sample test tycoon...", 1)
    
    -- Check if it already exists
    local existingTycoon = Workspace:FindFirstChild(TestConfig.SampleTycoonName)
    if existingTycoon then
        existingTycoon:Destroy()
    end
    
    -- Create base model
    TestTycoon = Instance.new("Model")
    TestTycoon.Name = TestConfig.SampleTycoonName
    TestTycoon.Parent = Workspace
    
    -- Create floors
    for i = 1, 3 do
        local floor = Instance.new("Model")
        floor.Name = "Floor" .. i
        floor.Parent = TestTycoon
        
        -- Create floor base
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Size = Vector3.new(50, 1, 50)
        base.Position = Vector3.new(0, (i-1) * 10, 0)
        base.Anchored = true
        base.CanCollide = true
        base.Parent = floor
        
        floor:SetAttribute("FloorNumber", i)
        
        -- Create different equipment for each floor
        if i == 1 then
            self:CreateSampleEquipment(floor, "Treadmill", "CARDIO", Vector3.new(-10, (i-1) * 10 + 1, -10))
            self:CreateSampleEquipment(floor, "BenchPress", "STRENGTH", Vector3.new(10, (i-1) * 10 + 1, -10))
        elseif i == 2 then
            self:CreateSampleEquipment(floor, "Elliptical", "CARDIO", Vector3.new(-10, (i-1) * 10 + 1, -10))
            self:CreateSampleEquipment(floor, "DumbbellRack", "STRENGTH", Vector3.new(10, (i-1) * 10 + 1, -10))
            self:CreateSampleEquipment(floor, "WaterFountain", "AMENITIES", Vector3.new(0, (i-1) * 10 + 1, 15))
        elseif i == 3 then
            self:CreateSampleEquipment(floor, "SwimmingPool", "SPECIALTY", Vector3.new(0, (i-1) * 10 + 1, 0))
        end
    end
    
    self:Log("Created test tycoon with 3 floors and sample equipment", 1)
    return TestTycoon
end

-- Create sample equipment for testing
function TestSuite:CreateSampleEquipment(parent, name, category, position)
    local equipment = Instance.new("Model")
    equipment.Name = name
    equipment.Parent = parent
    
    local main = Instance.new("Part")
    main.Name = "Main"
    main.Size = Vector3.new(4, 2, 4)
    main.Position = position
    main.Anchored = true
    main.CanCollide = true
    main.Parent = equipment
    
    equipment:SetAttribute("Category", category)
    equipment:SetAttribute("Floor", parent:GetAttribute("FloorNumber"))
    
    return equipment
end

-- Clean up after tests
function TestSuite:CleanupTestTycoon()
    if TestConfig.CleanupAfterTests and TestTycoon then
        TestTycoon:Destroy()
        self:Log("Cleaned up test tycoon", 1)
    end
end

----------------------------------
-- UNIT TESTS
----------------------------------

-- Unit tests for BoundingBoxManager
function TestSuite:RunBoundingBoxManagerUnitTests()
    if not TestConfig.TestGroups.UnitTests then return end
    if not Modules.BoundingBoxManager then 
        self:Log("Skipping BoundingBoxManager tests - module not found", 0)
        self.SkippedTests += 5
        return 
    end
    
    self:StartGroup("BoundingBoxManager Unit Tests")
    
    -- Test 1: Calculate bounding box
    local testPart = Instance.new("Part")
    testPart.Size = Vector3.new(4, 2, 4)
    testPart.Position = Vector3.new(0, 0, 0)
    
    local boundingBox = Modules.BoundingBoxManager:CalculateBoundingBox(testPart)
    self:Assert(boundingBox ~= nil, "Calculate bounding box returns a result")
    self:Assert(typeof(boundingBox.Size) == "Vector3", "Bounding box has Size property")
    self:Assert(typeof(boundingBox.CFrame) == "CFrame", "Bounding box has CFrame property")
    
    -- Test 2: Create hitbox
    local hitbox = Modules.BoundingBoxManager:CreateHitbox(testPart)
    self:Assert(hitbox ~= nil, "CreateHitbox returns a result")
    
    -- Test 3: Visibility toggle
    Modules.BoundingBoxManager:SetHitboxesVisible(false)
    self:Assert(hitbox.Transparency > 0.9, "Hitbox becomes invisible")
    
    Modules.BoundingBoxManager:SetHitboxesVisible(true)
    self:Assert(hitbox.Transparency < 0.9, "Hitbox becomes visible")
    
    -- Cleanup
    testPart:Destroy()
    if hitbox and hitbox.Parent then hitbox:Destroy() end
end

-- Unit tests for EquipmentManager
function TestSuite:RunEquipmentManagerUnitTests()
    if not TestConfig.TestGroups.UnitTests then return end
    if not Modules.EquipmentManager then 
        self:Log("Skipping EquipmentManager tests - module not found", 0)
        self.SkippedTests += 6
        return 
    end
    
    self:StartGroup("EquipmentManager Unit Tests")
    
    -- Create test equipment
    local equipment = self:CreateSampleEquipment(Workspace, "TestTreadmill", "CARDIO", Vector3.new(0, 0, 0))
    
    -- Test 1: Detect equipment category
    local category = Modules.EquipmentManager:DetectEquipmentCategory(equipment)
    self:Assert(category == "CARDIO", "DetectEquipmentCategory returns correct category")
    
    -- Test 2: Setup equipment attributes
    local attributes = Modules.EquipmentManager:SetupEquipmentAttributes(equipment)
    self:Assert(attributes ~= nil, "SetupEquipmentAttributes returns attributes")
    self:Assert(equipment:GetAttribute("Price") ~= nil, "Equipment has Price attribute")
    self:Assert(equipment:GetAttribute("IncomeBoost") ~= nil, "Equipment has IncomeBoost attribute")
    
    -- Test 3: Get upgrade info
    local upgradeInfo = Modules.EquipmentManager:GetNextUpgradeInfo(equipment)
    self:Assert(upgradeInfo ~= nil, "GetNextUpgradeInfo returns data")
    self:Assert(upgradeInfo.level == 2, "Next upgrade level is 2")
    
    -- Test 4: Upgrade equipment
    local upgraded = Modules.EquipmentManager:UpgradeEquipment(equipment)
    self:Assert(upgraded, "UpgradeEquipment returns true")
    self:Assert(equipment:GetAttribute("UpgradeLevel") == 2, "Equipment upgraded to level 2")
    
    -- Cleanup
    equipment:Destroy()
end

----------------------------------
-- INTEGRATION TESTS
----------------------------------

-- Integration tests for system interactions
function TestSuite:RunIntegrationTests()
    if not TestConfig.TestGroups.IntegrationTests then return end
    if not (Modules.EquipmentManager and Modules.BoundingBoxManager) then
        self:Log("Skipping integration tests - required modules not found", 0)
        self.SkippedTests += 4
        return
    end
    
    self:StartGroup("Integration Tests")
    
    -- Create test tycoon if not exists
    if not TestTycoon then
        self:CreateTestTycoon()
    end
    
    -- Test 1: Equipment processing creates hitboxes
    local treadmill = TestTycoon.Floor1.Treadmill
    if treadmill then
        Modules.EquipmentManager:ProcessEquipment(treadmill, {generateInteractions = true})
        
        -- Find the hitbox (should be a child of a "Hitboxes" folder or similar)
        local hitbox
        for _, child in ipairs(Workspace:GetDescendants()) do
            if child:IsA("BasePart") and child.Name:match("Hitbox") and 
               (child.Position - treadmill.Main.Position).Magnitude < 10 then
                hitbox = child
                break
            end
        end
        
        self:Assert(hitbox ~= nil, "Equipment processing creates hitboxes")
    else
        self:Log("Skipping equipment hitbox test - equipment not found", 0)
        self.SkippedTests += 1
    end
    
    -- Test 2: Equipment upgrades affect income values
    local benchPress = TestTycoon.Floor1.BenchPress
    if benchPress then
        Modules.EquipmentManager:ProcessEquipment(benchPress)
        local initialIncome = benchPress:GetAttribute("IncomeBoost") or benchPress:GetAttribute("IncomeBonus") or 0
        
        Modules.EquipmentManager:UpgradeEquipment(benchPress)
        local upgradedIncome = benchPress:GetAttribute("IncomeBoost") or benchPress:GetAttribute("IncomeBonus") or 0
        
        self:Assert(upgradedIncome > initialIncome, "Equipment upgrades increase income values")
    else
        self:Log("Skipping equipment upgrade test - equipment not found", 0)
        self.SkippedTests += 1
    end
    
    -- Test 3: Floor detection works with equipment
    local elliptical = TestTycoon.Floor2.Elliptical
    if elliptical and Modules.FloorAttributeSetup then
        local detectedFloor = Modules.FloorAttributeSetup:GetFloorForPosition(elliptical:GetPivot().Position)
        self:Assert(detectedFloor == 2, "Floor detection returns correct floor number")
    else
        self:Log("Skipping floor detection test - equipment or module not found", 0)
        self.SkippedTests += 1
    end
end

----------------------------------
-- EDGE CASE TESTS
----------------------------------

-- Edge case tests for error handling
function TestSuite:RunEdgeCaseTests()
    if not TestConfig.TestGroups.EdgeCaseTests then return end
    
    self:StartGroup("Edge Case Tests")
    
    -- Test 1: Handle null equipment
    if Modules.EquipmentManager then
        local success = pcall(function()
            Modules.EquipmentManager:ProcessEquipment(nil)
        end)
        self:Assert(success, "EquipmentManager handles nil equipment gracefully")
    else
        self.SkippedTests += 1
    end
    
    -- Test 2: Handle equipment with no parts
    if Modules.EquipmentManager then
        local emptyModel = Instance.new("Model")
        emptyModel.Name = "EmptyModel"
        emptyModel.Parent = Workspace
        
        local success = pcall(function()
            Modules.EquipmentManager:ProcessEquipment(emptyModel)
        end)
        self:Assert(success, "EquipmentManager handles empty models gracefully")
        
        emptyModel:Destroy()
    else
        self.SkippedTests += 1
    end
    
    -- Test 3: Handle invalid bounding box calculation
    if Modules.BoundingBoxManager then
        local success = pcall(function()
            Modules.BoundingBoxManager:CalculateBoundingBox(nil)
        end)
        self:Assert(success, "BoundingBoxManager handles nil model gracefully")
    else
        self.SkippedTests += 1
    end
end

----------------------------------
-- SAMPLE TYCOON VALIDATION
----------------------------------

-- Test automation on sample gym tycoon
function TestSuite:RunSampleTycoonTests()
    if not TestTycoon then
        self:CreateTestTycoon()
    end
    
    self:StartGroup("Sample Tycoon Validation Tests")
    
    -- Test 1: Process all equipment in tycoon
    if Modules.EquipmentManager then
        local stats = Modules.EquipmentManager:ProcessAllEquipment(TestTycoon)
        self:Assert(stats.processed >= 5, "All equipment in tycoon processed")
    else
        self.SkippedTests += 1
    end
    
    -- Test 2: Check for equipment attributes on all equipment
    local equipmentCount = 0
    local fullyAttributed = 0
    
    for _, floor in ipairs(TestTycoon:GetChildren()) do
        if floor:IsA("Model") and floor.Name:match("Floor") then
            for _, model in ipairs(floor:GetChildren()) do
                if model:IsA("Model") and model ~= floor.Base then
                    equipmentCount += 1
                    
                    if model:GetAttribute("Price") and 
                       model:GetAttribute("Category") and
                       (model:GetAttribute("IncomeBoost") or model:GetAttribute("IncomeBonus")) then
                        fullyAttributed += 1
                    end
                end
            end
        end
    end
    
    self:Assert(fullyAttributed == equipmentCount, 
        string.format("All equipment has necessary attributes (%d/%d)", fullyAttributed, equipmentCount))
    
    -- Additional tests could be added here
end

-- Run all tests
function TestSuite:RunAllTests()
    self:Log("\n========================================", 1)
    self:Log("STARTING CONSOLIDATED MODULES TEST SUITE", 1)
    self:Log("========================================\n", 1)
    
    -- Create test environment
    self:CreateTestTycoon()
    
    -- Unit Tests
    self:RunBoundingBoxManagerUnitTests()
    self:RunEquipmentManagerUnitTests()
    
    -- Integration Tests
    self:RunIntegrationTests()
    
    -- Edge Case Tests
    self:RunEdgeCaseTests()
    
    -- Sample Tycoon Tests
    self:RunSampleTycoonTests()
    
    -- Cleanup
    self:CleanupTestTycoon()
    
    -- Report Results
    self:Log("\n========================================", 1)
    self:Log("TEST SUITE SUMMARY", 1)
    self:Log("========================================", 1)
    self:Log(string.format("Total Tests: %d", self.TotalTests), 1)
    self:Log(string.format("Passed: %d (%.1f%%)", self.PassedTests, 
        self.TotalTests > 0 and (self.PassedTests / self.TotalTests * 100) or 0), 1)
    self:Log(string.format("Failed: %d", self.FailedTests), self.FailedTests > 0 and 0 or 1)
    self:Log(string.format("Skipped: %d", self.SkippedTests), self.SkippedTests > 0 and 0 or 1)
    self:Log("========================================\n", 1)
    
    return {
        total = self.TotalTests,
        passed = self.PassedTests,
        failed = self.FailedTests,
        skipped = self.SkippedTests
    }
end

-- Register global function for running tests
if RunService:IsStudio() then
    _G.RunTestSuite = function()
        return TestSuite:RunAllTests()
    end
    
    print("Test suite initialized. Run _G.RunTestSuite() to execute all tests.")
end

return TestSuite
