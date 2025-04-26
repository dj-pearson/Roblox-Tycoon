--!strict
--[[
    RebirthUI.luau
    
    Consolidated rebirth system interface that combines features from multiple implementations.
    Displays rebirth options, prerequisites, benefits, and confirmation dialogs.
    
    Features:
    - Enhanced statistics and rebirth history
    - Animated transitions
    - Detailed benefit breakdowns
    - Multiple rebirth tier options
    
    Authors: Combined from multiple implementations, updated April 26, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Safe require utility
local function requireSafely(moduleScript)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        return nil
    end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if not success then
        warn("Failed to load module: " .. moduleScript.Name .. " - " .. tostring(result))
        return nil
    end
    
    return result
end

-- Find paths to important folders
local srcFolder = ReplicatedStorage:FindFirstChild("src") 
if not srcFolder then
    error("Source folder not found")
    return
end

local sharedFolder = srcFolder:FindFirstChild("shared")
if not sharedFolder then
    error("Shared folder not found")
    return
end

local clientFolder = srcFolder:FindFirstChild("client")
local clientUIFolder = clientFolder and clientFolder:FindFirstChild("UI")
local clientCoreFolder = clientFolder and clientFolder:FindFirstChild("Core")
local uiCoreFolder = clientUIFolder and clientUIFolder:FindFirstChild("Core")

-- Required modules
local UIStyle = requireSafely(sharedFolder:FindFirstChild("UIStyle"))
local ButtonFactory = requireSafely(sharedFolder:FindFirstChild("ButtonFactory")) 
local UIUtils = requireSafely(sharedFolder:FindFirstChild("UIUtils"))
local DialogFactory = requireSafely(sharedFolder:FindFirstChild("DialogFactory"))
local UIManager = requireSafely(uiCoreFolder and uiCoreFolder:FindFirstChild("UIManager"))
local UIRegistry = requireSafely(uiCoreFolder and uiCoreFolder:FindFirstChild("UIRegistry"))
local ClientRegistry = requireSafely(clientCoreFolder and clientCoreFolder:FindFirstChild("ClientRegistry"))

-- Create fallbacks for critical modules
if not UIStyle then
    warn("UIStyle module not found, using fallback implementation")
    UIStyle = {
        Colors = {
            Primary = Color3.fromRGB(0, 120, 215),
            Secondary = Color3.fromRGB(45, 45, 45),
            Background = Color3.fromRGB(30, 30, 30),
            Text = Color3.fromRGB(255, 255, 255),
            TextDisabled = Color3.fromRGB(150, 150, 150),
            Success = Color3.fromRGB(46, 204, 113),
            Warning = Color3.fromRGB(230, 126, 34),
            Error = Color3.fromRGB(231, 76, 60)
        },
        Fonts = {
            Regular = Enum.Font.Gotham,
            Bold = Enum.Font.GothamBold,
            Light = Enum.Font.GothamMedium
        },
        Animations = {
            Standard = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            Slow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        },
        Padding = {
            Small = UDim.new(0, 5),
            Medium = UDim.new(0, 10),
            Large = UDim.new(0, 20)
        },
        CornerRadius = UDim.new(0, 8)
    }
end

if not ButtonFactory then
    warn("ButtonFactory module not found, using fallback implementation")
    ButtonFactory = {
        createButton = function(properties)
            local button = Instance.new("TextButton")
            button.Size = properties.size or UDim2.new(0, 200, 0, 50)
            button.Position = properties.position or UDim2.new(0, 0, 0, 0)
            button.BackgroundColor3 = properties.backgroundColor or UIStyle.Colors.Primary
            button.BorderSizePixel = 0
            button.Text = properties.text or "Button"
            button.TextColor3 = properties.textColor or UIStyle.Colors.Text
            button.Font = properties.font or UIStyle.Fonts.Regular
            button.TextSize = properties.textSize or 16
            button.Parent = properties.parent
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UIStyle.CornerRadius
            corner.Parent = button
            
            if properties.callback then
                button.Activated:Connect(properties.callback)
            end
            
            return button
        end
    }
end

-- Wait for the remote event
local RebirthRemote = ReplicatedStorage:WaitForChild("RebirthRemote")

-- Module and state variables
local RebirthUI = {}
local uiElements = {
    mainFrame = nil,
    tabs = {},
    activeTab = nil,
    confirmationDialog = nil
}

-- Configuration
local CONFIG = {
    animationDuration = 0.3,
    tabCount = 4, -- Overview, Benefits, History, Advanced
    mainFrameSize = UDim2.new(0, 600, 0, 400),
    tabButtonSize = UDim2.new(0.25, -10, 0, 30),
    tabContentSize = UDim2.new(1, -20, 1, -50),
    rebirthLevels = {
        {
            name = "Basic Rebirth",
            cost = 10000,
            level = 1,
            benefits = {
                "10% Revenue Bonus",
                "5% Discount on Equipment",
                "Faster Member Attraction",
                "Exclusive Basic Decorations"
            }
        },
        {
            name = "Advanced Rebirth",
            cost = 100000,
            level = 2,
            benefits = {
                "25% Revenue Bonus",
                "15% Discount on Equipment",
                "Much Faster Member Attraction",
                "Exclusive Advanced Decorations",
                "Ability to hire special trainers"
            }
        },
        {
            name = "Master Rebirth",
            cost = 1000000,
            level = 3,
            benefits = {
                "50% Revenue Bonus",
                "30% Discount on Equipment",
                "Ultra Fast Member Attraction",
                "Exclusive Master Decorations",
                "Special VIP Members",
                "Gym Specialization Bonuses"
            }
        }
    }
}

--[[ UI Creation Functions ]]--

-- Create the main UI
local function createMainUI()
    -- Create or find the ScreenGui
    local screenGui = PlayerGui:FindFirstChild("RebirthUI")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "RebirthUI"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = PlayerGui
    end
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = CONFIG.mainFrameSize
    mainFrame.Position = UDim2.new(0.5, -CONFIG.mainFrameSize.X.Offset / 2, 0.5, -CONFIG.mainFrameSize.Y.Offset / 2)
    mainFrame.BackgroundColor3 = UIStyle.Colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false -- Start hidden
    mainFrame.Parent = screenGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UIStyle.CornerRadius
    corner.Parent = mainFrame
    
    -- Add title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -100, 0, 40)
    title.Position = UDim2.new(0, 20, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Rebirth System"
    title.Font = UIStyle.Fonts.Bold
    title.TextSize = 24
    title.TextColor3 = UIStyle.Colors.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = mainFrame
    
    -- Add close button
    local closeButton = ButtonFactory.createButton({
        size = UDim2.new(0, 32, 0, 32),
        position = UDim2.new(1, -42, 0, 10),
        backgroundColor = UIStyle.Colors.Error,
        text = "X",
        textSize = 18,
        font = UIStyle.Fonts.Bold,
        parent = mainFrame,
        callback = function()
            RebirthUI:hide()
        end
    })
    
    -- Create tab buttons container
    local tabButtonsContainer = Instance.new("Frame")
    tabButtonsContainer.Name = "TabButtons"
    tabButtonsContainer.Size = UDim2.new(1, -20, 0, 30)
    tabButtonsContainer.Position = UDim2.new(0, 10, 0, 60)
    tabButtonsContainer.BackgroundTransparency = 1
    tabButtonsContainer.Parent = mainFrame
    
    -- Create tab content container
    local tabContentContainer = Instance.new("Frame")
    tabContentContainer.Name = "TabContent"
    tabContentContainer.Size = CONFIG.tabContentSize
    tabContentContainer.Position = UDim2.new(0, 10, 0, 100)
    tabContentContainer.BackgroundTransparency = 1
    tabContentContainer.Parent = mainFrame
    
    -- Store references
    uiElements.mainFrame = mainFrame
    uiElements.tabButtonsContainer = tabButtonsContainer
    uiElements.tabContentContainer = tabContentContainer
    uiElements.screenGui = screenGui
    
    return mainFrame
end

-- Create the tabs
local function createTabs()
    local tabNames = {"Overview", "Benefits", "History", "Advanced"}
    local tabButtons = {}
    local tabContents = {}
    
    -- Create tab buttons
    for i, tabName in ipairs(tabNames) do
        local button = ButtonFactory.createButton({
            size = CONFIG.tabButtonSize,
            position = UDim2.new((i - 1) * 0.25, 5, 0, 0),
            backgroundColor = i == 1 and UIStyle.Colors.Primary or UIStyle.Colors.Secondary,
            text = tabName,
            textSize = 14,
            parent = uiElements.tabButtonsContainer,
            callback = function()
                RebirthUI:switchTab(tabName)
            end
        })
        
        tabButtons[tabName] = button
        
        -- Create content frame for this tab
        local contentFrame = Instance.new("Frame")
        contentFrame.Name = tabName .. "Content"
        contentFrame.Size = UDim2.new(1, 0, 1, 0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.Visible = i == 1 -- Only first tab visible by default
        contentFrame.Parent = uiElements.tabContentContainer
        
        tabContents[tabName] = contentFrame
    end
    
    -- Store references
    uiElements.tabs = {
        buttons = tabButtons,
        contents = tabContents
    }
    uiElements.activeTab = "Overview"
    
    -- Now populate each tab's content
    createOverviewTabContent(tabContents["Overview"])
    createBenefitsTabContent(tabContents["Benefits"])
    createHistoryTabContent(tabContents["History"])
    createAdvancedTabContent(tabContents["Advanced"])
end

-- Create content for the Overview tab
local function createOverviewTabContent(contentFrame)
    -- Description text
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, 0, 0, 60)
    description.Position = UDim2.new(0, 0, 0, 0)
    description.BackgroundTransparency = 1
    description.Text = "Rebirth allows you to restart with powerful permanent bonuses. You'll lose your gym progress but gain significant advantages in your next playthrough."
    description.TextWrapped = true
    description.Font = UIStyle.Fonts.Regular
    description.TextSize = 16
    description.TextColor3 = UIStyle.Colors.Text
    description.Parent = contentFrame
    
    -- Current stats
    local currentStats = Instance.new("Frame")
    currentStats.Name = "CurrentStats"
    currentStats.Size = UDim2.new(1, 0, 0, 100)
    currentStats.Position = UDim2.new(0, 0, 0, 70)
    currentStats.BackgroundTransparency = 1
    currentStats.Parent = contentFrame
    
    local statsTitle = Instance.new("TextLabel")
    statsTitle.Name = "StatsTitle"
    statsTitle.Size = UDim2.new(1, 0, 0, 30)
    statsTitle.Position = UDim2.new(0, 0, 0, 0)
    statsTitle.BackgroundTransparency = 1
    statsTitle.Text = "Your Current Stats"
    statsTitle.Font = UIStyle.Fonts.Bold
    statsTitle.TextSize = 18
    statsTitle.TextColor3 = UIStyle.Colors.Text
    statsTitle.TextXAlignment = Enum.TextXAlignment.Left
    statsTitle.Parent = currentStats
    
    -- Stats container
    local statsContainer = Instance.new("Frame")
    statsContainer.Name = "StatsContainer"
    statsContainer.Size = UDim2.new(1, 0, 0, 70)
    statsContainer.Position = UDim2.new(0, 0, 0, 30)
    statsContainer.BackgroundTransparency = 1
    statsContainer.Parent = currentStats
    
    -- Create stats rows
    local statRows = {
        { name = "Lifetime Revenue", value = "$0", id = "revenue" },
        { name = "Current Level", value = "1", id = "level" },
        { name = "Equipment Owned", value = "0", id = "equipment" },
        { name = "Rebirth Level", value = "0", id = "rebirthLevel" }
    }
    
    for i, stat in ipairs(statRows) do
        local row = Instance.new("Frame")
        row.Name = stat.id .. "Row"
        row.Size = UDim2.new(1, 0, 0, 20)
        row.Position = UDim2.new(0, 0, 0, (i - 1) * 25)
        row.BackgroundTransparency = 1
        row.Parent = statsContainer
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Name"
        nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = stat.name
        nameLabel.Font = UIStyle.Fonts.Regular
        nameLabel.TextSize = 16
        nameLabel.TextColor3 = UIStyle.Colors.Text
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = row
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "Value"
        valueLabel.Size = UDim2.new(0.4, 0, 1, 0)
        valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = stat.value
        valueLabel.Font = UIStyle.Fonts.Bold
        valueLabel.TextSize = 16
        valueLabel.TextColor3 = UIStyle.Colors.Primary
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
        valueLabel.Parent = row
        
        -- Store reference for updating later
        uiElements[stat.id .. "Value"] = valueLabel
    end
    
    -- Rebirth button container 
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, 0, 0, 60)
    buttonContainer.Position = UDim2.new(0, 0, 1, -60)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = contentFrame
    
    -- Rebirth button
    local rebirthButton = ButtonFactory.createButton({
        size = UDim2.new(0.6, 0, 0, 50),
        position = UDim2.new(0.2, 0, 0, 0),
        backgroundColor = UIStyle.Colors.Primary,
        text = "Rebirth Now",
        textSize = 20,
        font = UIStyle.Fonts.Bold,
        parent = buttonContainer,
        callback = function()
            RebirthUI:showConfirmationDialog()
        end
    })
    
    -- Store reference
    uiElements.rebirthButton = rebirthButton
end

-- Create content for the Benefits tab
local function createBenefitsTabContent(contentFrame)
    -- Description text
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, 0, 0, 40)
    description.Position = UDim2.new(0, 0, 0, 0)
    description.BackgroundTransparency = 1
    description.Text = "Each rebirth level provides different benefits. Higher rebirth tiers require more resources but offer greater advantages."
    description.TextWrapped = true
    description.Font = UIStyle.Fonts.Regular
    description.TextSize = 16
    description.TextColor3 = UIStyle.Colors.Text
    description.Parent = contentFrame
    
    -- Benefits container
    local benefitsContainer = Instance.new("ScrollingFrame")
    benefitsContainer.Name = "BenefitsContainer"
    benefitsContainer.Size = UDim2.new(1, 0, 1, -50)
    benefitsContainer.Position = UDim2.new(0, 0, 0, 50)
    benefitsContainer.BackgroundTransparency = 1
    benefitsContainer.BorderSizePixel = 0
    benefitsContainer.ScrollBarThickness = 6
    benefitsContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    benefitsContainer.CanvasSize = UDim2.new(0, 0, 0, #CONFIG.rebirthLevels * 160) -- Height per card
    benefitsContainer.Parent = contentFrame
    
    -- Add list layout
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = benefitsContainer
    
    -- Create a card for each rebirth level
    for i, level in ipairs(CONFIG.rebirthLevels) do
        local card = Instance.new("Frame")
        card.Name = "RebirthLevel" .. level.level
        card.Size = UDim2.new(1, -10, 0, 150)
        card.BackgroundColor3 = UIStyle.Colors.Secondary
        card.BorderSizePixel = 0
        card.Parent = benefitsContainer
        
        -- Add corner radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UIStyle.CornerRadius
        corner.Parent = card
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -20, 0, 30)
        title.Position = UDim2.new(0, 10, 0, 10)
        title.BackgroundTransparency = 1
        title.Text = level.name
        title.Font = UIStyle.Fonts.Bold
        title.TextSize = 18
        title.TextColor3 = UIStyle.Colors.Text
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = card
        
        -- Cost
        local cost = Instance.new("TextLabel")
        cost.Name = "Cost"
        cost.Size = UDim2.new(0.4, 0, 0, 20)
        cost.Position = UDim2.new(0, 10, 0, 40)
        cost.BackgroundTransparency = 1
        cost.Text = "Cost: $" .. formatNumber(level.cost)
        cost.Font = UIStyle.Fonts.Regular
        cost.TextSize = 14
        cost.TextColor3 = UIStyle.Colors.TextDisabled
        cost.TextXAlignment = Enum.TextXAlignment.Left
        cost.Parent = card
        
        -- Level
        local levelLabel = Instance.new("TextLabel")
        levelLabel.Name = "Level"
        levelLabel.Size = UDim2.new(0.3, 0, 0, 20)
        levelLabel.Position = UDim2.new(0.4, 0, 0, 40)
        levelLabel.BackgroundTransparency = 1
        levelLabel.Text = "Level: " .. level.level
        levelLabel.Font = UIStyle.Fonts.Regular
        levelLabel.TextSize = 14
        levelLabel.TextColor3 = UIStyle.Colors.TextDisabled
        levelLabel.TextXAlignment = Enum.TextXAlignment.Left
        levelLabel.Parent = card
        
        -- Benefits container
        local benefitsList = Instance.new("Frame")
        benefitsList.Name = "BenefitsList"
        benefitsList.Size = UDim2.new(1, -20, 0, #level.benefits * 20 + 10)
        benefitsList.Position = UDim2.new(0, 10, 0, 70)
        benefitsList.BackgroundTransparency = 1
        benefitsList.Parent = card
        
        -- Benefits items
        for j, benefit in ipairs(level.benefits) do
            local item = Instance.new("Frame")
            item.Name = "Benefit" .. j
            item.Size = UDim2.new(1, 0, 0, 20)
            item.Position = UDim2.new(0, 0, 0, (j - 1) * 20)
            item.BackgroundTransparency = 1
            item.Parent = benefitsList
            
            local bullet = Instance.new("TextLabel")
            bullet.Name = "Bullet"
            bullet.Size = UDim2.new(0, 20, 0, 20)
            bullet.BackgroundTransparency = 1
            bullet.Text = "•"
            bullet.Font = UIStyle.Fonts.Bold
            bullet.TextSize = 18
            bullet.TextColor3 = UIStyle.Colors.Primary
            bullet.Parent = item
            
            local text = Instance.new("TextLabel")
            text.Name = "Text"
            text.Size = UDim2.new(1, -25, 1, 0)
            text.Position = UDim2.new(0, 25, 0, 0)
            text.BackgroundTransparency = 1
            text.Text = benefit
            text.Font = UIStyle.Fonts.Regular
            text.TextSize = 14
            text.TextColor3 = UIStyle.Colors.Text
            text.TextXAlignment = Enum.TextXAlignment.Left
            text.Parent = item
        end
    end
end

-- Create content for the History tab
local function createHistoryTabContent(contentFrame)
    -- Description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, 0, 0, 40)
    description.Position = UDim2.new(0, 0, 0, 0)
    description.BackgroundTransparency = 1
    description.Text = "View your rebirth history and progress across playthroughs."
    description.TextWrapped = true
    description.Font = UIStyle.Fonts.Regular
    description.TextSize = 16
    description.TextColor3 = UIStyle.Colors.Text
    description.Parent = contentFrame
    
    -- Create history table header
    local tableHeader = Instance.new("Frame")
    tableHeader.Name = "TableHeader"
    tableHeader.Size = UDim2.new(1, 0, 0, 30)
    tableHeader.Position = UDim2.new(0, 0, 0, 50)
    tableHeader.BackgroundColor3 = UIStyle.Colors.Primary
    tableHeader.BorderSizePixel = 0
    tableHeader.Parent = contentFrame
    
    -- Add column headers
    local columns = {
        { name = "#", width = 0.1 },
        { name = "Date", width = 0.25 },
        { name = "Level", width = 0.15 },
        { name = "Revenue", width = 0.25 },
        { name = "Equipment", width = 0.25 }
    }
    
    for i, column in ipairs(columns) do
        local header = Instance.new("TextLabel")
        header.Name = column.name .. "Header"
        header.Size = UDim2.new(column.width, 0, 1, 0)
        header.Position = UDim2.new(i == 1 and 0 or columns[i-1].width + (columns[i-2] and columns[i-2].width or 0), 0, 0, 0)
        header.BackgroundTransparency = 1
        header.Text = column.name
        header.Font = UIStyle.Fonts.Bold
        header.TextSize = 14
        header.TextColor3 = UIStyle.Colors.Text
        header.Parent = tableHeader
    end
    
    -- Create the history table
    local historyTable = Instance.new("ScrollingFrame")
    historyTable.Name = "HistoryTable"
    historyTable.Size = UDim2.new(1, 0, 1, -90)
    historyTable.Position = UDim2.new(0, 0, 0, 90)
    historyTable.BackgroundTransparency = 1
    historyTable.BorderSizePixel = 0
    historyTable.ScrollBarThickness = 6
    historyTable.ScrollingDirection = Enum.ScrollingDirection.Y
    historyTable.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be set dynamically
    historyTable.Parent = contentFrame
    
    -- Add list layout
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = historyTable
    
    -- Store references
    uiElements.historyTable = historyTable
