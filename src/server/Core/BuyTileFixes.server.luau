--!strict
--[[
    BuyTileFixes.server.luau
    Fixes for BuyTile model positioning issues
    
    Updated: April 29, 2025
]]

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

-- Monkey patch the BuyTileSystem to fix model placement issues
local function applyPatchesToBuyTileSystem()
    print("[BuyTileFixes] Applying patches to BuyTileSystem...")
    
    -- Find the BuyTileSystem module
    local BuyTileSystem = nil
    local paths = {
        game:GetService("ServerScriptService").Core,
        game:GetService("ServerScriptService").Systems,
        game:GetService("ServerScriptService").src.server.Core,
        game:GetService("ServerScriptService").src.server.Systems
    }
    
    -- Try to find the module
    for _, path in ipairs(paths) do
        if path and path:FindFirstChild("BuyTileSystem") then
            local success, result = pcall(function()
                return require(path:FindFirstChild("BuyTileSystem"))
            end)
            
            if success and type(result) == "table" then
                BuyTileSystem = result
                print("[BuyTileFixes] Found BuyTileSystem at:", path:FindFirstChild("BuyTileSystem"):GetFullName())
                break
            end
        end
    end
    
    if not BuyTileSystem then
        print("[BuyTileFixes] Could not find BuyTileSystem. Patches not applied.")
        return false
    end
    
    -- Store original function if it exists
    local originalSpawnGymPart = BuyTileSystem.spawnGymPart
    
    if not originalSpawnGymPart or type(originalSpawnGymPart) ~= "function" then
        print("[BuyTileFixes] Could not find spawnGymPart function in BuyTileSystem. Patches not applied.")
        return false
    end
    
    -- Replace the function with our patched version
    BuyTileSystem.spawnGymPart = function(player, tileId, gymPartId, tileObj)
        print("[BuyTileFixes] Enhanced spawnGymPart called:", player, tileId, gymPartId)
        
        -- Call original function but don't return yet
        local success = originalSpawnGymPart(player, tileId, gymPartId, tileObj)
        
        -- After original function completes, apply positioning fixes
        if success then
            -- Find the newly spawned model in the tile
            local model = nil
            for _, child in ipairs(tileObj:GetChildren()) do
                if child.Name == gymPartId then
                    model = child
                    break
                end
            end
            
            if model then
                -- Get model attributes or use defaults
                local offsetY = model:GetAttribute("OffsetY") or 0
                local offsetX = model:GetAttribute("OffsetX") or 0
                local offsetZ = model:GetAttribute("OffsetZ") or 0
                local rotationY = model:GetAttribute("RotationY") or 0
                
                -- Adjust position and rotation
                local adjustedCFrame = tileObj.CFrame * CFrame.new(offsetX, offsetY, offsetZ) * CFrame.Angles(0, math.rad(rotationY), 0)
                
                -- Apply position correction based on model type
                if model:IsA("Model") then
                    if model.PrimaryPart then
                        print("[BuyTileFixes] Adjusting position for model with PrimaryPart:", model.Name)
                        model:SetPrimaryPartCFrame(adjustedCFrame)
                    else
                        -- Find the largest part to use as primary part
                        local bestPart = nil
                        local largestSize = 0
                        
                        for _, part in ipairs(model:GetDescendants()) do
                            if part:IsA("BasePart") then
                                local partSize = part.Size.X * part.Size.Y * part.Size.Z
                                if partSize > largestSize then
                                    bestPart = part
                                    largestSize = partSize
                                end
                            end
                        end
                        
                        if bestPart then
                            print("[BuyTileFixes] Setting", bestPart.Name, "as primary part for", model.Name)
                            model.PrimaryPart = bestPart
                            model:SetPrimaryPartCFrame(adjustedCFrame)
                        else
                            -- Fallback for models with no parts
                            print("[BuyTileFixes] Using PivotTo for model with no suitable parts:", model.Name)
                            model:PivotTo(adjustedCFrame)
                        end
                    end
                else
                    -- Handle single parts
                    print("[BuyTileFixes] Adjusting position for single part:", model.Name)
                    model.CFrame = adjustedCFrame
                end
                
                print("[BuyTileFixes] Model", model.Name, "adjusted to position:", tostring(model:GetPivot().Position))
            else
                print("[BuyTileFixes] Could not find spawned model for gym part:", gymPartId)
            end
        end
        
        return success
    end
    
    print("[BuyTileFixes] Successfully patched BuyTileSystem.spawnGymPart")
    return true
end

-- Apply the patches
local success = applyPatchesToBuyTileSystem()
if success then
    print("[BuyTileFixes] BuyTile position fixes applied successfully")
else
    warn("[BuyTileFixes] Failed to apply BuyTile position fixes")
end

-- Return true to indicate the module loaded
return true
