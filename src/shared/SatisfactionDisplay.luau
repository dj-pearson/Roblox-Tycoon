--[[
    SatisfactionDisplay.luau
    UI module for displaying member satisfaction metrics
    Place in ReplicatedStorage/UIModules
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local CONFIG = {
    -- UI appearance
    mainFrameSize = UDim2.new(0, 300, 0, 300),
    mainFramePosition = UDim2.new(1, -320, 0.5, -150),
    backgroundColor = Color3.fromRGB(30, 30, 40),
    headerColor = Color3.fromRGB(20, 20, 30),
    textColor = Color3.fromRGB(255, 255, 255),
    
    -- Colors for satisfaction levels
    satisfactionColors = {
        [90] = Color3.fromRGB(0, 200, 0),      -- Excellent (90-100)
        [70] = Color3.fromRGB(100, 200, 0),    -- Good (70-89)
        [50] = Color3.fromRGB(200, 200, 0),    -- Average (50-69)
        [30] = Color3.fromRGB(200, 100, 0),    -- Poor (30-49)
        [0] = Color3.fromRGB(200, 0, 0)        -- Terrible (0-29)
    },
    
    -- Icon IDs
    icons = {
        satisfaction = "rbxassetid://3926307971", -- Verified face
        cleanliness = "rbxassetid://3926305904",  -- Broom
        equipment = "rbxassetid://3926307971",    -- Wrench
        revenue = "rbxassetid://3926305904",      -- Money
        retention = "rbxassetid://3926307971"     -- People
    },
    
    -- Description tooltips
    tooltips = {
        satisfaction = "Overall member satisfaction affects revenue and member retention",
        cleanliness = "Cleanliness is affected by member count and janitor staff",
        equipment = "Equipment quality degrades with use but can be maintained by staff",
        revenue = "Revenue bonus/penalty based on satisfaction level",
        retention = "Higher satisfaction means fewer members leave your gym"
    },
    
    -- Animations
    tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    
    -- Debug
    debug = true
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[SatisfactionDisplay]", ...)
    end
end

-- UI Elements
local SatisfactionDisplay = {
    initialized = false,
    isVisible = false,
    _frames = {}, -- UI frames storage
    _currentData = {
        satisfaction = 75,
        cleanliness = 50,
        equipmentQuality = 100,
        revenueFactor = 1.0,
        retentionFactor = 0.95
    },
    
    -- Dependencies
    ClientRegistry = nil,
    SatisfactionClient = nil,
    ClientEventBridge = nil,
    UIManager = nil
}

-- Initialize the module
function SatisfactionDisplay:init(dependencies)
    if self.initialized then return end
    
    self.ClientRegistry = dependencies.ClientRegistry
    
    -- Wait for required systems
    task.spawn(function()
        while not self.initialized do
            -- Try to get required systems
            if not self.ClientRegistry then
                task.wait(0.5)
                return
            end
            
            self.SatisfactionClient = self.ClientRegistry:getSystem("SatisfactionClient")
            self.ClientEventBridge = self.ClientRegistry:getSystem("ClientEventBridge")
            self.UIManager = self.ClientRegistry:getSystem("UIManager")
            
            if self.SatisfactionClient and self.ClientEventBridge and self.UIManager then
                self:setup()
                break
            end
            
            task.wait(0.5)
        end
    end)
    
    return self
end

-- Set up the display
function SatisfactionDisplay:setup()
    if self.initialized then return end
    
    -- Register for events
    if self.ClientEventBridge then
        self.ClientEventBridge:registerEvent("UpdateSatisfactionUI", function(data)
            self:handleDataUpdate(data)
        end)
        
        self.ClientEventBridge:registerEvent("ShowSatisfactionPanel", function()
            self:show()
        end)
        
        self.ClientEventBridge:registerEvent("HideSatisfactionPanel", function()
            self:hide()
        end)
        
        self.ClientEventBridge:registerEvent("ToggleSatisfactionPanel", function()
            self:toggle()
        end)
    end
    
    -- Create the UI
    self:createGui()
    
    -- Get initial data if available
    if self.SatisfactionClient then
        self._currentData = self.SatisfactionClient:getSatisfactionData()
        self:updateDisplay(self._currentData)
    end
    
    self.initialized = true
    debugPrint("Satisfaction Display initialized")
    
    -- Hide the panel by default
    self:hide()
    
    return true
end

-- Create the satisfaction UI
function SatisfactionDisplay:createGui()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SatisfactionGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = CONFIG.mainFrameSize
    mainFrame.Position = CONFIG.mainFramePosition
    mainFrame.BackgroundColor3 = CONFIG.backgroundColor
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.AnchorPoint = Vector2.new(1, 0.5)
    mainFrame.Parent = screenGui
    
    -- Add corner radius
    local cornerRadius = Instance.new("UICorner")
    cornerRadius.CornerRadius = UDim.new(0, 10)
    cornerRadius.Parent = mainFrame
    
    -- Add shadow effect
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.ZIndex = -1
    shadow.Parent = mainFrame
    
    -- Create header
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "HeaderFrame"
    headerFrame.Size = UDim2.new(1, 0, 0, 40)
    headerFrame.Position = UDim2.new(0, 0, 0, 0)
    headerFrame.BackgroundColor3 = CONFIG.headerColor
    headerFrame.BorderSizePixel = 0
    headerFrame.ZIndex = 2
    headerFrame.Parent = mainFrame
    
    -- Add corner radius to header (just top corners)
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = headerFrame
    
    -- Header title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamSemibold
    titleLabel.Text = "Member Satisfaction"
    titleLabel.TextSize = 18
    titleLabel.TextColor3 = CONFIG.textColor
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 3
    titleLabel.Parent = headerFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 14
    closeButton.ZIndex = 3
    closeButton.Parent = headerFrame
    
    -- Add corner radius to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeButton
    
    -- Create content frame
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -50)
    contentFrame.Position = UDim2.new(0, 10, 0, 45)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ScrollBarThickness = 6
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 500) -- Will be adjusted based on content
    contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    contentFrame.Parent = mainFrame
    
    -- Create stat containers in the content frame
    self:createStatContainer(contentFrame, "satisfaction", "Member Satisfaction", 0)
    self:createStatContainer(contentFrame, "cleanliness", "Gym Cleanliness", 1)
    self:createStatContainer(contentFrame, "equipmentQuality", "Equipment Quality", 2)
    self:createStatContainer(contentFrame, "revenueFactor", "Revenue Multiplier", 3)
    self:createStatContainer(contentFrame, "retentionFactor", "Member Retention", 4)
    
    -- Add tips section
    self:createTipsSection(contentFrame, 5)
    
    -- Store main elements for later reference
    self._frames = {
        screenGui = screenGui,
        mainFrame = mainFrame,
        contentFrame = contentFrame,
        headerFrame = headerFrame
    }
    
    -- Connect close button
    closeButton.MouseButton1Click:Connect(function()
        self:hide()
    end)
end

-- Create individual stat container
function SatisfactionDisplay:createStatContainer(parent, statName, displayName, position)
    local yPos = position * 80
    
    local container = Instance.new("Frame")
    container.Name = statName .. "Container"
    container.Size = UDim2.new(1, 0, 0, 70)
    container.Position = UDim2.new(0, 0, 0, yPos)
    container.BackgroundTransparency = 0.8
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    container.BorderSizePixel = 0
    container.Parent = parent
    
    -- Add corner radius
    local cornerRadius = Instance.new("UICorner")
    cornerRadius.CornerRadius = UDim.new(0, 8)
    cornerRadius.Parent = container
    
    -- Add stat icon
    local iconImage = Instance.new("ImageLabel")
    iconImage.Name = "Icon"
    iconImage.Size = UDim2.new(0, 30, 0, 30)
    iconImage.Position = UDim2.new(0, 10, 0, 10)
    iconImage.BackgroundTransparency = 1
    iconImage.Image = CONFIG.icons[statName] or ""
    iconImage.Parent = container
    
    -- Add stat name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -60, 0, 25)
    nameLabel.Position = UDim2.new(0, 50, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.Text = displayName
    nameLabel.TextSize = 16
    nameLabel.TextColor3 = CONFIG.textColor
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = container
    
    -- Add progress bar background
    local barBackground = Instance.new("Frame")
    barBackground.Name = "BarBackground"
    barBackground.Size = UDim2.new(1, -20, 0, 20)
    barBackground.Position = UDim2.new(0, 10, 0, 40)
    barBackground.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    barBackground.BorderSizePixel = 0
    barBackground.Parent = container
    
    -- Add corner radius to bar background
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 5)
    barCorner.Parent = barBackground
    
    -- Add progress bar fill
    local barFill = Instance.new("Frame")
    barFill.Name = "BarFill"
    barFill.Size = UDim2.new(0.75, 0, 1, 0) -- Will be set dynamically
    barFill.BackgroundColor3 = CONFIG.satisfactionColors[70] -- Default color
    barFill.BorderSizePixel = 0
    barFill.Parent = barBackground
    
    -- Add corner radius to bar fill
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 5)
    fillCorner.Parent = barFill
    
    -- Add value label
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "ValueLabel"
    valueLabel.Size = UDim2.new(1, 0, 1, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = "75%" -- Will be set dynamically
    valueLabel.TextSize = 14
    valueLabel.TextColor3 = CONFIG.textColor
    valueLabel.Parent = barBackground
    
    -- Add tooltip button
    local tooltipButton = Instance.new("ImageButton")
    tooltipButton.Name = "TooltipButton"
    tooltipButton.Size = UDim2.new(0, 20, 0, 20)
    tooltipButton.Position = UDim2.new(1, -25, 0, 10)
    tooltipButton.BackgroundTransparency = 1
    tooltipButton.Image = "rbxassetid://3926305904" -- Info icon
    tooltipButton.ImageColor3 = Color3.fromRGB(200, 200, 255)
    tooltipButton.Parent = container
    
    -- Create tooltip (initially hidden)
    local tooltip = Instance.new("Frame")
    tooltip.Name = "Tooltip"
    tooltip.Size = UDim2.new(0, 200, 0, 40)
    tooltip.Position = UDim2.new(1, -210, 0, -45)
    tooltip.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    tooltip.BackgroundTransparency = 0.2
    tooltip.BorderSizePixel = 0
    tooltip.Visible = false
    tooltip.ZIndex = 10
    tooltip.Parent = container
    
    -- Add corner radius to tooltip
    local tooltipCorner = Instance.new("UICorner")
    tooltipCorner.CornerRadius = UDim.new(0, 5)
    tooltipCorner.Parent = tooltip
    
    -- Add tooltip text
    local tooltipText = Instance.new("TextLabel")
    tooltipText.Name = "TooltipText"
    tooltipText.Size = UDim2.new(1, -10, 1, -10)
    tooltipText.Position = UDim2.new(0, 5, 0, 5)
    tooltipText.BackgroundTransparency = 1
    tooltipText.Font = Enum.Font.Gotham
    tooltipText.Text = CONFIG.tooltips[statName] or ""
    tooltipText.TextSize = 12
    tooltipText.TextColor3 = CONFIG.textColor
    tooltipText.TextWrapped = true
    tooltipText.ZIndex = 11
    tooltipText.Parent = tooltip
    
    -- Store references
    self._frames[statName] = {
        container = container,
        barFill = barFill,
        valueLabel = valueLabel,
        tooltip = tooltip
    }
    
    -- Connect tooltip button
    tooltipButton.MouseEnter:Connect(function()
        tooltip.Visible = true
    end)
    
    tooltipButton.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)
