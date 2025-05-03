--!strict
--[[
    ModelPositioningHelper.luau
    A helper module to correctly position models at their target locations.
    
    Created: May 3, 2025
    
    This module provides reliable model positioning functionality,
    resolving issues with models that lack a PrimaryPart.
]]

local ModelPositioningHelper = {}

-- Configuration
local DEFAULT_FIX_DELAY = 0.1 -- Delay before fixing newly created models

-- Function to safely set a model's position
-- Returns success (boolean) and a message (string)
function ModelPositioningHelper.setModelPosition(model, targetCFrame)
    if not model or not targetCFrame then
        return false, "Invalid model or targetCFrame"
    end
    
    -- Handle different types of instances
    if model:IsA("Model") then
        return ModelPositioningHelper.positionModel(model, targetCFrame)
    elseif model:IsA("BasePart") then
        model.CFrame = targetCFrame
        return true, "Successfully positioned BasePart"
    else
        return false, "Unsupported object type: " .. model.ClassName
    end
end

-- Function specifically for positioning models
function ModelPositioningHelper.positionModel(model, targetCFrame)
    if model.PrimaryPart then
        -- If model already has a PrimaryPart, use it
        model:SetPrimaryPartCFrame(targetCFrame)
        return true, "Used existing PrimaryPart"
    else
        -- Try to find a suitable part to use as PrimaryPart
        local bestPart = ModelPositioningHelper.findBestPrimaryPart(model)
        
        if bestPart then
            -- Temporarily set as PrimaryPart and position the model
            model.PrimaryPart = bestPart
            model:SetPrimaryPartCFrame(targetCFrame)
            return true, "Used temporary PrimaryPart"
        else
            -- For models without parts, we can't position them directly
            return false, "No suitable parts found in model"
        end
    end
end

-- Find the best part to use as a PrimaryPart
function ModelPositioningHelper.findBestPrimaryPart(model)
    local bestPart = nil
    local bestScore = 0
    
    -- Special handling for different model types
    local modelType = model:GetAttribute("ModelType") or ""
    
    for _, part in pairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            local score = 0
            
            -- Calculate score based on part properties
            local volume = part.Size.X * part.Size.Y * part.Size.Z
            score = volume -- Base score is volume
            
            -- Prefer parts that are:
            -- 1. Near the center of the model
            -- 2. Named meaningfully
            -- 3. Larger in size
            if part.Name:lower():find("primary") or part.Name:lower():find("main") then
                score = score * 3 -- Boost score for parts with suggestive names
            end
            
            if part.Name:lower():find("base") then
                score = score * 2 -- Boost score for base parts
            end
            
            -- Special handling for different model types
            if modelType == "Wall" and part.Size.Y > part.Size.X and part.Size.Y > part.Size.Z then
                score = score * 2 -- Prefer taller parts for walls
            elseif modelType == "Floor" and part.Size.Y < part.Size.X and part.Size.Y < part.Size.Z then
                score = score * 2 -- Prefer flatter parts for floors
            end
            
            if score > bestScore then
                bestPart = part
                bestScore = score
            end
        end
    end
    
    return bestPart
end

-- Position all child models within a parent (like a tycoon structure)
function ModelPositioningHelper.positionChildModels(parent, offsetVector)
    offsetVector = offsetVector or Vector3.new(0, 0, 0)
    local count = 0
    
    for _, child in pairs(parent:GetChildren()) do
        if child:IsA("Model") and not child:GetAttribute("PositionFixed") then
            local baseCFrame = CFrame.new(parent:GetPivot().Position + offsetVector)
            
            -- Get custom positioning info if available
            local posX = child:GetAttribute("PositionX") or 0
            local posY = child:GetAttribute("PositionY") or 0
            local posZ = child:GetAttribute("PositionZ") or 0
            local rotY = child:GetAttribute("RotationY") or 0
            
            -- Calculate final position
            local position = baseCFrame.Position + Vector3.new(posX, posY, posZ)
            local rotation = CFrame.Angles(0, math.rad(rotY), 0)
            local finalCFrame = CFrame.new(position) * rotation
            
            -- Position the model
            local success, _ = ModelPositioningHelper.setModelPosition(child, finalCFrame)
            
            if success then
                child:SetAttribute("PositionFixed", true)
                count = count + 1
            end
        end
    end
    
    return count
end

-- Auto-fix model positions after they're created
function ModelPositioningHelper.setupAutoFix(container, getTileFn, fixDelay)
    fixDelay = fixDelay or DEFAULT_FIX_DELAY
    
    -- Watch for new children being added
    container.ChildAdded:Connect(function(child)
        if child:IsA("Model") then
            -- Allow the model to fully initialize
            task.delay(fixDelay, function()
                -- Skip if already fixed
                if child:GetAttribute("PositionFixed") then
                    return
                end
                
                -- Find the associated tile
                local tileObj = nil
                if typeof(getTileFn) == "function" then
                    tileObj = getTileFn(child)
                end
                
                if tileObj then
                    -- Get position info from tile
                    local tilePosition = tileObj:GetPivot().Position
                    
                    -- Get rotation and offset from model attributes
                    local rotY = child:GetAttribute("RotationY") or 0
                    local offsetX = child:GetAttribute("OffsetX") or 0
                    local offsetY = child:GetAttribute("OffsetY") or 0
                    local offsetZ = child:GetAttribute("OffsetZ") or 0
                    
                    -- Calculate final position
                    local rotation = CFrame.Angles(0, math.rad(rotY), 0)
                    local position = tilePosition + Vector3.new(offsetX, offsetY, offsetZ)
                    local finalCFrame = CFrame.new(position) * rotation
                    
                    -- Apply position
                    local success, _ = ModelPositioningHelper.setModelPosition(child, finalCFrame)
                    
                    if success then
                        child:SetAttribute("PositionFixed", true)
                    end
                end
            end)
        end
    end)
end

return ModelPositioningHelper
