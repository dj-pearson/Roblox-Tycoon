# DataStore Plugin Validation Script
# This script checks for common issues with the DataStore plugin before/after syncing with Argon

Write-Host "DataStore Plugin Validation" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan
Write-Host ""

$pluginDir = "c:\Users\dpearson\OneDrive\Documents\RobloxProject\DataStore Plugin"
$projectFile = "c:\Users\dpearson\OneDrive\Documents\RobloxProject\DataStore-plugin.project.json"
$defaultProjectFile = "c:\Users\dpearson\OneDrive\Documents\RobloxProject\default.project.json"

# Check if project files exist and if they have comments
Write-Host "Checking project files..." -ForegroundColor Yellow

# Function to check for JSON comments
function Test-JsonComments {
    param (
        [string]$FilePath,
        [string]$FileDescription
    )
    
    if (Test-Path $FilePath) {
        Write-Host "✓ $FileDescription found at: $FilePath" -ForegroundColor Green
        
        # Check for comments in the file
        $fileContent = Get-Content $FilePath -Raw
        if ($fileContent -match "^\s*//") {
            Write-Host "✗ $FileDescription contains comments which can cause Argon sync errors" -ForegroundColor Red
            Write-Host "  To fix, run the following command:" -ForegroundColor Yellow
            Write-Host "  $" -NoNewline -ForegroundColor Gray
            Write-Host " Fix-JsonComments -FilePath `"$FilePath`"" -ForegroundColor White
            return $false
        }
        
        # Try to parse the JSON
        try {
            $null = $fileContent | ConvertFrom-Json
            Write-Host "✓ $FileDescription is valid JSON" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "✗ $FileDescription contains invalid JSON: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    else {
        Write-Host "✗ $FileDescription not found at: $FilePath" -ForegroundColor Red
        return $false
    }
}

# Function to fix JSON comments
function Fix-JsonComments {
    param (
        [string]$FilePath
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "File not found: $FilePath" -ForegroundColor Red
        return
    }
    
    $fileContent = Get-Content $FilePath -Raw
    
    # Remove comment lines (lines starting with //)
    $newContent = $fileContent -replace "(?m)^(\s*)//.*\r?\n", ""
    
    # Write to a temporary file
    $tempFile = "$FilePath.temp"
    Set-Content -Path $tempFile -Value $newContent
    
    # Replace the original file
    Remove-Item $FilePath
    Rename-Item $tempFile $FilePath
    
    Write-Host "Comments removed from $FilePath" -ForegroundColor Green
}

# Check the Argon project file
$argonProjectValid = Test-JsonComments -FilePath $projectFile -FileDescription "Argon project file"

# Check the default project file
$defaultProjectValid = Test-JsonComments -FilePath $defaultProjectFile -FileDescription "Default project file"

# Check project file content if valid
if ($argonProjectValid) {
    $projectContent = Get-Content $projectFile -Raw | ConvertFrom-Json
    if ($projectContent.tree.'$className' -eq "Plugin") {
        Write-Host "✓ Project file has correct Plugin class name" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Project file has incorrect class name: $($projectContent.tree.'$className')" -ForegroundColor Red
        Write-Host "  Should be 'Plugin' instead" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Checking for large files (>90KB)..." -ForegroundColor Yellow
$largeFiles = Get-ChildItem -Path $pluginDir -File -Recurse | 
Where-Object { $_.Length -gt 90KB -and $_.DirectoryName -notlike "*Backups*" } | 
Sort-Object Length -Descending

if ($largeFiles.Count -eq 0) {
    Write-Host "✓ No large files found outside of Backups folder" -ForegroundColor Green
}
else {
    Write-Host "! Found $($largeFiles.Count) large file(s) that might cause issues:" -ForegroundColor Yellow
    $largeFiles | ForEach-Object {
        Write-Host "  - $($_.Name): $([math]::Round($_.Length / 1KB, 2)) KB" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Checking for required files..." -ForegroundColor Yellow
$requiredFiles = @("init.server.luau", "DataExplorer.server.luau", "DataStoreManager.server.luau")
$missingFiles = @()

foreach ($file in $requiredFiles) {
    if (Test-Path "$pluginDir\$file") {
        Write-Host "✓ Required file found: $file" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Required file missing: $file" -ForegroundColor Red
        $missingFiles += $file
    }
}

Write-Host ""
Write-Host "Checking Backups folder..." -ForegroundColor Yellow
if (Test-Path "$pluginDir\Backups") {
    $backupFiles = Get-ChildItem -Path "$pluginDir\Backups" -File
    Write-Host "✓ Backups folder exists with $($backupFiles.Count) file(s)" -ForegroundColor Green
    
    # List backup files
    $backupFiles | ForEach-Object {
        Write-Host "  - $($_.Name): $([math]::Round($_.Length / 1KB, 2)) KB" -ForegroundColor Gray
    }
}
else {
    Write-Host "✗ Backups folder not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "========"
if ($missingFiles.Count -eq 0 -and $largeFiles.Count -eq 0 -and (Test-Path $projectFile) -and $argonProjectValid -and $defaultProjectValid) {
    Write-Host "✓ All checks passed. The plugin should be ready for Argon sync." -ForegroundColor Green
}
else {
    Write-Host "! There are some issues that might affect syncing with Argon:" -ForegroundColor Yellow
    
    if ($missingFiles.Count -gt 0) {
        Write-Host "  - Missing required files: $($missingFiles -join ', ')" -ForegroundColor Yellow
    }
    
    if ($largeFiles.Count -gt 0) {
        Write-Host "  - Large files detected outside of Backups folder" -ForegroundColor Yellow
    }
    
    if (-not (Test-Path $projectFile)) {
        Write-Host "  - Project file not found" -ForegroundColor Yellow
    }
    
    if (-not $argonProjectValid) {
        Write-Host "  - Issues detected with Argon project file" -ForegroundColor Yellow
    }
    
    if (-not $defaultProjectValid) {
        Write-Host "  - Issues detected with default project file" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "==========="
Write-Host "1. Fix any issues reported above"
Write-Host "2. Run SyncWithArgon.bat to sync the plugin to Roblox Studio"
Write-Host "3. Check Roblox Studio's output window for any sync errors"
Write-Host "4. Test the plugin functionality after syncing"
Write-Host ""
Write-Host "Need to fix JSON comments? Run:" -ForegroundColor Yellow
Write-Host "  $" -NoNewline -ForegroundColor Gray
Write-Host " Fix-JsonComments -FilePath `"c:\Users\dpearson\OneDrive\Documents\RobloxProject\DataStore-plugin.project.json`"" -ForegroundColor White
Write-Host "  $" -NoNewline -ForegroundColor Gray
Write-Host " Fix-JsonComments -FilePath `"c:\Users\dpearson\OneDrive\Documents\RobloxProject\default.project.json`"" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to exit"
