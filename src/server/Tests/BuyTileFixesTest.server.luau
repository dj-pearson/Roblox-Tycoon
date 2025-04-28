--[[
    BuyTileFixesTest.server.luau
    
    This script tests the fixes for the BuyTile system to ensure gym parts
    are properly found and spawned.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Test configuration
local CONFIG = {
    testIds = {1, 2, 3, "Test", "Missing", "GymPart1"},
    waitBetweenTests = 1
}

-- Test results
local results = {
    passed = 0,
    failed = 0,
    tests = {}
}

-- Record test result
local function recordTest(name, passed, details)
    local result = {
        name = name,
        passed = passed,
        details = details or ""
    }
    
    table.insert(results.tests, result)
    
    if passed then
        results.passed = results.passed + 1
        print("✅ [BuyTileFixesTest] PASSED:", name)
    else
        results.failed = results.failed + 1
        warn("❌ [BuyTileFixesTest] FAILED:", name, "-", details or "")
    end
    
    return passed
end

-- Find the BuyTile system
local function findBuyTileSystem()
    -- Look in common locations
    local searchPaths = {
        ServerScriptService:FindFirstChild("BuyTileSystem"),
        ServerScriptService.Server and ServerScriptService.Server:FindFirstChild("BuyTileSystem"),
        ServerScriptService:FindFirstChild("BuyTileFixer"),
        ServerScriptService.Server and ServerScriptService.Server:FindFirstChild("BuyTileFixer")
    }
    
    for _, path in ipairs(searchPaths) do
        if path and (path:IsA("ModuleScript") or path:IsA("Script")) then
            print("[BuyTileFixesTest] Found BuyTile system at:", path:GetFullName())
            
            if path:IsA("ModuleScript") then
                local success, module = pcall(function()
                    return require(path)
                end)
                
                if success and module then
                    return module
                end
            end
        end
    end
    
    warn("[BuyTileFixesTest] Could not find BuyTile system")
    return nil
end

-- Find the BuyTileFixer
local function findBuyTileFixer()
    -- Look in common locations
    local searchPaths = {
        ServerScriptService:FindFirstChild("BuyTileFixer"),
        ServerScriptService.Server and ServerScriptService.Server:FindFirstChild("BuyTileFixer"),
        ServerScriptService:FindFirstChild("BuyTileFixer.server"),
        ServerScriptService.Server and ServerScriptService.Server:FindFirstChild("BuyTileFixer.server")
    }
    
    for _, path in ipairs(searchPaths) do
        if path and (path:IsA("ModuleScript") or path:IsA("Script")) then
            print("[BuyTileFixesTest] Found BuyTileFixer at:", path:GetFullName())
            
            if path:IsA("ModuleScript") then
                local success, module = pcall(function()
                    return require(path)
                end)
                
                if success and module then
                    return module
                end
            end
        end
    end
    
    warn("[BuyTileFixesTest] Could not find BuyTileFixer")
    return nil
end

-- Test finding gym parts
local function testFindGymParts()
    -- First try to get the BuyTile system
    local buyTileSystem = findBuyTileSystem()
    local buyTileFixer = findBuyTileFixer()
    
    -- Choose which module to use for testing
    local moduleToTest = buyTileSystem or buyTileFixer
    
    if not moduleToTest then
        recordTest("Find BuyTile System", false, "Neither BuyTileSystem nor BuyTileFixer found")
        return false
    end
    
    recordTest("Find BuyTile System", true)
    
    -- Test if the module has the required functions
    local hasFindFunction = moduleToTest.findGymPartById or moduleToTest.findGymPart
    
    if not hasFindFunction then
        recordTest("Find Function Exists", false, "Module does not have findGymPartById or findGymPart function")
        return false
    end
    
    recordTest("Find Function Exists", true)
    
    -- Test finding each ID
    for _, id in ipairs(CONFIG.testIds) do
        local testName = "Find Gym Part ID: " .. tostring(id)
        
        local part
        if moduleToTest.findGymPartById then
            part = moduleToTest.findGymPartById(id)
        elseif moduleToTest.findGymPart then
            part = moduleToTest.findGymPart(id)
        end
        
        if part then
            recordTest(testName, true)
            
            -- Additional test: Check if it has an ID attribute
            local hasId = part:GetAttribute("ID") or part:GetAttribute("Id") or part:GetAttribute("id")
            recordTest(testName .. " - Has ID Attribute", hasId ~= nil, "Missing ID attribute")
        else
            recordTest(testName, false, "Failed to find gym part")
        end
        
        task.wait(CONFIG.waitBetweenTests)
    end
end

-- Test spawning gym parts
local function testSpawnGymParts()
    -- First try to get the BuyTile system
    local buyTileSystem = findBuyTileSystem()
    local buyTileFixer = findBuyTileFixer()
    
    -- Choose which module to use for testing
    local moduleToTest = buyTileSystem or buyTileFixer
    
    if not moduleToTest then
        recordTest("Find BuyTile System for Spawning", false, "Neither BuyTileSystem nor BuyTileFixer found")
        return false
    end
    
    -- Test if the module has the spawn function
    local hasSpawnFunction = moduleToTest.spawnGymPart
    
    if not hasSpawnFunction then
        recordTest("Spawn Function Exists", false, "Module does not have spawnGymPart function")
        return false
    end
    
    recordTest("Spawn Function Exists", true)
    
    -- Create a temp container for test spawns
    local tempContainer = Instance.new("Folder")
    tempContainer.Name = "TestSpawnContainer"
    tempContainer.Parent = Workspace
    
    -- Get a player to use for testing
    local testPlayer = Players:GetPlayers()[1]
    
    -- If no players, create a dummy player
    if not testPlayer then
        testPlayer = {
            Name = "TestPlayer",
            UserId = 0,
            FindFirstChild = function() return nil end
        }
    end
    
    -- Test spawning each ID
    for _, id in ipairs(CONFIG.testIds) do
        local testName = "Spawn Gym Part ID: " .. tostring(id)
        
        -- Try to spawn
        local spawnPosition = Vector3.new(0, 10, 0) -- Spawn high up
        local part = moduleToTest.spawnGymPart(testPlayer, id, spawnPosition)
        
        if part then
            recordTest(testName, true)
            
            -- Move to temp container for cleanup
            part.Parent = tempContainer
        else
            recordTest(testName, false, "Failed to spawn gym part")
        end
        
        task.wait(CONFIG.waitBetweenTests)
    end
    
    -- Clean up
    tempContainer:Destroy()
end

-- Test gym parts folder
local function testGymPartsFolder()
    -- Test if GymParts folder exists
    local gymPartsFolder
    
    -- Check common locations
    local locations = {
        ServerStorage:FindFirstChild("GymParts"),
        Workspace:FindFirstChild("GymParts")
    }
    
    for _, folder in ipairs(locations) do
        if folder and folder:IsA("Folder") then
            gymPartsFolder = folder
            break
        end
    end
    
    recordTest("GymParts Folder Exists", gymPartsFolder ~= nil, "GymParts folder not found in ServerStorage or Workspace")
    
    if not gymPartsFolder then
        return false
    end
    
    -- Check if it has at least some gym parts
    local hasItems = #gymPartsFolder:GetChildren() > 0
    recordTest("GymParts Folder Has Items", hasItems, "GymParts folder is empty")
    
    -- Check for gym part with ID 1
    local foundPart1 = false
    
    -- Check direct children first
    foundPart1 = gymPartsFolder:FindFirstChild("GymPart1") or 
               gymPartsFolder:FindFirstChild("Gym_Part_1") or
               gymPartsFolder:FindFirstChild("GymPart_1") ~= nil
    
    -- If not found, check using attributes
    if not foundPart1 then
        for _, item in ipairs(gymPartsFolder:GetDescendants()) do
            if (item:IsA("Model") or item:IsA("Part")) and 
               (item:GetAttribute("ID") == 1 or item:GetAttribute("Id") == 1 or item:GetAttribute("id") == 1 or
                item:GetAttribute("ID") == "1" or item:GetAttribute("Id") == "1" or item:GetAttribute("id") == "1") then
                foundPart1 = true
                break
            end
        end
    end
    
    recordTest("GymPart ID 1 Exists", foundPart1, "GymPart with ID 1 not found")
end

-- Run all tests
local function runAllTests()
    print("[BuyTileFixesTest] Starting tests...")
    
    testGymPartsFolder()
    testFindGymParts()
    testSpawnGymParts()
    
    -- Print summary
    print("[BuyTileFixesTest] Tests complete:")
    print(string.format("✅ Passed: %d", results.passed))
    print(string.format("❌ Failed: %d", results.failed))
    print(string.format("📊 Pass Rate: %.1f%%", (results.passed / (results.passed + results.failed)) * 100))
    
    -- Create a StringValue with the results
    local resultsValue = Instance.new("StringValue")
    resultsValue.Name = "BuyTileFixesTestResults"
    resultsValue.Value = string.format("Passed: %d, Failed: %d", results.passed, results.failed)
    resultsValue.Parent = script
    
    return results
end

-- Wait a moment for everything to load before testing
task.wait(3)
return runAllTests()
