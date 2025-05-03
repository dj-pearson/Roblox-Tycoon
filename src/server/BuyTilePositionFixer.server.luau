--!strict
--[[
    BuyTilePositionFixer.server.luau
    Fixes model positioning issues in the BuyTile system
    
    Created: April 29, 2025
    Updated: May 2, 2025 - Enhanced with CoreRegistryBridge integration,
             TycoonFolderInitializer compatibility, and improved model detection
]]

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Configuration
local CONFIG = {
    DEFAULT_BASE_POSITION = Vector3.new(-164, 0.5, 105), -- Default starting position for grid-based layout
    GRID_SIZE = 10, -- Standard grid spacing (in studs)
    CHECK_INTERVAL = 60, -- How often to check for positioning issues (in seconds)
    INITIAL_CHECK_DELAY = 2, -- Initial delay before first check (in seconds)
    MODEL_FIX_DELAY = 0.1, -- Delay after model creation before applying fixes (in seconds)
    DOOR_HEIGHT_DEFAULT = 44, -- Standard door height if not specified
    SPECIAL_TYPES = { -- Special model types that need custom handling
        ["Door"] = true,
        ["Wall"] = true,
        ["Glass"] = true,
        ["Window"] = true,
        ["Ceiling"] = true,
        ["Floor"] = true
    }
}

-- Import the ModelPositioningHelper if available
local ModelPositioningHelper
local success, result = pcall(function()
    return require(game.ReplicatedStorage.shared.ModelPositioningHelper)
end)

if success then
    ModelPositioningHelper = result
    print("[BuyTilePositionFixer] Loaded ModelPositioningHelper successfully")
else
    warn("[BuyTilePositionFixer] Could not load ModelPositioningHelper: " .. tostring(result))
end

-- Module definition
local BuyTilePositionFixer = {
    initialized = false,
    _version = "1.4.0", -- Versioning for update tracking
    CONFIG = CONFIG -- Expose config for other systems to access
}

-- Debug printing function with timestamp
local function debugPrint(...)
    local timestamp = os.date("%H:%M:%S")
    print("[BuyTilePositionFixer][" .. timestamp .. "]", ...)
end

-- Import CoreRegistryBridge for better system integration
local CoreRegistryBridge = nil

-- Try to find and require CoreRegistryBridge
local function importCoreRegistryBridge()
    local paths = {
        ServerScriptService:FindFirstChild("CoreRegistryBridge"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("CoreRegistryBridge"),
        ServerScriptService:FindFirstChild("server") and ServerScriptService.server:FindFirstChild("CoreRegistryBridge")
    }
    
    for _, path in ipairs(paths) do
        if path and path:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(path)
            end)
            
            if success and result then
                debugPrint("Successfully imported CoreRegistryBridge")
                return result
            end
        end
    end
    
    debugPrint("Could not find CoreRegistryBridge, falling back to direct methods")
    return nil
end

-- Try to initialize CoreRegistryBridge
CoreRegistryBridge = importCoreRegistryBridge()

-- Register with CoreRegistry
function BuyTilePositionFixer.registerWithCoreRegistry()
    if CoreRegistryBridge then
        local success = CoreRegistryBridge.registerSystem("BuyTilePositionFixer", BuyTilePositionFixer)
        if success then
            debugPrint("Successfully registered with CoreRegistry via CoreRegistryBridge")
            return true
        end
    end
    
    -- Try direct registration with CoreRegistry if bridge failed
    local success, result = pcall(function()
        local registry = nil
        
        -- Try different paths to find CoreRegistry
        local searchPaths = {
            ServerScriptService:FindFirstChild("Core"),
            ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"),
            ServerScriptService:FindFirstChild("Server") and ServerScriptService.Server:FindFirstChild("Core"),
            ReplicatedStorage:FindFirstChild("shared")
        }
        
        for _, path in ipairs(searchPaths) do
            if path and path:FindFirstChild("CoreRegistry") then
                local tryRegister = require(path.CoreRegistry)
                if tryRegister then
                    registry = tryRegister
                    break
                end
            end
        end
        
        if registry then
            if typeof(registry.registerSystem) == "function" then
                registry.registerSystem("BuyTilePositionFixer", BuyTilePositionFixer)
                return true
            elseif typeof(registry.Register) == "function" then
                registry:Register("BuyTilePositionFixer", BuyTilePositionFixer)
                return true
            end
        end
        
        return false
    end)
    
    if success and result then
        debugPrint("Successfully registered with CoreRegistry directly")
        return true
    end
    
    debugPrint("Could not register with CoreRegistry, but BuyTilePositionFixer will still function")
    return false
