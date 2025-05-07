# Fix-DataStorePlugin-Fresh.ps1
# This script fixes issues in the DataStore Plugin:
# 1. Fixes the varargs usage outside of a vararg function in APIIntegration.luau
# 2. Fixes the nil indexing issues with integration modules

Write-Host "Fixing DataStore Plugin issues..." -ForegroundColor Cyan

# Path to the plugin source folder
$srcPath = ".\DataStore Plugin\src"

# Fix 1: Replace APIIntegration.callPluginMethod to use varargs directly
$apiIntegrationPath = Join-Path $srcPath "APIIntegration.luau"
$apiIntegrationContent = Get-Content $apiIntegrationPath -Raw

# Replace the callPluginMethod implementation
$oldFunction = @"
-- Call a method on a plugin extension
function APIIntegration.callPluginMethod(pluginName, methodName, ...)
    local plugin = APIIntegration.configurations.customPlugins[pluginName]
    
    if not plugin then
        return nil, "Plugin extension not found: " .. pluginName
    end
    
    if not plugin[methodName] or type(plugin[methodName]) ~= "function" then
        return nil, "Method not found in plugin extension: " .. methodName
    end
    
    -- Capture varargs to pass them correctly
    local args = {...}
    
    -- Call the method on the plugin extension
    local success, result = pcall(function()
        return plugin[methodName](unpack(args))
    end)
    
    if not success then
        return nil, "Failed to call plugin method: " .. tostring(result)
    end
    
    return result
end
"@

$newFunction = @"
-- Call a method on a plugin extension
function APIIntegration.callPluginMethod(pluginName, methodName, ...)
    local plugin = APIIntegration.configurations.customPlugins[pluginName]
    
    if not plugin then
        return nil, "Plugin extension not found: " .. pluginName
    end
    
    if not plugin[methodName] or type(plugin[methodName]) ~= "function" then
        return nil, "Method not found in plugin extension: " .. methodName
    end
    
    -- Call the method on the plugin extension and pass varargs directly
    local success, result = pcall(plugin[methodName], ...)
    
    if not success then
        return nil, "Failed to call plugin method: " .. tostring(result)
    end
    
    return result
end
"@

$apiIntegrationContent = $apiIntegrationContent -replace [regex]::Escape($oldFunction), $newFunction
Set-Content -Path $apiIntegrationPath -Value $apiIntegrationContent
Write-Host "Fixed APIIntegration.callPluginMethod function" -ForegroundColor Green

# Fix 2: Update MultiServerCoordinationIntegration.luau to create a proper module
$msciPath = Join-Path $srcPath "MultiServerCoordinationIntegration.luau"
$msciContent = @"
--luau
-- DataStore Plugin/MultiServerCoordinationIntegration.luau

local MultiServerCoordinationIntegration = {}

-- Initialize the Multi-Server Coordination Integration
function MultiServerCoordinationIntegration.initialize()
    print("MultiServerCoordinationIntegration: Initializing module...")
    return true
end