end

-- Create tips section
function SatisfactionDisplay:createTipsSection(parent, position)
    local yPos = position * 80 + 10
    
    local tipsContainer = Instance.new("Frame")
    tipsContainer.Name = "TipsContainer"
    tipsContainer.Size = UDim2.new(1, 0, 0, 120)
    tipsContainer.Position = UDim2.new(0, 0, 0, yPos)
    tipsContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    tipsContainer.BackgroundTransparency = 0.7
    tipsContainer.BorderSizePixel = 0
    tipsContainer.Parent = parent
    
    -- Update content frame canvas size
    parent.CanvasSize = UDim2.new(0, 0, 0, yPos + 130)
    
    -- Add corner radius
    local cornerRadius = Instance.new("UICorner")
    cornerRadius.CornerRadius = UDim.new(0, 8)
    cornerRadius.Parent = tipsContainer
    
    -- Add title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -20, 0, 25)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "Tips to Improve Satisfaction"
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = CONFIG.textColor
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.Parent = tipsContainer
    
    -- Add tips text
    local tipsText = Instance.new("TextLabel")
    tipsText.Name = "TipsText"
    tipsText.Size = UDim2.new(1, -20, 0, 90)
    tipsText.Position = UDim2.new(0, 10, 0, 30)
    tipsText.BackgroundTransparency = 1
    tipsText.Font = Enum.Font.Gotham
    tipsText.Text = "• Hire janitors to maintain cleanliness\n• Hire maintenance staff to keep equipment in good condition\n• Maintain a good equipment-to-member ratio\n• Install amenities like showers and lockers\n• Run special events to boost satisfaction"
    tipsText.TextSize = 14
    tipsText.TextColor3 = CONFIG.textColor
    tipsText.TextWrapped = true
    tipsText.TextXAlignment = Enum.TextXAlignment.Left
    tipsText.TextYAlignment = Enum.TextYAlignment.Top
    tipsText.Parent = tipsContainer
    
    self._frames.tipsContainer = tipsContainer