end

-- Create content for the Advanced tab
local function createAdvancedTabContent(contentFrame)
    -- Description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, 0, 0, 40)
    description.Position = UDim2.new(0, 0, 0, 0)
    description.BackgroundTransparency = 1
    description.Text = "Advanced rebirth options and specialized configurations."
    description.TextWrapped = true
    description.Font = UIStyle.Fonts.Regular
    description.TextSize = 16
    description.TextColor3 = UIStyle.Colors.Text
    description.Parent = contentFrame
    
    -- Create options container
    local optionsContainer = Instance.new("Frame")
    optionsContainer.Name = "OptionsContainer"
    optionsContainer.Size = UDim2.new(1, 0, 1, -50)
    optionsContainer.Position = UDim2.new(0, 0, 0, 50)
    optionsContainer.BackgroundTransparency = 1
    optionsContainer.Parent = contentFrame
    
    -- Create toggle options
    local toggleOptions = {
        { name = "Keep Decorations", default = false, id = "keepDecorations" },
        { name = "Keep Research", default = false, id = "keepResearch" },
        { name = "Hard Mode (+50% Bonus)", default = false, id = "hardMode" },
        { name = "Fast Start (Begin with basic equipment)", default = false, id = "fastStart" }
    }
    
    for i, option in ipairs(toggleOptions) do
        local toggle = Instance.new("Frame")
        toggle.Name = option.id .. "Toggle"
        toggle.Size = UDim2.new(1, 0, 0, 40)
        toggle.Position = UDim2.new(0, 0, 0, (i - 1) * 50)
        toggle.BackgroundTransparency = 1
        toggle.Parent = optionsContainer
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = option.name
        label.Font = UIStyle.Fonts.Regular
        label.TextSize = 16
        label.TextColor3 = UIStyle.Colors.Text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = toggle
        
        local toggleButton = Instance.new("TextButton")
        toggleButton.Name = "Button"
        toggleButton.Size = UDim2.new(0.2, 0, 0, 30)
        toggleButton.Position = UDim2.new(0.8, 0, 0.5, -15)
        toggleButton.BackgroundColor3 = option.default and UIStyle.Colors.Primary or UIStyle.Colors.Secondary
        toggleButton.BorderSizePixel = 0
        toggleButton.Text = option.default and "ON" or "OFF"
        toggleButton.Font = UIStyle.Fonts.Bold
        toggleButton.TextSize = 14
        toggleButton.TextColor3 = UIStyle.Colors.Text
        toggleButton.Parent = toggle
        
        -- Add corner radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = toggleButton
        
        -- Button callback
        toggleButton.Activated:Connect(function()
            -- Toggle state
            local isOn = toggleButton.Text == "ON"
            toggleButton.Text = isOn and "OFF" or "ON"
            toggleButton.BackgroundColor3 = isOn and UIStyle.Colors.Secondary or UIStyle.Colors.Primary
            
            -- Store state in uiElements
            uiElements[option.id] = not isOn
        end)
        
        -- Initialize state
        uiElements[option.id] = option.default
    end
    
    -- Reset options button
    local resetButton = ButtonFactory.createButton({
        size = UDim2.new(0.6, 0, 0, 40),
        position = UDim2.new(0.2, 0, 0.8, 0),
        backgroundColor = UIStyle.Colors.Warning,
        text = "Reset to Default",
        textSize = 16,
        font = UIStyle.Fonts.Bold,
        parent = optionsContainer,
        callback = function()
            -- Reset all toggles to default
            for _, option in ipairs(toggleOptions) do
                local toggle = optionsContainer:FindFirstChild(option.id .. "Toggle")
                if toggle then
                    local button = toggle:FindFirstChild("Button")
                    if button then
                        button.Text = option.default and "ON" or "OFF"
                        button.BackgroundColor3 = option.default and UIStyle.Colors.Primary or UIStyle.Colors.Secondary
                        uiElements[option.id] = option.default
                    end
                end
            end
        end
    })
