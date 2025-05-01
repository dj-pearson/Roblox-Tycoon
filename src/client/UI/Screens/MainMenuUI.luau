--!strict
--[[
    MainMenuUI.luau
    
    Consolidated main menu interface that provides access to all major game features.
    Creates a visually appealing menu with animation transitions and responsive layout.
    
    Features:
    - Category-based navigation
    - Quick access shortcuts
    - Status indicators
    - Notification integration
    
    Author: Updated April 26, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
-- Not using UserInputService in this module yet
-- local UserInputService = game:GetService("UserInputService")

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
-- Commenting out unused variable:
-- local clientCoreFolder = clientFolder and clientFolder:FindFirstChild("Core")
local uiCoreFolder = clientUIFolder and clientUIFolder:FindFirstChild("Core")

-- Required modules
local UIStyle = requireSafely(sharedFolder:FindFirstChild("UIStyle"))
local ButtonFactory = requireSafely(sharedFolder:FindFirstChild("ButtonFactory")) 
local DialogFactory = requireSafely(sharedFolder:FindFirstChild("DialogFactory"))
local UIManager = requireSafely(uiCoreFolder and uiCoreFolder:FindFirstChild("UIManager"))
local UIRegistry = requireSafely(uiCoreFolder and uiCoreFolder:FindFirstChild("UIRegistry"))
-- Not using ClientRegistry in this module yet, but might need it later
-- local ClientRegistry = requireSafely(clientCoreFolder and clientCoreFolder:FindFirstChild("ClientRegistry"))

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
        }
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
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = button
            
            if properties.callback then
                button.Activated:Connect(properties.callback)
            end
            
            return button
        end
    }
end

-- Module and state variables
local MainMenuUI = {}
local uiElements = {
    mainFrame = nil,
    categories = {},
    currentCategory = nil,
    menuButtons = {},
    statusElements = {}
}

-- Forward declarations for functions to prevent "not defined" errors
local createStatusIndicators
local populateCategoryContent
local createGymContent
local createEquipmentContent
local createStaffContent
local createMembersContent
local createResearchContent
local createStatisticsContent
local createShopContent
local createSettingsContent

-- Configuration
local CONFIG = {
    mainFrameSize = UDim2.new(0, 800, 0, 500),
    sidebarWidth = 200,
    headerHeight = 60,
    categories = {
        "Gym", "Equipment", "Staff", "Members", "Research", "Statistics", "Shop", "Settings"
    },
    buttonHeight = 50,
    statusUpdateInterval = 5, -- Seconds between status updates
    animationDuration = 0.3
}

--[[ UI Creation Functions ]]--

-- Create the main UI
local function createMainUI()
    -- Create or find the ScreenGui
    local screenGui = PlayerGui:FindFirstChild("MainMenuUI")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "MainMenuUI"
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
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Create header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, CONFIG.headerHeight)
    header.BackgroundColor3 = UIStyle.Colors.Primary
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    -- Add corner radius to header (top corners only)
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    -- Add header title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Gym Tycoon"
    title.Font = UIStyle.Fonts.Bold
    title.TextSize = 24
    title.TextColor3 = UIStyle.Colors.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Add close button
    local closeButton = ButtonFactory.createButton({
        size = UDim2.new(0, 40, 0, 40),
        position = UDim2.new(1, -50, 0.5, -20),
        backgroundColor = Color3.fromRGB(231, 76, 60),
        text = "X",
        textSize = 18,
        font = UIStyle.Fonts.Bold,
        parent = header,
        callback = function()
            MainMenuUI:hide()
        end
    })
    
    -- Create sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, CONFIG.sidebarWidth, 1, -CONFIG.headerHeight)
    sidebar.Position = UDim2.new(0, 0, 0, CONFIG.headerHeight)
    sidebar.BackgroundColor3 = UIStyle.Colors.Secondary
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame
    
    -- Create sidebar corner (bottom left only)
    local sidebarCorner = Instance.new("UICorner")
    sidebarCorner.CornerRadius = UDim.new(0, 12)
    sidebarCorner.Parent = sidebar
    
    -- Create content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -CONFIG.sidebarWidth, 1, -CONFIG.headerHeight)
    content.Position = UDim2.new(0, CONFIG.sidebarWidth, 0, CONFIG.headerHeight)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame
    
    -- Create status bar
    local statusBar = Instance.new("Frame")
    statusBar.Name = "StatusBar"
    statusBar.Size = UDim2.new(1, -CONFIG.sidebarWidth, 0, 30)
    statusBar.Position = UDim2.new(0, CONFIG.sidebarWidth, 1, -30)
    statusBar.BackgroundColor3 = UIStyle.Colors.Secondary
    statusBar.BackgroundTransparency = 0.5
    statusBar.BorderSizePixel = 0
    statusBar.Parent = mainFrame
    
    -- Store references
    uiElements.mainFrame = mainFrame
    uiElements.sidebar = sidebar
    uiElements.content = content
    uiElements.statusBar = statusBar
    uiElements.screenGui = screenGui
    
    -- Create status indicators (will be called after function is defined)
    createStatusIndicators(statusBar)
    
    return mainFrame
