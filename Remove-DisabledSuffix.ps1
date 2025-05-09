# Remove-DisabledSuffix.ps1
#
# This PowerShell script finds and renames all files with .disabled suffix in your project
# It's useful for cleaning up after testing the UI Script Eliminator

param(
    [string]$rootFolder = "C:\Users\pears\OneDrive\Documents\RobloxProject\src",
    [switch]$dryRun = $true,
    [string]$filePattern = "*.disabled*"
)

# Print header
Write-Host "===== DISABLED SUFFIX REMOVER =====" -ForegroundColor Cyan
Write-Host "Root Folder: $rootFolder"
Write-Host "Dry Run Mode: $(if ($dryRun) { 'Yes (will not rename)' } else { 'No (will rename)' })"
Write-Host "File Pattern: $filePattern"
Write-Host "----------------------------------------"

# Find all disabled files
$disabledFiles = Get-ChildItem -Path $rootFolder -Filter $filePattern -Recurse

# Count for statistics
$totalCount = $disabledFiles.Count
$processedCount = 0

Write-Host "Found $totalCount files with .disabled suffix" -ForegroundColor Yellow

# Process each file
foreach ($file in $disabledFiles) {
    # Get original name by removing .disabled suffix
    $originalName = $file.Name -replace '\.disabled$', ''
    $originalPath = Join-Path -Path $file.DirectoryName -ChildPath $originalName
    
    # Display info
    Write-Host "Processing: $($file.FullName)"
    Write-Host "   -> New name: $originalName"
    
    # Rename the file if not in dry run mode
    if (-not $dryRun) {
        try {
            Rename-Item -Path $file.FullName -NewName $originalName -Force
            Write-Host "   -> Renamed successfully" -ForegroundColor Green
            $processedCount++
        }
        catch {
            Write-Host "   -> Error renaming: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "   -> Would rename (dry run)" -ForegroundColor Yellow
        $processedCount++
    }
}

# Print summary
Write-Host "`n----------------------------------------"
Write-Host "PROCESS COMPLETE"
Write-Host "Total files processed: $processedCount of $totalCount"
Write-Host "----------------------------------------" 

# Instructions for running in non-dry-run mode
if ($dryRun) {
    Write-Host "`nTo actually rename the files, run:" -ForegroundColor Cyan
    Write-Host ".\Remove-DisabledSuffix.ps1 -dryRun:`$false"
}
