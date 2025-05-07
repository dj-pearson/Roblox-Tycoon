# Fix-DataStore-Module-Requires.ps1
# This script updates all module files in the DataStore Plugin to use the ModuleResolver
# to fix the "Attempted to call require with invalid argument(s)" errors

# Configuration
$pluginFolder = Join-Path $PSScriptRoot "DataStore Plugin\src"
$moduleFiles = @(
    # Core modules
    "DataStoreManager.luau",
    "DataStoreManager.server.luau",
    "CacheManager.luau",
    "CacheManager.server.luau",
    "SchemaManager.luau",
    "SchemaManager.server.luau",
    "SchemaValidator.luau",
    "SchemaValidator.server.luau",
    "SessionManager.luau",
    "SessionManager.server.luau",
    "PerformanceMonitor.luau",
    "PerformanceMonitor.server.luau",
    "SecurityManager.luau",
    "SecurityManager.server.luau",
    "MultiServerCoordination.luau",
    "MultiServerCoordination.server.luau",
    "DataVisualization.luau",
    "DataVisualization.server.luau",
    "StyleGuide.luau",
    "StyleGuide.server.luau",
    "SchemaVersioning.luau",
    "SchemaVersioning.server.luau",
    
    # Integration modules
    "MultiServerCoordinationIntegration.luau",
    "MultiServerCoordinationIntegration.server.luau",
    "PerformanceAnalyzerIntegration.luau",
    "PerformanceAnalyzerIntegration.server.luau",
    
    # Explorer and UI modules
    "DataExplorer.luau",
    "DataExplorer.server.luau"
)

function Update-ModuleCode {
    param (
        [string]$filePath
    )
    
    if (-not (Test-Path $filePath)) {
        Write-Host "Warning: File not found: $filePath" -ForegroundColor Yellow
        return $false
    }
    
    $fileName = Split-Path -Leaf $filePath
    Write-Host "Processing $fileName..." -ForegroundColor Cyan
    
    # Read the file content
    $content = Get-Content -Path $filePath -Raw
    $originalContent = $content
    
    # Add resolver code at the top (after any initial comments)
    $resolverCode = @"

-- Get module resolver from init script or define a local one
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

"@
    
    # Add resolver after any initial comments
    if ($content -match "^(--.+\r?\n)+") {
        $commentBlock = $Matches[0]
        $codeAfterComments = $content.Substring($commentBlock.Length)
        
        # Check if there are any service definitions before adding resolver
        if ($codeAfterComments -match "^(local [A-Za-z]+ = game:GetService\([^\)]+\)\r?\n)+") {
            $serviceBlock = $Matches[0]
            $insertPoint = $commentBlock.Length + $serviceBlock.Length
            $content = $content.Substring(0, $insertPoint) + $resolverCode + $content.Substring($insertPoint)
        }
        else {
            $content = $commentBlock + $resolverCode + $codeAfterComments
        }
    }
    else {
        $content = $resolverCode + $content
    }
    
    # Replace require statements
    $content = $content -replace "require\(script\.Parent\.([A-Za-z0-9_]+)\)", "resolveModule('`$1')"
    
    # Save changes if content was modified
    if ($content -ne $originalContent) {
        # Backup the original file
        $backupPath = "$filePath.backup"
        if (-not (Test-Path $backupPath)) {
            Copy-Item -Path $filePath -Destination $backupPath
        }
        
        # Write the updated content
        Set-Content -Path $filePath -Value $content
        Write-Host "  Updated module requires in $fileName" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "  No changes made to $fileName" -ForegroundColor Yellow
        return $false
    }
}

# Main execution
Write-Host "Starting DataStore Plugin require fix..." -ForegroundColor Cyan
Write-Host "Plugin folder: $pluginFolder" -ForegroundColor Gray

$changedFiles = 0

foreach ($file in $moduleFiles) {
    $filePath = Join-Path $pluginFolder $file
    $changed = Update-ModuleCode -filePath $filePath
    if ($changed) {
        $changedFiles++
    }
}

Write-Host "`nFix complete! Updated $changedFiles module files." -ForegroundColor Green
Write-Host "To test the fix, run BuildDataStorePlugin.ps1.new to rebuild the plugin" -ForegroundColor Cyan
