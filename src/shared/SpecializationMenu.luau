-- SpecializationMenu.luau
-- UI Module for Gym Specialization Selection and Management
-- Place in ReplicatedStorage/UIModules

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Import client systems
local ClientRegistry = require(LocalPlayer.PlayerScripts.Core.ClientRegistry)
local UIManager = ClientRegistry.getSystem("UIManager")
local ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")
local NotificationSystem = ClientRegistry.getSystem("NotificationSystem")

-- Configuration
local CONFIG = {
    debugEnabled = true,
    baseColors = {
        bodybuilding = Color3.fromRGB(180, 50, 50),    -- Red theme
        cardio = Color3.fromRGB(50, 180, 80),          -- Green theme
        wellness = Color3.fromRGB(80, 120, 220),       -- Blue theme
        crosstraining = Color3.fromRGB(220, 150, 50),  -- Orange theme
        swimming = Color3.fromRGB(50, 150, 220),       -- Aqua theme
    },
    seasonalColors = {
        summer = Color3.fromRGB(255, 180, 50),         -- Sunny yellow
        winter = Color3.fromRGB(150, 200, 255),        -- Cold blue
        spring = Color3.fromRGB(200, 255, 150),        -- Fresh green
        fall = Color3.fromRGB(255, 150, 50),           -- Autumn orange
        holiday = Color3.fromRGB(255, 50, 50)          -- Festive red
    },
    cardPadding = UDim.new(0.02, 0),                   -- Space between specialization cards
    cardAspectRatio = 0.8,                             -- Height/Width ratio for cards
    defaultCategoryFilter = "All"                      -- Default category to show
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[SpecializationMenu]", ...)
    end
end

-- Module table
local SpecializationMenu = {}

-- Cached data
local specializations = {}
local currentSpecialization = "None"
local specializationLevel = 1
local selectedSpecialization = nil
local seasonalTimer = nil

-- Helper function to create a specialization card
local function createSpecializationCard(specialization)
    -- Create card frame
    local card = Instance.new("Frame")
    card.Name = specialization.id
    card.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel = 0
    
    -- Apply rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card
    
    -- Color accent at top
    local colorBar = Instance.new("Frame")
    colorBar.Name = "ColorBar"
    colorBar.Size = UDim2.new(1, 0, 0, 6)
    colorBar.BorderSizePixel = 0
    
    -- Determine color based on specialization type
    local baseType = specialization.id:lower()
    local color
    
    if specialization.seasonal then
        -- Use seasonal theme color
        if specialization.seasonal_theme then
            color = CONFIG.seasonalColors[specialization.seasonal_theme] or Color3.fromRGB(180, 180, 180)
        else
            color = Color3.fromRGB(180, 50, 180) -- Purple for unknown seasonal
        end
    else
        -- Use base specialization color
        for baseKey, baseColor in pairs(CONFIG.baseColors) do
            if baseType:find(baseKey) then
                color = baseColor
                break
            end
        end
        
        if not color then
            color = Color3.fromRGB(180, 180, 180) -- Gray for unknown type
        end
    end
    
    colorBar.BackgroundColor3 = color
    colorBar.Parent = card
    
    -- Round the top corners
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 10)
    barCorner.Parent = colorBar
    
    -- Fix bottom corners
    local bottomFix = Instance.new("Frame")
    bottomFix.Name = "BottomFix"
    bottomFix.Size = UDim2.new(1, 0, 0.5, 0)
    bottomFix.Position = UDim2.new(0, 0, 0.5, 0)
    bottomFix.BackgroundColor3 = colorBar.BackgroundColor3
    bottomFix.BorderSizePixel = 0
    bottomFix.Parent = colorBar
    
    -- Icon (if available)
    if specialization.icon and specialization.icon ~= "" then
        local iconFrame = Instance.new("ImageLabel")
        iconFrame.Name = "Icon"
        iconFrame.Size = UDim2.new(0.3, 0, 0.3, 0)
        iconFrame.Position = UDim2.new(0.5, 0, 0.25, 0)
        iconFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        iconFrame.BackgroundTransparency = 1
        iconFrame.Image = specialization.icon
        iconFrame.Parent = card
    end
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0.9, 0, 0.15, 0)
    title.Position = UDim2.new(0.5, 0, 0.45, 0)
    title.AnchorPoint = Vector2.new(0.5, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Text = specialization.name
    title.TextWrapped = true
    title.Parent = card
    
    -- Description
    local desc = Instance.new("TextLabel")
    desc.Name = "Description"
    desc.Size = UDim2.new(0.9, 0, 0.25, 0)
    desc.Position = UDim2.new(0.5, 0, 0.62, 0)
    desc.AnchorPoint = Vector2.new(0.5, 0)
    desc.BackgroundTransparency = 1
    desc.TextColor3 = Color3.fromRGB(200, 200, 200)
    desc.TextSize = 14
    desc.Font = Enum.Font.Gotham
    desc.Text = specialization.description
    desc.TextWrapped = true
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.Parent = card
    
    -- Seasonal indicator if applicable
    if specialization.seasonal then
        local seasonalBadge = Instance.new("Frame")
        seasonalBadge.Name = "SeasonalBadge"
        seasonalBadge.Size = UDim2.new(0.35, 0, 0.08, 0)
        seasonalBadge.Position = UDim2.new(0.05, 0, 0.05, 0)
        seasonalBadge.BackgroundColor3 = color
        seasonalBadge.BackgroundTransparency = 0.2
        seasonalBadge.BorderSizePixel = 0
        seasonalBadge.Parent = card
        
        -- Rounded corners
        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 10)
        badgeCorner.Parent = seasonalBadge
        
        -- Badge text
        local badgeText = Instance.new("TextLabel")
        badgeText.Name = "BadgeText"
        badgeText.Size = UDim2.new(1, -10, 1, 0)
        badgeText.Position = UDim2.new(0.5, 0, 0.5, 0)
        badgeText.AnchorPoint = Vector2.new(0.5, 0.5)
        badgeText.BackgroundTransparency = 1
        badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
        badgeText.TextSize = 12
        badgeText.Font = Enum.Font.GothamBold
        badgeText.Text = "SEASONAL"
        badgeText.Parent = seasonalBadge
        
        -- If there's a time limit, add a timer
        if specialization.endsIn then
            local endTime = os.time() + specialization.endsIn
            
            local timeLabel = Instance.new("TextLabel")
            timeLabel.Name = "TimeRemaining"
            timeLabel.Size = UDim2.new(0.9, 0, 0.08, 0)
            timeLabel.Position = UDim2.new(0.5, 0, 0.9, 0)
            timeLabel.AnchorPoint = Vector2.new(0.5, 0)
            timeLabel.BackgroundTransparency = 1
            timeLabel.TextColor3 = Color3.fromRGB(255, 220, 100) -- Gold color
            timeLabel.TextSize = 14
            timeLabel.Font = Enum.Font.Gotham
            timeLabel.Parent = card
            
            -- Update the time remaining
            local function updateTime()
                local timeLeft = endTime - os.time()
                if timeLeft <= 0 then
                    timeLabel.Text = "Ending soon!"
                    return
                end
                
                local days = math.floor(timeLeft / 86400)
                local hours = math.floor((timeLeft % 86400) / 3600)
                
                if days > 0 then
                    timeLabel.Text = "Ends in: " .. days .. "d " .. hours .. "h"
                else
                    local minutes = math.floor((timeLeft % 3600) / 60)
                    timeLabel.Text = "Ends in: " .. hours .. "h " .. minutes .. "m"
                end
            end
            
            -- Initial update
            updateTime()
            
            -- Create a timer to update the time
            task.spawn(function()
                while task.wait(60) do -- Update every minute
                    if card.Parent and timeLabel.Parent then
                        updateTime()
                    else
                        break -- Stop if card is destroyed
                    end
                end
            end)
        end
    end
    
    -- Select/Apply button
    local selectButton = Instance.new("TextButton")
    selectButton.Name = "SelectButton"
    selectButton.Size = UDim2.new(0.8, 0, 0.1, 0)
    selectButton.Position = UDim2.new(0.5, 0, 0.88, 0)
    selectButton.AnchorPoint = Vector2.new(0.5, 0)
    selectButton.BackgroundColor3 = color
    selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectButton.TextSize = 16
    selectButton.Font = Enum.Font.GothamSemibold
    selectButton.BorderSizePixel = 0
    
    -- Determine button state
    if currentSpecialization == specialization.id then
        selectButton.Text = "ACTIVE"
        selectButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80) -- Gray out when active
    else
        selectButton.Text = "SELECT"
    end
    
    -- Add rounded corners
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = selectButton
    
    -- Connect button
    selectButton.MouseButton1Click:Connect(function()
        SpecializationMenu:selectSpecialization(specialization.id)
    end)
    
    -- Add hover effect
    selectButton.MouseEnter:Connect(function()
        if currentSpecialization ~= specialization.id then
            selectButton.BackgroundColor3 = Color3.new(
                color.R * 1.1,
                color.G * 1.1,
                color.B * 1.1
            )
        end
    end)
    
    selectButton.MouseLeave:Connect(function()
        if currentSpecialization ~= specialization.id then
            selectButton.BackgroundColor3 = color
        else
            selectButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        end
    end)
    
    selectButton.Parent = card
    
    return card
