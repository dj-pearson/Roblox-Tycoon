-- DataStore Plugin/init.luau

local plugin = plugin -- Use the global plugin variable
local toolbar = plugin:CreateToolbar("DataStore Manager Pro")
-- Custom logo for DataStore Manager Pro
local button = toolbar:CreateButton("Open DataStore Manager", "Open the DataStore Manager Pro Interface", "rbxassetid://131528729537417")

local DataStoreManager = require(script.DataStoreManager)
local DataExplorer = require(script.DataExplorer)
local PerformanceMonitor = require(script.PerformanceMonitor)
local SchemaManager = require(script.SchemaManager)
local SessionManager = require(script.SessionManager)
local CacheManager = require(script.CacheManager)
local SchemaValidator = require(script.SchemaValidator)
local SecurityManager = require(script.SecurityManager)
local DataVisualization = require(script.DataVisualization)
local StyleGuide = require(script.StyleGuide)
local SchemaEditor = require(script.SchemaEditor)
local MonitoringDashboard = require(script.MonitoringDashboard)
local MonitoringDashboardUI = require(script.MonitoringDashboardUI)
local DataMigrationTools = require(script.DataMigrationTools)
local MultiServerCoordination = require(script.MultiServerCoordination)
local MultiServerCoordinationUI = require(script.MultiServerCoordinationUI)
local PerformanceAnalyzer = require(script.PerformanceAnalyzer)
local PerformanceAnalyzerUI = require(script.PerformanceAnalyzerUI)
local CachingSystemUI = require(script.CachingSystemUI)
local LoadTesting = require(script.LoadTesting)
local LoadTestingUI = require(script.LoadTestingUI)
local CodeGenerator = require(script.CodeGenerator)
local CodeGeneratorUI = require(script.CodeGeneratorUI)

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
    
    -- Visualization functions
    createBarChart = DataVisualization.createBarChart,
    createLineChart = DataVisualization.createLineChart,
    createPieChart = DataVisualization.createPieChart,
    createTableView = DataVisualization.createTableView
}

return DataStoreManagerPlugin