-- Initialize the Multi-Server Coordination UI in the provided container
function MultiServerCoordinationIntegration.initMultiServerCoordinationUI(DataExplorer)
    print("MultiServerCoordinationIntegration: Initializing UI...")
    
    if not DataExplorer then
        warn("MultiServerCoordinationIntegration: DataExplorer not provided for UI initialization")
        return false
    end
    
    local mainFrame = DataExplorer.mainFrame
    if not mainFrame then return end
    
    -- Create a button to open multi-server coordination UI
    local coordinationButton = Instance.new("TextButton")
    coordinationButton.Size = UDim2.new(0, 150, 0, 28)
    coordinationButton.Position = UDim2.new(1, -600, 0, 10) -- Position it to the left of other buttons
    coordinationButton.BackgroundColor3 = Color3.fromRGB(52, 152, 219) -- Blue color for coordination
    coordinationButton.BorderSizePixel = 0
    coordinationButton.Text = "Server Coordination"
    coordinationButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    coordinationButton.Font = Enum.Font.SourceSansSemibold
    coordinationButton.TextSize = 14
    coordinationButton.ZIndex = 5
    coordinationButton.Parent = mainFrame
    
    -- Add rounded corners
    local coordinationButtonCorner = Instance.new("UICorner")
    coordinationButtonCorner.CornerRadius = UDim.new(0, 4)
    coordinationButtonCorner.Parent = coordinationButton
    
    -- Create a container for the multi-server coordination UI (initially invisible)
    local coordinationContainer = Instance.new("Frame")
    coordinationContainer.Size = UDim2.new(1, 0, 1, 0)
    coordinationContainer.Position = UDim2.new(0, 0, 0, 0)
    coordinationContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    coordinationContainer.Visible = false
    coordinationContainer.Name = "MultiServerCoordinationContainer"
    coordinationContainer.Parent = mainFrame
    DataExplorer.coordinationContainer = coordinationContainer
    
    -- Create the multi-server coordination UI
    local MultiServerCoordinationUI = require(script.Parent.MultiServerCoordinationUI)
    MultiServerCoordinationUI.createUI(coordinationContainer)
    
    -- Toggle visibility when coordination button is clicked
    coordinationButton.MouseButton1Click:Connect(function()
        local contentPane = DataExplorer.contentPane
        local navPane = DataExplorer.navigationPane
        
        if DataExplorer.coordinationContainer.Visible then
            -- Hide coordination UI and show normal UI
            DataExplorer.coordinationContainer.Visible = false
            contentPane.Visible = true
            navPane.Visible = true
            coordinationButton.Text = "Server Coordination"
            coordinationButton.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
            
            -- Also ensure other containers are hidden
            if DataExplorer.schemaBuilderContainer then
                DataExplorer.schemaBuilderContainer.Visible = false
            end
            
            if DataExplorer.bulkOperationsContainer then
                DataExplorer.bulkOperationsContainer.Visible = false
            end
            
            if DataExplorer.monitoringDashboardContainer then
                DataExplorer.monitoringDashboardContainer.Visible = false
            end
            
            if DataExplorer.dataMigrationContainer then
                DataExplorer.dataMigrationContainer.Visible = false
            end
        else
            -- Show coordination UI and hide normal UI
            DataExplorer.coordinationContainer.Visible = true
            contentPane.Visible = false
            navPane.Visible = false
            coordinationButton.Text = "Back to Explorer"
            coordinationButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
            
            -- Also ensure other containers are hidden
            if DataExplorer.schemaBuilderContainer then
                DataExplorer.schemaBuilderContainer.Visible = false
            end
            
            if DataExplorer.bulkOperationsContainer then
                DataExplorer.bulkOperationsContainer.Visible = false
            end
            
            if DataExplorer.monitoringDashboardContainer then
                DataExplorer.monitoringDashboardContainer.Visible = false
            end
            
            if DataExplorer.dataMigrationContainer then
                DataExplorer.dataMigrationContainer.Visible = false
            end
        end
    end)
    
    return true
end

return MultiServerCoordinationIntegration
"@
Set-Content -Path $msciPath -Value $msciContent
Write-Host "Updated MultiServerCoordinationIntegration.luau" -ForegroundColor Green

# Fix 3: Update PerformanceAnalyzerIntegration.luau to create a proper module
$paiPath = Join-Path $srcPath "PerformanceAnalyzerIntegration.luau"
$paiContent = @"
--[[
    PerformanceAnalyzerIntegration.luau
    Part of DataStore Manager Pro
    
    This file contains the integration code to add the Performance Analyzer UI
    to the main DataExplorer interface.
]]

local PerformanceAnalyzerIntegration = {}

