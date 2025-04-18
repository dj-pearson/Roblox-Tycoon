-- SaunaTemperatureClient.luau
-- Client-side controller for sauna temperature functionality
-- Place in StarterPlayer/StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Import client-side systems
local ClientRegistry = require(script.Parent.Core.ClientRegistry)
local ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")
local UIManager = ClientRegistry.getSystem("UIManager")
local NotificationSystem = ClientRegistry.getSystem("NotificationSystem")

-- Configuration
local CONFIG = {
    debugEnabled = true,
    safetyThreshold = 85, -- Display warning above this temperature
    dangerThreshold = 95, -- Display danger notification above this temperature
    checkInterval = 1,    -- How often to check if player is still in sauna (seconds)
    notificationDuration = 4 -- Duration of temperature notifications
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[SaunaTemperatureClient]", ...)
    end
end

-- Module table
local SaunaTemperatureClient = {
    -- Internal state
    inSauna = false,
    currentTemperature = 0,
    saunaCheckThread = nil,
    temperatureMonitorThread = nil,
    initialized = false
}

-- Initialize the module
function SaunaTemperatureClient:initialize()
    log("Initializing SaunaTemperatureClient...")
    
    -- Register for events
    self:setupEventHandlers()
    
    -- Set up legacy compatibility
    self:setupLegacyCompatibility()
    
    self.initialized = true
    log("SaunaTemperatureClient initialized")
    return true
end

-- Set up event handlers
function SaunaTemperatureClient:setupEventHandlers()
    -- Listen for sauna entry/exit events from server
    ClientEventBridge.connectEvent("enterSauna", function(temperature)
        self:handleSaunaEntry(temperature)
    end)
    
    ClientEventBridge.connectEvent("exitSauna", function()
        self:handleSaunaExit()
    end)
    
    ClientEventBridge.connectEvent("updateTemperature", function(temperature)
        self:handleTemperatureUpdate(temperature)
    end)

    log("Event handlers set up")
end

-- Handle player entering sauna
function SaunaTemperatureClient:handleSaunaEntry(temperature)
    log("Player entered sauna with temperature: " .. temperature)
    
    -- Update state
    self.inSauna = true
    self.currentTemperature = temperature
    
    -- Open temperature UI
    UIManager.openUI("SaunaTemperatureUI", {
        inSauna = true,
        temperature = temperature
    })
    
    -- Broadcast event for other systems
    ClientEventBridge.fireEvent("PlayerEnterSauna", temperature)
    
    -- Start monitoring player position to detect if they walk out
    self:startSaunaChecking()
    
    -- Display appropriate notification based on temperature
    self:showTemperatureNotification(temperature)
    
    -- Start temperature effects if temperature is high
    if temperature > 60 then
        self:startTemperatureEffects(temperature)
    end
end

-- Handle player exiting sauna
function SaunaTemperatureClient:handleSaunaExit()
    log("Player exited sauna")
    
    -- Update state
    self.inSauna = false
    
    -- Stop monitoring
    self:stopSaunaChecking()
    self:stopTemperatureEffects()
    
    -- Broadcast event for other systems
    ClientEventBridge.fireEvent("PlayerExitSauna")
end

-- Handle temperature updates
function SaunaTemperatureClient:handleTemperatureUpdate(temperature)
    log("Temperature updated: " .. temperature)
    
    -- Update state
    self.currentTemperature = temperature
    
    -- Update UI through event
    ClientEventBridge.fireEvent("SaunaTemperatureUpdate", temperature)
    
    -- Show notification if temperature crosses thresholds
    if self.inSauna then
        self:showTemperatureNotification(temperature)
    end
    
    -- Update effects
    self:updateTemperatureEffects(temperature)
end

-- Show notification based on temperature
function SaunaTemperatureClient:showTemperatureNotification(temperature)
    -- Only show occasional notifications when temperature changes significantly
    if not self.lastNotificationTemp or math.abs(self.lastNotificationTemp - temperature) > 10 then
        self.lastNotificationTemp = temperature
        
        if temperature >= CONFIG.dangerThreshold then
            -- Dangerous temperature
            NotificationSystem.showWarning({
                title = "Extreme Temperature!",
                message = "The sauna is extremely hot! Be careful!",
                duration = CONFIG.notificationDuration
            })
        elseif temperature >= CONFIG.safetyThreshold then
            -- High temperature warning
            NotificationSystem.showInfo({
                title = "High Temperature",
                message = "The sauna is getting very hot.",
                duration = CONFIG.notificationDuration
            })
        elseif temperature <= 30 then
            -- Low temperature
            NotificationSystem.showInfo({
                title = "Low Temperature",
                message = "The sauna is still heating up.",
                duration = CONFIG.notificationDuration
            })
        end
    end
end

-- Start checking if player is still in sauna
function SaunaTemperatureClient:startSaunaChecking()
    -- Stop existing thread if running
    self:stopSaunaChecking()
    
    -- Create new monitoring thread
    self.saunaCheckThread = task.spawn(function()
        while self.inSauna do
            -- Check if player is still in a sauna zone
            self:checkPlayerInSauna()
            task.wait(CONFIG.checkInterval)
        end
    end)
end

-- Stop sauna checking
function SaunaTemperatureClient:stopSaunaChecking()
    if self.saunaCheckThread then
        task.cancel(self.saunaCheckThread)
        self.saunaCheckThread = nil
    end
end

-- Check if player is still in sauna
function SaunaTemperatureClient:checkPlayerInSauna()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = character.HumanoidRootPart
    
    -- This is just a placeholder for actual detection logic
    -- In a real implementation, you might check for:
    -- - Overlapping with a specific part
    -- - Being inside a specific region
    -- - Having a specific attribute set by a region
    
    -- Example: find sauna parts by name
    local saunaFound = false
    local nearbyParts = workspace:GetPartBoundsInRadius(rootPart.Position, 10)
    
    for _, part in ipairs(nearbyParts) do
        if part.Name:lower():find("sauna") then
            saunaFound = true
            break
        end
    end
    
    -- If not in sauna anymore, exit
    if not saunaFound and self.inSauna then
        -- Tell server player exited
        ClientEventBridge.fireServerEvent("PlayerExitedSauna")
        
        -- Handle locally as well
        self:handleSaunaExit()
    end
end

-- Start temperature visual effects
function SaunaTemperatureClient:startTemperatureEffects(temperature)
    -- Stop existing effects
    self:stopTemperatureEffects()
    
    -- Only apply effects at higher temperatures
    if temperature < 60 then return end
    
    -- Create effect monitoring thread
    self.temperatureMonitorThread = task.spawn(function()
        while self.inSauna do
            local effectIntensity = math.clamp((self.currentTemperature - 60) / 40, 0, 1)
            
            -- Apply camera effects based on temperature
            -- This is a placeholder for actual effect implementation
            
            task.wait(0.5)
        end
    end)
end

-- Update temperature effects
function SaunaTemperatureClient:updateTemperatureEffects(temperature)
    -- Effects are updated in the monitor thread
    -- This function could be expanded for immediate effect changes
end

-- Stop temperature effects
function SaunaTemperatureClient:stopTemperatureEffects()
    if self.temperatureMonitorThread then
        task.cancel(self.temperatureMonitorThread)
        self.temperatureMonitorThread = nil
    end
    
    -- Remove any applied effects
    -- This is a placeholder for actual effect removal
end

-- Set up compatibility with legacy code
function SaunaTemperatureClient:setupLegacyCompatibility()
    -- Create connections to legacy remote events if they exist
    local enterSaunaEvent = ReplicatedStorage:FindFirstChild("enterSauna")
    local exitSaunaEvent = ReplicatedStorage:FindFirstChild("exitSauna") 
    local updateTemperatureEvent = ReplicatedStorage:FindFirstChild("updateTemperature")
    
    if enterSaunaEvent and enterSaunaEvent:IsA("RemoteEvent") then
        enterSaunaEvent.OnClientEvent:Connect(function(temperature)
            self:handleSaunaEntry(temperature)
        end)
        log("Connected to legacy enterSauna event")
    end
    
    if exitSaunaEvent and exitSaunaEvent:IsA("RemoteEvent") then
        exitSaunaEvent.OnClientEvent:Connect(function()
            self:handleSaunaExit()
        end)
        log("Connected to legacy exitSauna event")
    end
    
    if updateTemperatureEvent and updateTemperatureEvent:IsA("RemoteEvent") then
        updateTemperatureEvent.OnClientEvent:Connect(function(temperature)
            self:handleTemperatureUpdate(temperature)
        end)
        log("Connected to legacy updateTemperature event")
    end
end

-- Public API
local PublicAPI = {
    initialize = function()
        return SaunaTemperatureClient:initialize()
    end,
    
    isInSauna = function()
        return SaunaTemperatureClient.inSauna
    end,
    
    getCurrentTemperature = function()
        return SaunaTemperatureClient.currentTemperature
    end,
    
    openTemperatureUI = function()
        if SaunaTemperatureClient.inSauna then
            UIManager.openUI("SaunaTemperatureUI", {
                inSauna = true,
                temperature = SaunaTemperatureClient.currentTemperature
            })
            return true
        else
            log("Cannot open temperature UI - player not in sauna")
            return false
        end
    end
}

-- Register with ClientRegistry
return ClientRegistry.registerSystem("SaunaTemperatureClient", PublicAPI, {"ClientEventBridge", "UIManager", "NotificationSystem"})