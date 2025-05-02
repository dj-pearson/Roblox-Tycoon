--!strict
--[[
    BuyTilePositionFixer.server.luau
    Fixes model positioning issues in the BuyTile system
    
    Created: April 29, 2025
]]

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Debug printing function
local function debugPrint(...)
    print("[BuyTilePositionFixer]", ...)
end

-- Find BuyTileSystem module
local function findBuyTileSystem()
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("src"):FindFirstChild("server"):FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("src"):FindFirstChild("server"):FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("Server"):FindFirstChild("Core")
    }
    
    for _, path in ipairs(searchPaths) do
        if path and path:FindFirstChild("BuyTileSystem") then
            local success, module = pcall(function()
                return require(path.BuyTileSystem)
            end)
            
            if success and typeof(module) == "table" then
                debugPrint("Found BuyTileSystem at:", path.BuyTileSystem:GetFullName())
                return module
            end
        end
    end
    
    debugPrint("Could not find BuyTileSystem module")
    return nil
end

-- Apply fixes to a model's position at a tile
local function fixModelPosition(model, tileObj)
    if not model or not tileObj then
        debugPrint("Invalid model or tile object provided")
        return
    end
    
    debugPrint("Fixing position for model:", model:GetFullName())
    
    -- Get model attributes or use defaults
    local offsetY = model:GetAttribute("OffsetY") or 0
    local offsetX = model:GetAttribute("OffsetX") or 0
    local offsetZ = model:GetAttribute("OffsetZ") or 0
    local rotationY = model:GetAttribute("RotationY") or 0
    
    -- Check if we have an OriginalPosition attribute
    local originalPosition = nil
    if model:GetAttribute("OriginalPosition") then
        local posStr = model:GetAttribute("OriginalPosition")
        local x, y, z = posStr:match("([-0-9.]+), ([-0-9.]+), ([-0-9.]+)")
        if x and y and z then
            originalPosition = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
            debugPrint("Using stored original position:", tostring(originalPosition))
        end
    end
    
    -- Create adjusted CFrame
    local tileCFrame = tileObj.CFrame or tileObj:GetPivot()
    local adjustedCFrame = nil
    
    if originalPosition then
        -- Use original position with tile's Y position to maintain height
        adjustedCFrame = CFrame.new(
            originalPosition.X, 
            tileCFrame.Position.Y + offsetY, 
            originalPosition.Z
        ) * CFrame.Angles(0, math.rad(rotationY), 0)
    else
        -- Use tile position with offsets
        adjustedCFrame = tileCFrame * CFrame.new(offsetX, offsetY, offsetZ) * CFrame.Angles(0, math.rad(rotationY), 0)
    end
    
    debugPrint("Original position:", tostring(model:GetPivot().Position))
    debugPrint("Tile position:", tostring(tileCFrame.Position))
    debugPrint("Applied offsets - X:", offsetX, "Y:", offsetY, "Z:", offsetZ, "Rotation Y:", rotationY)
    
    -- Apply position and rotation based on model type
    if model:IsA("Model") then
        if model.PrimaryPart then
            debugPrint("Using PrimaryPart for positioning:", model.PrimaryPart.Name)
            model:SetPrimaryPartCFrame(adjustedCFrame)
        else
            -- Find the best part to use as primary part
            debugPrint("No primary part set, looking for suitable part")
            local bestPart = nil
            local largestVolume = 0
            
            for _, part in pairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    local volume = part.Size.X * part.Size.Y * part.Size.Z
                    if volume > largestVolume then
                        bestPart = part
                        largestVolume = volume
                    end
                end
            end
            
            if bestPart then
                debugPrint("Setting", bestPart.Name, "as primary part")
                model.PrimaryPart = bestPart
                model:SetPrimaryPartCFrame(adjustedCFrame)
            else
                -- Fallback for models with no parts
                debugPrint("No suitable parts found for primary part, using PivotTo")
                model:PivotTo(adjustedCFrame)
            end
        end
    else
        -- Handle single parts
        debugPrint("Positioning single part")
        model.CFrame = adjustedCFrame
    end
    
    -- Store the position for future reference if not already stored
    if not model:GetAttribute("OriginalPosition") and not originalPosition then
        model:SetAttribute("OriginalPosition", tostring(adjustedCFrame.Position))
        debugPrint("Stored original position:", tostring(adjustedCFrame.Position))
    end
    
    debugPrint("New position:", tostring(model:GetPivot().Position))
}
end

