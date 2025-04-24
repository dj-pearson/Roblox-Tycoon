--[[
    NPCInteractionTest.server.luau
    This script tests the NPC interaction system by setting up test models and spawning NPCs.
]]

local NPCMovement = require(script.Parent.NPC_Movement)
local AttributeSetup = require(script.Parent.AttributeSetup)

local NPCInteractionTest = {}

-- Function to create a test NPC
local function createTestNPC(position, specialization)
    -- Create a basic humanoid model
    local npc = Instance.new("Model")
    npc.Name = "TestNPC_" .. specialization
    
    local humanoidRootPart = Instance.new("Part")
    humanoidRootPart.Name = "HumanoidRootPart"
    humanoidRootPart.Size = Vector3.new(2, 2, 1)
    humanoidRootPart.Position = position
    humanoidRootPart.Anchored = false
    humanoidRootPart.CanCollide = true
    humanoidRootPart.Parent = npc
    
    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = npc
    
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1, 1, 1)
    head.Position = position + Vector3.new(0, 1.5, 0)
    head.Parent = npc
    
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.Position = position + Vector3.new(0, 0, 0)
    torso.Parent = npc
    
    -- Create stats
    local stats = Instance.new("Folder")
    stats.Name = "Stats"
    stats.Parent = npc
    
    local energy = Instance.new("NumberValue")
    energy.Name = "Energy"
    energy.Value = 100
    energy.Parent = stats
    
    local strength = Instance.new("NumberValue")
    strength.Name = "Strength"
    strength.Value = 50
    strength.Parent = stats
    
    local endurance = Instance.new("NumberValue")
    endurance.Name = "Endurance"
    endurance.Value = 50
    endurance.Parent = stats
    
    -- Set specialization preference
    npc:SetAttribute("SpecializationPreference", specialization)
    
    -- Setup NPC with the movement system
    NPCMovement.setupNPC(npc)
    
    return npc
end

-- Function to create a test interactive element
local function createTestInteractiveElement(position, interactionType, specializationType)
    -- Create a basic model
    local model = Instance.new("Model")
    model.Name = interactionType .. "_" .. specializationType
    
    local primaryPart = Instance.new("Part")
    primaryPart.Name = "PrimaryPart"
    primaryPart.Size = Vector3.new(3, 1, 3)
    primaryPart.Position = position
    primaryPart.Anchored = true
    primaryPart.CanCollide = true
    primaryPart.Parent = model
    
    model.PrimaryPart = primaryPart
    
    -- Setup as an interactive element
    AttributeSetup.setupInteractiveElement(model, interactionType, specializationType, 1)
    
    -- Add equipment ID for caching
    model:SetAttribute("EquipmentId", interactionType .. "_" .. specializationType)
    
    return model
end

-- Run a basic test of the NPC interaction system
function NPCInteractionTest.runTest(tycoonModel)
    print("NPCInteractionTest: Starting test...")
    
    -- Create a test tycoon if one wasn't provided
    local testTycoon = tycoonModel or Instance.new("Model")
    testTycoon.Name = "TestTycoon"
    
    if not tycoonModel then
        -- Create a basic floor
        local floor = Instance.new("Part")
        floor.Name = "Floor"
        floor.Size = Vector3.new(50, 1, 50)
        floor.Position = Vector3.new(0, 0, 0)
        floor.Anchored = true
        floor.CanCollide = true
        floor.Parent = testTycoon
        
        AttributeSetup.setupFloor(floor)
        
        -- Add to workspace if it's our test tycoon
        testTycoon.Parent = workspace
    end
    
    -- Create NPCs folder
    local npcsFolder = Instance.new("Folder")
    npcsFolder.Name = "NPCs"
    npcsFolder.Parent = testTycoon
    
    -- Create test interactive elements
    local cardioElement = createTestInteractiveElement(
        Vector3.new(5, 1, 5), 
        "Cardio", 
        "Cardio"
    )
    cardioElement.Parent = testTycoon
    
    local weightElement = createTestInteractiveElement(
        Vector3.new(-5, 1, 5), 
        "Weights", 
        "Weights"
    )
    weightElement.Parent = testTycoon
    
    local spaElement = createTestInteractiveElement(
        Vector3.new(0, 1, -5), 
        "Spa", 
        "Spa"
    )
    spaElement.Parent = testTycoon
    
    local seatElement = createTestInteractiveElement(
        Vector3.new(10, 1, 0), 
        "Seat", 
        nil
    )
    seatElement.Parent = testTycoon
    
    -- Create test NPCs with different specializations
    local npc1 = createTestNPC(Vector3.new(0, 5, 0), "Cardio")
    npc1.Parent = npcsFolder
    
    local npc2 = createTestNPC(Vector3.new(3, 5, 3), "Weights")
    npc2.Parent = npcsFolder
    
    local npc3 = createTestNPC(Vector3.new(-3, 5, -3), "Spa")
    npc3.Parent = npcsFolder
    
    print("NPCInteractionTest: Test setup complete. NPCs and interactive elements created.")
    print("NPCInteractionTest: Observe NPCs to verify they interact with the elements correctly.")
    
    return testTycoon
end

return NPCInteractionTest
