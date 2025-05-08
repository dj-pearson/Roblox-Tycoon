# Fix-Argon-Issues.ps1
# This script fixes common Argon connection issues including JSON BOM characters,
# Node.js path problems, and resets the Argon configuration.

Write-Host "Starting Argon fix process..." -ForegroundColor Cyan

# 1. Fix JSON files by removing BOM characters
function Remove-BOM {
    param (
        [string]$FilePath
    )
    
    Write-Host "Checking $FilePath for BOM characters..." -ForegroundColor Yellow
    
    if (Test-Path $FilePath) {
        # Read the file content as bytes to detect BOM
        $content = [System.IO.File]::ReadAllBytes($FilePath)
        
        # Check if the file has a BOM (0xEF, 0xBB, 0xBF for UTF-8)
        if ($content.Length -ge 3 -and $content[0] -eq 0xEF -and $content[1] -eq 0xBB -and $content[2] -eq 0xBF) {
            Write-Host "BOM detected in $FilePath - removing..." -ForegroundColor Yellow
            
            # Create a backup
            $backupPath = "$FilePath.bak_$(Get-Date -Format 'yyyyMMddHHmmss')"
            Copy-Item -Path $FilePath -Destination $backupPath -Force
            Write-Host "Created backup at $backupPath" -ForegroundColor Green
            
            # Read the content as string, skipping the BOM
            $contentWithoutBOM = [System.Text.Encoding]::UTF8.GetString($content, 3, $content.Length - 3)
            
            # Write the content back without the BOM
            [System.IO.File]::WriteAllText($FilePath, $contentWithoutBOM, [System.Text.Encoding]::UTF8)
            
            Write-Host "Successfully removed BOM from $FilePath" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "No BOM detected in $FilePath" -ForegroundColor Green
            return $false
        }
    }
    else {
        Write-Host "File not found: $FilePath" -ForegroundColor Red
        return $false
    }
}

# 2. Check if Node.js is installed and available in PATH
function Test-NodeJS {
    try {
        $nodeVersion = node --version
        Write-Host "Node.js is installed: $nodeVersion" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Node.js is not available in PATH" -ForegroundColor Red
        return $false
    }
}

# 3. Find Node.js installation
function Find-NodeJS {
    $commonPaths = @(
        "C:\Program Files\nodejs",
        "C:\Program Files (x86)\nodejs",
        "$env:USERPROFILE\AppData\Roaming\npm",
        "$env:USERPROFILE\scoop\apps\nodejs\current",
        "$env:LOCALAPPDATA\Programs\nodejs"
    )
    
    foreach ($path in $commonPaths) {
        $nodePath = Join-Path -Path $path -ChildPath "node.exe"
        if (Test-Path $nodePath) {
            Write-Host "Found Node.js at: $path" -ForegroundColor Green
            return $path
        }
    }
    
    Write-Host "Could not find Node.js installation" -ForegroundColor Red
    return $null
}

# Fix all JSON files
$jsonFiles = @(
    "default.project.json",
    "clean-default.project.json",
    "clean-plugin.project.json",
    "DataStore-plugin.project.json",
    "enhanced.project.json"
)

foreach ($file in $jsonFiles) {
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath $file
    Remove-BOM -FilePath $filePath
}

# Check Node.js installation
$nodeInstalled = Test-NodeJS
if (-not $nodeInstalled) {
    $nodePath = Find-NodeJS
    if ($nodePath) {
        Write-Host "Adding Node.js to PATH for this session" -ForegroundColor Yellow
        $env:PATH = "$nodePath;$env:PATH"
        
        # Test again
        $nodeInstalled = Test-NodeJS
        if ($nodeInstalled) {
            Write-Host "Node.js is now available in PATH" -ForegroundColor Green
        }
        else {
            Write-Host "Failed to add Node.js to PATH" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Please install Node.js from https://nodejs.org/" -ForegroundColor Red
        Write-Host "After installing, run the Argon-Setup-Improved.bat script" -ForegroundColor Yellow
    }
}

# Check if aftman.toml exists and wally/argon are configured
$aftmanPath = Join-Path -Path $PSScriptRoot -ChildPath "aftman.toml"
if (Test-Path $aftmanPath) {
    Write-Host "Checking aftman.toml configuration..." -ForegroundColor Yellow
    $aftmanContent = Get-Content -Path $aftmanPath -Raw
    
    if (-not ($aftmanContent -match "wally") -or -not ($aftmanContent -match "argon")) {
        Write-Host "aftman.toml might be missing wally or argon configuration" -ForegroundColor Yellow
    }
    else {
        Write-Host "aftman.toml appears to be properly configured" -ForegroundColor Green
    }
}
else {
    Write-Host "aftman.toml not found - this might be needed for Argon" -ForegroundColor Yellow
}

# Suggest running the improved setup script
Write-Host "`nFix process completed. Next steps:" -ForegroundColor Cyan
Write-Host "1. Run Argon-Setup-Improved.bat to ensure proper Node.js setup" -ForegroundColor Yellow
Write-Host "2. If still encountering issues, close all command prompts and restart your computer" -ForegroundColor Yellow
Write-Host "3. After restart, run Argon-Setup-Improved.bat again" -ForegroundColor Yellow
