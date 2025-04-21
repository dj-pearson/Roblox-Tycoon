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

-- Get UI modules
local UIStyle = require(ReplicatedStorage:FindFirstChild("Shared"):FindFirstChild("UIStyle"))
local UIComponent = require(ReplicatedStorage:FindFirstChild("Shared"):FindFirstChild("UIComponent"))

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

-- Create a stat row with label and value
function EquipmentUpgradeUI:CreateInfoRow(label, value)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = UIStyle.Fonts.Regular
    nameLabel.Text = label
    nameLabel.TextSize = 18
    nameLabel.TextColor3 = UIStyle.Colors.TextSecondary
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = frame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "ValueLabel"
    valueLabel.Size = UDim2.new(0.5, 0, 1, 0)
    valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = UIStyle.Fonts.Bold
    valueLabel.Text = value
    valueLabel.TextSize = 18
    valueLabel.TextColor3 = UIStyle.Colors.Text
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame
    
    return frame
end

-- Create an upgrade option button
function EquipmentUpgradeUI:CreateUpgradeOption(parent, data)
    local frame = Instance.new("Frame")
    frame.Name = "UpgradeOption_" .. data.level
    frame.Size = UDim2.new(0.9, 0, 0, 80)
    frame.BackgroundColor3 = UIStyle.Colors.Secondary
    frame.BorderSizePixel = 0
    frame.LayoutOrder = data.level
    frame.Parent = parent
    
    -- Store the upgrade data
    frame:SetAttribute("level", data.level)
    frame:SetAttribute("cost", data.cost)
    frame:SetAttribute("incomeBonus", data.incomeBonus)
    frame:SetAttribute("satisfactionBonus", data.satisfactionBonus)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.1, 0)
    corner.Parent = frame
    
    -- Level header
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(1, 0, 0.3, 0)
    levelLabel.BackgroundColor3 = UIStyle.Colors.Accent
    levelLabel.BorderSizePixel = 0
    levelLabel.Font = UIStyle.Fonts.Bold
    levelLabel.Text = "Level " .. data.level
    levelLabel.TextSize = 18
    levelLabel.TextColor3 = UIStyle.Colors.Text
    levelLabel.Parent = frame
    
    local levelCorner = Instance.new("UICorner")
    levelCorner.CornerRadius = UDim.new(0.3, 0)
    levelCorner.Parent = levelLabel
    
    -- Stats container
    local statsContainer = Instance.new("Frame")
    statsContainer.Name = "StatsContainer"
    statsContainer.Size = UDim2.new(0.65, 0, 0.7, 0)
    statsContainer.Position = UDim2.new(0, 10, 0.3, 0)
    statsContainer.BackgroundTransparency = 1
    statsContainer.Parent = frame
    
    -- Stats layout
    local statsLayout = Instance.new("UIListLayout")
    statsLayout.Padding = UDim.new(0, 5)
    statsLayout.FillDirection = Enum.FillDirection.Horizontal
    statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    statsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    statsLayout.Parent = statsContainer
    
    -- Income bonus
    local incomeIconFrame = Instance.new("Frame")
    incomeIconFrame.Name = "IncomeIcon"
    incomeIconFrame.Size = UDim2.new(0, 80, 0, 30)
    incomeIconFrame.BackgroundTransparency = 1
    incomeIconFrame.LayoutOrder = 1
    incomeIconFrame.Parent = statsContainer
    
    local incomeIcon = Instance.new("ImageLabel")
    incomeIcon.Size = UDim2.new(0, 20, 0, 20)
    incomeIcon.Position = UDim2.new(0, 0, 0.5, -10)
    incomeIcon.BackgroundTransparency = 1
    incomeIcon.Image = "rbxassetid://3192533593" -- Money icon
    incomeIcon.Parent = incomeIconFrame
    
    local incomeText = Instance.new("TextLabel")
    incomeText.Size = UDim2.new(0, 60, 0, 20)
    incomeText.Position = UDim2.new(0, 25, 0.5, -10)
    incomeText.BackgroundTransparency = 1
    incomeText.Font = UIStyle.Fonts.Regular
    incomeText.Text = "+" .. data.incomeBonus
    incomeText.TextSize = 16
    incomeText.TextColor3 = Color3.fromRGB(85, 170, 127) -- Green
    incomeText.TextXAlignment = Enum.TextXAlignment.Left
    incomeText.Parent = incomeIconFrame
    
    -- Satisfaction bonus
    local satIconFrame = Instance.new("Frame")
    satIconFrame.Name = "SatisfactionIcon"
    satIconFrame.Size = UDim2.new(0, 80, 0, 30)
    satIconFrame.BackgroundTransparency = 1
    satIconFrame.LayoutOrder = 2
    satIconFrame.Parent = statsContainer
    
    local satIcon = Instance.new("ImageLabel")
    satIcon.Size = UDim2.new(0, 20, 0, 20)
    satIcon.Position = UDim2.new(0, 0, 0.5, -10)
    satIcon.BackgroundTransparency = 1
    satIcon.Image = "rbxassetid://3926307971" -- Smile icon
    satIcon.ImageRectSize = Vector2.new(36, 36)
    satIcon.ImageRectOffset = Vector2.new(684, 724)
    satIcon.Parent = satIconFrame
    
    local satText = Instance.new("TextLabel")
    satText.Size = UDim2.new(0, 60, 0, 20)
    satText.Position = UDim2.new(0, 25, 0.5, -10)
    satText.BackgroundTransparency = 1
    satText.Font = UIStyle.Fonts.Regular
    satText.Text = "+" .. data.satisfactionBonus
    satText.TextSize = 16
    satText.TextColor3 = Color3.fromRGB(85, 170, 255) -- Blue
    satText.TextXAlignment = Enum.TextXAlignment.Left
    satText.Parent = satIconFrame
    
    -- Upgrade button
    local upgradeButton = Instance.new("TextButton")
    upgradeButton.Name = "UpgradeButton"
    upgradeButton.Size = UDim2.new(0.3, -20, 0.7, -10)
    upgradeButton.Position = UDim2.new(0.7, 10, 0.3, 5)
    upgradeButton.BackgroundColor3 = UIStyle.Colors.Success
    upgradeButton.Font = UIStyle.Fonts.Bold
    upgradeButton.Text = "$" .. data.cost
    upgradeButton.TextSize = 16
    upgradeButton.TextColor3 = Color3.new(1, 1, 1)
    upgradeButton.Parent = frame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0.2, 0)
    buttonCorner.Parent = upgradeButton
    
    -- Connect upgrade button
    upgradeButton.MouseButton1Click:Connect(function()
        self:RequestUpgrade(data.level)
    end)
    
    return frame