end

-- Create the specialization menu UI
function SpecializationMenu.create(data)
    log("Creating specialization menu")
    
    -- Store specialization data if provided
    if data and data.specializations then
        specializations = data.specializations
    end
    
    if data and data.currentSpecialization then
        currentSpecialization = data.currentSpecialization
    end
    
    if data and data.level then
        specializationLevel = data.level
    end
    
    -- Create the ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SpecializationMenu"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    
    -- Create the main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 800, 0, 600)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    titleBar.BackgroundTransparency = 0.1
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    -- Add rounded corners to title bar
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    -- Fix bottom corners of title bar
    local bottomFix = Instance.new("Frame")
    bottomFix.Name = "BottomFix"
    bottomFix.Size = UDim2.new(1, 0, 0.5, 0)
    bottomFix.Position = UDim2.new(0, 0, 0.5, 0)
    bottomFix.BackgroundColor3 = titleBar.BackgroundColor3
    bottomFix.BackgroundTransparency = titleBar.BackgroundTransparency
    bottomFix.BorderSizePixel = 0
    bottomFix.Parent = titleBar
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -100, 1, 0)
    titleText.Position = UDim2.new(0, 20, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 24
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Text = "Gym Specializations"
    titleText.Parent = titleBar
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 36, 0, 36)
    closeButton.Position = UDim2.new(1, -18, 0.5, 0)
    closeButton.AnchorPoint = Vector2.new(1, 0.5)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "X"
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar
    
    -- Add rounded corners to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0.5, 0)
    closeCorner.Parent = closeButton
    
    -- Make the title bar draggable
    UIManager.makeFrameDraggable(mainFrame, titleBar)
    
    -- Category filter buttons
    local categoryBar = Instance.new("Frame")
    categoryBar.Name = "CategoryBar"
    categoryBar.Size = UDim2.new(1, -40, 0, 40)
    categoryBar.Position = UDim2.new(0, 20, 0, 60)
    categoryBar.BackgroundTransparency = 1
    categoryBar.Parent = mainFrame
    
    -- Category buttons
    local categories = {"All", "Standard", "Seasonal"}
    local buttonWidth = 1 / #categories
    
    for i, category in ipairs(categories) do
        local button = Instance.new("TextButton")
        button.Name = category .. "Button"
        button.Size = UDim2.new(buttonWidth, -10, 1, -10)
        button.Position = UDim2.new((i-1) * buttonWidth + 0.05, 0, 0, 5)
        button.BackgroundColor3 = category == CONFIG.defaultCategoryFilter 
            and Color3.fromRGB(80, 80, 180) 
            or Color3.fromRGB(60, 60, 60)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 16
        button.Font = Enum.Font.GothamMedium
        button.Text = category
        button.BorderSizePixel = 0
        
        -- Add rounded corners
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        
        -- Connect button
        button.MouseButton1Click:Connect(function()
            SpecializationMenu:filterByCategory(category)
        end)
        
        button.Parent = categoryBar
    end
    
    -- Create content frame for specialization cards
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -40, 1, -110)
    contentFrame.Position = UDim2.new(0, 20, 0, 100)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 6
    contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be set automatically
    contentFrame.Parent = mainFrame
    
    -- Grid layout for cards
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.3, -20, CONFIG.cardAspectRatio * 0.3, -20) -- 30% width minus padding
    gridLayout.CellPadding = UDim2.new(CONFIG.cardPadding, CONFIG.cardPadding)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = contentFrame
    
    -- Status text for no specializations
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, -40, 0, 30)
    statusText.Position = UDim2.new(0.5, 0, 0.5, 0)
    statusText.AnchorPoint = Vector2.new(0.5, 0.5)
    statusText.BackgroundTransparency = 1
    statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusText.TextSize = 18
    statusText.Font = Enum.Font.GothamMedium
    statusText.Text = "Loading specializations..."
    statusText.Visible = #specializations == 0
    statusText.Parent = contentFrame
    
    -- Current specialization info panel
    local infoPanel = Instance.new("Frame")
    infoPanel.Name = "InfoPanel"
    infoPanel.Size = UDim2.new(1, -40, 0, 80)
    infoPanel.Position = UDim2.new(0, 20, 1, -90)
    infoPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    infoPanel.BackgroundTransparency = 0.3
    infoPanel.BorderSizePixel = 0
    infoPanel.Visible = currentSpecialization ~= "None"
    infoPanel.Parent = mainFrame
    
    -- Add rounded corners
    local infoPanelCorner = Instance.new("UICorner")
    infoPanelCorner.CornerRadius = UDim.new(0, 8)
    infoPanelCorner.Parent = infoPanel
    
    -- Current specialization label
    local currentLabel = Instance.new("TextLabel")
    currentLabel.Name = "CurrentLabel"
    currentLabel.Size = UDim2.new(0.35, 0, 0.5, 0)
    currentLabel.Position = UDim2.new(0, 15, 0, 10)
    currentLabel.BackgroundTransparency = 1
    currentLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    currentLabel.TextSize = 16
    currentLabel.Font = Enum.Font.Gotham
    currentLabel.TextXAlignment = Enum.TextXAlignment.Left
    currentLabel.Text = "Current Specialization:"
    currentLabel.Parent = infoPanel
    
    -- Current specialization value
    local currentValue = Instance.new("TextLabel")
    currentValue.Name = "CurrentValue"
    currentValue.Size = UDim2.new(0.65, -20, 0.5, 0)
    currentValue.Position = UDim2.new(0.35, 0, 0, 10)
    currentValue.BackgroundTransparency = 1
    currentValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    currentValue.TextSize = 18
    currentValue.Font = Enum.Font.GothamBold
    currentValue.TextXAlignment = Enum.TextXAlignment.Left
    currentValue.Text = currentSpecialization ~= "None" and currentSpecialization or "None"
    currentValue.Parent = infoPanel
    
    -- Level label
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(0.25, 0, 0.5, 0)
    levelLabel.Position = UDim2.new(0, 15, 0.5, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    levelLabel.TextSize = 16
    levelLabel.Font = Enum.Font.Gotham
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelLabel.Text = "Mastery Level:"
    levelLabel.Parent = infoPanel
    
    -- Level progress bar background
    local levelBarBg = Instance.new("Frame")
    levelBarBg.Name = "LevelBarBg"
    levelBarBg.Size = UDim2.new(0.5, -20, 0.3, 0)
    levelBarBg.Position = UDim2.new(0.25, 0, 0.6, 0)
    levelBarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    levelBarBg.BorderSizePixel = 0
    levelBarBg.Parent = infoPanel
    
    -- Add rounded corners
    local levelBarBgCorner = Instance.new("UICorner")
    levelBarBgCorner.CornerRadius = UDim.new(0, 4)
    levelBarBgCorner.Parent = levelBarBg
    
    -- Level progress bar fill
    local levelBarFill = Instance.new("Frame")
    levelBarFill.Name = "LevelBarFill"
    levelBarFill.Size = UDim2.new(specializationLevel / 10, 0, 1, 0) -- Assuming max level is 10
    levelBarFill.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
    levelBarFill.BorderSizePixel = 0
    levelBarFill.Parent = levelBarBg
    
    -- Add rounded corners
    local levelBarFillCorner = Instance.new("UICorner")
    levelBarFillCorner.CornerRadius = UDim.new(0, 4)
    levelBarFillCorner.Parent = levelBarFill
    
    -- Level value
    local levelValue = Instance.new("TextLabel")
    levelValue.Name = "LevelValue"
    levelValue.Size = UDim2.new(0.25, 0, 0.5, 0)
    levelValue.Position = UDim2.new(0.75, 0, 0.5, 0)
    levelValue.BackgroundTransparency = 1
    levelValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    levelValue.TextSize = 18
    levelValue.Font = Enum.Font.GothamBold
    levelValue.TextXAlignment = Enum.TextXAlignment.Center
    levelValue.Text = specializationLevel .. " / 10"
    levelValue.Parent = infoPanel
    
    -- Request specializations if we don't have them
    if #specializations == 0 then
        ClientEventBridge.fireServerEvent("GetAvailableSpecializations")
    else
        -- Populate with existing specialization data
        SpecializationMenu:populateSpecializations(specializations)
    end
    
    -- Connect close button
    closeButton.MouseButton1Click:Connect(function()
        UIManager.closeUI("SpecializationMenu")
    end)
    
    -- Connect to server events for specialization data
    ClientEventBridge.connectEvent("SpecializationLevelUp", function(specName, newLevel)
        if currentSpecialization == specName then
            specializationLevel = newLevel
            
            -- Update UI elements
            if levelValue then levelValue.Text = specializationLevel .. " / 10" end
            if levelBarFill then levelBarFill.Size = UDim2.new(specializationLevel / 10, 0, 1, 0) end
        end
    end)
    
    -- Make the UI draggable
    UIManager.makeFrameDraggable(mainFrame, titleBar)
    
    return screenGui
end

-- Populate the UI with specialization cards
function SpecializationMenu:populateSpecializations(specList)
    if not specList or #specList == 0 then
        log("No specializations to populate")
        return
    end
    
    log("Populating " .. #specList .. " specializations")
    
    -- Store specializations
    specializations = specList
    
    local mainUI = LocalPlayer.PlayerGui:FindFirstChild("SpecializationMenu")
    if not mainUI then return end
    
    local contentFrame = mainUI.MainFrame.Content
    if not contentFrame then return end
    
    -- Clear existing status text
    local statusText = contentFrame:FindFirstChild("StatusText")
    if statusText then
        statusText.Visible = false
    end
    
    -- Clear existing cards
    for _, child in pairs(contentFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create cards for each specialization
    for i, spec in ipairs(specList) do
        local card = createSpecializationCard(spec)
        card.LayoutOrder = spec.seasonal and (i + 1000) or i -- Put seasonal ones after regular ones
        card.Parent = contentFrame
    end
    
    -- Default filter to show all
    self:filterByCategory(CONFIG.defaultCategoryFilter)
end

-- Filter specializations by category
function SpecializationMenu:filterByCategory(category)
    local mainUI = LocalPlayer.PlayerGui:FindFirstChild("SpecializationMenu")
    if not mainUI then return end
    
    -- Update category buttons
    local categoryBar = mainUI.MainFrame.CategoryBar
    for _, button in ipairs(categoryBar:GetChildren()) do
        if button:IsA("TextButton") then
            if button.Name == category .. "Button" then
                button.BackgroundColor3 = Color3.fromRGB(80, 80, 180) -- Selected
            else
                button.BackgroundColor3 = Color3.fromRGB(60, 60, 60) -- Not selected
            end
        end
    end
    
    -- Filter content
    local contentFrame = mainUI.MainFrame.Content
    if not contentFrame then return end
    
    for _, card in ipairs(contentFrame:GetChildren()) do
        if card:IsA("Frame") then
            if category == "All" then
                card.Visible = true
            elseif category == "Seasonal" then
                card.Visible = card:FindFirstChild("SeasonalBadge") ~= nil
            elseif category == "Standard" then
                card.Visible = card:FindFirstChild("SeasonalBadge") == nil
            end
        end
    end
end

-- Select a specialization
function SpecializationMenu:selectSpecialization(specializationId)
    log("Selected specialization: " .. specializationId)
    
    -- Store the selected specialization
    selectedSpecialization = specializationId
    
    -- If it's the same as current, do nothing
    if currentSpecialization == specializationId then
        NotificationSystem.showInfo({
            title = "Already Selected",
            message = "This specialization is already active."
        })
        return
    end
    
    -- Confirm selection
    local mainUI = LocalPlayer.PlayerGui:FindFirstChild("SpecializationMenu")
    if not mainUI then return end
    
    -- Create confirmation dialog
    local confirmFrame = Instance.new("Frame")
    confirmFrame.Name = "ConfirmFrame"
    confirmFrame.Size = UDim2.new(0, 400, 0, 200)
    confirmFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    confirmFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    confirmFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    confirmFrame.BorderSizePixel = 0
    confirmFrame.ZIndex = 100
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = confirmFrame
    
    -- Add confirmation message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, -40, 0, 80)
    messageLabel.Position = UDim2.new(0.5, 0, 0, 30)
    messageLabel.AnchorPoint = Vector2.new(0.5, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageLabel.TextSize = 18
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextWrapped = true
    messageLabel.Text = "Are you sure you want to specialize in " .. specializationId .. "?\n\nThis will change your gym's focus and bonuses."
    messageLabel.ZIndex = 101
    messageLabel.Parent = confirmFrame
    
    -- Add cancel button
    local cancelButton = Instance.new("TextButton")
    cancelButton.Name = "CancelButton"
    cancelButton.Size = UDim2.new(0.45, 0, 0, 40)
    cancelButton.Position = UDim2.new(0.05, 0, 1, -60)
    cancelButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelButton.TextSize = 16
    cancelButton.Font = Enum.Font.GothamMedium
    cancelButton.Text = "Cancel"
    cancelButton.BorderSizePixel = 0
    cancelButton.ZIndex = 101
    
    -- Add rounded corners
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 6)
    cancelCorner.Parent = cancelButton
    
    -- Add confirm button
    local confirmButton = Instance.new("TextButton")
    confirmButton.Name = "ConfirmButton"
    confirmButton.Size = UDim2.new(0.45, 0, 0, 40)
    confirmButton.Position = UDim2.new(0.5, 0, 1, -60)
    confirmButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
    confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmButton.TextSize = 16
    confirmButton.Font = Enum.Font.GothamMedium
    confirmButton.Text = "Confirm"
    confirmButton.BorderSizePixel = 0
    confirmButton.ZIndex = 101
    
    -- Add rounded corners
    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 6)
    confirmCorner.Parent = confirmButton
    
    -- Add dim background
    local dimBackground = Instance.new("Frame")
    dimBackground.Name = "DimBackground"
    dimBackground.Size = UDim2.new(1, 0, 1, 0)
    dimBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dimBackground.BackgroundTransparency = 0.7
    dimBackground.BorderSizePixel = 0
    dimBackground.ZIndex = 99
    
    -- Connect buttons
    cancelButton.MouseButton1Click:Connect(function()
        dimBackground:Destroy()
        confirmFrame:Destroy()
    end)
    
    confirmButton.MouseButton1Click:Connect(function()
        -- Send request to server
        ClientEventBridge.fireServerEvent("ChangeSpecialization", specializationId)
        
        -- Show loading indicator
        confirmButton.Text = "Applying..."
        confirmButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        
        -- Close confirmation dialog after a delay
        task.delay(0.5, function()
            if dimBackground and dimBackground.Parent then
                dimBackground:Destroy()
            end
            if confirmFrame and confirmFrame.Parent then
                confirmFrame:Destroy()
            end
        end)
    end)
    
    -- Parent the frames
    dimBackground.Parent = mainUI
    confirmFrame.Parent = mainUI
end

-- Update UI based on server changes
function SpecializationMenu:updateSpecializationUI(newSpecialization, oldSpecialization)
    currentSpecialization = newSpecialization
    
    local mainUI = LocalPlayer.PlayerGui:FindFirstChild("SpecializationMenu")
    if not mainUI then return end
    
    -- Update info panel
    local infoPanel = mainUI.MainFrame:FindFirstChild("InfoPanel")
    if infoPanel then
        infoPanel.Visible = newSpecialization ~= "None"
        
        local currentValue = infoPanel:FindFirstChild("CurrentValue")
        if currentValue then
            currentValue.Text = newSpecialization ~= "None" and newSpecialization or "None"
        end
    end
    
    -- Update card buttons
    local contentFrame = mainUI.MainFrame.Content
    if contentFrame then
        -- Find the old specialization card
        if oldSpecialization and oldSpecialization ~= "None" then
            local oldCard = contentFrame:FindFirstChild(oldSpecialization)
            if oldCard then
                local button = oldCard:FindFirstChild("SelectButton")
                if button then
                    button.Text = "SELECT"
                    button.BackgroundColor3 = oldCard.ColorBar.BackgroundColor3
                end
            end
        end
        
        -- Find the new specialization card
        if newSpecialization and newSpecialization ~= "None" then
            local newCard = contentFrame:FindFirstChild(newSpecialization)
            if newCard then
                local button = newCard:FindFirstChild("SelectButton")
                if button then
                    button.Text = "ACTIVE"
                    button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                end
            end
        end
    end
    
    -- Show confirmation message
    NotificationSystem.showSuccess({
        title = "Specialization Changed",
        message = "Your gym is now specialized in " .. newSpecialization
    })
end

-- Handle when the UI opens
function SpecializationMenu.open(ui, data)
    log("Opening specialization menu")
    
    -- Request fresh data
    ClientEventBridge.fireServerEvent("GetAvailableSpecializations")
    
    -- Connect to server events if not already connected
    if not SpecializationMenu.eventConnected then
        -- Handle receiving specialization list
        ClientEventBridge.connectEvent("SpecializationDataReceived", function(specList)
            SpecializationMenu:populateSpecializations(specList)
        end)
        
        -- Handle specialization changes
        ClientEventBridge.connectEvent("SpecializationChanged", function(newSpec, oldSpec)
            SpecializationMenu:updateSpecializationUI(newSpec, oldSpec)
        end)
        
        SpecializationMenu.eventConnected = true
    end
    
    return true
end

-- Handle when the UI closes
function SpecializationMenu.close(ui)
    log("Closing specialization menu")
    
    -- Clean up any timers
    if seasonalTimer then
        seasonalTimer:Disconnect()
        seasonalTimer = nil
    end
    
    -- Destroy the UI
    if ui and ui.Parent then
        ui:Destroy()
    end
    
    return true
end

return SpecializationMenu