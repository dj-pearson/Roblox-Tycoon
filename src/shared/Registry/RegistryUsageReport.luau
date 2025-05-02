--!strict
--[[
    RegistryUsageReport.luau
    
    A utility module that generates reports on registry system usage
    to help track migration progress and identify areas that need attention.
    
    This tool creates comprehensive reports on which systems are still using
    legacy registry APIs and which have successfully migrated.
    
    Created: May 2, 2025
]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Import required modules
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local RegistryModules = SharedModules:WaitForChild("Registry")
local RegistryTelemetry = require(RegistryModules:WaitForChild("RegistryTelemetry"))

-- The report generator
local RegistryUsageReport = {}

-- Report configuration
RegistryUsageReport.Config = {
    includeFullDetails = true,
    priorityThreshold = 5, -- Minimum usage count to be considered high priority
    exportFormat = "markdown" -- "markdown" or "text"
}

-- Generate a report on legacy registry usage
function RegistryUsageReport:GenerateLegacyUsageReport()
    local usageSummary = RegistryTelemetry:GetLegacyUsageSummary()
    local migrationStatus = RegistryTelemetry:GetMigrationStatus()
    
    -- Format the report based on configuration
    if self.Config.exportFormat == "markdown" then
        return self:FormatMarkdownReport(usageSummary, migrationStatus)
    else
        return self:FormatTextReport(usageSummary, migrationStatus)
    end
end

-- Format the report as markdown
function RegistryUsageReport:FormatMarkdownReport(usageSummary, migrationStatus)
    local lines = {
        "# Registry System Migration Report",
        "**Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. "**",
        "",
        "## Migration Progress",
        "",
        "| Metric | Value |",
        "|--------|-------|",
        "| Migration Ratio | " .. string.format("%.1f%%", migrationStatus.migrationRatio * 100) .. " |",
        "| Legacy Usage Count | " .. migrationStatus.legacyUsageCount .. " |",
        "| New Registry Usage Count | " .. migrationStatus.newUsageCount .. " |",
        "| Migration Events | " .. migrationStatus.migrationEvents .. " |",
        "| Errors | " .. migrationStatus.errors .. " |",
        "| Telemetry Duration | " .. string.format("%.1f", migrationStatus.telemetryDuration / 60) .. " minutes |",
        "",
        "## Top Components Still Using Legacy Registry",
        "",
        "| Component | Usage Count |",
        "|-----------|-------------|"
    }
    
    -- Add top legacy components
    for _, component in ipairs(migrationStatus.topLegacyComponents) do
        table.insert(lines, "| " .. component.name .. " | " .. component.count .. " |")
    end
    
    -- Add registry breakdown if full details requested
    if self.Config.includeFullDetails then
        table.insert(lines, "")
        table.insert(lines, "## Usage by Registry")
        table.insert(lines, "")
        table.insert(lines, "| Registry | Call Count |")
        table.insert(lines, "|----------|------------|")
        
        for registry, count in pairs(usageSummary.byRegistry) do
            table.insert(lines, "| " .. registry .. " | " .. count .. " |")
        end
        
        table.insert(lines, "")
        table.insert(lines, "## Usage by Method")
        table.insert(lines, "")
        table.insert(lines, "| Method | Call Count |")
        table.insert(lines, "|--------|------------|")
        
        for method, count in pairs(usageSummary.byMethod) do
            table.insert(lines, "| " .. method .. " | " .. count .. " |")
        end
        
        table.insert(lines, "")
        table.insert(lines, "## Top Callers")
        table.insert(lines, "")
        table.insert(lines, "| Script:Line | Call Count |")
        table.insert(lines, "|-------------|------------|")
        
        -- Sort callers by count
        local callers = {}
        for caller, count in pairs(usageSummary.byCaller) do
            table.insert(callers, {caller = caller, count = count})
        end
        
        table.sort(callers, function(a, b)
            return a.count > b.count
        end)
        
        -- Take top 20
        for i = 1, math.min(20, #callers) do
            table.insert(lines, "| " .. callers[i].caller .. " | " .. callers[i].count .. " |")
        end
    end
    
    table.insert(lines, "")
    table.insert(lines, "## Recommendations")
    table.insert(lines, "")
    
    -- Generate recommendations based on the data
    local priorityComponents = {}
    for _, component in ipairs(migrationStatus.topLegacyComponents) do
        if component.count >= self.Config.priorityThreshold then
            table.insert(priorityComponents, component)
        end
    end
    
    if #priorityComponents > 0 then
        table.insert(lines, "### High Priority Migration Targets")
        table.insert(lines, "")
        table.insert(lines, "The following components should be migrated first due to their high usage of legacy registry APIs:")
        table.insert(lines, "")
        
        for _, component in ipairs(priorityComponents) do
            table.insert(lines, "- **" .. component.name .. "** (" .. component.count .. " calls)")
        end
    else
        table.insert(lines, "No high-priority components identified. Continue with the general migration plan.")
    end
    
    -- Add migration status assessment
    table.insert(lines, "")
    if migrationStatus.migrationRatio < 0.25 then
        table.insert(lines, "**Migration Status: Early Stage** - Most systems are still using legacy APIs. Focus on migrating core systems first.")
    elseif migrationStatus.migrationRatio < 0.5 then
        table.insert(lines, "**Migration Status: In Progress** - Making good progress, but significant work remains. Prioritize high-usage components.")
    elseif migrationStatus.migrationRatio < 0.75 then
        table.insert(lines, "**Migration Status: Advanced Stage** - Most systems migrated. Focus on remaining specialized systems.")
    else
        table.insert(lines, "**Migration Status: Nearly Complete** - Most systems migrated successfully. Ready for final cleanup and legacy code removal.")
    end
    
    return table.concat(lines, "\n")
end

-- Format the report as plain text
function RegistryUsageReport:FormatTextReport(usageSummary, migrationStatus)
    local lines = {
        "Registry System Migration Report",
        "Generated: " .. os.date("%Y-%m-%d %H:%M:%S"),
        "",
        "Migration Progress:",
        "- Migration Ratio: " .. string.format("%.1f%%", migrationStatus.migrationRatio * 100),
        "- Legacy Usage Count: " .. migrationStatus.legacyUsageCount,
        "- New Registry Usage Count: " .. migrationStatus.newUsageCount,
        "- Migration Events: " .. migrationStatus.migrationEvents,
        "- Errors: " .. migrationStatus.errors,
        "- Telemetry Duration: " .. string.format("%.1f", migrationStatus.telemetryDuration / 60) .. " minutes",
        "",
        "Top Components Still Using Legacy Registry:"
    }
    
    -- Add top legacy components
    for _, component in ipairs(migrationStatus.topLegacyComponents) do
        table.insert(lines, "- " .. component.name .. ": " .. component.count .. " calls")
    end
    
    -- Add registry breakdown if full details requested
    if self.Config.includeFullDetails then
        table.insert(lines, "")
        table.insert(lines, "Usage by Registry:")
        
        for registry, count in pairs(usageSummary.byRegistry) do
            table.insert(lines, "- " .. registry .. ": " .. count .. " calls")
        end
        
        table.insert(lines, "")
        table.insert(lines, "Usage by Method:")
        
        for method, count in pairs(usageSummary.byMethod) do
            table.insert(lines, "- " .. method .. ": " .. count .. " calls")
        end
        
        table.insert(lines, "")
        table.insert(lines, "Top Callers:")
        
        -- Sort callers by count
        local callers = {}
        for caller, count in pairs(usageSummary.byCaller) do
            table.insert(callers, {caller = caller, count = count})
        end
        
        table.sort(callers, function(a, b)
            return a.count > b.count
        end)
        
        -- Take top 20
        for i = 1, math.min(20, #callers) do
            table.insert(lines, "- " .. callers[i].caller .. ": " .. callers[i].count .. " calls")
        end
    end
    
    table.insert(lines, "")
    table.insert(lines, "Recommendations:")
    
    -- Generate recommendations based on the data
    local priorityComponents = {}
    for _, component in ipairs(migrationStatus.topLegacyComponents) do
        if component.count >= self.Config.priorityThreshold then
            table.insert(priorityComponents, component)
        end
    end
    
    if #priorityComponents > 0 then
        table.insert(lines, "High Priority Migration Targets:")
        table.insert(lines, "The following components should be migrated first due to their high usage of legacy registry APIs:")
        
        for _, component in ipairs(priorityComponents) do
            table.insert(lines, "- " .. component.name .. " (" .. component.count .. " calls)")
        end
    else
        table.insert(lines, "No high-priority components identified. Continue with the general migration plan.")
    end
    
    -- Add migration status assessment
    table.insert(lines, "")
    if migrationStatus.migrationRatio < 0.25 then
        table.insert(lines, "Migration Status: Early Stage - Most systems are still using legacy APIs. Focus on migrating core systems first.")
    elseif migrationStatus.migrationRatio < 0.5 then
        table.insert(lines, "Migration Status: In Progress - Making good progress, but significant work remains. Prioritize high-usage components.")
    elseif migrationStatus.migrationRatio < 0.75 then
        table.insert(lines, "Migration Status: Advanced Stage - Most systems migrated. Focus on remaining specialized systems.")
    else
        table.insert(lines, "Migration Status: Nearly Complete - Most systems migrated successfully. Ready for final cleanup and legacy code removal.")
    end
    
    return table.concat(lines, "\n")
end

-- Generate and save the report to a file
function RegistryUsageReport:SaveReportToFile()
    local report = self:GenerateLegacyUsageReport()
    local fileName = "RegistryMigrationReport_" .. os.date("%Y%m%d") .. "." .. (self.Config.exportFormat == "markdown" and "md" or "txt")
    
    -- The path where to save depends on the context
    local filePath
    if RunService:IsStudio() then
        -- In Studio, use the workspace folder
        local success, result = pcall(function()
            -- This is studio-specific and should be handled appropriately
            return fileName
        end)
        
        filePath = success and result or fileName
    else
        -- In production, save to a designated reports folder
        filePath = "Reports/" .. fileName
    end
    
    -- Placeholder for actual file saving logic
    print("[RegistryUsageReport] Report generated and would be saved to: " .. filePath)
    print(report)
    
    return report, filePath
end

return RegistryUsageReport
