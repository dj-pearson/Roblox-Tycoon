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
    
    -- Create adjusted CFrame
    local tileCFrame = tileObj.CFrame or tileObj:GetPivot()
    local adjustedCFrame = tileCFrame * CFrame.new(offsetX, offsetY, offsetZ) * CFrame.Angles(0, math.rad(rotationY), 0)
    
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
    
    debugPrint("New position:", tostring(model:GetPivot().Position))
end

-- Fix existing models in the workspace
local function fixExistingModels()
    -- Find all BuyTile objects in the workspace
    local buyTiles = {}
    
    for _, player in pairs(game.Players:GetPlayers()) do
        local tycoon = player:FindFirstChild("Tycoon")
        if tycoon and tycoon.Value then
            for _, obj in pairs(tycoon.Value:GetDescendants()) do
                if obj.Name:match("^BuyTile") then
                    table.insert(buyTiles, obj)
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
               not (child.Name == "BillboardGui" or child.Name == "ClickDetector" or child.Name == "BuyTilePart") then
                fixModelPosition(child, tile)
            end
        end
    end
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
        local result = originalSpawnGymPart(table.unpack(args))
        
        -- Apply position fixes after original function runs
        if result then
            -- Find the spawned model (it should be the last child of the tile)
            local player, tileId, gymPartId, tileObj = args[1], args[2], args[3], args[4]
            
            if tileObj then
                -- Wait briefly for model to be fully created
                task.delay(0.1, function()
                    for _, child in pairs(tileObj:GetChildren()) do
                        if child.Name == gymPartId then
                            fixModelPosition(child, tileObj)
                            break
                        end
                    end
                end)
            end
        end
        
        return result
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
    task.delay(1, function()
        fixExistingModels()
        debugPrint("Completed fixing existing models")
    end)
    
    -- Set global flag for testing purposes
    _G.BuyTilePositionFixerInitialized = true
    
    -- Add flag to BuyTileSystem for testing
    local BuyTileSystem = findBuyTileSystem()
    if BuyTileSystem then
        BuyTileSystem._positionFixApplied = true
    end
else
    warn("Failed to patch BuyTileSystem - position issues may persist")
end

-- Return true to indicate successful initialization
return true