-- Fix existing models in the workspace
local function fixExistingModels()
    debugPrint("Starting to fix existing models in workspace...")
    
    -- Find all BuyTile objects in the workspace
    local buyTiles = {}
    local modelsFixed = 0
    
    -- Search for BuyTiles in all players' tycoons
    for _, player in pairs(game.Players:GetPlayers()) do
        local tycoon = player:FindFirstChild("Tycoon")
        if tycoon and tycoon.Value then
            -- Look for any object that could be a BuyTile
            for _, obj in pairs(tycoon.Value:GetDescendants()) do
                if obj.Name:match("^BuyTile") or obj:GetAttribute("IsBuyTile") or obj:GetAttribute("ID") then
                    table.insert(buyTiles, obj)
                end
            end
            
            -- Also look for potential buy tile parts with specific characteristics
            for _, obj in pairs(tycoon.Value:GetDescendants()) do
                if obj:IsA("BasePart") and 
                   (obj.Name == "BuyTilePart" or obj.Name:match("Tile") or obj.Name:match("Plot")) then
                    if not table.find(buyTiles, obj.Parent) then
                        table.insert(buyTiles, obj.Parent)
                    end
                end
            end
            
            -- We also need to fix standalone gym parts (not under a BuyTile)
            for _, obj in pairs(tycoon.Value:GetChildren()) do
                -- Skip BuyTiles which we'll handle separately
                if not obj.Name:match("^BuyTile") and not obj:GetAttribute("IsBuyTile") then
                    if obj:IsA("Model") then
                        -- Check if this is a gym part by looking for ID attribute or name pattern
                        if obj:GetAttribute("ID") or obj.Name:match("^GymPart") or obj.Name:match("Equipment") then
                            -- Since it's not under a BuyTile, we need to fix its position based on its ID
                            local id = obj:GetAttribute("ID")
                            if id then
                                -- Calculate position based on ID
                                local basePos = Vector3.new(-164, 0.5, 105) -- Starting position
                                local position = basePos + Vector3.new(((id-1) % 5) * 10, 1, math.floor((id-1) / 5) * 10)
                                
                                -- Create a CFrame at this calculated position
                                local adjustedCFrame = CFrame.new(position)
                                
                                -- Store original position if not already stored
                                if not obj:GetAttribute("OriginalPosition") then
                                    obj:SetAttribute("OriginalPosition", tostring(position))
                                end
                                
                                -- Apply position based on model
                                if obj.PrimaryPart then
                                    obj:SetPrimaryPartCFrame(adjustedCFrame)
                                    debugPrint("Fixed standalone gym part:", obj.Name, "ID:", id, "at position:", tostring(position))
                                    modelsFixed = modelsFixed + 1
                                else
                                    -- Find a primary part
                                    local largestPart = nil
                                    local largestVolume = 0
                                    
                                    for _, part in pairs(obj:GetDescendants()) do
                                        if part:IsA("BasePart") then
                                            local volume = part.Size.X * part.Size.Y * part.Size.Z
                                            if volume > largestVolume then
                                                largestPart = part
                                                largestVolume = volume
                                            end
                                        end
                                    end
                                    
                                    if largestPart then
                                        obj.PrimaryPart = largestPart
                                        obj:SetPrimaryPartCFrame(adjustedCFrame)
                                        debugPrint("Fixed standalone gym part (set primary part):", obj.Name, "ID:", id, "at position:", tostring(position))
                                        modelsFixed = modelsFixed + 1
                                    else
                                        debugPrint("Could not fix standalone gym part (no parts):", obj.Name, "ID:", id)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    debugPrint("Found", #buyTiles, "BuyTile objects to process")
    
    -- Fix models in each BuyTile
    for _, tile in pairs(buyTiles) do
        for _, child in pairs(tile:GetChildren()) do
            -- Skip non-model objects and special system objects
            if (child:IsA("Model") or child:IsA("BasePart")) and 
               not (child.Name == "BillboardGui" or child.Name == "ClickDetector" or child.Name == "BuyTilePart" or 
                    child:IsA("Script") or child:IsA("LocalScript") or child:IsA("SpecialMesh")) then
                fixModelPosition(child, tile)
                modelsFixed = modelsFixed + 1
            end
        end
    end
    
    debugPrint("Fixed a total of", modelsFixed, "models in the workspace")
    return modelsFixed
end

-- Monkey patch the BuyTileSystem to fix model placement on new purchases
local function monkeyPatchBuyTileSystem()
    local BuyTileSystem = findBuyTileSystem()
    if not BuyTileSystem then
        debugPrint("Could not patch BuyTileSystem - module not found")
        return false
    end
    
    -- Keep original function references
    local originalSpawnGymPart = BuyTileSystem.spawnGymPart
    
    if not originalSpawnGymPart or typeof(originalSpawnGymPart) ~= "function" then
        debugPrint("Could not find spawnGymPart function to patch")
        return false
    end
    
    -- Replace the function with our enhanced version
    BuyTileSystem.spawnGymPart = function(...)
        local args = {...}
        
        -- Check args and extract key info for later
        local player = nil
        local partId = nil
        local position = nil
        local tileObj = nil
        
        -- Different argument patterns based on how the function is called
        if #args >= 1 then
            -- First argument could be player, partId, or nothing
            if typeof(args[1]) == "Instance" and args[1]:IsA("Player") then
                player = args[1]
                if #args >= 2 then
                    partId = args[2]  -- Second arg would be partId
                end
            else
                partId = args[1]  -- First arg is partId
            end
            
            -- Position could be in different arg positions based on pattern
            if #args >= 2 and typeof(args[2]) == "Vector3" then
                position = args[2]
            elseif #args >= 3 and typeof(args[3]) == "Vector3" then
                position = args[3]
            end
            
            -- TileObj could also be in different positions
            for i = 1, #args do
                if typeof(args[i]) == "Instance" and not args[i]:IsA("Player") then
                    tileObj = args[i]
                    break
                end
            end
        end
        
        debugPrint("Calling spawnGymPart with:", "PartID:", partId, "Position:", position and tostring(position) or "nil")
        
        -- Call the original function
        local result = originalSpawnGymPart(table.unpack(args))
        
        -- Apply position fixes after original function runs
        if result then
            -- We may need to wait briefly for the model to be fully created
            task.delay(0.1, function()
                if not result.Parent then
                    debugPrint("Model was destroyed before fixes could be applied")
                    return
                end
                
                -- If we have a tile object, use that for positioning
                if tileObj then
                    fixModelPosition(result, tileObj)
                else
                    -- No tile object, so we need to calculate position based on ID
                    -- But first store original position if passed
                    if position and not result:GetAttribute("OriginalPosition") then
                        result:SetAttribute("OriginalPosition", tostring(position))
                    end
                    
                    -- If it has a primary part, ensure it's positioned correctly
                    if position and result.PrimaryPart then
                        result:SetPrimaryPartCFrame(CFrame.new(position))
                    elseif position and not result.PrimaryPart then
                        -- Find a part to use as primary part
                        local largestPart = nil
                        local largestVolume = 0
                        
                        for _, part in pairs(result:GetDescendants()) do
                            if part:IsA("BasePart") then
                                local volume = part.Size.X * part.Size.Y * part.Size.Z
                                if volume > largestVolume then
                                    largestPart = part
                                    largestVolume = volume
                                end
                            end
                        end
                        
                        if largestPart then
                            result.PrimaryPart = largestPart
                            result:SetPrimaryPartCFrame(CFrame.new(position))
                        end
                    end
                    
                    debugPrint("Applied position fixes to spawned model:", result.Name)
                end
            end)
        end
        
        return result
    end
    
    -- Also patch spawnBuyTile if it exists
    if typeof(BuyTileSystem.spawnBuyTile) == "function" then
        local originalSpawnBuyTile = BuyTileSystem.spawnBuyTile
        BuyTileSystem.spawnBuyTile = function(...)
            local result = originalSpawnBuyTile(...)
            -- No specific fixes needed for buy tiles
            return result
        end
        debugPrint("Successfully patched BuyTileSystem.spawnBuyTile")
    end
    
    -- Add our own spawnGymPartAtPosition function if it doesn't exist
    if not BuyTileSystem.spawnGymPartAtPosition then
        BuyTileSystem.spawnGymPartAtPosition = function(partId, position, parent, rotation)
            rotation = rotation or Vector3.new(0, 0, 0)
            
            -- Call the original function to spawn the part
            local part = BuyTileSystem.spawnGymPart(partId)
            
            if part then
                -- Store original position for restoration
                part:SetAttribute("OriginalPosition", tostring(position))
                
                -- Ensure it has a primary part
                if not part.PrimaryPart then
                    local largestPart = nil
                    local largestVolume = 0
                    
                    for _, p in pairs(part:GetDescendants()) do
                        if p:IsA("BasePart") then
                            local volume = p.Size.X * p.Size.Y * p.Size.Z
                            if volume > largestVolume then
                                largestPart = p
                                largestVolume = volume
                            end
                        end
                    end
                    
                    if largestPart then
                        part.PrimaryPart = largestPart
                    end
                end
                
                -- Position it correctly
                if part.PrimaryPart then
                    part:SetPrimaryPartCFrame(CFrame.new(position) * 
                        CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z)))
                end
                
                -- Set parent
                if parent then
                    part.Parent = parent
                end
            end
            
            return part
        end
        debugPrint("Added spawnGymPartAtPosition function to BuyTileSystem")
    end
    
    debugPrint("Successfully patched BuyTileSystem.spawnGymPart")
    return true
