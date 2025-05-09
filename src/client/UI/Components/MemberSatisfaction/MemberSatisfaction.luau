--!strict
--[[
    MemberSatisfaction.luau
    
    UI component for displaying member satisfaction metrics.
    Integrates with the UI system for consistent behavior.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Import UI utilities
local UIUtils = require(script.Parent.Parent.Parent.Core.UIUtils)
local UIConstants = require(script.Parent.Parent.Parent.Core.UIConstants)

-- MemberSatisfaction component class
local MemberSatisfaction = {}
MemberSatisfaction.__index = MemberSatisfaction

-- Create new MemberSatisfaction instance
function MemberSatisfaction.new()
    local self = setmetatable({}, MemberSatisfaction)
    self.name = UIConstants.ComponentNames.MemberSatisfaction
    self.gui = nil
    self.isVisible = false
    return self
end

-- Initialize the component
function MemberSatisfaction:initialize()
    if self.gui then return end
    
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create main GUI
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "MemberSatisfactionGui"
    self.gui.ResetOnSpawn = false
    self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.gui.Enabled = false
    self.gui.Parent = playerGui
    
    -- Create main frame using UIUtils
    local mainFrame = UIUtils.createFrame({
        Name = "MainFrame",
        Size = UDim2.new(0.8, 0, 0.4, 0),
        Position = UDim2.new(0.1, 0, 0.1, 0),
        BackgroundColor3 = UIConstants.Colors.Background,
        BackgroundTransparency = 0.1,
        Parent = self.gui
    })
    
    -- Add corner radius
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, UIConstants.CornerRadius.Medium)
    uiCorner.Parent = mainFrame
    
    -- Add title
    local titleLabel = UIUtils.createTextLabel({
        Name = "TitleLabel",
        Size = UDim2.new(1, 0, 0.2, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Member Satisfaction",
        TextColor3 = UIConstants.Colors.Text,
        TextSize = UIConstants.TextSizes.Title,
        Font = UIConstants.Fonts.Title,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = mainFrame
    })
    
    -- Add satisfaction score
    local satisfactionScore = UIUtils.createTextLabel({
        Name = "SatisfactionScore",
        Size = UDim2.new(0.5, 0, 0.3, 0),
        Position = UDim2.new(0.25, 0, 0.3, 0),
        Text = "100",
        TextColor3 = UIConstants.Colors.Text,
        TextSize = UIConstants.TextSizes.Title * 2,
        Font = UIConstants.Fonts.Title,
        Parent = mainFrame
    })
    
    -- Add status label
    local statusLabel = UIUtils.createTextLabel({
        Name = "StatusLabel",
        Size = UDim2.new(0.5, 0, 0.1, 0),
        Position = UDim2.new(0.25, 0, 0.6, 0),
        Text = "Excellent",
        TextColor3 = UIConstants.Colors.Text,
        TextSize = UIConstants.TextSizes.Body,
        Font = UIConstants.Fonts.Body,
        Parent = mainFrame
    })
    
    -- Add key factors container
    local keyFactorsContainer = UIUtils.createFrame({
        Name = "KeyFactorsContainer",
        Size = UDim2.new(1, 0, 0.3, 0),
        Position = UDim2.new(0, 0, 0.8, 0),
        BackgroundTransparency = 1,
        Parent = mainFrame
    })
    
    -- Add list layout for key factors
    local keyFactorsListLayout = Instance.new("UIListLayout")
    keyFactorsListLayout.FillDirection = Enum.FillDirection.Horizontal
    keyFactorsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    keyFactorsListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    keyFactorsListLayout.Padding = UDim.new(0, UIConstants.Spacing.Medium)
    keyFactorsListLayout.Parent = keyFactorsContainer
    
    -- Add member retention label
    local memberRetentionLabel = UIUtils.createTextLabel({
        Name = "MemberRetentionLabel",
        Size = UDim2.new(0.5, 0, 0.1, 0),
        Position = UDim2.new(0, 0, 1, 0),
        Text = "Member Retention: 95%",
        TextColor3 = UIConstants.Colors.Text,
        TextSize = UIConstants.TextSizes.Body,
        Font = UIConstants.Fonts.Body,
        Parent = mainFrame
    })
    
    -- Add revenue impact label
    local revenueImpactLabel = UIUtils.createTextLabel({
        Name = "RevenueImpactLabel",
        Size = UDim2.new(0.5, 0, 0.1, 0),
        Position = UDim2.new(0, 0, 1.2, 0),
        Text = "Revenue Impact: +10%",
        TextColor3 = UIConstants.Colors.Text,
        TextSize = UIConstants.TextSizes.Body,
        Font = UIConstants.Fonts.Body,
        Parent = mainFrame
    })
    
    -- Add trend indicator
    local trendIndicator = UIUtils.createImageLabel({
        Name = "TrendIndicator",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(0.75, 0, 0.4, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Parent = mainFrame
    })
end

-- Show the component
function MemberSatisfaction:show()
    if not self.gui then
        self:initialize()
    end
    
    self.gui.Enabled = true
    self.isVisible = true
    
    -- Animate in
    UIUtils.animate(self.gui.MainFrame, "FADE_IN")
end

-- Hide the component
function MemberSatisfaction:hide()
    if not self.gui then return end
    
    -- Animate out
    UIUtils.animate(self.gui.MainFrame, "FADE_OUT", function()
        self.gui.Enabled = false
        self.isVisible = false
    end)
end

-- Toggle the component
function MemberSatisfaction:toggle()
    if self.isVisible then
        self:hide()
    else
        self:show()
    end
end

-- Update satisfaction score
function MemberSatisfaction:updateSatisfactionScore(score)
    local scoreLabel = self.gui.MainFrame:FindFirstChild("SatisfactionScore")
    if scoreLabel then
        scoreLabel.Text = tostring(score)
    end
end

-- Update status label
function MemberSatisfaction:updateStatusLabel(status)
    local statusLabel = self.gui.MainFrame:FindFirstChild("StatusLabel")
    if statusLabel then
        statusLabel.Text = status
    end
end

-- Update trend indicator
function MemberSatisfaction:updateTrendIndicator(isImproving)
    local trendIndicator = self.gui.MainFrame:FindFirstChild("TrendIndicator")
    if trendIndicator then
        trendIndicator.Image = isImproving and "rbxassetid://13337321193" or "rbxassetid://13337324635"
    end
end

-- Update member retention
function MemberSatisfaction:updateMemberRetention(retention)
    local retentionLabel = self.gui.MainFrame:FindFirstChild("MemberRetentionLabel")
    if retentionLabel then
        retentionLabel.Text = "Member Retention: " .. tostring(retention) .. "%"
    end
end

-- Update revenue impact
function MemberSatisfaction:updateRevenueImpact(impact)
    local impactLabel = self.gui.MainFrame:FindFirstChild("RevenueImpactLabel")
    if impactLabel then
        impactLabel.Text = "Revenue Impact: " .. tostring(impact) .. "%"
    end
end

-- Add key factor
function MemberSatisfaction:addKeyFactor(iconId, factorName, value)
    local keyFactorsContainer = self.gui.MainFrame:FindFirstChild("KeyFactorsContainer")
    if not keyFactorsContainer then return end
    
    local keyFactorFrame = UIUtils.createFrame({
        Name = factorName .. "Factor",
        Size = UDim2.new(0, 50, 0, 50),
        BackgroundTransparency = 1,
        Parent = keyFactorsContainer
    })
    
    local icon = UIUtils.createImageLabel({
        Name = "Icon",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://" .. iconId,
        Parent = keyFactorFrame
    })
    
    local textLabel = UIUtils.createTextLabel({
        Name = "TextLabel",
        Size = UDim2.new(1, 0, 0.2, 0),
        Position = UDim2.new(0, 0, 1, 0),
        Text = factorName .. " : " .. value,
        TextColor3 = UIConstants.Colors.Text,
        TextSize = UIConstants.TextSizes.Small,
        Font = UIConstants.Fonts.Body,
        Parent = keyFactorFrame
    })
end

-- Clear key factors
function MemberSatisfaction:clearKeyFactors()
    local keyFactorsContainer = self.gui.MainFrame:FindFirstChild("KeyFactorsContainer")
    if not keyFactorsContainer then return end
    
    for _, child in ipairs(keyFactorsContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
end

-- Update component data
function MemberSatisfaction:update(data)
    if data.score then
        self:updateSatisfactionScore(data.score)
    end
    
    if data.status then
        self:updateStatusLabel(data.status)
    end
    
    if data.trend ~= nil then
        self:updateTrendIndicator(data.trend)
    end
    
    if data.retention then
        self:updateMemberRetention(data.retention)
    end
    
    if data.revenueImpact then
        self:updateRevenueImpact(data.revenueImpact)
    end
    
    if data.keyFactors then
        self:clearKeyFactors()
        for _, factor in ipairs(data.keyFactors) do
            self:addKeyFactor(factor.iconId, factor.name, factor.value)
        end
    end
end

-- Clean up the component
function MemberSatisfaction:destroy()
    if self.gui then
        self.gui:Destroy()
        self.gui = nil
    end
end

return MemberSatisfaction 