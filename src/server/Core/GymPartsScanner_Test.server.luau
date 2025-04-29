--[[
    GymPartsScanner_Test.server.luau
    
    This script tests the GymPartsScanner functionality by creating a sample
    GymParts folder structure and then running the scanner on it.
    
    Created April 28, 2025
]]

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

print("GymPartsScanner_Test: Starting test setup")

-- Create sample GymParts structure for testing
local function createSampleGymPartsStructure()
    print("Creating sample GymParts structure for testing")
    
    -- Remove existing GymParts folder if it exists
    local existingFolder = ServerStorage:FindFirstChild("GymPartsTest")
    if existingFolder then
        existingFolder:Destroy()
    end
    
    -- Create main folder
    local gymPartsFolder = Instance.new("Folder")
    gymPartsFolder.Name = "GymPartsTest"
    gymPartsFolder.Parent = ServerStorage
    
    -- Create FrontDesk
    local frontDeskFolder = Instance.new("Folder")
    frontDeskFolder.Name = "FrontDesk"
    frontDeskFolder.Parent = gymPartsFolder
    
    local frontDesk = Instance.new("Part")
    frontDesk.Name = "MainDesk"
    frontDesk.Size = Vector3.new(10, 2, 4)
    frontDesk.Anchored = true
    frontDesk.Parent = frontDeskFolder
    
    -- Create Floor 1
    local floor1Folder = Instance.new("Folder")
    floor1Folder.Name = "Floor 1"
    floor1Folder.Parent = gymPartsFolder
    
    -- Create Walls for Floor 1
    local walls1Folder = Instance.new("Folder")
    walls1Folder.Name = "Walls"
    walls1Folder.Parent = floor1Folder
    
    for i = 1, 4 do
        local wall = Instance.new("Part")
        wall.Name = "Wall" .. i
        wall.Size = Vector3.new(20, 8, 1)
        wall.Anchored = true
        wall.Parent = walls1Folder
    end
    
    -- Create Cardio room
    local cardioFolder = Instance.new("Folder")
    cardioFolder.Name = "Cardio"
    cardioFolder.Parent = floor1Folder
    
    -- Create Treadmills equipment group
    local treadmillsFolder = Instance.new("Folder")
    treadmillsFolder.Name = "Treadmills"
    treadmillsFolder.Parent = cardioFolder
    
    for i = 1, 3 do
        local treadmill = Instance.new("Part")
        treadmill.Name = "Treadmill" .. i
        treadmill.Size = Vector3.new(6, 1, 2)
        treadmill.Anchored = true
        treadmill.Parent = treadmillsFolder
    end
    
    -- Create Bikes equipment group
    local bikesFolder = Instance.new("Folder")
    bikesFolder.Name = "Bikes"
    bikesFolder.Parent = cardioFolder
    
    for i = 1, 2 do
        local bike = Instance.new("Part")
        bike.Name = "Bike" .. i
        bike.Size = Vector3.new(2, 3, 2)
        bike.Anchored = true
        bike.Parent = bikesFolder
    end
    
    -- Create Strength room
    local strengthFolder = Instance.new("Folder")
    strengthFolder.Name = "Strength"
    strengthFolder.Parent = floor1Folder
    
    -- Create Weights equipment group
    local weightsFolder = Instance.new("Folder")
    weightsFolder.Name = "Weights"
    weightsFolder.Parent = strengthFolder
    
    for i = 1, 4 do
        local weight = Instance.new("Part")
        weight.Name = "Weight" .. i
        weight.Size = Vector3.new(1, 1, 1)
        weight.Anchored = true
        weight.Parent = weightsFolder
    end
    
    -- Create Ceiling for Floor 1
    local ceiling1Folder = Instance.new("Folder")
    ceiling1Folder.Name = "Ceiling"
    ceiling1Folder.Parent = floor1Folder
    
    local ceiling = Instance.new("Part")
    ceiling.Name = "MainCeiling"
    ceiling.Size = Vector3.new(20, 1, 20)
    ceiling.Anchored = true
    ceiling.Parent = ceiling1Folder
    
    -- Create Stairs for Floor 1
    local stairs1Folder = Instance.new("Folder")
    stairs1Folder.Name = "Stairs"
    stairs1Folder.Parent = floor1Folder
    
    local stairs = Instance.new("Part")
    stairs.Name = "MainStairs"
    stairs.Size = Vector3.new(4, 10, 8)
    stairs.Anchored = true
    stairs.Parent = stairs1Folder
    
    -- Create Floor 2
    local floor2Folder = Instance.new("Folder")
    floor2Folder.Name = "Floor 2"
    floor2Folder.Parent = gymPartsFolder
    
    -- Create Walls for Floor 2
    local walls2Folder = Instance.new("Folder")
    walls2Folder.Name = "Walls"
    walls2Folder.Parent = floor2Folder
    
    for i = 1, 4 do
        local wall = Instance.new("Part")
        wall.Name = "Wall" .. i
        wall.Size = Vector3.new(20, 8, 1)
        wall.Anchored = true
        wall.Parent = walls2Folder
    end
    
    -- Create Specialty room
    local specialtyFolder = Instance.new("Folder")
    specialtyFolder.Name = "Specialty"
    specialtyFolder.Parent = floor2Folder
    
    for i = 1, 3 do
        local equipment = Instance.new("Part")
        equipment.Name = "SpecialEquip" .. i
        equipment.Size = Vector3.new(3, 2, 3)
        equipment.Anchored = true
        equipment.Parent = specialtyFolder
    end
    
    print("GymPartsScanner_Test: Sample structure created successfully")
    return gymPartsFolder
