-- RebirthClient.luau
-- Client-side controller for the rebirth system
-- Place in StarterPlayer/StarterPlayerScripts/Core

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Import client-side systems
local ClientRegistry = require(script.Parent.ClientRegistry)
local ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")
local UIManager = ClientRegistry.getSystem("UIManager")
local NotificationSystem = ClientRegistry.getSystem("NotificationSystem")

-- Configuration
local CONFIG = {
    debugEnabled = true,
    rebirthRemoteName = "RebirthRemote"
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[RebirthClient]", ...)
    end
end

-- Main rebirth client system
local RebirthClient = {
    -- Internal state
    initialized = false,
    rebirthRemote = nil,
    rebirthCount = 0,
    rebirthCost = 100000,
    rebirthMultiplier = 0.1
}

-- Initialize the client
function RebirthClient:initialize()
    if self.initialized then return true end
    log("Initializing RebirthClient...")
    
    -- Get remote event
    self.rebirthRemote = ReplicatedStorage:WaitForChild(CONFIG.rebirthRemoteName, 10)
    if not self.rebirthRemote then
        warn("RebirthClient: Failed to find rebirth remote event")
        return false
    end
    
    -- Set up event handlers
    self:setupEventHandlers()
    
    -- Request initial rebirth information from the server
    task.spawn(function()
        task.wait(1) -- Wait a moment for connections to establish
        self:requestRebirthInfo()
    end)
    
    self.initialized = true
    log("RebirthClient initialized")
    return true
end

-- Set up event handlers
function RebirthClient:setupEventHandlers()
    -- Listen for server rebirth responses
    if not self.rebirthRemote then return end
    
    self.rebirthRemote.OnClientEvent:Connect(function(messageType, data)
        self:handleRebirthResponse(messageType, data)
    end)
    
    -- Listen for client event bridge events
    ClientEventBridge.connectEvent("TycoonDataUpdated", function(tycoonData)
        -- Update rebirth UI if tycoon data changes
        if tycoonData and tycoonData.RebirthCount then
            self.rebirthCount = tycoonData.RebirthCount
            ClientEventBridge.fireEvent("RebirthDataUpdated", {
                count = self.rebirthCount,
                cost = self.rebirthCost,
                multiplier = self.rebirthMultiplier
            })
        end
    end)
    
    log("Event handlers set up")
end

-- Handle responses from the server about rebirth
function RebirthClient:handleRebirthResponse(messageType, data)
    log("Received rebirth response:", messageType)
    
    if messageType == "RebirthSuccess" then
        -- Update local data
        if data and data.rebirthCount ~= nil then
            self.rebirthCount = data.rebirthCount
        end
        if data and data.newMultiplier ~= nil then
            self.rebirthMultiplier = data.newMultiplier
        end
        
        -- Show success notification
        if NotificationSystem then
            NotificationSystem.showNotification({
                title = "Rebirth Complete",
                message = "You've successfully rebirthed! Your new rebirth level is " .. self.rebirthCount,
                duration = 5,
                type = "Success"
            })
        end
        
        -- Fire event for any listening systems
        ClientEventBridge.fireEvent("RebirthCompleted", {
            count = self.rebirthCount,
            multiplier = self.rebirthMultiplier
        })
        
    elseif messageType == "NotEnoughCash" then
        -- Show error notification
        if NotificationSystem then
            NotificationSystem.showNotification({
                title = "Rebirth Failed",
                message = "You need $" .. data.required .. " to rebirth. You have $" .. data.current,
                duration = 3,
                type = "Error"
            })
        end
        
    elseif messageType == "RebirthInfo" then
        -- Update local data with server values
        if data.cost then 
            self.rebirthCost = data.cost 
        end
        if data.rebirthCount then 
            self.rebirthCount = data.rebirthCount 
        end
        if data.multiplier then 
            self.rebirthMultiplier = data.multiplier 
        end
        
        -- Fire update event
        ClientEventBridge.fireEvent("RebirthDataUpdated", {
            count = self.rebirthCount,
            cost = self.rebirthCost,
            multiplier = self.rebirthMultiplier
        })
    end
end

-- Request rebirth info from server
function RebirthClient:requestRebirthInfo()
    if not self.rebirthRemote then return end
    
    log("Requesting rebirth information")
    self.rebirthRemote:FireServer("GetInfo")
end

-- Request rebirth from server
function RebirthClient:requestRebirth()
    if not self.rebirthRemote then return end
    
    log("Requesting rebirth")
    self.rebirthRemote:FireServer()
end

-- Get current rebirth count
function RebirthClient:getRebirthCount()
    return self.rebirthCount
end

-- Get current rebirth cost
function RebirthClient:getRebirthCost()
    return self.rebirthCost
end

-- Get current rebirth multiplier
function RebirthClient:getRebirthMultiplier()
    return self.rebirthMultiplier
end

-- Create public API
local PublicAPI = {
    initialize = function()
        return RebirthClient:initialize()
    end,
    
    requestRebirth = function()
        return RebirthClient:requestRebirth()
    end,
    
    getRebirthCount = function()
        return RebirthClient:getRebirthCount()
    end,
    
    getRebirthCost = function()
        return RebirthClient:getRebirthCost()
    end,
    
    getRebirthMultiplier = function()
        return RebirthClient:getRebirthMultiplier()
    end
}

-- Register with ClientRegistry
return ClientRegistry.registerSystem("RebirthClient", PublicAPI, {"ClientEventBridge", "UIManager", "NotificationSystem"})