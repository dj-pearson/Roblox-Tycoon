--!strict
--[[
    GuestPass.luau
    
    UI component for the Guest Pass system.
    Integrates with the UI system for consistent behavior.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Import UI utilities
local UIUtils = require(script.Parent.Parent.Parent.Core.UIUtils)
local UIConstants = require(script.Parent.Parent.Parent.Core.UIConstants)

-- GuestPass component class
local GuestPass = {}
GuestPass.__index = GuestPass

-- Create new GuestPass instance
function GuestPass.new()
    local self = setmetatable({}, GuestPass)
    self.name = UIConstants.ComponentNames.GuestPass
    self.gui = nil
    self.isVisible = false
    return self
end

-- Initialize the component
function GuestPass:initialize()
    if self.gui then return end
    
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create main GUI
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "GuestPassGui"
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
    
    -- Add title
    local titleLabel = UIUtils.createTextLabel({
        Name = "TitleLabel",
        Size = UDim2.new(1, 0, 0.1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Guest Pass",
        TextColor3 = UIConstants.Colors.Text,
        TextSize = UIConstants.TextSizes.Title,
        Font = UIConstants.Fonts.Title,
        Parent = mainFrame
    })
    
    -- Add close button
    local closeButton = UIUtils.createButton({
        Name = "CloseButton",
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(1, -50, 0, 10),
        BackgroundColor3 = UIConstants.Colors.Error,
        Text = "X",
        TextColor3 = UIConstants.Colors.Text,
        TextSize = UIConstants.TextSizes.Button,
        Font = UIConstants.Fonts.Button,
        Parent = mainFrame
    })
    
    -- Add corner radius to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, UIConstants.CornerRadius.Medium)
    closeCorner.Parent = closeButton
    
    -- Add description text
    local descLabel = UIUtils.createTextLabel({
        Name = "DescLabel",
        Size = UDim2.new(0.9, 0, 0.15, 0),
        Position = UDim2.new(0.5, 0, 0.175, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Text = "Invite friends to your gym with guest passes! They'll get a free trial and you'll earn a bonus when they join.",
        TextColor3 = UIConstants.Colors.TextSecondary,
        TextSize = UIConstants.TextSizes.Body,
        Font = UIConstants.Fonts.Body,
        TextWrapped = true,
        Parent = mainFrame
    })
    
    -- Add guest pass options frame
    local optionsFrame = UIUtils.createFrame({
        Name = "OptionsFrame",
        Size = UDim2.new(0.9, 0, 0.6, 0),
        Position = UDim2.new(0.5, 0, 0.525, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Parent = mainFrame
    })
    
    -- Guest pass options
    local passOptions = {
        {name = "1-Day Pass", desc = "24 hours of access", price = "Free", bonus = "10 coins"},
        {name = "3-Day Pass", desc = "72 hours of access", price = "20 coins", bonus = "30 coins"},
        {name = "7-Day Pass", desc = "1 week of access", price = "50 coins", bonus = "75 coins"}
    }
    
    -- Create pass option cards
    for i, option in ipairs(passOptions) do
        local passCard = UIUtils.createFrame({
            Name = option.name .. "Card",
            Size = UDim2.new(0.3, -20, 0.8, 0),
            Position = UDim2.new(0.333 * (i-1) + 0.167, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = UIConstants.Colors.Secondary,
            Parent = optionsFrame
        })
        
        -- Add corner radius
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, UIConstants.CornerRadius.Medium)
        cardCorner.Parent = passCard
        
        -- Add title
        local nameLabel = UIUtils.createTextLabel({
            Name = "NameLabel",
            Size = UDim2.new(0.9, 0, 0.15, 0),
            Position = UDim2.new(0.5, 0, 0.1, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Text = option.name,
            TextColor3 = UIConstants.Colors.Text,
            TextSize = UIConstants.TextSizes.Subtitle,
            Font = UIConstants.Fonts.Subtitle,
            Parent = passCard
        })
        
        -- Add description
        local descLabel = UIUtils.createTextLabel({
            Name = "DescLabel",
            Size = UDim2.new(0.9, 0, 0.15, 0),
            Position = UDim2.new(0.5, 0, 0.25, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Text = option.desc,
            TextColor3 = UIConstants.Colors.TextSecondary,
            TextSize = UIConstants.TextSizes.Body,
            Font = UIConstants.Fonts.Body,
            Parent = passCard
        })
        
        -- Add price
        local priceLabel = UIUtils.createTextLabel({
            Name = "PriceLabel",
            Size = UDim2.new(0.9, 0, 0.15, 0),
            Position = UDim2.new(0.5, 0, 0.45, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Text = "Cost: " .. option.price,
            TextColor3 = UIConstants.Colors.Success,
            TextSize = UIConstants.TextSizes.Body,
            Font = UIConstants.Fonts.Subtitle,
            Parent = passCard
        })
        
        -- Add bonus info
        local bonusLabel = UIUtils.createTextLabel({
            Name = "BonusLabel",
            Size = UDim2.new(0.9, 0, 0.15, 0),
            Position = UDim2.new(0.5, 0, 0.6, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Text = "You earn: " .. option.bonus,
            TextColor3 = UIConstants.Colors.Warning,
            TextSize = UIConstants.TextSizes.Body,
            Font = UIConstants.Fonts.Body,
            Parent = passCard
        })
        
        -- Add purchase button
        local purchaseButton = UIUtils.createButton({
            Name = "PurchaseButton",
            Size = UDim2.new(0.8, 0, 0.15, 0),
            Position = UDim2.new(0.5, 0, 0.8, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = UIConstants.Colors.Primary,
            Text = "Create Pass",
            TextColor3 = UIConstants.Colors.Text,
            TextSize = UIConstants.TextSizes.Button,
            Font = UIConstants.Fonts.Button,
            Parent = passCard
        })
        
        -- Add corner radius to button
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, UIConstants.CornerRadius.Small)
        buttonCorner.Parent = purchaseButton
        
        -- Add hover and click effects
        UIUtils.createHoverEffect(purchaseButton)
        UIUtils.createClickEffect(purchaseButton)
        
        -- Connect purchase button
        purchaseButton.MouseButton1Click:Connect(function()
            self:onPurchasePass(option)
        end)
    end
    
    -- Add help text
    local helpLabel = UIUtils.createTextLabel({
        Name = "HelpLabel",
        Size = UDim2.new(0.9, 0, 0.1, 0),
        Position = UDim2.new(0.5, 0, 0.9, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Text = "Guest passes can be shared with friends. You'll earn a bonus when they visit your gym!",
        TextColor3 = UIConstants.Colors.TextSecondary,
        TextSize = UIConstants.TextSizes.Small,
        Font = UIConstants.Fonts.Body,
        TextWrapped = true,
        Parent = mainFrame
    })
    
    -- Connect close button
    closeButton.MouseButton1Click:Connect(function()
        self:hide()
    end)
end

-- Show the component
function GuestPass:show()
    if not self.gui then
        self:initialize()
    end
    
    self.gui.Enabled = true
    self.isVisible = true
    
    -- Animate in
    UIUtils.animate(self.gui.MainFrame, "FADE_IN")
end

-- Hide the component
function GuestPass:hide()
    if not self.gui then return end
    
    -- Animate out
    UIUtils.animate(self.gui.MainFrame, "FADE_OUT", function()
        self.gui.Enabled = false
        self.isVisible = false
    end)
end

-- Toggle the component
function GuestPass:toggle()
    if self.isVisible then
        self:hide()
    else
        self:show()
    end
end

-- Handle pass purchase
function GuestPass:onPurchasePass(option)
    -- Fire event to server
    local ClientEventBridge = require(ReplicatedStorage.Shared.Systems.ClientRegistry):GetSystem("ClientEventBridge")
    ClientEventBridge:Fire("PurchaseGuestPass", {
        passType = option.name,
        price = option.price,
        duration = option.desc
    })
end

-- Update component data
function GuestPass:update(data)
    -- Handle any updates to the component
    if data.passes then
        -- Update available passes
    end
    
    if data.bonuses then
        -- Update bonus information
    end
end

-- Clean up the component
function GuestPass:destroy()
    if self.gui then
        self.gui:Destroy()
        self.gui = nil
    end
end

return GuestPass 