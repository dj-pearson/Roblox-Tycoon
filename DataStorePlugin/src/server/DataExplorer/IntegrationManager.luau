--[[
    IntegrationManager - DataExplorer Integration Manager
    Handles integration with various tools and systems
]]

-- Safe module resolver
local function safeRequire(moduleName)
    local success, result = pcall(function()
        return require(script.Parent.Parent:FindFirstChild(moduleName))
    end)
    return success and result or {}
end

-- Import integration modules
local BulkOperationsUI = safeRequire("BulkOperationsUI")
local SchemaBuilderUI = safeRequire("SchemaBuilderUI")
local DataMigrationUI = safeRequire("DataMigrationUI")
local MonitoringDashboard = safeRequire("MonitoringDashboard")
local MultiServerCoordinationUI = safeRequire("MultiServerCoordinationUI")
local PerformanceAnalyzerUI = safeRequire("PerformanceAnalyzerUI")
local CachingSystemUI = safeRequire("CachingSystemUI")
local LoadTestingUI = safeRequire("LoadTestingUI")
local CodeGeneratorUI = safeRequire("CodeGeneratorUI")
local APIIntegrationUI = safeRequire("APIIntegrationUI")
local AccessControlUI = safeRequire("AccessControlUI")

-- Import integration modules if they exist
local CachingSystemIntegration = safeRequire("CachingSystemIntegration")
local LoadTestingIntegration = safeRequire("LoadTestingIntegration")
local CodeGeneratorIntegration = safeRequire("CodeGeneratorIntegration")
local APIIntegrationIntegration = safeRequire("APIIntegrationIntegration")
local AccessControlIntegration = safeRequire("AccessControlIntegration")
local MultiServerCoordinationIntegration = safeRequire("MultiServerCoordinationIntegration")
local PerformanceAnalyzerIntegration = safeRequire("PerformanceAnalyzerIntegration")

local IntegrationManager = {}
local DataExplorer = nil

-- Initialize the module
function IntegrationManager.initialize(dataExplorerRef)
    DataExplorer = dataExplorerRef
    print("IntegrationManager: Initialized")
end

-- Helper function to create integration buttons
local function createIntegrationButton(text, position, backgroundColor, mainFrame)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 150, 0, 28)
    button.Position = position
    button.BackgroundColor3 = backgroundColor
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSansSemibold
    button.TextSize = 14
    button.ZIndex = 5
    button.Parent = mainFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = button
    
    return button
end

-- Helper function to toggle UI containers
local function toggleContainer(container, button, containerName, otherContainers)
    local contentPane = DataExplorer.contentPane
    local navPane = DataExplorer.navigationPane
    
    if container.Visible then
        -- Hide this container and show normal UI
        container.Visible = false
        if contentPane then contentPane.Visible = true end
        if navPane then navPane.Visible = true end
        button.Text = containerName
        button.BackgroundColor3 = button:GetAttribute("OriginalColor") or Color3.fromRGB(60, 120, 200)
    else
        -- Show this container and hide normal UI
        container.Visible = true
        if contentPane then contentPane.Visible = false end
        if navPane then navPane.Visible = false end
        button.Text = "Back to Explorer"
        button.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
        
        -- Hide all other containers
        for _, otherContainer in pairs(otherContainers) do
            if otherContainer and otherContainer ~= container then
                otherContainer.Visible = false
            end
        end
    end
end

-- Initialize Bulk Operations UI
function IntegrationManager.initBulkOperationsUI()
    local mainFrame = DataExplorer.mainFrame
    if not mainFrame then return end
    
    local bulkOperationsButton = createIntegrationButton(
        "Bulk Operations",
        UDim2.new(1, -160, 0, 10),
        Color3.fromRGB(60, 120, 200),
        mainFrame
    )
    bulkOperationsButton:SetAttribute("OriginalColor", Color3.fromRGB(60, 120, 200))
    
    DataExplorer.bulkOperationsButton = bulkOperationsButton
    
    -- Create the bulk operations container
    local bulkOperationsContainer = BulkOperationsUI.createTab and BulkOperationsUI.createTab(mainFrame) or Instance.new("Frame")
    DataExplorer.bulkOperationsContainer = bulkOperationsContainer
    
    -- Toggle visibility when button is clicked
    bulkOperationsButton.MouseButton1Click:Connect(function()
        local otherContainers = {
            DataExplorer.schemaBuilderContainer,
            DataExplorer.monitoringDashboardContainer,
            DataExplorer.dataMigrationContainer,
            DataExplorer.coordinationContainer,
            DataExplorer.performanceAnalyzerContainer,
            DataExplorer.cachingSystemContainer,
            DataExplorer.loadTestingContainer,
            DataExplorer.codeGeneratorContainer,
            DataExplorer.apiIntegrationContainer,
            DataExplorer.accessControlContainer
        }
        toggleContainer(bulkOperationsContainer, bulkOperationsButton, "Bulk Operations", otherContainers)
    end)
