# Quick-Fix-JSON.ps1
# A simple script to fix the BOM in JSON files

# Get all JSON files in the current directory
$jsonFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.json"

foreach ($file in $jsonFiles) {
    Write-Host "Processing $($file.FullName)..."
    
    # Read the file content (this will automatically handle BOM)
    $content = Get-Content -Path $file.FullName -Raw
    
    # Write the content back without BOM
    [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
    
    Write-Host "Fixed $($file.FullName)" -ForegroundColor Green
}

Write-Host "`nAll JSON files have been processed and fixed." -ForegroundColor Cyan
Write-Host "Now try running Argon again." -ForegroundColor Cyan
