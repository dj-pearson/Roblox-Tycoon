-- SeasonalClient.luau
-- Client-side controller for seasonal events functionality
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
    notificationDuration = 6,
    commandBarPosition = UDim2.new(1, -160, 0, 150),
    commandBarSize = UDim2.new(0, 150, 0, 40)
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[SeasonalClient]", ...)
    end
end

-- Module table
local SeasonalClient = {
    -- Internal state
    availableSeasons = {},
    currentActiveSeason = nil,
    globalSeason = nil,
    isUIOpen = false,
    commandButton = nil,
    initialized = false
}

-- Initialize the module
function SeasonalClient:initialize()
    log("Initializing SeasonalClient...")
    
    -- Register for events
    self:setupEventHandlers()
    
    -- Create command button
    self:createCommandButton()
    
    -- Set up legacy compatibility
    self:setupLegacyCompatibility()
    
    -- Request initial seasonal event data
    self:requestSeasonalData()
    
    self.initialized = true
    log("SeasonalClient initialized")
    return true
end

-- Set up event handlers
function SeasonalClient:setupEventHandlers()
    -- Listen for available seasons data
    ClientEventBridge.connectEvent("AvailableSeasonsData", function(data)
        self:handleSeasonalData(data)
    end)
    
    -- Listen for seasonal event responses
    ClientEventBridge.connectEvent("SeasonalEventResponse", function(response)
        self:handleSeasonalResponse(response)
    end)
    
    -- Listen for seasonal status changes
    ClientEventBridge.connectEvent("SeasonalStatusChanged", function(data)
        self:handleStatusChange(data)
    end)
    
    -- Listen for global seasonal events
    ClientEventBridge.connectEvent("GlobalSeasonStarted", function(data)
        self:handleGlobalSeasonStarted(data)
    end)
    
    ClientEventBridge.connectEvent("GlobalSeasonEnded", function(data)
        self:handleGlobalSeasonEnded(data)
    end)

    log("Event handlers set up")
end

-- Request seasonal data from the server
function SeasonalClient:requestSeasonalData()
    log("Requesting seasonal event data...")
    ClientEventBridge.fireServerEvent("RequestAvailableSeasons")
end

-- Handle seasonal data from server
function SeasonalClient:handleSeasonalData(data)
    if not data then return end
    
    log("Received seasonal event data")
    
    self.availableSeasons = data.seasons or {}
    self.globalSeason = data.globalSeason
    
    -- Update UI if open
    if self.isUIOpen then
        self:showSeasonalUI()
    end
end

-- Handle response after joining/leaving a seasonal event
function SeasonalClient:handleSeasonalResponse(response)
    if not response then return end
    
    -- Show notification
    if response.success then
        NotificationSystem.showSuccess({
            title = "Seasonal Event",
            message = response.message,
            duration = CONFIG.notificationDuration
        })
    else
        NotificationSystem.showWarning({
            title = "Seasonal Event Error",
            message = response.message,
            duration = CONFIG.notificationDuration
        })
    end
end

-- Handle seasonal status change
function SeasonalClient:handleStatusChange(data)
    if not data then return end
    
    if data.active then
        -- Player joined a seasonal event
        self.currentActiveSeason = {
            id = data.seasonId,
            name = data.name,
            endTime = data.endTime
        }
        
        log("Joined seasonal event:", data.name)
    else
        -- Player left a seasonal event
        self.currentActiveSeason = nil
        log("Left seasonal event")
    end
    
    -- Update UI if open
    if self.isUIOpen then
        self:showSeasonalUI()
    end
end

-- Handle global season started
function SeasonalClient:handleGlobalSeasonStarted(data)
    if not data then return end
    
    self.globalSeason = {
        id = data.id,
        name = data.name,
        endTime = data.endTime
    }
    
    -- Show notification if not already shown by the server
    NotificationSystem.showInfo({
        title = "Global Event Started",
        message = "A new seasonal event is available: " .. data.name,
        duration = CONFIG.notificationDuration
    })
    
    -- Update UI if open
    if self.isUIOpen then
        self:showSeasonalUI()
    end
end

-- Handle global season ended
function SeasonalClient:handleGlobalSeasonEnded(data)
    if not data then return end
    
    -- Store the ended season name for notification
    local seasonName = data.name
    
    -- Clear global season
    self.globalSeason = nil
    
    -- Show notification if not already shown by the server
    NotificationSystem.showInfo({
        title = "Global Event Ended",
        message = seasonName .. " has ended.",
        duration = CONFIG.notificationDuration
    })
    
    -- Update UI if open
    if self.isUIOpen then
        self:showSeasonalUI()
    end
end

