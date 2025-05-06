Write-Host "Reading JSON files in current directory" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

$files = @(
    "default.project.json",
    "DataStore-plugin.project.json", 
    "main.project.json"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "`n[$file]" -ForegroundColor Green
        $content = Get-Content $file -Raw
        Write-Host $content
    } else {
        Write-Host "`n[$file] - Not found" -ForegroundColor Red
    }
}

Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
Read-Host