end

-- Handle data updates
function SatisfactionDisplay:handleDataUpdate(data)
    -- Store the updated data
    for key, value in pairs(data) do
        self._currentData[key] = value
    end
    
    -- Update the display
    self:updateDisplay(self._currentData)
end

-- Update the display with current data
function SatisfactionDisplay:updateDisplay(data)
    -- Update satisfaction
    self:updateStatDisplay("satisfaction", data.satisfaction, 0, 100, "%")
    
    -- Update cleanliness
    self:updateStatDisplay("cleanliness", data.cleanliness, 0, 100, "%")
    
    -- Update equipment quality
    self:updateStatDisplay("equipmentQuality", data.equipmentQuality, 0, 100, "%")
    
    -- Update revenue factor (displayed as percentage modifier)
    local revenueModifier = math.floor((data.revenueFactor - 1) * 100)
    local revenueText = revenueModifier >= 0 and "+" .. revenueModifier or revenueModifier
    self:updateStatDisplay("revenueFactor", data.revenueFactor, 0.5, 1.5, " (" .. revenueText .. "%)", true)
    
    -- Update retention factor (displayed as percentage)
    local retentionPercent = math.floor(data.retentionFactor * 100)
    self:updateStatDisplay("retentionFactor", data.retentionFactor, 0.5, 1, "%", true)
