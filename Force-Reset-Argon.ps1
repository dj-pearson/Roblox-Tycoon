# Force-Reset-Argon.ps1
# This script forcibly removes all project JSON files and initializes a new Argon project

Write-Host "Forcibly removing all project JSON files..." -ForegroundColor Yellow

# List of files to remove
$filesToRemove = @(
    'default.project.json',
    'DataStore-plugin.project.json', 
    'clean-default.project.json',
    'clean-plugin.project.json',
    'enhanced.project.json',
    'main.project.json',
    'rojo-plugin.project.json',
    'rojo-plugin2.project.json',
    'rojo-plugin-standard.project.json',
    'rojo-plugin-detailed.project.json',
    'init.meta.json'
)

# Create backup directory
$backupDir = Join-Path -Path $PSScriptRoot -ChildPath 'ForcedBackups'
if (-not (Test-Path $backupDir)) {
    New-Item -Path $backupDir -ItemType Directory | Out-Null
    Write-Host "Created backup directory: $backupDir" -ForegroundColor Yellow
}

# Move files to backup
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
foreach ($file in $filesToRemove) {
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath $file
    if (Test-Path $filePath) {
        $backupFile = Join-Path -Path $backupDir -ChildPath ($file + '.' + $timestamp)
        Copy-Item -Path $filePath -Destination $backupFile -Force
        Remove-Item -Path $filePath -Force
        Write-Host "Removed $file (backup created)" -ForegroundColor Yellow
    }
}

# Now add a script that will create directory structure correctly if needed
$srcDir = Join-Path -Path $PSScriptRoot -ChildPath 'src'
$sharedDir = Join-Path -Path $srcDir -ChildPath 'shared'
$serverDir = Join-Path -Path $srcDir -ChildPath 'server'
$clientDir = Join-Path -Path $srcDir -ChildPath 'client'

# Create src directory structure if needed
if (-not (Test-Path $srcDir)) {
    New-Item -Path $srcDir -ItemType Directory | Out-Null
    Write-Host "Created directory: src" -ForegroundColor Green
}

if (-not (Test-Path $sharedDir)) {
    New-Item -Path $sharedDir -ItemType Directory | Out-Null
    Write-Host "Created directory: src/shared" -ForegroundColor Green
}

if (-not (Test-Path $serverDir)) {
    New-Item -Path $serverDir -ItemType Directory | Out-Null
    Write-Host "Created directory: src/server" -ForegroundColor Green
}

if (-not (Test-Path $clientDir)) {
    New-Item -Path $clientDir -ItemType Directory | Out-Null
    Write-Host "Created directory: src/client" -ForegroundColor Green
}

Write-Host "`nProject files removed and directory structure created" -ForegroundColor Green
Write-Host "Now run: argon init" -ForegroundColor Cyan
