--!strict
--[[
    EventSystemExamples.luau
    
    This file contains examples of how to use the new Event System,
    including migration patterns from the legacy event system.
    
    This is NOT meant to be required in production code - it's only
    for educational purposes.
    
    Created: May 2, 2025
]]

-- This would be in a real script:
-- local ServerEvents = require(ServerScriptService.src.server.Core.Events.ServerEvents).get()
-- local ClientEvents = require(PlayerScripts.src.client.Core.Events.ClientEvents).get()
-- local EventMigration = require(ReplicatedStorage.src.shared.Events.EventMigration)

-----------------------------------------
-- Example 1: Basic Event Usage (New API)
-----------------------------------------

-- SERVER CODE
local function serverExample1()
    local ServerEvents = require(game:GetService("ServerScriptService").src.server.Core.Events.ServerEvents).get()
    
    -- Create a player joined event handler with normal priority
    local joinSubscription = ServerEvents:subscribe("player.joined", function(event)
        print(event.data.player.Name .. " joined the game")
        
        -- We can check properties of the event
        if event.data.returning then
            print("Welcome back, " .. event.data.player.Name .. "!")
        else
            print("Welcome to Gym Tycoon, " .. event.data.player.Name .. "!")
        end
        
        -- Return true to continue event propagation (or false to cancel if event is cancelable)
        return true
    end)
    
    -- Create a high-priority handler that will run first
    local highPrioritySubscription = ServerEvents:subscribe("player.joined", function(event)
        print("HIGH PRIORITY: Player joined: " .. event.data.player.Name)
        return true
    end, ServerEvents.PRIORITIES.HIGH)
    
    -- Connect to Players service to emit our custom event
    game:GetService("Players").PlayerAdded:Connect(function(player)
        -- Emit event with player data
        ServerEvents:emit("player.joined", {
            player = player,
            returning = false, -- This would check player data in a real scenario
            joinTime = os.time()
        })
    end)
    
    -- Later, we can unsubscribe
    wait(600) -- 10 minutes later
    joinSubscription:unsubscribe()
    highPrioritySubscription:unsubscribe()
end

-- CLIENT CODE
local function clientExample1()
    local ClientEvents = require(game:GetService("Players").LocalPlayer.PlayerScripts.src.client.Core.Events.ClientEvents).get()
    
    -- Subscribe to UI events
    local buttonClickSubscription = ClientEvents:subscribe("ui.button.clicked", function(event)
        print("Button clicked: " .. event.data.buttonId)
        
        -- We can perform different actions based on the button
        if event.data.buttonId == "PurchaseButton" then
            -- Handle purchase logic
        elseif event.data.buttonId == "SettingsButton" then
            -- Open settings
        end
        
        return true
    end)
    
    -- We can pause subscriptions temporarily
    buttonClickSubscription:pause()
    
    -- And resume them later
    buttonClickSubscription:resume()
    
    -- Check if a subscription is paused
    if buttonClickSubscription:isPaused() then
        print("Button click subscription is paused")
    end
    
    -- We can emit UI events when the player interacts with UI
    local function onButtonClicked(buttonId)
        ClientEvents:emit("ui.button.clicked", {
            buttonId = buttonId,
            clickTime = os.time()
        })
    end
end

-----------------------------------------
-- Example 2: Migration from Legacy Events
-----------------------------------------

-- SERVER CODE
local function serverExample2()
    local ServerEvents = require(game:GetService("ServerScriptService").src.server.Core.Events.ServerEvents).get()
    local EventMigration = require(game:GetService("ReplicatedStorage").src.shared.Events.EventMigration)
    
    -- LEGACY APPROACH (old codebase):
    -- local purchaseEvent = ReplicatedStorage.RemoteEvents.EquipmentPurchase
    -- purchaseEvent.OnServerEvent:Connect(function(player, equipmentId, amount)
    --     -- Handle purchase
    -- end)
    
    -- NEW APPROACH WITH MIGRATION:
    -- Connect to legacy event but forward to new system
    EventMigration:ConnectLegacyEvent("EquipmentPurchase", function(player, equipmentId, amount)
        print("Legacy event received: Player " .. player.Name .. " purchased " .. equipmentId)
        -- Legacy handling can still be here for backward compatibility
    end)
    
    -- Also connect to new event - this will receive both direct calls
    -- AND forwarded events from the legacy system
    ServerEvents:subscribe("tycoon.equipment.purchase", function(event)
        print("New event system: Player purchased equipment")
        
        -- If this came from a legacy event, the data will be structured like this:
        if event.data.source == "legacy_event" then
            local player = event.data.player
            local equipmentId = event.data.args[1]
            local amount = event.data.args[2]
            
            print("Legacy purchase: " .. player.Name .. " bought " .. equipmentId)
        else
            -- If direct call to new API, the data would be structured like this:
            local player = event.data.player
            local equipmentId = event.data.equipmentId
            local amount = event.data.amount
            
            print("New API purchase: " .. player.Name .. " bought " .. equipmentId)
        end
        
        return true
    end)
    
    -- SENDING EVENTS - firing both legacy and new event systems
    local function processPurchase(player, equipmentId, amount)
        -- Legacy way (now wrapped to also fire new event)
        EventMigration:FireLegacyEvent("EquipmentPurchase", player, equipmentId, amount)
        
        -- Or just use the new system directly:
        ServerEvents:emit("tycoon.equipment.purchase", {
            player = player,
            equipmentId = equipmentId,
            amount = amount,
            timestamp = os.time()
        })
    end
