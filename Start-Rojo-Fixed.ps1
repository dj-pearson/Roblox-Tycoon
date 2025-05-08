# Start-Rojo-Fixed.ps1
# This script ensures all prerequisites are met and starts Rojo correctly

function Test-CommandExists {
    param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if (Get-Command $command) { return $true }
    }
    catch { return $false }
    finally { $ErrorActionPreference = $oldPreference }
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "         ROJO STARTER UTILITY" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Check if Rojo is installed
if (-not (Test-CommandExists "rojo")) {
    Write-Host "ERROR: Rojo is not installed or not in PATH!" -ForegroundColor Red
    Write-Host "Please make sure Aftman is installed and run 'aftman install'" -ForegroundColor Yellow
    exit 1
}

# Check Rojo version
$rojoVersion = (rojo --version) | Out-String
Write-Host "Detected: $rojoVersion" -ForegroundColor Cyan

# Stop any existing processes
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

# Fix default.project.json
$projectFile = Join-Path -Path $PSScriptRoot -ChildPath "default.project.json"
if (Test-Path $projectFile) {
    Write-Host "Fixing default.project.json..." -ForegroundColor Cyan
    
    # Read content
    $content = Get-Content -Path $projectFile -Raw
    
    # Remove comments if any
    $content = $content -replace "//.*?(\r?\n|$)", "`$1" -replace "/\*.*?\*/", ""
    
    # Create a UTF-8 encoder without BOM
    $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
    
    # Write the content back without BOM and comments
    [System.IO.File]::WriteAllText($projectFile, $content, $utf8NoBomEncoding)
    
    Write-Host "Project file fixed!" -ForegroundColor Green
}
else {
    Write-Host "ERROR: default.project.json not found!" -ForegroundColor Red
    exit 1
}

# Create the DataStore Plugin directory if it doesn't exist
$dataStorePluginDir = Join-Path -Path $PSScriptRoot -ChildPath "DataStore Plugin"
if (-not (Test-Path $dataStorePluginDir)) {
    Write-Host "Creating DataStore Plugin directory..." -ForegroundColor Yellow
    New-Item -Path $dataStorePluginDir -ItemType Directory -Force | Out-Null
}

# Create src directories if they don't exist
$srcDirs = @("src/shared", "src/server", "src/client")
foreach ($dir in $srcDirs) {
    $fullPath = Join-Path -Path $PSScriptRoot -ChildPath $dir
    if (-not (Test-Path $fullPath)) {
        Write-Host "Creating directory: $dir" -ForegroundColor Yellow
        New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
    }
}

# Start Rojo
Write-Host ""
Write-Host "Starting Rojo server..." -ForegroundColor Green
Write-Host "Connect in Roblox Studio using the Rojo plugin (not Argon)" -ForegroundColor Cyan
Write-Host "When the server starts, note the port number that will be displayed" -ForegroundColor Yellow
Write-Host "In Roblox Studio, connect to: http://localhost:[PORT_NUMBER]" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop the server when you're done" -ForegroundColor Yellow
Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Start Rojo
rojo serve
