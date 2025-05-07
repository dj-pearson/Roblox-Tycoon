-- DataStore Plugin/init.luau

-- Plugin version information (helps with testing in Argon)
local PluginVersion = "1.0.0"

-- Check if we're running in plugin context or under Argon
local runningInPluginContext = typeof(plugin) == "Plugin"

-- Setup plugin UI if we're in plugin context
local toolbar, button
if runningInPluginContext then
    toolbar = plugin:CreateToolbar("DataStore Manager Pro")
    -- Custom logo for DataStore Manager Pro
    button = toolbar:CreateButton("Open DataStore Manager", "Open the DataStore Manager Pro Interface", "rbxassetid://7634658388")
else
    -- We're likely running in Argon or another test environment
    print("DataStore Manager Pro plugin running in non-plugin context (possibly Argon)")
end

local DataStoreManager = require(script:FindFirstChild("DataStoreManager"))
local DataExplorer = require(script:FindFirstChild("DataExplorer"))
local PerformanceMonitor = require(script:FindFirstChild("PerformanceMonitor"))
local SchemaManager = require(script:FindFirstChild("SchemaManager"))
local SessionManager = require(script:FindFirstChild("SessionManager"))
local CacheManager = require(script:FindFirstChild("CacheManager"))
local SchemaValidator = require(script:FindFirstChild("SchemaValidator"))
local SecurityManager = require(script:FindFirstChild("SecurityManager"))
local DataVisualization = require(script:FindFirstChild("DataVisualization"))
local StyleGuide = require(script:FindFirstChild("StyleGuide"))
local SchemaEditor = require(script:FindFirstChild("SchemaEditor"))
local MonitoringDashboard = require(script:FindFirstChild("MonitoringDashboard"))
local MonitoringDashboardUI = require(script:FindFirstChild("MonitoringDashboardUI"))
local DataMigrationTools = require(script:FindFirstChild("DataMigrationTools"))
local MultiServerCoordination = require(script:FindFirstChild("MultiServerCoordination"))
local MultiServerCoordinationUI = require(script:FindFirstChild("MultiServerCoordinationUI"))
local PerformanceAnalyzer = require(script:FindFirstChild("PerformanceAnalyzer"))
local PerformanceAnalyzerUI = require(script:FindFirstChild("PerformanceAnalyzerUI"))
local CachingSystemUI = require(script:FindFirstChild("CachingSystemUI"))
local LoadTesting = require(script:FindFirstChild("LoadTesting"))
local LoadTestingUI = require(script:FindFirstChild("LoadTestingUI"))
local CodeGenerator = require(script:FindFirstChild("CodeGenerator"))
local CodeGeneratorUI = require(script:FindFirstChild("CodeGeneratorUI"))
local APIIntegration = require(script:FindFirstChild("APIIntegration"))
local APIIntegrationUI = require(script:FindFirstChild("APIIntegrationUI"))
local AccessControl = require(script:FindFirstChild("AccessControl"))
local AccessControlUI = require(script:FindFirstChild("AccessControlUI"))

-- Define the internal state
local widgetInfo = DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Right,
    false,
    false,
    800,
    600,
    800,
    600
)

local widget = plugin:CreateDockWidgetPluginGui("DataStoreManagerWidget", widgetInfo)
widget.Title = "DataStore Manager Pro"

-- Initialize the plugin components
DataStoreManager.initialize()
MonitoringDashboard.initialize()
MonitoringDashboardUI.initialize()
DataMigrationTools:initialize()
MultiServerCoordination.initialize()
MultiServerCoordinationUI.initialize()
PerformanceAnalyzer.initialize()
PerformanceAnalyzerUI.initialize()
CachingSystemUI.initialize()
CodeGenerator.initialize()
CodeGeneratorUI.initialize()
APIIntegration.initialize()
APIIntegrationUI.initialize()
AccessControl.initialize()
AccessControlUI.initialize()

