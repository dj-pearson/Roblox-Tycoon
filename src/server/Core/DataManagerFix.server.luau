--[[
    DataManagerFix.server.luau
    
    Enhances the DataManager with more robust equipment and tile restoration capabilities.
    This addresses the issue where only 1 of 7 tiles is being correctly restored.
    
    Created: April 27, 2025
]]

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Path to DataManager module, adjust if needed
local DATA_MANAGER_PATH = ServerScriptService:FindFirstChild("Core") and
                          ServerScriptService.Core:FindFirstChild("DataManager")
                          
if not DATA_MANAGER_PATH then
    warn("[DataManagerFix] DataManager not found in expected path")
    
    -- Try to locate it in other locations
    for _, possiblePath in ipairs({
        ServerScriptService.Core,
        ServerScriptService.src and ServerScriptService.src.server and ServerScriptService.src.server.Core,
        ServerScriptService:FindFirstChild("Systems")
    }) do
        if possiblePath and possiblePath:FindFirstChild("DataManager") then
            DATA_MANAGER_PATH = possiblePath.DataManager
            print("[DataManagerFix] Found DataManager at " .. possiblePath:GetFullName())
            break
        end
    end
end

-- Find the CoreRegistry
local CoreRegistry
local foundRegistry, registryResult = pcall(function()
    local possiblePaths = {
        ServerScriptService.Core.CoreRegistry,
        ServerScriptService.src and ServerScriptService.src.server and ServerScriptService.src.server.Core and 
            ServerScriptService.src.server.Core.CoreRegistry,
        ServerScriptService:FindFirstChild("Systems") and ServerScriptService.Systems.CoreRegistry
    }
    
    for _, path in ipairs(possiblePaths) do
        if path then
            return require(path)
        end
    end
    
    return nil
end)

if foundRegistry and registryResult then
    CoreRegistry = registryResult
    print("[DataManagerFix] Found CoreRegistry")
else
    warn("[DataManagerFix] Failed to find CoreRegistry: " .. tostring(registryResult))
end

-- Utility variables
local DEBUG = true
local ATTEMPTS_PER_TILE = 3  -- Number of attempts to restore each tile
local TEMPLATE_CACHE = {}    -- Cache for template gym parts

-- Debug logging
local function log(message)
    if DEBUG then
        print("[DataManagerFix] " .. message)
    end
end

