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

    local moduleScript = script.Parent:FindFirstChild(moduleName)
    
    if moduleScript then
        local success, result = pcall(function()
            return require(moduleScript)
        end)
        
        if success and result then
            moduleCache[moduleName] = result
            return result
        else
            warn("Error requiring module: " .. moduleName .. " - " .. tostring(result)) -- result here is the error message
        end
    else
        warn("Could not find module: " .. moduleName .. " in script.Parent.")
    end
    
    -- Return a dummy module if loading failed
    warn("Failed to resolve module: " .. moduleName .. ". Using dummy.")
    local dummyModule = {
        initialize = function(...) 
            warn("Dummy " .. moduleName .. ".initialize() called with: ", ...) 
            return true 
        end,
        createUI = function(...) 
            warn("Dummy " .. moduleName .. ".createUI() called with: ", ...) 
            return Instance.new("Frame") 
        end,
        -- Add other common functions here for dummy modules to prevent further errors
        createMainGui = function(...) warn("Dummy " .. moduleName .. ".createMainGui() called with: ", ...) return Instance.new("Frame") end,
        initBulkOperationsUI = function(...) warn("Dummy " .. moduleName .. ".initBulkOperationsUI() called with: ", ...) end,
        initMonitoringDashboardUI = function(...) warn("Dummy " .. moduleName .. ".initMonitoringDashboardUI() called with: ", ...) end,
        initDataMigrationUI = function(...) warn("Dummy " .. moduleName .. ".initDataMigrationUI() called with: ", ...) end,
        initMultiServerCoordinationUI = function(...) warn("Dummy " .. moduleName .. ".initMultiServerCoordinationUI() called with: ", ...) end,
        initPerformanceAnalyzerUI = function(...) warn("Dummy " .. moduleName .. ".initPerformanceAnalyzerUI() called with: ", ...) end,
        initCachingSystemUI = function(...) warn("Dummy " .. moduleName .. ".initCachingSystemUI() called with: ", ...) end,
        initLoadTestingUI = function(...) warn("Dummy " .. moduleName .. ".initLoadTestingUI() called with: ", ...) end,
        initCodeGeneratorUI = function(...) warn("Dummy " .. moduleName .. ".initCodeGeneratorUI() called with: ", ...) end,
        initAPIIntegrationUI = function(...) warn("Dummy " .. moduleName .. ".initAPIIntegrationUI() called with: ", ...) end,
        initAccessControlUI = function(...) warn("Dummy " .. moduleName .. ".initAccessControlUI() called with: ", ...) end,
        updatePerformanceUI = function(...) warn("Dummy " .. moduleName .. ".updatePerformanceUI() called with: ", ...) end,
        updateLockStatusUI = function(...) warn("Dummy " .. moduleName .. ".updateLockStatusUI() called with: ", ...) end,
        updateCacheViewerUI = function(...) warn("Dummy " .. moduleName .. ".updateCacheViewerUI() called with: ", ...) end,
        getData = function(...) warn("Dummy " .. moduleName .. ".getData() called with: ", ...) end,
        setData = function(...) warn("Dummy " .. moduleName .. ".setData() called with: ", ...) end,
        updateData = function(...) warn("Dummy " .. moduleName .. ".updateData() called with: ", ...) end,
        removeData = function(...) warn("Dummy " .. moduleName .. ".removeData() called with: ", ...) end,
        listKeys = function(...) warn("Dummy " .. moduleName .. ".listKeys() called with: ", ...) end,
        validate = function(...) warn("Dummy " .. moduleName .. ".validate() called with: ", ...) end,
        saveSchema = function(...) warn("Dummy " .. moduleName .. ".saveSchema() called with: ", ...) end,
        loadSchema = function(...) warn("Dummy " .. moduleName .. ".loadSchema() called with: ", ...) end,
        getPerformanceData = function(...) warn("Dummy " .. moduleName .. ".getPerformanceData() called with: ", ...) end,
        getOperationSummary = function(...) warn("Dummy " .. moduleName .. ".getOperationSummary() called with: ", ...) end,
        migrateKey = function(...) warn("Dummy " .. moduleName .. ".migrateKey() called with: ", ...) end,
        migrateDataStore = function(...) warn("Dummy " .. moduleName .. ".migrateDataStore() called with: ", ...) end,
        getMigrationStatus = function(...) warn("Dummy " .. moduleName .. ".getMigrationStatus() called with: ", ...) end,
        requestDistributedLock = function(...) warn("Dummy " .. moduleName .. ".requestDistributedLock() called with: ", ...) end,
        releaseDistributedLock = function(...) warn("Dummy " .. moduleName .. ".releaseDistributedLock() called with: ", ...) end,
        getActiveServers = function(...) warn("Dummy " .. moduleName .. ".getActiveServers() called with: ", ...) end,
        getCacheAnalytics = function(...) warn("Dummy " .. moduleName .. ".getCacheAnalytics() called with: ", ...) end,
        getCacheContents = function(...) warn("Dummy " .. moduleName .. ".getCacheContents() called with: ", ...) end,
        optimizeCache = function(...) warn("Dummy " .. moduleName .. ".optimizeCache() called with: ", ...) end,
        preloadData = function(...) warn("Dummy " .. moduleName .. ".preloadData() called with: ", ...) end,
        generateModuleFromSchema = function(...) warn("Dummy " .. moduleName .. ".generateModuleFromSchema() called with: ", ...) end,
        templates = function(...) warn("Dummy " .. moduleName .. ".templates() called with: ", ...) return {} end, -- Added dummy templates table
        configureWebhook = function(...) warn("Dummy " .. moduleName .. ".configureWebhook() called with: ", ...) end,
        triggerWebhook = function(...) warn("Dummy " .. moduleName .. ".triggerWebhook() called with: ", ...) end,
        configureOpenCloudAPI = function(...) warn("Dummy " .. moduleName .. ".configureOpenCloudAPI() called with: ", ...) end,
        getWebhooks = function(...) warn("Dummy " .. moduleName .. ".getWebhooks() called with: ", ...) end,
        createBarChart = function(...) warn("Dummy " .. moduleName .. ".createBarChart() called with: ", ...) end,
        createLineChart = function(...) warn("Dummy " .. moduleName .. ".createLineChart() called with: ", ...) end,
        createPieChart = function(...) warn("Dummy " .. moduleName .. ".createPieChart() called with: ", ...) end,
        createTableView = function(...) warn("Dummy " .. moduleName .. ".createTableView() called with: ", ...) end
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
local widgetInfo
if runningInPluginContext then
    widgetInfo = DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Right,
        false, -- Floating
        false, -- Enabled by default
        800,   -- Width
        600,   -- Height
        800,   -- MinWidth
        600    -- MinHeight
    )
