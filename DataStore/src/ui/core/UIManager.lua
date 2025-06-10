-- DataStore Manager Pro - UI Manager
-- Manages the main user interface and coordinates UI components

local UIManager = {}
UIManager.__index = UIManager

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[UI_MANAGER] [%s] %s", level, message))
end

-- Create new UI Manager instance
function UIManager.new(widget, services, pluginInfo)
    if not widget then
        debugLog("Widget is required for UI Manager", "ERROR")
        return nil
    end
    
    debugLog("Creating new UI Manager instance with " .. (services and "services" or "no services"))
    
    local self = setmetatable({}, UIManager)
    
    self.widget = widget
    self.services = services or {}
    self.pluginInfo = pluginInfo or {}
    self.components = {}
    self.initialized = false
    
    debugLog("UIManager object created, starting initialization...")
    
    -- Initialize the interface
    local success, error = pcall(function()
        return self:initialize()
    end)
    
    if not success then
        debugLog("UI Manager initialization failed: " .. tostring(error), "ERROR")
        debugLog("Error type: " .. type(error), "ERROR")
        return nil
    end
    
    debugLog("UI Manager instance creation completed successfully")
    return self
end

-- Initialize the UI
function UIManager:initialize()
    if not self then
        debugLog("UIManager self is nil!", "ERROR")
        return false
    end
    
    if self.initialized then
        debugLog("UI Manager already initialized")
        return true
    end
    
    debugLog("Initializing UI Manager...")
    debugLog("Widget: " .. tostring(self.widget))
    
    local serviceCount = 0
    if self.services then
        for _ in pairs(self.services) do
            serviceCount = serviceCount + 1
        end
    end
    debugLog("Services count: " .. serviceCount)
    
    -- Create main frame
    debugLog("Creating main frame...")
    local success1, error1 = pcall(function()
        self:createMainFrame()
    end)
    
    if not success1 then
        debugLog("Failed to create main frame: " .. tostring(error1), "ERROR")
        return false
    end
    
    debugLog("Main frame created, setting up layout...")
    
    -- Setup basic layout
    local success2, error2 = pcall(function()
        self:setupLayout()
    end)
    
    if not success2 then
        debugLog("Failed to setup layout: " .. tostring(error2), "ERROR")
        return false
    end
    
    self.initialized = true
    debugLog("UI Manager initialized successfully")
    return true
end

-- Create the main frame
function UIManager:createMainFrame()
    debugLog("Creating main frame")
    
    -- Main container
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "DataStoreManagerPro"
    self.mainFrame.Size = UDim2.new(1, 0, 1, 0)
    self.mainFrame.Position = UDim2.new(0, 0, 0, 0)
    self.mainFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.Parent = self.widget
    
    -- Title bar
    self.titleBar = Instance.new("Frame")
    self.titleBar.Name = "TitleBar"
    self.titleBar.Size = UDim2.new(1, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    self.titleBar.Position = UDim2.new(0, 0, 0, 0)
    self.titleBar.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    self.titleBar.BorderSizePixel = 1
    self.titleBar.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    self.titleBar.Parent = self.mainFrame
    
    -- Title text
    self.titleLabel = Instance.new("TextLabel")
    self.titleLabel.Name = "TitleLabel"
    self.titleLabel.Size = UDim2.new(1, -20, 1, 0)
    self.titleLabel.Position = UDim2.new(0, 10, 0, 0)
    self.titleLabel.BackgroundTransparency = 1
    self.titleLabel.Text = self.pluginInfo.name or "DataStore Manager Pro"
    self.titleLabel.Font = Constants.UI.THEME.FONTS.HEADING
    self.titleLabel.TextSize = 16
    self.titleLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    self.titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.titleLabel.Parent = self.titleBar
    
    -- Content area
    self.contentArea = Instance.new("Frame")
    self.contentArea.Name = "ContentArea"
    self.contentArea.Size = UDim2.new(1, 0, 1, -(Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT + Constants.UI.THEME.SIZES.STATUSBAR_HEIGHT))
    self.contentArea.Position = UDim2.new(0, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    self.contentArea.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    self.contentArea.BorderSizePixel = 0
    self.contentArea.Parent = self.mainFrame
    
    -- Status bar
    self.statusBar = Instance.new("Frame")
    self.statusBar.Name = "StatusBar"
    self.statusBar.Size = UDim2.new(1, 0, 0, Constants.UI.THEME.SIZES.STATUSBAR_HEIGHT)
    self.statusBar.Position = UDim2.new(0, 0, 1, -Constants.UI.THEME.SIZES.STATUSBAR_HEIGHT)
    self.statusBar.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    self.statusBar.BorderSizePixel = 1
    self.statusBar.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    self.statusBar.Parent = self.mainFrame
    
    -- Status text
    self.statusLabel = Instance.new("TextLabel")
    self.statusLabel.Name = "StatusLabel"
    self.statusLabel.Size = UDim2.new(1, -20, 1, 0)
    self.statusLabel.Position = UDim2.new(0, 10, 0, 0)
    self.statusLabel.BackgroundTransparency = 1
    self.statusLabel.Text = "🟢 Ready"
    self.statusLabel.Font = Constants.UI.THEME.FONTS.BODY
    self.statusLabel.TextSize = 12
    self.statusLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    self.statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.statusLabel.Parent = self.statusBar
    
    debugLog("Main frame created successfully")
end

-- Setup modern professional layout with sidebar
function UIManager:setupLayout()
    debugLog("Setting up modern professional layout")
    
    -- Create main container
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(1, 0, 1, 0)
    mainContainer.Position = UDim2.new(0, 0, 0, 0)
    mainContainer.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    mainContainer.BorderSizePixel = 0
    mainContainer.Parent = self.contentArea
    
    -- Create sidebar navigation
    debugLog("Creating sidebar navigation...")
    local success1, error1 = pcall(function()
        self:createSidebarNavigation(mainContainer)
    end)
    if not success1 then
        debugLog("Failed to create sidebar: " .. tostring(error1), "ERROR")
        return
    end
    debugLog("Sidebar navigation created successfully")
    
    -- Create main content area
    debugLog("Creating main content area...")
    local success2, error2 = pcall(function()
        self:createMainContentArea(mainContainer)
    end)
    if not success2 then
        debugLog("Failed to create main content area: " .. tostring(error2), "ERROR")
        return
    end
    debugLog("Main content area created successfully")
    
    -- Show default view
    local success, error = pcall(function()
        self:showDataExplorerView()
    end)
    
    if not success then
        debugLog("Failed to show Data Explorer view: " .. tostring(error), "ERROR")
        -- Fallback: create simple content
        local fallbackLabel = Instance.new("TextLabel")
        fallbackLabel.Size = UDim2.new(1, 0, 1, 0)
        fallbackLabel.Position = UDim2.new(0, 0, 0, 0)
        fallbackLabel.BackgroundTransparency = 1
        fallbackLabel.Text = "⚠️ Modern UI Loading Error\n\nFallback interface active.\nCheck console for details."
        fallbackLabel.Font = Constants.UI.THEME.FONTS.BODY
        fallbackLabel.TextSize = 16
        fallbackLabel.TextColor3 = Constants.UI.THEME.COLORS.WARNING
        fallbackLabel.TextWrapped = true
        fallbackLabel.TextXAlignment = Enum.TextXAlignment.Center
        fallbackLabel.TextYAlignment = Enum.TextYAlignment.Center
        fallbackLabel.Parent = self.mainContentArea or self.contentArea
    end
    
    debugLog("Modern professional layout setup complete")
end

-- Create modern sidebar navigation
function UIManager:createSidebarNavigation(parent)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, Constants.UI.THEME.SIZES.SIDEBAR_WIDTH, 1, 0)
    sidebar.Position = UDim2.new(0, 0, 0, 0)
    sidebar.BackgroundColor3 = Constants.UI.THEME.COLORS.SIDEBAR_BACKGROUND
    sidebar.BorderSizePixel = 0
    sidebar.Parent = parent
    
    self.sidebar = sidebar
    
    -- Sidebar header
    local sidebarHeader = Instance.new("Frame")
    sidebarHeader.Name = "Header"
    sidebarHeader.Size = UDim2.new(1, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    sidebarHeader.Position = UDim2.new(0, 0, 0, 0)
    sidebarHeader.BackgroundColor3 = Constants.UI.THEME.COLORS.SIDEBAR_BACKGROUND
    sidebarHeader.BorderSizePixel = 0
    sidebarHeader.Parent = sidebar
    
    -- Plugin title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.LARGE, 1, 0)
    titleLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "DataStore Manager Pro"
    titleLabel.Font = Constants.UI.THEME.FONTS.HEADING
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = sidebarHeader
    
    -- Navigation items container
    local navContainer = Instance.new("Frame")
    navContainer.Name = "Navigation"
    navContainer.Size = UDim2.new(1, 0, 1, -Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    navContainer.Position = UDim2.new(0, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    navContainer.BackgroundTransparency = 1
    navContainer.Parent = sidebar
    
    self.navContainer = navContainer
    self.currentNavItem = nil
    
    -- Create navigation items
    local yOffset = Constants.UI.THEME.SPACING.LARGE
    
    yOffset = self:createNavItem(navContainer, "🗂️", "Data Explorer", yOffset, true, function()
        self:showDataExplorerView()
    end)
    
    yOffset = self:createNavItem(navContainer, "🏗️", "Schema Builder", yOffset, false, function()
        self:showSchemaBuilderView()
    end)
    
    yOffset = self:createNavItem(navContainer, "📊", "Analytics", yOffset, false, function()
        self:showAnalyticsView()
    end)
    
    yOffset = self:createNavItem(navContainer, "👥", "Sessions", yOffset, false, function()
        self:showSessionsView()
    end)
    
    yOffset = self:createNavItem(navContainer, "🔒", "Security", yOffset, false, function()
        self:showSecurityView()
    end)
    
    -- Settings at bottom
    local settingsOffset = 1
    self:createNavItem(navContainer, "⚙️", "Settings", settingsOffset - Constants.UI.THEME.SIZES.BUTTON_HEIGHT - Constants.UI.THEME.SPACING.LARGE, false, function()
        self:showSettingsView()
    end, true)
end

-- Create navigation item
function UIManager:createNavItem(parent, icon, text, yOffset, isActive, callback, isBottom)
    local navItem = Instance.new("TextButton")
    navItem.Name = text:gsub("%s+", "") .. "NavItem"
    navItem.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM * 2, 0, Constants.UI.THEME.SIZES.BUTTON_HEIGHT)
    
    if isBottom then
        navItem.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, yOffset, 0)
    else
        navItem.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, yOffset)
    end
    
    navItem.BackgroundColor3 = isActive and Constants.UI.THEME.COLORS.SIDEBAR_ITEM_ACTIVE or Color3.fromRGB(0, 0, 0)
    navItem.BackgroundTransparency = isActive and 0 or 1
    navItem.BorderSizePixel = 0
    navItem.Text = ""
    navItem.Parent = parent
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    corner.Parent = navItem
    
    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, Constants.UI.THEME.SIZES.ICON_MEDIUM, 1, 0)
    iconLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.Font = Constants.UI.THEME.FONTS.UI
    iconLabel.TextSize = Constants.UI.THEME.SIZES.ICON_MEDIUM
    iconLabel.TextColor3 = isActive and Constants.UI.THEME.COLORS.TEXT_PRIMARY or Constants.UI.THEME.COLORS.TEXT_SECONDARY
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center
    iconLabel.TextYAlignment = Enum.TextYAlignment.Center
    iconLabel.Parent = navItem
    
    -- Text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.Size = UDim2.new(1, -Constants.UI.THEME.SIZES.ICON_MEDIUM - Constants.UI.THEME.SPACING.MEDIUM * 2, 1, 0)
    textLabel.Position = UDim2.new(0, Constants.UI.THEME.SIZES.ICON_MEDIUM + Constants.UI.THEME.SPACING.MEDIUM * 2, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.Font = Constants.UI.THEME.FONTS.UI
    textLabel.TextSize = 13
    textLabel.TextColor3 = isActive and Constants.UI.THEME.COLORS.TEXT_PRIMARY or Constants.UI.THEME.COLORS.TEXT_SECONDARY
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Parent = navItem
    
    -- Hover effects
    navItem.MouseEnter:Connect(function()
        if navItem ~= self.currentNavItem then
            navItem.BackgroundTransparency = 0.8
            navItem.BackgroundColor3 = Constants.UI.THEME.COLORS.SIDEBAR_ITEM_HOVER
        end
    end)
    
    navItem.MouseLeave:Connect(function()
        if navItem ~= self.currentNavItem then
            navItem.BackgroundTransparency = 1
        end
    end)
    
    -- Click handler
    navItem.MouseButton1Click:Connect(function()
        self:setActiveNavItem(navItem, iconLabel, textLabel)
        callback()
    end)
    
    -- Set as current if active
    if isActive then
        self.currentNavItem = navItem
    end
    
    return yOffset + Constants.UI.THEME.SIZES.BUTTON_HEIGHT + Constants.UI.THEME.SPACING.SMALL
end

-- Set active navigation item
function UIManager:setActiveNavItem(navItem, iconLabel, textLabel)
    -- Reset all nav items
    for _, child in ipairs(self.navContainer:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundTransparency = 1
            local icon = child:FindFirstChild("Icon")
            local text = child:FindFirstChild("Text")
            if icon then icon.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY end
            if text then text.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY end
        end
    end
    
    -- Set active state
    navItem.BackgroundTransparency = 0
    navItem.BackgroundColor3 = Constants.UI.THEME.COLORS.SIDEBAR_ITEM_ACTIVE
    iconLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    textLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    
    self.currentNavItem = navItem
    debugLog("Switched to: " .. textLabel.Text)
end

-- Create main content area
function UIManager:createMainContentArea(parent)
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -Constants.UI.THEME.SIZES.SIDEBAR_WIDTH, 1, 0)
    contentArea.Position = UDim2.new(0, Constants.UI.THEME.SIZES.SIDEBAR_WIDTH, 0, 0)
    contentArea.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    contentArea.BorderSizePixel = 0
    contentArea.Parent = parent
    
    self.mainContentArea = contentArea
end

-- Legacy tab system (keeping for compatibility)
function UIManager:createTabSystem(parent)
    -- Tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 40)
    tabBar.Position = UDim2.new(0, 0, 0, 0)
    tabBar.BackgroundColor3 = Constants.UI.THEME.COLORS.SURFACE
    tabBar.BorderSizePixel = 1
    tabBar.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
    tabBar.Parent = parent
    
    -- Tab content area
    local tabContent = Instance.new("Frame")
    tabContent.Name = "TabContent"
    tabContent.Size = UDim2.new(1, 0, 1, -40)
    tabContent.Position = UDim2.new(0, 0, 0, 40)
    tabContent.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND
    tabContent.BorderSizePixel = 0
    tabContent.Parent = parent
    
    self.tabContent = tabContent
    self.currentTab = nil
    
    -- Create tabs
    self:createTab(tabBar, "Overview", "📊", function() self:showOverviewTab() end, true)
    self:createTab(tabBar, "Explorer", "📂", function() self:showExplorerTab() end, false)
    self:createTab(tabBar, "Editor", "📝", function() self:showEditorTab() end, false)
    
    -- Show default tab
    self:showOverviewTab()