end

-- Initialize Monitoring Dashboard UI
function IntegrationManager.initMonitoringDashboardUI()
    local mainFrame = DataExplorer.mainFrame
    if not mainFrame then return end
    
    local monitoringButton = createIntegrationButton(
        "Monitoring",
        UDim2.new(1, -450, 0, 10),
        Color3.fromRGB(142, 68, 173),
        mainFrame
    )
    monitoringButton:SetAttribute("OriginalColor", Color3.fromRGB(142, 68, 173))
    
    -- Create monitoring dashboard container
    local monitoringDashboardContainer = Instance.new("Frame")
    monitoringDashboardContainer.Size = UDim2.new(1, 0, 1, 0)
    monitoringDashboardContainer.Position = UDim2.new(0, 0, 0, 0)
    monitoringDashboardContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    monitoringDashboardContainer.Visible = false
    monitoringDashboardContainer.Name = "MonitoringDashboardContainer"
    monitoringDashboardContainer.Parent = mainFrame
    DataExplorer.monitoringDashboardContainer = monitoringDashboardContainer
    
    -- Create the monitoring dashboard
    if MonitoringDashboard.createDashboardUI then
        MonitoringDashboard.createDashboardUI(monitoringDashboardContainer)
    end
    
    -- Toggle visibility
    monitoringButton.MouseButton1Click:Connect(function()
        local otherContainers = {
            DataExplorer.bulkOperationsContainer,
            DataExplorer.schemaBuilderContainer,
            DataExplorer.dataMigrationContainer,
            DataExplorer.coordinationContainer,
            DataExplorer.performanceAnalyzerContainer,
            DataExplorer.cachingSystemContainer,
            DataExplorer.loadTestingContainer,
            DataExplorer.codeGeneratorContainer,
            DataExplorer.apiIntegrationContainer,
            DataExplorer.accessControlContainer
        }
        toggleContainer(monitoringDashboardContainer, monitoringButton, "Monitoring", otherContainers)
    end)
end

-- Initialize Data Migration UI
function IntegrationManager.initDataMigrationUI()
    local mainFrame = DataExplorer.mainFrame
    if not mainFrame then return end
    
    local dataMigrationButton = createIntegrationButton(
        "Data Migration",
        UDim2.new(1, -160, 0, 50),
        Color3.fromRGB(142, 145, 250),
        mainFrame
    )
    dataMigrationButton:SetAttribute("OriginalColor", Color3.fromRGB(142, 145, 250))
    
    -- Create the data migration container
    local dataMigrationContainer = DataMigrationUI.createTab and DataMigrationUI.createTab(mainFrame) or Instance.new("Frame")
    DataExplorer.dataMigrationContainer = dataMigrationContainer
    
    -- Toggle visibility
    dataMigrationButton.MouseButton1Click:Connect(function()
        local otherContainers = {
            DataExplorer.bulkOperationsContainer,
            DataExplorer.schemaBuilderContainer,
            DataExplorer.monitoringDashboardContainer,
            DataExplorer.coordinationContainer,
            DataExplorer.performanceAnalyzerContainer,
            DataExplorer.cachingSystemContainer,
            DataExplorer.loadTestingContainer,
            DataExplorer.codeGeneratorContainer,
            DataExplorer.apiIntegrationContainer,
            DataExplorer.accessControlContainer
        }
        toggleContainer(dataMigrationContainer, dataMigrationButton, "Data Migration", otherContainers)
    end)
end

-- Initialize Multi-Server Coordination UI
function IntegrationManager.initMultiServerCoordinationUI()
    if MultiServerCoordinationIntegration and MultiServerCoordinationIntegration.initMultiServerCoordinationUI then
        MultiServerCoordinationIntegration.initMultiServerCoordinationUI(DataExplorer)
    else
        local mainFrame = DataExplorer.mainFrame
        if not mainFrame then return end
        
        local coordinationButton = createIntegrationButton(
            "Server Coordination",
            UDim2.new(1, -600, 0, 10),
            Color3.fromRGB(52, 152, 219),
            mainFrame
        )
        coordinationButton:SetAttribute("OriginalColor", Color3.fromRGB(52, 152, 219))
        
        -- Create coordination container
        local coordinationContainer = Instance.new("Frame")
        coordinationContainer.Size = UDim2.new(1, 0, 1, 0)
        coordinationContainer.Position = UDim2.new(0, 0, 0, 0)
        coordinationContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        coordinationContainer.Visible = false
        coordinationContainer.Name = "MultiServerCoordinationContainer"
        coordinationContainer.Parent = mainFrame
        DataExplorer.coordinationContainer = coordinationContainer
        
        -- Create the UI
        if MultiServerCoordinationUI.createUI then
            MultiServerCoordinationUI.createUI(coordinationContainer)
        end
        
        -- Toggle visibility
        coordinationButton.MouseButton1Click:Connect(function()
            local otherContainers = {
                DataExplorer.bulkOperationsContainer,
                DataExplorer.schemaBuilderContainer,
                DataExplorer.monitoringDashboardContainer,
                DataExplorer.dataMigrationContainer,
                DataExplorer.performanceAnalyzerContainer,
                DataExplorer.cachingSystemContainer,
                DataExplorer.loadTestingContainer,
                DataExplorer.codeGeneratorContainer,
                DataExplorer.apiIntegrationContainer,
                DataExplorer.accessControlContainer
            }
            toggleContainer(coordinationContainer, coordinationButton, "Server Coordination", otherContainers)
        end)
    end
