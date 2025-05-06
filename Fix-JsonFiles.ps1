# Fix-JsonFiles.ps1
# This script automatically fixes JSON project files for Argon compatibility
# It removes comments and validates the JSON structure

# Define the project files
$projectFiles = @(
    "c:\Users\dpearson\OneDrive\Documents\RobloxProject\DataStore-plugin.project.json",
    "c:\Users\dpearson\OneDrive\Documents\RobloxProject\default.project.json"
)

Write-Host "Argon JSON Project Files Fixer" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# Function to fix a JSON file by removing comments
function Fix-JsonFile {
    param (
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        Write-Host "✗ File not found: $FilePath" -ForegroundColor Red
        return $false
    }

    Write-Host "Processing: $FilePath" -ForegroundColor Yellow
    
    # Read file content
    $originalContent = Get-Content -Path $FilePath -Raw
    
    # Check if file has comments
    $hasComments = $originalContent -match "^\s*//|`n\s*//"
    
    if (-not $hasComments) {
        Write-Host "✓ No comments found in the file" -ForegroundColor Green
        
        # Validate JSON regardless
        try {
            $null = $originalContent | ConvertFrom-Json
            Write-Host "✓ JSON structure is valid" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "✗ JSON validation failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    
    # File has comments, let's fix it
    Write-Host "! Found comments in the file, removing..." -ForegroundColor Yellow
    
    # Create clean content by removing comment lines
    $cleanContent = $originalContent -replace "(?m)^\s*//.*\r?\n", ""
    
    # Create backup
    $backupPath = "$FilePath.backup-$(Get-Date -Format 'yyyyMMddHHmmss')"
    $originalContent | Set-Content -Path $backupPath
    Write-Host "✓ Created backup at: $backupPath" -ForegroundColor Green
    
    # Write clean content
    $cleanContent | Set-Content -Path $FilePath
    
    # Validate the cleaned JSON
    try {
        $null = $cleanContent | ConvertFrom-Json
        Write-Host "✓ Fixed file saved and validated successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "✗ JSON validation failed after cleaning: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "! Restoring from backup..." -ForegroundColor Yellow
        
        # Restore backup
        Get-Content -Path $backupPath -Raw | Set-Content -Path $FilePath
        Write-Host "✓ Original file restored from backup" -ForegroundColor Green
        return $false
    }
}

# Process each file
$results = @()
foreach ($file in $projectFiles) {
    $result = [PSCustomObject]@{
        File = (Split-Path $file -Leaf)
        Path = $file
        Success = (Fix-JsonFile -FilePath $file)
    }
    $results += $result
    Write-Host "" # Add a blank line between files
}

# Display summary
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "========" -ForegroundColor Cyan
$successCount = ($results | Where-Object { $_.Success -eq $true }).Count
$totalCount = $results.Count

$results | ForEach-Object {
    $status = if ($_.Success) { "✓" } else { "✗" }
    $color = if ($_.Success) { "Green" } else { "Red" }
    Write-Host "$status $($_.File): " -NoNewline -ForegroundColor $color
    Write-Host "$($_.Path)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Successfully processed $successCount out of $totalCount files" -ForegroundColor $(if ($successCount -eq $totalCount) { "Green" } else { "Yellow" })

# Provide next steps
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "==========="

if ($successCount -eq $totalCount) {
    Write-Host "1. Run SyncWithArgon.bat to sync your plugin to Roblox Studio"
    Write-Host "2. Check for any issues in the Roblox Studio output window"
} else {
    Write-Host "1. Address the issues in the files that couldn't be fixed"
    Write-Host "2. Run this script again"
    Write-Host "3. Once all files are fixed, run SyncWithArgon.bat"
}

Write-Host ""
Write-Host "To manually sync the plugin with Argon:" -ForegroundColor Cyan
Write-Host "1. Open Roblox Studio"
Write-Host "2. In the Argon plugin, select 'Open Project'"
Write-Host "3. Navigate to: $((Split-Path $projectFiles[0] -Parent))"
Write-Host "4. Select 'DataStore-plugin.project.json'"

Read-Host "`nPress Enter to exit..."