end

local widget
if runningInPluginContext then
    widget = plugin:CreateDockWidgetPluginGui("DataStoreManagerWidget", widgetInfo)
    widget.Title = "DataStore Manager Pro"
end

-- Initialize the plugin components
DataStoreManager.initialize()
MonitoringDashboard.initialize()
MonitoringDashboardUI.initialize()

-- Ensure DataMigrationTools is a table with an initialize method or handle it if it could be a function directly
if type(DataMigrationTools) == "table" and DataMigrationTools.initialize then
    DataMigrationTools:initialize()
elseif type(DataMigrationTools) == "function" then --This case should not happen with the current dummy but good for future
    DataMigrationTools()
else
    warn("DataMigrationTools does not have an initialize method or is not a function.")
end

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
if button and widget then -- Check if button and widget exist before connecting
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
            task.spawn(function() 
                while widget.Enabled and widget.Parent do 
                    DataExplorer.updatePerformanceUI()
                    DataExplorer.updateLockStatusUI()
                    DataExplorer.updateCacheViewerUI()
                    task.wait(5) 
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
    
    getData = DataStoreManager.getData,
    setData = DataStoreManager.setData,
    updateData = DataStoreManager.updateData,
    removeData = DataStoreManager.removeData,
    listKeys = DataStoreManager.listKeys,
    
    validateData = SchemaValidator.validate,
    createSchema = SchemaManager.saveSchema,
    loadSchema = SchemaManager.loadSchema,
    
    getPerformanceData = PerformanceMonitor.getPerformanceData,
    getOperationSummary = PerformanceMonitor.getOperationSummary,
    
    migrateKey = DataMigrationTools.migrateKey,
    migrateDataStore = DataMigrationTools.migrateDataStore,
    getMigrationStatus = DataMigrationTools.getMigrationStatus,
    
    requestDistributedLock = MultiServerCoordination.requestDistributedLock,
    releaseDistributedLock = MultiServerCoordination.releaseDistributedLock,
    getActiveServers = MultiServerCoordination.getActiveServers,
    
    getCacheAnalytics = CacheManager.getCacheAnalytics,
    getCacheContents = CacheManager.getCacheContents,
    optimizeCache = CacheManager.optimizeCache,
    preloadData = CacheManager.preloadData,
    
    generateCode = CodeGenerator.generateModuleFromSchema,
    getTemplates = function(moduleType) 
        if CodeGenerator and CodeGenerator.templates then
             return CodeGenerator.templates[moduleType or "module"]
        end
        return {}
    end,
    
    configureWebhook = APIIntegration.configureWebhook,
    triggerWebhook = APIIntegration.triggerWebhook,
    configureOpenCloudAPI = APIIntegration.configureOpenCloudAPI,
    getWebhooks = APIIntegration.getWebhooks,
    
    createBarChart = DataVisualization.createBarChart,
    createLineChart = DataVisualization.createLineChart,
    createPieChart = DataVisualization.createPieChart,
    createTableView = DataVisualization.createTableView,
    
    Version = PluginVersion or "1.0.0"
}

if not runningInPluginContext then
    print("DataStore Manager Pro loaded successfully in non-plugin context")
    print("Plugin Version:", DataStoreManagerPlugin.Version)
    local availableModulesCount = 0
    for k, v in pairs(DataStoreManagerPlugin) do
        if type(v) == "table" then -- Count only modules, not functions/version string
          local isDummy = true
          for funcName, _ in pairs(v) do
            if funcName ~= "initialize" and funcName ~= "createUI" then -- crude check for dummy
              isDummy = false
              break
            end
          end
          if not isDummy or k == "DataStoreManager" then -- Assuming DataStoreManager is critical and should be real
             availableModulesCount = availableModulesCount + 1
          end
        end
    end
    print("Real (non-dummy) modules count (approx):", availableModulesCount)
end

return DataStoreManagerPlugin