end

-- Create individual tab button
function UIManager:createTab(tabBar, name, icon, callback, isActive)
    local tabButton = Instance.new("TextButton")
    tabButton.Name = name .. "Tab"
    tabButton.Size = UDim2.new(0, 120, 1, -4)
    tabButton.Position = UDim2.new(0, (#tabBar:GetChildren() - 1) * 120 + 2, 0, 2)
    tabButton.BackgroundColor3 = isActive and Constants.UI.THEME.COLORS.PRIMARY or Constants.UI.THEME.COLORS.ACCENT
    tabButton.BorderSizePixel = 0
    tabButton.Text = icon .. " " .. name
    tabButton.Font = Constants.UI.THEME.FONTS.BODY
    tabButton.TextSize = 14
    tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabButton.Parent = tabBar
    
    tabButton.MouseButton1Click:Connect(function()
        self:setActiveTab(tabButton, name)
        callback()
    end)
    
    if isActive then
        self.activeTab = tabButton
    end
end

-- Set active tab
function UIManager:setActiveTab(tabButton, tabName)
    -- Reset all tabs
    for _, child in ipairs(tabButton.Parent:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundColor3 = Constants.UI.THEME.COLORS.ACCENT
        end
    end
    
    -- Set active tab
    tabButton.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
    self.activeTab = tabButton
    self.currentTab = tabName
    
    debugLog("Switched to tab: " .. tabName)
end

-- Show Overview tab
function UIManager:showOverviewTab()
    self:clearTabContent()
    
    -- Welcome section
    local welcomeSection = Instance.new("Frame")
    welcomeSection.Name = "WelcomeSection"
    welcomeSection.Size = UDim2.new(1, -40, 0, 120)
    welcomeSection.Position = UDim2.new(0, 20, 0, 20)
    welcomeSection.BackgroundColor3 = Constants.UI.THEME.COLORS.SURFACE
    welcomeSection.BorderSizePixel = 1
    welcomeSection.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
    welcomeSection.Parent = self.tabContent
    
    -- Welcome title
    local welcomeTitle = Instance.new("TextLabel")
    welcomeTitle.Name = "WelcomeTitle"
    welcomeTitle.Size = UDim2.new(1, -20, 0, 30)
    welcomeTitle.Position = UDim2.new(0, 10, 0, 10)
    welcomeTitle.BackgroundTransparency = 1
    welcomeTitle.Text = "🎉 DataStore Manager Pro"
    welcomeTitle.Font = Constants.UI.THEME.FONTS.HEADING
    welcomeTitle.TextSize = 20
    welcomeTitle.TextColor3 = Constants.UI.THEME.COLORS.PRIMARY
    welcomeTitle.TextXAlignment = Enum.TextXAlignment.Left
    welcomeTitle.Parent = welcomeSection
    
    -- Welcome message
    local welcomeMessage = Instance.new("TextLabel")
    welcomeMessage.Name = "WelcomeMessage"
    welcomeMessage.Size = UDim2.new(1, -20, 1, -50)
    welcomeMessage.Position = UDim2.new(0, 10, 0, 40)
    welcomeMessage.BackgroundTransparency = 1
    welcomeMessage.Text = "Professional DataStore management for Roblox Studio.\nExplore DataStores, edit data, and manage your game's data efficiently."
    welcomeMessage.Font = Constants.UI.THEME.FONTS.BODY
    welcomeMessage.TextSize = 14
    welcomeMessage.TextColor3 = Constants.UI.THEME.COLORS.TEXT
    welcomeMessage.TextWrapped = true
    welcomeMessage.TextXAlignment = Enum.TextXAlignment.Left
    welcomeMessage.TextYAlignment = Enum.TextYAlignment.Top
    welcomeMessage.Parent = welcomeSection
    
    -- Services status section
    local servicesSection = Instance.new("Frame")
    servicesSection.Name = "ServicesSection"
    servicesSection.Size = UDim2.new(1, -40, 0, 200)
    servicesSection.Position = UDim2.new(0, 20, 0, 160)
    servicesSection.BackgroundColor3 = Constants.UI.THEME.COLORS.SURFACE
    servicesSection.BorderSizePixel = 1
    servicesSection.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
    servicesSection.Parent = self.tabContent
    
    -- Services title
    local servicesTitle = Instance.new("TextLabel")
    servicesTitle.Name = "ServicesTitle"
    servicesTitle.Size = UDim2.new(1, -20, 0, 30)
    servicesTitle.Position = UDim2.new(0, 10, 0, 10)
    servicesTitle.BackgroundTransparency = 1
    servicesTitle.Text = "⚙️ Active Services"
    servicesTitle.Font = Constants.UI.THEME.FONTS.HEADING
    servicesTitle.TextSize = 16
    servicesTitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT
    servicesTitle.TextXAlignment = Enum.TextXAlignment.Left
    servicesTitle.Parent = servicesSection
    
    -- Services list
    local servicesList = Instance.new("TextLabel")
    servicesList.Name = "ServicesList"
    servicesList.Size = UDim2.new(1, -20, 1, -50)
    servicesList.Position = UDim2.new(0, 10, 0, 40)
    servicesList.BackgroundTransparency = 1
    servicesList.Text = self:generateServicesText()
    servicesList.Font = Constants.UI.THEME.FONTS.CODE
    servicesList.TextSize = 12
    servicesList.TextColor3 = Constants.UI.THEME.COLORS.SUCCESS
    servicesList.TextWrapped = true
    servicesList.TextXAlignment = Enum.TextXAlignment.Left
    servicesList.TextYAlignment = Enum.TextYAlignment.Top
    servicesList.Parent = servicesSection
end

-- Show Data Explorer view (modern layout)
function UIManager:showDataExplorerView()
    if not self.mainContentArea then
        debugLog("Main content area not available", "ERROR")
        return
    end
    
    -- Clear existing content
    for _, child in ipairs(self.mainContentArea:GetChildren()) do
        child:Destroy()
    end
    
    -- Create modern Data Explorer interface
    self:createModernDataExplorer()
    
    -- Load DataStores
    self:loadDataStores()
end

-- Create modern Data Explorer interface
function UIManager:createModernDataExplorer()
    -- Header section
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    header.BorderSizePixel = 0
    header.Parent = self.mainContentArea
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0.5, 0, 1, 0)
    titleLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.XLARGE, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Data Explorer"
    titleLabel.Font = Constants.UI.THEME.FONTS.HEADING
    titleLabel.TextSize = 24
    titleLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = header
    
    -- Search box
    local searchContainer = Instance.new("Frame")
    searchContainer.Name = "SearchContainer"
    searchContainer.Size = UDim2.new(0.4, 0, 0, Constants.UI.THEME.SIZES.INPUT_HEIGHT)
    searchContainer.Position = UDim2.new(0.6, 0, 0.5, -Constants.UI.THEME.SIZES.INPUT_HEIGHT/2)
    searchContainer.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
    searchContainer.BorderSizePixel = 1
    searchContainer.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
    searchContainer.Parent = header
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    searchCorner.Parent = searchContainer
    
    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(1, -40, 1, 0)
    searchBox.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Text = ""
    searchBox.PlaceholderText = "🔍 Search data stores..."
    searchBox.Font = Constants.UI.THEME.FONTS.BODY
    searchBox.TextSize = 14
    searchBox.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    searchBox.PlaceholderColor3 = Constants.UI.THEME.COLORS.TEXT_MUTED
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.Parent = searchContainer
    
    -- Content area
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, 0, 1, -60)
    contentFrame.Position = UDim2.new(0, 0, 0, 60)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = self.mainContentArea
    
    -- Two-column layout
    self:createDataStoreColumns(contentFrame)
end

-- Create DataStore columns (modern card-based layout)
function UIManager:createDataStoreColumns(parent)
    -- Left column - DataStore list
    local leftColumn = Instance.new("Frame")
    leftColumn.Name = "DataStoresColumn"
    leftColumn.Size = UDim2.new(0.35, -Constants.UI.THEME.SPACING.MEDIUM, 1, -Constants.UI.THEME.SPACING.XLARGE)
    leftColumn.Position = UDim2.new(0, Constants.UI.THEME.SPACING.XLARGE, 0, Constants.UI.THEME.SPACING.LARGE)
    leftColumn.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    leftColumn.BorderSizePixel = 0
    leftColumn.Parent = parent
    
    local leftCorner = Instance.new("UICorner")
    leftCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    leftCorner.Parent = leftColumn
    
    -- Left column header
    local leftHeader = Instance.new("Frame")
    leftHeader.Name = "Header"
    leftHeader.Size = UDim2.new(1, 0, 0, 50)
    leftHeader.Position = UDim2.new(0, 0, 0, 0)
    leftHeader.BackgroundTransparency = 1
    leftHeader.Parent = leftColumn
    
    local datastoreTitle = Instance.new("TextLabel")
    datastoreTitle.Name = "Title"
    datastoreTitle.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.LARGE, 1, 0)
    datastoreTitle.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE, 0, 0)
    datastoreTitle.BackgroundTransparency = 1
    datastoreTitle.Text = "📁 Data Stores"
    datastoreTitle.Font = Constants.UI.THEME.FONTS.SUBHEADING
    datastoreTitle.TextSize = 16
    datastoreTitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    datastoreTitle.TextXAlignment = Enum.TextXAlignment.Left
    datastoreTitle.TextYAlignment = Enum.TextYAlignment.Center
    datastoreTitle.Parent = leftHeader
    
    -- DataStore list (scrollable)
    local datastoreScroll = Instance.new("ScrollingFrame")
    datastoreScroll.Name = "DataStoreList"
    datastoreScroll.Size = UDim2.new(1, 0, 1, -50)
    datastoreScroll.Position = UDim2.new(0, 0, 0, 50)
    datastoreScroll.BackgroundTransparency = 1
    datastoreScroll.BorderSizePixel = 0
    datastoreScroll.ScrollBarThickness = 4
    datastoreScroll.ScrollBarImageColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    datastoreScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    datastoreScroll.Parent = leftColumn
    
    self.explorerElements = self.explorerElements or {}
    self.explorerElements.datastoreList = datastoreScroll
    
    -- Right column - Data preview
    local rightColumn = Instance.new("Frame")
    rightColumn.Name = "DataPreviewColumn"
    rightColumn.Size = UDim2.new(0.65, -Constants.UI.THEME.SPACING.MEDIUM, 1, -Constants.UI.THEME.SPACING.XLARGE)
    rightColumn.Position = UDim2.new(0.35, Constants.UI.THEME.SPACING.MEDIUM, 0, Constants.UI.THEME.SPACING.LARGE)
    rightColumn.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    rightColumn.BorderSizePixel = 0
    rightColumn.Parent = parent
    
    local rightCorner = Instance.new("UICorner")
    rightCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    rightCorner.Parent = rightColumn
    
    -- Right column header
    local rightHeader = Instance.new("Frame")
    rightHeader.Name = "Header"
    rightHeader.Size = UDim2.new(1, 0, 0, 50)
    rightHeader.Position = UDim2.new(0, 0, 0, 0)
    rightHeader.BackgroundTransparency = 1
    rightHeader.Parent = rightColumn
    
    local previewTitle = Instance.new("TextLabel")
    previewTitle.Name = "Title"
    previewTitle.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.LARGE, 1, 0)
    previewTitle.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE, 0, 0)
    previewTitle.BackgroundTransparency = 1
    previewTitle.Text = "📋 Data Preview - Select a DataStore"
    previewTitle.Font = Constants.UI.THEME.FONTS.SUBHEADING
    previewTitle.TextSize = 16
    previewTitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    previewTitle.TextXAlignment = Enum.TextXAlignment.Left
    previewTitle.TextYAlignment = Enum.TextYAlignment.Center
    previewTitle.Parent = rightHeader
    
    self.explorerElements.previewTitle = previewTitle
    
    -- Data preview area
    local previewArea = Instance.new("Frame")
    previewArea.Name = "PreviewArea"
    previewArea.Size = UDim2.new(1, 0, 1, -50)
    previewArea.Position = UDim2.new(0, 0, 0, 50)
    previewArea.BackgroundTransparency = 1
    previewArea.Parent = rightColumn
    
    -- Keys list section
    local keysSection = Instance.new("Frame")
    keysSection.Name = "KeysSection"
    keysSection.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.XLARGE, 0.4, 0)
    keysSection.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE, 0, Constants.UI.THEME.SPACING.LARGE)
    keysSection.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
    keysSection.BorderSizePixel = 1
    keysSection.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
    keysSection.Parent = previewArea
    
    local keysCorner = Instance.new("UICorner")
    keysCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    keysCorner.Parent = keysSection
    
    -- Keys header
    local keysHeader = Instance.new("TextLabel")
    keysHeader.Name = "KeysHeader"
    keysHeader.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.LARGE, 0, 30)
    keysHeader.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, Constants.UI.THEME.SPACING.MEDIUM)
    keysHeader.BackgroundTransparency = 1
    keysHeader.Text = "🔑 Keys"
    keysHeader.Font = Constants.UI.THEME.FONTS.SUBHEADING
    keysHeader.TextSize = 14
    keysHeader.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    keysHeader.TextXAlignment = Enum.TextXAlignment.Left
    keysHeader.TextYAlignment = Enum.TextYAlignment.Center
    keysHeader.Parent = keysSection
    
    -- Keys scroll frame
    local keysScroll = Instance.new("ScrollingFrame")
    keysScroll.Name = "KeysScroll"
    keysScroll.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.LARGE, 1, -40)
    keysScroll.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, 35)
    keysScroll.BackgroundTransparency = 1
    keysScroll.BorderSizePixel = 0
    keysScroll.ScrollBarThickness = 4
    keysScroll.ScrollBarImageColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    keysScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    keysScroll.Parent = keysSection
    
    self.explorerElements.keysScroll = keysScroll
    
    -- Data content section
    local dataSection = Instance.new("Frame")
    dataSection.Name = "DataSection"
    dataSection.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.XLARGE, 0.6, -Constants.UI.THEME.SPACING.LARGE)
    dataSection.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE, 0.4, Constants.UI.THEME.SPACING.MEDIUM)
    dataSection.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
    dataSection.BorderSizePixel = 1
    dataSection.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
    dataSection.Parent = previewArea
    
    local dataCorner = Instance.new("UICorner")
    dataCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    dataCorner.Parent = dataSection
    
    -- Data header
    local dataHeader = Instance.new("TextLabel")
    dataHeader.Name = "DataHeader"
    dataHeader.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.LARGE, 0, 30)
    dataHeader.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, Constants.UI.THEME.SPACING.MEDIUM)
    dataHeader.BackgroundTransparency = 1
    dataHeader.Text = "📄 Data Preview"
    dataHeader.Font = Constants.UI.THEME.FONTS.SUBHEADING
    dataHeader.TextSize = 14
    dataHeader.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    dataHeader.TextXAlignment = Enum.TextXAlignment.Left
    dataHeader.TextYAlignment = Enum.TextYAlignment.Center
    dataHeader.Parent = dataSection
    
    -- Data content scroll frame
    local dataScroll = Instance.new("ScrollingFrame")
    dataScroll.Name = "DataScroll"
    dataScroll.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.LARGE, 1, -40)
    dataScroll.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, 35)
    dataScroll.BackgroundTransparency = 1
    dataScroll.BorderSizePixel = 0
    dataScroll.ScrollBarThickness = 4
    dataScroll.ScrollBarImageColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    dataScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    dataScroll.Parent = dataSection
    
    -- Data content display
    local previewContent = Instance.new("TextLabel")
    previewContent.Name = "PreviewContent"
    previewContent.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM, 0, 50)
    previewContent.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, 0)
    previewContent.BackgroundTransparency = 1
    previewContent.Text = "Select a DataStore and key to view data contents."
    previewContent.Font = Constants.UI.THEME.FONTS.CODE
    previewContent.TextSize = 12
    previewContent.TextColor3 = Constants.UI.THEME.COLORS.TEXT_MUTED
    previewContent.TextWrapped = true
    previewContent.TextXAlignment = Enum.TextXAlignment.Left
    previewContent.TextYAlignment = Enum.TextYAlignment.Top
    previewContent.Parent = dataScroll
    
    self.explorerElements.previewContent = previewContent
    self.explorerElements.dataScroll = dataScroll