end

-- Determine if a model is a special type that needs custom handling
function BuyTilePositionFixer.getSpecialModelType(model)
    if not model then return nil end
    
    -- Check for direct type attribute
    local modelType = model:GetAttribute("Type")
    if modelType and CONFIG.SPECIAL_TYPES[modelType] then
        return modelType
    end
    
    -- Check name for type indicators
    local name = model.Name:lower()
    for typeName, _ in pairs(CONFIG.SPECIAL_TYPES) do
        if name:find(typeName:lower()) then
            return typeName
        end
    end
    
    -- Check for parts that might indicate type
    for _, child in pairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            local partName = child.Name:lower()
            for typeName, _ in pairs(CONFIG.SPECIAL_TYPES) do
                if partName:find(typeName:lower()) then
                    return typeName
                end
            end
        end
    end
    
    return nil
end

-- Find BuyTileSystem using CoreRegistryBridge or direct methods
function BuyTilePositionFixer.findBuyTileSystem()
    -- Try using CoreRegistryBridge first if available
    if CoreRegistryBridge then
        local system = CoreRegistryBridge.getSystem("BuyTileSystem")
        if system then
            debugPrint("Found BuyTileSystem through CoreRegistryBridge")
            return system
        end
    end
    
    -- If not found through CoreRegistryBridge, search directly
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("Server") and ServerScriptService.Server:FindFirstChild("Core")
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
    
    -- Last try to find any BuyTile-related module
    for _, path in ipairs(searchPaths) do
        if path then
            for _, child in ipairs(path:GetChildren()) do
                if child:IsA("ModuleScript") and (child.Name:find("BuyTile") or child.Name:find("buyTile") or child.Name:find("Buytile")) then
                    local success, module = pcall(function()
                        return require(child)
                    end)
                    
                    if success and typeof(module) == "table" then
                        debugPrint("Found alternative BuyTile module at:", child:GetFullName())
                        return module
                    end
                end
            end
        end
    end
    
    debugPrint("Could not find BuyTileSystem module")
    return nil
end

