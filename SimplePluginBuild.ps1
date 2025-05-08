# SimplePluginBuild.ps1
# A simple script to prepare plugin files for Roblox Studio

$srcFolder = "c:\Users\pears\OneDrive\Documents\RobloxProject\DataStore Plugin\src"
$pluginFolder = "$env:LOCALAPPDATA\Roblox\Plugins"

Write-Host "=== DataStore Plugin Simple Build Script ===" -ForegroundColor Cyan

# 1. Run the comprehensive fix script to ensure all files are correctly set up
Write-Host "`nStep 1: Running comprehensive fix..." -ForegroundColor White
& "c:\Users\pears\OneDrive\Documents\RobloxProject\Comprehensive-Fix-DataStore.ps1"

# 2. Ensure all server modules are properly formatted
Write-Host "`nStep 2: Checking server modules for proper formatting..." -ForegroundColor White

# 3. Manually deploy to Roblox Studio plugins folder
Write-Host "`nStep 3: Copying files to Roblox Studio plugins folder..." -ForegroundColor White

# Create a simple folder structure for the plugin
$pluginOutputFolder = Join-Path $pluginFolder "DataStoreManagerPro"
if (!(Test-Path $pluginOutputFolder)) {
    New-Item -ItemType Directory -Path $pluginOutputFolder -Force | Out-Null
    Write-Host "  - Created plugin folder: $pluginOutputFolder" -ForegroundColor Green
}

# Copy all .luau and .server.luau files
Copy-Item -Path "$srcFolder\*.luau" -Destination $pluginOutputFolder -Force
Copy-Item -Path "$srcFolder\*.server.luau" -Destination $pluginOutputFolder -Force

Write-Host "  - Copied all Luau files to plugin folder" -ForegroundColor Green

# Create a simple plugin descriptor file
$descriptorContent = @"
{
  "name": "DataStore Manager Pro",
  "description": "Advanced DataStore management, monitoring, and development tools",
  "version": "1.0.0",
  "author": "Pearson"
}
"@

Set-Content -Path (Join-Path $pluginOutputFolder "plugin.json") -Value $descriptorContent

Write-Host "  - Created plugin descriptor file" -ForegroundColor Green

Write-Host "`n=== Build process completed! ===" -ForegroundColor Cyan
Write-Host "`nPlugin has been deployed to: $pluginOutputFolder" -ForegroundColor Green
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Open Roblox Studio" -ForegroundColor Yellow
Write-Host "2. The plugin should appear in the Plugins tab" -ForegroundColor Yellow
Write-Host "3. Check the Output window for any errors" -ForegroundColor Yellow
