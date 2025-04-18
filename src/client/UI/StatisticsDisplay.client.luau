-- StatisticsDisplay.client.luau
-- Module to manage the Statistics Display UI component

local StatisticsDisplay = {}

-- Dependencies
local ClientRegistry = require(script.Parent.ClientRegistry)
local UIHub = ClientRegistry.getSystem("UIHub")
local ClientEvents = ClientRegistry.getSystem("ClientEvents")
local ClientFunctions = ClientRegistry.getSystem("ClientFunctions")

-- UI Elements (replace with actual UI elements)
local statisticsFrame = Instance.new("Frame")
local totalRebirthsLabel = Instance.new("TextLabel")
local fastestRebirthLabel = Instance.new("TextLabel")
local currentRebirthDurationLabel = Instance.new("TextLabel")

-- Initialize the module
function StatisticsDisplay:initialize()
    print("[StatisticsDisplay] Initializing...")

    -- Check if dependencies are initialized
    if not UIHub then
        error("[StatisticsDisplay] UIHub not found!")
    end
    if not ClientEvents then
        error("[StatisticsDisplay] ClientEvents not found!")
    end
    if not ClientFunctions then
        error("[StatisticsDisplay] ClientFunctions not found!")
    end
    -- Setup UI elements
    statisticsFrame.Name = "StatisticsFrame"
    statisticsFrame.Size = UDim2.new(1, 0, 1, 0)
    -- Customize the UI elements (colors, fonts, etc.)
    
    totalRebirthsLabel.Name = "TotalRebirthsLabel"
    totalRebirthsLabel.Size = UDim2.new(1, 0, 0, 50)
    totalRebirthsLabel.Position = UDim2.new(0,0,0,0)
    totalRebirthsLabel.Text = "Total Rebirths: 0"
    totalRebirthsLabel.TextColor3 = Color3.new(1, 1, 1)
    totalRebirthsLabel.BackgroundTransparency = 1
    totalRebirthsLabel.TextSize = 20
    totalRebirthsLabel.Parent = statisticsFrame
    
    fastestRebirthLabel.Name = "FastestRebirthLabel"
    fastestRebirthLabel.Size = UDim2.new(1, 0, 0, 50)
    fastestRebirthLabel.Position = UDim2.new(0,0,0,50)
    fastestRebirthLabel.Text = "Fastest Rebirth: 0s"
    fastestRebirthLabel.TextColor3 = Color3.new(1, 1, 1)
    fastestRebirthLabel.BackgroundTransparency = 1
    fastestRebirthLabel.TextSize = 20
    fastestRebirthLabel.Parent = statisticsFrame

    currentRebirthDurationLabel.Name = "CurrentRebirthDurationLabel"
    currentRebirthDurationLabel.Size = UDim2.new(1, 0, 0, 50)
    currentRebirthDurationLabel.Position = UDim2.new(0,0,0,100)
    currentRebirthDurationLabel.Text = "Current Rebirth Duration: 0s"
    currentRebirthDurationLabel.TextColor3 = Color3.new(1, 1, 1)
    currentRebirthDurationLabel.BackgroundTransparency = 1
    currentRebirthDurationLabel.TextSize = 20
    currentRebirthDurationLabel.Parent = statisticsFrame
    
    statisticsFrame.Parent = game.Players.LocalPlayer.PlayerGui

    print("[StatisticsDisplay] Initialized")
end

-- Register the module in the UI Hub
function StatisticsDisplay:register()
    UIHub:registerUIComponent("StatisticsDisplay", StatisticsDisplay)
    print("[StatisticsDisplay] Registered in UIHub")
end

-- Function to update the statistics
function StatisticsDisplay:updateStatistics(data)
    totalRebirthsLabel.Text = "Total Rebirths: " .. (data.totalRebirths or 0)
    fastestRebirthLabel.Text = "Fastest Rebirth: " .. (data.fastestRebirth or "N/A") .. "s"
    currentRebirthDurationLabel.Text = "Current Rebirth Duration: " .. (data.currentRebirthDuration or "N/A") .. "s"
end
-- Public API
local PublicAPI = {
    initialize = function()
        StatisticsDisplay:initialize()
    end,
    register = function()
        StatisticsDisplay:register()
    end,
    updateStatistics = function(data)
        StatisticsDisplay:updateStatistics(data)
    end
}

return PublicAPI