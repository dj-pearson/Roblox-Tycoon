# Test DataStorePlugin sync with Argon
# Using plugin.project.json instead of default.project.json

Write-Host "Testing DataStorePlugin sync with Argon..." -ForegroundColor Green
Write-Host "Using plugin.project.json instead of default.project.json" -ForegroundColor Yellow

# Set location to script directory
Set-Location $PSScriptRoot
Write-Host "Current directory: $(Get-Location)" -ForegroundColor Cyan

# Check if plugin.project.json exists
if (-not (Test-Path "plugin.project.json")) {
    Write-Host "ERROR: plugin.project.json not found!" -ForegroundColor Red
    exit 1
}

Write-Host "Found plugin.project.json" -ForegroundColor Green

# Check if argon is available
try {
    $argonVersion = argon --version
    Write-Host "Argon version: $argonVersion" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Argon not found or not installed!" -ForegroundColor Red
    Write-Host "Please install Argon first: npm install -g @argon-rbx/argon" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Starting Argon with plugin.project.json..." -ForegroundColor Green
Write-Host "This will only sync the DataStorePlugin, not the entire game" -ForegroundColor Yellow
Write-Host ""

# Start Argon with the plugin project file
try {
    argon serve plugin.project.json --port 8000
}
catch {
    Write-Host "ERROR: Failed to start Argon!" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