end

--[[ Helper Functions ]]--

-- Format a number with commas
local function formatNumber(number)
    local formatted = tostring(number)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Show confirmation dialog
function RebirthUI:showConfirmationDialog()
    -- Create dialog content
    local content = "Are you sure you want to rebirth? You will lose:\n\n"
    content = content .. "• Your current gym and equipment\n"
    content = content .. "• All current members\n"
    content = content .. "• Research progress\n\n"
    content = content .. "In return, you'll gain permanent bonuses for all future playthroughs."
    
    -- Use DialogFactory if available
    if DialogFactory and DialogFactory.createConfirmation then
        uiElements.confirmationDialog = DialogFactory.createConfirmation({
            title = "Confirm Rebirth",
            message = content,
            confirmText = "Rebirth",
            cancelText = "Cancel",
            onConfirm = function()
                RebirthUI:performRebirth()
            end
        })
    else
        -- Fallback implementation
        uiElements.confirmationDialog = UIManager and UIManager:createModal({
            title = "Confirm Rebirth",
            message = content,
            buttons = {
                {
                    text = "Rebirth",
                    color = UIStyle.Colors.Primary,
                    callback = function()
                        RebirthUI:performRebirth()
                    end
                },
                {
                    text = "Cancel",
                    color = UIStyle.Colors.Secondary
                }
            }
        })
    end