end

-- Update individual stat display
function SatisfactionDisplay:updateStatDisplay(statName, value, min, max, suffix, isSpecial)
    local statFrames = self._frames[statName]
    if not statFrames then return end
    
    -- Calculate the fill percentage
    local fillPercent
    if isSpecial then
        -- For special values like multipliers
        fillPercent = (value - min) / (max - min)
    else
        -- For percentage values
        fillPercent = value / 100
    end
    
    -- Clamp fill percentage to valid range
    fillPercent = math.clamp(fillPercent, 0, 1)
    
    -- Determine color based on value (satisfaction scale)
    local color
    if not isSpecial then
        -- For percentage values, use satisfaction color scale
        for threshold, thresholdColor in pairs(CONFIG.satisfactionColors) do
            if value >= threshold then
                color = thresholdColor
                break
            end
        end
    else
        -- For special values, green is good
        if value >= 1 then
            color = CONFIG.satisfactionColors[90] -- Good color
        elseif value >= 0.8 then
            color = CONFIG.satisfactionColors[70] -- OK color
        else
            color = CONFIG.satisfactionColors[30] -- Bad color
        end
    end
    
    -- Set color and size
    local barFill = statFrames.barFill
    local valueLabel = statFrames.valueLabel
    
    -- Create tweens
    local sizeTween = TweenService:Create(
        barFill, 
        CONFIG.tweenInfo,
        {Size = UDim2.new(fillPercent, 0, 1, 0)}
    )
    
    local colorTween = TweenService:Create(
        barFill,
        CONFIG.tweenInfo,
        {BackgroundColor3 = color}
    )
    
    -- Start tweens
    sizeTween:Play()
    colorTween:Play()
    
    -- Update value text
    local displayValue
    if isSpecial then
        -- Format special values appropriately
        if statName == "revenueFactor" then
            displayValue = string.format("%.2fx%s", value, suffix or "")
        else
            displayValue = string.format("%d%s", math.floor(value * 100), suffix or "")
        end
    else
        -- Format regular percentage values
        displayValue = string.format("%d%s", math.floor(value), suffix or "")
    end
    
    valueLabel.Text = displayValue
end

-- Show the satisfaction panel
function SatisfactionDisplay:show()
    if not self._frames.mainFrame then return end
    
    -- Make the panel visible
    self._frames.screenGui.Enabled = true
    
    -- Animate it in
    self._frames.mainFrame.Position = UDim2.new(1, 50, 0.5, -150)
    
    local showTween = TweenService:Create(
        self._frames.mainFrame,
        CONFIG.tweenInfo,
        {Position = CONFIG.mainFramePosition}
    )
    
    showTween:Play()
    self.isVisible = true
    
    -- Update display with current data
    self:updateDisplay(self._currentData)
end

-- Hide the satisfaction panel
function SatisfactionDisplay:hide()
    if not self._frames.mainFrame or not self.isVisible then return end
    
    local hideTween = TweenService:Create(
        self._frames.mainFrame,
        CONFIG.tweenInfo,
        {Position = UDim2.new(1, 50, 0.5, -150)}
    )
    
    hideTween.Completed:Connect(function()
        if not self.isVisible then
            self._frames.screenGui.Enabled = false
        end
    end)
    
    hideTween:Play()
    self.isVisible = false
end

-- Toggle the satisfaction panel
function SatisfactionDisplay:toggle()
    if self.isVisible then
        self:hide()
    else
        self:show()
    end
end

-- Start the module
function SatisfactionDisplay:start()
    -- No special start behavior needed as init sets everything up
    return self
end

-- Stop the module
function SatisfactionDisplay:stop()
    -- Clean up if needed
    return self
end

return SatisfactionDisplay