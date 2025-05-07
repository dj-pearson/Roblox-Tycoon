# Create-ReexportFiles.ps1
# This script updates all non-server Lua files to properly re-export the server versions

$baseFiles = Get-ChildItem -Path ".\DataStore Plugin\src" -Filter "*.luau" | 
    Where-Object { $_.Name -notlike "*.server.luau" -and $_.Name -notlike "*.client.luau" }

foreach ($file in $baseFiles) {
    $baseName = $file.BaseName
    $serverFile = Join-Path $file.Directory.FullName "$baseName.server.luau"
    
    if (Test-Path $serverFile) {
        $reexportContent = @"
--luau
-- DataStore Plugin/$baseName.luau
-- This is a simple re-export file that forwards to the server version
-- without using FindFirstChild which can cause stack overflows

-- In Roblox, files are referenced without their extensions
return require(script.server)
"@
        
        Set-Content -Path $file.FullName -Value $reexportContent -Encoding UTF8
        Write-Host "Updated re-export file: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "All re-export files updated." -ForegroundColor Cyan
