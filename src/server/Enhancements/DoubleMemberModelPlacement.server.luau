--[[
    DoubleMemberModelPlacement.server.luau
    
    This script ensures that the DoubleMember model is properly placed in the workspace
    if it exists in ServerStorage but isn't already in the workspace.
]]

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local function placeDoubleMemberModel()
    -- Check if the model already exists in workspace
    if Workspace:FindFirstChild("DoubleMember") then
        print("DoubleMember model already exists in workspace")
        return
    end
    
    -- Find the DoubleMember model in ServerStorage
    local gymPartsFolder = ServerStorage:FindFirstChild("GymParts")
    if not gymPartsFolder then
        warn("GymParts folder not found in ServerStorage")
        return
    end
    
    local doubleMemberModel = gymPartsFolder:FindFirstChild("DoubleMember")
    if not doubleMemberModel then
        warn("DoubleMember model not found in ServerStorage > GymParts")
        return
    end
    
    -- Clone the model to workspace
    local modelClone = doubleMemberModel:Clone()
    modelClone.Parent = Workspace
    
    -- Position the model at a reasonable location if it doesn't have a position
    if modelClone:IsA("Model") and not modelClone.PrimaryPart then
        -- Find a suitable part to use as reference
        local referencePart
        for _, part in ipairs(modelClone:GetDescendants()) do
            if part:IsA("BasePart") then
                referencePart = part
                break
            end
        end
        
        if referencePart then
            -- Place it at a reasonable position - adjust as needed for your game
            referencePart.Position = Vector3.new(0, 5, 0)
        end
    end
    
    print("DoubleMember model placed in workspace")
end

-- Run when the script starts
placeDoubleMemberModel()
