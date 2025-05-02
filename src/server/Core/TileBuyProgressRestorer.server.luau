--[[
    TileBuyProgressRestorer.server.luau
    
    This module specifically handles restoring the buy tile progress state when a player rejoins.
    It ensures that previously purchased tiles are loaded correctly and that the next buyable
    tile is properly positioned, instead of restarting from tile #1.
    
    Created: May 2, 2025
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Configuration
local CONFIG = {
    DEBUG = true,
    RETRY_TILE_PLACEMENT = true,
    TILE_PLACEMENT_ATTEMPTS = 3
}

-- Debug function
local function log(message)
    if CONFIG.DEBUG then
        print("[TileBuyProgressRestorer] " .. message)
    end
end

-- Find a module
local function findModule(moduleName)
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Server"),
        ServerScriptService,
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    return nil
end

-- Safely require a module
local function safeRequire(moduleInstance, fallback)
    if not moduleInstance then
        return fallback
    end
    
    local success, result = pcall(function()
        return require(moduleInstance)
    end)
    
    if success then
        return result
    else
        warn("TileBuyProgressRestorer: Failed to require " .. moduleInstance:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
end

-- Try to load dependencies
local CoreRegistryModule = findModule("CoreRegistry")
local CoreRegistry = safeRequire(CoreRegistryModule)

local EventBridgeModule = findModule("EventBridge")
local EventBridge = safeRequire(EventBridgeModule, { fireEvent = function() end, registerEvent = function() end })

local DataManagerModule = findModule("DataManager")
local DataManager = safeRequire(DataManagerModule)

local BuyTileSystemModule = findModule("BuyTileSystem")
local BuyTileSystem = safeRequire(BuyTileSystemModule)

-- Backup methods to find systems if not directly available
if not CoreRegistry then
    log("CoreRegistry not found, looking for alternative ways to access systems")
    
    -- Try to find systems directly
    if not BuyTileSystem then
        local buyTileSystemPaths = {
            ServerScriptService.Core.BuyTileSystem,
            ServerScriptService.server.Core.BuyTileSystem,
            ServerScriptService.Server.Core.BuyTileSystem,
            ServerScriptService.src.server.Core.BuyTileSystem,
            ServerScriptService.BuyTileSystem
        }
        
        for _, path in ipairs(buyTileSystemPaths) do
            if path then
                BuyTileSystem = safeRequire(path)
                if BuyTileSystem then
                    log("Found BuyTileSystem via direct path")
                    break
                end
            end
        end
    end
    
    if not DataManager then
        local dataManagerPaths = {
            ServerScriptService.Core.DataManager,
            ServerScriptService.server.Core.DataManager,
            ServerScriptService.Server.Core.DataManager,
            ServerScriptService.src.server.Core.DataManager,
            ServerScriptService.Data.GymTycoonDataManager,
            ServerScriptService.DataManager
        }
        
        for _, path in ipairs(dataManagerPaths) do
            if path then
                DataManager = safeRequire(path)
                if DataManager then
                    log("Found DataManager via direct path")
                    break
                end
            end
        end
    end
end

-- Ensure we have necessary systems
if not BuyTileSystem then
    warn("TileBuyProgressRestorer: BuyTileSystem not found, module will not function correctly")
end

if not DataManager then
    warn("TileBuyProgressRestorer: DataManager not found, module will not function correctly")
end

-- Create module
local TileBuyProgressRestorer = {
    Version = "1.0.0",
    Initialized = false
}

-- Get the highest tile ID purchased by a player
function TileBuyProgressRestorer.getHighestTileId(player)
    if not player then return 0 end
    
    local userId = player.UserId
    local highestTileId = 0
    
    -- Try to get from DataManager
    if DataManager and typeof(DataManager.getPlayerData) == "function" then
        local playerData = DataManager.getPlayerData(player)
        
        if playerData and playerData.tiles then
            for tileId, tileInfo in pairs(playerData.tiles) do
                if tileInfo.purchased then
                    -- Convert string IDs to numbers where possible
                    local numId = tonumber(tileId) or tonumber(string.match(tileId, "%d+")) or 0
                    if numId > highestTileId then
                        highestTileId = numId
                    end
                end
            end
        end
        
        if highestTileId > 0 then
            log("Found highest tile ID for " .. player.Name .. " from DataManager: " .. highestTileId)
            return highestTileId
        end
    end
    
    -- Check tycoon folder if DataManager didn't provide results
    local tycoon = player:FindFirstChild("Tycoon")
    if tycoon and tycoon.Value then
        -- Check in purchases folder
        local purchasesFolder = tycoon.Value:FindFirstChild("Purchases")
        if purchasesFolder then
            for _, value in ipairs(purchasesFolder:GetChildren()) do
                if value:IsA("BoolValue") and value.Value then
                    local numId = tonumber(value.Name) or tonumber(string.match(value.Name, "%d+")) or 0
                    if numId > highestTileId then
                        highestTileId = numId
                    end
                end
            end
        end
        
        -- Check models in tycoon
        for _, model in ipairs(tycoon.Value:GetDescendants()) do
            if model:GetAttribute("ID") or model:GetAttribute("TileID") then
                local numId = model:GetAttribute("ID") or model:GetAttribute("TileID") or 0
                -- Handle string IDs
                if typeof(numId) == "string" then
                    numId = tonumber(numId) or tonumber(string.match(numId, "%d+")) or 0
                end
                
                if numId > highestTileId then
                    highestTileId = numId
                end
            end
        end
    end
    
    log("Found highest tile ID for " .. player.Name .. " from tycoon folder: " .. highestTileId)
    return highestTileId
end

-- Spawn the next buy tile after the player's highest purchased tile
function TileBuyProgressRestorer.spawnNextBuyTile(player)
    if not player or not BuyTileSystem then
        return false
    end
    
    -- Get highest tile ID
    local highestTileId = TileBuyProgressRestorer.getHighestTileId(player)
    local nextTileId = highestTileId + 1
    
    log("Spawning next buy tile (" .. nextTileId .. ") for " .. player.Name)
    
    -- Try to spawn the next tile
    local success = false
    
    -- Use BuyTileSystem to spawn the next tile if available
    if typeof(BuyTileSystem.spawnBuyTile) == "function" then
        success = pcall(function()
            BuyTileSystem.spawnBuyTile(nextTileId)
        end)
    end
    
    -- Fallback to original BuyTile in case BuyTileSystem doesn't have the function
    if not success then
        local originalBuyTile = safeRequire(ServerScriptService:FindFirstChild("BuyTile"))
        if originalBuyTile and typeof(originalBuyTile.spawnBuyTile) == "function" then
            success = pcall(function()
                originalBuyTile.spawnBuyTile(nextTileId)
            end)
        end
    end
    
    if success then
        log("Successfully spawned next buy tile " .. nextTileId .. " for " .. player.Name)
        return true
    else
        warn("Failed to spawn next buy tile " .. nextTileId .. " for " .. player.Name)
        return false
    end
end

-- Fix a player's buy tile progression when they join
function TileBuyProgressRestorer.fixPlayerProgression(player)
    if not player then return false end
    
    log("Fixing buy tile progression for " .. player.Name)
    
    -- First, ensure all purchased tiles are properly restored
    if BuyTileSystem and typeof(BuyTileSystem.initializePlayer) == "function" then
        pcall(function()
            BuyTileSystem.initializePlayer(player)
        end)
    end
    
    -- Then spawn the next available buy tile
    local spawnSuccess = TileBuyProgressRestorer.spawnNextBuyTile(player)
    
    -- Return whether the restoration was successful
    return spawnSuccess
end

-- Handle player joining
local function onPlayerAdded(player)
    log("Player joined: " .. player.Name)
    
    -- Wait a short time for data to load and tycoon to be created
    task.delay(3, function()
        TileBuyProgressRestorer.fixPlayerProgression(player)
    end)
end

-- Initialize the module
function TileBuyProgressRestorer.initialize()
    if TileBuyProgressRestorer.Initialized then
        return
    end
    
    log("Initializing TileBuyProgressRestorer module")
    
    -- Register with CoreRegistry if available
    if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
        CoreRegistry.registerSystem("TileBuyProgressRestorer", TileBuyProgressRestorer)
        log("Registered with CoreRegistry")
    end
    
    -- Set up player connections
    Players.PlayerAdded:Connect(onPlayerAdded)
    
    -- Process existing players
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            onPlayerAdded(player)
        end)
    end
    
    TileBuyProgressRestorer.Initialized = true
    log("Initialization complete")
    
    return true
end

-- Start initialization
TileBuyProgressRestorer.initialize()

return TileBuyProgressRestorer