end

-- CLIENT CODE
local function clientExample2()
    local ClientEvents = require(game:GetService("Players").LocalPlayer.PlayerScripts.src.client.Core.Events.ClientEvents).get()
    local EventMigration = require(game:GetService("ReplicatedStorage").src.shared.Events.EventMigration)
    
    -- LEGACY APPROACH (old codebase):
    -- local resourceEvent = ReplicatedStorage.RemoteEvents.ResourceUpdate
    -- resourceEvent.OnClientEvent:Connect(function(resourceType, newAmount)
    --     -- Update UI
    -- end)
    
    -- NEW APPROACH WITH MIGRATION:
    -- Connect to legacy event but forward to new system
    EventMigration:ConnectLegacyEvent("ResourceUpdate", function(resourceType, newAmount)
        print("Legacy resource update: " .. resourceType .. " = " .. newAmount)
        -- Legacy UI updates could still happen here
    end)
    
    -- Also use the new event system
    ClientEvents:subscribe("economy.resource.update", function(event)
        print("New system resource update")
        
        if event.data.source == "legacy_event" then
            -- Handle data coming from legacy format
            local resourceType = event.data.args[1]
            local newAmount = event.data.args[2]
            print("Resource from legacy: " .. resourceType .. " = " .. newAmount)
        else
            -- Handle data in the new format
            local resourceType = event.data.resourceType
            local newAmount = event.data.amount
            print("Resource from new API: " .. resourceType .. " = " .. newAmount)
        end
        
        return true
    end)
    
    -- SENDING EVENTS TO SERVER
    local function requestResourcePurchase(resourceType, amount)
        -- Legacy way (now wrapped to also fire new event)
        EventMigration:FireLegacyEvent("PurchaseResource", resourceType, amount)
        
        -- Or use the new system directly
        ClientEvents:emit("economy.resource.purchase.request", {
            resourceType = resourceType,
            amount = amount,
            timestamp = os.time()
        })
    end
end

-----------------------------------------
-- Example 3: Advanced Features
-----------------------------------------

local function advancedFeatures()
    local ServerEvents = require(game:GetService("ServerScriptService").src.server.Core.Events.ServerEvents).get()
    
    -- Middleware for logging all events
    local loggingMiddleware = function(eventData, next)
        print("EVENT: " .. eventData.name .. " fired at " .. os.time())
        
        -- Call the next middleware or handlers
        next(eventData)
    end
    
    -- Add middleware globally
    ServerEvents:addGlobalMiddleware(loggingMiddleware)
    
    -- Use middleware for a specific event
    ServerEvents:addEventMiddleware("player.levelUp", function(eventData, next)
        -- Validate level data
        if eventData.data.newLevel <= eventData.data.oldLevel then
            warn("Invalid level up! New level must be higher than old level")
            return -- Stop processing
        end
        
        -- Transform data
        eventData.data.levelGain = eventData.data.newLevel - eventData.data.oldLevel
        
        -- Continue processing
        next(eventData)
    end)
    
    -- Event with cancellation
    ServerEvents:subscribe("player.purchaseAttempt", function(event)
        -- Make this event cancelable
        event.cancelable = true
        
        -- Check if player has enough currency
        if event.data.playerCurrency < event.data.cost then
            print("Purchase canceled: Not enough currency")
            return false -- Cancel the event
        end
        
        print("Purchase approved!")
        return true -- Continue event propagation
    end)
    
    -- Create type schema for a specific event
    local purchaseSchema = {
        player = function(v) return typeof(v) == "Instance" and v:IsA("Player") end,
        itemId = function(v) return typeof(v) == "string" end,
        cost = function(v) return typeof(v) == "number" and v >= 0 end
    }
    
    -- Register the schema
    ServerEvents:registerEventSchema("player.purchase", purchaseSchema)
end

-- These functions are examples only and should not be called directly
-- in a real module. They would be distributed in the appropriate scripts.
return {
    serverExample1 = serverExample1,
    clientExample1 = clientExample1,
    serverExample2 = serverExample2,
    clientExample2 = clientExample2,
    advancedFeatures = advancedFeatures
}
