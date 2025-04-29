--[[
    BuyTileSystem.server.luau
    
    Handles the purchasing and placement of tiles in the tycoon.
    Manages gym part spawning and ensures proper validation.
    
    Created as part of critical fixes on April 28, 2025.
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    DEBUG_MODE = true,
    GYM_PARTS_FOLDER = "GymParts",
    BUY_TILES_FOLDER = "BuyTiles",
    CACHE_TIMEOUT = 300, -- 5 minutes
    MAX_RETRIES = 3
}

-- Cache for gym parts and buy tiles
local gymPartsCache = {}
local buyTilesCache = {}
local lastCacheRefresh = 0

-- Initialize the BuyTileSystem
local BuyTileSystem = {
    initialized = false
}

-- Helper function for logging
local function log(message, isWarning, isError)
    local prefix = "[BuyTileSystem] "
    
    if isError then
        error(prefix .. message)
    elseif isWarning then
        warn(prefix .. message)
    elseif CONFIG.DEBUG_MODE then
        print(prefix .. message)
    end
end

-- Find a folder in different possible locations
local function findFolder(folderName)
    local locations = {
        ServerStorage,
        game.Workspace,
        ReplicatedStorage
    }
    
    for _, location in ipairs(locations) do
        local folder = location:FindFirstChild(folderName)
        if folder and folder:IsA("Folder") then
            return folder
        end
    end
    
    return nil
end

-- Refresh the cache of available gym parts and buy tiles
local function refreshCache()
    -- Check if cache refresh is needed
    local currentTime = os.time()
    if currentTime - lastCacheRefresh < CONFIG.CACHE_TIMEOUT and next(gymPartsCache) and next(buyTilesCache) then
        return true -- Cache is still valid
    end
    
    log("Refreshing gym parts and buy tiles cache")
    
    -- Clear existing cache
    table.clear(gymPartsCache)
    table.clear(buyTilesCache)
    
    -- Find folders
    local gymPartsFolder = findFolder(CONFIG.GYM_PARTS_FOLDER)
    local buyTilesFolder = findFolder(CONFIG.BUY_TILES_FOLDER)
    
    if not gymPartsFolder then
        log("Gym parts folder not found", true)
        
        -- Create folder if it doesn't exist
        gymPartsFolder = Instance.new("Folder")
        gymPartsFolder.Name = CONFIG.GYM_PARTS_FOLDER
        gymPartsFolder.Parent = ServerStorage
        
        log("Created gym parts folder in ServerStorage", true)
    end
    
    if not buyTilesFolder then
        log("Buy tiles folder not found", true)
        
        -- Create folder if it doesn't exist
        buyTilesFolder = Instance.new("Folder")
        buyTilesFolder.Name = CONFIG.BUY_TILES_FOLDER
        buyTilesFolder.Parent = ServerStorage
        
        log("Created buy tiles folder in ServerStorage", true)
    end
    
    -- Cache gym parts
    for _, part in ipairs(gymPartsFolder:GetChildren()) do
        local id = part:GetAttribute("ID") or part.Name
        gymPartsCache[id] = part
    end
    
    -- Cache buy tiles
    for _, tile in ipairs(buyTilesFolder:GetChildren()) do
        local id = tile:GetAttribute("TileID") or tile.Name
        buyTilesCache[id] = tile
    end
    
    log("Cached " .. #gymPartsFolder:GetChildren() .. " gym parts and " .. #buyTilesFolder:GetChildren() .. " buy tiles")
    
    -- Update last refresh time
    lastCacheRefresh = currentTime
    
    return true
end

-- Find a gym part by ID
function BuyTileSystem.findGymPart(partId)
    if not BuyTileSystem.initialized then
        BuyTileSystem.initialize()
    end
    
    -- Refresh cache if needed
    refreshCache()
    
    -- Try to get from cache
    local part = gymPartsCache[partId]
    if part then
        return part
    end
    
    -- Try using alternative IDs
    local alternativeIds = {
        tostring(partId),
        "GymPart_" .. tostring(partId),
        "Part_" .. tostring(partId)
    }
    
    for _, altId in ipairs(alternativeIds) do
        part = gymPartsCache[altId]
        if part then
            return part
        end
    end
    
    -- If still not found, do a direct search
    local gymPartsFolder = findFolder(CONFIG.GYM_PARTS_FOLDER)
    if gymPartsFolder then
        for _, child in ipairs(gymPartsFolder:GetChildren()) do
            local id = child:GetAttribute("ID") or child.Name
            if id == partId or id == tostring(partId) then
                gymPartsCache[partId] = child -- Add to cache for future use
                return child
            end
        end
    end
    
    log("Could not find gym part with ID: " .. tostring(partId), true)
    return nil
end

-- Find a buy tile by ID
function BuyTileSystem.findBuyTile(tileId)
    if not BuyTileSystem.initialized then
        BuyTileSystem.initialize()
    end
    
    -- Refresh cache if needed
    refreshCache()
    
    -- Try to get from cache
    local tile = buyTilesCache[tileId]
    if tile then
        return tile
    end
    
    -- Try using alternative IDs
    local alternativeIds = {
        tostring(tileId),
        "BuyTile_" .. tostring(tileId),
        "Tile_" .. tostring(tileId)
    }
    
    for _, altId in ipairs(alternativeIds) do
        tile = buyTilesCache[altId]
        if tile then
            return tile
        end
    end
    
    -- If still not found, do a direct search
    local buyTilesFolder = findFolder(CONFIG.BUY_TILES_FOLDER)
    if buyTilesFolder then
        for _, child in ipairs(buyTilesFolder:GetChildren()) do
            local id = child:GetAttribute("TileID") or child.Name
            if id == tileId or id == tostring(tileId) then
                buyTilesCache[tileId] = child -- Add to cache for future use
                return child
            end
        end
    end
    
    log("Could not find buy tile with ID: " .. tostring(tileId), true)
    return nil
end

-- Spawn a gym part at the specified location
function BuyTileSystem.spawnGymPart(partId, position, parent, rotation)
    if not BuyTileSystem.initialized then
        BuyTileSystem.initialize()
    end
    
    -- Default values
    position = position or Vector3.new(0, 0, 0)
    rotation = rotation or Vector3.new(0, 0, 0)
    
    -- Find the part to spawn
    local template = BuyTileSystem.findGymPart(partId)
    if not template then
        log("Failed to spawn gym part - template not found: " .. tostring(partId), true)
        return nil
    end
    
    -- Clone the part
    local part = template:Clone()
    
    -- Set position and orientation
    if part:IsA("Model") then
        part:PivotTo(CFrame.new(position) * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z)))
    else
        part.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
    end
    
    -- Set parent
    part.Parent = parent
    
    log("Spawned gym part " .. partId .. " at " .. tostring(position))
    return part
