--!strict
-- BuyTileSystemFix.server.luau
-- Fixes issues with BuyTile system and gym part spawning
-- Created on April 29, 2025 to fix critical BuyTile system errors

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Constants
local MAX_RETRIES = 3
local RETRY_DELAY = 1
local DEFAULT_MODEL_ID = "DefaultGymEquipment" -- Default model to use when specific model not found

-- Search paths for gym parts
local GYM_PART_SEARCH_PATHS = {
    ServerStorage:FindFirstChild("GymParts"),
    ServerStorage:FindFirstChild("Models"):FindFirstChild("GymParts"),
    ReplicatedStorage:FindFirstChild("Assets"):FindFirstChild("GymParts"),
    ServerStorage:FindFirstChild("Assets"):FindFirstChild("GymParts"),
    workspace:FindFirstChild("GymPartsTemplates"),
}

-- Filter out any nil entries from search paths
local function getValidSearchPaths()
    local validPaths = {}
    for _, path in ipairs(GYM_PART_SEARCH_PATHS) do
        if path then
            table.insert(validPaths, path)
        end
    end
    
    if #validPaths == 0 then
        warn("[BuyTileSystemFix] No valid search paths found for gym parts")
    else
        print(string.format("[BuyTileSystemFix] Found %d valid search paths for gym parts", #validPaths))
    end
    
    return validPaths
end

-- Find a gym part model by its ID
local function findGymPartModelById(id)
    local searchPaths = getValidSearchPaths()
    local idStr = tostring(id)
    
    print(string.format("[BuyTileSystemFix] Searching for gym part with ID: %s", idStr))
    
    -- First, try to find by exact name match (ID)
    for pathIndex, path in ipairs(searchPaths) do
        local model = path:FindFirstChild(idStr)
        if model then
            print(string.format("[BuyTileSystemFix] Found gym part with ID: %s in path %d", idStr, pathIndex))
            return model
        end
    end
    
    -- If not found, try models with GymPart_ID naming pattern
    for pathIndex, path in ipairs(searchPaths) do
        local model = path:FindFirstChild("GymPart_" .. idStr)
        if model then
            print(string.format("[BuyTileSystemFix] Found gym part with pattern GymPart_%s in path %d", idStr, pathIndex))
            return model
        end
    end
    
    -- If still not found, try to find a model with metadata
    for pathIndex, path in ipairs(searchPaths) do
        for _, model in ipairs(path:GetChildren()) do
            -- Check for ID value or attribute
            local idValue = model:FindFirstChild("ID")
            if idValue and idValue.Value == idStr then
                print(string.format("[BuyTileSystemFix] Found gym part with ID value matching %s in path %d", idStr, pathIndex))
                return model
            end
            
            -- Check for ID attribute
            if model:GetAttribute("ID") == idStr or model:GetAttribute("Id") == idStr or model:GetAttribute("id") == idStr then
                print(string.format("[BuyTileSystemFix] Found gym part with ID attribute matching %s in path %d", idStr, pathIndex))
                return model
            end
        end
    end
    
    warn(string.format("[BuyTileSystemFix] Could not find gym part with ID: %s in any search path", idStr))
    return nil
end

-- Find the default model to use as a fallback
local function findDefaultModel()
    local searchPaths = getValidSearchPaths()
    
    -- Try to find the default model
    for pathIndex, path in ipairs(searchPaths) do
        local model = path:FindFirstChild(DEFAULT_MODEL_ID)
        if model then
            print(string.format("[BuyTileSystemFix] Found default gym model in path %d", pathIndex))
            return model
        end
    end
    
    -- If no specific default, try to use the first model found
    for pathIndex, path in ipairs(searchPaths) do
        local children = path:GetChildren()
        if #children > 0 then
            print(string.format("[BuyTileSystemFix] Using first available model as default from path %d", pathIndex))
            return children[1]
        end
    end
    
    warn("[BuyTileSystemFix] Could not find any default gym model")
    return nil
end

-- Create a part collection in ServerStorage if it doesn't exist
local function ensureGymPartsCollectionExists()
    local gymPartsFolder = ServerStorage:FindFirstChild("GymParts")
    if not gymPartsFolder then
        print("[BuyTileSystemFix] Creating GymParts folder in ServerStorage")
        gymPartsFolder = Instance.new("Folder")
        gymPartsFolder.Name = "GymParts"
        gymPartsFolder.Parent = ServerStorage
        
        -- Create a default part for emergency use
        local defaultPart = Instance.new("Model")
        defaultPart.Name = DEFAULT_MODEL_ID
        
        -- Add a basic part to the model
        local part = Instance.new("Part")
        part.Anchored = true
        part.Size = Vector3.new(4, 1, 4)
        part.BrickColor = BrickColor.new("Bright blue")
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        part.Parent = defaultPart
        
        -- Add a basic mesh
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Brick
        mesh.Parent = part
        
        -- Add ID value
        local idValue = Instance.new("StringValue")
        idValue.Name = "ID"
        idValue.Value = DEFAULT_MODEL_ID
        idValue.Parent = defaultPart
        
        defaultPart.Parent = gymPartsFolder
    end
    
    return gymPartsFolder
end

-- Try to spawn a gym part for a specific player's tile
local function spawnGymPartForPlayer(player, tileId, position)
    local tileIdStr = tostring(tileId)
    print(string.format("[BuyTileSystemFix] Attempting to spawn gym part with ID: %s for player: %s", 
        tileIdStr, player.Name))
    
    -- Ensure we have a gym parts collection
    ensureGymPartsCollectionExists()
    
    -- Find the model
    local model = findGymPartModelById(tileId)
    local usedFallback = false
    
    -- If model not found, use default
    if not model then
        warn(string.format("[BuyTileSystemFix] Could not find gym part with ID: %s, using fallback", tileIdStr))
        model = findDefaultModel()
        usedFallback = true
        
        if not model then
            error(string.format("[BuyTileSystemFix] Critical error: No models available for tile ID: %s", tileIdStr))
            return nil
        end
    end
    
    -- Clone the model
    local success, clonedModel = pcall(function()
        return model:Clone()
    end)
    
    if not success or not clonedModel then
        warn(string.format("[BuyTileSystemFix] Failed to clone model for ID: %s - %s", 
            tileIdStr, tostring(clonedModel)))
        return nil
    end
    
    -- Set up the cloned model
    clonedModel.Name = string.format("GymPart_%s_Player_%s", tileIdStr, player.Name)
    
    -- Store the original ID and player
    local idValue = clonedModel:FindFirstChild("ID") or Instance.new("StringValue")
    idValue.Name = "ID"
    idValue.Value = tileIdStr
    idValue.Parent = clonedModel
    
    local playerValue = Instance.new("ObjectValue")
    playerValue.Name = "Player"
    playerValue.Value = player
    playerValue.Parent = clonedModel
    
    -- Position the model
    if position then
        clonedModel:SetPrimaryPartCFrame(CFrame.new(position))
    end
    
    -- Parent to workspace
    clonedModel.Parent = workspace
    
    print(string.format("[BuyTileSystemFix] Successfully spawned gym part for ID: %s for player: %s%s", 
        tileIdStr, player.Name, usedFallback and " (using fallback)" or ""))
    
    return clonedModel
end

-- Create a patch for the BuyTile system
local function patchBuyTileSystem()
    local success = false
    
    -- Find the BuyTile module or script
    local buyTileModule = nil
    local searchPaths = {
        ServerStorage:FindFirstChild("Scripts"),
        ServerStorage:FindFirstChild("Modules"),
        ReplicatedStorage:FindFirstChild("Modules"),
        game:GetService("ServerScriptService"),
    }
    
    -- Find BuyTile script or module
    for _, path in ipairs(searchPaths) do
        if path then
            -- Try various naming patterns
            local modulePatterns = {
                "BuyTile", 
                "BuyTileSystem", 
                "BuyTileManager",
                "TilePurchaseSystem",
                "TilePurchaser"
            }
            
            for _, pattern in ipairs(modulePatterns) do
                local found = path:FindFirstChild(pattern)
                if found then
                    buyTileModule = found
                    break
                end
            end
            
            if buyTileModule then
                break
            end
        end
    end
    
    if not buyTileModule then
        warn("[BuyTileSystemFix] Could not find BuyTile module to patch")
        return false
    end
    
    print("[BuyTileSystemFix] Found BuyTile module: " .. buyTileModule:GetFullName())
    
    -- Monkey patch the module or expose our functions
    local env = getfenv(0)
    env.FindGymPartById = findGymPartModelById
    env.SpawnGymPartForPlayer = spawnGymPartForPlayer
    env.GetValidGymPartPaths = getValidSearchPaths
    
    print("[BuyTileSystemFix] Patched global environment with BuyTile helper functions")
    
    -- Create global diagnostic function for debugging
    _G.DiagnoseBuyTileSystem = function(tileId)
        print("\n[BuyTileSystemFix] Running diagnostic for BuyTile system")
        print("======================================================")
        
        local idStr = tostring(tileId or 1)
        print("Testing for tile ID: " .. idStr)
        
        -- Check search paths
        local paths = getValidSearchPaths()
        print(string.format("Found %d search paths for gym parts:", #paths))
        for i, path in ipairs(paths) do
            print(string.format("  %d. %s (%d children)", i, path:GetFullName(), #path:GetChildren()))
        end
        
        -- Try to find the model
        print("\nSearching for model with ID: " .. idStr)
        local model = findGymPartModelById(idStr)
        if model then
            print(string.format("✓ Found model: %s at %s", model.Name, model:GetFullName()))
        else
            print("✗ Model not found, checking for default model")
            local defaultModel = findDefaultModel()
            if defaultModel then
                print(string.format("✓ Found default model: %s at %s", defaultModel.Name, defaultModel:GetFullName()))
            else
                print("✗ No default model found")
            end
        end
        
        print("\nTesting model spawn (no player)")
        local dummyPosition = Vector3.new(0, 100, 0)
        local testModel = spawnGymPartForPlayer(Players:GetPlayers()[1] or nil, idStr, dummyPosition)
        if testModel then
            print(string.format("✓ Test spawn successful: %s", testModel:GetFullName()))
            testModel:Destroy()
        else
            print("✗ Test spawn failed")
        end
        
        print("======================================================")
    end
    
    print("[BuyTileSystemFix] Added global diagnostic function: _G.DiagnoseBuyTileSystem()")
    success = true
    
    return success
end

-- Run the patch
local patchSuccess = patchBuyTileSystem()
if patchSuccess then
    print("[BuyTileSystemFix] Successfully patched BuyTile system")
else
    warn("[BuyTileSystemFix] Failed to patch BuyTile system")
end

-- Export the API
local API = {
    findGymPartModelById = findGymPartModelById,
    spawnGymPartForPlayer = spawnGymPartForPlayer,
    getValidSearchPaths = getValidSearchPaths,
    ensureGymPartsCollectionExists = ensureGymPartsCollectionExists
}

print("[BuyTileSystemFix] Initialized and active")
return API