-- Initialize the Performance Analyzer Integration
function PerformanceAnalyzerIntegration.initialize()
    print("PerformanceAnalyzerIntegration: Initializing module...")
    return true
end

-- Initialize the Performance Analyzer UI in the provided container
function PerformanceAnalyzerIntegration.initPerformanceAnalyzerUI(DataExplorer)
    print("PerformanceAnalyzerIntegration: Initializing UI...")
    
    if not DataExplorer then
        warn("PerformanceAnalyzerIntegration: DataExplorer not provided for UI initialization")
        return false
    end
    
    local mainFrame = DataExplorer.mainFrame
    if not mainFrame then return end
    
    -- Create a button to open the performance analyzer UI
    local performanceButton = Instance.new("TextButton")
    performanceButton.Size = UDim2.new(0, 150, 0, 28)
    performanceButton.Position = UDim2.new(1, -450, 0, 10) -- Position it to the left of other buttons
    performanceButton.BackgroundColor3 = Color3.fromRGB(155, 89, 182) -- Purple color for performance
    performanceButton.BorderSizePixel = 0
    performanceButton.Text = "Performance Analyzer"
    performanceButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    performanceButton.Font = Enum.Font.SourceSansSemibold
    performanceButton.TextSize = 14
    performanceButton.ZIndex = 5
    performanceButton.Parent = mainFrame
    
    -- Add rounded corners
    local performanceButtonCorner = Instance.new("UICorner")
    performanceButtonCorner.CornerRadius = UDim.new(0, 4)
    performanceButtonCorner.Parent = performanceButton
    
    -- Create a container for the performance analyzer UI (initially invisible)
    local performanceContainer = Instance.new("Frame")
    performanceContainer.Size = UDim2.new(1, 0, 1, 0)
    performanceContainer.Position = UDim2.new(0, 0, 0, 0)
    performanceContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    performanceContainer.Visible = false
    performanceContainer.Name = "PerformanceAnalyzerContainer"
    performanceContainer.Parent = mainFrame
    DataExplorer.performanceAnalyzerContainer = performanceContainer
    
    -- Create the performance analyzer UI
    local PerformanceAnalyzerUI = require(script.Parent.PerformanceAnalyzerUI)
    PerformanceAnalyzerUI.createUI(performanceContainer)
    
    -- Toggle visibility when performance button is clicked
    performanceButton.MouseButton1Click:Connect(function()
        local contentPane = DataExplorer.contentPane
        local navPane = DataExplorer.navigationPane
        
        if DataExplorer.performanceAnalyzerContainer.Visible then
            -- Hide performance analyzer UI and show normal UI
            DataExplorer.performanceAnalyzerContainer.Visible = false
            if contentPane then contentPane.Visible = true end
            if navPane then navPane.Visible = true end
        else
            -- Hide normal UI and show performance analyzer UI
            DataExplorer.performanceAnalyzerContainer.Visible = true
            if contentPane then contentPane.Visible = false end
            if navPane then navPane.Visible = false end
            
            -- Hide other containers
            if DataExplorer.bulkOperationsContainer then
                DataExplorer.bulkOperationsContainer.Visible = false
            end
            
            if DataExplorer.monitoringDashboardContainer then
                DataExplorer.monitoringDashboardContainer.Visible = false
            end
            
            if DataExplorer.dataMigrationContainer then
                DataExplorer.dataMigrationContainer.Visible = false
            end
            
            if DataExplorer.coordinationContainer then
                DataExplorer.coordinationContainer.Visible = false
            end
            
            if DataExplorer.cachingSystemContainer then
                DataExplorer.cachingSystemContainer.Visible = false
            end
        end
    end)
    
    return true
end

return PerformanceAnalyzerIntegration
"@
Set-Content -Path $paiPath -Value $paiContent
Write-Host "Updated PerformanceAnalyzerIntegration.luau" -ForegroundColor Green