end

-- Create category buttons in sidebar
local function createCategoryButtons(sidebar)
    -- Create scroll frame for buttons
    local buttonContainer = Instance.new("ScrollingFrame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, -10, 1, -10)
    buttonContainer.Position = UDim2.new(0, 5, 0, 5)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.BorderSizePixel = 0
    buttonContainer.ScrollBarThickness = 4
    buttonContainer.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    buttonContainer.Parent = sidebar
    
    -- Create layout for buttons
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = buttonContainer
    
    -- Create buttons for each category
    for i, category in ipairs(CONFIG.categories) do
        local button = ButtonFactory.createButton({
            size = UDim2.new(1, 0, 0, CONFIG.buttonHeight),
            backgroundColor = i == 1 and UIStyle.Colors.Primary or UIStyle.Colors.Secondary,
            text = category,
            textSize = 16,
            font = UIStyle.Fonts.Bold,
            parent = buttonContainer,
            callback = function()
                MainMenuUI:switchCategory(category)
            end
        })
        
        -- Store reference
        uiElements.menuButtons[category] = button
    end
    
    -- Set initial category
    uiElements.currentCategory = CONFIG.categories[1]
    
    -- Update scroll frame canvas size
    buttonContainer.CanvasSize = UDim2.new(0, 0, 0, (CONFIG.buttonHeight + 5) * #CONFIG.categories)
    
    -- Store reference
    uiElements.buttonContainer = buttonContainer
end

-- Create category content frames
local function createCategoryContents(content)
    for _, category in ipairs(CONFIG.categories) do
        local categoryFrame = Instance.new("Frame")
        categoryFrame.Name = category .. "Content"
        categoryFrame.Size = UDim2.new(1, -20, 1, -20)
        categoryFrame.Position = UDim2.new(0, 10, 0, 10)
        categoryFrame.BackgroundTransparency = 1
        categoryFrame.Visible = category == CONFIG.categories[1] -- Only first category visible initially
        categoryFrame.Parent = content
        
        -- Store reference
        uiElements.categories[category] = categoryFrame
        
        -- Populate category content
        populateCategoryContent(category, categoryFrame)
    end
end

-- Populate content for a specific category
populateCategoryContent = function(category, frame)
    -- Title for the category
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = category
    title.Font = UIStyle.Fonts.Bold
    title.TextSize = 24
    title.TextColor3 = UIStyle.Colors.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    
    if category == "Gym" then
        createGymContent(frame)
    elseif category == "Equipment" then
        createEquipmentContent(frame)
    elseif category == "Staff" then
        createStaffContent(frame)
    elseif category == "Members" then
        createMembersContent(frame)
    elseif category == "Research" then
        createResearchContent(frame)
    elseif category == "Statistics" then
        createStatisticsContent(frame)
    elseif category == "Shop" then
        createShopContent(frame)
    elseif category == "Settings" then
        createSettingsContent(frame)
    end
end

-- Create status indicators
createStatusIndicators = function(statusBar)
    local indicators = {
        { name = "Money", icon = "💰", value = "$0" },
        { name = "Members", icon = "👥", value = "0" },
        { name = "Rating", icon = "⭐", value = "0.0" },
        { name = "Level", icon = "📊", value = "1" }
    }
    
    local indicatorWidth = (statusBar.AbsoluteSize.X) / #indicators
    
    for i, indicator in ipairs(indicators) do
        local frame = Instance.new("Frame")
        frame.Name = indicator.name .. "Indicator"
        frame.Size = UDim2.new(0, indicatorWidth, 1, 0)
        frame.Position = UDim2.new(0, (i - 1) * indicatorWidth, 0, 0)
        frame.BackgroundTransparency = 1
        frame.Parent = statusBar
        
        local icon = Instance.new("TextLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 20, 1, 0)
        icon.Position = UDim2.new(0, 10, 0, 0)
        icon.BackgroundTransparency = 1
        icon.Text = indicator.icon
        icon.Font = UIStyle.Fonts.Regular
        icon.TextSize = 16
        icon.TextColor3 = UIStyle.Colors.Text
        icon.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(0, 50, 1, 0)
        label.Position = UDim2.new(0, 35, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = indicator.name .. ":"
        label.Font = UIStyle.Fonts.Regular
        label.TextSize = 14
        label.TextColor3 = UIStyle.Colors.TextDisabled
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local value = Instance.new("TextLabel")
        value.Name = "Value"
        value.Size = UDim2.new(0, 100, 1, 0)
        value.Position = UDim2.new(0, 90, 0, 0)
        value.BackgroundTransparency = 1
        value.Text = indicator.value
        value.Font = UIStyle.Fonts.Bold
        value.TextSize = 14
        value.TextColor3 = UIStyle.Colors.Text
        value.TextXAlignment = Enum.TextXAlignment.Left
        value.Parent = frame
        
        -- Store reference for updating later
        uiElements.statusElements[indicator.name] = value
    end
end

--[[ Category Content Creation Functions ]]--

-- Create Gym category content
createGymContent = function(frame)
    -- Description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, 0, 0, 40)
    description.Position = UDim2.new(0, 0, 0, 40)
    description.BackgroundTransparency = 1
    description.Text = "Manage your gym layout, appearance, and facilities."
    description.Font = UIStyle.Fonts.Regular
    description.TextSize = 16
    description.TextColor3 = UIStyle.Colors.Text
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextWrapped = true
    description.Parent = frame
    
    -- Create action buttons
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, 0, 0, 200)
    buttonContainer.Position = UDim2.new(0, 0, 0, 100)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = frame
    
    local buttons = {
        { name = "Buy Tiles", description = "Expand your gym with new floor tiles", icon = "🏗️" },
        { name = "Renovate", description = "Change the appearance of your gym", icon = "🎨" },
        { name = "Facilities", description = "Add specialized rooms and facilities", icon = "🏊" },
        { name = "Clean Gym", description = "Maintain cleanliness to improve satisfaction", icon = "🧹" }
    }
    
    for i, buttonInfo in ipairs(buttons) do
        local buttonCard = Instance.new("Frame")
        buttonCard.Name = buttonInfo.name .. "Card"
        buttonCard.Size = UDim2.new(0.48, -10, 0, 90)
        buttonCard.Position = UDim2.new(i % 2 == 1 and 0 or 0.52, 0, 0, math.floor((i-1) / 2) * 100)
        buttonCard.BackgroundColor3 = UIStyle.Colors.Secondary
        buttonCard.BorderSizePixel = 0
        buttonCard.Parent = buttonContainer
        
        -- Add corner radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = buttonCard
        
        -- Icon
        local icon = Instance.new("TextLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 40, 0, 40)
        icon.Position = UDim2.new(0, 10, 0, 10)
        icon.BackgroundTransparency = 1
        icon.Text = buttonInfo.icon
        icon.Font = UIStyle.Fonts.Regular
        icon.TextSize = 30
        icon.TextColor3 = UIStyle.Colors.Text
        icon.Parent = buttonCard
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -70, 0, 25)
        title.Position = UDim2.new(0, 60, 0, 10)
        title.BackgroundTransparency = 1
        title.Text = buttonInfo.name
        title.Font = UIStyle.Fonts.Bold
        title.TextSize = 18
        title.TextColor3 = UIStyle.Colors.Text
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = buttonCard
        
        -- Description
        local desc = Instance.new("TextLabel")
        desc.Name = "Description"
        desc.Size = UDim2.new(1, -70, 0, 40)
        desc.Position = UDim2.new(0, 60, 0, 35)
        desc.BackgroundTransparency = 1
        desc.Text = buttonInfo.description
        desc.Font = UIStyle.Fonts.Regular
        desc.TextSize = 14
        desc.TextColor3 = UIStyle.Colors.TextDisabled
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top
        desc.TextWrapped = true
        desc.Parent = buttonCard
        
        -- Make the entire card clickable
        local button = Instance.new("TextButton")
        button.Name = "Button"
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundTransparency = 1
        button.Text = ""
        button.Parent = buttonCard
        
        -- Button functionality
        button.Activated:Connect(function()
            if buttonInfo.name == "Buy Tiles" then
                MainMenuUI:hide()
                -- Show buy tiles interface
                if UIManager then
                    UIManager:showUI("BuyTileUI")
                end
            elseif buttonInfo.name == "Renovate" then
                if DialogFactory and DialogFactory.createNotification then
                    DialogFactory.createNotification({
                        title = "Coming Soon",
                        message = "The renovation system will be available in the next update!"
                    })
                end
            elseif buttonInfo.name == "Facilities" then
                if UIManager then
                    UIManager:showUI("FacilitiesUI")
                    MainMenuUI:hide()
                end
            elseif buttonInfo.name == "Clean Gym" then
                if UIManager then
                    UIManager:showUI("CleanGymUI")
                    MainMenuUI:hide()
                end
            end
        end)
    end
end

-- Create Equipment category content
createEquipmentContent = function(frame)
    -- Description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, 0, 0, 40)
    description.Position = UDim2.new(0, 0, 0, 40)
    description.BackgroundTransparency = 1
    description.Text = "Purchase, upgrade, and manage your gym equipment."
    description.Font = UIStyle.Fonts.Regular
    description.TextSize = 16
    description.TextColor3 = UIStyle.Colors.Text
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextWrapped = true
    description.Parent = frame
    
    -- Create equipment list
    local equipmentContainer = Instance.new("ScrollingFrame")
    equipmentContainer.Name = "EquipmentContainer"
    equipmentContainer.Size = UDim2.new(1, 0, 0, 300)
    equipmentContainer.Position = UDim2.new(0, 0, 0, 100)
    equipmentContainer.BackgroundTransparency = 1
    equipmentContainer.BorderSizePixel = 0
    equipmentContainer.ScrollBarThickness = 6
    equipmentContainer.ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200)
    equipmentContainer.Parent = frame
    
    -- Add layout for equipment list
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = equipmentContainer
    
    -- Add sample equipment items
    local equipment = {
        { name = "Treadmill", owned = 2, max = 10, cost = 500 },
        { name = "Weight Bench", owned = 1, max = 8, cost = 750 },
        { name = "Exercise Bike", owned = 1, max = 6, cost = 600 },
        { name = "Elliptical Trainer", owned = 0, max = 4, cost = 900 },
        { name = "Power Rack", owned = 0, max = 3, cost = 1200 },
        { name = "Rowing Machine", owned = 0, max = 3, cost = 800 }
    }
    
    for i, item in ipairs(equipment) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Name = item.name .. "Item"
        itemFrame.Size = UDim2.new(1, -10, 0, 80)
        itemFrame.BackgroundColor3 = UIStyle.Colors.Secondary
        itemFrame.BorderSizePixel = 0
        itemFrame.Parent = equipmentContainer
        
        -- Add corner radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = itemFrame
        
        -- Equipment name
        local name = Instance.new("TextLabel")
        name.Name = "Name"
        name.Size = UDim2.new(0.4, 0, 0, 25)
        name.Position = UDim2.new(0, 15, 0, 10)
        name.BackgroundTransparency = 1
        name.Text = item.name
        name.Font = UIStyle.Fonts.Bold
        name.TextSize = 18
        name.TextColor3 = UIStyle.Colors.Text
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = itemFrame
        
        -- Owned count
        local owned = Instance.new("TextLabel")
        owned.Name = "Owned"
        owned.Size = UDim2.new(0.2, 0, 0, 20)
        owned.Position = UDim2.new(0, 15, 0, 40)
        owned.BackgroundTransparency = 1
        owned.Text = "Owned: " .. item.owned .. "/" .. item.max
        owned.Font = UIStyle.Fonts.Regular
        owned.TextSize = 14
        owned.TextColor3 = UIStyle.Colors.TextDisabled
        owned.TextXAlignment = Enum.TextXAlignment.Left
        owned.Parent = itemFrame
        
        -- Cost
        local cost = Instance.new("TextLabel")
        cost.Name = "Cost"
        cost.Size = UDim2.new(0.2, 0, 0, 20)
        cost.Position = UDim2.new(0.2, 15, 0, 40)
        cost.BackgroundTransparency = 1
        cost.Text = "Cost: $" .. item.cost
        cost.Font = UIStyle.Fonts.Regular
        cost.TextSize = 14
        cost.TextColor3 = UIStyle.Colors.TextDisabled
        cost.TextXAlignment = Enum.TextXAlignment.Left
        cost.Parent = itemFrame
        
        -- Buy button
        local buyButton = ButtonFactory.createButton({
            size = UDim2.new(0, 100, 0, 30),
            position = UDim2.new(1, -120, 0.5, -15),
            backgroundColor = UIStyle.Colors.Primary,
            text = "Buy",
            textSize = 16,
            parent = itemFrame,
            callback = function()
                -- Purchase functionality would go here
                if UIManager then
                    UIManager:createNotification({
                        message = "Purchased " .. item.name,
                        type = "success"
                    })
                end
            end
        })
        
        -- Upgrade button
        local upgradeButton = ButtonFactory.createButton({
            size = UDim2.new(0, 100, 0, 30),
            position = UDim2.new(1, -230, 0.5, -15),
            backgroundColor = UIStyle.Colors.Secondary,
            text = "Upgrade",
            textSize = 16,
            parent = itemFrame,
            callback = function()
                -- Upgrade functionality would go here
                if item.owned > 0 then
                    if UIManager then
                        UIManager:showUI("EquipmentUpgradeUI", item.name)
                        MainMenuUI:hide()
                    end
                else
                    if UIManager then
                        UIManager:createNotification({
                            message = "You don't own any " .. item.name .. " to upgrade",
                            type = "warning"
                        })
                    end
                end
            end
        })
    end
    
    -- Update scroll frame canvas size
    equipmentContainer.CanvasSize = UDim2.new(0, 0, 0, (80 + 10) * #equipment)
end

-- Create Staff category content (simplified)
createStaffContent = function(frame)
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, 0, 0, 40)
    description.Position = UDim2.new(0, 0, 0, 40)
    description.BackgroundTransparency = 1
    description.Text = "Hire and manage staff for your gym."
    description.Font = UIStyle.Fonts.Regular
    description.TextSize = 16
    description.TextColor3 = UIStyle.Colors.Text
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextWrapped = true
    description.Parent = frame
    
    -- Create placeholder for staff UI
    local placeholderText = Instance.new("TextLabel")
    placeholderText.Size = UDim2.new(1, 0, 0, 60)
    placeholderText.Position = UDim2.new(0, 0, 0.5, -30)
    placeholderText.BackgroundTransparency = 1
    placeholderText.Text = "Staff management will be available in the next update!"
    placeholderText.Font = UIStyle.Fonts.Bold
    placeholderText.TextSize = 18
    placeholderText.TextColor3 = UIStyle.Colors.TextDisabled
    placeholderText.Parent = frame
    
    -- Add coming soon button
    local comingSoonButton = ButtonFactory.createButton({
        size = UDim2.new(0.5, 0, 0, 50),
        position = UDim2.new(0.25, 0, 0.7, 0),
        backgroundColor = UIStyle.Colors.Primary,
        text = "Coming Soon",
        textSize = 18,
        parent = frame,
        callback = function()
            -- Show notification about upcoming feature
            if UIManager then
                UIManager:createNotification({
                    message = "Staff management system will be available in the next update!",
                    type = "info"
                })
            end
        end
    })
