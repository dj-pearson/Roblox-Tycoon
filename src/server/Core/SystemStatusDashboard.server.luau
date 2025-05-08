--!strict
--[[
    SystemStatusDashboard.server.luau
    
    Dashboard for monitoring and displaying the health status of all systems.
    This module provides real-time monitoring, status reporting, and alerts
    for system health issues.
    
    Features:
    - Real-time system health monitoring
    - Status reporting and alerts
    - Health metrics tracking
    - System dependency visualization
    - Error history tracking
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

-- Configuration
local CONFIG = {
    updateInterval = 5, -- seconds
    maxErrorHistory = 100,
    alertThresholds = {
        errorRate = 0.1, -- 10% error rate
        recoveryAttempts = 3,
        healthCheckFailures = 5
    },
    statusColors = {
        Healthy = Color3.fromRGB(0, 255, 0),
        Degraded = Color3.fromRGB(255, 165, 0),
        Critical = Color3.fromRGB(255, 0, 0),
        Unknown = Color3.fromRGB(128, 128, 128)
    }
}

-- Dashboard state
local dashboard = {
    initialized = false,
    version = "1.0.0",
    systems = {},
    status = {},
    metrics = {},
    errorHistory = {},
    alerts = {},
    lastUpdate = 0
}

-- Debug logging
local function log(message, level)
    level = level or "Info"
    print(string.format("[SystemStatusDashboard][%s] %s", level, message))
end

-- Get CoreRegistry
local function getCoreRegistry()
    local CoreRegistry = require(script.Parent:WaitForChild("CoreRegistry_enhanced"))
    return CoreRegistry
end

-- Update system status
local function updateSystemStatus()
    local CoreRegistry = getCoreRegistry()
    if not CoreRegistry then
        log("Failed to get CoreRegistry", "Error")
        return
    end
    
    local currentTime = os.time()
    dashboard.lastUpdate = currentTime
    
    -- Get all system health statuses
    local healthStatuses = CoreRegistry.getAllSystemHealth()
    
    -- Update dashboard state
    for systemName, health in pairs(healthStatuses) do
        -- Update system status
        dashboard.systems[systemName] = {
            status = health.status,
            lastCheck = health.lastCheck,
            errorCount = health.errorCount,
            lastError = health.lastError,
            recoveryAttempts = health.recoveryAttempts
        }
        
        -- Track metrics
        dashboard.metrics[systemName] = dashboard.metrics[systemName] or {
            totalErrors = 0,
            totalRecoveries = 0,
            totalHealthChecks = 0,
            lastErrorTime = 0
        }
        
        -- Update metrics
        if health.errorCount then
            dashboard.metrics[systemName].totalErrors = health.errorCount
        end
        if health.recoveryAttempts then
            dashboard.metrics[systemName].totalRecoveries = health.recoveryAttempts
        end
        if health.lastCheck then
            dashboard.metrics[systemName].totalHealthChecks += 1
        end
        if health.lastError then
            dashboard.metrics[systemName].lastErrorTime = currentTime
        end
        
        -- Check for alerts
        local alerts = {}
        
        -- Check error rate
        local errorRate = dashboard.metrics[systemName].totalErrors / 
            (dashboard.metrics[systemName].totalHealthChecks + 1)
        if errorRate > CONFIG.alertThresholds.errorRate then
            table.insert(alerts, {
                type = "ErrorRate",
                message = string.format("High error rate: %.1f%%", errorRate * 100),
                severity = "Critical"
            })
        end
        
        -- Check recovery attempts
        if health.recoveryAttempts and health.recoveryAttempts >= CONFIG.alertThresholds.recoveryAttempts then
            table.insert(alerts, {
                type = "RecoveryAttempts",
                message = "High number of recovery attempts: " .. health.recoveryAttempts,
                severity = "Warning"
            })
        end
        
        -- Update alerts
        if #alerts > 0 then
            dashboard.alerts[systemName] = alerts
        else
            dashboard.alerts[systemName] = nil
        end
    end
end

-- Get system status
function dashboard:getSystemStatus(systemName)
    if not systemName then
        return dashboard.systems
    end
    
    return dashboard.systems[systemName]
end

-- Get system metrics
function dashboard:getSystemMetrics(systemName)
    if not systemName then
        return dashboard.metrics
    end
    
    return dashboard.metrics[systemName]
end

-- Get active alerts
function dashboard:getAlerts(systemName)
    if not systemName then
        return dashboard.alerts
    end
    
    return dashboard.alerts[systemName]
end

-- Get overall system health
function dashboard:getOverallHealth()
    local criticalCount = 0
    local degradedCount = 0
    local healthyCount = 0
    
    for _, system in pairs(dashboard.systems) do
        if system.status == "Critical" then
            criticalCount += 1
        elseif system.status == "Degraded" then
            degradedCount += 1
        elseif system.status == "Healthy" then
            healthyCount += 1
        end
    end
    
    local totalSystems = criticalCount + degradedCount + healthyCount
    if totalSystems == 0 then
        return "Unknown"
    end
    
    if criticalCount > 0 then
        return "Critical"
    elseif degradedCount > 0 then
        return "Degraded"
    else
        return "Healthy"
    end
end

-- Get status color
function dashboard:getStatusColor(status)
    return CONFIG.statusColors[status] or CONFIG.statusColors.Unknown
end

-- Initialize the dashboard
function dashboard:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing SystemStatusDashboard v" .. self.version)
    
    -- Start periodic updates
    task.spawn(function()
        while true do
            task.wait(CONFIG.updateInterval)
            updateSystemStatus()
        end
    end)
    
    -- Initial update
    updateSystemStatus()
    
    self.initialized = true
    log("SystemStatusDashboard initialized successfully")
    return true
end

-- Initialize the dashboard
dashboard:initialize()

return dashboard 