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
    
    -- Grid alignment correction
    local gridSize = 4 -- Standard grid size
    local gridAlignX = model:GetAttribute("GridAlignX")
    local gridAlignZ = model:GetAttribute("GridAlignZ")
    
    -- Apply grid alignment if specified
    if gridAlignX then
        offsetX = math.floor(offsetX / gridSize) * gridSize
    end
    if gridAlignZ then
        offsetZ = math.floor(offsetZ / gridSize) * gridSize
    end
    
    -- Special handling for doors
    if string.find(model.Name, "Door") then
        -- Ensure doors are at the right height
        if not model:GetAttribute("OffsetY") then
            -- Standard door height relative to floor
            offsetY = 0
        end
    end
    
    -- Special handling for walls
    if string.find(model.Name, "Wall") then
        -- Ensure walls are aligned with grid
        offsetX = math.floor(offsetX / gridSize) * gridSize
        offsetZ = math.floor(offsetZ / gridSize) * gridSize
    end
    
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
    
    -- Mark the model as fixed
    model:SetAttribute("PositionFixed", true)
    
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
                
                -- Special handling for doors
                if string.find(child.Name, "Door") then
                    local doorHeight = child:GetAttribute("StandardHeight") or 44
                    child:SetAttribute("OffsetY", doorHeight - tile.Position.Y)
                    debugPrint("Normalized door height for: " .. child.Name)
                end
                
                -- Special handling for glass groups
                if string.find(child.Name, "Glass Group") and child:IsA("Model") then
                    -- Find suitable primary part for glass groups
                    for _, part in pairs(child:GetDescendants()) do
                        if part:IsA("BasePart") and string.find(part.Name, "Wall") then
                            child.PrimaryPart = part
                            debugPrint("Set " .. part.Name .. " as primary part for " .. child.Name)
                            break
                        end
                    end
                end
                
                -- Fix the position
                fixModelPosition(child, tile)
                
                -- Mark as fixed
                child:SetAttribute("PositionFixed", true)
            end
        end
    end
    
    -- Search for problematic models that aren't attached to BuyTile objects
    local problemModels = {"Glass Group", "Door", "Wall-Bottom", "Wall-Top"}
    
    for _, modelName in ipairs(problemModels) do
        for _, workspace in pairs(game.Workspace:GetChildren()) do
            if workspace:IsA("Model") and workspace.Name:match("Tycoon_") then
                for _, obj in pairs(workspace:GetDescendants()) do
                    if (obj:IsA("Model") or obj:IsA("BasePart")) and 
                       string.find(obj.Name, modelName) and
                       not obj:GetAttribute("PositionFixed") then
                        
                        -- Find the nearest BuyTile to use as reference
                        local nearestTile = nil
                        local shortestDistance = math.huge
                        
                        local objPosition = obj:GetPivot().Position
                        for _, tile in ipairs(buyTiles) do
                            local distance = (tile.Position - objPosition).Magnitude
                            if distance < shortestDistance then
                                shortestDistance = distance
                                nearestTile = tile
                            end
                        end
                        
                        if nearestTile and shortestDistance < 50 then -- Only fix if reasonably close to a tile
                            debugPrint("Fixing orphaned model: " .. obj.Name .. " using nearby tile")
                            fixModelPosition(obj, nearestTile)
                            obj:SetAttribute("PositionFixed", true)
                        end
                    end
                end
            end
        end
    end
    
    debugPrint("Completed fixing existing models")
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
                    -- Fix models in the tile
                    for _, child in pairs(tileObj:GetChildren()) do
                        if (child:IsA("Model") or child:IsA("BasePart")) and
                           (child.Name == gymPartId or 
                            -- Also fix doors, walls, and glass elements which may need special handling
                            string.find(child.Name, "Door") or 
                            string.find(child.Name, "Wall") or 
                            string.find(child.Name, "Glass")) then
                            
                            -- Apply special height normalization for doors
                            if string.find(child.Name, "Door") then
                                local doorHeight = child:GetAttribute("StandardHeight") or 44
                                child:SetAttribute("OffsetY", doorHeight - tileObj.Position.Y)
                                debugPrint("Normalized door height for: " .. child.Name)
                            end
                            
                            -- Special handling for glass groups
                            if string.find(child.Name, "Glass Group") and child:IsA("Model") then
                                -- Find suitable primary part for glass groups
                                for _, part in pairs(child:GetDescendants()) do
                                    if part:IsA("BasePart") and string.find(part.Name, "Wall") then
                                        child.PrimaryPart = part
                                        debugPrint("Set " .. part.Name .. " as primary part for " .. child.Name)
                                        break
                                    end
                                end
                            end
                            
                            fixModelPosition(child, tileObj)
                        end
                    end
                end)
                
                -- Also do a second pass after a longer delay to catch any late-loading models
                task.delay(1, function()
                    for _, child in pairs(tileObj:GetChildren()) do
                        if (child:IsA("Model") or child:IsA("BasePart")) and 
                           not child:GetAttribute("PositionFixed") then
                            fixModelPosition(child, tileObj)
                            child:SetAttribute("PositionFixed", true)
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
        debugPrint("Completed initial fixing of existing models")
        
        -- Set up periodic checking for models that might have been missed
        task.spawn(function()
            while true do
                task.wait(30) -- Run every 30 seconds
                fixExistingModels()
            end
        end)
    end)
    
    -- Set global flag for testing purposes
    _G.BuyTilePositionFixerInitialized = true
    
    -- Add flag to BuyTileSystem for testing
    local BuyTileSystem = findBuyTileSystem()
    if BuyTileSystem then
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
    
    -- Even if patching failed, try to fix existing models
    task.delay(2, function()
        fixExistingModels()
        debugPrint("Completed fixing existing models despite patch failure")
        
        -- Set up fallback periodic checking for models
        task.spawn(function()
            while true do
                task.wait(15) -- Run more frequently if patch failed
                fixExistingModels()
            end
        end)
    end)
end

-- Return true to indicate successful initialization
return true
