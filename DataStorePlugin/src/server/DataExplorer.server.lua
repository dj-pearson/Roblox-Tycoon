--[[
    DataExplorer.server.lua - ENTRY POINT
    
    This file has been refactored into a modular structure.
    The main DataExplorer functionality is now in the DataExplorer folder.
    
    This file serves as the main entry point and initializes the system.
]]

-- Import the new modular DataExplorer
local DataExplorer = require(script.Parent.DataExplorer)

-- Initialize the DataExplorer system
DataExplorer.initialize()

-- Set up any additional integrations
pcall(function() DataExplorer.initBulkOperationsUI() end)
pcall(function() DataExplorer.initMonitoringDashboardUI() end)
pcall(function() DataExplorer.initDataMigrationUI() end)
pcall(function() DataExplorer.initMultiServerCoordinationUI() end)
pcall(function() DataExplorer.initPerformanceAnalyzerUI() end)
pcall(function() DataExplorer.initCachingSystemUI() end)
pcall(function() DataExplorer.initLoadTestingUI() end)
pcall(function() DataExplorer.initCodeGeneratorUI() end)
pcall(function() DataExplorer.initAPIIntegrationUI() end)
pcall(function() DataExplorer.initAccessControlUI() end)

print("DataExplorer.server.lua: System initialized with modular structure")

-- Export for any external usage
return DataExplorer 