end

-- Create Members category content (simplified)
createMembersContent = function(frame)
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, 0, 0, 40)
    description.Position = UDim2.new(0, 0, 0, 40)
    description.BackgroundTransparency = 1
    description.Text = "View and manage your gym members."
    description.Font = UIStyle.Fonts.Regular
    description.TextSize = 16
    description.TextColor3 = UIStyle.Colors.Text
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextWrapped = true
    description.Parent = frame
    
    -- Add button to view members
    local viewMembersButton = ButtonFactory.createButton({
        size = UDim2.new(0.5, 0, 0, 50),
        position = UDim2.new(0.25, 0, 0.3, 0),
        backgroundColor = UIStyle.Colors.Primary,
        text = "View Members",
        textSize = 18,
        parent = frame,
        callback = function()
            if UIManager then
                UIManager:showUI("MemberListUI")
                MainMenuUI:hide()
            end
        end
    })
    
    -- Add button to manage membership plans
    local managePlansButton = ButtonFactory.createButton({
        size = UDim2.new(0.5, 0, 0, 50),
        position = UDim2.new(0.25, 0, 0.5, 0),
        backgroundColor = UIStyle.Colors.Secondary,
        text = "Membership Plans",
        textSize = 18,
        parent = frame,
        callback = function()
            if UIManager then
                UIManager:showUI("MembershipPlansUI")
                MainMenuUI:hide()
            end
        end
    })
