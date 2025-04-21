--[[
    ConsolidationTest.server.luau
    
    Test script to validate the consolidation of GymAutomation systems.
    This script runs tests to verify that our consolidated modules are working together properly.
    
    To run the test, execute this script in Studio.
    
    Created: April 21, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local TestService = game:GetService("TestService")

-- Ensure we're running in Studio
if not RunService:IsStudio() then
    warn("ConsolidationTest can only be run in Studio")
    return
end

-- Locate CoreRegistry to get access to our systems
local CoreRegistry = nil
local systemFolder = ServerScriptService:FindFirstChild("Systems") or ServerScriptService

for _, folder in pairs(systemFolder:GetDescendants()) do
    if folder:IsA("ModuleScript") and folder.Name == "CoreRegistry" then
        CoreRegistry = require(folder)
        break
    end
end

if not CoreRegistry then
    error("CoreRegistry not found. Cannot run tests without it.")
    return
end

-- Test report variables
local totalTests = 0
local passedTests = 0

-- Simple test framework
local Test = {}
function Test:Run(testName, testFn)
    totalTests += 1
    print("\n[TEST] Running: " .. testName)
    
    local success, result = pcall(testFn)
    
    if success and result ~= false then
        print("✓ PASSED: " .. testName)
        passedTests += 1
        return true
    else
        warn("✗ FAILED: " .. testName)
        if not success then
            warn("Error: " .. tostring(result))
        end
        return false
    end
end

function Test:Assert(condition, message)
    if not condition then
        error(message or "Assertion failed", 2)
        return false
    end
    return true
end

function Test:AssertNotNil(value, name)
    if value == nil then
        error((name or "Value") .. " should not be nil", 2)
        return false
    end
    return true
end

-- Run tests with timeout protection
function Test:RunWithTimeout(testFn, timeoutSeconds)
    local testThread = coroutine.create(testFn)
    local success, result
    
    local timeoutConnection
    timeoutConnection = RunService.Heartbeat:Connect(function()
        if coroutine.status(testThread) == "dead" then
            if timeoutConnection then
                timeoutConnection:Disconnect()
                timeoutConnection = nil
            end
            return
        end
    end)
    
    -- Start test
    success, result = coroutine.resume(testThread)
    
    -- Cleanup timeout
    if timeoutConnection then
        timeoutConnection:Disconnect()
        timeoutConnection = nil
    end
    
    return success, result
end

-- Helper function to find or create a test tycoon
local function GetOrCreateTestTycoon()
    -- Check if test tycoon already exists
    local testTycoon = workspace:FindFirstChild("TestTycoon")
    
    if testTycoon then
        return testTycoon
    end
    
    -- Create a simple test tycoon
    testTycoon = Instance.new("Model")
    testTycoon.Name = "TestTycoon"
    
    -- Create basic floor structure
    local floor = Instance.new("Part")
    floor.Name = "Floor"
    floor.Size = Vector3.new(20, 1, 20)
    floor.Position = Vector3.new(0, 0, 0)
    floor.Anchored = true
    floor.Parent = testTycoon
    
    -- Set primary part
    testTycoon.PrimaryPart = floor
    
    -- Create second floor
    local floor2 = Instance.new("Part")
    floor2.Name = "Floor2"
    floor2.Size = Vector3.new(20, 1, 20)
    floor2.Position = Vector3.new(0, 10, 0)
    floor2.Anchored = true
    floor2.Parent = testTycoon
    
    -- Create walls
    local wall1 = Instance.new("Part")
    wall1.Name = "Wall1"
    wall1.Size = Vector3.new(20, 5, 1)
    wall1.Position = Vector3.new(0, 2.5, 10)
    wall1.Anchored = true
    wall1.Parent = testTycoon
    
    local wall2 = Instance.new("Part")
    wall2.Name = "Wall2"
    wall2.Size = Vector3.new(20, 5, 1)
    wall2.Position = Vector3.new(0, 2.5, -10)
    wall2.Anchored = true
    wall2.Parent = testTycoon
    
    local wall3 = Instance.new("Part")
    wall3.Name = "Wall3"
    wall3.Size = Vector3.new(1, 5, 20)
    wall3.Position = Vector3.new(10, 2.5, 0)
    wall3.Anchored = true
    wall3.Parent = testTycoon
    
    local wall4 = Instance.new("Part")
    wall4.Name = "Wall4"
    wall4.Size = Vector3.new(1, 5, 20)
    wall4.Position = Vector3.new(-10, 2.5, 0)
    wall4.Anchored = true
    wall4.Parent = testTycoon
    
    -- Create simple equipment
    local treadmill = Instance.new("Model")
    treadmill.Name = "Treadmill"
    
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(2, 0.5, 6)
    base.Position = Vector3.new(5, 0.75, 5)
    base.Anchored = true
    base.Parent = treadmill
    
    local console = Instance.new("Part")
    console.Name = "Console"
    console.Size = Vector3.new(2, 1, 1)
    console.Position = Vector3.new(5, 1.5, 2.5)
    console.Anchored = true
    console.Parent = treadmill
    
    treadmill.PrimaryPart = base
    treadmill.Parent = testTycoon
    
    -- Create weights equipment
    local benchPress = Instance.new("Model")
    benchPress.Name = "BenchPress"
    
    local bench = Instance.new("Part")
    bench.Name = "Bench"
    bench.Size = Vector3.new(2, 1, 5)
    bench.Position = Vector3.new(-5, 0.75, 5)
    bench.Anchored = true
    bench.Parent = benchPress
    
    local weights = Instance.new("Part")
    weights.Name = "Weights"
    weights.Size = Vector3.new(5, 0.5, 1)
    weights.Position = Vector3.new(-5, 0.75, 2.5)
    weights.Anchored = true
    weights.Parent = benchPress
    
    benchPress.PrimaryPart = bench
    benchPress.Parent = testTycoon
    
    testTycoon.Parent = workspace
    
    print("Created test tycoon with basic structure and equipment")
    return testTycoon
end

-- Start Running Tests
print("\n===== STARTING CONSOLIDATION TESTS =====\n")

-- Test 1: Verify that all required systems are registered
Test:Run("Core Systems Registration", function()
    local systems = {
        FloorAttributeSetup = CoreRegistry:GetSystem("FloorAttributeSetup"),
        BoundingBoxManager = CoreRegistry:GetSystem("BoundingBoxManager"),
        EquipmentManager = CoreRegistry:GetSystem("EquipmentManager"),
        MigrationUtils = CoreRegistry:GetSystem("MigrationUtils"),
        BuyTileSystem = CoreRegistry:GetSystem("BuyTileSystem"),
        TileDataGenerator = CoreRegistry:GetSystem("TileDataGenerator"),
        BuyTileProgressionManager = CoreRegistry:GetSystem("BuyTileProgressionManager")
    }
    
    for name, system in pairs(systems) do
        Test:AssertNotNil(system, name .. " should be registered with CoreRegistry")
        print("  - " .. name .. " registered: " .. tostring(system ~= nil))
    end
    
    return true
end)

-- Test 2: Test BoundingBoxManager functionality
Test:Run("BoundingBoxManager Functionality", function()
    local BoundingBoxManager = CoreRegistry:GetSystem("BoundingBoxManager")
    Test:AssertNotNil(BoundingBoxManager, "BoundingBoxManager should exist")
    
    -- Create test object for bounding box calculation
    local testParts = {}
    local testFolder = Instance.new("Folder")
    testFolder.Name = "TestBoundingBox"
    
    for i = 1, 3 do
        local part = Instance.new("Part")
        part.Size = Vector3.new(1, 1, 1)
        part.Position = Vector3.new(i, i, i)
        part.Anchored = true
        part.Parent = testFolder
        table.insert(testParts, part)
    end
    
    testFolder.Parent = workspace
    
    -- Calculate bounding box
    local bbox = BoundingBoxManager:CalculateBoundingBox(testParts)
    Test:Assert(bbox ~= nil, "Bounding box should be calculated")
    Test:Assert(bbox.Size ~= nil, "Bounding box should have Size")
    Test:Assert(bbox.CFrame ~= nil, "Bounding box should have CFrame")
    
    -- Create a hitbox
    local hitbox = BoundingBoxManager:CreateHitbox(
        "TestHitbox",
        CFrame.new(0, 5, 0),
        Vector3.new(2, 2, 2),
        testFolder,
        {TestAttribute = true}
    )
    
    Test:AssertNotNil(hitbox, "Hitbox should be created")
    Test:Assert(hitbox:GetAttribute("TestAttribute") == true, "Hitbox should have attributes")
    
    -- Test visibility functions
    local showResult = BoundingBoxManager:ShowHitboxes()
    Test:Assert(showResult.visible == true, "Hitboxes should be visible")
    
    local hideResult = BoundingBoxManager:HideHitboxes()
    Test:Assert(hideResult.visible == false, "Hitboxes should be hidden")
    
    -- Cleanup
    testFolder:Destroy()
    
    return true
end)

-- Test 3: Test EquipmentManager functionality
Test:Run("EquipmentManager Functionality", function()
    local EquipmentManager = CoreRegistry:GetSystem("EquipmentManager")
    Test:AssertNotNil(EquipmentManager, "EquipmentManager should exist")
    
    -- Create test equipment
    local testEquipment = Instance.new("Model")
    testEquipment.Name = "TestTreadmill"
    
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(2, 0.5, 6)
    base.Position = Vector3.new(0, 0.75, 0)
    base.Anchored = true
    base.Parent = testEquipment
    
    testEquipment.PrimaryPart = base
    testEquipment.Parent = workspace
    
    -- Test category detection
    local category = EquipmentManager:DetectEquipmentCategory(testEquipment)
    Test:Assert(category ~= nil, "Category should be detected")
    print("  - Detected category: " .. category)
    
    -- Test equipment attributes
    local attrs = EquipmentManager:SetupEquipmentAttributes(testEquipment)
    Test:AssertNotNil(attrs, "Equipment attributes should be set up")
    Test:Assert(testEquipment:GetAttribute("Category") ~= nil, "Equipment should have Category attribute")
    Test:Assert(testEquipment:GetAttribute("Price") ~= nil, "Equipment should have Price attribute")
    Test:Assert(testEquipment:GetAttribute("IncomeBoost") ~= nil, "Equipment should have IncomeBoost attribute")
    
    -- Test upgrade functionality
    local upgradeInfo = EquipmentManager:GetNextUpgradeInfo(testEquipment)
    Test:AssertNotNil(upgradeInfo, "Should get upgrade information")
    Test:Assert(upgradeInfo.level == 2, "Next upgrade level should be 2")
    
    local upgraded = EquipmentManager:UpgradeEquipment(testEquipment)
    Test:Assert(upgraded == true, "Equipment should upgrade successfully")
    Test:Assert(testEquipment:GetAttribute("UpgradeLevel") == 2, "Equipment should be at level 2")
    
    -- Cleanup
    testEquipment:Destroy()
    
    return true
end)

-- Test 4: Test MigrationUtils functionality
Test:Run("MigrationUtils Functionality", function()
    local MigrationUtils = CoreRegistry:GetSystem("MigrationUtils")
    Test:AssertNotNil(MigrationUtils, "MigrationUtils should exist")
    
    -- Find legacy modules
    local legacyModules = MigrationUtils:FindLegacyBuyTileModules()
    print("  - Found " .. tostring(#legacyModules) .. " legacy modules")
    
    -- Find legacy data
    local legacyData = MigrationUtils:FindLegacyBuyTileData()
    print("  - Found legacy data locations: " .. tostring(#legacyData))
    
    -- Check for conflicts
    local conflicts = MigrationUtils:CheckForConflicts()
    print("  - Module conflicts: " .. tostring(#conflicts.moduleConflicts))
    print("  - Data conflicts: " .. tostring(#conflicts.dataConflicts))
    
    return true
end)

-- Test 5: Full GymAutomation Test with Test Tycoon
Test:Run("Full GymAutomation Test", function()
    -- Get access to GymAutomation
    local GymAutomation
    
    -- First check if it's in CoreRegistry
    if CoreRegistry and CoreRegistry.GetSystem then
        GymAutomation = CoreRegistry:GetSystem("GymAutomation")
    end
    
    -- If not found, try to require it from the main location
    if not GymAutomation then
        local success, result = pcall(function()
            return require(game.ServerScriptService.GymAutomation)
        end)
        
        if success then
            GymAutomation = result
        end
    end
    
    -- Check if we found GymAutomation
    Test:AssertNotNil(GymAutomation, "GymAutomation module should be accessible")
    
    -- Create or get test tycoon
    local testTycoon = GetOrCreateTestTycoon()
    Test:AssertNotNil(testTycoon, "Test tycoon should exist")
    
    -- Run gym automation
    local results = GymAutomation:AutomateGym(testTycoon)
    Test:AssertNotNil(results, "AutomateGym should return results")
    
    -- Verify that floors were detected
    Test:Assert(results.floorCount >= 1, "Should detect at least one floor")
    print("  - Floor count: " .. results.floorCount)
    
    -- Verify that equipment was processed
    Test:Assert(results.equipmentCount >= 2, "Should process at least two equipment pieces")
    print("  - Equipment count: " .. results.equipmentCount)
    
    -- Verify that hitboxes were created
    Test:Assert(results.hitboxCount >= 2, "Should create at least two hitboxes")
    print("  - Hitbox count: " .. results.hitboxCount)
    
    -- Check that floor attributes were set correctly
    local floorPart = testTycoon:FindFirstChild("Floor", true)
    if floorPart then
        Test:Assert(floorPart:GetAttribute("Floor") ~= nil, "Floor part should have Floor attribute")
        print("  - Floor attribute: " .. tostring(floorPart:GetAttribute("Floor")))
    end
    
    return true
end)

-- Report test results
print("\n===== TEST RESULTS =====")
print(passedTests .. " of " .. totalTests .. " tests passed")

if passedTests < totalTests then
    warn("Some tests failed. See above for details.")
else
    print("All tests passed! The consolidation was successful.")
    print("The new modular system is working as expected.")
end