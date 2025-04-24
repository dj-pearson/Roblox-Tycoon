--[[
    AttributeSetup.server.luau
    This script provides utility functions to easily add attributes to models in the workspace.
    Used for setting up interactive elements and other game objects.
]]

local CollectionService = game:GetService("CollectionService")
local InteractiveElement = require(script.Parent.InteractiveElement)

local AttributeSetup = {}

-- Setup a model as an interactive element with common configurations
function AttributeSetup.setupInteractiveElement(model, interactionType, specializationType, maxUsers)
    if not model:IsA("Model") then
        warn("AttributeSetup: Attempted to setup a non-model as an interactive element:", model:GetFullName())
        return nil
    end
    
    -- Default values
    interactionType = interactionType or "Default"
    maxUsers = maxUsers or 1
    
    -- Configure the interactive element
    return InteractiveElement.setup(model, {
        interactionType = interactionType,
        specializationType = specializationType,
        maxUsers = maxUsers,
        interactionPointOffset = Vector3.new(0, 2, 0) -- Default offset above model
    })
end

-- Setup a seat (bench, chair, etc.)
function AttributeSetup.setupSeat(model, specializationType, maxUsers)
    return AttributeSetup.setupInteractiveElement(model, "Seat", specializationType, maxUsers or 1)
end

-- Setup a cardio machine (treadmill, bike, etc.)
function AttributeSetup.setupCardioEquipment(model, maxUsers)
    local result = AttributeSetup.setupInteractiveElement(model, "Cardio", "Cardio", maxUsers or 1)
    if result then
        CollectionService:AddTag(model, "Cardio")
    end
    return result
end

-- Setup a weight machine or free weights
function AttributeSetup.setupWeightEquipment(model, maxUsers)
    local result = AttributeSetup.setupInteractiveElement(model, "Weights", "Weights", maxUsers or 1)
    if result then
        CollectionService:AddTag(model, "Weights")
    end
    return result
end

-- Setup a spa element (sauna, massage table, etc.)
function AttributeSetup.setupSpaElement(model, maxUsers)
    local result = AttributeSetup.setupInteractiveElement(model, "Spa", "Spa", maxUsers or 1)
    if result then
        CollectionService:AddTag(model, "Spa")
    end
    return result
end

-- Setup floor parts for NPC navigation
function AttributeSetup.setupFloor(floorPart)
    if not floorPart:IsA("BasePart") then
        warn("AttributeSetup: Attempted to setup a non-BasePart as a floor:", floorPart:GetFullName())
        return nil
    end
    
    floorPart:SetAttribute("IsFloor", true)
    return floorPart
end

-- Process models in a folder to set them up as interactive elements
function AttributeSetup.processFolder(folder, setupFunctionName, ...)
    if not folder:IsA("Folder") and not folder:IsA("Model") then
        warn("AttributeSetup: processFolder expected a Folder or Model, got:", folder:GetFullName())
        return
    end
    
    local setupFunction = AttributeSetup[setupFunctionName]
    if not setupFunction then
        warn("AttributeSetup: Invalid setup function name:", setupFunctionName)
        return
    end
    
    -- Process all models in the folder
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then
            setupFunction(child, ...)
        end
    end
end

-- Main initialization function
function AttributeSetup.init()
    print("AttributeSetup: Initializing...")
    
    -- Example automatic setup - uncomment and customize as needed
    -- local cardioFolder = workspace:FindFirstChild("CardioEquipment")
    -- if cardioFolder then
    --     AttributeSetup.processFolder(cardioFolder, "setupCardioEquipment", 1)
    -- end
    
    -- More automatic setups can be added here
    
    print("AttributeSetup: Initialization complete.")
end

return AttributeSetup