end

-- Create Research category content (simplified)
createResearchContent = function(frame)
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, 0, 0, 40)
    description.Position = UDim2.new(0, 0, 0, 40)
    description.BackgroundTransparency = 1
    description.Text = "Research new technologies and improvements for your gym."
    description.Font = UIStyle.Fonts.Regular
    description.TextSize = 16
    description.TextColor3 = UIStyle.Colors.Text
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextWrapped = true
    description.Parent = frame
    
    -- Placeholder for research UI
    local placeholderText = Instance.new("TextLabel")
    placeholderText.Size = UDim2.new(1, 0, 0, 60)
    placeholderText.Position = UDim2.new(0, 0, 0.5, -30)
    placeholderText.BackgroundTransparency = 1
    placeholderText.Text = "Research system will be available in the next update!"
    placeholderText.Font = UIStyle.Fonts.Bold
    placeholderText.TextSize = 18
    placeholderText.TextColor3 = UIStyle.Colors.TextDisabled
    placeholderText.Parent = frame
end

-- Create Statistics category content (simplified)
createStatisticsContent = function(frame)
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, 0, 0, 40)
    description.Position = UDim2.new(0, 0, 0, 40)
    description.BackgroundTransparency = 1
    description.Text = "View detailed statistics about your gym performance."
    description.Font = UIStyle.Fonts.Regular
    description.TextSize = 16
    description.TextColor3 = UIStyle.Colors.Text
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextWrapped = true
    description.Parent = frame
    
    -- Add button to view detailed stats
    local viewStatsButton = ButtonFactory.createButton({
        size = UDim2.new(0.5, 0, 0, 50),
        position = UDim2.new(0.25, 0, 0.3, 0),
        backgroundColor = UIStyle.Colors.Primary,
        text = "Full Statistics",
        textSize = 18,
        parent = frame,
        callback = function()
            if UIManager then
                UIManager:showUI("StatisticsUI")
                MainMenuUI:hide()
            end
        end
    })
    
    -- Add button to view revenue report
    local viewRevenueButton = ButtonFactory.createButton({
        size = UDim2.new(0.5, 0, 0, 50),
        position = UDim2.new(0.25, 0, 0.5, 0),
        backgroundColor = UIStyle.Colors.Secondary,
        text = "Revenue Report",
        textSize = 18,
        parent = frame,
        callback = function()
            if UIManager then
                UIManager:showUI("RevenueReportUI")
                MainMenuUI:hide()
            end
        end
    })
