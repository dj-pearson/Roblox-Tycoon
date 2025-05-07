# SimpleBuildPlugin.ps1
# A simpler script to rebuild and deploy the DataStore Plugin

$pluginsFolder = "$env:LOCALAPPDATA\Roblox\Plugins"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = "DataStorePlugin_Backup_$timestamp.rbxmx"

Write-Host "Backing up original plugin file..." -ForegroundColor Yellow
if (Test-Path "$pluginsFolder\DataStorePlugin.rbxmx") {
    Copy-Item -Path "$pluginsFolder\DataStorePlugin.rbxmx" -Destination "$pluginsFolder\$backupFile"
    Write-Host "Backup created at: $pluginsFolder\$backupFile" -ForegroundColor Green
}

Write-Host "Looking for existing build scripts..." -ForegroundColor Yellow

# Try Python script if available
$pythonScript = ".\BuildDataStorePlugin.py"
if (Test-Path $pythonScript) {
    Write-Host "Found Python build script. Running..." -ForegroundColor Cyan
    python $pythonScript
}
# Try BAT file if available
elseif (Test-Path ".\BuildAndDeployPlugin.bat") {
    Write-Host "Found BAT build script. Running..." -ForegroundColor Cyan
    cmd /c BuildAndDeployPlugin.bat
}
else {
    Write-Host "No suitable build script found. Using direct file copy approach..." -ForegroundColor Yellow
    
    # Create a timestamp file to ensure we have a new file
    $timestampFile = ".\DataStore Plugin\src\BuildTimestamp.luau"
    Set-Content -Path $timestampFile -Value "--luau`n-- Build timestamp: $timestamp`n`nreturn '$timestamp'"
    
    # Copy the entire plugin directory to Roblox Plugins folder
    Copy-Item -Path ".\DataStore Plugin" -Destination "$pluginsFolder\DataStore Manager Pro" -Recurse -Force
    Write-Host "Copied plugin directory to: $pluginsFolder\DataStore Manager Pro" -ForegroundColor Green
}

Write-Host "`nPlugin update complete!" -ForegroundColor Green
Write-Host "Please restart Roblox Studio for changes to take effect." -ForegroundColor Cyan
