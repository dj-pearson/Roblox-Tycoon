--[[
    EquipmentBoundingBox.luau
    
    A utility module for creating and managing bounding boxes for gym equipment.
    These bounding boxes define the space each piece of equipment occupies and
    helps with equipment placement and upgrades.
    
    Author: Created April 2025
]]

local EquipmentBoundingBox = {}

local DEBUG_VISIBLE = false -- Set to true to see bounding boxes during development

-- Create a bounding box for a model or part
function EquipmentBoundingBox.CreateBoundingBox(object, name)
    if not object then return nil end
    
    -- Calculate bounds
    local bounds = EquipmentBoundingBox.CalculateBounds(object)
    if not bounds then
        return nil
    end
    
    local center = bounds.CFrame.Position
    local size = bounds.Size
    
    -- Create the bounding box part
    local box = Instance.new("Part")
    box.Name = "BoundingBox_" .. (name or object.Name)
    box.Anchored = true
    box.CanCollide = false
    box.Size = size * 1.05 -- Slightly larger than the actual object
    box.CFrame = bounds.CFrame
    box.Transparency = DEBUG_VISIBLE and 0.8 or 1 -- Invisible unless debugging
    box.Material = Enum.Material.SmoothPlastic
    box.BrickColor = BrickColor.new("Bright red")
    
    -- Set attributes
    box:SetAttribute("isBoundingBox", true)
    box:SetAttribute("forObject", object.Name)
    
    return box
end

-- Calculate the bounds of a model or part
function EquipmentBoundingBox.CalculateBounds(object)
    if not object then return nil end
    
    local parts = {}
    
    -- Collect all parts
    if object:IsA("Model") then
        for _, child in ipairs(object:GetDescendants()) do
            if child:IsA("BasePart") then
                table.insert(parts, child)
            end
        end
    elseif object:IsA("BasePart") then
        table.insert(parts, object)
    else
        return nil -- Not a valid object type
    end
    
    if #parts == 0 then
        return nil -- No parts found
    end
    
    -- Calculate bounds
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    
    for _, part in ipairs(parts) do
        -- Get part corners
        local size = part.Size * 0.5
        local cf = part.CFrame
        
        for _, corner in ipairs({
            Vector3.new(-size.X, -size.Y, -size.Z),
            Vector3.new(-size.X, -size.Y,  size.Z),
            Vector3.new(-size.X,  size.Y, -size.Z),
            Vector3.new(-size.X,  size.Y,  size.Z),
            Vector3.new( size.X, -size.Y, -size.Z),
            Vector3.new( size.X, -size.Y,  size.Z),
            Vector3.new( size.X,  size.Y, -size.Z),
            Vector3.new( size.X,  size.Y,  size.Z)
        }) do
            local worldPos = cf * corner
            
            minX = math.min(minX, worldPos.X)
            minY = math.min(minY, worldPos.Y)
            minZ = math.min(minZ, worldPos.Z)
            
            maxX = math.max(maxX, worldPos.X)
            maxY = math.max(maxY, worldPos.Y)
            maxZ = math.max(maxZ, worldPos.Z)
        end
    end
    
    -- Calculate center and size
    local center = Vector3.new(
        minX + (maxX - minX) * 0.5,
        minY + (maxY - minY) * 0.5,
        minZ + (maxZ - minZ) * 0.5
    )
    
    local size = Vector3.new(
        maxX - minX,
        maxY - minY,
        maxZ - minZ
    )
    
    -- Get the orientation from the object if it's a model with a PrimaryPart
    local orientation
    if object:IsA("Model") and object.PrimaryPart then
        orientation = object.PrimaryPart.CFrame - object.PrimaryPart.CFrame.Position
    else
        -- Default to identity rotation
        orientation = CFrame.identity
    end
    
    local boundsCFrame = CFrame.new(center) * orientation
    
    return {
        CFrame = boundsCFrame,
        Size = size,
        Min = Vector3.new(minX, minY, minZ),
        Max = Vector3.new(maxX, maxY, maxZ)
    }
end

