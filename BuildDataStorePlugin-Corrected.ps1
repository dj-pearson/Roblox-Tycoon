# BuildDataStorePlugin.ps1
# This script builds the DataStore Plugin and deploys it to the Roblox Plugins folder using Argon

# Configuration
$sourceFolder = "DataStore Plugin"
$outputFile = "DataStorePlugin.rbxm"
$pluginFolder = "$env:LOCALAPPDATA\Roblox\Plugins"

Write-Host "Building DataStore Plugin using Argon..." -ForegroundColor Cyan

# Check if Argon is available
$argonExists = Get-Command "argon" -ErrorAction SilentlyContinue
if (-not $argonExists) {
    Write-Host "Argon is not found in your PATH. Checking if it exists in the expected locations..." -ForegroundColor Yellow
    
    # Try common locations where Argon might be installed
    $argonPaths = @(
        "$env:USERPROFILE\.argon\argon.exe",
        ".\tools\argon\argon.exe"
    )
    
    $argonFound = $false
    foreach ($path in $argonPaths) {
        if (Test-Path $path) {
            $argonExe = $path
            $argonFound = $true
            Write-Host "Found Argon at: $argonExe" -ForegroundColor Green
            break
        }
    }
    
    if (-not $argonFound) {
        Write-Host "Argon not found. Please make sure Argon is installed and accessible." -ForegroundColor Red
        Write-Host "You can try running Argon-Setup.bat first or add Argon to your PATH." -ForegroundColor Yellow
        exit 1
    }
} else {
    $argonExe = "argon"
}

# Create the plugin directory structure
Write-Host "Creating directory structure for plugin..." -ForegroundColor Yellow
$tempDir = ".\DataStorePluginTemp"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Create a temporary plugin project file
$pluginJsonPath = "$tempDir\plugin.json"
$pluginJson = @"
{
    "name": "DataStore Manager Pro",
    "description": "A professional DataStore management plugin for Roblox",
    "authors": ["Your Name"],
    "version": "1.0.0"
}
"@
Set-Content -Path $pluginJsonPath -Value $pluginJson

# Copy the source files to the temporary directory
Write-Host "Copying source files..." -ForegroundColor Yellow
Copy-Item -Path "$sourceFolder\*" -Destination $tempDir -Recurse -Force

# Build the plugin using Argon
Write-Host "Building plugin using Argon..." -ForegroundColor Yellow
$buildCommand = "$argonExe build --path $tempDir --output $outputFile"
Invoke-Expression $buildCommand

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to build plugin with Argon" -ForegroundColor Red
    exit 1
}

# Deploy the plugin to the Roblox Plugins folder
if (Test-Path $outputFile) {
    Write-Host "Plugin built successfully: $outputFile" -ForegroundColor Green
    
    # Check if the Plugins folder exists
    if (-not (Test-Path $pluginFolder)) {
        Write-Host "Creating Roblox Plugins folder: $pluginFolder" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $pluginFolder -Force | Out-Null
    }
    
    # Copy the plugin to the Plugins folder
    Copy-Item -Path $outputFile -Destination $pluginFolder -Force
    Write-Host "Plugin deployed to: $pluginFolder\$outputFile" -ForegroundColor Green
} else {
    Write-Host "Error: Plugin file not found after build" -ForegroundColor Red
    exit 1
}

# Clean up
Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Build complete!" -ForegroundColor Green
