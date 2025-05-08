# Argon-Reset-Instructions.ps1
# This script documents the process of resetting an Argon project with corrupted JSON files
# and provides functions to perform these steps in the future

Write-Host "Argon Reset and Recovery Procedure" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

<#
WHAT WE DID TO FIX THE ISSUES:

1. Encountered JSON parsing errors with BOM characters in project.json files
2. Tried multiple approaches to fix the BOM issues:
   - PowerShell scripts to detect and remove BOM
   - Direct byte manipulation
   - Creating new files with known good content
3. Ultimate solution was to:
   - Delete ALL project.json files completely
   - Delete the init.meta.json file
   - Run 'argon init' to create fresh configuration files
   - Run 'argon serve' to start the server

This script provides functions to perform these steps in the future.
#>

function Reset-ArgonConfiguration {
    [CmdletBinding()]
    param (
        [switch]$Force,
        [switch]$CreateBackups = $true,
        [string]$BackupDir = "ArgonResetBackups"
    )
    
    Write-Host "Resetting Argon Configuration..." -ForegroundColor Yellow
    
    # Ask for confirmation if -Force is not specified
    if (-not $Force) {
        $confirmation = Read-Host "This will remove all project.json files. Are you sure? (y/n)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation cancelled." -ForegroundColor Red
            return
        }
    }
    
    # Create backup directory if needed
    if ($CreateBackups) {
        $backupPath = Join-Path -Path $PSScriptRoot -ChildPath $BackupDir
        if (-not (Test-Path $backupPath)) {
            New-Item -Path $backupPath -ItemType Directory | Out-Null
            Write-Host "Created backup directory: $backupPath" -ForegroundColor Green
        }
        
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $backupSubDir = Join-Path -Path $backupPath -ChildPath $timestamp
        New-Item -Path $backupSubDir -ItemType Directory | Out-Null
        Write-Host "Created backup subdirectory: $backupSubDir" -ForegroundColor Green
    }
    
    # Files to remove
    $filesToRemove = Get-ChildItem -Path $PSScriptRoot -Filter "*.project.json*"
    $filesToRemove += Get-ChildItem -Path $PSScriptRoot -Filter "init.meta.json"
    
    # Process each file
    foreach ($file in $filesToRemove) {
        if ($CreateBackups) {
            # Create backup
            $backupFile = Join-Path -Path $backupSubDir -ChildPath $file.Name
            Copy-Item -Path $file.FullName -Destination $backupFile -Force
            Write-Host "Backed up: $($file.Name)" -ForegroundColor Gray
        }
        
        # Remove the file
        Remove-Item -Path $file.FullName -Force
        Write-Host "Removed: $($file.Name)" -ForegroundColor Yellow
    }
    
    Write-Host "All configuration files removed." -ForegroundColor Green
    Write-Host "Now you can run 'argon init' to create fresh configuration files." -ForegroundColor Cyan
}

function Initialize-ArgonProject {
    [CmdletBinding()]
    param (
        [switch]$Force,
        [switch]$CreateSrcStructure = $true
    )
    
    # Create src directory structure if needed
    if ($CreateSrcStructure) {
        $srcDir = Join-Path -Path $PSScriptRoot -ChildPath 'src'
        $sharedDir = Join-Path -Path $srcDir -ChildPath 'shared'
        $serverDir = Join-Path -Path $srcDir -ChildPath 'server'
        $clientDir = Join-Path -Path $srcDir -ChildPath 'client'
        
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
    }
    
    # Run argon init (with force if specified)
    if ($Force) {
        # Use -y to automatically answer yes to prompts
        Write-Host "Running: argon init (with force)" -ForegroundColor Yellow
        & argon init
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to initialize Argon project."
            return
        }
    }
    else {
        Write-Host "Running: argon init" -ForegroundColor Yellow
        & argon init
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to initialize Argon project."
            return
        }
    }
    
    Write-Host "Argon project initialized successfully." -ForegroundColor Green
    Write-Host "You can now run 'argon serve' to start the server." -ForegroundColor Cyan
}

# Provide a complete reset and initialization function
function Repair-ArgonProject {
    [CmdletBinding()]
    param (
        [switch]$Force,
        [switch]$NoBackups
    )
    
    Write-Host "Performing complete Argon project repair..." -ForegroundColor Cyan
    
    # Step 1: Reset configuration
    Reset-ArgonConfiguration -Force:$Force -CreateBackups:(-not $NoBackups)
    
    # Step 2: Initialize project
    Initialize-ArgonProject -Force:$Force
    
    Write-Host "Argon project repair complete!" -ForegroundColor Green
    Write-Host "You can now run 'argon serve' to start the server." -ForegroundColor Cyan
}

Write-Host "Available commands:" -ForegroundColor Cyan
Write-Host "  Reset-ArgonConfiguration [-Force] [-CreateBackups] [-BackupDir <path>]" -ForegroundColor Yellow
Write-Host "  Initialize-ArgonProject [-Force] [-CreateSrcStructure]" -ForegroundColor Yellow
Write-Host "  Repair-ArgonProject [-Force] [-NoBackups]" -ForegroundColor Yellow
Write-Host ""
Write-Host "Example usage:" -ForegroundColor Cyan
Write-Host "  # Complete repair process:" -ForegroundColor Gray
Write-Host "  Repair-ArgonProject -Force" -ForegroundColor Yellow
Write-Host ""
Write-Host "  # Just reset configuration:" -ForegroundColor Gray
Write-Host "  Reset-ArgonConfiguration -Force" -ForegroundColor Yellow
Write-Host ""