end

-- Main execution
debugPrint("Starting BuyTile position fixer...")

local success = monkeyPatchBuyTileSystem()
if success then
    debugPrint("Successfully patched BuyTileSystem")
    
    -- Fix existing models after a short delay to ensure everything is loaded
    task.delay(2, function()
        fixExistingModels()
        debugPrint("Completed fixing existing models")
        
        -- Set up periodic check for new models with positioning issues
        task.spawn(function()
            while true do
                task.wait(60) -- Check every minute
                fixExistingModels()
            end
        end)
    end)
    
    -- Set global flag for testing purposes
    _G.BuyTilePositionFixerInitialized = true
    
    -- Add flag to BuyTileSystem for testing
    local BuyTileSystem = findBuyTileSystem()
    if BuyTileSystem then
        BuyTileSystem.PositionFixerApplied = true
    end
    
    -- Expose public API for other systems
    return {
        fixModelPosition = fixModelPosition,
        fixExistingModels = fixExistingModels
    }
else
    debugPrint("Failed to patch BuyTileSystem - position fixing may not work")
    
    -- Try to run the fixer anyway for existing models
    task.delay(5, function()
        fixExistingModels()
        debugPrint("Completed attempted fix of existing models")
    end)
    
    return {
        fixModelPosition = fixModelPosition,
        fixExistingModels = fixExistingModels
    }
