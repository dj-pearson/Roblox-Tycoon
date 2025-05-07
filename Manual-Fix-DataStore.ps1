# Manual-Fix-DataStore.ps1
# This script manually fixes critical issues in DataStore Plugin

$srcFolder = "c:\Users\pears\OneDrive\Documents\RobloxProject\DataStore Plugin\src"

# 1. Fix empty re-export files
$emptyReexportFiles = @(
    "DataExplorer.luau",
    "SchemaVersioning.luau",
    "DataStoreManager.luau",
    "MultiServerCoordinationIntegration.luau",
    "PerformanceAnalyzerIntegration.luau"
)

foreach ($file in $emptyReexportFiles) {
    $filePath = Join-Path $srcFolder $file
    $moduleName = $file -replace '\.luau$', ''
    
    $content = @"
--luau
-- DataStore Plugin/$file
-- This is a re-export file that forwards to the server version

-- Use direct reference to the server script instead of script.server
return require(script.Parent:FindFirstChild("$moduleName.server"))
"@
    
    Set-Content $filePath $content -NoNewline
    Write-Host "Created/updated re-export file: $file" -ForegroundColor Green
}

# 2. Fix init.server.luau module resolver
$initServerPath = Join-Path $srcFolder "init.server.luau"
$initContent = Get-Content $initServerPath -Raw

$moduleResolverPattern = @"
    local moduleScript = nil
    
    -- Try direct reference first
    moduleScript = script.Parent:FindFirstChild\(moduleName\)
    
    -- If not found, try with .server suffix
    if not moduleScript then
        moduleScript = script.Parent:FindFirstChild\(moduleName \.\. "\.server"\)
    end
    
    -- If not found, try with .luau suffix
    if not moduleScript then
        moduleScript = script.Parent:FindFirstChild\(moduleName \.\. "\.luau"\)
    end
    
    -- If still not found, try with .server.luau suffix
    if not moduleScript then
        moduleScript = script.Parent:FindFirstChild\(moduleName \.\. "\.server\.luau"\)
    end
"@

if (!($initContent -match $moduleResolverPattern)) {
    # Find where to insert our resolver code
    $simplePattern = 'local moduleScript = script.Parent:FindFirstChild\(moduleName\)'
    
    if ($initContent -match $simplePattern) {
        $updatedContent = $initContent -replace $simplePattern, @"
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
        Set-Content $initServerPath $updatedContent -NoNewline
        Write-Host "Updated init.server.luau module resolver" -ForegroundColor Green
    }
    else {
        Write-Host "Could not find module resolver pattern in init.server.luau" -ForegroundColor Red
    }
}

# 3. Check and fix the elif issue
$elifPattern = 'elif type\(DataMigrationTools\) == "function" then'
$initContent = Get-Content $initServerPath -Raw

if ($initContent -match $elifPattern) {
    $updatedContent = $initContent -replace $elifPattern, 'elseif type(DataMigrationTools) == "function" then'
    Set-Content $initServerPath $updatedContent -NoNewline
    Write-Host "Fixed 'elif' to 'elseif' in init.server.luau" -ForegroundColor Green
}

Write-Host "`nManual fixes completed!" -ForegroundColor Cyan
