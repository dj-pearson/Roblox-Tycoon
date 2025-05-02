--!strict
-- RebirthSystem.server.luau
-- Consolidated rebirth system implementation
-- Created: May 2, 2025

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Core dependencies
local ServerRegistry = require(ServerScriptService.Core.Registry.ServerRegistry)
local EventBridge = ServerRegistry.getSystem("EventBridge")
local DataManager = ServerRegistry.getSystem("DataManager")

-- Local imports
local RebirthCalculator = require(script.Parent.RebirthCalculator)
local UnlockManager = require(script.Parent.UnlockManager)
local RebirthData = require(script.Parent.RebirthData)

-- Type definitions
export type RebirthState = {
    level: number,
    totalRebirths: number,
    unlockedFeatures: {[string]: boolean},
    lastRebirthTime: number,
    rebirthMultiplier: number,
}

-- Constants
local DEBUG_ENABLED = true
local DEFAULT_REBIRTH_STATE: RebirthState = {
    level = 0,
    totalRebirths = 0,
    unlockedFeatures = {},
    lastRebirthTime = 0,
    rebirthMultiplier = 1,
}

-- RebirthSystem implementation
local RebirthSystem = {
    _initialized = false,
    _playerStates = {} :: {[Player]: RebirthState},
    _config = {
        dataKey = "Rebirth_v2",
        unlockableFeatures = {}
    }
}

-- Private methods
local function logDebug(...)
    if DEBUG_ENABLED then
        print("[RebirthSystem]", ...)
    end
end

-- Get player state, creating default if needed
function RebirthSystem:_getPlayerState(player: Player): RebirthState
    if not self._playerStates[player] then
        -- Load from DataManager or use default
        local savedData = DataManager:GetPlayerData(player, self._config.dataKey)
        if savedData then
            self._playerStates[player] = RebirthData.deserialize(savedData)
        else
            self._playerStates[player] = table.clone(DEFAULT_REBIRTH_STATE)
        end
    end
    
    return self._playerStates[player]
end

-- Save player state
function RebirthSystem:_savePlayerState(player: Player)
    local state = self._playerStates[player]
    if state then
        local serialized = RebirthData.serialize(state)
        DataManager:SetPlayerData(player, self._config.dataKey, serialized)
    end
end

-- Apply rebirth effects to a player
function RebirthSystem:_applyRebirthEffects(player: Player)
    local state = self:_getPlayerState(player)
    
    -- Reset player's progress (to be customized based on game requirements)
    EventBridge:FireEvent("RebirthEffectsApplied", player, {
        level = state.level,
        multiplier = state.rebirthMultiplier
    })
    
    -- Unlock new features if available
    local newUnlocks = UnlockManager:ProcessUnlocks(player, state)
    if #newUnlocks > 0 then
        EventBridge:FireEvent("RebirthUnlocksGranted", player, newUnlocks)
    end
end

-- Validate rebirth eligibility
function RebirthSystem:_canPlayerRebirth(player: Player): (boolean, string?)
    local tycoonSystem = ServerRegistry.getSystem("TycoonSystem")
    if not tycoonSystem then
        return false, "TycoonSystem not available"
    end
    
    local playerMoney = tycoonSystem:GetPlayerMoney(player)
    local rebirthCost = self:GetRebirthCost(player)
    
    if playerMoney < rebirthCost then
        return false, "Insufficient funds"
    end
    
    return true, nil
end

-- Public methods

-- Initialize the system
function RebirthSystem:Initialize()
    if self._initialized then
        return
    end
    
    logDebug("Initializing...")
    
    -- Set up event handlers
    EventBridge:SubscribeToEvent("RequestRebirth", function(player: Player)
        self:ProcessRebirthRequest(player)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player: Player)
        if self._playerStates[player] then
            self:_savePlayerState(player)
            self._playerStates[player] = nil
        end
    end)
    
    -- Load configuration from UnlockManager
    self._config.unlockableFeatures = UnlockManager:GetFeaturesList()
    
    self._initialized = true
    logDebug("Initialization complete")
end

