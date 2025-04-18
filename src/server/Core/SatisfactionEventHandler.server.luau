--[[
    SatisfactionEventHandler.luau
    Handles events and remote calls for the member satisfaction system
    Place in ServerScriptService/Core
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get references to systems
local CoreRegistry = require(script.Parent:FindFirstChild("CoreRegistry"))
local EventBridge
local MemberSatisfactionSystem

-- Configuration
local CONFIG = {
    debug = true
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[Satisfaction Event Handler]", ...)
    end
end

-- Setup event connections
local function setupEventConnections()
    if not EventBridge then
        debugPrint("EventBridge not found")
        return false
    end
    
    -- Handle client requests for satisfaction data
    EventBridge:registerClientEvent("RequestSatisfactionData", function(player)
        if not MemberSatisfactionSystem then return end
        
        -- Get satisfaction data
        local tycoon = MemberSatisfactionSystem:_getPlayerTycoon(player)
        if not tycoon then return end
        
        -- Send data to client
        EventBridge:fireClient("SatisfactionUpdated", player, {
            satisfaction = tycoon:GetAttribute("MemberSatisfaction") or 75,
            cleanliness = tycoon:GetAttribute("Cleanliness") or 50,
            equipmentQuality = tycoon:GetAttribute("EquipmentQuality") or 100,
            revenueFactor = tycoon:GetAttribute("SatisfactionRevenueFactor") or 1.0,
            retentionFactor = tycoon:GetAttribute("MemberRetentionFactor") or 0.95
        })
        
        debugPrint("Sent satisfaction data to " .. player.Name)
        return true
    end)
    
    -- Register client request to improve cleanliness
    EventBridge:registerClientEvent("ImproveCleanliness", function(player, amount)
        if not MemberSatisfactionSystem then return end
        if not amount or typeof(amount) ~= "number" then return end
        
        -- Prevent abuse
        amount = math.clamp(amount, 0, 100)
        
        return MemberSatisfactionSystem:ImproveCleanliness(player, amount)
    end)
    
    -- Register client request to improve equipment quality
    EventBridge:registerClientEvent("ImproveEquipmentQuality", function(player, amount)
        if not MemberSatisfactionSystem then return end
        if not amount or typeof(amount) ~= "number" then return end
        
        -- Prevent abuse
        amount = math.clamp(amount, 0, 100)
        
        return MemberSatisfactionSystem:ImproveEquipmentQuality(player, amount)
    end)
    
    -- Register an event for when cleanliness changes
    EventBridge:registerEvent("CleanlinessUpdated", function(player, newCleanliness)
        -- This event is for other systems to listen to
    end)
    
    -- Register an event for when equipment quality changes
    EventBridge:registerEvent("EquipmentQualityUpdated", function(player, newQuality)
        -- This event is for other systems to listen to
    end)
    
    debugPrint("Event connections setup complete")
    return true
end

-- Main initialization
local function initialize()
    debugPrint("Initializing satisfaction event handler...")
    
    -- Wait for required systems
    local attempts = 0
    while (not EventBridge or not MemberSatisfactionSystem) and attempts < 10 do
        EventBridge = CoreRegistry:getSystem("EventBridge")
        MemberSatisfactionSystem = CoreRegistry:getSystem("MemberSatisfactionSystem")
        
        if not EventBridge or not MemberSatisfactionSystem then
            task.wait(1)
            attempts = attempts + 1
        end
    end
    
    if not EventBridge then
        warn("Failed to get EventBridge after " .. attempts .. " attempts")
        return false
    end
    
    if not MemberSatisfactionSystem then
        warn("Failed to get MemberSatisfactionSystem after " .. attempts .. " attempts")
        return false
    end
    
    -- Set up event connections
    setupEventConnections()
    
    debugPrint("Satisfaction event handler initialized")
    return true
end

-- Start initialization
task.spawn(initialize)