--!strict
--[[
    BuyTileHelper.lua
    
    A helper module to assist with tile purchasing and restoration,
    providing a safe interface to the BuyTile system.
    
    Author: Pearson
    Date: April 25, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local BuyTileHelper = {}

-- Debug printing
local function debugPrint(...)
    print("[BuyTileHelper]", ...)
end

-- Track the original system if found
local originalBuyTileSystem
local hasWarnedAboutMissing = false

-- Try to find the BuyTile system in various locations
local function findBuyTileSystem()
    -- If we've already found it, return it
    if originalBuyTileSystem then
        return originalBuyTileSystem
    end
    
    -- Possible locations for the BuyTile system
    local possibleLocations = {
        ServerScriptService:FindFirstChild("BuyTile"),
        ServerScriptService:FindFirstChild("Core"):FindFirstChild("BuyTile"),
        ReplicatedStorage:FindFirstChild("src"):FindFirstChild("server"):FindFirstChild("BuyTile"),
        ReplicatedStorage:FindFirstChild("Systems"):FindFirstChild("BuyTile"),
        ServerScriptService:FindFirstChild("Systems"):FindFirstChild("BuyTile")
    }
    
    for _, location in ipairs(possibleLocations) do
        if location then
            local success, result = pcall(function()
                return require(location)
            end)
            
            if success and result then
                debugPrint("Found BuyTile system at " .. location:GetFullName())
                return result
            end
        end
    end
    
    -- Warn only once
    if not hasWarnedAboutMissing then
        warn("BuyTileHelper: Could not find BuyTile system")
        hasWarnedAboutMissing = true
    end
    
    return nil
end

-- Safely call a function from the BuyTile system
local function safeCall(funcName, ...)
    local system = findBuyTileSystem()
    if not system then
        return nil
    end
    
    local func = system[funcName]
    if type(func) ~= "function" then
        warn("BuyTileHelper: " .. funcName .. " is not a function in the BuyTile system")
        return nil
    end
    
    local success, result = pcall(func, ...)
    if not success then
        warn("BuyTileHelper: Error calling " .. funcName .. ": " .. tostring(result))
        return nil
    end
    
    return result
end

-- Spawn a gym part based on ID
function BuyTileHelper.spawnGymPart(tileId, player)
    -- Try original system first
    local part = safeCall("spawnGymPart", tileId, player)
    if part then
        return part
    end
    
    -- If that fails, use fallback implementation
    debugPrint("Using fallback spawnGymPart for ID: " .. tostring(tileId))
    
    -- Check if player is provided
    if not player and tileId then
        -- Try to find player from workspace
        local gymPartsFolder = Workspace:FindFirstChild("GymParts")
        if gymPartsFolder then
            for _, existingPart in ipairs(gymPartsFolder:GetChildren()) do
                if existingPart:GetAttribute("ID") == tileId then
                    local ownerId = existingPart:GetAttribute("OwnerID")
                    if ownerId then
                        player = Players:GetPlayerByUserId(ownerId)
                        if player then
                            break
                        end
                    end
                end
            end
        end
    end
    
    -- Create a basic part as a placeholder
    if player then
        -- Create GymParts folder if it doesn't exist
        local gymPartsFolder = Workspace:FindFirstChild("GymParts")
        if not gymPartsFolder then
            gymPartsFolder = Instance.new("Folder")
            gymPartsFolder.Name = "GymParts"
            gymPartsFolder.Parent = Workspace
        end
        
        -- Check if this tile ID already exists
        for _, existingPart in ipairs(gymPartsFolder:GetChildren()) do
            if existingPart:GetAttribute("ID") == tileId and 
               existingPart:GetAttribute("OwnerID") == player.UserId then
                return existingPart
            end
        end
        
        -- Create new part
        local part = Instance.new("Part")
        part.Name = "GymPart_" .. tileId
        part.Size = Vector3.new(4, 1, 4)
        part.Anchored = true
        part.CanCollide = true
        
        -- Try to place it at a reasonable position
        local tycoon = player:FindFirstChild("Tycoon")
        if tycoon and tycoon.Value then
            -- Place near the tycoon
            local tycoonPos = tycoon.Value:GetPivot().Position
            part.Position = tycoonPos + Vector3.new((tileId % 5) * 5, 0, math.floor(tileId / 5) * 5)
        else
            -- Fallback position
            local playerPos = player.Character and player.Character:GetPivot().Position or Vector3.new(0, 10, 0)
            part.Position = playerPos + Vector3.new((tileId % 5) * 5, 0, math.floor(tileId / 5) * 5)
        end
        
        -- Set attributes
        part:SetAttribute("ID", tileId)
        part:SetAttribute("OwnerID", player.UserId)
        part:SetAttribute("Type", "GymPart")
        
        part.Parent = gymPartsFolder
        
        debugPrint("Created fallback gym part " .. tileId .. " for player " .. player.Name)
        return part
    end
    
    warn("Could not create fallback gym part for ID " .. tostring(tileId) .. " - no player specified")
    return nil
end

-- Initialize a player's tycoon
function BuyTileHelper.initializeTycoon(player)
    -- Try original system first
    local result = safeCall("initializeTycoon", player)
    if result then
        return result
    end
    
    -- If that fails, use fallback implementation
    debugPrint("Using fallback initializeTycoon for " .. player.Name)
    
    -- Create tycoon object value if it doesn't exist
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon then
        tycoon = Instance.new("ObjectValue")
        tycoon.Name = "Tycoon"
        tycoon.Parent = player
    end
    
    -- Create tycoon model if it doesn't exist
    local model = Workspace:FindFirstChild("Tycoon_" .. player.Name)
    if not model then
        model = Instance.new("Model")
        model.Name = "Tycoon_" .. player.Name
        
        -- Create a base platform
        local platform = Instance.new("Part")
        platform.Name = "Base"
        platform.Size = Vector3.new(25, 1, 25)
        platform.Anchored = true
        platform.CanCollide = true
        
        -- Place it at a reasonable position
        local playerPos = player.Character and player.Character:GetPivot().Position or Vector3.new(0, 10, 0)
        platform.Position = playerPos + Vector3.new(0, -2, 0)
        platform.Parent = model
        
        model.Parent = Workspace
    end
    
    -- Connect the two
    tycoon.Value = model
    
    -- Set up initial attributes
    tycoon:SetAttribute("EquipmentCount", 0)
    tycoon:SetAttribute("GymTier", 1)
    tycoon:SetAttribute("MemberCount", 0)
    tycoon:SetAttribute("VIPCount", 0)
    
    return tycoon.Value
end

-- Buy a tile
function BuyTileHelper.buyTile(player, tileId, skipCostCheck)
    -- Try original system first
    local result = safeCall("buyTile", player, tileId, skipCostCheck)
    if result then
        return result
    end
    
    -- If that fails, use fallback implementation
    debugPrint("Using fallback buyTile for " .. player.Name .. ", tile " .. tileId)
    
    -- Spawn the gym part
    local part = BuyTileHelper.spawnGymPart(tileId, player)
    if not part then
        return false
    end
    
    return true
end

-- Initialize the module
local function initialize()
    -- Try to find the original system
    originalBuyTileSystem = findBuyTileSystem()
    
    -- Create RemoteFunction for client-server communication
    local buyTileRemote = ReplicatedStorage:FindFirstChild("BuyTileRemote")
    if not buyTileRemote then
        buyTileRemote = Instance.new("RemoteFunction")
        buyTileRemote.Name = "BuyTileRemote"
        buyTileRemote.Parent = ReplicatedStorage
        
        -- Set up the OnServerInvoke handler
        buyTileRemote.OnServerInvoke = function(player, action, tileId)
            if action == "BuyTile" then
                return BuyTileHelper.buyTile(player, tileId)
            elseif action == "GetTileInfo" then
                -- Return basic info about a tile
                return {
                    id = tileId,
                    cost = 100 * tileId, -- Simple formula for cost
                    name = "Gym Equipment " .. tileId,
                    description = "A piece of gym equipment"
                }
            end
            return nil
        end
    end
    
    debugPrint("BuyTileHelper initialized")
end

initialize()
return BuyTileHelper