-- Get gym part templates from various possible locations
local function getGymPartTemplates()
    if next(TEMPLATE_CACHE) then 
        return TEMPLATE_CACHE 
    end
    
    local templates = {}
    
    -- Check for template in ServerStorage
    local serverStorage = game:GetService("ServerStorage")
    local locations = {
        serverStorage:FindFirstChild("GymParts"),
        serverStorage:FindFirstChild("GymPartTemplates"),
        serverStorage:FindFirstChild("Templates") and serverStorage.Templates:FindFirstChild("GymParts"),
        Workspace:FindFirstChild("GymPartTemplates"),
        Workspace:FindFirstChild("Templates") and Workspace.Templates:FindFirstChild("GymParts"),
        ReplicatedStorage:FindFirstChild("GymPartTemplates"),
        ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("GymPartTemplates")
    }
    
    -- Cache all gym parts by ID
    for _, location in ipairs(locations) do
        if location then
            log("Found gym part templates in " .. location:GetFullName())
            
            -- Search for any part with ID attribute or name containing number
            for _, part in ipairs(location:GetDescendants()) do
                local id
                
                -- Try to get ID from attribute
                if part:GetAttribute("ID") then
                    id = part:GetAttribute("ID")
                elseif part:GetAttribute("Id") then
                    id = part:GetAttribute("Id")
                elseif part:GetAttribute("TileID") then
                    id = part:GetAttribute("TileID")
                elseif part:GetAttribute("TileId") then
                    id = part:GetAttribute("TileId")
                else
                    -- Try to extract ID from name
                    local nameID = string.match(part.Name, "(%d+)")
                    if nameID then
                        id = tonumber(nameID)
                    end
                end
                
                if id then
                    templates[id] = part
                    log("Cached template for ID " .. id)
                end
            end
        end
    end
    
    -- Save to cache
    TEMPLATE_CACHE = templates
    log("Cached " .. #templates .. " gym part templates")
    
    return templates
end

-- Function to create a tycoon for a player if it doesn't exist
local function ensurePlayerTycoon(player)
    if not player or not player:IsA("Player") then
        return nil
    end
    
    -- Check if player already has a tycoon
    local existingTycoon = player:FindFirstChild("Tycoon")
    if existingTycoon and existingTycoon.Value and existingTycoon.Value:IsA("Model") then
        return existingTycoon.Value
    end
    
    log("Creating tycoon for " .. player.Name)
    
    -- Find tycoon manager
    local TycoonManager
    if CoreRegistry then
        TycoonManager = CoreRegistry:GetSystem("TycoonManager")
    end
    
    -- If not found in registry, try requiring it directly
    if not TycoonManager then
        local possiblePaths = {
            ServerScriptService.Core.TycoonManager,
            ServerScriptService.src and ServerScriptService.src.server and 
                ServerScriptService.src.server.Core and ServerScriptService.src.server.Core.TycoonManager,
            ServerScriptService.Systems and ServerScriptService.Systems.TycoonManager
        }
        
        for _, path in ipairs(possiblePaths) do
            if path then
                local requireSuccess, requireResult = pcall(function() 
                    return require(path) 
                end)
                
                if requireSuccess then
                    TycoonManager = requireResult
                    break
                end
            end
        end
    end
    
    -- If found, create tycoon using TycoonManager
    if TycoonManager and TycoonManager.createTycoon then
        local tycoon = TycoonManager:createTycoon(player)
        if tycoon then
            log("Created tycoon for " .. player.Name .. " using TycoonManager")
            return tycoon
        end
    end
    
    -- Fallback: Create a basic tycoon
    local tycoon = Instance.new("Model")
    tycoon.Name = player.Name .. "_Tycoon"
    
    -- Create a reference in the player
    if not existingTycoon then
        local tycoonRef = Instance.new("ObjectValue")
        tycoonRef.Name = "Tycoon"
        tycoonRef.Value = tycoon
        tycoonRef.Parent = player
    elseif existingTycoon:IsA("ObjectValue") then
        existingTycoon.Value = tycoon
    end
    
    -- Create a basic platform
    local platform = Instance.new("Part")
    platform.Name = "Platform"
    platform.Size = Vector3.new(50, 1, 50)
    platform.Position = Vector3.new(0, 0, 0) -- This should be properly placed based on your game's tycoon layout
    platform.Anchored = true
    platform.Parent = tycoon
    
    tycoon.Parent = Workspace
    
    log("Created fallback tycoon for " .. player.Name)
    return tycoon
end

-- Function to spawn a specific gym part 
local function spawnGymPart(id, tycoon)
    if not id or not tycoon then
        return nil
    end
    
    -- Try using BuyTileSystem first
    local BuyTileSystem
    if CoreRegistry then
        BuyTileSystem = CoreRegistry:GetSystem("BuyTileSystem")
    end
    
    if BuyTileSystem and BuyTileSystem.spawnGymPart then
        local part = BuyTileSystem.spawnGymPart(id)
        if part then
            log("Spawned gym part " .. id .. " using BuyTileSystem")
            return part
        end
    end
    
    -- Try to find BuyTile module directly
    if not BuyTileSystem then
        local possiblePaths = {
            ServerScriptService.BuyTile,
            ServerScriptService.Core and ServerScriptService.Core.BuyTile,
            ServerScriptService.src and ServerScriptService.src.server and 
                ServerScriptService.src.server.Core and ServerScriptService.src.server.Core.BuyTile,
            ServerScriptService.Systems and ServerScriptService.Systems.BuyTile
        }
        
        for _, path in ipairs(possiblePaths) do
            if path then
                local requireSuccess, requireResult = pcall(function() 
                    return require(path) 
                end)
                
                if requireSuccess and requireResult and requireResult.spawnGymPart then
                    local part = requireResult.spawnGymPart(id)
                    if part then
                        log("Spawned gym part " .. id .. " using direct BuyTile module")
                        return part
                    end
                end
            end
        end
    end
    
    -- Fallback: Clone from templates
    local templates = getGymPartTemplates()
    local template = templates[id]
    
    if template then
        local clone = template:Clone()
        clone.Parent = tycoon
        
        -- Position on the platform if it exists
        local platform = tycoon:FindFirstChild("Platform")
        if platform and platform:IsA("BasePart") then
            clone:PivotTo(platform.CFrame * CFrame.new(0, platform.Size.Y/2 + 2, 0))
        end
        
        log("Spawned gym part " .. id .. " using template")
        return clone
    end
    
    log("Failed to find template for gym part " .. id)
    return nil
end

-- Enhanced version of RestorePlayerEquipment
local function EnhancedRestorePlayerEquipment(player)
    if not player then
        warn("[DataManagerFix] Cannot restore equipment for nil player")
        return false
    end
    
    log("Starting enhanced equipment restoration for " .. player.Name)
    
    -- Find DataManager
    local DataManager
    if CoreRegistry then
        DataManager = CoreRegistry:GetSystem("DataManager")
    elseif DATA_MANAGER_PATH then
        local requireSuccess, requireResult = pcall(function()
            return require(DATA_MANAGER_PATH)
        end)
        
        if requireSuccess and requireResult then
            DataManager = requireResult
        end
    end
    
    if not DataManager then
        warn("[DataManagerFix] DataManager not found, cannot restore equipment")
        return false
    end
    
    local userId = player.UserId
    
    -- Check if data is loaded
    if not DataManager.loadedData or not DataManager.loadedData[userId] then
        warn("[DataManagerFix] Player data not loaded for " .. player.Name)
        return false
    end
    
    local data = DataManager.loadedData[userId]
    
    -- Check if player has any purchased equipment
    if not data.equipmentPurchased or next(data.equipmentPurchased) == nil then
        log("No purchased equipment to restore for " .. player.Name)
        return true
    end
    
    -- Ensure player has a tycoon
    local tycoon = ensurePlayerTycoon(player)
    if not tycoon then
        warn("[DataManagerFix] Failed to create tycoon for " .. player.Name)
        return false
    end
    
    -- Get purchased tile IDs
    local purchasedTiles = {}
    for tileId, _ in pairs(data.equipmentPurchased) do
        local numericId = tonumber(tileId) or tonumber(string.match(tileId or "", "%d+"))
        if numericId then
            table.insert(purchasedTiles, numericId)
        end
    end
    
    -- Sort IDs to purchase in order
    table.sort(purchasedTiles)
    
    log("Restoring " .. #purchasedTiles .. " equipment pieces for " .. player.Name)
    
    -- Track successful spawns
    local spawnCount = 0
    local failedTiles = {}
    
    -- Spawn each tile with multiple retry attempts
    for _, tileId in ipairs(purchasedTiles) do
        local tileSuccess = false
        
        -- Try multiple times for each tile
        for attempt = 1, ATTEMPTS_PER_TILE do
            local part = spawnGymPart(tileId, tycoon)
            if part then
                spawnCount = spawnCount + 1
                log("Restored gym part " .. tileId .. " for " .. player.Name .. " on attempt " .. attempt)
                tileSuccess = true
                break
            else
                log("Failed attempt " .. attempt .. " to restore gym part " .. tileId)
                task.wait(0.5) -- Wait a bit before trying again
            end
        end
        
        if not tileSuccess then
            table.insert(failedTiles, tileId)
            warn("[DataManagerFix] Failed to restore gym part " .. tileId .. " after " .. ATTEMPTS_PER_TILE .. " attempts")
        end
        
        task.wait(0.2) -- Small delay between tiles to prevent issues
    end
    
    -- Log results
    log("Successfully restored " .. spawnCount .. "/" .. #purchasedTiles .. " equipment pieces for " .. player.Name)
    
    if #failedTiles > 0 then
        warn("[DataManagerFix] Failed to restore these tiles: " .. table.concat(failedTiles, ", "))
    end
    
    return spawnCount > 0
end

-- Override the DataManager's RestorePlayerEquipment method
local function ApplyFix()
    if not DATA_MANAGER_PATH then
        warn("[DataManagerFix] Cannot apply fix: DataManager module not found")
        return false
    end
    
    -- Try to require the DataManager module
    local requireSuccess, DataManager = pcall(function()
        return require(DATA_MANAGER_PATH)
    end)
    
    if not requireSuccess or not DataManager then
        warn("[DataManagerFix] Failed to require DataManager: " .. tostring(DataManager))
        return false
    end
    
    -- Store the original function for reference but don't use it (to avoid warning)
    -- Using '_' prefix to show it's intentionally not used
    local _originalRestoreFunction = DataManager.RestorePlayerEquipment
    
    -- Override the function
    DataManager.RestorePlayerEquipment = EnhancedRestorePlayerEquipment
    
    log("Successfully applied DataManager fix - RestorePlayerEquipment overridden")
    
    return true
end

-- Auto-apply the fix
ApplyFix()

-- Export the enhanced function for direct use
return {
    enhancedRestorePlayerEquipment = EnhancedRestorePlayerEquipment,
    getGymPartTemplates = getGymPartTemplates,
    spawnGymPart = spawnGymPart
}
