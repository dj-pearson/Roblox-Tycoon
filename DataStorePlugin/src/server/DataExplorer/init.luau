--[[
    DataExplorer - Main Module
    Orchestrates the DataExplorer UI and functionality
]]

local HttpService = game:GetService("HttpService")

-- Module resolver for safe requiring
local resolver = script.Parent:FindFirstChild("ModuleResolver")
local resolveModule = resolver and require(resolver).resolveModule or function(name)
    local success, result = pcall(function()
        return require(script.Parent:FindFirstChild(name))
    end)
    
    if success and result then
        return result
    end
    
    warn("Failed to resolve module: " .. name)
    return {
        initialize = function() return true end,
        createUI = function() return Instance.new("Frame") end
    }
end

-- Import sub-modules
local UIComponents = require(script.UIComponents)
local ContentViewers = require(script.ContentViewers)
local IntegrationManager = require(script.IntegrationManager)
local EventManager = require(script.EventManager)

-- Main DataExplorer module
local DataExplorer = {
    sessionId = HttpService:GenerateGUID(),
    mainFrame = nil,
    contentPane = nil,
    navigationPane = nil,
    performancePane = nil,
    lockStatusPane = nil,
    cacheViewerPane = nil,
    lockStatusContent = nil,
    splitPane = nil,
    
    -- UI Container references
    bulkOperationsContainer = nil,
    schemaBuilderContainer = nil,
    monitoringDashboardContainer = nil,
    dataMigrationContainer = nil,
    coordinationContainer = nil,
    performanceAnalyzerContainer = nil,
    cachingSystemContainer = nil,
    loadTestingContainer = nil,
    codeGeneratorContainer = nil,
    apiIntegrationContainer = nil,
    accessControlContainer = nil,
    sessionManagementUI = nil,
    
    -- Button references
    bulkOperationsButton = nil,
    schemaBuilderButton = nil,
}

-- Initialize the DataExplorer
function DataExplorer.initialize()
    print("DataExplorer: Initializing...")
    
    -- Initialize sub-modules
    UIComponents.initialize(DataExplorer)
    ContentViewers.initialize(DataExplorer)
    IntegrationManager.initialize(DataExplorer)
    EventManager.initialize(DataExplorer)
    
    print("DataExplorer: Initialization complete")
end

-- Create the main UI
function DataExplorer.createMainUI()
    return UIComponents.createMainUI()
end

-- Display key content
function DataExplorer.displayKeyContent(dataStoreName, keyName)
    return ContentViewers.displayKeyContent(dataStoreName, keyName)
end

-- Update UI functions
function DataExplorer.updateLockStatusUI()
    return UIComponents.updateLockStatusUI()
end

function DataExplorer.updatePerformanceDataUI()
    return UIComponents.updatePerformanceDataUI()
end

function DataExplorer.updateCacheViewerUI()
    return UIComponents.updateCacheViewerUI()
end

-- Session management
function DataExplorer.showSessionManagementUI()
    return UIComponents.showSessionManagementUI()
end

-- Integration initializers (delegated to IntegrationManager)
function DataExplorer.initBulkOperationsUI()
    return IntegrationManager.initBulkOperationsUI()
end

function DataExplorer.initMonitoringDashboardUI()
    return IntegrationManager.initMonitoringDashboardUI()
end

function DataExplorer.initDataMigrationUI()
    return IntegrationManager.initDataMigrationUI()
end

function DataExplorer.initMultiServerCoordinationUI()
    return IntegrationManager.initMultiServerCoordinationUI()
end

function DataExplorer.initPerformanceAnalyzerUI()
    return IntegrationManager.initPerformanceAnalyzerUI()
end

function DataExplorer.initCachingSystemUI()
    return IntegrationManager.initCachingSystemUI()
end

function DataExplorer.initLoadTestingUI()
    return IntegrationManager.initLoadTestingUI()
end

function DataExplorer.initCodeGeneratorUI()
    return IntegrationManager.initCodeGeneratorUI()
end

function DataExplorer.initAPIIntegrationUI()
    return IntegrationManager.initAPIIntegrationUI()
end

function DataExplorer.initAccessControlUI()
    return IntegrationManager.initAccessControlUI()
end

return DataExplorer 