end

-- Perform the rebirth
function RebirthUI:performRebirth()
    -- Get advanced options
    local options = {
        keepDecorations = uiElements.keepDecorations or false,
        keepResearch = uiElements.keepResearch or false,
        hardMode = uiElements.hardMode or false,
        fastStart = uiElements.fastStart or false
    }
    
    -- Call the rebirth remote
    RebirthRemote:FireServer(options)
    
    -- Show a success message
    if UIManager then
        UIManager:createNotification({
            message = "Rebirth successful! You've gained permanent bonuses.",
            type = "success",
            duration = 5
        })
    end
    
    -- Update the UI
    self:updateRebirthInfo()
    
    -- Hide the UI
    self:hide()
    
    -- Create rebirth animation
    self:playRebirthAnimation()
end

-- Play rebirth animation
function RebirthUI:playRebirthAnimation()
    -- Create a full-screen white overlay that fades in and out
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.new(1, 1, 1)
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 1000
    overlay.Parent = PlayerGui
    
    -- Add text
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(0.8, 0, 0.2, 0)
    text.Position = UDim2.new(0.1, 0, 0.4, 0)
    text.BackgroundTransparency = 1
    text.Text = "REBIRTH COMPLETE"
    text.TextColor3 = Color3.new(0, 0, 0)
    text.TextTransparency = 1
    text.Font = UIStyle.Fonts.Bold
    text.TextSize = 48
    text.ZIndex = 1001
    text.Parent = overlay
    
    -- Fade in
    local fadeInTween = TweenService:Create(
        overlay,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0 }
    )
    
    local textFadeInTween = TweenService:Create(
        text,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { TextTransparency = 0 }
    )
    
    fadeInTween:Play()
    fadeInTween.Completed:Connect(function()
        textFadeInTween:Play()
        
        -- Wait and fade out
        task.delay(2, function()
            local fadeOutTween = TweenService:Create(
                overlay,
                TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { BackgroundTransparency = 1 }
            )
            
            local textFadeOutTween = TweenService:Create(
                text,
                TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { TextTransparency = 1 }
            )
            
            textFadeOutTween:Play()
            fadeOutTween:Play()
            
            fadeOutTween.Completed:Connect(function()
                overlay:Destroy()
            end)
        end)
    end)
