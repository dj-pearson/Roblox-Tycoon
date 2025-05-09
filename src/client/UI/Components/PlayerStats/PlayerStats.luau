--!strict
--[[
    PlayerStats.luau
    
    UI component for displaying player statistics.
    Integrates with the UI system for consistent behavior.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Import UI utilities
local UIUtils = require(script.Parent.Parent.Parent.Core.UIUtils)
local UIConstants = require(script.Parent.Parent.Parent.Core.UIConstants)

-- PlayerStats component class
local PlayerStats = {}
PlayerStats.__index = PlayerStats

-- Create new PlayerStats instance
function PlayerStats.new()
    local self = setmetatable({}, PlayerStats)
    self.name = UIConstants.ComponentNames.PlayerStats
    self.gui = nil
    self.isVisible = false
    return self
end

-- Initialize the component
function PlayerStats:initialize()
    if self.gui then return end
    
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create main GUI
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "PlayerStatsGui"
    self.gui.ResetOnSpawn = false
    self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.gui.Enabled = false
    self.gui.Parent = playerGui
    
    -- Create main frame using UIUtils
    local statsFrame = UIUtils.createFrame({
        Name = "StatsFrame",
        Size = UDim2.new(0.3, 0, 0.1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = UIConstants.Colors.Background,
        BackgroundTransparency = 0.2,
        Parent = self.gui
    })
    
    -- Add corner radius
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, UIConstants.CornerRadius.Small)
    uiCorner.Parent = statsFrame
    
    -- Add list layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, UIConstants.Spacing.Medium)
    listLayout.Parent = statsFrame
    
    -- Create Members label
    local membersLabel = UIUtils.createTextLabel({
        Name = "MembersLabel",
        Size = UDim2.new(1/3, 0, 1, 0),
        Text = "Members: --",
        TextColor3 = UIConstants.Colors.Text,
        TextSize = UIConstants.TextSizes.Body,
        Font = UIConstants.Fonts.Body,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center,
        LayoutOrder = 1,
        Parent = statsFrame
    })
    
    -- Create Level label
    local levelLabel = UIUtils.createTextLabel({
        Name = "LevelLabel",
        Size = UDim2.new(1/3, 0, 1, 0),
        Text = "Level: --",
        TextColor3 = UIConstants.Colors.Text,
        TextSize = UIConstants.TextSizes.Body,
        Font = UIConstants.Fonts.Body,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center,
        LayoutOrder = 2,
        Parent = statsFrame
    })
    
    -- Create Cash label
    local cashLabel = UIUtils.createTextLabel({
        Name = "CashLabel",
        Size = UDim2.new(1/3, 0, 1, 0),
        Text = "Cash: --",
        TextColor3 = UIConstants.Colors.Text,
        TextSize = UIConstants.TextSizes.Body,
        Font = UIConstants.Fonts.Body,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center,
        LayoutOrder = 3,
        Parent = statsFrame
    })
    
    -- Store references
    self.membersLabel = membersLabel
    self.levelLabel = levelLabel
    self.cashLabel = cashLabel
    
    -- Connect to value changes
    self:connectValueChanges()
end

-- Connect to value changes
function PlayerStats:connectValueChanges()
    local player = Players.LocalPlayer
    
    -- Connect Members value
    if player:FindFirstChild("Members") and player.Members:FindFirstChild("Value") then
        local function updateMembers()
            self.membersLabel.Text = "Members: " .. tostring(player.Members.Value)
        end
        updateMembers()
        player.Members.Value.Changed:Connect(updateMembers)
    end
    
    -- Connect Level value
    if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Level") then
        local function updateLevel()
            self.levelLabel.Text = "Level: " .. tostring(player.leaderstats.Level.Value)
        end
        updateLevel()
        player.leaderstats.Level.Value.Changed:Connect(updateLevel)
    end
    
    -- Connect Cash value
    if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Cash") then
        local function updateCash()
            self.cashLabel.Text = "Cash: " .. tostring(player.leaderstats.Cash.Value)
        end
        updateCash()
        player.leaderstats.Cash.Value.Changed:Connect(updateCash)
    end
end

-- Show the component
function PlayerStats:show()
    if not self.gui then
        self:initialize()
    end
    
    self.gui.Enabled = true
    self.isVisible = true
    
    -- Animate in
    UIUtils.animate(self.gui.StatsFrame, "FADE_IN")
end

-- Hide the component
function PlayerStats:hide()
    if not self.gui then return end
    
    -- Animate out
    UIUtils.animate(self.gui.StatsFrame, "FADE_OUT", function()
        self.gui.Enabled = false
        self.isVisible = false
    end)
end

-- Toggle the component
function PlayerStats:toggle()
    if self.isVisible then
        self:hide()
    else
        self:show()
    end
end

-- Update component data
function PlayerStats:update(data)
    if data.members then
        self.membersLabel.Text = "Members: " .. tostring(data.members)
    end
    
    if data.level then
        self.levelLabel.Text = "Level: " .. tostring(data.level)
    end
    
    if data.cash then
        self.cashLabel.Text = "Cash: " .. tostring(data.cash)
    end
end

-- Clean up the component
function PlayerStats:destroy()
    if self.gui then
        self.gui:Destroy()
        self.gui = nil
    end
end

return PlayerStats 