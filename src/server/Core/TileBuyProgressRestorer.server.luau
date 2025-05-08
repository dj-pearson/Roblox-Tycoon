--!strict
--[[
    TileBuyProgressRestorer.server.luau
    Handles buy tile progression state and restoration
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Configuration
local CONFIG = {
    MAX_RETRIES = 3,
    RETRY_DELAY = 1,
    SPAWN_DELAY = 0.5,
    LOG_LEVEL = "INFO" -- "DEBUG", "INFO", "WARNING", "ERROR"
}

-- State tracking
local state = {
    initialized = false,
    buyTileSystem = nil,
    dataManager = nil,
    stats = {
        totalRestorations = 0,
        successfulRestorations = 0,
        failedRestorations = 0
    }
}

-- Helper functions
local function log(message, level)
    level = level or CONFIG.LOG_LEVEL
    if level == "DEBUG" and CONFIG.LOG_LEVEL ~= "DEBUG" then return end
    print("[TileBuyProgressRestorer]", message)
end

local function findBuyTileSystem()
    -- Try using CoreRegistryBridge first if available
    local CoreRegistryBridge = require(script.Parent:FindFirstChild("CoreRegistryBridge"))
    if CoreRegistryBridge then
        local system = CoreRegistryBridge.getSystem("BuyTileSystem")
        if system then
            log("Found BuyTileSystem through CoreRegistryBridge", "DEBUG")
            return system
        end
    end
    
    -- If not found through CoreRegistryBridge, search directly
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Systems")
    }
    
    for _, path in ipairs(searchPaths) do
        if path and path:FindFirstChild("BuyTileSystem") then
            local success, module = pcall(function()
                return require(path.BuyTileSystem)
            end)
            
            if success and typeof(module) == "table" then
                log("Found BuyTileSystem at: " .. path.BuyTileSystem:GetFullName(), "DEBUG")
                return module
            end
        end
    end
    
    log("Could not find BuyTileSystem module", "ERROR")
    return nil
end

local function findDataManager()
    -- Try using CoreRegistryBridge first if available
    local CoreRegistryBridge = require(script.Parent:FindFirstChild("CoreRegistryBridge"))
    if CoreRegistryBridge then
        local system = CoreRegistryBridge.getSystem("DataManager")
        if system then
            log("Found DataManager through CoreRegistryBridge", "DEBUG")
            return system
        end
    end
    
    -- If not found through CoreRegistryBridge, search directly
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Systems")
    }
    
    for _, path in ipairs(searchPaths) do
        if path and path:FindFirstChild("DataManager") then
            local success, module = pcall(function()
                return require(path.DataManager)
            end)
            
            if success and typeof(module) == "table" then
                log("Found DataManager at: " .. path.DataManager:GetFullName(), "DEBUG")
                return module
            end
        end
    end
    
    log("Could not find DataManager module", "WARNING")
    return nil
end

-- Get highest tile ID for a player
local function getHighestTileId(player)
    if not player then return 0 end
    
    local highestId = 0
    
    -- Try to get from DataManager first
    if state.dataManager and typeof(state.dataManager.getPlayerData) == "function" then
        local playerData = state.dataManager.getPlayerData(player)
        if playerData and playerData.equipmentPurchased then
            for tileId, _ in pairs(playerData.equipmentPurchased) do
                local numericId = tonumber(tileId) or tonumber(string.match(tileId, "%d+"))
                if numericId and numericId > highestId then
                    highestId = numericId
                end
            end
        end
    end
    
    -- If no data found, check tycoon
    if highestId == 0 then
        local tycoon = player:FindFirstChild("Tycoon")
        if tycoon and tycoon.Value then
            for _, item in pairs(tycoon.Value:GetDescendants()) do
                local id = item:GetAttribute("ID")
                if id and tonumber(id) and tonumber(id) > highestId then
                    highestId = tonumber(id)
                end
            end
        end
    end
    
    return highestId
end

-- Spawn next buy tile for a player
local function spawnNextBuyTile(player)
    if not player or not state.buyTileSystem then
        return false
    end
    
    -- Get highest tile ID
    local highestTileId = getHighestTileId(player)
    local nextTileId = highestTileId + 1
    
    log("Spawning next buy tile (" .. nextTileId .. ") for " .. player.Name, "INFO")
    
    -- Try to spawn the next tile
    local success = false
    
    -- Use BuyTileSystem to spawn the next tile if available
    if typeof(state.buyTileSystem.spawnBuyTile) == "function" then
        success = pcall(function()
            state.buyTileSystem.spawnBuyTile(nextTileId)
        end)
    end
    
    if success then
        log("Successfully spawned next buy tile " .. nextTileId .. " for " .. player.Name, "INFO")
        state.stats.successfulRestorations = state.stats.successfulRestorations + 1
        return true
    else
        log("Failed to spawn next buy tile " .. nextTileId .. " for " .. player.Name, "WARNING")
        state.stats.failedRestorations = state.stats.failedRestorations + 1
        return false
    end
end

-- Fix a player's buy tile progression
local function fixPlayerProgression(player)
    if not player then return false end
    
    log("Fixing buy tile progression for " .. player.Name, "INFO")
    state.stats.totalRestorations = state.stats.totalRestorations + 1
    
    -- Get the tycoon
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then
        log("No valid tycoon found for " .. player.Name, "WARNING")
        return false
    end
    
    -- Get highest tile ID
    local highestId = getHighestTileId(player)
    
    -- If this is a new player (no purchases), make sure first buy tile is visible
    if highestId == 0 then
        -- Check if tile 1 already exists in tycoon
        local existingTile1 = false
        for _, obj in pairs(tycoon.Value:GetDescendants()) do
            if (obj.Name:match("BuyTile") or obj.Name:match("Buy Tile")) and obj:GetAttribute("ID") == 1 then
                existingTile1 = true
                break
            end
        end
        
        -- If not, spawn tile 1
        if not existingTile1 then
            log("First-time player, ensuring BuyTile 1 is available", "INFO")
            return spawnNextBuyTile(player)
        end
    else
        -- Existing player, make sure the next buy tile is available
        local nextId = highestId + 1
        
        -- Check if next tile already exists in tycoon
        local existingNextTile = false
        for _, obj in pairs(tycoon.Value:GetDescendants()) do
            if (obj.Name:match("BuyTile") or obj.Name:match("Buy Tile")) and obj:GetAttribute("ID") == nextId then
                existingNextTile = true
                break
            end
        end
        
        -- If not, spawn next tile
        if not existingNextTile then
            log("Ensuring next BuyTile " .. nextId .. " is available", "INFO")
            return spawnNextBuyTile(player)
        end
    end
    
    return true
end

-- Initialize the restorer
local function initialize()
    if state.initialized then return true end
    
    log("Initializing TileBuyProgressRestorer...", "INFO")
    
    -- Find required systems
    state.buyTileSystem = findBuyTileSystem()
    state.dataManager = findDataManager()
    
    if not state.buyTileSystem then
        log("Failed to find BuyTileSystem", "ERROR")
        return false
    end
    
    -- Set up player joining handler
    Players.PlayerAdded:Connect(function(player)
        task.delay(CONFIG.SPAWN_DELAY, function()
            fixPlayerProgression(player)
        end)
    end)
    
    -- Fix progression for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            fixPlayerProgression(player)
        end)
    end
    
    state.initialized = true
    log("TileBuyProgressRestorer initialized successfully", "INFO")
    return true
end

-- Public API
return {
    initialize = initialize,
    fixPlayerProgression = fixPlayerProgression,
    getStats = function() return state.stats end
}
