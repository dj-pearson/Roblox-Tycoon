--[[
    ModelPositioningHelper.lua
    
    A comprehensive utility module for handling model positioning across the game.
    This module specializes in calculating and applying correct positions for models
    of different types, with robust error recovery and fallback systems.
    
    Created by: AI Assistant
    Created on: May 3, 2025
]]

local ModelPositioningHelper = {}

-- Constants
local DEFAULT_FIX_DELAY = 0.5
local PRIMARY_PART_TYPES = {"Part", "MeshPart", "BasePart", "SpawnLocation", "TrussPart"}
local IGNORE_PART_NAMES = {"Hitbox", "BoundingBox", "ClickDetector", "BillboardGui"}

-- Cache for performance
local positioningCache = {}

-- Internal helper functions
local function isValidPart(part)
    if not part:IsA("BasePart") then return false end
    
    -- Skip parts with certain names (non-visual components)
    for _, ignoreName in ipairs(IGNORE_PART_NAMES) do
        if part.Name:match(ignoreName) then
            return false
        end
    end
    
    return true
end

local function findBestPrimaryPart(model)
    if not model then return nil end
    
    -- If it already has a primary part, use it
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end
    
    local bestPart = nil
    local largestVolume = 0
    local centerPart = nil
    local centerDist = math.huge
    
    -- Calculate model center
    local modelCenter = model:GetBoundingBox().Position
    
    -- Find the largest part or the part closest to center
    for _, part in pairs(model:GetDescendants()) do
        if isValidPart(part) then
            -- Calculate part volume
            local volume = part.Size.X * part.Size.Y * part.Size.Z
            
            -- Check if this is a "main" part by name
            local isMainPart = part.Name:lower():match("main") or 
                               part.Name:lower():match("primary") or
                               part.Name:lower():match("base") or
                               part.Name:lower() == "hitbox" or
                               part.Name:lower() == model.Name:lower()
            
            if isMainPart then
                -- Prefer parts that seem to be designated as main
                return part
            end
            
            -- Calculate distance to center
            local distToCenter = (part.Position - modelCenter).Magnitude
            
            -- Update largest part if needed
            if volume > largestVolume then
                largestVolume = volume
                bestPart = part
            end
            
            -- Update center part if needed
            if distToCenter < centerDist then
                centerDist = distToCenter
                centerPart = part
            end
        end
    end
    
    -- Prefer the largest part, but if it's very far from center, use the center part
    if bestPart and centerPart and (bestPart.Position - modelCenter).Magnitude > 10 then
        return centerPart
    end
    
    return bestPart
end