end

-- Show Explorer tab (legacy)
function UIManager:showExplorerTab()
    self:clearTabContent()
    
    -- Create explorer interface
    self:createExplorerInterface()
end

-- Create DataStore Explorer interface
function UIManager:createExplorerInterface()
    -- Left panel - DataStore list
    local leftPanel = Instance.new("Frame")
    leftPanel.Name = "LeftPanel"
    leftPanel.Size = UDim2.new(0.3, -10, 1, -20)
    leftPanel.Position = UDim2.new(0, 10, 0, 10)
    leftPanel.BackgroundColor3 = Constants.UI.THEME.COLORS.SURFACE
    leftPanel.BorderSizePixel = 1
    leftPanel.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
    leftPanel.Parent = self.tabContent
    
    -- Left panel title
    local leftTitle = Instance.new("TextLabel")
    leftTitle.Name = "Title"
    leftTitle.Size = UDim2.new(1, -20, 0, 30)
    leftTitle.Position = UDim2.new(0, 10, 0, 10)
    leftTitle.BackgroundTransparency = 1
    leftTitle.Text = "📂 DataStores"
    leftTitle.Font = Constants.UI.THEME.FONTS.HEADING
    leftTitle.TextSize = 16
    leftTitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT
    leftTitle.TextXAlignment = Enum.TextXAlignment.Left
    leftTitle.Parent = leftPanel
    
    -- DataStore list
    local datastoreList = Instance.new("ScrollingFrame")
    datastoreList.Name = "DataStoreList"
    datastoreList.Size = UDim2.new(1, -20, 1, -60)
    datastoreList.Position = UDim2.new(0, 10, 0, 45)
    datastoreList.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND
    datastoreList.BorderSizePixel = 1
    datastoreList.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
    datastoreList.ScrollBarThickness = 8
    datastoreList.Parent = leftPanel
    
    -- Middle panel - Key list
    local middlePanel = Instance.new("Frame")
    middlePanel.Name = "MiddlePanel"
    middlePanel.Size = UDim2.new(0.35, -10, 1, -20)
    middlePanel.Position = UDim2.new(0.3, 5, 0, 10)
    middlePanel.BackgroundColor3 = Constants.UI.THEME.COLORS.SURFACE
    middlePanel.BorderSizePixel = 1
    middlePanel.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
    middlePanel.Parent = self.tabContent
    
    -- Middle panel title
    local middleTitle = Instance.new("TextLabel")
    middleTitle.Name = "Title"
    middleTitle.Size = UDim2.new(1, -20, 0, 30)
    middleTitle.Position = UDim2.new(0, 10, 0, 10)
    middleTitle.BackgroundTransparency = 1
    middleTitle.Text = "🔑 Keys"
    middleTitle.Font = Constants.UI.THEME.FONTS.HEADING
    middleTitle.TextSize = 16
    middleTitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT
    middleTitle.TextXAlignment = Enum.TextXAlignment.Left
    middleTitle.Parent = middlePanel
    
    -- Key list
    local keyList = Instance.new("ScrollingFrame")
    keyList.Name = "KeyList"
    keyList.Size = UDim2.new(1, -20, 1, -60)
    keyList.Position = UDim2.new(0, 10, 0, 45)
    keyList.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND
    keyList.BorderSizePixel = 1
    keyList.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
    keyList.ScrollBarThickness = 8
    keyList.Parent = middlePanel
    
    -- Right panel - Data viewer
    local rightPanel = Instance.new("Frame")
    rightPanel.Name = "RightPanel"
    rightPanel.Size = UDim2.new(0.35, -10, 1, -20)
    rightPanel.Position = UDim2.new(0.65, 5, 0, 10)
    rightPanel.BackgroundColor3 = Constants.UI.THEME.COLORS.SURFACE
    rightPanel.BorderSizePixel = 1
    rightPanel.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
    rightPanel.Parent = self.tabContent
    
    -- Right panel title
    local rightTitle = Instance.new("TextLabel")
    rightTitle.Name = "Title"
    rightTitle.Size = UDim2.new(1, -20, 0, 30)
    rightTitle.Position = UDim2.new(0, 10, 0, 10)
    rightTitle.BackgroundTransparency = 1
    rightTitle.Text = "📄 Data Viewer"
    rightTitle.Font = Constants.UI.THEME.FONTS.HEADING
    rightTitle.TextSize = 16
    rightTitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT
    rightTitle.TextXAlignment = Enum.TextXAlignment.Left
    rightTitle.Parent = rightPanel
    
    -- Data viewer
    local dataViewer = Instance.new("ScrollingFrame")
    dataViewer.Name = "DataViewer"
    dataViewer.Size = UDim2.new(1, -20, 1, -60)
    dataViewer.Position = UDim2.new(0, 10, 0, 45)
    dataViewer.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND
    dataViewer.BorderSizePixel = 1
    dataViewer.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
    dataViewer.ScrollBarThickness = 8
    dataViewer.Parent = rightPanel
    
    -- Store references
    self.explorerElements = {
        datastoreList = datastoreList,
        keyList = keyList,
        dataViewer = dataViewer
    }
    
    -- Load DataStores
    self:loadDataStores()
