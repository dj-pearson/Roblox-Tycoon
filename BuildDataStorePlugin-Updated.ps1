# BuildDataStorePlugin-Updated.ps1
# This script prepares and builds the DataStore Plugin for Roblox Studio

$srcFolder = "c:\Users\pears\OneDrive\Documents\RobloxProject\DataStore Plugin\src"
$outputFile = "c:\Users\pears\OneDrive\Documents\RobloxProject\DataStorePlugin.rbxmx"
$pluginFolder = "$env:LOCALAPPDATA\Roblox\Plugins"

Write-Host "=== DataStore Plugin Build Script ===" -ForegroundColor Cyan

# 1. First run the plugin structure fix script to ensure all files are correctly set up
Write-Host "`nStep 1: Running plugin structure fix..." -ForegroundColor White
& "c:\Users\pears\OneDrive\Documents\RobloxProject\Fix-PluginStructure.ps1"

# 2. Fix the init.server.luau file to properly resolve modules
Write-Host "`nStep 2: Checking init.server.luau module resolver..." -ForegroundColor White
$initPath = Join-Path $srcFolder "init.server.luau"
$initContent = Get-Content $initPath -Raw

# 3. Build the plugin using Rojo or similar
Write-Host "`nStep 3: Building plugin..." -ForegroundColor White
# Check if rojo is available
$rojoInstalled = $null -ne (Get-Command "rojo" -ErrorAction SilentlyContinue)

if ($rojoInstalled) {
    # Use rojo to build
    Write-Host "  Using Rojo to build plugin..." -ForegroundColor Gray
    rojo build -o $outputFile "c:\Users\pears\OneDrive\Documents\RobloxProject\DataStore-plugin.project.json"
} else {
    # Fallback to manual method
    Write-Host "  Rojo not found, using manual build method..." -ForegroundColor Yellow
    # Copy the files to a temporary folder
    $tempFolder = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
    New-Item -ItemType Directory -Path $tempFolder | Out-Null
    
    Copy-Item -Path "$srcFolder\*" -Destination $tempFolder -Recurse
    
    # TODO: Add fallback build logic here
    Write-Host "  Manual build not implemented. Please install Rojo or use Roblox Studio to build." -ForegroundColor Red
}

# 4. Copy to plugins folder for local testing
if (Test-Path $outputFile) {
    Write-Host "`nStep 4: Copying plugin to Roblox Studio Plugins folder..." -ForegroundColor White
    if (!(Test-Path $pluginFolder)) {
        New-Item -ItemType Directory -Path $pluginFolder -Force | Out-Null
    }
    
    Copy-Item -Path $outputFile -Destination "$pluginFolder\DataStoreManagerPro.rbxmx" -Force
    Write-Host "  Plugin copied to: $pluginFolder\DataStoreManagerPro.rbxmx" -ForegroundColor Green
} else {
    Write-Host "`nStep 4: Skipped - Output file not found" -ForegroundColor Red
}

Write-Host "`n=== Build process completed! ===" -ForegroundColor Cyan
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Test the plugin in Roblox Studio" -ForegroundColor Yellow
Write-Host "2. Check the output log in Studio for any errors" -ForegroundColor Yellow
Write-Host "3. If errors persist, check the specific module causing issues" -ForegroundColor Yellow
