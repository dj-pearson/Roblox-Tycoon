# Start-Rojo.ps1
# This script starts a clean Rojo server for your Roblox project

Write-Host "Starting Rojo server..." -ForegroundColor Cyan

# Stop any existing Rojo or Argon processes
$rojoProcesses = Get-Process -Name "rojo" -ErrorAction SilentlyContinue
if ($rojoProcesses) {
    Write-Host "Stopping existing Rojo processes..." -ForegroundColor Yellow
    Stop-Process -Name "rojo" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

$argonProcesses = Get-Process -Name "argon" -ErrorAction SilentlyContinue
if ($argonProcesses) {
    Write-Host "Stopping existing Argon processes..." -ForegroundColor Yellow
    Write-Host "Note: Argon and Rojo should not be run simultaneously" -ForegroundColor Yellow
    Stop-Process -Name "argon" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# Clean any comments from the JSON file (JSON doesn't support comments)
Write-Host "Checking project file..." -ForegroundColor Cyan
$jsonFile = Join-Path -Path $PSScriptRoot -ChildPath "default.project.json"
if (Test-Path $jsonFile) {
    $jsonContent = Get-Content -Path $jsonFile -Raw
    if ($jsonContent -match "//") {
        Write-Host "Removing comments from JSON file..." -ForegroundColor Yellow
        $jsonContent = $jsonContent -replace "//.*?`n", "`n"
        $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($jsonFile, $jsonContent, $utf8NoBomEncoding)
    }
}

# Start Rojo
Write-Host "Starting Rojo server..." -ForegroundColor Green
Write-Host "Connect in Roblox Studio using the Rojo plugin (not Argon)" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow

# Start Rojo in the current window
& rojo serve
