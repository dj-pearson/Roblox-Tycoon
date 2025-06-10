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
    
    local self = setmetatable({}, UIManager)
    
    self.widget = widget
    self.services = services or {}
    self.pluginInfo = pluginInfo or {}
    self.components = {}
    self.initialized = false
    
    debugLog("Creating new UI Manager instance")
    
    -- Initialize the interface
    local success, error = pcall(function()
        self:initialize()
    end)
    
    if not success then
        debugLog("UI Manager initialization failed: " .. tostring(error), "ERROR")
        return nil
    end
    
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
    
    debugLog("Initializing UI Manager")
    
    -- Create main frame
    self:createMainFrame()
    
    -- Setup basic layout
    self:setupLayout()
    
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
    self.mainFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.Parent = self.widget
    
    -- Title bar
    self.titleBar = Instance.new("Frame")
    self.titleBar.Name = "TitleBar"
    self.titleBar.Size = UDim2.new(1, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    self.titleBar.Position = UDim2.new(0, 0, 0, 0)
    self.titleBar.BackgroundColor3 = Constants.UI.THEME.COLORS.SURFACE
    self.titleBar.BorderSizePixel = 1
    self.titleBar.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
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
    self.titleLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT
    self.titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.titleLabel.Parent = self.titleBar
    
    -- Content area
    self.contentArea = Instance.new("Frame")
    self.contentArea.Name = "ContentArea"
    self.contentArea.Size = UDim2.new(1, 0, 1, -(Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT + Constants.UI.THEME.SIZES.STATUSBAR_HEIGHT))
    self.contentArea.Position = UDim2.new(0, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    self.contentArea.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND
    self.contentArea.BorderSizePixel = 0
    self.contentArea.Parent = self.mainFrame
    
    -- Status bar
    self.statusBar = Instance.new("Frame")
    self.statusBar.Name = "StatusBar"
    self.statusBar.Size = UDim2.new(1, 0, 0, Constants.UI.THEME.SIZES.STATUSBAR_HEIGHT)
    self.statusBar.Position = UDim2.new(0, 0, 1, -Constants.UI.THEME.SIZES.STATUSBAR_HEIGHT)
    self.statusBar.BackgroundColor3 = Constants.UI.THEME.COLORS.SURFACE
    self.statusBar.BorderSizePixel = 1
    self.statusBar.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
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
    self.statusLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT
    self.statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.statusLabel.Parent = self.statusBar
    
    debugLog("Main frame created successfully")
end

-- Setup the basic layout
function UIManager:setupLayout()
    debugLog("Setting up basic layout")
    
    -- Create main content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, 0, 1, 0)
    contentContainer.Position = UDim2.new(0, 0, 0, 0)
    contentContainer.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = self.contentArea
    
    -- Create tab system
    self:createTabSystem(contentContainer)
    
    debugLog("Professional layout setup complete")
end

-- Create tab system for different features
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

-- Show Explorer tab
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
    if not self.services or not self.services["features.explorer.DataExplorer"] then
        debugLog("Data Explorer service not available", "ERROR")
        return
    end
    
    local explorer = self.services["features.explorer.DataExplorer"]
    
    -- Set up service references
    if self.services["core.data.DataStoreManager"] then
        explorer:setDataStoreManager(self.services["core.data.DataStoreManager"])
    end
    explorer:setUIManager(self)
    
    local datastores = explorer:getDataStores()
    
    if not self.explorerElements or not self.explorerElements.datastoreList then
        debugLog("Explorer elements not initialized", "ERROR")
        return
    end
    
    local datastoreList = self.explorerElements.datastoreList
    
    -- Clear existing items
    for _, child in ipairs(datastoreList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Add DataStore buttons
    for i, datastoreName in ipairs(datastores) do
        local button = Instance.new("TextButton")
        button.Name = datastoreName
        button.Size = UDim2.new(1, -10, 0, 30)
        button.Position = UDim2.new(0, 5, 0, (i-1) * 32)
        button.BackgroundColor3 = Constants.UI.THEME.COLORS.ACCENT
        button.BorderSizePixel = 1
        button.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
        button.Text = datastoreName
        button.Font = Constants.UI.THEME.FONTS.BODY
        button.TextSize = 12
        button.TextColor3 = Constants.UI.THEME.COLORS.TEXT
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Parent = datastoreList
        
        -- Add padding
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.Parent = button
        
        button.MouseButton1Click:Connect(function()
            self:selectDataStore(datastoreName)
        end)
    end
    
    -- Update scroll canvas
    datastoreList.CanvasSize = UDim2.new(0, 0, 0, #datastores * 32)
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
    
    -- Load keys
    task.spawn(function()
        wait(0.1) -- Allow for async loading
        self:loadKeys()
    end)
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

return UIManager 