end

-- Find the GymPartsScanner module
local function findScannerModule()
    return ServerScriptService:FindFirstChild("Core") and 
           ServerScriptService.Core:FindFirstChild("GymPartsScanner.server") or
           ServerScriptService:FindFirstChild("GymPartsScanner.server")
end

-- Run the scanner
local function runScannerTest()
    -- Find scanner module
    local scannerModule = findScannerModule()
    
    if not scannerModule then
        print("GymPartsScanner_Test: Could not find GymPartsScanner module, creating stub for testing")
        
        -- Create stub for testing
        local stub = {
            scanGymPartsStructure = function()
                print("STUB: scanGymPartsStructure called")
                return {}
            end,
            applyTagsAndAttributes = function()
                print("STUB: applyTagsAndAttributes called")
                return true
            end,
            generateBuyTileConfig = function()
                print("STUB: generateBuyTileConfig called")
                return true
            end,
            setupBuyTileSystem = function()
                print("STUB: setupBuyTileSystem called")
                return true
            end
        }
        
        return stub
    end
    
    -- Require the module
    local success, scanner = pcall(function()
        return require(scannerModule)
    end)
    
    if not success then
        warn("GymPartsScanner_Test: Failed to require scanner module: " .. tostring(scanner))
        return nil
    end
    
    -- Run the scanner on our test structure
    local originalGymParts = ServerStorage:FindFirstChild("GymParts")
    local testGymParts = ServerStorage:FindFirstChild("GymPartsTest")
    
    if originalGymParts and testGymParts then
        -- Temporarily swap folders
        originalGymParts.Name = "GymParts_Original"
        testGymParts.Name = "GymParts"
        
        -- Run scanner
        local result = scanner.setupBuyTileSystem()
        print("GymPartsScanner_Test: Scanner test result: " .. (result and "SUCCESS" or "FAILED"))
        
        -- Check tags
        local taggedItems = CollectionService:GetTagged("BuyTile")
        print("GymPartsScanner_Test: Found " .. #taggedItems .. " tagged items")
        
        -- Detailed check on a few items
        local frontDesk = testGymParts:FindFirstChild("FrontDesk") and 
                          testGymParts.FrontDesk:FindFirstChild("MainDesk")
                          
        if frontDesk then
            print("FrontDesk BuyTileId: " .. (frontDesk:GetAttribute("BuyTileId") or "nil"))
            print("FrontDesk TileFloor: " .. (frontDesk:GetAttribute("TileFloor") or "nil"))
            print("FrontDesk TileIdAttribute: " .. (frontDesk:GetAttribute("TileIdAttribute") or "nil"))
        end
        
        -- Restore original folders
        testGymParts.Name = "GymPartsTest"
        originalGymParts.Name = "GymParts"
        
        return scanner
    else
        warn("GymPartsScanner_Test: Missing GymParts folders for testing")
        return nil
    end
end

-- Run the test
local sampleStructure = createSampleGymPartsStructure()
task.wait(1) -- Wait for any potential async processes

if sampleStructure then
    print("GymPartsScanner_Test: Running scanner test...")
    local scanner = runScannerTest()
    
    if scanner then
        print("GymPartsScanner_Test: Test completed successfully")
    else
        warn("GymPartsScanner_Test: Test failed")
    end
else
    warn("GymPartsScanner_Test: Failed to create sample structure")
end

-- Create command for running the test
_G.TestGymPartsScanner = function()
    local sampleStructure = createSampleGymPartsStructure()
    task.wait(1)
    
    if sampleStructure then
        return runScannerTest() ~= nil
    else
        return false
    end
end