-- Fix the position of a single model relative to its tile
function BuyTilePositionFixer.fixModelPosition(model, tile)
    -- Use ModelPositioningHelper if available (preferred method)
    if ModelPositioningHelper then
        local success, message = ModelPositioningHelper.positionAtTile(model, tile)
        if success then
            return true
        end
        
        -- If failed, log and fall back to original method
        warn("[BuyTilePositionFixer] ModelPositioningHelper failed: " .. message)
    end
    
    if not model or not tile then
        debugPrint("Invalid model or tile object provided")
        return
    end
    
    debugPrint("Fixing position for model:", model:GetFullName())
    
    -- Get model attributes or use defaults
    local offsetY = model:GetAttribute("OffsetY") or 0
    local offsetX = model:GetAttribute("OffsetX") or 0
    local offsetZ = model:GetAttribute("OffsetZ") or 0
    local rotationY = model:GetAttribute("RotationY") or 0
    
    -- Determine if this is a special model type that needs custom handling
    local specialType = BuyTilePositionFixer.getSpecialModelType(model)
    
    -- Special handling for doors
    if specialType == "Door" then
        -- Default door settings if not specified
        offsetY = model:GetAttribute("OffsetY") or 0
        rotationY = model:GetAttribute("RotationY") or 90 -- Most doors face outward by default
        
        -- For doors, find the height to position the door at the right height
        local height = model:GetAttribute("Height") or CONFIG.DOOR_HEIGHT_DEFAULT
        
        -- If the model does not have a primary part, try to set one
        if not model.PrimaryPart then
            -- Find the largest part to use as primary
            local largestPart = nil
            local largestVolume = 0
            
            for _, part in pairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    local volume = part.Size.X * part.Size.Y * part.Size.Z
                    if volume > largestVolume then
                        largestPart = part
                        largestVolume = volume
                    end
                end
            end
            
            if largestPart then
                model.PrimaryPart = largestPart
            end
        end
    end
    
    -- Special handling for walls
    if specialType == "Wall" then
        -- Walls typically align with the edge of a tile
        offsetY = model:GetAttribute("OffsetY") or 0
        
        -- If no primary part, try to find a suitable one
        if not model.PrimaryPart then
            -- For walls, try to find the largest vertical part
            local bestPart = nil
            local bestScore = 0
            
            for _, part in pairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    -- Prioritize taller, thinner parts as wall primary parts
                    local score = part.Size.Y * 2 - part.Size.X - part.Size.Z
                    if score > bestScore then
                        bestPart = part
                        bestScore = score
                    end
                end
            end
            
            if bestPart then
                model.PrimaryPart = bestPart
            end
        end
    end
    
    -- Get tile position
    local tilePosition = tile:GetPivot().Position
    
    -- Determine if there's a BuyTilePart we should reference
    local buyTilePart = tile:FindFirstChild("BuyTilePart")
    if buyTilePart and buyTilePart:IsA("BasePart") then
        tilePosition = buyTilePart.Position
    end
    
    -- Apply the rotation and offset to get the final CFrame
    local rotation = CFrame.Angles(0, math.rad(rotationY), 0)
    local position = tilePosition + Vector3.new(offsetX, offsetY, offsetZ)
    local finalCFrame = CFrame.new(position) * rotation
      -- Store original position if not already stored
    if not model:GetAttribute("OriginalPosition") then
        model:SetAttribute("OriginalPosition", tostring(position))
    end
    
    -- Apply position based on model type
    if model:IsA("Model") then
        if model.PrimaryPart then
            -- Use SetPrimaryPartCFrame to properly position based on primary part
            model:SetPrimaryPartCFrame(finalCFrame)
            debugPrint("Set primary part CFrame for model:", model:GetFullName())
        else
            -- If no primary part, try to find one
            local hasParts = false
            
            for _, part in pairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    hasParts = true
                    break
                end
            end
            
            if hasParts then
                -- Find best part to use as primary
                local bestPart = nil
                local bestVolume = 0
                
                for _, part in pairs(model:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local volume = part.Size.X * part.Size.Y * part.Size.Z
                        if volume > bestVolume then
                            bestPart = part
                            bestVolume = volume
                        end
                    end
                end
                
                if bestPart then
                    -- Set the primary part and position using it
                    model.PrimaryPart = bestPart
                    model:SetPrimaryPartCFrame(finalCFrame)
                    debugPrint("Set primary part for model:", model:GetFullName())
                else
                    debugPrint("Cannot find a suitable primary part for:", model:GetFullName())
                end
            else
                debugPrint("Model has no parts:", model:GetFullName())
            end
        end
    else
        -- For non-model instances (like individual parts)
        if model:IsA("BasePart") then
            model.CFrame = finalCFrame
            debugPrint("Set CFrame for part:", model:GetFullName())
        else
            debugPrint("Unsupported object type for positioning:", model:GetFullName())
        end
    end
    
    -- Mark the model as having its position fixed
    model:SetAttribute("PositionFixed", true)
    
    -- Set the last fix timestamp
    model:SetAttribute("LastFixTimestamp", os.time())
end

-- Integrate with BuyTileSystem by patching its functions
function BuyTilePositionFixer.integrateWithBuyTileSystem()
    local buyTileSystem = BuyTilePositionFixer.findBuyTileSystem()
    if not buyTileSystem then
        debugPrint("Could not find BuyTileSystem to integrate with")
        return false
    end
    
    -- Monkey patch the BuyTileSystem to fix positions when tiles are purchased
    if typeof(buyTileSystem.buyTile) == "function" then
        local originalBuyTile = buyTileSystem.buyTile
        
        buyTileSystem.buyTile = function(player, tileId, ...)
            local success, result = originalBuyTile(player, tileId, ...)
            
            if success then
                -- Schedule a delayed fix to ensure the model has been created
                task.delay(CONFIG.MODEL_FIX_DELAY, function()
                    BuyTilePositionFixer.fixModelsForPlayer(player)
                end)
            end
            
            return success, result
        end
        
        debugPrint("Successfully patched BuyTileSystem.buyTile function")
    else
        debugPrint("Could not find buyTile function in BuyTileSystem")
    end
    
    -- Check for other functions to patch
    local functionsToCheck = {
        "spawnGymPart",
        "placeModel",
        "restoreTiles",
        "loadTile"
    }
    
    for _, funcName in ipairs(functionsToCheck) do
        if typeof(buyTileSystem[funcName]) == "function" then
            local originalFunc = buyTileSystem[funcName]
            
            buyTileSystem[funcName] = function(...)
                local result = originalFunc(...)
                
                -- For multi-player functions, try to determine the player
                local args = {...}
                local player = nil
                
                for _, arg in ipairs(args) do
                    if typeof(arg) == "Instance" and arg:IsA("Player") then
                        player = arg
                        break
                    end
                end
                
                -- If we found a player, schedule a fix
                if player then
                    task.delay(CONFIG.MODEL_FIX_DELAY, function()
                        BuyTilePositionFixer.fixModelsForPlayer(player)
                    end)
                else
                    -- Otherwise, fix all players' models
                    task.delay(CONFIG.MODEL_FIX_DELAY, function()
                        BuyTilePositionFixer.fixAllModels()
                    end)
                end
                
                return result
            end
            
            debugPrint("Successfully patched BuyTileSystem." .. funcName .. " function")
        end
    end
    
    return true
end

-- Fix for a specific player
function BuyTilePositionFixer.fixModelsForPlayer(player)
    -- Check if player is valid
    if not player or not player:IsA("Player") then
        return false
    end
    
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then
        debugPrint("Player", player.Name, "has no tycoon set up yet")
        return false
    end
    
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
                BuyTilePositionFixer.fixModelPosition(child, tile)
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
                        local basePos = obj:GetAttribute("BasePosition") or CONFIG.DEFAULT_BASE_POSITION
                        local gridSize = obj:GetAttribute("GridSize") or CONFIG.GRID_SIZE
                        local position = basePos + Vector3.new(((id-1) % 5) * gridSize, 1, math.floor((id-1) / 5) * gridSize)
                        
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
    return true
end

-- Fix all models for all players
function BuyTilePositionFixer.fixAllModels()
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            BuyTilePositionFixer.fixModelsForPlayer(player)
        end)
    end
    return true
