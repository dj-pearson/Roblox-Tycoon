--!strict
--[[
    ProgressBar.luau
    
    UI component for displaying progress bars.
    Integrates with the UI system for consistent behavior.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Import UI utilities
local UIUtils = require(script.Parent.Parent.Parent.Core.UIUtils)
local UIConstants = require(script.Parent.Parent.Parent.Core.UIConstants)

-- ProgressBar component class
local ProgressBar = {}
ProgressBar.__index = ProgressBar

-- Create new ProgressBar instance
function ProgressBar.new()
    local self = setmetatable({}, ProgressBar)
    self.name = UIConstants.ComponentNames.ProgressBar
    self.gui = nil
    self.isVisible = false
    return self
end

-- Initialize the component
function ProgressBar:initialize()
    if self.gui then return end
    
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create main GUI
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "ProgressBarGui"
    self.gui.ResetOnSpawn = false
    self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.gui.Enabled = false
    self.gui.Parent = playerGui
    
    -- Create main frame using UIUtils
    local progressBarFrame = UIUtils.createFrame({
        Name = "ProgressBarFrame",
        Size = UDim2.new(0.3, 0, 0.05, 0),
        Position = UDim2.new(0.5, 0, 0.1, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = UIConstants.Colors.Background,
        BackgroundTransparency = 0.2,
        Parent = self.gui
    })
    
    -- Add corner radius
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, UIConstants.CornerRadius.Small)
    uiCorner.Parent = progressBarFrame
    
    -- Create background
    local background = UIUtils.createFrame({
        Name = "Background",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = UIConstants.Colors.Secondary,
        BackgroundTransparency = 0.5,
        Parent = progressBarFrame
    })
    
    -- Add corner radius to background
    local backgroundCorner = Instance.new("UICorner")
    backgroundCorner.CornerRadius = UDim.new(0, UIConstants.CornerRadius.Small)
    backgroundCorner.Parent = background
    
    -- Create fill bar
    local fillBar = UIUtils.createFrame({
        Name = "FillBar",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = UIConstants.Colors.Primary,
        Parent = background
    })
    
    -- Add corner radius to fill bar
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, UIConstants.CornerRadius.Small)
    fillCorner.Parent = fillBar
    
    -- Create progress text
    local progressText = UIUtils.createTextLabel({
        Name = "ProgressText",
        Size = UDim2.new(1, 0, 1, 0),
        Text = "0%",
        TextColor3 = UIConstants.Colors.Text,
        TextSize = UIConstants.TextSizes.Body,
        Font = UIConstants.Fonts.Body,
        BackgroundTransparency = 1,
        Parent = progressBarFrame
    })
    
    -- Store references
    self.fillBar = fillBar
    self.progressText = progressText
end

-- Show the component
function ProgressBar:show()
    if not self.gui then
        self:initialize()
    end
    
    self.gui.Enabled = true
    self.isVisible = true
    
    -- Animate in
    UIUtils.animate(self.gui.ProgressBarFrame, "FADE_IN")
end

-- Hide the component
function ProgressBar:hide()
    if not self.gui then return end
    
    -- Animate out
    UIUtils.animate(self.gui.ProgressBarFrame, "FADE_OUT", function()
        self.gui.Enabled = false
        self.isVisible = false
    end)
end

-- Toggle the component
function ProgressBar:toggle()
    if self.isVisible then
        self:hide()
    else
        self:show()
    end
end

-- Update progress
function ProgressBar:updateProgress(currentProgress, maxProgress)
    if not self.fillBar or not self.progressText then return end
    
    -- Calculate percentage
    local percentage = currentProgress / maxProgress
    
    -- Update fill bar with animation
    local tweenInfo = TweenInfo.new(
        0.3, -- Time
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(self.fillBar, tweenInfo, {
        Size = UDim2.new(percentage, 0, 1, 0)
    })
    tween:Play()
    
    -- Update progress text
    self.progressText.Text = math.floor(percentage * 100) .. "%"
end

-- Update component data
function ProgressBar:update(data)
    if data.currentProgress and data.maxProgress then
        self:updateProgress(data.currentProgress, data.maxProgress)
    end
end

-- Clean up the component
function ProgressBar:destroy()
    if self.gui then
        self.gui:Destroy()
        self.gui = nil
    end
end

return ProgressBar 