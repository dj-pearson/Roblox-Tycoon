--!strict
--[[
    BuyTileSystem and TycoonStructure Test Script
    
    This script verifies that the fixes to the BuyTile System and Tycoon Structure are working correctly.
    Run this script to test all the components and ensure they are integrated properly.
    
    Created: May 2, 2025
    Author: N-DPEARSON
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Test Configuration
local CONFIG = {
    TEST_TIMEOUT = 30, -- Timeout for tests in seconds
    PLAYER_JOIN_TIMEOUT = 5, -- Timeout for player join events in seconds
    MODEL_TYPES_TO_TEST = {
        "Door",
        "Wall",
        "Glass",
        "Ceiling",
        "Floor",
        "Equipment",
        "Standard"
    },
    EXPECTED_FOLDER_STRUCTURE = {
        "TycoonData",
        "GymStructure",
        "GymStructure/Models",
        "GymStructure/Tiles",
        "GymStructure/Layout"
    },
    EXPECTED_SYSTEMS = {
        "CoreRegistry",
        "BuyTileSystem",
        "BuyTilePositionFixer",
        "TycoonFolderInitializer"
    },
    TEST_MODELS = {
        Door = {
            PrimaryPart = "DoorFrame",
            ExpectedHeight = 44
        },
        Wall = {
            PrimaryPart = "WallSection",
            ExpectedHeight = 40
        },
        Equipment = {
            PrimaryPart = "Base",
            ExpectedHeight = 0
        }
    }
}

-- Test Utilities
local TestUtils = {}

-- Logger for test results
TestUtils.Logger = {
    log = function(message: string)
        print("[BuyTileTest] " .. message)
    end,
    error = function(message: string)
        warn("[BuyTileTest ERROR] " .. message)
    end,
    success = function(message: string)
        print("[BuyTileTest SUCCESS] " .. message)
    end
}

-- Test results tracker
local TestResults = {
    Total = 0,
    Passed = 0,
    Failed = 0,
    Skipped = 0,
    StartTime = os.clock(),
    CompletedTests = {}
}

-- Record a test result
local function recordTestResult(testName: string, passed: boolean, reason: string?)
    TestResults.Total += 1
    
    if passed then
        TestResults.Passed += 1
        TestUtils.Logger.success(testName .. ": PASSED")
    else
        TestResults.Failed += 1
        TestUtils.Logger.error(testName .. ": FAILED" .. (reason and " - " .. reason or ""))
    end
    
    table.insert(TestResults.CompletedTests, {
        Name = testName,
        Passed = passed,
        Reason = reason
    })
end

-- Test runner
local function runTest(testName: string, testFunc: () -> (boolean, string?))
    TestUtils.Logger.log("Running test: " .. testName)
    
    local success, result, reason = pcall(testFunc)
    
    if not success then
        -- Test function threw an error
        recordTestResult(testName, false, "Error: " .. tostring(result))
        return false
    end
    
    recordTestResult(testName, result, reason)
    return result
end

-- Find a system using CoreRegistryBridge
local function findSystem(systemName: string)
    -- Try multiple methods to find CoreRegistryBridge
    local coreRegistryBridge
    
    -- Method 1: Direct require
    local success, result = pcall(function()
        return require(game.ServerScriptService.CoreRegistryBridge)
    end)
    
    if success and result then
        coreRegistryBridge = result
    end
    
    -- Method 2: Search in ServerScriptService
    if not coreRegistryBridge then
        for _, module in ipairs(game.ServerScriptService:GetDescendants()) do
            if module:IsA("ModuleScript") and module.Name == "CoreRegistryBridge" then
                success, result = pcall(function()
                    return require(module)
                end)
                if success and result then
                    coreRegistryBridge = result
                    break
                end
            end
        end
    end
    
    -- Method 3: Search using LookupModule method
    if not coreRegistryBridge then
        local lookupModule = function(name)
            local function search(parent)
                for _, child in ipairs(parent:GetChildren()) do
                    if child.Name == name and child:IsA("ModuleScript") then
                        return child
                    end
                    
                    local result = search(child)
                    if result then
                        return result
                    end
                end
                return nil
            end
            
            return search(game)
        end
        
        local module = lookupModule("CoreRegistryBridge")
        if module then
            success, result = pcall(function()
                return require(module)
            end)
            if success and result then
                coreRegistryBridge = result
            end
        end
    end
    
    -- If we found CoreRegistryBridge, use it to find the system
    if coreRegistryBridge then
        local success, system = pcall(function()
            return coreRegistryBridge.getSystem(systemName)
        end)
        
        if success and system then
            return system
        end
    end
    
    -- Fallback method: Direct search
    local function searchForSystem(systemName: string)
        for _, descendant in ipairs(game:GetDescendants()) do
            if descendant:IsA("ModuleScript") and descendant.Name == systemName then
                local success, system = pcall(function()
                    return require(descendant)
                end)
                
                if success and system then
                    return system
                end
            end
        end
        return nil
    end
    
    return searchForSystem(systemName)
end

-- CoreRegistry Integration Tests
local function testCoreRegistryBridge()
    local bridge = findSystem("CoreRegistryBridge")
    
    if not bridge then
        return false, "CoreRegistryBridge not found"
    end
    
    if not bridge.getCoreRegistry then
        return false, "CoreRegistryBridge.getCoreRegistry function not found"
    end
    
    local registry = bridge.getCoreRegistry()
    
    if not registry then
        return false, "CoreRegistry not found through CoreRegistryBridge"
    end
    
    return true
end

-- Test CoreRegistry has critical systems
local function testCoreRegistrySystems()
    local bridge = findSystem("CoreRegistryBridge")
    
    if not bridge then
        return false, "CoreRegistryBridge not found"
    end
    
    local missingCount = 0
    local missingSystemNames = {}
    
    for _, systemName in ipairs(CONFIG.EXPECTED_SYSTEMS) do
        local system = bridge.getSystem(systemName)
        
        if not system then
            missingCount += 1
            table.insert(missingSystemNames, systemName)
        end
    end
    
    if missingCount > 0 then
        local missingNames = table.concat(missingSystemNames, ", ")
        return false, missingCount .. " required systems missing: " .. missingNames
    end
    
    return true
end

-- TycoonFolderInitializer Tests
local function testTycoonFolderInitializer()
    local folderInitializer = findSystem("TycoonFolderInitializer")
    
    if not folderInitializer then
        return false, "TycoonFolderInitializer not found"
    end
    
    -- Check functions
    if not folderInitializer.CreateTycoonFolders then
        return false, "CreateTycoonFolders function not found"
    end
    
    if not folderInitializer.ValidateTycoonStructure then
        return false, "ValidateTycoonStructure function not found"
    end
    
    -- Test folder creation with dummy player
    local dummyPlayer = {
        Name = "TestPlayer",
        UserId = 12345
    }
    
    local success, result = pcall(function()
        return folderInitializer.CreateTycoonFolders(dummyPlayer)
    end)
    
    if not success then
        return false, "Error calling CreateTycoonFolders: " .. tostring(result)
    end
    
    -- Cleanup test folder if it was created
    for _, folder in pairs(workspace:GetChildren()) do
        if folder:IsA("Folder") and folder.Name == "TestPlayer_Tycoon" then
            folder:Destroy()
        end
    end
    
    return true
end

-- BuyTilePositionFixer Tests
local function testBuyTilePositionFixer()
    local positionFixer = findSystem("BuyTilePositionFixer")
    
    if not positionFixer then
        return false, "BuyTilePositionFixer not found"
    end
    
    -- Check functions
    if not positionFixer.FixModelPosition then
        return false, "FixModelPosition function not found"
    end
    
    if not positionFixer.FindAndFixOrphanedModels then
        return false, "FindAndFixOrphanedModels function not found"
    end
    
    -- Create test model
    local testModel = Instance.new("Model")
    testModel.Name = "TestModel"
    
    local part = Instance.new("Part")
    part.Size = Vector3.new(4, 4, 4)
    part.CFrame = CFrame.new(0, 10, 0)
    part.Parent = testModel
    
    testModel.PrimaryPart = part
    testModel.Parent = workspace
    
    -- Test fixing model position
    local success, result = pcall(function()
        return positionFixer.FixModelPosition(testModel, 1, "TestPlayer")
    end)
    
    -- Cleanup
    testModel:Destroy()
    
    if not success then
        return false, "Error calling FixModelPosition: " .. tostring(result)
    end
    
    return true
end

-- Test folder structure creation
local function testFolderStructure()
    local folderInitializer = findSystem("TycoonFolderInitializer")
    
    if not folderInitializer then
        return false, "TycoonFolderInitializer not found"
    end
    
    -- Create test folder structure
    local dummyPlayer = {
        Name = "TestPlayer",
        UserId = 12345
    }
    
    local tycoonFolder
    local success, result = pcall(function()
        tycoonFolder = folderInitializer.CreateTycoonFolders(dummyPlayer)
        return tycoonFolder
    end)
    
    if not success or not tycoonFolder then
        return false, "Error creating tycoon folders: " .. tostring(result)
    end
    
    -- Check if all expected folders exist
    local missingFolders = {}
    
    for _, folderPath in ipairs(CONFIG.EXPECTED_FOLDER_STRUCTURE) do
        local pathParts = string.split(folderPath, "/")
        local current = tycoonFolder
        
        for _, part in ipairs(pathParts) do
            current = current:FindFirstChild(part)
            
            if not current then
                table.insert(missingFolders, folderPath)
                break
            end
        end
    end
    
    -- Cleanup
    tycoonFolder:Destroy()
    
    if #missingFolders > 0 then
        local missingNames = table.concat(missingFolders, ", ")
        return false, "Missing folders: " .. missingNames
    end
    
    return true
end

-- Test setup
local function setupTestEnvironment()
    -- Create test equipment templates
    local gymEquipment = Instance.new("Folder")
    gymEquipment.Name = "GymEquipment"
    
    -- Create test equipment
    local testEquipment = Instance.new("Model")
    testEquipment.Name = "TestBench"
    local part = Instance.new("Part")
    part.Size = Vector3.new(2, 1, 4)
    part.CFrame = CFrame.new(0, 0, 0)
    part.Parent = testEquipment
    testEquipment.PrimaryPart = part
    testEquipment:SetAttribute("Price", 100)
    testEquipment.Parent = gymEquipment
    
    -- Create special equipment
    local specialEquipment = testEquipment:Clone()
    specialEquipment.Name = "SpecialEquipment"
    specialEquipment:SetAttribute("IsSpecial", true)
    specialEquipment:SetAttribute("Price", 200)
    specialEquipment.Parent = gymEquipment
    
    gymEquipment.Parent = ReplicatedStorage
    
    return {
        cleanup = function()
            gymEquipment:Destroy()
        end
    }
end

-- Test cases
local function testInitialization()
    TestUtils.Logger.log("Testing initialization...")
    
    local BuyTileSystem = require(ServerScriptService.Core.BuyTileSystem)
    
    -- Test initial state
    local status = BuyTileSystem.getStatus()
    if status ~= "UNINITIALIZED" then
        TestUtils.Logger.error("Initial state should be UNINITIALIZED, got " .. status)
        return false
    end
    
    -- Test initialization
    local success = BuyTileSystem.initialize()
    if not success then
        local errors = BuyTileSystem.getInitializationErrors()
        TestUtils.Logger.warning("Initialization completed with errors: " .. table.concat(errors, ", "))
    end
    
    -- Check if system is at least in DEGRADED state
    status = BuyTileSystem.getStatus()
    if status ~= "INITIALIZED" and status ~= "DEGRADED" then
        TestUtils.Logger.error("System should be either INITIALIZED or DEGRADED, got " .. status)
        return false
    end
    
    -- Check template loading
    local templates = BuyTileSystem.getEquipmentTemplates()
    if templates["TestBench"] == nil then
        TestUtils.Logger.error("TestBench template should be loaded")
        return false
    end
    if templates["SpecialEquipment"] == nil then
        TestUtils.Logger.error("SpecialEquipment template should be loaded")
        return false
    end
    
    return success
end

local function testPriceCalculation()
    TestUtils.Logger.log("Testing price calculation...")
    
    local BuyTileSystem = require(ServerScriptService.Core.BuyTileSystem)
    
    -- Create mock player and tycoon
    local player = Instance.new("Player")
    local tycoon = Instance.new("ObjectValue")
    tycoon.Name = "Tycoon"
    
    local tycoonModel = Instance.new("Model")
    tycoonModel:SetAttribute("EquipmentCount", 0)
    tycoon.Value = tycoonModel
    tycoon.Parent = player
    
    -- Test basic price calculation
    local price = BuyTileSystem.calculateTilePrice(player, "TestBench")
    if price ~= 100 then
        TestUtils.Logger.error("Basic price calculation failed")
        return false
    end
    
    -- Test special equipment price
    local specialPrice = BuyTileSystem.calculateTilePrice(player, "SpecialEquipment")
    if specialPrice ~= 400 then
        TestUtils.Logger.error("Special equipment price calculation failed")
        return false
    end
    
    -- Test price progression
    tycoonModel:SetAttribute("EquipmentCount", 1)
    local progressionPrice = BuyTileSystem.calculateTilePrice(player, "TestBench")
    if progressionPrice <= 100 then
        TestUtils.Logger.error("Price should increase with equipment count")
        return false
    end
    
    player:Destroy()
    return true
end

local function testEquipmentPlacement()
    TestUtils.Logger.log("Testing equipment placement...")
    
    local BuyTileSystem = require(ServerScriptService.Core.BuyTileSystem)
    
    -- Create mock player and tycoon
    local player = Instance.new("Player")
    local tycoon = Instance.new("ObjectValue")
    tycoon.Name = "Tycoon"
    
    local tycoonModel = Instance.new("Model")
    local floor = Instance.new("Part")
    floor.Name = "Floor"
    floor.Size = Vector3.new(10, 1, 10)
    floor.Position = Vector3.new(0, 0, 0)
    floor.Parent = tycoonModel
    
    tycoonModel:SetAttribute("EquipmentCount", 0)
    tycoon.Value = tycoonModel
    tycoon.Parent = player
    
    -- Test equipment placement
    local success = BuyTileSystem.placeEquipment(player, "TestBench")
    if not success then
        TestUtils.Logger.error("Equipment placement failed")
        return false
    end
    
    -- Verify equipment was placed
    local equipment = tycoonModel:FindFirstChild("Equipment")
    if equipment == nil then
        TestUtils.Logger.error("Equipment folder should be created")
        return false
    end
    if #equipment:GetChildren() ~= 1 then
        TestUtils.Logger.error("One piece of equipment should be placed")
        return false
    end
    
    -- Test equipment attributes
    local placedEquipment = equipment:GetChildren()[1]
    if placedEquipment:GetAttribute("EquipmentId") ~= "TestBench" then
        TestUtils.Logger.error("Equipment should have correct ID")
        return false
    end
    if placedEquipment:GetAttribute("OwnerUserId") ~= player.UserId then
        TestUtils.Logger.error("Equipment should have correct owner")
        return false
    end
    
    player:Destroy()
    return true
end

local function testBulkRestoration()
    TestUtils.Logger.log("Testing bulk equipment restoration...")
    
    local BuyTileSystem = require(ServerScriptService.Core.BuyTileSystem)
    
    -- Create mock player and tycoon
    local player = Instance.new("Player")
    local tycoon = Instance.new("ObjectValue")
    tycoon.Name = "Tycoon"
    
    local tycoonModel = Instance.new("Model")
    local floor = Instance.new("Part")
    floor.Name = "Floor"
    floor.Size = Vector3.new(20, 1, 20)
    floor.Position = Vector3.new(0, 0, 0)
    floor.Parent = tycoonModel
    
    tycoonModel:SetAttribute("EquipmentCount", 0)
    tycoon.Value = tycoonModel
    tycoon.Parent = player
    
    -- Test bulk restoration
    local equipmentList = {
        "TestBench",
        "TestBench",
        "SpecialEquipment",
        "TestBench"
    }
    
    local success = BuyTileSystem.restoreEquipment(player, equipmentList)
    if not success then
        TestUtils.Logger.error("Bulk restoration should start successfully")
        return false
    end
    
    -- Wait for staggered placement
    task.wait(1)
    
    -- Verify equipment was placed
    local equipment = tycoonModel:FindFirstChild("Equipment")
    if equipment == nil then
        TestUtils.Logger.error("Equipment folder should be created")
        return false
    end
    if #equipment:GetChildren() ~= #equipmentList then
        TestUtils.Logger.error("Expected " .. #equipmentList .. " pieces of equipment, got " .. #equipment:GetChildren())
        return false
    end
    
    player:Destroy()
    return true
end

-- Run all tests
local function runAllTests()
    TestUtils.Logger.log("Starting BuyTile System and Tycoon Structure tests...")
    
    -- Core integration tests
    runTest("CoreRegistryBridge Integration", testCoreRegistryBridge)
    runTest("CoreRegistry Systems Registration", testCoreRegistrySystems)
    
    -- Module tests
    runTest("TycoonFolderInitializer Functionality", testTycoonFolderInitializer)
    runTest("BuyTilePositionFixer Functionality", testBuyTilePositionFixer)
    runTest("Folder Structure Creation", testFolderStructure)
    
    -- BuyTileSystem tests
    runTest("BuyTileSystem Initialization", testInitialization)
    runTest("BuyTileSystem Price Calculation", testPriceCalculation)
    runTest("BuyTileSystem Equipment Placement", testEquipmentPlacement)
    runTest("BuyTileSystem Bulk Restoration", testBulkRestoration)
    
    -- Print results
    local duration = os.clock() - TestResults.StartTime
    TestUtils.Logger.log(string.format(
        "Test Results: %d Total, %d Passed, %d Failed, %d Skipped (%.2f seconds)",
        TestResults.Total,
        TestResults.Passed,
        TestResults.Failed,
        TestResults.Skipped,
        duration
    ))
    
    if TestResults.Failed > 0 then
        TestUtils.Logger.error("Some tests failed. Please review the logs for details.")
    else
        TestUtils.Logger.success("All tests passed successfully!")
    end
end

-- Run tests when script is executed
runAllTests()

return {
    RunTests = runAllTests,
    TestResults = TestResults
}