end

-- Initialize the BuyTilePositionFixer module
function BuyTilePositionFixer.initialize()
    if BuyTilePositionFixer.initialized then
        return true
    end
    
    debugPrint("Initializing BuyTilePositionFixer...")
    
    -- Register with CoreRegistry
    BuyTilePositionFixer.registerWithCoreRegistry()
    
    -- Integrate with BuyTileSystem
    BuyTilePositionFixer.integrateWithBuyTileSystem()
    
    -- Try to load the TileBuyProgressRestorer module
    local tileBuyProgressRestorer = nil
    pcall(function()
        tileBuyProgressRestorer = require(ServerScriptService.Core.TileBuyProgressRestorer)
        if tileBuyProgressRestorer then
            debugPrint("Successfully integrated with TileBuyProgressRestorer")
        end
    end)
    
    -- Set up player added event to fix models when players join
    Players.PlayerAdded:Connect(function(player)
        -- Wait for tycoon to be set up
        task.delay(5, function()
            BuyTilePositionFixer.fixModelsForPlayer(player)
            
            -- Also fix the player's tile progression if the restorer is available
            if tileBuyProgressRestorer and typeof(tileBuyProgressRestorer.fixPlayerProgression) == "function" then
                task.spawn(function()
                    tileBuyProgressRestorer.fixPlayerProgression(player)
                end)
            end
        end)
    end)
    
    -- Set up periodic check for model positions
    task.spawn(function()
        task.wait(CONFIG.INITIAL_CHECK_DELAY)
        
        while true do
            BuyTilePositionFixer.fixAllModels()
            task.wait(CONFIG.CHECK_INTERVAL)
        end
    end)
    
    BuyTilePositionFixer.initialized = true
    debugPrint("BuyTilePositionFixer initialized successfully")
    return true
end

-- Start the initialization
BuyTilePositionFixer.initialize()

-- Print success message
print("✅ [BuyTilePositionFixer] Initialized and monitoring model positions - Fixed May 2, 2025")
print("✅ [BuyTilePositionFixer] Enhanced with CoreRegistryBridge integration and TycoonFolderInitializer compatibility")
print("✅ [BuyTilePositionFixer] Integrated with TileBuyProgressRestorer for proper buy tile progression")

-- Return the module
return BuyTilePositionFixer
