-- SpecializationClient.luau
-- Client-side controller for gym specialization functionality
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
    notificationDuration = 5,
    commandBarPosition = UDim2.new(1, -160, 0, 100),
    commandBarSize = UDim2.new(0, 150, 0, 40)
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[SpecializationClient]", ...)
    end
end

-- Module table
local SpecializationClient = {
    -- Internal state
    currentSpecializations = { primary = nil, secondary = nil },
    availableSpecializations = {},
    allSpecializations = {},
    isUIOpen = false,
    commandButton = nil,
    initialized = false
}

-- Initialize the module
function SpecializationClient:initialize()
    log("Initializing SpecializationClient...")
    
    -- Register for events
    self:setupEventHandlers()
    
    -- Create command button
    self:createCommandButton()
    
    -- Set up legacy compatibility
    self:setupLegacyCompatibility()
    
    -- Request initial specialization data
    self:requestSpecializationData()
    
    self.initialized = true
    log("SpecializationClient initialized")
    return true
end

-- Set up event handlers
function SpecializationClient:setupEventHandlers()
    -- Listen for specialization data updates
    ClientEventBridge.connectEvent("SpecializationsData", function(data)
        self:handleSpecializationData(data)
    end)
    
    -- Listen for specialization update responses
    ClientEventBridge.connectEvent("SpecializationResponse", function(response)
        self:handleSpecializationResponse(response)
    end)
    
    -- Listen for UI show requests
    ClientEventBridge.connectEvent("ShowSpecializationUI", function()
        self:showSpecializationUI()
    end)
    
    -- Listen for specialization updates
    ClientEventBridge.connectEvent("SpecializationUpdated", function(specs)
        self.currentSpecializations = specs
        -- Refresh UI if open
        if self.isUIOpen then
            self:showSpecializationUI()
        end
    end)

    log("Event handlers set up")
end

-- Request specialization data from the server
function SpecializationClient:requestSpecializationData()
    log("Requesting specialization data...")
    ClientEventBridge.fireServerEvent("RequestSpecializations")
end

-- Handle specialization data from server
function SpecializationClient:handleSpecializationData(data)
    if not data then return end
    
    log("Received specialization data")
    
    self.currentSpecializations = data.current or { primary = nil, secondary = nil }
    self.availableSpecializations = data.available or {}
    self.allSpecializations = data.allSpecs or {}
end

-- Handle response after setting a specialization
function SpecializationClient:handleSpecializationResponse(response)
    if not response then return end
    
    -- Show notification
    if response.success then
        NotificationSystem.showSuccess({
            title = "Specialization Set",
            message = response.message,
            duration = CONFIG.notificationDuration
        })
    else
        NotificationSystem.showWarning({
            title = "Specialization Error",
            message = response.message,
            duration = CONFIG.notificationDuration
        })
    end
end

-- Create command button for opening specialization menu
function SpecializationClient:createCommandButton()
    -- Create a ScreenGui for the command button if not using UIManager for this
    local commandGui = Instance.new("ScreenGui")
    commandGui.Name = "SpecializationCommands"
    commandGui.ResetOnSpawn = false
    
    -- Create button
    local button = Instance.new("TextButton")
    button.Name = "SpecializationButton"
    button.Size = CONFIG.commandBarSize
    button.Position = CONFIG.commandBarPosition
    button.AnchorPoint = Vector2.new(0, 0)
    button.BackgroundColor3 = Color3.fromRGB(0, 120, 180)
    button.Font = Enum.Font.GothamBold
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.Text = "Specializations"
    button.Parent = commandGui
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Connect button click
    button.MouseButton1Click:Connect(function()
        self:openSpecializationMenu()
    end)
    
    -- Store reference to button
    self.commandButton = button
    
    -- Add to PlayerGui
    commandGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    return commandGui
end

-- Open specialization menu
function SpecializationClient:openSpecializationMenu()
    log("Opening specialization menu...")
    
    -- Request fresh data before showing UI
    self:requestSpecializationData()
    
    -- Tell server to show UI (will trigger ShowSpecializationUI event via EventBridge)
    ClientEventBridge.fireServerEvent("OpenSpecializationMenu")
end

-- Show the specialization UI
function SpecializationClient:showSpecializationUI()
    log("Showing specialization UI")
    
    -- Mark UI as open
    self.isUIOpen = true
    
    -- Prepare data for UI module
    local uiData = {
        current = self.currentSpecializations,
        available = self.availableSpecializations,
        all = self.allSpecializations,
        
        -- Callbacks
        onSetPrimary = function(specializationId)
            self:setSpecialization(specializationId, false)
        end,
        
        onSetSecondary = function(specializationId)
            self:setSpecialization(specializationId, true)
        end,
        
        onClose = function()
            self.isUIOpen = false
        end
    }
    
    -- Open UI using UIManager
    UIManager.openUI("SpecializationMenu", uiData)
end

-- Set a specialization
function SpecializationClient:setSpecialization(specializationId, isSecondary)
    log("Setting specialization", specializationId, isSecondary)
    ClientEventBridge.fireServerEvent("SetSpecialization", specializationId, isSecondary)
end

-- Set up compatibility with legacy code
function SpecializationClient:setupLegacyCompatibility()
    -- Create connections to legacy remote functions/events if they exist
    local showSpecMenu = ReplicatedStorage:FindFirstChild("ShowSpecializationsMenu")
    local openSpecMenu = ReplicatedStorage:FindFirstChild("OpenSpecializationMenu")
    
    if showSpecMenu and showSpecMenu:IsA("RemoteFunction") then
        -- Handle legacy calls through our new system
        log("Connected to legacy ShowSpecializationsMenu")
    end
    
    if openSpecMenu and openSpecMenu:IsA("RemoteEvent") then
        openSpecMenu.OnClientEvent:Connect(function()
            self:showSpecializationUI()
        end)
        log("Connected to legacy OpenSpecializationMenu")
    end
end

-- Public API
local PublicAPI = {
    initialize = function()
        return SpecializationClient:initialize()
    end,
    
    getCurrentSpecializations = function()
        return SpecializationClient.currentSpecializations
    end,
    
    getAvailableSpecializations = function()
        return SpecializationClient.availableSpecializations
    end,
    
    openSpecializationMenu = function()
        SpecializationClient:openSpecializationMenu()
        return true
    end,
    
    setSpecialization = function(specializationId, isSecondary)
        SpecializationClient:setSpecialization(specializationId, isSecondary)
        return true
    end
}

-- Register with ClientRegistry
return ClientRegistry.registerSystem("SpecializationClient", PublicAPI, {"ClientEventBridge", "UIManager", "NotificationSystem"})