-- Create command button for opening seasonal events menu
function SeasonalClient:createCommandButton()
    -- Create a ScreenGui for the command button
    local commandGui = Instance.new("ScreenGui")
    commandGui.Name = "SeasonalCommands"
    commandGui.ResetOnSpawn = false
    
    -- Create button
    local button = Instance.new("TextButton")
    button.Name = "SeasonalButton"
    button.Size = CONFIG.commandBarSize
    button.Position = CONFIG.commandBarPosition
    button.AnchorPoint = Vector2.new(0, 0)
    button.BackgroundColor3 = Color3.fromRGB(220, 120, 30)
    button.Font = Enum.Font.GothamBold
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.Text = "Seasonal Events"
    button.Parent = commandGui
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Connect button click
    button.MouseButton1Click:Connect(function()
        self:openSeasonalMenu()
    end)
    
    -- Store reference to button
    self.commandButton = button
    
    -- Add to PlayerGui
    commandGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    return commandGui
end

-- Open seasonal menu
function SeasonalClient:openSeasonalMenu()
    log("Opening seasonal menu...")
    
    -- Request fresh data before showing UI
    self:requestSeasonalData()
    
    -- Show UI
    task.wait(0.1) -- Short wait to allow data to come back
    self:showSeasonalUI()
end

-- Show the seasonal UI
function SeasonalClient:showSeasonalUI()
    log("Showing seasonal UI")
    
    -- Mark UI as open
    self.isUIOpen = true
    
    -- Format time remaining for active season
    local timeRemaining = ""
    if self.currentActiveSeason and self.currentActiveSeason.endTime then
        local remainingSeconds = self.currentActiveSeason.endTime - os.time()
        if remainingSeconds > 0 then
            local days = math.floor(remainingSeconds / 86400)
            local hours = math.floor((remainingSeconds % 86400) / 3600)
            timeRemaining = days .. " days, " .. hours .. " hours remaining"
        end
    end
    
    -- Prepare data for UI module
    local uiData = {
        availableSeasons = self.availableSeasons,
        activeSeason = self.currentActiveSeason,
        globalSeason = self.globalSeason,
        timeRemaining = timeRemaining,
        
        -- Callbacks
        onJoinSeason = function(seasonId)
            self:joinSeasonalEvent(seasonId)
        end,
        
        onLeaveSeason = function()
            self:leaveSeasonalEvent()
        end,
        
        onClose = function()
            self.isUIOpen = false
        end
    }
    
    -- Open UI using UIManager
    UIManager.openUI("SeasonalEventsUI", uiData)
end

-- Join a seasonal event
function SeasonalClient:joinSeasonalEvent(seasonId)
    log("Joining seasonal event:", seasonId)
    ClientEventBridge.fireServerEvent("JoinSeasonalEvent", seasonId)
end

-- Leave seasonal event
function SeasonalClient:leaveSeasonalEvent()
    log("Leaving seasonal event")
    ClientEventBridge.fireServerEvent("LeaveSeasonalEvent")
end

-- Set up compatibility with legacy code
function SeasonalClient:setupLegacyCompatibility()
    -- Create connections to legacy remote functions/events if they exist
    local getAvailableSeasons = ReplicatedStorage:FindFirstChild("GetAvailableSeasons")
    local joinSeasonalEvent = ReplicatedStorage:FindFirstChild("JoinSeasonalEvent")
    local seasonalStarted = ReplicatedStorage:FindFirstChild("SeasonalEventStarted")
    local seasonalEnded = ReplicatedStorage:FindFirstChild("SeasonalEventEnded")
    
    if seasonalStarted and seasonalStarted:IsA("RemoteEvent") then
        seasonalStarted.OnClientEvent:Connect(function(seasonId, seasonName)
            self:handleGlobalSeasonStarted({
                id = seasonId,
                name = seasonName
            })
        end)
        log("Connected to legacy SeasonalEventStarted")
    end
    
    if seasonalEnded and seasonalEnded:IsA("RemoteEvent") then
        seasonalEnded.OnClientEvent:Connect(function()
            self:handleGlobalSeasonEnded({})
        end)
        log("Connected to legacy SeasonalEventEnded")
    end
end



-- Public API
local PublicAPI = {
    initialize = function()
        return SeasonalClient:initialize()
    end,
    
    getAvailableSeasons = function()
        return SeasonalClient.availableSeasons
    end,
    
    getCurrentSeason = function()
        return SeasonalClient.currentActiveSeason
    end,
    
    openSeasonalMenu = function()
        SeasonalClient:openSeasonalMenu()
        return true
    end,
    
    joinSeasonalEvent = function(seasonId)
        SeasonalClient:joinSeasonalEvent(seasonId)
        return true
    end,
    
    leaveSeasonalEvent = function()
        SeasonalClient:leaveSeasonalEvent()
        return true
    end
}

-- Register with ClientRegistry
return ClientRegistry.registerSystem("SeasonalClient", PublicAPI, {"ClientEventBridge", "UIManager", "NotificationSystem"})