end

-- Setup event connections
function EquipmentUpgradeUI:SetupEventConnections()
    -- Close button
    self.ui.closeButton.MouseButton1Click:Connect(function()
        self:Close()
    end)
    
    -- Listen for money changes to update display
    self:UpdateMoneyDisplay()
    
    -- Setup connection to player's leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local money = leaderstats:FindFirstChild("Money")
        if money then
            money:GetPropertyChangedSignal("Value"):Connect(function()
                self:UpdateMoneyDisplay()
            end)
        end
    end
end

-- Update the money display
function EquipmentUpgradeUI:UpdateMoneyDisplay()
    local money = 0
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local moneyValue = leaderstats:FindFirstChild("Money")
        if moneyValue then
            money = moneyValue.Value
        end
    end
    
    -- Format with commas
    local formattedMoney = tostring(money)
    local formatted = ""
    local length = #formattedMoney
    
    for i = 1, length do
        formatted = formatted .. string.sub(formattedMoney, i, i)
        if (length - i) % 3 == 0 and i ~= length then
            formatted = formatted .. ","
        end
    end
    
    self.ui.moneyText.Text = "$" .. formatted
end

-- Open the upgrade UI for a specific piece of equipment
function EquipmentUpgradeUI:Open(equipment)
    if not equipment then return end
    
    -- Store current equipment reference
    self.currentEquipment = equipment
    
    -- Get equipment data
    local equipmentType = equipment:GetAttribute("equipmentType") or equipment.Name
    local level = equipment:GetAttribute("upgradeLevel") or 1
    local incomeBonus = equipment:GetAttribute("incomeBonus") or 10
    local satisfactionBonus = equipment:GetAttribute("satisfactionBonus") or 0
    
    -- Update UI with equipment data
    self.ui.nameLabel.Text = equipmentType
    self.ui.levelDisplay.Text = tostring(level)
    self.ui.incomeDisplay.Text = "+" .. tostring(incomeBonus)
    self.ui.satisfactionDisplay.Text = "+" .. tostring(satisfactionBonus)
    
    -- Clear existing upgrade options
    for _, child in ipairs(self.ui.upgradesScroll:GetChildren()) do
        if child:IsA("Frame") and string.match(child.Name, "UpgradeOption_") then
            child:Destroy()
        end
    end
    
    -- Request upgrade options from server
    self:PopulateUpgradeOptions(equipment)
    
    -- Show the UI
    self.ui.screenGui.Enabled = true
    
    -- Animate opening
    self.ui.mainFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
    self.ui.mainFrame.Size = UDim2.new(0.5, 0, 0.7, 0)
    
    local openTween = TweenService:Create(
        self.ui.mainFrame,
        TWEEN_INFO,
        {Position = UDim2.new(0.5, 0, 0.5, 0)}
    )
    openTween:Play()
    
    self.isOpen = true