end

-- Load DataStores into the explorer
function UIManager:loadDataStores()
    debugLog("Loading DataStores into explorer...")
    
    if not self.services or not self.services["features.explorer.DataExplorer"] then
        debugLog("Data Explorer service not available", "ERROR")
        return
    end
    
    local explorer = self.services["features.explorer.DataExplorer"]
    
    -- Set up service references - try both stored services and fallback
    local dataStoreManager = self.services["core.data.DataStoreManager"]
    
    -- Debug: Check what methods the DataStore Manager has
    if dataStoreManager then
        debugLog("DataStore Manager found. Type: " .. type(dataStoreManager))
        debugLog("Has getDataStoreNames: " .. tostring(dataStoreManager.getDataStoreNames ~= nil))
        debugLog("Has getDataStoreKeys: " .. tostring(dataStoreManager.getDataStoreKeys ~= nil))
        debugLog("Has getDataInfo: " .. tostring(dataStoreManager.getDataInfo ~= nil))
    else
        debugLog("No DataStore Manager found in services")
    end
    
    -- Check if DataStore Manager has the required methods  
    if not dataStoreManager or not dataStoreManager.getDataStoreNames then
        debugLog("DataStore Manager not found or missing methods, creating fallback...", "WARN")
        -- Create a simple fallback DataStore manager for demo purposes
        dataStoreManager = {
            getDataStoreNames = function()
                debugLog("Using fallback DataStore names")
                return {
                    "PlayerData",
                    "PlayerStats", 
                    "GameSettings",
                    "Leaderboard",
                    "PlayerInventory",
                    "GameData",
                    "UserPreferences",
                    "ServerData"
                }
            end,
            getDataStoreKeys = function(self, datastoreName, scope, maxKeys)
                debugLog("Using fallback DataStore keys for: " .. datastoreName)
                return {
                    {
                        key = "Player_123456789",
                        lastModified = os.date("%Y-%m-%d %H:%M:%S"),
                        hasData = true
                    },
                    {
                        key = "Player_987654321", 
                        lastModified = os.date("%Y-%m-%d %H:%M:%S"),
                        hasData = true
                    },
                    {
                        key = "Settings_Global",
                        lastModified = os.date("%Y-%m-%d %H:%M:%S"),
                        hasData = true
                    }
                }
            end,
            getDataInfo = function(self, datastoreName, key, scope)
                debugLog("Using fallback data info for: " .. datastoreName .. " -> " .. key)
                local sampleData = {
                    ["Player_123456789"] = {
                        level = 25,
                        coins = 1250,
                        inventory = {"sword", "shield", "potion"},
                        lastLogin = "2024-01-20 15:30:00"
                    },
                    ["Player_987654321"] = {
                        level = 18,
                        coins = 850,
                        inventory = {"bow", "arrows", "health_potion"},
                        lastLogin = "2024-01-19 12:45:00"
                    },
                    ["Settings_Global"] = {
                        maxPlayers = 20,
                        gameMode = "adventure",
                        difficulty = "normal",
                        version = "1.2.3"
                    }
                }
                
                local data = sampleData[key] or {message = "Sample data for " .. key}
                
                return {
                    exists = true,
                    type = "table",
                    size = 250,
                    preview = "Sample DataStore data",
                    data = data
                }
            end
        }
        debugLog("Created fallback DataStore Manager")
    end
    
    if dataStoreManager then
        explorer:setDataStoreManager(dataStoreManager)
        debugLog("DataStore Manager connected to explorer")
    end
    
    explorer:setUIManager(self)
    
    -- Register callback for when keys are loaded
    explorer:registerCallback("onKeysLoaded", function(keys)
        debugLog("Keys loaded callback triggered with " .. #keys .. " keys")
        self:updateKeyList(keys)
    end)
    
    local datastores = explorer:getDataStores()
    
    -- Update modern interface if available
    if self.explorerElements and self.explorerElements.datastoreList then
        self:updateDataStoreList(datastores)
    end
    
    debugLog("Loaded " .. #datastores .. " DataStores into explorer")
end

-- Select a DataStore and load its keys
function UIManager:selectDataStore(datastoreName)
    debugLog("Selecting DataStore: " .. datastoreName)
    
    if not self.services or not self.services["features.explorer.DataExplorer"] then
        return
    end
    
    local explorer = self.services["features.explorer.DataExplorer"]
    explorer:selectDataStore(datastoreName)
    
    -- Keys will be loaded automatically via callback - no need to manually call loadKeys
end

-- Load keys for selected DataStore
function UIManager:loadKeys()
    if not self.services or not self.services["features.explorer.DataExplorer"] then
        return
    end
    
    local explorer = self.services["features.explorer.DataExplorer"]
    local state = explorer:getState()
    
    if not self.explorerElements or not self.explorerElements.keyList then
        return
    end
    
    local keyList = self.explorerElements.keyList
    
    -- Clear existing items
    for _, child in ipairs(keyList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Add key buttons
    for i, keyInfo in ipairs(state.keys) do
        local button = Instance.new("TextButton")
        button.Name = keyInfo.key
        button.Size = UDim2.new(1, -10, 0, 30)
        button.Position = UDim2.new(0, 5, 0, (i-1) * 32)
        button.BackgroundColor3 = Constants.UI.THEME.COLORS.ACCENT
        button.BorderSizePixel = 1
        button.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
        button.Text = keyInfo.key
        button.Font = Constants.UI.THEME.FONTS.CODE
        button.TextSize = 11
        button.TextColor3 = Constants.UI.THEME.COLORS.TEXT
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Parent = keyList
        
        -- Add padding
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.Parent = button
        
        button.MouseButton1Click:Connect(function()
            self:selectKey(keyInfo.key)
        end)
    end
    
    -- Update scroll canvas
    keyList.CanvasSize = UDim2.new(0, 0, 0, #state.keys * 32)
    debugLog("Loaded " .. #state.keys .. " keys into explorer")
end

-- Update key list with callback data
function UIManager:updateKeyList(keys)
    debugLog("Updating key list with " .. #keys .. " keys")
    
    if not self.explorerElements or not self.explorerElements.keyList then
        debugLog("Key list element not found", "ERROR")
        return
    end
    
    local keyList = self.explorerElements.keyList
    
    -- Clear existing items
    for _, child in ipairs(keyList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Add key buttons
    for i, keyInfo in ipairs(keys) do
        local button = Instance.new("TextButton")
        button.Name = keyInfo.key
        button.Size = UDim2.new(1, -10, 0, 30)
        button.Position = UDim2.new(0, 5, 0, (i-1) * 32)
        button.BackgroundColor3 = Constants.UI.THEME.COLORS.ACCENT
        button.BorderSizePixel = 1
        button.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
        button.Text = keyInfo.key .. " (" .. keyInfo.lastModified .. ")"
        button.Font = Constants.UI.THEME.FONTS.CODE
        button.TextSize = 11
        button.TextColor3 = Constants.UI.THEME.COLORS.TEXT
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Parent = keyList
        
        -- Add padding
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.Parent = button
        
        button.MouseButton1Click:Connect(function()
            self:selectKey(keyInfo.key)
        end)
    end
    
    -- Update scroll canvas
    keyList.CanvasSize = UDim2.new(0, 0, 0, #keys * 32)
    debugLog("Updated key list display with " .. #keys .. " keys")
end

-- Select a key and display its data
function UIManager:selectKey(key)
    debugLog("Selecting key: " .. key)
    
    if not self.services or not self.services["features.explorer.DataExplorer"] then
        return
    end
    
    local explorer = self.services["features.explorer.DataExplorer"]
    explorer:selectKey(key)
    
    -- Display data
    task.spawn(function()
        wait(0.1) -- Allow for async loading
        self:displayKeyData()
    end)
end

-- Display data for selected key
function UIManager:displayKeyData()
    if not self.services or not self.services["features.explorer.DataExplorer"] then
        return
    end
    
    local explorer = self.services["features.explorer.DataExplorer"]
    local state = explorer:getState()
    
    if not self.explorerElements or not self.explorerElements.dataViewer then
        return
    end
    
    local dataViewer = self.explorerElements.dataViewer
    
    -- Clear existing content
    for _, child in ipairs(dataViewer:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    if not state.currentData then
        local noDataLabel = Instance.new("TextLabel")
        noDataLabel.Size = UDim2.new(1, -10, 0, 30)
        noDataLabel.Position = UDim2.new(0, 5, 0, 5)
        noDataLabel.BackgroundTransparency = 1
        noDataLabel.Text = "No data selected"
        noDataLabel.Font = Constants.UI.THEME.FONTS.BODY
        noDataLabel.TextSize = 14
        noDataLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
        noDataLabel.TextXAlignment = Enum.TextXAlignment.Center
        noDataLabel.Parent = dataViewer
        return
    end
    
    -- Display data info
    local dataInfo = state.currentData
    local formattedData = explorer:getFormattedData(dataInfo.data)
    
    -- Info label
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "InfoLabel"
    infoLabel.Size = UDim2.new(1, -10, 0, 60)
    infoLabel.Position = UDim2.new(0, 5, 0, 5)
    infoLabel.BackgroundColor3 = Constants.UI.THEME.COLORS.ACCENT
    infoLabel.BorderSizePixel = 1
    infoLabel.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
    infoLabel.Text = string.format("Type: %s\nSize: %d bytes\nExists: %s", 
        dataInfo.type, dataInfo.size, tostring(dataInfo.exists))
    infoLabel.Font = Constants.UI.THEME.FONTS.CODE
    infoLabel.TextSize = 12
    infoLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
    infoLabel.Parent = dataViewer
    
    -- Add padding to info label
    local infoPadding = Instance.new("UIPadding")
    infoPadding.PaddingLeft = UDim.new(0, 10)
    infoPadding.PaddingTop = UDim.new(0, 5)
    infoPadding.Parent = infoLabel
    
    -- Data display
    local dataLabel = Instance.new("TextLabel")
    dataLabel.Name = "DataLabel"
    dataLabel.Size = UDim2.new(1, -10, 0, math.max(200, #formattedData / 50 * 20))
    dataLabel.Position = UDim2.new(0, 5, 0, 75)
    dataLabel.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND
    dataLabel.BorderSizePixel = 1
    dataLabel.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
    dataLabel.Text = formattedData
    dataLabel.Font = Constants.UI.THEME.FONTS.CODE
    dataLabel.TextSize = 11
    dataLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT
    dataLabel.TextXAlignment = Enum.TextXAlignment.Left
    dataLabel.TextYAlignment = Enum.TextYAlignment.Top
    dataLabel.TextWrapped = true
    dataLabel.Parent = dataViewer
    
    -- Add padding to data label
    local dataPadding = Instance.new("UIPadding")
    dataPadding.PaddingLeft = UDim.new(0, 10)
    dataPadding.PaddingTop = UDim.new(0, 5)
    dataPadding.Parent = dataLabel
    
    -- Update scroll canvas
    dataViewer.CanvasSize = UDim2.new(0, 0, 0, 80 + dataLabel.Size.Y.Offset)
    debugLog("Displayed data for key: " .. (state.selectedKey or "unknown"))
end

-- Show Editor tab (placeholder for now)
function UIManager:showEditorTab()
    self:clearTabContent()
    
    local placeholderLabel = Instance.new("TextLabel")
    placeholderLabel.Name = "Placeholder"
    placeholderLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
    placeholderLabel.Position = UDim2.new(0.1, 0, 0.35, 0)
    placeholderLabel.BackgroundTransparency = 1
    placeholderLabel.Text = "📝 Data Editor\n\nComing in Phase 2.2!\nEdit and modify DataStore entries with validation."
    placeholderLabel.Font = Constants.UI.THEME.FONTS.BODY
    placeholderLabel.TextSize = 18
    placeholderLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    placeholderLabel.TextWrapped = true
    placeholderLabel.TextXAlignment = Enum.TextXAlignment.Center
    placeholderLabel.TextYAlignment = Enum.TextYAlignment.Center
    placeholderLabel.Parent = self.tabContent
end

-- Clear tab content
function UIManager:clearTabContent()
    if self.tabContent then
        for _, child in ipairs(self.tabContent:GetChildren()) do
            child:Destroy()
        end
    end
end

-- Generate services status text
function UIManager:generateServicesText()
    if not self.services then
        return "No services available"
    end
    
    local text = ""
    local serviceNames = {
        "shared.Constants", "shared.Utils", "shared.Types",
        "core.config.PluginConfig", "core.error.ErrorHandler", "core.logging.Logger",
        "core.licensing.LicenseManager", "core.data.DataStoreManager", "core.performance.PerformanceMonitor",
        "features.explorer.DataExplorer", "features.validation.SchemaValidator", 
        "features.analytics.PerformanceAnalyzer", "features.operations.BulkOperations"
    }
    
    for _, serviceName in ipairs(serviceNames) do
        if self.services[serviceName] then
            text = text .. "✅ " .. serviceName .. "\n"
        else
            text = text .. "❌ " .. serviceName .. "\n"
        end
    end
    
    return text
end

-- Test services connection (demo functionality)
function UIManager:testServicesConnection()
    debugLog("Testing services connection...")
    
    if self.services and self.services["core.data.DataStoreManager"] then
        self:setStatus("🔄 Testing DataStore connection...", Constants.UI.THEME.COLORS.WARNING)
        
        -- Simulate async operation
        task.wait(1)
        
        self:setStatus("✅ All services operational - Ready for DataStore operations!", Constants.UI.THEME.COLORS.SUCCESS)
        debugLog("Services connection test completed successfully")
    else
        self:setStatus("❌ DataStore Manager not available", Constants.UI.THEME.COLORS.ERROR)
        debugLog("Services connection test failed - DataStore Manager not found")
    end
end

-- Update status bar
function UIManager:setStatus(text, color)
    if self.statusLabel then
        self.statusLabel.Text = text
        self.statusLabel.TextColor3 = color or Constants.UI.THEME.COLORS.TEXT
    end
end

-- Refresh the interface
function UIManager:refresh()
    debugLog("Refreshing UI")
    
    -- Update status based on service states
    if self.services then
        local activeServices = 0
        local totalServices = 0
        
        for serviceName, service in pairs(self.services) do
            if serviceName ~= "_ui" then
                totalServices = totalServices + 1
                if service then
                    activeServices = activeServices + 1
                end
            end
        end
        
        self:setStatus(string.format("🟢 Ready - %d/%d services active", activeServices, totalServices))
    else
        self:setStatus("🟡 Limited functionality - No services available", Constants.UI.THEME.COLORS.WARNING)
    end
    
    debugLog("UI refresh complete")
end

-- Add a component
function UIManager:addComponent(name, component)
    if not name or not component then
        debugLog("Invalid component provided: " .. tostring(name), "ERROR")
        return false
    end
    
    self.components[name] = component
    debugLog("Component added: " .. name)
    return true
end

-- Remove a component
function UIManager:removeComponent(name)
    if not name or not self.components[name] then
        debugLog("Component not found: " .. tostring(name), "WARN")
        return false
    end
    
    local component = self.components[name]
    if component.destroy then
        component:destroy()
    end
    
    self.components[name] = nil
    debugLog("Component removed: " .. name)
    return true
end

-- Get a component
function UIManager:getComponent(name)
    return self.components[name]
end

-- Show/hide the interface
function UIManager:setVisible(visible)
    if self.mainFrame then
        self.mainFrame.Visible = visible
        debugLog("UI visibility set to: " .. tostring(visible))
    end
end

-- Handle widget closing
function UIManager:onClose()
    debugLog("UI closing")
    -- Cleanup or save state if needed
end

-- Cleanup
function UIManager:destroy()
    debugLog("Destroying UI Manager")
    
    -- Destroy all components
    for name, component in pairs(self.components) do
        if component.destroy then
            component:destroy()
        end
    end
    
    -- Clear references
    self.components = {}
    
    if self.mainFrame then
        self.mainFrame:Destroy()
        self.mainFrame = nil
    end
    
    self.initialized = false
    debugLog("UI Manager destroyed")
end

-- Placeholder views for other navigation items
function UIManager:showSchemaBuilderView()
    if not self.mainContentArea then return end
    
    -- Clear existing content
    for _, child in ipairs(self.mainContentArea:GetChildren()) do
        child:Destroy()
    end
    
    self:createPlaceholderView("🏗️ Schema Builder", "Build and validate data schemas for your DataStores.")
end

function UIManager:showAnalyticsView()
    if not self.mainContentArea then return end
    
    -- Clear existing content
    for _, child in ipairs(self.mainContentArea:GetChildren()) do
        child:Destroy()
    end
    
    self:createPlaceholderView("📊 Analytics", "View performance metrics and usage analytics for your DataStores.")
end

function UIManager:showSessionsView()
    if not self.mainContentArea then return end
    
    -- Clear existing content
    for _, child in ipairs(self.mainContentArea:GetChildren()) do
        child:Destroy()
    end
    
    self:createPlaceholderView("👥 Sessions", "Monitor active sessions and user data access patterns.")
end

function UIManager:showSecurityView()
    if not self.mainContentArea then return end
    
    -- Clear existing content
    for _, child in ipairs(self.mainContentArea:GetChildren()) do
        child:Destroy()
    end
    
    self:createPlaceholderView("🔒 Security", "Manage access controls and security settings for DataStore operations.")
end

function UIManager:showSettingsView()
    if not self.mainContentArea then return end
    
    -- Clear existing content
    for _, child in ipairs(self.mainContentArea:GetChildren()) do
        child:Destroy()
    end
    
    self:createPlaceholderView("⚙️ Settings", "Configure plugin preferences, themes, and advanced options.")
end

-- Create placeholder view for future features
function UIManager:createPlaceholderView(title, description)
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    header.BorderSizePixel = 0
    header.Parent = self.mainContentArea
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.XLARGE, 1, 0)
    titleLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.XLARGE, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.Font = Constants.UI.THEME.FONTS.HEADING
    titleLabel.TextSize = 24
    titleLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = header
    
    -- Content
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -60)
    content.Position = UDim2.new(0, 0, 0, 60)
    content.BackgroundTransparency = 1
    content.Parent = self.mainContentArea
    
    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.new(0.6, 0, 0.4, 0)
    card.Position = UDim2.new(0.2, 0, 0.3, 0)
    card.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    card.BorderSizePixel = 0
    card.Parent = content
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    cardCorner.Parent = card
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "Description"
    descLabel.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.XLARGE, 1, -Constants.UI.THEME.SPACING.XLARGE)
    descLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.XLARGE, 0, Constants.UI.THEME.SPACING.XLARGE)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description .. "\\n\\n🚧 This feature is coming soon in a future update."
    descLabel.Font = Constants.UI.THEME.FONTS.BODY
    descLabel.TextSize = 16
    descLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    descLabel.TextWrapped = true
    descLabel.TextXAlignment = Enum.TextXAlignment.Center
    descLabel.TextYAlignment = Enum.TextYAlignment.Center
    descLabel.Parent = card
end

-- Update DataStore list with modern cards
function UIManager:updateDataStoreList(datastores)
    if not self.explorerElements or not self.explorerElements.datastoreList then
        debugLog("Explorer elements not initialized", "ERROR")
        return
    end
    
    local datastoreList = self.explorerElements.datastoreList
    
    -- Clear existing items
    for _, child in ipairs(datastoreList:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("DataStoreCard") then
            child:Destroy()
        end
    end
    
    -- Add modern DataStore cards
    for i, datastoreName in ipairs(datastores) do
        local card = Instance.new("Frame")
        card.Name = "DataStoreCard_" .. datastoreName
        card.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.LARGE, 0, Constants.UI.THEME.SIZES.CARD_MIN_HEIGHT)
        card.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, (i-1) * (Constants.UI.THEME.SIZES.CARD_MIN_HEIGHT + Constants.UI.THEME.SPACING.SMALL) + Constants.UI.THEME.SPACING.MEDIUM)
        card.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
        card.BorderSizePixel = 1
        card.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
        card.Parent = datastoreList
        
        -- Card corner radius
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
        cardCorner.Parent = card
        
        -- DataStore icon
        local icon = Instance.new("TextLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, Constants.UI.THEME.SIZES.ICON_LARGE, 0, Constants.UI.THEME.SIZES.ICON_LARGE)
        icon.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE, 0, Constants.UI.THEME.SPACING.LARGE)
        icon.BackgroundTransparency = 1
        icon.Text = "📊"
        icon.Font = Constants.UI.THEME.FONTS.UI
        icon.TextSize = Constants.UI.THEME.SIZES.ICON_LARGE
        icon.TextColor3 = Constants.UI.THEME.COLORS.PRIMARY
        icon.TextXAlignment = Enum.TextXAlignment.Center
        icon.TextYAlignment = Enum.TextYAlignment.Center
        icon.Parent = card
        
        -- DataStore name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, -Constants.UI.THEME.SIZES.ICON_LARGE - Constants.UI.THEME.SPACING.LARGE * 3, 0, 20)
        nameLabel.Position = UDim2.new(0, Constants.UI.THEME.SIZES.ICON_LARGE + Constants.UI.THEME.SPACING.LARGE * 2, 0, Constants.UI.THEME.SPACING.LARGE)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = datastoreName
        nameLabel.Font = Constants.UI.THEME.FONTS.SUBHEADING
        nameLabel.TextSize = 16
        nameLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextYAlignment = Enum.TextYAlignment.Center
        nameLabel.Parent = card
        
        -- DataStore description
        local descLabel = Instance.new("TextLabel")
        descLabel.Name = "Description"
        descLabel.Size = UDim2.new(1, -Constants.UI.THEME.SIZES.ICON_LARGE - Constants.UI.THEME.SPACING.LARGE * 3, 0, 16)
        descLabel.Position = UDim2.new(0, Constants.UI.THEME.SIZES.ICON_LARGE + Constants.UI.THEME.SPACING.LARGE * 2, 0, Constants.UI.THEME.SPACING.LARGE + 22)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = "Click to explore data..."
        descLabel.Font = Constants.UI.THEME.FONTS.BODY
        descLabel.TextSize = 12
        descLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_MUTED
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Center
        descLabel.Parent = card
        
        -- Click button (invisible overlay)
        local clickButton = Instance.new("TextButton")
        clickButton.Name = "ClickButton"
        clickButton.Size = UDim2.new(1, 0, 1, 0)
        clickButton.Position = UDim2.new(0, 0, 0, 0)
        clickButton.BackgroundTransparency = 1
        clickButton.Text = ""
        clickButton.Parent = card
        
        -- Hover effects
        clickButton.MouseEnter:Connect(function()
            card.BackgroundColor3 = Constants.UI.THEME.COLORS.SIDEBAR_ITEM_HOVER
            card.BorderColor3 = Constants.UI.THEME.COLORS.PRIMARY
        end)
        
        clickButton.MouseLeave:Connect(function()
            card.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
            card.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
        end)
        
        -- Click handler
        clickButton.MouseButton1Click:Connect(function()
            self:selectModernDataStore(datastoreName, card)
        end)
    end
    
    -- Update scroll canvas
    local totalHeight = #datastores * (Constants.UI.THEME.SIZES.CARD_MIN_HEIGHT + Constants.UI.THEME.SPACING.SMALL) + Constants.UI.THEME.SPACING.LARGE
    datastoreList.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

-- Select DataStore with modern interface
function UIManager:selectModernDataStore(datastoreName, selectedCard)
    debugLog("Selecting DataStore: " .. datastoreName)
    
    -- Reset all cards
    if self.explorerElements and self.explorerElements.datastoreList then
        for _, child in ipairs(self.explorerElements.datastoreList:GetChildren()) do
            if child:IsA("Frame") and child.Name:find("DataStoreCard") then
                child.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
                child.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
            end
        end
    end
    
    -- Highlight selected card
    if selectedCard then
        selectedCard.BackgroundColor3 = Constants.UI.THEME.COLORS.SIDEBAR_ITEM_ACTIVE
        selectedCard.BorderColor3 = Constants.UI.THEME.COLORS.PRIMARY
    end
    
    -- Update preview title
    if self.explorerElements and self.explorerElements.previewTitle then
        self.explorerElements.previewTitle.Text = "📋 Data Preview - " .. datastoreName
    end
    
    -- Load DataStore data
    if not self.services or not self.services["features.explorer.DataExplorer"] then
        return
    end
    
    local explorer = self.services["features.explorer.DataExplorer"]
    explorer:selectDataStore(datastoreName)
    
    -- Load and display data in preview area
    self:loadDataStorePreview(datastoreName)
end

-- Load DataStore preview
function UIManager:loadDataStorePreview(datastoreName)
    if not self.explorerElements then
        return
    end
    
    -- Clear data preview
    if self.explorerElements.previewContent then
        self.explorerElements.previewContent.Text = "🔄 Loading keys for " .. datastoreName .. "..."
        self.explorerElements.previewContent.TextColor3 = Constants.UI.THEME.COLORS.STATUS_LOADING
    end
    
    -- Clear keys list
    if self.explorerElements.keysScroll then
        for _, child in ipairs(self.explorerElements.keysScroll:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
    end
    
    -- Load keys
    task.spawn(function()
        wait(0.3) -- Brief loading delay
        
        if not self.services or not self.services["features.explorer.DataExplorer"] then
            if self.explorerElements.previewContent then
                self.explorerElements.previewContent.Text = "❌ Explorer service not available"
                self.explorerElements.previewContent.TextColor3 = Constants.UI.THEME.COLORS.ERROR
            end
            return
        end
        
        local explorer = self.services["features.explorer.DataExplorer"]
        local state = explorer:getState()
        
        if #state.keys > 0 then
            -- Populate keys list
            self:populateKeysList(state.keys)
            
            -- Update data preview
            if self.explorerElements.previewContent then
                self.explorerElements.previewContent.Text = "📋 Found " .. #state.keys .. " keys in " .. datastoreName .. "\\n\\nClick on a key to view its data contents."
                self.explorerElements.previewContent.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
            end
        else
            if self.explorerElements.previewContent then
                self.explorerElements.previewContent.Text = "📭 No data found in " .. datastoreName .. "\\n\\nThis DataStore appears to be empty or has no accessible keys."
                self.explorerElements.previewContent.TextColor3 = Constants.UI.THEME.COLORS.TEXT_MUTED
            end
        end
    end)
end

-- Populate keys list with clickable buttons
function UIManager:populateKeysList(keys)
    if not self.explorerElements or not self.explorerElements.keysScroll then
        return
    end
    
    local keysScroll = self.explorerElements.keysScroll
    
    -- Clear existing keys
    for _, child in ipairs(keysScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Add key buttons
    for i, keyInfo in ipairs(keys) do
        local keyButton = Instance.new("TextButton")
        keyButton.Name = "KeyButton_" .. i
        keyButton.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.SMALL, 0, 28)
        keyButton.Position = UDim2.new(0, 0, 0, (i-1) * 32)
        keyButton.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
        keyButton.BorderSizePixel = 1
        keyButton.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
        keyButton.Text = ""
        keyButton.Parent = keysScroll
        
        -- Key button corner
        local keyCorner = Instance.new("UICorner")
        keyCorner.CornerRadius = UDim.new(0, 4)
        keyCorner.Parent = keyButton
        
        -- Key icon
        local keyIcon = Instance.new("TextLabel")
        keyIcon.Name = "Icon"
        keyIcon.Size = UDim2.new(0, 20, 1, 0)
        keyIcon.Position = UDim2.new(0, 8, 0, 0)
        keyIcon.BackgroundTransparency = 1
        keyIcon.Text = "🔑"
        keyIcon.Font = Constants.UI.THEME.FONTS.UI
        keyIcon.TextSize = 12
        keyIcon.TextColor3 = Constants.UI.THEME.COLORS.PRIMARY
        keyIcon.TextXAlignment = Enum.TextXAlignment.Center
        keyIcon.TextYAlignment = Enum.TextYAlignment.Center
        keyIcon.Parent = keyButton
        
        -- Key name
        local keyName = Instance.new("TextLabel")
        keyName.Name = "KeyName"
        keyName.Size = UDim2.new(1, -40, 1, 0)
        keyName.Position = UDim2.new(0, 32, 0, 0)
        keyName.BackgroundTransparency = 1
        keyName.Text = keyInfo.key
        keyName.Font = Constants.UI.THEME.FONTS.CODE
        keyName.TextSize = 11
        keyName.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
        keyName.TextXAlignment = Enum.TextXAlignment.Left
        keyName.TextYAlignment = Enum.TextYAlignment.Center
        keyName.TextTruncate = Enum.TextTruncate.AtEnd
        keyName.Parent = keyButton
        
        -- Hover effects
        keyButton.MouseEnter:Connect(function()
            keyButton.BackgroundColor3 = Constants.UI.THEME.COLORS.SIDEBAR_ITEM_HOVER
            keyButton.BorderColor3 = Constants.UI.THEME.COLORS.PRIMARY
        end)
        
        keyButton.MouseLeave:Connect(function()
            keyButton.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
            keyButton.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
        end)
        
        -- Click handler
        keyButton.MouseButton1Click:Connect(function()
            self:loadKeyData(keyInfo.key)
        end)
    end
    
    -- Update canvas size
    keysScroll.CanvasSize = UDim2.new(0, 0, 0, #keys * 32)
end

-- Load and display data for a specific key
function UIManager:loadKeyData(keyName)
    if not self.explorerElements or not self.explorerElements.previewContent or not self.explorerElements.dataScroll then
        return
    end
    
    local previewContent = self.explorerElements.previewContent
    local dataScroll = self.explorerElements.dataScroll
    
    -- Show loading state
    previewContent.Text = "🔄 Loading data for key: " .. keyName .. "..."
    previewContent.TextColor3 = Constants.UI.THEME.COLORS.STATUS_LOADING
    previewContent.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM, 0, 50)
    
    task.spawn(function()
        wait(0.2)
        
        if not self.services or not self.services["features.explorer.DataExplorer"] then
            previewContent.Text = "❌ Explorer service not available"
            previewContent.TextColor3 = Constants.UI.THEME.COLORS.ERROR
            return
        end
        
        local explorer = self.services["features.explorer.DataExplorer"]
        local state = explorer:getState()
        
        -- Find the key data
        for _, keyInfo in ipairs(state.keys) do
            if keyInfo.key == keyName then
                -- Load the actual data
                explorer:selectKey(keyName)
                local dataInfo = explorer:getSelectedData()
                
                if dataInfo and dataInfo.exists then
                    -- Create formatted data display
                    self:displayFormattedData(keyName, dataInfo)
                else
                    previewContent.Text = "❌ Failed to load data for key: " .. keyName
                    previewContent.TextColor3 = Constants.UI.THEME.COLORS.ERROR
                end
                break
            end
        end
    end)
end

-- Display formatted data with proper JSON syntax highlighting
function UIManager:displayFormattedData(keyName, dataInfo)
    if not self.explorerElements or not self.explorerElements.previewContent or not self.explorerElements.dataScroll then
        return
    end
    
    local previewContent = self.explorerElements.previewContent
    local dataScroll = self.explorerElements.dataScroll
    
    -- Clear existing content
    for _, child in ipairs(dataScroll:GetChildren()) do
        if child.Name ~= "PreviewContent" then
            child:Destroy()
        end
    end
    
    -- Header info
    local headerText = "📊 Data for: " .. keyName .. "\\n"
    headerText = headerText .. "📏 Type: " .. (dataInfo.type or "unknown") .. "\\n"
    headerText = headerText .. "📦 Size: " .. (dataInfo.size or 0) .. " bytes\\n"
    headerText = headerText .. "✅ Exists: " .. tostring(dataInfo.exists) .. "\\n\\n"
    
    previewContent.Text = headerText
    previewContent.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    previewContent.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM, 0, 80)
    
    -- JSON data display
    if dataInfo.data then
        local jsonDisplay = Instance.new("TextLabel")
        jsonDisplay.Name = "JSONDisplay"
        jsonDisplay.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM, 0, 400) -- Will be adjusted based on content
        jsonDisplay.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, 90)
        jsonDisplay.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
        jsonDisplay.BorderSizePixel = 1
        jsonDisplay.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
        jsonDisplay.Parent = dataScroll
        
        local jsonCorner = Instance.new("UICorner")
        jsonCorner.CornerRadius = UDim.new(0, 4)
        jsonCorner.Parent = jsonDisplay
        
        -- Format JSON with proper indentation
        local jsonText = self:formatJSONData(dataInfo.data)
        
        local jsonLabel = Instance.new("TextLabel")
        jsonLabel.Name = "JSONText"
        jsonLabel.Size = UDim2.new(1, -16, 1, -16)
        jsonLabel.Position = UDim2.new(0, 8, 0, 8)
        jsonLabel.BackgroundTransparency = 1
        jsonLabel.Text = jsonText
        jsonLabel.Font = Constants.UI.THEME.FONTS.CODE
        jsonLabel.TextSize = 11
        jsonLabel.TextColor3 = Constants.UI.THEME.COLORS.JSON_STRING
        jsonLabel.TextWrapped = true
        jsonLabel.TextXAlignment = Enum.TextXAlignment.Left
        jsonLabel.TextYAlignment = Enum.TextYAlignment.Top
        jsonLabel.Parent = jsonDisplay
        
        -- Adjust height based on content
        local lines = select(2, jsonText:gsub('\\n', '\\n')) + 1
        jsonDisplay.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM, 0, math.max(100, lines * 15 + 20))
        
        -- Update scroll canvas
        dataScroll.CanvasSize = UDim2.new(0, 0, 0, 90 + jsonDisplay.Size.Y.Offset + 20)
    else
        previewContent.Text = previewContent.Text .. "❌ No data content available"
        previewContent.TextColor3 = Constants.UI.THEME.COLORS.TEXT_MUTED
    end
end

-- Format JSON data with proper indentation
function UIManager:formatJSONData(data)
    local HttpService = game:GetService("HttpService")
    
    local success, jsonString = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    
    if success then
        -- Add basic indentation for readability
        local formatted = jsonString
        formatted = formatted:gsub('","', '",\\n  "')
        formatted = formatted:gsub('":{"', '": {\\n    "')
        formatted = formatted:gsub('"},"', '"}\\n  ,"')
        formatted = formatted:gsub('^{', '{\\n  ')
        formatted = formatted:gsub('}$', '\\n}')
        return formatted
    else
        return tostring(data)
    end
end

return UIManager 