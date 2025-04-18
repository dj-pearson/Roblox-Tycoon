-- EventBridge.lua
-- Place in ServerScriptService
-- This script creates a central event system to unify all game systems

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")


-- Create the event bridge folder
local EventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
if not EventBridge then
	EventBridge = Instance.new("Folder")
	EventBridge.Name = "EventBridge"
	EventBridge.Parent = ReplicatedStorage
	print("Created EventBridge in ReplicatedStorage")
end

-- Create standard events
local events = {
	-- Economy events
	"TilePurchasedEvent", -- Fired when a player buys a tile
	"DuesCollectedEvent", -- Fired when a player collects membership dues
	"CashUpdatedEvent",   -- Fired when a player's cash changes

	-- NPC events
	"NPCSpawnedEvent",     -- Fired when an NPC spawns
	"NPCRemovedEvent",     -- Fired when an NPC is removed
	"NPCInteractionEvent", -- Fired when an NPC interacts with equipment

	-- Player events
	"PlayerJoinedGymEvent",  -- Fired when a player enters their gym
	"PlayerLeftGymEvent",    -- Fired when a player leaves their gym
	"GymLevelUpEvent",       -- Fired when a gym levels up
	"EquipmentUsedEvent",    -- Fired when a player uses equipment

	-- Special events
	"SpecialEventStartedEvent", -- Fired when a special event begins
	"SpecialEventEndedEvent",   -- Fired when a special event ends
	"MilestoneReachedEvent",    -- Fired when a player reaches a milestone
	"ChallengeCompletedEvent"   -- Fired when a player completes a challenge
}

-- Create all event objects
for _, eventName in ipairs(events) do
	if not EventBridge:FindFirstChild(eventName) then
		local event = Instance.new("RemoteEvent")
		event.Name = eventName
		event.Parent = EventBridge
		print("Created " .. eventName .. " in EventBridge")
	end
end

-- Try to load all systems
local systems = {
	EconomySystem = ServerScriptService:FindFirstChild("UnifiedGymEconomySystem"),
	NPCSystem = ServerScriptService:FindFirstChild("UnifiedNPCSystem"),
	TycoonSystem = ServerScriptService:FindFirstChild("UnifiedTycoonSystem"),
	FrontDeskSystem = ServerScriptService:FindFirstChild("UnifiedFrontDeskSystem")
}

-- Connect core events (more would be added as systems are connected)
local TilePurchasedEvent = EventBridge:FindFirstChild("TilePurchasedEvent")
if TilePurchasedEvent then
	TilePurchasedEvent.OnServerEvent:Connect(function(player, tileId)
		print(player.Name .. " purchased tile #" .. tileId .. " (via EventBridge)")

		-- Notify Economy System
		if systems.EconomySystem and systems.EconomySystem.onTilePurchased then
			systems.EconomySystem.onTilePurchased(player, tileId)
		end

		-- Notify NPC System (could spawn an NPC after purchase)
		if systems.NPCSystem and systems.NPCSystem.trySpawnNPC then
			-- Chance to spawn an NPC after purchase
			if math.random() < 0.7 then -- 70% chance
				delay(2, function() -- Small delay
					systems.NPCSystem.trySpawnNPC(player)
				end)
			end
		end

		-- Set up front desk on first purchase
		if tileId == 1 and systems.FrontDeskSystem and systems.FrontDeskSystem.handleFirstTilePurchase then
			systems.FrontDeskSystem.handleFirstTilePurchase(player)
		end
	end)
end

local DuesCollectedEvent = EventBridge:FindFirstChild("DuesCollectedEvent")
if DuesCollectedEvent then
	DuesCollectedEvent.OnServerEvent:Connect(function(player, amount)
		print(player.Name .. " collected $" .. amount .. " in dues (via EventBridge)")

		-- Notify Economy System
		if systems.EconomySystem and systems.EconomySystem.collectDues then
			systems.EconomySystem.collectDues(player)
		end
	end)
end

-- Function to manually fire server-side events
local function fireServerEvent(eventName, player, ...)
	local event = EventBridge:FindFirstChild(eventName)
	if event then
		event:FireClient(player, ...)
	end
end

-- Expose the event system to other scripts
_G.GymEventSystem = {
	fireEvent = fireServerEvent
}

print("EventBridge system initialized - connecting " .. #events .. " events")