end

-- Close the upgrade UI
function EquipmentUpgradeUI:Close()
    if not self.isOpen then return end
    
    -- Animate closing
    local closeTween = TweenService:Create(
        self.ui.mainFrame,
        TWEEN_INFO,
        {Position = UDim2.new(0.5, 0, 1.5, 0)}
    )
    
    closeTween.Completed:Connect(function()
        self.ui.screenGui.Enabled = false
        self.currentEquipment = nil
    end)
    
    closeTween:Play()
    self.isOpen = false
end

-- Populate upgrade options for equipment
function EquipmentUpgradeUI:PopulateUpgradeOptions(equipment)
    local currentLevel = equipment:GetAttribute("upgradeLevel") or 1
    local basePrice = equipment:GetAttribute("basePrice") or 100
    local incomeBonus = equipment:GetAttribute("incomeBonus") or 10
    
    -- Mock data (in a real implementation, this would come from the server)
    local maxLevel = 4
    local upgradePriceMultiplier = 1.75
    local incomeMultiplier = 1.5
    
    -- Create upgrade options
    for level = currentLevel + 1, maxLevel do
        local upgradePrice = math.floor(basePrice * (upgradePriceMultiplier ^ (level - 1)))
        local newIncome = math.floor(incomeBonus * (1 + (level - 1) * 0.5))
        local satisfactionBonus = (level - 1) * 5
        
        -- Create upgrade option
        self:CreateUpgradeOption(self.ui.upgradesScroll, {
            level = level,
            cost = upgradePrice,
            incomeBonus = newIncome,
            satisfactionBonus = satisfactionBonus
        })
    end
    
    -- Auto-size scrolling frame content
    local totalHeight = 0
    for _, child in ipairs(self.ui.upgradesScroll:GetChildren()) do
        if child:IsA("Frame") then
            totalHeight = totalHeight + child.Size.Y.Offset + 10 -- Add padding
        end
    end
    
    self.ui.upgradesScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

-- Request an upgrade from the server
function EquipmentUpgradeUI:RequestUpgrade(targetLevel)
    if not self.currentEquipment then return end
    
    local equipmentId = self.currentEquipment:GetAttribute("EquipmentId")
    local equipmentType = self.currentEquipment:GetAttribute("equipmentType") or self.currentEquipment.Name
    
    -- Request upgrade from server
    requestUpgradeEvent:FireServer(equipmentId, equipmentType, targetLevel)
    
    -- Close UI after request
    self:Close()
end

-- Setup equipment click detection
function EquipmentUpgradeUI:SetupEquipmentClickDetection()
    -- This would connect to input events to detect when equipment is clicked
    -- For the example, we'll just have a direct method to open the UI
end

-- Test opening the UI (for debugging)
function EquipmentUpgradeUI:TestOpen()
    -- Create a mock equipment object
    local mockEquipment = Instance.new("Model")
    mockEquipment:SetAttribute("equipmentType", "Treadmill")
    mockEquipment:SetAttribute("upgradeLevel", 1)
    mockEquipment:SetAttribute("basePrice", 100)
    mockEquipment:SetAttribute("incomeBonus", 10)
    mockEquipment:SetAttribute("satisfactionBonus", 0)
    mockEquipment:SetAttribute("EquipmentId", 1)
    
    self:Open(mockEquipment)
end

-- Initialize the UI when the module is required
return EquipmentUpgradeUI:Initialize()