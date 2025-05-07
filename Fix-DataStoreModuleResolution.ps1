# Fix-DataStoreModuleResolution.ps1
# This script fixes module resolution issues in the DataStore Plugin

Write-Host "=== DataStore Plugin Module Resolution Fix ===" -ForegroundColor Cyan

$srcFolder = "c:\Users\pears\OneDrive\Documents\RobloxProject\DataStore Plugin\src"

# 1. Update all re-export files to use the correct pattern
$reexportFiles = @(
    "AccessControlIntegration.luau",
    "BulkOperationsManager.luau",
    "BulkOperationsUI.luau",
    "CodeGeneratorIntegration.luau",
    "DataExplorer.luau",
    "DataMigrationTools.luau",
    "DataMigrationUI.luau",
    "DataVisualization.luau",
    "MonitoringDashboard.luau",
    "PerformanceMonitor.luau",
    "SchemaBuilder.luau",
    "SchemaBuilderUI.luau",
    "SchemaEditor.luau", 
    "SchemaManager.luau",
    "SchemaValidator.luau",
    "SchemaVersioning.luau",
    "SchemaVersionViewer.luau",
    "SessionManagementUI.luau"
)

foreach ($file in $reexportFiles) {
    $filePath = Join-Path $srcFolder $file
    if (Test-Path $filePath) {
        $content = Get-Content $filePath -Raw
        
        if ($content -match "return require\(script\.server\)") {
            $moduleName = $file -replace '\.luau$', ''
            $newContent = $content -replace "return require\(script\.server\)", "-- Use direct reference to the server script instead of script.server`nreturn require(script.Parent:FindFirstChild(`"$moduleName.server`"))"
            Set-Content $filePath $newContent -NoNewline
            Write-Host "Updated $file to use direct server reference" -ForegroundColor Green
        }
        else {
            Write-Host "Skipped $file - pattern not found" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "File not found: $file" -ForegroundColor Red
    }
}

# 2. Fix the init.server.luau file to include all common suffixes in module resolution
$initFilePath = Join-Path $srcFolder "init.server.luau"
if (Test-Path $initFilePath) {
    $content = Get-Content $initFilePath -Raw
    
    # Update the module resolver function
    $moduleResolverPattern = 'local moduleScript = script\.Parent:FindFirstChild\(moduleName\)'
    $moduleResolverReplacement = @"
    -- Try multiple approaches to find the module
    local moduleScript = nil
    
    -- Try direct reference first
    moduleScript = script.Parent:FindFirstChild(moduleName)
    
    -- If not found, try with .server suffix
    if not moduleScript then
        moduleScript = script.Parent:FindFirstChild(moduleName .. ".server")
    end
    
    -- If not found, try with .luau suffix
    if not moduleScript then
        moduleScript = script.Parent:FindFirstChild(moduleName .. ".luau")
    end
    
    -- If still not found, try with .server.luau suffix
    if not moduleScript then
        moduleScript = script.Parent:FindFirstChild(moduleName .. ".server.luau")
    end
"@
    
    if ($content -match $moduleResolverPattern) {
        $content = $content -replace $moduleResolverPattern, $moduleResolverReplacement
        Set-Content $initFilePath $content -NoNewline
        Write-Host "Updated init.server.luau module resolver to handle all common suffixes" -ForegroundColor Green
    }
    else {
        Write-Host "Could not find module resolver pattern in init.server.luau" -ForegroundColor Red
    }
    
    # Ensure 'elif' is replaced with 'elseif'
    $elifPattern = 'elif type\(DataMigrationTools\) == "function" then'
    $elseifReplacement = 'elseif type(DataMigrationTools) == "function" then'
    
    if ($content -match $elifPattern) {
        $content = $content -replace $elifPattern, $elseifReplacement
        Set-Content $initFilePath $content -NoNewline
        Write-Host "Fixed 'elif' to 'elseif' in init.server.luau" -ForegroundColor Green
    }
}
else {
    Write-Host "init.server.luau file not found!" -ForegroundColor Red
}

# 3. Update InstallModuleResolver to look for init.server.luau
$installerFilePath = Join-Path $srcFolder "InstallModuleResolver.server.luau"
if (Test-Path $installerFilePath) {
    $content = Get-Content $installerFilePath -Raw
    
    $initScriptPattern = 'local initScript = script\.Parent:FindFirstChild\("init\.server"\) or script\.Parent:FindFirstChild\("init"\)'
    $initScriptReplacement = 'local initScript = script.Parent:FindFirstChild("init.server.luau") or script.Parent:FindFirstChild("init.server") or script.Parent:FindFirstChild("init")'
    
    if ($content -match $initScriptPattern) {
        $content = $content -replace $initScriptPattern, $initScriptReplacement
        Set-Content $installerFilePath $content -NoNewline
        Write-Host "Updated InstallModuleResolver to search for init.server.luau" -ForegroundColor Green
    }
    else {
        Write-Host "Could not find init script pattern in InstallModuleResolver" -ForegroundColor Red
    }
}
else {
    Write-Host "InstallModuleResolver.server.luau file not found!" -ForegroundColor Red
}

Write-Host "`n=== Module resolution fixes complete! ===" -ForegroundColor Cyan