end

-- Create Shop category content (simplified)
createShopContent = function(frame)
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, 0, 0, 40)
    description.Position = UDim2.new(0, 0, 0, 40)
    description.BackgroundTransparency = 1
    description.Text = "Purchase special items and perks for your gym."
    description.Font = UIStyle.Fonts.Regular
    description.TextSize = 16
    description.TextColor3 = UIStyle.Colors.Text
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextWrapped = true
    description.Parent = frame
    
    -- Create shop items
    local shopContainer = Instance.new("ScrollingFrame")
    shopContainer.Name = "ShopContainer"
    shopContainer.Size = UDim2.new(1, 0, 0, 300)
    shopContainer.Position = UDim2.new(0, 0, 0, 100)
    shopContainer.BackgroundTransparency = 1
    shopContainer.BorderSizePixel = 0
    shopContainer.ScrollBarThickness = 6
    shopContainer.ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200)
    shopContainer.Parent = frame
    
    -- Add layout for shop items
    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.new(0.48, -10, 0, 100)
    layout.CellPadding = UDim2.new(0, 10, 0, 10)
    layout.Parent = shopContainer
    
    -- Add sample shop items
    local shopItems = {
        { name = "Double Members", description = "Double member visits for 10 minutes", cost = 500, icon = "👥" },
        { name = "Revenue Boost", description = "50% more revenue for 10 minutes", cost = 750, icon = "💰" },
        { name = "Builder Boost", description = "Faster building for 10 minutes", cost = 600, icon = "🏗️" },
        { name = "Member Satisfaction", description = "Increase member satisfaction by 20%", cost = 900, icon = "😊" }
    }
    
    for _, item in ipairs(shopItems) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Name = item.name .. "Item"
        itemFrame.BackgroundColor3 = UIStyle.Colors.Secondary
        itemFrame.BorderSizePixel = 0
        itemFrame.Parent = shopContainer
        
        -- Add corner radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = itemFrame
        
        -- Item icon
        local icon = Instance.new("TextLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 40, 0, 40)
        icon.Position = UDim2.new(0, 10, 0, 10)
        icon.BackgroundTransparency = 1
        icon.Text = item.icon
        icon.Font = UIStyle.Fonts.Regular
        icon.TextSize = 30
        icon.TextColor3 = UIStyle.Colors.Text
        icon.Parent = itemFrame
        
        -- Item name
        local name = Instance.new("TextLabel")
        name.Name = "Name"
        name.Size = UDim2.new(1, -130, 0, 25)
        name.Position = UDim2.new(0, 60, 0, 10)
        name.BackgroundTransparency = 1
        name.Text = item.name
        name.Font = UIStyle.Fonts.Bold
        name.TextSize = 18
        name.TextColor3 = UIStyle.Colors.Text
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = itemFrame
          -- Item description
        local shopItemDesc = Instance.new("TextLabel")
        shopItemDesc.Name = "Description"
        shopItemDesc.Size = UDim2.new(1, -130, 0, 40)
        shopItemDesc.Position = UDim2.new(0, 60, 0, 35)
        shopItemDesc.BackgroundTransparency = 1
        shopItemDesc.Text = item.description
        shopItemDesc.Font = UIStyle.Fonts.Regular
        shopItemDesc.TextSize = 14
        shopItemDesc.TextColor3 = UIStyle.Colors.TextDisabled
        shopItemDesc.TextXAlignment = Enum.TextXAlignment.Left
        shopItemDesc.TextYAlignment = Enum.TextYAlignment.Top
        shopItemDesc.TextWrapped = true
        shopItemDesc.Parent = itemFrame
        
        -- Item cost
        local costLabel = Instance.new("TextLabel")
        costLabel.Name = "Cost"
        costLabel.Size = UDim2.new(0, 80, 0, 20)
        costLabel.Position = UDim2.new(1, -90, 0, 10)
        costLabel.BackgroundTransparency = 1
        costLabel.Text = "$" .. item.cost
        costLabel.Font = UIStyle.Fonts.Bold
        costLabel.TextSize = 16
        costLabel.TextColor3 = UIStyle.Colors.Success
        costLabel.TextXAlignment = Enum.TextXAlignment.Right
        costLabel.Parent = itemFrame
        
        -- Buy button
        local buyButton = ButtonFactory.createButton({
            size = UDim2.new(0, 80, 0, 30),
            position = UDim2.new(1, -90, 0, 60),
            backgroundColor = UIStyle.Colors.Primary,
            text = "Buy",
            textSize = 16,
            parent = itemFrame,
            callback = function()
                -- Purchase functionality would go here
                if UIManager then
                    -- Show appropriate UI for the purchase
                    if item.name == "Double Members" then
                        UIManager:showUI("DoubleMemberPurchaseUI")
                        MainMenuUI:hide()
                    elseif item.name == "Builder Boost" then
                        UIManager:showUI("BuilderBoostPurchaseUI")
                        MainMenuUI:hide()
                    else
                        -- Generic purchase notification
                        UIManager:createNotification({
                            message = "Purchased " .. item.name,
                            type = "success"
                        })
                    end
                end
            end
        })
    end
    
    -- Update canvas size
    shopContainer.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#shopItems / 2) * 110)
end

-- Create Settings category content (simplified)
createSettingsContent = function(frame)
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, 0, 0, 40)
    description.Position = UDim2.new(0, 0, 0, 40)
    description.BackgroundTransparency = 1
    description.Text = "Adjust game settings and preferences."
    description.Font = UIStyle.Fonts.Regular
    description.TextSize = 16
    description.TextColor3 = UIStyle.Colors.Text
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextWrapped = true
    description.Parent = frame
    
    -- Add button to open settings
    local settingsButton = ButtonFactory.createButton({
        size = UDim2.new(0.5, 0, 0, 50),
        position = UDim2.new(0.25, 0, 0.3, 0),
        backgroundColor = UIStyle.Colors.Primary,
        text = "Open Settings",
        textSize = 18,
        parent = frame,
        callback = function()
            if UIManager then
                UIManager:showUI("SettingsUI")
                MainMenuUI:hide()
            end
        end
    })
