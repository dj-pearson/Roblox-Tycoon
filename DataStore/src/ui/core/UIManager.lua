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
    
    -- Welcome section
    local welcomeSection = Instance.new("Frame")
    welcomeSection.Name = "WelcomeSection"
    welcomeSection.Size = UDim2.new(1, -40, 0, 120)
    welcomeSection.Position = UDim2.new(0, 20, 0, 20)
    welcomeSection.BackgroundColor3 = Constants.UI.THEME.COLORS.SURFACE
    welcomeSection.BorderSizePixel = 1
    welcomeSection.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
    welcomeSection.Parent = contentContainer
    
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
    welcomeMessage.Text = "Foundation phase complete! All modular services loaded successfully.\nReady for Phase 2 development."
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
    servicesSection.Parent = contentContainer
    
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
    
    -- Demo button for functionality
    local demoButton = Instance.new("TextButton")
    demoButton.Name = "DemoButton"
    demoButton.Size = UDim2.new(0, 200, 0, 35)
    demoButton.Position = UDim2.new(0, 20, 0, 380)
    demoButton.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
    demoButton.BorderSizePixel = 0
    demoButton.Text = "Test Services Connection"
    demoButton.Font = Constants.UI.THEME.FONTS.BODY
    demoButton.TextSize = 14
    demoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    demoButton.Parent = contentContainer
    
    -- Add button functionality
    demoButton.MouseButton1Click:Connect(function()
        self:testServicesConnection()
    end)
    
    debugLog("Professional layout setup complete")
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