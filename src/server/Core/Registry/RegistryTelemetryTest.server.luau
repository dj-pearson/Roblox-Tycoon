--!strict
--[[
    RegistryTelemetryTest.server.luau
    
    Test script for the Registry Telemetry system. This script verifies 
    that the telemetry data collection works correctly.
    
    To run: Place in ServerScriptService and execute manually in Studio.
    
    Created: May 2, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local RegistryModules = SharedModules:WaitForChild("Registry")

-- Import required modules
local RegistryTelemetry = require(RegistryModules:WaitForChild("RegistryTelemetry"))
local RegistryUsageReport = require(RegistryModules:WaitForChild("RegistryUsageReport"))
local RegistryBridge = require(RegistryModules:WaitForChild("RegistryBridge"))

print("=== Registry Telemetry System Test ===")

-- Test 1: Basic telemetry tracking
print("Test 1: Basic telemetry tracking")
RegistryTelemetry:TrackOperation("test_operation", {test = "data"})
local stats = RegistryTelemetry:GetStats()
print("Operation tracked. Total operations:", stats.totalOperations)

-- Test 2: Component telemetry
print("\nTest 2: Component telemetry")
RegistryTelemetry:TrackComponentOperation("TestComponent", "register", {context = "server"})
RegistryTelemetry:TrackComponentOperation("TestComponent", "retrieve", {context = "server"})
local telemetryData = RegistryTelemetry:GetTelemetryData("summary")
print("Component tracking complete. Components tracked:", telemetryData.componentCount)

-- Test 3: Legacy bridge telemetry
print("\nTest 3: Legacy bridge telemetry")
RegistryTelemetry:LogLegacyUsage("TestScript", "GetSystem", "TestSystem")
stats = RegistryTelemetry:GetStats()
print("Legacy usage tracked. Bridge usages:", stats.bridgeUsage)

-- Test 4: Performance tracking
print("\nTest 4: Performance tracking")
local function testFunction()
    task.wait(0.1) -- Simulate work
    return true
end
RegistryTelemetry:TimeOperation("test_performance", {source = "test"}, testFunction)
print("Performance tracking complete")

-- Test 5: Error tracking
print("\nTest 5: Error tracking")
RegistryTelemetry:LogError("TestSource", "Test error message", "TestDetails")
telemetryData = RegistryTelemetry:GetTelemetryData("summary")
print("Error tracking complete. Errors tracked:", telemetryData.errorCount)

-- Test 6: Migration event tracking
print("\nTest 6: Migration event tracking")
RegistryTelemetry:LogMigrationEvent("component_migrated", {
    component = "TestComponent",
    success = true,
    details = "Migrated successfully"
})
telemetryData = RegistryTelemetry:GetTelemetryData("summary")
print("Migration event tracking complete. Migration events:", telemetryData.migrationCount)

-- Test 7: Generate a report
print("\nTest 7: Generate a report")
local report = RegistryUsageReport:GenerateLegacyUsageReport()
print("Report generated with", report.legacyComponents, "legacy components and", 
    report.migratedComponents, "migrated components")

-- Test 8: Registry Bridge integration
print("\nTest 8: Registry Bridge integration")
-- Register a test system through the bridge
RegistryBridge:RegisterSystem("TestBridgeSystem", {
    id = "TestBridgeSystem",
    initialize = function() return true end
})
-- Retrieve the system
local testSystem = RegistryBridge:GetSystem("TestBridgeSystem")
print("Bridge system registered and retrieved:", testSystem ~= nil)

print("\n=== Test complete ===")
print("All telemetry systems verified.")
