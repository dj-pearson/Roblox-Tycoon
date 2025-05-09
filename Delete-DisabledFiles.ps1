# Delete-DisabledFiles.ps1
#
# This PowerShell script finds and deletes all files with .disabled suffix in your project
# It's useful for cleaning up after testing the UI Script Eliminator

param(
    [string]$rootFolder = "C:\Users\pears\OneDrive\Documents\RobloxProject\src",
    [switch]$dryRun = $true,
    [string]$filePattern = "*.disabled*"
)

# Print header
Write-Host "===== DISABLED FILES DELETION =====" -ForegroundColor Cyan
Write-Host "Root Folder: $rootFolder"
Write-Host "Dry Run Mode: $(if ($dryRun) { 'Yes (will not delete)' } else { 'No (will delete)' })"
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
    # Display info
    Write-Host "Processing: $($file.FullName)"
    
    # Delete the file if not in dry run mode
    if (-not $dryRun) {
        try {
            Remove-Item -Path $file.FullName -Force
            Write-Host "   -> Deleted successfully" -ForegroundColor Green
            $processedCount++
        }
        catch {
            Write-Host "   -> Error deleting: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "   -> Would delete (dry run)" -ForegroundColor Yellow
        $processedCount++
    }
}

# Print summary
Write-Host "`n----------------------------------------"
Write-Host "PROCESS COMPLETE"
Write-Host "Total files processed: $processedCount of $totalCount"
Write-Host "----------------------------------------" 

# Instructions and warnings
if ($dryRun) {
    Write-Host "`nWARNING: This script will permanently delete files. Make sure you have backups." -ForegroundColor Red
    Write-Host "`nTo actually delete the files, run:" -ForegroundColor Cyan
    Write-Host ".\Delete-DisabledFiles.ps1 -dryRun:`$false"
}
else {
    Write-Host "`nThe disabled files have been permanently deleted." -ForegroundColor Green
    Write-Host "If you need to recover them, check your backups." -ForegroundColor Yellow
}
