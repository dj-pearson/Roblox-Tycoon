--[[
    BuyTileComprehensiveTest.server.lua
    A comprehensive test suite for validating BuyTile position fixes across different model types
    
    Place in ServerScriptService/Tests to run tests on game start
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Configuration
local CONFIG = {
    debug = true,
    runOnStart = true, 
    waitDuration = 5,
    testCaseTimeout = 10, -- Seconds to wait for each test case before marking as failed
    testCategories = {
        "singlePart",      -- Test with basic single parts
        "modelWithPrimary", -- Test with models that have primary parts
        "modelNoPrimary",   -- Test with models that don't have primary parts
        "restoration",      -- Test the restoration process for previously saved models
        "playerJoin",       -- Test fixes when a player joins
        "buytileSpawn"      -- Test the BuyTile spawning system directly
    }
}

-- Color codes for log messages
local COLORS = {
    SUCCESS = Color3.fromRGB(0, 255, 0),
    ERROR = Color3.fromRGB(255, 0, 0),
    WARNING = Color3.fromRGB(255, 255, 0),
    INFO = Color3.fromRGB(0, 255, 255)
}

-- Logger
local function colorPrint(color, ...)
    local args = {...}
    local message = ""
    for i, arg in ipairs(args) do
        message = message .. tostring(arg)
        if i < #args then
            message = message .. " "
        end
    end
    
    local textObject = Instance.new("StringValue")
    textObject.Name = "OutputMessage"
    
    -- Use rich text formatting for color
    local coloredText = string.format(
        '<font color="rgb(%d,%d,%d)"><b>[BuyTileTest]</b> %s</font>',
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255),
        message
    )
    
    textObject.Value = coloredText
    game:GetService("TestService"):Message(message)
    print("[BuyTileTest]", message)
    
    textObject:Destroy()
end

-- Test results tracking
local testResults = {
    categories = {},
    total = 0,
    passed = 0,
    failed = 0
}

-- Initialize test category results
for _, category in ipairs(CONFIG.testCategories) do
    testResults.categories[category] = {
        total = 0,
        passed = 0,
        failed = 0
    }
end

-- Helper function to get the position fixer
local function getPositionFixer()
    local positionFixer = nil
    
    -- Try all possible paths
    local paths = {
        ServerScriptService.Server.BuyTilePositionFixer,
        ServerScriptService:FindFirstChild("BuyTilePositionFixer"),
        ServerScriptService:FindFirstChild("BuyTilePositionFixer", true)
    }
    
    for _, path in ipairs(paths) do
        if path then
            local success, result = pcall(function()
                return require(path)
            end)
            
            if success and result then
                positionFixer = result
                break
            end
        end
    end
    
    return positionFixer
end

-- Helper function to get the BuyTileSystem
local function getBuyTileSystem()
    local buyTileSystem = nil
    
    -- Try all possible paths
    local paths = {
        ServerScriptService:FindFirstChild("BuyTile"),
        ServerScriptService.Server:FindFirstChild("BuyTileSystem"),
        ServerScriptService.Server.Essentials:FindFirstChild("BuyTile"),
        ServerScriptService.Server.Systems:FindFirstChild("BuyTileSystem"),
        ServerScriptService:FindFirstChild("BuyTileSystem", true),
        ServerScriptService:FindFirstChild("BuyTile", true)
    }
    
    for _, path in ipairs(paths) do
        if path then
            local success, result = pcall(function()
                return require(path)
            end)
            
            if success and result then
                buyTileSystem = result
                break
            end
        end
    end
    
    return buyTileSystem
end

-- Helper function to get the DataManager
local function getDataManager()
    local dataManager = nil
    
    -- Try all possible paths
    local paths = {
        ServerScriptService.Server.Data:FindFirstChild("GymTycoonDataManager"),
        ServerScriptService.Server:FindFirstChild("GymTycoonDataManager"),
        ServerScriptService:FindFirstChild("GymTycoonDataManager", true),
        ServerScriptService:FindFirstChild("DataManager", true)
    }
    
    for _, path in ipairs(paths) do
        if path then
            local success, result = pcall(function()
                return require(path)
            end)
            
            if success and result then
                dataManager = result
                break
            end
        end
    end
    
    return dataManager
end

-- Helper function to create a test tycoon for a player
local function createTestTycoon(player)
    -- Make sure player has a Tycoon value
    local tycoonValue = player:FindFirstChild("Tycoon")
    if not tycoonValue then
        tycoonValue = Instance.new("ObjectValue")
        tycoonValue.Name = "Tycoon"
        tycoonValue.Parent = player
    end
    
    -- Create a test tycoon model if needed
    if not tycoonValue.Value then
        local tycoonModel = Instance.new("Model")
        tycoonModel.Name = "TestTycoon_" .. player.Name
        
        -- Create basic tycoon structure
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Size = Vector3.new(100, 1, 100)
        base.Position = Vector3.new(0, 0, 0)
        base.Anchored = true
        base.CanCollide = true
        base.BrickColor = BrickColor.new("Bright green")
        base.Parent = tycoonModel
        
        -- Set the tycoon Value
        tycoonValue.Value = tycoonModel
        tycoonModel.Parent = workspace
        
        -- Set owner attribute
        tycoonModel:SetAttribute("Owner", player.UserId)
        
        colorPrint(COLORS.INFO, "Created test tycoon for player:", player.Name)
    end
    
    return tycoonValue.Value
end

-- Helper function to create a test BuyTile
local function createTestBuyTile(tycoon, id, position)
    position = position or Vector3.new(0, 1, 0)
    id = id or 999
    
    -- Look for existing BuyTile with this ID
    for _, child in pairs(tycoon:GetChildren()) do
        if (child.Name:match("BuyTile") or child:GetAttribute("IsBuyTile")) and child:GetAttribute("ID") == id then
            return child
        end
    end
    
    -- Create a new BuyTile
    local buyTile = Instance.new("Model")
    buyTile.Name = "BuyTile_" .. id
    buyTile:SetAttribute("ID", id)
    buyTile:SetAttribute("IsBuyTile", true)
    
    local tilePart = Instance.new("Part")
    tilePart.Name = "BuyTilePart"
    tilePart.Size = Vector3.new(10, 1, 10)
    tilePart.Position = position
    tilePart.Anchored = true
    tilePart.CanCollide = true
    tilePart.BrickColor = BrickColor.new("Bright green")
    tilePart.Material = Enum.Material.Grass
    tilePart.Parent = buyTile
    
    buyTile.PrimaryPart = tilePart
    
    -- Create a label
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BillboardGui"
    billboard.Size = UDim2.new(5, 0, 1, 0)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.Adornee = tilePart
    billboard.Parent = buyTile
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Text = "BuyTile " .. id
    label.Parent = billboard
    
    -- Add ClickDetector
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.Parent = buyTile
    
    buyTile.Parent = tycoon
    
    colorPrint(COLORS.INFO, "Created test BuyTile with ID:", id, "at position:", tostring(position))
    return buyTile
end

-- Helper function to create a single part test model
local function createSinglePartModel(name, parent, id)
    name = name or "TestPart"
    id = id or 888
    
    local part = Instance.new("Part")
    part.Name = name
    part.Size = Vector3.new(2, 2, 2)
    part.Position = Vector3.new(0, 5, 0)
    part.Anchored = true
    part.CanCollide = true
    part.BrickColor = BrickColor.new("Really red")
    part.Material = Enum.Material.Neon
    part:SetAttribute("ID", id)
    part.Parent = parent
    
    return part
end

-- Helper function to create a model with primary part
local function createModelWithPrimaryPart(name, parent, id)
    name = name or "TestModelWithPrimary"
    id = id or 777
    
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("ID", id)
    
    local primaryPart = Instance.new("Part")
    primaryPart.Name = "PrimaryPart"
    primaryPart.Size = Vector3.new(3, 3, 3)
    primaryPart.Position = Vector3.new(0, 5, 0)
    primaryPart.Anchored = true
    primaryPart.CanCollide = true
    primaryPart.BrickColor = BrickColor.new("Bright blue")
    primaryPart.Material = Enum.Material.SmoothPlastic
    primaryPart.Parent = model
    
    local secondaryPart = Instance.new("Part")
    secondaryPart.Name = "SecondaryPart"
    secondaryPart.Size = Vector3.new(1, 1, 1)
    secondaryPart.Position = Vector3.new(0, 7, 0)
    secondaryPart.Anchored = true
    secondaryPart.CanCollide = true
    secondaryPart.BrickColor = BrickColor.new("Bright yellow")
    secondaryPart.Material = Enum.Material.Neon
    secondaryPart.Parent = model
    
    -- Create a beam connecting parts
    local attachment1 = Instance.new("Attachment")
    attachment1.Parent = primaryPart
    
    local attachment2 = Instance.new("Attachment")
    attachment2.Parent = secondaryPart
    
    local beam = Instance.new("Beam")
    beam.Attachment0 = attachment1
    beam.Attachment1 = attachment2
    beam.Width0 = 0.5
    beam.Width1 = 0.5
    beam.FaceCamera = true
    beam.Color = ColorSequence.new(Color3.new(0, 1, 1))
    beam.Parent = model
    
    model.PrimaryPart = primaryPart
    model.Parent = parent
    
    return model
end

-- Helper function to create a model without primary part
local function createModelWithoutPrimaryPart(name, parent, id)
    name = name or "TestModelNoPrimary"
    id = id or 666
    
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("ID", id)
    
    local part1 = Instance.new("Part")
    part1.Name = "Part1"
    part1.Size = Vector3.new(2, 2, 2)
    part1.Position = Vector3.new(1, 5, 1)
    part1.Anchored = true
    part1.CanCollide = true
    part1.BrickColor = BrickColor.new("Bright green")
    part1.Material = Enum.Material.SmoothPlastic
    part1.Parent = model
    
    local part2 = Instance.new("Part")
    part2.Name = "Part2"
    part2.Size = Vector3.new(2, 2, 2)
    part2.Position = Vector3.new(-1, 5, 1)
    part2.Anchored = true
    part2.CanCollide = true
    part2.BrickColor = BrickColor.new("Bright green")
    part2.Material = Enum.Material.SmoothPlastic
    part2.Parent = model
    
    local part3 = Instance.new("Part")
    part3.Name = "Part3"
    part3.Size = Vector3.new(2, 2, 2)
    part3.Position = Vector3.new(0, 5, -1)
    part3.Anchored = true
    part3.CanCollide = true
    part3.BrickColor = BrickColor.new("Bright green")
    part3.Material = Enum.Material.SmoothPlastic
    part3.Parent = model
    
    -- Note: Deliberately NOT setting a primary part
    
    model.Parent = parent
    
    return model
end

------------------------------------------
-- TEST CASES
------------------------------------------

-- Test case: Fix single part positioning
local function testSinglePartPositioning(player)
    local category = "singlePart"
    testResults.total += 1
    testResults.categories[category].total += 1
    
    -- Get position fixer
    local positionFixer = getPositionFixer()
    if not positionFixer then
        colorPrint(COLORS.ERROR, "Test failed: Position fixer not found")
        testResults.failed += 1
        testResults.categories[category].failed += 1
        return false
    end
    
    -- Create test tycoon and BuyTile
    local tycoon = createTestTycoon(player)
    local buyTile = createTestBuyTile(tycoon, 1001, Vector3.new(10, 1, 10))
    
    -- Create test part
    local part = createSinglePartModel("SinglePartTest", tycoon, 1001)
    
    -- Record original position
    local originalPosition = part.Position
    
    -- Fix position
    positionFixer.fixModelPosition(part, buyTile)
    
    -- Check if position changed
    local newPosition = part.Position
    
    -- Cleanup
    local success = newPosition ~= originalPosition
    
    if success then
        colorPrint(COLORS.SUCCESS, "Single part positioning test passed")
        testResults.passed += 1
        testResults.categories[category].passed += 1
    else
        colorPrint(COLORS.ERROR, "Single part positioning test failed - Position did not change")
        testResults.failed += 1
        testResults.categories[category].failed += 1
    end
    
    return success
end

-- Test case: Fix model with primary part positioning
local function testModelWithPrimaryPartPositioning(player)
    local category = "modelWithPrimary"
    testResults.total += 1
    testResults.categories[category].total += 1
    
    -- Get position fixer
    local positionFixer = getPositionFixer()
    if not positionFixer then
        colorPrint(COLORS.ERROR, "Test failed: Position fixer not found")
        testResults.failed += 1
        testResults.categories[category].failed += 1
        return false
    end
    
    -- Create test tycoon and BuyTile
    local tycoon = createTestTycoon(player)
    local buyTile = createTestBuyTile(tycoon, 1002, Vector3.new(20, 1, 10))
    
    -- Create test model
    local model = createModelWithPrimaryPart("ModelWithPrimaryTest", tycoon, 1002)
    
    -- Record original position
    local originalPosition = model:GetPivot().Position
    
    -- Fix position
    positionFixer.fixModelPosition(model, buyTile)
    
    -- Check if position changed
    local newPosition = model:GetPivot().Position
    
    -- Verify attributes were set
    local originalPosAttr = model:GetAttribute("OriginalPosition")
    
    local success = newPosition ~= originalPosition and originalPosAttr ~= nil
    
    if success then
        colorPrint(COLORS.SUCCESS, "Model with primary part positioning test passed")
        testResults.passed += 1
        testResults.categories[category].passed += 1
    else
        colorPrint(COLORS.ERROR, "Model with primary part positioning test failed - Position did not change or attributes not set")
        testResults.failed += 1
        testResults.categories[category].failed += 1
    end
    
    return success
end

-- Test case: Fix model without primary part positioning
local function testModelWithoutPrimaryPartPositioning(player)
    local category = "modelNoPrimary"
    testResults.total += 1
    testResults.categories[category].total += 1
    
    -- Get position fixer
    local positionFixer = getPositionFixer()
    if not positionFixer then
        colorPrint(COLORS.ERROR, "Test failed: Position fixer not found")
        testResults.failed += 1
        testResults.categories[category].failed += 1
        return false
    end
    
    -- Create test tycoon and BuyTile
    local tycoon = createTestTycoon(player)
    local buyTile = createTestBuyTile(tycoon, 1003, Vector3.new(30, 1, 10))
    
    -- Create test model
    local model = createModelWithoutPrimaryPart("ModelNoPrimaryTest", tycoon, 1003)
    
    -- Record original positions of parts
    local originalPositions = {}
    for _, part in pairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            originalPositions[part] = part.Position
        end
    end
    
    -- Fix position
    positionFixer.fixModelPosition(model, buyTile)
    
    -- Check if positions changed
    local positionsChanged = false
    for part, originalPos in pairs(originalPositions) do
        if part.Position ~= originalPos then
            positionsChanged = true
            break
        end
    end
    
    -- Check if primary part was set
    local primaryPartSet = model.PrimaryPart ~= nil
    
    local success = positionsChanged and primaryPartSet
    
    if success then
        colorPrint(COLORS.SUCCESS, "Model without primary part positioning test passed")
        testResults.passed += 1
        testResults.categories[category].passed += 1
    else
        colorPrint(COLORS.ERROR, "Model without primary part positioning test failed - Positions did not change or primary part not set")
        testResults.failed += 1
        testResults.categories[category].failed += 1
    end
    
    return success
end

-- Test case: Test BuyTile spawning system
local function testBuyTileSpawnSystem(player)
    local category = "buytileSpawn"
    testResults.total += 1
    testResults.categories[category].total += 1
    
    -- Get BuyTileSystem
    local buyTileSystem = getBuyTileSystem()
    if not buyTileSystem then
        colorPrint(COLORS.ERROR, "Test failed: BuyTileSystem not found")
        testResults.failed += 1
        testResults.categories[category].failed += 1
        return false
    end
    
    -- Create test tycoon
    local tycoon = createTestTycoon(player)
    
    -- Try to spawn a gym part
    local gymPart = nil
    local success, result = pcall(function()
        if buyTileSystem.spawnGymPartAtPosition then
            -- Try position-based spawn first
            return buyTileSystem.spawnGymPartAtPosition(1, Vector3.new(40, 1, 10), tycoon)
        elseif buyTileSystem.spawnGymPart then
            -- Try different signatures based on what's expected
            if typeof(buyTileSystem.spawnGymPart) == "function" then
                -- Try player, id
                local result = buyTileSystem.spawnGymPart(player, 1)
                if result then return result end
                
                -- Try id, position, parent
                return buyTileSystem.spawnGymPart(1, Vector3.new(40, 1, 10), tycoon)
            end
        end
        return nil
    end)
    
    if success and result then
        gymPart = result
    end
    
    if not gymPart then
        colorPrint(COLORS.ERROR, "Test failed: Could not spawn gym part")
        testResults.failed += 1
        testResults.categories[category].failed += 1
        return false
    end
    
    -- Check if the part spawned at a reasonable position (not origin)
    local position = nil
    if gymPart:IsA("Model") and gymPart.PrimaryPart then
        position = gymPart.PrimaryPart.Position
    elseif gymPart:IsA("BasePart") then
        position = gymPart.Position
    else
        -- Try to get position via GetPivot
        position = gymPart:GetPivot().Position
    end
    
    -- Check if position is set and not at origin
    local positionCheck = position ~= nil and position ~= Vector3.new(0, 0, 0)
    
    -- Check if attributes are set
    local attributesCheck = gymPart:GetAttribute("ID") ~= nil
    
    local testPassed = positionCheck and attributesCheck
    
    if testPassed then
        colorPrint(COLORS.SUCCESS, "BuyTile spawn system test passed")
        testResults.passed += 1
        testResults.categories[category].passed += 1
    else
        local failureReason = ""
        if not positionCheck then
            failureReason = "Model position not set or at origin"
        elseif not attributesCheck then
            failureReason = "Model attributes not set correctly"
        end
        
        colorPrint(COLORS.ERROR, "BuyTile spawn system test failed -", failureReason)
        testResults.failed += 1
        testResults.categories[category].failed += 1
    end
    
    return testPassed
end

-- Test case: Test restoration of saved models
local function testModelRestoration(player)
    local category = "restoration"
    testResults.total += 1
    testResults.categories[category].total += 1
    
    -- Get DataManager
    local dataManager = getDataManager()
    if not dataManager then
        colorPrint(COLORS.ERROR, "Test failed: DataManager not found")
        testResults.failed += 1
        testResults.categories[category].failed += 1
        return false
    end
    
    -- Create test tycoon
    local tycoon = createTestTycoon(player)
    
    -- Simulate purchased equipment
    local simulatedData = {
        equipmentPurchased = {
            ["1"] = true,
            ["2"] = true,
            ["3"] = true
        }
    }
    
    -- Store simulated data in player
    if not player:FindFirstChild("SimulatedData") then
        local folder = Instance.new("Folder")
        folder.Name = "SimulatedData"
        folder.Parent = player
    end
    
    player.SimulatedData:SetAttribute("HasSimulatedData", true)
    
    -- Override standard load data to use our simulated data
    local originalLoadData = dataManager.loadData
    dataManager.loadData = function(targetPlayer)
        if targetPlayer == player and player.SimulatedData:GetAttribute("HasSimulatedData") then
            return simulatedData
        else
            return originalLoadData(targetPlayer)
        end
    end
    
    -- Count existing models before restoration
    local existingModelsCount = 0
    for _, child in pairs(tycoon:GetDescendants()) do
        if child:GetAttribute("ID") and (child:IsA("Model") or child:IsA("BasePart")) then
            existingModelsCount += 1
        end
    end
    
    -- Attempt restoration
    local success = dataManager.restorePurchasedEquipment(player)
    
    -- Count models after restoration
    task.wait(1) -- Wait a bit for async operations
    
    local afterModelsCount = 0
    for _, child in pairs(tycoon:GetDescendants()) do
        if child:GetAttribute("ID") and (child:IsA("Model") or child:IsA("BasePart")) then
            afterModelsCount += 1
        end
    end
    
    -- Check if new models were added
    local modelsAdded = afterModelsCount > existingModelsCount
    
    -- Restore original loadData function
    dataManager.loadData = originalLoadData
    
    if success and modelsAdded then
        colorPrint(COLORS.SUCCESS, "Model restoration test passed")
        testResults.passed += 1
        testResults.categories[category].passed += 1
    else
        colorPrint(COLORS.ERROR, "Model restoration test failed - Models not added or restoration failed")
        testResults.failed += 1
        testResults.categories[category].failed += 1
    end
    
    return success and modelsAdded
end

-- Test case: Test model fixing when a player joins
local function testPlayerJoinFixes()
    local category = "playerJoin"
    testResults.total += 1
    testResults.categories[category].total += 1
    
    -- Create a dummy player
    local dummyPlayer = Instance.new("Player")
    dummyPlayer.Name = "TestPlayer_" .. os.time()
    
    -- Create tycoon with offset models
    local tycoon = createTestTycoon(dummyPlayer)
    
    -- Create BuyTile
    local buyTile = createTestBuyTile(tycoon, 1005, Vector3.new(50, 1, 10))
    
    -- Create models with offset positions
    local model1 = createModelWithPrimaryPart("JoinTestModel1", buyTile, 1005)
    model1:SetPrimaryPartCFrame(CFrame.new(Vector3.new(55, 10, 15))) -- Deliberately offset
    
    local model2 = createSinglePartModel("JoinTestPart", buyTile, 1005)
    model2.Position = Vector3.new(55, 15, 15) -- Deliberately offset
    
    -- Record original positions
    local originalPos1 = model1:GetPivot().Position
    local originalPos2 = model2.Position
    
    -- Get position fixer
    local positionFixer = getPositionFixer()
    if not positionFixer then
        colorPrint(COLORS.ERROR, "Test failed: Position fixer not found")
        testResults.failed += 1
        testResults.categories[category].failed += 1
        return false
    end
    
    -- Find the PlayerAdded handler (which should be a function)
    local playerAddedHandler = nil
    for _, conn in pairs(getconnections(Players.PlayerAdded)) do
        -- Simulate the handler with our dummy player
        if conn.Function then
            pcall(function()
                conn.Function(dummyPlayer)
            end)
        end
    end
    
    -- Wait for handler to potentially run
    task.wait(5)
    
    -- Check if positions were fixed
    local newPos1 = model1:GetPivot().Position
    local newPos2 = model2.Position
    
    local pos1Changed = newPos1 ~= originalPos1
    local pos2Changed = newPos2 ~= originalPos2
    
    -- Dummy player cleanup
    dummyPlayer:Destroy()
    
    if pos1Changed or pos2Changed then
        colorPrint(COLORS.SUCCESS, "Player join fixes test passed")
        testResults.passed += 1
        testResults.categories[category].passed += 1
        return true
    else
        colorPrint(COLORS.ERROR, "Player join fixes test failed - Model positions not fixed on player join")
        testResults.failed += 1
        testResults.categories[category].failed += 1
        return false
    end
end

-- Run all test cases
local function runAllTests()
    colorPrint(COLORS.INFO, "Starting comprehensive BuyTile position tests...")
    
    -- Reset test results
    testResults.total = 0
    testResults.passed = 0
    testResults.failed = 0
    
    for _, category in ipairs(CONFIG.testCategories) do
        testResults.categories[category].total = 0
        testResults.categories[category].passed = 0
        testResults.categories[category].failed = 0
    end
    
    -- Get a test player
    local testPlayer = Players:GetPlayers()[1]
    
    if not testPlayer then
        -- Create a temporary player instance for testing
        testPlayer = Instance.new("Player")
        testPlayer.Name = "TemporaryTestPlayer"
        
        -- Run tests that require a player
        testSinglePartPositioning(testPlayer)
        testModelWithPrimaryPartPositioning(testPlayer)
        testModelWithoutPrimaryPartPositioning(testPlayer)
        testBuyTileSpawnSystem(testPlayer)
        testModelRestoration(testPlayer)
        
        -- Cleanup
        testPlayer:Destroy()
    else
        -- Run tests with real player
        colorPrint(COLORS.INFO, "Using player for tests:", testPlayer.Name)
        
        testSinglePartPositioning(testPlayer)
        testModelWithPrimaryPartPositioning(testPlayer)
        testModelWithoutPrimaryPartPositioning(testPlayer)
        testBuyTileSpawnSystem(testPlayer)
        testModelRestoration(testPlayer)
    end
    
    -- Run player join test
    testPlayerJoinFixes()
    
    -- Report results
    colorPrint(COLORS.INFO, "===== TEST RESULTS =====")
    colorPrint(COLORS.INFO, "Total tests:  ", testResults.total)
    colorPrint(COLORS.INFO, "Tests passed: ", testResults.passed)
    colorPrint(COLORS.INFO, "Tests failed: ", testResults.failed)
    colorPrint(COLORS.INFO, "Success rate: ", testResults.total > 0 and math.floor((testResults.passed / testResults.total) * 100) .. "%" or "N/A")
    
    -- Report by category
    colorPrint(COLORS.INFO, "===== CATEGORY RESULTS =====")
    for category, results in pairs(testResults.categories) do
        if results.total > 0 then
            local successRate = math.floor((results.passed / results.total) * 100)
            local color = successRate >= 100 and COLORS.SUCCESS or (successRate >= 50 and COLORS.WARNING or COLORS.ERROR)
            colorPrint(color, category, ":", results.passed, "/", results.total, "(", successRate, "%)")
        end
    end
    
    -- Display results to all players
    for _, player in pairs(Players:GetPlayers()) do
        if player:FindFirstChild("PlayerGui") then
            pcall(function()
                local screen = Instance.new("ScreenGui")
                screen.Name = "BuyTileTestResults"
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(0.3, 0, 0.5, 0)
                frame.Position = UDim2.new(0.35, 0, 0.25, 0)
                frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                frame.BackgroundTransparency = 0.2
                frame.BorderSizePixel = 2
                frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
                frame.Parent = screen
                
                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, 0, 0.1, 0)
                title.Text = "BuyTile Position Fix Tests"
                title.TextSize = 18
                title.Font = Enum.Font.GothamBold
                title.TextColor3 = Color3.fromRGB(255, 255, 255)
                title.BackgroundTransparency = 1
                title.Parent = frame
                
                local resultsLabel = Instance.new("TextLabel")
                resultsLabel.Size = UDim2.new(1, 0, 0.1, 0)
                resultsLabel.Position = UDim2.new(0, 0, 0.1, 0)
                resultsLabel.Text = "Overall: " .. testResults.passed .. "/" .. testResults.total .. " (" .. (testResults.total > 0 and math.floor((testResults.passed / testResults.total) * 100) or 0) .. "%)"
                resultsLabel.TextSize = 14
                resultsLabel.Font = Enum.Font.Gotham
                resultsLabel.TextColor3 = testResults.failed > 0 and Color3.fromRGB(255, 150, 150) or Color3.fromRGB(150, 255, 150)
                resultsLabel.BackgroundTransparency = 1
                resultsLabel.Parent = frame
                
                -- Create scrolling frame for category results
                local scrollFrame = Instance.new("ScrollingFrame")
                scrollFrame.Size = UDim2.new(0.9, 0, 0.7, 0)
                scrollFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
                scrollFrame.BackgroundTransparency = 0.5
                scrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                scrollFrame.BorderSizePixel = 0
                scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 30 * #CONFIG.testCategories)
                scrollFrame.ScrollBarThickness = 4
                scrollFrame.Parent = frame
                
                -- Add category results
                local yPosition = 0
                for _, category in ipairs(CONFIG.testCategories) do
                    local results = testResults.categories[category]
                    if results.total > 0 then
                        local successRate = math.floor((results.passed / results.total) * 100)
                        
                        local categoryLabel = Instance.new("TextLabel")
                        categoryLabel.Size = UDim2.new(1, 0, 0, 25)
                        categoryLabel.Position = UDim2.new(0, 0, 0, yPosition)
                        categoryLabel.Text = category .. ": " .. results.passed .. "/" .. results.total .. " (" .. successRate .. "%)"
                        categoryLabel.TextSize = 14
                        categoryLabel.Font = Enum.Font.Gotham
                        categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
                        categoryLabel.TextColor3 = successRate >= 100 and Color3.fromRGB(150, 255, 150) or (successRate >= 50 and Color3.fromRGB(255, 255, 150) or Color3.fromRGB(255, 150, 150))
                        categoryLabel.BackgroundTransparency = 1
                        categoryLabel.Parent = scrollFrame
                        
                        yPosition += 30
                    end
                end
                
                -- Close button
                local closeButton = Instance.new("TextButton")
                closeButton.Size = UDim2.new(0.2, 0, 0.05, 0)
                closeButton.Position = UDim2.new(0.4, 0, 0.95, 0)
                closeButton.Text = "Close"
                closeButton.TextSize = 14
                closeButton.Font = Enum.Font.GothamBold
                closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                closeButton.BorderSizePixel = 0
                closeButton.Parent = frame
                
                closeButton.MouseButton1Click:Connect(function()
                    screen:Destroy()
                end)
                
                -- Auto-close after 30 seconds
                screen.Parent = player.PlayerGui
                game:GetService("Debris"):AddItem(screen, 30)
            end)
        end
    end
    
    return testResults.passed == testResults.total