-- Set a model's position properly based on its type
function ModelPositioningHelper.setModelPosition(model, cframe)
    if not model or not cframe then
        warn("ModelPositioningHelper: Invalid arguments for setModelPosition")
        return false, "Invalid arguments"
    end
    
    -- Create a unique cache key based on model and intended position
    local cacheKey = tostring(model:GetFullName()) .. "_" .. tostring(cframe)
    if positioningCache[cacheKey] then
        -- Position already set, avoid redundant operations
        return true, "Already positioned (cached)"
    end
    
    local success, message = false, ""
    
    if model:IsA("Model") then
        -- Method 1: Use PrimaryPart if available
        if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
            model:SetPrimaryPartCFrame(cframe)
            success = true
            message = "Used primary part"
        else
            -- Method 2: Find the best part to use as primary
            local bestPart = findBestPrimaryPart(model)
            
            if bestPart then
                -- Temporarily set it as primary part
                model.PrimaryPart = bestPart
                model:SetPrimaryPartCFrame(cframe)
                success = true
                message = "Used best part as primary"
            else
                -- Method 3: Use model pivot as a fallback
                local currentPivot = model:GetPivot()
                local offset = currentPivot.Position - model:GetModelCFrame().Position
                
                -- Apply position by moving all parts
                for _, part in pairs(model:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CFrame = part.CFrame - offset + cframe.Position
                    end
                end
                success = true
                message = "Used manual offset calculation"
            end
        end
    elseif model:IsA("BasePart") then
        -- Simple case: just set the CFrame directly
        model.CFrame = cframe
        success = true
        message = "Direct part positioning"
    else
        -- Unsupported model type
        warn("ModelPositioningHelper: Unsupported model type: " .. model.ClassName)
        success = false
        message = "Unsupported model type: " .. model.ClassName
    end
    
    -- Store result in cache if successful
    if success then
        positioningCache[cacheKey] = true
        model:SetAttribute("PositionFixed", true)
        model:SetAttribute("OriginalPosition", tostring(cframe.Position))
    end
    
    return success, message
end

-- Position a model at a tile with correct offset
function ModelPositioningHelper.positionAtTile(model, tile, options)
    if not model or not tile then
        warn("ModelPositioningHelper: Invalid arguments for positionAtTile")
        return false, "Invalid arguments"
    end
    
    options = options or {}
    local offsetY = options.offsetY or model:GetAttribute("OffsetY") or 0
    local offsetX = options.offsetX or model:GetAttribute("OffsetX") or 0
    local offsetZ = options.offsetZ or model:GetAttribute("OffsetZ") or 0
    local rotationY = options.rotationY or model:GetAttribute("RotationY") or 0
    
    -- Calculate the target CFrame
    local targetCFrame = tile.CFrame *
                        CFrame.new(offsetX, offsetY, offsetZ) *
                        CFrame.Angles(0, math.rad(rotationY), 0)
    
    -- Position the model
    local success, message = ModelPositioningHelper.setModelPosition(model, targetCFrame)
    
    -- If successful, store the tile reference
    if success then
        model:SetAttribute("TileID", tile:GetAttribute("ID") or tile.Name:match("%d+"))
    end
    
    return success, message
end

-- Fix positions of all models in a container
function ModelPositioningHelper.fixAllModelPositions(container, getTileFn)
    if not container then
        warn("ModelPositioningHelper: Invalid container for fixAllModelPositions")
        return 0
    end
    
    local count = 0
    
    for _, child in pairs(container:GetChildren()) do
        if (child:IsA("Model") or child:IsA("BasePart")) and not child:GetAttribute("PositionFixed") then
            -- Skip buy tiles (they should stay in place)
            if child.Name:match("^BuyTile") or child:GetAttribute("IsBuyTile") then
                continue
            end
            
            -- Get the tile for this model if a function is provided
            local tile = nil
            if getTileFn and type(getTileFn) == "function" then
                tile = getTileFn(child)
            end
            
            if tile then
                -- Position at the specific tile
                local success = ModelPositioningHelper.positionAtTile(child, tile)
                if success then
                    count = count + 1
                end
            else
                -- Use model's own attributes to position it correctly
                local posX = child:GetAttribute("PositionX") or 0
                local posY = child:GetAttribute("PositionY") or 0
                local posZ = child:GetAttribute("PositionZ") or 0
                local rotY = child:GetAttribute("RotationY") or 0
                
                -- Calculate final position
                local position = container:GetPivot().Position + Vector3.new(posX, posY, posZ)
                local rotation = CFrame.Angles(0, math.rad(rotY), 0)
                local finalCFrame = CFrame.new(position) * rotation
                
                -- Position the model
                local success = ModelPositioningHelper.setModelPosition(child, finalCFrame)
                
                if success then
                    child:SetAttribute("PositionFixed", true)
                    count = count + 1
                end
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
        if (child:IsA("Model") or child:IsA("BasePart")) and not child:GetAttribute("PositionFixed") then
            -- Wait a short delay to let the model fully load
            task.wait(fixDelay)
            
            -- Skip buy tiles
            if child.Name:match("^BuyTile") or child:GetAttribute("IsBuyTile") then
                return
            end
            
            -- Get the tile for this model if a function is provided
            local tile = nil
            if getTileFn and type(getTileFn) == "function" then
                tile = getTileFn(child)
            end
            
            if tile then
                -- Position at the specific tile
                ModelPositioningHelper.positionAtTile(child, tile)
            else
                -- Use model's own attributes to position it correctly
                local posX = child:GetAttribute("PositionX") or 0
                local posY = child:GetAttribute("PositionY") or 0
                local posZ = child:GetAttribute("PositionZ") or 0
                local rotY = child:GetAttribute("RotationY") or 0
                
                if posX ~= 0 or posY ~= 0 or posZ ~= 0 or rotY ~= 0 then
                    -- Calculate final position
                    local position = container:GetPivot().Position + Vector3.new(posX, posY, posZ)
                    local rotation = CFrame.Angles(0, math.rad(rotY), 0)
                    local finalCFrame = CFrame.new(position) * rotation
                    
                    -- Position the model
                    ModelPositioningHelper.setModelPosition(child, finalCFrame)
                end
            end
        end
    end)
end

-- Clear the positioning cache (useful for memory management)
function ModelPositioningHelper.clearCache()
    table.clear(positioningCache)
end

return ModelPositioningHelper