end

-- Spawn a buy tile at the specified location
function BuyTileSystem.spawnBuyTile(tileId, position, parent, rotation)
    if not BuyTileSystem.initialized then
        BuyTileSystem.initialize()
    end
    
    -- Default values
    position = position or Vector3.new(0, 0, 0)
    rotation = rotation or Vector3.new(0, 0, 0)
    
    -- Find the tile to spawn
    local template = BuyTileSystem.findBuyTile(tileId)
    if not template then
        log("Failed to spawn buy tile - template not found: " .. tostring(tileId), true)
        return nil
    end
    
    -- Clone the tile
    local tile = template:Clone()
    
    -- Set position and orientation
    if tile:IsA("Model") then
        tile:PivotTo(CFrame.new(position) * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z)))
    else
        tile.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
    end
    
    -- Set parent
    tile.Parent = parent
    
    log("Spawned buy tile " .. tileId .. " at " .. tostring(position))
    return tile
end

-- Buy a tile for a player
function BuyTileSystem.buyTile(player, tileId, gymPartId, position, tycoon)
    if not BuyTileSystem.initialized then
        BuyTileSystem.initialize()
    end
    
    if not player or not tileId then
        log("Invalid arguments for buyTile", true)
        return false
    end
    
    local tile = BuyTileSystem.spawnBuyTile(tileId, position, tycoon)
    if not tile then
        log("Failed to spawn buy tile " .. tileId .. " for " .. player.Name, true)
        return false
    end
    
    -- If a gym part is specified, spawn it as well
    if gymPartId then
        local gymPart = BuyTileSystem.spawnGymPart(gymPartId, position, tycoon)
        if not gymPart then
            log("Failed to spawn gym part " .. gymPartId .. " for " .. player.Name, true)
            -- Continue anyway, the tile was spawned
        end
    end
    
    log("Successfully bought tile " .. tileId .. " for " .. player.Name)
    return true
end

-- Initialize the system
function BuyTileSystem.initialize()
    if BuyTileSystem.initialized then
        return true
    end
    
    log("Initializing BuyTileSystem")
    
    -- Refresh the cache
    refreshCache()
    
    BuyTileSystem.initialized = true
    log("BuyTileSystem initialized successfully")
    
    return true
end

-- Return the module
return BuyTileSystem