end

-- Set up command to run tests
local function setupTestCommand()
    local ChatService = nil
    pcall(function()
        ChatService = require(game:GetService("ServerScriptService"):WaitForChild("ChatServiceRunner"):WaitForChild("ChatService"))
    end)
    
    if ChatService then
        ChatService:RegisterProcessCommandsFunction("buytiletest", function(speakerName, message, channel)
            local speaker = ChatService:GetSpeaker(speakerName)
            local player = speaker:GetPlayer()
            
            if not player or not player:GetRankInGroup(game.CreatorId) >= 254 then
                speaker:SendSystemMessage("You don't have permission to run this command.", channel)
                return true
            end
            
            speaker:SendSystemMessage("Running comprehensive BuyTile position tests...", channel)
            
            task.spawn(function()
                local success = runAllTests()
                if success then
                    speaker:SendSystemMessage("All BuyTile tests passed!", channel)
                else
                    speaker:SendSystemMessage("Some BuyTile tests failed. Check output for details.", channel)
                end
            end)
            
            return true
        end)
        
        colorPrint(COLORS.INFO, "Registered :buytiletest command")
    end
end

-- Main initialization
if CONFIG.runOnStart then
    task.delay(CONFIG.waitDuration, function()
        runAllTests()
    end)
end

-- Set up test command
setupTestCommand()

-- Return API for external use
return {
    runAllTests = runAllTests,
    testSinglePartPositioning = testSinglePartPositioning,
    testModelWithPrimaryPartPositioning = testModelWithPrimaryPartPositioning,
    testModelWithoutPrimaryPartPositioning = testModelWithoutPrimaryPartPositioning,
    testBuyTileSpawnSystem = testBuyTileSpawnSystem,
    testModelRestoration = testModelRestoration,
    testPlayerJoinFixes = testPlayerJoinFixes,
    getTestResults = function() return testResults end
}
