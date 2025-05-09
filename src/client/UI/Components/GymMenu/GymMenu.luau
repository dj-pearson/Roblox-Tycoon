--!strict
--[[
    GymMenu.luau
    
    UI component for the Gym Management menu.
    Integrates with the UI system for consistent behavior.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Import UI utilities
local UIUtils = require(script.Parent.Parent.Parent.Core.UIUtils)
local UIConstants = require(script.Parent.Parent.Parent.Core.UIConstants)

-- GymMenu component class
local GymMenu = {}
GymMenu.__index = GymMenu

-- Create new GymMenu instance
function GymMenu.new()
    local self = setmetatable({}, GymMenu)
    self.name = UIConstants.ComponentNames.GymMenu
    self.gui = nil
    self.isVisible = false
    return self
end

-- Initialize the component
function GymMenu:initialize()
    if self.gui then return end
    
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create main GUI
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "GymMenuGui"
    self.gui.ResetOnSpawn = false
    self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.gui.Enabled = false
    self.gui.Parent = playerGui
    
    -- Create main frame using UIUtils
    local mainFrame = UIUtils.createFrame({
        Name = "MainFrame",
        Size = UDim2.new(0.6, 0, 0.7, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = UIConstants.Colors.Background,
        BackgroundTransparency = 0.1,
        Parent = self.gui
    })
    
    -- Add corner radius
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, UIConstants.CornerRadius.Medium)
    uiCorner.Parent = mainFrame
    
    -- Add title bar
    local titleBar = UIUtils.createFrame({
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = UIConstants.Colors.Secondary,
        Parent = mainFrame
    })
    
    -- Add title text
    local titleLabel = UIUtils.createTextLabel({
        Name = "TitleLabel",
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Text = "Gym Management",
        TextColor3 = UIConstants.Colors.Text,
        TextSize = UIConstants.TextSizes.Title,
        Font = UIConstants.Fonts.Title,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar
    })
    
    -- Add close button
    local closeButton = UIUtils.createButton({
        Name = "CloseButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -40, 0, 5),
        BackgroundColor3 = UIConstants.Colors.Secondary,
        Text = "X",
        TextColor3 = UIConstants.Colors.Text,
        TextSize = UIConstants.TextSizes.Button,
        Font = UIConstants.Fonts.Button,
        Parent = titleBar
    })
    
    -- Add corner radius to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, UIConstants.CornerRadius.Small)
    closeCorner.Parent = closeButton
    
    -- Add hover and click effects
    UIUtils.createHoverEffect(closeButton)
    UIUtils.createClickEffect(closeButton)
    
    -- Create content frame
    local contentFrame = UIUtils.createFrame({
        Name = "ContentFrame",
        Size = UDim2.new(1, 0, 1, -titleBar.Size.Y.Offset),
        Position = UDim2.new(0, 0, 0, titleBar.Size.Y.Offset),
        BackgroundTransparency = 1,
        Parent = mainFrame
    })
    
    -- Create management sections
    local sections = {
        {
            name = "Equipment",
            icon = "🔧",
            description = "Manage gym equipment and upgrades"
        },
        {
            name = "Staff",
            icon = "👥",
            description = "Hire and manage staff members"
        },
        {
            name = "Members",
            icon = "👤",
            description = "View and manage gym members"
        },
        {
            name = "Finances",
            icon = "💰",
            description = "Track income and expenses"
        }
    }
    
    -- Create section buttons
    for i, section in ipairs(sections) do
        local sectionButton = UIUtils.createButton({
            Name = section.name .. "Button",
            Size = UDim2.new(0.45, 0, 0.2, 0),
            Position = UDim2.new(
                i % 2 == 1 and 0.025 or 0.525,
                0,
                0.1 + math.floor((i-1)/2) * 0.25,
                0
            ),
            BackgroundColor3 = UIConstants.Colors.Secondary,
            Parent = contentFrame
        })
        
        -- Add corner radius
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, UIConstants.CornerRadius.Medium)
        buttonCorner.Parent = sectionButton
        
        -- Add section icon
        local iconLabel = UIUtils.createTextLabel({
            Name = "IconLabel",
            Size = UDim2.new(0.2, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Text = section.icon,
            TextColor3 = UIConstants.Colors.Text,
            TextSize = UIConstants.TextSizes.Title,
            Font = UIConstants.Fonts.Title,
            Parent = sectionButton
        })
        
        -- Add section name
        local nameLabel = UIUtils.createTextLabel({
            Name = "NameLabel",
            Size = UDim2.new(0.75, 0, 0.5, 0),
            Position = UDim2.new(0.25, 0, 0, 0),
            Text = section.name,
            TextColor3 = UIConstants.Colors.Text,
            TextSize = UIConstants.TextSizes.Subtitle,
            Font = UIConstants.Fonts.Subtitle,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = sectionButton
        })
        
        -- Add section description
        local descLabel = UIUtils.createTextLabel({
            Name = "DescLabel",
            Size = UDim2.new(0.75, 0, 0.5, 0),
            Position = UDim2.new(0.25, 0, 0.5, 0),
            Text = section.description,
            TextColor3 = UIConstants.Colors.TextSecondary,
            TextSize = UIConstants.TextSizes.Small,
            Font = UIConstants.Fonts.Body,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = sectionButton
        })
        
        -- Add hover and click effects
        UIUtils.createHoverEffect(sectionButton)
        UIUtils.createClickEffect(sectionButton)
        
        -- Connect section button
        sectionButton.MouseButton1Click:Connect(function()
            self:onSectionSelected(section)
        end)
    end
    
    -- Connect close button
    closeButton.MouseButton1Click:Connect(function()
        self:hide()
    end)
end

-- Show the component
function GymMenu:show()
    if not self.gui then
        self:initialize()
    end
    
    self.gui.Enabled = true
    self.isVisible = true
    
    -- Animate in
    UIUtils.animate(self.gui.MainFrame, "FADE_IN")
end

-- Hide the component
function GymMenu:hide()
    if not self.gui then return end
    
    -- Animate out
    UIUtils.animate(self.gui.MainFrame, "FADE_OUT", function()
        self.gui.Enabled = false
        self.isVisible = false
    end)
end

-- Toggle the component
function GymMenu:toggle()
    if self.isVisible then
        self:hide()
    else
        self:show()
    end
end

-- Handle section selection
function GymMenu:onSectionSelected(section)
    -- Fire event to server
    local ClientEventBridge = require(ReplicatedStorage.Shared.Systems.ClientRegistry):GetSystem("ClientEventBridge")
    ClientEventBridge:Fire("GymMenuSectionSelected", {
        section = section.name,
        icon = section.icon
    })
end

-- Update component data
function GymMenu:update(data)
    -- Handle any updates to the component
    if data.sections then
        -- Update section data
    end
    
    if data.stats then
        -- Update gym statistics
    end
end

-- Clean up the component
function GymMenu:destroy()
    if self.gui then
        self.gui:Destroy()
        self.gui = nil
    end
end

return GymMenu 