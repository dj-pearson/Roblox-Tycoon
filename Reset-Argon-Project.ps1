# Reset-Argon-Project.ps1
# This script backs up all JSON files and initializes a new Argon project

# Create backup directory
$backupDir = Join-Path -Path $PSScriptRoot -ChildPath 'JsonBackupsBeforeReinit'
if (-not (Test-Path $backupDir)) {
    New-Item -Path $backupDir -ItemType Directory | Out-Null
    Write-Host "Created backup directory: $backupDir" -ForegroundColor Yellow
}

# Move JSON files to backup
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$jsonFiles = @('default.project.json', 'DataStore-plugin.project.json', 'clean-default.project.json', 'clean-plugin.project.json', 'enhanced.project.json')
foreach ($file in $jsonFiles) {
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath $file
    if (Test-Path $filePath) {
        $backupFile = Join-Path -Path $backupDir -ChildPath ($file + '.' + $timestamp)
        Move-Item -Path $filePath -Destination $backupFile -Force
        Write-Host "Moved $file to backup" -ForegroundColor Yellow
    }
}

Write-Host "All JSON files moved to backup" -ForegroundColor Green
Write-Host "Now run: argon init" -ForegroundColor Cyan