# Fix 4: Update DataExplorer.server.luau to use the integration modules
$dataExplorerPath = Join-Path $srcPath "DataExplorer.server.luau"
$dataExplorerContent = Get-Content $dataExplorerPath -Raw

# Replace the initMultiServerCoordinationUI function
$oldInitMSCUI = @"
function DataExplorer.initMultiServerCoordinationUI()
    local mainFrame = DataExplorer.mainFrame
    if not mainFrame then return end
"@

$newInitMSCUI = @"
function DataExplorer.initMultiServerCoordinationUI()
    if MultiServerCoordinationIntegration and MultiServerCoordinationIntegration.initMultiServerCoordinationUI then
        MultiServerCoordinationIntegration.initMultiServerCoordinationUI(DataExplorer)
    else
        local mainFrame = DataExplorer.mainFrame
        if not mainFrame then return end
"@

$dataExplorerContent = $dataExplorerContent -replace [regex]::Escape($oldInitMSCUI), $newInitMSCUI

# Replace the initPerformanceAnalyzerUI function
$oldInitPAUI = @"
function DataExplorer.initPerformanceAnalyzerUI()
    local mainFrame = DataExplorer.mainFrame
    if not mainFrame then return end
"@

$newInitPAUI = @"
function DataExplorer.initPerformanceAnalyzerUI()
    if PerformanceAnalyzerIntegration and PerformanceAnalyzerIntegration.initPerformanceAnalyzerUI then
        PerformanceAnalyzerIntegration.initPerformanceAnalyzerUI(DataExplorer)
    else
        local mainFrame = DataExplorer.mainFrame
        if not mainFrame then return end
"@

$dataExplorerContent = $dataExplorerContent -replace [regex]::Escape($oldInitPAUI), $newInitPAUI
Set-Content -Path $dataExplorerPath -Value $dataExplorerContent
Write-Host "Updated DataExplorer.server.luau functions" -ForegroundColor Green

# Fix 5: Update init.server.luau to require and initialize the integration modules
$initPath = Join-Path $srcPath "init.server.luau"
$initContent = Get-Content $initPath -Raw

# Add requires for integration modules
$oldRequires = @"
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
local APIIntegration = require(script.APIIntegration)
local APIIntegrationUI = require(script.APIIntegrationUI)
local AccessControl = require(script.AccessControl)
local AccessControlUI = require(script.AccessControlUI)
"@

$newRequires = @"
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
local MultiServerCoordinationIntegration = require(script.MultiServerCoordinationIntegration)
local PerformanceAnalyzer = require(script.PerformanceAnalyzer)
local PerformanceAnalyzerUI = require(script.PerformanceAnalyzerUI)
local PerformanceAnalyzerIntegration = require(script.PerformanceAnalyzerIntegration)
local CachingSystemUI = require(script.CachingSystemUI)
local LoadTesting = require(script.LoadTesting)
local LoadTestingUI = require(script.LoadTestingUI)
local CodeGenerator = require(script.CodeGenerator)
local CodeGeneratorUI = require(script.CodeGeneratorUI)
local APIIntegration = require(script.APIIntegration)
local APIIntegrationUI = require(script.APIIntegrationUI)
local AccessControl = require(script.AccessControl)
local AccessControlUI = require(script.AccessControlUI)
"@

$initContent = $initContent -replace [regex]::Escape($oldRequires), $newRequires

# Add initialization for integration modules
$oldInit = @"
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
"@

$newInit = @"
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
MultiServerCoordinationIntegration.initialize()
PerformanceAnalyzerIntegration.initialize()
"@

$initContent = $initContent -replace [regex]::Escape($oldInit), $newInit
Set-Content -Path $initPath -Value $initContent
Write-Host "Updated init.server.luau with integration modules" -ForegroundColor Green

Write-Host "All fixes have been successfully applied!" -ForegroundColor Green
Write-Host "The DataStore plugin should now run without the reported errors." -ForegroundColor Cyan
