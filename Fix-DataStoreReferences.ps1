# Fix DataStore Plugin Script References
# This script fixes require paths in all Lua/Luau files in the DataStore Plugin directory

param (
    [string]$directory = ".\DataStore Plugin\src"
)

function Fix-RequireStatements {
    param (
        [string]$filePath
    )
    
    Write-Host "Processing $filePath"
    
    # Read the file content
    $content = Get-Content -Path $filePath -Raw
    $modified = $false
    
    # Fix require statements by adding .server extension
    $moduleNames = @(
        "DataStoreManager",
        "DataExplorer",
        "PerformanceMonitor",
        "SchemaManager",
        "SessionManager",
        "CacheManager",
        "SchemaValidator",
        "SecurityManager",
        "DataVisualization",
        "StyleGuide",
        "SchemaEditor",
        "MonitoringDashboard",
        "MultiServerCoordination",
        "PerformanceAnalyzer",
        "BulkOperationsManager",
        "SchemaBuilder",
        "SchemaVersionViewer",
        "DataMigrationTools"
    )
    
    foreach ($moduleName in $moduleNames) {
        # Look for require(script.Parent.ModuleName) without .server extension
        if ($content -match "require\(script\.Parent\.$moduleName\)") {
            $content = $content -replace "require\(script\.Parent\.$moduleName\)", "require(script.Parent.$moduleName.server)"
            $modified = $true
        }
        
        # Look for require(script.ModuleName) without .server extension
        if ($content -match "require\(script\.$moduleName\)") {
            $content = $content -replace "require\(script\.$moduleName\)", "require(script.$moduleName.server)"
            $modified = $true
        }
    }
    
    # Fix files that use DataExplorer without requiring it
    if ($filePath -match "Integration\.server\.luau$" -or $filePath -match "Integration\.luau$") {
        if ($content -match "function DataExplorer\." -and $content -notmatch "local DataExplorer") {
            $newContent = "--[[
    $(Split-Path -Leaf $filePath)
    Part of DataStore Manager Pro
]]

local DataExplorer = require(script.Parent.DataExplorer.server)

$content"
            $content = $newContent
            $modified = $true
        }
    }
    
    # Only write back if changes were made
    if ($modified) {
        Write-Host "  Fixing require statements"
        Set-Content -Path $filePath -Value $content -NoNewline
        Write-Host "  Fixed successfully"
    } else {
        Write-Host "  No require statements to fix"
    }
}

# Get all Lua and Luau files in the directory
$files = Get-ChildItem -Path $directory -Recurse -Include "*.lua", "*.luau"

foreach ($file in $files) {
    Fix-RequireStatements -filePath $file.FullName
}

Write-Host "All files processed"
