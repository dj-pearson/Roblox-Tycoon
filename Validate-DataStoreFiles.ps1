# Validate-DataStoreFiles.ps1
# This script checks that for every .server.luau file, there is a matching .luau file that re-exports it

$serverFiles = Get-ChildItem -Path ".\DataStore Plugin\src" -Filter "*.server.luau" -Recurse
$missingFiles = @()

foreach ($serverFile in $serverFiles) {
    $baseFile = $serverFile.FullName -replace "\.server\.luau$", ".luau"
    if (-not (Test-Path $baseFile)) {
        $missingFiles += $serverFile.Name -replace "\.server\.luau$", ".luau"
        Write-Host "Missing file: $($serverFile.Name -replace "\.server\.luau$", ".luau")" -ForegroundColor Red
    }
}

if ($missingFiles.Count -eq 0) {
    Write-Host "All .server.luau files have corresponding .luau re-export files." -ForegroundColor Green
}
else {
    Write-Host "The following files are missing and need to be created:" -ForegroundColor Yellow
    $missingFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}
