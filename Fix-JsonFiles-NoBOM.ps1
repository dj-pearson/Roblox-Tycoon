# Fix-JsonFiles-NoBOM.ps1
# This script fixes JSON files by removing any BOM (Byte Order Mark) characters and comments
# BOM characters can cause parsing errors in tools like Argon

Write-Host "JSON File Cleaner (BOM Remover)" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

$files = @(
    "DataStore-plugin.project.json",
    "default.project.json",
    "main.project.json"
)

foreach ($file in $files) {
    $filePath = Join-Path $PSScriptRoot $file
    
    if (Test-Path $filePath) {
        Write-Host "Processing $file..." -ForegroundColor Yellow
        
        # Create a backup
        $backupPath = "$filePath.bak"
        Copy-Item -Path $filePath -Destination $backupPath -Force
        Write-Host "  Backup created: $file.bak" -ForegroundColor Gray
        
        # Read file content as string (this automatically strips the BOM)
        $content = Get-Content -Path $filePath -Raw
        
        # Remove any commented lines
        $content = $content -replace '(?m)^\s*//.*$', ''
        
        # Parse and reformat to ensure proper JSON structure
        try {
            $jsonObj = $content | ConvertFrom-Json
            $formattedJson = $jsonObj | ConvertTo-Json -Depth 10
            
            # Write the processed content back without BOM
            $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($filePath, $formattedJson, $utf8NoBomEncoding)
            
            Write-Host "  Successfully fixed and saved without BOM: $file" -ForegroundColor Green
        }
        catch {
            Write-Host "  Error processing $file: $_" -ForegroundColor Red
            Write-Host "  Restoring from backup..." -ForegroundColor Yellow
            
            Copy-Item -Path $backupPath -Destination $filePath -Force
            Write-Host "  Restored from backup" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "File not found: $file" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "All JSON files processed. You can now try Argon sync again." -ForegroundColor Cyan
Write-Host "If you encounter issues, check the .bak files to restore the original versions." -ForegroundColor Yellow
