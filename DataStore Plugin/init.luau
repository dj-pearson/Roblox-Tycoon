--luau
-- DataStore Plugin/init.luau

local plugin = script.Parent
local toolbar = plugin:CreateToolbar("DataStore Manager Pro")
local button = toolbar:CreateButton("Open DataStore Manager", "Open the DataStore Manager Pro Interface", "rbxassetid://6031090990") -- Updated to database icon

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
        
        -- Update performance data at intervals
        spawn(function()
            while widget.Enabled do
                DataExplorer.updatePerformanceUI()
                DataExplorer.updateLockStatusUI()
                DataExplorer.updateCacheViewerUI()
                wait(5) -- Update every 5 seconds
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
    
    -- Visualization functions
    createBarChart = DataVisualization.createBarChart,
    createLineChart = DataVisualization.createLineChart,
    createPieChart = DataVisualization.createPieChart,
    createTableView = DataVisualization.createTableView
}

return DataStoreManagerPlugin