-- Generate bounding boxes for all equipment in a tycoon
function EquipmentBoundingBox.GenerateEquipmentBoundingBoxes(tycoon, equipmentFolder, serverStorage)
    if not tycoon then return end
    
    local boundingBoxesFolder = tycoon:FindFirstChild("EquipmentBoundingBoxes")
    if not boundingBoxesFolder then
        boundingBoxesFolder = Instance.new("Folder")
        boundingBoxesFolder.Name = "EquipmentBoundingBoxes"
        boundingBoxesFolder.Parent = tycoon
    end
    
    -- Process equipment folder if provided
    if equipmentFolder then
        for _, equipment in ipairs(equipmentFolder:GetChildren()) do
            -- Skip if already has a bounding box
            if boundingBoxesFolder:FindFirstChild("BoundingBox_" .. equipment.Name) then
                continue
            end
            
            -- Create bounding box
            local box = EquipmentBoundingBox.CreateBoundingBox(equipment)
            if box then
                box.Parent = boundingBoxesFolder
            end
        end
    end
    
    -- Look for equipment in the tycoon that might not be in the equipment folder
    for _, child in ipairs(tycoon:GetDescendants()) do
        -- Only look at models and parts with specific attributes
        if (child:IsA("Model") or child:IsA("BasePart")) and 
           child:GetAttribute("equipmentType") and 
           not boundingBoxesFolder:FindFirstChild("BoundingBox_" .. child.Name) then
            
            local box = EquipmentBoundingBox.CreateBoundingBox(child)
            if box then
                box.Parent = boundingBoxesFolder
            end
        end
    end
    
    return boundingBoxesFolder
end

-- Get the bounding box for a specific equipment type
function EquipmentBoundingBox.GetBoundingBox(tycoon, equipmentName)
    if not tycoon or not equipmentName then return nil end
    
    local boundingBoxesFolder = tycoon:FindFirstChild("EquipmentBoundingBoxes")
    if not boundingBoxesFolder then return nil end
    
    -- Look for exact match first
    local box = boundingBoxesFolder:FindFirstChild("BoundingBox_" .. equipmentName)
    if box then return box end
    
    -- Look for box with matching forObject attribute
    for _, child in ipairs(boundingBoxesFolder:GetChildren()) do
        if child:GetAttribute("forObject") == equipmentName then
            return child
        end
    end
    
    return nil
end

-- Get the transform for a bounding box
function EquipmentBoundingBox.GetBoundingBoxTransform(tycoon, equipmentName)
    local box = EquipmentBoundingBox.GetBoundingBox(tycoon, equipmentName)
    if box and box:IsA("BasePart") then
        return box.CFrame
    end
    return nil
end

-- Check if a position is within a bounding box
function EquipmentBoundingBox.IsPositionInBox(box, position)
    if not box or not box:IsA("BasePart") then return false end
    
    -- Transform position to box's local space
    local localPos = box.CFrame:PointToObjectSpace(position)
    local halfSize = box.Size * 0.5
    
    -- Check if position is inside box bounds
    return math.abs(localPos.X) <= halfSize.X and
           math.abs(localPos.Y) <= halfSize.Y and
           math.abs(localPos.Z) <= halfSize.Z
end

-- Show or hide all bounding boxes in a tycoon
function EquipmentBoundingBox.VisualizeBoxes(tycoon, show)
    if not tycoon then return end
    
    local transparency = show and 0.8 or 1
    local boundingBoxesFolder = tycoon:FindFirstChild("EquipmentBoundingBoxes")
    
    if boundingBoxesFolder then
        for _, box in ipairs(boundingBoxesFolder:GetChildren()) do
            if box:IsA("BasePart") then
                box.Transparency = transparency
            end
        end
    end
    
    DEBUG_VISIBLE = show
end

-- Clean up all bounding boxes in a tycoon
function EquipmentBoundingBox.CleanupBoxes(tycoon)
    if not tycoon then return end
    
    local boundingBoxesFolder = tycoon:FindFirstChild("EquipmentBoundingBoxes")
    if boundingBoxesFolder then
        boundingBoxesFolder:Destroy()
    end
end

return EquipmentBoundingBox