-- Set up event handlers
button.Click:Connect(function()
    widget.Enabled = not widget.Enabled
      if widget.Enabled and widget:FindFirstChild("DataStoreExplorerFrame") == nil then
        -- Create the main GUI
        local mainFrame = DataExplorer.createMainGui(widget)
        mainFrame.Parent = widget
        
        -- Initialize UI components
        DataExplorer.initBulkOperationsUI()
        DataExplorer.initMonitoringDashboardUI()
        DataExplorer.initDataMigrationUI()
        DataExplorer.initMultiServerCoordinationUI()
        DataExplorer.initPerformanceAnalyzerUI()
        DataExplorer.initCachingSystemUI()
        DataExplorer.initLoadTestingUI()
        DataExplorer.initCodeGeneratorUI()
        DataExplorer.initAPIIntegrationUI()
        DataExplorer.initAccessControlUI()
        
        -- Update performance data at intervals
        task.spawn(function() -- Using task.spawn instead of spawn (deprecated)
            while widget.Enabled do
                DataExplorer.updatePerformanceUI()
                DataExplorer.updateLockStatusUI()
                DataExplorer.updateCacheViewerUI()
                task.wait(5) -- Update every 5 seconds, using task.wait instead of wait
            end
        end)
    end
end)

-- Expose the API for external usage
local DataStoreManagerPlugin = {
    DataStoreManager = DataStoreManager,
    SchemaManager = SchemaManager,
    SchemaValidator = SchemaValidator,
    DataVisualization = DataVisualization,
    SchemaEditor = SchemaEditor,
    StyleGuide = StyleGuide,
    DataMigrationTools = DataMigrationTools,
    MultiServerCoordination = MultiServerCoordination,
    
    -- Convenience functions for external access
    getData = DataStoreManager.getData,
    setData = DataStoreManager.setData,
    updateData = DataStoreManager.updateData,
    removeData = DataStoreManager.removeData,
    listKeys = DataStoreManager.listKeys,
    
    -- Schema functions
    validateData = SchemaValidator.validate,
    createSchema = SchemaManager.saveSchema,
    loadSchema = SchemaManager.loadSchema,
    
    -- Performance monitoring
    getPerformanceData = PerformanceMonitor.getPerformanceData,
    getOperationSummary = PerformanceMonitor.getOperationSummary,
    
    -- Migration functions
    migrateKey = DataMigrationTools.migrateKey,
    migrateDataStore = DataMigrationTools.migrateDataStore,
    getMigrationStatus = DataMigrationTools.getMigrationStatus,
    
    -- Server coordination functions
    requestDistributedLock = MultiServerCoordination.requestDistributedLock,
    releaseDistributedLock = MultiServerCoordination.releaseDistributedLock,
    getActiveServers = MultiServerCoordination.getActiveServers,
    
    -- Caching functions
    getCacheAnalytics = CacheManager.getCacheAnalytics,
    getCacheContents = CacheManager.getCacheContents,
    optimizeCache = CacheManager.optimizeCache,
    preloadData = CacheManager.preloadData,
    
    -- Code generation functions
    generateCode = CodeGenerator.generateModuleFromSchema,
    getTemplates = function(moduleType) return CodeGenerator.templates[moduleType or "module"] end,
    
    -- API Integration functions
    configureWebhook = APIIntegration.configureWebhook,
    triggerWebhook = APIIntegration.triggerWebhook,
    configureOpenCloudAPI = APIIntegration.configureOpenCloudAPI,
    getWebhooks = APIIntegration.getWebhooks,
    
    -- Visualization functions
    createBarChart = DataVisualization.createBarChart,
    createLineChart = DataVisualization.createLineChart,
    createPieChart = DataVisualization.createPieChart,
    createTableView = DataVisualization.createTableView,
    
    -- Version information (useful for testing with Argon)
    Version = PluginVersion or "1.0.0"
}

-- If we're running in Argon or another test environment, print some debug info
if not runningInPluginContext then
    print("DataStore Manager Pro loaded successfully in non-plugin context")
    print("Plugin Version:", DataStoreManagerPlugin.Version)
    print("Available modules:", #DataStoreManagerPlugin > 0 and "Yes" or "No")
end

return DataStoreManagerPlugin