end

-- Update rebirth info from server data
function RebirthUI:updateRebirthInfo()
    -- Remote call to get updated data
    local success, data = pcall(function()
        return RebirthRemote:InvokeServer("getRebirthInfo")
    end)
    
    if not success or not data then
        warn("Failed to get rebirth info")
        return
    end
    
    -- Update UI elements with new data
    if uiElements.revenueValue then
        uiElements.revenueValue.Text = "$" .. formatNumber(data.revenue or 0)
    end
    
    if uiElements.levelValue then
        uiElements.levelValue.Text = tostring(data.level or 1)
    end
    
    if uiElements.equipmentValue then
        uiElements.equipmentValue.Text = tostring(data.equipment or 0)
    end
    
    if uiElements.rebirthLevelValue then
        uiElements.rebirthLevelValue.Text = tostring(data.rebirthLevel or 0)
    end
    
    -- Update history table
    if uiElements.historyTable and data.history then
        -- Clear existing rows
        for _, child in pairs(uiElements.historyTable:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Add new rows
        for i, entry in ipairs(data.history) do
            -- Create row
            local row = Instance.new("Frame")
            row.Name = "HistoryRow" .. i
            row.Size = UDim2.new(1, 0, 0, 30)
            row.BackgroundColor3 = i % 2 == 0 and UIStyle.Colors.Secondary or Color3.fromRGB(40, 40, 40)
            row.BorderSizePixel = 0
            row.Parent = uiElements.historyTable
            
            -- Add columns
            local columns = {
                { value = tostring(i), width = 0.1 },
                { value = entry.date or "", width = 0.25 },
                { value = tostring(entry.level or ""), width = 0.15 },
                { value = "$" .. formatNumber(entry.revenue or 0), width = 0.25 },
                { value = tostring(entry.equipment or 0), width = 0.25 }
            }
            
            for j, column in ipairs(columns) do
                local cell = Instance.new("TextLabel")
                cell.Size = UDim2.new(column.width, 0, 1, 0)
                cell.Position = UDim2.new(j == 1 and 0 or columns[j-1].width + (columns[j-2] and columns[j-2].width or 0), 0, 0, 0)
                cell.BackgroundTransparency = 1
                cell.Text = column.value
                cell.Font = UIStyle.Fonts.Regular
                cell.TextSize = 14
                cell.TextColor3 = UIStyle.Colors.Text
                cell.Parent = row
            end
        end
        
        -- Update canvas size
        uiElements.historyTable.CanvasSize = UDim2.new(0, 0, 0, #data.history * 32) -- Height per row + padding
    end
}

--[[ Public API Functions ]]--

-- Switch active tab
function RebirthUI:switchTab(tabName)
    if not uiElements.tabs or not uiElements.tabs.buttons[tabName] or not uiElements.tabs.contents[tabName] then
        return
    end
    
    -- Update tab button colors
    for name, button in pairs(uiElements.tabs.buttons) do
        button.BackgroundColor3 = name == tabName and UIStyle.Colors.Primary or UIStyle.Colors.Secondary
    end
    
    -- Show/hide tab contents
    for name, content in pairs(uiElements.tabs.contents) do
        content.Visible = name == tabName
    end
    
    uiElements.activeTab = tabName
end

-- Initialize the UI
function RebirthUI:initialize()
    -- Create base UI if not already created
    if not uiElements.mainFrame then
        createMainUI()
    end
    
    if not uiElements.tabs or not next(uiElements.tabs) then
        createTabs()
    end
    
    -- Register with UIRegistry if available
    if UIRegistry and UIRegistry.registerComponent then
        UIRegistry:registerComponent("RebirthUI", self)
    end
    
    -- Register with UIManager if available
    if UIManager and UIManager.registerUI then
        UIManager:registerUI("RebirthUI", self)
    end
    
    -- Get initial data
    self:updateRebirthInfo()
    
    return self
end

-- Show the UI
function RebirthUI:show()
    if not uiElements.mainFrame then
        self:initialize()
    end
    
    -- Update data before showing
    self:updateRebirthInfo()
    
    -- Show the main frame with animation
    uiElements.mainFrame.Visible = true
    uiElements.mainFrame.BackgroundTransparency = 1
    uiElements.mainFrame.Position = UDim2.new(0.5, -CONFIG.mainFrameSize.X.Offset / 2, 0.6, -CONFIG.mainFrameSize.Y.Offset / 2)
    
    -- Create and play entrance animation
    local positionTween = TweenService:Create(
        uiElements.mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, -CONFIG.mainFrameSize.X.Offset / 2, 0.5, -CONFIG.mainFrameSize.Y.Offset / 2) }
    )
    
    local transparencyTween = TweenService:Create(
        uiElements.mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0 }
    )
    
    positionTween:Play()
    transparencyTween:Play()
    
    return true
end

-- Hide the UI
function RebirthUI:hide()
    if not uiElements.mainFrame then
        return false
    end
    
    -- Create and play exit animation
    local positionTween = TweenService:Create(
        uiElements.mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(0.5, -CONFIG.mainFrameSize.X.Offset / 2, 0.6, -CONFIG.mainFrameSize.Y.Offset / 2) }
    )
    
    local transparencyTween = TweenService:Create(
        uiElements.mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { BackgroundTransparency = 1 }
    )
    
    -- Hide after animation completes
    transparencyTween.Completed:Connect(function()
        uiElements.mainFrame.Visible = false
    end)
    
    positionTween:Play()
    transparencyTween:Play()
    
    return true
end

-- Initialize on module load
RebirthUI:initialize()

-- Return the module
return RebirthUI
