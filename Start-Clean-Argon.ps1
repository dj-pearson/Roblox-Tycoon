# Start-Clean-Argon.ps1
# This script runs a clean Argon server with proper configuration

Write-Host "Starting clean Argon server..." -ForegroundColor Cyan

# Stop any existing Argon processes
$argonProcesses = Get-Process -Name "argon" -ErrorAction SilentlyContinue
if ($argonProcesses) {
    Write-Host "Stopping existing Argon processes..." -ForegroundColor Yellow
    Stop-Process -Name "argon" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# Run Quick-Fix-Default-JSON.ps1 to ensure a clean default.project.json
Write-Host "Creating clean project file..." -ForegroundColor Cyan
& "$PSScriptRoot\Quick-Fix-Default-JSON.ps1"

# Start Argon
Write-Host "Starting Argon server..." -ForegroundColor Green
Write-Host "Server will be available at: http://localhost:8000 (or another port if 8000 is in use)" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow

# Start Argon in the current window
& argon serve
