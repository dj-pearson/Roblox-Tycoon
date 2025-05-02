--[[
    BuyTilePositionFixerTest.server.lua
    Tests the BuyTilePositionFixer system to validate model positioning fixes
    
    Place in ServerScriptService to run tests on game start
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Configuration
local CONFIG = {
    debug = true,
    runOnStart = true,  -- Set to false to only run tests on command
    waitDuration = 5,   -- Seconds to wait after game start before running tests
    testModels = 10,    -- Number of test models to create
    testPlayerId = nil, -- Set to a specific player ID to test, or nil for any player
}

-- Logger
local function log(...)
    if CONFIG.debug then
        print("[BuyTilePositionFixerTest]", ...)
    end
end

-- Test status tracker
local testResults = {
    total = 0,
    passed = 0,
    failed = 0,
}

-- Helper function to get the position fixer
local function getPositionFixer()
    local success, positionFixer = pcall(function()
        return require(ServerScriptService.Server.BuyTilePositionFixer)
    end)
    
    if success and positionFixer then
        return positionFixer
    end
    
    -- Try alternative paths
    success, positionFixer = pcall(function()
        return require(ServerScriptService:FindFirstChild("BuyTilePositionFixer", true))
    end)
    
    if success and positionFixer then
        return positionFixer
    end
    
    return nil
end

-- Helper function to get the BuyTileSystem
local function getBuyTileSystem()
    -- Try multiple approaches to find the BuyTileSystem
    local buyTileSystem = nil
    
    -- First try direct require from ServerScriptService
    pcall(function()
        buyTileSystem = require(ServerScriptService:FindFirstChild("BuyTile"))
    end)
    
    -- If that didn't work, try looking in server folder
    if not buyTileSystem or not buyTileSystem.spawnGymPart then
        pcall(function()
            buyTileSystem = require(ServerScriptService.Server:FindFirstChild("BuyTileSystem"))
        end)
    end
    
    -- Try Essentials folder
    if not buyTileSystem or not buyTileSystem.spawnGymPart then
        pcall(function()
            buyTileSystem = require(ServerScriptService.Server.Essentials:FindFirstChild("BuyTile"))
        end)
    end
    
    -- Try Systems folder
    if not buyTileSystem or not buyTileSystem.spawnGymPart then
        pcall(function()
            buyTileSystem = require(ServerScriptService.Server.Systems:FindFirstChild("BuyTileSystem"))
        end)
    end
    
    return buyTileSystem
end

-- Test: Check if BuyTilePositionFixer is loaded
local function testPositionFixerLoaded()
    testResults.total += 1
    
    local positionFixer = getPositionFixer()
    if positionFixer then
        log("✓ BuyTilePositionFixer is loaded")
        testResults.passed += 1
        return true
    else
        log("✗ BuyTilePositionFixer is NOT loaded")
        testResults.failed += 1
        return false
    end
end

-- Test: Check if BuyTileSystem is loaded
local function testBuyTileSystemLoaded()
    testResults.total += 1
    
    local buyTileSystem = getBuyTileSystem()
    if buyTileSystem then
        log("✓ BuyTileSystem is loaded")
        testResults.passed += 1
        return true
    else
        log("✗ BuyTileSystem is NOT loaded")
        testResults.failed += 1
        return false
    end
end

-- Test: Create a model and fix its position
local function testModelPositioning(player)
    if not player then
        log("No player available for testing model positioning")
        return false
    end
    
    testResults.total += 1
    
    local positionFixer = getPositionFixer()
    if not positionFixer then
        log("✗ Cannot test model positioning - BuyTilePositionFixer not found")
        testResults.failed += 1
        return false
    end
    
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then
        log("✗ Player has no tycoon assigned")
        testResults.failed += 1
        return false
    end
    
    -- Create a test model
    local model = Instance.new("Model")
    model.Name = "TestModel_" .. os.time()
    
    local part = Instance.new("Part")
    part.Size = Vector3.new(2, 2, 2)
    part.BrickColor = BrickColor.new("Bright red")
    part.Material = Enum.Material.Neon
    part.Anchored = true
    part.CanCollide = true
    part.Parent = model
    
    model.PrimaryPart = part
    model:SetAttribute("ID", 999) -- Test ID
    model.Parent = tycoon.Value
    
    -- Create a test tile
    local tilePart = Instance.new("Part")
    tilePart.Name = "TestBuyTile"
    tilePart.Size = Vector3.new(10, 1, 10)
    tilePart.BrickColor = BrickColor.new("Bright green")
    tilePart.Material = Enum.Material.Grass
    tilePart.Anchored = true
    tilePart.Position = Vector3.new(-100, 0, -100) -- Test position
    tilePart:SetAttribute("ID", 999) -- Same ID as model
    tilePart.Parent = tycoon.Value
    
    -- Store model's original position
    local originalPosition = model:GetPivot().Position
    log("Original model position:", tostring(originalPosition))
    
    -- Apply position fix
    positionFixer.fixModelPosition(model, tilePart)
    
    -- Check if position changed
    local newPosition = model:GetPivot().Position
    log("New model position:", tostring(newPosition))
    
    -- Verify position was changed
    if newPosition ~= originalPosition then
        log("✓ Model position was successfully changed")
        testResults.passed += 1
        
        -- Cleanup
        model:Destroy()
        tilePart:Destroy()
        return true
    else
        log("✗ Model position was not changed")
        testResults.failed += 1
        
        -- Cleanup
        model:Destroy()
        tilePart:Destroy()
        return false
    end
end

-- Test: Test spawning a model using BuyTileSystem
local function testModelSpawning(player)
    if not player then
        log("No player available for testing model spawning")
        return false
    end
    
    testResults.total += 1
    
    local buyTileSystem = getBuyTileSystem()
    if not buyTileSystem or not buyTileSystem.spawnGymPart then
        log("✗ Cannot test model spawning - BuyTileSystem not found or missing spawnGymPart")
        testResults.failed += 1
        return false
    end
    
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then
        log("✗ Player has no tycoon assigned")
        testResults.failed += 1
        return false
    end
    
    -- Create a test tile
    local tilePart = Instance.new("Part")
    tilePart.Name = "TestBuyTile"
    tilePart.Size = Vector3.new(10, 1, 10)
    tilePart.BrickColor = BrickColor.new("Bright green")
    tilePart.Material = Enum.Material.Grass
    tilePart.Anchored = true
    tilePart.Position = Vector3.new(-120, 0, -120) -- Test position
    tilePart:SetAttribute("ID", 888) -- Test ID
    tilePart.Parent = tycoon.Value
    
    -- Try to spawn a gym part
    local success, model = pcall(function()
        return buyTileSystem.spawnGymPart(1) -- Use ID 1 which usually exists
    end)
    
    if not success or not model then
        -- Try alternative signature
        success, model = pcall(function()
            return buyTileSystem.spawnGymPart(player, 1)
        end)
    end
    
    if success and model then
        log("✓ Successfully spawned model using BuyTileSystem")
        
        -- Move model to test tile
        if model:IsA("Model") and model.PrimaryPart then
            model:SetPrimaryPartCFrame(CFrame.new(tilePart.Position + Vector3.new(0, 2, 0)))
        elseif model:IsA("BasePart") then
            model.Position = tilePart.Position + Vector3.new(0, 2, 0)
        end
        
        model.Parent = tycoon.Value
        
        -- Check if position is not at origin
        local position = nil
        if model:IsA("Model") and model.PrimaryPart then
            position = model.PrimaryPart.Position
        elseif model:IsA("BasePart") then
            position = model.Position
        end
        
        if position and position ~= Vector3.new(0, 0, 0) then
            log("✓ Model spawn position is not at origin:", tostring(position))
            testResults.passed += 1
            
            -- Cleanup
            model:Destroy()
            tilePart:Destroy()
            return true
        else
            log("✗ Model spawn position is at origin or could not be determined")
            testResults.failed += 1
            
            -- Cleanup
            model:Destroy()
            tilePart:Destroy()
            return false
        end
    else
        log("✗ Failed to spawn model using BuyTileSystem")
        testResults.failed += 1
        
        -- Cleanup
        tilePart:Destroy()
        return false
    end
end

-- Test: Fix multiple models in workspace
local function testFixExistingModels()
    testResults.total += 1
    
    local positionFixer = getPositionFixer()
    if not positionFixer or not positionFixer.fixExistingModels then
        log("✗ Cannot test fixExistingModels - function not found")
        testResults.failed += 1
        return false
    end
    
    -- Create some test models in random positions
    local testModels = {}
    local player = CONFIG.testPlayerId and Players:GetPlayerByUserId(CONFIG.testPlayerId) or Players:GetPlayers()[1]
    
    if not player then
        log("✗ No player available for testing fixExistingModels")
        testResults.failed += 1
        return false
    end
    
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then
        log("✗ Player has no tycoon assigned")
        testResults.failed += 1
        return false
    end
    
    -- Create a BuyTile parent
    local buyTile = Instance.new("Model")
    buyTile.Name = "BuyTile_Test"
    buyTile:SetAttribute("ID", 777)
    
    local tilePart = Instance.new("Part")
    tilePart.Name = "BuyTilePart"
    tilePart.Size = Vector3.new(10, 1, 10)
    tilePart.BrickColor = BrickColor.new("Bright green")
    tilePart.Material = Enum.Material.Grass
    tilePart.Anchored = true
    tilePart.Position = Vector3.new(-140, 0, -140)
    tilePart.Parent = buyTile
    
    buyTile.PrimaryPart = tilePart
    buyTile.Parent = tycoon.Value
    
    -- Create test models
    for i = 1, CONFIG.testModels do
        local model = Instance.new("Model")
        model.Name = "TestModel_" .. i
        
        local part = Instance.new("Part")
        part.Size = Vector3.new(2, 2, 2)
        part.BrickColor = BrickColor.new("Bright blue")
        part.Material = Enum.Material.Neon
        part.Anchored = true
        part.CanCollide = true
        part.Position = Vector3.new(math.random(-150, -130), math.random(5, 10), math.random(-150, -130))
        part.Parent = model
        
        model.PrimaryPart = part
        model:SetAttribute("ID", 777 + i)
        model.Parent = buyTile
        
        table.insert(testModels, model)
    end
    
    -- Record original positions
    local originalPositions = {}
    for i, model in ipairs(testModels) do
        originalPositions[i] = model:GetPivot().Position
    end
    
    -- Call fixExistingModels
    local fixedCount = positionFixer.fixExistingModels()
    
    -- Check if positions changed
    local changed = 0
    for i, model in ipairs(testModels) do
        if model:GetPivot().Position ~= originalPositions[i] then
            changed += 1
        end
    end
    
    log("Models with changed positions:", changed, "out of", #testModels)
    log("Reported fixed count:", fixedCount)
    
    if changed > 0 then
        log("✓ fixExistingModels successfully changed model positions")
        testResults.passed += 1
        
        -- Cleanup
        buyTile:Destroy()
        return true
    else
        log("✗ fixExistingModels did not change any model positions")
        testResults.failed += 1
        
        -- Cleanup
        buyTile:Destroy()
        return false
    end
end

-- Run all tests
local function runAllTests()
    log("Starting BuyTilePositionFixer tests...")
    
    -- Reset test results
    testResults.total = 0
    testResults.passed = 0
    testResults.failed = 0
    
    -- Basic module loading tests
    testPositionFixerLoaded()
    testBuyTileSystemLoaded()
    
    -- Get a player for testing
    local player = CONFIG.testPlayerId and Players:GetPlayerByUserId(CONFIG.testPlayerId) or Players:GetPlayers()[1]
    
    if player then
        log("Using player for tests:", player.Name)
        
        -- Model positioning tests
        testModelPositioning(player)
        testModelSpawning(player)
        testFixExistingModels()
    else
        log("No player available for model tests")
    end
    
    -- Report results
    log("===== TEST RESULTS =====")
    log("Total tests:  ", testResults.total)
    log("Tests passed: ", testResults.passed)
    log("Tests failed: ", testResults.failed)
    log("Success rate: ", testResults.total > 0 and math.floor((testResults.passed / testResults.total) * 100) .. "%" or "N/A")
    log("========================")
    
    -- Report to all players
    local message = "BuyTilePositionFixer Tests: " .. 
                   testResults.passed .. "/" .. testResults.total .. " passed (" .. 
                   (testResults.total > 0 and math.floor((testResults.passed / testResults.total) * 100) or 0) .. "%)"
    
    for _, p in pairs(Players:GetPlayers()) do
        if p:FindFirstChild("PlayerGui") then
            -- Try to display test results
            pcall(function()
                local screenGui = Instance.new("ScreenGui")
                screenGui.Name = "TestResults"
                
                local textLabel = Instance.new("TextLabel")
                textLabel.Size = UDim2.new(1, 0, 0, 30)
                textLabel.Position = UDim2.new(0, 0, 0, 0)
                textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                textLabel.BackgroundTransparency = 0.5
                textLabel.TextColor3 = testResults.failed > 0 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
                textLabel.Text = message
                textLabel.TextSize = 18
                textLabel.Parent = screenGui
                
                screenGui.Parent = p.PlayerGui
                
                game:GetService("Debris"):AddItem(screenGui, 10) -- Show for 10 seconds
            end)
        end
    end
    
    return testResults.passed == testResults.total
end

-- Command to run tests
local function setupTestCommand()
    if not game:GetService("ServerScriptService"):FindFirstChild("ChatServiceRunner") then
        log("ChatServiceRunner not found, skipping test command setup")
        return
    end
    
    -- Get Chat service
    local Chat = nil
    pcall(function()
        Chat = require(game:GetService("ServerScriptService").ChatServiceRunner.ChatService)
    end)
    
    if not Chat then
        log("Failed to get Chat service, skipping test command setup")
        return
    end
    
    -- Register command
    Chat:RegisterProcessCommandsFunction("buytiletest", function(speakerName, message, channel)
        local speaker = Chat:GetSpeaker(speakerName)
        local player = speaker:GetPlayer()
        
        if not player or not player:GetRankInGroup(game.CreatorId) >= 254 then
            speaker:SendSystemMessage("You don't have permission to run this command.", channel)
            return true
        end
        
        speaker:SendSystemMessage("Running BuyTilePositionFixer tests...", channel)
        
        -- Run tests
        task.spawn(function()
            local success = runAllTests()
            if success then
                speaker:SendSystemMessage("All BuyTilePositionFixer tests passed!", channel)
            else
                speaker:SendSystemMessage("Some BuyTilePositionFixer tests failed. Check output for details.", channel)
            end
        end)
        
        return true
    end)
    
    log("Registered :buytiletest command")
end

-- Run tests on game start
if CONFIG.runOnStart then
    task.delay(CONFIG.waitDuration, function()
        runAllTests()
    end)
end

-- Set up test command
task.spawn(setupTestCommand)

-- Export functions for external use
return {
    runAllTests = runAllTests,
    testPositionFixerLoaded = testPositionFixerLoaded,
    testBuyTileSystemLoaded = testBuyTileSystemLoaded,
    testModelPositioning = testModelPositioning,
    testModelSpawning = testModelSpawning,
    testFixExistingModels = testFixExistingModels,
}
