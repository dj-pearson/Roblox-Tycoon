--!strict
--[[
    BuyTileSystemFixer.server.luau
    Comprehensive fixes for BuyTile system issues
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Configuration
local CONFIG = {
    MAX_RETRIES = 3,
    RETRY_DELAY = 1,
    MODEL_FIX_DELAY = 0.5,
    HEALTH_CHECK_INTERVAL = 30,
    LOG_LEVEL = "INFO" -- "DEBUG", "INFO", "WARNING", "ERROR"
}

-- State tracking
local state = {
    initialized = false,
    buyTileSystem = nil,
    originalFunctions = {},
    stats = {
        totalFixes = 0,
        successfulFixes = 0,
        failedFixes = 0,
        retryAttempts = 0
    }
}

-- Helper functions
local function log(message, level)
    level = level or CONFIG.LOG_LEVEL
    if level == "DEBUG" and CONFIG.LOG_LEVEL ~= "DEBUG" then return end
    print("[BuyTileSystemFixer]", message)
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

-- Fix model positioning
local function fixModelPosition(model, tile)
    if not model or not tile then return false end
    
    -- Skip if already fixed
    if model:GetAttribute("PositionFixed") then return true end
    
    -- Get tile position
    local tilePosition = tile:GetPivot().Position
    
    -- Calculate final position
    local offsetX = model:GetAttribute("OffsetX") or 0
    local offsetY = model:GetAttribute("OffsetY") or 0
    local offsetZ = model:GetAttribute("OffsetZ") or 0
    local rotationY = model:GetAttribute("RotationY") or 0
    
    local finalPosition = tilePosition + Vector3.new(offsetX, offsetY, offsetZ)
    local finalCFrame = CFrame.new(finalPosition) * CFrame.Angles(0, math.rad(rotationY), 0)
    
    -- Position the model
    if model:IsA("Model") then
        if model.PrimaryPart then
            model:PivotTo(finalCFrame)
        else
            -- Find largest part to use as reference
            local largestPart = nil
            local largestSize = 0
            
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    local size = part.Size.Magnitude
                    if size > largestSize then
                        largestSize = size
                        largestPart = part
                    end
                end
            end
            
            if largestPart then
                model:PivotTo(finalCFrame)
            else
                log("Could not find suitable part for positioning model: " .. model:GetFullName(), "WARNING")
                return false
            end
        end
    elseif model:IsA("BasePart") then
        model.CFrame = finalCFrame
    else
        log("Unsupported object type for positioning: " .. model:GetFullName(), "WARNING")
        return false
    end
    
    -- Mark as fixed
    model:SetAttribute("PositionFixed", true)
    model:SetAttribute("LastFixTimestamp", os.time())
    
    return true
end

-- Fix all models for a player
local function fixModelsForPlayer(player)
    if not player or not player:IsA("Player") then return false end
    
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then
        log("Player " .. player.Name .. " has no tycoon set up yet", "WARNING")
        return false
    end
    
    local modelsFixed = 0
    
    -- Find all BuyTiles
    local buyTiles = {}
    for _, obj in pairs(tycoon.Value:GetDescendants()) do
        if obj.Name:match("^BuyTile") or obj:GetAttribute("IsBuyTile") or obj:GetAttribute("ID") then
            table.insert(buyTiles, obj)
        end
    end
    
    -- Fix models in each BuyTile
    for _, tile in pairs(buyTiles) do
        for _, child in pairs(tile:GetChildren()) do
            if (child:IsA("Model") or child:IsA("BasePart")) and 
               not (child.Name == "BillboardGui" or child.Name == "ClickDetector" or child.Name == "BuyTilePart" or 
                    child:IsA("Script") or child:IsA("LocalScript") or child:IsA("SpecialMesh")) then
                if fixModelPosition(child, tile) then
                    modelsFixed = modelsFixed + 1
                end
            end
        end
    end
    
    log("Fixed " .. modelsFixed .. " models for player " .. player.Name, "INFO")
    return modelsFixed > 0
end

-- Patch BuyTileSystem functions
local function patchBuyTileSystem()
    if not state.buyTileSystem then
        log("No BuyTileSystem found to patch", "ERROR")
        return false
    end
    
    -- Store original functions
    state.originalFunctions = {
        spawnGymPart = state.buyTileSystem.spawnGymPart,
        buyTile = state.buyTileSystem.buyTile,
        spawnBuyTile = state.buyTileSystem.spawnBuyTile
    }
    
    -- Patch spawnGymPart
    if typeof(state.originalFunctions.spawnGymPart) == "function" then
        state.buyTileSystem.spawnGymPart = function(tileId: number, args: {any}?)
            local result
            if args then
                result = state.originalFunctions.spawnGymPart(tileId, table.unpack(args))
            else
                result = state.originalFunctions.spawnGymPart(tileId)
            end
            
            -- Schedule a delayed fix
            task.delay(CONFIG.MODEL_FIX_DELAY, function()
                -- Find the player from the arguments or context
                local player
                if args and #args > 0 and typeof(args[1]) == "Instance" and args[1]:IsA("Player") then
                    player = args[1]
                end
                
                if player then
                    fixModelsForPlayer(player)
                end
            end)
            
            return result
        end
        log("Patched spawnGymPart function", "INFO")
    end
    
    -- Patch buyTile
    if typeof(state.originalFunctions.buyTile) == "function" then
        state.buyTileSystem.buyTile = function(player, tileId, ...)
            local success, result = state.originalFunctions.buyTile(player, tileId, ...)
            
            if success then
                task.delay(CONFIG.MODEL_FIX_DELAY, function()
                    fixModelsForPlayer(player)
                end)
            end
            
            return success, result
        end
        log("Patched buyTile function", "INFO")
    end
    
    -- Patch spawnBuyTile
    if typeof(state.originalFunctions.spawnBuyTile) == "function" then
        state.buyTileSystem.spawnBuyTile = function(tileId, ...)
            local result = state.originalFunctions.spawnBuyTile(tileId, ...)
            
            -- Schedule a delayed fix for all players
            task.delay(CONFIG.MODEL_FIX_DELAY, function()
                for _, player in ipairs(Players:GetPlayers()) do
                    fixModelsForPlayer(player)
                end
            end)
            
            return result
        end
        log("Patched spawnBuyTile function", "INFO")
    end
    
    return true
end

-- Initialize the fixer
local function initialize()
    if state.initialized then return true end
    
    log("Initializing BuyTileSystemFixer...", "INFO")
    
    -- Find BuyTileSystem
    state.buyTileSystem = findBuyTileSystem()
    if not state.buyTileSystem then
        log("Failed to find BuyTileSystem", "ERROR")
        return false
    end
    
    -- Apply patches
    if not patchBuyTileSystem() then
        log("Failed to patch BuyTileSystem", "ERROR")
        return false
    end
    
    -- Set up periodic health check
    task.spawn(function()
        while true do
            task.wait(CONFIG.HEALTH_CHECK_INTERVAL)
            
            -- Check if BuyTileSystem is still available
            if not state.buyTileSystem then
                log("BuyTileSystem no longer available, attempting to reinitialize", "WARNING")
                initialize()
            end
        end
    end)
    
    state.initialized = true
    log("BuyTileSystemFixer initialized successfully", "INFO")
    return true
end

-- Public API
return {
    initialize = initialize,
    fixModelsForPlayer = fixModelsForPlayer,
    getStats = function() return state.stats end
} 