end

-- Initialize Performance Analyzer UI
function IntegrationManager.initPerformanceAnalyzerUI()
    if PerformanceAnalyzerIntegration and PerformanceAnalyzerIntegration.initPerformanceAnalyzerUI then
        PerformanceAnalyzerIntegration.initPerformanceAnalyzerUI(DataExplorer)
    else
        local mainFrame = DataExplorer.mainFrame
        if not mainFrame then return end
        
        local performanceButton = createIntegrationButton(
            "Performance Analyzer",
            UDim2.new(1, -450, 0, 10),
            Color3.fromRGB(155, 89, 182),
            mainFrame
        )
        performanceButton:SetAttribute("OriginalColor", Color3.fromRGB(155, 89, 182))
        
        -- Create performance analyzer container
        local performanceContainer = Instance.new("Frame")
        performanceContainer.Size = UDim2.new(1, 0, 1, 0)
        performanceContainer.Position = UDim2.new(0, 0, 0, 0)
        performanceContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        performanceContainer.Visible = false
        performanceContainer.Name = "PerformanceAnalyzerContainer"
        performanceContainer.Parent = mainFrame
        DataExplorer.performanceAnalyzerContainer = performanceContainer
        
        -- Create the UI
        if PerformanceAnalyzerUI.createUI then
            PerformanceAnalyzerUI.createUI(performanceContainer)
        end
        
        -- Toggle visibility
        performanceButton.MouseButton1Click:Connect(function()
            local otherContainers = {
                DataExplorer.bulkOperationsContainer,
                DataExplorer.schemaBuilderContainer,
                DataExplorer.monitoringDashboardContainer,
                DataExplorer.dataMigrationContainer,
                DataExplorer.coordinationContainer,
                DataExplorer.cachingSystemContainer,
                DataExplorer.loadTestingContainer,
                DataExplorer.codeGeneratorContainer,
                DataExplorer.apiIntegrationContainer,
                DataExplorer.accessControlContainer
            }
            toggleContainer(performanceContainer, performanceButton, "Performance Analyzer", otherContainers)
        end)
    end
end

-- Initialize Caching System UI
function IntegrationManager.initCachingSystemUI()
    if CachingSystemIntegration and CachingSystemIntegration.initCachingSystemUI then
        CachingSystemIntegration.initCachingSystemUI(DataExplorer)
    else
        warn("CachingSystemIntegration module or initCachingSystemUI function not found")
    end
end

-- Initialize Load Testing UI
function IntegrationManager.initLoadTestingUI()
    if LoadTestingIntegration and LoadTestingIntegration.initLoadTestingUI then
        LoadTestingIntegration.initLoadTestingUI(DataExplorer)
    else
        warn("LoadTestingIntegration module or initLoadTestingUI function not found")
    end
end

-- Initialize Code Generator UI
function IntegrationManager.initCodeGeneratorUI()
    if CodeGeneratorIntegration and CodeGeneratorIntegration.initCodeGeneratorUI then
        CodeGeneratorIntegration.initCodeGeneratorUI(DataExplorer)
    else
        warn("CodeGeneratorIntegration module or initCodeGeneratorUI function not found")
    end
end

-- Initialize API Integration UI
function IntegrationManager.initAPIIntegrationUI()
    if APIIntegrationIntegration and APIIntegrationIntegration.initAPIIntegrationUI then
        APIIntegrationIntegration.initAPIIntegrationUI(DataExplorer)
    else
        warn("APIIntegrationIntegration module or initAPIIntegrationUI function not found")
    end
end

-- Initialize Access Control UI
function IntegrationManager.initAccessControlUI()
    if AccessControlIntegration and AccessControlIntegration.initialize then
        AccessControlIntegration.initialize(DataExplorer)
    else
        warn("AccessControlIntegration module or initialize function not found")
    end
end

return IntegrationManager 