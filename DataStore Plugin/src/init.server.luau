-- DataStore Plugin/init.luau

-- Plugin version information (helps with testing in Argon)
local PluginVersion = "1.0.0"

-- Check if we're running in plugin context or under Argon
local runningInPluginContext = typeof(plugin) == "Plugin"

-- Create a module resolver to handle both local and cloud environments
local moduleCache = {}

local function resolveModule(moduleName)
    if moduleCache[moduleName] then
        return moduleCache[moduleName]
    end
    
    -- First try to require from script.Parent (correct for this structure)
    local success, result = pcall(function()
        return require(script.Parent:FindFirstChild(moduleName))
    end)
    
    if success and result then
        moduleCache[moduleName] = result
        return result
    end
    
    -- If that fails, try alternative methods (e.g. direct child - less likely)
    warn("Failed to load module from Parent: " .. moduleName .. ". Trying script child...")
    success, result = pcall(function()
        return require(script:FindFirstChild(moduleName))
    end)

    if success and result then
        moduleCache[moduleName] = result
        return result
    end

    -- Last resort - try to require by string name (works in some cloud environments)
    warn("Failed to load module as script child: " .. moduleName .. ". Trying string require...")
    success, result = pcall(function()
        -- This might work in cloud environment
        return require(moduleName)
    end)
    
    if success and result then
        moduleCache[moduleName] = result
        return result
    end
    
    warn("Failed to resolve module: " .. moduleName)
    
    -- Return a dummy module with basic functions to prevent errors
    local dummyModule = {
        initialize = function() 
            warn("Using dummy implementation of " .. moduleName .. ".initialize()") 
            return true 
        end,
        createUI = function() 
            warn("Using dummy implementation of " .. moduleName .. ".createUI()") 
            return Instance.new("Frame") 
        end
    }
    
    moduleCache[moduleName] = dummyModule
    return dummyModule
end

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

-- Use our resolver to require modules
local DataStoreManager = resolveModule("DataStoreManager")
local DataExplorer = resolveModule("DataExplorer")
local PerformanceMonitor = resolveModule("PerformanceMonitor")
local SchemaManager = resolveModule("SchemaManager")
local SessionManager = resolveModule("SessionManager")
local CacheManager = resolveModule("CacheManager")
local SchemaValidator = resolveModule("SchemaValidator")
local SecurityManager = resolveModule("SecurityManager")
local DataVisualization = resolveModule("DataVisualization")
local StyleGuide = resolveModule("StyleGuide")
local SchemaEditor = resolveModule("SchemaEditor")
local MonitoringDashboard = resolveModule("MonitoringDashboard")
local MonitoringDashboardUI = resolveModule("MonitoringDashboardUI")
local DataMigrationTools = resolveModule("DataMigrationTools")
local MultiServerCoordination = resolveModule("MultiServerCoordination")
local MultiServerCoordinationUI = resolveModule("MultiServerCoordinationUI")
local MultiServerCoordinationIntegration = resolveModule("MultiServerCoordinationIntegration")
local PerformanceAnalyzer = resolveModule("PerformanceAnalyzer")
local PerformanceAnalyzerUI = resolveModule("PerformanceAnalyzerUI")
local PerformanceAnalyzerIntegration = resolveModule("PerformanceAnalyzerIntegration")
local CachingSystemUI = resolveModule("CachingSystemUI")
local LoadTesting = resolveModule("LoadTesting")
local LoadTestingUI = resolveModule("LoadTestingUI")
local CodeGenerator = resolveModule("CodeGenerator")
local CodeGeneratorUI = resolveModule("CodeGeneratorUI")
local APIIntegration = resolveModule("APIIntegration")
local APIIntegrationUI = resolveModule("APIIntegrationUI")
local AccessControl = resolveModule("AccessControl")
local AccessControlUI = resolveModule("AccessControlUI")

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
DataMigrationTools:initialize() -- Note: This uses a colon, ensure this is intended.
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
MultiServerCoordinationIntegration.initialize()
PerformanceAnalyzerIntegration.initialize()

-- Set up event handlers
if button then -- Check if button exists before connecting
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
                while widget.Enabled and widget.Parent do -- Added check for widget.Parent to ensure it's still in GUI
                    DataExplorer.updatePerformanceUI()
                    DataExplorer.updateLockStatusUI()
                    DataExplorer.updateCacheViewerUI()
                    task.wait(5) -- Update every 5 seconds, using task.wait instead of wait
                end
            end)
        end
    end)
end

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
    -- Check available modules more robustly by iterating through the table
    local availableModulesCount = 0
    for _, _ in pairs(DataStoreManagerPlugin) do
        availableModulesCount = availableModulesCount + 1
    end
    print("Available modules count:", availableModulesCount)
end

return DataStoreManagerPlugin
