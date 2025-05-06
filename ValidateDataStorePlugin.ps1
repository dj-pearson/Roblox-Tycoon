# DataStore Plugin Validation Script
# This script checks for common issues with the DataStore plugin before/after syncing with Argon

Write-Host "DataStore Plugin Validation" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan
Write-Host ""

$pluginDir = "c:\Users\dpearson\OneDrive\Documents\RobloxProject\DataStore Plugin"
$projectFile = "c:\Users\dpearson\OneDrive\Documents\RobloxProject\DataStore-plugin.project.json"

# Check if project file exists
Write-Host "Checking project file..." -ForegroundColor Yellow
if (Test-Path $projectFile) {
    Write-Host "✓ Project file found at: $projectFile" -ForegroundColor Green
    
    # Check project file content
    $projectContent = Get-Content $projectFile -Raw | ConvertFrom-Json
    if ($projectContent.tree.'$className' -eq "Plugin") {
        Write-Host "✓ Project file has correct Plugin class name" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Project file has incorrect class name: $($projectContent.tree.'$className')" -ForegroundColor Red
        Write-Host "  Should be 'Plugin' instead" -ForegroundColor Red
    }
}
else {
    Write-Host "✗ Project file not found at: $projectFile" -ForegroundColor Red
}

Write-Host ""
Write-Host "Checking for large files (>90KB)..." -ForegroundColor Yellow
$largeFiles = Get-ChildItem -Path $pluginDir -File -Recurse | 
Where-Object { $_.Length -gt 90KB -and $_.DirectoryName -notlike "*Backups*" } | 
Sort-Object Length -Descending

if ($largeFiles.Count -eq 0) {
    Write-Host "✓ No large files found outside of Backups folder" -ForegroundColor Green
}
else {
    Write-Host "! Found $($largeFiles.Count) large file(s) that might cause issues:" -ForegroundColor Yellow
    $largeFiles | ForEach-Object {
        Write-Host "  - $($_.Name): $([math]::Round($_.Length / 1KB, 2)) KB" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Checking for required files..." -ForegroundColor Yellow
$requiredFiles = @("init.server.luau", "DataExplorer.server.luau", "DataStoreManager.server.luau")
$missingFiles = @()

foreach ($file in $requiredFiles) {
    if (Test-Path "$pluginDir\$file") {
        Write-Host "✓ Required file found: $file" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Required file missing: $file" -ForegroundColor Red
        $missingFiles += $file
    }
}

Write-Host ""
Write-Host "Checking Backups folder..." -ForegroundColor Yellow
if (Test-Path "$pluginDir\Backups") {
    $backupFiles = Get-ChildItem -Path "$pluginDir\Backups" -File
    Write-Host "✓ Backups folder exists with $($backupFiles.Count) file(s)" -ForegroundColor Green
    
    # List backup files
    $backupFiles | ForEach-Object {
        Write-Host "  - $($_.Name): $([math]::Round($_.Length / 1KB, 2)) KB" -ForegroundColor Gray
    }
}
else {
    Write-Host "✗ Backups folder not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "========"
if ($missingFiles.Count -eq 0 -and $largeFiles.Count -eq 0 -and (Test-Path $projectFile)) {
    Write-Host "✓ All checks passed. The plugin should be ready for Argon sync." -ForegroundColor Green
}
else {
    Write-Host "! There are some issues that might affect syncing with Argon:" -ForegroundColor Yellow
    
    if ($missingFiles.Count -gt 0) {
        Write-Host "  - Missing required files: $($missingFiles -join ', ')" -ForegroundColor Yellow
    }
    
    if ($largeFiles.Count -gt 0) {
        Write-Host "  - Large files detected outside of Backups folder" -ForegroundColor Yellow
    }
    
    if (-not (Test-Path $projectFile)) {
        Write-Host "  - Project file not found" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "==========="
Write-Host "1. Run SyncWithArgon.bat to sync the plugin to Roblox Studio"
Write-Host "2. Check Roblox Studio's output window for any sync errors"
Write-Host "3. Test the plugin functionality after syncing"
Write-Host ""

Read-Host "Press Enter to exit"