end

--[[ Helper Functions ]]--

-- Update status indicators
local function updateStatusIndicators()
    -- In a real implementation, this would get data from the game
    local gameData = {
        Money = "$" .. math.random(1000, 100000),
        Members = tostring(math.random(10, 200)),
        Rating = string.format("%.1f", math.random(10, 50) / 10),
        Level = tostring(math.random(1, 10))
    }
    
    -- Update UI elements
    for name, value in pairs(gameData) do
        if uiElements.statusElements[name] then
            uiElements.statusElements[name].Text = value
        end
    end
end

-- Start status update timer
local function startStatusUpdates()
    -- Initial update
    updateStatusIndicators()
    
    -- Set up recurring updates
    task.spawn(function()
        while true do
            task.wait(CONFIG.statusUpdateInterval)
            updateStatusIndicators()
        end
    end)
end

--[[ Public API Functions ]]--

-- Switch active category
function MainMenuUI:switchCategory(category)
    if not uiElements.categories[category] then
        return
    end
    
    -- Update button colors
    for name, button in pairs(uiElements.menuButtons) do
        button.BackgroundColor3 = name == category and UIStyle.Colors.Primary or UIStyle.Colors.Secondary
    end
    
    -- Show/hide category contents
    for name, content in pairs(uiElements.categories) do
        content.Visible = name == category
    end
    
    uiElements.currentCategory = category
