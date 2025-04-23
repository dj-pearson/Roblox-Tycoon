--[[
    EquipmentUpgradeUI.client.luau
    
    Client-side UI for equipment upgrades. This module handles displaying
    the equipment upgrade interface and sending upgrade requests to the server.
    
    Author: Created April 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create fallback UI styles in case modules aren't found
local UIStyle, UIComponent

-- Try to get UI modules with error handling
local function safeRequire(moduleReference)
    if not moduleReference then return nil end
    
    local success, result = pcall(function()
        return require(moduleReference)
    end)
    
    if success then
        return result
    else
        warn("Failed to load module: " .. moduleReference.Name)
        return nil
    end
end

-- Try to find Shared folder (might be called "shared" with lowercase)
local sharedFolder = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:FindFirstChild("shared")

-- Try to load UI modules with fallbacks
if sharedFolder then
    UIStyle = safeRequire(sharedFolder:FindFirstChild("UIStyle"))
    UIComponent = safeRequire(sharedFolder:FindFirstChild("UIComponent"))
end

-- Create fallback UI style if not found
if not UIStyle then
    warn("UIStyle module not found, using fallback styles")
    UIStyle = {
        Colors = {
            Background = Color3.fromRGB(36, 36, 36),
            Secondary = Color3.fromRGB(45, 45, 45),
            Accent = Color3.fromRGB(0, 120, 215),
            Text = Color3.fromRGB(255, 255, 255),
            TextSecondary = Color3.fromRGB(200, 200, 200),
            Success = Color3.fromRGB(40, 167, 69),
            Danger = Color3.fromRGB(220, 53, 69)
        },
        Fonts = {
            Regular = Enum.Font.Gotham,
            Bold = Enum.Font.GothamBold,
            SemiBold = Enum.Font.GothamSemibold,
            Title = Enum.Font.GothamBlack,
            Subtitle = Enum.Font.GothamMedium
        }
    }
end

-- Create fallback UI component system if not found
if not UIComponent then
    warn("UIComponent module not found, using fallback implementation")
    UIComponent = {
        createButton = function()
            return Instance.new("TextButton")
        end,
        createFrame = function()
            return Instance.new("Frame")
        end
    }
end

local EquipmentUpgradeUI = {}

-- Constants
local UPGRADE_UI_NAME = "EquipmentUpgradeUI"
local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Remote events
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder")
if remoteEvents.Parent ~= ReplicatedStorage then
    remoteEvents.Name = "RemoteEvents"
    remoteEvents.Parent = ReplicatedStorage
end

local requestUpgradeEvent = remoteEvents:FindFirstChild("RequestEquipmentUpgrade") or Instance.new("RemoteEvent")
if requestUpgradeEvent.Parent ~= remoteEvents then
    requestUpgradeEvent.Name = "RequestEquipmentUpgrade"
    requestUpgradeEvent.Parent = remoteEvents
end

-- Initialize the UI
function EquipmentUpgradeUI:Initialize()
    -- Create the UI
    self:CreateUpgradeUI()
    
    -- Setup event connections
    self:SetupEventConnections()
    
    return self
end

-- Create the upgrade UI
function EquipmentUpgradeUI:CreateUpgradeUI()
    -- Check if UI already exists
    local existingUI = playerGui:FindFirstChild(UPGRADE_UI_NAME)
    if existingUI then
        existingUI:Destroy()
    end
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = UPGRADE_UI_NAME
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Enabled = false
    screenGui.Parent = playerGui
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.Size = UDim2.new(0.5, 0, 0.7, 0)
    mainFrame.BackgroundColor3 = UIStyle.Colors.Background
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Apply corner and stroke
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.02, 0)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = UIStyle.Colors.Accent
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    
    -- Create title
    local titleFrame = Instance.new("Frame")
    titleFrame.Name = "TitleFrame"
    titleFrame.Size = UDim2.new(1, 0, 0.1, 0)
    titleFrame.BackgroundColor3 = UIStyle.Colors.Accent
    titleFrame.BorderSizePixel = 0
    titleFrame.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0.1, 0)
    titleCorner.Parent = titleFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -20, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = UIStyle.Fonts.Title
    titleLabel.Text = "Equipment Upgrade"
    titleLabel.TextSize = 24
    titleLabel.TextColor3 = UIStyle.Colors.Text
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.Parent = titleFrame
    
    -- Create close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.AnchorPoint = Vector2.new(1, 0.5)
    closeButton.Position = UDim2.new(1, -10, 0.5, 0)
    closeButton.Size = UDim2.new(0.1, 0, 0.8, 0)
    closeButton.BackgroundColor3 = UIStyle.Colors.Danger
    closeButton.Text = "X"
    closeButton.TextSize = 20
    closeButton.Font = UIStyle.Fonts.Bold
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.Parent = titleFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0.2, 0)
    closeCorner.Parent = closeButton
    
    -- Create content frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Position = UDim2.new(0, 0, 0.1, 0)
    contentFrame.Size = UDim2.new(1, 0, 0.9, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- Create two columns: left for info, right for upgrades
    local leftColumn = Instance.new("Frame")
    leftColumn.Name = "InfoColumn"
    leftColumn.Position = UDim2.new(0, 10, 0, 10)
    leftColumn.Size = UDim2.new(0.45, -20, 1, -20)
    leftColumn.BackgroundTransparency = 1
    leftColumn.Parent = contentFrame
    
    local rightColumn = Instance.new("Frame")
    rightColumn.Name = "UpgradesColumn"
    rightColumn.Position = UDim2.new(0.45, 10, 0, 10)
    rightColumn.Size = UDim2.new(0.55, -20, 1, -20)
    rightColumn.BackgroundTransparency = 1
    rightColumn.Parent = contentFrame
    
    -- Equipment info (left column)
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "EquipmentInfo"
    infoFrame.Size = UDim2.new(1, 0, 0.5, 0)
    infoFrame.BackgroundColor3 = UIStyle.Colors.Secondary
    infoFrame.BackgroundTransparency = 0.5
    infoFrame.Parent = leftColumn
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0.02, 0)
    infoCorner.Parent = infoFrame
    
    -- Equipment name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -20, 0.15, 0)
    nameLabel.Position = UDim2.new(0, 10, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = UIStyle.Fonts.Subtitle
    nameLabel.Text = "Equipment Name"
    nameLabel.TextSize = 22
    nameLabel.TextColor3 = UIStyle.Colors.Text
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = infoFrame
    
    -- Equipment stats
    local statsLayout = Instance.new("UIListLayout")
    statsLayout.Padding = UDim.new(0, 8)
    statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    statsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(1, -20, 0.8, -20)
    statsFrame.Position = UDim2.new(0, 10, 0.15, 10)
    statsFrame.BackgroundTransparency = 1
    statsFrame.Parent = infoFrame
    statsLayout.Parent = statsFrame
    
    -- Current level
    local levelFrame = self:CreateInfoRow("Current Level", "1")
    levelFrame.LayoutOrder = 1
    levelFrame.Parent = statsFrame
    
    -- Income bonus
    local incomeFrame = self:CreateInfoRow("Income Bonus", "+10")
    incomeFrame.LayoutOrder = 2
    incomeFrame.Parent = statsFrame
    
    -- Satisfaction bonus
    local satisfactionFrame = self:CreateInfoRow("Satisfaction", "+0")
    satisfactionFrame.LayoutOrder = 3
    satisfactionFrame.Parent = statsFrame
    
    -- Equipment image viewpoint
    local previewFrame = Instance.new("Frame")
    previewFrame.Name = "PreviewFrame"
    previewFrame.Size = UDim2.new(1, 0, 0.45, 0)
    previewFrame.Position = UDim2.new(0, 0, 0.55, 0)
    previewFrame.BackgroundColor3 = UIStyle.Colors.Secondary
    previewFrame.BackgroundTransparency = 0.5
    previewFrame.Parent = leftColumn
    
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0.02, 0)
    previewCorner.Parent = previewFrame
    
    local previewTitle = Instance.new("TextLabel")
    previewTitle.Name = "PreviewTitle"
    previewTitle.Size = UDim2.new(1, -20, 0.15, 0)
    previewTitle.Position = UDim2.new(0, 10, 0, 10)
    previewTitle.BackgroundTransparency = 1
    previewTitle.Font = UIStyle.Fonts.Subtitle
    previewTitle.Text = "Equipment Preview"
    previewTitle.TextSize = 18
    previewTitle.TextColor3 = UIStyle.Colors.Text
    previewTitle.TextXAlignment = Enum.TextXAlignment.Left
    previewTitle.Parent = previewFrame
    
    -- This would be a ViewportFrame in the actual implementation
    local previewImage = Instance.new("ImageLabel")
    previewImage.Name = "PreviewImage"
    previewImage.Size = UDim2.new(0.9, 0, 0.7, 0)
    previewImage.Position = UDim2.new(0.05, 0, 0.25, 0)
    previewImage.BackgroundTransparency = 1
    previewImage.Image = "rbxassetid://0" -- Placeholder
    previewImage.ScaleType = Enum.ScaleType.Fit
    previewImage.Parent = previewFrame
    
    -- Upgrade options (right column)
    local upgradesScrollFrame = Instance.new("ScrollingFrame")
    upgradesScrollFrame.Name = "UpgradesScroll"
    upgradesScrollFrame.Size = UDim2.new(1, 0, 0.75, 0)
    upgradesScrollFrame.BackgroundTransparency = 1
    upgradesScrollFrame.BorderSizePixel = 0
    upgradesScrollFrame.ScrollBarThickness = 6
    upgradesScrollFrame.ScrollBarImageColor3 = UIStyle.Colors.Accent
    upgradesScrollFrame.Parent = rightColumn
    
    local upgradesLayout = Instance.new("UIListLayout")
    upgradesLayout.Padding = UDim.new(0, 10)
    upgradesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    upgradesLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    upgradesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    upgradesLayout.Parent = upgradesScrollFrame
    
    local upgradePadding = Instance.new("UIPadding")
    upgradePadding.PaddingTop = UDim.new(0, 10)
    upgradePadding.PaddingBottom = UDim.new(0, 10)
    upgradePadding.Parent = upgradesScrollFrame
    
    -- Add sample upgrade option
    self:CreateUpgradeOption(upgradesScrollFrame, {
        level = 2,
        cost = 150,
        incomeBonus = 15,
        satisfactionBonus = 5
    })
    
    -- Current money display
    local moneyFrame = Instance.new("Frame")
    moneyFrame.Name = "MoneyFrame"
    moneyFrame.Size = UDim2.new(1, 0, 0.15, 0)
    moneyFrame.Position = UDim2.new(0, 0, 0.8, 0)
    moneyFrame.BackgroundColor3 = UIStyle.Colors.Accent
    moneyFrame.BackgroundTransparency = 0.7
    moneyFrame.Parent = rightColumn
    
    local moneyCorner = Instance.new("UICorner")
    moneyCorner.CornerRadius = UDim.new(0.1, 0)
    moneyCorner.Parent = moneyFrame
    
    local moneyIcon = Instance.new("ImageLabel")
    moneyIcon.Name = "MoneyIcon"
    moneyIcon.Size = UDim2.new(0.15, 0, 0.8, 0)
    moneyIcon.Position = UDim2.new(0.05, 0, 0.1, 0)
    moneyIcon.BackgroundTransparency = 1
    moneyIcon.Image = "rbxassetid://3192533593" -- Placeholder money icon
    moneyIcon.Parent = moneyFrame
    
    local moneyText = Instance.new("TextLabel")
    moneyText.Name = "MoneyText"
    moneyText.Size = UDim2.new(0.75, 0, 0.8, 0)
    moneyText.Position = UDim2.new(0.2, 10, 0.1, 0)
    moneyText.BackgroundTransparency = 1
    moneyText.Font = UIStyle.Fonts.Bold
    moneyText.Text = "$1,000"
    moneyText.TextSize = 24
    moneyText.TextColor3 = UIStyle.Colors.Text
    moneyText.TextXAlignment = Enum.TextXAlignment.Left
    moneyText.Parent = moneyFrame
    
    -- Store UI references
    self.ui = {
        screenGui = screenGui,
        mainFrame = mainFrame,
        nameLabel = nameLabel,
        levelDisplay = levelFrame.ValueLabel,
        incomeDisplay = incomeFrame.ValueLabel,
        satisfactionDisplay = satisfactionFrame.ValueLabel,
        previewImage = previewImage,
        upgradesScroll = upgradesScrollFrame,
        moneyText = moneyText,
        closeButton = closeButton
    }
    
    -- Animation state
    self.isOpen = false
end

-- Rest of the script continues unchanged...
-- Initialize the UI when the module is required
return EquipmentUpgradeUI:Initialize()