-- Process a rebirth request from a player
function RebirthSystem:ProcessRebirthRequest(player: Player): boolean
    local canRebirth, reason = self:_canPlayerRebirth(player)
    
    if not canRebirth then
        EventBridge:FireEvent("RebirthRejected", player, {reason = reason})
        return false
    end
    
    -- Get current state
    local state = self:_getPlayerState(player)
    
    -- Charge the player for rebirthing
    local tycoonSystem = ServerRegistry.getSystem("TycoonSystem")
    local rebirthCost = self:GetRebirthCost(player)
    tycoonSystem:DeductMoney(player, rebirthCost)
    
    -- Update rebirth state
    state.level += 1
    state.totalRebirths += 1
    state.lastRebirthTime = os.time()
    state.rebirthMultiplier = RebirthCalculator:CalculateMultiplier(state.level)
    
    -- Apply effects
    self:_applyRebirthEffects(player)
    
    -- Save updated state
    self:_savePlayerState(player)
    
    -- Notify clients
    EventBridge:FireEvent("RebirthCompleted", player, {
        newLevel = state.level,
        newMultiplier = state.rebirthMultiplier
    })
    
    return true
end

-- Get the current rebirth level for a player
function RebirthSystem:GetRebirthLevel(player: Player): number
    local state = self:_getPlayerState(player)
    return state.level
end

-- Get the current rebirth multiplier for a player
function RebirthSystem:GetRebirthMultiplier(player: Player): number
    local state = self:_getPlayerState(player)
    return state.rebirthMultiplier
end

-- Get the cost for a player's next rebirth
function RebirthSystem:GetRebirthCost(player: Player): number
    local state = self:_getPlayerState(player)
    return RebirthCalculator:CalculateCost(state.level)
end

-- Check if a player has a specific feature unlocked
function RebirthSystem:HasFeatureUnlocked(player: Player, featureId: string): boolean
    local state = self:_getPlayerState(player)
    return state.unlockedFeatures[featureId] == true
end

-- Get all unlocked features for a player
function RebirthSystem:GetUnlockedFeatures(player: Player): {string}
    local state = self:_getPlayerState(player)
    local features = {}
    
    for featureId, unlocked in pairs(state.unlockedFeatures) do
        if unlocked then
            table.insert(features, featureId)
        end
    end
    
    return features
end

-- Override a player's rebirth state (admin/debug functionality)
function RebirthSystem:SetRebirthLevel(player: Player, level: number)
    if not DEBUG_ENABLED then
        return
    end
    
    local state = self:_getPlayerState(player)
    state.level = level
    state.rebirthMultiplier = RebirthCalculator:CalculateMultiplier(level)
    
    -- Process unlocks for the new level
    UnlockManager:ProcessUnlocks(player, state)
    
    -- Save changes
    self:_savePlayerState(player)
    
    -- Notify clients
    EventBridge:FireEvent("RebirthStateUpdated", player, {
        level = state.level,
        multiplier = state.rebirthMultiplier
    })
end

-- Get summary statistics for all players (admin functionality)
function RebirthSystem:GetGlobalStatistics(): {[string]: any}
    local stats = {
        totalRebirths = 0,
        averageLevel = 0,
        playerCount = 0,
        maxLevel = 0
    }
    
    for player, state in pairs(self._playerStates) do
        stats.totalRebirths += state.totalRebirths
        stats.playerCount += 1
        stats.maxLevel = math.max(stats.maxLevel, state.level)
    end
    
    if stats.playerCount > 0 then
        stats.averageLevel = math.round(stats.totalRebirths / stats.playerCount)
    end
    
    return stats
end

-- Public API exposed to the Registry
local PublicAPI = {
    Initialize = function()
        RebirthSystem:Initialize()
    end,
    ProcessRebirthRequest = function(player: Player): boolean
        return RebirthSystem:ProcessRebirthRequest(player)
    end,
    GetRebirthLevel = function(player: Player): number
        return RebirthSystem:GetRebirthLevel(player)
    end,
    GetRebirthMultiplier = function(player: Player): number
        return RebirthSystem:GetRebirthMultiplier(player)
    end,
    GetRebirthCost = function(player: Player): number
        return RebirthSystem:GetRebirthCost(player)
    end,
    HasFeatureUnlocked = function(player: Player, featureId: string): boolean
        return RebirthSystem:HasFeatureUnlocked(player, featureId)
    end,
    GetUnlockedFeatures = function(player: Player): {string}
        return RebirthSystem:GetUnlockedFeatures(player)
    end,
    SetRebirthLevel = function(player: Player, level: number)
        RebirthSystem:SetRebirthLevel(player, level)
    end,
    GetGlobalStatistics = function(): {[string]: any}
        return RebirthSystem:GetGlobalStatistics()
    end
}

-- Register with ServerRegistry and return
return ServerRegistry.registerSystem("RebirthSystem", PublicAPI, {
    "EventBridge",
    "DataManager",
    "TycoonSystem" -- Optional dependency, but will be checked before use
})