end
        BuyTileSystem._positionFixApplied = true
    end
    
    -- Register events for new model spawns
    game.Players.PlayerAdded:Connect(function(player)
        task.delay(5, function() -- Wait for player's tycoon to be created
            fixExistingModels() -- Fix models for this player
        end)
    end)
else
    warn("Failed to patch BuyTileSystem - position issues may persist")
end

-- Fix player's models when they join
game.Players.PlayerAdded:Connect(function(player)
    -- Wait a bit for their tycoon to be set up
    task.delay(5, function()
        debugPrint("Player joined:", player.Name, "- fixing their models")
        local tycoon = player:FindFirstChild("Tycoon")
        if tycoon and tycoon.Value then
            -- Fix models in their tycoon
            local modelsFixed = 0
            
            -- First find any BuyTiles
            local buyTiles = {}
            for _, obj in pairs(tycoon.Value:GetDescendants()) do
                if obj.Name:match("^BuyTile") or obj:GetAttribute("IsBuyTile") or obj:GetAttribute("ID") then
                    table.insert(buyTiles, obj)
                end
            end
            
            -- Fix models in each BuyTile
            for _, tile in pairs(buyTiles) do
                for _, child in pairs(tile:GetChildren()) do
                    -- Skip non-model objects and special system objects
                    if (child:IsA("Model") or child:IsA("BasePart")) and 
                       not (child.Name == "BillboardGui" or child.Name == "ClickDetector" or child.Name == "BuyTilePart" or 
                            child:IsA("Script") or child:IsA("LocalScript") or child:IsA("SpecialMesh")) then
                        fixModelPosition(child, tile)
                        modelsFixed = modelsFixed + 1
                    end
                end
            end
            
            -- Look for standalone models too
            for _, obj in pairs(tycoon.Value:GetChildren()) do
                if not obj.Name:match("^BuyTile") and not obj:GetAttribute("IsBuyTile") then
                    if obj:IsA("Model") then
                        -- Check if this is a gym part by looking for ID attribute or name pattern
                        if obj:GetAttribute("ID") or obj.Name:match("^GymPart") or obj.Name:match("Equipment") then
                            local id = obj:GetAttribute("ID")
                            if id then
                                -- Calculate position based on ID
                                local basePos = Vector3.new(-164, 0.5, 105) -- Starting position
                                local position = basePos + Vector3.new(((id-1) % 5) * 10, 1, math.floor((id-1) / 5) * 10)
                                
                                -- Create a CFrame at this calculated position
                                local adjustedCFrame = CFrame.new(position)
                                
                                -- Apply position if we have original position stored
                                local originalPosition = nil
                                if obj:GetAttribute("OriginalPosition") then
                                    local posStr = obj:GetAttribute("OriginalPosition")
                                    local x, y, z = posStr:match("([-0-9.]+), ([-0-9.]+), ([-0-9.]+)")
                                    if x and y and z then
                                        originalPosition = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
                                        adjustedCFrame = CFrame.new(originalPosition)
                                    end
                                end
                                
                                -- Apply position based on model
                                if obj.PrimaryPart then
                                    obj:SetPrimaryPartCFrame(adjustedCFrame)
                                    modelsFixed = modelsFixed + 1
                                else
                                    -- Find a primary part
                                    local largestPart = nil
                                    local largestVolume = 0
                                    
                                    for _, part in pairs(obj:GetDescendants()) do
                                        if part:IsA("BasePart") then
                                            local volume = part.Size.X * part.Size.Y * part.Size.Z
                                            if volume > largestVolume then
                                                largestPart = part
                                                largestVolume = volume
                                            end
                                        end
                                    end
                                    
                                    if largestPart then
                                        obj.PrimaryPart = largestPart
                                        obj:SetPrimaryPartCFrame(adjustedCFrame)
                                        modelsFixed = modelsFixed + 1
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            debugPrint("Fixed", modelsFixed, "models for player", player.Name)
        else
            debugPrint("Player", player.Name, "has no tycoon set up yet")
        end
    end)
end)

-- Return true to indicate successful initialization
return true
