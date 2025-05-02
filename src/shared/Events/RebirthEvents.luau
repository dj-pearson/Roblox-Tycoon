--!strict
-- RebirthEvents.luau
-- Defines all event types for the rebirth system
-- Created: May 2, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Try to find EventBridge or import it
local EventBridge
pcall(function()
    EventBridge = require(ReplicatedStorage:FindFirstChild("EventBridge"))
end)

-- Event definitions
local RebirthEvents = {
    -- Server events
    
    -- Client requests a rebirth
    -- Parameters: none
    -- Handled by: RebirthSystem.server.luau
    ["RequestRebirth"] = {
        isReliable = true,
        fromClient = true,
        toServer = true,
    },
    
    -- Client requests rebirth information
    -- Parameters: none
    -- Handled by: RebirthSystem.server.luau
    ["RequestRebirthInfo"] = {
        isReliable = true,
        fromClient = true,
        toServer = true,
    },
    
    -- Client events
    
    -- Server notifies client of a completed rebirth
    -- Parameters: { newLevel: number, newMultiplier: number }
    -- Handled by: RebirthClient.client.luau
    ["RebirthCompleted"] = {
        isReliable = true,
        fromServer = true,
        toClient = true,
    },
    
    -- Server sends requested rebirth information
    -- Parameters: { level: number, multiplier: number, cost: number, canRebirth: boolean, progressInfo: table }
    -- Handled by: RebirthClient.client.luau
    ["RebirthInfoResponse"] = {
        isReliable = true,
        fromServer = true,
        toClient = true,
    },
    
    -- Server notifies client of unlocked features
    -- Parameters: Array of { id: string, name: string, description: string, icon: string? }
    -- Handled by: RebirthClient.client.luau
    ["RebirthUnlocksGranted"] = {
        isReliable = true,
        fromServer = true,
        toClient = true,
    },
    
    -- Server notifies client that rebirth was rejected
    -- Parameters: { reason: string }
    -- Handled by: RebirthClient.client.luau
    ["RebirthRejected"] = {
        isReliable = true,
        fromServer = true,
        toClient = true,
    },
    
    -- Server notifies client of rebirth state update (e.g., from admin command)
    -- Parameters: { level: number, multiplier: number }
    -- Handled by: RebirthClient.client.luau
    ["RebirthStateUpdated"] = {
        isReliable = true,
        fromServer = true,
        toClient = true,
    },
    
    -- Server informs systems of rebirth effects being applied
    -- Parameters: { level: number, multiplier: number }
    -- Handled by: Various game systems
    ["RebirthEffectsApplied"] = {
        isReliable = true,
        fromServer = true,
        toServer = true, -- Local server event
        toClient = false,
    },
    
    -- Client-side events (not networked)
    
    -- Client notifies UI components of rebirth state changes
    -- Parameters: RebirthState object
    -- Handled by: UI components
    ["RebirthUIUpdate"] = {
        isReliable = true,
        fromClient = true,
        toClient = true, -- Local client event only
        toServer = false,
    },
}

-- Register all events with EventBridge if available
if EventBridge and EventBridge.registerEvent then
    for eventName, eventConfig in pairs(RebirthEvents) do
        EventBridge.registerEvent(eventName, eventConfig)
    end
end

return RebirthEvents
