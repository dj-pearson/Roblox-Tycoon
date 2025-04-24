--!strict
--[[
    RebirthUI.client.luau
    Enhanced client-side UI for the rebirth system with unlockable content progression
    
    Uses modern UI framework components:
    - UIStyle for consistent styling
    - ButtonFactory for standardized buttons
    - DialogFactory for notifications and popups
    - IconSet for consistent iconography
    
    Updated: April 24, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Import modern UI framework components
local UIStyle = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UIStyle"))
local ButtonFactory = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("ButtonFactory"))
local DialogFactory = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("DialogFactory"))
local IconSet = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("IconSet"))

-- Wait for the remote event
local RebirthRemote = ReplicatedStorage:WaitForChild("RebirthRemote")

-- Module and state variables
local RebirthUI = {}
local rebirthUIElements = {
    -- Will store UI elements for access throughout the module
}

-- Color configurations and UI constants integrated with UIStyle
local CONFIG = {
    animationDuration = 0.3,
    tabCount = 4,
    toggleButtonSize = UDim2.new(0, 120, 0, 40),
}

-- Forward declarations of functions we'll define later
local createFeatureCard, createPerkCard, createAchievementCard
local updateRebirthInfo, showNotification, formatNumber

-- Create the main UI structure
local function createRebirthUI()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RebirthUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create main frame with UIStyle
    local mainFrame = UIStyle.createFrame({
        name = "RebirthFrame",
        size = UDim2.new(0, 500, 0, 400),
        position = UDim2.new(0.5, -250, 0.5, -200),
        color = UIStyle.Colors.Background,
        cornerRadius = UDim.new(0, 10),
        transparency = 0.1,
        zIndex = UIStyle.ZIndex.Standard
    })
    mainFrame.Parent = screenGui
    
    -- Add title using UIStyle
    local titleLabel = UIStyle.createText({
        name = "TitleLabel",
        size = UDim2.new(1, 0, 0, 40),
        position = UDim2.new(0, 0, 0, 0),
        text = "Rebirth System",
        font = UIStyle.Fonts.Title,
        textSize = 24,
        textColor = UIStyle.Colors.Text,
        zIndex = UIStyle.ZIndex.Standard + 1
    })
    titleLabel.Parent = mainFrame
    
    -- Add Rebirth icon from IconSet
    local titleIcon = IconSet.createIcon("Rebirth", UDim2.new(0, 30, 0, 30))
    titleIcon.Position = UDim2.new(0, 10, 0, 5)
    titleIcon.Parent = mainFrame
    
    -- Shift title text to accommodate icon
    titleLabel.Position = UDim2.new(0, 45, 0, 0)
    
    -- Add description
    local descLabel = UIStyle.createText({
        name = "DescriptionLabel",
        size = UDim2.new(1, -20, 0, 40),
        position = UDim2.new(0, 10, 0, 40),
        text = "Reset your progress to gain permanent bonuses and unlock new features!",
        font = UIStyle.Fonts.Body,
        textSize = 14,
        textColor = UIStyle.Colors.TextSecondary,
        textWrapped = true,
        textXAlignment = Enum.TextXAlignment.Center,
        zIndex = UIStyle.ZIndex.Standard
    })
    descLabel.Parent = mainFrame
    
    -- Create tab container
    local tabsContainer = UIStyle.createFrame({
        name = "TabsContainer",
        size = UDim2.new(1, -20, 0, 40),
        position = UDim2.new(0, 10, 0, 90),
        transparency = 1,
        zIndex = UIStyle.ZIndex.Standard
    })
    tabsContainer.Parent = mainFrame
    
    -- Create tab buttons using ButtonFactory
    local tabButtons = {}
    local tabNames = {"Main", "Features", "Perks", "Achievements"}
    
    for i, tabName in ipairs(tabNames) do
        local position = i - 1
        local tabButton = ButtonFactory.createTabButton({
            name = tabName .. "TabButton",
            size = UDim2.new(0.25, -10, 1, 0),
            position = UDim2.new(0.25 * position, position > 0 and 5 or 0, 0, 0),
            text = tabName,
            selected = (i == 1), -- Main tab selected by default
            cornerRadius = UDim.new(0, 8),
            zIndex = UIStyle.ZIndex.Standard + 1
        })
        tabButton.Parent = tabsContainer
        tabButtons[tabName] = tabButton
    end
    
    -- Content container for tab content
    local contentContainer = UIStyle.createFrame({
        name = "ContentContainer",
        size = UDim2.new(1, -20, 0, 220),
        position = UDim2.new(0, 10, 0, 140),
        color = UIStyle.Colors.Secondary,
        cornerRadius = UDim.new(0, 8),
        zIndex = UIStyle.ZIndex.Standard
    })
    contentContainer.Parent = mainFrame
    
    -- Create content for each tab
    -- 1. Main tab content
    local mainTabContent = UIStyle.createFrame({
        name = "MainTabContent",
        size = UDim2.new(1, 0, 1, 0),
        transparency = 1,
        zIndex = UIStyle.ZIndex.Standard + 1
    })
    mainTabContent.Parent = contentContainer
    
    -- Cost label
    local costLabel = UIStyle.createText({
        name = "CostLabel",
        size = UDim2.new(1, -20, 0, 25),
        position = UDim2.new(0, 10, 0, 20),
        text = "Cost: $100,000",
        font = UIStyle.Fonts.Bold,
        textSize = 18,
        textColor = UIStyle.Colors.Accent,
        zIndex = UIStyle.ZIndex.Standard + 1
    })
    costLabel.Parent = mainTabContent
    
    -- Add money icon from IconSet
    local moneyIcon = IconSet.createIcon("Cash", UDim2.new(0, 20, 0, 20))
    moneyIcon.Position = UDim2.new(0, 10, 0, 22)
    moneyIcon.Parent = mainTabContent
    
    -- Shift cost label to accommodate icon
    costLabel.Position = UDim2.new(0, 35, 0, 20)
    
    -- Current rebirth count
    local rebirthCountLabel = UIStyle.createText({
        name = "RebirthCountLabel",
        size = UDim2.new(1, -20, 0, 25),
        position = UDim2.new(0, 10, 0, 50),
        text = "Your Rebirth Level: 0",
        font = UIStyle.Fonts.Body,
        textSize = 16,
        textColor = Color3.fromRGB(100, 255, 100), -- Success color
        zIndex = UIStyle.ZIndex.Standard + 1
    })
    rebirthCountLabel.Parent = mainTabContent
    
    -- Rebirth multiplier
    local multiplierLabel = UIStyle.createText({
        name = "MultiplierLabel",
        size = UDim2.new(1, -20, 0, 25),
        position = UDim2.new(0, 10, 0, 80),
        text = "Revenue Multiplier: 0%",
        font = UIStyle.Fonts.Body,
        textSize = 16,
        textColor = Color3.fromRGB(100, 255, 255), -- Info color
        zIndex = UIStyle.ZIndex.Standard + 1
    })
    multiplierLabel.Parent = mainTabContent
    
    -- Progress bar container using UIStyle
    local progressBarContainer = UIStyle.createFrame({
        name = "ProgressBarContainer",
        size = UDim2.new(1, -20, 0, 20),
        position = UDim2.new(0, 10, 0, 115),
        color = UIStyle.Colors.Background,
        cornerRadius = UDim.new(0, 4),
        zIndex = UIStyle.ZIndex.Standard + 1
    })
    progressBarContainer.Parent = mainTabContent
    
    -- Progress bar fill
    local progressBarFill = UIStyle.createFrame({
        name = "ProgressBarFill",
        size = UDim2.new(0, 0, 1, 0),
        color = UIStyle.Colors.Accent,
        cornerRadius = UDim.new(0, 4),
        zIndex = UIStyle.ZIndex.Standard + 2
    })
    progressBarFill.Parent = progressBarContainer
    
    -- Progress label
    local progressLabel = UIStyle.createText({
        name = "ProgressLabel",
        size = UDim2.new(1, -20, 0, 20),
        position = UDim2.new(0, 10, 0, 140),
        text = "Progress: 0%",
        font = UIStyle.Fonts.Body,
        textSize = 14,
        textColor = UIStyle.Colors.Text,
        zIndex = UIStyle.ZIndex.Standard + 1
    })
    progressLabel.Parent = mainTabContent
    
    -- Next unlock info
    local nextUnlockLabel = UIStyle.createText({
        name = "NextUnlockLabel",
        size = UDim2.new(1, -20, 0, 40),
        position = UDim2.new(0, 10, 0, 165),
        text = "Next Unlock: None",
        font = UIStyle.Fonts.Body,
        textSize = 14,
        textColor = UIStyle.Colors.Warning,
        textWrapped = true,
        zIndex = UIStyle.ZIndex.Standard + 1
    })
    nextUnlockLabel.Parent = mainTabContent
    
    -- 2. Features tab content with scroll frame
    local featuresTabContent = createScrollingTabContent("Features", contentContainer)
    featuresTabContent.Visible = false
    
    -- 3. Perks tab content with scroll frame
    local perksTabContent = createScrollingTabContent("Perks", contentContainer)
    perksTabContent.Visible = false
    
    -- 4. Achievements tab content with scroll frame
    local achievementsTabContent = createScrollingTabContent("Achievements", contentContainer)
    achievementsTabContent.Visible = false
    
    -- Add rebirth button using ButtonFactory
    local rebirthButton = ButtonFactory.createActionButton({
        name = "RebirthButton",
        size = UDim2.new(0, 200, 0, 50),
        position = UDim2.new(0.5, -100, 1, -70),
        text = "REBIRTH NOW",
        icon = IconSet.getIconId("Rebirth"),
        color = UIStyle.Colors.Primary,
        hoverColor = UIStyle.Colors.PrimaryHover,
        textSize = 18,
        cornerRadius = UDim.new(0, 8),
        zIndex = UIStyle.ZIndex.Standard + 2
    })
    rebirthButton.Parent = mainFrame
    
    -- Add close button using ButtonFactory with standard template
    local closeButton = ButtonFactory.createCloseButton()
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.Parent = mainFrame
    
    -- Stats section at the bottom
    local statsContainer = UIStyle.createFrame({
        name = "StatsContainer",
        size = UDim2.new(1, -20, 0, 30),
        position = UDim2.new(0, 10, 1, -30),
        transparency = 1,
        zIndex = UIStyle.ZIndex.Standard
    })
    statsContainer.Parent = mainFrame
    
    -- Total rebirths
    local totalRebirthsLabel = UIStyle.createText({
        name = "TotalRebirthsLabel",
        size = UDim2.new(0.5, -10, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        text = "Total Rebirths: 0",
        font = UIStyle.Fonts.Body,
        textSize = 12,
        textColor = UIStyle.Colors.TextSecondary,
        textXAlignment = Enum.TextXAlignment.Left,
        zIndex = UIStyle.ZIndex.Standard
    })
    totalRebirthsLabel.Parent = statsContainer
    
    -- Fastest rebirth
    local fastestRebirthLabel = UIStyle.createText({
        name = "FastestRebirthLabel",
        size = UDim2.new(0.5, -10, 1, 0),
        position = UDim2.new(0.5, 10, 0, 0),
        text = "Fastest Rebirth: None",
        font = UIStyle.Fonts.Body,
        textSize = 12,
        textColor = UIStyle.Colors.TextSecondary,
        textXAlignment = Enum.TextXAlignment.Left,
        zIndex = UIStyle.ZIndex.Standard
    })
    fastestRebirthLabel.Parent = statsContainer
    
    -- Toggle button using ButtonFactory
    local toggleButton = ButtonFactory.createActionButton({
        name = "RebirthToggleButton",
        size = CONFIG.toggleButtonSize,
        position = UDim2.new(1, -130, 0, 10),
        anchorPoint = Vector2.new(1, 0),
        text = "Rebirth",
        icon = IconSet.getIconId("Rebirth"),
        color = UIStyle.Colors.Secondary,
        hoverColor = UIStyle.Colors.SecondaryHover,
        textSize = 16,
        cornerRadius = UDim.new(0, 8),
        zIndex = UIStyle.ZIndex.Float
    })
    toggleButton.Parent = screenGui
    
    -- Initially hide the main frame
    mainFrame.Visible = false
    
    -- Store UI elements for access throughout the module
    rebirthUIElements = {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        CostLabel = costLabel,
        RebirthCountLabel = rebirthCountLabel,
        MultiplierLabel = multiplierLabel,
        ProgressBarFill = progressBarFill,
        ProgressLabel = progressLabel,
        NextUnlockLabel = nextUnlockLabel,
        TabButtons = tabButtons,
        TabContents = {
            Main = mainTabContent,
            Features = featuresTabContent,
            Perks = perksTabContent,
            Achievements = achievementsTabContent
        },
        ScrollFrames = {
            Features = featuresTabContent.ChildrenContents.ScrollFrame,
            Perks = perksTabContent.ChildrenContents.ScrollFrame,
            Achievements = achievementsTabContent.ChildrenContents.ScrollFrame
        },
        RebirthButton = rebirthButton,
        TotalRebirthsLabel = totalRebirthsLabel,
        FastestRebirthLabel = fastestRebirthLabel,
        ToggleButton = toggleButton
    }
    
    return screenGui
end

-- Helper function to create scrolling tab content
function createScrollingTabContent(name, parent)
    local tabContent = UIStyle.createFrame({
        name = name .. "TabContent",
        size = UDim2.new(1, 0, 1, 0),
        transparency = 1,
        zIndex = UIStyle.ZIndex.Standard + 1
    })
    
    local scrollFrame = UIStyle.createScrollingFrame({
        name = name .. "ScrollFrame",
        size = UDim2.new(1, -20, 1, -20),
        position = UDim2.new(0, 10, 0, 10),
        canvasSize = UDim2.new(0, 0, 0, 0),
        zIndex = UIStyle.ZIndex.Standard + 1
    })
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame
    
    scrollFrame.Parent = tabContent
    tabContent.Parent = parent
    
    -- Store references to child elements for easy access
    tabContent.ChildrenContents = {
        ScrollFrame = scrollFrame,
        ListLayout = listLayout
    }
    
    return tabContent
end

-- Function to create a feature card using UIStyle
function createFeatureCard(feature)
    local isModelFeature = feature.info.model ~= nil
    local cardColor = isModelFeature and Color3.fromRGB(80, 50, 100) or UIStyle.Colors.CardBackground
    
    local featureCard = UIStyle.createCard({
        name = "FeatureCard_" .. feature.level,
        size = UDim2.new(1, -20, 0, 80),
        color = cardColor,
        cornerRadius = UDim.new(0, 8),
    })
    
    -- Feature icon from IconSet or use provided icon
    local iconId = feature.info.icon
    local icon
    
    if iconId then
        -- Try to use IconSet first if it's a standard icon
        local standardIcon = IconSet.hasIcon(iconId) and IconSet.createIcon(iconId, UDim2.new(0, 50, 0, 50)) or nil
        
        -- If not a standard icon, use the provided icon
        if not standardIcon then
            icon = Instance.new("ImageLabel")
            icon.Name = "FeatureIcon"
            icon.Size = UDim2.new(0, 50, 0, 50)
            icon.Position = UDim2.new(0, 10, 0, 15)
            icon.BackgroundTransparency = 1
            icon.Image = iconId
        else
            icon = standardIcon
            icon.Position = UDim2.new(0, 10, 0, 15)
        end
        icon.Parent = featureCard
    end
    
    -- Feature name
    local nameLabel = UIStyle.createText({
        name = "FeatureName",
        size = UDim2.new(1, -80, 0, 25),
        position = UDim2.new(0, 70, 0, 10),
        text = feature.info.name,
        font = UIStyle.Fonts.Bold,
        textSize = 16,
        textColor = UIStyle.Colors.Text,
        textXAlignment = Enum.TextXAlignment.Left
    })
    nameLabel.Parent = featureCard
    
    -- Feature description
    local descLabel = UIStyle.createText({
        name = "FeatureDesc",
        size = UDim2.new(1, -80, 0, 40),
        position = UDim2.new(0, 70, 0, 35),
        text = feature.info.description,
        font = UIStyle.Fonts.Body,
        textSize = 12,
        textColor = UIStyle.Colors.TextSecondary,
        textWrapped = true,
        textXAlignment = Enum.TextXAlignment.Left
    })
    descLabel.Parent = featureCard
    
    -- Level indicator with UIStyle pill badge
    local levelLabel = UIStyle.createBadge({
        name = "LevelLabel",
        size = UDim2.new(0, 50, 0, 20),
        position = UDim2.new(1, -60, 0, 10),
        text = "Lvl " .. feature.level,
        color = UIStyle.Colors.Info,
        textSize = 12,
    })
    levelLabel.Parent = featureCard
    
    return featureCard
end

-- Function to create a perk card using UIStyle
function createPerkCard(perk)
    local perkCard = UIStyle.createCard({
        name = "PerkCard_" .. perk.id,
        size = UDim2.new(1, -20, 0, 80),
        color = UIStyle.Colors.CardBackground,
        cornerRadius = UDim.new(0, 8),
    })
    
    -- Perk icon
    local iconId = perk.info.icon
    local icon
    
    if iconId then
        -- Try to use IconSet first if it's a standard icon
        local standardIcon = IconSet.hasIcon(iconId) and IconSet.createIcon(iconId, UDim2.new(0, 50, 0, 50)) or nil
        
        -- If not a standard icon, use the provided icon
        if not standardIcon then
            icon = Instance.new("ImageLabel")
            icon.Name = "PerkIcon"
            icon.Size = UDim2.new(0, 50, 0, 50)
            icon.Position = UDim2.new(0, 10, 0, 15)
            icon.BackgroundTransparency = 1
            icon.Image = iconId
        else
            icon = standardIcon
            icon.Position = UDim2.new(0, 10, 0, 15)
        end
        icon.Parent = perkCard
    end
    
    -- Perk name
    local nameLabel = UIStyle.createText({
        name = "PerkName",
        size = UDim2.new(1, -80, 0, 25),
        position = UDim2.new(0, 70, 0, 10),
        text = perk.info.name,
        font = UIStyle.Fonts.Bold,
        textSize = 16,
        textColor = UIStyle.Colors.Text,
        textXAlignment = Enum.TextXAlignment.Left
    })
    nameLabel.Parent = perkCard
    
    -- Perk description
    local descLabel = UIStyle.createText({
        name = "PerkDesc",
        size = UDim2.new(1, -80, 0, 40),
        position = UDim2.new(0, 70, 0, 35),
        text = perk.info.description,
        font = UIStyle.Fonts.Body,
        textSize = 12,
        textColor = UIStyle.Colors.TextSecondary,
        textWrapped = true,
        textXAlignment = Enum.TextXAlignment.Left
    })
    descLabel.Parent = perkCard
    
    -- Perk value indicator with UIStyle pill badge
    if perk.value then
        local valueText = type(perk.value) == "number" 
            and (perk.value > 1 and ("+" .. (perk.value * 100 - 100) .. "%") or ("+" .. perk.value * 100 .. "%"))
            or tostring(perk.value)
            
        local valueLabel = UIStyle.createBadge({
            name = "ValueLabel",
            size = UDim2.new(0, 60, 0, 20),
            position = UDim2.new(1, -70, 0, 10),
            text = valueText,
            color = UIStyle.Colors.Success,
            textSize = 12,
        })
        valueLabel.Parent = perkCard
    end
    
    return perkCard
end

-- Function to create an achievement card using UIStyle
function createAchievementCard(achievement)
    local isComplete = achievement.completed or false
    local cardColor = isComplete and UIStyle.Colors.Success or UIStyle.Colors.CardBackground
    cardColor = UIStyle.adjustColorBrightness(cardColor, isComplete and -0.3 or 0)
    
    local achievementCard = UIStyle.createCard({
        name = "AchievementCard_" .. achievement.id,
        size = UDim2.new(1, -20, 0, 80),
        color = cardColor,
        cornerRadius = UDim.new(0, 8),
    })
    
    -- Achievement icon from IconSet or use provided icon
    local iconId = achievement.icon
    local icon
    
    if iconId then
        -- Try to use IconSet first if it's a standard icon
        local standardIcon = IconSet.hasIcon(iconId) and IconSet.createIcon(iconId, UDim2.new(0, 50, 0, 50)) or nil
        
        -- If not a standard icon, use the provided icon
        if not standardIcon then
            icon = Instance.new("ImageLabel")
            icon.Name = "AchievementIcon"
            icon.Size = UDim2.new(0, 50, 0, 50)
            icon.Position = UDim2.new(0, 10, 0, 15)
            icon.BackgroundTransparency = 1
            icon.Image = iconId
        else
            icon = standardIcon
            icon.Position = UDim2.new(0, 10, 0, 15)
        end
        icon.Parent = achievementCard
    end
    
    -- Achievement name
    local nameLabel = UIStyle.createText({
        name = "AchievementName",
        size = UDim2.new(1, -80, 0, 25),
        position = UDim2.new(0, 70, 0, 10),
        text = achievement.name,
        font = UIStyle.Fonts.Bold,
        textSize = 16,
        textColor = isComplete and UIStyle.Colors.Text or UIStyle.Colors.TextSecondary,
        textXAlignment = Enum.TextXAlignment.Left
    })
    nameLabel.Parent = achievementCard
    
    -- Achievement description
    local descLabel = UIStyle.createText({
        name = "AchievementDesc",
        size = UDim2.new(1, -80, 0, 40),
        position = UDim2.new(0, 70, 0, 35),
        text = achievement.description,
        font = UIStyle.Fonts.Body,
        textSize = 12,
        textColor = UIStyle.Colors.TextSecondary,
        textWrapped = true,
        textXAlignment = Enum.TextXAlignment.Left
    })
    descLabel.Parent = achievementCard
    
    -- Completion status
    local statusLabel = UIStyle.createBadge({
        name = "StatusLabel",
        size = UDim2.new(0, 70, 0, 20),
        position = UDim2.new(1, -80, 0, 10),
        text = isComplete and "COMPLETED" or "LOCKED",
        color = isComplete and UIStyle.Colors.Success or UIStyle.Colors.Warning,
        textSize = 10,
    })
    statusLabel.Parent = achievementCard
    
    -- Progress info if not completed
    if not isComplete and achievement.progress and achievement.requirement then
        local progressBar = UIStyle.createProgressBar({
            name = "ProgressBar",
            size = UDim2.new(0, 60, 0, 8),
            position = UDim2.new(1, -70, 0, 35),
            progress = achievement.progress / achievement.requirement,
        })
        progressBar.Parent = achievementCard
        
        local progressText = UIStyle.createText({
            name = "ProgressText",
            size = UDim2.new(0, 60, 0, 12),
            position = UDim2.new(1, -70, 0, 45),
            text = achievement.progress .. "/" .. achievement.requirement,
            font = UIStyle.Fonts.Small,
            textSize = 10,
            textColor = UIStyle.Colors.TextSecondary,
            textXAlignment = Enum.TextXAlignment.Right,
        })
        progressText.Parent = achievementCard
    end
    
    return achievementCard
end

-- Function to switch between tabs
local function switchToTab(tabName)
    -- Hide all tab contents
    for name, content in pairs(rebirthUIElements.TabContents) do
        content.Visible = (name == tabName)
    end
    
    -- Reset all tab button colors
    for name, button in pairs(rebirthUIElements.TabButtons) do
        if name == tabName then
            ButtonFactory.setTabActive(button, true)
        else
            ButtonFactory.setTabActive(button, false)
        end
    end
end

-- Function to update the rebirth info with data from server
function updateRebirthInfo()
    -- Request rebirth info from server
    RebirthRemote:FireServer("GetInfo")
end

-- Format numbers with commas
function formatNumber(number)
    if not number then return "0" end
    
    local formatted = tostring(number)
    local result = ""
    local length = formatted:len()
    
    for i = 1, length do
        result = result .. formatted:sub(i, i)
        if (length - i) % 3 == 0 and (length - i) > 0 then
            result = result .. ","
        end
    end
    
    return result
end

-- Show notification using DialogFactory
function showNotification(messageType, data)
    if messageType == "Success" then
        -- Show success message with DialogFactory
        DialogFactory.showNotification({
            title = "Rebirth Successful!",
            message = "New Multiplier: " .. string.format("%.1f", data.newMultiplier * 100) .. "%",
            type = "success",
            duration = 3
        })
        
        -- Request updated info
        RebirthRemote:FireServer("GetInfo")
        
    elseif messageType == "NotEnoughCash" then
        -- Show error message with DialogFactory
        DialogFactory.showNotification({
            title = "Not Enough Cash",
            message = "You need $" .. formatNumber(data.required),
            type = "error",
            duration = 3
        })
        
    elseif messageType == "RebirthInfo" then
        -- Update all UI elements with the rebirth data
        if rebirthUIElements.CostLabel then
            rebirthUIElements.CostLabel.Text = "Cost: $" .. formatNumber(data.cost)
        end
        
        if rebirthUIElements.RebirthCountLabel then
            rebirthUIElements.RebirthCountLabel.Text = "Your Rebirth Level: " .. (data.rebirthCount or 0)
        end
        
        if rebirthUIElements.MultiplierLabel then
            rebirthUIElements.MultiplierLabel.Text = "Revenue Multiplier: " .. string.format("%.1f", (data.multiplier or 0) * 100) .. "%"
        end
        
        -- Update progress bar
        local progress = data.progress or 0
        TweenService:Create(rebirthUIElements.ProgressBarFill, TweenInfo.new(0.5), {
            Size = UDim2.new(progress, 0, 1, 0)
        }):Play()
        
        if rebirthUIElements.ProgressLabel then
            rebirthUIElements.ProgressLabel.Text = "Progress: " .. string.format("%.1f", progress * 100) .. "%"
        end
        
        -- Update next unlock info
        if data.nextFeature then
            rebirthUIElements.NextUnlockLabel.Text = "Next Feature: " .. data.nextFeature.name .. " (Level " .. (data.rebirthCount + 1) .. ")"
        elseif data.nextPerk then
            rebirthUIElements.NextUnlockLabel.Text = "Next Perk: " .. data.nextPerk.name .. " (Level " .. (data.rebirthCount + 1) .. ")"
        else
            rebirthUIElements.NextUnlockLabel.Text = "All content unlocked!"
        end
        
        -- Update stats
        if rebirthUIElements.TotalRebirthsLabel then
            rebirthUIElements.TotalRebirthsLabel.Text = "Total Rebirths: " .. (data.totalRebirths or 0)
        end
        
        if rebirthUIElements.FastestRebirthLabel then
            local fastestTime = data.fastestRebirthTime
            rebirthUIElements.FastestRebirthLabel.Text = "Fastest Rebirth: " .. (fastestTime and string.format("%d:%02d:%02d", 
                math.floor(fastestTime/3600), 
                math.floor((fastestTime%3600)/60), 
                math.floor(fastestTime%60)) 
            or "None")
        end
        
        -- Clear existing feature cards
        if rebirthUIElements.ScrollFrames.Features then
            for _, child in ipairs(rebirthUIElements.ScrollFrames.Features:GetChildren()) do
                if child:IsA("Frame") and string.match(child.Name, "FeatureCard_") then
                    child:Destroy()
                end
            end
        end
        
        -- Add feature cards
        if data.features and rebirthUIElements.ScrollFrames.Features then
            local layoutOrder = 1
            for _, feature in pairs(data.features) do
                local featureCard = createFeatureCard(feature)
                featureCard.LayoutOrder = layoutOrder
                featureCard.Parent = rebirthUIElements.ScrollFrames.Features
                layoutOrder = layoutOrder + 1
            end
            
            -- Update canvas size
            rebirthUIElements.ScrollFrames.Features.CanvasSize = UDim2.new(0, 0, 0, layoutOrder * 90)
        end
        
        -- Clear existing perk cards
        if rebirthUIElements.ScrollFrames.Perks then
            for _, child in ipairs(rebirthUIElements.ScrollFrames.Perks:GetChildren()) do
                if child:IsA("Frame") and string.match(child.Name, "PerkCard_") then
                    child:Destroy()
                end
            end
        end
        
        -- Add perk cards
        if data.perks and rebirthUIElements.ScrollFrames.Perks then
            local layoutOrder = 1
            for _, perk in pairs(data.perks) do
                local perkCard = createPerkCard(perk)
                perkCard.LayoutOrder = layoutOrder
                perkCard.Parent = rebirthUIElements.ScrollFrames.Perks
                layoutOrder = layoutOrder + 1
            end
            
            -- Update canvas size
            rebirthUIElements.ScrollFrames.Perks.CanvasSize = UDim2.new(0, 0, 0, layoutOrder * 90)
        end
        
        -- Clear existing achievement cards
        if rebirthUIElements.ScrollFrames.Achievements then
            for _, child in ipairs(rebirthUIElements.ScrollFrames.Achievements:GetChildren()) do
                if child:IsA("Frame") and string.match(child.Name, "AchievementCard_") then
                    child:Destroy()
                end
            end
        end
        
        -- Add achievement cards
        if data.achievements and rebirthUIElements.ScrollFrames.Achievements then
            local layoutOrder = 1
            for _, achievement in pairs(data.achievements) do
                local achievementCard = createAchievementCard(achievement)
                achievementCard.LayoutOrder = layoutOrder
                achievementCard.Parent = rebirthUIElements.ScrollFrames.Achievements
                layoutOrder = layoutOrder + 1
            end
            
            -- Update canvas size
            rebirthUIElements.ScrollFrames.Achievements.CanvasSize = UDim2.new(0, 0, 0, layoutOrder * 90)
        end
    end
end

-- Handle remote events from server
RebirthRemote.OnClientEvent:Connect(function(messageType, data)
    showNotification(messageType, data)
end)

-- Initialize the UI
local function initialize()
    local screenGui = createRebirthUI()
    screenGui.Parent = PlayerGui
    
    -- Connect tab button clicks
    for tabName, button in pairs(rebirthUIElements.TabButtons) do
        button.MouseButton1Click:Connect(function()
            switchToTab(tabName)
        end)
    end
    
    -- Connect toggle button click
    rebirthUIElements.ToggleButton.MouseButton1Click:Connect(function()
        rebirthUIElements.MainFrame.Visible = not rebirthUIElements.MainFrame.Visible
        
        -- Animate the opening/closing using UIStyle animations
        if rebirthUIElements.MainFrame.Visible then
            -- Pop-in animation
            rebirthUIElements.MainFrame.Size = UDim2.new(0, 480, 0, 380)
            rebirthUIElements.MainFrame.BackgroundTransparency = 0.5
            
            TweenService:Create(rebirthUIElements.MainFrame, UIStyle.Animations.PopIn, {
                Size = UDim2.new(0, 500, 0, 400),
                BackgroundTransparency = 0.1
            }):Play()
            
            -- Update the rebirth info
            updateRebirthInfo()
        end
    end)
    
    -- Connect close button
    rebirthUIElements.MainFrame.CloseButton.MouseButton1Click:Connect(function()
        rebirthUIElements.MainFrame.Visible = false
    end)
    
    -- Connect rebirth button
    rebirthUIElements.RebirthButton.MouseButton1Click:Connect(function()
        -- Disable the button temporarily
        ButtonFactory.setButtonState(rebirthUIElements.RebirthButton, "disabled")
        rebirthUIElements.RebirthButton.Text = "Processing..."
        
        -- Send rebirth request to server
        RebirthRemote:FireServer("Rebirth")
        
        -- Re-enable button after a delay
        task.delay(2, function()
            ButtonFactory.setButtonState(rebirthUIElements.RebirthButton, "default")
            rebirthUIElements.RebirthButton.Text = "REBIRTH NOW"
        end)
    end)
    
    -- Default to the Main tab
    switchToTab("Main")
    
    -- Request initial rebirth info
    task.delay(0.5, function()
        updateRebirthInfo()
    end)
    
    return rebirthUIElements
end

-- Public API
RebirthUI = {
    initialize = initialize,
    updateRebirthInfo = updateRebirthInfo,
    showNotification = showNotification
}

-- Auto-initialize
initialize()

return RebirthUI
