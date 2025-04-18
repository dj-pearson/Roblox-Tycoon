--[[
    SatisfactionClient.luau
    Client-side controller for the member satisfaction system
    Place in StarterPlayer/StarterPlayerScripts/ClientCore
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Import client-side systems
local ClientRegistry
local ClientEventBridge
local UIManager
local NotificationSystem

-- Configuration
local CONFIG = {
    debugEnabled = true,
    uiUpdateCooldown = 1, -- Prevent UI updates more frequently than this
    satisfactionLevels = {
        {min = 90, name = "Excellent", color = Color3.fromRGB(0, 200, 0)},
        {min = 70, name = "Good", color = Color3.fromRGB(100, 200, 0)},
        {min = 50, name = "Average", color = Color3.fromRGB(200, 200, 0)},
        {min = 30, name = "Poor", color = Color3.fromRGB(200, 100, 0)},
        {min = 0, name = "Terrible", color = Color3.fromRGB(200, 0, 0)}
    },
    memberLeftThreshold = 5 -- Show notification when this many members leave at once
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[SatisfactionClient]", ...)
    end
end

-- Main satisfaction client system
local SatisfactionClient = {
    -- Internal state
    initialized = false,
    lastUIUpdate = 0,
    satisfactionData = {
        satisfaction = 75,
        cleanliness = 50,
        equipmentQuality = 100,
        revenueFactor = 1.0,
        retentionFactor = 0.95
    }
}

-- Initialize the client
function SatisfactionClient:initialize()
    if self.initialized then return true end
    log("Initializing SatisfactionClient...")
    
    -- Get dependencies
    ClientRegistry = self.ClientRegistry
    ClientEventBridge = ClientRegistry:getSystem("ClientEventBridge")
    UIManager = ClientRegistry:getSystem("UIManager")
    NotificationSystem = ClientRegistry:getSystem("NotificationSystem")
    
    -- Set up event handlers
    self:setupEventHandlers()
    
    -- Request initial satisfaction data from server
    task.spawn(function()
        task.wait(1) -- Wait a moment for connections to establish
        self:requestSatisfactionData()
    end)
    
    self.initialized = true
    log("SatisfactionClient initialized")
    return true
end

-- Set up event handlers
function SatisfactionClient:setupEventHandlers()
    if not ClientEventBridge then 
        log("ClientEventBridge not found")
        return 
    end
    
    -- Listen for satisfaction updates from server
    ClientEventBridge:registerServerEvent("SatisfactionUpdated", function(data)
        self:handleSatisfactionUpdate(data)
    end)
    
    -- Listen for members leaving events
    ClientEventBridge:registerServerEvent("MembersLeft", function(count)
        self:handleMembersLeft(count)
    end)
    
    -- Listen for tile purchases (which can affect satisfaction)
    ClientEventBridge:registerServerEvent("TilePurchased", function()
        -- Request updated satisfaction data after buying equipment
        task.delay(0.5, function()
            self:requestSatisfactionData()
        end)
    end)
    
    log("Event handlers set up")
end

-- Handle satisfaction updates from the server
function SatisfactionClient:handleSatisfactionUpdate(data)
    local previousSatisfaction = self.satisfactionData.satisfaction
    
    -- Update local data
    for key, value in pairs(data) do
        self.satisfactionData[key] = value
    end
    
    -- Update UI if enough time has passed since last update
    if os.clock() - self.lastUIUpdate >= CONFIG.uiUpdateCooldown then
        self:updateUI()
        self.lastUIUpdate = os.clock()
    end
    
    -- Notify if satisfaction level changed significantly
    local currentSatisfaction = self.satisfactionData.satisfaction
    if math.abs(currentSatisfaction - previousSatisfaction) >= 10 then
        self:notifySatisfactionChange(previousSatisfaction, currentSatisfaction)
    end
end

-- Handle members leaving due to satisfaction
function SatisfactionClient:handleMembersLeft(count)
    if count >= CONFIG.memberLeftThreshold then
        if NotificationSystem then
            NotificationSystem.showNotification({
                title = "Member Exodus",
                message = count .. " members have left your gym due to dissatisfaction!",
                duration = 5,
                type = "Warning"
            })
        end
    end
end

-- Notify player about significant satisfaction changes
function SatisfactionClient:notifySatisfactionChange(previousSatisfaction, currentSatisfaction)
    if not NotificationSystem then return end
    
    -- Get satisfaction level info
    local currentLevel = self:getSatisfactionLevel(currentSatisfaction)
    
    if currentSatisfaction > previousSatisfaction then
        NotificationSystem.showNotification({
            title = "Member Satisfaction Improved",
            message = "Your gym's satisfaction level is now " .. currentLevel.name,
            duration = 4,
            type = "Success"
        })
    else
        NotificationSystem.showNotification({
            title = "Member Satisfaction Declining",
            message = "Your gym's satisfaction level is now " .. currentLevel.name,
            duration = 4,
            type = "Warning"
        })
    end
end

-- Get satisfaction level info based on value
function SatisfactionClient:getSatisfactionLevel(value)
    for _, level in ipairs(CONFIG.satisfactionLevels) do
        if value >= level.min then
            return level
        end
    end
    return CONFIG.satisfactionLevels[#CONFIG.satisfactionLevels]
end

-- Request satisfaction data from server
function SatisfactionClient:requestSatisfactionData()
    if not ClientEventBridge then return end
    
    ClientEventBridge:fireServer("RequestSatisfactionData")
    log("Requested satisfaction data from server")
end

-- Update UI with current satisfaction data
function SatisfactionClient:updateUI()
    -- This will be implemented by the SatisfactionDisplay UI module
    ClientEventBridge:fireEvent("UpdateSatisfactionUI", self.satisfactionData)
    log("Fired UpdateSatisfactionUI event")
end

-- Show the satisfaction panel
function SatisfactionClient:showSatisfactionPanel()
    ClientEventBridge:fireEvent("ShowSatisfactionPanel")
    log("Fired ShowSatisfactionPanel event")
end

-- Hide the satisfaction panel
function SatisfactionClient:hideSatisfactionPanel()
    ClientEventBridge:fireEvent("HideSatisfactionPanel")
    log("Fired HideSatisfactionPanel event")
end

-- Toggle the satisfaction panel
function SatisfactionClient:toggleSatisfactionPanel()
    ClientEventBridge:fireEvent("ToggleSatisfactionPanel")
    log("Fired ToggleSatisfactionPanel event")
end

-- Get current satisfaction data
function SatisfactionClient:getSatisfactionData()
    return table.clone(self.satisfactionData)
end

-- Create public API
local PublicAPI = {
    initialize = function()
        return SatisfactionClient:initialize()
    end,
    
    requestSatisfactionData = function()
        return SatisfactionClient:requestSatisfactionData()
    end,
    
    showSatisfactionPanel = function()
        SatisfactionClient:showSatisfactionPanel()
    end,
    
    hideSatisfactionPanel = function()
        SatisfactionClient:hideSatisfactionPanel()
    end,
    
    toggleSatisfactionPanel = function()
        SatisfactionClient:toggleSatisfactionPanel()
    end,
    
    getSatisfactionData = function()
        return SatisfactionClient:getSatisfactionData()
    end,
    
    getSatisfactionLevel = function(value)
        return SatisfactionClient:getSatisfactionLevel(value)
    end
}

-- Register with ClientRegistry
return ClientRegistry.registerSystem("SatisfactionClient", PublicAPI, {"ClientRegistry", "ClientEventBridge", "UIManager", "NotificationSystem"})