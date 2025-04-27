--!strict
--[[
    PlayerStatsDisplay.luau
    
    Example UI component that displays player statistics using the new 
    ClientDataService for data access. This demonstrates how to properly
    integrate UI components with our data system.
    
    Features:
    - Real-time stat updates
    - Clean data access using ClientDataService
    - Automatic UI updates on data changes
    - Loading states and error handling
    
    Author: Created April 28, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Import modules
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local ClientModules = script.Parent.Parent

local DataTypes = require(SharedModules:WaitForChild("Data"):WaitForChild("DataTypes"))
local DataConstants = require(SharedModules:WaitForChild("Data"):WaitForChild("DataConstants"))
local ClientDataService = require(ClientModules:WaitForChild("Data"):WaitForChild("ClientDataService"))

-- Local variables
local localPlayer = Players.LocalPlayer
local PlayerGui = localPlayer:WaitForChild("PlayerGui")
local StatsScreenGui = PlayerGui:WaitForChild("StatsGui")
local MainFrame = StatsScreenGui:WaitForChild("MainFrame")
local StatsContainer = MainFrame:WaitForChild("StatsContainer")

-- Stat elements in UI
local statsDisplay = {
    gymLevel = StatsContainer:WaitForChild("GymLevel"):WaitForChild("Value"),
    experience = StatsContainer:WaitForChild("Experience"):WaitForChild("Value"),
    memberCount = StatsContainer:WaitForChild("MemberCount"):WaitForChild("Value"),
    revenue = StatsContainer:WaitForChild("Revenue"):WaitForChild("Value"),
    reputation = StatsContainer:WaitForChild("Reputation"):WaitForChild("Value"),
}

-- Keep track of update connections
local updateConnections = {}
local isInitialized = false

-- Helper function to format numbers nicely
local function formatNumber(value)
    if type(value) ~= "number" then
        return tostring(value)
    end
    
    if value >= 1000000000 then
        return string.format("%.1fB", value / 1000000000)
    elseif value >= 1000000 then
        return string.format("%.1fM", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.1fK", value / 1000)
    else
        return tostring(math.floor(value))
    end
end

-- Setup loading indicators
local function showLoading()
    for stat, element in pairs(statsDisplay) do
        element.Text = "Loading..."
    end
end

-- Handle errors
local function showError()
    for stat, element in pairs(statsDisplay) do
        if element.Text == "Loading..." then
            element.Text = "Error"
            element.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end
end

-- Initialize stat display
local function initializeStats()
    if isInitialized then
        return
    end
    
    -- Initialize ClientDataService first
    ClientDataService:initialize({
        debugMode = true,
        enableClientCache = true
    })
    
    -- Show loading state
    showLoading()
    
    -- Define stats to load and watch
    local statsToWatch = {
        { name = "gymLevel", defaultValue = 1 },
        { name = "experience", defaultValue = 0 },
        { name = "memberCount", defaultValue = 0 },
        { name = "revenue", defaultValue = 0 },
        { name = "reputation", defaultValue = 50 }
    }
    
    -- Function to update a specific stat display
    local function updateStatDisplay(statName, value)
        if statsDisplay[statName] then
            statsDisplay[statName].Text = formatNumber(value)
            statsDisplay[statName].TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
    
    -- Setup each stat
    for _, statInfo in ipairs(statsToWatch) do
        local statName = statInfo.name
        local defaultValue = statInfo.defaultValue
        
        -- Set default value while loading
        updateStatDisplay(statName, defaultValue)
        
        -- Initial load for each stat
        task.spawn(function()
            local value = ClientDataService:getData(DataConstants.PLAYER_SCOPES.STATS, statName)
            
            if value ~= nil then
                updateStatDisplay(statName, value)
            end
        end)
        
        -- Listen for changes to each stat
        local success = ClientDataService:onDataChanged(
            DataConstants.PLAYER_SCOPES.STATS,
            statName,
            function(newValue)
                updateStatDisplay(statName, newValue)
            end
        )
        
        -- Store connection for cleanup
        table.insert(updateConnections, {
            scope = DataConstants.PLAYER_SCOPES.STATS,
            key = statName
        })
    end
    
    isInitialized = true
    print("PlayerStatsDisplay initialized")
end

-- Initialize the component
initializeStats()

-- Example function to update a stat (for testing)
local function updateStat(statName, newValue)
    ClientDataService:setData(DataConstants.PLAYER_SCOPES.STATS, statName, newValue)
end

-- Test setup: Create example update button to demonstrate data flow
local function createTestButtons()
    local TestFrame = Instance.new("Frame")
    TestFrame.Name = "TestFrame"
    TestFrame.Size = UDim2.new(0, 200, 0, 200)
    TestFrame.Position = UDim2.new(0, 10, 0, 10)
    TestFrame.BackgroundTransparency = 0.5
    TestFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TestFrame.Parent = PlayerGui:WaitForChild("ScreenGui", 5)
    
    -- Create test button for each stat
    local statsToTest = {"gymLevel", "experience", "memberCount", "revenue", "reputation"}
    
    for i, statName in ipairs(statsToTest) do
        local Button = Instance.new("TextButton")
        Button.Name = statName .. "Button"
        Button.Text = "Increase " .. statName
        Button.Size = UDim2.new(0.8, 0, 0, 30)
        Button.Position = UDim2.new(0.1, 0, 0, 10 + (i-1) * 35)
        Button.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.Parent = TestFrame
        
        Button.MouseButton1Click:Connect(function()
            local currentValue = ClientDataService:getData(DataConstants.PLAYER_SCOPES.STATS, statName) or 0
            updateStat(statName, currentValue + 10)
        end)
    end
    
    -- Add refresh button
    local RefreshButton = Instance.new("TextButton")
    RefreshButton.Name = "RefreshButton"
    RefreshButton.Text = "Refresh Data"
    RefreshButton.Size = UDim2.new(0.8, 0, 0, 30)
    RefreshButton.Position = UDim2.new(0.1, 0, 0.8, 0)
    RefreshButton.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
    RefreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    RefreshButton.Parent = TestFrame
    
    RefreshButton.MouseButton1Click:Connect(function()
        ClientDataService:clearCache(DataConstants.PLAYER_SCOPES.STATS)
        for _, statInfo in ipairs(statsToTest) do
            ClientDataService:refreshData(DataConstants.PLAYER_SCOPES.STATS, statInfo)
        end
    end)
end

-- Only create test buttons in Studio for testing
if RunService:IsStudio() then
    createTestButtons()
end

-- Cleanup function
local function cleanupConnections()
    for _, connection in ipairs(updateConnections) do
        -- In a real implementation, we would disconnect the event connections
        -- However, ClientDataService doesn't yet have an "offDataChanged" method
    end
    
    updateConnections = {}
    isInitialized = false
end

-- Return public interface
return {
    initialize = initializeStats,
    updateStat = updateStat,
    cleanup = cleanupConnections
}