end

-- Initialize the UI
function MainMenuUI:initialize()
    -- Create base UI if not already created
    if not uiElements.mainFrame then
        createMainUI()
    end
    
    -- Create sidebar buttons
    if not uiElements.menuButtons or not next(uiElements.menuButtons) then
        createCategoryButtons(uiElements.sidebar)
    end
    
    -- Create category contents
    if not uiElements.categories or not next(uiElements.categories) then
        createCategoryContents(uiElements.content)
    end
    
    -- Start status updates
    startStatusUpdates()
      -- Register with UIRegistry if available
    if UIRegistry and UIRegistry.registerComponent then
        UIRegistry:registerComponent("MainMenuUI", self)
        UIRegistry:registerComponent("MainMenu", self) -- Also register as MainMenu for compatibility
        print("MainMenuUI: Registered with UIRegistry as both MainMenuUI and MainMenu")
    end
    
    -- Register with UIManager if available
    if UIManager and UIManager.registerUI then
        UIManager:registerUI("MainMenuUI", self)
        UIManager:registerUI("MainMenu", self) -- Also register as MainMenu for compatibility
        print("MainMenuUI: Registered with UIManager as both MainMenuUI and MainMenu")
    end
      -- No longer using global access point for better code structure
    print("MainMenuUI: Initialization complete")
    
    return self
end

-- Show the UI
function MainMenuUI:show()
    if not uiElements.mainFrame then
        self:initialize()
    end
    
    -- Show the main frame with animation
    uiElements.mainFrame.Visible = true
    uiElements.mainFrame.BackgroundTransparency = 1
    uiElements.mainFrame.Position = UDim2.new(0.5, -CONFIG.mainFrameSize.X.Offset / 2, 0.55, -CONFIG.mainFrameSize.Y.Offset / 2)
    
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
    
    -- Force a status update
    updateStatusIndicators()
    
    return true
end

-- Hide the UI
function MainMenuUI:hide()
    if not uiElements.mainFrame then
        return false
    end
    
    -- Create and play exit animation
    local positionTween = TweenService:Create(
        uiElements.mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(0.5, -CONFIG.mainFrameSize.X.Offset / 2, 0.55, -CONFIG.mainFrameSize.Y.Offset / 2) }
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
MainMenuUI:initialize()

-- Return the module
return MainMenuUI
